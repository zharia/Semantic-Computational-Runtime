# RenderSnapshot encoder — read-only projection of World → bytes
# (104_contract.md §4). Pure function: world is never mutated (invariant §1);
# the projection-purity test hashes the world before and after encoding.

from std.collections import List
from std.math import floor

from sim.world import World
from sim.flock import flock_wire
from sim.raycast import raycast_look
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    EYE_HEIGHT,
    SNAPSHOT_MAGIC,
    SCHEMA_VERSION,
)
from materials.catalog import MAT_WATER, MAT_VOCAB_COUNT
from snapshot.types import (
    ENVELOPE_BYTES,
    SECTION_HEADER_BYTES,
    SHORE_FOAM_HEADER_BYTES,
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
    TARGET_BYTES,
    RIGID_HEADER_BYTES,
    RIGID_RECORD_BYTES,
    RIGID_BODIES_MAX,
    VOLCANO,
    TARGET,
    RigidBodyRecord,
    put_hotbar,
    put_target,
    put_rigid_bodies,
    PLUME,
    put_u32,
    put_u8,
    put_f32,
    put_f64,
    put_volcano,
    put_plume,
    put_flora,
    put_fauna,
)

comptime TWO_PI: Float64 = 6.283185307179586


def _encode_player(world: World) -> List[UInt8]:
    var b = List[UInt8]()
    put_f32(b, Float32(world.player.x))
    put_f32(b, Float32(world.player.y))
    put_f32(b, Float32(world.player.z))
    put_f32(b, Float32(world.player.vel_x))
    put_f32(b, Float32(world.player.vel_y))
    put_f32(b, Float32(world.player.vel_z))
    put_f32(b, Float32(world.player.yaw))
    put_f32(b, Float32(world.player.pitch))
    put_f32(b, Float32(EYE_HEIGHT))
    b.append(UInt8(1 if world.player.on_ground else 0))
    b.append(UInt8(1 if world.player.in_water else 0))
    # Pad through byte 43: the field table ends at 40 (38: u8×2 pad) but the
    # section is declared 44 bytes; bytes 40..43 zero-fill so BOTH the table
    # offsets and the declared size hold. See report: contract ambiguity.
    for _i in range(6):
        b.append(0)
    return b^


def _encode_terrain_meta(world: World) -> List[UInt8]:
    var b = List[UInt8]()
    put_f32(b, Float32(world.hydro.ocean.sea_level))
    put_f32(b, Float32(world.island.peak_height))
    put_f32(b, Float32(world.island.spawn_x))
    put_f32(b, Float32(world.island.spawn_y))
    put_f32(b, Float32(world.island.spawn_z))
    put_u32(b, UInt32(GRID_N))
    put_f32(b, Float32(CELL_SIZE))
    put_u32(b, UInt32(world.island.chunk_count))
    return b^


def _encode_terrain(world: World) raises -> List[UInt8]:
    var b = List[UInt8]()
    put_u32(b, UInt32(world.island.chunk_count))
    for i in range(world.island.chunk_count):
        var c = world.island.chunks[i].copy()
        put_f32(b, Float32(c.origin_x))
        put_f32(b, Float32(c.origin_y))
        put_f32(b, Float32(c.origin_z))
        put_u32(b, UInt32(c.vert_count()))
        put_u32(b, UInt32(c.idx_count()))
        for j in range(len(c.vertices)):
            put_f32(b, c.vertices[j])
        for j in range(len(c.normals)):
            put_f32(b, c.normals[j])
        # Vertex payload: 4-byte blend tuple (schema 4, 0005 §3.6) —
        # (u8 dominant catalog id, u8 blend partner catalog id, u8 weight,
        #  u8 pad 0). Stride-neutral vs schema 3's per-vertex u32 material id.
        # No-blend vertices carry blend == dominant, weight == 0.
        for j in range(len(c.material_ids)):
            var mat_cat = world.catalog.defs[Int(c.material_ids[j])].catalog_index
            var partner_cat = world.catalog.defs[Int(c.blends[j].blend)].catalog_index
            if mat_cat > 255 or partner_cat > 255:
                raise Error("catalog index does not fit u8 blend tuple")
            put_u8(b, UInt8(mat_cat))
            put_u8(b, UInt8(partner_cat))
            put_u8(b, c.blends[j].weight)
            put_u8(b, 0)
        for j in range(len(c.indices)):
            put_u32(b, c.indices[j])
    return b^


