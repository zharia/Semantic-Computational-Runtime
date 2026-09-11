# Phase 10 — AMQP frame-parser fuzz / adversarial test (docs/SECURITY.md).
#
# Requirement: "A malformed client must not crash the process or corrupt
# broker state." This test feeds MALFORMED wire bytes into AMQPFrameCodec and
# checks that every input reaches ONE of three safe outcomes:
#   "error" — a catchable `AMQP frame error:` raise (fail closed),
#   "none"  — try_parse_frame returned None (needs more bytes), or
#   "frame" — a structurally complete frame decoded.
#
# A segfault or an uncaught raise aborts Mojo, so the final
# PHASE10_FRAME_FUZZ_TEST=PASS line itself proves the process survived.
# Each case uses a FRESH codec, modelling the network path failing the
# connection closed and discarding its codec on a protocol error.

from std.collections import List

from hyrx.amqp.frame_codec import AMQPFrameCodec, parse_method_args
from hyrx.testing import check


def append_header(mut b: List[UInt8], t: UInt8, size: UInt32):
    """Append a 7-octet frame header: type(1) + channel(2) + size(4)."""
    b.append(t)
    b.append(0)
    b.append(1)
    b.append(UInt8((size >> 24) & 0xFF))
    b.append(UInt8((size >> 16) & 0xFF))
    b.append(UInt8((size >> 8) & 0xFF))
    b.append(UInt8(size & 0xFF))


def probe(var data: List[UInt8]) raises -> String:
    """Feed `data` to a fresh codec; return "error" | "none" | "frame".

    Never catches a crash: a bad input that segfaults aborts the process, so
    reaching a return value is itself the safety evidence. The retained-backlog
    bound is re-checked after the attempt so a malformed input can never grow
    the codec past one maximum-size frame.
    """
    var codec = AMQPFrameCodec()
    var rejected = False
    var parsed = False
    try:
        codec.feed_bytes(data^)
        parsed = codec.try_parse_frame().__bool__()
    except:
        rejected = True
    check(
        codec.buffered_bytes() <= codec.frame_limit() + 8,
        "adversarial input left the codec backlog unbounded",
    )
    if rejected:
        return "error"
    if parsed:
        return "frame"
    return "none"


def test_empty_input() raises:
    """(1) An empty byte list must yield no frame and no crash."""
    check(probe(List[UInt8]()) == "none", "empty byte list yields no frame")


def test_truncated_header() raises:
    """(2) Fewer than 7 header octets must be buffered, not misread."""
    var one = List[UInt8]()
    one.append(1)  # METHOD, a legal first octet
    check(probe(one^) == "none", "1-octet truncated header waits for more")

    var five = List[UInt8]()
    five.append(1)
    for _ in range(4):
        five.append(0)
    check(probe(five^) == "none", "5-octet truncated header waits for more")


def test_oversized_declared_size() raises:
    """(3) A declared size of 0xFFFFFFFF with no body must be rejected before
    any allocation is driven by the declared value."""
    var b = List[UInt8]()
    append_header(b, 1, UInt32(0xFFFFFFFF))
    check(len(b) == 7, "header is exactly 7 octets")
    check(
        probe(b^) == "error",
        "0xFFFFFFFF declared size with no body is rejected cleanly",
    )


def test_truncated_body() raises:
    """(4) A valid header whose declared body has not fully arrived waits."""
    var b = List[UInt8]()
    append_header(b, 3, UInt32(100))  # BODY declares 100 octets
    for _ in range(50):
        b.append(0x41)  # only half the declared body arrives
    check(probe(b^) == "none", "valid header + short body waits, no crash")


def test_invalid_frame_type() raises:
    """(5) An illegal frame-type octet (99) must be rejected as soon as the
    first octet arrives."""
    var b = List[UInt8]()
    append_header(b, 99, UInt32(4))
    for _ in range(4):
        b.append(0x41)
    b.append(0xCE)
    check(probe(b^) == "error", "frame type 99 is rejected cleanly")


def test_random_bytes() raises:
    """(6) 1000 deterministic xorshift64 inputs, each 0..63 bytes.

    Any malformed string may error, wait, or (rarely) decode; all three are
    safe. The distribution is printed for evidence.
    """
    var state = UInt64(88172645463325252)
    var saw_error = 0
    var saw_none = 0
    var saw_frame = 0
    for _ in range(1000):
        state = state ^ (state << 13)
        state = state ^ (state >> 7)
        state = state ^ (state << 17)
        var n = Int(state & 0x3F)  # 0..63 octets
        var data = List[UInt8](capacity=n)
        for _ in range(n):
            state = state ^ (state << 13)
            state = state ^ (state >> 7)
            state = state ^ (state << 17)
            data.append(UInt8(state & 0xFF))
        var r = probe(data^)
        if r == "error":
            saw_error += 1
        elif r == "none":
            saw_none += 1
        elif r == "frame":
            saw_frame += 1
        else:
            check(False, "unexpected fuzz outcome: " + r)
    check(
        saw_error + saw_none + saw_frame == 1000,
        "every random input produced a safe outcome",
    )
    print(
        "FUZZ_RANDOM error="
        + String(saw_error)
        + " none="
        + String(saw_none)
        + " frame="
        + String(saw_frame)
    )


def test_truncated_method_args() raises:
    """(7) A structurally complete METHOD frame whose payload is too short to
    hold class-id + method-id must fail the method-args parser cleanly."""
    var b = List[UInt8]()
    append_header(b, 1, UInt32(2))  # METHOD payload = class-id only
    b.append(0)
    b.append(60)
    b.append(0xCE)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(b^)
    var fr = codec.try_parse_frame()
    check(fr.__bool__(), "structurally complete method frame decodes")
    check(fr.value().payload_size() == 2, "payload is 2 octets (class-id only)")
    var rejected = False
    try:
        _ = parse_method_args(fr.value().payload_copy())
    except:
        rejected = True
    check(rejected, "truncated method args raise a clean error, not a crash")


def test_zero_length_frames() raises:
    """(8) Zero-length METHOD/HEADER/BODY/HEARTBEAT frames parse safely."""
    for t in [UInt8(1), UInt8(2), UInt8(3), UInt8(8)]:
        var b = List[UInt8]()
        append_header(b, t, UInt32(0))
        b.append(0xCE)
        check(
            probe(b^) == "frame",
            "zero-length frame type " + String(Int(t)) + " parses safely",
        )


def main() raises:
    test_empty_input()
    test_truncated_header()
    test_oversized_declared_size()
    test_truncated_body()
    test_invalid_frame_type()
    test_random_bytes()
    test_truncated_method_args()
    test_zero_length_frames()
    print("PHASE10_FRAME_FUZZ_TEST=PASS")
