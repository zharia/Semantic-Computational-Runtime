# Spec test — Projection purity invariant (milestone_0002 §6.3, 104_contract §1):
# producing a snapshot must not mutate world state. Hash the world before and
# after a full projection (encode + decode + field reads); hashes must match.
# Milestone_0003 §7 amendment: the world fingerprint MUST include the volcano
# subject (a projection that mutated VOLCANO/PLUME source state is caught).
# Milestone_0006 §7 amendment: the fingerprint MUST include flora + flock
# state (a projection that mutated section 10/11 source state is caught),
# and the adapter-style reads consume FLORA/FAUNA too.
# Milestone_0007 §7 amendment: the fingerprint MUST include hotbar + edit
# queue + rigid prop state (a projection that mutated section 12/13/14
# source state is caught), and adapter-style reads consume HOTBAR / TARGET /
# RIGID_BODIES too.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.testing import TestSuite

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
from sim.parameters import GRID_N, EDIT_OP_DIG
from sim.edit import edit_apply_batch, edit_pop
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
)


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _drive_projection(data: List[UInt8]) raises -> Int:
    """Consume the snapshot exactly like an adapter would; returns a checksum
    so the reads cannot be optimized away. Sections 7/8 and 9 are read too —
    the volcano and shore-foam projection paths are read-only (0003 §6
    invariant 3; 0005 §3.3: the projection reads the foam field)."""
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
    # 9 SHORE_FOAM (schema 4): adapter-style read, no world access.
    var fi = find_section(secs, SEC_SHORE_FOAM)
    var foam = read_shore_foam(data, secs[fi])
    sum += Int(foam[0]) + Int(foam[3] * 1000.0)
    sum += Int(foam[3 + GRID_N * GRID_N - 1] * 1000.0)
    # 10 FLORA (schema 5, may be absent by the presence rule) + 11 FAUNA
    # (schema 5, always present): adapter-style reads, no world access.
    var fli = find_section(secs, SEC_FLORA)
    if fli >= 0:
        var flora = read_flora(data, secs[fli])
        sum += len(flora)
        for i in range(len(flora)):
            sum += Int(flora[i].species_id) + Int(flora[i].scale * 100.0)
    var fai = find_section(secs, SEC_FAUNA)
    var fauna = read_fauna(data, secs[fai])
    sum += len(fauna)
    for i in range(len(fauna)):
        sum += Int(fauna[i].yaw * 100.0) + Int(fauna[i].species_id)
    # 12 HOTBAR / 13 TARGET / 14 RIGID_BODIES (schema 6): adapter-style
    # reads, no world access — the raycast TARGET is computed at encode time.
    var hi = find_section(secs, SEC_HOTBAR)
    var hb = read_hotbar(data, secs[hi])
    sum += Int(hb.count) + Int(hb.selected_index)
    for i in range(len(hb.slot_ids)):
        sum += Int(hb.slot_ids[i])
    var tgti = find_section(secs, SEC_TARGET)
    var tgt = read_target(data, secs[tgti])
    sum += Int(tgt.hit) + Int(tgt.material_id) + Int(tgt.cell_lattice_y)
    var rgi = find_section(secs, SEC_RIGID_BODIES)
    var bodies = read_rigid_bodies(data, secs[rgi])
    sum += len(bodies)
    for i in range(len(bodies)):
        sum += Int(bodies[i].y * 100.0) + Int(bodies[i].material_id)
    var ti = find_section(secs, SEC_TERRAIN)
    if ti < 0:
        return sum  # TERRAIN absent by contract (§4.3): adapter keeps meshes
    var chunks = Int(read_terrain_header(data, secs[ti]))
    for c in range(chunks):
        var ch = read_terrain_chunk_header(data, secs[ti], c)
        sum += Int(ch[3])
        var span = terrain_chunk_byte_span(data, secs[ti], c)
        sum += span[1] - span[0]
        # Walk the schema-4 vertex blend tuples of every vertex (stride 4).
        var vc = Int(ch[3])
        var v_off = span[0] + 20 + 4 * (6 * vc)  # header + vertices + normals
        for j in range(vc):
            var t = read_terrain_tuple(data, v_off + 4 * j)
            sum += Int(t.material) + Int(t.blend) + Int(t.weight)
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
        var snap = encode_snapshot(world, i == 0, i == 0)
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


