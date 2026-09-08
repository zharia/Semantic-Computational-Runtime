# Consumer registration and demand tracking.
#
# A Consumer represents a registered delivery target for a queue.
# It tracks prefetch limits and active (unacked) deliveries.
#
# Ownership model:
#   - Consumer is a value type (copyable via implicit struct copy).
#   - No heap-allocated fields; all fields are value types.

struct Consumer:
    """A registered delivery target for a queue."""

    var _id: UInt64
    var _queue_name: String
    var _prefetch: Int
    var _active_deliveries: Int

    def __init__(
        out self,
        consumer_id: UInt64,
        var queue_name: String,
        prefetch: Int,
    ):
        self._id = consumer_id
        self._queue_name = queue_name^
        self._prefetch = prefetch
        self._active_deliveries = 0

    def id(self) -> UInt64:
        return self._id

    def queue_name(ref self) -> String:
        return self._queue_name

    def prefetch(self) -> Int:
        return self._prefetch

    def active_deliveries(self) -> Int:
        return self._active_deliveries

    def can_deliver(ref self) -> Bool:
        """True if consumer can accept more deliveries.

        Returns True if prefetch is 0 (unlimited) or
        active_deliveries < prefetch.
        """
        if self._prefetch == 0:
            return True
        return self._active_deliveries < self._prefetch

    def record_delivery(mut self):
        """Record that a delivery was sent to this consumer."""
        self._active_deliveries += 1

    def record_ack(mut self):
        """Record that a delivery was acknowledged.

        active_deliveries decreases by 1 (clamped to 0).
        """
        if self._active_deliveries > 0:
            self._active_deliveries -= 1
