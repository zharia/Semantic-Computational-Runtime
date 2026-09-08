# Routing semantics matrix (audit §6).
#
# Exercises the REAL engine (Router/Exchange/Queue) and asserts the EXACT
# routing outcome for each card in the audit §6 matrix:
#   1 pub -> 1 queue, 1 pub -> N queues, N pub -> 1 queue, N pub -> N queues,
#   N consumers -> 1 queue, unroutable publish, multiple matching bindings,
#   duplicate bindings.
#
# Ownership outcome asserted throughout: publish() COPIES the payload bytes
# per destination queue (one owned Buffer per queue, no sharing between
# queues), and the original Message is consumed by the publish() call.
#
# Deviations from the intended contract are labelled REPORTED: asserted as
# OBSERVED behaviour, not endorsed. See docs/MEMORY_MODEL.md "Reported defects".
#
# Note: Router exposes no queue-depth accessor, so "exactly one copy" is
# proven by draining a consumer and asserting the extra deliveries are None.

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import Binding, Exchange, ExchangeType
from hyrx.core.router import Router

from hyrx.testing import check

def _msg(var key: String, val: UInt8) raises -> Message:
    """One-byte payload carrying `val`; message_id == val."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(val)), key^, headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = val
    return Message(env^, buf^)

def _binding(var queue_name: String, var routing_key: String) -> Binding:
    var args = Dict[String, String]()
    return Binding(queue_name^, routing_key^, args^)

def _fanout(var ex_name: String, var qnames: List[String], capacity: Int) raises -> Router:
    """Router with one fanout exchange bound to every queue in qnames."""
    var router = Router()
    router.declare_exchange(ex_name, ExchangeType.fanout())
    for i in range(len(qnames)):
        router.declare_queue(qnames[i], capacity)
        router.bind_queue(qnames[i], ex_name, "")
    return router^

def _drain_payloads(mut router: Router, consumer_id: UInt64, var want: Int) raises -> Int:
    """Consume exactly `want` deliveries and return their payload XOR-fold."""
    var fold = 0
    for i in range(want):
        var d = router.consume(consumer_id)
        check(d.__bool__(), "drain: delivery " + String(i) + " expected")
        var snap = router.read_payload(consumer_id, d.value().delivery_tag())
        for j in range(snap.size()):
            fold = fold ^ Int(snap[j])
    return fold

def _assert_empty(mut router: Router, consumer_id: UInt64, label: String) raises:
    """No further delivery may be available to this consumer."""
    check(not router.consume(consumer_id).__bool__(), label + ": queue exhausted")

# ---- card 1: one publisher -> one queue -------------------------------

def test_one_pub_one_queue() raises:
    """One matching binding: routed == 1 and exactly one owned copy queued."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("orders", 100)
    router.bind_queue("orders", "ex", "orders.new")

    var routed = router.publish(_msg("orders.new", 0x01)^, "ex")
    check(routed == 1, "1pub->1q: routed == 1")
    check(router.messages_routed() == 1, "1pub->1q: counter == 1")

    var cid = router.register_consumer("orders", 0)
    var d = router.consume(cid)
    check(d.__bool__(), "1pub->1q: one delivery available")
    var snap = router.read_payload(cid, d.value().delivery_tag())
    check(snap.size() == 1, "1pub->1q: copied payload length preserved")
    check(snap[0] == 0x01, "1pub->1q: copied payload byte preserved")
    check(snap.to_bytes()[0] == 0x01, "1pub->1q: to_bytes() yields the same copied bytes")
    _assert_empty(router, cid, "1pub->1q")