def test_world_fingerprint_includes_foam_state() raises:
    """0005 §7/§3.3: the fingerprint folds the shore-foam field — a projection
    that read it must not change it, and a mutated field is detected."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var base = world_fingerprint(world)
    var snap = encode_snapshot(world, True)
    _ = _drive_projection(snap)
    _check(
        world_fingerprint(world) == base,
        "SHORE_FOAM projection mutated world (foam fingerprint drift)",
    )
    var saved = world.foam[10]
    world.foam[10] = 0.75 if saved != 0.75 else 0.25
    _check(world_fingerprint(world) != base, "fingerprint misses foam state")
    world.foam[10] = saved
    _check(world_fingerprint(world) == base, "fingerprint not restored")


def test_world_fingerprint_includes_flora_flock_state() raises:
    """0006 §7: the fingerprint folds flora + flock — projecting sections
    10/11 must not mutate them, and a mutated subject field is detected."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var base = world_fingerprint(world)
    var snap = encode_snapshot(world, True)
    _ = _drive_projection(snap)
    _check(
        world_fingerprint(world) == base,
        "FLORA/FAUNA projection mutated world (ecology fingerprint drift)",
    )

    # Flora sensitivity: instance pose + count.
    var saved_x = world.flora.instances[0].x
    world.flora.instances[0].x = saved_x + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses flora x")
    world.flora.instances[0].x = saved_x

    var saved_scale = world.flora.instances[1].scale
    world.flora.instances[1].scale = saved_scale + 0.25
    _check(world_fingerprint(world) != base, "fingerprint misses flora scale")
    world.flora.instances[1].scale = saved_scale

    var saved_sid = world.flora.instances[2].species_id
    world.flora.instances[2].species_id = saved_sid + 1
    _check(world_fingerprint(world) != base, "fingerprint misses species_id")
    world.flora.instances[2].species_id = saved_sid

    var saved_count = world.flora.count
    world.flora.count = saved_count - 1
    _check(world_fingerprint(world) != base, "fingerprint misses flora count")
    world.flora.count = saved_count

    # Flock sensitivity: bird pose + trajectory + slot metadata.
    var saved_bx = world.flock.birds[0].x
    world.flock.birds[0].x = saved_bx + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses bird x")
    world.flock.birds[0].x = saved_bx

    var saved_bvz = world.flock.birds[0].vz
    world.flock.birds[0].vz = saved_bvz + 0.5
    _check(world_fingerprint(world) != base, "fingerprint misses bird velocity")
    world.flock.birds[0].vz = saved_bvz

    var saved_rc = world.flock.birds[0].respawn_count
    world.flock.birds[0].respawn_count = saved_rc + 1
    _check(world_fingerprint(world) != base, "fingerprint misses respawn_count")
    world.flock.birds[0].respawn_count = saved_rc

    var saved_active = world.flock.birds[40].active
    world.flock.birds[40].active = not saved_active
    _check(world_fingerprint(world) != base, "fingerprint misses slot active")
    world.flock.birds[40].active = saved_active

    _check(world_fingerprint(world) == base, "fingerprint fully restored")


def test_world_fingerprint_includes_hotbar_queue_props() raises:
    """0007 §7: the fingerprint folds hotbar + edit FIFO + rigid prop state —
    projecting sections 12/13/14 must not mutate them, and a mutated subject
    field is detected."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var base = world_fingerprint(world)
    var snap = encode_snapshot(world, True)
    _ = _drive_projection(snap)
    _check(
        world_fingerprint(world) == base,
        "HOTBAR/TARGET/RIGID projection mutated world (fingerprint drift)",
    )

    # Hotbar sensitivity: selection + slot table.
    var saved_sel = world.hotbar.selected_index
    world.hotbar.selected_index = 4 if saved_sel != 4 else 5
    _check(world_fingerprint(world) != base, "fingerprint misses selection")
    world.hotbar.selected_index = saved_sel

    var saved_slot = world.hotbar.slot_ids[3]
    world.hotbar.slot_ids[3] = 90 if saved_slot != 90 else 91
    _check(world_fingerprint(world) != base, "fingerprint misses slot ids")
    world.hotbar.slot_ids[3] = saved_slot

    # Edit FIFO sensitivity: pending op count + head.
    _check(
        edit_apply_batch(world.edit_queue, world.hotbar, EDIT_OP_DIG, 1),
        "queue accepts a batch for the sensitivity probe",
    )
    _check(world_fingerprint(world) != base, "fingerprint misses pending op")
    var saved_head = world.edit_queue.head
    world.edit_queue.head = saved_head  # restore no-op; pop instead
    var popped = edit_pop(world.edit_queue)
    _ = popped
    _check(
        world_fingerprint(world) == base,
        "fingerprint not restored after draining the queue",
    )

    # Rigid prop sensitivity: pose + material + count.
    var saved_px = world.props.bodies[0].x
    world.props.bodies[0].x = saved_px + 1.0
    _check(world_fingerprint(world) != base, "fingerprint misses body x")
    world.props.bodies[0].x = saved_px

    var saved_pm = world.props.bodies[0].material_id
    world.props.bodies[0].material_id = saved_pm + 1
    _check(world_fingerprint(world) != base, "fingerprint misses body material")
    world.props.bodies[0].material_id = saved_pm

    var saved_pc = world.props.count
    world.props.count = saved_pc - 1
    _check(world_fingerprint(world) != base, "fingerprint misses prop count")
    world.props.count = saved_pc

    _check(world_fingerprint(world) == base, "fingerprint fully restored")


def main() raises:
    TestSuite.discover_tests[
        (
            test_purity_after_first_projection,
            test_purity_after_steps_and_repeated_projection,
            test_projection_is_pure_and_repeatable,
            test_world_fingerprint_includes_volcano_state,
            test_world_fingerprint_includes_foam_state,
            test_world_fingerprint_includes_flora_flock_state,
            test_world_fingerprint_includes_hotbar_queue_props,
        )
    ]().run()
