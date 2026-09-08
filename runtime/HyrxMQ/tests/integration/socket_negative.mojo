# Malformed / hostile inputs fed to AMQPFrameCodec (audit §9 robustness,
# §13/§18/§29 enforcement).

# Every case asserts the codec either REJECTS (catchable `AMQP frame error:`),
# returns None ("need more"), or keeps its internal buffer inside the declared
# ceiling — i.e. fails SAFE. Nothing here documents a gap any more: the two
# former KNOWN_GAP cases (invalid frame_type accepted; no frame-size ceiling)
# are now enforced rejections.

# Success prints SOCKET_NEGATIVE_PASS.

from std.collections import List

from hyrx.amqp.frame_codec import AMQPFrameCodec, DEFAULT_MAX_FRAME_SIZE

from hyrx.testing import check


def OUT_NEED_MORE() -> Int:
    return 0


def OUT_PARSED() -> Int:
    return 1


def OUT_REJECTED() -> Int:
    return 2


def OUT_FED() -> Int:
    """feed_bytes returned without raising (no verdict about frames)."""
    return 3


struct Verdict:
    """Classified outcome of one codec call + the rejection message."""

    var code: Int
    var msg: String

    def __init__(out self, code: Int, var msg: String):
        self.code = code
        self.msg = msg


def attempt(mut codec: AMQPFrameCodec) -> Verdict:
    """Classify one try_parse_frame call. A raise is a SAFE rejection."""
    try:
        var f = codec.try_parse_frame()
        if f.__bool__():
            return Verdict(OUT_PARSED(), "")
        return Verdict(OUT_NEED_MORE(), "")
    except e:
        return Verdict(OUT_REJECTED(), String(e))


def attempt_feed(mut codec: AMQPFrameCodec, var data: List[UInt8]) -> Verdict:
    """Classify one feed_bytes call (the accumulation bound lives there)."""
    try:
        codec.feed_bytes(data^)
    except e:
        return Verdict(OUT_REJECTED(), String(e))
    return Verdict(OUT_FED(), "")


def is_rejection(v: Verdict) -> Bool:
    """A rejection must be the dedicated, catchable AMQP frame error."""
    return v.code == OUT_REJECTED() and v.msg.find("AMQP frame error:") == 0


def hdr(mut b: List[UInt8], t: UInt8, ch: UInt16, size: UInt32):
    """Append a 7-byte AMQP frame header (type, channel, size big-endian)."""
    b.append(t)
    b.append(UInt8((ch >> 8) & 0xFF))
    b.append(UInt8(ch & 0xFF))
    b.append(UInt8((size >> 24) & 0xFF))
    b.append(UInt8((size >> 16) & 0xFF))
    b.append(UInt8((size >> 8) & 0xFF))
    b.append(UInt8(size & 0xFF))


def frame_with_type(t: UInt8) -> List[UInt8]:
    """A structurally valid frame (size + trailing 0xCE) but a caller-chosen
    frame-type byte."""
    var b = List[UInt8]()
    hdr(b, t, UInt16(1), UInt32(4))
    b.append(0x00)
    b.append(0x01)
    b.append(0x02)
    b.append(0x03)
    b.append(0xCE)
    return b^


def whole_frame(size: Int) -> List[UInt8]:
    """A complete METHOD frame declaring a `size`-byte payload."""
    var b = List[UInt8]()
    hdr(b, UInt8(1), UInt16(1), UInt32(size))
    b.resize(7 + size, 0x41)
    b.append(0xCE)
    return b^


# ---- case A: invalid frame-type byte (was KNOWN_GAP) ----------------
# Valid AMQP frame types are 1,2,3,8. Any other first octet is now rejected,
# immediately (before the rest of the frame even arrives).

def case_invalid_frame_type() raises:
    for bad in [UInt8(0xAA), UInt8(0x00), UInt8(0x04), UInt8(0xFF)]:
        var codec = AMQPFrameCodec()
        codec.feed_bytes(frame_with_type(bad)^)
        var v = attempt(codec)
        check(
            is_rejection(v),
            "invalid frame_type byte " + String(Int(bad)) + " must be rejected"
        )
        check(
            v.msg.find("bad frame_type") >= 0,
            "rejection must name the offending field: " + v.msg
        )
        check(
            codec.buffered_bytes() <= codec.frame_limit() + 8,
            "rejection must leave the buffer bounded"
        )

    # Illegal type is provable from the first octet alone: no need-more.
    var codec = AMQPFrameCodec()
    var one = List[UInt8]()
    one.append(0x7F)
    codec.feed_bytes(one^)
    check(is_rejection(attempt(codec)), "bad type rejected before the header ends")


