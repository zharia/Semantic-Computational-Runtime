# AMQP-to-Hyrx translation layer.
#
# Translates AMQP protocol operations into Hyrx semantic operations.
# This is the boundary between the wire protocol and the core engine: it is the
# ONLY place that maps AMQP concepts (exchange-type names, method arguments)
# onto Hyrx concepts.
#
# Architecture (AGENTS.md rules 5/6/14, "Providers implement contracts; they do
# not own them"): the adapter owns NO routing substrate. It never constructs a
# router. The single routing authority is the broker's HyrxEngine (whose core
# Router is the one and only routing object); the adapter receives that engine
# as an injected `mut` handle on every call and translates into engine calls.
# Auditing `grep -n "Router(" src/` shows no construction here at all: the only
# construction site is src/hyrx/embedded/api.mojo (the engine that owns it).

from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.core.buffer import Buffer
from hyrx.core.queue import Delivery
from hyrx.embedded.api import HyrxEngine
from std.memory import unsafe_memcpy


def exchange_type_from_name(var name: String) -> ExchangeType:
    """Map an AMQP exchange-type name to a Hyrx ExchangeType.

    Single mapping (was previously duplicated in the broker with a different
    result for "headers"): "headers" maps to ExchangeType.headers(). Header
    matching is a documented stub in core (src/hyrx/core/exchange.mojo:181 —
    the headers branch currently matches all bindings), so a "headers" exchange
    behaves like fanout until the stub is implemented. It is NOT silently
    re-typed as direct anywhere.

    NOT IMPLEMENTED: headers-based matching semantics.
    """
    if name == "fanout":
        return ExchangeType.fanout()
    if name == "topic":
        return ExchangeType.topic()
    if name == "headers":
        return ExchangeType.headers()
    return ExchangeType.direct()


