# Phase 10 — correctness test matrix (M1 Sprint 1.4).
#
# One self-contained, in-process matrix over the HyrxMQBroker product
# surface (no TCP, no files). It pins the routing / ownership / delivery-tag
# / queue-semantics contract. Existing coverage in tests/phase2
# (routing_matrix_test.mojo, queue_test.mojo) is NOT duplicated: those drive
# the core Router/Queue directly, this drives the broker + adapter path.
#
# Notes on observed vs. intended contract:
#   * Delivery tags are a PER-QUEUE 0-based counter (Queue._next_delivery_tag
#     starts at 0); the matrix asserts strict monotonic +1 and records the
#     0 base (existing phase2 tests already pin that base).
#   * The broker's publish path carries no message header map (AMQP field
#     tables are not transported yet), so headers x-match is proven at the
#     core Exchange boundary with crafted headers, plus the broker-observable
#     consequence (a required header that is absent never matches).

from std.collections import List, Dict
from std.time import monotonic

from hyrxmq.config import HyrxMQConfig
from hyrxmq.broker import HyrxMQBroker

from hyrx.core.exchange import Exchange, ExchangeType, Binding, HeaderArgs

from hyrx.testing import check


def _broker(capacity: Int) raises -> HyrxMQBroker:
    """Start a fresh in-process broker with a chosen default queue capacity."""
    var cfg = HyrxMQConfig()
    cfg.default_queue_capacity = capacity
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    return broker^


def _b(val: UInt8) -> List[UInt8]:
    """One-byte owned payload."""
    var body = List[UInt8]()
    body.append(val)
    return body^


def _no_props() -> List[UInt8]:
    """Empty AMQP property-list slice."""
    return List[UInt8]()


def _spin_ms(ms: Int):
    """Busy-wait (the engine has no timer; TTL is evaluated at delivery)."""
    var start = monotonic()
    var target = ms * 1_000_000
    while monotonic() - start < target:
        pass


def _xmatch1(var mode: String, var k: String, var v: String) -> HeaderArgs:
    """HeaderArgs for a headers binding: x-match + one required pair."""
    var keys = List[String]()
    var vals = List[String]()
    keys.append("x-match")
    vals.append(mode)
    keys.append(k)
    vals.append(v)
    return HeaderArgs(keys^, vals^)


def _xmatch2(
    var mode: String,
    var k1: String,
    var v1: String,
    var k2: String,
    var v2: String,
) -> HeaderArgs:
    """HeaderArgs for a headers binding: x-match + two required pairs."""
    var keys = List[String]()
    var vals = List[String]()
    keys.append("x-match")
    vals.append(mode)
    keys.append(k1)
    vals.append(v1)
    keys.append(k2)
    vals.append(v2)
    return HeaderArgs(keys^, vals^)


# ---- 1. Routing matrix -------------------------------------------------

def test_direct_exact_no_match_and_empty_key() raises:
    """direct: exact key match routes, non-match / empty key do not."""
    var broker = _broker(1024)
    _ = broker.declare_exchange("d1", "direct")
    _ = broker.declare_queue("dq1")
    _ = broker.declare_queue("dq_empty")
    _ = broker.bind_queue("dq1", "d1", "k1", HeaderArgs())
    _ = broker.bind_queue("dq_empty", "d1", "", HeaderArgs())

    check(broker.publish("d1", "k1", _b(0x01)) == 1,
          "direct: exact key match routes to its queue")
    check(broker.publish("d1", "k2", _b(0x02)) == 0,
          "direct: non-matching key routes nowhere")
    check(broker.publish("d1", "", _b(0x03)) == 1,
          "direct: the empty key matches the empty-key binding")
    check(broker.queue_depth("dq1") == 1, "direct: only the matched publish queued")
    check(broker.queue_depth("dq_empty") == 1, "direct: empty-key publish queued once")


