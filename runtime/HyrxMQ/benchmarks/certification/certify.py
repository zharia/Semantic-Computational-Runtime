#!/usr/bin/env python3
"""HyrxMQ (M9) performance-certification driver.

Certifies ONE HyrxMQ broker process against the regression thresholds in
`thresholds.json`. Runs the broker over TCP (unless `--port`/`--broker-pid`
attach an already-running one), exercises fixed scenarios, and exits non-zero
if any thresholded metric fails.

What is measured (per scenario: plaintext and, when configured, TLS):

  * throughput   -- closed-loop publish -> basic_get(auto_ack) cycle,
                    msgs/sec. Closed loop because HyrxMQ's queue capacity is
                    1024 messages and publishes past it are dropped SILENTLY;
                    batching at <=1024 keeps the depth bounded and the rate
                    meaningful.
  * latency      -- publish -> get round trip, one message in flight,
                    p50/p95/p99/p99.9 in milliseconds.
  * memory       -- (peak broker VmRSS - baseline VmRSS) / queued messages,
                    bytes/msg, sampled via /proc/<pid>/status VmRSS.
  * TLS overhead -- 1KB plaintext vs 1KB TLS throughput on the same binary.

Client: pika if importable, else a raw TCP socket fallback that measures the
transport floor (connect + AMQP protocol-header handshake latency and
connection churn). Message-level metrics are SKIPped, never faked, in raw mode.

Broker env knobs used (see src/hyrxmq/main_listen.mojo):
  HYRXMQ_HOST, HYRXMQ_PORT, HYRXMQ_TLS_ENABLED, HYRXMQ_TLS_CERT, HYRXMQ_TLS_KEY.

Usage:
  python3 benchmarks/certification/certify.py
  python3 benchmarks/certification/certify.py --quick
  python3 benchmarks/certification/certify.py --port 5673 --broker-pid 12345
  python3 benchmarks/certification/certify.py --tls-cert c.pem --tls-key k.pem
"""
import argparse
import datetime
import json
import os
import platform
import shutil
import socket
import ssl
import statistics
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DEFAULT_BIN = os.path.join(ROOT, "build", "hyrxmq-listen")
RESULTS_DIR = os.path.join(HERE, "results")
THRESHOLDS_PATH = os.path.join(HERE, "thresholds.json")

try:
    import pika  # type: ignore
    HAVE_PIKA = True
except Exception:  # pragma: no cover - environment dependent
    pika = None
    HAVE_PIKA = False

# scenario key -> payload bytes
SCENARIOS = (("1kb", 1024), ("64kb", 65536), ("1mb", 1048576))

# message counts (normal, quick). Tuned so each scenario runs < 3s while
# still covering warm-up + steady state.
COUNTS = {
    "1kb": (20000, 4000),
    "64kb": (4000, 800),
    "1mb": (400, 100),
}
LATENCY_OPS = {
    "1kb": (2000, 400),
    "64kb": (500, 100),
    "1mb": (100, 30),
}

USER = os.environ.get("HYRX_USER", "admin")
PASSWORD = os.environ.get("HYRX_PASS", "password")
VHOST = "/"
FRAME_MAX = 131072
QUEUE_CAPACITY = 1024
BATCH = 256
WARMUP_FRAC = 0.05


# ---------------------------------------------------------------------------
# host + process sampling
# ---------------------------------------------------------------------------

