from std.collections import List
from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.testing import check


def main() raises:
    var chan = UInt16(1)
    var n1 = 90000
    var n2 = 4000
    var b1 = List[UInt8](unsafe_uninit_length=n1)
    var b2 = List[UInt8](unsafe_uninit_length=n2)
    for i in range(n1):
        b1[i] = UInt8(i & 255)
    for i in range(n2):
        b2[i] = UInt8((i + 13) & 255)
    var f1 = AMQPFrameCodec.encode_body_frame(chan, b1^)
    var f2 = AMQPFrameCodec.encode_body_frame(chan, b2^)

    var codec = AMQPFrameCodec(131072)
    codec.feed_bytes(f1^)
    # partial second frame: first 2000 octets of f2
    var part = List[UInt8]()
    for i in range(2000):
        part.append(f2[i])
    codec.feed_bytes(part^)

    # frame 1 parses now; cursor lands past half -> forced compaction on
    # the NEXT feed (remaining=2000 > 0, cursor=90008 > half).
    var fr = codec.try_parse_frame()
    check(fr.__bool__(), "large frame parses")
    var got = fr.value().payload_copy()
    check(len(got) == n1, "frame1 payload length")
    for i in range(n1):
        if got[i] != UInt8(i & 255):
            check(False, "frame1 byte " + String(i) + " corrupted")
            break

    # remaining tail of frame 2: this feed exercises the in-place shift
    var rest = List[UInt8]()
    for i in range(2000, len(f2)):
        rest.append(f2[i])
    codec.feed_bytes(rest^)

    var fr2 = codec.try_parse_frame()
    check(fr2.__bool__(), "compacted frame 2 parses")
    var got2 = fr2.value().payload_copy()
    check(len(got2) == n2, "frame2 payload length after compaction")
    for i in range(n2):
        if got2[i] != UInt8((i + 13) & 255):
            check(
                False,
                "frame2 byte "
                + String(i)
                + " stale after compaction: "
                + String(got2[i])
                + " vs "
                + String(UInt8((i + 13) & 255)),
            )
            break
    print("CODEC_COMPACTION=PASS")
