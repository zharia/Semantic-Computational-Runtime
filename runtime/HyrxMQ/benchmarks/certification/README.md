# HyrxMQ performance certification (M9)

Thresholded performance certification and extended soak testing for the
HyrxMQ broker (`build/hyrxmq-listen`). This directory is **not** part of the
correctness suite: it is a long-running empirical measurement that produces a
machine-readable report and a pass/fail verdict.

Files:

| File | Role |
|------|------|
| `certify.py` | performance certification driver (throughput, latency, memory, TLS overhead) |
| `soak.py` | extended soak driver (RSS/fd sampling, leak detection, latency drift) |
| `thresholds.json` | regression thresholds both drivers gate on |
| `run_certification.sh` | build → start broker → certify → soak → stop broker, with `trap` cleanup |
| `results/` | generated JSON reports + broker logs (not source of truth) |

## Quick start

```bash
bash benchmarks/certification/run_certification.sh --quick   # smoke (~30s)
bash benchmarks/certification/run_certification.sh           # full
SOAK_DURATION=3600 bash benchmarks/certification/run_certification.sh  # 1-hour soak
```

Standalone (already-running broker, no `run_certification.sh`):

```bash
python3 benchmarks/certification/certify.py --port 5673 --broker-pid "$(pgrep -f hyrxmq-listen)"
python3 benchmarks/certification/soak.py --duration 3600 --rate 200 --port 5673 --broker-pid "$PID"
```

## What is measured, how

All scenarios drive the **same single broker connection at a time**, closed
loop, so the measured rate is meaningful and the queue never exceeds its
1024-entry capacity (publishes past capacity are dropped **silently** by the
broker; the harness batches at ≤1024 and raises on under-delivery rather than
reporting a hollow rate).

| Metric | Method |
|--------|--------|
| throughput (msgs/s) | closed-loop publish → `basic_get(auto_ack)` cycle, 5 % warm-up, median of the timed window |
| latency p50/p95/p99/p99.9 | publish → get round trip, one message in flight |
| memory per message (bytes) | (peak − baseline broker `VmRSS`) ÷ queued messages, sampled from `/proc/<pid>/status` |
| TLS overhead (%) | 1 KB plaintext throughput vs 1 KB TLS throughput on the same binary |
| soak RSS growth | per-half medians of sampled `VmRSS`, plus monotonicity |
| soak fd growth | sampled `/proc/<pid>/fd` count, second half vs first half |
| soak latency drift | second-half p99 vs first-half p99 |

Scenarios: **1 KB**, **64 KB**, **1 MB**, each plaintext and (when configured)
TLS. TLS uses a self-signed cert generated with `openssl` into a temp dir, or an
explicit `--tls-cert` / `--tls-key`. If `openssl` is absent and no cert is
given, the TLS scenario is SKIPped, never faked.

Broker build knobs honoured: `HYRXMQ_HOST`, `HYRXMQ_PORT`,
`HYRXMQ_TLS_ENABLED`, `HYRXMQ_TLS_CERT`, `HYRXMQ_TLS_KEY` (see
`src/hyrxmq/main_listen.mojo`). Credentials default to `admin` / `password`
(`HYRX_USER` / `HYRX_PASS`).

Client: `pika` if importable, otherwise a raw-socket fallback that measures the
transport floor (TCP connect + AMQP protocol-header handshake latency and
connection churn). In raw mode message-level metrics are reported `null` and
their checks are `SKIP`, never invented.

## Thresholds

`thresholds.json` is the single gate definition:

```json
"min_throughput_1kb": 5000,
"min_throughput_64kb": 1000,
"min_throughput_1mb": 100,
"max_p99_latency_ms_1kb": 50,
"max_p99_latency_ms_64kb": 100,
"max_p99_latency_ms_1mb": 250,
"max_p999_latency_ms_1kb": 200,
"max_memory_per_msg_bytes": 4096,
"max_tls_overhead_pct": 60,
"min_tls_throughput_ratio": 0.5,
"soak_max_rss_growth_pct": 10,
"soak_max_fd_growth": 16,
"soak_max_p99_degradation_pct": 25
```

`certify.py` exits non-zero if any thresholded metric FAILs; an unmeasurable
metric is `SKIP` (reported, not counted as pass or fail). `soak.py` exits
non-zero on RSS growth, fd growth, p99 drift, or a broker that died mid-soak.

## Hardware assumptions

Thresholds are a **floor for a quiet, modern x86-64 development host**
(comparable to the benchmark baseline: AMD Ryzen-class CPU, ≥4 cores, local
loopback, CPU governor not thermally throttled, no competing load). They are
**not** cross-machine comparable: absolute throughput/latency depends on CPU,
kernel, governor and load. Re-measure the thresholds on the target class of
hardware before treating a failure as a regression. Record the host signature
the drivers embed in every report (`cpu_model`, `nproc`, `kernel`, `python`,
`pika_version`, `hyrxmq_git_head`, `governor`).

Memory is sampled from `/proc`, so it is Linux-only (as is the broker's fd
accounting). The soak drivers require a live `/proc`; on non-Linux the sampling
is skipped and the corresponding checks are SKIP.

## How to reproduce

1. Build the broker:
   `pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen`
2. Ensure `pika` (optional; the scripts create `/tmp/hyrxmq-cert-venv` if not):
   `python3 -m venv /tmp/hyrxmq-cert-venv && /tmp/hyrxmq-cert-venv/bin/pip install 'pika==1.4.4'`
3. Run: `bash benchmarks/certification/run_certification.sh`
4. Inspect `results/certification-*.json` and `results/soak-*.json`; the
   process exit code is the verdict (0 = PASS).

The broker process is always torn down (shell `trap` on EXIT/INT/TERM; the
Python drivers stop a broker they spawned, and never stop an attached one). No
existing benchmark file is modified by these drivers.
