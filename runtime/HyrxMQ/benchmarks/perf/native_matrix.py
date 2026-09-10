#!/usr/bin/env python
"""0019 native platform-capacity matrix: HyrxMQ TCP / HyrxMQ UDS (incl.
abstract @name) vs RabbitMQ 4.3.5, measured with the NATIVE Mojo client
(closed-loop publish->basic_get, 1 in flight) — the same client bytes on
both brokers so numbers are comparable per client.

Records benchmarks/perf/native_baseline.json (observation tier:
PLATFORM-CAPACITY see; the pika GATE number still lives in results.json).

Run: /tmp/amqp-venv/bin/python benchmarks/perf/native_matrix.py
Desktop-load caveat (0013: interactive windows distort; loadavg recorded).
"""
import json, os, socket, statistics, subprocess, time

ROOT = os.path.dirname(os.path.abspath(__file__))
BENCH = os.environ.get("HYRX_BENCH_BIN", "/tmp/opencode/mb/native_bench")
BROKER = os.path.join(ROOT, "..", "..", "build", "hyrxmq-listen")
RABBIT_PORT = int(os.environ.get("RABBIT_PORT", "5673"))
HYRX_TCP_PORT = int(os.environ.get("HYRX_PORT", "5698"))
UDS_PATH = os.environ.get("HYRX_UDS_PATH", "@hyrx_native_matrix")
REPS = int(os.environ.get("NATIVE_REPS", "3"))
SIZES = [64, 256, 1024, 4096, 16384, 65536, 131072]
COUNTS = {64: 30000, 256: 30000, 1024: 20000, 4096: 20000,
          16384: 8000, 65536: 4000, 131072: 2000}


def _wait(kind):
    for _ in range(120):
        if kind() is True:
            return True
        time.sleep(0.2)
    return False


def wait_tcp(port):
    return _wait(lambda: (lambda c: (c.settimeout(0.2), c.connect(
        ("127.0.0.1", port)))[1] is None or True)(socket.socket())
        if False else _probe_tcp(port))


def _probe_tcp(port):
    try:
        s = socket.socket()
        s.settimeout(0.2)
        try:
            s.connect(("127.0.0.1", port))
            return True
        finally:
            s.close()
    except OSError:
        return False


def _probe_uds(path):
    # @name = abstract namespace: NO file path exists; readiness = a live
    # AF_UNIX connect to "\0<name>". Pathname sockets test the file.
    try:
        addr = ("\0" + path[1:]) if path.startswith("@") else path
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(0.2)
        try:
            s.connect(addr)
            return True
        finally:
            s.close()
    except OSError:
        return False


def _parse(out):
    rate = us = 0.0
    for line in (out or "").splitlines():
        if line.startswith("NATIVE_BENCH size="):
            for tok in line.split():
                if tok.startswith("rate="):
                    rate = float(tok[5:])
                elif tok.startswith("us_per_msg="):
                    us = float(tok[11:])
    return rate, us


def _run(peer, size, count, no_echo=False):
    arg = [BENCH, peer, "--sizes", str(size), "--count", str(count)]
    if peer.startswith("@") or peer.startswith("/"):
        arg = [BENCH, "--uds", peer, "--sizes", str(size),
               "--count", str(count)]
    if no_echo:
        arg.append("--no-echo")
    try:
        out = subprocess.run(arg, capture_output=True, text=True,
                             timeout=max(45, count // 12))
        return _parse(out.stdout)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return 0.0, 0.0


def start_broker(env_extra, tag):
    env = dict(os.environ)
    env.update(env_extra)
    out = open(f"/tmp/native-matrix-{tag}.log", "w")
    return subprocess.Popen([os.path.abspath(BROKER)], stdout=out,
                            stderr=subprocess.STDOUT, env=env)


def stop(proc):
    if not proc or proc.poll() is not None:
        return
    proc.terminate()
    try:
        proc.wait(timeout=3)
    except Exception:
        proc.kill()


def measure(env_extra, ready, peer):
    proc = start_broker(env_extra, keyword(peer, env_extra))
    try:
        up = False
        for _ in range(120):  # 120x0.2s readiness budget
            if ready():
                up = True
                break
            if proc.poll() is not None:
                raise RuntimeError("broker exited early rc=%s"
                                   % proc.returncode)
            time.sleep(0.2)
        if not up:
            raise RuntimeError("broker did not come up")
        cell = {}
        for size in SIZES:
            rates, uss = [], []
            for _ in range(REPS):
                r, u = _run(peer, size, COUNTS[size])
                if r > 0:
                    rates.append(r)
                    uss.append(u)
            if rates:
                cell[str(size)] = {
                    "rate_median": statistics.median(rates),
                    "rate_max": max(rates),
                    "us_median": statistics.median(uss),
                    "reps": len(rates),
                }
        return cell
    finally:
        stop(proc)


def keyword(peer, env):

    return "hyrx"


def loadavg():
    return round(float(open("/proc/loadavg").read().split()[0]), 2)


def main():
    cells = {}
    t0 = time.time()
    env = { "HYRXMQ_HOST": "127.0.0.1",
            "HYRXMQ_PORT": str(HYRX_TCP_PORT) }
    cells["hyrx-tcp"] = measure(env, lambda: _probe_tcp(HYRX_TCP_PORT),
                                str(HYRX_TCP_PORT))
    env = { "HYRXMQ_UDS_PATH": UDS_PATH }
    cells["hyrx-uds"] = measure(env, lambda: _probe_uds(UDS_PATH), UDS_PATH)
    cellr = {}
    for size in SIZES:
        rates, uss = [], []
        for _ in range(REPS):
            r, u = _run(str(RABBIT_PORT), size, COUNTS[size], no_echo=True)
            if r > 0:
                rates.append(r)
                uss.append(u)
        if rates:
            cellr[str(size)] = {"rate_median": statistics.median(rates),
                                "rate_max": max(rates),
                                "us_median": statistics.median(uss)}
    cells["rabbit"] = cellr
    doc = {"schema": 1,
           "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "loadavg_1m": loadavg(), "wall_s": round(time.time() - t0, 1),
           "client": "native mojo closed loop, 1 in flight",
           "cells": cells,
           "note": "observation tier for PLATFORM-CAPACITY; the pika gate"
                   " number lives in results.json"}
    dst = os.path.join(ROOT, "native_baseline.json")
    with open(dst, "w") as fh:
        json.dump(doc, fh, indent=2)
    print(f"{'size':>8} {'hyrx-tcp':>9} {'hyrx-uds':>9} {'rabbit':>9} "
          f"{'uds/rb':>8} {'tcp/rb':>8}")
    for size in SIZES:
        k = str(size)
        h = cells["hyrx-tcp"].get(k, {}).get("rate_median", 0)
        u = cells["hyrx-uds"].get(k, {}).get("rate_median", 0)
        r = cells["rabbit"].get(k, {}).get("rate_median", 0)
        ur = f"{u/r:.2f}x" if r and u else "-"

        tr = f"{h/r:.2f}x" if r and h else "-"
        print(f"{size:>8} {h:>9.0f} {u:>9.0f} {r:>9.0f} {ur:>8} {tr:>8}")


if __name__ == "__main__":
    main()
