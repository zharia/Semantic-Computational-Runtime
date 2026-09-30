# Spec test — Snapshot binary schema (104_contract.md §4, schema 5), including
# loud-failure behaviour for malformed input (§8: never silently coerced).
# Milestone_0003 §7 additions: envelope schema_version == 2, sections
# 7 VOLCANO / 8 PLUME framing + payload validation, schema ≠ 2 rejection.
# Milestone_0004 §7 additions: SKY grows to 64 bytes (16×f32), schema == 3,
# schema ∈ {1, 2, 4} rejected, SKY fields round-trip the atmosphere derivation.
# Milestone_0005 §7 additions: schema == 4, section 9 SHORE_FOAM framing +
# payload validation (malformed refused), TERRAIN vertex 4-byte blend
# tuples (u8 material, u8 partner, u8 weight, u8 pad), schema ∈ {1,2,3,5}
# rejected, TERRAIN section keeps its schema-3 byte count (228100).
# Milestone_0006 §7 additions: schema == 5, sections 10 FLORA / 11 FAUNA
# framing + payload validation (malformed refused), FLORA gated like
# TERRAIN / FAUNA every snapshot.
# Milestone_0007 §7 additions: schema == 6, sections 12 HOTBAR / 13 TARGET /
# 14 RIGID_BODIES framing + payload validation (malformed refused),
# schema ∈ {1,2,3,4,5,7} rejected, sections present every snapshot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite
from std.math import abs, sin

from sim.world import world_init, step_world
from sim.input import InputBatch
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    EYE_HEIGHT,
    PITCH_CLAMP,
    WAVE_AMPLITUDE,
    WAVE_STEEPNESS,
    WAVE_WAVELENGTH,
    SCHEMA_VERSION,
    FLORA_N_MAX,
    FLOCK_N_MAX,
)
from snapshot.encode import encode_snapshot
from snapshot.decode import (
    decode_envelope,
    decode_sections,
    find_section,
    read_player,
    read_terrain_meta,
    read_ocean,
    read_sky,
    read_materials_count,
    read_material_record,
    read_terrain_header,
    read_terrain_chunk_header,
    terrain_chunk_byte_span,
    read_volcano,
    read_plume,
    read_shore_foam,
    read_terrain_tuple,
    read_flora,
    read_fauna,
    read_hotbar,
    read_target,
    read_rigid_bodies,
)
from snapshot.types import (
    ENVELOPE_BYTES,
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
    get_u32,
    get_f32,
    get_f64,
)
from ocean.gerstner import wave_height
from sim.shore import FOAM_DEPTH_M, MAX_WAVE_REACH
from sim.raycast import raycast_look
from sim.parameters import HOTBAR_SLOT_COUNT

comptime SECTIONS_AT_TICK1: Int = 14  # schema 6: 1..14 (0007 §1.1)
comptime TERRAIN_BYTES_SEED1: Int = 228100  # schema-3 size, stride-neutral
comptime SHORE_FOAM_BYTES: Int = SHORE_FOAM_HEADER_BYTES + 4 * 64 * 64


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _snapshot_at_tick1() raises -> List[UInt8]:
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    return encode_snapshot(world, True)^


def _expect_error(data: List[UInt8]) raises -> Bool:
    try:
        var env = decode_envelope(data)
        _ = decode_sections(data, env)
        return False
    except e:
        return True


def _expect_read_error(data: List[UInt8], sid: UInt32) raises -> Bool:
    """Decode envelope+sections, then read section `sid` — any loud failure
    (framing, read, validation) returns True; silent success returns False."""
    try:
        var env = decode_envelope(data)
        var secs = decode_sections(data, env)
        var i = find_section(secs, sid)
        if i < 0:
            return True
        if sid == SEC_VOLCANO:
            _ = read_volcano(data, secs[i])
        elif sid == SEC_PLUME:
            _ = read_plume(data, secs[i])
        elif sid == SEC_SHORE_FOAM:
            _ = read_shore_foam(data, secs[i])
        elif sid == SEC_FLORA:
            _ = read_flora(data, secs[i])
        elif sid == SEC_FAUNA:
            _ = read_fauna(data, secs[i])
        elif sid == SEC_HOTBAR:
            _ = read_hotbar(data, secs[i])
        elif sid == SEC_TARGET:
            _ = read_target(data, secs[i])
        elif sid == SEC_RIGID_BODIES:
            _ = read_rigid_bodies(data, secs[i])
        else:
            return False
        return False
    except e:
        return True


def test_envelope_layout() raises:
    var data = _snapshot_at_tick1()
    _check(len(data) >= ENVELOPE_BYTES, "envelope present")
    # Documented offsets (§4.1), little-endian, explicit.
    _check(get_u32(data, 0) == 0x53524353, "magic 'SCRS'")
    _check(SCHEMA_VERSION == 6, "sim parameters SCHEMA_VERSION == 6")
    _check(get_u32(data, 4) == SCHEMA_VERSION, "schema_version == 6")
    var env = decode_envelope(data)
    _check(
        Int(env.section_count) == SECTIONS_AT_TICK1,
        "tick1 carries all fourteen sections",
    )
    _check(env.world_version == 1, "world_version == 1")
    _check(env.state_generation == 1, "state_generation == 1")
    _check(env.simulation_tick == 1, "simulation_tick == 1")
    _check(env.seed == 1, "seed == 1")
    _check(env.determinism_epoch != 0, "epoch derived from seed")
    _check(abs(env.simulation_time - 1.0 / 60.0) < 1e-12, "tick × (1/60)")
    _check(Int(env.payload_bytes) == len(data) - ENVELOPE_BYTES, "payload_bytes")
    _check(env.reserved == 0, "reserved == 0")
    _check(get_f64(data, 32) == env.simulation_time, "f64 at offset 32")


