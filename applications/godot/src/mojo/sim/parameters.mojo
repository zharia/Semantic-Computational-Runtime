# AP-7 parameter table — the single home for every simulation tunable.
#
# Normative source for locomotion values: providers/render/graphics/godot/
# 104_contract.md §6 (mirrored in applications/godot/docs/04_simulation_engine.md).
# Scene-generation values are milestone_0002 spec parameters (Sprint 01).
# Nothing outside this file may hard-code a tunable.

# --- Timestep (104_contract §6 / §3) ---------------------------------------
comptime TICK_RATE_HZ: Int = 60
comptime FIXED_DT: Float64 = 1.0 / 60.0
comptime FRAME_DT_CLAMP: Float64 = 0.05

# --- Locomotion (104_contract §6, all units documented there) --------------
comptime WALK_SPEED: Float64 = 4.25          # u/s
comptime SPRINT_SPEED: Float64 = 8.0         # u/s
comptime JUMP_VELOCITY: Float64 = 5.8        # u/s
comptime GRAVITY: Float64 = -10.0            # u/s^2
comptime PITCH_CLAMP: Float64 = 1.45         # rad (±)
comptime EYE_HEIGHT: Float64 = 1.7           # u (standing)
comptime SWIM_SPEED_FACTOR: Float64 = 0.65   # × walk/sprint while submerged
comptime MOUSE_SENSITIVITY: Float64 = 0.0025 # rad per input unit (AP-7)

# --- Terrain / island synthesis (milestone_0002 Sprint 01) -----------------
comptime SEA_LEVEL: Float64 = 0.0            # u, water datum (y = 0)
comptime GRID_N: Int = 64                    # cells per side of height field
comptime CELL_SIZE: Float64 = 4.0            # u per cell
comptime ISLAND_RADIUS: Float64 = 96.0       # u, radial falloff reaches 0 here
comptime PEAK_HEIGHT: Float64 = 44.0         # u, summit above sea level
comptime CALDERA_RIM_RADIUS: Float64 = 26.0  # u, rim ring radius
comptime CALDERA_RIM_WIDTH: Float64 = 7.0    # u, rim ring sigma
comptime CALDERA_RIM_BUMP: Float64 = 6.0     # u, rim lift above base profile
comptime CALDERA_FLOOR: Float64 = 4.0        # u, crater floor above sea level
comptime OCEAN_FLOOR_DEPTH: Float64 = 18.0   # u, seabed depth at map edge
comptime HEIGHT_DETAIL_AMP: Float64 = 7.0    # u, fBm detail amplitude
comptime RIDGE_DETAIL_AMP: Float64 = 5.0     # u, ridged detail on slopes
comptime TERRAIN_CHUNK_CELLS: Int = 16       # cells per chunk edge
comptime SHALLOW_WATER_DEPTH: Float64 = 6.0  # u, DEEP_OCEAN |SHALLOW_WATER| cut
comptime BEACH_BAND_HEIGHT: Float64 = 1.5    # u, land at/below this height = BEACH
comptime CALDERA_LAKE_RADIUS: Float64 = 20.0  # u, r < this ⇒ CALDERA_LAKE
comptime CALDERA_RIM_OUTER_RADIUS: Float64 = 34.0  # u, r ≥ this ⇒ outside rim
comptime SPAWN_BEACH_OFFSET: Float64 = 1.25  # target beach height band center (u)
comptime SPAWN_SEARCH_RADIUS_MIN: Float64 = 56.0  # u, spawn stays inside the island
comptime SPAWN_SEARCH_RADIUS_MAX: Float64 = 94.0  # u, spawn stays above waterline
comptime LATTICE_Y_OFFSET: Float64 = 24.0   # lattice y = world y + 24 (y=0 bedrock
                                             # ⇒ world y=-24; sea level ⇒ lattice 24)
comptime SUBSURFACE_BAND_CELLS: Int = 4     # cells below surface counted "sub-surface"

# --- Noise (SCR-LIB-MATH-NOISE §2: octaves/lacunarity/gain defaults) ------
comptime NOISE_OCTAVES: Int = 5
comptime NOISE_LACUNARITY: Float64 = 2.0
comptime NOISE_GAIN: Float64 = 0.5
comptime NOISE_BASE_FREQUENCY: Float64 = 0.012  # cycles per world unit
comptime RIDGE_OCTAVES: Int = 4

