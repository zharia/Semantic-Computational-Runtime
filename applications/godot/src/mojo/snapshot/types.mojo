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
comptime SKY_BYTES: Int = 64  # 16×f32 (schema 3, 0004 §1.1 — was 8×f32)
comptime MATERIALS_HEADER_BYTES: Int = 4
comptime MATERIAL_RECORD_BYTES: Int = 36
comptime VOLCANO_BYTES: Int = 32  # 7×f32 + u8 effusion_state + 3 pad
comptime PLUME_BYTES: Int = 32  # 8×f32

comptime SEC_PLAYER: UInt32 = 1
comptime SEC_TERRAIN_META: UInt32 = 2
comptime SEC_TERRAIN: UInt32 = 3
comptime SEC_OCEAN: UInt32 = 4
comptime SEC_SKY: UInt32 = 5
comptime SEC_MATERIALS: UInt32 = 6
comptime SEC_VOLCANO: UInt32 = 7  # schema 2 (milestone_0003 §3.2)
comptime SEC_PLUME: UInt32 = 8
comptime SEC_SHORE_FOAM: UInt32 = 9  # schema 4 (milestone_0005 §3.3)
comptime SEC_FLORA: UInt32 = 10  # schema 5 (milestone_0006 §1.1 sibling rebase)
comptime SEC_FAUNA: UInt32 = 11  # schema 5 (milestone_0006 §1.1 sibling rebase)

# §10 FLORA / §11 FAUNA framing (104_contract §4.3): u32 count header, then
# records of 24 B (FLORA) / 20 B (FAUNA) — layouts locked by 0006 §3.2.
comptime FLORA_HEADER_BYTES: Int = 4
comptime FLORA_RECORD_BYTES: Int = 24  # f32×3 + f32 yaw + f32 scale + u32 id
comptime FAUNA_HEADER_BYTES: Int = 4
comptime FAUNA_RECORD_BYTES: Int = 20  # f32×3 + f32 yaw + u8 id + u8×3 pad

# §9 SHORE_FOAM framing (104_contract §4.3): u32 grid_n + f32 cell_size
# + f32 sea_level = 12-byte header, then grid_n² f32 foam values.
comptime SHORE_FOAM_HEADER_BYTES: Int = 12
comptime SHORE_FOAM_MAX_GRID: Int = 1024  # decode-side sanity bound