def _encode_ocean(world: World) -> List[UInt8]:
    var b = List[UInt8]()
    var w = world.hydro.ocean.wave
    put_f32(b, Float32(world.hydro.ocean.sea_level))
    put_f32(b, Float32(w.amplitude))
    put_f32(b, Float32(w.wavenumber))  # frequency = k (rad/u)
    put_f32(b, Float32(w.steepness))  # Q
    put_f32(b, Float32(w.dir_x))
    put_f32(b, Float32(w.dir_z))
    put_f32(b, Float32(w.phase_speed))  # c = sqrt(|g|/k), dispersion
    # Temporal phase (−ω·t + φ) folded into [0, 2π).
    var phase = -w.omega * world.simulation_time + world.hydro.ocean.phase_offset
    phase = phase - floor(phase / TWO_PI) * TWO_PI
    if phase < 0.0:
        phase += TWO_PI
    put_f32(b, Float32(phase))
    return b^


def _encode_sky(world: World) -> List[UInt8]:
    """SKY section, schema 3 (104_contract §4.3 / 0004 §1.1): 16×f32 = 64
    bytes. First 8 fields keep their schema-1 offsets (0..31); fields 8..15
    append the sun-color triple, weather inputs and wetness. Fog density and
    fog color come from the atmosphere derivation (never display literals)."""
    var b = List[UInt8]()
    var a = world.atmosphere
    put_f32(b, Float32(a.time_of_day_hours))
    put_f32(b, Float32(a.sun_azimuth))
    put_f32(b, Float32(a.sun_elevation))
    put_f32(b, Float32(a.fog_density))
    put_f32(b, Float32(a.fog_r))
    put_f32(b, Float32(a.fog_g))
    put_f32(b, Float32(a.fog_b))
    put_f32(b, Float32(a.sun_intensity))
    put_f32(b, Float32(a.sun_color_r))
    put_f32(b, Float32(a.sun_color_g))
    put_f32(b, Float32(a.sun_color_b))
    put_f32(b, Float32(a.cloud_cover))
    put_f32(b, Float32(a.precipitation))
    put_f32(b, Float32(a.wind_x))
    put_f32(b, Float32(a.wind_z))
    put_f32(b, Float32(a.wetness))
    return b^


def _encode_materials(world: World) raises -> List[UInt8]:
    """One record per material present in the snapshot, deduplicated by
    stable catalog id, emitted in ascending voxel-code order (deterministic).
    Present = island surface vocabulary ∪ water (ocean is always shown)."""
    var present = List[UInt32]()  # voxel codes, ascending
    for code in range(MAT_VOCAB_COUNT):
        var ucode = UInt32(code)
        var found = False
        for k in range(len(world.island.used_materials)):
            if world.island.used_materials[k] == ucode:
                found = True
        if ucode == MAT_WATER:
            found = True
        if found:
            present.append(ucode)
    # Dedup by stable catalog id (bedrock and basalt both map to rock.basalt).
    var chosen = List[UInt32]()
    var chosen_ids = List[UInt32]()
    for i in range(len(present)):
        var d = world.catalog.defs[Int(present[i])].copy()
        var dup = False
        for j in range(len(chosen_ids)):
            if chosen_ids[j] == d.catalog_index:
                dup = True
        if not dup:
            chosen.append(present[i])
            chosen_ids.append(d.catalog_index)

    var b = List[UInt8]()
    put_u32(b, UInt32(len(chosen)))
    for i in range(len(chosen)):
        var d = world.catalog.defs[Int(chosen[i])].copy()
        put_u32(b, d.catalog_index)
        put_f32(b, d.albedo_r)
        put_f32(b, d.albedo_g)
        put_f32(b, d.albedo_b)
        put_f32(b, d.roughness)
        put_f32(b, d.emissive_r)
        put_f32(b, d.emissive_g)
        put_f32(b, d.emissive_b)
        put_f32(b, d.opacity)
    return b^


