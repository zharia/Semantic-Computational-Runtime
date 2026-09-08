# AMQP frame codec BOUND + VALIDATION tests (audit §9/§13/§18/§29).

# Focus: the untrusted-input guarantees of AMQPFrameCodec —
#   1. frame-type validation (only 1/2/3/8 are legal),
#   2. the declared-size ceiling (validated before any payload is copied),
#   3. the internal-buffer accumulation bound (a dribbling client cannot grow it
#      past ceiling + 8),
#   4. every violation is a CATCHABLE error, never a crash or an allocation.

# Success prints PHASE6_FRAME_CODEC_BOUNDS=PASS.

from std.collections import List

from hyrx.amqp.frame_codec import (
    AMQPFrameCodec,
    DEFAULT_MAX_FRAME_SIZE,
)
from hyrx.amqp.constants import (
    FRAME_BODY,
    FRAME_END,
    FRAME_HEADER,
    FRAME_HEARTBEAT,
    FRAME_METHOD,
)

from hyrx.testing import check


def header(mut b: List[UInt8], t: UInt8, size: Int):
    b.append(t)
    b.append(UInt8(0))
    b.append(UInt8(1))
    b.append(UInt8((size >> 24) & 0xFF))
    b.append(UInt8((size >> 16) & 0xFF))
    b.append(UInt8((size >> 8) & 0xFF))
    b.append(UInt8(size & 0xFF))


def complete_frame(t: UInt8, size: Int) -> List[UInt8]:
    """A structurally complete frame of type `t` with a `size`-byte payload."""
    var b = List[UInt8]()
    header(b, t, size)
    b.resize(7 + size, 0x41)
    b.append(FRAME_END())
    return b^


def rejected(mut codec: AMQPFrameCodec) -> String:
    """Return the rejection message, or "" when the parse did not reject."""
    try:
        _ = codec.try_parse_frame()
    except e:
        return String(e)
    return ""


def test_default_ceiling() raises:
    """Default construction carries the documented fixed ceiling."""
    var codec = AMQPFrameCodec()
    check(codec.frame_limit() == 131072, "default ceiling is 131072")
    check(
        codec.frame_limit() == DEFAULT_MAX_FRAME_SIZE(),
        "default matches the module constant",
    )
    check(codec.buffered_bytes() == 0, "a fresh codec holds no bytes")

    var tight = AMQPFrameCodec(4096)
    check(tight.frame_limit() == 4096, "ceiling is configurable per codec")


def test_legal_frame_types_accepted() raises:
    """METHOD/HEADER/BODY/HEARTBEAT all parse."""
    for t in [FRAME_METHOD(), FRAME_HEADER(), FRAME_BODY(), FRAME_HEARTBEAT()]:
        var codec = AMQPFrameCodec()
        codec.feed_bytes(complete_frame(t, 4)^)
        var v = codec.try_parse_frame()
        check(v.__bool__(), "legal frame type " + String(Int(t)) + " parses")
        check(v.value().frame_type == t, "frame type round-trips")
        check(v.value().payload_size() == 4, "payload round-trips")
        check(codec.buffered_bytes() == 0, "buffer drained after parse")


def test_illegal_frame_types_rejected() raises:
    """Every other first octet is rejected, catchably, without buffering more."""
    for t in [UInt8(0), UInt8(4), UInt8(5), UInt8(6), UInt8(7), UInt8(9), UInt8(0xFE)]:
        var codec = AMQPFrameCodec()
        codec.feed_bytes(complete_frame(t, 4)^)
        var msg = rejected(codec)
        check(msg.byte_length() > 0, "frame type " + String(Int(t)) + " must be rejected")
        check(msg.find("AMQP frame error:") == 0, "rejection is the dedicated error")
        check(msg.find("bad frame_type") >= 0, "rejection names the field: " + msg)


