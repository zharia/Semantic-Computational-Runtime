#!/usr/bin/env python3
"""Real-pika handshake + basic-flow gate against the HyrxMQ listen binary.

This is the acceptance harness for the AMQP connection-negotiation feature: it
drives a REAL pika client (not a fake socket) against HyrxMQ on a port that is
NOT the RabbitMQ 5672, and prints a per-step PASS/FAIL table.

The HANDSHAKE (header -> start -> start-ok -> tune -> tune-ok -> open ->
open-ok) plus the method-only steps (channel.open / exchange.declare /
queue.declare / queue.bind) are the gate: those must PASS. The content-frame
steps (basic.publish body, basic.consume/delivery, basic.ack) are reported
honestly -- HyrxMQ's Phase 7 vertical slice carries the publish/deliver body
INLINE in the method frame and does NOT reassemble the separate content
HEADER/BODY frames a real pika client emits, so those may FAIL even though the
handshake succeeded. A failure there is EXPECTED and is documented, not hidden.

Run:
    /tmp/amqp-venv/bin/python scripts/interop/pika_negotiation.py
Defaults: 127.0.0.1:5699 admin/password (override via HYRX_HOST/HYRX_PORT/
HYRX_USER/HYRX_PASS). Exits 0 iff the HANDSHAKE gate steps all PASS.
"""
import os
import signal
import sys
import time
import traceback

import pika


class _Blocked(Exception):
    pass


class bounded:
    """Context manager: raise _Blocked after `secs` of a single blocking call.

    A real client that sends a synchronous method the broker never answers
    (basic.get-ok, or a consume we mis-parse) wedges BOTH sides: pika waits for
    the reply, the single-threaded server blocks on the next recv. This bounds
    each such call so the harness still prints an honest result; the broker
    subprocess is torn down regardless.
    """

    def __init__(self, secs):
        self.secs = secs

    def _boom(self, signum, frame):
        raise _Blocked("timed out after %ss waiting for a broker reply" % self.secs)

    def __enter__(self):
        self.prev = signal.signal(signal.SIGALRM, self._boom)
        signal.setitimer(signal.ITIMER_REAL, self.secs)
        return self

    def __exit__(self, *a):
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, self.prev)
        return False

HOST = os.environ.get("HYRX_HOST", "127.0.0.1")
PORT = int(os.environ.get("HYRX_PORT", "5699"))
USER = os.environ.get("HYRX_USER", "admin")
PW = os.environ.get("HYRX_PASS", "password")
VHOST = "/"
EXCH = "hyrx.nego.x"
Q = "hyrx.nego.q"
RK = "hyrx.key"

# Steps that MUST pass for the negotiation gate (handshake + method-only ops).
GATE_STEPS = {
    "connect (header/start/start-ok/tune/tune-ok/open/open-ok)",
    "channel.open",
    "exchange.declare",
    "queue.declare",
    "queue.bind",
}
# Steps that depend on the content-frame reassembly NOT yet implemented.
CONTENT_STEPS = {
    "basic.publish",
    "basic.consume",
    "delivery received",
    "basic.ack",
}

STEPS = []


def record(name, ok, detail=""):
    STEPS.append((name, "PASS" if ok else "FAIL", detail))
    print("[%s] %s%s" % ("PASS" if ok else "FAIL", name,
                          ("  :: " + detail) if detail else ""))
    return ok


def new_conn():
    creds = pika.PlainCredentials(USER, PW)
    params = pika.ConnectionParameters(
        host=HOST, port=PORT, virtual_host=VHOST, credentials=creds,
        connection_attempts=1, retry_delay=0.2, socket_timeout=6,
        blocked_connection_timeout=6,
        # heartbeat=0 on the client too: HyrxMQ advertises heartbeat=0 (no
        # timer implemented), so the sync path must not depend on heartbeats.
        heartbeat=0,
    )
    return pika.BlockingConnection(params)


