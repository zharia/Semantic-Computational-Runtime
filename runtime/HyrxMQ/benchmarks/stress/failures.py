"""Failure injector for AMQP stress testing.

Simulates production failure conditions to measure broker resilience:
- Network interruptions (TCP reset, partition simulation)
- Connection drops mid-publish
- Channel errors (publish to non-existent exchange, bad routing)
- Queue exhaustion / memory pressure
- Consumer cancellation storms
- Rapid connect/disconnect cycles
- Malformed AMQP frames (via raw socket)

Each failure scenario runs as an independent test, recording:
- Recovery time (time from fault to broker accepting work again)
- Error rate during fault
- Data loss (messages published but not consumed)
- Broker stability (did it crash? OOM? deadlock?)
"""
import os
import socket
import struct
import sys
import threading
import time

import pika
import pika.exceptions


def _connect(url, heartbeat=0):
    params = pika.URLParameters(url)
    params.heartbeat = heartbeat
    return pika.BlockingConnection(params)


def _make_body(size):
    return os.urandom(size)


# ---------------------------------------------------------------------------
# Scenario: connection drop mid-publish
# ---------------------------------------------------------------------------
def scenario_connection_drop(url, queue_name, body_size, num_messages,
                             drop_at, metrics):
    """Publish drop_at messages, kill the connection, reconnect, continue.

    drop_at: index of message where connection is severed.
    """
    body = _make_body(body_size)

    # Phase 1: publish up to drop_at
    conn = _connect(url)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)

    published = 0
    for i in range(drop_at):
        ch.basic_publish(exchange='', routing_key=queue_name, body=body)
        published += 1

    # Phase 2: kill connection without clean close
    t_kill = time.monotonic()
    try:
        conn._impl._transport._writer.close()
    except Exception:
        pass
    try:
        conn.close()
    except Exception:
        pass

    # Phase 3: wait, then reconnect and continue
    time.sleep(0.5)
    t_reconnect_start = time.monotonic()
    reconnected = False
    for attempt in range(20):
        try:
            conn = _connect(url)
            ch = conn.channel()
            ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)
            reconnected = True
            break
        except Exception:
            time.sleep(0.5)

    t_reconnected = time.monotonic()
    recovery_ms = (t_reconnected - t_reconnect_start) * 1000

    remaining = num_messages - published
    for i in range(max(0, remaining)):
        try:
            ch.basic_publish(exchange='', routing_key=queue_name, body=body)
            published += 1
        except Exception:
            break

    try:
        conn.close()
    except Exception:
        pass

    metrics.record_scenario('connection_drop', {
        'published_before': drop_at,
        'published_after': published - drop_at,
        'total_published': published,
        'target': num_messages,
        'recovery_ms': round(recovery_ms, 2),
        'reconnected': reconnected,
    })


# ---------------------------------------------------------------------------
# Scenario: channel error (invalid exchange)
# ---------------------------------------------------------------------------
def scenario_channel_error(url, body_size, num_messages, error_at, metrics):
    """Publish to a non-existent exchange at error_at, causing channel close."""
    body = _make_body(body_size)
    conn = _connect(url)
    ch = conn.channel()

    published = 0
    for i in range(num_messages):
        if i == error_at:
            try:
                ch.basic_publish(exchange='nonexistent_exchange',
                                 routing_key='key', body=body)
            except Exception:
                pass
            # channel is now closed — reopen
            try:
                ch = conn.channel()
            except Exception:
                break
        else:
            try:
                ch.basic_publish(exchange='', routing_key='test_queue',
                                 body=body)
                published += 1
            except Exception:
                try:
                    ch = conn.channel()
                except Exception:
                    break

    try:
        conn.close()
    except Exception:
        pass

    metrics.record_scenario('channel_error', {
        'published': published,
        'target': num_messages,
        'error_at': error_at,
    })


