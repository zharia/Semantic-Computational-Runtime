# Stable Hyrx embedded API.
#
# This is the public interface for in-process Hyrx usage.
# Exposes semantic operations; hides implementation details.
#
# Architecture: Layer 1 (Hyrx Embedded) wraps Layer 0 (Hyrx Core).
# The embedded API delegates to the core Router for all routing/delivery.
# No duplicate routing logic. No duplicate queue/exchange structs.

from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.pool_stats import PoolStats
from hyrx.core.message import Message
from hyrx.core.exchange import ExchangeType
from hyrx.core.queue import Delivery
from hyrx.core.router import Router
from hyrx.core.exchange import HeaderArgs
from hyrx.core.storage import MessageJournal

struct HyrxConfig:
    """Configuration for an embedded Hyrx instance."""

    var _default_queue_capacity: Int
    var _buffer_pool_slab_size: Int
    var _buffer_pool_max_slabs: Int
    var _buffer_pool_enabled: Bool

    def __init__(out self):
        self._default_queue_capacity = 1024
        self._buffer_pool_slab_size = 4096
        self._buffer_pool_max_slabs = 64
        self._buffer_pool_enabled = False

    def __init__(
        out self,
        queue_capacity: Int,
        slab_size: Int,
        max_slabs: Int,
    ):
        self._default_queue_capacity = queue_capacity
        self._buffer_pool_slab_size = slab_size
        self._buffer_pool_max_slabs = max_slabs
        self._buffer_pool_enabled = False

struct HyrxStats:
    """Snapshot of engine statistics."""

    var messages_published: Int
    var messages_delivered: Int
    var messages_acknowledged: Int
    var messages_rejected: Int
    var active_queues: Int
    var active_consumers: Int
    var pool_stats: PoolStats

    def __init__(
        out self,
        messages_published: Int,
        messages_delivered: Int,
        messages_acknowledged: Int,
        messages_rejected: Int,
        active_queues: Int,
        active_consumers: Int,
        var pool_stats: PoolStats,
    ):
        self.messages_published = messages_published
        self.messages_delivered = messages_delivered
        self.messages_acknowledged = messages_acknowledged
        self.messages_rejected = messages_rejected
        self.active_queues = active_queues
        self.active_consumers = active_consumers
        self.pool_stats = pool_stats^

