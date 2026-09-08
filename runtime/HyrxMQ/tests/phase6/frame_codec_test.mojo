# Tests for AMQP frame codec.
#
# Verifies frame encode/decode round-trip for method, header, body, heartbeat.

from std.collections import List
from hyrx.amqp.frame_codec import (
    AMQPFrameCodec,
    AMQPFrame,
    MethodFrame,
    HeaderFrame,
    parse_method_args,
    parse_header_frame_payload,
)


from hyrx.testing import check

def test_encode_decode_method_frame() raises:
    """Method frame encode/decode round-trip."""
    var args = List[UInt8]()
    args.append(0x00)
    args.append(0x0A)

    var encoded = AMQPFrameCodec.encode_method_frame(
        channel=1, class_id=50, method_id=10, args=args^
    )

    # Verify wire format: type=1, channel=1, size=8 (4+4 args), payload, end=0xCE
    check((encoded[0] == 1), "L27")
    check((encoded[1] == 0), "L28")
    check((encoded[2] == 1), "L29")
    # size = 4 (class+method) + 2 (args) = 6... wait, args has 2 bytes
    # Actually: payload = class_id(2) + method_id(2) + args(2) = 6
    check((encoded[3] == 0), "L32")
    check((encoded[4] == 0), "L33")
    check((encoded[5] == 0), "L34")
    check((encoded[6] == 6), "L35")
    # class_id=50 (queue), method_id=10 (declare) — spec indices
    check((encoded[7] == 0), "L37")
    check((encoded[8] == 50), "L38")
    check((encoded[9] == 0), "L39")
    check((encoded[10] == 10), "L40")
    # args bytes
    check((encoded[11] == 0x00), "L42")
    check((encoded[12] == 0x0A), "L43")
    # frame end
    check((encoded[13] == 0xCE), "L45")

    # Now decode
    var codec = AMQPFrameCodec()
    codec.feed_bytes(encoded^)
    var frame = codec.try_parse_frame()
    check((frame.__bool__()), "L51")
    check((frame.value().frame_type == 1), "L52")
    check((frame.value().channel == 1), "L53")

    var method = parse_method_args(frame.value().payload_copy())
    check((method.class_id == 50), "queue.declare class is 50")
    check((method.method_id == 10), "queue.declare method is 10")


def test_encode_decode_header_frame() raises:
    """Content header frame round-trip with a non-empty property section.

    Layout asserted byte-by-byte against amqp0-9-1 §2.3.5.2:
      type(1) channel(2) size(4) | class-id(2) weight(2) body-size(8)
      property-flags(2) property-list(N) | frame-end(1)
    """
    var props = List[UInt8]()
    props.append(0x0A)
    props.append(0x14)
    props.append(0x1E)

    var encoded = AMQPFrameCodec.encode_header_frame(
        channel=1,
        class_id=60,
        body_size=256,
        property_flags=0x0001,
        properties=props^,
    )

    check((encoded[0] == 2), "frame type is HEADER (2)")
    # channel = 1
    check((encoded[1] == 0), "L73")
    check((encoded[2] == 1), "L74")
    # payload size = 2 class + 2 weight + 8 body_size + 2 flags + 3 props = 17
    check((encoded[3] == 0), "L76")
    check((encoded[4] == 0), "L77")
    check((encoded[5] == 0), "L78")
    check((encoded[6] == 17), "payload size includes weight + property flags")
    # class-id at payload[0:2] -> frame[7:9]
    check((encoded[7] == 0), "class hi")
    check((encoded[8] == 60), "class lo")
    # weight at payload[2:4] -> frame[9:11], reserved and MUST be 0
    check((encoded[9] == 0), "weight hi must be 0")
    check((encoded[10] == 0), "weight lo must be 0")
    # body-size at payload[4:12] -> frame[11:19] (256 = 0x100, low byte at 18)
    check((encoded[11] == 0), "body_size byte 0")
    check((encoded[17] == 1), "body_size byte 6 (256 >> 8)")
    check((encoded[18] == 0), "body_size byte 7 (256 & 0xFF)")
    # property-flags at payload[12:14] -> frame[19:21]
    check((encoded[19] == 0), "property flags hi")
    check((encoded[20] == 1), "property flags lo")
    # property-list at payload[14:] -> frame[21:24]
    check((encoded[21] == 0x0A), "property byte 0")
    check((encoded[22] == 0x14), "property byte 1")
    check((encoded[23] == 0x1E), "property byte 2")
    # frame end at last byte
    check((len(encoded) == 25), "total frame length")
    check((encoded[len(encoded) - 1] == 0xCE), "L81")

    # Decode
    var codec = AMQPFrameCodec()
    codec.feed_bytes(encoded^)
    var frame = codec.try_parse_frame()
    check((frame.__bool__()), "L87")
    check((frame.value().frame_type == 2), "L88")

    var header = parse_header_frame_payload(frame.value().payload_copy())
    check((header.class_id == 60), "L91")
    check((header.weight == 0), "parsed weight is 0")
    check((header.body_size == 256), "L92")
    check((header.property_flags == 1), "parsed property flags")
    check((len(header.properties) == 3), "property list length preserved")
    check((header.properties[0] == 0x0A), "property 0 round-trip")
    check((header.properties[2] == 0x1E), "property 2 round-trip")


