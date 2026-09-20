#!/usr/bin/env python3
"""make_report.py — render REPORT.md from the consolidated benchmark JSON.

Usage: make_report.py <consolidated.json> <REPORT.md>

The report is generated from real measurements only. If a transport is
blocked, the report says so and does not invent numbers.
"""
import json
import math
import sys
from datetime import datetime, timezone


def geomean(xs):
    xs = [x for x in xs if x and x > 0]
    if not xs:
        return None
    return math.exp(sum(math.log(x) for x in xs) / len(xs))


def cell_key(c):
    return (c["workload"], c["payload"], c["concurrency"])


def fmt_row(cells, workload, payload, conc):
    tcp = next((c for c in cells if c["transport"] == "tcp"
                and cell_key(c) == (workload, payload, conc)), None)
    ws = next((c for c in cells if c["transport"] == "ws"
               and cell_key(c) == (workload, payload, conc)), None)
    return tcp, ws


def main():
    src, out = sys.argv[1], sys.argv[2]
    data = json.load(open(src))
    cells = data.get("cells", [])
    blocked = data.get("blocked", [])
    resources = data.get("resources", {})

    quick = data.get("quick")
    stamp = data.get("stamp", "unknown")
    ws_blocked = any(b.get("blocked") for b in blocked if b.get("transport") == "ws")

    workloads = ["publish", "pubget", "confirm", "latency"]
    payloads = sorted({c["payload"] for c in cells})
    concs = sorted({c["concurrency"] for c in cells})

    L = []
    L.append("# HyrxMQ Interface Benchmark: TCP vs WebSocket\n")
    L.append(f"Generated: {datetime.now(timezone.utc).isoformat(timespec='seconds')}  ")
    L.append(f"Run stamp: `{stamp}`  ")
    L.append(f"Matrix: **{'quick' if quick else 'full'}**\n")

    L.append("## Methodology\n")
    L.append(
        "One compiled Go binary (`benchmarks/interfaces/go`, module "
        "`hyrxmq-interfaces`) drives BOTH transports through the same "
        "`Transport` interface `{Write,Read,Close}`. `TCPTransport` wraps a "
        "`net.Conn` with `TCP_NODELAY`; `WSTransport` wraps a gorilla "
        "`*websocket.Conn` (one binary write per call; reads concatenate WS "
        "payloads into a byte stream). The raw AMQP 0-9-1 client in `amqp.go` "
        "speaks only to `Transport`, so the only difference between the TCP "
        "and WS runs is `--transport`.\n")
    L.append(
        "Topology: one goroutine per connection; each opens its own "
        "connection + channel + exchange/queue, so concurrent workers never "
        "contend on one queue. `publish` is fire-and-forget to a bindingless "
        "direct exchange; `pubget` publishes a batch then drains it with "
        "`basic.get(auto_ack)`; `confirm` waits for a per-publish "
        "`basic.ack`; `latency` is publish -> get -> ack per message. Payload "
        "64 B..256 KiB, concurrency 1/4/16, rotated run order, medians across "
        "reps. Broker `/proc/<pid>/stat` and `VmRSS` are sampled around the "
        "matrix.\n")

    if ws_blocked:
        L.append("## WSS tier status: BLOCKED\n")
        for b in blocked:
            if b.get("transport") == "ws":
                L.append(f"- {b.get('reason', 'blocked')}")
        L.append(
            "- The shipped `hyrxmq-listen` refuses `HYRXMQ_WSS_TLS_MODE=none` "
            "(no cert source) and, with a cert, its `WSSAMQPListener."
            "serve_forever` raises because the default `event_driven_serving()`"
            " loop reads the raw fd and cannot de-frame WebSocket bytes.\n"
            "- A benchmark-only launcher (`ws_broker.mojo`, no `src/` changes) "
            "was built to compose the same `WSSListener` + "
            "`AMQPConnServing[WSSConnection]` with the legacy WSS loop. Its "
            "probe result is recorded below; the WS carrier's blocking read "
            "contract (`recv_bytes` waits for a full ~131 KB quota or peer "
            "CLOSE/EOF) deadlocks a normal request/response client.\n")
        L.append(
            "**No WebSocket comparison numbers are reported because the "
            "transport is not serviceable in this build.** The TCP matrix "
            "below is real and complete.\n")
        L.append("### Evidence (exact, reproducible)\n")
        L.append("```text")
        L.append("$ HYRXMQ_WSS_LISTEN=<p> HYRXMQ_WSS_TLS_MODE=none ./build/hyrxmq-listen")
        L.append("Unhandled exception: WSSAMQPListener.start: no cert source configured")
        L.append("  (wss_tls_mode=none); the wss tier refuses to start.")
        L.append("")
        L.append("$ HYRXMQ_WSS_LISTEN=<p> HYRXMQ_WSS_TLS_MODE=path \\")
        L.append("    HYRXMQ_WSS_TLS_PATH=cert.pem HYRXMQ_WSS_TLS_KEY=key.pem ./build/hyrxmq-listen")
        L.append("HyrxMQ hyrxmq@localhost listening on wss://127.0.0.1:<p>")
        L.append("Unhandled exception: WSSAMQPListener.serve_forever: event-driven serving")
        L.append("  reads the raw fd (plaintext seam) and is not valid on the TLS-carrying")
        L.append("  wss tier; use the legacy loop (event_driven_serving = False)")
        L.append("")
        L.append("$ HYRXMQ_WSS_LISTEN=<p> ./build/hyrxmq-ws-bench   # plaintext ws:// launcher")
        L.append("HyrxMQ ws_broker (plaintext ws://, legacy WSS loop) listening on ws://...")
        L.append("$ timeout 8 ./ifbench -transport ws -url 127.0.0.1:<p> -probe   # timed out")
        L.append("hyrxmq: connection.start-ok mechanism=PLAIN authcid=admin locale=en_US")
        L.append("  (logged only after the client gave up; WSSConnection.recv_bytes blocked")
        L.append("   waiting for its full frame_max+8 byte quota)")
        L.append("```\n")
    elif not any(c["transport"] == "ws" for c in cells):
        L.append("## WSS tier status: no WS cells collected\n")

    # ---- throughput table ----
    L.append("## Throughput (msgs/sec, medians)\n")
    have_ws = any(c["transport"] == "ws" for c in cells)
    if have_ws:
        L.append("| workload | payload | conc | TCP | WS | WS/TCP |")
        L.append("|---|---:|---:|---:|---:|---:|")
    else:
        L.append("| workload | payload | conc | TCP msgs/sec | TCP wall s |")
        L.append("|---|---:|---:|---:|---:|")
    for w in workloads:
        for p in payloads:
            for c in concs:
                tcp, ws = fmt_row(cells, w, p, c)
                if tcp is None:
                    continue
                if have_ws:
                    if ws is not None and tcp.get("msgs_per_sec") and ws.get("msgs_per_sec"):
                        ratio = ws["msgs_per_sec"] / tcp["msgs_per_sec"]
                        L.append(f"| {w} | {p} | {c} | {tcp['msgs_per_sec']:.1f} | "
                                 f"{ws['msgs_per_sec']:.1f} | {ratio:.3f} |")
                    elif ws is not None:
                        L.append(f"| {w} | {p} | {c} | {tcp['msgs_per_sec']:.1f} | "
                                 f"{ws.get('msgs_per_sec')} | n/a |")
                else:
                    L.append(f"| {w} | {p} | {c} | {tcp['msgs_per_sec']:.1f} | "
                             f"{tcp.get('wall_s')} |")
    L.append("")

    # ---- overhead ----
    if have_ws:
        L.append("## WebSocket overhead ratio (WS / TCP)\n")
        ratios_all = {}
        for c in cells:
            if c["transport"] != "tcp":
                continue
            tcp = c
            ws = next((x for x in cells if x["transport"] == "ws"
                       and cell_key(x) == cell_key(c)), None)
            if ws and tcp.get("msgs_per_sec") and ws.get("msgs_per_sec"):
                r = ws["msgs_per_sec"] / tcp["msgs_per_sec"]
                ratios_all.setdefault(c["workload"], []).append(r)
        if ratios_all:
            L.append("| workload | geomean WS/TCP | cells |")
            L.append("|---|---:|---:|")
            for w, rs in ratios_all.items():
                L.append(f"| {w} | {geomean(rs):.3f} | {len(rs)} |")
            allr = [r for rs in ratios_all.values() for r in rs]
            L.append(f"| **overall** | **{geomean(allr):.3f}** | {len(allr)} |")
            L.append("")
            L.append("< 1.0 = WS slower; > 1.0 = WS faster.\n")
        else:
            L.append("No cells had both TCP and WS measurements.\n")
    else:
        L.append("## WebSocket overhead ratio (WS / TCP)\n")
        L.append("Not computed: no WS measurements (tier blocked).\n")

    # ---- latency ----
    L.append("## Latency (microseconds, medians)\n")
    lat = [c for c in cells if c["workload"] == "latency" and c.get("p50_us") is not None]
    if not lat:
        L.append("No latency samples.\n")
    else:
        have_ws_lat = any(c["transport"] == "ws" for c in lat)
        if have_ws_lat:
            L.append("| conc | payload | transport | p50 | p95 | p99 | p99.9 |")
            L.append("|---:|---:|---|---:|---:|---:|---:|")
        else:
            L.append("| conc | payload | transport | p50 | p95 | p99 | p99.9 |")
            L.append("|---:|---:|---|---:|---:|---:|---:|")
        for c in sorted(lat, key=lambda x: (x["concurrency"], x["payload"], x["transport"])):
            L.append(f"| {c['concurrency']} | {c['payload']} | {c['transport']} | "
                     f"{c['p50_us']} | {c['p95_us']} | {c['p99_us']} | {c['p999_us']} |")
        L.append("")

    # ---- resources ----
    L.append("## Broker resource usage\n")
    HZ = 100  # Linux CLK_TCK default
    L.append("| broker | CPU ticks (u+s) delta | CPU seconds | final RSS KiB |")
    L.append("|---|---:|---:|---:|")
    for name, r in resources.items():
        raw = r.get("raw") if isinstance(r, dict) else None
        if not raw:
            continue
        try:
            # raw = "<u0> <s0> <u1> <s1> <rss0_kb> <rss1_kb>"
            u0, s0, u1, s1, _rss0, rss1 = [int(x) for x in str(raw).split()]
            delta = (u1 - u0) + (s1 - s0)
            L.append(f"| {name} | {delta} | {delta / HZ:.2f} | {rss1} |")
        except Exception:
            continue
    L.append("")
    L.append("CPU ticks are `utime+stime` from `/proc/<pid>/stat`; RSS from "
             "`/proc/<pid>/status` `VmRSS`. CPU covers the whole matrix, not a "
             "single cell.\n")

    # ---- caveats ----
    L.append("## Caveats\n")
    if ws_blocked:
        L.append("- **WebSocket cells are absent, not zero.** The WSS tier "
                 "could not serve the probe in this build, so no WS number "
                 "exists to compare. This is a broker/transport limitation, "
                 "not a measured overhead.\n")
        L.append("- The WS carrier's server read (`WSSConnection.recv_bytes`) "
                 "returns only when it has a full `frame_max+8` quota or sees a "
                 "peer CLOSE/EOF. A normal request/response AMQP client "
                 "therefore deadlocks; the bundled `tests/phase9/wss_test.mojo` "
                 "avoids this only by pinning `frame_max` small and pre-writing "
                 "batches.\n")
    L.append("- `publish` uses a bindingless exchange, so it measures producer "
             "+ carrier cost with nothing stored.\n")
    L.append("- `pubget`, `confirm` and `latency` include broker queue "
             "operations and are not pure transport cost; they are still "
             "identical across transports.\n")
    L.append("- `HYRXMQ_FRAME_MAX` is set equal for both tiers so large bodies "
             "chunk identically.\n")
    L.append("- Single machine, loopback, no TLS: absolute values are "
             "indicative, ratios are the point.\n")

    with open(out, "w") as f:
        f.write("\n".join(L) + "\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
