#!/usr/bin/env python3
"""HyrxMQ (M9) extended soak-test driver.

Runs a fixed-rate workload against one HyrxMQ broker for a configurable
duration (default 60s; `--duration 3600` for the 1-hour soak) while sampling
the broker's resident memory (`/proc/<pid>/status` VmRSS) and open file
descriptors (`/proc/<pid>/fd`) every `--sample-interval` seconds.

Detects:
  * memory leaks  -- RSS growth from the first half to the second half beyond
                     `soak_max_rss_growth_pct`;
  * fd leaks      -- descriptor-count growth beyond `soak_max_fd_growth`;
  * latency drift -- second-half p99 vs first-half p99 beyond
                     `soak_max_p99_degradation_pct`.

Writes a JSON report under `results/` and prints PASS/FAIL; exits non-zero on
any leak/degradation. pika is used when importable; otherwise a raw
TCP + AMQP-header connect/close cycle is the kept-alive workload (message-level
latency is then unavailable and reported as such, never fabricated).

Usage:
  python3 benchmarks/certification/soak.py
  python3 benchmarks/certification/soak.py --duration 3600 --rate 200
  python3 benchmarks/certification/soak.py --port 5673 --broker-pid 12345
  bash benchmarks/certification/run_certification.sh --quick
"""
import argparse
import datetime
import json
import os
import socket
import statistics
import subprocess
import sys
import tempfile
import threading
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

USER = os.environ.get("HYRX_USER", "admin")
PASSWORD = os.environ.get("HYRX_PASS", "password")
VHOST = "/"
FRAME_MAX = 131072
AMQP_HEADER = b"AMQP\x00\x00\x09\x01"


# ---------------------------------------------------------------------------
# process sampling
# ---------------------------------------------------------------------------

def read_rss_kb(pid):
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


def median(values):
    return statistics.median(values) if values else None


class Sampler(threading.Thread):
    """Samples RSS + fd count on an interval until stopped."""

    def __init__(self, pid, interval):
        super().__init__(daemon=True)
        self.pid = pid
        self.interval = interval
        self.samples = []          # (t, rss_kb, fds)
        self._stop = threading.Event()
        self._t0 = time.monotonic()

    def run(self):
        while not self._stop.is_set():
            self.samples.append((round(time.monotonic() - self._t0, 3),
                                 read_rss_kb(self.pid), count_fds(self.pid)))
            self._stop.wait(self.interval)

    def stop(self):
        self._stop.set()
        # take one final sample so the tail is represented
        self.samples.append((round(time.monotonic() - self._t0, 3),
                             read_rss_kb(self.pid), count_fds(self.pid)))


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
    def __init__(self, binary, host, port, owned=True, pid=None):
        self.binary = binary
        self.host = host
        self.port = port
        self.owned = owned
        self.pid = pid
        self.proc = None
        self.log_path = None

    def start(self):
        env = dict(os.environ)
        env["HYRXMQ_HOST"] = self.host
        env["HYRXMQ_PORT"] = str(self.port)
        fd, self.log_path = tempfile.mkstemp(prefix="hyrxmq-soak-", suffix=".log")
        self._log = os.fdopen(fd, "w")
        self.proc = subprocess.Popen([self.binary], env=env, cwd=ROOT,
                                     stdout=self._log, stderr=subprocess.STDOUT)
        self.pid = self.proc.pid
        return self

    def alive(self):
        if self.proc is not None:
            return self.proc.poll() is None
        return self.pid is not None and os.path.isdir(f"/proc/{int(self.pid)}")

    def wait_ready(self, timeout=10.0):
        deadline = time.monotonic() + timeout
        last = "no attempt"
        while time.monotonic() < deadline:
            if self.proc is not None and self.proc.poll() is not None:
                return False, f"broker exited rc={self.proc.returncode}"
            try:
                if HAVE_PIKA:
                    conn = _connect(self.host, self.port)
                    _force_close(conn)
                    return True, "pika handshake ok"
                socket.create_connection((self.host, self.port), timeout=1).close()
                return True, "tcp accept ok"
            except Exception as exc:
                last = f"{type(exc).__name__}: {exc}"
                time.sleep(0.2)
        return False, f"timeout ({last})"

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
# workloads
# ---------------------------------------------------------------------------

def _connect(host, port):
    return pika.BlockingConnection(pika.ConnectionParameters(
        host=host, port=port, virtual_host=VHOST,
        credentials=pika.PlainCredentials(USER, PASSWORD),
        heartbeat=0, frame_max=FRAME_MAX, channel_max=1,
        connection_attempts=1, socket_timeout=20,
        blocked_connection_timeout=10))


def _force_close(conn):
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