def test_fanout_ignores_key() raises:
    """fanout: routing key is ignored; every bound queue receives."""
    var broker = _broker(1024)
    _ = broker.declare_exchange("f1", "fanout")
    _ = broker.declare_queue("fa")
    _ = broker.declare_queue("fb")
    _ = broker.bind_queue("fa", "f1", "ignored.a", HeaderArgs())
    _ = broker.bind_queue("fb", "f1", "ignored.b", HeaderArgs())

    check(broker.publish("f1", "totally.different", _b(0x10)) == 2,
          "fanout: any key reaches all bound queues")
    check(broker.publish("f1", "", _b(0x11)) == 2,
          "fanout: empty key also reaches all bound queues")
    check(broker.queue_depth("fa") == 2, "fanout: first queue got both copies")
    check(broker.queue_depth("fb") == 2, "fanout: second queue got both copies")


def test_topic_wildcards_and_no_match() raises:
    """topic: a.b.c matches a.*.c, #, a.#; unrelated key matches none."""
    var broker = _broker(1024)
    _ = broker.declare_exchange("t1", "topic")
    _ = broker.declare_queue("t_star")
    _ = broker.declare_queue("t_hash")
    _ = broker.declare_queue("t_tail")
    _ = broker.bind_queue("t_star", "t1", "a.*.c", HeaderArgs())
    _ = broker.bind_queue("t_hash", "t1", "#", HeaderArgs())
    _ = broker.bind_queue("t_tail", "t1", "a.#", HeaderArgs())

    check(broker.publish("t1", "a.b.c", _b(0x20)) == 3,
          "topic: a.b.c matches a.*.c, #, and a.#")

    _ = broker.declare_exchange("tneg", "topic")
    _ = broker.declare_queue("tneg_q")
    _ = broker.bind_queue("tneg_q", "tneg", "a.*.c", HeaderArgs())
    check(broker.publish("tneg", "x.b.c", _b(0x21)) == 0,
          "topic: x.b.c does not match a.*.c (first word differs)")


def test_headers_x_match_all_any() raises:
    """headers: x-match semantics at the core boundary + broker consequence."""
    # Broker-observable: publishes carry no header map, so a binding that
    # REQUIRES a header never matches; a bare binding matches all.
    var broker = _broker(1024)
    _ = broker.declare_exchange("hx", "headers")
    _ = broker.declare_queue("h_all")
    _ = broker.declare_queue("h_need_all")
    _ = broker.declare_queue("h_need_any")
    _ = broker.bind_queue("h_all", "hx", "", HeaderArgs())
    _ = broker.bind_queue("h_need_all", "hx", "", _xmatch1("all", "kind", "a"))
    _ = broker.bind_queue("h_need_any", "hx", "", _xmatch1("any", "kind", "a"))
    check(broker.publish("hx", "k", _b(0x30)) == 1,
          "headers: only the unconditional binding matches an empty header map")

    # Core-boundary truth table with crafted message headers.
    var ex = Exchange("hcore", ExchangeType.headers())
    ex.add_binding(Binding("allq", "", _xmatch2("all", "kind", "a", "color", "red")))
    ex.add_binding(Binding("anyq", "", _xmatch2("any", "kind", "a", "color", "red")))
    var h = Dict[String, String]()
    h["kind"] = "a"
    var matched = ex.match("", h)
    check(len(matched) == 1, "headers: x-match=all fails on the missing 'color'")
    check(matched[0] == "anyq", "headers: x-match=any succeeds on one match")
    h["color"] = "red"
    check(len(ex.match("", h)) == 2, "headers: both bindings match once all present")


def test_default_exchange_direct_to_queue() raises:
    """default exchange "": publish routes DIRECT to the queue named by key."""
    var broker = _broker(1024)
    _ = broker.declare_queue("named")
    check(broker.publish_to_queue_with_props("named", _b(0x40), UInt16(0), _no_props()) == 1,
          "default exchange: routes to the queue named by the routing key")
    check(broker.publish_to_queue_with_props("ghost", _b(0x41), UInt16(0), _no_props()) == 0,
          "default exchange: missing queue name is silently unrouted")
    check(broker.queue_depth("named") == 1, "default exchange: exactly one copy queued")


