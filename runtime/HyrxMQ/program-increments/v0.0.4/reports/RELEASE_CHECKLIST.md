# v0.0.4 Release Checklist

**Version:** HyrxMQ v0.0.4 — Production Readiness
**Date:** 2026-09-14
**Artifact:** `build/hyrxmq-listen`

Commands are run from the project root
(`runtime/HyrxMQ`). Build/serve/test commands must run under `pixi` so the
Mojo runtime and the flare FFI libraries (`$CONDA_PREFIX/lib/libflare_tls.so`)
resolve.

---

## 1. Clean build

```bash
rm -rf build && pixi run hyrxmq-listen
```

Result: **PASS** — produces `build/hyrxmq-listen` (~1.03 MB, 1,075,816 bytes)
plus `build/shutdown_shim.o`.

> Note: the broker `dlopen`s `libflare_tls.so` at startup. Under `pixi run` the
> canonical `$CONDA_PREFIX/lib/libflare_tls.so` is found. If the binary is run
> outside the pixi env, stage the library next to it
> (`cp vendor/libflare_tls.so build/`) or the broker aborts with
> `dlopen failed: build/libflare_tls.so`.

## 2. Full test suite

```bash
pixi run test          # == bash scripts/test_all.sh
```

Result: **68 / 69 PASS** — 1 expected failure,
`tests/_selftest/assertion_negfail.mojo` (negative self-test that must fail).
Suite covers phase0–phase10 + integration + interop + selftest + fuzz.

## 3. Performance certification

```bash
pixi run bash benchmarks/certification/run_certification.sh --quick
# full:   pixi run bash benchmarks/certification/run_certification.sh
# 1-hour: SOAK_DURATION=3600 pixi run bash benchmarks/certification/run_certification.sh
```

Result: **PASS** (quick, 2026-09-14) — `certify exit=0  soak exit=0`.

| Check | Value | Threshold |
|-------|-------|-----------|
| throughput 1 KB | 7441 msg/s | ≥ 5000 |
| throughput 64 KB | 4426 msg/s | ≥ 1000 |
| throughput 1 MB | 322 msg/s | ≥ 100 |
| p99 latency 1 KB | 0.207 ms | ≤ 50 |
| p99 latency 64 KB | 0.415 ms | ≤ 100 |
| p99 latency 1 MB | 3.237 ms | ≤ 250 |
| p99.9 latency 1 KB | 0.264 ms | ≤ 200 |
| memory / msg 1 KB | 160 B | ≤ 4096 |
| TLS overhead | 11.5 % | ≤ 60 |
| TLS throughput ratio | 0.885 | ≥ 0.5 |
| soak RSS growth | 0.0 % | ≤ 10 |
| soak fd growth | 1 | ≤ 16 |
| soak p99 drift | 0.61 % | ≤ 25 |

Reports: `benchmarks/certification/results/certification-*.json`,
`soak-*.json`.

## 4. SIGKILL durability harness

```bash
pixi run bash scripts/sigkill_harness.sh
```

Result: **PASS** (2026-09-14):

```
SIGKILL_HARNESS=PASS recovery: 10:10 50:50 90:90
```

Broker killed with `kill -9` mid-publish at 10 / 50 / 90 of 100 durable
messages; every kill point recovered all published messages on restart.

> Must run under `pixi run` (same `libflare_tls.so` reason as §1). Requires a
> `pika` client; the harness creates `/tmp/hyrxmq-pika-venv` if absent.

## 5. Disk-failure harness

```bash
pixi run bash scripts/disk_failure_harness.sh
```

Harness present; complements in-process `tests/phase10/disk_failure_test.mojo`
(append/sync failure bounded, broker survives journal failure). Not re-executed
for this receipt.

## Extended Soak (10 min)

```bash
# broker started manually (libflare staged at build/libflare_tls.so)
HYRXMQ_HOST=127.0.0.1 HYRXMQ_PORT=<free> ./build/hyrxmq-listen &
/tmp/hyrxmq-cert-venv/bin/python benchmarks/certification/soak.py \
  --host 127.0.0.1 --port <free> --broker-pid <PID> \
  --duration 600 --rate 100 --sample-interval 5
```

### Before fix — FAIL (2026-09-14, 12:44:05Z → 12:54:06Z)

Actual duration **600 s**. 60 000 messages at the 100 msg/s target, 0 errors,
broker alive at end.

| Metric | Value | Threshold | Verdict |
|--------|-------|-----------|---------|
| RSS growth | **+18.9 %** (13 852 → 28 184 KB) | ≤ 10 % | **FAIL** |
| fd growth | 1 (min 6, max 7) | ≤ 16 | PASS |
| p99 drift | −4.25 % (0.406 → 0.389 ms) | ≤ 25 % | PASS |
| throughput | 100 msg/s (target-limited) | — | — |
| errors | 0 | — | — |

