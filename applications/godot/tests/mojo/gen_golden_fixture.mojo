# Golden fixture generator (NOT a test — a maintenance tool).
#
# Regenerates tests/fixtures/snapshot_seed1_tick1.bin:
#   seed 1 → one step dt = 1/60 with the documented scripted input →
#   snapshot with all fourteen sections (schema 7: 1..9 framing from schema
#   4; 10 FLORA — 32 B records since 0010 Sprint 02; 11 FAUNA + 12 HOTBAR +
#   13 TARGET + 14 RIGID_BODIES from schema 6;
#   TERRAIN per-vertex payload is the 4-byte blend tuple — stride-neutral;
#   include_terrain = True, include_flora = True, first snapshot).
#
# Run (from repo root) ONLY when an intentional contract/code change alters
# snapshot bytes; test_golden_fixture must then be re-run and the diff
# reviewed:
#   mojo run -I applications/godot/src/mojo \
#     applications/godot/tests/mojo/gen_golden_fixture.mojo
#
# Scripted input (shared by test_golden_fixture and tests/abi_smoke.py):
#   move_x=0.5  move_y=1.0  look_dx=0.25  look_dy=-0.1  jump=1  sprint=0

from sim.world import world_init, step_world
from sim.input import InputBatch
from snapshot.encode import encode_snapshot
from util.files import find_repo_root, join_path, write_file_bytes

comptime FIXTURE_REL = "applications/godot/tests/fixtures/snapshot_seed1_tick1.bin"

comptime SEED: UInt32 = 1
comptime MOVE_X: Float32 = 0.5
comptime MOVE_Y: Float32 = 1.0
comptime LOOK_DX: Float32 = 0.25
comptime LOOK_DY: Float32 = -0.1
comptime JUMP: UInt8 = 1
comptime SPRINT: UInt8 = 0


def scripted_input() -> InputBatch:
    var b = InputBatch()
    b.move_x = MOVE_X
    b.move_y = MOVE_Y
    b.look_dx = LOOK_DX
    b.look_dy = LOOK_DY
    b.jump = JUMP
    b.sprint = SPRINT
    return b


def main() raises:
    var world = world_init(SEED)
    var ran = step_world(world, 1.0 / 60.0, scripted_input())
    if ran != 1:
        raise Error("expected exactly one tick, got " + String(ran))
    var snapshot = encode_snapshot(world, True)
    var path = join_path(find_repo_root(), FIXTURE_REL)
    write_file_bytes(path, snapshot)
    print("wrote", path, len(snapshot), "bytes; tick", world.simulation_tick)
