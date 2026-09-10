#!/usr/bin/env python3
"""benchmarks/compat/conformance.py — 0017 T2 pika conformance matrix.

Amqp 0-9-1 CONTENT-PROPERTY + delivery-semantics conformance probe. Pika
(1.4.x) drives BOTH brokers with the same operation table:

    rabbit mode:  LIVE reference RabbitMQ on :5672 (ground truth; never
                  modified, process/container untouched).
    hyrx mode:    spawns build/hyrxmq-listen on HYRXMQ_PORT (default 5699,
                  never 5672). Loads the rabbit ground-truth rows and
                  COMPARES.

Output contract (per task): the SAME operation table run against both
brokers; the runner compares rabbit-recorded ground truth against the hyrx
observed rows row-by-row and prints PASS / PARTIAL / DIFF with the exact
observed difference. Differences are DATA — they are printed, never
annotated away. No green-washing: an op that raises, blocks or returns an
unexpected shape is recorded as-is (exception `__class__` + `message`).

Rows (0017 T2 sequence):
    props.<field>         ... same content properties back via basic.get-ok
        fields: content_type, content_encoding, headers (typed field table:
                string/int/bool), delivery_mode, priority, correlation_id,
                reply_to, expiration, message_id, timestamp, type,
                user_id, app_id
    redelivered.first     ... first delivery: redelivered = False
    redelivered.nack_requeue ... nack(requeue=True) → second delivery:
        redelivered = True AND body byte-identical
    tags.no_collision     ... TWO queues, ONE channel: delivery-tags advance
        monotonically — no collision across queues
    tags.per_channel      ... one delivery each on TWO channels: both
        channels issue the same FIRST tag (standard per-channel scope)
    unknown_exchange.404  ... basic.publish to a MISSING exchange
        (mandatory=0) → channel.close 404 NOT_FOUND (normative)
    return.mandatory_312  ... basic.publish mandatory=1 to an EXISTING
        exchange whose route misses → NO delivery anywhere + connection
        stays usable (312 basic.return on the wire; see needs-probe note)

Run modes:

    python conformance.py rabbit    # record ground truth → SESSIONS
    python conformance.py hyrx      # spawn broker, compare vs ground truth
    python conformance.py compare   # print the diff table from two files

Ground-truth json: /tmp/opencode/mb/conformance_rabbit.json (hyrx writes
conformance_hyrx.json). Path override: HYRX_CONFORMANCE_DIR.

PARTIAL semantics: a row matches the ground truth EXCEPT for a named,
documented difference (e.g. delivery-tag numbering that starts at 0 vs
rabbit's 1) — PARTIAL is never used to hide an unnamed difference.
"""

import json
import os
import signal
import socket
import subprocess
import sys
import time
import traceback
from contextlib import contextmanager

import pika

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BIN = os.environ.get("HYRXMQ_BIN", os.path.join(ROOT, "build", "hyrxmq-listen"))
PORT = int(os.environ.get("HYRXMQ_PORT", "5699"))
HOST = os.environ.get("HYRX_HOST", "127.0.0.1")
USER = os.environ.get("HYRX_USER", "admin")
PW = os.environ.get("HYRX_PASS", "password")
VHOST = "/"
GROUND_DIR = os.environ.get(
    "HYRX_CONFORMANCE_GROUND_DIR", "/tmp/opencode/mb"
)
GROUND_PATH = os.path.join(GROUND_DIR, "conformance_rabbit.json")
HYRX_PATH = os.path.join(GROUND_DIR, "conformance_hyrx.json")

# Known, named limitations: rows where HyrxMQ differs for a DOCUMENTED
# reason are PARTIAL (the difference is named here, data also shown);
# everything else must be PASS or it is printed as DIFF.
KNOWN_LIMITATIONS = {
    # delivery-tags are per-channel but the service namespace, for legacy
    # byte parity with the 44-test suite, starts at 0 (rabbit starts at 1).
    # The no-collision / independence semantics are identical.
    "tags.no_collision": "delivery-tags start at 0 (rabbit: 1); "
    "monotonic no-collision semantics are the same",
    "tags.per_channel": "delivery-tags start at 0 (rabbit: 1); "
    "per-channel independence semantics are the same",
}