Report: `benchmarks/certification/results/soak-20260914T125406Z.json`.

RSS was **not** strictly monotonic — it stepped and plateaued
(13 852 → 15 564 → 16 668 → 18 856 → 22 400 → 28 184 KB), with step sizes and
step spacing both roughly **doubling**. That signature is geometric container
reallocation, not allocator fragmentation (fragmentation has no doubling
structure).

### Root cause

`AMQPService._handle_get` (and the auto-ack branch of `_flush_deliveries`)
allocated a per-channel WIRE delivery-tag through `_chan_alloc_tag`, which
records a binding in `_ChanTagMap.consumer_by_tag`, `.engine_tag_by_tag` and
`.tags`. The `no-ack` (auto-ack) branch then acked the engine delivery but
never called `_chan_take`, so **every auto-acked get leaked one tag binding
for the channel's whole life**. `_ChanTagMap` is per `(conn, channel)`, so the
three containers grew by one entry per delivery and reallocated (doubling) as
they filled — exactly the observed step pattern.

Proven empirically by a differential probe (same 1 KB publish→get workload):

| Workload | 20 000 msgs | 40 000 msgs |
|----------|-------------|-------------|
| auto-ack (soak path) | +4 896 KB | +7 804 KB |
| explicit-ack (`basic.ack`) | +424 KB | — |

Manual ack resolves the tag through `_chan_take`; growth scales with message
count for auto-ack only.

### Fix

`_chan_alloc_tag_auto` (new, `src/hyrxmq/amqp_service.mojo`) issues the wire
tag and keeps `next_tag` monotonic for the channel (AMQP delivery-tag
monotonicity) but stores **no** per-tag binding. Both auto-ack call sites now
use it. Memory is bounded by the channel count, not the delivery count.

### After fix — PASS (2026-09-14, 13:21:42Z → 13:31:42Z)

| Metric | Value | Threshold | Verdict |
|--------|-------|-----------|---------|
| RSS growth | **+0.056 %** (13 908 → 14 356 KB) | ≤ 10 % | **PASS** |
| fd growth | 1 (min 6, max 7) | ≤ 16 | PASS |
| p99 drift | +5.27 % (0.977 → 1.029 ms) | ≤ 25 % | PASS |
| throughput | 100 msg/s (target-limited) | — | — |
| errors | 0 | — | — |

RSS is flat after warm-up (plateau at 14 356 KB from t ≈ 575 s to 600 s);
the residual ~450 KB is one-time warm-up, confirmed constant across a 20 000
vs 40 000 message probe (+436 KB vs +456 KB).

Report: `benchmarks/certification/results/soak-20260914T133142Z.json`.

> Note: `soak.py --out <path>` is currently a silent no-op (line 531,
> `path = args.out or write_report(report)` skips the writer). Run without
> `--out` and read the newest `results/soak-*.json`.
> The 1-hour (`--duration 3600`) soak remains pending.

---

## Known gaps

| Gap | Status |
|-----|--------|
| Go interop client (amqp091-go) | **NOT DONE** — no Go toolchain available. |
| True 1-hour soak | **NOT DONE** — quick (15 s) soak only; full run pending. |
| Segment rotation | **NOT DONE** — single-log WAL. |
| Permission / read-only-fs failure tests | **NOT DONE**. |
| `max_channels_per_connection` / `max_memory_bytes` enforcement | **NOT DONE** — config keys only. |
| `max_unacked` delivery-path enforcement | **NOT DONE** — config contract only. |
| Repeated auth-failure rate limiting | **NOT DONE** — counter only. |
| Dedicated ACL / resource-limit tests | **NOT DONE** — code-verified (R16, R18). |
| Log secret redaction | **NOT DONE**. |
| StatefulSet manifest + live-cluster K8s tests | **NOT DONE**. |
| Field-table fuzz target; 1M-iteration fuzz bar | **NOT DONE** — 25k iterations run. |
| Half-open TCP / wrong-method-in-state tests | **NOT DONE**. |
| CI regression-gate integration | **NOT DONE**. |

## Release artifact

- `build/hyrxmq-listen` — broker (listen mode), ~1.03 MB.
- Container: `Dockerfile` (`pixi run docker-build`).
- Docs: `RELEASE_NOTES.md`, `CHANGELOG.md`,
  `reports/{INVARIANT_AUDIT,DOC_TRUTH_AUDIT,SECURITY_AUDIT}.md`.