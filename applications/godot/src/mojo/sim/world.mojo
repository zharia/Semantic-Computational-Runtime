# World — commit metadata + fixed-timestep integration (Sprint 01).
#
# Owns (milestone spec §3.1): world_version / state_generation /
# simulation_tick / simulation_time and the six subjects (player, hydro,
# weather, atmosphere, volcano — milestone 0004 adds weather; 0003 volcano,
# catalog). Fixed tick 60 Hz; frame dt clamped to 0.05 s (104_contract §6).
# Determinism: same seed + same input sequence + dt = 1/60 per call ⇒
# identical state trajectory.
#
# The world never knows about snapshots; snapshot/ projects it read-only
# (projection purity invariant).

from std.math import atan2, floor

from sim.parameters import FIXED_DT, FRAME_DT_CLAMP, TICK_RATE_HZ
from sim.input import InputBatch, idle_input
from sim.island import IslandSubject, build_island, TerrainChunk
from sim.subjects import (
    PlayerSubject,
    HydrologySubject,
    AtmosphereSubject,
    atmosphere_from_weather,
    player_tick,
)
from sim.volcano import VolcanoSubject, volcano_from_island, volcano_tick
from sim.shore import compute_foam_field
from sim.flora import (
    FloraSubject,
    flora_from_island,
    flora_re_evaluate,
    flora_tick,
    flora_survival,
)
from sim.edit import EditQueue, edit_queue_init, consume_one_edit
from sim.hotbar import HotbarSubject, hotbar_init
from sim.props import PhysicsSubject, props_from_island, props_tick
from sim.flock import FlockSubject, flock_from_island, flock_tick
from weather.state import WeatherSubject, weather_tick
from ocean.gerstner import make_ocean, OceanState
from materials.catalog import MaterialCatalog, MaterialDef, load_catalog
from synthesis.noise import splitmix64


struct World(Movable, Deinitable):
    var seed: UInt32
    var determinism_epoch: UInt32  # fixed per init; changes only on reseed
    var world_version: UInt32  # increments on (re)generation; 1 at init
    var state_generation: UInt32  # increments every committed tick
    var simulation_tick: UInt32  # fixed-tick counter
    var simulation_time: Float64  # tick * (1/60)
    var accumulator: Float64  # fractional seconds toward the next tick
    var island: IslandSubject
    var player: PlayerSubject
    var hydro: HydrologySubject
    var weather: WeatherSubject  # milestone_0004: seeded weather machine
    var atmosphere: AtmosphereSubject
    var volcano: VolcanoSubject
    var catalog: MaterialCatalog
    var foam: List[Float32]  # GRID_N² shore foam (§3.3; f32, row-major)
    var flora: FloraSubject  # milestone_0006: flora population (sim locus)
    var flock: FlockSubject  # milestone_0006: seabird flock (sim locus)
    # milestone_0007: sim-owned edit authority + display state.
    var edit_queue: EditQueue  # scr_edit_submit FIFO (one op per tick)
    var hotbar: HotbarSubject  # selection = sim state (AP-13)
    var props: PhysicsSubject  # rigid props (≤ PROP_N_MAX)

    def __init__(out self, seed: UInt32):
        self.seed = seed
        self.determinism_epoch = 0
        self.world_version = 0
        self.state_generation = 0
        self.simulation_tick = 0
        self.simulation_time = 0.0
        self.accumulator = 0.0
        self.island = IslandSubject(seed)
        self.player = PlayerSubject()
        self.hydro = HydrologySubject(make_ocean())
        self.weather = WeatherSubject()
        self.atmosphere = AtmosphereSubject()
        self.volcano = VolcanoSubject()
        self.catalog = MaterialCatalog(List[MaterialDef](), "")
        self.foam = List[Float32]()
        self.flora = FloraSubject()
        self.flock = FlockSubject()
        self.edit_queue = edit_queue_init()
        self.hotbar = HotbarSubject()
        self.props = PhysicsSubject()

    def __deinit__(deinit self):
        pass


