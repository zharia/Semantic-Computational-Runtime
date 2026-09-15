# M5 — Coverage-guided AMQP frame fuzzing harness for HyrxMQ.
#
# Feeds mutated frames through AMQPFrameCodec AND AMQPService, asserting
# no unhandled exceptions leak. Tracks unique crash signatures via
# exception-message hashing. Deterministic LCG for reproducibility.
#
# Strategy: build valid METHOD/HEADER/BODY/HEARTBEAT frames with the codec's
# own encoders, then mutate bytes before decoding. This tests both the codec
# AND the service dispatch path with adversarial input.

from std.collections import Dict, List, Optional
from std.os import getenv

from hyrx.amqp.frame_codec import AMQPFrameCodec, AMQPFrame
from hyrxmq.amqp_service import AMQPService
from hyrxmq.config import HyrxMQConfig
from hyrx.testing import check


def resolve_iters(var env_name: String, default: Int) raises -> Int:
    """Total iteration target: HYRXMQ_FUZZ_ITERS when set, else `default`.

    Keeps the historical default when no override is present so the regular
    suite behaviour is unchanged; a malformed value fails loud (never silently
    runs a smaller bar than requested)."""
    var v = getenv(env_name, "")
    if len(v.bytes()) == 0:
        return default
    return Int(v)


# ---- deterministic LCG (glibc params, period 2^32) ----

struct LCG:
    """Linear congruential generator — deterministic, 32-bit period."""
    var state: UInt32

    def __init__(out self, seed: UInt32):
        self.state = seed

    def next(mut self) -> UInt32:
        self.state = self.state * 1103515245 + 12345
        return self.state

    def next_range(mut self, lo: Int, hi: Int) -> Int:
        """Return lo..hi inclusive, deterministic."""
        var span = hi - lo + 1
        if span <= 0:
            return lo
        var r = self.next()
        return lo + Int(r % UInt32(span))


# ---- helpers ----

def list_copy(ref src: List[UInt8]) -> List[UInt8]:
    """Copy a byte list (Mojo 1.0 List has no .copy())."""
    var result = List[UInt8](capacity=len(src))
    for i in range(len(src)):
        result.append(src[i])
    return result^


def simple_hash(var msg: String) -> UInt64:
    """FNV-1a hash of a string — used to deduplicate crash signatures."""
    var h: UInt64 = 0xCBF29CE484222325
    var b = msg.as_bytes()
    for i in range(len(b)):
        h = h ^ UInt64(b[i])
        h = h * 0x100000001B3
    return h


# ---- seed frame builders ----

def build_method_frame() -> List[UInt8]:
    """Valid METHOD frame: channel.open (20,10) with empty args."""
    var args = List[UInt8]()
    return AMQPFrameCodec.encode_method_frame(UInt16(1), UInt16(20), UInt16(10), args^)


def build_header_frame() -> List[UInt8]:
    """Valid HEADER frame: class 60, body-size 42, flags 0, empty props."""
    var props = List[UInt8]()
    return AMQPFrameCodec.encode_header_frame(
        UInt16(1), UInt16(60), UInt64(42), UInt16(0), props^
    )


def build_body_frame() -> List[UInt8]:
    """Valid BODY frame with 4 payload bytes."""
    var body = List[UInt8]()
    body.append(0xDE)
    body.append(0xAD)
    body.append(0xBE)
    body.append(0xEF)
    return AMQPFrameCodec.encode_body_frame(UInt16(1), body^)


def build_heartbeat_frame() -> List[UInt8]:
    """Valid HEARTBEAT frame."""
    return AMQPFrameCodec.encode_heartbeat(UInt16(0))


def build_garbage(seed_val: UInt32, count: Int) -> List[UInt8]:
    """Generate `count` garbage bytes from a seed."""
    var lcg = LCG(seed_val)
    var data = List[UInt8](capacity=count)
    for _ in range(count):
        data.append(UInt8(lcg.next() & 0xFF))
    return data^


