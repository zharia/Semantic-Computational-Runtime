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

    def ack(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Bool:
        """Acknowledge a delivery."""
        return self._adapter.acknowledge(self._engine, consumer_id, delivery_tag)

    def reject(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Reject a delivery (requeue)."""
        return self._adapter.reject(self._engine, consumer_id, delivery_tag)

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
