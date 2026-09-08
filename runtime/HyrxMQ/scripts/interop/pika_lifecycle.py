#!/usr/bin/env python3
"""RabbitMQ reference baseline for the HyrxMQ real-client interop gate (audit 11/12).

Exercises the AMQP lifecycle a real client performs and prints a per-step
PASS/FAIL table. This is the REFERENCE behavior capture: it MUST pass against
the running RabbitMQ, validating the harness itself and recording what
"correct AMQP" looks like for the differential matrix.

Run:
    /tmp/amqp-venv/bin/python scripts/interop/pika_lifecycle.py
Defaults: 127.0.0.1:5672 admin/password (override via RABBIT_HOST/RABBIT_PORT/
RABBIT_USER/RABBIT_PASS env).

Exit 0 iff every recorded step is PASS (a real gate, not a print-and-hope).
"""
import os
import sys
import time
import traceback

import pika

HOST = os.environ.get("RABBIT_HOST", "127.0.0.1")
PORT = int(os.environ.get("RABBIT_PORT", "5672"))
USER = os.environ.get("RABBIT_USER", "admin")
PW = os.environ.get("RABBIT_PASS", "password")
VHOST = "/"
EXCH = "hyrx.interop.x"
Q = "hyrx.interop.q"
RK = "hyrx.key"

STEPS = []


def record(name, ok, detail=""):
    STEPS.append((name, "PASS" if ok else "FAIL", detail))
    print("[%s] %s%s" % ("PASS" if ok else "FAIL", name,
                          ("  :: " + detail) if detail else ""))
    return ok


def new_conn(vhost=VHOST, user=USER, pw=PW, timeout=6):
    creds = pika.PlainCredentials(user, pw)
    params = pika.ConnectionParameters(
        host=HOST, port=PORT, virtual_host=vhost, credentials=creds,
        connection_attempts=1, retry_delay=0.2, socket_timeout=timeout,
        blocked_connection_timeout=timeout, heartbeat=60,
    )
    return pika.BlockingConnection(params)


