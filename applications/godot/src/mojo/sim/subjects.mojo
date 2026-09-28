# Simulation subjects (Sprint 01): PlayerSubject locomotion, HydrologySubject
# (Gerstner state over the ocean), AtmosphereSubject (diurnal arc + palette +
# derived fog; milestone_0004 Sprint 01 — solar-arc fix, A01_Render/Sky tier
# palettes, fog derivation from weather state, weather inputs in SKY fields).
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
    SUN_PI,
    SUN_TWO_PI,
    SUN_SPAWN_YAW_DEFAULT,
    SUN_ENERGY_HORIZON,
    SUN_ELEVATION_NOON_DEG,
    SKY_ELEV_NIGHT_DEG,
    SKY_ELEV_SUNSET_DEG,
    SKY_ELEV_DAWN_LOW_DEG,
    SKY_ELEV_GOLDEN_DEG,
    SKY_ELEV_DAWN_HIGH_DEG,
    SKY_ELEV_WARM_DEG,
    SKY_ELEV_NOON_DEG,
    SKY_ZENITH_NIGHT_R,
    SKY_ZENITH_NIGHT_G,
    SKY_ZENITH_NIGHT_B,
    SKY_ZENITH_SUNSET_R,
    SKY_ZENITH_SUNSET_G,
    SKY_ZENITH_SUNSET_B,
    SKY_ZENITH_DAWN_R,
    SKY_ZENITH_DAWN_G,
    SKY_ZENITH_DAWN_B,
    SKY_ZENITH_NOON_R,
    SKY_ZENITH_NOON_G,
    SKY_ZENITH_NOON_B,
    SKY_HORIZON_NIGHT_R,
    SKY_HORIZON_NIGHT_G,
    SKY_HORIZON_NIGHT_B,
    SKY_HORIZON_SUNSET_R,
    SKY_HORIZON_SUNSET_G,
    SKY_HORIZON_SUNSET_B,
    SKY_HORIZON_DAWN_R,
    SKY_HORIZON_DAWN_G,
    SKY_HORIZON_DAWN_B,
    SKY_HORIZON_NOON_R,
    SKY_HORIZON_NOON_G,
    SKY_HORIZON_NOON_B,
    SUN_COLOR_NIGHT_R,
    SUN_COLOR_NIGHT_G,
    SUN_COLOR_NIGHT_B,
    SUN_COLOR_LOW_R,
    SUN_COLOR_LOW_G,
    SUN_COLOR_LOW_B,
    SUN_COLOR_RISING_R,
    SUN_COLOR_RISING_G,
    SUN_COLOR_RISING_B,
    SUN_COLOR_GOLDEN_R,
    SUN_COLOR_GOLDEN_G,
    SUN_COLOR_GOLDEN_B,
    SUN_COLOR_WARM_R,
    SUN_COLOR_WARM_G,
    SUN_COLOR_WARM_B,
    SUN_COLOR_NOON_R,
    SUN_COLOR_NOON_G,
    SUN_COLOR_NOON_B,
    FOG_DENSITY_BASE,
    FOG_COEF_CLOUD,
    FOG_COEF_PRECIP,
    FOG_COEF_BIAS,
    FOG_COEF_NIGHT,
    FOG_COLOR_R,
    FOG_COLOR_G,
    FOG_COLOR_B,
    FOG_COLOR_STORM_R,
    FOG_COLOR_STORM_G,
    FOG_COLOR_STORM_B,
    FOG_COLOR_NIGHT_R,
    FOG_COLOR_NIGHT_G,
    FOG_COLOR_NIGHT_B,
    FOG_COLOR_CLOUD_MIX,
    FOG_COLOR_PRECIP_MIX,
    FOG_COLOR_NIGHT_MIX,
    GRID_N,
    CELL_SIZE,
    GLOW_NIGHT_MAX_FACTOR,
    GLOW_NIGHT_ELEVATION_REF,
)
from weather.state import WeatherSubject
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
    """Authoritative atmosphere state (milestone_0004): diurnal arc + palette
    + derived fog + weather inputs. SKY snapshot source for fields 1..16
    (104_contract §4.3); sky_zenith/sky_horizon are sim-side palette authority
    (A01_Render/Sky §2) consumed by the adapter through the SKY fog/sun colors
    (§3.4) — no second arc or palette formula exists anywhere else (AP-16)."""

    var time_of_day_hours: Float64
    var sun_azimuth: Float64
    var sun_elevation: Float64
    var sun_intensity: Float64
    var sun_color_r: Float64
    var sun_color_g: Float64
    var sun_color_b: Float64
    var sky_zenith_r: Float64
    var sky_zenith_g: Float64
    var sky_zenith_b: Float64
    var sky_horizon_r: Float64
    var sky_horizon_g: Float64
    var sky_horizon_b: Float64
    var fog_density: Float64  # derived (0004 §1.1), not a display literal
    var fog_r: Float64  # derived fog color
    var fog_g: Float64
    var fog_b: Float64
    var cloud_cover: Float64  # from WeatherSubject, 0..1
    var precipitation: Float64  # from WeatherSubject, 0..1
    var wind_x: Float64  # u/s, world frame
    var wind_z: Float64
    var wetness: Float64  # accumulated surface wetness, 0..1

    def __init__(out self):
        self.time_of_day_hours = TIME_OF_DAY_START_HOURS
        self.sun_azimuth = 0.0
        self.sun_elevation = 0.0
        self.sun_intensity = 0.0
        self.sun_color_r = 0.0
        self.sun_color_g = 0.0
        self.sun_color_b = 0.0
        self.sky_zenith_r = 0.0
        self.sky_zenith_g = 0.0
        self.sky_zenith_b = 0.0
        self.sky_horizon_r = 0.0
        self.sky_horizon_g = 0.0
        self.sky_horizon_b = 0.0
        self.fog_density = 0.0
        self.fog_r = 0.0
        self.fog_g = 0.0
        self.fog_b = 0.0
        self.cloud_cover = 0.0
        self.precipitation = 0.0
        self.wind_x = 0.0
        self.wind_z = 0.0
        self.wetness = 0.0

    def __deinit__(deinit self):
        pass


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
# Color + interpolation primitives (pure; every constant is AP-7 parameters)
# ---------------------------------------------------------------------------