# ---- case B: bad frame-end byte (not 0xCE) --------------------------
# The codec raises on a mismatched frame-end. That is a safe rejection.

def case_bad_frame_end() raises:
    var good = AMQPFrameCodec.encode_method_frame(
        UInt16(1), UInt16(10), UInt16(40), List[UInt8]()^
    )
    var last = len(good) - 1
    good[last] = 0x00  # corrupt only the frame-end byte
    var codec = AMQPFrameCodec()
    codec.feed_bytes(good^)
    var v = attempt(codec)
    check(is_rejection(v), "bad frame-end must be rejected (raise) — got safe")
    check(v.msg.find("frame end byte") >= 0, "rejection names the frame end")


# ---- case C: truncated frame (declared size legal) ------------------
# Must report "need more" (None), never over-read into uninitialized bytes.

def case_truncated() raises:
    var full = AMQPFrameCodec.encode_method_frame(
        UInt16(2), UInt16(50), UInt16(10), bytes_of_abcd()^
    )
    var codec = AMQPFrameCodec()
    codec.feed_bytes(slice_copy(full, 0, 7)^)
    check(
        attempt(codec).code == OUT_NEED_MORE(),
        "header-only legal frame must report need-more"
    )
    for cut in range(7, len(full)):
        codec.feed_bytes(slice_copy(full, cut, cut + 1)^)
        if cut < len(full) - 1:
            check(
                attempt(codec).code == OUT_NEED_MORE(),
                "truncated frame must report need-more, not over-read"
            )
    check(
        attempt(codec).code == OUT_PARSED(),
        "full frame parses once complete"
    )


# ---- case D: oversized declared size (was KNOWN_GAP) ----------------
# D1: a header declaring ~4 GiB is REJECTED at once — the declared size is
#     never allocated, and the buffer stays at the 7 header bytes.
# D2: a complete frame one byte over the 131072-byte ceiling is REJECTED.
# D3: a client dribbling bytes toward a never-complete huge frame is REJECTED
#     by the accumulation bound, with the buffer never exceeding ceiling + 8.

def case_oversized_header_only() raises:
    var b = List[UInt8]()
    hdr(b, UInt8(1), UInt16(1), UInt32(0xFFFFFFFF))  # ~4 GiB declared
    var codec = AMQPFrameCodec()
    codec.feed_bytes(b^)
    var v = attempt(codec)
    check(is_rejection(v), "huge declared size must be rejected, not buffered")
    check(
        v.msg.find("exceeds the frame ceiling") >= 0,
        "rejection must state the ceiling: " + v.msg
    )
    check(
        codec.buffered_bytes() == 7,
        "no payload may be allocated for an oversized frame"
    )
    # Still rejected after further bytes arrive; the buffer never grows past
    # the ceiling either.
    for _ in range(64):
        var more = List[UInt8](capacity=64)
        more.resize(64, 0x41)
        var fv = attempt_feed(codec, more^)
        check(
            fv.code == OUT_FED() or is_rejection(fv),
            "feed either accepts or rejects safely"
        )
        check(is_rejection(attempt(codec)), "oversized stays rejected")
        check(
            codec.buffered_bytes() <= codec.frame_limit() + 8,
            "buffer must stay bounded while dribbling"
        )


def case_frame_over_ceiling_rejected() raises:
    """A 131073-byte frame (one over the ceiling) is refused and never buffered
    beyond the bound — either at feed time (whole batch) or at parse time
    (header announcing it)."""
    var over_max = DEFAULT_MAX_FRAME_SIZE() + 1  # 131073 > 131072

    # Whole batch delivered: refused by the accumulation bound.
    var codec = AMQPFrameCodec()
    var fv = attempt_feed(codec, whole_frame(over_max)^)
    check(is_rejection(fv), "a frame larger than max_frame_size must be rejected")
    check(
        codec.buffered_bytes() <= codec.frame_limit() + 8,
        "buffer must stay bounded after an oversized frame ("
        + String(codec.buffered_bytes())
        + ")",
    )

    # Header only: the DECLARED size alone is enough to reject, with no payload
    # allocation at all.
    var h = AMQPFrameCodec()
    var hb = List[UInt8]()
    hdr(hb, UInt8(1), UInt16(1), UInt32(over_max))
    h.feed_bytes(hb^)
    var v = attempt(h)
    check(is_rejection(v), "oversized declared size must be rejected at parse")
    check(
        v.msg.find("exceeds the frame ceiling") >= 0,
        "rejection must state the ceiling: " + v.msg
    )
    check(h.buffered_bytes() == 7, "no payload allocated for an oversized frame")