def main():
    print("HyrxMQ interop REFERENCE baseline")
    print("  client : pika %s" % pika.__version__)
    print("  broker : %s:%d vhost=%r" % (HOST, PORT, VHOST))
    conn = None
    ch = None
    gen = None
    try:
        # 1 connect + 2 authenticate (successful PLAIN handshake)
        try:
            t0 = time.monotonic()
            conn = new_conn()
            sp = conn._impl.server_properties
            record("connect", True, "in %.0f ms; server=%s v%s (%s)" % (
                (time.monotonic() - t0) * 1000, sp.get("product"),
                sp.get("version"), sp.get("platform")))
        except Exception as e:
            record("connect", False, "%s: %s" % (type(e).__name__, e))
            raise

        # 2b authenticate is actually enforced: wrong creds must be refused
        try:
            bad = new_conn(user=USER, pw="definitely-wrong-" + USER)
            record("authenticate (negative)", False, "bad password accepted")
            bad.close()
        except Exception as e:
            accepted = "ProbableAuthenticationError" in type(e).__name__ or \
                "ACCESS_REFUSED" in str(e) or "403" in str(e)
            record("authenticate (negative)", accepted,
                   "refused via %s" % type(e).__name__)

        # 3 open vhost "/"
        cur_vhost = conn._impl.params.virtual_host
        record("open vhost '/'", bool(conn.is_open) and cur_vhost == VHOST,
               "vhost=%r" % cur_vhost)

        # 4 open channel
        try:
            ch = conn.channel()
            record("channel.open", ch.is_open, "channel_number=%s" % ch.channel_number)
        except Exception as e:
            record("channel.open", False, "%s: %s" % (type(e).__name__, e))

        # 5 exchange.declare (direct)
        try:
            ch.exchange_declare(exchange=EXCH, exchange_type="direct",
                                durable=False, auto_delete=True)
            record("exchange.declare", True, "direct '%s'" % EXCH)
        except Exception as e:
            record("exchange.declare", False, "%s: %s" % (type(e).__name__, e))

        # 6 queue.declare
        # NOTE (real broker behavior captured): RabbitMQ 4.3.5 rejects
        # transient NON-exclusive queues by default (541 INTERNAL_ERROR,
        # feature `transient_nonexcl_queues` deprecated). An EXCLUSIVE queue is
        # the correct way to get a short-lived, auto-cleaned-up test queue.
        try:
            qd = ch.queue_declare(queue=Q, durable=False, exclusive=True)
            record("queue.declare", True,
                   "msg_count=%s consumer_count=%s (exclusive)" % (qd.method.message_count,
                                                                    qd.method.consumer_count))
        except Exception as e:
            record("queue.declare", False, "%s: %s" % (type(e).__name__, e))

        # 7 queue.bind
        try:
            ch.queue_bind(queue=Q, exchange=EXCH, routing_key=RK)
            record("queue.bind", True, "%s -[%s]-> %s" % (EXCH, RK, Q))
        except Exception as e:
            record("queue.bind", False, "%s: %s" % (type(e).__name__, e))

        # 8 basic.publish (message A)
        try:
            ch.basic_publish(exchange=EXCH, routing_key=RK, body=b"body-A",
                             properties=pika.BasicProperties(delivery_mode=1))
            conn.process_data_events(time_limit=1)
            record("basic.publish", True, "body-A")
        except Exception as e:
            record("basic.publish", False, "%s: %s" % (type(e).__name__, e))

        # 9 basic.consume (register a manual-ack pull generator)
        try:
            gen = iter(ch.consume(queue=Q, auto_ack=False,
                                  inactivity_timeout=3))
            record("basic.consume", True, "auto_ack=False, inactivity_timeout=3s")
        except Exception as e:
            record("basic.consume", False, "%s: %s" % (type(e).__name__, e))

        # 10 delivery received (pull A)
        delivery_A = None
        try:
            got = next(gen)
            assert got is not None, "no delivery (timed out)"
            method, props, body = got
            delivery_A = method
            ok = body == b"body-A" and method.routing_key == RK
            record("delivery received", ok,
                   "body=%r exchange=%r rk=%r redelivered=%s" %
                   (body, method.exchange, method.routing_key, method.redelivered))
        except Exception as e:
            record("delivery received", False, "%s: %s" % (type(e).__name__, e))

        # 11 basic.ack (A)
        try:
            ch.basic_ack(delivery_A.delivery_tag)
            conn.process_data_events(time_limit=1)
            record("basic.ack", True, "delivery_tag=%s" % delivery_A.delivery_tag)
        except Exception as e:
            record("basic.ack", False, "%s: %s" % (type(e).__name__, e))

        # 12 prefetch / QoS
        try:
            ch.basic_qos(prefetch_count=10)
            record("prefetch/QoS (basic.qos)", True, "prefetch_count=10")
        except Exception as e:
            record("prefetch/QoS (basic.qos)", False, "%s: %s" % (type(e).__name__, e))

        # publish message B to exercise nack/redelivery, then pull it
        delivery_B = None
        try:
            ch.basic_publish(exchange=EXCH, routing_key=RK, body=b"body-B")
            got = next(gen)
            assert got is not None, "no delivery for B (timed out)"
            delivery_B = got[0]
            record("delivery received (B, pre-nack)", True,
                   "body=%r" % got[2])
        except Exception as e:
            record("delivery received (B, pre-nack)", False,
                   "%s: %s" % (type(e).__name__, e))

        # 13 basic.nack(requeue=True) on B
        try:
            ch.basic_nack(delivery_B.delivery_tag, requeue=True)
            conn.process_data_events(time_limit=1)
            record("basic.nack(requeue=True)", True,
                   "delivery_tag=%s" % delivery_B.delivery_tag)
        except Exception as e:
            record("basic.nack(requeue=True)", False,
                   "%s: %s" % (type(e).__name__, e))

        # 14 redelivery observed (B again, redelivered flag set)
        try:
            got = next(gen)
            assert got is not None, "no redelivery (timed out)"
            method2, _p2, body2 = got
            ok = body2 == b"body-B" and method2.redelivered is True
            record("redelivery observed", ok,
                   "body=%r redelivered=%s" % (body2, method2.redelivered))
            ch.basic_ack(method2.delivery_tag)  # settle B
            conn.process_data_events(time_limit=1)
        except Exception as e:
            record("redelivery observed", False, "%s: %s" % (type(e).__name__, e))

        # 15 channel close
        try:
            if ch.is_open:
                ch.close()
            record("channel.close", not ch.is_open, "closed")
        except Exception as e:
            record("channel.close", not ch.is_open, "%s (state=%s)" % (
                type(e).__name__, "closed" if not ch.is_open else "open"))

        # 16 connection close
        try:
            if conn.is_open:
                conn.close()
            record("connection.close", not conn.is_open, "closed")
        except Exception as e:
            record("connection.close", not conn.is_open, "%s (state=%s)" % (
                type(e).__name__, "closed" if not conn.is_open else "open"))

        # 17 reconnect (fresh connection + channel + passive declare works)
        try:
            c2 = new_conn()
            ch2 = c2.channel()
            ch2.queue_declare(queue=Q, passive=True)  # queue gone (auto_delete) -> may fail; tolerate by direct declare
            record("reconnect", c2.is_open and ch2.is_open, "reconnected + new channel")
            ch2.close()
            c2.close()
        except Exception:
            # passive may raise NotFound if auto_delete already removed Q; retry with plain reconnect
            try:
                c2 = new_conn()
                ch2 = c2.channel()
                ok = c2.is_open and ch2.is_open
                record("reconnect", ok, "reconnected (fresh conn+channel)")
                ch2.close()
                c2.close()
            except Exception as e:
                record("reconnect", False, "%s: %s" % (type(e).__name__, e))
                traceback.print_exc()

    finally:
        # best-effort teardown; never mask the recorded outcome
        for closer in (lambda: ch and ch.is_open and ch.close(),
                       lambda: conn and conn.is_open and conn.close()):
            try:
                closer()
            except Exception:
                pass

    # ---- table ----
    print("\n===================== BASELINE RESULT TABLE =====================")
    print("%-32s  %-5s  %s" % ("STEP", "STATE", "DETAIL"))
    print("-" * 78)
    fails = 0
    for name, st, detail in STEPS:
        if st == "FAIL":
            fails += 1
        print("%-32s  %-5s  %s" % (name, st, detail))
    print("-" * 78)
    total = len(STEPS)
    print("TOTAL %d   PASS %d   FAIL %d" % (total, total - fails, fails))
    verdict = "PASS" if fails == 0 else "FAIL"
    print("BASELINE VERDICT: %s" % verdict)
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