def _append_section(
    mut payload: List[UInt8], section_id: UInt32, data: List[UInt8]
):
    put_u32(payload, section_id)
    put_u32(payload, UInt32(len(data)))
    for i in range(len(data)):
        payload.append(data[i])


def _encode_volcano(world: World) -> List[UInt8]:
    """7 VOLCANO (32 bytes): 7×f32 + u8 effusion_state + 3 pad (§4.3)."""
    var v = VOLCANO()
    v.center_x = Float32(world.volcano.center_x)
    v.center_z = Float32(world.volcano.center_z)
    v.radius = Float32(world.volcano.radius)
    v.lake_level = Float32(world.volcano.lake_level)
    v.emissive_intensity = Float32(world.volcano.emissive_intensity)
    v.crust_fraction = Float32(world.volcano.crust_fraction)
    v.glow_intensity = Float32(world.volcano.glow_intensity)
    v.effusion_state = world.volcano.effusion_state
    var b = List[UInt8]()
    put_volcano(b, v)
    return b^


def _encode_plume(world: World) -> List[UInt8]:
    """8 PLUME (32 bytes): 8×f32 (§4.3); rate 0 ⇒ idle emitter."""
    var p = PLUME()
    p.origin_x = Float32(world.volcano.plume_origin_x)
    p.origin_y = Float32(world.volcano.plume_origin_y)
    p.origin_z = Float32(world.volcano.plume_origin_z)
    p.rate = Float32(world.volcano.plume_rate)
    p.initial_velocity = Float32(world.volcano.plume_initial_velocity)
    p.spread = Float32(world.volcano.plume_spread)
    p.turbulence = Float32(world.volcano.plume_turbulence)
    p.lifetime = Float32(world.volcano.plume_lifetime)
    var b = List[UInt8]()
    put_plume(b, p)
    return b^


def _encode_shore_foam(world: World) raises -> List[UInt8]:
    """9 SHORE_FOAM (schema 4, 104_contract §4.3): 12-byte header
    (u32 grid_n, f32 cell_size, f32 sea_level) + grid_n² f32 foam values,
    row-major (iz · grid_n + ix), element ∈ [0,1] (milestone_0005 §3.3)."""
    if len(world.foam) != GRID_N * GRID_N:
        raise Error(
            "foam field must be " + String(GRID_N * GRID_N) + " values, got "
            + String(len(world.foam))
        )
    var b = List[UInt8]()
    put_u32(b, UInt32(GRID_N))
    put_f32(b, Float32(CELL_SIZE))
    put_f32(b, Float32(world.hydro.ocean.sea_level))
    if len(b) != SHORE_FOAM_HEADER_BYTES:
        raise Error("SHORE_FOAM header size drift")
    for i in range(len(world.foam)):
        put_f32(b, world.foam[i])
    return b^


def _encode_flora(world: World) raises -> List[UInt8]:
    """10 FLORA (schema 5, 104_contract §4.3): u32 count + count×24 B
    records — f32×3 position, f32 yaw, f32 scale, u32 species_id
    (milestone_0006 §3.2). count ≤ FLORA_N_MAX (AP-13)."""
    if world.flora.count > len(world.flora.instances):
        raise Error("FLORA count exceeds instance list")
    if world.flora.count != len(world.flora.instances):
        raise Error("FLORA count drift from instance list")
    var b = List[UInt8]()
    put_flora(b, world.flora.instances)
    return b^


