# VolcanoSubject — sim-owned caldera lava lake + plume emission parameters
# (milestone_0003 spec §3.1 / §5 Sprint 01; SCR-LIB-RENDER-VOLCANO is a
# spec-only contract — implemented here in Mojo per definition, CORE subset
# only: crater lake scalars + plume emission parameters, spec §4 row).
#
# Authority split (AP-11 / §6 invariant 3): every lava/plume STATE field
# lives here and reaches the scene only through the VOLCANO/PLUME snapshot
# sections. Godot/shader hold representation only (spatial crust pattern and
# per-particle integration are display-only).
#
# Determinism (AP-12 / §6 invariant 2): all state is a pure function of
# (World.seed, simulation_tick, island geometry, AtmosphereSubject). The
# effusion state machine draws from a counter-based PRNG stream seeded from
# World.seed on a fixed schedule — once per EFFUSION_TICK_STEP ticks — so
# there is no unseeded randomness and no wall clock anywhere in this file.
#
# Out of scope here (spec §9): Bingham lava flow/rivers, crust tearing
# field, vortex-curl billow advection, wind-advected ash dispersion, and
# eruption events (Rule 10: no event semantics defined yet).
# `lava_water_quench` = documented partial (AP-14): no reaction evaluator is
# implemented in this milestone.
#
# Plume kinematics consumed as emission parameters (spec §4): w0 ≈ 8.5 m/s →
# PLUME_VELOCITY; R(z)/billow fields stay display-side (GPU integrates the
# particles — §1.1 locked decision).

from std.collections import List
from std.math import sqrt

from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    SEA_LEVEL,
    LAVA_EMISSIVE_CORE,
    LAVA_EMISSIVE_CRUST,
    LAVA_CRUST_DORMANT,
    LAVA_CRUST_EFFUSING,
    EFFUSION_TICK_STEP,
    EFFUSION_ACTIVE_PROBABILITY,
    PLUME_RATE_DORMANT,
    PLUME_RATE_EFFUSING,
    PLUME_VELOCITY,
    PLUME_SPREAD,
    PLUME_TURBULENCE,
    PLUME_LIFETIME,
    VOLCANO_LAKE_RADIUS_FALLBACK,
)
from sim.island import IslandSubject
from sim.subjects import AtmosphereSubject, night_factor
from synthesis.noise import splitmix64
from synthesis.voxel import BIOME_CALDERA_LAKE