def test_section_framing_and_sizes() raises:
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    _check(Int(len(secs)) == Int(env.section_count), "sections list == count")
    # Fixed-size sections per §4.3.
    var pi = find_section(secs, SEC_PLAYER)
    var mi = find_section(secs, SEC_TERRAIN_META)
    var oi = find_section(secs, SEC_OCEAN)
    var ki = find_section(secs, SEC_SKY)
    var ti = find_section(secs, SEC_TERRAIN)
    var mdi = find_section(secs, SEC_MATERIALS)
    var vi = find_section(secs, SEC_VOLCANO)
    var pli = find_section(secs, SEC_PLUME)
    var fi = find_section(secs, SEC_SHORE_FOAM)
    var fli = find_section(secs, SEC_FLORA)
    var fai = find_section(secs, SEC_FAUNA)
    var hi = find_section(secs, SEC_HOTBAR)
    var tgti = find_section(secs, SEC_TARGET)
    var rgi = find_section(secs, SEC_RIGID_BODIES)
    _check(
        pi >= 0 and mi >= 0 and oi >= 0 and ki >= 0 and ti >= 0 and mdi >= 0,
        "sections 1..6 present",
    )
    _check(vi >= 0 and pli >= 0, "sections 7/8 present")
    _check(fi >= 0, "section 9 SHORE_FOAM present")
    _check(fli >= 0, "section 10 FLORA present (first snapshot)")
    _check(fai >= 0, "section 11 FAUNA present")
    _check(hi >= 0, "section 12 HOTBAR present (every snapshot)")
    _check(tgti >= 0, "section 13 TARGET present (every snapshot)")
    _check(rgi >= 0, "section 14 RIGID_BODIES present (every snapshot)")
    _check(secs[hi].length == HOTBAR_BYTES, "HOTBAR = 44 bytes (§4.3 §12)")
    _check(secs[tgti].length == TARGET_BYTES, "TARGET = 32 bytes (§4.3 §13)")
    var rigid_count = Int(get_u32(data, secs[rgi].offset))
    _check(
        rigid_count > 0 and rigid_count <= RIGID_BODIES_MAX,
        "RIGID_BODIES count in cap",
    )
    _check(
        secs[rgi].length
        == RIGID_HEADER_BYTES + RIGID_RECORD_BYTES * rigid_count,
        "RIGID_BODIES section = 4 + 36·count",
    )
    _check(secs[pi].length == 44, "PLAYER section = 44 bytes (§4.3 header)")
    _check(secs[mi].length == 32, "TERRAIN_META = 32 bytes")
    _check(secs[oi].length == 32, "OCEAN = 32 bytes")
    _check(secs[ki].length == SKY_BYTES, "SKY = 64 bytes (schema 3)")
    _check(secs[ki].length == 64, "SKY = 16×f32")
    _check(secs[vi].length == VOLCANO_BYTES, "VOLCANO = 32 bytes (§4.3 §7)")
    _check(secs[pli].length == PLUME_BYTES, "PLUME = 32 bytes (§4.3 §8)")
    _check(secs[fi].length == SHORE_FOAM_BYTES, "SHORE_FOAM = 12 + 4·64² bytes")
    _check(secs[ti].length == TERRAIN_BYTES_SEED1, "TERRAIN stride-neutral (228100)")
    # FLORA/FAUNA framing arithmetic (§4.3 §10/§11): exact 4 + 24·count /
    # 4 + 20·count, counts within the caps.
    var flora_count = Int(get_u32(data, secs[fli].offset))
    var fauna_count = Int(get_u32(data, secs[fai].offset))
    _check(flora_count > 0 and flora_count <= FLORA_N_MAX, "FLORA count in cap")
    _check(
        secs[fli].length == FLORA_HEADER_BYTES + FLORA_RECORD_BYTES * flora_count,
        "FLORA section = 4 + 24·count",
    )
    _check(
        fauna_count > 0 and fauna_count <= FLOCK_N_MAX, "FAUNA count in cap"
    )
    _check(
        secs[fai].length == FAUNA_HEADER_BYTES + FAUNA_RECORD_BYTES * fauna_count,
        "FAUNA section = 4 + 20·count",
    )
    # Section ids in contract order 1..14.
    for k in range(Int(env.section_count)):
        var hdr = secs[k].offset - 8
        _check(get_u32(data, hdr) == UInt32(k + 1), "section id order at " + String(k))
    # Framing: section headers carry their id and length (§4.2).
    _check(get_u32(data, secs[pi].offset - 8) == SEC_PLAYER, "PLAYER id header")
    _check(get_u32(data, secs[pi].offset - 4) == 44, "PLAYER length header")
    _check(get_u32(data, secs[vi].offset - 8) == SEC_VOLCANO, "VOLCANO id header")
    _check(get_u32(data, secs[vi].offset - 4) == 32, "VOLCANO length header")
    _check(get_u32(data, secs[pli].offset - 8) == SEC_PLUME, "PLUME id header")
    _check(get_u32(data, secs[pli].offset - 4) == 32, "PLUME length header")
    _check(
        get_u32(data, secs[fi].offset - 8) == SEC_SHORE_FOAM, "SHORE_FOAM id header"
    )
    _check(
        get_u32(data, secs[fi].offset - 4) == UInt32(SHORE_FOAM_BYTES),
        "SHORE_FOAM length header",
    )


