# SCR-LIB-MATH-GERSTNER (lib/202_Math/Gerstner/101_definition.md) —
# spec-only contract implemented in Mojo.
#
# Consumed equations:
#   §2.1 single harmonic: k = 2π/λ, c = sqrt(g/k) (deep-water dispersion,
#        g = |GRAVITY|), ω = k·c, Q ∈ [0,1]; displaced position formulas.
#   §2.2 analytical surface normal N = B × T (unnormalized form in spec).
#   §2.3 Jacobian J and crest whitecap foam thresholds (J < 0.65 or
#        normalized height > 0.7).
#   §3  invariants: steepness bound Σ Q·k·A ≤ 1 (single wave: Q·k·A ≤ 1);
#       continuity (C∞ — analytic trig, no discretisation).
#
# SIM vs DISPLAY split (104_contract §4.3 note): the sim uses the vertical
# displacement y(x,z,t) as authoritative water height for grounding/foam;
# horizontal displacement (x,z terms of §2.1) is display-only and applied by
# the Godot shader from the OCEAN section fields.

from std.math import sqrt, cos, sin, atan2, abs, pi
from sim.parameters import (
    SEA_LEVEL,
    WAVE_AMPLITUDE,
    WAVE_WAVELENGTH,
    WAVE_STEEPNESS,
    WAVE_DIRECTION_X,
    WAVE_DIRECTION_Z,
    FOAM_JACOBIAN_THRESHOLD,
    FOAM_HEIGHT_THRESHOLD,
    GRAVITY,
)


struct GerstnerWave(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var amplitude: Float64  # A
    var wavelength: Float64  # λ
    var wavenumber: Float64  # k = 2π/λ
    var steepness: Float64  # Q ∈ [0,1]
    var dir_x: Float64  # unit direction d
    var dir_z: Float64
    var phase_speed: Float64  # c = sqrt(g/k)
    var omega: Float64  # ω = k·c

    def __init__(out self):
        self.amplitude = 0.0
        self.wavelength = 0.0
        self.wavenumber = 0.0
        self.steepness = 0.0
        self.dir_x = 0.0
        self.dir_z = 0.0
        self.phase_speed = 0.0
        self.omega = 0.0

    def __deinit__(deinit self):
        pass


struct OceanState(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var sea_level: Float64
    var wave: GerstnerWave
    var phase_offset: Float64  # φ (fixed at 0 for the core slice)

    def __init__(out self):
        self.sea_level = 0.0
        self.wave = GerstnerWave()
        self.phase_offset = 0.0

    def __deinit__(deinit self):
        pass


def make_ocean() -> OceanState:
    """Build the core-slice ocean from the parameter table (AP-7)."""
    var out = OceanState()
    out.sea_level = SEA_LEVEL
    var w = GerstnerWave()
    w.amplitude = WAVE_AMPLITUDE
    w.wavelength = WAVE_WAVELENGTH
    w.wavenumber = 2.0 * pi / WAVE_WAVELENGTH
    w.steepness = WAVE_STEEPNESS
    # Direction params ship as (0.8, 0.6); normalise defensively (§2.1 ‖d‖=1).
    var mag = sqrt(WAVE_DIRECTION_X * WAVE_DIRECTION_X + WAVE_DIRECTION_Z * WAVE_DIRECTION_Z)
    w.dir_x = WAVE_DIRECTION_X / mag
    w.dir_z = WAVE_DIRECTION_Z / mag
    w.phase_speed = sqrt(abs(GRAVITY) / w.wavenumber)  # §2.1 dispersion
    w.omega = w.wavenumber * w.phase_speed
    out.wave = w
    out.phase_offset = 0.0
    return out^


def wave_phase(ocean: OceanState, x: Float64, z: Float64, t: Float64) -> Float64:
    """θ = k·(d·p0) − ω·t + φ  (§2.1)."""
    var w = ocean.wave
    var dot = w.dir_x * x + w.dir_z * z
    return w.wavenumber * dot - w.omega * t + ocean.phase_offset


def wave_height(ocean: OceanState, x: Float64, z: Float64, t: Float64) -> Float64:
    """Vertical displacement y(x,z,t) = sea + A·cosθ (§2.1 y-equation).

    Authoritative sim-side water height (horizontal terms are display-only)."""
    return ocean.sea_level + ocean.wave.amplitude * cos(wave_phase(ocean, x, z, t))


def normalized_wave_height(ocean: OceanState, x: Float64, z: Float64, t: Float64) -> Float64:
    """Displacement normalised to [0,1]: (y − sea)/A scaled by ½ (§2.3)."""
    var a = ocean.wave.amplitude
    if a == 0.0:
        return 0.5
    var h = (wave_height(ocean, x, z, t) - ocean.sea_level) / a
    return 0.5 * (h + 1.0)


def jacobian(ocean: OceanState, x: Float64, z: Float64, t: Float64) -> Float64:
    """§2.3 Jacobian determinant. For a single wave with unit direction:
    J = (1 − a·dx²·cosθ)(1 − a·dz²·cosθ) − (a·dx·dz·cosθ)²  where a = Q·k·A.
    Algebraically J = 1 − Q·k·A·cosθ (dx² + dz² = 1)."""
    var w = ocean.wave
    var a = w.steepness * w.wavenumber * w.amplitude
    var theta = wave_phase(ocean, x, z, t)
    var c = cos(theta)
    var t1 = 1.0 - a * w.dir_x * w.dir_x * c
    var t2 = 1.0 - a * w.dir_z * w.dir_z * c
    var off = a * w.dir_x * w.dir_z * c
    return t1 * t2 - off * off


def surface_normal(ocean: OceanState, x: Float64, z: Float64, t: Float64) -> Tuple[
    Float64, Float64, Float64
]:
    """§2.2 unnormalized N = B × T for the single-wave case."""
    var w = ocean.wave
    var theta = wave_phase(ocean, x, z, t)
    # §2.2 literal single-wave form: N = (−d·k·A·sinθ, 1 − Q·k·A·cosθ,
    # −d·k·A·sinθ).
    var nx = -w.dir_x * w.wavenumber * w.amplitude * sin(theta)
    var ny = 1.0 - w.steepness * w.wavenumber * w.amplitude * cos(theta)
    var nz = -w.dir_z * w.wavenumber * w.amplitude * sin(theta)
    return (nx, ny, nz)


def foam_factor(ocean: OceanState, x: Float64, z: Float64, t: Float64) -> Float64:
    """§2.3 crest whitecap foam ∈ [0,1]:
    triggers when J < FOAM_JACOBIAN_THRESHOLD or normalized height >
    FOAM_HEIGHT_THRESHOLD; ramps linearly to 1 at J = 0 / height = 1."""
    var j = jacobian(ocean, x, z, t)
    var h = normalized_wave_height(ocean, x, z, t)
    var foam = 0.0
    if j < FOAM_JACOBIAN_THRESHOLD:
        foam = (FOAM_JACOBIAN_THRESHOLD - j) / FOAM_JACOBIAN_THRESHOLD
    if h > FOAM_HEIGHT_THRESHOLD:
        var hf = (h - FOAM_HEIGHT_THRESHOLD) / (1.0 - FOAM_HEIGHT_THRESHOLD)
        if hf > foam:
            foam = hf
    if foam > 1.0:
        foam = 1.0
    if foam < 0.0:
        foam = 0.0
    return foam


def steepness_bound_holds(ocean: OceanState) -> Bool:
    """§3 invariant 2: Σ Q·k·A ≤ 1 (single wave)."""
    var w = ocean.wave
    return w.steepness * w.wavenumber * w.amplitude <= 1.0