def world_init(seed: UInt32) raises -> World:
    """Create the world: catalog load + island synthesis + spawn placement."""
    var world = World(seed)
    world.determinism_epoch = UInt32(splitmix64(UInt64(seed)) & 0xFFFFFFFF)
    world.catalog = load_catalog()
    world.island = build_island(seed)
    world.hydro = HydrologySubject(make_ocean())
    var player = PlayerSubject()
    player.x = world.island.spawn_x
    player.y = world.island.spawn_y
    player.z = world.island.spawn_z
    # Spawn faces the island center (forward = (-sin yaw, -cos yaw));
    # yaw = atan2(spawn_x, spawn_z) points the player from spawn to (0, 0).
    player.yaw = atan2(world.island.spawn_x, world.island.spawn_z)
    player.on_ground = True
    player.in_water = False
    world.player = player^
    # Weather (milestone_0004): seeded machine committed at tick 0 (dt = 0 ⇒
    # no wetness drift on the initial state). AP-12: seed only, no wall clock.
    world.weather = WeatherSubject()
    weather_tick(world.weather, world.seed, 0, 0.0)
    # Spawn-facing arc: yaw points the player from spawn to (0, 0); the sun
    # azimuth law is anchored on that facing direction (0004 §1.1 lock).
    var spawn_yaw = atan2(world.island.spawn_x, world.island.spawn_z)
    world.atmosphere = atmosphere_from_weather(0.0, world.weather, spawn_yaw)
    # Volcano: geometry from the island's CALDERA_LAKE columns, then the
    # tick-0 state draw (seeded effusion schedule) + glow at the initial sky.
    world.volcano = volcano_from_island(world.island)
    volcano_tick(world.volcano, world.seed, world.simulation_tick, world.atmosphere)
    # Shore foam field (§3.3): computed at init from (island, ocean, t=0).
    world.foam = compute_foam_field(
        world.island.heights, world.hydro.ocean, world.simulation_time
    )
    # Ecology (milestone_0006 Sprint 01 / 0009 Sprint 02): flora scatter is
    # a pure function of (seed, island, declared environment); flock spawns
    # from (seed, island). Construction only — no runtime mutation of these
    # two outside flock_tick / flora_survival below. Establishment gets the
    # committed crater geometry + weather wetness as EXPLICIT inputs
    # (EVOLUTION-INV-011): volcano and weather are initialized above.
    world.flora = flora_from_island(
        world.island,
        world.seed,
        world.volcano.center_x,
        world.volcano.center_z,
        world.weather.wetness,
    )
    world.flock = flock_from_island(world.island, world.seed)
    # milestone_0007: hotbar slot table resolved against the catalog (loud
    # if any id fails — invariant 5), rigid props at deterministic beach
    # anchors, empty edit FIFO.
    world.hotbar = hotbar_init(world.catalog)
    world.props = props_from_island(world.island, world.catalog)
    world.edit_queue = edit_queue_init()
    world.world_version = 1  # first generation
    world.state_generation = 0
    world.simulation_tick = 0
    world.simulation_time = 0.0
    world.accumulator = 0.0
    return world^


