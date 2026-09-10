# Bounded FIFO queue with delivery tracking and ack/reject semantics.
#
# Ownership model:
#   - Queue owns all Messages throughout their lifecycle.
#   - Messages move between inbox, outbox, and unacked pools.
#   - Delivery is a lightweight claim token (tag only).
#   - Consumer reads messages through the Queue via read_payload(),
#     which copies payload bytes out; the Message never leaves the Queue.
#   - Acknowledge destroys the message. Reject requeues it.
#
# Two-stack queue for FIFO ordering:
#   - inbox: new messages are appended here (enqueue)
#   - outbox: messages are dequeued from here (pop gives oldest)
#   - When outbox is empty, inbox is reversed into outbox

from std.collections import List
from std.time import monotonic

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.message import Message, MessageID

struct QueueConfig:
    """Configuration for a message queue.

    0017 T3: the AMQP declare-argument semantics are carried HERE in the
    queue's own config (single semantics authority). All of them are
    in-memory flags/limits — durable is FLAG ONLY (no disk persistence;
    milestone 0018 owns real storage)."""

    var _capacity: Int
    var _durable: Bool
    # x-message-ttl: per-message DELIVERY-TIME expiry in ms (age measured
    # from the enqueue stamp). 0 = off.
    var _ttl_ms: Int
    # x-max-length: queue-length cap. 0 = off (queue keeps its bare capacity).
    var _max_length: Int
    # overflow='reject-publish' (else the AMQP default drop-head):
    # when set, a full x-max-length queue REFUSES new publishes instead of
    # dropping the oldest message.
    var _overflow_reject: Bool
    # x-dead-letter-exchange / x-dead-letter-routing-key. Empty string =
    # unset (dead-lettering falls back to drop; routing key falls back to
    # the original message's routing key).
    var _dlx: String
    var _dlrk: String

    def __init__(out self, capacity: Int):
        self._capacity = capacity
        self._durable = False
        self._ttl_ms = 0
        self._max_length = 0
        self._overflow_reject = False
        self._dlx = ""
        self._dlrk = ""

    def __copyinit__(out self, existing: Self):
        self._capacity = existing._capacity
        self._durable = existing._durable
        self._ttl_ms = existing._ttl_ms
        self._max_length = existing._max_length
        self._overflow_reject = existing._overflow_reject
        self._dlx = existing._dlx.copy()
        self._dlrk = existing._dlrk.copy()

    def ttl_ms(ref self) -> Int:
        return self._ttl_ms

    def max_length(ref self) -> Int:
        return self._max_length

    def overflow_reject(ref self) -> Bool:
        return self._overflow_reject

    def dlx_exchange(ref self) -> String:
        return self._dlx.copy()

    def dlx_routing_key(ref self) -> String:
        return self._dlrk.copy()

struct Delivery:
    """A lightweight claim token for a delivered message.

    The message itself remains owned by the Queue. The consumer reads
    it via read_payload() and resolves it via acknowledge() or reject().
    """

    var _delivery_tag: UInt64

    def __init__(out self, delivery_tag: UInt64):
        self._delivery_tag = delivery_tag

    def delivery_tag(self) -> UInt64:
        return self._delivery_tag

