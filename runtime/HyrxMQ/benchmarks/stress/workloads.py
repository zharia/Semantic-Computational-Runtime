"""Workload generators for AMQP stress testing.

Defines workload patterns that exercise different broker dimensions:
- Throughput saturation (publish as fast as possible)
- Sustained steady-state (constant rate over time)
- Fan-out (multiple consumers per queue)
- Bursty traffic (alternating idle/full-blast phases)
- Mixed pub/sub (exchanges, routing, multiple queues)
- Large message payloads (memory pressure)

Each workload is a function that runs in a thread, writing time-series
metrics into a shared collector.
"""
import os
import sys
import threading
import time
import uuid

import pika
import pika.exceptions


def _connect(url, heartbeat=0, blocked_connection_timeout=None):
    params = pika.URLParameters(url)
    params.heartbeat = heartbeat
    if blocked_connection_timeout:
        params.blocked_connection_timeout = blocked_connection_timeout
    return pika.BlockingConnection(params)


def _make_body(size):
    return os.urandom(size)


# ---------------------------------------------------------------------------
# Workload: saturated throughput
# ---------------------------------------------------------------------------
def workload_saturated(url, queue_name, body_size, duration_s,
                       metrics, tag='pub', ack=True, prefetch=1):
    """Maximum throughput: publish or consume as fast as possible for duration_s.

    tag: 'pub' or 'sub' — controls which leg this thread runs.
    """
    conn = _connect(url)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)

    body = _make_body(body_size)
    start = time.monotonic()
    count = 0

    if tag == 'pub':
        while time.monotonic() - start < duration_s:
            try:
                ch.basic_publish(exchange='', routing_key=queue_name,
                                 body=body)
                count += 1
                if count % 1000 == 0:
                    metrics.record(tag, count, time.monotonic() - start,
                                   body_size)
            except (pika.exceptions.NackError,
                    pika.exceptions.ChannelClosed) as e:
                metrics.record_error(tag, str(e), time.monotonic() - start)
                break
        metrics.record(tag, count, time.monotonic() - start, body_size,
                       final=True)
    else:
        ch.basic_qos(prefetch_count=prefetch)
        received = []

        def on_msg(ch_, method, props, body_):
            received.append(time.monotonic())
            if ack:
                ch_.basic_ack(delivery_tag=method.delivery_tag)

        ch.basic_consume(queue=queue_name, on_message_callback=on_msg)
        deadline = time.monotonic() + duration_s
        while time.monotonic() < deadline:
            try:
                ch.connection.process_data_events(time_limit=0.1)
            except Exception:
                break
        count = len(received)
        metrics.record(tag, count, time.monotonic() - start, body_size,
                       final=True)

    conn.close()


# ---------------------------------------------------------------------------
# Workload: sustained constant rate
# ---------------------------------------------------------------------------
def workload_steady(url, queue_name, body_size, duration_s,
                    msgs_per_sec, metrics, tag='pub'):
    """Publish or consume at a fixed rate for duration_s."""
    conn = _connect(url)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)

    body = _make_body(body_size)
    interval = 1.0 / msgs_per_sec
    start = time.monotonic()
    count = 0
    next_send = start

    if tag == 'pub':
        while time.monotonic() - start < duration_s:
            now = time.monotonic()
            if now < next_send:
                time.sleep(min(next_send - now, 0.01))
                continue
            try:
                ch.basic_publish(exchange='', routing_key=queue_name,
                                 body=body)
                count += 1
                next_send += interval
                if count % 500 == 0:
                    metrics.record(tag, count, time.monotonic() - start,
                                   body_size)
            except Exception as e:
                metrics.record_error(tag, str(e), time.monotonic() - start)
                break
        metrics.record(tag, count, time.monotonic() - start, body_size,
                       final=True)
    else:
        ch.basic_qos(prefetch_count=msgs_per_sec)
        received = []

        def on_msg(ch_, method, props, body_):
            received.append(time.monotonic())
            ch_.basic_ack(delivery_tag=method.delivery_tag)

        ch.basic_consume(queue=queue_name, on_message_callback=on_msg)
        deadline = time.monotonic() + duration_s
        while time.monotonic() < deadline:
            try:
                ch.connection.process_data_events(time_limit=0.1)
            except Exception:
                break
        metrics.record(tag, len(received), time.monotonic() - start,
                       body_size, final=True)

    conn.close()


