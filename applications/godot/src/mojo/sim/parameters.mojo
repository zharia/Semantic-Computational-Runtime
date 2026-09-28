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

# --- Atmosphere-lite (SCR-LIB-RENDER-SKY, minimal diurnal arc) -------------
# 12:00 start: sun in the south (+Z-normal-facing slopes get direct light at
# the spawn view), max intensity sin(1.2)=0.93 vs sin(0.849)=0.75 at 09:00.
comptime TIME_OF_DAY_START_HOURS: Float64 = 12.0
comptime SECONDS_PER_SIM_HOUR: Float64 = 100.0  # full day = 2400 sim seconds
comptime FOG_DENSITY: Float64 = 0.0045  # exp² fog: ~17% at 100u, ~71% at 250u
comptime FOG_COLOR_R: Float64 = 0.58    # cool blue haze (terrain stays legible)
comptime FOG_COLOR_G: Float64 = 0.66
comptime FOG_COLOR_B: Float64 = 0.78
comptime SUN_INTENSITY_NOON: Float64 = 1.0
comptime SUN_ELEVATION_MAX: Float64 = 1.2    # rad, peak elevation of the diurnal arc

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
comptime SCHEMA_VERSION: UInt32 = 2  # 1 → 2: +VOLCANO(7), +PLUME(8) (0003 §3.5)
comptime ABI_VERSION: UInt32 = 1

# --- Error codes (scr_godot_abi.h) ----------------------------------------
comptime SCR_ERR_NOT_INIT: Int32 = -1
comptime SCR_ERR_ABI_MISMATCH: Int32 = -2
comptime SCR_ERR_BUF_SMALL: Int32 = -3
comptime SCR_ERR_BAD_STATE: Int32 = -4
