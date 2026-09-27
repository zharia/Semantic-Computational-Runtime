# Spec test — Gerstner wave contract (SCR-LIB-MATH-GERSTNER via
# lib/202_Math/Gerstner/101_definition.md): deterministic heights, deep-water
# dispersion, steepness bound, Jacobian whitecap factor in contract ranges.

from std.testing import TestSuite
from std.math import abs, sqrt

from ocean.gerstner import (
    make_ocean,
    wave_height,
    normalized_wave_height,
    jacobian,
    surface_normal,
    foam_factor,
    steepness_bound_holds,
    OceanState,
)
from sim.parameters import (
    WAVE_AMPLITUDE,
    WAVE_WAVELENGTH,
    WAVE_STEEPNESS,
    FOAM_JACOBIAN_THRESHOLD,
    FOAM_HEIGHT_THRESHOLD,
    GRAVITY,
)

comptime TWO_PI: Float64 = 6.283185307179586
comptime EPS: Float64 = 1e-9


def test_dispersion_relation() raises:
    # §2.1: deep-water phase speed c = sqrt(|g| / k); ω = k·c.
    var ocean = make_ocean()
    var k = ocean.wave.wavenumber
    var expect_k = TWO_PI / WAVE_WAVELENGTH
    assert abs(k - expect_k) < EPS, "k = 2π/λ"
    var c = sqrt(abs(GRAVITY) / k)
    assert abs(ocean.wave.phase_speed - c) < 1e-9, "c = sqrt(|g|/k)"
    assert abs(ocean.wave.omega - k * c) < 1e-9, "ω = k·c"


def test_steepness_bound() raises:
    # §3.2: Q·k·A ≤ 1 and Q ∈ [0,1].
    var ocean = make_ocean()
    assert ocean.wave.steepness >= 0.0 and ocean.wave.steepness <= 1.0, "Q range"
    assert steepness_bound_holds(ocean), "Q·k·A ≤ 1"
    var qka = ocean.wave.steepness * ocean.wave.wavenumber * ocean.wave.amplitude
    assert qka <= 1.0 + EPS, "explicit bound check"


def test_height_range_and_determinism() raises:
    var ocean = make_ocean()
    var a = WAVE_AMPLITUDE
    var min_h = 1e9
    var max_h = -1e9
    for i in range(64):
        for j in range(64):
            var x = Float64(i) * 4.0 - 128.0
            var z = Float64(j) * 4.0 - 128.0
            var h = wave_height(ocean, x, z, 0.7)
            if h < min_h:
                min_h = h
            if h > max_h:
                max_h = h
            # Determinism: same inputs ⇒ same height.
            assert h == wave_height(ocean, x, z, 0.7), "nondeterministic height"
    assert min_h >= -a - EPS, "height ≥ −A"
    assert max_h <= a + EPS, "height ≤ +A"
    # Crest/trough reachable (amplitude actually realized).
    assert max_h > a * 0.3, "crest realized"
    assert min_h < -a * 0.3, "trough realized"


def test_normalized_height_and_foam_ranges() raises:
    var ocean = make_ocean()
    for i in range(32):
        var x = Float64(i) * 8.0 - 128.0
        var nh = normalized_wave_height(ocean, x, 3.0, 1.1)
        assert nh >= -1.0 - EPS and nh <= 1.0 + EPS, "normalized ∈ [−1,1]"
        var f = foam_factor(ocean, x, 3.0, 1.1)
        assert f >= 0.0 and f <= 1.0, "foam ∈ [0,1]"


def test_jacobian_whitecap_factor() raises:
    # §2.3: J = 1 − Q·k·A·(...); whitecap when J < threshold (0.65),
    # and the non-invertibility bound keeps J ≥ 1 − Q·k·A > 0.
    var ocean = make_ocean()
    var qka = ocean.wave.steepness * ocean.wave.wavenumber * ocean.wave.amplitude
    var j_floor = 1.0 - qka
    var min_j = 1e9
    for i in range(128):
        var x = Float64(i) * 2.0 - 128.0
        var j = jacobian(ocean, x, 0.0, 0.0)
        assert j >= j_floor - EPS, "J ≥ 1 − Q·k·A"
        assert j > 0.0, "J strictly positive (bound holds)"
        if j < min_j:
            min_j = j
    # The parameter choice must make the threshold reachable (Q·k·A = 0.39
    # ⇒ J_min = 0.61 < 0.65), otherwise the foam channel is dead config.
    assert j_floor < FOAM_JACOBIAN_THRESHOLD, "whitecap threshold reachable"
    assert min_j <= FOAM_JACOBIAN_THRESHOLD + 0.1, "J dips near threshold"
    # Height foam threshold also reachable: |h|/A > 0.7 somewhere.
    var ocean2 = make_ocean()
    var reached = False
    for i in range(256):
        var x = Float64(i) - 128.0
        var nh = abs(normalized_wave_height(ocean2, x, 0.0, 0.0))
        if nh > FOAM_HEIGHT_THRESHOLD:
            reached = True
    assert reached, "height foam threshold reachable"


def test_surface_normal_upward() raises:
    var ocean = make_ocean()
    for i in range(16):
        var x = Float64(i) * 16.0 - 128.0
        var n = surface_normal(ocean, x, 5.0, 0.3)
        var nx = n[0]
        var ny = n[1]
        var nz = n[2]
        var len2 = nx * nx + ny * ny + nz * nz
        assert abs(len2 - 1.0) < 1e-6, "unit normal"
        assert ny > 0.0, "upward-facing"


def test_wave_height_offset_around_sea_level() raises:
    # At the temporal node (cos phase alignment) height sits at sea level +
    # spatial crest structure; sea level datum is exactly ocean.sea_level.
    var ocean = make_ocean()
    assert ocean.sea_level == 0.0, "sea level datum"
    # Wave at (0,0) at t=0 with φ=0: phase = 0 ⇒ height = A·cos(0)... depends
    # on formulation; assert it is within the band either way and at the
    # datum when amplitude is zeroed.
    var h0 = wave_height(ocean, 0.0, 0.0, 0.0)
    assert h0 >= -WAVE_AMPLITUDE - EPS and h0 <= WAVE_AMPLITUDE + EPS
    var flat = OceanState()
    flat.sea_level = 0.0
    flat.wave = ocean.wave
    flat.wave.amplitude = 0.0
    flat.phase_offset = 0.0
    var h_flat = wave_height(flat, 12.0, -7.0, 3.0)
    assert abs(h_flat) < EPS, "zero amplitude ⇒ flat sea"


def main() raises:
    TestSuite.discover_tests[
        (
            test_dispersion_relation,
            test_steepness_bound,
            test_height_range_and_determinism,
            test_normalized_height_and_foam_ranges,
            test_jacobian_whitecap_factor,
            test_surface_normal_upward,
            test_wave_height_offset_around_sea_level,
        )
    ]().run()