# ---------------------------------------------------------------------------
# Workload: bursty traffic
# ---------------------------------------------------------------------------
def workload_bursty(url, queue_name, body_size, duration_s,
                    burst_size, burst_interval_s, metrics):
    """Alternating: burst of burst_size publishes, then idle for burst_interval_s."""
    conn = _connect(url)
    ch = conn.channel()
    ch.queue_declare(queue=queue_name, durable=False, auto_delete=True)

    body = _make_body(body_size)
    start = time.monotonic()
    count = 0
    burst_count = 0
    in_burst = False
    burst_start = 0.0

    while time.monotonic() - start < duration_s:
        now = time.monotonic()

        if not in_burst:
            # idle phase — wait until next burst
            elapsed_bursts = count // burst_size if burst_size else 0
            next_burst_time = start + elapsed_bursts * burst_interval_s
            if now < next_burst_time:
                time.sleep(min(next_burst_time - now, 0.01))
                continue
            in_burst = True
            burst_start = now
            burst_count = 0

        if burst_count >= burst_size:
            in_burst = False
            metrics.record('burst', burst_count, now - start, body_size)
            continue

        try:
            ch.basic_publish(exchange='', routing_key=queue_name, body=body)
            count += 1
            burst_count += 1
        except Exception as e:
            metrics.record_error('burst', str(e), now - start)
            break

    metrics.record('burst', count, time.monotonic() - start, body_size,
                   final=True)
    conn.close()


# ---------------------------------------------------------------------------
# Workload: fan-out (multiple consumers)
# ---------------------------------------------------------------------------
def workload_fanout(url, exchange_name, body_size, duration_s,
                    num_consumers, metrics):
    """Publish to a fanout exchange, N consumers each get every message."""
    conn = _connect(url)
    ch = conn.channel()
    ch.exchange_declare(exchange=exchange_name, exchange_type='fanout')

    consumer_counts = [0] * num_consumers
    consumer_ready = threading.Event()
    stop_event = threading.Event()
    consumer_threads = []

    for i in range(num_consumers):
        qname = f'fanout_{exchange_name}_{i}_{uuid.uuid4().hex[:6]}'
        ch.queue_declare(queue=qname, durable=False, auto_delete=True)
        ch.queue_bind(queue=qname, exchange=exchange_name)

        def consumer_fn(url_, qname_, idx, counts):
            c = _connect(url_)
            ch_ = c.channel()
            ch_.basic_qos(prefetch_count=100)

            def on_msg(ch_, method, props, body_):
                counts[idx] += 1
                ch_.basic_ack(delivery_tag=method.delivery_tag)

            ch_.basic_consume(queue=qname_, on_message_callback=on_msg)
            consumer_ready.set()
            while not stop_event.is_set():
                try:
                    ch_.connection.process_data_events(time_limit=0.1)
                except Exception:
                    break
            c.close()

        t = threading.Thread(target=consumer_fn,
                             args=(url, qname, i, consumer_counts))
        t.daemon = True
        t.start()
        consumer_threads.append(t)

    consumer_ready.wait(timeout=10)
    time.sleep(0.5)  # let consumers settle

    body = _make_body(body_size)
    start = time.monotonic()
    count = 0
    while time.monotonic() - start < duration_s:
        try:
            ch.basic_publish(exchange=exchange_name, routing_key='',
                             body=body)
            count += 1
            if count % 1000 == 0:
                metrics.record('fanout_pub', count, time.monotonic() - start,
                               body_size)
        except Exception as e:
            metrics.record_error('fanout_pub', str(e), time.monotonic() - start)
            break

    metrics.record('fanout_pub', count, time.monotonic() - start, body_size,
                   final=True)
    stop_event.set()
    for t in consumer_threads:
        t.join(timeout=5)
    for idx, c in enumerate(consumer_counts):
        metrics.record(f'fanout_sub_{idx}', c, time.monotonic() - start,
                       body_size, final=True)

    conn.close()


