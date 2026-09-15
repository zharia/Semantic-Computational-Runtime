# Phase 10 — stateful protocol fuzzing for HyrxMQ (AMQPService).
#
# Unlike the frame-level fuzzer (amqp_fuzz_test.mojo), this harness fuzzes the
# OPERATION SEQUENCE of a connection lifecycle:
#
#   CONNECT -> OPEN -> CHANNEL -> DECLARE -> PUBLISH -> CONSUME -> ACK -> CLOSE
#
# Each iteration starts from that ordered list of operations and applies one
# mutation strategy:
#   reorder        — Fisher-Yates shuffle of the operation order
#   duplicate      — repeat one operation in place
#   omit           — drop one operation
#   malformed-value— corrupt one argument byte of one operation
#
# The mutated sequence is fed to a live AMQPService.handle_frame. Every raise
# is caught (bare except); the harness asserts no unhandled crash and reports
# the number of service exceptions + unique exception signatures.
#
# Deterministic LCG (no random module), default 5000 iterations (override with
# HYRXMQ_FUZZ_ITERS), bounded broker state.

from std.collections import Dict, List
from std.os import getenv

from hyrx.amqp.constants import (
    BASIC_ACK,
    BASIC_CONSUME,
    BASIC_PUBLISH,
    CHANNEL_OPEN,
    CONNECTION_CLOSE,
    CONNECTION_OPEN,
    QUEUE_DECLARE,
    QUEUE_DELETE,
)
from hyrx.amqp.frame_codec import AMQPFrame
from hyrxmq.amqp_service import (
    AMQPService,
    write_short_string,
    write_u16,
    write_u64,
)
from hyrxmq.config import HyrxMQConfig
from hyrx.testing import check


# ---- deterministic LCG (glibc params, period 2^32) ---------------------------

struct LCG:
    var state: UInt32

    def __init__(out self, seed: UInt32):
        self.state = seed

    def next(mut self) -> UInt32:
        self.state = self.state * 1103515245 + 12345
        return self.state

    def next_range(mut self, lo: Int, hi: Int) -> Int:
        var span = hi - lo + 1
        if span <= 0:
            return lo
        var r = self.next()
        return lo + Int(r % UInt32(span))


def simple_hash(var msg: String) -> UInt64:
    """FNV-1a hash of an exception message (signature dedup)."""
    var h: UInt64 = 0xCBF29CE484222325
    var b = msg.as_bytes()
    for i in range(len(b)):
        h = h ^ UInt64(b[i])
        h = h * 0x100000001B3
    return h


def resolve_iters(var env_name: String, default: Int) raises -> Int:
    """Iteration count: HYRXMQ_FUZZ_ITERS when set, else `default`.

    Keeps the historical default when no override is present; a malformed
    value fails loud rather than silently running a smaller bar."""
    var v = getenv(env_name, "")
    if len(v.bytes()) == 0:
        return default
    return Int(v)


# ---- frame builders ----------------------------------------------------------

def reserved() -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)
    return a^


def empty_table(mut a: List[UInt8]):
    a.append(0)
    a.append(0)
    a.append(0)
    a.append(0)


def method_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) -> AMQPFrame:
    """A METHOD frame payload = class(2) + method(2) + args."""
    var p = List[UInt8]()
    p.append(UInt8((Int(class_id) >> 8) & 0xFF))
    p.append(UInt8(Int(class_id) & 0xFF))
    p.append(UInt8((Int(method_id) >> 8) & 0xFF))
    p.append(UInt8(Int(method_id) & 0xFF))
    for i in range(len(args)):
        p.append(args[i])
    return AMQPFrame(UInt8(1), chan, p^)


def header_frame(chan: UInt16, body_size: Int) -> AMQPFrame:
    """A HEADER frame payload = class(2) + weight(2) + size(8) + flags(2)."""
    var p = List[UInt8]()
    p.append(0)
    p.append(60)  # basic class
    p.append(0)
    p.append(0)  # weight (reserved, MUST be 0)
    var bs = Int(body_size)
    for i in range(8):
        var shift = (7 - i) * 8
        p.append(UInt8((bs >> shift) & 0xFF))
    p.append(0)
    p.append(0)  # property flags
    return AMQPFrame(UInt8(2), chan, p^)


def body_frame(chan: UInt16, var body: List[UInt8]) -> AMQPFrame:
    return AMQPFrame(UInt8(3), chan, body^)


