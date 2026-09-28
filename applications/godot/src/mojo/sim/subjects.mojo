# Simulation subjects (Sprint 01): PlayerSubject locomotion, HydrologySubject
# (Gerstner state over the ocean), AtmosphereSubject-lite (diurnal arc).
# Milestone 0003 Sprint 01 adds night_factor — the pure sun-elevation →
# night factor used by VolcanoSubject's crater glow (104_contract §4.3
# VOLCANO.glow_intensity).
#
# Locomotion parameters come from sim/parameters.mojo ONLY (AP-7):
# walk 4.25, sprint 8.0, jump 5.8, gravity −10, pitch ±1.45, eye 1.7,
# swim 0.65×, mouse-look 0.0025 rad/unit, fixed dt = 1/60.
#
# Dispatch: sim/input.mojo build_input_table produces the fixed row order;
# apply_input_event is the single applier (AP-5: no scattered if/else chain
# across the frame path — one table loop, one switch).

from std.math import sin, cos, atan2, sqrt, floor
from sim.parameters import (
    WALK_SPEED,
    SPRINT_SPEED,
    JUMP_VELOCITY,
    GRAVITY,
    PITCH_CLAMP,
    EYE_HEIGHT,
    SWIM_SPEED_FACTOR,
    MOUSE_SENSITIVITY,
    FIXED_DT,
    SEA_LEVEL,
    TIME_OF_DAY_START_HOURS,
    SECONDS_PER_SIM_HOUR,
    SUN_ELEVATION_MAX,
    SUN_INTENSITY_NOON,
    GRID_N,
    CELL_SIZE,
    GLOW_NIGHT_MAX_FACTOR,
    GLOW_NIGHT_ELEVATION_REF,
)
from sim.input import (
    InputBatch,
    InputEvent,
    build_input_table,
    ACT_MOVE,
    ACT_LOOK,
    ACT_JUMP,
    ACT_SPRINT,
    ACT_PRIMARY,
    ACT_SECONDARY,
)
from sim.island import IslandSubject
from ocean.gerstner import OceanState, wave_height

comptime SWIM_GRAVITY_FACTOR: Float64 = 0.3  # reduced sink while swimming
comptime SWIM_JUMP_FACTOR: Float64 = 0.5  # jump acts as swim-up boost
comptime SWIM_VERTICAL_DAMP: Float64 = 0.9  # vertical damping in water
comptime MAP_BOUND: Float64 = 126.0  # keep the player inside the height grid


