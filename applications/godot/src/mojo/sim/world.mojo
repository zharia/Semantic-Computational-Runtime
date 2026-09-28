# World — commit metadata + fixed-timestep integration (Sprint 01).
#
# Owns (milestone spec §3.1): world_version / state_generation /
# simulation_tick / simulation_time and the five subjects (player, hydro,
# atmosphere, volcano — milestone 0003, catalog). Fixed tick 60 Hz;
# frame dt clamped to 0.05 s (104_contract §6). Determinism: same seed +
# same input sequence + dt = 1/60 per call ⇒ identical state trajectory.
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
    atmosphere_from_time,
    player_tick,
)
from sim.volcano import VolcanoSubject, volcano_from_island, volcano_tick
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
    var atmosphere: AtmosphereSubject
    var volcano: VolcanoSubject
    var catalog: MaterialCatalog

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
        self.atmosphere = AtmosphereSubject()
        self.volcano = VolcanoSubject()
        self.catalog = MaterialCatalog(List[MaterialDef](), "")

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
    world.atmosphere = atmosphere_from_time(0.0)
    # Volcano: geometry from the island's CALDERA_LAKE columns, then the
    # tick-0 state draw (seeded effusion schedule) + glow at the initial sky.
    world.volcano = volcano_from_island(world.island)
    volcano_tick(world.volcano, world.seed, world.simulation_tick, world.atmosphere)
    world.world_version = 1  # first generation
    world.state_generation = 0
    world.simulation_tick = 0
    world.simulation_time = 0.0
    world.accumulator = 0.0
    return world^


def tick_world(mut world: World, input: InputBatch):
    """Execute exactly one fixed tick (dt = 1/60)."""
    player_tick(world.player, input, world.island, world.hydro, world.simulation_time)
    world.simulation_tick += 1
    world.simulation_time = Float64(world.simulation_tick) * FIXED_DT
    world.state_generation += 1
    world.atmosphere = atmosphere_from_time(world.simulation_time)
    # Volcano state is a pure function of (seed, tick, atmosphere) — AP-12.
    volcano_tick(world.volcano, world.seed, world.simulation_tick, world.atmosphere)


def step_world(mut world: World, frame_dt: Float64, input: InputBatch) -> Int32:
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
        for j in range(len(c.indices)):
            h = _fold_u64(h, UInt64(c.indices[j]))
    for i in range(len(world.island.used_materials)):
        h = _fold_u64(h, UInt64(world.island.used_materials[i]))

    # Ocean + atmosphere + catalog identity.
    h = _fold_f64(h, world.hydro.ocean.sea_level)
    h = _fold_f64(h, world.hydro.ocean.wave.amplitude)
    h = _fold_f64(h, world.hydro.ocean.wave.wavenumber)
    h = _fold_f64(h, world.hydro.ocean.wave.steepness)
    h = _fold_f64(h, world.hydro.ocean.wave.omega)
    h = _fold_f64(h, world.atmosphere.time_of_day_hours)
    h = _fold_f64(h, world.atmosphere.sun_elevation)

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

    h = _fold_str(h, world.catalog.root)
    for i in range(world.catalog.count()):
        var d = world.catalog.defs[i].copy()
        h = _fold_str(h, d.catalog_id)
        h = _fold_u64(h, UInt64(d.catalog_index))
    return h