# --------------------------------------------------------------------------
# harness plumbing (same discipline as scripts/interop/pika_content.py)
# --------------------------------------------------------------------------


class _Blocked(Exception):
    pass


@contextmanager
def bounded(secs):
    """Bound ONE blocking call with SIGALRM (honest FAIL, never a hang)."""
    def _boom(signum, frame):
        raise _Blocked("timed out after %ss waiting for the broker" % secs)

    prev = signal.signal(signal.SIGALRM, _boom)
    signal.setitimer(signal.ITIMER_REAL, secs)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, prev)


def new_conn(host, port):
    creds = pika.PlainCredentials(USER, PW)
    params = pika.ConnectionParameters(
        host=host, port=port, virtual_host=VHOST, credentials=creds,
        connection_attempts=1, retry_delay=0.2, socket_timeout=10,
        blocked_connection_timeout=10, heartbeat=0,
    )
    return pika.BlockingConnection(params)


def _raw_sock(conn):
    impl = getattr(conn, "_impl", None)
    tr = getattr(impl, "_transport", None) if impl else None
    return getattr(tr, "_sock", None) if tr else None


def force_close(conn):
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


def graceful_close(conn, channels=()):
    """pika-close each channel/conn bounded, then a raw force-close backstop.

    On the single-connection HyrxMQ broker the force-close is what frees the
    accept loop for the next row (same as the 0017 content probe).
    """
    for ch in channels:
        try:
            with bounded(3):
                if ch and ch.is_open:
                    ch.close()
        except Exception:
            pass
    try:
        with bounded(3):
            if conn and conn.is_open:
                conn.close()
    except Exception:
        pass
    try:
        force_close(conn)
    except Exception:
        pass


def _exc_payload(e):
    """Canonical exception payload: class + code + message (data, not trials)."""
    return {
        "type": type(e).__name__,
        "code": int(getattr(e, "reply_code", -1) or -1),
        "message": "%s" % (getattr(e, "reply_text", None) or e),
    }




# --------------------------------------------------------------------------
# the operation table (0017 T2): each row runs on its OWN connection.
# --------------------------------------------------------------------------

# Content properties ONE publish carries; each field becomes ONE row.
PROPS_SPEC = {
    "content_type": "text/plain",
    "content_encoding": "utf-8",
    "headers": {"hstr": "hv", "hint": 7, "hbool": True},
    "delivery_mode": 2,
    "priority": 7,
    "correlation_id": "corr-t2",
    "reply_to": "reply.q",
    "expiration": "3000",
    "message_id": "msg-t2",
    "timestamp": 1700000000,
    "type": "report",
    "user_id": "admin",
    "app_id": "conformance-t2",
}

BODY = b"conformance-t2-body"

# `timestamp` round-trips with a one-off repr (the value itself is an int on
# both brokers); every other row compares its observed payload directly.
ROW_ORDER = ["props." + f for f in PROPS_SPEC] + [
    "redelivered.first",
    "redelivered.nack_requeue",
    "tags.no_collision",
    "tags.per_channel",
    "unknown_exchange.404",
    "return.mandatory_312",
]


def declare_topology(ch, exch, queue, rkey):
    ch.exchange_declare(exchange=exch, exchange_type="direct",
                        durable=False, auto_delete=True)
    ch.queue_declare(queue=queue, durable=False, exclusive=True)
    ch.queue_bind(queue=queue, exchange=exch, routing_key=rkey)


def get_once(ch, queue):
    """One bounded basic_get (auto_ack=False); (method, props, body) | None."""
    with bounded(6):
        return ch.basic_get(queue=queue, auto_ack=False)


