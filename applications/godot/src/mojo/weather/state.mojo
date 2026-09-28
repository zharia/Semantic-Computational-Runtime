# WeatherSubject — sim-owned weather state machine (milestone_0004 Sprint 01;
# 503_Simulation/Environment/Weather is a spec-only contract — implemented
# here in Mojo per definition, CORE subset only: 3 profiles, cloud cover,
# precipitation, wind vector, fog bias — spec §3 / milestone spec §3.3).
#
# Authority split (0004 §6): every weather STATE field lives here and reaches
# the scene only through the SKY snapshot section (cloud_cover, precipitation,
# wind, wetness) and the AtmosphereSubject inputs (fog/palette).
#
# Determinism (AP-12 / AP-15): the machine is a pure function of
# (World.seed, simulation_tick). Transitions are counter-based splitmix64
# draws (same discipline as sim/volcano.mojo::effusion_draw) taken once per
# WEATHER_TRANSITION_TICK_STEP ticks — no mutable PRNG state, no wall clock,
# no engine time anywhere in this file. Only wetness is history-dependent;
# it is an incremental fold over the (already seeded) precipitation history,
# so identical seed + tick sequences still yield identical wetness.
#
# Transitions (Weather §3): the profile tuple (cloud cover, precipitation,
# wind vector, fog bias) Hermite-blends with s(ξ) = 3ξ² − 2ξ³ over
# WEATHER_BLEND_TICKS ticks from the previous draw to the new one, then holds.
# Wind is that Hermite-smoothed world-frame vector plus a seeded-phase gust;
# wetness rises with precipitation and decays once it stops (§3.2 field 16).
#
# Out of scope (0004 §3.3 deviation, recorded): profiles marine mist and
# volcanic ash tempest, barometric pressure, humidity, aerosol and lightning
# fields — `TBD — future milestone`.

from std.math import sin

from sim.parameters import (
    WEATHER_TRANSITION_TICK_STEP,
    WEATHER_BLEND_TICKS,
    WEATHER_CLEAR_CLOUD,
    WEATHER_CLEAR_PRECIP,
    WEATHER_CLEAR_WIND_X,
    WEATHER_CLEAR_WIND_Z,
    WEATHER_CLEAR_FOG_BIAS,
    WEATHER_OVERCAST_CLOUD,
    WEATHER_OVERCAST_PRECIP,
    WEATHER_OVERCAST_WIND_X,
    WEATHER_OVERCAST_WIND_Z,
    WEATHER_OVERCAST_FOG_BIAS,
    WEATHER_MONSOON_CLOUD,
    WEATHER_MONSOON_PRECIP,
    WEATHER_MONSOON_WIND_X,
    WEATHER_MONSOON_WIND_Z,
    WEATHER_MONSOON_FOG_BIAS,
    WETNESS_RISE_RATE,
    WETNESS_DECAY_RATE,
    WIND_GUST_FRACTION,
    WIND_GUST_PERIOD_TICKS,
    WIND_MAX_SPEED,
)
from synthesis.noise import splitmix64

comptime _WEATHER_MIX_A: UInt64 = 0xA24BAED4963EE407
comptime _WEATHER_MIX_B: UInt64 = 0x9FB21C651E98DF25
comptime _WEATHER_MIX_C: UInt64 = 0xC13FA9A902A6328F
comptime _WEATHER_GUST_MIX: UInt64 = 0xD6E8FEB86659FD93
comptime _TWO_POW_53: Float64 = 9007199254740992.0  # 2^53
comptime _TWO_PI: Float64 = 6.283185307179586
comptime WEATHER_PROFILE_COUNT: Int = 3

# Profile ids (0004 §3.3 core subset).
comptime WEATHER_CLEAR: UInt8 = 0  # CLEAR_TROPICAL_SUN
comptime WEATHER_OVERCAST: UInt8 = 1  # OVERCAST_STRATUS
comptime WEATHER_MONSOON: UInt8 = 2  # TROPICAL_MONSOON (rain)