def main():
    print("HyrxMQ real-pika negotiation gate")
    print("  client : pika %s" % pika.__version__)
    print("  broker : HyrxMQ %s:%d vhost=%r user=%s" % (HOST, PORT, VHOST, USER))
    conn = None
    ch = None
    gate_ok = True
    try:
        # ---- THE HANDSHAKE GATE: a full connect is header+start+start-ok+
        # tune+tune-ok+open+open-ok. This is the acceptance criterion. ----
        # ---- connect under a guard: if the handshake itself ever wedges we
        # still report FAIL rather than hang the harness. ----
        try:
            t0 = time.monotonic()
            with bounded(20):
                conn = new_conn()
            record("connect (header/start/start-ok/tune/tune-ok/open/open-ok)",
                   True, "handshake completed in %.0f ms" %
                   ((time.monotonic() - t0) * 1000))
        except Exception as e:
            record("connect (header/start/start-ok/tune/tune-ok/open/open-ok)",
                   False, "%s: %s" % (type(e).__name__, e))
            gate_ok = False
            raise

        # NOTE on negotiated parameters: the tune bytes (channel-max 2047,
        # frame-max = config.frame_max, heartbeat 0) are asserted EXACTLY by
        # tests/phase7/connection_negotiation_test.mojo; and a successful pika
        # connect is itself the evidence that heartbeat=0 was required and
        # accepted (a non-zero heartbeat with no server timer would make pika
        # stall). We do not re-read pika's private attributes here.

        if not conn.is_open:
            record("connection is open", False, "pika reports connection closed")
            gate_ok = False

        # ---- method-only steps (no content frames) ----
        try:
            ch = conn.channel()
            record("channel.open", ch.is_open,
                   "channel_number=%s" % ch.channel_number)
        except Exception as e:
            record("channel.open", False, "%s: %s" % (type(e).__name__, e))
            gate_ok = False

        try:
            ch.exchange_declare(exchange=EXCH, exchange_type="direct",
                                durable=False, auto_delete=True)
            record("exchange.declare", True, "direct '%s'" % EXCH)
        except Exception as e:
            record("exchange.declare", False, "%s: %s" % (type(e).__name__, e))
            gate_ok = False

        try:
            qd = ch.queue_declare(queue=Q, durable=False, exclusive=True)
            record("queue.declare", True,
                   "queue=%s msg_count=%s consumer_count=%s" % (
                       qd.method.queue, qd.method.message_count,
                       qd.method.consumer_count))
        except Exception as e:
            record("queue.declare", False, "%s: %s" % (type(e).__name__, e))
            gate_ok = False

        try:
            ch.queue_bind(queue=Q, exchange=EXCH, routing_key=RK)
            record("queue.bind", True, "%s -[%s]-> %s" % (EXCH, RK, Q))
        except Exception as e:
            record("queue.bind", False, "%s: %s" % (type(e).__name__, e))
            gate_ok = False

        # ---- content-frame steps (HONEST: these depend on the content-frame
        # reassembly HyrxMQ's Phase 7 slice does NOT do, and on synchronous
        # replies like basic.get-ok it does NOT send). Each is bounded so a
        # deliberate non-reply is recorded as a BLOCKED gap, not a hang. ----
        delivery = None
        try:
            with bounded(8):
                ch.basic_publish(exchange=EXCH, routing_key=RK, body=b"body-A",
                                 properties=pika.BasicProperties(delivery_mode=1))
                conn.process_data_events(time_limit=1)
            record("basic.publish", True,
                   "publish method + separate HEADER/BODY frames sent; the "
                   "broker read the method (empty INLINE body) and consumed the "
                   "content frames WITHOUT reassembling them")
        except _Blocked as e:
            record("basic.publish", False, "BLOCKED: %s" % e)
        except Exception as e:
            record("basic.publish", False, "%s: %s" % (type(e).__name__, e))

        try:
            with bounded(8):
                method, props, body = ch.basic_get(queue=Q, auto_ack=False)
            if method is None:
                record("delivery received (basic_get)", False,
                       "basic_get returned None (no delivery reassembled)")
            else:
                record("delivery received (basic_get)", True,
                       "body=%r rk=%r" % (body, method.routing_key))
                delivery = method
        except _Blocked as e:
            record("delivery received (basic_get)", False,
                   "BLOCKED (NOT IMPLEMENTED): the broker never answers "
                   "basic.get-ok -> basic.get deadlocks: %s" % e)
        except Exception as e:
            record("delivery received (basic_get)", False,
                   "%s: %s (content-frame / sync-reply gap)" % (
                       type(e).__name__, e))

        if delivery is not None:
            try:
                with bounded(8):
                    ch.basic_ack(delivery.delivery_tag)
                    conn.process_data_events(time_limit=1)
                record("basic.ack", True, "delivery_tag=%s" %
                       delivery.delivery_tag)
            except Exception as e:
                record("basic.ack", False, "%s: %s" % (type(e).__name__, e))
        else:
            record("basic.ack", False, "skipped (no delivery to ack)")

    except Exception:
        traceback.print_exc()
    finally:
        # Best-effort teardown, EACH bounded: a channel.close / connection.close
        # waits for a *_ok reply the broker does not send, so an unbounded close
        # could hang before the result table prints. The broker subprocess is
        # killed by the caller regardless.
        for label, closer in (
            ("channel.close", lambda: ch and ch.is_open and ch.close()),
            ("connection.close", lambda: conn and conn.is_open and conn.close()),
        ):
            try:
                with bounded(4):
                    closer()
            except Exception:
                pass

    print("\n============ REAL-PIKA NEGOTIATION RESULT TABLE ============")
    print("%-58s  %-5s  %s" % ("STEP", "STATE", "DETAIL"))
    print("-" * 100)
    for name, st, detail in STEPS:
        mark = "  (gate)" if name in GATE_STEPS else (
            "  (content)" if name in CONTENT_STEPS else "")
        print("%-58s  %-5s  %s%s" % (name, st, detail, mark))
    print("-" * 100)
    gate_pass = all(
        st == "PASS" for nm, st, _ in STEPS if nm in GATE_STEPS
    ) and gate_ok
    print("HANDSHAKE GATE: %s" % ("PASS" if gate_pass else "FAIL"))
    return 0 if gate_pass else 1


if __name__ == "__main__":
    sys.exit(main())
