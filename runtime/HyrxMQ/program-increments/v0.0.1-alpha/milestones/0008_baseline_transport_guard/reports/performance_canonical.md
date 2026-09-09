# 0008 — Baseline Refresh & Transport Guard Performance Report

**Date:** 2026-09-09 (canonical sweep run: 2026-09-09 17:33 UTC)
**Milestone:** 0008_baseline_transport_guard
**Depends on:** 0007_transport_byte_path

---

## Summary

0008 makes the performance gate reproducible and the transport byte path
regression-visible: `baseline.json` refreshed from a canonical 5-rep sweep of
the 0007-state tree; new guard test `tests/phase8/transport_byte_path_test.mojo`
locks the `recv_bytes` byte path; `recv_exact` residue closed as "retained —
premise rebutted". **No production code change.**

### Environment

- **Sweep run:** 2026-09-09 17:33 UTC
- **Host:** single host (single-host caveat stands; compare.py host-signature
  guard covers cross-host misuse)
- **Reference broker:** RabbitMQ 4.3.5 (docker), `RABBIT_PORT=5673` bench rabbit
- **Client:** pika 1.4.4, `frame_max` 131072
- **Protocol:** 5 reps per cell, medians; all four cells status OK
- **Cells:** rabbit-tcp / hyrx-tcp-native / hyrx-tcp-docker / hyrx-uds

---

## Table 1 — throughput (median msgs/s)

| size | rabbit-tcp | hyrx-tcp-native | hyrx-tcp-docker | hyrx-uds |
|---:|---:|---:|---:|---:|
| 64 | 4,243 | 7,488 | 5,986 | 8,455 |
| 256 | 4,214 | 7,344 | 5,960 | 8,558 |
| 1,024 | 4,146 | 7,098 | 5,821 | 8,205 |
| 4,096 | 3,960 | 6,696 | 5,465 | 8,122 |
| 16,384 | 3,990 | 6,334 | 4,866 | 6,960 |
| 65,536 | 2,915 | 4,133 | 3,283 | 4,521 |
| 131,072 | 1,756 | 2,567 | 2,299 | 2,656 |

## Table 2 — ratio vs rabbit (per cell)

| size | hyrx-tcp-native | hyrx-tcp-docker | hyrx-uds |
|---:|---:|---:|---:|
| 64 | 1.76x | 1.41x | 1.99x |
| 256 | 1.74x | 1.41x | 2.03x |
| 1,024 | 1.71x | 1.40x | 1.98x |
| 4,096 | 1.69x | 1.38x | 2.05x |
| 16,384 | 1.59x | 1.22x | 1.74x |
| 65,536 | 1.42x | 1.13x | 1.55x |
| 131,072 | 1.46x | 1.31x | 1.51x |

Every Hyrx cell/size above parity on this run — minimum 1.13x (docker @ 65K).

## Gate line

```
PERFORMANCE RATING R 1.364 -> 1.364 (threshold ±0.10) PASS   95% CI 1.3511-1.3742
```

Baseline refreshed to this sweep; gate unchanged vs the 0007-state reference,
as expected for a no-production-change increment.

## 128 KB gate verdict

> **128 KB Hyrx/Rabbit >= ~1.0 — PASS (native 1.46x, docker 1.31x, uds 1.51x,
> 5 independently timed reps per cell)**

Hardening notes:

- Run-to-run variance exists **in rabbit itself**: 128 KB rabbit measured
  1,756–1,965 across the two canonical runs (0007's run vs this sweep). All
  Hyrx ratios above are computed against this run's rabbit column.
- The single-host caveat stands (same as the baseline it replaces).
  compare.py's host-signature guard blocks accidental cross-host gate use.
- Rabbit-tcp at 131,072 B: 1,756 msg/s — consistent with the 0007 run's 1,965
  within observed variance.

---

## Guard-test record

`tests/phase8/transport_byte_path_test.mojo` — suite now **41/0**
(40 + new transport guard), auto-discovered by test_all.

- **Coverage:** socketpair fixture over a real `TCPConnection` (flare
  loopback); full frame path driven through live `recv_bytes`; sizes
  **0 / 1 / 2 / 3 / 7 / 8 / 127 / 128 / 255 / 4096 / 16384 / 65536 / 131072**
  byte-exact on every round-trip.
- **Partial feeds:** 1-octet and 3-octet chunked feeds at 65 KB and 128 KB
  assert the 0007 shrink branch executes (`partial_reads > 0`).
- **Contracts:** EOF and `max_bytes <= 0` return empty — pinned.
- **NEGATIVE PROOF (executed, not argued):** skipping the
  `buf.resize(unsafe_uninit_length=got)` shrink on partial reads makes the
  test fail (CHECK FAILED ×2); shrink restored → PASS. The 0007 defect class
  is now regression-visible.

---

## Residue record: `recv_exact` NOT retired

Plan-time premise ("dead code, element loop could matter") **rebutted**:

- **17 callers in 7 test files:** phase4/uds_test, phase5/tcp_test,
  listener_hostile, amqp_over_tcp, broker_tcp_e2e, socket_behavior,
  broker_uds_e2e
- **Zero callers in `src/`**; function sits outside the `AMQPConn` trait
- **Verdict:** retained unchanged. Not on any measured hot path; deletion
  would be speculative churn justified by nothing.

---

## Files changed (0008)

| File | Change |
|---|---|
| `tests/phase8/transport_byte_path_test.mojo` | NEW transport byte-path guard (13 sizes, partial feeds, negative proof) |
| `benchmarks/perf/baseline.json` | refreshed to the 0007-state canonical sweep (R 1.364) |
| production code | **none** |
