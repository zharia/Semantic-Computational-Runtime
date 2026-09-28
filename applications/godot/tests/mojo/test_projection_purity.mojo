# Spec test — Projection purity invariant (milestone_0002 §6.3, 104_contract §1):
# producing a snapshot must not mutate world state. Hash the world before and
# after a full projection (encode + decode + field reads); hashes must match.
# Milestone_0003 §7 amendment: the world fingerprint MUST include the volcano
# subject (a projection that mutated VOLCANO/PLUME source state is caught).
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

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
    read_volcano,
    read_plume,
)
from snapshot.types import (
    SEC_PLAYER,
    SEC_TERRAIN_META,
    SEC_TERRAIN,
    SEC_OCEAN,
    SEC_SKY,
    SEC_MATERIALS,
    SEC_VOLCANO,
    SEC_PLUME,
)


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _drive_projection(data: List[UInt8]) raises -> Int:
    """Consume the snapshot exactly like an adapter would; returns a checksum
    so the reads cannot be optimized away. Sections 7/8 are read too — the
    volcano projection path is read-only (0003 §6 invariant 3)."""
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
    # 7 VOLCANO + 8 PLUME (schema 2): adapter-style reads, no world access.
    var vi = find_section(secs, SEC_VOLCANO)
    var v = read_volcano(data, secs[vi])
    sum += Int(v.radius) + Int(v.effusion_state) + Int(v.crust_fraction * 100.0)
    var plmi = find_section(secs, SEC_PLUME)
    var pm = read_plume(data, secs[plmi])
    sum += Int(pm.rate) + Int(pm.lifetime) + Int(pm.origin_y)
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
    _check(consumed > 0, "projection reads must happen")
    var after = world_fingerprint(world)
    _check(before == after, "projection mutated world state")


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
    _check(before == after, "repeated projection mutated world state")


def test_projection_is_pure_and_repeatable() raises:
    var world = world_init(1)
    var a = encode_snapshot(world, True)
    var b = encode_snapshot(world, True)
    _check(len(a) == len(b), "projection must be a pure function of state")
    for i in range(len(a)):
        _check(a[i] == b[i], "non-deterministic projection at byte " + String(i))


def test_world_fingerprint_includes_volcano_state() raises:
    """0003 §7: the fingerprint must fold volcano state — every field the
    VOLCANO/PLUME sections project — so a mutating projection is detected."""
    var world = world_init(1)
    var base = world_fingerprint(world)
    # Purity: projecting 7/8 must not touch the subject (already covered
    # above, but explicitly for the volcano path).
    var snap = encode_snapshot(world, False)
    _ = _drive_projection(snap)
    _check(world_fingerprint(world) == base, "volcano projection mutated world")

    # Sensitivity: each volcano field, perturbed, must change the fingerprint.
    var saved_f64 = world.volcano.emissive_intensity
    world.volcano.emissive_intensity = saved_f64 + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses emissive")
    world.volcano.emissive_intensity = saved_f64
    _check(world_fingerprint(world) == base, "fingerprint not restored")

    var saved_c = world.volcano.crust_fraction
    world.volcano.crust_fraction = 1.0 - saved_c
    _check(world_fingerprint(world) != base, "fingerprint misses crust_fraction")
    world.volcano.crust_fraction = saved_c

    var saved_e = world.volcano.effusion_state
    world.volcano.effusion_state = UInt8(1 - Int(saved_e))
    _check(world_fingerprint(world) != base, "fingerprint misses effusion_state")
    world.volcano.effusion_state = saved_e

    var saved_g = world.volcano.glow_intensity
    world.volcano.glow_intensity = saved_g + 0.5
    _check(world_fingerprint(world) != base, "fingerprint misses glow")
    world.volcano.glow_intensity = saved_g

    var saved_r = world.volcano.plume_rate
    world.volcano.plume_rate = saved_r + 7.0
    _check(world_fingerprint(world) != base, "fingerprint misses plume_rate")
    world.volcano.plume_rate = saved_r

    var saved_o = world.volcano.plume_origin_y
    world.volcano.plume_origin_y = saved_o + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses plume origin")
    world.volcano.plume_origin_y = saved_o

    var saved_rad = world.volcano.radius
    world.volcano.radius = saved_rad + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses radius")
    world.volcano.radius = saved_rad

    var saved_l = world.volcano.lake_level
    world.volcano.lake_level = saved_l + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses lake_level")
    world.volcano.lake_level = saved_l

    _check(world_fingerprint(world) == base, "fingerprint fully restored")


def main() raises:
    TestSuite.discover_tests[
        (
            test_purity_after_first_projection,
            test_purity_after_steps_and_repeated_projection,
            test_projection_is_pure_and_repeatable,
            test_world_fingerprint_includes_volcano_state,
        )
    ]().run()
