# Byte-exactness guard for the contiguous byte path (unsafe_memcpy).
#
# Every batch-copy site is checked byte-for-byte against a deterministic
# pattern: Buffer.from_buffer_copy, Buffer.snapshot/BufferSnapshot.to_bytes,
# Message.payload_into, AMQPFrameCodec.feed_bytes / try_parse_frame /
# encode_body_frame / encode_method_frame, including the zero-length frame and
# the buffer compaction shift. Mojo `assert` is inert in this toolchain (see
# src/hyrx/testing.mojo), so every assertion goes through `check`.

from std.collections import List

from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.core.buffer import Buffer
from hyrx.core.message import Envelope, Message, MessageID
from hyrx.testing import check


def pat_byte(i: Int) -> UInt8:
    """Deterministic pattern byte: (i*31+7) % 256."""
    return UInt8((i * 31 + 7) % 256)


def differ_byte(i: Int) -> UInt8:
    """A byte guaranteed to differ from pat_byte(i)."""
    if pat_byte(i) == UInt8(255):
        return UInt8(0)
    return UInt8(255)


def pattern(n: Int) -> List[UInt8]:
    """A fresh owned list holding the first n pattern bytes."""
    var out = List[UInt8](capacity=n)
    for i in range(n):
        out.append(pat_byte(i))
    return out^


def eq(a: List[UInt8], b: List[UInt8]) -> Bool:
    """Byte-for-byte equality; both lists are consumed."""
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def size_count() -> Int:
    """Number of guarded sizes."""
    return 12


def size_at(i: Int) -> Int:
    """Guarded size set: 0,1,2,3,7,8,127,128,255,4096,16384,65536."""
    if i == 0:
        return 0
    elif i == 1:
        return 1
    elif i == 2:
        return 2
    elif i == 3:
        return 3
    elif i == 4:
        return 7
    elif i == 5:
        return 8
    elif i == 6:
        return 127
    elif i == 7:
        return 128
    elif i == 8:
        return 255
    elif i == 9:
        return 4096
    elif i == 10:
        return 16384
    return 65536


def codec_for(payload_size: Int) -> AMQPFrameCodec:
    """A codec that admits `payload_size`: 4096 where legal, else exactly it.

    try_parse_frame rejects a declared size above its ceiling, so a 4096
    ceiling cannot carry a 16 KiB or 64 KiB frame at all. Larger sizes get a
    ceiling equal to the payload so the byte path, not the reject path, runs.
    """
    var ceiling = 4096
    if payload_size > 4096:
        ceiling = payload_size
    var codec = AMQPFrameCodec(ceiling)
    return codec^


def filled_buffer(size: Int) raises -> Buffer:
    """A Buffer of length `size` (capacity `size`) holding the pattern."""
    var buf = Buffer(size)
    buf.resize(size)
    for i in range(size):
        buf[i] = pat_byte(i)
    return buf^


def test_from_buffer_copy_exact() raises:
    """from_buffer_copy matches the source and does not alias it."""
    for si in range(size_count()):
        var size = size_at(si)
        var src = filled_buffer(size)
        var copy = Buffer.from_buffer_copy(src)
        check(copy.size() == size, "from_buffer_copy: length preserved")
        for j in range(size):
            check(copy[j] == pat_byte(j), "from_buffer_copy: byte exact")
        for j in range(size):
            src[j] = differ_byte(j)
        var unchanged = True
        var distinct = True
        for j in range(size):
            if copy[j] != pat_byte(j):
                unchanged = False
            if src[j] == copy[j]:
                distinct = False
        check(unchanged, "from_buffer_copy: copy survives source mutation")
        check(distinct, "from_buffer_copy: copy does not alias the source")


def test_snapshot_to_bytes_exact() raises:
    """snapshot().to_bytes() reproduces the buffer bytes at every size."""
    for si in range(size_count()):
        var size = size_at(si)
        var buf = filled_buffer(size)
        var snap = buf.snapshot()
        check(snap.size() == size, "snapshot: length preserved")
        var want = pattern(size)
        var got = snap.to_bytes()
        check(eq(want^, got^), "snapshot().to_bytes(): bytes exact")


def test_payload_into_exact() raises:
    """payload_into fills a pre-sized length-0 destination exactly."""
    for si in range(size_count()):
        var size = size_at(si)
        var payload = filled_buffer(size)
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(7), "byte.path", headers^)
        var msg = Message(env^, payload^)
        var dst = Buffer(size)
        check(dst.size() == 0, "payload_into: destination starts empty")
        var filled = msg.payload_into(dst^)
        check(filled.size() == size, "payload_into: destination length exact")
        var want = pattern(size)
        var got = filled.snapshot().to_bytes()
        check(eq(want^, got^), "payload_into: destination bytes exact")
        check(
            msg.payload_size() == size,
            "payload_into: message keeps its own payload",
        )
        var retained = pattern(size)
        var snap = msg.payload().to_bytes()
        check(eq(retained^, snap^), "payload_into: payload snapshot still exact")


def test_body_frame_roundtrip() raises:
    """One feed of a whole body frame parses to the exact payload."""
    for si in range(size_count()):
        var size = size_at(si)
        var wire = AMQPFrameCodec.encode_body_frame(UInt16(1), pattern(size)^)
        check(
            len(wire) == size + 8,
            "body frame: wire length is payload plus 8 octets",
        )
        var codec = codec_for(size)
        codec.feed_bytes(wire^)
        var frame = codec.try_parse_frame()
        check(frame.__bool__(), "body frame: parses after one feed")
        check(
            frame.value().payload_size() == size,
            "body frame: declared size preserved",
        )
        check(frame.value().frame_type == 3, "body frame: type octet preserved")
        var want = pattern(size)
        var got = frame.value().payload_copy()
        check(eq(want^, got^), "body frame: payload bytes exact")
        var drained = codec.try_parse_frame()
        check(not drained.__bool__(), "body frame: buffer drained after parse")