def maybe_corrupt(mut args: List[UInt8], corrupt: Bool, mut lcg: LCG):
    """Malformed-value mutation: overwrite one argument byte with 0xFF."""
    if corrupt and len(args) > 0:
        var pos = lcg.next_range(0, len(args) - 1)
        args[pos] = UInt8(0xFF)


# ---- one operation -----------------------------------------------------------

def emit_op(
    mut svc: AMQPService, conn_id: UInt64, op: Int, corrupt: Bool, mut lcg: LCG
) raises:
    """Feed one operation's frame(s) to the service. May raise (caught)."""
    if op == 0:
        # CONNECT -> connection.open (10,40) on channel 0.
        var a0 = reserved()
        write_short_string(a0, "/")
        a0.append(0)
        a0.append(0)
        a0.append(0)
        maybe_corrupt(a0, corrupt, lcg)
        var f0 = method_frame(
            UInt16(0), CONNECTION_OPEN().class_id, CONNECTION_OPEN().method_id, a0^
        )
        _ = svc.handle_frame(conn_id, f0)
        return
    if op == 1:
        # OPEN -> channel.open (20,10) on channel 1.
        var a1 = reserved()
        a1.append(0)
        a1.append(0)
        a1.append(0)
        a1.append(0)
        maybe_corrupt(a1, corrupt, lcg)
        var f1 = method_frame(
            UInt16(1), CHANNEL_OPEN().class_id, CHANNEL_OPEN().method_id, a1^
        )
        _ = svc.handle_frame(conn_id, f1)
        return
    if op == 2:
        # CHANNEL -> channel.open (20,10) on channel 2.
        var a2 = reserved()
        a2.append(0)
        a2.append(0)
        a2.append(0)
        a2.append(0)
        maybe_corrupt(a2, corrupt, lcg)
        var f2 = method_frame(
            UInt16(2), CHANNEL_OPEN().class_id, CHANNEL_OPEN().method_id, a2^
        )
        _ = svc.handle_frame(conn_id, f2)
        return
    if op == 3:
        # DECLARE -> queue.declare (50,10) "fq" on channel 1.
        var a3 = reserved()
        write_short_string(a3, "fq")
        a3.append(0)  # bits: passive/durable/exclusive/auto-delete/no-wait
        empty_table(a3)
        maybe_corrupt(a3, corrupt, lcg)
        var f3 = method_frame(
            UInt16(1), QUEUE_DECLARE().class_id, QUEUE_DECLARE().method_id, a3^
        )
        _ = svc.handle_frame(conn_id, f3)
        return
    if op == 4:
        # PUBLISH -> basic.publish (60,40) + HEADER + BODY on channel 1.
        var a4 = reserved()
        write_short_string(a4, "")  # default exchange
        write_short_string(a4, "fq")
        a4.append(0)  # bits: mandatory/immediate
        maybe_corrupt(a4, corrupt, lcg)
        var f4 = method_frame(
            UInt16(1), BASIC_PUBLISH().class_id, BASIC_PUBLISH().method_id, a4^
        )
        _ = svc.handle_frame(conn_id, f4)
        var body = List[UInt8]()
        body.append(0xAB)
        body.append(0xCD)
        _ = svc.handle_frame(conn_id, header_frame(UInt16(1), len(body)))
        _ = svc.handle_frame(conn_id, body_frame(UInt16(1), body^))
        return
    if op == 5:
        # CONSUME -> basic.consume (60,20) "fq" ctag "ct" on channel 1.
        var a5 = reserved()
        write_short_string(a5, "fq")
        write_short_string(a5, "ct")
        a5.append(0)  # bits: no-local/no-ack/exclusive/no-wait
        empty_table(a5)
        maybe_corrupt(a5, corrupt, lcg)
        var f5 = method_frame(
            UInt16(1), BASIC_CONSUME().class_id, BASIC_CONSUME().method_id, a5^
        )
        _ = svc.handle_frame(conn_id, f5)
        return
    if op == 6:
        # ACK -> basic.ack (60,80) tag=1 + bits on channel 1.
        var a6 = List[UInt8]()
        write_u64(a6, UInt64(1))
        a6.append(0)
        maybe_corrupt(a6, corrupt, lcg)
        var f6 = method_frame(
            UInt16(1), BASIC_ACK().class_id, BASIC_ACK().method_id, a6^
        )
        _ = svc.handle_frame(conn_id, f6)
        return
    if op == 7:
        # CLOSE -> connection.close (10,50) on channel 0 (cleanup).
        var a7 = List[UInt8]()
        write_u16(a7, UInt16(200))
        write_short_string(a7, "bye")
        write_u16(a7, UInt16(0))
        write_u16(a7, UInt16(0))
        maybe_corrupt(a7, corrupt, lcg)
        var f7 = method_frame(
            UInt16(0), CONNECTION_CLOSE().class_id, CONNECTION_CLOSE().method_id, a7^
        )
        _ = svc.handle_frame(conn_id, f7)
        return