def _encode_fauna(world: World) -> List[UInt8]:
    """11 FAUNA (schema 5, 104_contract §4.3): u32 count + count×20 B
    records — f32×3 position, f32 yaw, u8 species_id, u8×3 pad = 0
    (milestone_0006 §3.2). Active flock slots in ascending slot order."""
    var b = List[UInt8]()
    put_fauna(b, flock_wire(world.flock))
    return b^


def _encode_hotbar(world: World) raises -> List[UInt8]:
    """12 HOTBAR (schema 6, 104_contract §4.3): u32 count (= 9), u32
    selected_index, 9×u32 stable catalog ids — 44 B (0007 §3.3)."""
    var b = List[UInt8]()
    put_hotbar(b, UInt32(world.hotbar.selected_index), world.hotbar.slot_ids)
    if len(b) != HOTBAR_BYTES:
        raise Error(
            "HOTBAR section size drift: " + String(len(b)) + " != "
            + String(HOTBAR_BYTES)
        )
    return b^


def _encode_target(world: World) raises -> List[UInt8]:
    """13 TARGET (schema 6, 104_contract §4.3): sim-owned raycast of this
    tick's player pose — 32 B (0007 §3.3). Emitted EVERY snapshot; a miss
    yields all-zero fields (HUD reads SKY / AIR)."""
    var hit = raycast_look(
        world.island,
        world.catalog,
        world.player.x,
        world.player.y,
        world.player.z,
        world.player.yaw,
        world.player.pitch,
    )
    var t = TARGET()
    if hit.hit:
        t.hit = 1
        t.material_id = hit.material_id
        t.hit_x = Float32(hit.hit_x)
        t.hit_y = Float32(hit.hit_y)
        t.hit_z = Float32(hit.hit_z)
        t.cell_x = UInt32(hit.cell_x)
        t.cell_lattice_y = UInt32(hit.cell_lattice_y)
        t.cell_z = UInt32(hit.cell_z)
    var b = List[UInt8]()
    put_target(b, t)
    if len(b) != TARGET_BYTES:
        raise Error(
            "TARGET section size drift: " + String(len(b)) + " != "
            + String(TARGET_BYTES)
        )
    return b^


def _encode_rigid_bodies(world: World) raises -> List[UInt8]:
    """14 RIGID_BODIES (schema 6, 104_contract §4.3): u32 count (≤ 16) +
    count×36 B records — f32×3 position, f32×3 euler (0 — no angular
    dynamics), u32 shape, f32 size, u32 material id (0007 §3.5)."""
    if world.props.count > RIGID_BODIES_MAX:
        raise Error(
            "rigid_body_count " + String(world.props.count) + " exceeds "
            + String(RIGID_BODIES_MAX)
        )
    if world.props.count > len(world.props.bodies):
        raise Error("RIGID_BODIES count exceeds body list")
    var recs = List[RigidBodyRecord]()
    for i in range(world.props.count):
        var src = world.props.bodies[i]
        var r = RigidBodyRecord()
        r.x = Float32(src.x)
        r.y = Float32(src.y)
        r.z = Float32(src.z)
        # Euler stays 0: minimal model has no angular dynamics (0007 §3.5).
        r.euler_x = 0.0
        r.euler_y = 0.0
        r.euler_z = 0.0
        r.shape = src.shape
        r.size = Float32(src.size)
        r.material_id = src.material_id
        recs.append(r)
    var b = List[UInt8]()
    put_rigid_bodies(b, recs)
    var expect = RIGID_HEADER_BYTES + RIGID_RECORD_BYTES * world.props.count
    if len(b) != expect:
        raise Error(
            "RIGID_BODIES section size drift: " + String(len(b)) + " != "
            + String(expect)
        )
    return b^