def _single_octet_feed(size: Int) raises:
    """Dribble a whole body frame in one octet at a time; parse must be exact."""
    var wire = AMQPFrameCodec.encode_body_frame(UInt16(1), pattern(size)^)
    var codec = codec_for(size)
    for j in range(len(wire)):
        var one = List[UInt8](capacity=1)
        one.append(wire[j])
        codec.feed_bytes(one^)
        if j < len(wire) - 1:
            var partial = codec.try_parse_frame()
            check(
                not partial.__bool__(),
                "single-octet feed: incomplete frame must not parse",
            )
    var frame = codec.try_parse_frame()
    check(frame.__bool__(), "single-octet feed: frame parses at the end")
    var want = pattern(size)
    var got = frame.value().payload_copy()
    check(eq(want^, got^), "single-octet feed: payload bytes exact")


def _chunked_feed(size: Int, chunk: Int) raises:
    """Feed a whole body frame in fixed-size chunks; parse must be exact."""
    var wire = AMQPFrameCodec.encode_body_frame(UInt16(1), pattern(size)^)
    var codec = codec_for(size)
    var pos = 0
    while pos < len(wire):
        var part = List[UInt8](capacity=chunk)
        var taken = 0
        while taken < chunk and pos < len(wire):
            part.append(wire[pos])
            pos += 1
            taken += 1
        codec.feed_bytes(part^)
        if pos < len(wire):
            var partial = codec.try_parse_frame()
            check(
                not partial.__bool__(),
                "chunked feed: incomplete frame must not parse",
            )
    var frame = codec.try_parse_frame()
    check(frame.__bool__(), "chunked feed: frame parses at the end")
    check(
        frame.value().payload_size() == size,
        "chunked feed: declared size preserved",
    )
    var want = pattern(size)
    var got = frame.value().payload_copy()
    check(eq(want^, got^), "chunked feed: payload bytes exact")


def test_chunked_feeds_exact() raises:
    """Both the 4096 and 16384 body frames survive octet and 3-octet feeding."""
    _single_octet_feed(4096)
    _single_octet_feed(16384)
    _chunked_feed(4096, 3)
    _chunked_feed(16384, 3)


def test_compaction_preserves_bytes() raises:
    """_compact must shift the unparsed backlog without disturbing any byte.

    Three 9-byte frames are fed, two are parsed (cursor 18 of 27, past half),
    then a fourth feed triggers compaction with a frame still outstanding.
    """
    var codec = AMQPFrameCodec(4096)
    var i = 0
    while i < 3:
        var body = List[UInt8](capacity=1)
        body.append(UInt8(160 + i))
        var wire = AMQPFrameCodec.encode_body_frame(UInt16(1), body^)
        codec.feed_bytes(wire^)
        i += 1
    var f0 = codec.try_parse_frame()
    check(f0.__bool__(), "compaction: frame 0 parses")
    check(f0.value().payload[0] == UInt8(160), "compaction: frame 0 byte exact")
    var f1 = codec.try_parse_frame()
    check(f1.__bool__(), "compaction: frame 1 parses")
    check(f1.value().payload[0] == UInt8(161), "compaction: frame 1 byte exact")
    var last = List[UInt8](capacity=1)
    last.append(UInt8(163))
    var wire3 = AMQPFrameCodec.encode_body_frame(UInt16(1), last^)
    codec.feed_bytes(wire3^)
    var f2 = codec.try_parse_frame()
    check(f2.__bool__(), "compaction: frame 2 parses after the shift")
    check(f2.value().payload[0] == UInt8(162), "compaction: frame 2 byte exact")
    var f3 = codec.try_parse_frame()
    check(f3.__bool__(), "compaction: frame 3 parses")
    check(f3.value().payload[0] == UInt8(163), "compaction: frame 3 byte exact")
    check(
        codec.buffered_bytes() == 0,
        "compaction: backlog fully drained",
    )


def test_method_frame_roundtrip() raises:
    """A method frame keeps its octets and its args byte-for-byte."""
    var wire = AMQPFrameCodec.encode_method_frame(
        UInt16(1),
        UInt16(60),
        UInt16(70),
        pattern(20)^,
    )
    var codec = AMQPFrameCodec(4096)
    codec.feed_bytes(wire^)
    var frame = codec.try_parse_frame()
    check(frame.__bool__(), "method frame: parses")
    check(frame.value().frame_type == 1, "method frame: frame_type is 1")
    check(frame.value().channel == 1, "method frame: channel is 1")
    # payload = class_id(2 BE) + method_id(2 BE) + args(20)
    var want = List[UInt8]([UInt8(0), UInt8(60), UInt8(0), UInt8(70)])
    var argpat = pattern(20)
    for i in range(20):
        want.append(argpat[i])
    var got = frame.value().payload_copy()
    check(eq(want^, got^), "method frame: class+method+args bytes exact")


def main() raises:
    test_from_buffer_copy_exact()
    test_snapshot_to_bytes_exact()
    test_payload_into_exact()
    test_body_frame_roundtrip()
    test_chunked_feeds_exact()
    test_compaction_preserves_bytes()
    test_method_frame_roundtrip()
    print("BYTE_PATH_TEST=PASS")