# --- Ocean (SCR-LIB-MATH-GERSTNER; OCEAN section fields) -------------------
# Phase speed c is NOT a free tunable: §2.1 fixes the deep-water dispersion
# relation c = sqrt(g/k) with g = |GRAVITY| (same units). Q chosen so the
# Jacobian can actually cross the §2.3 whitecap threshold (Q*k*A = 0.39 ⇒
# J_min = 1 - Q*k*A = 0.61 < 0.65) while keeping the §3.2 steepness bound
# Q*k*A <= 1.0 and the §2.1 requirement Q ∈ [0,1].
comptime WAVE_AMPLITUDE: Float64 = 0.55      # u
comptime WAVE_WAVELENGTH: Float64 = 8.0      # u (λ ⇒ k = 2π/λ ≈ 0.785 rad/u)
comptime WAVE_STEEPNESS: Float64 = 0.9       # Q (unitless, §2.1)
comptime WAVE_DIRECTION_X: Float64 = 0.8     # (0.8, 0.6) already unit length
comptime WAVE_DIRECTION_Z: Float64 = 0.6
comptime FOAM_JACOBIAN_THRESHOLD: Float64 = 0.65   # §2.3 J < 0.65 ⇒ whitecap
comptime FOAM_HEIGHT_THRESHOLD: Float64 = 0.7      # §2.3 normalized height > 0.7

# --- Day cycle (SCR-LIB-RENDER-SKY, diurnal arc; milestone_0004) -----------
# 12:00 start: max intensity sin(1.2)=0.93 vs sin(0.849)=0.75 at 09:00.
comptime TIME_OF_DAY_START_HOURS: Float64 = 12.0
comptime SECONDS_PER_SIM_HOUR: Float64 = 100.0  # full day = 2400 sim seconds
comptime SUN_INTENSITY_NOON: Float64 = 1.0
comptime SUN_ELEVATION_MAX: Float64 = 1.2    # rad, peak elevation of the diurnal arc

# Solar azimuth law (milestone_0004 §1.1 locked "spawn-facing arc"):
#   azimuth(h, spawn_yaw) = spawn_yaw + PI + PI * (h - 12) / 12   [radians]
# sun horizontal direction = (sin azimuth, cos azimuth) (world frame, §801).
# h = 06:00 ⇒ azimuth = facing - PI/2, 12:00 ⇒ facing, 18:00 ⇒ facing + PI/2,
# so the whole daytime arc sits inside the spawn-facing hemisphere.
# `spawn_yaw` is the player's spawn yaw (atan2(spawn_x, spawn_z), world.mojo);
# the legacy single-argument atmosphere path uses SUN_SPAWN_YAW_DEFAULT.
comptime SUN_SPAWN_YAW_DEFAULT: Float64 = 0.0
comptime SUN_PI: Float64 = 3.141592653589793
comptime SUN_TWO_PI: Float64 = 6.283185307179586
# Energy tier factor: golden-hour dimming below the horizon up to full energy
# at the NOON tier edge (SUN_ELEVATION_NOON_DEG); values at 09/12/15 keep the
# schema-1 intensity (factor 1.0 there).
comptime SUN_ENERGY_HORIZON: Float64 = 0.75
comptime SUN_ELEVATION_NOON_DEG: Float64 = 45.0