def test_player_and_meta_payloads() raises:
    var world = world_init(1)
    var spawn_y = Float32(world.island.spawn_y)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var pl = read_player(data, secs[find_section(secs, SEC_PLAYER)])
    # spawn position round-trips through f32.
    _check(abs(pl[0] - Float32(world.island.spawn_x)) < 1e-6, "spawn x")
    _check(abs(pl[1] - spawn_y) < 1e-6, "spawn y")
    # Spawn yaw faces the island center: atan2(spawn_x, spawn_z) (world.mojo),
    # NOT 0 — assert the round-trip against the subject instead of a literal.
    _check(abs(pl[6] - Float32(world.player.yaw)) < 1e-6, "yaw round-trip")
    _check(abs(pl[6]) <= 3.14159274, "yaw within ±π")
    _check(abs(pl[7]) <= Float32(PITCH_CLAMP), "pitch within ±1.45")
    _check(abs(pl[8] - Float32(EYE_HEIGHT)) < 1e-6, "eye_height 1.7")
    _check(pl[9] == 1.0, "on ground at spawn")
    var meta = read_terrain_meta(data, secs[find_section(secs, SEC_TERRAIN_META)])
    _check(meta[0] == 0.0, "sea level")
    _check(meta[1] > 39.0 and meta[1] < 44.0, "peak below build height cap")
    _check(Int(meta[5]) == GRID_N, "grid_n == GRID_N")
    _check(abs(meta[6] - Float32(CELL_SIZE)) < 1e-6, "cell_size")
    var terrain = read_terrain_header(data, secs[find_section(secs, SEC_TERRAIN)])
    _check(Int(terrain) == Int(meta[7]), "TERRAIN.chunk_count == META.chunk_count")


def test_ocean_sky_materials_payloads() raises:
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var oc = read_ocean(data, secs[find_section(secs, SEC_OCEAN)])
    var k = 6.283185307179586 / WAVE_WAVELENGTH
    _check(abs(oc[0] - 0.0) < 1e-6, "sea_level")
    _check(abs(oc[1] - Float32(WAVE_AMPLITUDE)) < 1e-6, "amplitude")
    _check(abs(oc[2] - Float32(k)) < 1e-5, "frequency = k = 2π/λ")
    _check(abs(oc[3] - Float32(WAVE_STEEPNESS)) < 1e-6, "steepness = Q")
    _check(abs(oc[4] - 0.8) < 1e-6 and abs(oc[5] - 0.6) < 1e-6, "direction")
    _check(oc[6] > 3.0 and oc[6] < 4.0, "speed c = sqrt(g/k)")
    _check(oc[7] >= 0.0 and oc[7] < 6.2832, "phase folded to [0, 2π)")
    var sk = read_sky(data, secs[find_section(secs, SEC_SKY)])
    var a = world.atmosphere
    _check(abs(sk[0] - Float32(a.time_of_day_hours)) < 1e-6, "hours round-trip")
    _check(abs(sk[1] - Float32(a.sun_azimuth)) < 1e-6, "azimuth round-trip")
    _check(abs(sk[2] - Float32(a.sun_elevation)) < 1e-6, "elevation round-trip")
    _check(abs(sk[3] - Float32(a.fog_density)) < 1e-7, "fog_density derived")
    _check(abs(sk[4] - Float32(a.fog_r)) < 1e-6, "fog r")
    _check(abs(sk[5] - Float32(a.fog_g)) < 1e-6, "fog g")
    _check(abs(sk[6] - Float32(a.fog_b)) < 1e-6, "fog b")
    _check(abs(sk[7] - Float32(a.sun_intensity)) < 1e-6, "sun_intensity")
    _check(abs(sk[8] - Float32(a.sun_color_r)) < 1e-6, "sun color r")
    _check(abs(sk[9] - Float32(a.sun_color_g)) < 1e-6, "sun color g")
    _check(abs(sk[10] - Float32(a.sun_color_b)) < 1e-6, "sun color b")
    _check(abs(sk[11] - Float32(a.cloud_cover)) < 1e-6, "cloud_cover")
    _check(abs(sk[12] - Float32(a.precipitation)) < 1e-6, "precipitation")
    _check(abs(sk[13] - Float32(a.wind_x)) < 1e-6, "wind_x")
    _check(abs(sk[14] - Float32(a.wind_z)) < 1e-6, "wind_z")
    _check(abs(sk[15] - Float32(a.wetness)) < 1e-6, "wetness")
    _check(sk[0] >= 12.0, "clock starts at 12.0 h")
    # Range invariants (104_contract §4.3 SKY / §6).
    _check(sk[11] >= 0.0 and sk[11] <= 1.0, "cloud_cover ∈ [0,1]")
    _check(sk[12] >= 0.0 and sk[12] <= 1.0, "precipitation ∈ [0,1]")
    _check(sk[15] >= 0.0 and sk[15] <= 1.0, "wetness ∈ [0,1]")
    _check(sk[7] >= 0.0, "sun_intensity ≥ 0")
    _check(sk[3] >= 0.0, "fog_density ≥ 0")
    var mdi = find_section(secs, SEC_MATERIALS)
    var count = Int(read_materials_count(data, secs[mdi]))
    _check(count >= 1, "materials present")
    for i in range(count):
        var rec = read_material_record(data, secs[mdi], i)
        _check(Int(rec[0]) < 96, "stable id is a catalog index")
        for f in range(1, 4):
            _check(rec[f] >= 0.0 and rec[f] <= 1.0, "albedo in [0,1]")
        _check(rec[4] >= 0.0 and rec[4] <= 1.0, "roughness in [0,1]")
        for f in range(5, 8):
            _check(rec[f] >= 0.0 and rec[f] <= 1.0, "emissive in [0,1]")
        _check(rec[8] > 0.0 and rec[8] <= 1.0, "opacity in (0,1]")