struct FloraInstance(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """One §10 FLORA record (0006 §3.2 — 24 bytes exactly): world-frame
    position (y = surface height at the anchor cell), yaw (rad), uniform
    scale (> 0) and the sim species enum (species → catalog table in
    materials/catalog.mojo). Pose only — no animation phase (0006 AP-12)."""

    var x: Float32
    var y: Float32
    var z: Float32
    var yaw: Float32
    var scale: Float32
    var species_id: UInt32

    def __init__(out self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.yaw = 0.0
        self.scale = 1.0
        self.species_id = 0

    def __init__(
        out self,
        x: Float32,
        y: Float32,
        z: Float32,
        yaw: Float32,
        scale: Float32,
        species_id: UInt32,
    ):
        self.x = x
        self.y = y
        self.z = z
        self.yaw = yaw
        self.scale = scale
        self.species_id = species_id

    def __deinit__(deinit self):
        pass


struct FlockBird(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """One §11 FAUNA record (0006 §3.2 — 20 bytes exactly): world-frame
    position, heading yaw (rad), u8 species (0 = seabird) and 3 zero pad
    bytes. Pose only — wing flap runs display-side on TIME (0006 AP-12)."""

    var x: Float32
    var y: Float32
    var z: Float32
    var yaw: Float32
    var species_id: UInt8
    var pad0: UInt8
    var pad1: UInt8
    var pad2: UInt8

    def __init__(out self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.yaw = 0.0
        self.species_id = 0
        self.pad0 = 0
        self.pad1 = 0
        self.pad2 = 0

    def __init__(
        out self,
        x: Float32,
        y: Float32,
        z: Float32,
        yaw: Float32,
        species_id: UInt8,
    ):
        self.x = x
        self.y = y
        self.z = z
        self.yaw = yaw
        self.species_id = species_id
        self.pad0 = 0
        self.pad1 = 0
        self.pad2 = 0

    def __deinit__(deinit self):
        pass


struct VOLCANO(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Section 7 payload (104_contract §4.3, milestone_0003 §3.2 — locked):
    7×f32 (28 bytes) + u8 effusion_state (offset 28) + 3 pad = exactly 32.
    Wire layout = field order below; pad0..pad2 are always written as 0."""

    var center_x: Float32
    var center_z: Float32
    var radius: Float32
    var lake_level: Float32
    var emissive_intensity: Float32
    var crust_fraction: Float32
    var glow_intensity: Float32
    var effusion_state: UInt8  # 0 dormant, 1 effusing
    var pad0: UInt8
    var pad1: UInt8
    var pad2: UInt8

    def __init__(out self):
        self.center_x = 0.0
        self.center_z = 0.0
        self.radius = 0.0
        self.lake_level = 0.0
        self.emissive_intensity = 0.0
        self.crust_fraction = 0.0
        self.glow_intensity = 0.0
        self.effusion_state = 0
        self.pad0 = 0
        self.pad1 = 0
        self.pad2 = 0

    def __deinit__(deinit self):
        pass


struct PLUME(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Section 8 payload (104_contract §4.3, milestone_0003 §3.2 — locked):
    8×f32 = exactly 32 bytes. rate == 0 ⇒ emitter idle."""

    var origin_x: Float32
    var origin_y: Float32
    var origin_z: Float32
    var rate: Float32
    var initial_velocity: Float32
    var spread: Float32
    var turbulence: Float32
    var lifetime: Float32

    def __init__(out self):
        self.origin_x = 0.0
        self.origin_y = 0.0
        self.origin_z = 0.0
        self.rate = 0.0
        self.initial_velocity = 0.0
        self.spread = 0.0
        self.turbulence = 0.0
        self.lifetime = 0.0

    def __deinit__(deinit self):
        pass


def put_volcano(mut buf: List[UInt8], v: VOLCANO):
    """Serialize the VOLCANO section: f32×7 at 0,4,…,24; u8 at 28; pad 29..31."""
    put_f32(buf, v.center_x)
    put_f32(buf, v.center_z)
    put_f32(buf, v.radius)
    put_f32(buf, v.lake_level)
    put_f32(buf, v.emissive_intensity)
    put_f32(buf, v.crust_fraction)
    put_f32(buf, v.glow_intensity)
    put_u8(buf, v.effusion_state)
    put_u8(buf, v.pad0)
    put_u8(buf, v.pad1)
    put_u8(buf, v.pad2)


def put_plume(mut buf: List[UInt8], p: PLUME):
    """Serialize the PLUME section: f32×8 at 0,4,…,28."""
    put_f32(buf, p.origin_x)
    put_f32(buf, p.origin_y)
    put_f32(buf, p.origin_z)
    put_f32(buf, p.rate)
    put_f32(buf, p.initial_velocity)
    put_f32(buf, p.spread)
    put_f32(buf, p.turbulence)
    put_f32(buf, p.lifetime)


def put_flora(mut buf: List[UInt8], instances: List[FloraInstance]):
    """Serialize the §10 FLORA payload: u32 count + count×24 B records
    (f32×3 position, f32 yaw, f32 scale, u32 species_id) — 0006 §3.2."""
    put_u32(buf, UInt32(len(instances)))
    for i in range(len(instances)):
        var inst = instances[i]
        put_f32(buf, inst.x)
        put_f32(buf, inst.y)
        put_f32(buf, inst.z)
        put_f32(buf, inst.yaw)
        put_f32(buf, inst.scale)
        put_u32(buf, inst.species_id)


def put_fauna(mut buf: List[UInt8], birds: List[FlockBird]):
    """Serialize the §11 FAUNA payload: u32 count + count×20 B records
    (f32×3 position, f32 yaw, u8 species_id, u8×3 pad = 0) — 0006 §3.2."""
    put_u32(buf, UInt32(len(birds)))
    for i in range(len(birds)):
        var b = birds[i]
        put_f32(buf, b.x)
        put_f32(buf, b.y)
        put_f32(buf, b.z)
        put_f32(buf, b.yaw)
        put_u8(buf, b.species_id)
        put_u8(buf, b.pad0)
        put_u8(buf, b.pad1)
        put_u8(buf, b.pad2)


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