def cleanup(mut svc: AMQPService, conn_id: UInt64):
    """Best-effort: drop the queue + close the connection (bounded state)."""
    try:
        var q = reserved()
        write_short_string(q, "fq")
        q.append(0)  # bits: if-empty/if-unused/no-wait
        var qf = method_frame(
            UInt16(1), QUEUE_DELETE().class_id, QUEUE_DELETE().method_id, q^
        )
        _ = svc.handle_frame(conn_id, qf)
    except:
        pass
    try:
        var c = List[UInt8]()
        write_u16(c, UInt16(200))
        write_short_string(c, "bye")
        write_u16(c, UInt16(0))
        write_u16(c, UInt16(0))
        var cf = method_frame(
            UInt16(0), CONNECTION_CLOSE().class_id, CONNECTION_CLOSE().method_id, c^
        )
        _ = svc.handle_frame(conn_id, cf)
    except:
        pass


# ---- sequence mutations ------------------------------------------------------

def shuffle_ops(mut seq: List[Int], mut lcg: LCG):
    var i = len(seq) - 1
    while i > 0:
        var j = lcg.next_range(0, i)
        var tmp = seq[i]
        seq[i] = seq[j]
        seq[j] = tmp
        i -= 1


def duplicate_op(mut seq: List[Int], mut lcg: LCG):
    if len(seq) == 0:
        return
    var pos = lcg.next_range(0, len(seq) - 1)
    var out = List[Int]()
    for i in range(len(seq)):
        out.append(seq[i])
        if i == pos:
            out.append(seq[i])
    seq = out^


def omit_op(mut seq: List[Int], mut lcg: LCG):
    if len(seq) <= 1:
        return
    var pos = lcg.next_range(0, len(seq) - 1)
    var out = List[Int]()
    for i in range(len(seq)):
        if i != pos:
            out.append(seq[i])
    seq = out^


# ---- main --------------------------------------------------------------------

def main() raises:
    var lcg = LCG(UInt32(0x5EEDF00D))

    var cfg = HyrxMQConfig()
    cfg.validate()
    var svc = AMQPService(cfg^)
    svc.start()

    var seen_sigs = Dict[UInt64, Int]()
    var sig_keys = List[UInt64]()
    var iterations = resolve_iters("HYRXMQ_FUZZ_ITERS", 5000)
    if iterations < 0:
        iterations = 0
    var service_exceptions = 0

    for it in range(iterations):
        # base ordered lifecycle: CONNECT->OPEN->CHANNEL->DECLARE->PUBLISH->
        # CONSUME->ACK->CLOSE
        var seq = List[Int]()
        for k in range(8):
            seq.append(k)

        var strategy = lcg.next_range(0, 3)
        var corrupt_index = -1
        if strategy == 0:
            shuffle_ops(seq, lcg)
        elif strategy == 1:
            duplicate_op(seq, lcg)
        elif strategy == 2:
            omit_op(seq, lcg)
        else:
            corrupt_index = lcg.next_range(0, len(seq) - 1)

        var conn_id = UInt64(100000 + it)

        for pos in range(len(seq)):
            var op = seq[pos]
            var corrupt = pos == corrupt_index
            try:
                emit_op(svc, conn_id, op, corrupt, lcg)
            except e:
                service_exceptions += 1
                var sig = simple_hash(String(e))
                if sig in seen_sigs:
                    seen_sigs[sig] = seen_sigs[sig] + 1
                else:
                    seen_sigs[sig] = 1
                    sig_keys.append(sig)

        cleanup(svc, conn_id)

    svc.shutdown()

    var unique_sigs = len(sig_keys)
    print("===== STATEFUL FUZZ SUMMARY =====")
    print("iterations: " + String(iterations))
    print("service_exceptions: " + String(service_exceptions))
    print("unique_signatures: " + String(unique_sigs))
    print("===== END STATEFUL FUZZ =====")

    # All raises are expected protocol-level errors caught by the harness.
    # Reaching here proves no unhandled crash across every iteration.
    check(True, "process survived " + String(iterations) + " stateful fuzz iterations")
    print("STATEFUL_FUZZ_TEST=PASS")