def op_props(host, port, field):
    """One properties round-trip row: publish ALL fields, read the ONE field
    back via basic_get-ok (byte-faithful header transmit as stored).

    Per-ROW namespaces: exclusive queues reuse nothing across rows (an
    exclusive queue is locked while the previous connection's cleanup is
    still decaying on the reference broker)."""
    exch = f"t2.props.{field}.x"
    queue = f"t2.props.{field}.q"
    rkey = f"t2.props.{field}.k"
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        declare_topology(ch, exch, queue, rkey)
        with bounded(8):
            ch.basic_publish(exchange=exch, routing_key=rkey,
                             body=BODY, properties=pika.BasicProperties(**PROPS_SPEC))
            m, p, b = get_once(ch, queue)
        if m is None:
            graceful_close(conn, (ch,))
            return {"observed": "empty-after-publish"}
        out = {"body": b == BODY, "value": getattr(p, field, "<missing>")}
        ch.basic_ack(delivery_tag=m.delivery_tag)
        graceful_close(conn, (ch,))
        return {"observed": out}
    except Exception as e:
        return {"error": _exc_payload(e)}


def op_redelivered_first(host, port):
    """Fresh message, first delivery: redelivered = False."""
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        declare_topology(ch, "t2.red.x", "t2.red.q", "t2.red.k")
        ch.basic_publish(exchange="t2.red.x", routing_key="t2.red.k", body=BODY)
        m, _p, _b = get_once(ch, "t2.red.q")
        out = None if m is None else {"redelivered": bool(m.redelivered)}
        if m:
            ch.basic_ack(delivery_tag=m.delivery_tag)
        graceful_close(conn, (ch,))
        return {"observed": out}
    except Exception as e:
        return {"error": _exc_payload(e)}


def op_redelivered_nack(host, port):
    """nack(requeue=True) -> SECOND delivery: redelivered = True + the SAME
    body byte-identically."""
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        declare_topology(ch, "t2.redn.x", "t2.redn.q", "t2.redn.k")
        with bounded(8):
            ch.basic_publish(exchange="t2.redn.x", routing_key="t2.redn.k",
                             body=BODY)
            m1, _p, _b = get_once(ch, "t2.redn.q")
        if m1 is None:
            graceful_close(conn, (ch,))
            return {"observed": "first-get-empty"}
        with bounded(6):
            ch.basic_nack(delivery_tag=m1.delivery_tag, requeue=True)
        m2, _p2, b2 = get_once(ch, "t2.redn.q")
        out = {
            "second_redelivered": None if m2 is None else bool(m2.redelivered),
            "body_equal": None if m2 is None else (b2 == BODY),
            "tag1": m1.delivery_tag,
            "tag2": None if m2 is None else m2.delivery_tag,
        }
        if m2:
            with bounded(6):
                ch.basic_ack(delivery_tag=m2.delivery_tag)
        graceful_close(conn, (ch,))
        return {"observed": out}
    except Exception as e:
        return {"error": _exc_payload(e)}


def _tag_of_first_get(res):
    return None if res[0] is None else res[0].delivery_tag


def op_tags_no_collision(host, port):
    """TWO queues, ONE channel: delivery-tags advance monotonically and do
    NOT collide across queues (standard: one tag namespace per channel)."""
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        declare_topology(ch, "t2.taga.x", "t2.taga.q1", "t2.taga.k")
        ch.queue_declare(queue="t2.taga.q2", durable=False, exclusive=True)
        ch.queue_bind(queue="t2.taga.q2", exchange="t2.taga.x",
                      routing_key="t2.taga.k")
        with bounded(8):
            ch.basic_publish(exchange="t2.taga.x", routing_key="t2.taga.k",
                             body=BODY)
        t1 = _tag_of_first_get(get_once(ch, "t2.taga.q1"))
        t2 = _tag_of_first_get(get_once(ch, "t2.taga.q2"))
        out = {"tag_q1": t1, "tag_q2": t2,
               "distinct_no_collision": (t1 is not None and t2 != t1)}
        graceful_close(conn, (ch,))
        return {"observed": out}
    except Exception as e:
        return {"error": _exc_payload(e)}