def soak_pika(broker, duration, rate, payload):
    """Fixed-rate publish -> get round trip; returns (latencies_ms, errors)."""
    body = bytes((i * 31 + 7) & 0xFF for i in range(payload))
    conn = _connect(broker.host, broker.port)
    latencies = []
    errors = 0
    try:
        ch = conn.channel()
        tag = f"{os.getpid()}-{time.time_ns()}"
        qname, xname = f"soak.q.{tag}", f"soak.x.{tag}"
        ch.exchange_declare(exchange=xname, exchange_type="direct",
                            durable=False, auto_delete=True)
        ch.queue_declare(queue=qname, durable=False, exclusive=True,
                         auto_delete=True, arguments={"x-expires": 60000})
        ch.queue_bind(queue=qname, exchange=xname, routing_key="rk")
        props = pika.BasicProperties(delivery_mode=1,
                                     content_type="application/octet-stream")
        deadline = time.monotonic() + duration
        interval = 1.0 / rate if rate > 0 else 0.0
        next_at = time.monotonic()
        while time.monotonic() < deadline and broker.alive():
            now = time.monotonic()
            if interval and now < next_at:
                time.sleep(min(next_at - now, 0.5))
                continue
            next_at = max(next_at + interval, time.monotonic())
            try:
                t0 = time.perf_counter()
                ch.basic_publish(exchange=xname, routing_key="rk", body=body,
                                 properties=props)
                method = None
                while method is None:
                    method, _p, _b = ch.basic_get(queue=qname, auto_ack=True)
                latencies.append((time.perf_counter() - t0) * 1000.0)
            except Exception:
                errors += 1
                if not broker.alive():
                    break
    finally:
        _force_close(conn)
    return latencies, errors


def soak_raw(broker, duration, rate):
    """Raw TCP + AMQP-header connect/close cycle; returns (latencies_ms, errors)."""
    latencies = []
    errors = 0
    deadline = time.monotonic() + duration
    interval = 1.0 / rate if rate > 0 else 0.0
    next_at = time.monotonic()
    while time.monotonic() < deadline and broker.alive():
        now = time.monotonic()
        if interval and now < next_at:
            time.sleep(min(next_at - now, 0.5))
            continue
        next_at = max(next_at + interval, time.monotonic())
        try:
            t0 = time.perf_counter()
            s = socket.create_connection((broker.host, broker.port), timeout=5)
            try:
                s.sendall(AMQP_HEADER)
                s.settimeout(5)
                s.recv(4096)
            finally:
                s.close()
            latencies.append((time.perf_counter() - t0) * 1000.0)
        except Exception:
            errors += 1
            if not broker.alive():
                break
    return latencies, errors


# ---------------------------------------------------------------------------
# leak analysis
# ---------------------------------------------------------------------------

def analyze(samples, latencies, duration, thresholds):
    th = thresholds.get("soak", {})
    rss = [s[1] for s in samples if s[1] is not None]
    fds = [s[2] for s in samples if s[2] is not None]

    first, second = _halves(samples)
    rss_first = [s[1] for s in first if s[1] is not None]
    rss_second = [s[1] for s in second if s[1] is not None]
    rss_growth_pct = _growth_pct(rss_first, rss_second)
    rss_monotonic = _strictly_increasing(rss)

    fd_first = [s[2] for s in first if s[2] is not None]
    fd_second = [s[2] for s in second if s[2] is not None]
    fd_growth = None
    if fd_first and fd_second:
        fd_growth = max(fd_second) - min(fd_first)

    lat_first, lat_second = _halves_values(latencies)
    p99_first = percentile(lat_first, 99)
    p99_second = percentile(lat_second, 99)
    lat_degradation_pct = None
    if p99_first and p99_second and p99_first > 0:
        lat_degradation_pct = 100.0 * (p99_second - p99_first) / p99_first

    checks = []
    checks.append(_check("rss_growth_pct", rss_growth_pct,
                         th.get("soak_max_rss_growth_pct"), "<="))
    checks.append(_check("fd_growth", fd_growth,
                         th.get("soak_max_fd_growth"), "<="))
    checks.append(_check("p99_degradation_pct", lat_degradation_pct,
                         th.get("soak_max_p99_degradation_pct"), "<="))

    failed = [c for c in checks if c["verdict"] == "FAIL"]
    report = {
        "duration_s": duration,
        "samples": len(samples),
        "rss_kb_first_sample": rss[0] if rss else None,
        "rss_kb_last_sample": rss[-1] if rss else None,
        "rss_growth_pct": _round(rss_growth_pct),
        "rss_monotonic_increase": rss_monotonic,
        "fd_first_sample": fds[0] if fds else None,
        "fd_last_sample": fds[-1] if fds else None,
        "fd_min": min(fds) if fds else None,
        "fd_max": max(fds) if fds else None,
        "fd_growth": fd_growth,
        "latency_ops": len(latencies),
        "p50_ms": _round(percentile(latencies, 50)),
        "p99_ms": _round(percentile(latencies, 99)),
        "p99_first_half_ms": _round(p99_first),
        "p99_second_half_ms": _round(p99_second),
        "p99_degradation_pct": _round(lat_degradation_pct),
        "checks": checks,
        "time_series": [{"t": s[0], "rss_kb": s[1], "fds": s[2]}
                        for s in samples],
        "notes": [],
    }
    if not latencies:
        report["notes"].append("no latency samples (raw fallback or broker "
                               "stopped early)")
    if rss_monotonic and (rss_growth_pct or 0) > th.get("soak_max_rss_growth_pct", 0):
        report["notes"].append("RSS grows monotonically across every sample")
    return report, ("FAIL" if failed else "PASS"), failed


