# SCR-LIB-MATH-NOISE (lib/202_Math/Noise/101_definition.md) — spec-only
# contract implemented in Mojo.
#
# Consumed contracts:
#   §2.1 GradientNoise: sample(x,y,z,seed) ∈ [-1,1], period 256 per axis,
#        permutation-table driven, continuous at non-lattice points.
#   §2.3 RidgedNoise:   r(x) = 1 - |2·N(x) - 1| per octave, output ∈ [0,1],
#        ridge crests (maxima) approach 1.
#   §2.4 SpectralOctaves (fBm): octave i has amplitude gain^i, frequency
#        lacunarity^i, result normalised by total amplitude, output ∈ [-1,1].
#   §3   SpectralSynthesizer purity: pure function of (x, z, seed, params).
#   §4   invariants 1 (deterministic per seed) and 3 (seed independence).
#
# §5 (no heap allocation during sample evaluation): the permutation table is
# built once at NoiseContext construction; sampling only reads it.

from std.collections import List
from std.math import floor

# ---------------------------------------------------------------------------
# NoiseContext — seeded permutation table (§2.1: period 256 per axis)
# ---------------------------------------------------------------------------

struct NoiseContext(Movable, Deinitable):
    var seed: UInt32
    var perm: List[UInt8]  # 512 entries: doubled permutation of 0..255

    def __init__(out self, seed: UInt32):
        self.seed = seed
        self.perm = List[UInt8]()
        _build_permutation(seed, self.perm)

    def __deinit__(deinit self):
        pass


# splitmix64 — deterministic uint32 seed expansion (SCR-LIB-MATH-RANDOM
# stand-in; the noise contract only requires determinism from the seed).
def splitmix64(state: UInt64) -> UInt64:
    var z = state + 0x9E3779B97F4A7C15
    var x = z
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9
    x = (x ^ (x >> 27)) * 0x94D049BB133111EB
    return x ^ (x >> 31)


# --- Pure integer hash over (seed, x, z, salt) -------------------------------
# Shared by sim/flora placement and sim/flock respawn (milestone_0006 §1.1:
# "integer hash over (seed, x, z), no mutable RNG stream"). Order-independent
# and side-effect free — same inputs, same output, forever.
comptime _CELL_MIX_A: UInt64 = 0x9E3779B97F4A7C15
comptime _CELL_MIX_B: UInt64 = 0xD1B54A32D192ED03
comptime _CELL_MIX_C: UInt64 = 0x85EBCA77C2B2AE63
comptime _TWO_POW_53: Float64 = 9007199254740992.0  # 2^53


def hash64_cells(seed: UInt32, x: Int, z: Int, salt: UInt64) -> UInt64:
    """Pure splitmix64 finalizer over a composed (seed, x, z, salt) state."""
    var s = (
        UInt64(seed) * _CELL_MIX_A
        ^ (UInt64(UInt32(x)) + 1) * _CELL_MIX_B
        ^ (UInt64(UInt32(z)) + 1) * _CELL_MIX_C
        ^ salt
    )
    return splitmix64(s)


def hash01_cells(seed: UInt32, x: Int, z: Int, salt: UInt64) -> Float64:
    """Top 53 bits → u ∈ [0, 1)."""
    return Float64(hash64_cells(seed, x, z, salt) >> 11) / _TWO_POW_53


def _build_permutation(seed: UInt32, mut perm: List[UInt8]):
    # Fisher-Yates over 0..255 driven by splitmix64(seed) — deterministic.
    var state = UInt64(seed) * 0x9E3779B97F4A7C15 + 0x85EBCA77C2B2AE63
    for i in range(256):
        perm.append(UInt8(i))
    for i in range(255, 0, -1):
        state = splitmix64(state)
        var j = Int(state % UInt64(i + 1))
        var tmp = perm[i]
        perm[i] = perm[j]
        perm[j] = tmp
    # Double so index arithmetic never needs a modulo (period 256, §2.1).
    for i in range(256):
        perm.append(perm[i])


# ---------------------------------------------------------------------------
# GradientNoise (§2.1)
# ---------------------------------------------------------------------------

def _grad(hash_val: UInt8, x: Float64, y: Float64, z: Float64) -> Float64:
    # 12 edge directions of a cube — standard Perlin gradient set.
    var h = Int(hash_val) & 15
    var u = x if h < 8 else y
    var v: Float64
    if h < 4:
        v = y
    elif h == 12 or h == 14:
        v = x
    else:
        v = z
    var sign_a = 1.0 if (h & 1) == 0 else -1.0
    var sign_b = 1.0 if (h & 2) == 0 else -1.0
    return u * sign_a + v * sign_b


def _fade(t: Float64) -> Float64:
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