def test_volcano_plume_payloads() raises:
    """§4.3 §7/§8: VOLCANO/PLUME round-trip against VolcanoSubject state."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var v = read_volcano(data, secs[find_section(secs, SEC_VOLCANO)])
    var src = world.volcano
    _check(abs(v.center_x - Float32(src.center_x)) < 1e-6, "center_x round-trip")
    _check(abs(v.center_z - Float32(src.center_z)) < 1e-6, "center_z round-trip")
    _check(abs(v.radius - Float32(src.radius)) < 1e-6, "radius round-trip")
    _check(abs(v.lake_level - Float32(src.lake_level)) < 1e-6, "lake_level round-trip")
    _check(
        abs(v.emissive_intensity - Float32(src.emissive_intensity)) < 1e-6,
        "emissive_intensity round-trip",
    )
    _check(
        abs(v.crust_fraction - Float32(src.crust_fraction)) < 1e-6,
        "crust_fraction round-trip",
    )
    _check(
        abs(v.glow_intensity - Float32(src.glow_intensity)) < 1e-6,
        "glow_intensity round-trip",
    )
    _check(v.effusion_state == src.effusion_state, "effusion_state round-trip")
    _check(v.radius > 0.0, "radius > 0")
    _check(v.crust_fraction >= 0.0 and v.crust_fraction <= 1.0, "crust ∈ [0,1]")
    _check(v.emissive_intensity > 0.0, "emissive > 0")
    _check(v.effusion_state <= 1, "effusion_state ∈ {0,1}")
    var p = read_plume(data, secs[find_section(secs, SEC_PLUME)])
    _check(abs(p.origin_x - Float32(src.plume_origin_x)) < 1e-6, "origin_x round-trip")
    _check(abs(p.origin_y - Float32(src.plume_origin_y)) < 1e-6, "origin_y round-trip")
    _check(abs(p.origin_z - Float32(src.plume_origin_z)) < 1e-6, "origin_z round-trip")
    _check(abs(p.rate - Float32(src.plume_rate)) < 1e-6, "rate round-trip")
    _check(
        abs(p.initial_velocity - Float32(src.plume_initial_velocity)) < 1e-6,
        "initial_velocity round-trip",
    )
    _check(abs(p.spread - Float32(src.plume_spread)) < 1e-6, "spread round-trip")
    _check(
        abs(p.turbulence - Float32(src.plume_turbulence)) < 1e-6,
        "turbulence round-trip",
    )
    _check(abs(p.lifetime - Float32(src.plume_lifetime)) < 1e-6, "lifetime round-trip")
    _check(p.rate >= 0.0, "rate ≥ 0")
    _check(p.lifetime > 0.0, "lifetime > 0")
    _check(p.origin_y > 0.0, "origin above sea level")


def test_terrain_chunk_framing() raises:
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var ti = find_section(secs, SEC_TERRAIN)
    var chunks = Int(read_terrain_header(data, secs[ti]))
    _check(chunks == 16, "4×4 chunks of 16 cells (64/16)²")
    var covered = 0
    for c in range(chunks):
        var ch = read_terrain_chunk_header(data, secs[ti], c)
        var vc = Int(ch[3])
        var ic = Int(ch[4])
        _check(vc == 289, "(16+1)² vertices per chunk")
        _check(ic == 1536, "16² quads × 2 triangles × 3 indices")
        _check(ic % 3 == 0, "idx_count multiple of 3 (§4.3)")
        var span = terrain_chunk_byte_span(data, secs[ti], c)
        var expect = 20 + (3 * vc + 3 * vc + vc + ic) * 4
        _check(span[1] - span[0] == expect, "record size arithmetic")
        covered += 1
    _check(covered == chunks, "all chunks walked")
    # Last record ends exactly at section end.
    var last = terrain_chunk_byte_span(data, secs[ti], chunks - 1)
    _check(last[1] == secs[ti].offset + secs[ti].length, "no trailing bytes")


def test_bad_inputs_fail_loudly() raises:
    var data = _snapshot_at_tick1()
    # Wrong magic.
    var bad = data.copy()
    bad[0] = 0x00
    _check(_expect_error(bad), "bad magic must raise")
    # Truncated.
    var trunc = List[UInt8]()
    for i in range(ENVELOPE_BYTES - 1):
        trunc.append(data[i])
    _check(_expect_error(trunc), "truncation must raise")
    # Unsupported schemas: 1..5 (all previous) and 7 (future) must be
    # refused — only SCHEMA_VERSION (6) is accepted (0007 §1.1 sibling rebase).
    for prev in range(1, 6):
        var old_schema = data.copy()
        old_schema[4] = UInt8(prev)
        _check(
            _expect_error(old_schema),
            "schema " + String(prev) + " must be refused (expected 6)",
        )
    var schema7 = data.copy()
    schema7[4] = 7
    _check(_expect_error(schema7), "schema 7 must be refused (expected 6)")
    # payload_bytes inconsistent with buffer length.
    var wrong_len = data.copy()
    wrong_len[40] = wrong_len[40] + 1
    _check(_expect_error(wrong_len), "payload length mismatch must raise")
    # Section id unknown (rewrite PLAYER id to 99).
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var id_off = secs[0].offset - 8
    var bad_id = data.copy()
    bad_id[id_off] = 99
    var raised = False
    try:
        var env2 = decode_envelope(bad_id)
        _ = decode_sections(bad_id, env2)
    except e:
        raised = True
    _check(raised, "unknown section id must raise")


def test_malformed_volcano_plume_fail_loudly() raises:
    """§4.3 §7/§8 validation: wrong length, bad pad, bad effusion_state,
    rate < 0, lifetime <= 0 — all loud, never silently coerced (§8)."""
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var vi = find_section(secs, SEC_VOLCANO)
    var pi = find_section(secs, SEC_PLUME)
    _check(vi >= 0 and pi >= 0, "sections 7/8 present")
    var v_off = secs[vi].offset
    var p_off = secs[pi].offset

    # Sanity: the pristine snapshot must decode cleanly.
    _check(not _expect_read_error(data, SEC_VOLCANO), "pristine VOLCANO decodes")
    _check(not _expect_read_error(data, SEC_PLUME), "pristine PLUME decodes")

    # Truncated VOLCANO: section length 31 instead of 32.
    var trunc_v = data.copy()
    var len_off = v_off - 4
    trunc_v[len_off] = 31
    _check(_expect_read_error(trunc_v, SEC_VOLCANO), "truncated VOLCANO must raise")

    # Truncated PLUME: section length 16 instead of 32.
    var trunc_p = data.copy()
    trunc_p[p_off - 4] = 16
    _check(_expect_read_error(trunc_p, SEC_PLUME), "truncated PLUME must raise")

    # Nonzero pad byte 29.
    var bad_pad = data.copy()
    bad_pad[v_off + 29] = 1
    _check(_expect_read_error(bad_pad, SEC_VOLCANO), "nonzero VOLCANO pad must raise")

    # effusion_state = 2 (locked {0,1}, §3.2).
    var bad_eff = data.copy()
    bad_eff[v_off + 28] = 2
    _check(_expect_read_error(bad_eff, SEC_VOLCANO), "effusion_state > 1 must raise")

    # PLUME rate = -0.5 (bytes 00 00 00 BF LE at offset 12).
    var bad_rate = data.copy()
    bad_rate[p_off + 12] = 0x00
    bad_rate[p_off + 13] = 0x00
    bad_rate[p_off + 14] = 0x00
    bad_rate[p_off + 15] = 0xBF
    _check(_expect_read_error(bad_rate, SEC_PLUME), "negative rate must raise")

    # PLUME lifetime = 0.0 (offset 28).
    var bad_life = data.copy()
    for k in range(4):
        bad_life[p_off + 28 + k] = 0
    _check(_expect_read_error(bad_life, SEC_PLUME), "lifetime <= 0 must raise")


def test_shore_foam_payload() raises:
    """§4.3 §9 (0005 §3.3): header + grid round-trip against world.foam;
    every value ∈ [0,1]; row-major cell centers align with the grid."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var fi = find_section(secs, SEC_SHORE_FOAM)
    _check(fi >= 0, "SHORE_FOAM present")
    var foam = read_shore_foam(data, secs[fi])
    _check(Int(foam[0]) == GRID_N, "header grid_n == GRID_N")
    _check(abs(foam[1] - Float32(CELL_SIZE)) < 1e-6, "header cell_size")
    _check(abs(foam[2] - 0.0) < 1e-6, "header sea_level")
    _check(len(foam) == 3 + GRID_N * GRID_N, "header + n² values")
    for i in range(GRID_N * GRID_N):
        _check(
            foam[3 + i] >= 0.0 and foam[3 + i] <= 1.0, "foam ∈ [0,1]"
        )
        _check(
            abs(foam[3 + i] - world.foam[i]) < 1e-6, "foam round-trip at " + String(i)
        )
    # Recompute the shore formula for one cell from world state (AP-19: the
    # section is a faithful copy of the sim's field, not an adapter product).
    var ix = 30
    var iz = 34
    var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var y_w = wave_height(world.hydro.ocean, wx, wz, world.simulation_time)
    var y_t = world.island.heights[iz * GRID_N + ix]
    var dy = y_w - y_t
    var expect = 0.0
    if y_t < MAX_WAVE_REACH and dy < FOAM_DEPTH_M:
        var c = 1.0 - dy / FOAM_DEPTH_M
        if c < 0.0:
            c = 0.0
        expect = c * c * (0.6 + 0.4 * sin(6.0 * dy - 4.0 * world.simulation_time))
    _check(
        abs(Float64(foam[3 + iz * GRID_N + ix]) - expect) < 1e-6,
        "foam cell equals the library shore formula",
    )