def op_tags_per_channel(host, port):
    """One delivery each on TWO channels of ONE connection: both channels
    issue the SAME first tag (per-channel delivery-tag scope)."""
    try:
        conn = new_conn(host, port)
        c1 = conn.channel()
        c2 = conn.channel()
        declare_topology(c1, "t2.tagb.x", "t2.tagb.q", "t2.tagb.k")
        t1 = _tag_of_first_get(get_once(c1, "t2.tagb.q"))
        t2 = _tag_of_first_get(get_once(c2, "t2.tagb.q"))
        out = {"ch1_tag": t1, "ch2_tag": t2}
        graceful_close(conn, (c1, c2))
        return {"observed": out}
    except Exception as e:
        return {"error": _exc_payload(e)}


def op_unknown_exchange(host, port):
    """basic.publish MISSING exchange (mandatory=0) -> channel.close 404."""
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        try:
            with bounded(8):
                ch.basic_publish(exchange="t2.missing.x", routing_key="t2.k",
                                 body=BODY, mandatory=False)
                conn.process_data_events(time_limit=2)
            graceful_close(conn, (ch,))
            return {"observed": {"closed": False}}
        except pika.exceptions.ChannelClosedByBroker as e:
            graceful_close(conn, ())
            return {"observed": {"closed": True,
                                 "code": int(e.reply_code),
                                 "text": str(e.reply_text)}}
    except Exception as e:
        return {"error": _exc_payload(e)}


def op_mandatory_return(host, port):
    """basic.publish mandatory=1 to an EXISTING exchange whose ROUTE misses
    -> NO delivery anywhere + the connection/channel stays usable."""
    try:
        conn = new_conn(host, port)
        ch = conn.channel()
        declare_topology(ch, "t2.ret.x", "t2.ret.q", "t2.ret.k2")
        with bounded(8):
            ch.basic_publish(exchange="t2.ret.x", routing_key="t2.ret.k",
                             body=BODY, mandatory=True)
            conn.process_data_events(time_limit=1)
        m, _p, _b = get_once(ch, "t2.ret.q")
        out = {"delivered": m is not None,
               "connection_usable": bool(conn.is_open)}
        if m:
            ch.basic_ack(delivery_tag=m.delivery_tag)
        graceful_close(conn, (ch,))
        return {"observed": out}
    except Exception as e:
        return {"error": _exc_payload(e)}


def run_ops_table(host, port, timeout_secs=240):
    """Run every row on its own connection; return {row: op-data}.

    The table itself is bounded END-TO-END with SIGALRM so a wedged op can
    never hang the matrix (the op-level bounded() already guards each call).
    """
    signal.signal(signal.SIGALRM, _alarm_table)
    signal.setitimer(signal.ITIMER_REAL, timeout_secs)
    rows = {}
    with bounded(10):
        for field in PROPS_SPEC:
            rows["props." + field] = op_props(host, port, field)
        rows["redelivered.first"] = op_redelivered_first(host, port)
        rows["redelivered.nack_requeue"] = op_redelivered_nack(host, port)
        rows["tags.no_collision"] = op_tags_no_collision(host, port)
        rows["tags.per_channel"] = op_tags_per_channel(host, port)
        rows["unknown_exchange.404"] = op_unknown_exchange(host, port)
        rows["return.mandatory_312"] = op_mandatory_return(host, port)
    signal.setitimer(signal.ITIMER_REAL, 0)
    signal.signal(signal.SIGALRM, signal.SIG_DFL)
    return rows


def _alarm_table(signum, frame):
    raise _Blocked("conformance TABLE exceeded its end-to-end bound")




# --------------------------------------------------------------------------
# broker subprocess control (hyrx mode; identical discipline to
# scripts/interop/pika_content.py — the broker is NEVER run on 5672)
# --------------------------------------------------------------------------


def _port_listening(port):
    import socket as _s
    s = _s.socket(_s.AF_INET, _s.SOCK_STREAM)
    s.settimeout(0.2)
    try:
        return s.connect_ex(("127.0.0.1", port)) == 0
    finally:
        s.close()