def test_header_frame_offsets_from_raw_bytes() raises:
    """Parsing reads weight/body-size/flags at the spec offsets, not earlier.

    Every field uses a distinct byte pattern so any off-by-two read is caught.
    """
    var payload = List[UInt8]()
    # class-id = 0x003C (60)
    payload.append(0x00)
    payload.append(0x3C)
    # weight = 0x0000 (MUST be 0)
    payload.append(0x00)
    payload.append(0x00)
    # body-size = 0x0102030405060708
    payload.append(0x01)
    payload.append(0x02)
    payload.append(0x03)
    payload.append(0x04)
    payload.append(0x05)
    payload.append(0x06)
    payload.append(0x07)
    payload.append(0x08)
    # property-flags = 0x000F
    payload.append(0x00)
    payload.append(0x0F)
    # property-list
    payload.append(0xAA)
    payload.append(0xBB)

    var header = parse_header_frame_payload(payload^)
    check((header.class_id == 60), "class-id from payload[0:2]")
    check((header.weight == 0), "weight from payload[2:4]")
    check(
        (header.body_size == 0x0102030405060708),
        "body-size must come from payload[4:12]",
    )
    check(
        (header.property_flags == 0x000F),
        "property-flags must come from payload[12:14]",
    )
    check((len(header.properties) == 2), "property-list starts at payload[14:]")
    check((header.properties[0] == 0xAA), "property byte 0")
    check((header.properties[1] == 0xBB), "property byte 1")


def test_header_frame_nonzero_weight_raises() raises:
    """§2.3.5.2: the weight field MUST be zero — a non-zero weight is rejected."""
    var payload = List[UInt8]()
    payload.append(0x00)
    payload.append(0x3C)  # class-id 60
    payload.append(0x00)
    payload.append(0x01)  # weight = 1 (illegal)
    for _ in range(8):
        payload.append(0)
    payload.append(0x00)
    payload.append(0x00)

    var caught = False
    try:
        _ = parse_header_frame_payload(payload^)
    except:
        caught = True
    check(caught, "non-zero weight must raise")

    # A payload shorter than class+weight+body-size+flags is also rejected.
    var short = List[UInt8]()
    for _ in range(13):
        short.append(0)
    var caught_short = False
    try:
        _ = parse_header_frame_payload(short^)
    except:
        caught_short = True
    check(caught_short, "13-byte payload is below the 14-byte minimum")


