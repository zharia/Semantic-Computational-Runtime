# 0013 — hostnet gate wiring + native client UDS

**Status:** in progress
**Mode:** coordinator; T1/T2 delegated, verify = coordinator

## Why

0011 left the new evidence unweighted in the official gate and the abstract
UDS ceiling unmeasured:

1. `benchmarks/perf/compare.py` HYRX_CELLS + `index.py` CELL_ORDER do not
   know `hyrx-tcp-hostnet` — the cleanest cell (no userspace proxy hop) is
   currently invisible to the perf gate.
2. `benchmarks/native_cycle_bench.mojo` is TCP-only (TCPConnection). The 0011
   limitation block names UDS A/B as the deferred half; pika cannot speak
   abstract addrs, so the native client is the only instrument.

## Tasks

- **T1** (cavecrew-builder): gate wiring — `index.py` CELL_ORDER gains
  `hyrx-tcp-hostnet`; `compare.py` rating composition updated accordingly
  (rabbit-tcp still the sole reference; fair-pair logic per file's own
  documented shape). No baseline value changes in this edit; the re-anchor
  happens through the standard sweep + --update-baseline.
- **T2** (cavecrew-builder): native client UDS — `--uds <socketaddr>` flag
  (mutually exclusive with port usage): connects via `UDSConnection`
  (hyrx.transport.uds, pattern = tests/integration/* uds clienti), same
  handshake/publish/get cycle, byte-compare unchanged. `@name` values pass
  straight through to the UDS transport (abstract supported since 0011).
- **T3** (coordinator): verify — build, suite, hostnet smoke via harness,
  native UDS bench vs TCP ceilings (path + abstract @name), full 5-cell
  sweep + gate PASS + baseline refresh, docs, commits.

## Gates

- suite 44/0 untouched tier; gate edit must leave older baselines comparable
  (five-cell gate with the same rabbit reference).
- No production-code change (compare/index/bench-tooling only).

## Explicitly NOT claimed

- No new perf claims until T3 numbers recorded.