# ---------------------------------------------------------------------------
# Scenario: rapid connect/disconnect
# ---------------------------------------------------------------------------
def scenario_rapid_reconnect(url, queue_name, num_cycles, metrics):
    """Open connection, declare queue, close. Repeat num_cycles times."""
    start = time.monotonic()
    successes = 0
    failures = 0

    for i in range(num_cycles):
        try:
            conn = _connect(url)
            ch = conn.channel()
            ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)
            ch.queue_delete(queue=queue_name)
            conn.close()
            successes += 1
        except Exception:
            failures += 1
            time.sleep(0.1)

    elapsed = time.monotonic() - start
    metrics.record_scenario('rapid_reconnect', {
        'cycles': num_cycles,
        'successes': successes,
        'failures': failures,
        'elapsed_s': round(elapsed, 3),
        'cycles_per_s': round(num_cycles / elapsed, 1) if elapsed > 0 else 0,
    })


# ---------------------------------------------------------------------------
# Scenario: consumer cancellation storm
# ---------------------------------------------------------------------------
def scenario_consumer_storm(url, queue_name, body_size, num_consumers,
                            num_messages, metrics):
    """Start N consumers, publish messages, cancel all consumers mid-flight."""
    body = _make_body(body_size)
    conn = _connect(url)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)

    consumed = [0] * num_consumers
    stop = threading.Event()
    consumer_threads = []
    tag_to_thread = {}

    for i in range(num_consumers):
        def consumer_fn(idx, counts):
            c = _connect(url)
            ch_ = c.channel()
            ch_.basic_qos(prefetch_count=10)
            tag = ch_.basic_consume(
                queue=queue_name,
                on_message_callback=lambda c_, m, p, b: (
                    counts.__setitem__(idx, counts[idx] + 1),
                    c_.basic_ack(delivery_tag=m.delivery_tag)
                ),
                auto_ack=False)

            while not stop.is_set():
                try:
                    c.process_data_events(time_limit=0.05)
                except Exception:
                    break
            try:
                c.close()
            except Exception:
                pass

        t = threading.Thread(target=consumer_fn, args=(i, consumed))
        t.daemon = True
        t.start()
        consumer_threads.append(t)

    time.sleep(1.0)

    # publish half the messages
    half = num_messages // 2
    for _ in range(half):
        ch.basic_publish(exchange='', routing_key=queue_name, body=body)

    # cancel all consumers mid-flight
    t_cancel = time.monotonic()
    for tag in list(tag_to_thread.keys()):
        try:
            ch.basic_cancel(tag)
        except Exception:
            pass

    # publish remaining
    for _ in range(num_messages - half):
        try:
            ch.basic_publish(exchange='', routing_key=queue_name, body=body)
        except Exception:
            break

    time.sleep(1.0)
    stop.set()
    for t in consumer_threads:
        t.join(timeout=3)

    try:
        conn.close()
    except Exception:
        pass

    metrics.record_scenario('consumer_storm', {
        'consumers': num_consumers,
        'messages_published': num_messages,
        'messages_consumed': sum(consumed),
        'per_consumer': consumed,
    })


# ---------------------------------------------------------------------------
# Scenario: queue exhaustion (backpressure)
# ---------------------------------------------------------------------------
def scenario_queue_exhaustion(url, queue_name, body_size, publish_count,
                              prefetch, metrics):
    """Publish many messages, single slow consumer. Measures backpressure."""
    body = _make_body(body_size)
    conn = _connect(url)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)
    ch.basic_qos(prefetch_count=prefetch)

    # publish burst
    t0 = time.monotonic()
    published = 0
    blocked = False
    for _ in range(publish_count):
        try:
            ch.basic_publish(exchange='', routing_key=queue_name, body=body)
            published += 1
        except pika.exceptions.ChannelClosed as e:
            metrics.record_error('exhaustion', str(e),
                                 time.monotonic() - t0)
            blocked = True
            try:
                ch = conn.channel()
            except Exception:
                break
        except Exception as e:
            metrics.record_error('exhaustion', str(e),
                                 time.monotonic() - t0)
            blocked = True
            break

    t_publish_done = time.monotonic()
    publish_time_ms = (t_publish_done - t0) * 1000

    # slow consumer: take 10ms per message
    consumed = 0
    def on_msg(c_, m, p, b_):
        nonlocal consumed
        consumed += 1
        time.sleep(0.01)
        c_.basic_ack(delivery_tag=m.delivery_tag)

    ch.basic_consume(queue=queue_name, on_message_callback=on_msg)
    t_drain_start = time.monotonic()
    while consumed < published:
        try:
            conn.process_data_events(time_limit=0.1)
        except Exception:
            break
    t_drain_done = time.monotonic()
    drain_time_ms = (t_drain_done - t_drain_start) * 1000

    try:
        conn.close()
    except Exception:
        pass

    metrics.record_scenario('queue_exhaustion', {
        'published': published,
        'target': publish_count,
        'consumed': consumed,
        'blocked': blocked,
        'publish_time_ms': round(publish_time_ms, 2),
        'drain_time_ms': round(drain_time_ms, 2),
        'prefetch': prefetch,
    })