def encode_snapshot(
    world: World, include_terrain: Bool, include_flora: Bool = True
) raises -> List[UInt8]:
    """Serialize the world projection (104_contract §4).
    include_terrain: TERRAIN emitted only when terrain (re)generation
    occurred since the adapter's last consumed snapshot (§4.3).
    include_flora: FLORA emitted under the change-driven rule (0009 §3.2 /
    104_contract §10: first snapshot after init, then on count/species/
    pose/yaw change or an instance scale delta ≥ FLORA_EMIT_EPS; absence
    ⇒ the adapter retains cached instances). FAUNA is emitted EVERY
    snapshot (§4.3)."""
    var payload = List[UInt8]()
    var section_count: UInt32 = 0

    var player = _encode_player(world)
    _append_section(payload, SEC_PLAYER, player^)
    section_count += 1

    var meta = _encode_terrain_meta(world)
    _append_section(payload, SEC_TERRAIN_META, meta^)
    section_count += 1

    if include_terrain:
        var terrain = _encode_terrain(world)
        _append_section(payload, SEC_TERRAIN, terrain^)
        section_count += 1

    var ocean = _encode_ocean(world)
    _append_section(payload, SEC_OCEAN, ocean^)
    section_count += 1

    var sky = _encode_sky(world)
    _append_section(payload, SEC_SKY, sky^)
    section_count += 1

    var materials = _encode_materials(world)
    _append_section(payload, SEC_MATERIALS, materials^)
    section_count += 1

    # Sections 7/8: emitted EVERY snapshot (104_contract §4.3 / 0003 §3.2).
    var volcano = _encode_volcano(world)
    _append_section(payload, SEC_VOLCANO, volcano^)
    section_count += 1

    var plume = _encode_plume(world)
    _append_section(payload, SEC_PLUME, plume^)
    section_count += 1

    # Section 9: shore foam field — EVERY snapshot (0005 §3.3, schema 4).
    var foam = _encode_shore_foam(world)
    _append_section(payload, SEC_SHORE_FOAM, foam^)
    section_count += 1

    # Section 10: flora — change-driven (0009 §3.2 / 104_contract §10);
    # TERRAIN keeps its own world_version rule. Layout unchanged (24 B/record).
    if include_flora:
        var flora = _encode_flora(world)
        _append_section(payload, SEC_FLORA, flora^)
        section_count += 1

    # Section 11: seabird flock — EVERY snapshot (0006 §1.1, schema 5).
    var fauna = _encode_fauna(world)
    _append_section(payload, SEC_FAUNA, fauna^)
    section_count += 1

    # Section 12: hotbar (selection + 9 slot catalog ids) — EVERY snapshot
    # (0007 §1.1 rebased id, schema 6).
    var hotbar = _encode_hotbar(world)
    _append_section(payload, SEC_HOTBAR, hotbar^)
    section_count += 1

    # Section 13: sim-owned raycast target — EVERY snapshot (0007 §3.3).
    var target = _encode_target(world)
    _append_section(payload, SEC_TARGET, target^)
    section_count += 1

    # Section 14: rigid props — EVERY snapshot (0007 §3.5).
    var rigid = _encode_rigid_bodies(world)
    _append_section(payload, SEC_RIGID_BODIES, rigid^)
    section_count += 1

    # Envelope (48 bytes) + payload.
    var out = List[UInt8]()
    put_u32(out, SNAPSHOT_MAGIC)
    put_u32(out, SCHEMA_VERSION)
    put_u32(out, section_count)
    put_u32(out, world.world_version)
    put_u32(out, world.state_generation)
    put_u32(out, world.simulation_tick)
    put_u32(out, world.determinism_epoch)
    put_u32(out, world.seed)
    put_f64(out, world.simulation_time)
    put_u32(out, UInt32(len(payload)))
    put_u32(out, 0)  # reserved
    for i in range(len(payload)):
        out.append(payload[i])
    return out^
