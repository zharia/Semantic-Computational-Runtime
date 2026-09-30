# FlockSubject — deterministic seabird flock (milestone_0006 Sprint 01;
# SCR-LIB-ECOLOGY §1 "flora and fauna" fauna half). Placement locus = SIM
# (0006 AP-11): Godot never ticks, spawns or respawns fauna; the §11 FAUNA
# section carries pose only (0006 AP-12).
#
# Rules (0006 §1.1, §3.1): waypoint seek (per-slot orbit ring over
# ocean/beach), alignment, cohesion, separation, terrain/ocean avoidance
# from the heightfield, speed clamp. Fixed slots 0..FLOCK_N_MAX-1; the first
# FLOCK_N_INIT start active; a bound violation despawns the slot and respawns
# it from (seed, slot, respawn_count) — count never exceeds the cap
# (0006 AP-13 / §6 invariant 3).
#
# Determinism (0006 §6 invariant 4): forces are computed from the PRE-tick
# state, integration runs in slot order, separation and respawn follow in
# slot order, and every random draw is the pure integer hash
# synthesis.noise.hash01_cells — no mutable RNG stream. Respawn position is
# a pure function of (seed, slot, respawn_count): spawn/respawn lands AT the
# slot's orbit waypoint (angle at the current tick) so every bird starts
# aligned with its seek target, with radial/altitude jitter from the hash and
# a bounded deterministic small angular correction when the raw point would
# sit inside FLOCK_SEPARATION_MIN of a live neighbour (keeps the pairwise
# floor and the radius bound both satisfiable — documented correction, still
# slot-order deterministic).
#
# State mutation is confined to construction + flock_tick (the per-tick
# commit owned by sim/world.mojo); the snapshot projection reads it
# read-only (projection purity, 0006 §6.8).

from std.collections import List
from std.math import sqrt, atan2, sin, cos

from sim.island import IslandSubject
from sim.parameters import (
    SEA_LEVEL,
    FIXED_DT,
    FLOCK_N_MAX,
    FLOCK_N_INIT,
    FLOCK_WAYPOINT_RADIUS,
    FLOCK_WAYPOINT_JITTER,
    FLOCK_WAYPOINT_PERIOD_TICKS,
    FLOCK_BOUND_RADIUS,
    FLOCK_MIN_ALTITUDE,
    FLOCK_MAX_ALTITUDE,
    FLOCK_SPEED_CRUISE,
    FLOCK_SPEED_MIN,
    FLOCK_SPEED_MAX,
    FLOCK_W_SEEK,
    FLOCK_W_ALIGN,
    FLOCK_W_COHERE,
    FLOCK_W_SEPARATE,
    FLOCK_W_AVOID,
    FLOCK_ALIGN_RADIUS,
    FLOCK_COHERE_RADIUS,
    FLOCK_SEPARATE_RADIUS,
    FLOCK_SEPARATION_MIN,
)
from synthesis.noise import hash01_cells
from snapshot.types import FlockBird

comptime TWO_PI: Float64 = 6.283185307179586
comptime _SALT_WAYPOINT: UInt64 = 0x510000001B3
comptime _SALT_RADIUS: UInt64 = 0x520000001B3
comptime _SALT_RES_RADIUS: UInt64 = 0x540000001B3
comptime _SALT_RES_ALT: UInt64 = 0x560000001B3
comptime _SLOT_SALT: UInt64 = 0x570000001B3
comptime _RESPAWN_TRIES: Int = 16
# Separation-retry angular step (rad). Offsets stay near the waypoint
# sector (±0.4 rad ≈ ±40 u at r=100) instead of scattering across the ring.
comptime _RESPAWN_ANG_STEP: Float64 = 0.05
# Per-respawn radial jitter = half the waypoint jitter so the worst-case
# spawn radius (100 + 6 + 3 = 109) stays inside FLOCK_BOUND_RADIUS (110).
comptime _RES_RADIUS_JITTER: Float64 = FLOCK_WAYPOINT_JITTER * 0.5