def tick_world(mut world: World, input: InputBatch) raises:
    """Execute exactly one fixed tick (dt = 1/60)."""
    player_tick(world.player, input, world.island, world.hydro, world.simulation_time)
    # Edit FIFO: pop at most ONE op per fixed tick against this tick's pose
    # (0007 §3.2). Applied ⇒ world_version bump + flora recompute so every
    # downstream projection sees a consistent generation (AP-8 one-way).
    var edit_out = consume_one_edit(
        world.island,
        world.edit_queue,
        world.hotbar,
        world.catalog,
        world.player.x,
        world.player.y,
        world.player.z,
        world.player.yaw,
        world.player.pitch,
    )
    if edit_out.applied:
        world.world_version += 1
        # Field re-evaluation (0009 R1): survivors keep age + grown scale,
        # new establishments enter at a0/s0, dead drop same pass. Strategy =
        # FULL row-major re-scan (0009 R5 allows affected columns or full —
        # measure + document choice): measured ~70–130 µs/call on the 64×64
        # grid at pop 154 (test_flora_growth perf probe) vs an affected-
        # column bookkeeping structure — full rescan wins on simplicity at
        # this grid size (≤1 edit tick ⇒ ≤130 µs/tick of 16.6 ms budget).
        # Environmental inputs (EVOLUTION-INV-011): crater geometry is static
        # and wetness is THIS world's previously committed weather state (the
        # edit hook runs before the weather advance below) — explicit, not
        # derived inside the flora scan.
        world.flora = flora_re_evaluate(
            world.island,
            world.flora,
            world.seed,
            world.volcano.center_x,
            world.volcano.center_z,
            world.weather.wetness,
        )
    # Rigid props: gravity + ground contact, ascending slot order (§3.5).
    props_tick(world.props, world.island, FIXED_DT)
    world.simulation_tick += 1
    world.simulation_time = Float64(world.simulation_tick) * FIXED_DT
    world.state_generation += 1
    # Weather first (SIM time + seed only, AP-15): it feeds the atmosphere
    # derivation (cloud cover / precipitation / wind → fog + palette inputs).
    weather_tick(world.weather, world.seed, world.simulation_tick, FIXED_DT)
    var spawn_yaw = atan2(world.island.spawn_x, world.island.spawn_z)
    world.atmosphere = atmosphere_from_weather(
        world.simulation_time, world.weather, spawn_yaw
    )
    # Volcano state is a pure function of (seed, tick, atmosphere) — AP-12.
    volcano_tick(world.volcano, world.seed, world.simulation_tick, world.atmosphere)
    # Flora survival selection (0009 Sprint 02 / R3, EVOLUTION-INV-005):
    # recompute every anchor's local stress from THIS tick's committed
    # weather wetness + the static crater geometry and drop the instances
    # whose tolerances no longer cover it — dead removed same tick (cap
    # never violated, AP-22 / spec §6 invariant 5). Full recompute every
    # tick (no amortization; O(count), documented in flora_survival).
    # Pure given state ⇒ run-twice identical deaths (R6 / INV-018); tick
    # phase ONLY (projection purity, spec §6 invariant 7).
    flora_survival(
        world.flora,
        world.volcano.center_x,
        world.volcano.center_z,
        world.weather.wetness,
    )
    # Shore foam (§3.3): pure function of (island heights, ocean, sim time) —
    # recomputed once per committed tick so the projection stays read-only.
    world.foam = compute_foam_field(
        world.island.heights, world.hydro.ocean, world.simulation_time
    )
    # Seabird flock: one ordered commit per fixed tick (0006 §1.1 — rules
    # listed there; deterministic in (seed, tick, island)).
    flock_tick(world.flock, world.island, world.simulation_tick)
    # Flora growth (0009 R2/R3): +1 age/instance, ε-quantized scale snap —
    # tick phase ONLY (projection purity: the §10 projection reads state
    # read-only after this commit). 0010 R4: this call also advances each
    # instance's developmental stage (stage_for_age over the new age —
    # quantized, monotone, 0..STAGE_MAX); variant_seed is establishment-
    # time state, never recomputed here.
    flora_tick(world.flora)


def step_world(mut world: World, frame_dt: Float64, input: InputBatch) raises -> Int32:
    """Accumulate frame_dt (clamped to 0.05 s), run 0..n fixed ticks.
    The input batch is applied to EVERY tick executed by this call.
    Returns the number of ticks run (>= 0)."""
    var dt = frame_dt
    if dt > FRAME_DT_CLAMP:
        dt = FRAME_DT_CLAMP
    if dt < 0.0:
        dt = 0.0
    world.accumulator += dt
    # Ticks due, with an epsilon so dt = 1/60 (not exact in binary) always
    # yields exactly one tick per call (determinism contract, 104_contract §3).
    var due = floor(world.accumulator * Float64(TICK_RATE_HZ) + 1.0e-9)
    var n = Int(due)
    if n < 0:
        n = 0
    if n > 1000:
        n = 1000  # safety rail (unreachable for dt <= 0.05)
    world.accumulator -= Float64(n) * FIXED_DT
    if world.accumulator < 0.0:
        world.accumulator = 0.0
    for _ in range(n):
        tick_world(world, input)
    return Int32(n)


