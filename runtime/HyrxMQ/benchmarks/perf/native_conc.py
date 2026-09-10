#!/usr/bin/env python
"""0019-concurrency: N simultaneous native boundaries per cell.

Measures PLATFORM CAPACITY under N concurrent closed-loop publish->get
clients (native Mojo client, 1 in flight per conn), aggregate = total
messages / wall window. Cells: hyrx-tcp / hyrx-uds on BOTH serving tiers
(legacy serialized + 0015 event-driven, in the shipped build) + rabbit.

Run: /tmp/amqp-venv/bin/python benchmarks/perf/native_conc.py
Writes benchmarks/perf/native_conc_c<N>.json + prints the tables.
"""
import json, os, re, socket, subprocess, time, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
BENCH = os.environ.get("HYRX_BENCH_BIN", "/tmp/opencode/mb/native_bench")
BROKER = os.path.abspath(os.path.join(ROOT, "..", "..", "build",
                                      "hyrxmq-listen"))
BROKER_EV = os.environ.get("HYRX_EV_BIN", "/tmp/opencode/mb/hyrx_broker_ev")
RABBIT_PORT = int(os.environ.get("RABBIT_PORT", "5673"))
HYRX_TCP_PORT = int(os.environ.get("HYRX_PORT", "5698"))
UDS_PATH = os.environ.get("HYRX_UDS_PATH", "@hyrx_native_conc")
SIZES = [64, 256, 1024, 4096, 16384, 65536, 131072]
TOTALS = {64: 60000, 256: 60000, 1024: 40000, 4096: 30000,
          16384: 12000, 65536: 6000, 131072: 3000}


def probe_tcp(port):
    try:
        s = socket.socket(); s.settimeout(0.3)
        try:
            s.connect(("127.0.0.1", port)); return True
        finally:
            s.close()
    except OSError:
        return False


def probe_uds(path):
    addr = ("\0" + path[1:]) if path.startswith("@") else path
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(0.3)
        try:
            s.connect(addr); return True
        finally:
            s.close()
    except OSError:
        return False


BATCH = int(os.environ.get("HYRX_BATCH", "1"))


def start(broker, env_extra, tag):
    env = dict(os.environ)
    env.update(env_extra)
    out = open(f"/tmp/native-conc-{tag}.log", "w")
    return subprocess.Popen([os.path.abspath(broker)], stdout=out,
                            stderr=subprocess.STDOUT, env=env)


def stop(proc):
    if proc and proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except Exception:
            proc.kill()


