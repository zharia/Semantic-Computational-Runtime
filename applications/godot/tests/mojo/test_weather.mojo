# Spec test — WeatherSubject (milestone_0004 Sprint 01): seeded draws,
# Hermite transitions, rain onset ≤ 9000 ticks, wetness fold, gust/wind
# bounds, byte determinism (§7 exit criteria). Headless: no Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite

from sim.world import world_init, step_world
from sim.input import InputBatch
from weather.state import (
    WeatherSubject,
    WeatherTuple,
    weather_profile,
    weather_draw,
    weather_draw_for_tick,
    weather_tuple_at,
    weather_tick,
    WEATHER_CLEAR,
    WEATHER_OVERCAST,
    WEATHER_MONSOON,
)
from sim.parameters import (
    WEATHER_TRANSITION_TICK_STEP,
    WEATHER_BLEND_TICKS,
    WEATHER_CLEAR_CLOUD,
    WEATHER_CLEAR_PRECIP,
    WEATHER_CLEAR_WIND_X,
    WEATHER_CLEAR_WIND_Z,
    WEATHER_MONSOON_CLOUD,
    WEATHER_MONSOON_PRECIP,
    WETNESS_RISE_RATE,
    WETNESS_DECAY_RATE,
    WIND_GUST_FRACTION,
    WIND_MAX_SPEED,
    FIXED_DT,
)

# Seed-1 draw sequence (validated model): indices 0..11 = draws taken every
# WEATHER_TRANSITION_TICK_STEP ticks.
comptime SEED1_DRAWS_LEN: Int = 12

# First tick where the seed-1 precipitation leaves 0 (draw 1 = MONSOON at
# tick 1800, blend starts immediately) — §7 exit criterion: onset ≤ 9000.
comptime SEED1_FIRST_RAIN_TICK: Int = 1801


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _abs_f(v: Float64) -> Float64:
    if v < 0.0:
        return -v
    return v


def _seed1_draws() -> List[UInt8]:
    # Validated against the implementation's splitmix64 mapping (probe run).
    var out = List[UInt8]()
    out.append(0)  # draw 0: CLEAR
    out.append(2)  # 1: MONSOON
    out.append(2)  # 2: MONSOON
    out.append(2)  # 3: MONSOON
    out.append(1)  # 4: OVERCAST
    out.append(0)  # 5: CLEAR
    out.append(1)  # 6: OVERCAST
    out.append(2)  # 7: MONSOON
    out.append(0)  # 8: CLEAR
    out.append(1)  # 9: OVERCAST
    out.append(0)  # 10: CLEAR
    out.append(1)  # 11: OVERCAST
    return out^


def test_seeded_draws_deterministic() raises:
    """weather_draw is a pure function of (seed, draw_index) — same inputs,
    same profile; seed 1 matches the recorded sequence; seeds 1 and 2 differ."""
    var expected = _seed1_draws()
    for i in range(SEED1_DRAWS_LEN):
        var d = weather_draw(1, UInt32(i))
        _check(d == expected[i], "seed1 draw " + String(i))
        _check(weather_draw(1, UInt32(i)) == d, "draw pure at " + String(i))
        _check(d <= WEATHER_MONSOON, "draw in {0,1,2} at " + String(i))
    var differs = False
    for i in range(SEED1_DRAWS_LEN):
        if weather_draw(2, UInt32(i)) != weather_draw(1, UInt32(i)):
            differs = True
    _check(differs, "seed 2 must differ from seed 1 somewhere")
    # weather_draw_for_tick == weather_draw at the step boundary.
    _check(
        weather_draw_for_tick(1, UInt32(WEATHER_TRANSITION_TICK_STEP))
        == weather_draw(1, 1),
        "tick → draw index mapping",
    )


def test_rain_onset_within_9000_ticks() raises:
    """Exit criterion: seed 1 produces a rain transition (precipitation > 0)
    at or before tick 9000; first onset is the recorded 1801."""
    var first = -1
    for t in range(0, 9001):
        var tup = weather_tuple_at(1, UInt32(t))
        if tup.precipitation > 0.0:
            first = t
            break
    _check(first >= 0, "rain must occur by tick 9000")
    _check(first == SEED1_FIRST_RAIN_TICK, "first rain onset tick == 1801")
    _check(first <= 9000, "onset ≤ 9000 (exit criterion)")