struct AMQPAdapter:
    """Translates AMQP operations to Hyrx operations on an injected engine.

    Stateless with respect to routing: every operation is performed on the
    `mut engine: HyrxEngine` handle passed in, which the broker owns.
    """

    def __init__(out self):
        pass

    def declare_exchange(
        mut self,
        mut engine: HyrxEngine,
        var name: String,
        var exchange_type: String,
        durable: Bool,
    ) raises -> Bool:
        """Translate AMQP exchange.declare to Hyrx. True if created.

        NOT IMPLEMENTED: `durable` is not represented in the core engine
        (no persistence layer yet); the flag is accepted and ignored, never
        used to change routing semantics.
        """
        _ = durable
        return engine.declare_exchange(name^, exchange_type_from_name(exchange_type^))

    def declare_queue(
        mut self, mut engine: HyrxEngine, var name: String, durable: Bool
    ) raises -> Bool:
        """Translate AMQP queue.declare to Hyrx. True if created.

        NOT IMPLEMENTED: `durable` (see declare_exchange) plus exclusive /
        auto-delete queue properties, which the engine does not model.
        """
        _ = durable
        return engine.declare_queue(name^)

    def bind_queue(
        mut self,
        mut engine: HyrxEngine,
        var queue: String,
        var exchange: String,
        var routing_key: String,
    ) raises -> Bool:
        """Translate AMQP queue.bind to Hyrx."""
        return engine.bind_queue(queue^, exchange^, routing_key^)

    def publish(
        mut self,
        mut engine: HyrxEngine,
        var routing_key: String,
        var body: List[UInt8],
        var exchange_name: String,
    ) raises -> Int:
        """Translate AMQP basic.publish to Hyrx. Returns queues routed to.

        NOT IMPLEMENTED: content properties (the AMQP property table) are not
        carried; the envelope's header map stays empty because field tables are
        not serialized on the wire yet (see src/hyrx/amqp/field_table.mojo).
        """
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(0), routing_key^, headers^)
        var buf = Buffer(len(body))
        buf.resize_uninit(len(body))
        unsafe_memcpy(
            dest=buf._data.unsafe_ptr(),
            src=body.unsafe_ptr(),
            count=len(body),
        )
        var msg = Message(env^, buf^)
        return engine.publish(msg^, exchange_name^)

    # 0017 T2: publish WITH the byte-faithful content properties.
    def publish_with_props(
        mut self,
        mut engine: HyrxEngine,
        var routing_key: String,
        var body: List[UInt8],
        var exchange_name: String,
        prop_flags: UInt16,
        var prop_bytes: List[UInt8],
    ) raises -> Int:
        """Translate AMQP basic.publish carrying the publisher's own content
        header (flag word + raw property-list slice). Transmitted outbound
        byte-identically on deliver/get-ok."""
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(0), routing_key^, headers^)
        var buf = Buffer(len(body))
        buf.resize_uninit(len(body))
        unsafe_memcpy(
            dest=buf._data.unsafe_ptr(),
            src=body.unsafe_ptr(),
            count=len(body),
        )
        var msg = Message(env^, buf^, prop_flags, prop_bytes^)
        return engine.publish(msg^, exchange_name^)

    # ---- 0017 T2 readouts ----

    def queue_content_prop_flags(
        ref self, mut engine: HyrxEngine, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> UInt16:
        """Translate the raw AMQP property-flag word of an unacked delivery."""
        return engine.queue_prop_flags(consumer_id, delivery_tag)

    def queue_content_prop_bytes_copy(
        ref self, mut engine: HyrxEngine, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Translate the raw AMQP property-list chars of an unacked delivery
        (owned copy of the publisher's slice)."""
        return engine.queue_prop_bytes_copy(consumer_id, delivery_tag)

    def queue_redelivered(
        ref self, mut engine: HyrxEngine, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Translate the redelivered AMQP bit of an unacked delivery."""
        return engine.queue_redelivery(consumer_id, delivery_tag)

    def consume(
        mut self, mut engine: HyrxEngine, var queue_name: String
    ) raises -> UInt64:
        """Translate AMQP basic.consume to Hyrx. Returns the engine's consumer id.

        The id is issued by the routing authority (the engine), NOT by a local
        adapter counter, so ids observed on the wire always identify a real
        engine consumer.

        NOT IMPLEMENTED: prefetch/no Ack handling beyond the engine default,
        consumer tags (the wire layer reports the numeric id).
        """
        return engine.consume(queue_name^, 0)

    def deliver_next(
        mut self, mut engine: HyrxEngine, consumer_id: UInt64
    ) raises -> Optional[Delivery]:
        """Translate AMQP basic.deliver from Hyrx."""
        return engine.next_message(consumer_id)

    def read_payload(
        mut self, mut engine: HyrxEngine, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Read a delivered message's payload bytes (message stays owned)."""
        var view = engine.read_payload(consumer_id, delivery_tag)
        return view.take_bytes()

    def queue_routing_key(
        mut self, mut engine: HyrxEngine, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> String:
        """Read a delivery routing key from the injected routing authority."""
        return engine.queue_routing_key(consumer_id, delivery_tag)

    def queue_message_count(
        mut self, mut engine: HyrxEngine, consumer_id: UInt64
    ) raises -> Int:
        """Return the consumer queue's pending (ready) message count."""
        return engine.queue_message_count(consumer_id)

    def acknowledge(
        mut self,
        mut engine: HyrxEngine,
        consumer_id: UInt64,
        delivery_tag: UInt64,
    ) raises -> Bool:
        """Translate AMQP basic.ack (multiple=false) to Hyrx.

        NOT IMPLEMENTED: basic.ack with multiple=true ("up to and including")
        — the engine only acknowledges one delivery tag at a time.
        """
        return engine.acknowledge(consumer_id, delivery_tag)

    def reject(
        mut self,
        mut engine: HyrxEngine,
        consumer_id: UInt64,
        delivery_tag: UInt64,
    ) raises -> Bool:
        """Translate AMQP basic.nack/reject to Hyrx.

        NOT IMPLEMENTED: the `requeue` bit — the engine always requeues.
        """
        return engine.reject(consumer_id, delivery_tag)

    # ---- 0017 T1 translations (additive; single routing authority = engine) ----

    def has_queue(ref self, ref engine: HyrxEngine, var name: String) -> Bool:
        """Queue presence preflight before queue.purge/delete (404 table)."""
        return engine.has_queue(name^)

    def has_exchange(ref self, ref engine: HyrxEngine, var name: String) -> Bool:
        """Exchange presence preflight before delete (404 table)."""
        return engine.has_exchange(name^)

    def purge_queue(mut self, mut engine: HyrxEngine, var name: String) raises -> Int:
        """Translate AMQP queue.purge (50,30). -1 = missing queue."""
        return engine.purge_queue(name^)

    def delete_queue_checked(
        mut self,
        mut engine: HyrxEngine,
        var name: String,
        if_empty: Bool,
        if_unused: Bool,
    ) raises -> Int:
        """Translate AMQP queue.delete (50,40); sentinels -1/-2/-3."""
        return engine.delete_queue_checked(name^, if_empty, if_unused)

    def delete_exchange_checked(
        mut self, mut engine: HyrxEngine, var name: String, if_unused: Bool
    ) raises -> Int:
        """Translate AMQP exchange.delete (40,20); sentinels -1/-2."""
        return engine.delete_exchange_checked(name^, if_unused)

    def bind_exchange(
        mut self,
        mut engine: HyrxEngine,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """Translate AMQP exchange.bind (40,30)."""
        return engine.bind_exchange(source^, destination^, routing_key^)

    def unbind_exchange(
        mut self,
        mut engine: HyrxEngine,
        var source: String,
        var destination: String,
        var routing_key: String,
    ) raises -> Bool:
        """Translate AMQP exchange.unbind (40,40)."""
        return engine.unbind_exchange(source^, destination^, routing_key)

    def unbind_queue(
        mut self,
        mut engine: HyrxEngine,
        var queue: String,
        var exchange: String,
        var routing_key: String,
    ) raises -> Bool:
        """Translate AMQP queue.unbind (50,50)."""
        return engine.unbind_queue(queue^, exchange^, routing_key)

    def unregister_consumer(
        mut self, mut engine: HyrxEngine, consumer_id: UInt64
    ) raises -> Bool:
        """Translate consumer deregistration (channel/connection teardown)."""
        return engine.unregister_consumer(consumer_id)

    def bulk_ack(
        mut self, mut engine: HyrxEngine, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Int:
        """Translate AMQP basic.ack multiple=true: every tag <= tag."""
        return engine.bulk_ack(consumer_id, delivery_tag)

    def nack(
        mut self,
        mut engine: HyrxEngine,
        consumer_id: UInt64,
        delivery_tag: UInt64,
        requeue: Bool,
    ) raises -> Bool:
        """Translate AMQP basic.nack (60,120) single tag."""
        return engine.nack(consumer_id, delivery_tag, requeue)

    def nack_through(
        mut self,
        mut engine: HyrxEngine,
        consumer_id: UInt64,
        delivery_tag: UInt64,
        requeue: Bool,
    ) raises -> Int:
        """Translate AMQP basic.nack (60,120) multiple=true."""
        return engine.nack_through(consumer_id, delivery_tag, requeue)
