# 0014 — multi-connection serving (serialized today)

**Status:** complete — P1 measured; P2 gate PASSED -> event-driven serving = 0015
**Mode:** coordinator; P1 measure (coordinator), P2 spec+impl gated on P1

## Why

Broker serves strictly ONE connection at a time (`listener.mojo
serve_forever`: accept_and_serve_one blocks to completion). Slot machinery
(`_conns`/SERVE codes/`_active`/refused) was built for many, but only one
slot is ever driven. Real deployments = several clients/pipelines per node;
serialized serving adds queueing delays at accept and per-frame head-of-line.

## Stages

- **P1 — DONE**: two prebuilt native benches ( sacks of 100k cycles, 0.05s
  stagger) vs one broker @64B: A 53,331 / B 53,132 msg/s individually,
  B mtime - A mtime = +2.0 s ~= A's own window (1.88 s) -> B serialized
  behind A (head-of-line stall invisible to B's own rate clock);
  aggregate ~= 1.0x single-conn ceiling (expected ~2x if concurrent).
  VITAL correction recorded: first two-conn runs that appeared concurrent
  were an artifact of the bench's timed window hiding the warmup stall;
  file-mtime wall evidence settles it. Connect lesson recorded: prebuilt
  bench binary + timeout wrappers after the 40 s per-run compile hangs
  (user-visible).
- **P2 — GO (gate passed)**: aggregate loss >> 15% + conn-2 latency
  = full first-conn serving time. Implemented as 0015.
- **P2 (gated)**: event-driven serving spec (epoll/io_uring based slot pump;
  fairness = rotating slots; failure semantics via existing SERVE contract;
  partial-frame handling unchanged; heartbeats unchanged) → increment
  0015 if P1 passes the gate.
- **P3**: verify/gates/docs.

## Gates

- No production change in P1 (two bench processes use the stock broker).
- P2 GO only on P1 numbers; spec written before implementation (failure
  semantics are the risk area per transport contract).

## Explicitly NOT claimed

- No claims about wring improvements to single-conn numbers.
