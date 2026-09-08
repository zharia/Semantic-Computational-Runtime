# Stable Hyrx embedded API.
#
# This is the public interface for in-process Hyrx usage.
# Exposes semantic operations; hides implementation details.
#
# Architecture: Layer 1 (Hyrx Embedded) wraps Layer 0 (Hyrx Core).
# The embedded API delegates to the core Router for all routing/delivery.
# No duplicate routing logic. No duplicate queue/exchange structs.

from hyrx.core.buffer_pool import BufferPool
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.pool_stats import PoolStats
from hyrx.core.message import Message
from hyrx.core.exchange import ExchangeType
from hyrx.core.queue import Delivery
from hyrx.core.router import Router

struct HyrxConfig:
    """Configuration for an embedded Hyrx instance."""

    var _default_queue_capacity: Int
    var _buffer_pool_slab_size: Int
    var _buffer_pool_max_slabs: Int

    def __init__(out self):
        self._default_queue_capacity = 1024
        self._buffer_pool_slab_size = 4096
        self._buffer_pool_max_slabs = 64

    def __init__(
        out self,
        queue_capacity: Int,
        slab_size: Int,
        max_slabs: Int,
    ):
        self._default_queue_capacity = queue_capacity
        self._buffer_pool_slab_size = slab_size
        self._buffer_pool_max_slabs = max_slabs

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
    var _pool: BufferPool
    var _config: HyrxConfig
    var _messages_published: Int
    var _messages_delivered: Int
    var _messages_acknowledged: Int
    var _messages_rejected: Int

    def __init__(out self, var config: HyrxConfig):
        self._router = Router()
        self._pool = BufferPool(
            config._buffer_pool_slab_size,
            config._buffer_pool_max_slabs,
        )
        self._config = config^
        self._messages_published = 0
        self._messages_delivered = 0
        self._messages_acknowledged = 0
        self._messages_rejected = 0

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

    def bind_queue(
        mut self,
        queue_name: String,
        exchange_name: String,
        var routing_key: String,
    ) raises -> Bool:
        """Bind a queue to an exchange with a routing key."""
        return self._router.bind_queue(queue_name, exchange_name, routing_key^)

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
            self._pool.stats(),
        )