def _halves(samples):
    n = len(samples)
    return samples[: n // 2], samples[n // 2:]


def _halves_values(values):
    n = len(values)
    return values[: n // 2], values[n // 2:]


def _growth_pct(first, second):
    if not first or not second:
        return None
    a, b = median(first), median(second)
    if a is None or b is None or a == 0:
        return None
    return 100.0 * (b - a) / a


def _strictly_increasing(values):
    return len(values) >= 3 and all(values[i] < values[i + 1]
                                    for i in range(len(values) - 1))


def _check(name, value, limit, op):
    if value is None or limit is None:
        verdict = "SKIP"
    elif op == "<=":
        verdict = "PASS" if value <= limit else "FAIL"
    else:
        verdict = "PASS" if value >= limit else "FAIL"
    return {"metric": name, "value": value, "limit": limit, "op": op,
            "verdict": verdict}


def _round(x):
    return None if x is None else round(x, 4)


def write_report(payload):
    os.makedirs(RESULTS_DIR, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = os.path.join(RESULTS_DIR, f"soak-{stamp}.json")
    with open(path, "w") as fh:
        json.dump(payload, fh, indent=1)
    return path


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--binary", default=None)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=None,
                    help="attach to a broker already listening here")
    ap.add_argument("--broker-pid", type=int, default=None)
    ap.add_argument("--duration", type=float, default=60.0,
                    help="seconds (default 60; use 3600 for the 1-hour soak)")
    ap.add_argument("--rate", type=float, default=100.0,
                    help="target messages/sec (default 100)")
    ap.add_argument("--payload", type=int, default=1024)
    ap.add_argument("--sample-interval", type=float, default=5.0)
    ap.add_argument("--quick", action="store_true",
                    help="15s duration, 2s sampling (smoke run)")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    if args.quick:
        args.duration = min(args.duration, 15.0)
        args.sample_interval = min(args.sample_interval, 2.0)

    binary = find_binary(args.binary)
    if not binary and args.port is None:
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
        print("WARN: pika not importable; raw connect/close soak mode "
              "(latency metrics unavailable).", file=sys.stderr)

    attached = args.port is not None
    if attached:
        broker = Broker(binary or "attached", args.host, args.port,
                        owned=False, pid=args.broker_pid)
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
            broker.stop()
            return 3

    if broker.pid is None:
        print("WARN: broker pid unknown; RSS/fd sampling disabled.",
              file=sys.stderr)

    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    sampler = Sampler(broker.pid, args.sample_interval) if broker.pid else None
    if sampler:
        sampler.start()

    print(f"soak: mode={mode} broker_pid={broker.pid} port={broker.port} "
          f"duration={args.duration:.0f}s rate={args.rate:.0f}/s "
          f"payload={args.payload}B")
    try:
        if mode == "pika":
            latencies, errors = soak_pika(broker, args.duration, args.rate,
                                          args.payload)
        else:
            latencies, errors = soak_raw(broker, args.duration, args.rate)
        alive = broker.alive()
    finally:
        if sampler:
            sampler.stop()
            sampler.join(timeout=5)
        if not attached:
            broker.stop()

    samples = sampler.samples if sampler else []
    report, verdict, failed = analyze(samples, latencies, args.duration,
                                      thresholds)
    report.update({
        "schema": 1,
        "kind": "hyrxmq-soak",
        "started_utc": started,
        "finished_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "mode": mode,
        "attached_broker": attached,
        "broker_pid": broker.pid,
        "target_rate": args.rate,
        "payload_bytes": args.payload,
        "sample_interval_s": args.sample_interval,
        "errors": errors,
        "broker_alive_at_end": alive,
        "verdict": verdict,
    })
    if not alive:
        report["verdict"] = "FAIL"
        report["notes"].append("broker was not alive at the end of the soak")
    path = args.out or write_report(report)

    print("\n=== soak checks ===")
    for c in report["checks"]:
        val = "--" if c["value"] is None else f"{c['value']:.3f}"
        print(f"  {c['verdict']:>4}  {c['metric']:<24} {val:>12}  "
              f"{c['op']} {c['limit']}")
    print(f"  RSS   {report['rss_kb_first_sample']} -> "
          f"{report['rss_kb_last_sample']} KB "
          f"({report['rss_growth_pct']}%)")
    print(f"  fds   min={report['fd_min']} max={report['fd_max']} "
          f"growth={report['fd_growth']}")
    print(f"  p99   {report['p99_first_half_ms']} -> "
          f"{report['p99_second_half_ms']} ms "
          f"({report['p99_degradation_pct']}%)")
    for n in report["notes"]:
        print(f"  note: {n}")
    print(f"\nsoak: {report['verdict']}")
    print(f"report: {path}")
    return 1 if report["verdict"] == "FAIL" else 0


if __name__ == "__main__":
    sys.exit(main())