struct PlayerSubject(Movable, Deinitable):
    var x: Float64
    var y: Float64  # feet position
    var z: Float64
    var vel_x: Float64
    var vel_y: Float64
    var vel_z: Float64
    var yaw: Float64  # radians, 0 = facing −Z (Godot convention)
    var pitch: Float64  # radians, clamped ±1.45
    var on_ground: Bool
    var in_water: Bool

    def __init__(out self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.vel_x = 0.0
        self.vel_y = 0.0
        self.vel_z = 0.0
        self.yaw = 0.0
        self.pitch = 0.0
        self.on_ground = True
        self.in_water = False

    def __deinit__(deinit self):
        pass


struct HydrologySubject(Movable, Deinitable):
    """Authoritative sim-side water: sea level + Gerstner vertical height."""
    var ocean: OceanState

    def __init__(out self, ocean: OceanState):
        self.ocean = ocean

    def __deinit__(deinit self):
        pass

    def surface_height(self, x: Float64, z: Float64, t: Float64) -> Float64:
        return wave_height(self.ocean, x, z, t)


struct AtmosphereSubject(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Minimal diurnal arc (SCR-LIB-RENDER-SKY): hours + sun angles."""
    var time_of_day_hours: Float64
    var sun_azimuth: Float64
    var sun_elevation: Float64
    var sun_intensity: Float64

    def __init__(out self):
        self.time_of_day_hours = TIME_OF_DAY_START_HOURS
        self.sun_azimuth = 0.0
        self.sun_elevation = 0.0
        self.sun_intensity = 0.0

    def __deinit__(deinit self):
        pass


def atmosphere_from_time(sim_time: Float64) -> AtmosphereSubject:
    """Pure projection of sim time → sky state (deterministic)."""
    var out = AtmosphereSubject()
    var hours = TIME_OF_DAY_START_HOURS + sim_time / SECONDS_PER_SIM_HOUR
    hours = hours - floor(hours / 24.0) * 24.0
    if hours < 0.0:
        hours += 24.0
    out.time_of_day_hours = hours
    # Elevation: sine arc, peak SUN_ELEVATION_MAX at 12:00, zero at 06/18.
    var day_phase = (hours - 6.0) / 12.0  # 0 at 06:00, 1 at 18:00
    out.sun_elevation = SUN_ELEVATION_MAX * sin(3.141592653589793 * day_phase)
    # Azimuth: rotates 2π over 24h (east at dawn → south at noon → west).
    out.sun_azimuth = 6.283185307179586 * (hours / 24.0)
    var intensity = 0.0
    if out.sun_elevation > 0.0:
        intensity = SUN_INTENSITY_NOON * sin(out.sun_elevation)
    out.sun_intensity = intensity
    return out^


def night_factor(sun_elevation: Float64) -> Float64:
    """Pure night factor for the crater glow (milestone_0003 §3.3):
    glow_intensity = emissive_intensity · night_factor(sun_elevation).

    0 while the sun is at/above the horizon; rises linearly with depth below
    the horizon to GLOW_NIGHT_MAX_FACTOR at −GLOW_NIGHT_ELEVATION_REF rad,
    clamped there. Pure function of AtmosphereSubject.sun_elevation only —
    no wall clock, no display input (AP-11 / AP-12)."""
    if sun_elevation >= 0.0:
        return 0.0
    if GLOW_NIGHT_ELEVATION_REF <= 0.0:
        return GLOW_NIGHT_MAX_FACTOR
    var f = -sun_elevation / GLOW_NIGHT_ELEVATION_REF
    if f > GLOW_NIGHT_MAX_FACTOR:
        return GLOW_NIGHT_MAX_FACTOR
    if f < 0.0:
        return 0.0
    return f


# ---------------------------------------------------------------------------
# Input dispatch (table-driven, single applier)
# ---------------------------------------------------------------------------

struct MoveIntent(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var move_x: Float64
    var move_y: Float64
    var sprint: Bool
    var jump: Bool
    var yaw_delta: Float64   # world yaw delta, left-positive (device x negated)
    var pitch_delta: Float64  # world pitch delta, up-positive (device y as-is)

    def __init__(out self):
        self.move_x = 0.0
        self.move_y = 0.0
        self.sprint = False
        self.jump = False
        self.yaw_delta = 0.0
        self.pitch_delta = 0.0

    def __deinit__(deinit self):
        pass


def collect_intent(events: List[InputEvent]) -> MoveIntent:
    """Fold the dispatch table into one per-tick intent.

    Table order (sim/input.mojo): MOVE, LOOK, JUMP, SPRINT, PRIMARY,
    SECONDARY. PRIMARY/SECONDARY are placeholders for successor-milestone
    actions — consumed here so every row has exactly one owner."""
    var intent = MoveIntent()
    for i in range(len(events)):
        var e = events[i]
        if e.action == ACT_MOVE:
            intent.move_x = Float64(e.value_x)
            intent.move_y = Float64(e.value_y)
        elif e.action == ACT_LOOK:
            # Device look deltas are device-space: value_x > 0 = mouse/look
            # RIGHT, value_y > 0 = mouse/look DOWN. World yaw is defined
            # left-positive/CCW (yaw 0 faces -Z, +yaw turns left), so the
            # horizontal delta is the one coordinate frame that needs a sign
            # flip: look right (dx > 0) must DECREASE yaw. Pitch already
            # agrees (look down => pitch falls), so it passes through.
            intent.yaw_delta = -Float64(e.value_x)
            intent.pitch_delta = Float64(e.value_y)
        elif e.action == ACT_JUMP:
            intent.jump = e.flag != 0
        elif e.action == ACT_SPRINT:
            intent.sprint = e.flag != 0
        elif e.action == ACT_PRIMARY:
            _ = e.flag  # successor milestone (hotbar/editing)
        elif e.action == ACT_SECONDARY:
            _ = e.flag  # successor milestone
    return intent^


# ---------------------------------------------------------------------------
# One fixed tick of player locomotion
# ---------------------------------------------------------------------------

def player_tick(
    mut player: PlayerSubject,
    input: InputBatch,
    island: IslandSubject,
    hydro: HydrologySubject,
    sim_time: Float64,
):
    """Advance the player by one fixed tick (dt = 1/60, AP-7 table)."""
    var events = build_input_table(input)
    var intent = collect_intent(events)

    # Look: intent deltas are already device->world mapped by collect_intent
    # (yaw negated: device right-positive, world yaw left-positive), then
    # scaled by MOUSE_SENSITIVITY (AP-7; recorded deviation vs 104_contract
    # §5 'radians' wording — see final report).
    # Invariant: yaw positive = left/CCW; mouse right (look_dx > 0) DECREASES
    # yaw, mouse down (look_dy > 0) DECREASES pitch.
    player.yaw += intent.yaw_delta * MOUSE_SENSITIVITY
    player.pitch -= intent.pitch_delta * MOUSE_SENSITIVITY
    if player.pitch > PITCH_CLAMP:
        player.pitch = PITCH_CLAMP
    if player.pitch < -PITCH_CLAMP:
        player.pitch = -PITCH_CLAMP

    # Water state (feet vs authoritative sim-side surface height).
    var water_h = hydro.surface_height(player.x, player.z, sim_time)
    player.in_water = player.y < water_h

    # Horizontal wish direction (yaw about +Y, 0 ⇒ −Z forward).
    var fwd_x = -sin(player.yaw)
    var fwd_z = -cos(player.yaw)
    var right_x = cos(player.yaw)
    var right_z = -sin(player.yaw)
    var wish_x = fwd_x * intent.move_y + right_x * intent.move_x
    var wish_z = fwd_z * intent.move_y + right_z * intent.move_x
    # Clamp the stick vector length to 1 (diagonal never faster).
    var wish_len = sqrt(wish_x * wish_x + wish_z * wish_z)
    if wish_len > 1.0:
        wish_x /= wish_len
        wish_z /= wish_len

    var speed = WALK_SPEED
    if intent.sprint:
        speed = SPRINT_SPEED
    if player.in_water:
        speed *= SWIM_SPEED_FACTOR
    player.vel_x = wish_x * speed
    player.vel_z = wish_z * speed

    # Vertical.
    var dt = FIXED_DT
    if player.in_water:
        player.vel_y += GRAVITY * SWIM_GRAVITY_FACTOR * dt
        player.vel_y *= SWIM_VERTICAL_DAMP
        if intent.jump:
            player.vel_y = JUMP_VELOCITY * SWIM_JUMP_FACTOR
    else:
        player.vel_y += GRAVITY * dt
        if intent.jump and player.on_ground:
            player.vel_y = JUMP_VELOCITY

    # Integrate.
    player.x += player.vel_x * dt
    player.z += player.vel_z * dt
    player.y += player.vel_y * dt

    # World bounds (height grid domain, half-extent 128 minus one cell).
    if player.x > MAP_BOUND:
        player.x = MAP_BOUND
    if player.x < -MAP_BOUND:
        player.x = -MAP_BOUND
    if player.z > MAP_BOUND:
        player.z = MAP_BOUND
    if player.z < -MAP_BOUND:
        player.z = -MAP_BOUND

    # Ground clamp against the terrain field (sim-side authoritative).
    var ground = island.height_at(player.x, player.z)
    if player.y <= ground:
        player.y = ground
        if player.vel_y < 0.0:
            player.vel_y = 0.0
        player.on_ground = True
    else:
        player.on_ground = False
    # Standing in a crater-lake/lava pool: floor is still terrain; lava is
    # terrain surface material, not a physics volume (successor milestone).
    _ = SEA_LEVEL
