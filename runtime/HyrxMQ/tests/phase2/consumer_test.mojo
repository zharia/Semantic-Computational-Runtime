# Tests for Consumer prefetch and delivery tracking.
#
# Covers: can_deliver with prefetch limits, record_delivery/record_ack.

from hyrx.core.consumer import Consumer

from hyrx.testing import check

def test_unlimited_prefetch() raises:
    """Consumer with prefetch=0 can always deliver."""
    var c = Consumer(1, "test-queue", 0)
    check(c.can_deliver() == True, "L10 expect: c.can_deliver() == True")
    c.record_delivery()
    check(c.can_deliver() == True, "L12 expect: c.can_deliver() == True")
    c.record_delivery()
    check(c.can_deliver() == True, "L14 expect: c.can_deliver() == True")

def test_limited_prefetch() raises:
    """Consumer with prefetch=N limits active deliveries."""
    var c = Consumer(2, "test-queue", 3)
    check(c.can_deliver() == True, "L19 expect: c.can_deliver() == True")

    c.record_delivery()
    check(c.active_deliveries() == 1, "L22 expect: c.active_deliveries() == 1")
    check(c.can_deliver() == True, "L23 expect: c.can_deliver() == True")

    c.record_delivery()
    check(c.active_deliveries() == 2, "L26 expect: c.active_deliveries() == 2")
    check(c.can_deliver() == True, "L27 expect: c.can_deliver() == True")

    c.record_delivery()
    check(c.active_deliveries() == 3, "L30 expect: c.active_deliveries() == 3")
    check(c.can_deliver() == False, "L31 expect: c.can_deliver() == False")

    # After ack, can deliver again
    c.record_ack()
    check(c.active_deliveries() == 2, "L35 expect: c.active_deliveries() == 2")
    check(c.can_deliver() == True, "L36 expect: c.can_deliver() == True")

def test_ack_clamps_to_zero() raises:
    """record_ack does not go below 0."""
    var c = Consumer(3, "q", 5)
    check(c.active_deliveries() == 0, "L41 expect: c.active_deliveries() == 0")
    c.record_ack()  # Should not go negative
    check(c.active_deliveries() == 0, "L43 expect: c.active_deliveries() == 0")

def test_consumer_id_and_queue() raises:
    """Consumer exposes id and queue_name correctly."""
    var c = Consumer(42, "my-queue", 10)
    check(c.id() == 42, "L48 expect: c.id() == 42")
    check(c.queue_name() == "my-queue", "L49 expect: c.queue_name() == 'my-queue'")
    check(c.prefetch() == 10, "L50 expect: c.prefetch() == 10")

def test_record_delivery_increments() raises:
    """Multiple deliveries increment active count."""
    var c = Consumer(5, "q", 100)
    c.record_delivery()
    c.record_delivery()
    c.record_delivery()
    check(c.active_deliveries() == 3, "L58 expect: c.active_deliveries() == 3")

def test_full_cycle() raises:
    """Full cycle: deliver, ack, deliver, reject (ack on reject)."""
    var c = Consumer(6, "q", 2)

    # Deliver two (at limit)
    c.record_delivery()
    c.record_delivery()
    check(c.can_deliver() == False, "L67 expect: c.can_deliver() == False")

    # Ack one
    c.record_ack()
    check(c.can_deliver() == True, "L71 expect: c.can_deliver() == True")

    # Deliver one more
    c.record_delivery()
    check(c.can_deliver() == False, "L75 expect: c.can_deliver() == False")

    # Ack both remaining
    c.record_ack()
    c.record_ack()
    check(c.active_deliveries() == 0, "L80 expect: c.active_deliveries() == 0")
    check(c.can_deliver() == True, "L81 expect: c.can_deliver() == True")

def main() raises:
    test_unlimited_prefetch()
    test_limited_prefetch()
    test_ack_clamps_to_zero()
    test_consumer_id_and_queue()
    test_record_delivery_increments()
    test_full_cycle()
    print("CONSUMER_TEST=PASS")