# ---------------------------------------------------------------------------
# World fingerprint (projection purity test support — read-only)
# ---------------------------------------------------------------------------

def _fold_byte(h: UInt64, b: UInt8) -> UInt64:
    return (h ^ UInt64(b)) * 1099511628211  # FNV-1a 64-bit


def _fold_u64(h: UInt64, v: UInt64) -> UInt64:
    var acc = h
    for i in range(8):
        acc = _fold_byte(acc, UInt8((v >> UInt64(i * 8)) & 0xFF))
    return acc


def _fold_f64(h: UInt64, v: Float64) -> UInt64:
    return _fold_u64(h, UInt64(v.to_bits()))


def _fold_f32(h: UInt64, v: Float32) -> UInt64:
    return _fold_u64(h, UInt64(v.to_bits()))


def _fold_str(h: UInt64, s: String) -> UInt64:
    var acc = h
    for b in s.bytes():
        acc = _fold_byte(acc, b)
    return acc


def world_fingerprint(world: World) -> UInt64:
    """FNV-1a 64-bit hash over the complete world state.
    Used by the projection-purity test: hashing before and after a snapshot
    projection must produce the same value (world unmodified)."""
    var h: UInt64 = 0xCBF29CE484222325  # FNV offset basis
    h = _fold_u64(h, UInt64(world.seed))
    h = _fold_u64(h, UInt64(world.determinism_epoch))
    h = _fold_u64(h, UInt64(world.world_version))
    h = _fold_u64(h, UInt64(world.state_generation))
    h = _fold_u64(h, UInt64(world.simulation_tick))
    h = _fold_f64(h, world.simulation_time)
    h = _fold_f64(h, world.accumulator)

    # Player.
    h = _fold_f64(h, world.player.x)
    h = _fold_f64(h, world.player.y)
    h = _fold_f64(h, world.player.z)
    h = _fold_f64(h, world.player.vel_x)
    h = _fold_f64(h, world.player.vel_y)
    h = _fold_f64(h, world.player.vel_z)
    h = _fold_f64(h, world.player.yaw)
    h = _fold_f64(h, world.player.pitch)
    h = _fold_byte(h, UInt8(1 if world.player.on_ground else 0))
    h = _fold_byte(h, UInt8(1 if world.player.in_water else 0))

    # Island grids + spawn + meshes.
    var n = len(world.island.heights)
    h = _fold_u64(h, UInt64(n))
    for i in range(n):
        h = _fold_f64(h, world.island.heights[i])
        h = _fold_u64(h, UInt64(world.island.biomes[i]))
        h = _fold_u64(h, UInt64(world.island.surface_materials[i]))
    h = _fold_f64(h, world.island.spawn_x)
    h = _fold_f64(h, world.island.spawn_y)
    h = _fold_f64(h, world.island.spawn_z)
    h = _fold_f64(h, world.island.peak_height)
    h = _fold_u64(h, UInt64(world.island.chunk_count))
    for i in range(world.island.chunk_count):
        var c = world.island.chunks[i].copy()
        h = _fold_f64(h, c.origin_x)
        h = _fold_f64(h, c.origin_y)
        h = _fold_f64(h, c.origin_z)
        h = _fold_u64(h, UInt64(len(c.vertices)))
        for j in range(len(c.vertices)):
            h = _fold_f32(h, c.vertices[j])
        for j in range(len(c.normals)):
            h = _fold_f32(h, c.normals[j])
        for j in range(len(c.material_ids)):
            h = _fold_u64(h, UInt64(c.material_ids[j]))
        for j in range(len(c.blends)):
            h = _fold_u64(h, UInt64(c.blends[j].material))
            h = _fold_u64(h, UInt64(c.blends[j].blend))
            h = _fold_byte(h, c.blends[j].weight)
        for j in range(len(c.indices)):
            h = _fold_u64(h, UInt64(c.indices[j]))
    for i in range(len(world.island.used_materials)):
        h = _fold_u64(h, UInt64(world.island.used_materials[i]))

    # Ocean + atmosphere + weather + catalog identity.
    h = _fold_f64(h, world.hydro.ocean.sea_level)
    h = _fold_f64(h, world.hydro.ocean.wave.amplitude)
    h = _fold_f64(h, world.hydro.ocean.wave.wavenumber)
    h = _fold_f64(h, world.hydro.ocean.wave.steepness)
    h = _fold_f64(h, world.hydro.ocean.wave.omega)
    h = _fold_f64(h, world.atmosphere.time_of_day_hours)
    h = _fold_f64(h, world.atmosphere.sun_elevation)
    h = _fold_f64(h, world.atmosphere.sun_azimuth)
    h = _fold_f64(h, world.atmosphere.sun_intensity)
    h = _fold_f64(h, world.atmosphere.sun_color_r)
    h = _fold_f64(h, world.atmosphere.sun_color_g)
    h = _fold_f64(h, world.atmosphere.sun_color_b)
    h = _fold_f64(h, world.atmosphere.sky_zenith_r)
    h = _fold_f64(h, world.atmosphere.sky_zenith_g)
    h = _fold_f64(h, world.atmosphere.sky_zenith_b)
    h = _fold_f64(h, world.atmosphere.sky_horizon_r)
    h = _fold_f64(h, world.atmosphere.sky_horizon_g)
    h = _fold_f64(h, world.atmosphere.sky_horizon_b)
    h = _fold_f64(h, world.atmosphere.fog_density)
    h = _fold_f64(h, world.atmosphere.fog_r)
    h = _fold_f64(h, world.atmosphere.fog_g)
    h = _fold_f64(h, world.atmosphere.fog_b)
    h = _fold_f64(h, world.atmosphere.cloud_cover)
    h = _fold_f64(h, world.atmosphere.precipitation)
    h = _fold_f64(h, world.atmosphere.wind_x)
    h = _fold_f64(h, world.atmosphere.wind_z)
    h = _fold_f64(h, world.atmosphere.wetness)

    # Weather subject (milestone_0004): profile tuple, wind, wetness, profile
    # id — every field the SKY section and the fog derivation project, so a
    # mutating projection is caught by the projection-purity test.
    h = _fold_f64(h, world.weather.cloud_cover)
    h = _fold_f64(h, world.weather.precipitation)
    h = _fold_f64(h, world.weather.wind_x)
    h = _fold_f64(h, world.weather.wind_z)
    h = _fold_f64(h, world.weather.fog_bias)
    h = _fold_f64(h, world.weather.wetness)
    h = _fold_u64(h, UInt64(world.weather.profile_index))

    # Volcano subject (milestone_0003): geometry, effusion/crust/emissive,
    # glow, plume emission params. Folded so a projection that mutated any
    # volcano field would be caught by the projection-purity test.
    h = _fold_f64(h, world.volcano.center_x)
    h = _fold_f64(h, world.volcano.center_z)
    h = _fold_f64(h, world.volcano.radius)
    h = _fold_f64(h, world.volcano.lake_level)
    h = _fold_f64(h, world.volcano.emissive_intensity)
    h = _fold_f64(h, world.volcano.crust_fraction)
    h = _fold_byte(h, world.volcano.effusion_state)
    h = _fold_f64(h, world.volcano.glow_intensity)
    h = _fold_f64(h, world.volcano.plume_origin_x)
    h = _fold_f64(h, world.volcano.plume_origin_y)
    h = _fold_f64(h, world.volcano.plume_origin_z)
    h = _fold_f64(h, world.volcano.plume_rate)
    h = _fold_f64(h, world.volcano.plume_initial_velocity)
    h = _fold_f64(h, world.volcano.plume_spread)
    h = _fold_f64(h, world.volcano.plume_turbulence)
    h = _fold_f64(h, world.volcano.plume_lifetime)

    # Shore foam field (§3.3) — folded so a projection that touched it fails
    # the projection-purity test.
    h = _fold_u64(h, UInt64(len(world.foam)))
    for i in range(len(world.foam)):
        h = _fold_f32(h, world.foam[i])

    # Flora subject (milestone_0006): seed, count, every instance field —
    # folded so a projection that mutated flora fails projection purity.
    # Ages (0009 R2, SIM-side only) and trait vectors (0009 Sprint 02,
    # SIM-side only — parallel list, never on the wire) fold too: a
    # projection that ticked growth or selection must fail the same way.
    h = _fold_u64(h, UInt64(world.flora.seed))
    h = _fold_u64(h, UInt64(world.flora.count))
    for i in range(world.flora.count):
        var fi = world.flora.instances[i]
        h = _fold_f32(h, fi.x)
        h = _fold_f32(h, fi.y)
        h = _fold_f32(h, fi.z)
        h = _fold_f32(h, fi.yaw)
        h = _fold_f32(h, fi.scale)
        h = _fold_u64(h, UInt64(fi.species_id))
        if i < len(world.flora.ages):
            h = _fold_u64(h, UInt64(world.flora.ages[i]))
        if i < len(world.flora.traits):
            h = _fold_f64(h, world.flora.traits[i].ash)
            h = _fold_f64(h, world.flora.traits[i].drought)
            h = _fold_f64(h, world.flora.traits[i].reserved0)
            h = _fold_f64(h, world.flora.traits[i].reserved1)
        # Phenome state (milestone_0010, SIM-side only): developmental stage
        # + generative variant seed fold too — a projection that advanced a
        # stage or rewrote a seed must fail projection purity the same way
        # ages/traits do (invariant 8).
        if i < len(world.flora.stages):
            h = _fold_u64(h, UInt64(world.flora.stages[i]))
        if i < len(world.flora.variant_seeds):
            h = _fold_u64(h, UInt64(world.flora.variant_seeds[i]))

    # Flock subject (milestone_0006): seed, count, every slot's full state —
    # folded so a projection that mutated fauna fails projection purity.
    h = _fold_u64(h, UInt64(world.flock.seed))
    h = _fold_u64(h, UInt64(world.flock.count))
    for i in range(len(world.flock.birds)):
        var fb = world.flock.birds[i]
        h = _fold_f64(h, fb.x)
        h = _fold_f64(h, fb.y)
        h = _fold_f64(h, fb.z)
        h = _fold_f64(h, fb.vx)
        h = _fold_f64(h, fb.vy)
        h = _fold_f64(h, fb.vz)
        h = _fold_f64(h, fb.yaw)
        h = _fold_u64(h, UInt64(fb.respawn_count))
        h = _fold_byte(h, UInt8(1 if fb.active else 0))

    # Edit FIFO (0007): pending count + every pending op — folded so a
    # projection that consumed/queued edits fails projection purity.
    # (The head cursor is representation state, not semantics: two queues
    # with the same pending ops are the same queue.)
    h = _fold_u64(h, UInt64(world.edit_queue.pending()))
    for i in range(world.edit_queue.head, len(world.edit_queue.entries)):
        h = _fold_byte(h, world.edit_queue.entries[i].op)

    # Hotbar (0007 AP-13): selection + both slot tables (ids on the wire,
    # codes as the place material).
    h = _fold_u64(h, UInt64(world.hotbar.selected_index))
    h = _fold_u64(h, UInt64(len(world.hotbar.slot_ids)))
    for i in range(len(world.hotbar.slot_ids)):
        h = _fold_u64(h, UInt64(world.hotbar.slot_ids[i]))
        h = _fold_u64(h, UInt64(world.hotbar.slot_codes[i]))

    # Rigid props (0007 §3.5): count + every body field.
    h = _fold_u64(h, UInt64(world.props.count))
    for i in range(world.props.count):
        var pb = world.props.bodies[i]
        h = _fold_f64(h, pb.x)
        h = _fold_f64(h, pb.y)
        h = _fold_f64(h, pb.z)
        h = _fold_f64(h, pb.vx)
        h = _fold_f64(h, pb.vy)
        h = _fold_f64(h, pb.vz)
        h = _fold_u64(h, UInt64(pb.shape))
        h = _fold_f64(h, pb.size)
        h = _fold_u64(h, UInt64(pb.material_id))

    h = _fold_str(h, world.catalog.root)
    for i in range(world.catalog.count()):
        var d = world.catalog.defs[i].copy()
        h = _fold_str(h, d.catalog_id)
        h = _fold_u64(h, UInt64(d.catalog_index))
    return h