def _read_cpu_model():
    try:
        with open("/proc/cpuinfo") as fh:
            for line in fh:
                if line.lower().startswith("model name"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return platform.processor() or "unknown"


def host_info():
    return {
        "cpu_model": _read_cpu_model(),
        "nproc": os.cpu_count(),
        "kernel": platform.release(),
        "machine": platform.machine(),
        "python": platform.python_version(),
        "pika_version": getattr(pika, "__version__", None) if HAVE_PIKA else None,
        "hyrxmq_git_head": _git_head(),
        "governor": _governor(),
    }


def _git_head():
    try:
        out = subprocess.run(
            ["git", "-C", ROOT, "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5)
        return out.stdout.strip() or None
    except Exception:
        return None


def _governor():
    path = ("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
    try:
        with open(path) as fh:
            return fh.read().strip()
    except OSError:
        return None


def read_rss_kb(pid):
    """Resident set size of `pid` in KB, or None if it is gone."""
    try:
        with open(f"/proc/{int(pid)}/status") as fh:
            for line in fh:
                if line.startswith("VmRSS:"):
                    return int(line.split()[1])
    except (OSError, ValueError):
        pass
    return None


def count_fds(pid):
    try:
        return len(os.listdir(f"/proc/{int(pid)}/fd"))
    except OSError:
        return None


# ---------------------------------------------------------------------------
# broker lifecycle
# ---------------------------------------------------------------------------

def free_port(host="127.0.0.1"):
    s = socket.socket()
    s.bind((host, 0))
    port = s.getsockname()[1]
    s.close()
    return port


def find_binary(explicit):
    if explicit:
        return explicit if os.path.exists(explicit) else None
    env = os.environ.get("HYRXMQ_BIN")
    if env and os.path.exists(env):
        return env
    return DEFAULT_BIN if os.path.exists(DEFAULT_BIN) else None


class Broker:
    """A HyrxMQ listen process, owned (spawned) or attached (external pid)."""

    def __init__(self, binary, host, port, tls=False, cert=None, key=None,
                 owned=True, pid=None):
        self.binary = binary
        self.host = host
        self.port = port
        self.tls = tls
        self.cert = cert
        self.key = key
        self.owned = owned
        self.pid = pid
        self.proc = None
        self.log_path = None

    def start(self):
        env = dict(os.environ)
        env["HYRXMQ_HOST"] = self.host
        env["HYRXMQ_PORT"] = str(self.port)
        if self.tls:
            env["HYRXMQ_TLS_ENABLED"] = "true"
            env["HYRXMQ_TLS_CERT"] = self.cert or ""
            env["HYRXMQ_TLS_KEY"] = self.key or ""
        fd, self.log_path = tempfile.mkstemp(prefix="hyrxmq-cert-", suffix=".log")
        self._log = os.fdopen(fd, "w")
        self.proc = subprocess.Popen(
            [self.binary], env=env, cwd=ROOT,
            stdout=self._log, stderr=subprocess.STDOUT)
        self.pid = self.proc.pid
        return self

    def log_tail(self, n=2000):
        if not self.log_path:
            return ""
        try:
            with open(self.log_path) as fh:
                return fh.read()[-n:]
        except OSError:
            return ""

    def alive(self):
        if self.proc is not None:
            return self.proc.poll() is None
        return self.pid is not None and os.path.isdir(f"/proc/{int(self.pid)}")

    def wait_ready(self, timeout=10.0):
        """Wait until the broker accepts a real connection.

        pika + TLS is used when available (a bare TCP connect to a TLS listener
        is not a valid readiness probe and can confuse the accept loop);
        otherwise a raw TCP connect + close.
        """
        deadline = time.monotonic() + timeout
        last = "no attempt"
        while time.monotonic() < deadline:
            if self.proc is not None and self.proc.poll() is not None:
                return False, f"broker exited rc={self.proc.returncode}"
            try:
                if HAVE_PIKA:
                    conn = _connect(self.host, self.port,
                                    _ssl_ctx() if self.tls else None)
                    _force_close(conn)
                    return True, "pika handshake ok"
                s = socket.create_connection((self.host, self.port), timeout=1.0)
                s.close()
                return True, "tcp accept ok"
            except Exception as exc:  # keep polling until deadline
                last = f"{type(exc).__name__}: {exc}"
                time.sleep(0.2)
        return False, f"timeout waiting for bind ({last})"

    def stop(self):
        if not self.owned or self.proc is None:
            return
        if self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()
        try:
            self._log.close()
        except Exception:
            pass
        if self.log_path and os.path.exists(self.log_path):
            try:
                os.unlink(self.log_path)
            except OSError:
                pass


# ---------------------------------------------------------------------------
# pika workloads
# ---------------------------------------------------------------------------

def _ssl_ctx():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def _connect(host, port, sslctx=None):
    kwargs = dict(
        host=host, port=port, virtual_host=VHOST,
        credentials=pika.PlainCredentials(USER, PASSWORD),  # type: ignore[union-attr]
        heartbeat=0, frame_max=FRAME_MAX, channel_max=1,
        connection_attempts=1, socket_timeout=20,
        blocked_connection_timeout=10)
    if sslctx is not None:
        kwargs["ssl_options"] = pika.SSLOptions(sslctx, server_hostname="localhost")  # type: ignore[union-attr]
    return pika.BlockingConnection(pika.ConnectionParameters(**kwargs))  # type: ignore[union-attr]


def _force_close(conn):
    """Abrupt fd close: HyrxMQ implements connection.close, but the abrupt
    close keeps teardown out of every timed window and symmetric across runs."""
    try:
        impl = getattr(conn, "_impl", None)
        transport = getattr(impl, "_transport", None) if impl else None
        sock = getattr(transport, "_sock", None) if transport else None
        if sock is not None:
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            sock.close()
    except Exception:
        pass


def _mkbody(payload):
    return bytes((i * 31 + 7) & 0xFF for i in range(payload))


def _open_topology(conn):
    tag = f"{os.getpid()}-{time.time_ns()}"
    ch = conn.channel()
    qname = f"cert.q.{tag}"
    xname = f"cert.x.{tag}"
    ch.exchange_declare(exchange=xname, exchange_type="direct",
                        durable=False, auto_delete=True)
    ch.queue_declare(queue=qname, durable=False, exclusive=True,
                     auto_delete=True, arguments={"x-expires": 60000})
    ch.queue_bind(queue=qname, exchange=xname, routing_key="rk")
    return ch, qname, xname


def _drain(ch, qname, n, body, mismatch):
    got = 0
    idle = 0
    while got < n:
        method, _props, payload = ch.basic_get(queue=qname, auto_ack=True)
        if method is None:
            idle += 1
            if idle > 50:
                break
            time.sleep(0.001)
            continue
        idle = 0
        if body is not None and len(mismatch) < 3 and payload != body:
            mismatch.append(len(payload))
        got += 1
    return got


def pika_throughput(host, port, sslctx, payload, count, batch=BATCH):
    body = _mkbody(payload)
    conn = _connect(host, port, sslctx)
    try:
        ch, qname, xname = _open_topology(conn)
        props = pika.BasicProperties(delivery_mode=1,
                                     content_type="application/octet-stream")
        warm = int(count * WARMUP_FRAC) if count else 0
        mismatch = []
        for _ in range(0, warm, batch):
            n = min(batch, warm - _)
            for _i in range(n):
                ch.basic_publish(exchange=xname, routing_key="rk", body=body,
                                 properties=props)
            _drain(ch, qname, n, body, mismatch)

        t0 = time.perf_counter()
        done = 0
        while done < count:
            n = min(batch, count - done)
            for _i in range(n):
                ch.basic_publish(exchange=xname, routing_key="rk", body=body,
                                 properties=props)
            got = _drain(ch, qname, n, body, mismatch)
            done += n
            if got < n:
                raise RuntimeError(f"under-delivery: {got}/{n} (queue full?)")
        elapsed = time.perf_counter() - t0
    finally:
        _force_close(conn)
    return {"msgs_per_s": count / elapsed if elapsed > 0 else float("nan"),
            "seconds": elapsed, "requested": count,
            "delivered": count, "warmup": warm,
            "body_verified": not mismatch, "mismatch_lens": mismatch}


def pika_latency(host, port, sslctx, payload, ops):
    body = _mkbody(payload)
    conn = _connect(host, port, sslctx)
    samples_ms = []
    try:
        ch, qname, xname = _open_topology(conn)
        props = pika.BasicProperties(delivery_mode=1,
                                     content_type="application/octet-stream")
        _drain(ch, qname, 0, body, [])
        for _ in range(ops):
            t0 = time.perf_counter()
            ch.basic_publish(exchange=xname, routing_key="rk", body=body,
                             properties=props)
            method = None
            while method is None:
                method, _p, _b = ch.basic_get(queue=qname, auto_ack=True)
            samples_ms.append((time.perf_counter() - t0) * 1000.0)
    finally:
        _force_close(conn)
    return summarize(samples_ms)


def pika_memory_probe(broker, sslctx, payload, depth):
    """Bytes of broker RSS held per queued message (peak minus baseline)."""
    base = read_rss_kb(broker.pid)
    if base is None:
        return None
    body = _mkbody(payload)
    conn = _connect(broker.host, broker.port, sslctx)
    try:
        ch, qname, xname = _open_topology(conn)
        props = pika.BasicProperties(delivery_mode=1,
                                     content_type="application/octet-stream")
        for _ in range(depth):
            ch.basic_publish(exchange=xname, routing_key="rk", body=body,
                             properties=props)
        peak = read_rss_kb(broker.pid)
        time.sleep(0.2)
        peak = max(peak or 0, read_rss_kb(broker.pid) or 0)
        _drain(ch, qname, depth, None, [])
    finally:
        _force_close(conn)
    if peak is None:
        return None
    delta_bytes = (peak - base) * 1024
    return {"bytes_per_msg": delta_bytes / depth, "baseline_rss_kb": base,
            "peak_rss_kb": peak, "depth": depth}


# ---------------------------------------------------------------------------
# raw-socket fallback (no pika)
# ---------------------------------------------------------------------------

AMQP_HEADER = b"AMQP\x00\x00\x09\x01"


def raw_handshake_latency(host, port, ops):
    """TCP connect + AMQP protocol-header echo/handshake latency, ms."""
    samples_ms = []
    for _ in range(ops):
        t0 = time.perf_counter()
        s = socket.create_connection((host, port), timeout=5)
        try:
            s.sendall(AMQP_HEADER)
            s.settimeout(5)
            got = b""
            while len(got) < 8:
                chunk = s.recv(4096)
                if not chunk:
                    break
                got += chunk
        finally:
            s.close()
        samples_ms.append((time.perf_counter() - t0) * 1000.0)
    return summarize(samples_ms)


def raw_connection_latency(host, port, ops):
    """Bare TCP connect + close latency, ms (the transport floor)."""
    samples_ms = []
    for _ in range(ops):
        t0 = time.perf_counter()
        s = socket.create_connection((host, port), timeout=5)
        s.close()
        samples_ms.append((time.perf_counter() - t0) * 1000.0)
    return summarize(samples_ms)


# ---------------------------------------------------------------------------
# statistics
# ---------------------------------------------------------------------------

def percentile(values, p):
    if not values:
        return None
    s = sorted(values)
    if len(s) == 1:
        return s[0]
    k = (p / 100.0) * (len(s) - 1)
    lo = int(k)
    hi = min(lo + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


def summarize(samples_ms):
    if not samples_ms:
        return {"n": 0}
    return {
        "n": len(samples_ms),
        "p50_ms": round(percentile(samples_ms, 50), 4),
        "p95_ms": round(percentile(samples_ms, 95), 4),
        "p99_ms": round(percentile(samples_ms, 99), 4),
        "p99_9_ms": round(percentile(samples_ms, 99.9), 4),
        "mean_ms": round(statistics.fmean(samples_ms), 4),
    }


# ---------------------------------------------------------------------------
# threshold evaluation
# ---------------------------------------------------------------------------

def _check(checks, name, value, limit, op):
    if value is None:
        verdict = "SKIP"
    elif op == ">=":
        verdict = "PASS" if value >= limit else "FAIL"
    else:  # "<="
        verdict = "PASS" if value <= limit else "FAIL"
    checks.append({"metric": name, "value": value, "limit": limit,
                   "op": op, "verdict": verdict})
    return verdict


def evaluate(scenarios, tls_overhead, thresholds, mode):
    checks = []

    def tp(key):
        s = scenarios.get(key, {}).get("plaintext") or {}
        return (s.get("throughput") or {}).get("msgs_per_s")

    def p99(key):
        s = scenarios.get(key, {}).get("plaintext") or {}
        return (s.get("latency") or {}).get("p99_ms")

    thr = thresholds.get("throughput", {})
    lat = thresholds.get("latency", {})
    mem = thresholds.get("memory", {})
    tls = thresholds.get("tls", {})

    _check(checks, "throughput_1kb_msgs_per_s", tp("1kb"),
           thr.get("min_throughput_1kb"), ">=")
    _check(checks, "throughput_64kb_msgs_per_s", tp("64kb"),
           thr.get("min_throughput_64kb"), ">=")
    _check(checks, "throughput_1mb_msgs_per_s", tp("1mb"),
           thr.get("min_throughput_1mb"), ">=")
    _check(checks, "p99_latency_ms_1kb", p99("1kb"),
           lat.get("max_p99_latency_ms_1kb"), "<=")
    _check(checks, "p99_latency_ms_64kb", p99("64kb"),
           lat.get("max_p99_latency_ms_64kb"), "<=")
    _check(checks, "p99_latency_ms_1mb", p99("1mb"),
           lat.get("max_p99_latency_ms_1mb"), "<=")
    p999 = (scenarios.get("1kb", {}).get("plaintext") or {}).get("latency") or {}
    _check(checks, "p99_9_latency_ms_1kb", p999.get("p99_9_ms"),
           lat.get("max_p999_latency_ms_1kb"), "<=")

    mp = (scenarios.get("1kb", {}).get("plaintext") or {}).get("memory") or {}
    _check(checks, "memory_per_msg_bytes_1kb", mp.get("bytes_per_msg"),
           mem.get("max_memory_per_msg_bytes"), "<=")

    if tls_overhead is not None:
        _check(checks, "tls_overhead_pct", tls_overhead.get("overhead_pct"),
               tls.get("max_tls_overhead_pct"), "<=")
        _check(checks, "tls_throughput_ratio", tls_overhead.get("ratio"),
               tls.get("min_tls_throughput_ratio"), ">=")

    failed = [c for c in checks if c["verdict"] == "FAIL"]
    skipped = [c for c in checks if c["verdict"] == "SKIP"]
    return checks, ("FAIL" if failed else "PASS"), failed, skipped


# ---------------------------------------------------------------------------
# orchestration
# ---------------------------------------------------------------------------

def choose_counts(quick):
    idx = 1 if quick else 0
    return ({k: COUNTS[k][idx] for k, _ in SCENARIOS},
            {k: LATENCY_OPS[k][idx] for k, _ in SCENARIOS})


def run_pika_scenarios(broker, sslctx, quick, scenarios_to_run):
    out = {}
    counts, lat_ops = choose_counts(quick)
    for key, payload in SCENARIOS:
        if key not in scenarios_to_run:
            continue
        print(f"  [{key}] throughput …", flush=True)
        tp = pika_throughput(broker.host, broker.port, sslctx, payload,
                             counts[key])
        print(f"  [{key}] latency …", flush=True)
        latency = pika_latency(broker.host, broker.port, sslctx, payload,
                               lat_ops[key])
        entry = {"payload_bytes": payload, "throughput": tp,
                 "latency": latency}
        if key == "1kb" and broker.pid is not None:
            print("  [1kb] memory probe …", flush=True)
            entry["memory"] = pika_memory_probe(broker, sslctx, payload, 256)
        out[key] = {"plaintext": entry}
        print(f"  [{key}] {tp['msgs_per_s']:.0f} msg/s, "
              f"p99 {latency.get('p99_ms')} ms", flush=True)
    return out


def run_raw_scenarios(broker, quick, scenarios_to_run):
    out = {}
    counts, lat_ops = choose_counts(quick)
    for key, payload in SCENARIOS:
        if key not in scenarios_to_run:
            continue
        print(f"  [{key}] raw transport probe …", flush=True)
        entry = {"payload_bytes": payload, "throughput": None, "latency": None,
                 "raw_connection": raw_connection_latency(
                     broker.host, broker.port, 200 if not quick else 50),
                 "raw_handshake": raw_handshake_latency(
                     broker.host, broker.port, lat_ops[key])}
        out[key] = {"plaintext": entry}
    return out


def gen_self_signed(dirpath):
    """Self-signed cert/key via openssl; (cert, key) paths or (None, None)."""
    openssl = shutil.which("openssl")
    if not openssl:
        return None, None
    cert = os.path.join(dirpath, "cert.pem")
    key = os.path.join(dirpath, "key.pem")
    proc = subprocess.run(
        [openssl, "req", "-x509", "-newkey", "rsa:2048", "-days", "1",
         "-nodes", "-subj", "/CN=localhost", "-keyout", key, "-out", cert],
        capture_output=True, text=True)
    if proc.returncode != 0 or not os.path.exists(cert):
        return None, None
    return cert, key


def write_results(payload):
    os.makedirs(RESULTS_DIR, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = os.path.join(RESULTS_DIR, f"certification-{stamp}.json")
    with open(path, "w") as fh:
        json.dump(payload, fh, indent=1)
    return path


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--binary", default=None,
                    help=f"broker binary (default {DEFAULT_BIN})")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=None,
                    help="attach to a broker already listening here")
    ap.add_argument("--broker-pid", type=int, default=None,
                    help="pid of the attached broker (for RSS sampling)")
    ap.add_argument("--quick", action="store_true",
                    help="reduced message counts (smoke run)")
    ap.add_argument("--no-tls", action="store_true",
                    help="skip the TLS-overhead scenario")
    ap.add_argument("--tls-cert", default=None)
    ap.add_argument("--tls-key", default=None)
    ap.add_argument("--out", default=None,
                    help="explicit results JSON path")
    args = ap.parse_args()

    binary = find_binary(args.binary)
    if not binary:
        print("FATAL: broker binary not found.", file=sys.stderr)
        print(f"  expected: {DEFAULT_BIN}", file=sys.stderr)
        print("  build:    pixi run mojo build -I src -I vendor/flare "
              "src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen",
              file=sys.stderr)
        return 3

    with open(THRESHOLDS_PATH) as fh:
        thresholds = json.load(fh)

    mode = "pika" if HAVE_PIKA else "raw"
    if not HAVE_PIKA:
        print("WARN: pika not importable; running raw-socket fallback "
              "(message-level metrics SKIPped).", file=sys.stderr)

    scenarios_to_run = {k for k, _ in SCENARIOS}
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    notes = []
    scenarios = {}
    tls_overhead = None

    attached = args.port is not None
    if attached:
        broker = Broker(binary, args.host, args.port, owned=False,
                        pid=args.broker_pid)
        ok, why = broker.wait_ready(timeout=10.0)
        if not ok:
            print(f"FATAL: attached broker not ready: {why}", file=sys.stderr)
            return 3
    else:
        port = free_port(args.host)
        broker = Broker(binary, args.host, port, owned=True).start()
        ok, why = broker.wait_ready(timeout=10.0)
        if not ok:
            print(f"FATAL: broker did not become ready: {why}", file=sys.stderr)
            print(broker.log_tail(), file=sys.stderr)
            broker.stop()
            return 3

    tls_broker = None
    tempdir = None
    try:
        print(f"certify: mode={mode} binary={binary} "
              f"port={broker.port} attached={attached}")
        if mode == "pika":
            scenarios = run_pika_scenarios(broker, None, args.quick,
                                           scenarios_to_run)
        else:
            scenarios = run_raw_scenarios(broker, args.quick, scenarios_to_run)

        if mode == "pika" and not args.no_tls:
            tempdir = tempfile.mkdtemp(prefix="hyrxmq-cert-tls-")
            cert, key = args.tls_cert, args.tls_key
            if not (cert and key):
                cert, key = gen_self_signed(tempdir)
            if cert and key:
                print("  TLS: cert/key ready, starting TLS broker …")
                tls_port = free_port(args.host)
                tls_broker = Broker(binary, args.host, tls_port, tls=True,
                                    cert=cert, key=key, owned=True).start()
                tok, twhy = tls_broker.wait_ready(timeout=15.0)
                if not tok:
                    notes.append(f"TLS broker not ready: {twhy}")
                    print(f"  WARN: TLS broker not ready ({twhy}); "
                          f"skipping TLS overhead", file=sys.stderr)
                else:
                    counts, _ = choose_counts(args.quick)
                    tls_tp = pika_throughput(tls_broker.host, tls_broker.port,
                                             _ssl_ctx(), 1024, counts["1kb"])
                    plain_tp = ((scenarios.get("1kb", {})
                                 .get("plaintext", {}) or {})
                                .get("throughput", {}).get("msgs_per_s"))
                    if plain_tp:
                        overhead = 100.0 * (plain_tp - tls_tp["msgs_per_s"]) / plain_tp
                        tls_overhead = {
                            "plaintext_msgs_per_s": plain_tp,
                            "tls_msgs_per_s": tls_tp["msgs_per_s"],
                            "overhead_pct": overhead,
                            "ratio": tls_tp["msgs_per_s"] / plain_tp,
                            "payload_bytes": 1024,
                        }
                        scenarios.setdefault("1kb", {})["tls"] = {
                            "payload_bytes": 1024, "throughput": tls_tp}
                        print(f"  TLS: {tls_tp['msgs_per_s']:.0f} msg/s vs "
                              f"{plain_tp:.0f} plain "
                              f"({overhead:+.1f}% overhead)")
                    else:
                        notes.append("plaintext 1kb throughput missing; "
                                     "TLS overhead not computed")
            else:
                notes.append("openssl unavailable and no --tls-cert/--tls-key; "
                             "TLS scenario skipped")
                print("  TLS: openssl unavailable; scenario skipped",
                      file=sys.stderr)
    finally:
        if tls_broker is not None:
            tls_broker.stop()
        if tempdir:
            shutil.rmtree(tempdir, ignore_errors=True)
        if not attached:
            broker.stop()

    checks, verdict, failed, skipped = evaluate(scenarios, tls_overhead,
                                                thresholds, mode)
    finished = datetime.datetime.now(datetime.timezone.utc).isoformat()

    payload = {
        "schema": 1,
        "kind": "hyrxmq-certification",
        "started_utc": started,
        "finished_utc": finished,
        "host": host_info(),
        "mode": mode,
        "attached_broker": attached,
        "broker": {"binary": binary, "host": broker.host, "port": broker.port,
                   "pid": broker.pid},
        "scenarios": scenarios,
        "tls_overhead": tls_overhead,
        "thresholds": thresholds,
        "checks": checks,
        "verdict": verdict,
        "notes": notes,
    }
    path = args.out or write_results(payload)

    print("\n=== certification checks ===")
    for c in checks:
        val = "--" if c["value"] is None else f"{c['value']:.3f}"
        print(f"  {c['verdict']:>4}  {c['metric']:<28} {val:>12}  "
              f"{c['op']} {c['limit']}")
    if skipped:
        print(f"  ({len(skipped)} metric(s) SKIPped - not measurable here)")
    for n in notes:
        print(f"  note: {n}")
    print(f"\ncertification: {verdict}")
    print(f"results: {path}")
    return 1 if verdict == "FAIL" else 0


if __name__ == "__main__":
    sys.exit(main())
