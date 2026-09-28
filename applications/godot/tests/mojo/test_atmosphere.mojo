# Spec test — AtmosphereSubject (milestone_0004 Sprint 01): solar-arc law
# (spawn-facing lock), palette tiers, derived fog, intensity gating — §7 exit
# criteria. Night factor (0003) is re-checked here only where the fog
# derivation depends on it. Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.testing import TestSuite
from std.math import abs, sin, atan2, cos

from sim.world import world_init
from sim.subjects import (
    AtmosphereSubject,
    Color3,
    atmosphere_from_time,
    atmosphere_from_weather,
    sun_elevation_at_hours,
    sun_azimuth_at_hours,
    sky_zenith_color,
    sky_horizon_color,
    sun_color_of,
    sun_energy_factor,
    fog_density_of,
    fog_color_of,
    night_factor,
)
from sim.parameters import (
    SUN_ELEVATION_MAX,
    SUN_INTENSITY_NOON,
    SUN_PI,
    TIME_OF_DAY_START_HOURS,
    SECONDS_PER_SIM_HOUR,
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
    SKY_ZENITH_NIGHT_R,
    SKY_ZENITH_NOON_R,
    SKY_ZENITH_NOON_G,
    SKY_ZENITH_NOON_B,
    SKY_HORIZON_NOON_R,
    SKY_HORIZON_NOON_G,
    SKY_HORIZON_NOON_B,
    SUN_COLOR_NIGHT_R,
    SUN_COLOR_NIGHT_G,
    SUN_COLOR_NIGHT_B,
    SUN_COLOR_NOON_R,
    SUN_COLOR_NOON_G,
    SUN_COLOR_NOON_B,
    SUN_ENERGY_HORIZON,
    GLOW_NIGHT_MAX_FACTOR,
)
from weather.state import WeatherSubject

# Golden azimuths for seed 1 (spawn yaw = atan2(spawn_x, spawn_z) =
# -3.025833435869...; facing = spawn_yaw + π = 0.11575921772081071):
# 09:00 = facing − π/4, 12:00 = facing, 15:00 = facing + π/4 (0004 §1.1).
comptime GOLDEN_AZ_09: Float64 = -0.6696389456766376
comptime GOLDEN_AZ_12: Float64 = 0.11575921772081071
comptime GOLDEN_AZ_15: Float64 = 0.901157381118259
comptime GOLDEN_ELEV_09: Float64 = 0.8485281374238569  # 1.2·sin(π/4)


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _sim_time_for_hours(hours: Float64) -> Float64:
    """Invert the hour law: t = h·100 − 1200 (mod 2400), start 12:00."""
    var h = hours
    return h * 100.0 - 1200.0


def test_solar_arc_spawn_facing() raises:
    """Locked arc: golden azimuths at 09/12/15 and the whole daytime arc
    inside the spawn-facing hemisphere (dot with facing > 0)."""
    var world = world_init(1)
    var yaw = atan2(world.island.spawn_x, world.island.spawn_z)
    var az12 = sun_azimuth_at_hours(12.0, yaw)
    var az09 = sun_azimuth_at_hours(9.0, yaw)
    var az15 = sun_azimuth_at_hours(15.0, yaw)
    _check(abs(az12 - GOLDEN_AZ_12) < 1e-12, "azimuth 12:00 golden")
    _check(abs(az09 - GOLDEN_AZ_09) < 1e-12, "azimuth 09:00 golden")
    _check(abs(az15 - GOLDEN_AZ_15) < 1e-12, "azimuth 15:00 golden")
    # Day arc: horizontal direction (sin az, cos az) has positive dot with the
    # spawn-facing direction for every daytime hour.
    var facing = GOLDEN_AZ_12  # facing == azimuth(12:00) by construction
    var h = 6.05
    while h < 17.95:
        var az = sun_azimuth_at_hours(h, yaw)
        var dot = sin(az) * sin(facing) + cos(az) * cos(facing)
        _check(dot > 0.0, "daytime sun in front of spawn at h=" + String(h))
        h += 0.1
    # Azimuth always folded into [−π, π).
    var k = 0.0
    while k < 24.0:
        var az = sun_azimuth_at_hours(k, yaw)
        _check(az >= -SUN_PI and az < SUN_PI, "azimuth folded at h=" + String(k))
        k += 0.5


