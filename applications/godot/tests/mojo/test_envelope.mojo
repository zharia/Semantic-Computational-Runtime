# Spec test — Snapshot binary schema (104_contract.md §4, schema 2), including
# loud-failure behaviour for malformed input (§8: never silently coerced).
# Milestone_0003 §7 additions: envelope schema_version == 2, sections
# 7 VOLCANO / 8 PLUME framing + payload validation, schema ≠ 2 rejection.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite
from std.math import abs

from sim.world import world_init, step_world
from sim.input import InputBatch
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    EYE_HEIGHT,
    FOG_DENSITY,
    FOG_COLOR_R,
    FOG_COLOR_G,
    FOG_COLOR_B,
    PITCH_CLAMP,
    WAVE_AMPLITUDE,
    WAVE_STEEPNESS,
    WAVE_WAVELENGTH,
    SCHEMA_VERSION,
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
)
from snapshot.types import (
    ENVELOPE_BYTES,
    SEC_PLAYER,
    SEC_TERRAIN_META,
    SEC_TERRAIN,
    SEC_OCEAN,
    SEC_SKY,
    SEC_MATERIALS,
    SEC_VOLCANO,
    SEC_PLUME,
    VOLCANO_BYTES,
    PLUME_BYTES,
    get_u32,
    get_f32,
    get_f64,
)

comptime SECTIONS_AT_TICK1: Int = 8  # schema 2: 1..8 (0003 §3.2)


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
    _check(SCHEMA_VERSION == 2, "sim parameters SCHEMA_VERSION == 2")
    _check(get_u32(data, 4) == SCHEMA_VERSION, "schema_version == 2")
    var env = decode_envelope(data)
    _check(
        Int(env.section_count) == SECTIONS_AT_TICK1,
        "tick1 carries all eight sections",
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
    _check(
        pi >= 0 and mi >= 0 and oi >= 0 and ki >= 0 and ti >= 0 and mdi >= 0,
        "sections 1..6 present",
    )
    _check(vi >= 0 and pli >= 0, "sections 7/8 present")
    _check(secs[pi].length == 44, "PLAYER section = 44 bytes (§4.3 header)")
    _check(secs[mi].length == 32, "TERRAIN_META = 32 bytes")
    _check(secs[oi].length == 32, "OCEAN = 32 bytes")
    _check(secs[ki].length == 32, "SKY = 32 bytes")
    _check(secs[vi].length == VOLCANO_BYTES, "VOLCANO = 32 bytes (§4.3 §7)")
    _check(secs[pli].length == PLUME_BYTES, "PLUME = 32 bytes (§4.3 §8)")
    # Section ids in contract order 1..8.
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
    var data = _snapshot_at_tick1()
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
    _check(abs(sk[3] - Float32(FOG_DENSITY)) < 1e-7, "fog_density")
    _check(abs(sk[4] - Float32(FOG_COLOR_R)) < 1e-6, "fog r")
    _check(abs(sk[5] - Float32(FOG_COLOR_G)) < 1e-6, "fog g")
    _check(abs(sk[6] - Float32(FOG_COLOR_B)) < 1e-6, "fog b")
    _check(sk[0] >= 9.0, "clock starts at 9.0 h")
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
    # Unsupported schemas: schema 1 (pre-bump) and schema 3 (future) must both
    # be refused — only SCHEMA_VERSION (2) is accepted (0003 §3.5).
    var schema1 = data.copy()
    schema1[4] = 1
    _check(_expect_error(schema1), "schema 1 must be refused (expected 2)")
    var schema3 = data.copy()
    schema3[4] = 3
    _check(_expect_error(schema3), "schema 3 must be refused (expected 2)")
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
        )
    ]().run()
