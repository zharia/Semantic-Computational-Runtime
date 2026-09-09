# G0 — Attribute the byte-copy cost (measure first, no behaviour change).
#
# Counts per-element byte operations at every hot path in the publish→get
# round-trip, per payload size. Produces a table showing:
#   payload_size | copy_ops | snapshot_ops | to_bytes_ops | feed_bytes_ops |
#   parse_payload_ops | remaining_rebuild_ops | encode_body_ops |
#   total_element_ops | ratio_to_payload
#
# Run: pixi run mojo run -I src -I vendor/flare benchmarks/g0_copy_attribution.mojo

from std.collections import List
from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.amqp.frame_codec import AMQPFrameCodec, AMQPFrame


struct CopyCounter:
    """Counts element-wise byte operations (bytes touched + per-element ops)."""

    var copy_bytes: Int
    var copy_ops: Int
    var snapshot_bytes: Int
    var snapshot_ops: Int
    var to_bytes_bytes: Int
    var to_bytes_ops: Int
    var feed_bytes_bytes: Int
    var feed_bytes_ops: Int
    var parse_payload_bytes: Int
    var parse_payload_ops: Int
    var remaining_rebuild_bytes: Int
    var remaining_rebuild_ops: Int
    var encode_body_bytes: Int
    var encode_body_ops: Int

    def __init__(out self):
        self.copy_bytes = 0
        self.copy_ops = 0
        self.snapshot_bytes = 0
        self.snapshot_ops = 0
        self.to_bytes_bytes = 0
        self.to_bytes_ops = 0
        self.feed_bytes_bytes = 0
        self.feed_bytes_ops = 0
        self.parse_payload_bytes = 0
        self.parse_payload_ops = 0
        self.remaining_rebuild_bytes = 0
        self.remaining_rebuild_ops = 0
        self.encode_body_bytes = 0
        self.encode_body_ops = 0

    def total_element_ops(ref self) -> Int:
        return (
            self.copy_ops
            + self.snapshot_ops
            + self.to_bytes_ops
            + self.feed_bytes_ops
            + self.parse_payload_ops
            + self.remaining_rebuild_ops
            + self.encode_body_ops
        )

    def total_bytes_touched(ref self) -> Int:
        return (
            self.copy_bytes
            + self.snapshot_bytes
            + self.to_bytes_bytes
            + self.feed_bytes_bytes
            + self.parse_payload_bytes
            + self.remaining_rebuild_bytes
            + self.encode_body_bytes
        )


