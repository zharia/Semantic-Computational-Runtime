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