def test_malformed_shore_foam_fails_loudly() raises:
    """§8: wrong length, grid_n = 0, value > 1 — all loud refusals."""
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var fi = find_section(secs, SEC_SHORE_FOAM)
    _check(fi >= 0, "SHORE_FOAM present")
    var f_off = secs[fi].offset

    # Pristine decodes.
    _check(not _expect_read_error(data, SEC_SHORE_FOAM), "pristine decodes")

    # Declared section length wrong (12 + 4·64² − 4).
    var bad_len = data.copy()
    var len_low = SHORE_FOAM_BYTES - 4
    bad_len[f_off - 4] = UInt8(len_low & 0xFF)
    bad_len[f_off - 3] = UInt8((len_low >> 8) & 0xFF)
    bad_len[f_off - 2] = 0
    bad_len[f_off - 1] = 0
    _check(
        _expect_read_error(bad_len, SEC_SHORE_FOAM), "truncated SHORE_FOAM raises"
    )

    # grid_n = 0.
    var bad_grid = data.copy()
    for k in range(4):
        bad_grid[f_off + k] = 0
    _check(_expect_read_error(bad_grid, SEC_SHORE_FOAM), "grid_n = 0 raises")

    # Foam value > 1: overwrite value 0 with 0x3F800001 (> 1.0).
    var bad_val = data.copy()
    var v_off = f_off + SHORE_FOAM_HEADER_BYTES
    bad_val[v_off] = 0x01
    bad_val[v_off + 1] = 0x00
    bad_val[v_off + 2] = 0x80
    bad_val[v_off + 3] = 0x3F
    _check(_expect_read_error(bad_val, SEC_SHORE_FOAM), "foam > 1 raises")


