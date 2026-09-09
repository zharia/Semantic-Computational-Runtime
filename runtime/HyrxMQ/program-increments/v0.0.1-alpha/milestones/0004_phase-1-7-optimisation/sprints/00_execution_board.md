# Increment 0004 — Execution Board

Status: **resolved — Sprints 01–05 complete** (WP-A/B/C/D implemented, full suite
38/0 green, docs + commits landed) as of 2026-09-08. Architectural decisions D1–D3
(decisions.md) unblocked Sprints 02–04.

## Meaning and proof obligations

This is an implementation optimisation increment. It must preserve routing,
payload ownership, queue boundedness, and AMQP wire meaning. Every behavioural
claim requires a `hyrx.testing.check` runtime test; every performance claim
requires a real benchmark result. No dependency additions are permitted.

## Sprint sequence

| Sprint | Scope | Status |
|---|---|---|
| [01](01_metadata_fidelity.md) | WP-A: preserve message ID and headers on fan-out | **Done** — metadata preserved + read-back API; pinned by `test_metadata_fidelity_*` |
| [02](02_copy_cut_pool.md) | WP-B: one-copy fan-out, move path, size-classed pool acquire | **Done (B1)** — single bulk copy + single-dest move; pool acquire/release deferred to P1b (decision D2) |
| [03](03_delivery_wire_fidelity.md) | WP-C: routing key and get-ok count | **Done** — routing key + post-pop count surfaced on deliver/get-ok (decision D1); `exchange` stays empty (§8) |
| [04](04_cleanup.md) | WP-D: dead try cleanup and parser-loop cleanup | **Complete** — dead `try/except` removed; parser-loop item withdrawn per decision D3 |
| [05](05_evidence_release.md) | Tests, negative proofs, benchmarks, documentation and commits | **Done** — suite 38/0 green, docs bumped, commits landed; full `bench-fair` blocked by interactive 120s cap (noted in report) |

## Major progress and feedback

- Read the increment specification and audited the live core, embedded, broker,
  adapter, AMQP service, listener, tests, benchmark, and ownership document.
- Confirmed the core currently copies the payload twice per fan-out destination
  and drops `message_id`/headers. This matches the stated baseline.
- Confirmed tests use `hyrx.testing.check`, as required.
- Completed the two non-raising listener `close()` cleanup edits. No performance
  claim is made for that cleanup. It compiles through the listener-hostile test,
  whose socket execution is blocked by this environment; the phase-7 AMQP
  service regression passes.

## Required decisions

1. **Queue count contract:** may `Queue.depth()` change from its established
   pending-only `Int` meaning to pending-plus-unacked `UInt64`, or must a new
   `total_count()`/`message_count()` API carry the AMQP get-ok meaning?
2. **Pool contract before P1b:** how is the engine-owned pool injected into the
   router, and when a normal size-class bucket is exhausted (there is no release
   path), must publish direct-allocate, reject, or fail? The spec defines only
   oversize fallback; each answer changes observable resource behavior.
3. **Listener parsing contract:** `_serve_step` parses once before reading to
   consume an already-buffered frame and once after reading newly received data.
   What single-parse restructuring is intended while retaining both cases and
   the current partial-frame behavior?


## P1b (previously deferred) — implemented + measured (2026-09-08)
Implemented by scr-architect (k3 retired). Pool wired into Router, leak-correct across
all death sites + D8 orphans requeued. Commits 575fc70..fd92345, suite 39/0, every
phase negative-proofed. Measured (benchmarks/pool_ab.mojo): NO throughput win
(0.79-1.00x) -> kept `buffer_pool_enabled=false`. See p1b_design.md §9. Increment 0004
is now COMPLETE (WP-A/B/C/D + evidence + P1b implemented-and-evaluated).

## Containerization + canonical benchmark (2026-09-09)
- HyrxMQ containerized (self-contained `FROM scratch` image, `Dockerfile` +
  `packaging/build_image.sh`, commit b921882); validated serving AMQP end-to-end.
- Deploy to 192.168.100.112 BLOCKED by target CPU (2009 i7-920, pre-x86-64-v3);
  Mojo runtime libs require v3 -> cannot execute there. Not a code defect.
- Canonical fair matrix re-run vs a FRESH same-host reference RabbitMQ (node-rabbitmq
  untouched): **R=1.063 (CI 1.054-1.073)** — honest decomposition: ~1.3-1.5x faster
  small payloads, ~2-3x slower at >=4KB (large-payload copy remains the top gap).
  See reports/performance_canonical.md.