# --- Diurnal palette tiers (SCR-LIB-RENDER-SKY §2; milestone_0004) ---------
# Elevation knots (degrees; converted to radians in sim/subjects.mojo).
# Tier precedence on the spec's overlapping ranges: NIGHT < -10°,
# SUNSET [-10°,-5°] anchor, DAWN [0°,15°] constant (dawn wins over the
# sunset/dawn overlap [0°,10°]), NOON >= 45°. Between knots the palette is
# linearly interpolated ⇒ continuous everywhere (test_envelope/atmosphere).
comptime SKY_ELEV_NIGHT_DEG: Float64 = -10.0
comptime SKY_ELEV_SUNSET_DEG: Float64 = -5.0
comptime SKY_ELEV_DAWN_LOW_DEG: Float64 = 0.0
comptime SKY_ELEV_GOLDEN_DEG: Float64 = 10.0
comptime SKY_ELEV_DAWN_HIGH_DEG: Float64 = 15.0
comptime SKY_ELEV_WARM_DEG: Float64 = 25.0
comptime SKY_ELEV_NOON_DEG: Float64 = 45.0
# Sky gradient — zenith (top of the dome), per tier.
comptime SKY_ZENITH_NIGHT_R: Float64 = 0.008   # §2 night "deep cosmic navy"
comptime SKY_ZENITH_NIGHT_G: Float64 = 0.012
comptime SKY_ZENITH_NIGHT_B: Float64 = 0.035
comptime SKY_ZENITH_SUNSET_R: Float64 = 0.20   # §2 sunset violet
comptime SKY_ZENITH_SUNSET_G: Float64 = 0.10
comptime SKY_ZENITH_SUNSET_B: Float64 = 0.38
comptime SKY_ZENITH_DAWN_R: Float64 = 0.08     # §2 dawn indigo-blue zenith
comptime SKY_ZENITH_DAWN_G: Float64 = 0.18
comptime SKY_ZENITH_DAWN_B: Float64 = 0.42
comptime SKY_ZENITH_NOON_R: Float64 = 0.18     # §2 azure noon zenith
comptime SKY_ZENITH_NOON_G: Float64 = 0.48
comptime SKY_ZENITH_NOON_B: Float64 = 0.92
# Sky gradient — horizon (base of the dome), per tier.
comptime SKY_HORIZON_NIGHT_R: Float64 = 0.015  # night horizon (dim navy)
comptime SKY_HORIZON_NIGHT_G: Float64 = 0.020
comptime SKY_HORIZON_NIGHT_B: Float64 = 0.050
comptime SKY_HORIZON_SUNSET_R: Float64 = 0.85  # §2 deep crimson horizon
comptime SKY_HORIZON_SUNSET_G: Float64 = 0.25
comptime SKY_HORIZON_SUNSET_B: Float64 = 0.12
comptime SKY_HORIZON_DAWN_R: Float64 = 1.00    # §2 fiery orange-pink horizon
comptime SKY_HORIZON_DAWN_G: Float64 = 0.48
comptime SKY_HORIZON_DAWN_B: Float64 = 0.15
comptime SKY_HORIZON_NOON_R: Float64 = 0.62    # §2 luminous translucent cyan base
comptime SKY_HORIZON_NOON_G: Float64 = 0.80
comptime SKY_HORIZON_NOON_B: Float64 = 0.95
# Sun color by elevation (§2 intent: crimson → golden → white; night reuses
# the night navy — the night intensity gate is 0 anyway).
comptime SUN_COLOR_NIGHT_R: Float64 = 0.008
comptime SUN_COLOR_NIGHT_G: Float64 = 0.012
comptime SUN_COLOR_NIGHT_B: Float64 = 0.035
comptime SUN_COLOR_LOW_R: Float64 = 0.95      # crimson low sun (sunset knot)
comptime SUN_COLOR_LOW_G: Float64 = 0.38
comptime SUN_COLOR_LOW_B: Float64 = 0.18
comptime SUN_COLOR_RISING_R: Float64 = 1.00   # fiery rising sun (0°)
comptime SUN_COLOR_RISING_G: Float64 = 0.55
comptime SUN_COLOR_RISING_B: Float64 = 0.22
comptime SUN_COLOR_GOLDEN_R: Float64 = 1.00   # golden hour (10°)
comptime SUN_COLOR_GOLDEN_G: Float64 = 0.78
comptime SUN_COLOR_GOLDEN_B: Float64 = 0.50
comptime SUN_COLOR_WARM_R: Float64 = 1.00     # warm white (25°)
comptime SUN_COLOR_WARM_G: Float64 = 0.93
comptime SUN_COLOR_WARM_B: Float64 = 0.82
comptime SUN_COLOR_NOON_R: Float64 = 1.00     # crisp white (>= 45°)
comptime SUN_COLOR_NOON_G: Float64 = 0.98
comptime SUN_COLOR_NOON_B: Float64 = 0.95