struct HyrxEngine:
    """Stable embedded API for Hyrx messaging.

    This is the primary entry point for in-process Hyrx usage.
    Exposes semantic operations; hides implementation details.

    Does NOT expose:
    - slab internals
    - queue implementation structures
    - buffer pool details
    """

    var _router: Router
    var _config: HyrxConfig
    var _messages_published: Int
    var _messages_delivered: Int
    var _messages_acknowledged: Int
    var _messages_rejected: Int

    def __init__(out self, var config: HyrxConfig):
        self._router = Router(
            config._buffer_pool_slab_size,
            config._buffer_pool_max_slabs,
            config._buffer_pool_enabled,
        )
        self._config = config^
        self._messages_published = 0
        self._messages_delivered = 0
        self._messages_acknowledged = 0
        self._messages_rejected = 0

    # ---- 0018: pluggable storage pass-throughs (additive) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the storage journal into the engine's single Router.

        The embedded API holds no storage logic: the injection is the one
        wire the Router's write hooks run on (disabled DEFAULT = no storage
        class at all)."""
        self._router.attach_journal(journal^)

    def recover_journal(mut self) raises -> Int:
        """Replay the injected journal into the engine. Returns the number
        of recovered messages."""
        return self._router.recover()

    def journal_mode(ref self) -> Int:
        """The engine's active storage mode."""
        return self._router.journal_mode()

    def sync_journal(mut self) raises:
        """Flush the attached journal (graceful-shutdown durability seam)."""
        self._router.sync_journal()

    # ---- topology ----

    def declare_exchange(
        mut self, var name: String, var exchange_type: ExchangeType
    ) raises -> Bool:
        """Declare an exchange. Returns True if created."""
        return self._router.declare_exchange(name^, exchange_type^)

    def declare_queue(mut self, var name: String) raises -> Bool:
        """Declare a queue with default capacity. Returns True if created."""
        return self._router.declare_queue(
            name^, self._config._default_queue_capacity
        )

    # ---- 0017 T3: decoded-argument declare + service readouts (additive) ----

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
        """Declare a queue carrying the decoded AMQP declare arguments
        (durable = FLAG ONLY, in-memory; storage = milestone 0018).
        capacity <= 0 falls back to the engine's default queue capacity."""
        var cap = capacity
        if cap <= 0:
            cap = self._config._default_queue_capacity
        return self._router.declare_queue_full(
            name^, cap, durable, ttl_ms, expires_ms,
            max_length, overflow_reject, dlx^, dlrk^,
        )

    def queue_depth(ref self, var name: String) -> Int:
        """Ready depth of a queue (declare-ok message-count). -1 missing."""
        return self._router.queue_depth(name^)

    def queue_consumer_count(ref self, var name: String) -> Int:
        """Live consumer count of a queue (declare-ok consumer-count)."""
        return self._router.queue_consumer_count(name^)

    def exchange_type_of(ref self, var name: String) -> String:
        """Existing exchange's type name ("" = missing)."""
        return self._router.exchange_type_of(name^)

    def exchange_binding_total(ref self, var name: String) -> Int:
        """Total bindings on an exchange; -1 missing."""
        return self._router.exchange_binding_total(name^)

    def bind_queue(
        mut self,
        queue_name: String,
        exchange_name: String,
        var routing_key: String,
        var arguments: HeaderArgs,
    ) raises -> Bool:
        """Bind a queue to an exchange with a routing key."""
        return self._router.bind_queue(queue_name, exchange_name, routing_key^, arguments^)

    # ---- messaging ----

    def publish(
        mut self, var msg: Message, exchange_name: String
    ) raises -> Int:
        """Publish a message through the named exchange.
        Returns the number of queues the message was routed to.
        """
        var count = self._router.publish(msg^, exchange_name)
        self._messages_published += 1
        return count

    def publish_to_queue(
        mut self, var msg: Message, var queue_name: String
    ) raises -> Int:
        """0017 T3: the DEFAULT exchange ("") publish — DIRECT into the
        named queue (the exchange's pre-bound queue-name binding)."""
        var count = self._router.publish_to_queue(msg^, queue_name)
        self._messages_published += 1
        return count

    def consume(
        mut self, queue_name: String, prefetch: Int
    ) raises -> UInt64:
        """Register a consumer on a queue. Returns consumer_id."""
        return self._router.register_consumer(queue_name, prefetch)

    def next_message(
        mut self, consumer_id: UInt64
    ) raises -> Optional[Delivery]:
        """Deliver the next message for a consumer.
        Returns None if no messages available.
        """
        var result = self._router.consume(consumer_id)
        if result:
            self._messages_delivered += 1
        return result^

    def read_payload(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> BufferSnapshot:
        """Copy out the payload of a delivered message.

        Delegates to the core Router. Bytes are COPIED into the returned
        BufferSnapshot; the message itself stays owned by the queue.
        """
        return self._router.read_payload(consumer_id, delivery_tag)

    def queue_routing_key(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> String:
        """Read an unacked delivery's routing key through the engine boundary."""
        return self._router.queue_routing_key(consumer_id, delivery_tag)

    def queue_message_count(self, consumer_id: UInt64) raises -> Int:
        """Return the consumer queue's pending (ready) message count."""
        return self._router.queue_message_count(consumer_id)

    # ---- 0017 T2 readouts (content props + redelivery per unacked tag) ----

    def queue_prop_flags(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> UInt16:
        """Read an unacked delivery's raw AMQP property-flag word."""
        return self._router.queue_prop_flags(consumer_id, delivery_tag)

    def queue_prop_bytes_copy(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Read an owned copy of an unacked delivery's raw AMQP property-list
        bytes (the publisher's transmitted slice)."""
        return self._router.queue_prop_bytes_copy(consumer_id, delivery_tag)

    def queue_redelivery(
        ref self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Whether an unacked claim is a re-delivery (redelivered AMQP bit)."""
        return self._router.queue_redelivery(consumer_id, delivery_tag)

    def acknowledge(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Acknowledge a delivery. Message is destroyed."""
        var result = self._router.acknowledge(consumer_id, delivery_tag)
        if result:
            self._messages_acknowledged += 1
        return result

    def reject(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Reject a delivery. Message is requeued."""
        var result = self._router.reject(consumer_id, delivery_tag)
        if result:
            self._messages_rejected += 1
        return result

    # ---- 0017 T1: topology management pass-throughs (additive) ----

    def has_queue(ref self, var name: String) -> Bool:
        """Whether a queue with this name is declared."""
        return self._router.has_queue(name^)

    def has_exchange(ref self, var name: String) -> Bool:
        """Whether an exchange with this name is declared."""
        return self._router.has_exchange(name^)

    def purge_queue(mut self, var name: String) raises -> Int:
        """queue.purge (50,30): drop ready messages (unacked untouched).

        Returns the number purged, -1 when the queue is missing."""
        return self._router.purge_queue(name^)

    def delete_queue_checked(
        mut self, var name: String, if_empty: Bool, if_unused: Bool
    ) raises -> Int:
        """queue.delete (50,40) with if-empty/if-unused; sentinels -1/-2/-3."""
        return self._router.delete_queue_checked(name^, if_empty, if_unused)

    def delete_exchange_checked(
        mut self, var name: String, if_unused: Bool
    ) raises -> Int:
        """exchange.delete (40,20) with if-unused; sentinels -1/-2."""
        return self._router.delete_exchange_checked(name^, if_unused)

    def bind_exchange(
        mut self,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """exchange.bind (40,30) exchange→exchange binding."""
        return self._router.bind_exchange(source^, destination^, routing_key^)

    def unbind_exchange(
        mut self,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """exchange.unbind (40,40)."""
        return self._router.unbind_exchange(source^, destination^, routing_key)

    def unbind_queue(
        mut self,
        queue_name: String,
        exchange_name: String,
        routing_key: String,
    ) raises -> Bool:
        """queue.unbind (50,50) via the router's binding removal."""
        return self._router.unbind_queue(queue_name, exchange_name, routing_key)

    def unregister_consumer(mut self, consumer_id: UInt64) raises -> Bool:
        """Reader deregistration (channel.close / teardown): requeues unacked."""
        return self._router.unregister_consumer(consumer_id)

    def bulk_ack(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Int:
        """basic.ack multiple=true: ack every tag <= tag (0 = all)."""
        var n = self._router.bulk_ack(consumer_id, delivery_tag)
        self._messages_acknowledged += n
        return n

    def nack(
        mut self, consumer_id: UInt64, delivery_tag: UInt64, requeue: Bool
    ) raises -> Bool:
        """basic.nack (60,120) single tag."""
        var result = self._router.nack(consumer_id, delivery_tag, requeue)
        if result:
            self._messages_rejected += 1
        return result

    def nack_through(
        mut self, consumer_id: UInt64, delivery_tag: UInt64, requeue: Bool
    ) raises -> Int:
        """basic.nack (60,120) multiple=true: every tag <= tag."""
        var n = self._router.nack_through(consumer_id, delivery_tag, requeue)
        self._messages_rejected += n
        return n

    # ---- telemetry ----

    def stats(ref self) -> HyrxStats:
        """Snapshot of engine statistics."""
        return HyrxStats(
            self._messages_published,
            self._messages_delivered,
            self._messages_acknowledged,
            self._messages_rejected,
            self._router.queue_count(),
            self._router.consumer_count(),
            self._router.pool_stats(),
        )
