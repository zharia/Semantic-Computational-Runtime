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

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import Exchange, ExchangeType, Binding
from hyrx.core.queue import Queue, QueueConfig, Delivery
from hyrx.core.consumer import Consumer
from hyrx.core.buffer_pool import BufferPool
from hyrx.core.pool_stats import PoolStats


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
        var result = False
        if requeue:
            result = self._queues[qname].reject(delivery_tag)
        else:
            if self._queues[qname].has_unacked(delivery_tag):
                var buf = self._queues[qname].drop_unacked(delivery_tag)
                self._pool.release(buf^)
                result = True
        if result:
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
        var n = 0
        if requeue:
            n = self._queues[qname].requeue_unacked_through(upper)
        else:
            var bufs = self._queues[qname].drop_unacked_through(upper)
            n = len(bufs)
            while len(bufs) > 0:
                var buf = bufs.pop()
                self._pool.release(buf^)
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
            self._queues[only_queue].enqueue_prechecked(msg^)
            self._messages_routed += 1
            return 1

        var payload_len = msg.payload_size()
        # 0017 T2: byte-faithful content props ride into EVERY destination
        # copy (read once, copied per destination fan-out).
        var prop_flags = msg.content_prop_flags()
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
                var cloned = Message(
                    env^, payload^, prop_flags,
                    msg.content_prop_bytes_copy(),
                )
                self._queues[qname].enqueue_prechecked(cloned^)
                count += 1

        self._messages_routed += count
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
            _ = self._queues[qname].requeue_unacked()
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
        var result = self._queues[qname].reject(delivery_tag)
        if result:
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