def test_encode_decode_body_frame() raises:
    """Body frame encode/decode round-trip."""
    var body = List[UInt8]()
    body.append(0xDE)
    body.append(0xAD)
    body.append(0xBE)
    body.append(0xEF)

    var encoded = AMQPFrameCodec.encode_body_frame(channel=1, body=body^)

    check((encoded[0] == 3), "L105")
    check((encoded[1] == 0), "L106")
    check((encoded[2] == 1), "L107")
    check((encoded[3] == 0), "L108")
    check((encoded[4] == 0), "L109")
    check((encoded[5] == 0), "L110")
    check((encoded[6] == 4), "L111")
    check((encoded[7] == 0xDE), "L112")
    check((encoded[8] == 0xAD), "L113")
    check((encoded[9] == 0xBE), "L114")
    check((encoded[10] == 0xEF), "L115")
    check((encoded[11] == 0xCE), "L116")

    # Decode
    var codec = AMQPFrameCodec()
    codec.feed_bytes(encoded^)
    var frame = codec.try_parse_frame()
    check((frame.__bool__()), "L122")
    check((frame.value().frame_type == 3), "L123")
    check((frame.value().payload_size() == 4), "L124")
    check((frame.value().payload[0] == 0xDE), "L125")
    check((frame.value().payload[3] == 0xEF), "L126")


def test_encode_decode_heartbeat() raises:
    """Heartbeat frame encode/decode round-trip."""
    var encoded = AMQPFrameCodec.encode_heartbeat(channel=0)

    check((encoded[0] == 8), "L133")
    check((encoded[1] == 0), "L134")
    check((encoded[2] == 0), "L135")
    check((encoded[3] == 0), "L136")
    check((encoded[4] == 0), "L137")
    check((encoded[5] == 0), "L138")
    check((encoded[6] == 0), "L139")
    check((encoded[7] == 0xCE), "L140")

    # Decode
    var codec = AMQPFrameCodec()
    codec.feed_bytes(encoded^)
    var frame = codec.try_parse_frame()
    check((frame.__bool__()), "L146")
    check((frame.value().frame_type == 8), "L147")
    check((frame.value().channel == 0), "L148")
    check((frame.value().payload_size() == 0), "L149")


def test_incomplete_frame_returns_none() raises:
    """Partial frame data returns None, not a frame."""
    var partial = List[UInt8]()
    partial.append(1)   # type
    partial.append(0)   # channel high
    partial.append(1)   # channel low
    # Missing size bytes and payload

    var codec = AMQPFrameCodec()
    codec.feed_bytes(partial^)
    var frame = codec.try_parse_frame()
    check(not (frame.__bool__()), "L163")


def test_multiple_frames_in_buffer() raises:
    """Codec handles multiple frames concatenated in buffer."""
    var h1 = AMQPFrameCodec.encode_heartbeat(channel=0)
    var h2 = AMQPFrameCodec.encode_heartbeat(channel=0)

    var codec = AMQPFrameCodec()
    codec.feed_bytes(h1^)
    codec.feed_bytes(h2^)

    var f1 = codec.try_parse_frame()
    check((f1.__bool__()), "L176")
    check((f1.value().frame_type == 8), "L177")

    var f2 = codec.try_parse_frame()
    check((f2.__bool__()), "L180")
    check((f2.value().frame_type == 8), "L181")

    # Buffer should be empty now
    var f3 = codec.try_parse_frame()
    check(not (f3.__bool__()), "L185")


def test_frame_end_byte_mismatch_raises() raises:
    """Corrupted frame end byte raises error."""
    var bad = List[UInt8]()
    bad.append(1)   # type
    bad.append(0)   # channel
    bad.append(0)
    bad.append(0)   # size = 0
    bad.append(0)
    bad.append(0)
    bad.append(0)
    bad.append(0xFF)  # WRONG end byte

    var codec = AMQPFrameCodec()
    codec.feed_bytes(bad^)
    var caught = False
    try:
        _ = codec.try_parse_frame()
    except:
        caught = True
    check((caught), "L207")


def main() raises:
    test_encode_decode_method_frame()
    test_encode_decode_header_frame()
    test_header_frame_offsets_from_raw_bytes()
    test_header_frame_nonzero_weight_raises()
    test_encode_decode_body_frame()
    test_encode_decode_heartbeat()
    test_incomplete_frame_returns_none()
    test_multiple_frames_in_buffer()
    test_frame_end_byte_mismatch_raises()
    print("PHASE6_FRAME_CODEC_TEST=PASS")