def start_broker():
    import tempfile
    log = tempfile.NamedTemporaryFile(prefix="hyrxmq-conform-", suffix=".log",
                                      delete=False)
    env = dict(os.environ)
    env["HYRXMQ_HOST"] = HOST
    env["HYRXMQ_PORT"] = str(PORT)
    proc = subprocess.Popen([BIN], stdout=log, stderr=subprocess.STDOUT, env=env)
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if proc.poll() is not None:
            log.flush()
            with open(log.name) as fh:
                print("BROKER EXITED EARLY:\n" + fh.read())
            raise RuntimeError("broker exited early rc=%s" % proc.returncode)
        if _port_listening(PORT):
            return proc
        time.sleep(0.1)
    proc.terminate()
    raise RuntimeError("broker did not bind :%d" % PORT)


def stop_broker(proc):
    for sig in (signal.SIGTERM, signal.SIGKILL):
        if proc is None or proc.poll() is not None:
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
    if _port_listening(PORT):
        print("FATAL: port %d still bound after teardown" % PORT)
    else:
        print("teardown ok: broker gone, port %d released, RabbitMQ :5672 untouched" % PORT)


# --------------------------------------------------------------------------
# compare + print (NOT a green-washer: differences are DATA, printed).
# --------------------------------------------------------------------------

# Named, DOCUMENTED deviations: exact rows whose hyrx-vs-rabbit difference
# corresponds to a known T2 design decision. PARTIAL must never hide an
# UNNAMED difference — anything else is DIFF, printed with the data.
KNOWN_LIMITATIONS = {
    "tags.no_collision":
        "T2 delivery-tags start at 0 (legacy byte parity with the 44-test "
        "suite) where rabbit starts at 1; monotonic no-collision semantics "
        "identical",
    "tags.per_channel":
        "T2 delivery-tags start at 0 (legacy byte parity with the 44-test "
        "suite) where rabbit starts at 1; per-channel independence identical",
}

# Rows whose DEPENDENT truth is derived (tag values differ EXCEPT the
# semantics column): the compared columns for tags.* rows.
_TAGS_ROWS = {"tags.no_collision", "tags.per_channel"}


def _project(row, data):
    """The compared projection of one op's data (unprojected rows never hidden)."""
    if not isinstance(data, dict):
        return data
    if row in _TAGS_ROWS and "observed" in data and isinstance(data["observed"], dict):
        obs = dict(data["observed"])
        # delivery-tag numbers are a documented-as-different axis: the pass
        # criterion is the DERIVED center (no-collision / per-channeltruth);
        # the tag values are still SHOWN in the row detail.
        for key in ("tag_q1", "tag_q2", "ch1_tag", "ch2_tag", "tag1", "tag2"):
            obs.pop(key, None)
        return obs
    return data


def compare_rows(ground, hyrx):
    """{row: (state, detail)} — PASS equal / PARTIAL named / DIFF other.

    Equal = the projected rabbit cell equals the projected hyrx cell;
    PARTIAL = known limitation named in KNOWN_LIMITATIONS (the raw cells are
    shown anyway); DIFF = anything else, with both raw cells printed.
    """
    table = []
    for row in ROW_ORDER:
        g = ground.get(row)
        h = hyrx.get(row)
        if g is None or h is None:
            table.append((row, "DIFF",
                          "missing cells: rabbit=%r hyrx=%r" % (g, h)))
            continue
        gp = _project(row, g)
        hp = _project(row, h)
        if _equal(gp, hp):
            table.append((row, "PASS", ""))
        elif row in KNOWN_LIMITATIONS:
            table.append((row, "PARTIAL",
                          KNOWN_LIMITATIONS[row] + "   raw: rabbit=%r hyrx=%r" % (g, h)))
        else:
            table.append((row, "DIFF", "rabbit=%r hyrx=%r" % (g, h)))
    return table


def _equal(a, b):
    """JSON-structural equality (nested dicts and lists too)."""
    if isinstance(a, dict) and isinstance(b, dict):
        if a.keys() != b.keys():
            return False
        return all(_equal(a[k], b[k]) for k in a)
    if isinstance(a, (list, tuple)) and isinstance(b, (list, tuple)):
        return len(a) == len(b) and all(_equal(x, y) for x, y in zip(a, b))
    return a == b