struct WeatherTuple(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Profile parameter tuple (Weather §3): cloud cover C ∈ [0,1],
    precipitation R_precip ∈ [0,1], wind vector (world frame, u/s) and the
    profile fog bias consumed by the fog derivation (0004 §1.1)."""

    var cloud_cover: Float64
    var precipitation: Float64
    var wind_x: Float64
    var wind_z: Float64
    var fog_bias: Float64

    def __init__(out self):
        self.cloud_cover = 0.0
        self.precipitation = 0.0
        self.wind_x = 0.0
        self.wind_z = 0.0
        self.fog_bias = 0.0

    def __deinit__(deinit self):
        pass


struct WeatherSubject(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Authoritative weather state committed once per fixed tick.

    cloud_cover / precipitation / wind / fog_bias are recomputed every tick
    from the Hermite blend (pure function of seed + tick); profile_index is
    the current draw's target profile; wetness is the incremental fold over
    precipitation history (0..1)."""

    var cloud_cover: Float64
    var precipitation: Float64
    var wind_x: Float64
    var wind_z: Float64
    var fog_bias: Float64
    var wetness: Float64  # accumulated surface wetness, 0..1 (§3.2 field 16)
    var profile_index: UInt8  # current target profile id (0/1/2)

    def __init__(out self):
        self.cloud_cover = WEATHER_CLEAR_CLOUD
        self.precipitation = WEATHER_CLEAR_PRECIP
        self.wind_x = WEATHER_CLEAR_WIND_X
        self.wind_z = WEATHER_CLEAR_WIND_Z
        self.fog_bias = WEATHER_CLEAR_FOG_BIAS
        self.wetness = 0.0
        self.profile_index = WEATHER_CLEAR

    def __deinit__(deinit self):
        pass


def weather_profile(index: Int) -> WeatherTuple:
    """The 3 committed profiles (Weather §3 graph, 0004 §3.3 core subset).
    Out-of-range indices clamp to the nearest committed profile."""
    var t = WeatherTuple()
    if index <= 0:
        t.cloud_cover = WEATHER_CLEAR_CLOUD
        t.precipitation = WEATHER_CLEAR_PRECIP
        t.wind_x = WEATHER_CLEAR_WIND_X
        t.wind_z = WEATHER_CLEAR_WIND_Z
        t.fog_bias = WEATHER_CLEAR_FOG_BIAS
    elif index == 1:
        t.cloud_cover = WEATHER_OVERCAST_CLOUD
        t.precipitation = WEATHER_OVERCAST_PRECIP
        t.wind_x = WEATHER_OVERCAST_WIND_X
        t.wind_z = WEATHER_OVERCAST_WIND_Z
        t.fog_bias = WEATHER_OVERCAST_FOG_BIAS
    else:
        t.cloud_cover = WEATHER_MONSOON_CLOUD
        t.precipitation = WEATHER_MONSOON_PRECIP
        t.wind_x = WEATHER_MONSOON_WIND_X
        t.wind_z = WEATHER_MONSOON_WIND_Z
        t.fog_bias = WEATHER_MONSOON_FOG_BIAS
    return t^


def weather_draw(seed: UInt32, draw_index: UInt32) -> UInt8:
    """One seeded profile draw ∈ {0,1,2} (AP-12: counter-based, never
    unseeded). Splitmix64 stream seeded from World.seed: draw i uses
    splitmix64(seed·A + i·B + C), maps the top 53 bits to u ∈ [0,1), and
    returns floor(u · 3) clamped to 2. Pure function of (seed, draw_index)."""
    var s = (
        UInt64(seed) * _WEATHER_MIX_A
        + UInt64(draw_index) * _WEATHER_MIX_B
        + _WEATHER_MIX_C
    )
    var x = splitmix64(s)
    var u = Float64(x >> 11) / _TWO_POW_53  # 53-bit mantissa → [0, 1)
    var idx = Int(u * Float64(WEATHER_PROFILE_COUNT))
    if idx >= WEATHER_PROFILE_COUNT:
        idx = WEATHER_PROFILE_COUNT - 1
    if idx < 0:
        idx = 0
    return UInt8(idx)


def weather_draw_for_tick(seed: UInt32, simulation_tick: UInt32) -> UInt8:
    """Profile draw in effect at this tick: draw index =
    simulation_tick // WEATHER_TRANSITION_TICK_STEP (one draw per step)."""
    var draw = simulation_tick // UInt32(WEATHER_TRANSITION_TICK_STEP)
    return weather_draw(seed, draw)


def weather_gust_phase(seed: UInt32, axis: UInt32) -> Float64:
    """Seeded gust phase ∈ [0, 2π) per wind axis (AP-12: counter-based)."""
    var s = (
        UInt64(seed) * _WEATHER_MIX_A
        + UInt64(axis) * _WEATHER_GUST_MIX
        + _WEATHER_MIX_C
    )
    var x = splitmix64(s)
    var u = Float64(x >> 11) / _TWO_POW_53
    return _TWO_PI * u


def weather_tuple_at(seed: UInt32, simulation_tick: UInt32) -> WeatherTuple:
    """Hermite-blended profile tuple at this tick (Weather §3):
    s(ξ) = 3ξ² − 2ξ³ with ξ = (tick mod STEP) / BLEND during the first
    WEATHER_BLEND_TICKS ticks of a draw, blending the previous draw's profile
    into the current one; held exactly (s = 1) for the rest of the step.
    Draw 0 has no predecessor and starts on its own profile."""
    var step = UInt32(WEATHER_TRANSITION_TICK_STEP)
    var blend = UInt32(WEATHER_BLEND_TICKS)
    var draw = simulation_tick // step
    var r = simulation_tick - draw * step
    var target = weather_profile(Int(weather_draw(seed, draw)))
    if draw == 0 or r >= blend:
        return target^
    var prev = weather_profile(Int(weather_draw(seed, draw - 1)))
    var xi = Float64(r) / Float64(blend)
    var s = 3.0 * xi * xi - 2.0 * xi * xi * xi
    var out = WeatherTuple()
    out.cloud_cover = (1.0 - s) * prev.cloud_cover + s * target.cloud_cover
    out.precipitation = (1.0 - s) * prev.precipitation + s * target.precipitation
    out.wind_x = (1.0 - s) * prev.wind_x + s * target.wind_x
    out.wind_z = (1.0 - s) * prev.wind_z + s * target.wind_z
    out.fog_bias = (1.0 - s) * prev.fog_bias + s * target.fog_bias
    return out^


def weather_tick(
    mut weather: WeatherSubject,
    seed: UInt32,
    simulation_tick: UInt32,
    dt: Float64,
):
    """Commit one fixed tick of weather state (0004 §3.1 / §3.3).

    Pure function of (seed, simulation_tick) for the profile fields; wetness
    integrates this tick's precipitation over dt (history fold, clamped 0..1).
    SIM time only (AP-15): no wall clock, no engine time."""
    var base = weather_tuple_at(seed, simulation_tick)
    weather.cloud_cover = base.cloud_cover
    weather.precipitation = base.precipitation
    weather.fog_bias = base.fog_bias
    weather.profile_index = weather_draw_for_tick(seed, simulation_tick)

    # Wind: Hermite-smoothed world-frame vector × seeded-phase gust.
    # |gust factor| ≤ 1 + WIND_GUST_FRACTION ⇒ direction preserved, bounded.
    var ang = _TWO_PI * Float64(simulation_tick) / WIND_GUST_PERIOD_TICKS
    var gx = 1.0 + WIND_GUST_FRACTION * sin(ang + weather_gust_phase(seed, 0))
    var gz = 1.0 + WIND_GUST_FRACTION * sin(ang + weather_gust_phase(seed, 1))
    weather.wind_x = base.wind_x * gx
    weather.wind_z = base.wind_z * gz
    # Range guard (104_contract §6 WIND_MAX_SPEED): per-axis clamp; the gust
    # factor alone cannot reach it, so this only binds under future profiles.
    if weather.wind_x > WIND_MAX_SPEED:
        weather.wind_x = WIND_MAX_SPEED
    elif weather.wind_x < -WIND_MAX_SPEED:
        weather.wind_x = -WIND_MAX_SPEED
    if weather.wind_z > WIND_MAX_SPEED:
        weather.wind_z = WIND_MAX_SPEED
    elif weather.wind_z < -WIND_MAX_SPEED:
        weather.wind_z = -WIND_MAX_SPEED

    # Wetness: rises with precipitation, decays after it stops.
    if weather.precipitation > 0.0:
        weather.wetness += WETNESS_RISE_RATE * weather.precipitation * dt
    else:
        weather.wetness -= WETNESS_DECAY_RATE * dt
    if weather.wetness < 0.0:
        weather.wetness = 0.0
    if weather.wetness > 1.0:
        weather.wetness = 1.0