def test_elevation_law_zero_at_dawn_dusk() raises:
    """elevation(h) = SUN_ELEVATION_MAX·sin(π(h−6)/12): exact zero-crossing
    character at 06:00/18:00, peak at noon, sign negative outside daylight."""
    _check(
        abs(sun_elevation_at_hours(12.0) - SUN_ELEVATION_MAX) < 1e-15,
        "peak at 12:00",
    )
    _check(abs(sun_elevation_at_hours(6.0)) < 1e-12, "zero at 06:00")
    _check(abs(sun_elevation_at_hours(18.0)) < 1e-12, "zero at 18:00")
    _check(sun_elevation_at_hours(18.01) < 0.0, "negative just after dusk")
    _check(sun_elevation_at_hours(5.99) < 0.0, "negative just before dawn")
    _check(
        abs(sun_elevation_at_hours(9.0) - GOLDEN_ELEV_09) < 1e-12,
        "09:00 elevation golden",
    )
    _check(
        abs(sun_elevation_at_hours(9.0) - sun_elevation_at_hours(15.0)) < 1e-12,
        "symmetric about noon",
    )
    # Night depth bounded by SUN_ELEVATION_MAX (night_factor saturates).
    _check(
        sun_elevation_at_hours(0.0) > -SUN_ELEVATION_MAX - 1e-12,
        "night elevation bounded",
    )


def test_sun_intensity_day_night() raises:
    """sin(elevation) ramp gated above the horizon; energy factor preserves
    the schema-1 values at hours 09/12/15 (elevation ≥ 45° there)."""
    var day = atmosphere_from_time(0.0)  # 12:00
    _check(abs(day.time_of_day_hours - 12.0) < 1e-9, "start hour 12:00")
    _check(day.sun_elevation > 1.0, "noon elevation near arc max (1.2 rad)")
    _check(
        abs(day.sun_intensity - SUN_INTENSITY_NOON * sin(SUN_ELEVATION_MAX)) < 1e-12,
        "schema-1 noon intensity preserved (energy = 1 above 45°)",
    )
    # 19:00 → t = 700 s: sun below horizon ⇒ intensity exactly 0.
    var night = atmosphere_from_time(_sim_time_for_hours(19.0))
    _check(night.sun_elevation < 0.0, "night elevation < 0")
    _check(night.sun_intensity == 0.0, "night intensity exactly 0")
    # Sweep: intensity ≥ 0 everywhere, > 0 exactly when elevation > 0.
    var h = 0.0
    while h < 24.0:
        var a = atmosphere_from_time(_sim_time_for_hours(h))
        _check(a.sun_intensity >= 0.0, "intensity ≥ 0 at h=" + String(h))
        if a.sun_elevation > 0.0:
            _check(a.sun_intensity > 0.0, "daytime intensity > 0 at h=" + String(h))
        h += 0.25
    # Energy factor bounds.
    _check(
        abs(sun_energy_factor(-1.0) - SUN_ENERGY_HORIZON) < 1e-12,
        "energy at horizon",
    )
    _check(abs(sun_energy_factor(1.2) - 1.0) < 1e-12, "energy 1.0 at high sun")