# ---- 2. Ownership lifecycle --------------------------------------------

def test_publish_two_queues_independent_copies() raises:
    """One publish -> two queues: independent copies; ack isolates one."""
    var broker = _broker(1024)
    _ = broker.declare_exchange("ox", "direct")
    _ = broker.declare_queue("oa")
    _ = broker.declare_queue("ob")
    _ = broker.bind_queue("oa", "ox", "k", HeaderArgs())
    _ = broker.bind_queue("ob", "ox", "k", HeaderArgs())

    check(broker.publish("ox", "k", _b(0x77)) == 2,
          "ownership: one publish fans out to two bound queues")
    var ca = broker.consume_register("oa")
    var cb = broker.consume_register("ob")
    var da = broker.deliver(ca)
    var db = broker.deliver(cb)
    check(da.__bool__() and db.__bool__(), "ownership: both queues hold a delivery")
    var ta = da.value().delivery_tag()
    var tb = db.value().delivery_tag()
    var pa = broker.read_payload(ca, ta)
    var pb = broker.read_payload(cb, tb)
    check(len(pa) == 1 and pa[0] == 0x77, "ownership: queue a copy intact")
    check(len(pb) == 1 and pb[0] == 0x77, "ownership: queue b copy intact")

    # Resolve (the only mutation the surface exposes) queue a's copy.
    check(broker.ack(ca, ta), "ownership: ack resolves queue a's delivery")
    var pb2 = broker.read_payload(cb, tb)
    check(len(pb2) == 1 and pb2[0] == 0x77,
          "ownership: queue b's copy is unaffected by queue a's resolution")
    check(not broker.deliver(ca).__bool__(),
          "ownership: ack removed the message from queue a only")
    check(not broker.deliver(cb).__bool__(),
          "ownership: queue b held exactly one copy (no duplication)")


# ---- 3. Delivery tag correctness ---------------------------------------

def test_delivery_tags_monotonic() raises:
    """Per-queue tags are strictly monotonic (+1); base is 0."""
    var broker = _broker(1024)
    _ = broker.declare_queue("tagq")
    for i in range(3):
        check(broker.publish_to_queue_with_props("tagq", _b(UInt8(0x10 + i)), UInt16(0), _no_props()) == 1,
              "tags: publish " + String(i) + " accepted")
    var cid = broker.consume_register("tagq")
    var d1 = broker.deliver(cid)
    var d2 = broker.deliver(cid)
    var d3 = broker.deliver(cid)
    check(d1.__bool__() and d2.__bool__() and d3.__bool__(),
          "tags: three deliveries registered")
    var t1 = d1.value().delivery_tag()
    var t2 = d2.value().delivery_tag()
    var t3 = d3.value().delivery_tag()
    check(t1 == 0, "tags: per-queue base tag is 0")
    check(t2 == t1 + 1, "tags: second tag is exactly one greater")
    check(t3 == t2 + 1, "tags: third tag is exactly one greater (monotonic 0,1,2)")


def test_ack_middle_tag_leaves_others() raises:
    """Ack tag 2 (middle) -> tags 1 and 3 remain unacked."""
    var broker = _broker(1024)
    _ = broker.declare_queue("midq")
    for i in range(3):
        _ = broker.publish_to_queue_with_props("midq", _b(UInt8(0x50 + i)), UInt16(0), _no_props())
    var cid = broker.consume_register("midq")
    var t1 = broker.deliver(cid).value().delivery_tag()
    var t2 = broker.deliver(cid).value().delivery_tag()
    var t3 = broker.deliver(cid).value().delivery_tag()
    check(broker.ack(cid, t2), "ack middle: the middle tag resolves")
    check(len(broker.read_payload(cid, t1)) == 1, "ack middle: earlier tag remains")
    check(len(broker.read_payload(cid, t2)) == 0, "ack middle: middle tag removed")
    check(len(broker.read_payload(cid, t3)) == 1, "ack middle: later tag remains")