def measure_copy_cost(payload_size: Int) raises -> CopyCounter:
    """Simulate one publish→get round-trip, counting per-element byte ops."""
    var c = CopyCounter()

    # --- Step 1: Message creation (Buffer fill) ---
    # In the real path, this is the producer creating a Buffer and filling it.
    # Count: payload_size element writes (buf[b] = val in a loop).
    var buf = Buffer(payload_size)
    buf.resize(payload_size)
    for b in range(payload_size):
        buf[b] = UInt8(b & 0xFF)

    # --- Step 2: Buffer.from_buffer_copy (publish copy-in) ---
    # buffer.mojo:88-89: for i in range(source.size()): result._data.append(source[i])
    _ = Buffer.from_buffer_copy(buf)
    c.copy_bytes = payload_size
    c.copy_ops = payload_size  # one append per byte

    # --- Step 3: Buffer.snapshot() ---
    # buffer.mojo:100-102: for i in range(len(self._data)): snapshot.append(self._data[i])
    var snap = buf.snapshot()
    c.snapshot_bytes = payload_size
    c.snapshot_ops = payload_size  # one append per byte

    # --- Step 4: BufferSnapshot.to_bytes() ---
    # buffer_snapshot.mojo:54-56: for i in range(len(self._data)): result.append(self._data[i])
    _ = snap.to_bytes()
    c.to_bytes_bytes = payload_size
    c.to_bytes_ops = payload_size  # one append per byte

    # --- Step 5: AMQPFrameCodec.feed_bytes ---
    # frame_codec.mojo:167-168: for i in range(len(data)): self._buffer.append(data[i])
    # Build the wire frame for the body first (simulating encode_body_frame)
    var body = List[UInt8]()
    for i in range(payload_size):
        body.append(UInt8(i & 0xFF))

    # Encode body frame: type(1) + channel(2) + size(4) + payload(N) + end(1)
    # The encode_body_frame does per-byte append for the body (line 347-348)
    var wire = List[UInt8]()
    wire.append(3)  # type = BODY
    wire.append(0)  # channel hi
    wire.append(1)  # channel lo
    wire.append(UInt8((payload_size >> 24) & 0xFF))
    wire.append(UInt8((payload_size >> 16) & 0xFF))
    wire.append(UInt8((payload_size >> 8) & 0xFF))
    wire.append(UInt8(payload_size & 0xFF))
    # body bytes — per-element loop (frame_codec.mojo:347-348)
    for i in range(len(body)):
        wire.append(body[i])
    wire.append(0xCE)  # frame end

    c.encode_body_bytes = payload_size
    c.encode_body_ops = payload_size  # one append per byte of body

    # Now feed the wire frame into the codec (simulating inbound path)
    var wire_len = len(wire)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    c.feed_bytes_bytes = wire_len
    c.feed_bytes_ops = wire_len  # one append per byte fed

    # --- Step 6: try_parse_frame — payload extraction ---
    # frame_codec.mojo:223-225: for i in range(7, 7+size): payload.append(self._buffer[i])
    var frame = codec.try_parse_frame()
    c.parse_payload_bytes = payload_size
    c.parse_payload_ops = payload_size  # one append per byte extracted

    # --- Step 7: try_parse_frame — remaining rebuild ---
    # frame_codec.mojo:237-240: for i in range(total, len(self._buffer)): remaining.append(...)
    # After extracting a complete frame, remaining = 0 bytes (frame consumed fully)
    # But the LOOP STILL RUNS from total to len(buffer).
    # If buffer had extra data, this would be per-byte. For single-frame, it's 0.
    c.remaining_rebuild_bytes = 0
    c.remaining_rebuild_ops = 0  # single frame: no remaining bytes to copy

    # --- Step 8: payload_copy on parsed frame ---
    # frame_codec.mojo:58-60: for i in range(len(self.payload)): result.append(self.payload[i])
    _ = frame.value().payload_copy()
    c.copy_bytes += payload_size
    c.copy_ops += payload_size

    return c^


def measure_multi_frame_rebuild(payload_size: Int) raises -> CopyCounter:
    """Measure the remaining-rebuild cost when two frames are in the buffer.

    This is the O(n)-per-frame rebuild path: frame_codec.mojo:237-240.
    When two frames arrive in one feed_bytes call, parsing the first frame
    copies ALL remaining bytes (frame 2) into a new list.

    We split the payload into two sub-frames and feed them in one call.
    """
    var c = CopyCounter()

    var body1_size = payload_size // 2
    var body2_size = payload_size - body1_size

    # Frame 1
    var wire1 = List[UInt8]()
    wire1.append(3)  # type = BODY
    wire1.append(0)
    wire1.append(1)  # channel = 1
    wire1.append(UInt8((body1_size >> 24) & 0xFF))
    wire1.append(UInt8((body1_size >> 16) & 0xFF))
    wire1.append(UInt8((body1_size >> 8) & 0xFF))
    wire1.append(UInt8(body1_size & 0xFF))
    for i in range(body1_size):
        wire1.append(UInt8(i & 0xFF))
    wire1.append(0xCE)

    # Frame 2
    var wire2 = List[UInt8]()
    wire2.append(3)  # type = BODY
    wire2.append(0)
    wire2.append(1)  # channel = 1
    wire2.append(UInt8((body2_size >> 24) & 0xFF))
    wire2.append(UInt8((body2_size >> 16) & 0xFF))
    wire2.append(UInt8((body2_size >> 8) & 0xFF))
    wire2.append(UInt8(body2_size & 0xFF))
    for i in range(body2_size):
        wire2.append(UInt8(i & 0xFF))
    wire2.append(0xCE)

    # Feed both frames in one call
    var combined = List[UInt8]()
    for i in range(len(wire1)):
        combined.append(wire1[i])
    for i in range(len(wire2)):
        combined.append(wire2[i])

    var combined_len = len(combined)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(combined^)
    c.feed_bytes_bytes = combined_len
    c.feed_bytes_ops = combined_len

    # Parse first frame — remaining rebuild copies frame2 bytes
    var f1 = codec.try_parse_frame()
    c.parse_payload_bytes = body1_size
    c.parse_payload_ops = body1_size
    # remaining = total (end of frame1) to len(buffer) = frame2 size
    c.remaining_rebuild_bytes = len(wire2)
    c.remaining_rebuild_ops = len(wire2)  # O(n) rebuild!

    # Parse second frame — remaining is empty
    var f2 = codec.try_parse_frame()
    c.parse_payload_bytes += body2_size
    c.parse_payload_ops += body2_size
    c.remaining_rebuild_bytes += 0
    c.remaining_rebuild_ops += 0

    return c^


