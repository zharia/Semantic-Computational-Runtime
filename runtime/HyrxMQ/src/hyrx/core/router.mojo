# Central routing engine.
#
# Ties together exchanges, queues, and consumers.
# Routes published messages to queue destinations via exchange matching.
#
# Ownership model:
#   - Router owns all exchanges, queues, and consumers.
#   - publish() COPIES the payload per destination queue (one owned copy
#     per queue); the original Message is consumed by the publish call.
#   - each fan-out destination owns an independent copy of payload bytes (no
#     sharing between queues); message_id, routing_key, and headers are
#     preserved in every per-destination envelope.
#   - consume() returns a Delivery claim token (message stays in queue).
#   - acknowledge() and reject() operate on the queue's message copy.

from std.collections import List
from std.time import monotonic

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import Exchange, ExchangeType, Binding
from hyrx.core.queue import Queue, QueueConfig, Delivery
from hyrx.core.consumer import Consumer
from hyrx.core.buffer_pool import BufferPool
from hyrx.core.pool_stats import PoolStats
from hyrx.core.storage import (
    MessageJournal,
    RecoveryBuilder,
    props_delivery_mode,
)


# Upper bound on exchange→exchange chain hops walked by one publish
# (Router._expand_chain). The AMQP spec permits cyclic exchange.bind graphs;
# the depth cap + seen-list replaces an unbounded recursion (fail closed:
# deeper chains are simply not further routed past the cap).
def _MAX_CHAIN_DEPTH() -> Int:
    return 16


def _router_dedup_append(
    mut dest: List[String], var name: String
) -> Bool:
    """Append `name` when absent (destination-set semantics). True if appended."""
    for i in range(len(dest)):
        if dest[i] == name:
            return False
    dest.append(name^)
    return True