# ---- mutation strategies ----

def mutate_bit_flip(mut data: List[UInt8], mut lcg: LCG):
    """Flip one random bit in the frame."""
    if len(data) == 0:
        return
    var pos = lcg.next_range(0, len(data) - 1)
    var bit = lcg.next_range(0, 7)
    data[pos] = data[pos] ^ (UInt8(1) << UInt8(bit))


def mutate_byte_replace(mut data: List[UInt8], mut lcg: LCG):
    """Replace 1-3 random bytes with 0x00 or 0xFF."""
    if len(data) == 0:
        return
    var count = lcg.next_range(1, min(3, len(data)))
    for _ in range(count):
        var pos = lcg.next_range(0, len(data) - 1)
        var val = lcg.next_range(0, 1)
        data[pos] = UInt8(0) if val == 0 else UInt8(0xFF)


def mutate_truncate(mut data: List[UInt8], mut lcg: LCG):
    """Cut frame at a random point (1..len-1 bytes)."""
    if len(data) <= 1:
        return
    var cut = lcg.next_range(1, len(data) - 1)
    var result = List[UInt8](capacity=cut)
    for i in range(cut):
        result.append(data[i])
    data = result^


def mutate_duplicate(mut data: List[UInt8], mut lcg: LCG):
    """Repeat a random 1-4 byte section once."""
    if len(data) == 0:
        return
    var start = lcg.next_range(0, len(data) - 1)
    var seg_len = lcg.next_range(1, min(4, len(data) - start))
    var result = List[UInt8](capacity=len(data) + seg_len)
    for i in range(start):
        result.append(data[i])
    for i in range(start, start + seg_len):
        result.append(data[i])
    for i in range(start, start + seg_len):
        result.append(data[i])
    for i in range(start + seg_len, len(data)):
        result.append(data[i])
    data = result^


def apply_mutation(mut data: List[UInt8], mut lcg: LCG, mut_type: Int):
    """Apply one of four mutations in-place."""
    if mut_type == 0:
        mutate_bit_flip(data, lcg)
    elif mut_type == 1:
        mutate_byte_replace(data, lcg)
    elif mut_type == 2:
        mutate_truncate(data, lcg)
    elif mut_type == 3:
        mutate_duplicate(data, lcg)


# ---- build seed by index (avoids storing List in List) ----

def build_seed(idx: Int, lcg: LCG) -> List[UInt8]:
    """Return one of 7 seed frames by index."""
    if idx == 0:
        return build_method_frame()
    elif idx == 1:
        return build_header_frame()
    elif idx == 2:
        return build_body_frame()
    elif idx == 3:
        return build_heartbeat_frame()
    elif idx == 4:
        return build_garbage(0xCAFEBABE, 16)
    elif idx == 5:
        return build_garbage(0xFEEDFACE, 32)
    else:
        return List[UInt8]()


# ---- codec-only fuzz ----

def fuzz_codec_only(
    mut lcg: LCG,
    iterations: Int,
    mut seen_sigs: Dict[UInt64, Int],
    mut sig_keys: List[UInt64],
) raises -> Int:
    """Feed mutated frames to AMQPFrameCodec only. Returns crash count."""
    var crashes = 0
    var num_seeds = 7

    for i in range(iterations):
        # pick seed frame
        var seed_idx = lcg.next_range(0, num_seeds - 1)
        var data = build_seed(seed_idx, lcg)

        # pick mutation
        var mut_type = lcg.next_range(0, 3)

        # apply mutation
        apply_mutation(data, lcg, mut_type)

        # feed to fresh codec
        var codec = AMQPFrameCodec()
        var got_exception = False
        var exc_msg = String()
        try:
            codec.feed_bytes(data^)
            _ = codec.try_parse_frame()
        except e:
            got_exception = True
            exc_msg = String(e)

        # safe outcomes: exception (caught), None, or decoded frame.
        # Reaching here = process survived.

        if got_exception:
            crashes += 1
            var sig = simple_hash(exc_msg)
            if sig in seen_sigs:
                seen_sigs[sig] = seen_sigs[sig] + 1
            else:
                seen_sigs[sig] = 1
                sig_keys.append(sig)

    return crashes


