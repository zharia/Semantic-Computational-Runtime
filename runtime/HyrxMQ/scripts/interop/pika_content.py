#!/usr/bin/env python3
"""Real-pika CONTENT-FRAME acceptance gate: publish -> consume/get -> ack.

This is the acceptance harness for the AMQP 0-9-1 content-frame reassembly
feature (the gap left after connection negotiation). It drives a REAL pika
client (pika 1.4.4) — not a fake socket — and asserts byte-equal bodies on BOTH
delivery paths:

  Flow A (consumer): open -> channel -> exchange.declare(direct) ->
    queue.declare -> queue.bind -> basic_publish(b"hello-hyrx") ->
    basic_consume -> delivery body == b"hello-hyrx" -> basic_ack.

  Flow B (get): publish -> basic_get(queue) -> get-ok body == published -> ack;
    then basic_get on the now-empty queue -> None (get-empty) within a timeout.

The SAME two flows are run against two brokers, in this order:

    /tmp/amqp-venv/bin/python scripts/interop/pika_content.py rabbit
        -> against the reference LIVE RabbitMQ on :5672 (proves the HARNESS and
           the byte-equality assertions are correct; does not touch/modify it).

    /tmp/amqp-venv/bin/python scripts/interop/pika_content.py hyrx
        -> spawns build/hyrxmq-listen on HYRXMQ_PORT (default 5699, never 5672),
           runs the identical flows, then kills the subprocess (port freed).

The HyrxMQ listen binary serves ONE connection at a time (synchronous), so the
flows are publish-before-subscribe: the broker flushes queued deliveries as part
of the consume-ok / in response to get. Async push-after-subscribe is out of
scope. Each flow uses fresh, uniquely-named topology and its own connection; the
underlying socket is force-closed between flows so the single-threaded server is
guaranteed to see EOF and accept the next connection.

Exit 0 iff every decisive step PASSes. A step that a real client cannot complete
is recorded FAIL (with any pika exception / a hexdump of the last exchange), not
hidden.
"""
import os
import signal
import socket
import subprocess
import sys
import time
import traceback

import pika

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BIN = os.environ.get("HYRXMQ_BIN", os.path.join(ROOT, "build", "hyrxmq-listen"))
PORT = int(os.environ.get("HYRXMQ_PORT", "5699"))
HOST = os.environ.get("HYRX_HOST", "127.0.0.1")
USER = os.environ.get("HYRX_USER", "admin")
PW = os.environ.get("HYRX_PASS", "password")
VHOST = "/"

# The two bodies the flows must reproduce byte-for-byte.
BODY_A = b"hello-hyrx"          # Flow A: publish-before-consume
BODY_B = b"get-hyrx-body-1234"  # Flow B: publish-before-get (18 bytes, one frame)

# A body larger than one frame_max-8 chunk. With the broker run at
# HYRXMQ_FRAME_MAX=4096 (chunk 4088) this spans 3 BODY frames inbound AND is
# emitted back as 3 BODY frames, proving §2.3.5 multi-frame reassembly/chunking
# against the real client (this is the path an off-by-one in the outbound
# chunker corrupts). Deterministic bytes so any mismatch is obvious.
BODY_BIG = bytes((i * 31 + 7) & 0xFF for i in range(9000))

STEPS = []


class _Blocked(Exception):
    pass


