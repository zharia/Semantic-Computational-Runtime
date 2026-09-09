# 0009 — native measurement client + broker profile pass

**Status:** complete — T1..T3 done; suite 41/0; native ceiling + strict-Rabbit interop proven; 0010 target list evidence-ranked.
**Mode:** coordinator; T1 delegated (cavecrew-builder), T2 coordinator-run (perf), T3 delegated (general)

## Why

All gate numbers to date (0004..0008) are measured through the **pika client**,
which burns ~450 µs CPU/msg at 128 KB — the harness cycles are client-bound,
so broker headroom is invisible and copy-elimination work (0010 candidates:
direct-into-codec ingest, zero-copy outbound) cannot be sized honestly.
Separately, post-0007 the broker still spends ~230 µs/msg user-CPU at 128 KB
whose location is unattributed (copies were proven minor in 0007).

## Tasks

- **T1 — DONE** (cavecrew-builder): `benchmarks/native_cycle_bench.mojo` — closed-loop
  publish→basic_get cycle bench client, composed **only** from patterns proven
  in `tests/integration/broker_tcp_e2e.mojo` (TCPConnection.connect, handshake
  arg builders, frame parse via AMQPFrameCodec, publish wire incl. content
  header). Sizes 64..131072, timed, prints `NATIVE_BENCH size=.. msgs=..
  rate=.. us_per_msg=..`. Zero production-code change.
- **T2 — DONE** (coordinator): `perf record` + report on `build/hyrxmq-listen`
  (current HEAD) during 128 KB load — remaining-time attribution table →
  ordered implication list for 0010.
- **T3 — DONE** (general): milestone docs after T1+T2 numbers exist.

## Gates / no-regression rules

- AMQP compatibility: T1 adds no broker code; the pika fair pair is untouched
  and re-run once as the interop cross-check (rabbit cell + suite 41/0).
- Native-client numbers are recorded as **ceiling evidence**, not as a
  replacement for the rabbit gate (different client = different absolute
  numbers; the gate stays the pika matrix).

## Explicitly NOT claimed

- No multi-connection scaling claims (broker serves one connection at a time —
  unchanged).
- No perf-improvement claims in this increment (measurement only).