def test_bulk_ack_through_removes_prefix() raises:
    """basic.ack multiple=true: every tag <= tag is removed."""
    var broker = _broker(1024)
    _ = broker.declare_queue("bulkq")
    for i in range(3):
        _ = broker.publish_to_queue_with_props("bulkq", _b(UInt8(0x60 + i)), UInt16(0), _no_props())
    var cid = broker.consume_register("bulkq")
    var t1 = broker.deliver(cid).value().delivery_tag()
    var t2 = broker.deliver(cid).value().delivery_tag()
    var t3 = broker.deliver(cid).value().delivery_tag()
    check(broker.bulk_ack(cid, t2) == 2, "bulk ack: two tags <= t2 acknowledged")
    check(len(broker.read_payload(cid, t1)) == 0, "bulk ack: t1 removed")
    check(len(broker.read_payload(cid, t2)) == 0, "bulk ack: t2 removed")
    check(len(broker.read_payload(cid, t3)) == 1, "bulk ack: t3 outside prefix remains")
    check(broker.ack(cid, t3), "bulk ack: the surviving tag is still ackable")


# ---- 4. Queue semantics -------------------------------------------------

def test_capacity_backpressure() raises:
    """Bare capacity: enqueue past capacity is refused (routed == 0)."""
    var broker = _broker(2)
    _ = broker.declare_queue("capq")
    check(broker.publish_to_queue_with_props("capq", _b(0xA1), UInt16(0), _no_props()) == 1,
          "capacity: first publish accepted")
    check(broker.publish_to_queue_with_props("capq", _b(0xA2), UInt16(0), _no_props()) == 1,
          "capacity: second publish accepted")
    check(broker.publish_to_queue_with_props("capq", _b(0xA3), UInt16(0), _no_props()) == 0,
          "capacity: third publish refused at capacity")
    check(broker.queue_depth("capq") == 2, "capacity: queue holds exactly its capacity")


def test_message_ttl_expiry() raises:
    """x-message-ttl: an expired message is not delivered (reaped at delivery)."""
    var broker = _broker(1024)
    _ = broker.declare_queue_full("ttlq", False, 1, 0, 0, False, "", "")
    check(broker.publish_to_queue_with_props("ttlq", _b(0xF1), UInt16(0), _no_props()) == 1,
          "ttl: publish accepted")
    check(broker.queue_depth("ttlq") == 1, "ttl: message is initially ready")
    _spin_ms(5)
    var cid = broker.consume_register("ttlq")
    check(not broker.deliver(cid).__bool__(), "ttl: expired message is not delivered")
    check(broker.queue_depth("ttlq") == 0, "ttl: expired message reaped from the queue")


def test_max_length_drop_head() raises:
    """x-max-length (default overflow=drop-head): oldest message is trimmed."""
    var broker = _broker(1024)
    _ = broker.declare_queue_full("mlq", False, 0, 0, 2, False, "", "")
    for i in range(3):
        check(broker.publish_to_queue_with_props("mlq", _b(UInt8(0xB0 + i)), UInt16(0), _no_props()) == 1,
              "max-length: publish " + String(i) + " accepted (drop-head)")
    check(broker.queue_depth("mlq") == 2, "max-length: queue trimmed back to its cap")
    var cid = broker.consume_register("mlq")
    var first = broker.read_payload(cid, broker.deliver(cid).value().delivery_tag())
    var second = broker.read_payload(cid, broker.deliver(cid).value().delivery_tag())
    check(first[0] == 0xB1, "max-length: head (0xB0) was dropped")
    check(second[0] == 0xB2, "max-length: survivors keep FIFO order")