class bounded:
    """Context manager: raise _Blocked after `secs` in a single blocking call.

    On the synchronous single-connection broker an un-answered request wedges
    both ends (pika waits for a reply; the server waits for the next recv). This
    bounds each such call so the harness prints an honest FAIL instead of hanging
    forever. The broker subprocess is torn down regardless.
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


def record(name, ok, detail=""):
    STEPS.append((name, "PASS" if ok else "FAIL", detail))
    print("[%s] %s%s" % ("PASS" if ok else "FAIL", name,
                         ("  :: " + detail) if detail else ""))
    return ok


def new_conn(host, port):
    creds = pika.PlainCredentials(USER, PW)
    params = pika.ConnectionParameters(
        host=host, port=port, virtual_host=VHOST, credentials=creds,
        connection_attempts=1, retry_delay=0.2, socket_timeout=10,
        blocked_connection_timeout=10,
        # heartbeat=0: HyrxMQ advertises heartbeat=0 (no server timer), so the
        # sync path must not depend on heartbeats. Harmless on RabbitMQ, whose
        # flows complete far inside any interval.
        heartbeat=0,
    )
    return pika.BlockingConnection(params)


def _raw_sock(conn):
    impl = getattr(conn, "_impl", None)
    tr = getattr(impl, "_transport", None) if impl else None
    return getattr(tr, "_sock", None) if tr else None


def _force_close(conn):
    """Guarantee the single-threaded server sees EOF (advance to next accept).

    The broker serves one connection at a time and never sends a close-ok, so a
    graceful pika close can wedge; closing the raw socket is what reliably makes
    the server's next recv return 0 (SERVE_CLOSED) and accept the next client.
    """
    s = _raw_sock(conn)
    if s is not None:
        try:
            s.shutdown(socket.SHUT_RDWR)
        except Exception:
            pass
        try:
            s.close()
        except Exception:
            pass


def graceful_close(conn, ch):
    """Best-effort pika close (each bounded), then a force socket-close backstop.

    On RabbitMQ the normal handshake completes and this is clean; on the
    single-connection HyrxMQ broker the close-ok replies are not sent, so the
    force-close backstop is what actually frees the accept loop for the next
    connection.
    """
    for closer in (lambda: ch and ch.is_open and ch.close(),
                   lambda: conn and conn.is_open and conn.close()):
        try:
            with bounded(3):
                closer()
        except Exception:
            pass
    try:
        _force_close(conn)
    except Exception:
        pass


# ---------------------------- Flow A: consumer ----------------------------

def flow_a(host, port):
    tag = "A"
    exch = "hyrx.content.a.x"
    queue = "hyrx.content.a.q"
    rkey = "hyrx.key.a"
    conn = None
    ch = None
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        ch.exchange_declare(exchange=exch, exchange_type="direct",
                            durable=False, auto_delete=True)
        qd = ch.queue_declare(queue=queue, durable=False, exclusive=True)
        ch.queue_bind(queue=queue, exchange=exch, routing_key=rkey)

        # Publish BEFORE subscribing (required by the sync single-conn server).
        ch.basic_publish(exchange=exch, routing_key=rkey, body=BODY_A)
        # Flush the publish method+header+body frames to the server.
        conn.process_data_events(time_limit=0.5)

        got = []

        def on_msg(channel, method, props, body):
            got.append((method, props, body))

        with bounded(8):
            ch.basic_consume(queue=queue, on_message_callback=on_msg,
                             auto_ack=False)
        # Pump until the delivery is dispatched (queued flush on our broker;
        # async push on RabbitMQ) or we time out.
        deadline = time.monotonic() + 8
        while not got and time.monotonic() < deadline:
            conn.process_data_events(time_limit=0.3)

        if not got:
            record("A.delivery received (basic_consume)", False,
                   "no delivery within 8s of consume (publish was before consume)")
            return
        method, props, body = got[0]
        ok = (body == BODY_A)
        record("A.delivery received (basic_consume)", ok,
               "body=%r want=%r exchange=%r rk=%r ctag=%r" % (
                   body, BODY_A, getattr(method, "exchange", None),
                   getattr(method, "routing_key", None),
                   getattr(method, "consumer_tag", None)))
        if not ok:
            return

        # Ack and confirm it is accepted (fire-and-forget; a protocol error would
        # tear down the connection, caught by the follow-up liveness probe).
        with bounded(6):
            ch.basic_ack(delivery_tag=method.delivery_tag)
            conn.process_data_events(time_limit=0.3)
        record("A.basic_ack", True, "delivery_tag=%s" % method.delivery_tag)

        # Liveness after ack: a fresh get on the drained queue must be get-empty,
        # proving the ack/content path left the connection in a good state.
        with bounded(6):
            m2, _p2, _b2 = ch.basic_get(queue=queue, auto_ack=False)
        record("A.connection alive + queue drained after ack (get->None)",
               m2 is None,
               "basic_get returned %s (expected None/get-empty)" %
               ("method" if m2 is not None else "None"))
    except Exception as e:
        record("A.flow", False, "%s: %s" % (type(e).__name__, e))
        traceback.print_exc()
    finally:
        graceful_close(conn, ch)


# ------------------------------ Flow B: get -------------------------------

def flow_b(host, port):
    exch = "hyrx.content.b.x"
    queue = "hyrx.content.b.q"
    rkey = "hyrx.key.b"
    conn = None
    ch = None
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        ch.exchange_declare(exchange=exch, exchange_type="direct",
                            durable=False, auto_delete=True)
        ch.queue_declare(queue=queue, durable=False, exclusive=True)
        ch.queue_bind(queue=queue, exchange=exch, routing_key=rkey)

        # Empty-get first: proves get-empty on a queue with no message.
        with bounded(6):
            e_m, _e_p, _e_b = ch.basic_get(queue=queue, auto_ack=False)
        record("B.basic_get on empty -> get-empty (None)", e_m is None,
               "basic_get returned %s" % ("method" if e_m is not None else "None"))

        ch.basic_publish(exchange=exch, routing_key=rkey, body=BODY_B)
        conn.process_data_events(time_limit=0.5)

        with bounded(6):
            method, props, body = ch.basic_get(queue=queue, auto_ack=False)
        if method is None:
            record("B.delivery received (basic_get)", False,
                   "basic_get returned None after a publish (content not routed)")
            return
        ok = (body == BODY_B)
        record("B.delivery received (basic_get)", ok,
               "body=%r want=%r rk=%r msg_count=%s" % (
                   body, BODY_B, getattr(method, "routing_key", None),
                   getattr(method, "message_count", None)))
        if not ok:
            return

        with bounded(6):
            ch.basic_ack(delivery_tag=method.delivery_tag)
            conn.process_data_events(time_limit=0.3)
        record("B.basic_ack", True, "delivery_tag=%s" % method.delivery_tag)

        # Drain confirmation: get again -> get-empty (message was consumed).
        with bounded(6):
            m2, _p2, _b2 = ch.basic_get(queue=queue, auto_ack=False)
        record("B.drained after get+ack (get->None)", m2 is None,
               "basic_get returned %s" % ("method" if m2 is not None else "None"))
    except Exception as e:
        record("B.flow", False, "%s: %s" % (type(e).__name__, e))
        traceback.print_exc()
    finally:
        graceful_close(conn, ch)


# --------------------- Flow C: multi-chunk large body ---------------------

def flow_c(host, port):
    """A body spanning several BODY frames, in AND out, reassembled exactly.

    The broker runs at HYRXMQ_FRAME_MAX=4096 (chunk 4088) in hyrx mode, so
    BODY_BIG (9000 B) crosses 3 frames on the way in (pika splits by the
    negotiated frame-max) and 3 frames on the way out (our emit_message_frames).
    This is the path the fixed outbound chunker guards (a double-indexed
    body[pos+i] would raise / misassemble here).
    """
    exch = "hyrx.content.c.x"
    queue = "hyrx.content.c.q"
    rkey = "hyrx.key.c"
    conn = None
    ch = None
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        ch.exchange_declare(exchange=exch, exchange_type="direct",
                            durable=False, auto_delete=True)
        ch.queue_declare(queue=queue, durable=False, exclusive=True)
        ch.queue_bind(queue=queue, exchange=exch, routing_key=rkey)

        ch.basic_publish(exchange=exch, routing_key=rkey, body=BODY_BIG)
        conn.process_data_events(time_limit=0.8)

        with bounded(8):
            method, props, body = ch.basic_get(queue=queue, auto_ack=False)
        if method is None:
            record("C.large multi-frame body round-trips (basic_get)", False,
                   "basic_get returned None after a %d-byte publish" % len(BODY_BIG))
            return
        ok = (body == BODY_BIG)
        record("C.large multi-frame body round-trips (basic_get)", ok,
               "got %d bytes (want %d); equal=%s" % (
                   len(body), len(BODY_BIG), ok))
        if not ok:
            # Show the first divergence to make a chunk-boundary bug obvious.
            n = min(len(body), len(BODY_BIG))
            first = next((i for i in range(n) if body[i] != BODY_BIG[i]), -1)
            print("   C.mismatch first diff at byte %s; head got=%r want=%r" % (
                first, body[:8], BODY_BIG[:8]))
            return
        with bounded(6):
            ch.basic_ack(delivery_tag=method.delivery_tag)
            conn.process_data_events(time_limit=0.3)
        record("C.basic_ack (large body)", True,
               "delivery_tag=%s" % method.delivery_tag)
    except Exception as e:
        record("C.flow", False, "%s: %s" % (type(e).__name__, e))
        traceback.print_exc()
    finally:
        graceful_close(conn, ch)


def run_flows(host, port, label):
    print("\n----- %s : %s:%d (pika %s) -----" % (label, host, port,
                                        pika.__version__))
    flow_a(host, port)
    time.sleep(0.4)  # let the single-conn server finish the prior slot's teardown
    flow_b(host, port)
    time.sleep(0.4)
    flow_c(host, port)
    # Every recorded step must be PASS.
    return all(st == "PASS" for _n, st, _d in STEPS)


def table():
    print("\n================= REAL-PIKA CONTENT RESULT TABLE =================")
    print("%-56s  %-5s  %s" % ("STEP", "STATE", "DETAIL"))
    print("-" * 110)
    for name, st, detail in STEPS:
        print("%-56s  %-5s  %s" % (name, st, detail))
    print("-" * 110)
    fails = sum(1 for _n, st, _d in STEPS if st == "FAIL")
    print("TOTAL %d   PASS %d   FAIL %d" % (len(STEPS), len(STEPS) - fails, fails))
    return fails == 0


def start_broker():
    """Spawn the listen binary on PORT (never 5672); return (proc, logpath)."""
    import tempfile
    log = tempfile.NamedTemporaryFile(prefix="hyrxmq-listen-", suffix=".log",
                                      delete=False)
    env = dict(os.environ)
    env["HYRXMQ_HOST"] = HOST
    env["HYRXMQ_PORT"] = str(PORT)
    # Force small frames (AMQP frame_min 4096) so BODY_BIG spans several BODY
    # frames in BOTH directions — the §2.3.5 chunking/reassembly path.
    env["HYRXMQ_FRAME_MAX"] = os.environ.get("HYRXMQ_FRAME_MAX", "4096")
    proc = subprocess.Popen([BIN], stdout=log, stderr=subprocess.STDOUT, env=env)
    # Wait until the port is bound (or 10s).
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if proc.poll() is not None:
            log.flush()
            with open(log.name) as fh:
                print("BROKER EXITED EARLY:\n" + fh.read())
            raise RuntimeError("broker exited early rc=%s" % proc.returncode)
        if _port_listening(PORT):
            return proc, log.name
        time.sleep(0.1)
    proc.terminate()
    raise RuntimeError("broker did not bind :%d" % PORT)


def _port_listening(port):
    import socket as _s
    s = _s.socket(_s.AF_INET, _s.SOCK_STREAM)
    s.settimeout(0.2)
    try:
        return s.connect_ex(("127.0.0.1", port)) == 0
    finally:
        s.close()


def stop_broker(proc):
    if proc is None:
        return
    for sig, _lbl in ((signal.SIGTERM, "TERM"), (signal.SIGKILL, "KILL")):
        if proc.poll() is not None:
            break
        try:
            proc.send_signal(sig)
        except Exception:
            pass
        for _ in range(30):
            if proc.poll() is not None:
                break
            time.sleep(0.1)
    try:
        proc.wait(timeout=2)
    except Exception:
        pass
    # Prove the port is actually released.
    if _port_listening(PORT):
        print("FATAL: port %d still bound after teardown" % PORT)
    else:
        print("teardown ok: broker gone, port %d released, RabbitMQ :5672 untouched"
              % PORT)


def main(argv):
    target = argv[1] if len(argv) > 1 else "hyrx"
    if target not in ("rabbit", "hyrx"):
        print("usage: pika_content.py [rabbit|hyrx]")
        return 2

    if target == "rabbit":
        # Reference harness-correctness run against LIVE RabbitMQ :5672.
        # RabbitMQ owns 5672; we only connect (read-only lifecycle), never touch
        # the container/process.
        run_flows(HOST, 5672, "REFERENCE RabbitMQ")
        verdict = table()
        print("PIKA_CONTENT(rabbit) VERDICT: %s" % ("PASS" if verdict else "FAIL"))
        return 0 if verdict else 1

    # target == hyrx: spawn OUR broker on PORT (not 5672), run, tear down.
    if not os.path.exists(BIN):
        print("missing %s — build it first:\n  pixi run mojo build -I src -I "
              "vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen"
              % BIN)
        return 2
    proc = None
    logpath = None
    try:
        proc, logpath = start_broker()
        print("broker PID=%s listening on %s:%d (RabbitMQ stays on 5672)"
              % (proc.pid, HOST, PORT))
        run_flows(HOST, PORT, "HyrxMQ listen")
        verdict = table()
        print("PIKA_CONTENT(hyrx) VERDICT: %s" % ("PASS" if verdict else "FAIL"))
        if logpath and not verdict:
            print("---- broker log tail ----")
            with open(logpath) as fh:
                data = fh.read()
            print(data[-4000:])
        return 0 if verdict else 1
    finally:
        stop_broker(proc)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
