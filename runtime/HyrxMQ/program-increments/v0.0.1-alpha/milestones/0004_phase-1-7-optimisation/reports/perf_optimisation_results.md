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

## Performance — fair matrix (`bench-fair`)

`pixi run bench-fair` drives the RabbitMQ-vs-HyrxMQ differential over the live
docker broker (`node-rabbitmq`) across 4 cells × 5 payloads.

**Environment constraint:** the interactive execution cap here is 120 s, so the
full 4-cell run (build + `hyrx-bench` docker cell + measure + index + gate,
~10 min) cannot complete in one call. The 2 cells that run within the cap are the
**transport-symmetric fair pair** the harness itself headlines: `rabbit-tcp` vs
`hyrx-tcp-docker` over the *same* docker port-published path. `hyrx-tcp-native`
and `hyrx-uds` were NOT run (would exceed the cap). `baseline.json` is **not**
updated (spec: human review required); the 4-cell `R≈1.051` from 0003 remains
the recorded baseline.

**Defect found + fixed:** the reporting tool `benchmarks/perf/index.py` crashed
(`NoneType` format) whenever a cell was absent (e.g. the NATIVE reference missing),
so a partial run produced no report. Fixed to print `--` for absent overhead and
still compute the fair-pair `R`. Committed as a benchmark-tooling fix.

**Measured (2-cell fair pair, quick reps — `R` valid, throughput valid):**

```
fair pair: rabbit-tcp vs hyrx-tcp-docker   R = 1.019   (HyrxMQ ~1.02x RabbitMQ)
               64B      4096B      16384B     (median msgs/s)
  rabbit-tcp   4232      4312        4033
  hyrx-tcp-docker  6470      2284        1262
```

Interpretation: on the symmetric docker-TCP path HyrxMQ is **faster at small
payloads** (6470 vs 4232/s at 64B) but **slower at large** (1262 vs 4033/s at
16KiB) — exactly the large-payload crossover weakness the 0003 baseline reported
(0.51× @4KiB, 0.28× @16KiB). The 0004 copy-cut (single bulk copy + single-dest
move) did not change the crossover shape; it removes a per-byte pass, which helps
small/moderate payloads and the in-process `bench-fanout` slope, consistent with
the `R≈1.02` near-parity here. A full 4-cell run (native + uds) on an
unrestricted host is needed to re-assert the headline `R` and update `baseline.json`.

`GATE FAIL` on the run is `compare.py` comparing this 2-cell `R` against the
4-cell baseline — an invalid cell-set comparison, not a real regression.

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
