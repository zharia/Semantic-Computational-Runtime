# SCR IPC server — headless UDS entry point (milestone 0008 / AP-15..18).
#
#   mojo build server/main.mojo -I src/mojo -o ../../build/scr_sim_server
#   scr_sim_server --socket /path/to.sock --seed 1 --pace manual
#
# Options:
#   --socket PATH   filesystem Unix-domain socket path (required)
#   --seed N        world seed (default: 1)
#   --pace MODE     wall | manual (default: wall) — server-side default only;
#                   a HELLO with SCR_IPC_FLAG_MANUAL_PACE always wins
#   --help          show this help and exit
#
# Exit codes: 0 = clean session (BYE/EOF), non-zero = handshake refused,
# socket failure, or a fatal session error (0008 AP-17: refusals are loud).
#
# AP-1: engine-free (scripts/check_layout.sh gate 1 covers every .mojo under
# src/mojo). AP-4: the socket path is a runtime argument, never a source
# literal.

from std.sys import argv
from std.runtime import initialize_runtime

from server.session import serve


comptime VERSION = "0.0.1"


def _help():
    print("SCR IPC simulation server " + VERSION)
    print("")
    print("usage: scr_sim_server --socket PATH [--seed N] [--pace MODE]")
    print("")
    print("options:")
    print("  --help         show this help and exit")
    print("  --socket PATH  filesystem Unix-domain socket path (required)")
    print("  --seed N       world seed (default: 1)")
    print("  --pace MODE    wall | manual (default: wall)")
    print("")
    print("protocol: SCRT frames, proto 1 / ABI 2 / schema 7")


def _parse_u32(s: String) raises -> UInt32:
    var acc: UInt64 = 0
    var any_digit = False
    for b in s.bytes():
        var c = Int(b)
        if c < 48 or c > 57:
            raise Error("bad integer: " + s)
        acc = acc * 10 + UInt64(c - 48)
        if acc > 4294967295:
            raise Error("integer out of u32 range: " + s)
        any_digit = True
    if not any_digit:
        raise Error("bad integer: " + s)
    return UInt32(acc)


def main() raises:
    initialize_runtime()  # same explicit boot as export/abi.mojo entry points
    var args = argv()
    var socket_path = String("")
    var seed: UInt32 = 1
    var pace_manual = False

    var i = 1
    while i < len(args):
        var a = args[i]
        if a == "--":
            i += 1
            continue
        if a == "--help" or a == "-h":
            _help()
            return
        elif a == "--socket":
            if i + 1 >= len(args):
                raise Error("--socket requires a value")
            socket_path = args[i + 1]
            i += 2
            continue
        elif a == "--seed":
            if i + 1 >= len(args):
                raise Error("--seed requires a value")
            seed = _parse_u32(args[i + 1])
            i += 2
            continue
        elif a == "--pace":
            if i + 1 >= len(args):
                raise Error("--pace requires a value")
            var mode = args[i + 1]
            if mode == "manual":
                pace_manual = True
            elif mode == "wall":
                pace_manual = False
            else:
                raise Error("--pace must be 'wall' or 'manual', got: " + mode)
            i += 2
            continue
        else:
            raise Error("unknown argument: " + a)

    if socket_path == "":
        _help()
        raise Error("--socket PATH is required")

    var code = serve(socket_path, pace_manual, seed)
    if code != 0:
        raise Error("session ended with code " + String(code))