def case_trickle_to_ceiling() raises:
    """size=0xFFFFFFFF dribbled one chunk at a time is refused, bounded."""
    var b = List[UInt8]()
    hdr(b, UInt8(1), UInt16(1), UInt32(0xFFFFFFFF))
    var codec = AMQPFrameCodec()
    var fed = 0
    var rejected = False
    var ceiling = codec.frame_limit() + 8
    while fed < 2 * ceiling and not rejected:
        var more = List[UInt8](capacity=4096)
        more.resize(4096, 0x41)
        var fv = attempt_feed(codec, more^)
        if is_rejection(fv):
            rejected = True
            break
        fed += 4096
        check(
            codec.buffered_bytes() <= ceiling,
            "buffer must never exceed ceiling+8 during the trickle"
        )
        if attempt(codec).code == OUT_REJECTED():
            rejected = True
    check(rejected, "a never-complete huge frame must be refused")
    check(
        codec.buffered_bytes() <= ceiling,
        "buffer is bounded at refusal ("
        + String(codec.buffered_bytes())
        + " <= "
        + String(ceiling)
        + ")"
    )


# ---- case F: the ceiling is a ceiling, not a wall (regression) ------
# Exactly-ceiling-size frames must still parse, and a large legitimate batch
# within the ceiling must not be refused.

def case_at_ceiling_still_parses() raises:
    var codec = AMQPFrameCodec()
    check(codec.frame_limit() == DEFAULT_MAX_FRAME_SIZE(), "default ceiling")
    var b = whole_frame(codec.frame_limit())
    check(len(b) == codec.frame_limit() + 8, "frame is exactly at the ceiling")
    var fv = attempt_feed(codec, b^)
    check(fv.code == OUT_FED(), "at-ceiling feed must be accepted")
    check(
        attempt(codec).code == OUT_PARSED(),
        "at-ceiling frame must parse (bound is not off by one)"
    )

    var small = AMQPFrameCodec()
    for _ in range(8):
        small.feed_bytes(frame_with_type(UInt8(1))^)
        check(
            attempt(small).code == OUT_PARSED(),
            "back-to-back small frames parse one per call"
        )


# ---- case E: garbage / short buffer repeatedly ----------------------
# Feeding random short garbage must never crash the process or hang; every call
# returns control (NEED_MORE, PARSED, or REJECTED are all "handled").

def case_garbage_repeated() raises:
    var codec = AMQPFrameCodec()
    var handled = 0
    for i in range(256):
        var g = List[UInt8](capacity=8)
        var n = 1 + (i % 8)
        g.resize(n, 0)
        for j in range(n):
            g[j] = UInt8((i * 31 + j * 17 + 5) & 0xFF)
        if is_rejection(attempt_feed(codec, g^)):
            handled += 1
            break
        var v = attempt(codec)
        check(
            v.code == OUT_NEED_MORE()
            or v.code == OUT_PARSED()
            or is_rejection(v),
            "garbage always yields a classified outcome"
        )
        handled += 1
        if codec.buffered_bytes() > 1000:
            # A rejected codec keeps its poison; drain by constructing a new one
            # so the loop cannot reach the accumulation bound by accident.
            codec = AMQPFrameCodec()
    check(handled > 0, "garbage loop ran to completion without hang/crash")


# ---------- small byte helpers ----------

def bytes_of_abcd() -> List[UInt8]:
    var out = List[UInt8]()
    out.append(0xAA)
    out.append(0xBB)
    out.append(0xCC)
    out.append(0xDD)
    return out^


def slice_copy(src: List[UInt8], lo: Int, hi: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(lo, hi):
        out.append(src[i])
    return out^


def main() raises:
    case_invalid_frame_type()
    case_bad_frame_end()
    case_truncated()
    case_oversized_header_only()
    case_frame_over_ceiling_rejected()
    case_trickle_to_ceiling()
    case_at_ceiling_still_parses()
    case_garbage_repeated()
    print("enforced rejections: invalid frame_type, oversized frame, trickle")
    print("SOCKET_NEGATIVE_PASS")
