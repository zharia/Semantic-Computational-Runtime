# P1b: pool-enabled fan-out reclaim — buffer reuse without stale bytes, and no
# leak at acknowledge (in_use returns to 0). Exercises Router(max_class,max_pooled,
# pool_enabled=True) end to end. Uses hyrx.testing.check (Mojo assert is inert).

from std.collections import Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.core.router import Router

from hyrx.testing import check


def make_msg(val: Int, n: Int) raises -> Message:
    """A message whose payload byte i is UInt8((val+i) mod 256)."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(7)), "fan.key", headers^)
    var buf = Buffer(n)
    buf.resize(n)
    for i in range(n):
        buf[i] = UInt8((val + i) % 256)
    return Message(env^, buf^)


def test_fanout_reuse_no_stale() raises:
    var router = Router(1024, 32, True)
    router.declare_exchange("ex", ExchangeType.fanout())
    router.declare_queue("qa", 100)
    router.declare_queue("qb", 100)
    router.bind_queue("qa", "ex", "")
    router.bind_queue("qb", "ex", "")
    var ca = router.register_consumer("qa", 0)
    var cb = router.register_consumer("qb", 0)

    var msg1 = make_msg(100, 900)
    check(router.publish(msg1^, "ex") == 2, "fan1 to 2")
    var a1 = router.consume(ca)
    var b1 = router.consume(cb)
    var s1 = router.read_payload(ca, a1.value().delivery_tag())
    check(s1.size() == 900, "msg1 length 900")
    check(s1[0] == UInt8(100), "msg1 byte0")
    check(s1[899] == UInt8((100 + 899) % 256), "msg1 last byte")
    router.acknowledge(ca, a1.value().delivery_tag())
    router.acknowledge(cb, b1.value().delivery_tag())
    check(router.pool_stats().in_use == 0, "both returned to pool after ack1")

    # Same size, different content -> same class -> REUSES the freed buffers.
    # Must show ONLY msg2 bytes: reset-on-acquire prevents a stale msg1 tail.
    var msg2 = make_msg(50, 900)
    check(router.publish(msg2^, "ex") == 2, "fan2 to 2")
    var a2 = router.consume(ca)
    var b2 = router.consume(cb)
    var s2 = router.read_payload(ca, a2.value().delivery_tag())
    check(s2.size() == 900, "msg2 length 900")
    check(s2[0] == UInt8(50), "msg2 byte0 (not stale msg1 100)")
    check(s2[899] == UInt8((50 + 899) % 256), "msg2 last byte")
    check(router.pool_stats().reuses >= 1, "same-class buffers were reused")
    router.acknowledge(ca, a2.value().delivery_tag())
    router.acknowledge(cb, b2.value().delivery_tag())
    check(router.pool_stats().in_use == 0, "idle again after ack2")


def test_no_leak_balance() raises:
    var router = Router(512, 32, True)
    router.declare_exchange("ex", ExchangeType.fanout())
    for k in range(4):
        router.declare_queue("q" + String(k), 100)
        router.bind_queue("q" + String(k), "ex", "")
    check(router.pool_stats().in_use == 0, "start idle")

    var m = make_msg(1, 200)
    check(router.publish(m^, "ex") == 4, "fanned to 4")
    check(router.pool_stats().in_use == 4, "4 pooled buffers checked out")
    for k in range(4):
        var cid = router.register_consumer("q" + String(k), 0)
        var d = router.consume(cid)
        check(d.__bool__(), "delivered on q")
        router.acknowledge(cid, d.value().delivery_tag())
    check(router.pool_stats().in_use == 0, "all reclaimed to pool at ack (no leak)")


def main() raises:
    test_fanout_reuse_no_stale()
    test_no_leak_balance()
    print("POOL_RECLAIM_TEST=PASS")
