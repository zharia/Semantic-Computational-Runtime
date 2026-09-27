# SCR Godot application — headless simulation CLI entry.
#
# Runs the fixed-timestep core without Godot (AP-1: no engine dependency)
# and can emit a snapshot file for inspection or golden-fixture regeneration.
#
#   mojo run main.mojo -- --help
#   mojo run main.mojo -- --seed 1 --ticks 60 --out snapshot.bin
#
# Determinism: `--ticks N` executes N calls of dt = 1/60 (exactly one fixed
# tick each), so `--seed 1 --ticks 1` is the golden-fixture trajectory.

from std.sys import argv
from std.collections import List

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
from snapshot.encode import encode_snapshot
from snapshot.decode import decode_envelope, decode_sections, find_section
from snapshot.types import SEC_TERRAIN, SEC_PLAYER, SEC_MATERIALS
from util.files import write_file_bytes

comptime VERSION = "0.0.1"


def _help():
    print("SCR Godot headless simulation core " + VERSION)
    print("")
    print("usage: scr-sim [options]")
    print("")
    print("options:")
    print("  --help            show this help and exit")
    print("  --version         print version and exit")
    print("  --seed N          world seed (default: 1)")
    print("  --ticks N         fixed ticks to run at 60 Hz (default: 60)")
    print("  --input move_x,move_y,look_dx,look_dy,jump,sprint")
    print("                    input batch applied to every tick")
    print("                    (defaults: 0,0,0,0,0,0 = idle)")
    print("  --out FILE        write the final snapshot bytes to FILE")


def _parse_f(s: String) raises -> Float64:
    var neg = False
    var i = 0
    var bytes = List[UInt8]()
    for b in s.bytes():
        bytes.append(b)
    if len(bytes) == 0:
        raise Error("empty number")
    if bytes[0] == 45:  # '-'
        neg = True
        i = 1
    var int_part: Float64 = 0.0
    var seen_dot = False
    var frac = 0.0
    var frac_div = 1.0
    var any_digit = False
    while i < len(bytes):
        var c = Int(bytes[i])
        if c == 46 and not seen_dot:
            seen_dot = True
            i += 1
            continue
        if c < 48 or c > 57:
            raise Error("bad number: " + s)
        any_digit = True
        if not seen_dot:
            int_part = int_part * 10.0 + Float64(c - 48)
        else:
            frac_div *= 10.0
            frac += Float64(c - 48) / frac_div
        i += 1
    if not any_digit:
        raise Error("bad number: " + s)
    var v = int_part + frac
    if neg:
        v = -v
    return v


def _parse_u64(s: String) raises -> UInt64:
    var acc: UInt64 = 0
    var any_digit = False
    for b in s.bytes():
        var c = Int(b)
        if c < 48 or c > 57:
            raise Error("bad integer: " + s)
        acc = acc * 10 + UInt64(c - 48)
        any_digit = True
    if not any_digit:
        raise Error("bad integer: " + s)
    return acc


def main() raises:
    var args = argv()
    var seed: UInt64 = 1
    var ticks: UInt64 = 60
    var out_path = String("")
    var mvx = 0.0
    var mvy = 0.0
    var ldx = 0.0
    var ldy = 0.0
    var jump = 0
    var sprint = 0

    var i = 1
    while i < len(args):
        var a = args[i]
        if a == "--":
            i += 1
            continue
        if a == "--help" or a == "-h":
            _help()
            return
        elif a == "--version":
            print("godot-app version", VERSION)
            return
        elif a == "--seed":
            if i + 1 >= len(args):
                raise Error("--seed requires a value")
            i += 1
            seed = _parse_u64(args[i])
        elif a == "--ticks":
            if i + 1 >= len(args):
                raise Error("--ticks requires a value")
            i += 1
            ticks = _parse_u64(args[i])
        elif a == "--out":
            if i + 1 >= len(args):
                raise Error("--out requires a value")
            i += 1
            out_path = args[i]
        elif a == "--input":
            if i + 1 >= len(args):
                raise Error("--input requires a value")
            i += 1
            var parts = List[String]()
            var cur = String("")
            for b in args[i].bytes():
                if b == 44:  # ','
                    parts.append(cur.copy())
                    cur = String("")
                else:
                    cur = cur + chr(Int(b))
            parts.append(cur^)
            if len(parts) != 6:
                raise Error("--input expects 6 comma-separated values")
            mvx = _parse_f(parts[0])
            mvy = _parse_f(parts[1])
            ldx = _parse_f(parts[2])
            ldy = _parse_f(parts[3])
            jump = Int(_parse_u64(parts[4]))
            sprint = Int(_parse_u64(parts[5]))
        else:
            raise Error("unknown option: " + a + " (try --help)")
        i += 1

    var input = InputBatch()
    input.move_x = Float32(mvx)
    input.move_y = Float32(mvy)
    input.look_dx = Float32(ldx)
    input.look_dy = Float32(ldy)
    input.jump = UInt8(jump)
    input.sprint = UInt8(sprint)

    var world = world_init(UInt32(seed))
    print("seed:", world.seed, "spawn:", world.island.spawn_x, world.island.spawn_y, world.island.spawn_z)
    print("chunks:", world.island.chunk_count, "peak:", world.island.peak_height)

    var total: UInt64 = 0
    for _ in range(Int(ticks)):
        var ran = step_world(world, 1.0 / 60.0, input)
        if ran < 0:
            raise Error("step failed: " + String(ran))
        total += UInt64(ran)
    print("ticks:", total, "tick:", world.simulation_tick, "time:", world.simulation_time)

    var snapshot = encode_snapshot(world, True)
    var env = decode_envelope(snapshot)
    var secs = decode_sections(snapshot, env)
    var has_terrain = find_section(secs, SEC_TERRAIN)
    var materials = find_section(secs, SEC_MATERIALS)
    print(
        "snapshot:", len(snapshot), "bytes,", env.section_count, "sections, terrain idx",
        has_terrain, "materials idx", materials,
    )
    print("fingerprint:", world_fingerprint(world))

    if out_path.byte_length() > 0:
        write_file_bytes(out_path, snapshot)
        print("wrote", out_path)