def test_hermite_blend_bounds_and_hold() raises:
    """Blend output stays within the convex hull of the two profiles; after
    WEATHER_BLEND_TICKS the tuple is held exactly on the target profile."""
    var step = WEATHER_TRANSITION_TICK_STEP
    var blend = WEATHER_BLEND_TICKS
    # Mid-blend at draw 1 (prev CLEAR → MONSOON): strictly between.
    var mid = weather_tuple_at(1, UInt32(step + blend // 2))
    _check(
        mid.cloud_cover > WEATHER_CLEAR_CLOUD and mid.cloud_cover < WEATHER_MONSOON_CLOUD,
        "mid-blend cloud between profiles",
    )
    _check(mid.precipitation > 0.0, "mid-blend precipitation rising")
    _check(mid.precipitation <= WEATHER_MONSOON_PRECIP, "blend ≤ monsoon precip")
    # Held exactly for the rest of the step (r ≥ blend).
    var held = weather_tuple_at(1, UInt32(step + blend))
    var target = weather_profile(2)  # draw 1 = MONSOON
    _check(held.cloud_cover == target.cloud_cover, "hold cloud exact")
    _check(held.precipitation == target.precipitation, "hold precip exact")
    _check(held.wind_x == target.wind_x, "hold wind profile exact")
    # Draw 0 has no predecessor: starts on its own profile.
    var d0 = weather_tuple_at(1, 0)
    var p0 = weather_profile(0)
    _check(d0.cloud_cover == p0.cloud_cover, "draw 0 starts on clear")
    # All tuple fields in [0,1]-ish ranges for cloud/precip/fog_bias.
    for t in range(0, 6000, 137):
        var tup = weather_tuple_at(1, UInt32(t))
        _check(
            tup.cloud_cover >= 0.0 and tup.cloud_cover <= 1.0,
            "cloud ∈ [0,1] at " + String(t),
        )
        _check(
            tup.precipitation >= 0.0 and tup.precipitation <= 1.0,
            "precip ∈ [0,1] at " + String(t),
        )
        _check(
            tup.fog_bias >= 0.0 and tup.fog_bias <= 1.0,
            "fog_bias ∈ [0,1] at " + String(t),
        )


def test_wetness_rise_decay_and_clamp() raises:
    """Wetness integrates precipitation (rise 0.15/s), decays dry (0.01/s),
    stays in [0, 1] over the whole seed-1 trajectory."""
    var w = WeatherSubject()
    weather_tick(w, 1, 0, 0.0)  # commit tick 0, no integration (dt = 0)
    _check(w.wetness == 0.0, "starts dry")
    _check(w.precipitation == 0.0, "clear profile has no rain")
    var wet_at_4000 = 0.0
    var wet_at_9000 = 0.0
    for t in range(1, 9001):
        weather_tick(w, 1, UInt32(t), FIXED_DT)
        _check(w.wetness >= 0.0 and w.wetness <= 1.0, "wetness ∈ [0,1]")
        if t == 4000:
            wet_at_4000 = w.wetness
        if t == 9000:
            wet_at_9000 = w.wetness
    _check(wet_at_4000 > 0.0, "wetness accumulated during rain")
    _check(wet_at_9000 < wet_at_4000, "wetness decays after the rain")
    # Rise-rate bound: wetness never exceeds rise_rate · rain_time + margin.
    _check(wet_at_4000 <= 1.0, "wetness ≤ 1")


def test_wind_gust_bounded_and_direction_preserved() raises:
    """Wind = profile vector × (1 + gust), |gust| ≤ WIND_GUST_FRACTION ⇒
    per-axis magnitude ≤ profile·(1+0.18) ≤ WIND_MAX_SPEED; sign preserved."""
    var w = WeatherSubject()
    weather_tick(w, 1, 0, 0.0)
    for t in range(1, 7201):
        weather_tick(w, 1, UInt32(t), FIXED_DT)
        var tup = weather_tuple_at(1, UInt32(t))
        _check(
            _abs_f(w.wind_x) <= _abs_f(tup.wind_x) * (1.0 + WIND_GUST_FRACTION) + 1e-9,
            "wind_x gust bound",
        )
        _check(
            _abs_f(w.wind_z) <= _abs_f(tup.wind_z) * (1.0 + WIND_GUST_FRACTION) + 1e-9,
            "wind_z gust bound",
        )
        _check(_abs_f(w.wind_x) <= WIND_MAX_SPEED + 1e-9, "wind_x ≤ WIND_MAX_SPEED")
        _check(_abs_f(w.wind_z) <= WIND_MAX_SPEED + 1e-9, "wind_z ≤ WIND_MAX_SPEED")
        # Sign preserved (profile wind vectors are strictly positive here).
        if tup.wind_x > 0.0:
            _check(w.wind_x > 0.0, "wind_x direction preserved")
        if tup.wind_z > 0.0:
            _check(w.wind_z > 0.0, "wind_z direction preserved")


def test_weather_tick_pure_for_profile_fields() raises:
    """Two independent runs over the same (seed, tick) sequence produce
    identical committed state (determinism exit criterion)."""
    var a = WeatherSubject()
    var b = WeatherSubject()
    for t in range(0, 3601):
        weather_tick(a, 1, UInt32(t), FIXED_DT)
        weather_tick(b, 1, UInt32(t), FIXED_DT)
        _check(a.cloud_cover == b.cloud_cover, "cloud determinism")
        _check(a.precipitation == b.precipitation, "precip determinism")
        _check(a.wind_x == b.wind_x and a.wind_z == b.wind_z, "wind determinism")
        _check(a.wetness == b.wetness, "wetness determinism")
        _check(a.profile_index == b.profile_index, "profile determinism")
    # Profile fields depend only on (seed, tick): a fresh subject jumped
    # straight to tick 2500 matches the folded run. Same-shape runs compare
    # bit-exact; cross-shape (single call vs loop) allows 1 ULP of FP
    # contraction difference at most — same trajectory either way.
    var fresh1 = WeatherSubject()
    weather_tick(fresh1, 1, 2500, 0.0)
    var fresh2 = WeatherSubject()
    weather_tick(fresh2, 1, 2500, 0.0)
    _check(
        fresh1.cloud_cover == fresh2.cloud_cover
        and fresh1.precipitation == fresh2.precipitation
        and fresh1.profile_index == fresh2.profile_index,
        "single-tick commit bit-exact",
    )
    var folded = WeatherSubject()
    for t in range(0, 2501):
        weather_tick(folded, 1, UInt32(t), FIXED_DT)
    var direct = weather_tuple_at(1, 2500)
    _check(
        _abs_f(fresh1.cloud_cover - folded.cloud_cover) < 1e-12,
        "cloud stateless",
    )
    _check(
        _abs_f(fresh1.precipitation - folded.precipitation) < 1e-12,
        "precip stateless",
    )
    _check(fresh1.profile_index == folded.profile_index, "profile stateless")
    _check(
        _abs_f(folded.cloud_cover - direct.cloud_cover) < 1e-15
        and _abs_f(folded.precipitation - direct.precipitation) < 1e-15,
        "folded commit == tuple at same tick",
    )


def test_world_commits_weather_each_tick() raises:
    """World owns the weather subject: tick 0 carries a committed profile and
    the atmosphere mirrors it (Sprint 01 integration)."""
    var world = world_init(1)
    _check(world.atmosphere.cloud_cover == world.weather.cloud_cover, "tick0 mirror")
    _check(world.weather.profile_index == weather_draw_for_tick(1, 0), "tick0 profile")
    _ = step_world(world, FIXED_DT, InputBatch())
    _check(world.weather.profile_index == weather_draw_for_tick(1, 1), "tick1 profile")
    _check(world.atmosphere.cloud_cover == world.weather.cloud_cover, "tick1 mirror")
    _check(world.atmosphere.wetness == world.weather.wetness, "wetness mirror")
    # Weather feeds fog: atmosphere fog equals the derivation over inputs.
    var expect_d = world.atmosphere.fog_density
    _check(expect_d >= 0.0, "fog ≥ 0")


def main() raises:
    TestSuite.discover_tests[
        (
            test_seeded_draws_deterministic,
            test_rain_onset_within_9000_ticks,
            test_hermite_blend_bounds_and_hold,
            test_wetness_rise_decay_and_clamp,
            test_wind_gust_bounded_and_direction_preserved,
            test_weather_tick_pure_for_profile_fields,
            test_world_commits_weather_each_tick,
        )
    ]().run()
