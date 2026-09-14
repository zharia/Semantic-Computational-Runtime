# M9: Performance & Soak Certification

**Gate:** Part of Gate G
**Status:** PARTIAL — thresholded certification and leak/drift soak drivers
pass; the true 1-hour soak and CI gate integration remain.
**Spec:** Sections 47-49

## Sprint 9.1 — Performance Certification
**Dir:** `benchmarks/certification/` (`certify.py`, `thresholds.json`)
- [x] Full benchmark suite execution
- [x] Throughput + p50/p95/p99/p99.9 latency
- [x] Memory per message (`VmRSS` sampling)
- [x] TLS overhead measurement
- Verified 2026-09-14 (`--quick`): cert PASS — 7441 / 4426 / 322 msg/s
  (1 KB / 64 KB / 1 MB), p99 0.21 / 0.42 / 3.24 ms, p99.9 1 KB 0.26 ms,
  160 bytes/msg, TLS overhead 11.5 %, TLS ratio 0.885.

## Sprint 9.2 — Soak Testing
**Dir:** `benchmarks/certification/soak.py`
- [ ] 1-hour continuous operation — **NOT DONE**: full run not executed; quick
  soak (15 s) only.
- [x] Memory leak detection (RSS growth check: 0.0 %)
- [x] Descriptor leak detection (fd growth: 1)
- [x] Latency degradation monitoring (p99 drift: 0.61 %)

## Sprint 9.3 — Regression Gate
- [x] Benchmark threshold establishment (`thresholds.json`)
- [ ] CI gate integration — **NOT DONE**: drivers exist; no pipeline wiring.

## Exit Criteria
- [x] Performance baseline established (quiet dev host)
- [ ] 1-hour soak
- [ ] CI regression gate