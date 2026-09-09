from std.collections import List
from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.testing import check


def main() raises:
    var sizes = List[Int]()
    sizes.append(0)
    sizes.append(1)
    sizes.append(2)
    sizes.append(3)
    sizes.append(7)
    sizes.append(8)
    sizes.append(255)
    sizes.append(262144 - 3)
    for i in range(131072):
        sizes.append(0)
    sizes.clear()
    for sz in List[Int]([0, 1, 2, 3, 7, 8, 255, 131064]):
        sizes.append(sz)
    var chan = UInt16(7)
    for s in range(len(sizes)):
        var n = sizes[s]
        var body = List[UInt8](unsafe_uninit_length=n)
        for i in range(n):
            body[i] = UInt8((i + s) & 255)
        var a = AMQPFrameCodec.encode_body_frame(chan, body.copy())
        var b = List[UInt8]()
        AMQPFrameCodec.append_body_frame(
            b, chan, body.unsafe_ptr(), n
        )
        if len(a) != len(b):
            check(False, "append vs encode length mismatch at size " + String(n))
        for i in range(len(a)):
            if a[i] != b[i]:
                check(
                    False,
                    "append vs encode byte "
                    + String(i)
                    + " mismatch at size "
                    + String(n)
                    + ": "
                    + String(a[i])
                    + " vs "
                    + String(b[i]),
                )
    print("APPEND_BODY_FRAME_IDENTITY=PASS")
