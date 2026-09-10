# HyrxMQ broker (Phase 7 product assembly).
#
# Layer 5: composes the embedded Hyrx engine (Layer 0/1) and an AMQP adapter
# (Layer 4) into a standalone broker product surface. It adds NO routing logic
# and NO AMQP→Hyrx translation of its own: the engine owns the one and only
# Router (the single routing authority) and the adapter is the single
# translation surface, which operates on that engine by injection. The broker
# merely wires the two together and owns the engine's lifetime.
#
# The network path is provided by the flare-backed transport contract
# (src/hyrx/transport, ADR-0005) and wired by src/hyrxmq/listener.mojo; the
# broker surface itself binds no socket, so `listening` reports the
# in-process lifecycle, not a bound socket (see status()).

from std.collections import List, Optional

from hyrx.core.queue import Delivery
from hyrx.embedded.api import HyrxEngine, HyrxConfig
from hyrx.amqp.adapter import AMQPAdapter

from hyrxmq.config import HyrxMQConfig
from hyrxmq.status import BrokerStatus


# Broker lifecycle states.
def BROKER_STATE_STARTING() -> Int:
    return 0


def BROKER_STATE_READY() -> Int:
    return 1


def BROKER_STATE_DEGRADED() -> Int:
    return 2


struct HyrxMQBroker:
    """Standalone broker product surface built on the embedded Hyrx engine."""

    var _engine: HyrxEngine
    var _adapter: AMQPAdapter
    var _config: HyrxMQConfig
    var _state: Int
    var _started: Bool

    def __init__(out self, var config: HyrxMQConfig):
        self._engine = HyrxEngine(
            HyrxConfig(
                config.default_queue_capacity,
                4096,
                64,
            )
        )
        self._adapter = AMQPAdapter()
        self._config = config^
        self._state = BROKER_STATE_STARTING()
        self._started = False

    # ---- lifecycle ----

    def start(mut self) raises:
        """Validate config and mark the broker ready (in-process, NOT bound)."""
        self._config.validate()
        self._state = BROKER_STATE_READY()
        self._started = True

    def shutdown(mut self):
        """Stop serving. Uptime is preserved (the broker was started)."""
        self._state = BROKER_STATE_DEGRADED()

    # ---- topology (translate via the adapter; route in the one engine) ----

    def declare_exchange(
        mut self, var name: String, var etype: String
    ) raises -> Bool:
        """Declare an exchange by AMQP type name. True if created."""
        return self._adapter.declare_exchange(
            self._engine, name^, etype^, durable=False
        )

    def declare_queue(mut self, var name: String) raises -> Bool:
        """Declare a queue. True if created."""
        return self._adapter.declare_queue(self._engine, name^, durable=False)

    # ---- 0017 T3: decoded-argument declare + declare-ok readouts ----

    def declare_queue_full(
        mut self,
        var name: String,
        durable: Bool,
        ttl_ms: Int,
        expires_ms: Int,
        max_length: Int,
        overflow_reject: Bool,
        var dlx: String,
        var dlrk: String,
    ) raises -> Bool:
        """Declare a queue with the decoded declare arguments (the ADAPTER
        owns the AMQP→Hyrx translation; this passes the decoded values)."""
        return self._adapter.declare_queue_full(
            self._engine, name^, durable, ttl_ms, expires_ms,
            max_length, overflow_reject, dlx^, dlrk^,
        )

    def queue_depth(ref self, var name: String) -> Int:
        """Ready depth (declare-ok message-count). -1 = missing queue."""
        return self._adapter.queue_depth(self._engine, name^)

    def queue_consumer_count(ref self, var name: String) -> Int:
        """Live consumer count (declare-ok consumer-count). -1 missing."""
        return self._adapter.queue_consumer_count(self._engine, name^)

    def exchange_type_of(ref self, var name: String) -> String:
        """Existing exchange's type name ("" = missing; 406 equivalence)."""
        return self._adapter.exchange_type_of(self._engine, name^)

    def exchange_binding_total(ref self, var name: String) -> Int:
        """Total bindings on an exchange; -1 missing."""
        return self._adapter.exchange_binding_total(self._engine, name^)

    def bind_queue(
        mut self,
        var queue: String,
        var exchange: String,
        var routing_key: String,
    ) raises -> Bool:
        """Bind a queue to an exchange with a routing key."""
        return self._adapter.bind_queue(
            self._engine, queue^, exchange^, routing_key^
        )

    # ---- messaging ----

    def publish(
        mut self,
        var exchange: String,
        var routing_key: String,
        var body: List[UInt8],
    ) raises -> Int:
        """Publish a body through an exchange. Returns number of queues routed.
        """
        return self._adapter.publish(
            self._engine, routing_key^, body^, exchange^
        )

    # ---- 0017 T2: publish with byte-faithful content props ----

    def publish_with_props(
        mut self,
        var exchange: String,
        var routing_key: String,
        var body: List[UInt8],
        prop_flags: UInt16,
        var prop_bytes: List[UInt8],
    ) raises -> Int:
        """Publish a body + the publisher's own content header (flag word +
        raw property-list slice). Returns number of queues routed."""
        return self._adapter.publish_with_props(
            self._engine, routing_key^, body^, exchange^,
            prop_flags, prop_bytes^,
        )

    # 0017 T3: the DEFAULT exchange ("") publish — DIRECT into the queue
    # named by the routing key (the exchange's pre-bound direct binding).
    def publish_to_queue_with_props(
        mut self,
        var queue_name: String,
        var body: List[UInt8],
        prop_flags: UInt16,
        var prop_bytes: List[UInt8],
    ) raises -> Int:
        """Publish straight into a named queue (the default exchange's
        normative direct binding). Returns 1 = routed / 0 = unrouted."""
        return self._adapter.publish_to_queue_with_props(
            self._engine, queue_name^, body^, prop_flags, prop_bytes^,
        )

    def content_prop_flags(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> UInt16:        """Read an unacked delivery's raw AMQP property-flag word."""
        return self._adapter.queue_content_prop_flags(
            self._engine, consumer_id, delivery_tag
        )

    def content_prop_bytes_copy(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Read an owned copy of an unacked delivery's raw AMQP property-list
        bytes (the publisher's slice — transmitted outbound byte-identically)."""
        return self._adapter.queue_content_prop_bytes_copy(
            self._engine, consumer_id, delivery_tag
        )

    def redelivered(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Bool:
        """Whether an unacked delivery is a re-delivery (AMQP redelivered bit)."""
        return self._adapter.queue_redelivered(self._engine, consumer_id, delivery_tag)

    def consume_register(mut self, var queue: String) raises -> UInt64:
        """Register a consumer on a queue. Returns consumer_id (issued by the
        engine, the single routing authority)."""
        return self._adapter.consume(self._engine, queue^)

    def deliver(mut self, consumer_id: UInt64) raises -> Optional[Delivery]:
        """Deliver the next message for a consumer, or None."""
        return self._adapter.deliver_next(self._engine, consumer_id)

    def read_payload(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Read a delivered message's payload bytes (message stays owned)."""
        return self._adapter.read_payload(self._engine, consumer_id, delivery_tag)

    def queue_routing_key(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> String:
        """Read a delivered message's routing key through the engine boundary."""
        return self._adapter.queue_routing_key(
            self._engine, consumer_id, delivery_tag
        )

    def queue_message_count(mut self, consumer_id: UInt64) raises -> Int:
        """Return the consumer queue's pending (ready) message count."""
        return self._adapter.queue_message_count(self._engine, consumer_id)

    def ack(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Bool:
        """Acknowledge a delivery."""
        return self._adapter.acknowledge(self._engine, consumer_id, delivery_tag)

    def reject(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Reject a delivery (requeue)."""
        return self._adapter.reject(self._engine, consumer_id, delivery_tag)

    # ---- 0017 T1 management surface (additive; adapter = the one translator) ----

    def has_queue(ref self, var name: String) -> Bool:
        """Queue presence (404 preflight for purge/delete/unbind)."""
        return self._adapter.has_queue(self._engine, name^)

    def has_exchange(ref self, var name: String) -> Bool:
        """Exchange presence (404 preflight)."""
        return self._adapter.has_exchange(self._engine, name^)

    def purge_queue(mut self, var name: String) raises -> Int:
        """queue.purge (50,30): -1 = missing queue, else purged count."""
        return self._adapter.purge_queue(self._engine, name^)

    def delete_queue_checked(
        mut self, var name: String, if_empty: Bool, if_unused: Bool
    ) raises -> Int:
        """queue.delete (50,40): -1 missing / -2 not empty / -3 in use."""
        return self._adapter.delete_queue_checked(
            self._engine, name^, if_empty, if_unused
        )

    def delete_exchange_checked(
        mut self, var name: String, if_unused: Bool
    ) raises -> Int:
        """exchange.delete (40,20): -1 missing / -2 in use."""
        return self._adapter.delete_exchange_checked(self._engine, name^, if_unused)

    def bind_exchange(
        mut self,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """exchange.bind (40,30) exchange→exchange."""
        return self._adapter.bind_exchange(
            self._engine, source^, destination^, routing_key^
        )

    def unbind_exchange(
        mut self,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """exchange.unbind (40,40)."""
        return self._adapter.unbind_exchange(
            self._engine, source^, destination^, routing_key
        )

    def unbind_queue(
        mut self,
        var queue: String,
        var exchange: String,
        var routing_key: String,
    ) raises -> Bool:
        """queue.unbind (50,50)."""
        return self._adapter.unbind_queue(
            self._engine, queue^, exchange^, routing_key
        )

    def unregister_consumer(mut self, consumer_id: UInt64) raises -> Bool:
        """Consumer deregistration (teardown path; requeues unacked)."""
        return self._adapter.unregister_consumer(self._engine, consumer_id)

    def bulk_ack(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Int:
        """basic.ack multiple=true: ack every tag <= tag (0 = all)."""
        return self._adapter.bulk_ack(self._engine, consumer_id, delivery_tag)

    def nack(
        mut self, consumer_id: UInt64, delivery_tag: UInt64, requeue: Bool
    ) raises -> Bool:
        """basic.nack (60,120) single tag: requeue or drop."""
        return self._adapter.nack(
            self._engine, consumer_id, delivery_tag, requeue
        )

    def nack_through(
        mut self, consumer_id: UInt64, delivery_tag: UInt64, requeue: Bool
    ) raises -> Int:
        """basic.nack (60,120) multiple=true: every tag <= tag."""
        return self._adapter.nack_through(
            self._engine, consumer_id, delivery_tag, requeue
        )

    # ---- management surface ----

    def status(ref self) -> BrokerStatus:
        """Assemble a read-only status snapshot from the engine + lifecycle."""
        var stats = self._engine.stats()
        var s = BrokerStatus()
        s.node_name = self._config.node_name
        s.vhost = self._config.vhost
        s.uptime = self._started
        s.ready = self._state == BROKER_STATE_READY()
        # Socket bind lives in AMQPListener, not here; False = "this broker
        # surface holds no bound socket" (the listener wires one on top).
        s.listening = False
        s.queues = stats.active_queues
        s.consumers = stats.active_consumers
        s.messages_published = stats.messages_published
        s.messages_delivered = stats.messages_delivered
        s.messages_acked = stats.messages_acknowledged
        return s^

    def health(ref self) -> String:
        """Deterministic health string: ok / starting / degraded."""
        if self._state == BROKER_STATE_READY():
            return "ok"
        if self._state == BROKER_STATE_STARTING():
            return "starting"
        return "degraded"

    def ready(ref self) -> Bool:
        return self._state == BROKER_STATE_READY()

    def node_name(ref self) -> String:
        return self._config.node_name

    # ---- protocol path ----

    def protocol_selfcheck(mut self) raises -> Bool:
        """Exercise the composed AMQPAdapter (Layer 4) end to end.

        The adapter holds no routing substrate of its own: every call below is
        executed on THIS broker's engine, so the selfcheck proves translation and
        routing on the single authority. Consequence (deliberate): the "ps-*"
        topology and message counters are visible in status(), i.e. the
        selfcheck is not side-effect free.
        It is NOT the network path (in-process only; the socket path is proven
        separately in tests/integration/broker_tcp_e2e.mojo).
        """
        if not self._adapter.declare_exchange(
            self._engine, "ps-ex", "direct", durable=False
        ):
            return False
        if not self._adapter.declare_queue(self._engine, "ps-q", durable=False):
            return False
        if not self._adapter.bind_queue(self._engine, "ps-q", "ps-ex", "ps-k"):
            return False
        var body = List[UInt8]()
        body.append(0x50)  # 'P'
        if self._adapter.publish(self._engine, "ps-k", body^, "ps-ex") < 1:
            return False
        var cid = self._adapter.consume(self._engine, "ps-q")
        var d = self._adapter.deliver_next(self._engine, cid)
        if not d.__bool__():
            return False
        return self._adapter.acknowledge(self._engine, cid, d.value().delivery_tag())