# --- Fog derivation (milestone_0004 §1.1 locked; AP-7 / AP-17) -------------
# fog_density = BASE + COEF_CLOUD·C + COEF_PRECIP·P + COEF_BIAS·fog_bias
#               + COEF_NIGHT·night_factor(elevation)     [all coefficients > 0]
# ⇒ strictly increasing in cloud_cover and in precipitation (test-enforced).
comptime FOG_DENSITY_BASE: Float64 = 0.0030  # clear day baseline (~12% @ 100u)
comptime FOG_COEF_CLOUD: Float64 = 0.0030    # +0.0030 at C = 1
comptime FOG_COEF_PRECIP: Float64 = 0.0040   # +0.0040 at P = 1
comptime FOG_COEF_BIAS: Float64 = 0.0010     # +0.0010 at profile fog_bias = 1
comptime FOG_COEF_NIGHT: Float64 = 0.0015    # +0.0015 at night saturation
# fog_color = lerp(lerp(CLEAR, STORM, w), NIGHT, night·NIGHT_MIX),
#   w = min(1, C·CLOUD_MIX + P·PRECIP_MIX)  (per channel, same w)
comptime FOG_COLOR_R: Float64 = 0.58         # clear-sky haze (terrain legible)
comptime FOG_COLOR_G: Float64 = 0.66
comptime FOG_COLOR_B: Float64 = 0.78
comptime FOG_COLOR_STORM_R: Float64 = 0.40   # overcast/rain gray
comptime FOG_COLOR_STORM_G: Float64 = 0.44
comptime FOG_COLOR_STORM_B: Float64 = 0.50
comptime FOG_COLOR_NIGHT_R: Float64 = 0.05   # night haze
comptime FOG_COLOR_NIGHT_G: Float64 = 0.07
comptime FOG_COLOR_NIGHT_B: Float64 = 0.13
comptime FOG_COLOR_CLOUD_MIX: Float64 = 0.60
comptime FOG_COLOR_PRECIP_MIX: Float64 = 0.70
comptime FOG_COLOR_NIGHT_MIX: Float64 = 0.85

# --- Weather state machine (503_Simulation/Environment/Weather §3;
#     milestone_0004 §3.3 — core subset of 3 profiles) ----------------------
# One seeded draw per WEATHER_TRANSITION_TICK_STEP ticks; the profile tuple
# Hermite-blends (S3 = 3ξ² − 2ξ³) from the previous draw to the new one over
# WEATHER_BLEND_TICKS ticks, then holds. AP-12: draws are counter-based
# (splitmix64), never unseeded; AP-15: driven by simulation_time only.
comptime WEATHER_TRANSITION_TICK_STEP: Int = 1800  # 30 s @ 60 Hz
comptime WEATHER_BLEND_TICKS: Int = 900            # Δt_trans = 15 s @ 60 Hz
# Profile 0 — CLEAR_TROPICAL_SUN
comptime WEATHER_CLEAR_CLOUD: Float64 = 0.15
comptime WEATHER_CLEAR_PRECIP: Float64 = 0.0
comptime WEATHER_CLEAR_WIND_X: Float64 = 1.6   # u/s, world frame
comptime WEATHER_CLEAR_WIND_Z: Float64 = 1.0
comptime WEATHER_CLEAR_FOG_BIAS: Float64 = 0.0
# Profile 1 — OVERCAST_STRATUS
comptime WEATHER_OVERCAST_CLOUD: Float64 = 0.88
comptime WEATHER_OVERCAST_PRECIP: Float64 = 0.0
comptime WEATHER_OVERCAST_WIND_X: Float64 = 3.2
comptime WEATHER_OVERCAST_WIND_Z: Float64 = 2.4
comptime WEATHER_OVERCAST_FOG_BIAS: Float64 = 0.45
# Profile 2 — TROPICAL_MONSOON (rain)
comptime WEATHER_MONSOON_CLOUD: Float64 = 0.97
comptime WEATHER_MONSOON_PRECIP: Float64 = 0.8   # 0..1 intensity (§3.2)
comptime WEATHER_MONSOON_WIND_X: Float64 = 6.5
comptime WEATHER_MONSOON_WIND_Z: Float64 = 4.8
comptime WEATHER_MONSOON_FOG_BIAS: Float64 = 0.85
# Wetness: rises with precipitation, decays once it stops (§3.2 field 16).
comptime WETNESS_RISE_RATE: Float64 = 0.15   # 1/s at precipitation = 1
comptime WETNESS_DECAY_RATE: Float64 = 0.01  # 1/s dry-out after the rain
# Wind evolution: profile wind is Hermite-smoothed (world frame) and modulated
# by a seeded-phase gust; |wind| stays < WIND_MAX_SPEED (test-enforced).
comptime WIND_GUST_FRACTION: Float64 = 0.18
comptime WIND_GUST_PERIOD_TICKS: Float64 = 960.0  # 16 s gust period
comptime WIND_MAX_SPEED: Float64 = 12.0            # u/s range guard
# Cloud plane altitude (SCR-LIB-MATH-ATMOSPHERE §3 low-deck cumulus band
# 150–550 m; the display cloud plane sits at the deck mid-point).
comptime CLOUD_PLANE_ALTITUDE: Float64 = 400.0  # m above sea level