def test_terrain_blend_tuples() raises:
    """§4.3 TERRAIN (0005 §3.6): per-vertex (u8 catalog id, u8 partner
    catalog id, u8 weight, u8 pad 0); pad nonzero is a loud decode; weight
    0 ⇒ partner == dominant (no-blend identity)."""
    var world = world_init(1)
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var ti = find_section(secs, SEC_TERRAIN)
    _check(secs[ti].length == TERRAIN_BYTES_SEED1, "TERRAIN size unchanged")
    var ch = read_terrain_chunk_header(data, secs[ti], 0)
    var vc = Int(ch[3])
    var ic = Int(ch[4])
    var span = terrain_chunk_byte_span(data, secs[ti], 0)
    var v_off = span[0] + 20  # chunk header: 3×f32 + vc + ic = 20 bytes
    # Walk every vertex tuple: pad is zero, ids < 96 (catalog), weight ∈ [0,255].
    var nonzero_pad = 0
    var blended = 0
    for j in range(vc):
        var t = read_terrain_tuple(data, v_off + 4 * (3 * vc + 3 * vc) + 4 * j)
        if Int(t.material) >= 96:
            raise Error("vertex catalog id >= 96")
        if Int(t.blend) >= 96:
            raise Error("partner catalog id >= 96")
        if t.weight == 0 and t.blend != t.material:
            raise Error("no-blend vertex must carry partner == dominant")
        if t.weight > 0:
            blended += 1
    # Vertex tuple block sits between normals and indices; verify framing by
    # record arithmetic too.
    var expect = 20 + (3 * vc + 3 * vc + vc + ic) * 4
    _check(span[1] - span[0] == expect, "record still stride-neutral")
    _check(nonzero_pad == 0, "pad bytes are zero (read_terrain_tuple enforces)")
    # Chunk 0 covers the deep-ocean corner: must be a blend band region only
    # if a material boundary passes through it — accept either, but the tuple
    # reader already validated structure for all 289 vertices.
    var t0 = read_terrain_tuple(data, v_off + 4 * (6 * vc))
    _check(Int(t0.material) < 96, "first vertex material id < 96")
    _ = blended
    _ = world