# ---------------------------------------------------------------------------
# Workload: mixed exchange routing
# ---------------------------------------------------------------------------
def workload_mixed(url, body_size, duration_s, metrics):
    """Publish to direct + topic exchanges with multiple routing keys."""
    conn = _connect(url)
    ch = conn.channel()

    exchanges = [
        ('direct_test', 'direct', [('key_a', ['key_a']), ('key_b', ['key_b'])]),
        ('topic_test', 'topic', [
            ('orders.create', ['orders.#']),
            ('orders.cancel', ['orders.#']),
            ('logs.info', ['logs.*']),
            ('logs.error', ['logs.*']),
        ]),
    ]

    queues_declared = set()
    for ex_name, ex_type, bindings in exchanges:
        ch.exchange_declare(exchange=ex_name, exchange_type=ex_type)
        for key, patterns in bindings:
            qname = f'mixed_{ex_name}_{key}'
            if qname not in queues_declared:
                ch.queue_declare(queue=qname, durable=False, auto_delete=True)
                for pat in patterns:
                    ch.queue_bind(queue=qname, exchange=ex_name,
                                  routing_key=pat)
                queues_declared.add(qname)

    body = _make_body(body_size)
    start = time.monotonic()
    count = 0
    round_robin_keys = []
    for ex_name, _, bindings in exchanges:
        for key, _ in bindings:
            round_robin_keys.append((ex_name, key))

    idx = 0
    while time.monotonic() - start < duration_s:
        ex_name, key = round_robin_keys[idx % len(round_robin_keys)]
        try:
            ch.basic_publish(exchange=ex_name, routing_key=key, body=body)
            count += 1
            idx += 1
            if count % 1000 == 0:
                metrics.record('mixed', count, time.monotonic() - start,
                               body_size)
        except Exception as e:
            metrics.record_error('mixed', str(e), time.monotonic() - start)
            break

    metrics.record('mixed', count, time.monotonic() - start, body_size,
                   final=True)

    # drain
    for qname in queues_declared:
        try:
            ch.queue_purge(queue=qname)
        except Exception:
            pass

    conn.close()


# ---------------------------------------------------------------------------
# Workload: large message body
# ---------------------------------------------------------------------------
def workload_large(url, queue_name, body_size, duration_s, metrics):
    """Publish and consume large messages (memory pressure test)."""
    return workload_saturated(url, queue_name, body_size, duration_s,
                              metrics, tag='pub')


WORKLOAD_REGISTRY = {
    'saturated_pub': lambda url, q, sz, dur, **kw: workload_saturated(
        url, q, sz, dur, kw['metrics'], tag='pub', **{k: v for k, v in kw.items() if k != 'metrics'}),
    'saturated_sub': lambda url, q, sz, dur, **kw: workload_saturated(
        url, q, sz, dur, kw['metrics'], tag='sub', **{k: v for k, v in kw.items() if k != 'metrics'}),
    'steady_pub': lambda url, q, sz, dur, **kw: workload_steady(
        url, q, sz, dur, kw.get('rate', 1000), kw['metrics'], tag='pub'),
    'steady_sub': lambda url, q, sz, dur, **kw: workload_steady(
        url, q, sz, dur, kw.get('rate', 1000), kw['metrics'], tag='sub'),
    'bursty': lambda url, q, sz, dur, **kw: workload_bursty(
        url, q, sz, dur, kw.get('burst_size', 500),
        kw.get('burst_interval', 2.0), kw['metrics']),
    'fanout': lambda url, q, sz, dur, **kw: workload_fanout(
        url, q, sz, dur, kw.get('num_consumers', 4), kw['metrics']),
    'mixed': lambda url, q, sz, dur, **kw: workload_mixed(
        url, q, sz, dur, kw['metrics']),
    'large': lambda url, q, sz, dur, **kw: workload_large(
        url, q, sz, dur, kw['metrics']),
}
