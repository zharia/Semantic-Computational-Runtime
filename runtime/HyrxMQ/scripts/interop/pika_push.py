#!/usr/bin/env python3
"""RC-3 pika async-push gate: basic_consume FIRST, then basic.publish.

The original pika content harness only exercised publish-before-subscribe
(pull-on-subscribe). This gate drives a REAL pika client the way the standard
multi-client suites do — subscribe to an EMPTY queue, then publish — and
asserts the broker pushes the basic.deliver asynchronously (no basic.get).

Spawns build/hyrxmq-listen on HYRXMQ_PORT (default 5701, never 5672), runs the
flow, then tears the subprocess down. Exit 0 iff the body arrives byte-equal.
"""
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BIN = os.environ.get("HYRXMQ_BIN", os.path.join(ROOT, "build", "hyrxmq-listen"))
PORT = int(os.environ.get("HYRXMQ_PORT", "5701"))
HOST = os.environ.get("HYRX_HOST", "127.0.0.1")
USER = os.environ.get("HYRX_USER", "admin")
PW = os.environ.get("HYRX_PASS", "password")
BODY = b"pika-async-push-body"

proc = subprocess.Popen(
    [BIN],
    env={**os.environ, "HYRXMQ_HOST": HOST, "HYRXMQ_PORT": str(PORT)},
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
try:
    time.sleep(1.0)
    import pika

    params = pika.ConnectionParameters(
        host=HOST,
        port=PORT,
        virtual_host="/",
        credentials=pika.PlainCredentials(USER, PW),
        heartbeat=0,
        blocked_connection_timeout=10,
    )
    conn = pika.BlockingConnection(params)
    ch = conn.channel()
    q = "pika.push.q"
    ch.queue_declare(queue=q, durable=False, auto_delete=False, exclusive=False)

    got = []
    # auto_ack consumer (no-ack) registered while the queue is EMPTY.
    ch.basic_consume(
        queue=q,
        on_message_callback=lambda *a: got.append(a[3]),
        auto_ack=True,
    )
    # publish AFTER consume; a pull-on-subscribe broker delivers nothing here.
    ch.basic_publish(exchange="", routing_key=q, body=BODY)
    deadline = time.time() + 5
    while not got and time.time() < deadline:
        conn.process_data_events(time_limit=1)

    ok = len(got) > 0 and got[0] == BODY
    print("delivered:", got)
    print("PIKA_ASYNC_PUSH=" + ("PASS" if ok else "FAIL"))
    conn.close()
    rc = 0 if ok else 1
finally:
    proc.terminate()
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
sys.exit(rc)
