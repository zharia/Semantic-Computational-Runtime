# RenderSnapshot decoder — validation-only mirror of encode.mojo
# (104_contract.md §4). Used by spec tests and the Godot adapter's decode
# path documentation; decode errors are loud (§8: never silently coerced).

from std.collections import List

from sim.parameters import SCHEMA_VERSION, FLORA_N_MAX, FLOCK_N_MAX
from materials.catalog import SPECIES_NONE, SPECIES_COUNT
from snapshot.types import (
    ENVELOPE_BYTES,
    SECTION_HEADER_BYTES,
    SHORE_FOAM_HEADER_BYTES,
    SHORE_FOAM_MAX_GRID,
    SEC_PLAYER,
    SEC_TERRAIN_META,
    SEC_TERRAIN,
    SEC_OCEAN,
    SEC_SKY,
    SEC_MATERIALS,
    SEC_VOLCANO,
    SEC_PLUME,
    SEC_SHORE_FOAM,
    SEC_FLORA,
    SEC_FAUNA,
    SEC_HOTBAR,
    SEC_TARGET,
    SEC_RIGID_BODIES,
    HOTBAR_BYTES,
    HOTBAR_SLOT_WIRE,
    TARGET_BYTES,
    RIGID_HEADER_BYTES,
    RIGID_RECORD_BYTES,
    RIGID_BODIES_MAX,
    FLORA_HEADER_BYTES,
    FLORA_RECORD_BYTES,
    FAUNA_HEADER_BYTES,
    FAUNA_RECORD_BYTES,
    VOLCANO_BYTES,
    PLUME_BYTES,
    SKY_BYTES,
    VOLCANO,
    PLUME,
    TARGET,
    RigidBodyRecord,
    FloraInstance,
    FlockBird,
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
    if env.schema_version != SCHEMA_VERSION:
        raise Error(
            "unsupported schema version "
            + String(env.schema_version)
            + " (expected "
            + String(SCHEMA_VERSION)
            + ")"
        )
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
        or id == SEC_VOLCANO
        or id == SEC_PLUME
        or id == SEC_SHORE_FOAM
        or id == SEC_FLORA
        or id == SEC_FAUNA
        or id == SEC_HOTBAR
        or id == SEC_TARGET
        or id == SEC_RIGID_BODIES
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
    """64-byte SKY → 16×f32 (schema 3): hours, az, el, fog_d, fog_r, fog_g,
    fog_b, sun_i, sun_r, sun_g, sun_b, cloud, precip, wind_x, wind_z, wet."""
    if sec.length != SKY_BYTES:
        raise Error("SKY section must be " + String(SKY_BYTES) + " bytes")
    var out = List[Float32]()
    for i in range(16):
        out.append(get_f32(data, sec.offset + 4 * i))
    return out^


def read_volcano(data: List[UInt8], sec: SectionRef) raises -> VOLCANO:
    """32-byte VOLCANO (§4.3 §7): f32×7 @0..24, u8 effusion_state @28,
    3 pad bytes @29..31 that MUST be zero (loud, never silently coerced)."""
    if sec.length != VOLCANO_BYTES:
        raise Error("VOLCANO section must be " + String(VOLCANO_BYTES) + " bytes")
    var v = VOLCANO()
    var o = sec.offset
    v.center_x = get_f32(data, o)
    v.center_z = get_f32(data, o + 4)
    v.radius = get_f32(data, o + 8)
    v.lake_level = get_f32(data, o + 12)
    v.emissive_intensity = get_f32(data, o + 16)
    v.crust_fraction = get_f32(data, o + 20)
    v.glow_intensity = get_f32(data, o + 24)
    v.effusion_state = get_u8(data, o + 28)
    if v.effusion_state > 1:
        raise Error(
            "VOLCANO effusion_state must be 0 or 1, got "
            + String(v.effusion_state)
        )
    v.pad0 = get_u8(data, o + 29)
    v.pad1 = get_u8(data, o + 30)
    v.pad2 = get_u8(data, o + 31)
    if v.pad0 != 0 or v.pad1 != 0 or v.pad2 != 0:
        raise Error("VOLCANO pad nonzero at bytes 29..31")
    return v^


def read_plume(data: List[UInt8], sec: SectionRef) raises -> PLUME:
    """32-byte PLUME (§4.3 §8): 8×f32. rate == 0 ⇒ emitter idle."""
    if sec.length != PLUME_BYTES:
        raise Error("PLUME section must be " + String(PLUME_BYTES) + " bytes")
    var p = PLUME()
    var o = sec.offset
    p.origin_x = get_f32(data, o)
    p.origin_y = get_f32(data, o + 4)
    p.origin_z = get_f32(data, o + 8)
    p.rate = get_f32(data, o + 12)
    p.initial_velocity = get_f32(data, o + 16)
    p.spread = get_f32(data, o + 20)
    p.turbulence = get_f32(data, o + 24)
    p.lifetime = get_f32(data, o + 28)
    if p.lifetime <= 0.0:
        raise Error("PLUME lifetime must be > 0")
    if p.rate < 0.0:
        raise Error("PLUME rate must be >= 0")
    return p^


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


# --- Schema 4 (milestone_0005) readers ---------------------------------------

struct TerrainTuple(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """One TERRAIN vertex blend tuple (schema 4): (u8 dominant catalog id,
    u8 blend partner catalog id, u8 weight 0..255, u8 pad = 0)."""

    var material: UInt8
    var blend: UInt8
    var weight: UInt8
    var pad: UInt8

    def __init__(out self, material: UInt8, blend: UInt8, weight: UInt8, pad: UInt8):
        self.material = material
        self.blend = blend
        self.weight = weight
        self.pad = pad

    def __deinit__(deinit self):
        pass


def read_terrain_tuple(data: List[UInt8], off: Int) raises -> TerrainTuple:
    """Read one 4-byte vertex tuple at absolute offset `off`; pad MUST be 0
    (loud decode — §8, never silently coerced)."""
    var t = TerrainTuple(
        get_u8(data, off),
        get_u8(data, off + 1),
        get_u8(data, off + 2),
        get_u8(data, off + 3),
    )
    if t.pad != 0:
        raise Error("TERRAIN tuple pad nonzero at offset " + String(off))
    return t


def read_shore_foam(data: List[UInt8], sec: SectionRef) raises -> List[Float32]:
    """9 SHORE_FOAM → [grid_n, cell_size, sea_level, foam_0 .. foam_{n²-1}].

    Validates framing: length == 12 + 4·grid_n², 0 < grid_n ≤ 1024, and
    every foam value ∈ [0, 1] (loud on violation, §8)."""
    if sec.length < SHORE_FOAM_HEADER_BYTES:
        raise Error("SHORE_FOAM section shorter than its header")
    var o = sec.offset
    var grid_n = get_u32(data, o)
    if grid_n == 0 or Int(grid_n) > SHORE_FOAM_MAX_GRID:
        raise Error("SHORE_FOAM grid_n out of range: " + String(grid_n))
    var expect = SHORE_FOAM_HEADER_BYTES + 4 * Int(grid_n) * Int(grid_n)
    if sec.length != expect:
        raise Error(
            "SHORE_FOAM section must be " + String(expect)
            + " bytes, got " + String(sec.length)
        )
    var cell_size = get_f32(data, o + 4)
    var sea_level = get_f32(data, o + 8)
    var out = List[Float32]()
    out.append(Float32(grid_n))
    out.append(cell_size)
    out.append(sea_level)
    for i in range(Int(grid_n) * Int(grid_n)):
        var v = get_f32(data, o + SHORE_FOAM_HEADER_BYTES + 4 * i)
        if v < 0.0 or v > 1.0:
            raise Error(
                "SHORE_FOAM value out of [0,1] at index " + String(i)
            )
        out.append(v)
    return out^


# --- Schema 5 (milestone_0006) readers ----------------------------------------

def read_flora(data: List[UInt8], sec: SectionRef) raises -> List[FloraInstance]:
    """10 FLORA: u32 count + count×24 B (f32×3, yaw, scale, u32 species_id).
    Framing must be exact (4 + 24·count); count ≤ FLORA_N_MAX (AP-13);
    species_id ∈ 1..SPECIES_COUNT-1 (SPECIES_NONE never emitted)."""
    if sec.length < FLORA_HEADER_BYTES:
        raise Error("FLORA section shorter than its header")
    var count = get_u32(data, sec.offset)
    var expect = FLORA_HEADER_BYTES + FLORA_RECORD_BYTES * Int(count)
    if sec.length != expect:
        raise Error(
            "FLORA section must be " + String(expect) + " bytes, got "
            + String(sec.length)
        )
    if Int(count) > FLORA_N_MAX:
        raise Error("FLORA count exceeds FLORA_N_MAX: " + String(count))
    var out = List[FloraInstance]()
    var o = sec.offset + FLORA_HEADER_BYTES
    for _i in range(Int(count)):
        var inst = FloraInstance()
        inst.x = get_f32(data, o)
        inst.y = get_f32(data, o + 4)
        inst.z = get_f32(data, o + 8)
        inst.yaw = get_f32(data, o + 12)
        inst.scale = get_f32(data, o + 16)
        inst.species_id = get_u32(data, o + 20)
        if inst.species_id == SPECIES_NONE or inst.species_id >= UInt32(SPECIES_COUNT):
            raise Error("FLORA species_id out of range: " + String(inst.species_id))
        if inst.scale <= 0.0:
            raise Error("FLORA scale must be > 0")
        out.append(inst)
        o += FLORA_RECORD_BYTES
    return out^


def read_fauna(data: List[UInt8], sec: SectionRef) raises -> List[FlockBird]:
    """11 FAUNA: u32 count + count×20 B (f32×3, yaw, u8 species_id, u8×3 pad
    = 0 — loud on violation, §8). Framing exact: 4 + 20·count;
    count ≤ FLOCK_N_MAX (AP-13); species_id ≤ 255 (u8)."""
    if sec.length < FAUNA_HEADER_BYTES:
        raise Error("FAUNA section shorter than its header")
    var count = get_u32(data, sec.offset)
    var expect = FAUNA_HEADER_BYTES + FAUNA_RECORD_BYTES * Int(count)
    if sec.length != expect:
        raise Error(
            "FAUNA section must be " + String(expect) + " bytes, got "
            + String(sec.length)
        )
    if Int(count) > FLOCK_N_MAX:
        raise Error("FAUNA count exceeds FLOCK_N_MAX: " + String(count))
    var out = List[FlockBird]()
    var o = sec.offset + FAUNA_HEADER_BYTES
    for _i in range(Int(count)):
        var b = FlockBird()
        b.x = get_f32(data, o)
        b.y = get_f32(data, o + 4)
        b.z = get_f32(data, o + 8)
        b.yaw = get_f32(data, o + 12)
        b.species_id = get_u8(data, o + 16)
        b.pad0 = get_u8(data, o + 17)
        b.pad1 = get_u8(data, o + 18)
        b.pad2 = get_u8(data, o + 19)
        if b.pad0 != 0 or b.pad1 != 0 or b.pad2 != 0:
            raise Error("FAUNA pad nonzero at offset " + String(o + 17))
        out.append(b)
        o += FAUNA_RECORD_BYTES
    return out^


# --- Schema 6 (milestone_0007) readers ----------------------------------------


struct HotbarView(Copyable, Movable, Deinitable):
    """Decoded 12 HOTBAR: u32 count (= 9), u32 selected_index (0-based),
    9×u32 stable catalog ids (0007 §3.3)."""

    var count: UInt32
    var selected_index: UInt32
    var slot_ids: List[UInt32]

    def __init__(out self):
        self.count = 0
        self.selected_index = 0
        self.slot_ids = List[UInt32]()

    def __deinit__(deinit self):
        pass


def read_hotbar(data: List[UInt8], sec: SectionRef) raises -> HotbarView:
    """12 HOTBAR: 44-byte fixed section — count must be 9 and the selected
    index must address a slot (loud, §8)."""
    if sec.length != HOTBAR_BYTES:
        raise Error(
            "HOTBAR section must be " + String(HOTBAR_BYTES)
            + " bytes, got " + String(sec.length)
        )
    var o = sec.offset
    var out = HotbarView()
    out.count = get_u32(data, o)
    if Int(out.count) != HOTBAR_SLOT_WIRE:
        raise Error("HOTBAR count must be " + String(HOTBAR_SLOT_WIRE) + ", got " + String(out.count))
    out.selected_index = get_u32(data, o + 4)
    if out.selected_index >= out.count:
        raise Error("HOTBAR selected_index out of range: " + String(out.selected_index))
    for i in range(Int(out.count)):
        out.slot_ids.append(get_u32(data, o + 8 + 4 * i))
    return out^


def read_target(data: List[UInt8], sec: SectionRef) raises -> TARGET:
    """13 TARGET: 32-byte fixed section — pad bytes MUST be 0 and a miss
    (hit == 0) must carry all-zero fields (loud, §8)."""
    if sec.length != TARGET_BYTES:
        raise Error(
            "TARGET section must be " + String(TARGET_BYTES)
            + " bytes, got " + String(sec.length)
        )
    var o = sec.offset
    var t = TARGET()
    t.hit = get_u8(data, o)
    if t.hit > 1:
        raise Error("TARGET hit must be 0 or 1, got " + String(t.hit))
    if get_u8(data, o + 1) != 0 or get_u8(data, o + 2) != 0 or get_u8(data, o + 3) != 0:
        raise Error("TARGET pad nonzero at bytes 1..3")
    t.material_id = get_u32(data, o + 4)
    t.hit_x = get_f32(data, o + 8)
    t.hit_y = get_f32(data, o + 12)
    t.hit_z = get_f32(data, o + 16)
    t.cell_x = get_u32(data, o + 20)
    t.cell_lattice_y = get_u32(data, o + 24)
    t.cell_z = get_u32(data, o + 28)
    if t.hit == 0 and (
        t.material_id != 0
        or t.hit_x != 0.0
        or t.hit_y != 0.0
        or t.hit_z != 0.0
        or t.cell_x != 0
        or t.cell_lattice_y != 0
        or t.cell_z != 0
    ):
        raise Error("TARGET miss must carry all-zero fields")
    return t


def read_rigid_bodies(data: List[UInt8], sec: SectionRef) raises -> List[RigidBodyRecord]:
    """14 RIGID_BODIES: u32 count (≤ 16) + count×36 B records; framing must
    be exact (0007 §3.3, §8 loud)."""
    if sec.length < RIGID_HEADER_BYTES:
        raise Error("RIGID_BODIES section shorter than its header")
    var count = get_u32(data, sec.offset)
    if Int(count) > RIGID_BODIES_MAX:
        raise Error("RIGID_BODIES count exceeds " + String(RIGID_BODIES_MAX) + ": " + String(count))
    var expect = RIGID_HEADER_BYTES + RIGID_RECORD_BYTES * Int(count)
    if sec.length != expect:
        raise Error(
            "RIGID_BODIES section must be " + String(expect)
            + " bytes, got " + String(sec.length)
        )
    var out = List[RigidBodyRecord]()
    var o = sec.offset + RIGID_HEADER_BYTES
    for _i in range(Int(count)):
        var r = RigidBodyRecord()
        r.x = get_f32(data, o)
        r.y = get_f32(data, o + 4)
        r.z = get_f32(data, o + 8)
        r.euler_x = get_f32(data, o + 12)
        r.euler_y = get_f32(data, o + 16)
        r.euler_z = get_f32(data, o + 20)
        r.shape = get_u32(data, o + 24)
        r.size = get_f32(data, o + 28)
        r.material_id = get_u32(data, o + 32)
        if r.shape > 1:
            raise Error("RIGID_BODIES shape must be 0 or 1, got " + String(r.shape))
        out.append(r)
        o += RIGID_RECORD_BYTES
    return out^