def test_declared_size_ceiling_enforced() raises:
    """A declared size over the ceiling is rejected BEFORE any payload copy."""
    var over = DEFAULT_MAX_FRAME_SIZE() + 1
    var codec = AMQPFrameCodec()
    var b = List[UInt8]()
    header(b, FRAME_METHOD(), over)  # header only: the bytes never arrive
    codec.feed_bytes(b^)
    var msg = rejected(codec)
    check(msg.find("exceeds the frame ceiling") >= 0, "oversized declared rejected")
    check(codec.buffered_bytes() == 7, "only the header is retained, never size")

    # A whole oversized frame cannot even be fed: the accumulation bound stops
    # it earlier (still a catchable rejection, still no uncontrolled copy).
    var tight = AMQPFrameCodec(64)
    var fed_msg = ""
    try:
        tight.feed_bytes(complete_frame(FRAME_BODY(), 65)^)
    except e:
        fed_msg = String(e)
    check(fed_msg.byte_length() > 0 and fed_msg.find("AMQP frame error:") == 0, "oversized batch refused at feed")
    check(
        tight.buffered_bytes() <= 64 + 8,
        "refused batch is not buffered (" + String(tight.buffered_bytes()) + " bytes)"
    )

    # Exactly at the ceiling is legal (bound is not off by one).
    var at = AMQPFrameCodec()
    at.feed_bytes(complete_frame(FRAME_BODY(), DEFAULT_MAX_FRAME_SIZE())^)
    var v = at.try_parse_frame()
    check(v.__bool__(), "a ceiling-sized frame parses")
    check(
        v.value().payload_size() == DEFAULT_MAX_FRAME_SIZE(),
        "ceiling-sized payload intact",
    )

    # An in-ceiling declared size on a tight codec still waits for its bytes.
    var patient = AMQPFrameCodec(1024)
    var pb = List[UInt8]()
    header(pb, FRAME_BODY(), 1000)
    patient.feed_bytes(pb^)
    check(
        not patient.try_parse_frame().__bool__(),
        "legal-but-incomplete frame must not be rejected",
    )


def test_buffer_accumulation_bound() raises:
    """Dribbling bytes toward a never-complete frame cannot grow the buffer."""
    var codec = AMQPFrameCodec(1024)
    var ceiling = codec.frame_limit() + 8
    var b = List[UInt8]()
    header(b, FRAME_BODY(), 4096)  # declared larger than this codec's ceiling
    var fmsg = ""
    try:
        codec.feed_bytes(b^)
    except e:
        fmsg = String(e)
    check(fmsg.byte_length() == 0, "the 7-byte header itself is feedable")

    var refused = False
    for _ in range(64):
        var more = List[UInt8](capacity=256)
        more.resize(256, 0x42)
        try:
            codec.feed_bytes(more^)
        except e:
            refused = True
            var emsg = String(e)
            check(
                emsg.find("buffer accumulation") >= 0,
                "accumulation rejection is explicit: " + emsg
            )
            break
        check(
            codec.buffered_bytes() <= ceiling,
            "buffer never exceeds ceiling+8 ("
            + String(codec.buffered_bytes())
            + ")",
        )
    check(refused, "an endless dribble must eventually be refused")
    check(
        codec.buffered_bytes() <= ceiling,
        "buffer is bounded at refusal",
    )

    # The declared size is rejected on its own merits too.
    check(
        rejected(codec).find("exceeds the frame ceiling") >= 0,
        "oversized declared size still rejected after the dribble",
    )


def test_truncated_legal_frame_still_needs_more() raises:
    """A legal, in-ceiling, incomplete frame is NOT rejected — it waits."""
    var codec = AMQPFrameCodec(1024)
    var b = List[UInt8]()
    header(b, FRAME_BODY(), 500)
    codec.feed_bytes(b^)
    check(not codec.try_parse_frame().__bool__(), "header alone needs more")
    var part = List[UInt8]()
    for _ in range(400):
        part.append(0x41)
    codec.feed_bytes(part^)
    check(not codec.try_parse_frame().__bool__(), "400/500 bytes needs more")
    check(codec.buffered_bytes() < 1024 + 8, "partial frame stays bounded")
    var rest = List[UInt8]()
    for _ in range(100):
        rest.append(0x41)
    rest.append(FRAME_END())
    codec.feed_bytes(rest^)
    var done = codec.try_parse_frame()
    check(done.__bool__(), "the frame completes once all bytes arrive")
    check(done.value().payload_size() == 500, "completed payload intact")


def main() raises:
    test_default_ceiling()
    test_legal_frame_types_accepted()
    test_illegal_frame_types_rejected()
    test_declared_size_ceiling_enforced()
    test_buffer_accumulation_bound()
    test_truncated_legal_frame_still_needs_more()
    print("PHASE6_FRAME_CODEC_BOUNDS=PASS")
