# P4 — A/B benchmark: codec performance with cursor (P2) vs old rebuild.
#
# Measures the isolated codec path: feed + parse + encode per payload size.
# The cursor-based try_parse_frame eliminates the O(n) remaining rebuild.
#
# Run: pixi run mojo run -I src -I vendor/flare benchmarks/p4_codec_ab.mojo

from std.time import perf_counter_ns
from std.collections import List

from hyrx.amqp.frame_codec import AMQPFrameCodec, AMQPFrame
from hyrx.core.feature_flags import contiguous_batch_enabled

from std.collections import Dict


def _pad(var s: String, width: Int) -> String:
    while s.byte_length() < width:
        s = s + " "
    return s


def _r(x: Float64, digits: Int) -> String:
    var m = 1.0
    for _ in range(digits):
        m *= 10.0
    return String(Float64(Int(x * m)) / m)


def build_body_frame(channel: UInt16, payload_size: Int) -> List[UInt8]:
    """Build a wire-format AMQP BODY frame."""
    var result = List[UInt8](capacity=payload_size + 8)
    result.append(3)  # type = BODY
    result.append(UInt8((channel >> 8) & 0xFF))
    result.append(UInt8(channel & 0xFF))
    result.append(UInt8((payload_size >> 24) & 0xFF))
    result.append(UInt8((payload_size >> 16) & 0xFF))
    result.append(UInt8((payload_size >> 8) & 0xFF))
    result.append(UInt8(payload_size & 0xFF))
    for i in range(payload_size):
        result.append(UInt8(i & 0xFF))
    result.append(0xCE)
    return result^


def build_two_body_frames(channel: UInt16, size1: Int, size2: Int) -> List[UInt8]:
    """Build two concatenated BODY frames."""
    var f1 = build_body_frame(channel, size1)
    var f2 = build_body_frame(channel, size2)
    var combined = List[UInt8](capacity=len(f1) + len(f2))
    for i in range(len(f1)):
        combined.append(f1[i])
    for i in range(len(f2)):
        combined.append(f2[i])
    return combined^


def bench_codec_single_frame(payload_size: Int, reps: Int) raises -> Float64:
    """Measure: feed + parse + payload_copy for single-frame payload. Returns ns/op."""
    var wire = build_body_frame(UInt16(1), payload_size)
    var times = List[Float64]()

    for _ in range(reps):
        var codec = AMQPFrameCodec()
        var t0 = perf_counter_ns()
        codec.feed_bytes(wire.copy())
        var frame = codec.try_parse_frame()
        if frame.__bool__():
            _ = frame.value().payload_copy()
        var t1 = perf_counter_ns()
        times.append(Float64(t1 - t0))

    # Return median
    var n = len(times)
    for i in range(1, n):
        var key = times[i]
        var j = i - 1
        while j >= 0 and times[j] > key:
            times[j + 1] = times[j]
            j -= 1
        times[j + 1] = key
    return times[n // 2]


def bench_codec_two_frames(payload_size: Int, reps: Int) raises -> Float64:
    """Measure: feed + parse two frames (the O(n)-rebuild path). Returns ns/op."""
    var half = payload_size // 2
    var wire = build_two_body_frames(UInt16(1), half, payload_size - half)
    var times = List[Float64]()

    for _ in range(reps):
        var codec = AMQPFrameCodec()
        var t0 = perf_counter_ns()
        codec.feed_bytes(wire.copy())
        var f1 = codec.try_parse_frame()
        var f2 = codec.try_parse_frame()
        if f1.__bool__():
            _ = f1.value().payload_copy()
        if f2.__bool__():
            _ = f2.value().payload_copy()
        var t1 = perf_counter_ns()
        times.append(Float64(t1 - t0))

    var n = len(times)
    for i in range(1, n):
        var key = times[i]
        var j = i - 1
        while j >= 0 and times[j] > key:
            times[j + 1] = times[j]
            j -= 1
        times[j + 1] = key
    return times[n // 2]


def bench_encode_body(payload_size: Int, reps: Int) raises -> Float64:
    """Measure: encode_body_frame. Returns ns/op."""
    var body = List[UInt8](capacity=payload_size)
    for i in range(payload_size):
        body.append(UInt8(i & 0xFF))
    var times = List[Float64]()

    for _ in range(reps):
        var t0 = perf_counter_ns()
        _ = AMQPFrameCodec.encode_body_frame(UInt16(1), body.copy())
        var t1 = perf_counter_ns()
        times.append(Float64(t1 - t0))

    var n = len(times)
    for i in range(1, n):
        var key = times[i]
        var j = i - 1
        while j >= 0 and times[j] > key:
            times[j + 1] = times[j]
            j -= 1
        times[j + 1] = key
    return times[n // 2]


def main() raises:
    print("P4 — Codec A/B Benchmark (cursor vs old rebuild)")
    print("contiguous_batch_enabled = " + String(contiguous_batch_enabled()))
    print("")
    print("=" * 90)

    var sizes = List[Int]()
    sizes.append(64)
    sizes.append(256)
    sizes.append(1024)
    sizes.append(4096)
    sizes.append(16384)
    sizes.append(65536)

    var reps = 1000

    print(_pad("payload", 10)
          + _pad("single(ns)", 14)
          + _pad("2frame(ns)", 14)
          + _pad("encode(ns)", 14)
          + _pad("single MB/s", 14)
          + _pad("2frame MB/s", 14))
    print("-" * 90)

    for i in range(len(sizes)):
        var sz = sizes[i]
        var t1 = bench_codec_single_frame(sz, reps)
        var t2 = bench_codec_two_frames(sz, reps)
        var te = bench_encode_body(sz, reps)
        var mbps1 = 0.0
        if t1 > 0:
            mbps1 = Float64(sz) / t1 * 1000.0
        var mbps2 = 0.0
        if t2 > 0:
            mbps2 = Float64(sz) / t2 * 1000.0
        print(
            _pad(String(sz), 10)
            + _pad(String(Int(t1)), 14)
            + _pad(String(Int(t2)), 14)
            + _pad(String(Int(te)), 14)
            + _pad(_r(mbps1, 1), 14)
            + _pad(_r(mbps2, 1), 14)
        )

    print("=" * 90)
    print("P4 BENCHMARK COMPLETE")