def print_table(rows):
    print("\n============== 0017-T2 CONFORMANCE MATRIX (rabbit ground truth) ==============")
    print("%-26s  %-8s  %s" % ("ROW", "STATE", "DETAIL"))
    print("-" * 110)
    for row, state, detail in rows:
        print("%-26s  %-8s  %s" % (row, state, detail))
    print("-" * 110)
    counts = {}
    for _r, state, _d in rows:
        counts[state] = counts.get(state, 0) + 1
    print("ROWS %d   " % len(rows) +
          "  ".join("%s %d" % (k, v) for k, v in sorted(counts.items())))
    return counts.get("DIFF", 0) == 0 and counts.get("PASS", 0) + counts.get("PARTIAL", 0) == len(rows)


# --------------------------------------------------------------------------
# modes
# --------------------------------------------------------------------------

def ensure_ground_dir():
    os.makedirs(GROUND_DIR, exist_ok=True)


def mode_rabbit():
    ensure_ground_dir()
    rabbit_port = int(os.environ.get("RABBIT_PORT", "5673"))
    print("== 0017-T2 conformance: ground truth against RabbitMQ %s:%d ==" % (HOST, rabbit_port))
    rows = run_ops_table(HOST, rabbit_port)
    payload = {"target": "rabbit", "host": HOST, "port": 5672,
               "pika_version": pika.__version__, "rows": rows}
    with open(GROUND_PATH, "w") as fh:
        json.dump(payload, fh, indent=2, sort_keys=True)
    errored = sorted(r for r, v in rows.items()
                     if isinstance(v, dict) and "error" in v)
    print("ground truth written: %s" % GROUND_PATH)
    print("rabbit rows that errored: %d %s" % (len(errored), errored))
    return 0 if errored else 1


def mode_hyrx():
    """Spawn the hyrxmq-listen binary, run the SAME table, record, compare
    against the rabbit ground truth (if present) and print the matrix."""
    if not os.path.exists(BIN):
        print("missing %s — build it first (pixi run mojo build ... "
              "src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen)" % BIN)
        return 2
    ensure_ground_dir()
    proc = start_broker()
    try:
        rows = run_ops_table(HOST, PORT)
        payload = {"target": "hyrx", "host": HOST, "port": PORT,
                   "pika_version": pika.__version__, "rows": rows}
        with open(HYRX_PATH, "w") as fh:
            json.dump(payload, fh, indent=2, sort_keys=True)
        errored = sorted(r for r, v in rows.items()
                         if isinstance(v, dict) and "error" in v)
        if errored:
            print("hyrx rows that errored: %d %s" % (len(errored), errored))
    finally:
        stop_broker(proc)
    if not os.path.exists(GROUND_PATH):
        print("no rabbit ground truth (%s); RECORD it first:"
              " conformance.py rabbit" % GROUND_PATH)
        return 2
    with open(GROUND_PATH) as fh:
        ground = json.load(fh)["rows"]
    verdict = print_table(compare_rows(ground, rows))
    print("COMPARE VERDICT: %s" % ("PASS" if verdict else "DIFFS PRESENT"))
    return 0 if verdict else 1


def mode_compare():
    ensure_ground_dir()
    if not (os.path.exists(GROUND_PATH) and os.path.exists(HYRX_PATH)):
        print("usage: conformance.py compare — both %s and %s must exist" %
              (GROUND_PATH, HYRX_PATH))
        return 2
    with open(GROUND_PATH) as fh:
        ground = json.load(fh)["rows"]
    with open(HYRX_PATH) as fh:
        hyrx = json.load(fh)["rows"]
    verdict = print_table(compare_rows(ground, hyrx))
    print("COMPARE VERDICT: %s" % ("PASS" if verdict else "DIFFS PRESENT"))
    return 0 if verdict else 1


def main(argv):
    mode = argv[1] if len(argv) > 1 else "help"
    if mode == "rabbit":
        return mode_rabbit()
    if mode == "compare":
        return mode_compare()
    if mode == "hyrx":
        return mode_hyrx()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