def test_palette_tiers_and_continuity() raises:
    """Tier membership (night / noon knots) + continuity: adjacent samples
    along a fine elevation sweep never jump (linear between knots)."""
    var zn = sky_zenith_color(-0.30)  # −17° ⇒ night tier
    _check(abs(zn.r - SKY_ZENITH_NIGHT_R) < 1e-12, "zenith night knot")
    var zq = sky_zenith_color(1.0)  # high noon
    _check(abs(zq.r - SKY_ZENITH_NOON_R) < 1e-12, "zenith noon knot")
    _check(abs(zq.g - SKY_ZENITH_NOON_G) < 1e-12, "zenith noon knot g")
    _check(abs(zq.b - SKY_ZENITH_NOON_B) < 1e-12, "zenith noon knot b")
    var hq = sky_horizon_color(1.0)
    _check(abs(hq.r - SKY_HORIZON_NOON_R) < 1e-12, "horizon noon knot")
    var sn = sun_color_of(-0.30)
    _check(abs(sn.r - SUN_COLOR_NIGHT_R) < 1e-12, "sun night knot")
    _check(abs(sn.g - SUN_COLOR_NIGHT_G) < 1e-12, "sun night knot g")
    var sq = sun_color_of(1.0)
    _check(abs(sq.r - SUN_COLOR_NOON_R) < 1e-12, "sun noon knot")
    _check(abs(sq.g - SUN_COLOR_NOON_G) < 1e-12, "sun noon knot g")

    # Continuity: step 0.001 rad (~0.057°) ⇒ per-channel step ≤ ~0.011 even at
    # the steepest knot (sun crimson 0.008→0.95 over 5° ≈ 10.8/rad ⇒ 0.0108).
    var step = 0.001
    var e = -0.35  # −20°
    var prev_z = sky_zenith_color(e)
    var prev_h = sky_horizon_color(e)
    var prev_s = sun_color_of(e)
    while e < 0.95:  # ~54°
        e += step
        var z = sky_zenith_color(e)
        var hh = sky_horizon_color(e)
        var s = sun_color_of(e)
        _check(abs(z.r - prev_z.r) < 0.02, "zenith r jump at " + String(e))
        _check(abs(z.g - prev_z.g) < 0.02, "zenith g jump at " + String(e))
        _check(abs(z.b - prev_z.b) < 0.02, "zenith b jump at " + String(e))
        _check(abs(hh.r - prev_h.r) < 0.02, "horizon r jump at " + String(e))
        _check(abs(hh.g - prev_h.g) < 0.02, "horizon g jump at " + String(e))
        _check(abs(hh.b - prev_h.b) < 0.02, "horizon b jump at " + String(e))
        _check(abs(s.r - prev_s.r) < 0.02, "sun r jump at " + String(e))
        _check(abs(s.g - prev_s.g) < 0.02, "sun g jump at " + String(e))
        _check(abs(s.b - prev_s.b) < 0.02, "sun b jump at " + String(e))
        # All channels in [0, 1] over the whole sweep.
        _check(
            z.r >= 0.0 and z.r <= 1.0 and hh.r >= 0.0 and hh.r <= 1.0,
            "zenith/horizon channels in [0,1]",
        )
        _check(s.r >= 0.0 and s.r <= 1.0, "sun channels in [0,1]")
        prev_z = z
        prev_h = hh
        prev_s = s


def test_fog_formula_and_monotonicity() raises:
    """fog_density = BASE + c·C + p·P + b·bias + n·night (0004 §1.1):
    exact at the C,P corners, strictly increasing in C and in P."""
    var day = 0.8  # high sun ⇒ night_factor = 0
    _check(
        abs(fog_density_of(0.0, 0.0, 0.0, day) - FOG_DENSITY_BASE) < 1e-15,
        "fog at (0,0) == BASE",
    )
    _check(
        abs(fog_density_of(1.0, 0.0, 0.0, day) - (FOG_DENSITY_BASE + FOG_COEF_CLOUD))
        < 1e-15,
        "fog at (1,0) == BASE + COEF_CLOUD",
    )
    _check(
        abs(fog_density_of(0.0, 1.0, 0.0, day) - (FOG_DENSITY_BASE + FOG_COEF_PRECIP))
        < 1e-15,
        "fog at (0,1) == BASE + COEF_PRECIP",
    )
    _check(
        abs(
            fog_density_of(1.0, 1.0, 0.0, day)
            - (FOG_DENSITY_BASE + FOG_COEF_CLOUD + FOG_COEF_PRECIP)
        )
        < 1e-15,
        "fog at (1,1) == BASE + COEF_CLOUD + COEF_PRECIP",
    )
    # Bias and night add their coefficients.
    _check(
        abs(fog_density_of(0.0, 0.0, 1.0, day) - (FOG_DENSITY_BASE + FOG_COEF_BIAS))
        < 1e-15,
        "fog bias coefficient",
    )
    var night_elev = -1.2
    _check(
        abs(
            fog_density_of(0.0, 0.0, 0.0, night_elev)
            - (FOG_DENSITY_BASE + FOG_COEF_NIGHT * GLOW_NIGHT_MAX_FACTOR)
        )
        < 1e-15,
        "fog night coefficient (saturated night_factor)",
    )
    # Strictly increasing in cloud cover (fixed P) and precipitation (fixed C).
    var p = 0.3
    var prev = fog_density_of(0.0, p, 0.0, day)
    var c = 0.1
    while c <= 1.0:
        var d = fog_density_of(c, p, 0.0, day)
        _check(d > prev, "strictly increasing in C at " + String(c))
        prev = d
        c += 0.1
    var cc = 0.4
    prev = fog_density_of(cc, 0.0, 0.0, day)
    var pp = 0.1
    while pp <= 1.0:
        var d2 = fog_density_of(cc, pp, 0.0, day)
        _check(d2 > prev, "strictly increasing in P at " + String(pp))
        prev = d2
        pp += 0.1
    # Never negative.
    _check(fog_density_of(0.0, 0.0, 0.0, night_elev) >= 0.0, "fog ≥ 0")


