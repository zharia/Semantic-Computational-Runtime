# AMQP-to-Hyrx translation layer.
#
# Translates AMQP protocol operations into Hyrx semantic operations.
# This is the boundary between the wire protocol and the core engine.

from hyrx.core.router import Router
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.core.buffer import Buffer
from hyrx.core.queue import Delivery


struct AMQPAdapter:
    """Translates AMQP operations to Hyrx operations."""

    var _router: Router
    var _next_consumer_id: UInt64

    def __init__(out self):
        self._router = Router()
        self._next_consumer_id = 0

    def declare_exchange(
        mut self, var name: String, var exchange_type: String, durable: Bool
    ) raises -> Bool:
        """Translate AMQP exchange.declare to Hyrx."""
        var et: ExchangeType
        if exchange_type == "direct":
            et = ExchangeType.direct()
        elif exchange_type == "fanout":
            et = ExchangeType.fanout()
        elif exchange_type == "topic":
            et = ExchangeType.topic()
        else:
            et = ExchangeType.direct()
        return self._router.declare_exchange(name^, et^)

    def declare_queue(
        mut self, var name: String, durable: Bool
    ) raises -> Bool:
        """Translate AMQP queue.declare to Hyrx."""
        return self._router.declare_queue(name^, 1024)

    def bind_queue(
        mut self, var queue: String, var exchange: String, var routing_key: String
    ) raises -> Bool:
        """Translate AMQP queue.bind to Hyrx."""
        return self._router.bind_queue(queue^, exchange^, routing_key^)

    def publish(
        mut self, var routing_key: String, var body: List[UInt8], var exchange_name: String
    ) raises -> Int:
        """Translate AMQP basic.publish to Hyrx."""
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(0), routing_key^, headers^)
        var buf = Buffer(len(body))
        buf.resize(len(body))
        for i in range(len(body)):
            buf[i] = body[i]
        var msg = Message(env^, buf^)
        return self._router.publish(msg^, exchange_name)

    def consume(
        mut self, var queue_name: String
    ) raises -> UInt64:
        """Translate AMQP basic.consume to Hyrx."""
        var cid = self._next_consumer_id
        self._next_consumer_id += 1
        _ = self._router.register_consumer(queue_name, 0)
        return cid

    def deliver_next(
        mut self, consumer_id: UInt64
    ) raises -> Optional[Delivery]:
        """Translate AMQP basic.deliver from Hyrx."""
        return self._router.consume(consumer_id)

    def read_payload(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        """Read a delivered message's payload bytes (message stays owned)."""
        var view = self._router.read_payload(consumer_id, delivery_tag)
        return view.to_bytes()

    def acknowledge(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Translate AMQP basic.ack to Hyrx."""
        return self._router.acknowledge(consumer_id, delivery_tag)

    def reject(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> Bool:
        """Translate AMQP basic.nack/reject to Hyrx."""
        return self._router.reject(consumer_id, delivery_tag)
