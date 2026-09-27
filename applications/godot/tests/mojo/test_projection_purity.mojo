# Spec test — Projection purity invariant (milestone_0002 §6.3, 104_contract §1):
# producing a snapshot must not mutate world state. Hash the world before and
# after a full projection (encode + decode + field reads); hashes must match.

from std.testing import TestSuite

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
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
    SEC_PLAYER,
    SEC_TERRAIN_META,
    SEC_TERRAIN,
    SEC_OCEAN,
    SEC_SKY,
    SEC_MATERIALS,
)


def _drive_projection(data: List[UInt8]) raises -> Int:
    """Consume the snapshot exactly like an adapter would; returns a checksum
    so the reads cannot be optimized away."""
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var sum = 0
    var pi = find_section(secs, SEC_PLAYER)
    var pl = read_player(data, secs[pi])
    sum += Int(pl[0]) + Int(pl[9])
    var mi = find_section(secs, SEC_TERRAIN_META)
    var meta = read_terrain_meta(data, secs[mi])
    sum += Int(meta[5])
    var oi = find_section(secs, SEC_OCEAN)
    var oc = read_ocean(data, secs[oi])
    sum += Int(oc[1])
    var ki = find_section(secs, SEC_SKY)
    var sk = read_sky(data, secs[ki])
    sum += Int(sk[3] * 1000.0)
    var mdi = find_section(secs, SEC_MATERIALS)
    var count = Int(read_materials_count(data, secs[mdi]))
    for i in range(count):
        var rec = read_material_record(data, secs[mdi], i)
        sum += Int(rec[0])
    var ti = find_section(secs, SEC_TERRAIN)
    if ti < 0:
        return sum  # TERRAIN absent by contract (§4.3): adapter keeps meshes
    var chunks = Int(read_terrain_header(data, secs[ti]))
    for c in range(chunks):
        var ch = read_terrain_chunk_header(data, secs[ti], c)
        sum += Int(ch[3])
        var span = terrain_chunk_byte_span(data, secs[ti], c)
        sum += span[1] - span[0]
    return sum


def test_purity_after_first_projection() raises:
    var world = world_init(1)
    var before = world_fingerprint(world)
    var snap = encode_snapshot(world, True)
    var consumed = _drive_projection(snap)
    assert consumed > 0, "projection reads must happen"
    var after = world_fingerprint(world)
    assert before == after, "projection mutated world state"


def test_purity_after_steps_and_repeated_projection() raises:
    var world = world_init(1)
    var input = InputBatch()
    input.move_x = 0.5
    input.move_y = 1.0
    for _ in range(3):
        _ = step_world(world, 1.0 / 60.0, input)
    var before = world_fingerprint(world)
    for i in range(3):
        var snap = encode_snapshot(world, i == 0)
        _ = _drive_projection(snap)
    var after = world_fingerprint(world)
    assert before == after, "repeated projection mutated world state"


def test_projection_is_pure_and_repeatable() raises:
    var world = world_init(1)
    var a = encode_snapshot(world, True)
    var b = encode_snapshot(world, True)
    assert len(a) == len(b), "projection must be a pure function of state"
    for i in range(len(a)):
        assert a[i] == b[i], "non-deterministic projection at byte " + String(i)


def main() raises:
    TestSuite.discover_tests[
        (
            test_purity_after_first_projection,
            test_purity_after_steps_and_repeated_projection,
            test_projection_is_pure_and_repeatable,
        )
    ]().run()
