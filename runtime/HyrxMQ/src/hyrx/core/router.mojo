# Central routing engine.
#
# Ties together exchanges, queues, and consumers.
# Routes published messages to queue destinations via exchange matching.
#
# Ownership model:
#   - Router owns all exchanges, queues, and consumers.
#   - publish() creates new messages from the original's data for each destination.
#   - consume() returns a Delivery claim token (message stays in queue).
#   - acknowledge() and reject() operate on the queue's message copy.

from std.collections import List

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_view import BufferView
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import Exchange, ExchangeType, Binding
from hyrx.core.queue import Queue, QueueConfig, Delivery
from hyrx.core.consumer import Consumer

struct Router:
    """Core routing engine. Routes published messages to queue destinations."""

    var _exchanges: Dict[String, Exchange]
    var _queues: Dict[String, Queue]
    var _consumers: Dict[UInt64, Consumer]
    var _next_consumer_id: UInt64
    var _messages_routed: Int

    def __init__(out self):
        self._exchanges = Dict[String, Exchange]()
        self._queues = Dict[String, Queue]()
        self._consumers = Dict[UInt64, Consumer]()
        self._next_consumer_id = 0
        self._messages_routed = 0

    # ---- exchange management ------------------------------------------

    def declare_exchange(
        mut self, var name: String, var exchange_type: ExchangeType
    ) raises -> Bool:
        """Declare an exchange. Returns True if created, False if exists."""
        if name in self._exchanges:
            return False
        self._exchanges[name^] = Exchange(name, exchange_type^)
        return True

    def delete_exchange(mut self, name: String) raises -> Bool:
        """Delete an exchange. Returns True if found and deleted."""
        if name in self._exchanges:
            _ = self._exchanges.pop(name)
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
        """Delete a queue. Returns list of unacked messages for cleanup."""
        var result = List[Message]()
        if name in self._queues:
            _ = self._queues.pop(name)
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
    ) -> Bool:
        """Unbind a queue from an exchange.

        Returns True if unbound, False if not found.
        """
        if exchange_name not in self._exchanges:
            return False
        return self._exchanges[exchange_name].remove_binding(
            queue_name, routing_key
        )

    # ---- publishing ---------------------------------------------------

    def publish(
        mut self, var msg: Message, exchange_name: String
    ) raises -> Int:
        """Route a message through an exchange to bound queues.

        Creates new messages for each destination queue, copying the
        routing key and payload data from the original.
        Returns the number of queues the message was routed to.

        Ownership: msg is consumed (destroyed after routing).
        """
        if exchange_name not in self._exchanges:
            return 0

        # Get routing key (borrows from msg, does not consume)
        var queue_names = self._exchanges[exchange_name].match(
            msg.routing_key()
        )
        var count = 0

        for i in range(len(queue_names)):
            var qname = queue_names[i]
            if qname in self._queues:
                # Create a new message for this queue, copying the data
                var headers = Dict[String, String]()
                var env = Envelope(
                    MessageID(0), msg.routing_key(), headers^
                )
                var view = msg.payload()
                var payload = Buffer(view.size())
                payload.resize(view.size())
                for j in range(view.size()):
                    payload[j] = view[j]
                var cloned = Message(env^, payload^)
                if self._queues[qname].enqueue(cloned^):
                    count += 1

        self._messages_routed += count
        return count

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
        return cid

    def unregister_consumer(mut self, consumer_id: UInt64) raises -> Bool:
        """Unregister a consumer. Returns True if found and removed."""
        if consumer_id in self._consumers:
            _ = self._consumers.pop(consumer_id)
            return True
        return False

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
        var result = self._queues[qname].acknowledge(delivery_tag)
        if result:
            self._consumers[consumer_id].record_ack()
        return result

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
    ) raises -> BufferView:
        """Read the payload of a delivered message.

        The message remains owned by the queue.
        """
        var qname = self._consumers[consumer_id].queue_name()
        return self._queues[qname].read_payload(delivery_tag)

    # ---- stats --------------------------------------------------------

    def messages_routed(ref self) -> Int:
        return self._messages_routed

    def exchange_count(ref self) -> Int:
        return len(self._exchanges)

    def queue_count(ref self) -> Int:
        return len(self._queues)

    def consumer_count(ref self) -> Int:
        return len(self._consumers)