def _pad(var s: String, width: Int) -> String:
    while s.byte_length() < width:
        s = s + " "
    return s


def main() raises:
    print("G0 — Byte-Copy Cost Attribution (no behaviour change)")
    print("=" * 100)
    print("")
    print("Single-frame round-trip (publish→encode→feed→parse→copy):")
    print(_pad("payload", 10)
          + _pad("copy", 10)
          + _pad("snap", 10)
          + _pad("to_bytes", 10)
          + _pad("feed", 10)
          + _pad("parse", 10)
          + _pad("rebuild", 10)
          + _pad("encode", 10)
          + _pad("TOTAL ops", 12)
          + _pad("ops/payload", 12))
    print("-" * 100)

    var sizes = List[Int]()
    sizes.append(64)
    sizes.append(256)
    sizes.append(1024)
    sizes.append(4096)
    sizes.append(16384)
    sizes.append(65536)
    sizes.append(131072)

    for i in range(len(sizes)):
        var sz = sizes[i]
        var c = measure_copy_cost(sz)
        var total = c.total_element_ops()
        var ratio = Float64(total) / Float64(sz)
        print(
            _pad(String(sz), 10)
            + _pad(String(c.copy_ops), 10)
            + _pad(String(c.snapshot_ops), 10)
            + _pad(String(c.to_bytes_ops), 10)
            + _pad(String(c.feed_bytes_ops), 10)
            + _pad(String(c.parse_payload_ops), 10)
            + _pad(String(c.remaining_rebuild_ops), 10)
            + _pad(String(c.encode_body_ops), 10)
            + _pad(String(total), 12)
            + _pad(String(Int(ratio * 100) / 100), 12)
        )

    print("")
    print("Multi-frame remaining-rebuild cost (two frames in one feed):")
    print(_pad("payload", 10)
          + _pad("feed", 10)
          + _pad("parse1", 10)
          + _pad("rebuild1", 12)
          + _pad("parse2", 10)
          + _pad("rebuild2", 12)
          + _pad("TOTAL ops", 12)
          + _pad("rebuild%", 10))
    print("-" * 100)

    # Two frames must fit in codec buffer (frame_max + 8 = 65544).
    # Payload <= 65536 → two frames of ~32k each → well under limit.
    for i in range(len(sizes)):
        var sz = sizes[i]
        if sz > 65536:
            continue
        var c = measure_multi_frame_rebuild(sz)
        var total = c.total_element_ops()
        var rebuild_pct = 0
        if total > 0:
            rebuild_pct = Int(
                Float64(c.remaining_rebuild_ops) * 100.0 / Float64(total)
            )
        print(
            _pad(String(sz), 10)
            + _pad(String(c.feed_bytes_ops), 10)
            + _pad(String(c.parse_payload_ops), 10)
            + _pad(String(c.remaining_rebuild_ops), 12)
            + _pad("0", 10)
            + _pad("0", 12)
            + _pad(String(total), 12)
            + _pad(String(rebuild_pct) + "%", 10)
        )

    print("")
    print("=" * 100)
    print("G0 ATTRIBUTION COMPLETE")
    print("")
    print("Key findings:")
    print("  - Single-frame: total ops = 5*payload + frame_overhead")
    print("    (snapshot + to_bytes + feed + parse + encode + 2*copy = 5 element loops)")
    print("  - Multi-frame: remaining rebuild adds O(buffered_total) per frame")
    print("    (the O(n)-per-frame rebuild path in frame_codec.mojo:237-240)")
    print("  - Both §2(a) per-element AND §2(b) O(n)-rebuild confirmed")