struct VolcanoSubject(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Caldera lava lake + convective plume state (104_contract §4.3 §7/§8).

    VOLCANO section source: center_x, center_z, radius, lake_level,
    emissive_intensity, crust_fraction, glow_intensity, effusion_state.
    PLUME section source: plume_origin_{x,y,z}, plume_rate,
    plume_initial_velocity, plume_spread, plume_turbulence, plume_lifetime.
    """

    var center_x: Float64  # world-frame caldera center (lake centroid)
    var center_z: Float64
    var radius: Float64  # lava lake radius, u (> 0)
    var lake_level: Float64  # lava surface height, world y
    var emissive_intensity: Float64  # scalar radiance energy (> 0)
    var crust_fraction: Float64  # C ∈ [0,1] (Volcano §2.1)
    var effusion_state: UInt8  # 0 dormant, 1 effusing (locked, §3.2)
    var glow_intensity: Float64  # emissive × night_factor (§3.3)
    var plume_origin_x: Float64  # world-frame emission origin (§801 spatial)
    var plume_origin_y: Float64
    var plume_origin_z: Float64
    var plume_rate: Float64  # 0 ⇒ idle emitter (§3.2)
    var plume_initial_velocity: Float64  # u/s (w0, Volcano §2.2)
    var plume_spread: Float64  # deg
    var plume_turbulence: Float64  # amount, display-side noise
    var plume_lifetime: Float64  # s (> 0)

    def __init__(out self):
        self.center_x = 0.0
        self.center_z = 0.0
        self.radius = 0.0
        self.lake_level = 0.0
        self.emissive_intensity = 0.0
        self.crust_fraction = 0.0
        self.effusion_state = 0
        self.glow_intensity = 0.0
        self.plume_origin_x = 0.0
        self.plume_origin_y = 0.0
        self.plume_origin_z = 0.0
        self.plume_rate = 0.0
        self.plume_initial_velocity = 0.0
        self.plume_spread = 0.0
        self.plume_turbulence = 0.0
        self.plume_lifetime = 0.0

    def __deinit__(deinit self):
        pass


# --- Effusion state machine (AP-12: seeded, fixed schedule only) -----------

comptime _EFFUSION_MIX_A: UInt64 = 0x9E3779B97F4A7C15
comptime _EFFUSION_MIX_B: UInt64 = 0xD1B54A32D192ED03
comptime _EFFUSION_MIX_C: UInt64 = 0x85EBCA77C2B2AE63
comptime _TWO_POW_53: Float64 = 9007199254740992.0  # 2^53


def effusion_draw(seed: UInt32, draw_index: UInt32) -> UInt8:
    """One draw of the effusion state machine: 1 (effusing) or 0 (dormant).

    Counter-based splitmix64 stream seeded from World.seed: draw i uses
    splitmix64(seed·A + i·B + C), maps the top 53 bits to u ∈ [0,1), and
    returns 1 iff u < EFFUSION_ACTIVE_PROBABILITY. Pure function of
    (seed, draw_index) — order-independent, no mutable PRNG state, no wall
    clock. Draw schedule: draw index = simulation_tick // EFFUSION_TICK_STEP,
    i.e. exactly one draw per EFFUSION_TICK_STEP ticks (spec §3.3)."""
    var s = (
        UInt64(seed) * _EFFUSION_MIX_A
        + UInt64(draw_index) * _EFFUSION_MIX_B
        + _EFFUSION_MIX_C
    )
    var x = splitmix64(s)
    var u = Float64(x >> 11) / _TWO_POW_53  # 53-bit mantissa → [0, 1)
    if u < EFFUSION_ACTIVE_PROBABILITY:
        return 1
    return 0


# --- Construction + per-tick update ----------------------------------------


def volcano_from_island(island: IslandSubject) raises -> VolcanoSubject:
    """Geometry + plume constants derived from the island's CALDERA_LAKE
    terrain columns (synthesis/voxel BIOME_CALDERA_LAKE; world-frame
    positions per §801_SPATIAL-INV-002):

      center = centroid of CALDERA_LAKE column centers (island center/caldera)
      radius = max column distance from that centroid
      lake level = mean column height (crater floor)

    Plume origin is the world-frame lake surface position (center, level).
    State fields (effusion/emissive/crust/glow/rate) are filled by
    volcano_tick — world_init calls it at tick 0 with the initial
    AtmosphereSubject. Fallback (no CALDERA_LAKE column — unreachable for
    the volcanic profile): center (0,0), radius from the parameter table."""
    var v = VolcanoSubject()
    var n = 0
    var sx = 0.0
    var sz = 0.0
    var sh = 0.0
    var cells = List[Int]()
    for i in range(len(island.biomes)):
        if island.biomes[i] != BIOME_CALDERA_LAKE:
            continue
        var ix = i % GRID_N
        var iz = i // GRID_N
        var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
        var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
        cells.append(i)
        sx += wx
        sz += wz
        sh += island.heights[i]
        n += 1
    if n > 0:
        v.center_x = sx / Float64(n)
        v.center_z = sz / Float64(n)
        v.lake_level = sh / Float64(n)
        var max_r = 0.0
        for k in range(len(cells)):
            var i = cells[k]
            var ix = i % GRID_N
            var iz = i // GRID_N
            var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
            var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
            var dx = wx - v.center_x
            var dz = wz - v.center_z
            var r = sqrt(dx * dx + dz * dz)
            if r > max_r:
                max_r = r
        v.radius = max_r
        if v.radius <= 0.0:
            v.radius = VOLCANO_LAKE_RADIUS_FALLBACK
        if v.lake_level < SEA_LEVEL:
            v.lake_level = SEA_LEVEL
    else:
        v.center_x = 0.0
        v.center_z = 0.0
        v.radius = VOLCANO_LAKE_RADIUS_FALLBACK
        v.lake_level = SEA_LEVEL
    # Plume emission origin + constant emission parameters (spec §4 row:
    # w(z), R(z) represented as emission parameters where representable).
    v.plume_origin_x = v.center_x
    v.plume_origin_y = v.lake_level  # world-frame lake surface, above sea level
    v.plume_origin_z = v.center_z
    v.plume_initial_velocity = PLUME_VELOCITY
    v.plume_spread = PLUME_SPREAD
    v.plume_turbulence = PLUME_TURBULENCE
    v.plume_lifetime = PLUME_LIFETIME
    return v^


def volcano_tick(
    mut volcano: VolcanoSubject,
    seed: UInt32,
    simulation_tick: UInt32,
    atmosphere: AtmosphereSubject,
):
    """One fixed tick of volcano state — pure function of
    (seed, simulation_tick, atmosphere); idempotent for equal inputs.

    Effusion draw schedule: the state is recomputed from draw index
    simulation_tick // EFFUSION_TICK_STEP at every tick, so a draw effectively
    happens once per EFFUSION_TICK_STEP ticks (ticks
    k·EFFUSION_TICK_STEP, k = 0, 1, 2, …) and is held in between.

    Effusion → rate mapping (spec §3.2 "if rate == 0 the emitter is idle"):
      state 1 (effusing) ⇒ plume_rate = PLUME_RATE_EFFUSING (active plume)
      state 0 (dormant)  ⇒ plume_rate = PLUME_RATE_DORMANT = 0 (idle emitter)
    """
    var draw_index = simulation_tick // UInt32(EFFUSION_TICK_STEP)
    var state = effusion_draw(seed, draw_index)
    volcano.effusion_state = state
    if state == 1:
        volcano.crust_fraction = LAVA_CRUST_EFFUSING
        volcano.plume_rate = PLUME_RATE_EFFUSING
    else:
        volcano.crust_fraction = LAVA_CRUST_DORMANT
        volcano.plume_rate = PLUME_RATE_DORMANT

    # Crust-factor radiance (Volcano §2.1): L = (1−C)·E_core + C·E_crust.
    # Colors (core (1.0,0.72,0.12) / crust (0.12,0.04,0.02)) are carried by
    # the material catalog and rendered by the shader; the snapshot carries
    # the scalar energy of that blend (bright channel of each color).
    volcano.emissive_intensity = (
        (1.0 - volcano.crust_fraction) * LAVA_EMISSIVE_CORE
        + volcano.crust_fraction * LAVA_EMISSIVE_CRUST
    )

    # Crater glow: emissive × night factor from the existing AtmosphereSubject
    # (§3.3 locked decision — adapter must never derive "night" itself).
    volcano.glow_intensity = (
        volcano.emissive_intensity * night_factor(atmosphere.sun_elevation)
    )
