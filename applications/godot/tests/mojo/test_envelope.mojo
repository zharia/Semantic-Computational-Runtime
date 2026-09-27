# Spec test — Snapshot binary schema (104_contract.md §4), including
# loud-failure behaviour for malformed input (§8: never silently coerced).

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
)
from snapshot.types import (
    ENVELOPE_BYTES,
    SEC_PLAYER,
    SEC_TERRAIN_META,
    SEC_TERRAIN,
    SEC_OCEAN,
    SEC_SKY,
    SEC_MATERIALS,
    get_u32,
    get_f32,
    get_f64,
)


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


def test_envelope_layout() raises:
    var data = _snapshot_at_tick1()
    assert len(data) >= ENVELOPE_BYTES
    # Documented offsets (§4.1), little-endian, explicit.
    assert get_u32(data, 0) == 0x53524353, "magic 'SCRS'"
    assert get_u32(data, 4) == 1, "schema_version"
    var env = decode_envelope(data)
    assert env.section_count == 6, "tick1 carries all six sections"
    assert env.world_version == 1
    assert env.state_generation == 1
    assert env.simulation_tick == 1
    assert env.seed == 1
    assert env.determinism_epoch != 0, "epoch derived from seed"
    assert abs(env.simulation_time - 1.0 / 60.0) < 1e-12, "tick × (1/60)"
    assert Int(env.payload_bytes) == len(data) - ENVELOPE_BYTES
    assert env.reserved == 0
    assert get_f64(data, 32) == env.simulation_time, "f64 at offset 32"


def test_section_framing_and_sizes() raises:
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    assert len(secs) == Int(env.section_count)
    # Fixed-size sections per §4.3.
    var pi = find_section(secs, SEC_PLAYER)
    var mi = find_section(secs, SEC_TERRAIN_META)
    var oi = find_section(secs, SEC_OCEAN)
    var ki = find_section(secs, SEC_SKY)
    var ti = find_section(secs, SEC_TERRAIN)
    var mdi = find_section(secs, SEC_MATERIALS)
    assert pi >= 0 and mi >= 0 and oi >= 0 and ki >= 0 and ti >= 0 and mdi >= 0
    assert secs[pi].length == 44, "PLAYER section = 44 bytes (§4.3 header)"
    assert secs[mi].length == 32, "TERRAIN_META = 32 bytes"
    assert secs[oi].length == 32, "OCEAN = 32 bytes"
    assert secs[ki].length == 32, "SKY = 32 bytes"
    # Framing: section headers carry their id and length (§4.2).
    assert get_u32(data, secs[pi].offset - 8) == SEC_PLAYER
    assert get_u32(data, secs[pi].offset - 4) == 44


def test_player_and_meta_payloads() raises:
    var world = world_init(1)
    var spawn_y = Float32(world.island.spawn_y)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var pl = read_player(data, secs[find_section(secs, SEC_PLAYER)])
    # spawn position round-trips through f32.
    assert abs(pl[0] - Float32(world.island.spawn_x)) < 1e-6
    assert abs(pl[1] - spawn_y) < 1e-6
    assert abs(pl[6]) < 1e-6, "yaw starts at 0"
    assert abs(pl[7]) <= Float32(PITCH_CLAMP), "pitch within ±1.45"
    assert abs(pl[8] - Float32(EYE_HEIGHT)) < 1e-6, "eye_height 1.7"
    assert pl[9] == 1.0, "on ground at spawn"
    var meta = read_terrain_meta(data, secs[find_section(secs, SEC_TERRAIN_META)])
    assert meta[0] == 0.0, "sea level"
    assert meta[1] > 39.0 and meta[1] < 44.0, "peak below build height cap"
    assert Int(meta[5]) == GRID_N
    assert abs(meta[6] - Float32(CELL_SIZE)) < 1e-6
    var terrain = read_terrain_header(data, secs[find_section(secs, SEC_TERRAIN)])
    assert Int(terrain) == Int(meta[7]), "TERRAIN.chunk_count == META.chunk_count"