def test_max_length_overflow_reject() raises:
    """x-max-length + overflow=reject-publish: new publishes are refused."""
    var broker = _broker(1024)
    _ = broker.declare_queue_full("mrq", False, 0, 0, 2, True, "", "")
    check(broker.publish_to_queue_with_props("mrq", _b(0xC1), UInt16(0), _no_props()) == 1,
          "overflow-reject: first publish accepted")
    check(broker.publish_to_queue_with_props("mrq", _b(0xC2), UInt16(0), _no_props()) == 1,
          "overflow-reject: second publish accepted")
    check(broker.publish_to_queue_with_props("mrq", _b(0xC3), UInt16(0), _no_props()) == 0,
          "overflow-reject: third publish refused (not drop-head)")
    check(broker.queue_depth("mrq") == 2, "overflow-reject: no message was trimmed")
    var cid = broker.consume_register("mrq")
    var first = broker.read_payload(cid, broker.deliver(cid).value().delivery_tag())
    check(first[0] == 0xC1, "overflow-reject: head survives intact")


def test_dead_letter_exchange() raises:
    """x-dead-letter-exchange: a nack(requeue=false) routes to the DLX."""
    var broker = _broker(1024)
    _ = broker.declare_exchange("dlxex", "direct")
    _ = broker.declare_queue("deadq")
    _ = broker.bind_queue("deadq", "dlxex", "dead", HeaderArgs())
    _ = broker.declare_queue_full("orig", False, 0, 0, 0, False, "dlxex", "dead")

    check(broker.publish_to_queue_with_props("orig", _b(0xD1), UInt16(0), _no_props()) == 1,
          "dlx: message published into the source queue")
    var cid = broker.consume_register("orig")
    var tag = broker.deliver(cid).value().delivery_tag()
    check(broker.nack(cid, tag, False), "dlx: nack(requeue=false) resolves the delivery")
    check(broker.queue_depth("orig") == 0, "dlx: source queue no longer holds the message")
    check(broker.queue_depth("deadq") == 1, "dlx: dead-lettered message landed on the DLX queue")

    var dead_cid = broker.consume_register("deadq")
    var dead = broker.deliver(dead_cid)
    check(dead.__bool__(), "dlx: dead-lettered message is deliverable")
    check(broker.read_payload(dead_cid, dead.value().delivery_tag())[0] == 0xD1,
          "dlx: dead-lettered payload is byte-preserved")
    check(broker.queue_routing_key(dead_cid, dead.value().delivery_tag()) == "dead",
          "dlx: dead-letter routing key replaces the original")


def test_purge_empties_queue() raises:
    """queue.purge drops every ready message and returns the count."""
    var broker = _broker(1024)
    _ = broker.declare_queue("pq")
    for i in range(3):
        _ = broker.publish_to_queue_with_props("pq", _b(UInt8(0xE0 + i)), UInt16(0), _no_props())
    check(broker.queue_depth("pq") == 3, "purge: three ready messages")
    check(broker.purge_queue("pq") == 3, "purge: returns the purged count")
    check(broker.queue_depth("pq") == 0, "purge: queue is empty afterwards")
    var cid = broker.consume_register("pq")
    check(not broker.deliver(cid).__bool__(), "purge: no message is deliverable")
    check(broker.purge_queue("ghost") == -1, "purge: missing queue returns -1")


def main() raises:
    test_direct_exact_no_match_and_empty_key()
    test_fanout_ignores_key()
    test_topic_wildcards_and_no_match()
    test_headers_x_match_all_any()
    test_default_exchange_direct_to_queue()
    test_publish_two_queues_independent_copies()
    test_delivery_tags_monotonic()
    test_ack_middle_tag_leaves_others()
    test_bulk_ack_through_removes_prefix()
    test_capacity_backpressure()
    test_message_ttl_expiry()
    test_max_length_drop_head()
    test_max_length_overflow_reject()
    test_dead_letter_exchange()
    test_purge_empties_queue()
    print("CORRECTNESS_MATRIX_TEST=PASS")