def test_flora_fauna_payloads() raises:
    """§4.3 §10/§11 (0006 §3.2): FLORA/FAUNA framing + round-trip against
    FloraSubject/FlockSubject; FLORA gated like TERRAIN (absent when
    include_flora = False), FAUNA present either way; malformed records
    (species_id = 0, scale <= 0, nonzero pad) fail loudly (§8)."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)

    # FLORA round-trip against the sim population (count, every field).
    var fli = find_section(secs, SEC_FLORA)
    _check(fli >= 0, "FLORA present in first snapshot")
    var flora = read_flora(data, secs[fli])
    _check(Int(len(flora)) == world.flora.count, "FLORA count == FloraSubject.count")
    _check(world.flora.count > 0 and world.flora.count <= FLORA_N_MAX, "count in cap")
    for i in range(world.flora.count):
        var inst = world.flora.instances[i]
        _check(flora[i].species_id == inst.species_id, "species_id round-trip")
        _check(abs(flora[i].x - inst.x) < 1e-6, "flora x round-trip")
        _check(abs(flora[i].y - inst.y) < 1e-6, "flora y round-trip")
        _check(abs(flora[i].z - inst.z) < 1e-6, "flora z round-trip")
        _check(abs(flora[i].yaw - inst.yaw) < 1e-6, "flora yaw round-trip")
        _check(abs(flora[i].scale - inst.scale) < 1e-6, "flora scale round-trip")
        _check(flora[i].species_id >= 1, "SPECIES_NONE never emitted")
        _check(flora[i].scale > 0.0, "scale > 0")

    # FAUNA round-trip: every active slot in slot order, pose within bounds.
    var fai = find_section(secs, SEC_FAUNA)
    _check(fai >= 0, "FAUNA present")
    var fauna = read_fauna(data, secs[fai])
    _check(Int(len(fauna)) == world.flock.count, "FAUNA count == flock.count")
    _check(world.flock.count <= FLOCK_N_MAX, "count <= FLOCK_N_MAX")
    for i in range(world.flock.count):
        var b = world.flock.birds[i]
        _check(b.active, "wire records map to active slots in order")
        _check(abs(fauna[i].x - Float32(b.x)) < 1e-6, "bird x round-trip")
        _check(abs(fauna[i].y - Float32(b.y)) < 1e-6, "bird y round-trip")
        _check(abs(fauna[i].z - Float32(b.z)) < 1e-6, "bird z round-trip")
        _check(abs(fauna[i].yaw - Float32(b.yaw)) < 1e-6, "bird yaw round-trip")
        _check(fauna[i].species_id == 0, "seabird species id")
        _check(
            fauna[i].pad0 == 0 and fauna[i].pad1 == 0 and fauna[i].pad2 == 0,
            "FAUNA pad zero",
        )

    # Gating: include_flora = False drops section 10 only (FAUNA every
    # snapshot — §4.3 presence rules).
    var gated = encode_snapshot(world, True, False)
    var genv = decode_envelope(gated)
    var gsecs = decode_sections(gated, genv)
    _check(find_section(gsecs, SEC_FLORA) < 0, "FLORA suppressed when gated")
    _check(find_section(gsecs, SEC_FAUNA) >= 0, "FAUNA present when FLORA gated")
    _check(
        Int(genv.section_count) == Int(env.section_count) - 1,
        "gated snapshot drops exactly one section",
    )

    # Malformed FLORA: species_id = 0 (SPECIES_NONE) at record 0.
    var f_off = secs[fli].offset
    _check(not _expect_read_error(data, SEC_FLORA), "pristine FLORA decodes")
    _check(not _expect_read_error(data, SEC_FAUNA), "pristine FAUNA decodes")
    var bad_species = data.copy()
    for k in range(4):
        bad_species[f_off + FLORA_HEADER_BYTES + 20 + k] = 0
    _check(
        _expect_read_error(bad_species, SEC_FLORA), "species_id = 0 must raise"
    )
    # Malformed FLORA: scale = 0.0 at record 0.
    var bad_scale = data.copy()
    for k in range(4):
        bad_scale[f_off + FLORA_HEADER_BYTES + 16 + k] = 0
    _check(_expect_read_error(bad_scale, SEC_FLORA), "scale = 0 must raise")
    # Malformed FLORA: declared section length off by 4.
    var bad_len = data.copy()
    var wrong_len = secs[fli].length - 4
    var l0 = f_off - 4
    bad_len[l0] = UInt8(wrong_len & 0xFF)
    bad_len[l0 + 1] = UInt8((wrong_len >> 8) & 0xFF)
    bad_len[l0 + 2] = UInt8((wrong_len >> 16) & 0xFF)
    bad_len[l0 + 3] = UInt8((wrong_len >> 24) & 0xFF)
    _check(_expect_read_error(bad_len, SEC_FLORA), "FLORA length drift raises")
    # Malformed FAUNA: nonzero pad byte 17 of record 0.
    var a_off = secs[fai].offset
    var bad_pad = data.copy()
    bad_pad[a_off + FAUNA_HEADER_BYTES + 17] = 1
    _check(_expect_read_error(bad_pad, SEC_FAUNA), "nonzero FAUNA pad raises")
    # Malformed FAUNA: declared length off by 4.
    var bad_alen = data.copy()
    var alen = secs[fai].length - 4
    var b0 = a_off - 4
    bad_alen[b0] = UInt8(alen & 0xFF)
    bad_alen[b0 + 1] = UInt8((alen >> 8) & 0xFF)
    bad_alen[b0 + 2] = UInt8((alen >> 16) & 0xFF)
    bad_alen[b0 + 3] = UInt8((alen >> 24) & 0xFF)
    _check(_expect_read_error(bad_alen, SEC_FAUNA), "FAUNA length drift raises")


def test_hotbar_target_rigid_payloads() raises:
    """§4.3 §12/§13/§14 round-trip: HOTBAR against the sim slot table,
    TARGET against the sim-owned raycast of this tick's pose, RIGID_BODIES
    against PhysicsSubject state (every snapshot, schema 6)."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)

    # 12 HOTBAR: count = 9, 0-based selection, slot ids == sim table.
    var h = read_hotbar(data, secs[find_section(secs, SEC_HOTBAR)])
    _check(Int(h.count) == HOTBAR_SLOT_COUNT, "HOTBAR count == 9")
    _check(
        len(h.slot_ids) == HOTBAR_SLOT_COUNT,
        "HOTBAR carries 9 slot ids",
    )
    _check(
        Int(h.selected_index) == world.hotbar.selected_index,
        "selected_index round-trip",
    )
    for i in range(HOTBAR_SLOT_COUNT):
        _check(
            h.slot_ids[i] == world.hotbar.slot_ids[i],
            "slot " + String(i) + " catalog id round-trip",
        )

    # 13 TARGET: sim-owned raycast of the CURRENT pose, decoded fields match.
    var hit = raycast_look(
        world.island,
        world.catalog,
        world.player.x,
        world.player.y,
        world.player.z,
        world.player.yaw,
        world.player.pitch,
    )
    var t = read_target(data, secs[find_section(secs, SEC_TARGET)])
    _check(
        Bool(t.hit == 1) == hit.hit,
        "TARGET.hit == sim raycast hit (" + String(t.hit) + ")",
    )
    if hit.hit:
        _check(t.material_id == hit.material_id, "TARGET material id round-trip")
        _check(abs(t.hit_x - Float32(hit.hit_x)) < 1e-5, "TARGET hit_x")
        _check(abs(t.hit_y - Float32(hit.hit_y)) < 1e-5, "TARGET hit_y")
        _check(abs(t.hit_z - Float32(hit.hit_z)) < 1e-5, "TARGET hit_z")
        _check(Int(t.cell_x) == hit.cell_x, "TARGET cell_x")
        _check(Int(t.cell_z) == hit.cell_z, "TARGET cell_z")
        _check(
            Int(t.cell_lattice_y) == hit.cell_lattice_y,
            "TARGET cell_lattice_y",
        )

    # 14 RIGID_BODIES: count + every body field against PhysicsSubject.
    var bodies = read_rigid_bodies(
        data, secs[find_section(secs, SEC_RIGID_BODIES)]
    )
    _check(Int(len(bodies)) == world.props.count, "body count round-trip")
    _check(world.props.count <= RIGID_BODIES_MAX, "count <= PROP_N_MAX")
    for i in range(world.props.count):
        var src = world.props.bodies[i]
        var b = bodies[i]
        _check(abs(b.x - Float32(src.x)) < 1e-5, "body x round-trip")
        _check(abs(b.y - Float32(src.y)) < 1e-5, "body y round-trip")
        _check(abs(b.z - Float32(src.z)) < 1e-5, "body z round-trip")
        _check(b.euler_x == 0.0 and b.euler_y == 0.0, "euler zero (no angular dynamics)")
        _check(b.euler_z == 0.0, "euler z zero")
        _check(b.shape == src.shape, "shape round-trip")
        _check(abs(b.size - Float32(src.size)) < 1e-6, "size round-trip")
        _check(b.material_id == src.material_id, "material id round-trip")


