# RenderSnapshot decoder — validation-only mirror of encode.mojo
# (104_contract.md §4). Used by spec tests and the Godot adapter's decode
# path documentation; decode errors are loud (§8: never silently coerced).

from std.collections import List

from snapshot.types import (
    ENVELOPE_BYTES,
    SECTION_HEADER_BYTES,
    SEC_PLAYER,
    SEC_TERRAIN_META,
    SEC_TERRAIN,
    SEC_OCEAN,
    SEC_SKY,
    SEC_MATERIALS,
    get_u8,
    get_u32,
    get_f32,
    get_f64,
)

struct Envelope(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var magic: UInt32
    var schema_version: UInt32
    var section_count: UInt32
    var world_version: UInt32
    var state_generation: UInt32
    var simulation_tick: UInt32
    var determinism_epoch: UInt32
    var seed: UInt32
    var simulation_time: Float64
    var payload_bytes: UInt32
    var reserved: UInt32

    def __init__(out self):
        self.magic = 0
        self.schema_version = 0
        self.section_count = 0
        self.world_version = 0
        self.state_generation = 0
        self.simulation_tick = 0
        self.determinism_epoch = 0
        self.seed = 0
        self.simulation_time = 0.0
        self.payload_bytes = 0
        self.reserved = 0

    def __deinit__(deinit self):
        pass


struct SectionRef(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var section_id: UInt32
    var offset: Int  # absolute offset of `data` within the snapshot
    var length: Int  # section_bytes (data only)

    def __init__(out self, section_id: UInt32, offset: Int, length: Int):
        self.section_id = section_id
        self.offset = offset
        self.length = length

    def __deinit__(deinit self):
        pass


def decode_envelope(data: List[UInt8]) raises -> Envelope:
    if len(data) < ENVELOPE_BYTES:
        raise Error("snapshot shorter than envelope")
    var env = Envelope()
    env.magic = get_u32(data, 0)
    if env.magic != 0x53524353:
        raise Error("bad snapshot magic")
    env.schema_version = get_u32(data, 4)
    if env.schema_version != 1:
        raise Error("unsupported schema version " + String(env.schema_version))
    env.section_count = get_u32(data, 8)
    env.world_version = get_u32(data, 12)
    env.state_generation = get_u32(data, 16)
    env.simulation_tick = get_u32(data, 20)
    env.determinism_epoch = get_u32(data, 24)
    env.seed = get_u32(data, 28)
    env.simulation_time = get_f64(data, 32)
    env.payload_bytes = get_u32(data, 40)
    env.reserved = get_u32(data, 44)
    if env.reserved != 0:
        raise Error("reserved field nonzero")
    if Int(env.payload_bytes) != len(data) - ENVELOPE_BYTES:
        raise Error("payload_bytes does not match buffer length")
    return env^


def _known_id(id: UInt32) -> Bool:
    return (
        id == SEC_PLAYER
        or id == SEC_TERRAIN_META
        or id == SEC_TERRAIN
        or id == SEC_OCEAN
        or id == SEC_SKY
        or id == SEC_MATERIALS
    )


def decode_sections(data: List[UInt8], env: Envelope) raises -> List[SectionRef]:
    """Walk section framing; validate sizes, ids, and total payload."""
    var secs = List[SectionRef]()
    var off = ENVELOPE_BYTES
    var end = ENVELOPE_BYTES + Int(env.payload_bytes)
    var seen = List[UInt32]()
    for _i in range(Int(env.section_count)):
        if off + SECTION_HEADER_BYTES > end:
            raise Error("section header overruns payload")
        var id = get_u32(data, off)
        var nbytes = Int(get_u32(data, off + 4))
        if not _known_id(id):
            raise Error("unknown section id " + String(id))
        for j in range(len(seen)):
            if seen[j] == id:
                raise Error("duplicate section id " + String(id))
        if off + SECTION_HEADER_BYTES + nbytes > end:
            raise Error("section data overruns payload")
        secs.append(SectionRef(id, off + SECTION_HEADER_BYTES, nbytes))
        seen.append(id)
        off += SECTION_HEADER_BYTES + nbytes
    if off != end:
        raise Error("payload has trailing bytes")
    return secs^


def find_section(secs: List[SectionRef], section_id: UInt32) -> Int:
    for i in range(len(secs)):
        if secs[i].section_id == section_id:
            return i
    return -1


# --- Field readers (mirror encode.mojo byte-for-byte) -----------------------

def read_player(data: List[UInt8], sec: SectionRef) raises -> List[Float32]:
    """44-byte PLAYER → [px,py,pz, vx,vy,vz, yaw, pitch, eye, ground, water]."""
    if sec.length != 44:
        raise Error("PLAYER section must be 44 bytes")
    var out = List[Float32]()
    var o = sec.offset
    for i in range(9):
        out.append(get_f32(data, o + 4 * i))
    out.append(Float32(get_u8(data, o + 36)))
    out.append(Float32(get_u8(data, o + 37)))
    for i in range(38, 44):
        if get_u8(data, o + i) != 0:
            raise Error("PLAYER pad nonzero at byte " + String(i))
    return out^


def read_terrain_meta(data: List[UInt8], sec: SectionRef) raises -> List[Float32]:
    """32-byte TERRAIN_META → [sea, peak, sx, sy, sz, grid_n, cell, chunks]."""
    if sec.length != 32:
        raise Error("TERRAIN_META section must be 32 bytes")
    var out = List[Float32]()
    var o = sec.offset
    out.append(get_f32(data, o))
    out.append(get_f32(data, o + 4))
    out.append(get_f32(data, o + 8))
    out.append(get_f32(data, o + 12))
    out.append(get_f32(data, o + 16))
    out.append(Float32(get_u32(data, o + 20)))
    out.append(get_f32(data, o + 24))
    out.append(Float32(get_u32(data, o + 28)))
    return out^


def read_ocean(data: List[UInt8], sec: SectionRef) raises -> List[Float32]:
    """32-byte OCEAN → 8×f32 (sea, amp, freq, steep, dirx, dirz, speed, phase)."""
    if sec.length != 32:
        raise Error("OCEAN section must be 32 bytes")
    var out = List[Float32]()
    for i in range(8):
        out.append(get_f32(data, sec.offset + 4 * i))
    return out^


def read_sky(data: List[UInt8], sec: SectionRef) raises -> List[Float32]:
    """32-byte SKY → 8×f32 (hours, az, el, fog_d, fog_r, fog_g, fog_b, sun_i)."""
    if sec.length != 32:
        raise Error("SKY section must be 32 bytes")
    var out = List[Float32]()
    for i in range(8):
        out.append(get_f32(data, sec.offset + 4 * i))
    return out^


def read_materials_count(data: List[UInt8], sec: SectionRef) raises -> UInt32:
    if sec.length < 4:
        raise Error("MATERIALS section too short")
    var count = get_u32(data, sec.offset)
    if Int(count) * 36 + 4 != sec.length:
        raise Error("MATERIALS section length mismatch")
    return count


def read_material_record(
    data: List[UInt8], sec: SectionRef, index: Int
) raises -> List[Float32]:
    """One 36-byte record → [id, ar, ag, ab, rough, er, eg, eb, opacity]."""
    var count = Int(read_materials_count(data, sec))
    if index < 0 or index >= count:
        raise Error("material record index out of range")
    var o = sec.offset + 4 + index * 36
    var out = List[Float32]()
    out.append(Float32(get_u32(data, o)))
    for i in range(8):
        out.append(get_f32(data, o + 4 + 4 * i))
    return out^


def read_terrain_header(data: List[UInt8], sec: SectionRef) raises -> UInt32:
    if sec.length < 4:
        raise Error("TERRAIN section too short")
    return get_u32(data, sec.offset)


def read_terrain_chunk_header(
    data: List[UInt8], sec: SectionRef, chunk_index: Int
) raises -> List[Float32]:
    """Returns [ox, oy, oz, vert_count, idx_count] for one chunk record.
    Walks chunk records from the section start (variable-size records)."""
    var count = Int(read_terrain_header(data, sec))
    if chunk_index < 0 or chunk_index >= count:
        raise Error("chunk index out of range")
    var o = sec.offset + 4
    for _i in range(chunk_index):
        var vc = Int(get_u32(data, o + 12))
        var ic = Int(get_u32(data, o + 16))
        o += 20 + (3 * vc + 3 * vc + vc + ic) * 4
    var out = List[Float32]()
    out.append(get_f32(data, o))
    out.append(get_f32(data, o + 4))
    out.append(get_f32(data, o + 8))
    out.append(Float32(get_u32(data, o + 12)))
    out.append(Float32(get_u32(data, o + 16)))
    return out^


def terrain_chunk_byte_span(
    data: List[UInt8], sec: SectionRef, chunk_index: Int
) raises -> Tuple[Int, Int]:
    """(record_start, record_end) offsets of one chunk record."""
    var count = Int(read_terrain_header(data, sec))
    if chunk_index < 0 or chunk_index >= count:
        raise Error("chunk index out of range")
    var o = sec.offset + 4
    for i in range(count):
        var vc = Int(get_u32(data, o + 12))
        var ic = Int(get_u32(data, o + 16))
        var rec = 20 + (3 * vc + 3 * vc + vc + ic) * 4
        if i == chunk_index:
            return (o, o + rec)
        o += rec
    raise Error("chunk not found")