def _lerp(a: Float64, b: Float64, t: Float64) -> Float64:
    return a + t * (b - a)


def gradient_noise(ctx: NoiseContext, x: Float64, y: Float64, z: Float64) -> Float32:
    """GradientNoise.sample(x, y, z, seed) -> f ∈ [-1, 1] (§2.1)."""
    var cell_x = floor(x)
    var cell_y = floor(y)
    var cell_z = floor(z)
    var fx = x - cell_x
    var fy = y - cell_y
    var fz = z - cell_z
    var X = Int(cell_x) & 255
    var Y = Int(cell_y) & 255
    var Z = Int(cell_z) & 255

    var u = _fade(fx)
    var v = _fade(fy)
    var w = _fade(fz)

    # Hash the corners of the unit cube through the doubled permutation.
    var A = Int(ctx.perm[X]) + Y
    var AA = Int(ctx.perm[A & 511]) + Z
    var AB = Int(ctx.perm[(A + 1) & 511]) + Z
    var B = Int(ctx.perm[X + 1]) + Y
    var BA = Int(ctx.perm[B & 511]) + Z
    var BB = Int(ctx.perm[(B + 1) & 511]) + Z

    var g000 = _grad(ctx.perm[AA & 511], fx, fy, fz)
    var g100 = _grad(ctx.perm[BA & 511], fx - 1.0, fy, fz)
    var g010 = _grad(ctx.perm[AB & 511], fx, fy - 1.0, fz)
    var g110 = _grad(ctx.perm[BB & 511], fx - 1.0, fy - 1.0, fz)
    var g001 = _grad(ctx.perm[(AA + 1) & 511], fx, fy, fz - 1.0)
    var g101 = _grad(ctx.perm[(BA + 1) & 511], fx - 1.0, fy, fz - 1.0)
    var g011 = _grad(ctx.perm[(AB + 1) & 511], fx, fy - 1.0, fz - 1.0)
    var g111 = _grad(ctx.perm[(BB + 1) & 511], fx - 1.0, fy - 1.0, fz - 1.0)

    var x00 = _lerp(g000, g100, u)
    var x10 = _lerp(g010, g110, u)
    var x01 = _lerp(g001, g101, u)
    var x11 = _lerp(g011, g111, u)
    var y0 = _lerp(x00, x10, v)
    var y1 = _lerp(x01, x11, v)
    # Gradient-noise lattice bound is < 1; scale to guarantee [-1,1] (§2.1).
    var value = _lerp(y0, y1, w) * 1.2
    if value > 1.0:
        value = 1.0
    if value < -1.0:
        value = -1.0
    return Float32(value)


# ---------------------------------------------------------------------------
# SpectralOctaves / fBm (§2.4)
# ---------------------------------------------------------------------------

def fbm(
    ctx: NoiseContext,
    x: Float64,
    y: Float64,
    z: Float64,
    octaves: Int,
    lacunarity: Float64,
    gain: Float64,
) -> Float32:
    """fbm(...) -> f ∈ [-1,1]; amplitude gain^i, frequency lacunarity^i,
    normalised by total amplitude (§2.4)."""
    var amp = 1.0
    var freq = 1.0
    var total_amp = 0.0
    var sum = 0.0
    for _ in range(octaves):
        sum += Float64(gradient_noise(ctx, x * freq, y * freq, z * freq)) * amp
        total_amp += amp
        amp *= gain
        freq *= lacunarity
    if total_amp == 0.0:
        return Float32(0.0)
    var v = sum / total_amp
    if v > 1.0:
        v = 1.0
    if v < -1.0:
        v = -1.0
    return Float32(v)


# ---------------------------------------------------------------------------
# RidgedNoise (§2.3)
# ---------------------------------------------------------------------------

def ridged(
    ctx: NoiseContext,
    x: Float64,
    y: Float64,
    z: Float64,
    octaves: Int,
    lacunarity: Float64,
    gain: Float64,
) -> Float32:
    """ridged(...) -> f ∈ [0,1]; r = 1 - |2N - 1| per octave with spectral
    weight gain^i; ridge crests (maxima) approach 1 (§2.3)."""
    var amp = 1.0
    var freq = 1.0
    var total_amp = 0.0
    var sum = 0.0
    for _ in range(octaves):
        var n = Float64(gradient_noise(ctx, x * freq, y * freq, z * freq))
        var r = 1.0 - abs(2.0 * n - 1.0)
        sum += r * amp
        total_amp += amp
        amp *= gain
        freq *= lacunarity
    if total_amp == 0.0:
        return Float32(0.0)
    var v = sum / total_amp
    if v > 1.0:
        v = 1.0
    if v < 0.0:
        v = 0.0
    return Float32(v)