struct Queue:
    """Bounded message queue with delivery tracking."""

    var _name: String
    var _inbox: List[Message]
    var _outbox: List[Message]
    var _unacked: Dict[UInt64, Message]
    var _unacked_tags: List[UInt64]
    var _config: QueueConfig
    var _next_delivery_tag: UInt64
    # 0017 T3: messages reaped by the queue itself per AMQP declare-arg
    # semantics (x-message-ttl timed out at delivery, x-max-length
    # drop-head trimming). The Router drains this list with take_swept()
    # right after the triggering operation and dead-letters (DLX set) or
    # releases each message.
    var _swept: List[Message]

    def __init__(out self, var name: String, var config: QueueConfig):
        self._name = name^
        self._inbox = List[Message]()
        self._outbox = List[Message]()
        self._unacked = Dict[UInt64, Message]()
        self._unacked_tags = List[UInt64]()
        self._config = config^
        self._next_delivery_tag = 0
        self._swept = List[Message]()

    def name(ref self) -> String:
        return self._name

    def _total_count(ref self) -> Int:
        """Total messages: pending (inbox + outbox) + unacked."""
        return len(self._inbox) + len(self._outbox) + len(self._unacked)

    def _transfer(mut self):
        """Reverse inbox into outbox for FIFO dequeue."""
        while len(self._inbox) > 0:
            self._outbox.append(self._inbox.pop())

    def enqueue(mut self, var msg: Message) raises -> Bool:
        """Enqueue a message. Returns False if queue is full (backpressure).

        Ownership: msg is moved into the queue's inbox.
        0017 T3: after the move the x-max-length cap trims (drop-oldest)
        regardless of the overflow mode (drop-head is the AMQP default);
        with overflow='reject-publish' the has_capacity preflight refuses
        BEFORE this call, matching the publish-side refusal."""
        if self._total_count() >= self._config._capacity:
            return False
        self._inbox.append(msg^)
        if self._config._overflow_reject and self._config._max_length > 0:
            if self._total_count() > self._config._max_length:
                return False
        _ = self._trim_to_max()
        return True

    def has_capacity(ref self) -> Bool:
        """Whether enqueue would accept one message at this instant.

        This is a non-consuming preflight for the router's single-destination
        move path. The core is single-threaded, so no concurrent enqueue can
        invalidate the result between this check and the immediate transfer.

        0017 T3: overflow='reject-publish' turns the x-max-length cap into a
        refusal (the publisher's copy is silently unrouted, as with any
        capacity reject). Default (drop-head) keeps normal capacity behavior;
        reaping happens after the enqueue.
        """
        if self._config._max_length > 0:
            if self._config._overflow_reject:
                return self._total_count() < self._config._max_length
            return self._total_count() <= self._config._max_length
        return self._total_count() < self._config._capacity

    def enqueue_prechecked(mut self, var msg: Message) raises:
        """Move a message into a Queue proven available by ``has_capacity()``.

        Router invokes this immediately after its capacity preflight in the
        single-threaded core. Keeping the transfer separate from ``enqueue``
        preserves the source message when an ordinary capacity-reject needs to
        use the fan-out copy path.
        """
        self._inbox.append(msg^)
        _ = self._trim_to_max()

    # 0017 T3 readouts (declare-ok parity + service preflights)

    def total_count(ref self) -> Int:
        """Ready + unacked messages currently held (declare-ok basis is
        Router.queue_depth; this total feeds the x-max-length cap)."""
        return self._total_count()

    def dequeue(mut self) -> Optional[Delivery]:
        """Move next message to unacked, return delivery token.

        Returns None if no messages are available.

        0017 T3 x-message-ttl: when the queue carries a per-message TTL,
        every message whose enqueue-age has reached the TTL is reaped into
        `_swept` (dead-lettered or released by the Router) and skipped —
        the next live message delivers (or None). This is the only expiry
        evaluation the engine performs (there is NO timer subsystem; the
        check happens at delivery time, per the honest PARTIAL framing)."""
        if self._config._ttl_ms > 0:
            var ttl_ns = self._config._ttl_ms * 1_000_000
            while True:
                if len(self._outbox) == 0:
                    self._transfer()
                if len(self._outbox) == 0:
                    return Optional[Delivery]()
                var msg = self._outbox.pop()
                if (monotonic() - msg.enqueue_ns()) >= ttl_ns:
                    self._swept.append(msg^)
                    continue
                msg.increment_delivery_count()
                var tag = self._next_delivery_tag
                self._next_delivery_tag += 1
                self._unacked[tag] = msg^
                self._unacked_tags.append(tag)
                return Optional[Delivery](Delivery(tag))
        if len(self._outbox) == 0:
            self._transfer()
        if len(self._outbox) == 0:
            return Optional[Delivery]()
        var msg = self._outbox.pop()
        msg.increment_delivery_count()
        var tag = self._next_delivery_tag
        self._next_delivery_tag += 1
        self._unacked[tag] = msg^
        self._unacked_tags.append(tag)
        return Optional[Delivery](Delivery(tag))

    # ---- 0017 T3: swept-message reaping (dead-letter / drop by Router) ----

    def take_swept(mut self) raises -> List[Message]:
        """Drain (and own) every message the queue reaped on its own:
        TTL-expired at delivery, or trim-dropped by x-max-length drop-head.

        The Router dead-letters each into x-dead-letter-exchange when the
        queue declares one, otherwise releases the payload."""
        var out = List[Message]()
        while len(self._swept) > 0:
            out.append(self._swept.pop())
        return out^

    def _trim_to_max(mut self) raises -> Bool:
        """Enforce x-max-length (drop-oldest on overflow).

        Runs AFTER every enqueue. Returns True when overflow trimming
        occurred. The engine's default capacity refusal (enqueue returning
        False on a bare-full queue) is UNCHANGED for queues declared
        without x-max-length; a queue with x-max-length = N effectively
        holds N messages and drops the head beyond that (AMQP default
        overflow='drop-head')."""
        if self._config._max_length <= 0:
            return False
        var trimmed = False
        while self._total_count() > self._config._max_length:
            if len(self._outbox) > 0:
                self._swept.append(self._outbox.pop())
            elif len(self._inbox) > 0:
                self._swept.append(self._inbox.pop(0))
            else:
                break
            trimmed = True
        return trimmed

    def read_payload(ref self, delivery_tag: UInt64) raises -> BufferSnapshot:
        """Copy out the payload of an unacked message.

        Ownership: the payload bytes are COPIED into the returned
        BufferSnapshot. The Message itself remains owned by the queue
        (unacked pool) and is neither moved nor consumed.

        DESIGN GAP (audit §7): an unknown delivery_tag silently yields
        an EMPTY snapshot instead of raising — see docs/MEMORY_MODEL.md.
        """
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].payload()
        # DESIGN GAP: silent empty snapshot for an unknown tag (no raise).
        var empty = List[UInt8]()
        return BufferSnapshot(empty^)

    def read_routing_key(ref self, delivery_tag: UInt64) raises -> String:
        """Read the routing key of an unacked message."""
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].routing_key()
        return ""

    def read_message_id(ref self, delivery_tag: UInt64) raises -> MessageID:
        """Read the identifier of an unacked message claim."""
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].message_id()
        return MessageID(0)

    def read_headers(
        ref self, delivery_tag: UInt64
    ) raises -> Dict[String, String]:
        """Read an owned header-map copy of an unacked message claim."""
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].headers()
        return Dict[String, String]()

    # ---- 0017 T2: content-property + redelivery readouts per unacked tag ----

    def read_prop_flags(ref self, delivery_tag: UInt64) raises -> UInt16:
        """The raw AMQP property-flag word of an unacked message."""
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].content_prop_flags()
        return 0

    def read_prop_bytes_copy(ref self, delivery_tag: UInt64) raises -> List[UInt8]:
        """An owned copy of the raw AMQP property-list bytes of an unacked
        message (empty when the publisher declared no properties)."""
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].content_prop_bytes_copy()
        return List[UInt8]()

    def is_redelivery(ref self, delivery_tag: UInt64) raises -> Bool:
        """Whether this unacked claim is a REDELIVERY (delivery_count > 1).

        A message dequeued for the first time counts exactly one delivery
        (Queue.dequeue increments before returning the token), so the
        redelivered AMQP bit is True only when the message was requeued by a
        nack/reject/disconnect and dequeued again.
        """
        if delivery_tag in self._unacked:
            return self._unacked[delivery_tag].delivery_count() > 1
        return False

    def _untrack_unacked(mut self, delivery_tag: UInt64):
        """Remove a tag from the unacked-order list (find + index-pop)."""
        var i = 0
        while i < len(self._unacked_tags):
            if self._unacked_tags[i] == delivery_tag:
                _ = self._unacked_tags.pop(i)
                return
            i += 1

    def acknowledge(mut self, delivery_tag: UInt64) raises -> Bool:
        """Confirm delivery. Message is destroyed. Returns True if found."""
        if delivery_tag in self._unacked:
            var _ = self._unacked.pop(delivery_tag)
            self._untrack_unacked(delivery_tag)
            return True
        return False

    def has_unacked(ref self, delivery_tag: UInt64) -> Bool:
        """Whether a delivery tag is currently unacked (non-consuming preflight)."""
        return delivery_tag in self._unacked

    def ack_reclaim(mut self, delivery_tag: UInt64) raises -> Buffer:
        """Acknowledge and RETURN the dead message's payload Buffer (owned).

        For the pool-reclaim path: the caller (Router) releases the returned
        buffer into its BufferPool (a no-op if it was never pooled). Assumes the
        tag is present (guard with has_unacked first); the Message's envelope is
        dropped and its empty shell consumed. Unlike acknowledge() this hands the
        buffer back instead of destroying it in place.
        """
        var msg = self._unacked.pop(delivery_tag)
        self._untrack_unacked(delivery_tag)
        return msg.take_payload()

    def reject(mut self, delivery_tag: UInt64) raises -> Bool:
        """Reject delivery. Message is requeued. Returns True if found."""
        if delivery_tag in self._unacked:
            var msg = self._unacked.pop(delivery_tag)
            self._untrack_unacked(delivery_tag)
            self._inbox.append(msg^)
            return True
        return False

    # ---- bulk resolution (amqp basic.ack/nack multiple=true; 0017 T1) ----
    #
    # Delivery tags are per-queue ascending dequeue order, so "all unacked tags
    # ≤ T" is exactly the prefix of _unacked_tags up to the first tag > T.

    def _take_reclaim_through(
        mut self, delivery_tag: UInt64
    ) raises -> List[Buffer]:
        """Pop every unacked message with tag <= delivery_tag, in tag order.

        Each message's envelope is destroyed and its payload Buffer handed out
        (owned) — call Router-side per buffer with pool.release (no-op for
        non-pooled). Shared body of ack_reclaim_through / drop_unacked_through.
        """
        var out = List[Buffer]()
        var i = 0
        while i < len(self._unacked_tags):
            var t = self._unacked_tags[i]
            if t > delivery_tag:
                break
            _ = self._unacked_tags.pop(i)
            var msg = self._unacked.pop(t)
            out.append(msg.take_payload())
        return out^

    def ack_reclaim_through(mut self, delivery_tag: UInt64) raises -> List[Buffer]:
        """basic.ack (60,80) multiple=true: acknowledge every tag <= tag.

        Messages are destroyed; payload Buffers returned for pool release.
        Assumes the embedding consumer resolved the tag scope (Router).
        """
        return self._take_reclaim_through(delivery_tag)

    def drop_unacked_through(mut self, delivery_tag: UInt64) raises -> List[Buffer]:
        """basic.nack (60,120) requeue=false, multiple=true: drop <= tag.

        Same mechanics as ack_reclaim_through but semantically the
        no-requeue nack path (drops; no x-dead-letter routing in T1).
        """
        return self._take_reclaim_through(delivery_tag)

    def drop_unacked(mut self, delivery_tag: UInt64) raises -> Buffer:
        """basic.nack single-tag requeue=false: destroy one unacked message.

        Returns the payload Buffer (pool release by Router). Assumes the tag
        is present (Router re-checks has_unacked first).
        """
        var msg = self._unacked.pop(delivery_tag)
        self._untrack_unacked(delivery_tag)
        return msg.take_payload()

    # ---- 0017 T3: DLX-NACK message-reaping (dead-letter with content) ----

    def take_unacked(mut self, delivery_tag: UInt64) raises -> Message:
        """basic.nack requeue=false WITH a DLX: hand the whole Message out
        (owned) so Router rebuilds + reroutes it into the DLX.

        Same preconditions as drop_unacked (Router re-checks has_unacked).
        """
        var msg = self._unacked.pop(delivery_tag)
        self._untrack_unacked(delivery_tag)
        return msg^

    def take_unacked_through(mut self, delivery_tag: UInt64) raises -> List[Message]:
        """DLX-NACK multiple=true: every unacked message with tag <= tag,
        in tag order, handed out owned."""
        var out = List[Message]()
        var i = 0
        while i < len(self._unacked_tags):
            var t = self._unacked_tags[i]
            if t > delivery_tag:
                break
            _ = self._unacked_tags.pop(i)
            out.append(self._unacked.pop(t))
        return out^

    def requeue_unacked_through(mut self, delivery_tag: UInt64) raises -> Int:
        """basic.nack requeue=true, multiple=true: requeue every tag <= tag.

        Tag order is preserved (each requeued message is appended to the
        inbox in _unacked_tags order); the next dequeue bumps each message's
        delivery counter (increment_delivery_count in dequeue — the
        redelivery counter Router.requeue_unacked relies on). Returns the
        number requeued.
        """
        var n = 0
        var i = 0
        while i < len(self._unacked_tags):
            var t = self._unacked_tags[i]
            if t > delivery_tag:
                break
            _ = self._unacked_tags.pop(i)
            var msg = self._unacked.pop(t)
            self._inbox.append(msg^)
            n += 1
        return n

    # ---- queue.purge (amqp 50,30; 0017 T1) ----

    def purge_ready(mut self) raises -> List[Message]:
        """Remove every READY message (inbox + outbox); UNACKED untouched.

        queue.purge drops only ready messages and MUST NOT touch unacked
        deliveries. Returns the purged messages so Router releases their
        payload Buffers to the pool. Returns an empty list for an empty queue
        (a legal purge, count 0)."""
        var out = List[Message]()
        while len(self._outbox) > 0:
            out.append(self._outbox.pop())
        while len(self._inbox) > 0:
            out.append(self._inbox.pop())
        return out^

    def drain_messages(mut self) raises -> List[Message]:
        """Move every owned Message (outbox + inbox + unacked) out for reclaim.

        Leaves the Queue empty. `Router.delete_queue` uses this to return each
        payload Buffer to the pool; without it a deleted queue cascade-destroys its
        Messages, permanently stranding pooled buffers (starvation). Iterates the
        copyable `_unacked_tags` list (Dict[_, Message] is not key-iterable because
        Message is not Copyable).
        """
        var out = List[Message]()
        while len(self._outbox) > 0:
            out.append(self._outbox.pop())
        while len(self._inbox) > 0:
            out.append(self._inbox.pop())
        while len(self._unacked_tags) > 0:
            var t = self._unacked_tags.pop()
            var m = self._unacked.pop(t)
            out.append(m^)
        return out^

    def requeue_unacked(mut self) raises -> Int:
        """Move every unacked message back to the inbox (D8 orphan reclaim).

        Used by `Router.unregister_consumer`: a consumer that goes away must not
        strand its delivered-but-unacked messages (which under pooling would also
        strand their buffers). They become deliverable again. Their payload buffers
        stay owned by the requeued Messages (still `in_use`), returning to the pool
        only at a real death site (ack / delete-drain / shutdown-drain).
        Returns the number requeued.
        """
        var n = 0
        while len(self._unacked_tags) > 0:
            var t = self._unacked_tags.pop()
            var m = self._unacked.pop(t)
            self._inbox.append(m^)
            n += 1
        return n

    def depth(ref self) -> Int:
        """Number of pending messages (not including unacked)."""
        return len(self._inbox) + len(self._outbox)

    def unacked_count(ref self) -> Int:
        """Number of messages awaiting acknowledgement."""
        return len(self._unacked)

    def capacity(ref self) -> Int:
        return self._config._capacity

    # 0017 T1: bulk-resolution + purge additions live above (ack_reclaim_through,
    # drop_unacked, drop_unacked_through, requeue_unacked_through, purge_ready).