struct Router:
    """Core routing engine. Routes published messages to queue destinations."""

    # _pool is declared FIRST so, under Mojo's reverse-order field deinit, it is
    # torn down AFTER _queues: the pool must outlive every queue whose messages may
    # release pooled buffers back into it (p1b invariant R6). Owned here, not by the
    # engine, so Router is the single component that acquires/releases buffers and
    # Queue never needs a borrow of the pool (avoids disjoint-mutable-borrow issues).
    var _pool: BufferPool
    var _pool_enabled: Bool
    var _exchanges: Dict[String, Exchange]
    var _queues: Dict[String, Queue]
    var _consumers: Dict[UInt64, Consumer]
    var _next_consumer_id: UInt64
    var _messages_routed: Int
    # Reverse indexes (0017 T1, additive):
    #   _queue_consumers: cid-per-queue index so queue.delete (50,40) can
    #     unregister every consumer on the deleted queue without a Dict of
    #     non-Copyable values needing iteration.
    #   _exchange_index: declared exchange names, so exchange.delete (40,20)
    #     can drop E2E bindings pointing at the deleted exchange.
    var _queue_consumers: Dict[String, List[UInt64]]
    var _exchange_index: List[String]
    # 0018: the injected storage journal (the DEFAULT tier is DISABLED — no
    # storage class activity of any kind). Every fs byte flows through the
    # journal's own FileSystemOps; the Router itself touches no file.
    var _journal: MessageJournal
    # 0018: the recovery materialization's recursion flag — no journal write
    # may fire for a recovered entity (an EXISTS check would otherwise
    # re-journal each declare inside the replay).
    var _recovering: Bool

    def __init__(out self):
        self._pool = BufferPool(4096, 64)
        self._pool_enabled = False
        self._exchanges = Dict[String, Exchange]()
        self._queues = Dict[String, Queue]()
        self._consumers = Dict[UInt64, Consumer]()
        self._next_consumer_id = 0
        self._messages_routed = 0
        self._queue_consumers = Dict[String, List[UInt64]]()
        self._exchange_index = List[String]()
        self._journal = MessageJournal()
        self._recovering = False

    def __init__(
        out self, max_class: Int, max_pooled: Int, pool_enabled: Bool
    ):
        self._pool = BufferPool(max_class, max_pooled)
        self._pool_enabled = pool_enabled
        self._exchanges = Dict[String, Exchange]()
        self._queues = Dict[String, Queue]()
        self._consumers = Dict[UInt64, Consumer]()
        self._next_consumer_id = 0
        self._messages_routed = 0
        self._queue_consumers = Dict[String, List[UInt64]]()
        self._exchange_index = List[String]()
        self._journal = MessageJournal()
        self._recovering = False

    # ---- 0018: pluggable storage (the single fs seam stays injected) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the (pre-validated) storage journal.

        The Router NEVER opens/reads/truncates a file itself: every record
        routes through the journal, whose write path is either the RAM WAL
        (memory tier) or the SUPPLIED FileSystemOps (file tier)."""
        self._journal = journal^

    def journal_mode(ref self) -> Int:
        """The active storage mode (0=disabled default)."""
        return self._journal.mode()

    def journal_pages_copy(ref self) raises -> List[UInt8]:
        """Owned copy of the journal's RAM pages (a fresh-engine recovery
        fixture for the test harness; the disabled tier yields empty)."""
        return self._journal.mem_pages()

    def _journalize_enqueue(mut self, var qname: String, ref msg: Message) raises -> Int:
        """WRITE-AHEAD the MSG record for a durable-queue publish with
        delivery_mode=2 and STAMP the message with the journal seq.

        Skips: the disabled tier, a non-durable destination, a transient
        (delivery_mode != 2) publish, a recovery materialization. Returns
        the seq (record ordinal) or -1."""
        if self._recovering or not self._journal.enabled():
            return -1
        if qname not in self._queues:
            return -1
        if not self._queues[qname].durable():
            return -1
        var pflags = msg.content_prop_flags()
        var pbytes = msg.content_prop_bytes_copy()
        if props_delivery_mode(pflags, pbytes^) != 2:
            return -1
        var payload = msg.payload().to_bytes()
        var seq = self._journal.write_enqueue(
            qname^, msg.routing_key(), pflags, pbytes^, payload^,
            msg.enqueue_ns(),
        )
        return seq

    def _journalize_tombstone(mut self, seq: Int, kind: Int) raises:
        """Write a tombstone: 0=ACK (the delivery state goes fresh-empty),
        1=REDELIVER bump (requeue acceptance), 2=REMOVE (an expiry /
        dead-letter / purge-drop outcome must not resurrect)."""
        if seq < 0:
            return
        if self._recovering or not self._journal.enabled():
            return
        if kind == 0:
            _ = self._journal.write_ack(seq)
        elif kind == 1:
            _ = self._journal.write_redeliver(seq)
        else:
            _ = self._journal.write_remove(seq)

    @staticmethod
    def _TOMB_ACK() -> Int:
        return 0

    @staticmethod
    def _TOMB_REDELIVER() -> Int:
        return 1

    @staticmethod
    def _TOMB_REMOVE() -> Int:
        return 2

    def _journalize_seqs(mut self, qname: String, var seqs: List[Int], kind: Int) raises:
        """Tombstone every journal seq in the list (bulk resolution order)."""
        if self._recovering or not self._journal.enabled():
            while len(seqs) > 0:
                _ = seqs.pop()
            return
        while len(seqs) > 0:
            var seq = seqs.pop(0)
            self._journalize_tombstone(seq, kind)

    # ---- 0018: journal recovery ----------------------------------------

    def recover(mut self) raises -> Int:
        """Replay the injected journal and materialize the recovered engine.

        Ordered replay through the RecoveryBuilder: durable queues (+ the
        decoded x-args), exchanges, bindings, still-live persistent messages
        (every tombstoned seq already resolved), and finally the recovered
        messages with the redelivered approximation (delivery_count >= 1 so
        the FIRST recovered dequeue carries the AMQP redelivered bit).

        ZERO journal writes fire during the materialization (the recovery
        flag gates the write hooks). Recovered messages bypass the capacity
        preflight/x-max-length trim (the next publish-side enqueue
        reasserts them — the LIMITS note). Returns the recovered message
        count."""
        self._recovering = True
        var parsed = self._journal.replay()
        var builder = RecoveryBuilder()
        builder.apply(parsed^)
        var topo = builder.finalize()
        # exchanges first (bindings need them)
        var total_ex = len(topo.exchanges)
        for i in range(total_ex):
            var name = topo.exchanges[i].name.copy()
            var tcode = topo.exchanges[i].type_code
            if name not in self._exchanges:
                var etype = ExchangeType(tcode)
                self._exchange_index.append(name.copy())
                var key = name.copy()
                self._exchanges[key] = Exchange(key, etype^)
        # queues (last-declare configuration wins)
        var total_q = len(topo.queues)
        for i in range(total_q):
            var qname = topo.queues[i].name.copy()
            if qname not in self._queues:
                if topo.queues[i].durable:
                    var cfg = QueueConfig(topo.queues[i].capacity)
                    cfg._durable = True
                    cfg._ttl_ms = topo.queues[i].ttl_ms
                    cfg._max_length = topo.queues[i].max_length
                    cfg._overflow_reject = topo.queues[i].overflow_reject
                    cfg._dlx = topo.queues[i].dlx.copy()
                    cfg._dlrk = topo.queues[i].dlrk.copy()
                    self._queues[qname^] = Queue(qname, cfg^)
        # bindings (both endpoints must exist)
        var total_b = len(topo.bindings)
        for i in range(total_b):
            var dest = topo.bindings[i].destination.copy()
            var exn = topo.bindings[i].exchange.copy()
            var rk = topo.bindings[i].routing_key.copy()
            if topo.bindings[i].e2e:
                if dest in self._exchanges and exn in self._exchanges:
                    var bargs = Dict[String, String]()
                    var bbinding = Binding(dest, rk^, bargs^)
                    self._exchanges[exn].add_exchange_binding(bbinding^)
            else:
                if dest in self._queues and exn in self._exchanges:
                    var qargs = Dict[String, String]()
                    var qbinding = Binding(dest, rk^, qargs^)
                    self._exchanges[exn].add_binding(qbinding^)
        # recovered messages: fresh inbox entries with the recovered
        # redelivered state
        var recovered = topo.recovered_messages
        for i in range(total_q):
            var qname = topo.queues[i].name
            if qname not in self._queues:
                continue
            var jm = len(topo.queues[i].msgs)
            for j in range(jm):
                var rk = topo.queues[i].msgs[j].routing_key.copy()
                var flags = topo.queues[i].msgs[j].prop_flags
                var pb = topo.queues[i].msgs[j].prop_bytes.copy()
                var pay = topo.queues[i].msgs[j].payload.copy()
                var bump = topo.queues[i].msgs[j].bumps
                var seqv = topo.queues[i].msgs[j].seq
                var env = Envelope(
                    MessageID(0), rk^, Dict[String, String]()
                )
                var buf = Buffer(len(pay))
                buf.resize(len(pay))
                for k in range(len(pay)):
                    buf[k] = pay[k]
                var msg = Message(env^, buf^, flags, pb^)
                msg.set_storage_seq(Int(seqv))
                msg.set_delivery_count(1 + bump)
                msg.set_enqueue_ns(monotonic())
                self._queues[qname].recover_message(msg^)
        self._recovering = False
        return recovered

    def pool_stats(ref self) -> PoolStats:
        """Pool allocation snapshot (surfaced via the engine's stats())."""
        return self._pool.stats()

    # ---- exchange management ------------------------------------------

    def declare_exchange(
        mut self, var name: String, var exchange_type: ExchangeType
    ) raises -> Bool:
        """Declare an exchange. Returns True if created, False if exists."""
        if name in self._exchanges:
            return False
        # 0018: read the type code BEFORE the Exchange consumes it; the
        # declared exchange is recorded when the journal runs (topology
        # recovery; a redeclare is a no-op — no record).
        var tcode = 0
        if exchange_type == ExchangeType.fanout():
            tcode = 1
        elif exchange_type == ExchangeType.topic():
            tcode = 2
        elif exchange_type == ExchangeType.headers():
            tcode = 3
        if not self._recovering:
            _ = self._journal.write_exchange_declare(name.copy(), tcode)
        self._exchange_index.append(name.copy())
        var key = name.copy()
        self._exchanges[key] = Exchange(key, exchange_type^)
        return True

    def delete_exchange(mut self, name: String) raises -> Bool:
        """Delete an exchange. Returns True if found and deleted.

        Also drops every exchange→exchange binding pointing AT the deleted
        exchange (40,20 normative reachability: after deletion the deleted
        exchange must be unroutable from any surviving chain).
        """
        if name in self._exchanges:
            _ = self._exchanges.pop(name)
            var i = 0
            while i < len(self._exchange_index):
                if self._exchange_index[i] == name:
                    _ = self._exchange_index.pop(i)
                else:
                    i += 1
            for j in range(len(self._exchange_index)):
                var other = self._exchange_index[j].copy()
                if other in self._exchanges:
                    _ = self._exchanges[other].remove_exchange_bindings_to(
                        name.copy()
                    )
            return True
        return False

    # ---- queue management ---------------------------------------------

    def declare_queue(
        mut self, var name: String, capacity: Int
    ) raises -> Bool:
        """Declare a queue. Returns True if created, False if exists."""
        if name in self._queues:
            return False
        self._queues[name^] = Queue(name, QueueConfig(capacity))
        return True

    # 0017 T3: full declare-arg translation (the AMQP-side arguments are
    # decoded in the service and translated here ONCE). durable is stored as
    # a FLAG only (in-memory; real persistence = milestone 0018).
    def declare_queue_full(
        mut self,
        var name: String,
        capacity: Int,
        durable: Bool,
        ttl_ms: Int,
        expires_ms: Int,
        max_length: Int,
        overflow_reject: Bool,
        var dlx: String,
        var dlrk: String,
    ) raises -> Bool:
        """Declare a queue carrying the decoded AMQP declare arguments.

        x-expires (`expires_ms`) is recorded for the service's LAZY expiry
        (no timer subsystem exists in this engine slice; the service
        evaluates last-activity on next access). Returns True if created,
        False if the queue exists (the service answers the 406/405 table)."""
        _ = expires_ms
        if name in self._queues:
            return False
        if durable and not self._recovering:
            # 0018: WRITE-AHEAD the durable DECLARE_QUEUE (+ x-args) record
            # before the declare consumes the strings.
            _ = self._journal.write_queue_declare(
                name.copy(), durable, capacity, ttl_ms, max_length,
                overflow_reject, dlx.copy(), dlrk.copy(),
            )
        var cfg = QueueConfig(capacity)
        cfg._durable = durable
        cfg._ttl_ms = ttl_ms
        cfg._max_length = max_length
        cfg._overflow_reject = overflow_reject
        cfg._dlx = dlx^
        cfg._dlrk = dlrk^
        self._queues[name^] = Queue(name, cfg^)
        return True

    def delete_queue(mut self, name: String) raises -> List[Message]:
        """Delete a queue, reclaiming its live payloads into the pool.

        The popped Queue would otherwise cascade-destroy its Messages on drop and
        permanently strand any pool-acquired payload buffers (starvation). We drain
        every owned Message and release its payload Buffer (a no-op for non-pooled
        direct/moved buffers). Returns an empty list (messages were reclaimed).
        """
        var result = List[Message]()
        if name in self._queues:
            var q = self._queues.pop(name)
            var drained = q.drain_messages()
            while len(drained) > 0:
                var m = drained.pop()
                var buf = m.take_payload()
                self._pool.release(buf^)
            # 0018: the queue deletion is journaled (its messages + bindings
            # drop with it on recovery).
            _ = self._journal.write_delete_queue(name.copy())
        return result^

    # ---- binding management -------------------------------------------

    def bind_queue(
        mut self,
        queue_name: String,
        exchange_name: String,
        var routing_key: String,
    ) raises -> Bool:
        """Bind a queue to an exchange with a routing key pattern.

        Returns True if bound, False if queue or exchange not found.
        """
        if queue_name not in self._queues:
            return False
        if exchange_name not in self._exchanges:
            return False
        # 0018: bindings of DURABLE queues are journaled (the recovered
        # binding becomes a no-op when the queue was not durable) — written
        # BEFORE the Binding consumes the routing key.
        if not self._recovering and queue_name in self._queues:
            if self._queues[queue_name].durable():
                _ = self._journal.write_bind(
                    exchange_name.copy(), queue_name.copy(),
                    routing_key.copy(), False,
                )
        var args = Dict[String, String]()
        var binding = Binding(queue_name, routing_key^, args^)
        self._exchanges[exchange_name].add_binding(binding^)
        return True

    def unbind_queue(
        mut self,
        queue_name: String,
        exchange_name: String,
        routing_key: String,
    ) raises -> Bool:
        """Unbind a queue from an exchange.

        Returns True if unbound, False if not found.

        Ownership: the Binding (and its routing-key/pattern strings) is
        destroyed on removal; queue and exchange objects are untouched.

        NOTE: declared `raises` because the exchange lookup can raise
        DictKeyError. BUG FIXED HERE (audit §6): the signature omitted
        `raises`, so the function could not compile when called at all —
        it had no call sites and was therefore never exercised
        (tests/phase2/routing_matrix_test.mojo now covers it).
        """
        if exchange_name not in self._exchanges:
            return False
        return self._exchanges[exchange_name].remove_binding(
            queue_name, routing_key
        )

    # ---- publishing ---------------------------------------------------

    # 0017 T3: the DEFAULT exchange ("") routing — publish DIRECT to the
    # queue named by the routing key (amqp0-9-1 normative: the default
    # exchange is a direct exchange pre-bound to every queue by its name).
    # Before this slice the "" exchange routed to zero queues (needs-probe
    # resolved here).

    def publish_to_queue(
        mut self, var msg: Message, var queue_name: String
    ) raises -> Int:
        """Route ONE message DIRECT into a named queue (the default
        exchange's pre-bound direct binding: exchange="" publishes to the
        queue named by the routing key).

        Returns 0 when the queue is missing (silently unrouted — the
        mandatory=1 wire path composes the basic.return; normative)."""
        if queue_name not in self._queues:
            var buf = msg.take_payload()
            self._pool.release(buf^)
            return 0
        msg.set_enqueue_ns(monotonic())
        if self._queues[queue_name].has_capacity():
            # 0018: WRITE-AHEAD the durable MSG record (a skipped journal
            # keeps the enqueue path untouched — the disabled tier stays
            # byte-identical).
            var journal_seq = self._journalize_enqueue(queue_name, msg)
            if journal_seq >= 0:
                msg.set_storage_seq(journal_seq)
            self._queues[queue_name].enqueue_prechecked(msg^)
            self._reap_queue(queue_name.copy())
            self._messages_routed += 1
            return 1
        var buf = msg.take_payload()
        self._pool.release(buf^)
        return 0

    # 0017 T1 additions (additive APIs — no existing method replaced):
    #
    # Purpose map (amqp0-9-1 method → Router entry point):
    #   queue.purge (50,30)          → purge_queue
    #   queue.delete (50,40)         → delete_queue_checked (sentinel returns)
    #   exchange.delete (40,20)      → delete_exchange_checked
    #   basic.ack multiple=true      → bulk_ack
    #   basic.nack (60,120)          → nack / nack_through
    #   exchange.bind (40,30)        → bind_exchange
    #   exchange.unbind (40,40)      → unbind_exchange
    #   consumer dereg (channel close)→ unregister_consumer (existed)

    def has_queue(ref self, var name: String) -> Bool:
        """Whether a queue with this name is declared (11 T1 404 preflight)."""
        return name in self._queues

    def has_exchange(ref self, var name: String) -> Bool:
        """Whether an exchange with this name is declared (404 preflight)."""
        return name in self._exchanges

    # ---- 0017 T3 readouts (declare-ok parity + service preflights) ----

    def queue_depth(ref self, var name: String) -> Int:
        """Ready message depth of a queue (declare-ok message-count). -1
        when the queue is missing (the service answers 404)."""
        if name not in self._queues:
            return -1
        try:
            return self._queues[name].depth()
        except:
            return -1

    def queue_consumer_count(ref self, var name: String) -> Int:
        """Number of live consumers on a queue (declare-ok consumer-count).
        -1 when the queue is missing."""
        if name not in self._queues:
            return -1
        if name not in self._queue_consumers:
            return 0
        try:
            return len(self._queue_consumers[name])
        except:
            return 0

    def exchange_type_of(ref self, var name: String) -> String:
        """An existing exchange's type name (declare/passive equivalence
        check). "" = missing exchange."""
        if name not in self._exchanges:
            return ""
        var t = ExchangeType(-1)
        try:
            t = self._exchanges[name].exchange_type()
        except:
            return ""
        if t == ExchangeType.direct():
            return "direct"
        if t == ExchangeType.fanout():
            return "fanout"
        if t == ExchangeType.topic():
            return "topic"
        if t == ExchangeType.headers():
            return "headers"
        return "direct"

    def exchange_binding_total(ref self, var name: String) -> Int:
        """Total bindings on an exchange (queue + exchange→exchange). Used
        for the exchange auto-delete (delete on the LAST unbind). -1 when
        the exchange is missing."""
        if name not in self._exchanges:
            return -1
        try:
            return (
                self._exchanges[name].binding_count()
                + self._exchanges[name].exchange_binding_count()
            )
        except:
            return -1

    # ---- 0017 T3: dead-lettering ----

    def _dead_letter_one(mut self, var qname: String, var msg: Message) raises:
        """Route ONE reaped message through its queue's DLX (or drop it).

        0018: the YES tombstone journal: the removal marker (a requeued-
        removal marker verbatim) so a recovery never resurrects the reaped
        message while it lived on this queue. The DLX reroute below is a
        separate publish — a DURABLE DLX destination automatically journals
        its own fresh MSG record.

        x-dead-letter-routing-key overrides the ORIGINAL routing key when
        set; the message keeps its byte-faithful content props. With no DLX
        the message is dropped (payload released to the pool). Publish
        routing is the ONE authority — the DLX is just another exchange."""
        self._journalize_tombstone(msg.storage_seq(), self._TOMB_REMOVE())
        var dlx = self._queues[qname]._config.dlx_exchange()
        if len(dlx.bytes()) == 0:
            var buf = msg.take_payload()
            self._pool.release(buf^)
            _ = qname  # consumed only via the queue lookup above
            return
        var dlrk = self._queues[qname]._config.dlx_routing_key()
        var rk = dlrk
        if len(rk.bytes()) == 0:
            rk = msg.routing_key()
        var env = Envelope(MessageID(0), rk.copy(), msg.headers())
        var flags = msg.content_prop_flags()
        var pbytes = msg.content_prop_bytes_copy()
        var payload = msg.take_payload()
        var dead_msg = Message(env^, payload^, flags, pbytes^)
        _ = self.publish(dead_msg^, dlx^)

    def _reap_queue(mut self, var qname: String) raises:
        """Drain and resolve every message the queue reaped on its own
        (TTL-expired at delivery / x-max-length drop-head trimming)."""
        if qname not in self._queues:
            return
        var dead = self._queues[qname].take_swept()
        while len(dead) > 0:
            var m = dead.pop()
            self._dead_letter_one(qname.copy(), m^)

    def purge_queue(mut self, var name: String) raises -> Int:
        """Drop every READY message of a queue; unacked STAY (queue.purge 50,30).

        Returns the number purged, or -1 when the queue is missing
        (caller turns that into the 404 channel error). Purged payloads are
        released into the router's pool.
        """
        if name not in self._queues:
            return -1
        var msgs = self._queues[name].purge_ready()
        var n = len(msgs)
        while len(msgs) > 0:
            var m = msgs.pop()
            var buf = m.take_payload()
            self._pool.release(buf^)
        # 0018: the purge tombstone (a recovered purge state does not
        # resurrect the purged set again).
        if n > 0:
            _ = self._journal.write_purge(name.copy())
        return n

    # delete_queue_checked sentinels (negative = refused, no side effects):
    #   -1  queue missing           → channel 404 NOT_FOUND
    #   -2  if_empty violated       → channel 406 PRECONDITION_FAILED
    #   -3  if_unused violated      → channel 406 PRECONDITION_FAILED
    def delete_queue_checked(
        mut self, var name: String, if_empty: Bool, if_unused: Bool
    ) raises -> Int:
        """queue.delete (50,40) with if-empty / if-unused checks.

        Success: unregisters every consumer on the queue and deletes it
        (ready + unacked drained, payloads released to the pool). Returns the
        number of deleted messages (= the delete-ok purged-message-count), or
        one of the negative sentinels above.
        """
        if name not in self._queues:
            return -1
        if if_unused and name in self._queue_consumers:
            var cids = self._queue_consumers[name].copy()
            if len(cids) > 0:
                return -3
        var pending = self._queues[name].depth() + self._queues[name].unacked_count()
        if if_empty and pending > 0:
            return -2
        if name in self._queue_consumers:
            var cids = self._queue_consumers.pop(name)
            for i in range(len(cids)):
                _ = self._consumers.pop(cids[i])
        var q = self._queues.pop(name)
        var drained = q.drain_messages()
        var n = len(drained)
        while len(drained) > 0:
            var m = drained.pop()
            var buf = m.take_payload()
            self._pool.release(buf^)
        # 0018: DELETE_QUEUE tombstone (bindings vanish with the queue).
        _ = self._journal.write_delete_queue(name.copy())
        return n

    # delete_exchange_checked sentinels:
    #   -1 exchange missing         → channel 404 NOT_FOUND
    #   -2 if_unused violated       → channel 406 PRECONDITION_FAILED
    def delete_exchange_checked(mut self, var name: String, if_unused: Bool) raises -> Int:
        """exchange.delete (40,20) with the if-unused check.

        "In use" = at least one binding exists on the exchange (queue-binding
        or exchange→exchange binding). Returns 1 when deleted, sentinels
        otherwise. Part of the delete's side effects (unbinding from every
        surviving chain) lives in delete_exchange.
        """
        if name not in self._exchanges:
            return -1
        if if_unused and self._exchanges[name].binding_count() + self._exchanges[name].exchange_binding_count() > 0:
            return -2
        _ = self.delete_exchange(name.copy())
        # 0018: the exchange deletion is journaled.
        _ = self._journal.write_exchange_delete(name.copy())
        return 1

    def bind_exchange(
        mut self,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """exchange.bind (40,30): bind destination exchange onto source.

        Messages published to `source` under `routing_key` are routed onward
        INTO `destination`. False when source or destination is missing (the
        caller answers 404). The binding lives on the SOURCE exchange
        (add_exchange_binding with destination as the Binding queue_name).
        """
        if source not in self._exchanges:
            return False
        if destination not in self._exchanges:
            return False
        # 0018: the E2E binding is journaled (e2e=1 record flag) BEFORE the
        # Binding consumes the routing key.
        _ = self._journal.write_bind(
            source.copy(), destination.copy(), routing_key.copy(), True,
        )
        var args = Dict[String, String]()
        var binding = Binding(destination, routing_key^, args^)
        self._exchanges[source].add_exchange_binding(binding^)
        return True

    def unbind_exchange(
        mut self,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """exchange.unbind (40,40). True if the exact binding was removed."""
        if source not in self._exchanges:
            return False
        return self._exchanges[source].remove_exchange_binding(
            destination.copy(), routing_key
        )

    # ---- bulk kinds of amqp basic.ack / basic.nack (60,80 / 60,120) ----

    def bulk_ack(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Int:
        """Ack up to AND INCLUDING delivery_tag (multiple=true).

        tag == 0 means "all outstanding deliveries" (AMQP: with multiple,
        tag 0 acknowledges every unacked on the channel → UInt64 max here).
        Returns the number acknowledged; buffers released to the pool.
        """
        if consumer_id not in self._consumers:
            return 0
        var upper = delivery_tag
        if upper == 0:
            upper = UInt64(18446744073709551615)
        var qname = self._consumers[consumer_id].queue_name()
        if qname not in self._queues:
            return 0
        # 0018: journal every ACK tombstone BEFORE the reclaim destroys the
        # delivery states.
        var seqs = self._queues[qname].ack_seqs_through(upper)
        self._journalize_seqs(qname^, seqs^, self._TOMB_ACK())
        var bufs = self._queues[qname].ack_reclaim_through(upper)
        var n = len(bufs)
        while len(bufs) > 0:
            var buf = bufs.pop()
            self._pool.release(buf^)
        self._consumers[consumer_id].record_ack()
        return n

    def nack(
        mut self, consumer_id: UInt64, delivery_tag: UInt64, requeue: Bool
    ) raises -> Bool:
        """basic.nack single-tag (60,120): requeue OR drop the delivery.

        requeue=True  → reject() semantics (message requeued; the
                        per-message delivery counter bumps on its next
                        dequeue = the redelivery counter).
        requeue=False → the message is DESTROYED unless a dead-letter
                        exchange argument exists (x-dead-letter-exchange
                        routing lands in 0017 T3; T1 drops).
        Returns True if the delivery resolved.
        """
        if consumer_id not in self._consumers:
            return False
        var qname = self._consumers[consumer_id].queue_name()
        if qname not in self._queues:
            return False
        var journal_seq = self._queues[qname].persist_seq_of(delivery_tag)
        var result = False
        if requeue:
            result = self._queues[qname].reject(delivery_tag)
        elif self._queues[qname].has_unacked(delivery_tag):
            # 0017 T3: requeue=false is DROP first, but a queue carrying
            # x-dead-letter-exchange dead-letters the message instead (the
            # byte-faithful body + props reroute through the DLX Exchange).
            var msg = self._queues[qname].take_unacked(delivery_tag)
            self._dead_letter_one(qname.copy(), msg^)
            result = True
        if result:
            # 0018: a requeued requeue acceptance is REDELIVER; a drop is
            # tombstoned inside _dead_letter_one (REMOVE).
            if requeue:
                self._journalize_tombstone(
                    journal_seq, self._TOMB_REDELIVER()
                )
            self._consumers[consumer_id].record_ack()
        return result

    def nack_through(
        mut self, consumer_id: UInt64, delivery_tag: UInt64, requeue: Bool
    ) raises -> Int:
        """basic.nack multiple=true (60,120): resolve every tag <= tag.

        tag == 0 → all outstanding (same rule as bulk_ack). Tag order holds
        (Queue resolves in _unacked_tags order = order of tags). Requeue=
        True requeues; False drops (payloads to the pool). Returns the count.
        """
        if consumer_id not in self._consumers:
            return 0
        var upper = delivery_tag
        if upper == 0:
            upper = UInt64(18446744073709551615)
        var qname = self._consumers[consumer_id].queue_name()
        if qname not in self._queues:
            return 0
        # 0018: journal the REDELIVER bumps BEFORE the requeue moves the
        # unacked set.
        var seqs = self._queues[qname].ack_seqs_through(upper)
        var n = 0
        if requeue:
            self._journalize_seqs(qname^, seqs^, self._TOMB_REDELIVER())
            n = self._queues[qname].requeue_unacked_through(upper)
        else:
            # 0017 T3: requeue=false → dead-letter through the DLX when the
            # queue declares one (whole messages, ack-order), else drop.
            var msgs = self._queues[qname].take_unacked_through(upper)
            n = len(msgs)
            while len(msgs) > 0:
                var m = msgs.pop()
                self._dead_letter_one(qname.copy(), m^)
        self._consumers[consumer_id].record_ack()
        return n

    def publish(
        mut self, var msg: Message, exchange_name: String
    ) raises -> Int:
        """Route a message through an exchange to bound queues.

        Builds one owned Message per destination queue: the routing key is
        copied and the payload bytes are COPIED per destination (no payload
        buffer is shared between queues).

        Returns the number of queues the message was actually routed to,
        i.e. the number of destinations whose enqueue() accepted the copy:
        a destination at capacity silently drops its copy (audit §7).

        Ownership: msg is consumed (destroyed after routing). Each queued
        copy is owned by its destination Queue from enqueue() onwards.
        """
        if exchange_name not in self._exchanges:
            return 0

        # 0017 T3: stamp the source message once (x-message-ttl ages from
        # enqueue; fan-out copies receive the same stamp below).
        msg.set_enqueue_ns(monotonic())

        # Get routing key (borrows from msg, does not consume).
        var queue_names = self._exchanges[exchange_name].match(
            msg.routing_key()
        )
        # Exchange→exchange chain expansion (exchange.bind, 40,30): when the
        # source has E2E bindings for this routing key, walk them (bounded,
        # cycle-guarded) and merge every reachable queue destination into the
        # destination set. With no E2E bindings this is a no-op and the
        # behavior below is byte-identical to before (additive rule).
        var chained = False
        if self._exchanges[exchange_name].exchange_binding_count() > 0:
            chained = True
            var merged = List[String]()
            var seen = List[String]()
            for i in range(len(queue_names)):
                var qn = queue_names[i]
                if not _router_dedup_append(merged, qn):
                    continue
            var frontier = List[String]()
            frontier.append(exchange_name.copy())
            var depth = 0
            while len(frontier) > 0 and depth < _MAX_CHAIN_DEPTH():
                var next_frontier = List[String]()
                for i in range(len(frontier)):
                    var src = frontier[i]
                    if src not in self._exchanges:
                        continue
                    var outgoing = self._exchanges[src].match(msg.routing_key())
                    for j in range(len(outgoing)):
                        _ = _router_dedup_append(merged, outgoing[j].copy())
                    var downstream = self._exchanges[src].match_exchanges(msg.routing_key())
                    for j in range(len(downstream)):
                        var d = downstream[j].copy()
                        if d == src:
                            continue
                        var fresh = True
                        for k in range(len(merged)):
                            if merged[k] == d:
                                fresh = False
                                break
                        for k in range(len(seen)):
                            if seen[k] == d:
                                fresh = False
                        if fresh:
                            _ = _router_dedup_append(seen, d.copy())
                            next_frontier.append(d.copy())
                frontier = next_frontier^
                depth += 1
            queue_names = merged^
        var count = 0

        # A single eligible queue can receive the consumed source Message
        # directly. Preflight is non-consuming; Queue and Router are
        # single-threaded, so this immediate enqueue cannot be displaced.
        var eligible_count = 0
        var only_queue = String("")
        for i in range(len(queue_names)):
            if queue_names[i] in self._queues:
                eligible_count += 1
                only_queue = queue_names[i]
        if (
            eligible_count == 1
            and self._queues[only_queue].has_capacity()
        ):
            var journal_seq = self._journalize_enqueue(only_queue, msg)
            if journal_seq >= 0:
                msg.set_storage_seq(journal_seq)
            self._queues[only_queue].enqueue_prechecked(msg^)
            self._reap_queue(only_queue.copy())
            self._messages_routed += 1
            return 1

        var payload_len = msg.payload_size()
        # 0017 T2: byte-faithful content props ride into EVERY destination
        # copy (read once, copied per destination fan-out).
        var prop_flags = msg.content_prop_flags()
        # 0017 T3: the monotonic enqueue stamp rides with the source source
        # message AND each fan-out copy (x-message-ttl ages from enqueue).
        var stamp_ns = monotonic()
        msg.set_enqueue_ns(stamp_ns)
        for i in range(len(queue_names)):
            var qname = queue_names[i]
            # Preflight capacity so we never acquire a pooled buffer for a
            # destination that would drop it (a full destination is silently
            # skipped here, matching the old enqueue-returns-False outcome).
            if qname in self._queues and self._queues[qname].has_capacity():
                var env = Envelope(
                    msg.message_id(), msg.routing_key(), msg.headers()
                )
                var payload = self._fill_destination(msg, payload_len)
                var props_copy = msg.content_prop_bytes_copy()
                var cloned = Message(
                    env^, payload^, prop_flags,
                    props_copy^,
                )
                cloned.set_enqueue_ns(stamp_ns)
                # 0018: WRITE-AHEAD the durable MSG record per destination.
                var jseq = self._journalize_enqueue(qname, cloned)
                if jseq >= 0:
                    cloned.set_storage_seq(jseq)
                self._queues[qname].enqueue_prechecked(cloned^)
                count += 1

        self._messages_routed += count
        for i in range(len(queue_names)):
            self._reap_queue(queue_names[i].copy())
        return count

    def _fill_destination(
        mut self, ref msg: Message, n: Int
    ) raises -> Buffer:
        """Produce one owned payload Buffer for a fan-out destination.

        With the pool enabled, acquire a (reused) buffer from the pool and fill it
        in a single pass via `payload_into`; otherwise fall back to the WP-B direct
        `payload_copy`. Both paths do exactly one byte-copy pass, so enabling the
        pool changes allocation reuse, not copy count (no regression either way).
        """
        if self._pool_enabled:
            var pooled = self._pool.acquire(n)
            return msg.payload_into(pooled^)
        return msg.payload_copy()

    # ---- consumer management ------------------------------------------

    def register_consumer(
        mut self, queue_name: String, prefetch: Int
    ) raises -> UInt64:
        """Register a consumer on a queue.

        Returns the consumer_id. Raises if queue not found.
        """
        if queue_name not in self._queues:
            raise "register_consumer: queue not found: " + queue_name
        var cid = self._next_consumer_id
        self._next_consumer_id += 1
        self._consumers[cid] = Consumer(cid, queue_name, prefetch)
        self._index_consumer(queue_name, cid)
        return cid

    def _index_consumer(mut self, var queue_name: String, cid: UInt64) raises:
        """Additive reverse-index upkeep: cid appended under its queue name."""
        var lst = List[UInt64]()
        if queue_name in self._queue_consumers:
            lst = self._queue_consumers[queue_name].copy()
        lst.append(cid)
        self._queue_consumers[queue_name] = lst^

    def _deindex_consumer(mut self, var queue_name: String, cid: UInt64) raises:
        """Drop one cid from the per-queue consumer index (if present)."""
        if queue_name not in self._queue_consumers:
            return
        var kept = List[UInt64]()
        var old = self._queue_consumers.pop(queue_name)
        for i in range(len(old)):
            if old[i] != cid:
                kept.append(old[i])
        if len(kept) > 0:
            self._queue_consumers[queue_name] = kept^

    def unregister_consumer(mut self, consumer_id: UInt64) raises -> Bool:
        """Unregister a consumer and requeue its unacked messages (D8 reclaim).

        A consumer that disconnects must not strand its delivered-but-unacked
        messages; under pooling that also permanently pins their payload buffers.
        Requeuing makes them deliverable again (the buffers stay owned, returning
        to the pool only at a real death site). Returns True if the consumer existed.
        """
        if consumer_id not in self._consumers:
            return False
        var qname = self._consumers[consumer_id].queue_name()
        _ = self._consumers.pop(consumer_id)
        self._deindex_consumer(qname, consumer_id)
        if qname in self._queues:
            # 0018: a disconnect-requeue keeps every unacked delivery in the
            # RECOVERED set (still-live redelivered messages — the journal
            # bumps the REDELIVER approximation for the durable ones).
            var seqs = self._queues[qname].ack_seqs_through(
                UInt64(18446744073709551615)
            )
            _ = self._queues[qname].requeue_unacked()
            self._journalize_seqs(qname^, seqs^, self._TOMB_REDELIVER())
        return True

    # ---- consuming ----------------------------------------------------

    def consume(mut self, consumer_id: UInt64) raises -> Optional[Delivery]:
        """Deliver the next message for a consumer.

        Returns a Delivery claim token, or None if:
        - Consumer not found
        - Consumer at prefetch limit
        - Queue is empty
        """
        if consumer_id not in self._consumers:
            return Optional[Delivery]()

        if not self._consumers[consumer_id].can_deliver():
            return Optional[Delivery]()

        var qname = self._consumers[consumer_id].queue_name()
        if qname not in self._queues:
            return Optional[Delivery]()

        var maybe_delivery = self._queues[qname].dequeue()
        # 0017 T3: x-message-ttl expiry evaluated at delivery time — the
        # skipped (expired) messages are dead-lettered/resolved here.
        self._reap_queue(qname.copy())
        if maybe_delivery:
            self._consumers[consumer_id].record_delivery()
            return maybe_delivery^

        return Optional[Delivery]()

    def acknowledge(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Acknowledge a delivery. Message is destroyed.

        Returns True if found and acknowledged.
        """
        if consumer_id not in self._consumers:
            return False
        var qname = self._consumers[consumer_id].queue_name()
        if qname not in self._queues:
            return False
        if not self._queues[qname].has_unacked(delivery_tag):
            return False
        # 0018: pre-read the journal identity; the ACK tombstone drops the
        # persisted message's live state at recovery (a fresh-empty state).
        var journal_seq = self._queues[qname].persist_seq_of(delivery_tag)
        self._journalize_tombstone(journal_seq, self._TOMB_ACK())
        # Reclaim the dead message's payload and return it to the pool. `release`
        # is a no-op for non-pooled buffers (single-dest moves and direct copies),
        # so with the pool disabled or for non-pooled payloads this matches the old
        # "acknowledge destroys" behavior exactly (the buffer is freed on drop).
        var reclaimed = self._queues[qname].ack_reclaim(delivery_tag)
        self._pool.release(reclaimed^)
        self._consumers[consumer_id].record_ack()
        return True

    def reject(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Reject a delivery. Message is requeued.

        Returns True if found and rejected.
        """
        if consumer_id not in self._consumers:
            return False
        var qname = self._consumers[consumer_id].queue_name()
        if qname not in self._queues:
            return False
        var journal_seq = self._queues[qname].persist_seq_of(delivery_tag)
        var result = self._queues[qname].reject(delivery_tag)
        if result:
            # 0018: the requeue acceptance bumps the journal's recovered
            # redelivered approximation (REDELIVER marker).
            self._journalize_tombstone(journal_seq, self._TOMB_REDELIVER())
            self._consumers[consumer_id].record_ack()
        return result

    # ---- read access --------------------------------------------------

    def read_payload(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> BufferSnapshot:
        """Copy out the payload of a delivered message.

        Ownership: bytes are COPIED into the returned BufferSnapshot;
        the Message remains owned by the queue.
        Raises if consumer_id is unknown (Dict subscript, not Optional).
        """
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_payload(delivery_tag)

    def queue_routing_key(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> String:
        """Read the routing key associated with an unacked delivery.

        Delivery tags are scoped to queues, so the consumer id is required to
        resolve the owning queue. The queue remains the semantic authority for
        the envelope field.
        """
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_routing_key(delivery_tag)

    def queue_message_count(self, consumer_id: UInt64) raises -> Int:
        """Return this consumer queue's pending (ready) message count.

        This deliberately exposes Queue.depth(), whose established meaning is
        pending-only. It is therefore the post-pop AMQP get-ok message-count,
        not the queue's pending-plus-unacked management/backpressure count.
        """
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].depth()

    def read_message_id(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> MessageID:
        """Read an unacked message's preserved identifier."""
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_message_id(delivery_tag)

    def read_headers(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Dict[String, String]:
        """Read an owned copy of an unacked message's preserved headers."""
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_headers(delivery_tag)

    # ---- 0017 T2 readouts (content props + redelivery per unacked tag) ----

    def queue_prop_flags(ref self, consumer_id: UInt64, delivery_tag: UInt64) raises -> UInt16:
        """Read an unacked delivery's raw AMQP property-flag word."""
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_prop_flags(delivery_tag)

    def queue_prop_bytes_copy(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Read an owned copy of an unacked delivery's raw AMQP property-list
        bytes (the publisher's transmitted slice)."""
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_prop_bytes_copy(delivery_tag)

    def queue_redelivery(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Whether an unacked claim is a re-delivery (redelivered AMQP bit)."""
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].is_redelivery(delivery_tag)

    # ---- stats --------------------------------------------------------

    def messages_routed(ref self) -> Int:
        return self._messages_routed

    def exchange_count(ref self) -> Int:
        return len(self._exchanges)

    def queue_count(ref self) -> Int:
        return len(self._queues)

    def consumer_count(ref self) -> Int:
        return len(self._consumers)