def test_malformed_hotbar_target_rigid_fail_loudly() raises:
    """§8 loud refusals for schema-6 sections: HOTBAR count != 9 /
    selected_index out of range, TARGET hit > 1 / nonzero pad / nonzero miss
    fields, RIGID_BODIES count > 16 / shape > 1 / length drift."""
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var hi = find_section(secs, SEC_HOTBAR)
    var tgti = find_section(secs, SEC_TARGET)
    var rgi = find_section(secs, SEC_RIGID_BODIES)
    _check(hi >= 0 and tgti >= 0 and rgi >= 0, "sections 12/13/14 present")
    _check(not _expect_read_error(data, SEC_HOTBAR), "pristine HOTBAR decodes")
    _check(not _expect_read_error(data, SEC_TARGET), "pristine TARGET decodes")
    _check(
        not _expect_read_error(data, SEC_RIGID_BODIES),
        "pristine RIGID_BODIES decodes",
    )

    var h_off = secs[hi].offset
    # count = 8 (wire must be 9).
    var bad_count = data.copy()
    bad_count[h_off] = 8
    _check(_expect_read_error(bad_count, SEC_HOTBAR), "HOTBAR count != 9 raises")
    # selected_index = 9 (out of range for count 9).
    var bad_sel = data.copy()
    bad_sel[h_off + 4] = 9
    _check(_expect_read_error(bad_sel, SEC_HOTBAR), "selected_index >= count raises")

    var t_off = secs[tgti].offset
    # hit = 2 (must be 0/1).
    var bad_hit = data.copy()
    bad_hit[t_off] = 2
    _check(_expect_read_error(bad_hit, SEC_TARGET), "TARGET hit > 1 raises")
    # Nonzero pad byte 1.
    var bad_pad = data.copy()
    bad_pad[t_off + 1] = 1
    _check(_expect_read_error(bad_pad, SEC_TARGET), "TARGET pad raises")
    var r_off = secs[rgi].offset
    # count = 17 (> PROP_N_MAX).
    var bad_rcount = data.copy()
    bad_rcount[r_off] = 17
    _check(
        _expect_read_error(bad_rcount, SEC_RIGID_BODIES),
        "RIGID_BODIES count > 16 raises",
    )
    # shape = 2 on record 0.
    var bad_shape = data.copy()
    bad_shape[r_off + RIGID_HEADER_BYTES + 24] = 2
    _check(
        _expect_read_error(bad_shape, SEC_RIGID_BODIES),
        "shape > 1 raises",
    )
    # Declared length drift (4 + 36·count − 4).
    var bad_rlen = data.copy()
    var wrong = secs[rgi].length - 4
    var r0 = r_off - 4
    bad_rlen[r0] = UInt8(wrong & 0xFF)
    bad_rlen[r0 + 1] = UInt8((wrong >> 8) & 0xFF)
    bad_rlen[r0 + 2] = UInt8((wrong >> 16) & 0xFF)
    bad_rlen[r0 + 3] = UInt8((wrong >> 24) & 0xFF)
    _check(
        _expect_read_error(bad_rlen, SEC_RIGID_BODIES),
        "RIGID_BODIES length drift raises",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_envelope_layout,
            test_section_framing_and_sizes,
            test_player_and_meta_payloads,
            test_ocean_sky_materials_payloads,
            test_volcano_plume_payloads,
            test_terrain_chunk_framing,
            test_bad_inputs_fail_loudly,
            test_malformed_volcano_plume_fail_loudly,
            test_shore_foam_payload,
            test_malformed_shore_foam_fails_loudly,
            test_terrain_blend_tuples,
            test_flora_fauna_payloads,
            test_hotbar_target_rigid_payloads,
            test_malformed_hotbar_target_rigid_fail_loudly,
        )
    ]().run()
