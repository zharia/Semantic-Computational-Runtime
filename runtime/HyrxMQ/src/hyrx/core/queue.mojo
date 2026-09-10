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

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.message import Message, MessageID

struct QueueConfig:
    """Configuration for a message queue."""

    var _capacity: Int
    var _durable: Bool

    def __init__(out self, capacity: Int):
        self._capacity = capacity
        self._durable = False

    def __copyinit__(out self, existing: Self):
        self._capacity = existing._capacity
        self._durable = existing._durable

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

    def __init__(out self, var name: String, var config: QueueConfig):
        self._name = name^
        self._inbox = List[Message]()
        self._outbox = List[Message]()
        self._unacked = Dict[UInt64, Message]()
        self._unacked_tags = List[UInt64]()
        self._config = config^
        self._next_delivery_tag = 0

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
        """
        if self._total_count() >= self._config._capacity:
            return False
        self._inbox.append(msg^)
        return True

    def has_capacity(ref self) -> Bool:
        """Whether enqueue would accept one message at this instant.

        This is a non-consuming preflight for the router's single-destination
        move path. The core is single-threaded, so no concurrent enqueue can
        invalidate the result between this check and the immediate transfer.
        """
        return self._total_count() < self._config._capacity

    def enqueue_prechecked(mut self, var msg: Message):
        """Move a message into a Queue proven available by ``has_capacity()``.

        Router invokes this immediately after its capacity preflight in the
        single-threaded core. Keeping the transfer separate from ``enqueue``
        preserves the source message when an ordinary capacity-reject needs to
        use the fan-out copy path.
        """
        self._inbox.append(msg^)

    def dequeue(mut self) -> Optional[Delivery]:
        """Move next message to unacked, return delivery token.

        Returns None if no messages are available.
        """
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
