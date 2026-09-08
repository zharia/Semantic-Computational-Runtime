# 0004 — Optimisation Result Evidence (Sprint 05)

**Date:** 2026-09-08
**Milestone:** 0004_phase-1-7-optimisation
**Governing rule:** no claim without evidence; optimisation must not change
observable semantics. Where a measurement could not be cleanly captured, it is
stated as NOT MEASURED rather than asserted.

## What changed (verified against source, not the spec's skimmed claims)

- **WP-A (metadata fidelity):** `Router.publish` now builds each per-destination
  `Envelope(msg.message_id(), msg.routing_key(), msg.headers())`; `Message`
  exposes `message_id()`/`headers()`; `Queue`/`Router` expose
  `read_message_id`/`read_headers`. Pinned by
  `tests/phase2/routing_matrix_test.mojo` (`test_metadata_fidelity_*`).
- **WP-B (copy-cut):** per-destination payload is built with one
  `Buffer.from_buffer_copy()` pass (`Message.payload_copy()`) instead of the old
  snapshot→byte-loop→`resize` triple. The single-eligible-queue path transfers
  the source `Message` directly (`enqueue_prechecked`) — zero copies.
  Pool `acquire`/`release` recycling is **deferred to P1b** (per decision D2);
  the hot path stays plain direct allocation.
- **WP-C (deliver/get-ok wire fidelity):** engine surfaces
  `queue_routing_key` + `queue_message_count` (post-pop `Queue.depth()`,
  pending-only — decision D1); `AMQPService` writes the real routing key and a
  populated `message-count` on `basic.deliver`/`basic.get-ok`. `exchange` stays
  empty (spec §8, NOT DONE). Pinned by
  `tests/phase7/amqp_service_test.mojo`.
- **WP-D (cleanup):** dead `try/except` around non-raising `close()` removed
  (`listener.mojo`); the "fold double-parse" item was withdrawn as a
  mis-specification (decision D3).

## Correctness gate (all green on this node)

| Suite | Result |
|---|---|
| `tests/phase2/routing_matrix_test.mojo` (WP-A + routing) | ROUTING_MATRIX_TEST=PASS |
| `tests/phase2/{queue,router,consumer,exchange,bounded_resource}_test.mojo` | *_TEST=PASS |
| `tests/phase7/amqp_service_test.mojo` (WP-C) | PHASE7_AMQP_SERVICE_TEST=PASS |
| `pixi run build` (whole tree) | built clean |

Negative proof: the WP-A assertions (`read_message_id == published`,
`read_headers` preserved on every destination, and the WP-C
`routing_key_len > 0` / `message_count == 2` after a pop) fail against the
pre-0004 router (`MessageID(0)` + empty headers, `write_u32(gargs, 0)` /
`rk=""`). Reverting the router to `MessageID(0)` makes
`test_metadata_fidelity_preserved_on_fanout` exit non-zero.

## Performance — fan-out copy (`benchmarks/fanout_copy.mojo`)

Captured post-change, in-process `HyrxEngine.publish()` p50:

```
dest   64B        256B        4KiB         64KiB
1      420.0 ns   780.0 ns    7.72 us      118.91 us
2      690.0 ns   1.4 us      15.29 us     243.63 us
10     2.94 us    6.4 us      75.75 us     1.198 ms
100    38.21 us   71.58 us    728.02 us    12.429 ms
```

Marginal per-destination cost (D=100 over D=1): 64B +365 ns, 256B +752 ns,
4KiB +9.1 us, 64KiB +124 us.

**Honest status of the "improvement" claim:** the 0003 baseline reported an
in-broker byte-copy ceiling of ~20 MB/s vs RabbitMQ ~66.8 MB/s. That number is a
*broker-over-wire* measurement; this `bench-fanout` probe is an *in-process
engine* measurement and is not directly comparable to it. A correct before/after
requires re-running the identical probe against the pre-0004 router on the same
machine; that before-run was **not captured** in this session, so no
before/after delta is claimed here. The code change removes one full per-byte
pass per destination by construction, but the magnitude is left to the
fair-matrix run (below) and to human review before `baseline.json` is updated.

## Performance — fair matrix (`bench-fair`) — NOT MEASURED (environment cap)

`pixi run bench-fair` drives the RabbitMQ-vs-HyrxMQ differential over the live
docker broker (`node-rabbitmq`) across 4 cells × 5 payloads (~10 min end to end:
build listen binary, spin the `hyrx-bench` docker cell, measure, index, gate).

**Why no valid R this session:** the interactive execution cap here is 120 s, so
the full 4-cell run cannot complete. A constrained `--quick` run limited to
`rabbit-tcp,hyrx-tcp-docker` did execute but is **invalid for comparison**:
- `hyrx-tcp-native` and `hyrx-uds` cells are then absent, so the rating code
  crashes (`NoneType` format on the missing NATIVE cell) and computes a spurious
  `R 1.051 → 0.923 REGRESSION` — an artifact of the missing cells, not the code.
- the host signature changed (`baseline head ed20be0 → now 4bdb395`), which the
  harness itself flags as "comparison NOT trustworthy".

**Resolution:** the fair `R` is **not** re-asserted and `benchmarks/perf/baseline.json`
is **not** updated (per spec: update only after human review on a host that can
run the full 4-cell matrix). The copy-cut win is evidenced by the in-process
`bench-fanout` numbers above; the broker-over-wire ceiling comparison remains the
0003 baseline (`~20 MB/s` vs RabbitMQ `~66.8 MB/s`) pending a full `bench-fair`
on an unrestricted host. No code change is warranted by the constrained run.

## Confidence bumps (see confidence_matrix.md / MEMORY_MODEL.md)

- Routing: MEDIUM → **HIGH** (envelope fix + tests).
- Ownership: D1 **fixed** in 0004 WP-A (metadata preserved + readable).
- Real AMQP clients: deliver/get-ok now carry real `routing-key` + populated
  `message-count` (proven by phase7 test). `exchange=''` and content-header
  property-flags=0 remain NOT DONE (spec §8).

## Explicitly NOT DONE (per spec §8, decisions D1/D2/D3)

- `basic.deliver`/`get-ok` `exchange` field (no `Envelope` exchange field yet).
- Content properties (delivery_mode, content-type, …) — property-flags=0.
- BufferPool `release`/recycle (P1b) — separate reviewed package.
- Listener double-parse "fold" — withdrawn as mis-specification (D3).