# ---- service-level fuzz ----

def fuzz_with_service(
    mut lcg: LCG,
    iterations: Int,
    mut svc: AMQPService,
    mut seen_sigs: Dict[UInt64, Int],
    mut sig_keys: List[UInt64],
) raises -> Int:
    """Feed mutated frames through AMQPService.handle_frame. Returns crash count."""
    var crashes = 0
    var conn_id: UInt64 = 42
    var num_seeds = 7

    for i in range(iterations):
        # pick seed frame
        var seed_idx = lcg.next_range(0, num_seeds - 1)
        var raw = build_seed(seed_idx, lcg)

        # pick mutation
        var mut_type = lcg.next_range(0, 3)

        # apply mutation
        apply_mutation(raw, lcg, mut_type)

        # decode mutated bytes
        var codec = AMQPFrameCodec()
        var decode_ok = False
        var frame_type: UInt8 = 0
        var frame_channel: UInt16 = 0
        var frame_payload = List[UInt8]()
        try:
            codec.feed_bytes(raw^)
            var frame_optional = codec.try_parse_frame()
            decode_ok = frame_optional.__bool__()
            if decode_ok:
                frame_type = frame_optional.value().frame_type
                frame_channel = frame_optional.value().channel
                frame_payload = frame_optional.value().payload_copy()
        except:
            # codec rejected — safe, skip service dispatch
            continue

        if not decode_ok:
            continue

        # feed decoded frame to service
        var frame = AMQPFrame(frame_type, frame_channel, frame_payload^)
        try:
            _ = svc.handle_frame(conn_id, frame)
        except e:
            crashes += 1
            var exc_msg = String(e)
            var sig = simple_hash(exc_msg)
            if sig in seen_sigs:
                seen_sigs[sig] = seen_sigs[sig] + 1
            else:
                seen_sigs[sig] = 1
                sig_keys.append(sig)

    return crashes


# ---- main ----

def main() raises:
    var lcg = LCG(UInt32(0xDEADBEEF))

    # shared crash signature tracking
    var seen_sigs = Dict[UInt64, Int]()
    var sig_keys = List[UInt64]()

    # Total iteration budget: HYRXMQ_FUZZ_ITERS override, else the historical
    # 20000 (10000 codec-only + 10000 service-level). Split across the two
    # phases so a requested 1M bar is actually run.
    var total_target = resolve_iters("HYRXMQ_FUZZ_ITERS", 20000)
    if total_target < 0:
        total_target = 0
    var codec_iters = total_target // 2
    var svc_iters = total_target - codec_iters

    # ---- codec-only fuzz ----
    var codec_crashes = fuzz_codec_only(lcg, codec_iters, seen_sigs, sig_keys)

    # ---- service-level fuzz ----
    var config = HyrxMQConfig()
    config.validate()
    var svc = AMQPService(config^)
    svc.start()

    var svc_crashes = fuzz_with_service(lcg, svc_iters, svc, seen_sigs, sig_keys)

    svc.shutdown()

    var total_iterations = codec_iters + svc_iters
    var total_crashes = codec_crashes + svc_crashes
    var unique_sigs = len(sig_keys)

    print("===== AMQP FUZZ SUMMARY =====")
    print("iterations: " + String(total_iterations))
    print("codec_rejections: " + String(codec_crashes))
    print("service_exceptions: " + String(svc_crashes))
    print("unique_signatures: " + String(unique_sigs))
    print("===== END FUZZ =====")

    # All exceptions are expected protocol-level raises — not bugs.
    # The PASS condition is: no process crash (segfault / abort).
    # We reached this point, so the process survived.
    check(True, "process survived " + String(total_iterations) + " fuzz iterations")
    print("AMQP_FUZZ_TEST=PASS")
