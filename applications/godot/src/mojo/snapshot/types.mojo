# Snapshot byte layout constants + little-endian buffer primitives
# (104_contract.md §4; adapter/scr_godot_abi.h section ids).
#
# All writes/reads are explicit byte-at-a-time little-endian — never native
# memory casts (endianness is contract-mandated, not host-dependent).
#
# Float encoding uses `to_bits()` (verified in Mojo 1.0.0). Float decoding is
# the exact inverse done in Float64 arithmetic: for every finite f32/f64 bit
# pattern the formula (1 + frac·2^-k)·2^(exp−bias) is exact in Float64
# (24/53-bit significands fit), so round-trip encode→decode is lossless.
# Non-finite patterns (exp==255 / 0x7FF) are rejected loudly — the sim only
# ever emits finite values (104_contract §8: decode errors are loud).

from std.collections import List
from std.math import exp2
from sim.parameters import SNAPSHOT_MAGIC, SCHEMA_VERSION

comptime ENVELOPE_BYTES: Int = 48
comptime SECTION_HEADER_BYTES: Int = 8
comptime PLAYER_BYTES: Int = 44
comptime TERRAIN_META_BYTES: Int = 32
comptime OCEAN_BYTES: Int = 32
comptime SKY_BYTES: Int = 32
comptime MATERIALS_HEADER_BYTES: Int = 4
comptime MATERIAL_RECORD_BYTES: Int = 36

comptime SEC_PLAYER: UInt32 = 1
comptime SEC_TERRAIN_META: UInt32 = 2
comptime SEC_TERRAIN: UInt32 = 3
comptime SEC_OCEAN: UInt32 = 4
comptime SEC_SKY: UInt32 = 5
comptime SEC_MATERIALS: UInt32 = 6


def put_u8(mut buf: List[UInt8], v: UInt8):
    buf.append(v)


def put_u32(mut buf: List[UInt8], v: UInt32):
    buf.append(UInt8(v & 0xFF))
    buf.append(UInt8((v >> 8) & 0xFF))
    buf.append(UInt8((v >> 16) & 0xFF))
    buf.append(UInt8((v >> 24) & 0xFF))


def put_f32(mut buf: List[UInt8], v: Float32):
    put_u32(buf, UInt32(v.to_bits()))


def put_f64(mut buf: List[UInt8], v: Float64):
    var bits = UInt64(v.to_bits())
    for i in range(8):
        buf.append(UInt8((bits >> UInt64(8 * i)) & 0xFF))


def get_u8(data: List[UInt8], off: Int) -> UInt8:
    return data[off]


def get_u32(data: List[UInt8], off: Int) -> UInt32:
    return (
        UInt32(data[off])
        | (UInt32(data[off + 1]) << 8)
        | (UInt32(data[off + 2]) << 16)
        | (UInt32(data[off + 3]) << 24)
    )


def get_f32(data: List[UInt8], off: Int) raises -> Float32:
    var b = get_u32(data, off)
    var sign = 1.0
    if (b >> 31) != 0:
        sign = -1.0
    var exp = Int((b >> 23) & 0xFF)
    var frac = b & 0x7FFFFF
    if exp == 255:
        raise Error("non-finite f32 in snapshot at offset " + String(off))
    if exp == 0:
        if frac == 0:
            return Float32(sign * 0.0)
        # Subnormal: frac · 2^-149.
        return Float32(sign * Float64(frac) * exp2(-149.0))
    return Float32(sign * (1.0 + Float64(frac) * exp2(-23.0)) * exp2(Float64(exp - 127)))


def get_f64(data: List[UInt8], off: Int) raises -> Float64:
    var lo = get_u32(data, off)
    var hi = get_u32(data, off + 4)
    var sign = 1.0
    if (hi >> 31) != 0:
        sign = -1.0
    var exp = Int((hi >> 20) & 0x7FF)
    # 52-bit fraction: hi's low 20 bits (high part) | lo (low 32 bits).
    var frac52 = (UInt64(hi & 0xFFFFF) << 32) | UInt64(lo)
    if exp == 2047:
        raise Error("non-finite f64 in snapshot at offset " + String(off))
    if exp == 0:
        if frac52 == 0:
            return sign * 0.0
        return sign * Float64(frac52) * exp2(-1074.0)
    return sign * (1.0 + Float64(frac52) * exp2(-52.0)) * exp2(Float64(exp - 1023))


def magic_ok(data: List[UInt8]) -> Bool:
    return len(data) >= ENVELOPE_BYTES and get_u32(data, 0) == SNAPSHOT_MAGIC


def schema_version_of(data: List[UInt8]) -> UInt32:
    if len(data) < ENVELOPE_BYTES:
        return 0
    return get_u32(data, 4)