def test_ocean_sky_materials_payloads() raises:
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var oc = read_ocean(data, secs[find_section(secs, SEC_OCEAN)])
    var k = 6.283185307179586 / WAVE_WAVELENGTH
    assert abs(oc[0] - 0.0) < 1e-6, "sea_level"
    assert abs(oc[1] - Float32(WAVE_AMPLITUDE)) < 1e-6, "amplitude"
    assert abs(oc[2] - Float32(k)) < 1e-5, "frequency = k = 2π/λ"
    assert abs(oc[3] - Float32(WAVE_STEEPNESS)) < 1e-6, "steepness = Q"
    assert abs(oc[4] - 0.8) < 1e-6 and abs(oc[5] - 0.6) < 1e-6, "direction"
    assert oc[6] > 3.0 and oc[6] < 4.0, "speed c = sqrt(g/k)"
    assert oc[7] >= 0.0 and oc[7] < 6.2832, "phase folded to [0, 2π)"
    var sk = read_sky(data, secs[find_section(secs, SEC_SKY)])
    assert abs(sk[3] - Float32(FOG_DENSITY)) < 1e-7, "fog_density"
    assert abs(sk[4] - Float32(FOG_COLOR_R)) < 1e-6, "fog r"
    assert abs(sk[5] - Float32(FOG_COLOR_G)) < 1e-6, "fog g"
    assert abs(sk[6] - Float32(FOG_COLOR_B)) < 1e-6, "fog b"
    assert sk[0] >= 9.0, "clock starts at 9.0 h"
    var mdi = find_section(secs, SEC_MATERIALS)
    var count = Int(read_materials_count(data, secs[mdi]))
    assert count >= 1, "materials present"
    for i in range(count):
        var rec = read_material_record(data, secs[mdi], i)
        assert Int(rec[0]) < 96, "stable id is a catalog index"
        for f in range(1, 4):
            assert rec[f] >= 0.0 and rec[f] <= 1.0, "albedo in [0,1]"
        assert rec[4] >= 0.0 and rec[4] <= 1.0, "roughness in [0,1]"
        for f in range(5, 8):
            assert rec[f] >= 0.0 and rec[f] <= 1.0, "emissive in [0,1]"
        assert rec[8] > 0.0 and rec[8] <= 1.0, "opacity in (0,1]"


def test_terrain_chunk_framing() raises:
    var data = _snapshot_at_tick1()
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var ti = find_section(secs, SEC_TERRAIN)
    var chunks = Int(read_terrain_header(data, secs[ti]))
    assert chunks == 16, "4×4 chunks of 16 cells (64/16)²"
    var covered = 0
    for c in range(chunks):
        var ch = read_terrain_chunk_header(data, secs[ti], c)
        var vc = Int(ch[3])
        var ic = Int(ch[4])
        assert vc == 289, "(16+1)² vertices per chunk"
        assert ic == 1536, "16² quads × 2 triangles × 3 indices"
        assert ic % 3 == 0, "idx_count multiple of 3 (§4.3)"
        var span = terrain_chunk_byte_span(data, secs[ti], c)
        var expect = 20 + (3 * vc + 3 * vc + vc + ic) * 4
        assert span[1] - span[0] == expect, "record size arithmetic"
        covered += 1
    assert covered == chunks
    # Last record ends exactly at section end.
    var last = terrain_chunk_byte_span(data, secs[ti], chunks - 1)
    assert last[1] == secs[ti].offset + secs[ti].length, "no trailing bytes"


def test_bad_inputs_fail_loudly() raises:
    var data = _snapshot_at_tick1()
    # Wrong magic.
    var bad = data.copy()
    bad[0] = 0x00
    assert _expect_error(bad), "bad magic must raise"
    # Truncated.
    var trunc = List[UInt8]()
    for i in range(ENVELOPE_BYTES - 1):
        trunc.append(data[i])
    assert _expect_error(trunc), "truncation must raise"
    # Unsupported schema.
    var wrong_schema = data.copy()
    wrong_schema[4] = 2
    assert _expect_error(wrong_schema), "schema mismatch must raise"
    # payload_bytes inconsistent with buffer length.
    var wrong_len = data.copy()
    wrong_len[40] = wrong_len[40] + 1
    assert _expect_error(wrong_len), "payload length mismatch must raise"
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
    assert raised, "unknown section id must raise"


def main() raises:
    TestSuite.discover_tests[
        (
            test_envelope_layout,
            test_section_framing_and_sizes,
            test_player_and_meta_payloads,
            test_ocean_sky_materials_payloads,
            test_terrain_chunk_framing,
            test_bad_inputs_fail_loudly,
        )
    ]().run()