struct Color3(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Linear RGB triple used by the sim-side sky/sun/fog palettes."""

    var r: Float64
    var g: Float64
    var b: Float64

    def __init__(out self):
        self.r = 0.0
        self.g = 0.0
        self.b = 0.0

    def __deinit__(deinit self):
        pass


def _lerp(a: Float64, b: Float64, t: Float64) -> Float64:
    return a + (b - a) * t


def _seg(x: Float64, x0: Float64, x1: Float64) -> Float64:
    """Normalized, clamped position of x inside [x0, x1]."""
    if x <= x0:
        return 0.0
    if x >= x1:
        return 1.0
    return (x - x0) / (x1 - x0)


def _clamp01(x: Float64) -> Float64:
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return x


def _deg(sun_elevation: Float64) -> Float64:
    return sun_elevation * 180.0 / SUN_PI


# ---------------------------------------------------------------------------
# Diurnal palette tiers (SCR-LIB-RENDER-SKY §2) — continuous by construction
# ---------------------------------------------------------------------------

def _tier_channel(
    e_deg: Float64,
    night: Float64,
    sunset: Float64,
    dawn: Float64,
    noon: Float64,
) -> Float64:
    """Piecewise-linear tier blend shared by zenith and horizon colors.
    Knots (parameters.mojo): ≤ −10° night, −5° sunset, 0..15° dawn (constant),
    ≥ 45° noon; linear between knots ⇒ continuous at every tier boundary."""
    if e_deg <= SKY_ELEV_NIGHT_DEG:
        return night
    if e_deg <= SKY_ELEV_SUNSET_DEG:
        return _lerp(night, sunset, _seg(e_deg, SKY_ELEV_NIGHT_DEG, SKY_ELEV_SUNSET_DEG))
    if e_deg <= SKY_ELEV_DAWN_LOW_DEG:
        return _lerp(sunset, dawn, _seg(e_deg, SKY_ELEV_SUNSET_DEG, SKY_ELEV_DAWN_LOW_DEG))
    if e_deg <= SKY_ELEV_DAWN_HIGH_DEG:
        return dawn
    if e_deg <= SKY_ELEV_NOON_DEG:
        return _lerp(dawn, noon, _seg(e_deg, SKY_ELEV_DAWN_HIGH_DEG, SKY_ELEV_NOON_DEG))
    return noon


def _sun_channel(
    e_deg: Float64,
    night: Float64,
    low: Float64,
    rising: Float64,
    golden: Float64,
    warm: Float64,
    noon: Float64,
) -> Float64:
    """Piecewise-linear sun-color blend: night → crimson (−5°) → fiery (0°)
    → golden (10°) → warm white (25°) → crisp white (≥ 45°). Linear between
    knots ⇒ continuous at every tier boundary."""
    if e_deg <= SKY_ELEV_NIGHT_DEG:
        return night
    if e_deg <= SKY_ELEV_SUNSET_DEG:
        return _lerp(night, low, _seg(e_deg, SKY_ELEV_NIGHT_DEG, SKY_ELEV_SUNSET_DEG))
    if e_deg <= SKY_ELEV_DAWN_LOW_DEG:
        return _lerp(low, rising, _seg(e_deg, SKY_ELEV_SUNSET_DEG, SKY_ELEV_DAWN_LOW_DEG))
    if e_deg <= SKY_ELEV_GOLDEN_DEG:
        return _lerp(rising, golden, _seg(e_deg, SKY_ELEV_DAWN_LOW_DEG, SKY_ELEV_GOLDEN_DEG))
    if e_deg <= SKY_ELEV_WARM_DEG:
        return _lerp(golden, warm, _seg(e_deg, SKY_ELEV_GOLDEN_DEG, SKY_ELEV_WARM_DEG))
    if e_deg <= SKY_ELEV_NOON_DEG:
        return _lerp(warm, noon, _seg(e_deg, SKY_ELEV_WARM_DEG, SKY_ELEV_NOON_DEG))
    return noon


def sky_zenith_color(sun_elevation: Float64) -> Color3:
    """Sky-dome zenith color (A01_Render/Sky §2 tiers) from sun elevation."""
    var e = _deg(sun_elevation)
    var c = Color3()
    c.r = _tier_channel(
        e, SKY_ZENITH_NIGHT_R, SKY_ZENITH_SUNSET_R, SKY_ZENITH_DAWN_R, SKY_ZENITH_NOON_R
    )
    c.g = _tier_channel(
        e, SKY_ZENITH_NIGHT_G, SKY_ZENITH_SUNSET_G, SKY_ZENITH_DAWN_G, SKY_ZENITH_NOON_G
    )
    c.b = _tier_channel(
        e, SKY_ZENITH_NIGHT_B, SKY_ZENITH_SUNSET_B, SKY_ZENITH_DAWN_B, SKY_ZENITH_NOON_B
    )
    return c^


def sky_horizon_color(sun_elevation: Float64) -> Color3:
    """Sky-dome horizon color (A01_Render/Sky §2 tiers) from sun elevation."""
    var e = _deg(sun_elevation)
    var c = Color3()
    c.r = _tier_channel(
        e,
        SKY_HORIZON_NIGHT_R,
        SKY_HORIZON_SUNSET_R,
        SKY_HORIZON_DAWN_R,
        SKY_HORIZON_NOON_R,
    )
    c.g = _tier_channel(
        e,
        SKY_HORIZON_NIGHT_G,
        SKY_HORIZON_SUNSET_G,
        SKY_HORIZON_DAWN_G,
        SKY_HORIZON_NOON_G,
    )
    c.b = _tier_channel(
        e,
        SKY_HORIZON_NIGHT_B,
        SKY_HORIZON_SUNSET_B,
        SKY_HORIZON_DAWN_B,
        SKY_HORIZON_NOON_B,
    )
    return c^


def sun_color_of(sun_elevation: Float64) -> Color3:
    """Sun color by elevation (A01_Render/Sky §2 sun-color-by-elevation
    intent). Night reuses the night navy — sun intensity gates to 0 there."""
    var e = _deg(sun_elevation)
    var c = Color3()
    c.r = _sun_channel(
        e,
        SUN_COLOR_NIGHT_R,
        SUN_COLOR_LOW_R,
        SUN_COLOR_RISING_R,
        SUN_COLOR_GOLDEN_R,
        SUN_COLOR_WARM_R,
        SUN_COLOR_NOON_R,
    )
    c.g = _sun_channel(
        e,
        SUN_COLOR_NIGHT_G,
        SUN_COLOR_LOW_G,
        SUN_COLOR_RISING_G,
        SUN_COLOR_GOLDEN_G,
        SUN_COLOR_WARM_G,
        SUN_COLOR_NOON_G,
    )
    c.b = _sun_channel(
        e,
        SUN_COLOR_NIGHT_B,
        SUN_COLOR_LOW_B,
        SUN_COLOR_RISING_B,
        SUN_COLOR_GOLDEN_B,
        SUN_COLOR_WARM_B,
        SUN_COLOR_NOON_B,
    )
    return c^


def sun_energy_factor(sun_elevation: Float64) -> Float64:
    """Tier energy multiplier: golden-hour dimming (SUN_ENERGY_HORIZON at the
    horizon) rising linearly to 1.0 at the NOON tier edge (45°). Schemas-1
    intensity values at hours 09/12/15 are preserved (elevation ≥ 45° there)."""
    var e = _deg(sun_elevation)
    if e <= 0.0:
        return SUN_ENERGY_HORIZON
    if e >= SUN_ELEVATION_NOON_DEG:
        return 1.0
    return SUN_ENERGY_HORIZON + (1.0 - SUN_ENERGY_HORIZON) * (
        e / SUN_ELEVATION_NOON_DEG
    )


# ---------------------------------------------------------------------------
# Derived fog (0004 §1.1 locked; AP-17: computed, never hand-tuned)
# ---------------------------------------------------------------------------

def fog_density_of(
    cloud_cover: Float64, precipitation: Float64, fog_bias: Float64, sun_elevation: Float64
) -> Float64:
    """fog_density = BASE + COEF_CLOUD·C + COEF_PRECIP·P + COEF_BIAS·bias
    + COEF_NIGHT·night_factor(elevation); every coefficient is a positive
    parameters.mojo constant ⇒ strictly increasing in cloud_cover and in
    precipitation (test-enforced) and equal to the parameters formula at the
    boundary values C,P ∈ {0,1}."""
    var d = (
        FOG_DENSITY_BASE
        + FOG_COEF_CLOUD * cloud_cover
        + FOG_COEF_PRECIP * precipitation
        + FOG_COEF_BIAS * fog_bias
        + FOG_COEF_NIGHT * night_factor(sun_elevation)
    )
    if d < 0.0:
        return 0.0
    return d


def fog_color_of(cloud_cover: Float64, precipitation: Float64, sun_elevation: Float64) -> Color3:
    """fog_color = lerp(lerp(CLEAR, STORM, w), NIGHT, night·NIGHT_MIX) with
    w = min(1, C·CLOUD_MIX + P·PRECIP_MIX) — a pure function of cloud cover,
    precipitation and sun elevation (0004 §1.1)."""
    var w = _clamp01(
        cloud_cover * FOG_COLOR_CLOUD_MIX + precipitation * FOG_COLOR_PRECIP_MIX
    )
    var nf = night_factor(sun_elevation) * FOG_COLOR_NIGHT_MIX
    var c = Color3()
    c.r = _lerp(_lerp(FOG_COLOR_R, FOG_COLOR_STORM_R, w), FOG_COLOR_NIGHT_R, nf)
    c.g = _lerp(_lerp(FOG_COLOR_G, FOG_COLOR_STORM_G, w), FOG_COLOR_NIGHT_G, nf)
    c.b = _lerp(_lerp(FOG_COLOR_B, FOG_COLOR_STORM_B, w), FOG_COLOR_NIGHT_B, nf)
    return c^


# ---------------------------------------------------------------------------
# Solar arc (single authority — AP-16: this is the ONLY arc formula)
# ---------------------------------------------------------------------------

def wrap_hours(hours0: Float64) -> Float64:
    """Fold hours into [0, 24)."""
    var hours = hours0 - floor(hours0 / 24.0) * 24.0
    if hours < 0.0:
        hours += 24.0
    return hours


def sun_elevation_at_hours(hours: Float64) -> Float64:
    """Sine arc, peak SUN_ELEVATION_MAX at 12:00, exact zero at 06:00/18:00:
    elevation(h) = SUN_ELEVATION_MAX · sin(π · (h − 6) / 12)."""
    var day_phase = (hours - 6.0) / 12.0
    return SUN_ELEVATION_MAX * sin(SUN_PI * day_phase)


def sun_azimuth_at_hours(hours: Float64, spawn_yaw: Float64) -> Float64:
    """Spawn-facing azimuth law (0004 §1.1 locked decision):

        azimuth(h) = spawn_yaw + π + π · (h − 12) / 12     (folded to [−π, π))

    Sun horizontal direction = (sin azimuth, cos azimuth) in the world frame
    (§801). With facing = spawn_yaw + π (spawn → island center, world.mojo):
    06:00 ⇒ facing − π/2, 12:00 ⇒ facing, 18:00 ⇒ facing + π/2, so the whole
    daytime arc (elevation > 0) lies inside the spawn-facing hemisphere."""
    var facing = spawn_yaw + SUN_PI
    var az = facing + SUN_PI * (hours - 12.0) / 12.0
    az = az - floor((az + SUN_PI) / SUN_TWO_PI) * SUN_TWO_PI
    return az


def atmosphere_from_weather(
    sim_time: Float64, weather: WeatherSubject, spawn_yaw: Float64
) -> AtmosphereSubject:
    """Pure projection of (sim time, weather state, spawn yaw) → full sky
    state (deterministic; AP-15: simulation_time only — no wall clock)."""
    var out = AtmosphereSubject()
    var hours = wrap_hours(TIME_OF_DAY_START_HOURS + sim_time / SECONDS_PER_SIM_HOUR)
    out.time_of_day_hours = hours
    out.sun_elevation = sun_elevation_at_hours(hours)
    out.sun_azimuth = sun_azimuth_at_hours(hours, spawn_yaw)
    # Sun intensity: schema-1 sine ramp gated above the horizon, scaled by the
    # tier energy factor (unchanged at hours 09/12/15 — see sun_energy_factor).
    var intensity = 0.0
    if out.sun_elevation > 0.0:
        intensity = (
            SUN_INTENSITY_NOON
            * sin(out.sun_elevation)
            * sun_energy_factor(out.sun_elevation)
        )
    out.sun_intensity = intensity

    var sc = sun_color_of(out.sun_elevation)
    out.sun_color_r = sc.r
    out.sun_color_g = sc.g
    out.sun_color_b = sc.b
    var zen = sky_zenith_color(out.sun_elevation)
    out.sky_zenith_r = zen.r
    out.sky_zenith_g = zen.g
    out.sky_zenith_b = zen.b
    var hor = sky_horizon_color(out.sun_elevation)
    out.sky_horizon_r = hor.r
    out.sky_horizon_g = hor.g
    out.sky_horizon_b = hor.b

    out.fog_density = fog_density_of(
        weather.cloud_cover, weather.precipitation, weather.fog_bias, out.sun_elevation
    )
    var fc = fog_color_of(
        weather.cloud_cover, weather.precipitation, out.sun_elevation
    )
    out.fog_r = fc.r
    out.fog_g = fc.g
    out.fog_b = fc.b

    out.cloud_cover = weather.cloud_cover
    out.precipitation = weather.precipitation
    out.wind_x = weather.wind_x
    out.wind_z = weather.wind_z
    out.wetness = weather.wetness
    return out^


def atmosphere_from_time(sim_time: Float64) -> AtmosphereSubject:
    """Legacy single-argument projection (milestone_0003 call sites): clear
    default weather and the default spawn yaw. Same arc/palette/fog formulas
    as atmosphere_from_weather — one authority, no second arc (AP-16)."""
    return atmosphere_from_weather(sim_time, WeatherSubject(), SUN_SPAWN_YAW_DEFAULT)


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