struct Bird(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Sim-side bird state — Float64 integration state (the §11 wire record
    FlockBird is the Float32 pose projection of this, encode.mojo)."""

    var x: Float64
    var y: Float64
    var z: Float64
    var vx: Float64
    var vy: Float64
    var vz: Float64
    var yaw: Float64
    var respawn_count: UInt32
    var active: Bool

    def __init__(out self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.vx = 0.0
        self.vy = 0.0
        self.vz = 0.0
        self.yaw = 0.0
        self.respawn_count = 0
        self.active = False

    def __deinit__(deinit self):
        pass


struct FlockSubject(Movable, Deinitable):
    """Explicit fauna population: fixed slot array, membership = active flag.
    count == number of active slots, never > FLOCK_N_MAX."""

    var seed: UInt32
    var count: Int
    var birds: List[Bird]

    def __init__(out self):
        self.seed = 0
        self.count = 0
        self.birds = List[Bird]()

    def __deinit__(deinit self):
        pass


def _slot_hash(seed: UInt32, slot: Int, salt: UInt64) -> Float64:
    """Pure per-slot hash (slot folded into the x coordinate slot)."""
    return hash01_cells(seed, slot, 0, salt ^ _SLOT_SALT)


def _waypoint_radius(seed: UInt32, slot: Int) -> Float64:
    var u = _slot_hash(seed, slot, _SALT_RADIUS)
    return FLOCK_WAYPOINT_RADIUS + (2.0 * u - 1.0) * FLOCK_WAYPOINT_JITTER


def _waypoint_angle(seed: UInt32, slot: Int, tick: UInt32) -> Float64:
    """Per-slot orbit angle: slot base + 2π·tick/period (counter-clockwise)."""
    var base = _slot_hash(seed, slot, _SALT_WAYPOINT) * TWO_PI
    return base + TWO_PI * Float64(tick) / FLOCK_WAYPOINT_PERIOD_TICKS


def _waypoint(seed: UInt32, slot: Int, tick: UInt32) -> Tuple[Float64, Float64]:
    """Per-slot orbit waypoint (x, z) at `tick`."""
    var ang = _waypoint_angle(seed, slot, tick)
    var r = _waypoint_radius(seed, slot)
    return (r * cos(ang), r * sin(ang))


def _cruise_altitude(island: IslandSubject, x: Float64, z: Float64) -> Float64:
    """Avoidance target: surface (or ocean plane) + FLOCK_MIN_ALTITUDE."""
    var surf = island.height_at(x, z)
    if surf < SEA_LEVEL:
        surf = SEA_LEVEL
    return surf + FLOCK_MIN_ALTITUDE


def _horizontal_r(b: Bird) -> Float64:
    return sqrt(b.x * b.x + b.z * b.z)


def _dist(a: Bird, b: Bird) -> Float64:
    var dx = a.x - b.x
    var dy = a.y - b.y
    var dz = a.z - b.z
    return sqrt(dx * dx + dy * dy + dz * dz)


def _raw_respawn_state(
    seed: UInt32, island: IslandSubject, slot: Int, respawn_count: UInt32,
    tick: UInt32
) -> Tuple[Float64, Float64, Float64, Float64]:
    """Pure base placement from (seed, slot, respawn_count): position AT the
    slot's waypoint angle for `tick` (spawn starts aligned with its seek
    target — an antipodal spawn makes the bird cut across the island
    centre), radius jittered by respawn_count, altitude = surface + jitter,
    velocity along the tangent (yaw = heading). Returns (x, y, z, yaw)."""
    var c = Int(respawn_count)
    var u_r = hash01_cells(seed, slot, c, _SALT_RES_RADIUS)
    var u_alt = hash01_cells(seed, slot, c, _SALT_RES_ALT)
    var ang = _waypoint_angle(seed, slot, tick)
    var r = _waypoint_radius(seed, slot) + (2.0 * u_r - 1.0) * _RES_RADIUS_JITTER
    var x = r * cos(ang)
    var z = r * sin(ang)
    var alt = _cruise_altitude(island, x, z) + u_alt * 2.0
    # Tangent (counter-clockwise) — heading yaw = atan2(vx, vz).
    var yaw = atan2(-sin(ang), cos(ang))
    return (x, alt, z, yaw)


def _respawn_slot(
    mut flock: FlockSubject, island: IslandSubject, slot: Int, tick: UInt32
):
    """Despawn + respawn slot at the state derived from
    (seed, slot, flock.birds[slot].respawn_count) — the CALLER advances the
    count before calling (init: count stays 0; tick: count += 1). Spawn sits
    at the slot's waypoint angle for `tick`. Deterministic small angular
    offsets keep the candidate ≥ FLOCK_SEPARATION_MIN from every live
    neighbour and ≤ the bound (slot-order deterministic; see file header)."""
    var seed = flock.seed
    var count = flock.birds[slot].respawn_count
    var base = _raw_respawn_state(seed, island, slot, count, tick)
    var x = base[0]
    var y = base[1]
    var z = base[2]

    # Bounded deterministic search: step ±0.05, ±0.10, ... rad around the
    # waypoint angle until both constraints hold (or give up after 16).
    var base_ang = _waypoint_angle(seed, slot, tick)
    var u_alt = hash01_cells(seed, slot, Int(count), _SALT_RES_ALT)
    var r0 = sqrt(x * x + z * z)
    for attempt in range(_RESPAWN_TRIES):
        if attempt > 0:
            var mag = _RESPAWN_ANG_STEP * Float64((attempt + 1) // 2)
            var ang = base_ang + mag if attempt % 2 == 1 else base_ang - mag
            x = r0 * cos(ang)
            z = r0 * sin(ang)
            y = _cruise_altitude(island, x, z) + u_alt * 2.0
        var ok = True
        if sqrt(x * x + z * z) > FLOCK_BOUND_RADIUS:
            ok = False
        if ok:
            for j in range(FLOCK_N_MAX):
                if j == slot or not flock.birds[j].active:
                    continue
                var d = sqrt(
                    (x - flock.birds[j].x) ** 2
                    + (y - flock.birds[j].y) ** 2
                    + (z - flock.birds[j].z) ** 2
                )
                if d < FLOCK_SEPARATION_MIN:
                    ok = False
        if ok:
            break

    var b = flock.birds[slot]
    b.x = x
    b.y = y
    b.z = z
    # Tangent velocity at the final angle (orbit direction).
    var ang_f = atan2(z, x)
    b.vx = -sin(ang_f) * FLOCK_SPEED_CRUISE
    b.vy = 0.0
    b.vz = cos(ang_f) * FLOCK_SPEED_CRUISE
    b.yaw = atan2(b.vx, b.vz)  # heading convention = atan2(vx, vz)
    b.active = True
    flock.birds[slot] = b


def flock_from_island(island: IslandSubject, seed: UInt32) -> FlockSubject:
    """Construction: slots 0..FLOCK_N_INIT-1 active at deterministic spawn
    points (respawn_count == 0). No world mutation (0006 Sprint 01)."""
    var flock = FlockSubject()
    flock.seed = seed
    for _slot in range(FLOCK_N_MAX):
        var b = Bird()
        flock.birds.append(b)
    for slot in range(FLOCK_N_INIT):
        flock.birds[slot].active = True
        flock.count += 1
        _respawn_slot(flock, island, slot, 0)
    return flock^


def flock_tick(
    mut flock: FlockSubject, island: IslandSubject, tick: UInt32
):
    """One per-tick commit (called from sim/world.mojo). Four ordered passes
    over slots — forces from pre-tick state, integrate, hard separation
    floor, bound check + respawn — all in slot order (determinism)."""
    var n = FLOCK_N_MAX

    # --- pass 1: forces from the PRE-tick state (read-only) ----------------
    var ax = List[Float64]()
    var ay = List[Float64]()
    var az = List[Float64]()
    for _i in range(n):
        ax.append(0.0)
        ay.append(0.0)
        az.append(0.0)

    for slot in range(n):
        if not flock.birds[slot].active:
            continue
        var p = flock.birds[slot]

        # Waypoint seek.
        var wp = _waypoint(flock.seed, slot, tick)
        var ty = _cruise_altitude(island, wp[0], wp[1])
        var dx = wp[0] - p.x
        var dy = ty - p.y
        var dz = wp[1] - p.z
        var dl = sqrt(dx * dx + dy * dy + dz * dz)
        if dl > 1.0e-9:
            var ste_x = dx / dl * FLOCK_SPEED_CRUISE - p.vx
            var ste_y = dy / dl * FLOCK_SPEED_CRUISE - p.vy
            var ste_z = dz / dl * FLOCK_SPEED_CRUISE - p.vz
            ax[slot] += FLOCK_W_SEEK * ste_x
            ay[slot] += FLOCK_W_SEEK * ste_y
            az[slot] += FLOCK_W_SEEK * ste_z

        # Neighbourhood rules.
        var avg_vx = 0.0
        var avg_vy = 0.0
        var avg_vz = 0.0
        var n_align = 0
        var c_px = 0.0
        var c_py = 0.0
        var c_pz = 0.0
        var n_cohere = 0
        for other in range(n):
            if other == slot or not flock.birds[other].active:
                continue
            var o = flock.birds[other]
            var ox = p.x - o.x
            var oy = p.y - o.y
            var oz = p.z - o.z
            var d = sqrt(ox * ox + oy * oy + oz * oz)
            if d < FLOCK_ALIGN_RADIUS:
                avg_vx += o.vx
                avg_vy += o.vy
                avg_vz += o.vz
                n_align += 1
            if d < FLOCK_COHERE_RADIUS:
                c_px += o.x
                c_py += o.y
                c_pz += o.z
                n_cohere += 1
            if d < FLOCK_SEPARATE_RADIUS and d > 1.0e-9:
                # Push away, strongest at contact, zero at the radius edge.
                var k = FLOCK_W_SEPARATE * (1.0 - d / FLOCK_SEPARATE_RADIUS) / d
                ax[slot] += ox * k
                ay[slot] += oy * k
                az[slot] += oz * k

        if n_align > 0:
            var f = Float64(n_align)
            ax[slot] += FLOCK_W_ALIGN * (avg_vx / f - p.vx)
            ay[slot] += FLOCK_W_ALIGN * (avg_vy / f - p.vy)
            az[slot] += FLOCK_W_ALIGN * (avg_vz / f - p.vz)
        if n_cohere > 0:
            var f = Float64(n_cohere)
            var gx = c_px / f - p.x
            var gy = c_py / f - p.y
            var gz = c_pz / f - p.z
            var gl = sqrt(gx * gx + gy * gy + gz * gz)
            if gl > 1.0e-9:
                ax[slot] += FLOCK_W_COHERE * (
                    gx / gl * FLOCK_SPEED_CRUISE - p.vx
                )
                ay[slot] += FLOCK_W_COHERE * (
                    gy / gl * FLOCK_SPEED_CRUISE - p.vy
                )
                az[slot] += FLOCK_W_COHERE * (
                    gz / gl * FLOCK_SPEED_CRUISE - p.vz
                )

        # Terrain / ocean avoidance: spring toward cruise altitude.
        var alt_t = _cruise_altitude(island, p.x, p.z)
        ay[slot] += FLOCK_W_AVOID * (alt_t - p.y)
        if p.y > FLOCK_MAX_ALTITUDE:
            ay[slot] -= FLOCK_W_AVOID * (p.y - FLOCK_MAX_ALTITUDE)

    # --- pass 2: integrate in slot order (speed clamp, yaw) ----------------
    for slot in range(n):
        if not flock.birds[slot].active:
            continue
        var b = flock.birds[slot]
        b.vx += ax[slot] * FIXED_DT
        b.vy += ay[slot] * FIXED_DT
        b.vz += az[slot] * FIXED_DT
        var sp = sqrt(b.vx * b.vx + b.vy * b.vy + b.vz * b.vz)
        if sp > FLOCK_SPEED_MAX:
            var k = FLOCK_SPEED_MAX / sp
            b.vx *= k
            b.vy *= k
            b.vz *= k
        elif sp < FLOCK_SPEED_MIN and sp > 1.0e-9:
            var k = FLOCK_SPEED_MIN / sp
            b.vx *= k
            b.vy *= k
            b.vz *= k
        b.x += b.vx * FIXED_DT
        b.y += b.vy * FIXED_DT
        b.z += b.vz * FIXED_DT
        b.yaw = atan2(b.vx, b.vz)
        flock.birds[slot] = b

    # --- pass 3: hard separation floor (slot order, i < j) -----------------
    for i in range(n):
        if not flock.birds[i].active:
            continue
        for j in range(i + 1, n):
            if not flock.birds[j].active:
                continue
            var a = flock.birds[i]
            var b = flock.birds[j]
            var dx = b.x - a.x
            var dy = b.y - a.y
            var dz = b.z - a.z
            var d = sqrt(dx * dx + dy * dy + dz * dz)
            if d >= FLOCK_SEPARATION_MIN:
                continue
            var ux = 1.0
            var uy = 0.0
            var uz = 0.0
            if d > 1.0e-9:
                ux = dx / d
                uy = dy / d
                uz = dz / d
            var push = (FLOCK_SEPARATION_MIN - d) * 0.5
            a.x -= ux * push
            a.y -= uy * push
            a.z -= uz * push
            b.x += ux * push
            b.y += uy * push
            b.z += uz * push
            flock.birds[i] = a
            flock.birds[j] = b

    # --- pass 4: bound check + deterministic respawn (slot order) ----------
    for slot in range(n):
        if not flock.birds[slot].active:
            continue
        var b = flock.birds[slot]
        var out_of_bound = (
            _horizontal_r(b) > FLOCK_BOUND_RADIUS
            or b.y > FLOCK_MAX_ALTITUDE
            or b.y < SEA_LEVEL + 1.0
        )
        if out_of_bound:
            flock.birds[slot].respawn_count += 1
            _respawn_slot(flock, island, slot, tick)


def flock_wire(flock: FlockSubject) -> List[FlockBird]:
    """§11 wire projection: active slots in ascending slot order (deterministic)."""
    var out = List[FlockBird]()
    for slot in range(FLOCK_N_MAX):
        var b = flock.birds[slot]
        if not b.active:
            continue
        out.append(
            FlockBird(
                Float32(b.x),
                Float32(b.y),
                Float32(b.z),
                Float32(b.yaw),
                0,  # FLOCK_SEABIRD_SPECIES
            )
        )
    return out^


def flock_speed(b: Bird) -> Float64:
    return sqrt(b.vx * b.vx + b.vy * b.vy + b.vz * b.vz)


def flock_horizontal_r(b: Bird) -> Float64:
    return _horizontal_r(b)