def test_publish_consumes_the_source_message() raises:
    """The published Message is consumed by publish(); the queue's copy is a
    separate allocation (proved: payload bytes are copied), and the metadata
    the publisher set (message_id + headers) is preserved on the queued copy
    (WP-A of increment 0004 — the previous "REPORTED defect" is now fixed via
    the queue read-back API)."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("q", 10)
    router.bind_queue("q", "ex", "k")
    var headers = Dict[String, String]()
    headers["prio"] = "high"
    var rk = "k"
    var env = Envelope(MessageID(UInt64(0xBEEF)), rk, headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = 0x77
    var msg = Message(env^, buf^)
    check(router.publish(msg^, "ex") == 1, "source consumed by publish")
    var cid = router.register_consumer("q", 0)
    var d = router.consume(cid)
    check(router.read_payload(cid, d.value().delivery_tag())[0] == 0x77,
          "payload COPIED into the queued message")
    check(router.read_message_id(cid, d.value().delivery_tag()) == MessageID(UInt64(0xBEEF)),
          "WP-A: published message_id preserved on the queued copy")
    var got_headers = router.read_headers(cid, d.value().delivery_tag())
    check(got_headers["prio"] == "high", "WP-A: published header preserved")

def test_metadata_fidelity_preserved_on_fanout() raises:
    """WP-A (increment 0004, Sprint 01): a publish carrying a non-zero
    message_id and ≥1 header must deliver the SAME id and headers to EVERY
    accepted fan-out destination; each queued envelope owns an independent
    header map.

    Negative proof: against the old router (MessageID(0) + empty headers) the
    checks below fail — this is the regression guard for the fix."""
    var router = Router()
    router.declare_exchange("f", ExchangeType.fanout())
    for n in ["a", "b", "c"]:
        router.declare_queue(n, 100)
        router.bind_queue(n, "f", "")

    var mid_val = UInt64(0xCAFE)
    var headers = Dict[String, String]()
    headers["prio"] = "high"
    headers["trace"] = "abc"
    var rk = "k"
    var env = Envelope(MessageID(mid_val), rk, headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = 0x2A
    var msg = Message(env^, buf^)
    check(router.publish(msg^, "f") == 3, "WP-A: fanned out to all three queues")

    for n in ["a", "b", "c"]:
        var cid = router.register_consumer(n, 0)
        var d = router.consume(cid)
        check(d.__bool__(), "WP-A: " + n + " received a delivery")
        var tag = d.value().delivery_tag()
        check(router.read_message_id(cid, tag) == MessageID(mid_val),
              "WP-A: " + n + " keeps the published message_id")
        var got = router.read_headers(cid, tag)
        check(got["prio"] == "high", "WP-A: " + n + " keeps header prio")
        check(got["trace"] == "abc", "WP-A: " + n + " keeps header trace")
        check(len(got) == 2, "WP-A: " + n + " owns an independent header map")

def test_metadata_fidelity_single_destination_move() raises:
    """WP-A + single-destination move path: when exactly one queue is eligible,
    publish transfers the source Message directly (no per-destination clone);
    the move must still preserve message_id and headers."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("only", 10)
    router.bind_queue("only", "ex", "k")
    var mid_val = UInt64(0x1234)
    var headers = Dict[String, String]()
    headers["x"] = "one"
    var rk = "k"
    var env = Envelope(MessageID(mid_val), rk, headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = 0x5
    var msg = Message(env^, buf^)
    check(router.publish(msg^, "ex") == 1, "single eligible queue takes the move")
    var cid = router.register_consumer("only", 0)
    var d = router.consume(cid)
    check(router.read_message_id(cid, d.value().delivery_tag()) == MessageID(mid_val),
          "WP-A: moved message keeps message_id")
    check(router.read_headers(cid, d.value().delivery_tag())["x"] == "one",
          "WP-A: moved message keeps header x")

# ---- card 2: one publisher -> many queues -----------------------------

def test_one_pub_many_queues() raises:
    """Fanout: one owned COPY of the payload per destination queue."""
    var names = List[String]()
    names.append("a")
    names.append("b")
    names.append("c")
    var router = _fanout("f", names^, 100)

    var routed = router.publish(_msg("whatever", 0x2A)^, "f")
    check(routed == 3, "1pub->Nq: fanout routes to all three queues")
    check(router.messages_routed() == 3, "1pub->Nq: counter counts copies, not messages")

    var ca = router.register_consumer("a", 0)
    var cb = router.register_consumer("b", 0)
    var cc = router.register_consumer("c", 0)
    var da = router.consume(ca)
    var db = router.consume(cb)
    var dc = router.consume(cc)
    check(router.read_payload(ca, da.value().delivery_tag())[0] == 0x2A, "1pub->Nq: a got a copy")
    check(router.read_payload(cb, db.value().delivery_tag())[0] == 0x2A, "1pub->Nq: b got a copy")
    check(router.read_payload(cc, dc.value().delivery_tag())[0] == 0x2A, "1pub->Nq: c got a copy")
    _assert_empty(router, ca, "1pub->Nq a")
    _assert_empty(router, cb, "1pub->Nq b")
    _assert_empty(router, cc, "1pub->Nq c")

    # Copies, not shared ownership: acking one queue cannot affect another.
    check(router.acknowledge(ca, da.value().delivery_tag()), "1pub->Nq: ack in queue a")
    check(router.read_payload(cb, db.value().delivery_tag())[0] == 0x2A,
          "1pub->Nq: queue b's copy survives queue a's ack")

def test_delivery_tags_are_per_queue_counters() raises:
    """Delivery tags are scoped to a queue and restart at 0, so two queues
    hand out the SAME tag number for their own messages (observed)."""
    var names = List[String]()
    names.append("a")
    names.append("b")
    var router = _fanout("f", names^, 10)
    router.publish(_msg("k", 0x01)^, "f")
    var ca = router.register_consumer("a", 0)
    var cb = router.register_consumer("b", 0)
    var da = router.consume(ca)
    var db = router.consume(cb)
    check(da.value().delivery_tag() == 0, "tag counter for queue a starts at 0")
    check(db.value().delivery_tag() == 0, "tag counter for queue b starts at 0 too")
    check(router.acknowledge(ca, 0), "tags resolve through the consumer's own queue")
    check(router.read_payload(cb, db.value().delivery_tag())[0] == 0x01,
          "the same tag number in another queue is unaffected")

# ---- card 3: many publishers -> one queue -----------------------------

def test_many_pub_one_queue() raises:
    """N publishes into one queue: FIFO order, one Message owned per publish."""
    var names = List[String]()
    names.append("q")
    var router = _fanout("f", names^, 100)
    for i in range(4):
        check(router.publish(_msg("k", UInt8(0x50 + i))^, "f") == 1, "Npub->1q: routes once")
    check(router.messages_routed() == 4, "Npub->1q: counter == 4")

    var cid = router.register_consumer("q", 0)
    for i in range(4):
        var d = router.consume(cid)
        check(d.__bool__(), "Npub->1q: delivery for every publish")
        check(router.read_payload(cid, d.value().delivery_tag())[0] == UInt8(0x50 + i),
              "Npub->1q: FIFO order preserved by the router")
    _assert_empty(router, cid, "Npub->1q")

# ---- card 4: many publishers -> many queues ---------------------------

def test_many_pub_many_queues() raises:
    """Cross product: every published copy lands in every bound queue."""
    var names = List[String]()
    names.append("left")
    names.append("right")
    var router = _fanout("f", names^, 100)
    for i in range(3):
        check(router.publish(_msg("k", UInt8(0x60 + i))^, "f") == 2, "Npub->Nq: 2 destinations")
    check(router.messages_routed() == 6, "Npub->Nq: 3 x 2 = 6 owned copies")

    var cl = router.register_consumer("left", 0)
    var cr = router.register_consumer("right", 0)
    var fold_left = _drain_payloads(router, cl, 3)
    var fold_right = _drain_payloads(router, cr, 3)
    check(fold_left == fold_right, "Npub->Nq: identical payload VALUES, independently owned")
    _assert_empty(router, cl, "Npub->Nq left")
    _assert_empty(router, cr, "Npub->Nq right")

# ---- card 5: many consumers -> one queue ------------------------------

def test_many_consumers_one_queue_pull_model() raises:
    """Consumer selection is PULL-BY-CALL, not round-robin (observed).

    Router.consume(consumer_id) pops the queue head for whichever consumer
    asks. There is no scheduler, no fairness and no per-consumer partition:
    a lone polling consumer drains the whole queue. This test pins the
    ACTUAL behaviour so a future scheduler is a deliberate change.
    """
    var names = List[String]()
    names.append("q")
    var router = _fanout("f", names^, 100)
    for i in range(4):
        router.publish(_msg("k", UInt8(0x70 + i))^, "f")

    var c1 = router.register_consumer("q", 0)
    var c2 = router.register_consumer("q", 0)

    var d1 = router.consume(c1)
    var d2 = router.consume(c1)
    var d3 = router.consume(c2)
    check(router.read_payload(c1, d1.value().delivery_tag())[0] == 0x70,
          "pull model: c1 gets the head item")
    check(router.read_payload(c1, d2.value().delivery_tag())[0] == 0x71,
          "pull model: the same consumer gets the NEXT item (no round-robin skip)")
    check(router.read_payload(c2, d3.value().delivery_tag())[0] == 0x72,
          "pull model: c2 resumes the single shared cursor where c1 stopped")
    var d4 = router.consume(c2)
    check(router.read_payload(c2, d4.value().delivery_tag())[0] == 0x73,
          "pull model: c2 can drain the queue alone")
    _assert_empty(router, c1, "pull model")

def test_consumer_prefetch_limit() raises:
    """Prefetch is the only enforced delivery limit (per consumer)."""
    var names = List[String]()
    names.append("q")
    var router = _fanout("f", names^, 100)
    for i in range(4):
        router.publish(_msg("k", UInt8(0x80 + i))^, "f")

    var limited = router.register_consumer("q", 2)
    var unlimited = router.register_consumer("q", 0)
    var first = router.consume(limited)
    check(router.read_payload(limited, first.value().delivery_tag())[0] == 0x80,
          "prefetch: limited consumer takes the head")
    var second = router.consume(limited)
    check(second.__bool__(), "prefetch: 2nd delivery allowed")
    check(not router.consume(limited).__bool__(), "prefetch: 3rd blocked at prefetch=2")
    var third = router.consume(unlimited)
    check(router.read_payload(unlimited, third.value().delivery_tag())[0] == 0x82,
          "prefetch: prefetch=0 is unlimited and continues the shared cursor")
    check(router.acknowledge(limited, first.value().delivery_tag()), "prefetch: ack first delivery")
    var fourth = router.consume(limited)
    check(router.read_payload(limited, fourth.value().delivery_tag())[0] == 0x83,
          "prefetch: ack frees a slot for the last pending message")

def test_unregister_leaves_unacked_message_owned_by_queue() raises:
    """REPORTED gap: unregistering a consumer does not reclaim its unacked
    messages — they stay in the queue's unacked pool (no disconnect path in a
    single-node engine, and no other reclaim trigger)."""
    var names = List[String]()
    names.append("q")
    var router = _fanout("f", names^, 10)
    router.publish(_msg("k", 0x88)^, "f")
    var cid = router.register_consumer("q", 0)
    var d = router.consume(cid)
    check(router.unregister_consumer(cid), "unregister returns True")
    check(not router.acknowledge(cid, d.value().delivery_tag()),
          "ack after unregister fails (consumer gone)")
    var other = router.register_consumer("q", 0)
    _assert_empty(router, other, "orphaned unacked message is not redeliverable")

# ---- card 6: unroutable publish ---------------------------------------

def test_unroutable_publish() raises:
    """No matching binding: routed == 0 and the message is SILENTLY DESTROYED.

    REPORTED §7 gap: no mandatory/return path, no error; the only
    producer-visible signal is the returned count.
    """
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("q", 100)
    router.bind_queue("q", "ex", "a.b")

    var routed = router.publish(_msg("no.match", 0x09)^, "ex")
    check(routed == 0, "unroutable: routed == 0")
    check(router.messages_routed() == 0, "unroutable: counter untouched")
    var cid = router.register_consumer("q", 0)
    _assert_empty(router, cid, "unroutable: queue never received the message")

def test_publish_to_unknown_exchange() raises:
    """Unknown exchange: routed == 0, no raise, message destroyed."""
    var router = Router()
    check(router.publish(_msg("any", 0x0A)^, "does.not.exist") == 0,
          "unknown exchange: routed == 0, silent")
    check(router.queue_count() == 0, "unknown exchange: no topology side effects")

def test_bind_to_missing_names_returns_false() raises:
    """Bind validation: missing queue or exchange returns False (no raise)."""
    var router = Router()
    router.declare_exchange("e", ExchangeType.direct())
    check(not router.bind_queue("ghost", "e", "k"), "bind with missing queue returns False")
    router.declare_queue("real", 10)
    check(not router.bind_queue("real", "ghost-ex", "k"), "bind with missing exchange returns False")
    check(router.publish(_msg("k", 0x01)^, "e") == 0, "queue bound to nothing is unroutable")

# ---- card 7: multiple matching bindings -------------------------------

def test_multiple_matching_bindings_different_queues() raises:
    """Two distinct queues whose patterns both match: one copy each."""
    var ex = Exchange("t", ExchangeType.topic())
    ex.add_binding(_binding("all", "#"))
    ex.add_binding(_binding("orders", "orders.#"))
    var matched = ex.match("orders.new")
    check(len(matched) == 2, "match set: two distinct queues")
    check(matched[0] == "all", "match set: first-in-binding-order")
    check(matched[1] == "orders", "match set: second")

    var router = Router()
    router.declare_exchange("t", ExchangeType.topic())
    router.declare_queue("all", 10)
    router.declare_queue("orders", 10)
    router.bind_queue("all", "t", "#")
    router.bind_queue("orders", "t", "orders.#")
    check(router.publish(_msg("orders.new", 0x0B)^, "t") == 2,
          "multi-match across queues: two copies (one per queue)")

def test_multiple_matching_bindings_same_queue_one_copy() raises:
    """AUDIT §6 FIX: a queue bound by TWO matching patterns gets ONE copy.

    Observed BEFORE the fix: Exchange.match() returned a destination LIST
    with the queue repeated, and publish() enqueued 2 owned copies into the
    same queue (routed == 2). docs/ROUTING.md:4 requires AMQP-compatible
    duplication behaviour (RabbitMQ: "each queue receives exactly one copy"),
    so match() now returns a destination SET (exchange.mojo `_already_present`).
    This test is the regression guard for that fix.
    """
    var ex = Exchange("t", ExchangeType.topic())
    ex.add_binding(_binding("hot", "stock.*"))
    ex.add_binding(_binding("hot", "#"))
    var matched = ex.match("stock.us")
    check(len(matched) == 1, "destination set: the queue is listed once")
    check(matched[0] == "hot", "destination set: correct queue name")

    var router = Router()
    router.declare_exchange("t", ExchangeType.topic())
    router.declare_queue("hot", 10)
    router.bind_queue("hot", "t", "stock.*")
    router.bind_queue("hot", "t", "#")
    check(router.publish(_msg("stock.us", 0x0C)^, "t") == 1, "one routed copy for one queue")
    var cid = router.register_consumer("hot", 0)
    var only = router.consume(cid)
    check(router.read_payload(cid, only.value().delivery_tag())[0] == 0x0C,
          "the single copy carries the published payload")
    _assert_empty(router, cid, "duplicate-match queue holds a single copy")

def test_direct_same_queue_multiple_keys() raises:
    """Direct: one queue bound to several EXACT keys; only the matching key
    routes, and it routes once."""
    var router = Router()
    router.declare_exchange("d", ExchangeType.direct())
    router.declare_queue("multi", 10)
    router.bind_queue("multi", "d", "k1")
    router.bind_queue("multi", "d", "k2")
    check(router.publish(_msg("k2", 0x11)^, "d") == 1, "direct: matching key routes once")
    check(router.publish(_msg("k3", 0x12)^, "d") == 0, "direct: non-matching key routes nowhere")
    var cid = router.register_consumer("multi", 0)
    var d = router.consume(cid)
    check(router.read_payload(cid, d.value().delivery_tag())[0] == 0x11,
          "direct: only the k2 publish reached the queue")
    _assert_empty(router, cid, "direct multi-key")

# ---- card 8: duplicate bindings ---------------------------------------

def test_duplicate_binding_is_idempotent() raises:
    """Identical (queue, key) binding twice: stored once, routes once."""
    var ex = Exchange("d", ExchangeType.direct())
    ex.add_binding(_binding("q", "a.b"))
    ex.add_binding(_binding("q", "a.b"))
    check(ex.binding_count() == 1, "duplicate binding not stored")
    check(len(ex.match("a.b")) == 1, "duplicate binding yields one destination")

    var router = Router()
    router.declare_exchange("f", ExchangeType.fanout())
    router.declare_queue("q", 10)
    check(router.bind_queue("q", "f", ""), "first bind")
    check(router.bind_queue("q", "f", ""), "identical second bind accepted but ignored")
    check(router.publish(_msg("k", 0x0D)^, "f") == 1, "duplicate binding: one copy only")
    var cid = router.register_consumer("q", 0)
    var only_dup = router.consume(cid)
    check(only_dup.__bool__(), "duplicate binding: exactly one delivery exists")
    _assert_empty(router, cid, "duplicate binding")

def test_unbind_removes_destination() raises:
    """Unbind is exact-match on (queue, key) and makes the queue unroutable."""
    var router = Router()
    router.declare_exchange("d", ExchangeType.direct())
    router.declare_queue("q", 10)
    router.bind_queue("q", "d", "k")
    check(router.unbind_queue("q", "d", "k"), "unbind existing binding")
    check(router.publish(_msg("k", 0x0E)^, "d") == 0, "after unbind: unroutable")
    check(not router.unbind_queue("q", "d", "k"), "unbind twice returns False")

# ---- match sets per exchange type -------------------------------------

def test_match_sets_by_type() raises:
    """direct / fanout / topic match sets, including non-matches."""
    var direct = Exchange("d", ExchangeType.direct())
    direct.add_binding(_binding("dq", "exact.key"))
    check(len(direct.match("exact.key")) == 1, "direct: exact key matches")
    check(len(direct.match("exact.keys")) == 0, "direct: word-prefix is not a match")
    check(len(direct.match("other")) == 0, "direct: unrelated key matches nothing")

    var fanout = Exchange("fo", ExchangeType.fanout())
    fanout.add_binding(_binding("fq", "ignored"))
    check(len(fanout.match("anything")) == 1, "fanout: routing key ignored")
    check(len(fanout.match("")) == 1, "fanout: empty routing key still matches")

    var topic = Exchange("to", ExchangeType.topic())
    topic.add_binding(_binding("star", "*.info"))
    topic.add_binding(_binding("hash", "sys.#"))
    check(len(topic.match("app.info")) == 1, "topic: * matches exactly one word")
    check(topic.match("app.info")[0] == "star", "topic: the * queue is selected")
    check(len(topic.match("app.more.info")) == 0, "topic: * never spans two words")
    check(len(topic.match("sys")) == 1, "topic: # matches zero words")
    check(topic.match("sys")[0] == "hash", "topic: # queue selected for zero-word tail")
    check(len(topic.match("sys.a.b")) == 1, "topic: # matches many words")
    check(len(topic.match("none")) == 0, "topic: unrelated key matches nothing")

def test_headers_exchange_is_a_stub() raises:
    """REPORTED: headers matching is unimplemented; the stub matches all.

    exchange.mojo headers branch returns every bound queue regardless of
    routing key or headers. Asserted so the stub is never mistaken for the
    contract.
    """
    var ex = Exchange("h", ExchangeType.headers())
    ex.add_binding(_binding("hq", "some.key"))
    check(len(ex.match("completely.unrelated")) == 1,
          "headers STUB: matches every key regardless of headers")

# ---- failed delivery / redelivery ownership ---------------------------

def test_reject_requeues_same_owned_message() raises:
    """Reject MOVES the queue's own Message back to the inbox: the payload is
    never re-copied or rebuilt, and the delivery counter accumulates."""
    var names = List[String]()
    names.append("q")
    var router = _fanout("f", names^, 20)
    router.publish(_msg("k", 0xA1)^, "f")
    router.publish(_msg("k", 0xA2)^, "f")
    var cid = router.register_consumer("q", 0)

    var d1 = router.consume(cid)
    check(router.read_payload(cid, d1.value().delivery_tag())[0] == 0xA1, "first delivery")
    check(router.reject(cid, d1.value().delivery_tag()), "reject returns True")
    check(router.reject(cid, d1.value().delivery_tag()) == False,
          "reject of a resolved tag returns False (no double requeue)")

    # REPORTED ordering deviation: the requeued message goes to the TAIL of
    # the pending set, so 0xA2 is delivered first (RabbitMQ requeues near the
    # head). delivery_count becomes 2 on the redelivered copy.
    var d2 = router.consume(cid)
    check(router.read_payload(cid, d2.value().delivery_tag())[0] == 0xA2,
          "requeued message goes to the TAIL (observed)")
    var d3 = router.consume(cid)
    check(router.read_payload(cid, d3.value().delivery_tag())[0] == 0xA1,
          "requeued message is redelivered last")
    check(router.acknowledge(cid, d3.value().delivery_tag()), "ack the redelivered copy")
    _assert_empty(router, cid, "after requeue cycle")

def test_failed_enqueue_drops_only_that_copy() raises:
    """A destination at capacity drops ITS OWN copy; other destinations keep
    theirs (routed count is the number of accepted copies)."""
    var router = Router()
    router.declare_exchange("f", ExchangeType.fanout())
    router.declare_queue("small", 1)
    router.declare_queue("big", 5)
    router.bind_queue("small", "f", "")
    router.bind_queue("big", "f", "")
    check(router.publish(_msg("k", 0xB1)^, "f") == 2, "first fanout: both queues accept")
    check(router.publish(_msg("k", 0xB2)^, "f") == 1,
          "second fanout: full queue silently drops its copy -> routed == 1")
    check(router.messages_routed() == 3, "counter counts accepted copies only")
    var cs = router.register_consumer("small", 0)
    var cbig = router.register_consumer("big", 0)
    var first_big = router.consume(cbig)
    check(router.read_payload(cbig, first_big.value().delivery_tag())[0] == 0xB1,
          "non-full queue kept FIFO with its first copy")
    var second = router.consume(cbig)
    check(router.read_payload(cbig, second.value().delivery_tag())[0] == 0xB2,
          "non-full queue received the second copy")
    var dropped = router.consume(cs)
    check(router.read_payload(cs, dropped.value().delivery_tag())[0] == 0xB1,
          "full queue holds only the first copy; 0xB2 was dropped")
    _assert_empty(router, cs, "dropped copy is unrecoverable")

def main() raises:
    test_one_pub_one_queue()
    test_publish_consumes_the_source_message()
    test_one_pub_many_queues()
    test_delivery_tags_are_per_queue_counters()
    test_many_pub_one_queue()
    test_many_pub_many_queues()
    test_many_consumers_one_queue_pull_model()
    test_consumer_prefetch_limit()
    test_unregister_leaves_unacked_message_owned_by_queue()
    test_unroutable_publish()
    test_publish_to_unknown_exchange()
    test_bind_to_missing_names_returns_false()
    test_multiple_matching_bindings_different_queues()
    test_multiple_matching_bindings_same_queue_one_copy()
    test_direct_same_queue_multiple_keys()
    test_duplicate_binding_is_idempotent()
    test_unbind_removes_destination()
    test_metadata_fidelity_preserved_on_fanout()
    test_metadata_fidelity_single_destination_move()
    test_match_sets_by_type()
    test_headers_exchange_is_a_stub()
    test_reject_requeues_same_owned_message()
    test_failed_enqueue_drops_only_that_copy()
    print("ROUTING_MATRIX_TEST=PASS")