# ---------------------------------------------------------------------------
# Scenario: malformed AMQP frame (raw socket)
# ---------------------------------------------------------------------------
def scenario_malformed_frame(host, port, num_frames, metrics):
    """Send raw garbage bytes to the AMQP port to test frame parser resilience."""
    start = time.monotonic()
    accepted = 0
    errors = 0
    sock = None

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2.0)
        sock.connect((host, port))

        # read AMQP protocol header
        try:
            sock.recv(256)
        except Exception:
            pass

        for i in range(num_frames):
            try:
                if i % 3 == 0:
                    # random garbage
                    frame = os.urandom(64)
                elif i % 3 == 1:
                    # partially valid AMQP frame header + garbage
                    frame = struct.pack('>BI', 1, 64) + os.urandom(64)
                else:
                    # valid length prefix but wrong type
                    frame = struct.pack('>BIB', 1, 32, 99) + os.urandom(32)
                sock.sendall(frame)
                accepted += 1
                time.sleep(0.01)
            except (socket.error, BrokenPipeError, ConnectionResetError):
                errors += 1
                # reconnect
                try:
                    sock.close()
                except Exception:
                    pass
                try:
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(2.0)
                    sock.connect((host, port))
                    try:
                        sock.recv(256)
                    except Exception:
                        pass
                except Exception:
                    break

    except Exception as e:
        metrics.record_error('malformed_frame', str(e),
                             time.monotonic() - start)
    finally:
        if sock:
            try:
                sock.close()
            except Exception:
                pass

    elapsed = time.monotonic() - start
    metrics.record_scenario('malformed_frame', {
        'frames_sent': accepted,
        'target': num_frames,
        'errors': errors,
        'elapsed_s': round(elapsed, 3),
    })


# ---------------------------------------------------------------------------
# Scenario: sustained heartbeat starvation
# ---------------------------------------------------------------------------
def scenario_heartbeat_starve(url, queue_name, body_size, duration_s,
                              metrics):
    """Establish connection, then stall the event loop (simulate slow consumer).
    Broker should either close the connection or keep it alive per heartbeat."""
    body = _make_body(body_size)
    conn = _connect(url, heartbeat=5)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)

    start = time.monotonic()
    published = 0
    heartbeat_ok = True

    try:
        while time.monotonic() - start < duration_s:
            try:
                ch.basic_publish(exchange='', routing_key=queue_name,
                                 body=body)
                published += 1
            except Exception:
                heartbeat_ok = False
                break
            # intentionally stall: do NOT process events
            time.sleep(0.5)

        # try to recover
        ch2 = conn.channel()
        ch2.queue_declare(queue=queue_name, durable=False, auto_delete=True)
    except Exception:
        heartbeat_ok = False

    try:
        conn.close()
    except Exception:
        pass

    metrics.record_scenario('heartbeat_starve', {
        'duration_s': duration_s,
        'published': published,
        'heartbeat_ok': heartbeat_ok,
    })


SCENARIOS = {
    'connection_drop': scenario_connection_drop,
    'channel_error': scenario_channel_error,
    'rapid_reconnect': scenario_rapid_reconnect,
    'consumer_storm': scenario_consumer_storm,
    'queue_exhaustion': scenario_queue_exhaustion,
    'malformed_frame': scenario_malformed_frame,
    'heartbeat_starve': scenario_heartbeat_starve,
}