# --- Material derivation (SCR-LIB-RENDER-MATERIAL, catalog → snapshot) ----
# emissive_rgb = albedo_rgb * saturate(emission_cd_m2 / SATURATION);
# saturation = fluid.lava's emission (the catalog maximum) at load time.
comptime MATERIAL_EMISSION_SATURATION: Float64 = 25000.0

# --- Volcano / lava lake + plume (milestone_0003 spec §5; SCR-LIB-RENDER-VOLCANO)
# Crust-factor radiance (Volcano §2.1): L = (1−C)·E_core + C·E_crust with the
# normative colors core (1.0, 0.72, 0.12) / crust (0.12, 0.04, 0.02). The
# snapshot carries the scalar energy; E_core/E_crust below are the brightest
# (red) channel of each color. Effusion draws from a seeded PRNG stream once
# per EFFUSION_TICK_STEP ticks (AP-12: no unseeded RNG).
comptime LAVA_EMISSIVE_CORE: Float64 = 1.0     # scalar of E_core (bright channel)
comptime LAVA_EMISSIVE_CRUST: Float64 = 0.12   # scalar of E_crust (bright channel)
comptime LAVA_CRUST_DORMANT: Float64 = 0.85    # crust fraction C at state 0
comptime LAVA_CRUST_EFFUSING: Float64 = 0.15   # crust fraction C at state 1
comptime EFFUSION_TICK_STEP: Int = 300         # ticks between draws (5 s @ 60 Hz)
comptime EFFUSION_ACTIVE_PROBABILITY: Float64 = 0.35  # P(effusing) per draw
comptime PLUME_RATE_DORMANT: Float64 = 0.0     # rate 0 ⇒ idle emitter (§3.2)
comptime PLUME_RATE_EFFUSING: Float64 = 60.0   # emission rate while effusing (1/s)
comptime PLUME_VELOCITY: Float64 = 8.5         # u/s, w0 (Volcano §2.2)
comptime PLUME_SPREAD: Float64 = 15.0          # deg, emission cone half-angle
comptime PLUME_TURBULENCE: Float64 = 0.35      # turbulence amount (display noise)
comptime PLUME_LIFETIME: Float64 = 6.0         # s, particle lifetime (> 0)
comptime GLOW_NIGHT_MAX_FACTOR: Float64 = 1.0  # night_factor cap
comptime GLOW_NIGHT_ELEVATION_REF: Float64 = SUN_ELEVATION_MAX  # saturates here
comptime VOLCANO_LAKE_RADIUS_FALLBACK: Float64 = CALDERA_LAKE_RADIUS  # no lake cells

# --- Snapshot contract constants (104_contract §4) -------------------------
comptime SNAPSHOT_MAGIC: UInt32 = 0x53524353
comptime SCHEMA_VERSION: UInt32 = 3  # 2 → 3: SKY 32 → 64 B, 16×f32 (0004 §3.5)
comptime ABI_VERSION: UInt32 = 1

# --- Error codes (scr_godot_abi.h) ----------------------------------------
comptime SCR_ERR_NOT_INIT: Int32 = -1
comptime SCR_ERR_ABI_MISMATCH: Int32 = -2
comptime SCR_ERR_BUF_SMALL: Int32 = -3
comptime SCR_ERR_BAD_STATE: Int32 = -4
