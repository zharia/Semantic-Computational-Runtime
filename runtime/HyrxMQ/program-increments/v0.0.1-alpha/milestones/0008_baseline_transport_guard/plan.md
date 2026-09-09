# 0008 — baseline refresh, transport guard, residue closure

**Status:** complete — T1..T4 done; suite 41/0 (40 + new transport guard); fresh gate R=1.364 CI 1.351-1.374, all cells >= rabbit parity.
**Mode:** coordinator (`scr-architect`); T1/T2 delegated (cavecrew-builder), T3 docs delegated (general)

## Why

The 0007 investigation exposed three systemic gaps; user directed "all issues
addressed and resolved":

1. `benchmarks/perf/baseline.json` held pre-0005 numbers (e.g. 16 KB hyrx
   native 1208/s vs ~6013/s actual) — every regression gate compares against
   stale data.
2. No test guards the transport `recv_bytes` byte path — the defect class
   0007 fixed (per-element loops feeding a live byte path) was invisible to
   the suite; phase8's guard covers codec/copy sites only.
3. 0007's 128 KB verdict (1.21x) was single-run/single-host; make it
   reproducible before calling size-parity closed.
4. Residue: `recv_exact` (tcp/uds) has zero callers and is outside the
   `AMQPConn` trait — dead code. Plan-time assumption that its element loop
   could matter was rebutted: dead code cannot affect the measured path.

## Tasks

- **T1 — DONE**: `tests/phase8/transport_byte_path_test.mojo` — socketpair
  fixture over a real `TCPConnection` (flare loopback), drives the full frame
  path through `recv_bytes` at sizes 0/1/2/3/7/8/127/128/255/4096/16384/
  65536/131072, single-octet + 3-octet chunked feeds, byte-compares every
  round-trip; negative-proofs a `got`-shrink mutation. Builds on the phase8
  byte_path idioms; test_all auto-discovers it (find over tests/phase8).
- **T2 — DONE (premise rebutted)**: plan assumed `recv_exact` was dead code;
  verification found 17 callers across 7 test files
  (phase4/uds_test, phase5/tcp_test, 5 integration tests) — NOT dead.
  Retained unchanged; not on any measured hot path. Deletion would be
  speculative churn justified by nothing.
- **T3 — DONE** (coordinator, not delegated — measurement): full canonical
  sweep (env rabbit 127.0.0.1:5673) over payloads 64..131072, cells
  rabbit-tcp / hyrx-tcp-native / hyrx-uds; refresh `baseline.json` via
  compare.py --update-baseline (explicit human step per compare.py header);
  record the 128 KB gate verdict (5-rep medians) + hardening note.
- **T4 — DONE** (general): 0008 docs — spec.md + reports/performance_canonical.md
  (sweep + gate table + guard-test/negative-proof record), MEMORY_MODEL line,
  cross-ref from 0007.

## Explicitly NOT claimed

- No perf number may be recorded from the guard-test session (server load,
  different context); benchmark numbers come only from the T3 sweep.
- Baseline is single-host data by definition (same as its predecessor);
  compare.py host-signature guard covers accidental cross-host use.