def test_fog_color_derivation() raises:
    """fog_color = lerp(lerp(CLEAR, STORM, w), NIGHT, 0.85·night_factor)."""
    var clear_day = fog_color_of(0.0, 0.0, 0.8)
    _check(abs(clear_day.r - FOG_COLOR_R) < 1e-15, "clear day fog r")
    _check(abs(clear_day.g - FOG_COLOR_G) < 1e-15, "clear day fog g")
    _check(abs(clear_day.b - FOG_COLOR_B) < 1e-15, "clear day fog b")
    # Full storm (C = P = 1) sits exactly on the storm knot (w clamped to 1).
    var storm = fog_color_of(1.0, 1.0, 0.8)
    _check(abs(storm.r - FOG_COLOR_STORM_R) < 1e-15, "storm fog r")
    _check(abs(storm.g - FOG_COLOR_STORM_G) < 1e-15, "storm fog g")
    # Channels stay within the knot hull for any input.
    var e = -0.4
    while e < 1.0:
        var f = fog_color_of(0.5, 0.5, e)
        _check(
            f.r >= 0.0 and f.r <= 1.0 and f.g >= 0.0 and f.g <= 1.0 and f.b >= 0.0
            and f.b <= 1.0,
            "fog channels in [0,1]",
        )
        e += 0.05
    # Night haze strictly darker than day-clear (all channels).
    var nite = fog_color_of(0.0, 0.0, -1.2)
    _check(nite.r < FOG_COLOR_R, "night fog darker (r)")
    _check(nite.g < FOG_COLOR_G, "night fog darker (g)")
    _check(nite.b < FOG_COLOR_B, "night fog darker (b)")
    _check(nite.r >= FOG_COLOR_NIGHT_R - 1e-12, "night fog ≥ night knot (r)")


def test_atmosphere_projection_consistency() raises:
    """atmosphere_from_weather mirrors the weather inputs and derives fog via
    the §6 formula; the legacy 1-arg path uses clear weather + default yaw."""
    var w = WeatherSubject()
    w.cloud_cover = 0.7
    w.precipitation = 0.4
    w.fog_bias = 0.2
    w.wind_x = 3.0
    w.wind_z = -2.0
    w.wetness = 0.55
    var yaw = -3.025833435869
    var a = atmosphere_from_weather(0.0, w, yaw)
    _check(a.cloud_cover == 0.7, "cloud mirror")
    _check(a.precipitation == 0.4, "precip mirror")
    _check(a.wind_x == 3.0 and a.wind_z == -2.0, "wind mirror")
    _check(a.wetness == 0.55, "wetness mirror")
    _check(
        abs(a.fog_density - fog_density_of(0.7, 0.4, 0.2, a.sun_elevation)) < 1e-15,
        "fog derived from weather inputs",
    )
    var fc = fog_color_of(0.7, 0.4, a.sun_elevation)
    _check(abs(a.fog_r - fc.r) < 1e-15, "fog color derived (r)")
    _check(
        abs(a.sun_azimuth - sun_azimuth_at_hours(a.time_of_day_hours, yaw)) < 1e-12,
        "azimuth consistent with hour law",
    )
    # Legacy path: default yaw, clear weather.
    var legacy = atmosphere_from_time(0.0)
    _check(
        abs(legacy.sun_azimuth - sun_azimuth_at_hours(12.0, 0.0)) < 1e-12,
        "legacy path uses default spawn yaw",
    )
    _check(legacy.precipitation == 0.0, "legacy path clear weather")
    # Clear profile still carries cloud_cover 0.15 ⇒ fog = BASE + c·0.15.
    _check(
        abs(
            legacy.fog_density
            - (FOG_DENSITY_BASE + FOG_COEF_CLOUD * legacy.cloud_cover)
        )
        < 1e-15,
        "legacy fog == BASE + COEF_CLOUD·clear cloud",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_solar_arc_spawn_facing,
            test_elevation_law_zero_at_dawn_dusk,
            test_sun_intensity_day_night,
            test_palette_tiers_and_continuity,
            test_fog_formula_and_monotonicity,
            test_fog_color_derivation,
            test_atmosphere_projection_consistency,
        )
    ]().run()