def cell_run(broker, env_extra, tag, peer, ready, no_echo, N):
    d = {}
    proc = start(broker, env_extra, tag)
    try:
        up = False
        for _ in range(20):
            if ready():
                up = True; break
            if proc.poll() is not None:
                log = f"/tmp/native-conc-{tag}.log"
                with open(log) as fh:
                    raise RuntimeError(f"{tag}: broker early-exit: "
                                       + " ".join(fh.readlines()[:3]))
            time.sleep(0.3)
        if not up:
            raise RuntimeError(f"{tag}: broker did not come up")
        for size in SIZES:
            per = max(1, TOTALS[size] // N)
            handles = []
            t0 = time.time()
            for _ in range(N):
                if peer.startswith("@") or peer.startswith("/"):
                    a = [BENCH, "--uds", peer, "--sizes", str(size),
                         "--count", str(per)] + (["--batch", str(BATCH)] if BATCH > 1 else [])
                else:
                    a = [BENCH, peer, "--sizes", str(size),
                         "--count", str(per)] + (["--batch", str(BATCH)] if BATCH > 1 else [])
                if no_echo:
                    a.append("--no-echo")
                handles.append((per, subprocess.Popen(a, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)))
            total_msgs = 0
            for per_c, h in handles:
                o, _e = h.communicate(timeout=300)
                if o and "NATIVE_BENCH size=" in o:
                    total_msgs += per_c
            wall = time.time() - t0
            d[str(size)] = {"msgs_total": total_msgs,
                            "wall_s": round(wall, 2),
                            "aggregate_msg_s":
                                round(total_msgs / wall) if wall > 0 else 0}
            print(f"  {tag:<10} {size:>6}B wall={wall:6.2f}s "
                  f"done={total_msgs} agg={d[str(size)]['aggregate_msg_s']:>9,}"
                  " msg/s", flush=True)
        return d
    finally:
        stop(proc)


def main():
    N = int(os.environ.get("HYRX_CONC", "10"))
    print(f"native concurrency matrix: N={N} (total per size "
          f"= per-client x {N})")
    cells = {}
    # --- hyrx-TCP legacy (0015 flag OFF, serialized) ---
    print("cell hyrx-tcp legacy:")
    cells["hyrx-tcp-legacy"] = cell_run(
        BROKER, {"HYRXMQ_HOST": "127.0.0.1",
                 "HYRXMQ_PORT": "5698"}, "hyrx-tcp-legacy",
        "5698", (lambda: probe_tcp(5698)), False, N)
    # --- hyrx-uds legacy ---
    print("cell hyrx-uds legacy:")
    cells["hyrx-uds-legacy"] = cell_run(
        BROKER, {"HYRXMQ_UDS_PATH": "@hyrx_conc"}, "hyrx-uds-legacy",
        "@hyrx_conc", (lambda: probe_uds("@hyrx_conc")), False, N)
    # --- rabbit 10 conns (native client) ---
    print("cell rabbit:")
    cells["rabbit"] = cell_run(
        "echo", {}, "rabbit", str(RABBIT_PORT),
        (lambda: probe_tcp(RABBIT_PORT)), True, N)
    # --- event-driven tier (built variant with the 0015 loop ON) ---
    try:
        print("cell hyrx-tcp event:")
        cells["hyrx-tcp-event"] = cell_run(
            os.environ.get("HYRX_EV_BIN", "/tmp/opencode/mb/hyrx_broker_ev"),
            {"HYRXMQ_HOST": "127.0.0.1", "HYRXMQ_PORT": "5698"},
            "hyrx-tcp-event", "5698", (lambda: probe_tcp(5698)), False, N)
        print("cell hyrx-uds event:")
        cells["hyrx-uds-event"] = cell_run(
            os.environ.get("HYRX_EV_BIN", "/tmp/opencode/mb/hyrx_broker_ev"),
            {"HYRXMQ_UDS_PATH": "@hyrx_conc"}, "hyrx-uds-event",
            "@hyrx_conc", (lambda: probe_uds("@hyrx_conc")), False, N)
    except Exception as e:
        print("event-tier cell skipped:", e)
    # summary + write
    dst = os.path.join(ROOT, "native_conc_c%d.json" % N)
    doc = {"schema": 1, "N": N,
           "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "loadavg": round(float(open("/proc/loadavg").read().split()[0]), 2),
           "broker_bin_legacy": BROKER,
           "broker_bin_event": (os.environ.get("HYRX_EV_BIN",
                                "/tmp/opencode/mb/hyrx_broker_ev")),
           "cells": cells}
    with open(dst, "w") as fh:
        json.dump(doc, fh, indent=2)
    print(f"cells: {', '.join(sorted(cells))}")
    print("written:", dst)
    # table summary
    print(f"{'size':>8} " + " ".join(f"{t:>12}" for t in sorted(cells.keys())))
    for size in SIZES:
        k = str(size)
        row = f"{size:>8} "
        for t in sorted(cells.keys()):
            v = cells[t].get(k, {}).get("aggregate_msg_s", 0) if t in cells else 0
            row += f"{v:>12,}"
        print(row)


def cell_run(broker, env_extra, tag, peer, ready, no_echo, N):
    """Broker is 'echo' for rabbit (already live): pass-through without runs."""
    if broker == "echo":
        # rabbit: no broker to spawn; run the clients straight
        d = {}
        for size in SIZES:
            per = max(1, TOTALS[size] // N)
            handles = []
            t0 = time.time()
            for _ in range(N):
                a = [BENCH, str(RABBIT_PORT), "--sizes", str(size),
                     "--count", str(per), "--no-echo"] + (
                     ["--batch", str(BATCH)] if BATCH > 1 else [])
                handles.append((per, subprocess.Popen(a, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)))
            total = 0
            for per_c, h in handles:
                o, _e = h.communicate(timeout=300)
                if o and "NATIVE_BENCH size=" in o:
                    total += per_c
            wall = time.time() - t0
            d[str(size)] = {"msgs_total": total, "wall_s": round(wall, 2),
                            "aggregate_msg_s":
                                round(total / wall) if wall > 0 else 0}
            print(f"  {'rabbit':<10} {size:>6}B wall={wall:6.2f}s "
                  f"done={total} agg={d[str(size)]['aggregate_msg_s']:>9,}"
                  " msg/s", flush=True)
        return d
    d = {}
    proc = start(broker, env_extra, tag)
    try:
        up = False
        for _ in range(20):
            if ready():
                up = True; break
            if proc.poll() is not None:
                log = f"/tmp/native-conc-{tag}.log"
                with open(log) as fh:
                    head = "".join(ln for ln in fh.readlines()[:3]
                                   if "warn" not in ln.lower())
                raise RuntimeError(f"{tag}: early-exit: {head}")
            time.sleep(0.3)
        if not up:
            raise RuntimeError(f"{tag}: not up")
        for size in SIZES:
            per = max(1, TOTALS[size] // N)
            handles = []
            t0 = time.time()
            for _ in range(N):
                if peer.startswith("@") or peer.startswith("/"):
                    a = [BENCH, "--uds", peer, "--sizes", str(size),
                         "--count", str(per)] + (["--batch", str(BATCH)] if BATCH > 1 else [])
                else:
                    a = [BENCH, peer, "--sizes", str(size),
                         "--count", str(per)] + (["--batch", str(BATCH)] if BATCH > 1 else [])
                if no_echo:
                    a.append("--no-echo")
                handles.append((per, subprocess.Popen(a, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)))
            total_msgs = 0
            for per_c, h in handles:
                o, _e = h.communicate(timeout=300)
                if o and "NATIVE_BENCH size=" in o:
                    total_msgs += per_c
            wall = time.time() - t0
            d[str(size)] = {"msgs_total": total_msgs,
                            "wall_s": round(wall, 2),
                            "aggregate_msg_s":
                                round(total_msgs / wall) if wall > 0 else 0}
            print(f"  {tag:<10} {size:>6}B wall={wall:6.2f}s "
                  f"done={total_msgs} agg={d[str(size)]['aggregate_msg_s']:>9,}"
                  " msg/s", flush=True)
        return d
    finally:
        stop(proc)


if __name__ == "__main__":
    main()
