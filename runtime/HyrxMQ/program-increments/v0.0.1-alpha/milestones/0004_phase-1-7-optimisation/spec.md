# HyrxMQ — Phase 1-7 Optimisation Increment (0004)

**Status:** Draft for approval
**Milestone:** 0004_phase-1-7-optimisation
**Depends on:** 0003_phase-1-7-audit (defect registry + measured baselines)
**Date:** 2026-09-08

---

## 0. Mission

Convert the confidence audit's measured findings into concrete, evidence-gated
improvements. The single dominant cost is **payload copying in the publish
path**; the cheap correctness wins are the metadata/fidelity defects the audit
left reported-not-fixed.

> **Rule inherited from the audit (§36/§37):** a change is done only when a
> real measurement or a real (runtime-checked) test demonstrates it. No claim
> without evidence. No optimisation that changes observable semantics.

Governing principle unchanged: **correctness precedes optimisation; optimisation
requires measurement.**

---

## 1. Measured baseline (what we are improving against)

From `0003_phase-1-7-audit/reports/benchmarks.md` and
`perf_rabbitmq_vs_hyrxmq_fair.md` (Ryzen 5 3600, 12c, kernel 7.1.8, pika 1.4.4,
RabbitMQ 4.3.5, HyrxMQ frame_max 131072, queue capacity 1024):

- **Fair AMQP Rating R = 1.051** (95% CI [1.045,1.053]) HyrxMQ vs RabbitMQ.
- **In-broker byte-copy ceiling ~20 MB/s vs RabbitMQ ~66.8 MB/s**, *identical
  across native / docker / UDS* ⇒ the cost is the engine copy, not transport.
- **Throughput crossover**: HyrxMQ falls to **0.51× RabbitMQ at 4 KiB** and
  **0.28× at 16 KiB** — large-payload publish is the weak point.
- **Fan-out copy slope**: +2.38 µs per additional destination (256 B),
  consistent with a per-byte rebuild loop.
- UDS beats HyrxMQ-TCP ~15% (msgs/s geomean); docker tax ~9.2%.

The root cause is in `src/hyrx/core/router.mojo:161-186`: for **each**
destination `publish` performs, per payload byte:

1. `msg.payload()` → `Buffer.snapshot()` — copy #1 (byte loop, `buffer.mojo:72-75`)
2. `Buffer(snap.size())` + `resize()` — allocation + zero-fill (copy #2)
3. `for j: payload[j] = snap[j]` — copy #3 (byte loop, `router.mojo:179-180`)

i.e. 2–3 full passes plus allocation churn, per destination queue.

---

## 2. Scope

### IN (this increment)
- **P1a** — Publish copy-cut + single-destination move + size-classed pool
  **acquire** path (reuse the engine's existing `BufferPool`, currently stats-only).
- **P2** — Propagate `message_id` + `headers` on fan-out.
- **P3** — Real `routing_key` + `message_count` on `basic.deliver`/`basic.get-ok`.
- **P6** — Dead-`try` and double-parse cleanups.

### OUT (explicitly deferred / excluded)
- **P1b — BufferPool *release* path** (returning buffers at every message-death
  site + the pool-outlives-queues lifecycle invariant). Deferred to a **separate
  reviewed package**; see §7. This increment may **acquire** from the pool and
  free buffers via the normal `__deinit__` path; it does **not** yet recycle them.
- Async push-to-idle-subscriber (needs a threaded/evented model — deferred with
  evidence by the audit; Mojo 1.0.0 std exposes no threads/atomics here).
- Per-message `exchange` on deliver (needs an `Envelope` schema change — §8).
- AMQP field-table / content-property wire serialization (separate package).
- Persistence (Phase 10), auth/TLS (Phase 11), clustering (never, per spec §30).

---

## 3. Work packages

### WP-A (P2) — Envelope metadata fidelity
**Defect:** `router.mojo:166-169` builds each per-destination `Envelope` with
`MessageID(0)` and an empty `headers` dict, silently discarding the published
message's id/headers (audit D1-adjacent).

**Change:**
- `src/hyrx/core/message.mojo` — expose `Message.message_id()` and
  `Message.headers()` (they already exist on `Envelope` at `message.mojo:46/52`;
  `Message` only re-exports `routing_key`/`payload` today).
- `router.publish` — build the per-destination envelope as
  `Envelope(msg.message_id(), msg.routing_key(), msg.headers())`.
  `headers` is a `Dict[String,String]`; deep-copy it per destination (independent
  ownership), or document immutability.

**Acceptance:**
- New runtime-checked test (`tests/phase2/routing_matrix_test.mojo` or new): a
  message published with a non-zero `MessageID` and ≥1 header, fanned to N queues,
  is delivered on each with the **same** message_id and headers. Fails on the old
  `MessageID(0)` behaviour (negative proof required per §36).

### WP-B (P1a) — Copy-cut + single-destination move
**Goal:** one payload copy per destination (not 2–3), and **zero** copies when a
message routes to exactly one queue.

**Changes:**
1. `src/hyrx/core/buffer_snapshot.mojo` / `buffer.mojo` — add a **bulk copy**
   primitive so a `Buffer` can be filled from a `BufferSnapshot`/span in one pass
   with correct logical length (no separate `resize` zero-fill then overwrite):
   e.g. `Buffer.from_snapshot_copy(src)` or `buffer.copy_from_span(span)`.
   - MUST yield `buffer.size() == src.size()` and byte-identical contents.
   - No stale bytes: length is the payload length, never the slab capacity.
2. `router.mojo:161-186` — replace the three-step per-destination build with the
   single bulk copy. **Remove the intermediate `msg.payload()` snapshot copy** in
   favour of reading the source buffer once.
3. **Single-destination move fast-path:** when `len(queue_names) == 1` (after the
   membership filter), **transfer** the source message's owned payload+envelope to
   that queue instead of copying (`msg` is already consumed by `publish`). Guard:
   only when the destination `enqueue` will accept it; on capacity-reject, fall
   back to the copy path so `msg` isn't lost.
4. **Pool acquire path (reuse existing pool, no release yet):** route the copy
   destination through the engine's `BufferPool` (`embedded/api.mojo:82/91`,
   `buffer_pool.mojo`) via a **size-classed** allocator so 64 B and 16 KiB
   payloads draw from appropriate buckets:
   - `buffer_pool.mojo` — extend to size classes (capacity buckets) with
     `acquire(min_capacity) raises -> Buffer`; **oversize > max class → direct
     `Buffer(...)` allocation fallback** (never block, never corrupt).
   - Because P1b (release/recycle) is deferred, this step primarily standardises
     allocation; the measurable win in this increment is items 1–3. State that
     honestly (do not claim recycle benefit before P1b).

**Invariants (must hold + be tested):**
- Payload bytes identical to source at every destination (reuse must not leak
  stale bytes from a recycled slab).
- Single-dest move: the source `msg` is unusable after publish (no double-free);
  delivered payload byte-equal.
- Oversized message (> largest pool class) still publishes correctly via the
  direct-alloc fallback.
- Boundedness preserved: publish never grows unbounded (queue capacity +
  frame_max still the ceilings — audit §7).

**Acceptance (performance — MEASURED, not asserted):**
- Re-run `benchmarks/fanout_copy.mojo` + the fair matrix (`pixi run bench-fair`).
- **Required evidence:** byte-copy ceiling materially above ~20 MB/s; the 4 KiB /
  16 KiB crossover toward Rabbit narrows; fan-out slope reduced. Report before/after
  tables in `0004 .../reports/perf_optimisation_results.md`. Only update
  `benchmarks/perf/baseline.json` via `--update-baseline` after human review.
- If the measured improvement is not material, keep the (correct) code but say so
  in the report — do not overclaim (spec §36).

### WP-C (P3) — Delivery/get-ok wire fidelity
**Defect:** `amqp_service.mojo:939-941` and `:979-980` send `exchange=''`,
`routing-key=''` (Delivery carries none) and `message-count=0`.

**Change:**
- Use the **existing** `Queue.read_routing_key(tag)` (`queue.mojo:123`) surfaced
  through `broker` → `AMQPService`, so `basic.deliver`/`get-ok` carry the real
  routing key (pika currently sees `rk=''` — confirmed in the fair-report log).
- Add `Queue.depth() -> UInt64` (pending + unacked, matching the engine's count)
  and emit it as `basic.get-ok message-count`.
- `exchange` stays empty this increment (no envelope field for it) — document as a
  known limitation (§8), NOT silently.

**Acceptance:** pika `basic_get`/`basic_consume` against our broker reports the
**published routing-key** and a non-negative message-count matching queue state;
Mojo-level assertions on the encoded deliver/get-ok args. Update the interop
report's NOT-PROVEN list accordingly (rk now proven; exchange still gap).

### WP-D (P6) — Cleanup
- `listener.mojo:224,236` — remove the two `try/except` blocks whose bodies cannot
  raise (`close()` is non-raising), silencing the compile warnings.
- `frame_codec`/`listener._serve_step` — eliminate the double `try_parse_frame()`
  call in the read loop (parse once, act on the result).
- No behaviour change; `test_all.sh` must stay green.

---

## 4. Test & validity requirements (audit §3 discipline)

- Every new assertion uses `from hyrx.testing import check` (raise-based). Mojo 1.0
  `assert` is **inert** at runtime — banned in tests.
- **Negative proof per behavioural change:** break the expectation, confirm the
  test exits non-zero, restore. Cite in the report.
- New/updated tests: envelope metadata (WP-A), no-stale-bytes reuse + single-dest
  move fidelity + oversize fallback (WP-B), deliver/get-ok routing-key+count
  (WP-C).
- `bash scripts/test_all.sh` green after **each** WP (commit per WP, §36 style).
- No new dependency (spec §38). No `from flare` outside `src/hyrx/transport/*`.

---

## 5. Architectural invariants that MUST NOT break

- **Single routing authority:** only `HyrxEngine`'s `Router` routes; the AMQP
  layer stays translation-only. No `Router()` construction added (grep-verified).
- **Core independence:** `src/hyrx/core/**` imports no AMQP/socket/flare/broker.
- **Ownership honesty:** buffer lifetime semantics in `MEMORY_MODEL.md` updated to
  match reality; no "view"/"zero-copy" wording that contradicts a copy (§27).
- **Boundedness:** publish/queue/pool ceilings documented and unchanged.

---

## 6. Definition of done (this increment)

1. WP-A/B/C/D implemented, each with runtime-checked tests + negative proofs.
2. `test_all.sh` fully green (was 38/0).
3. Re-benchmarked: `perf_optimisation_results.md` with before/after byte-ceiling,
   crossover, and fan-out slope; fair `R` re-measured and reported honestly.
4. `MEMORY_MODEL.md` / interop report / confidence matrix rows bumped **only** to
   what the new evidence supports (e.g. Routing HIGH with the envelope fix + tests;
   deliver `rk`/`count` proven; `exchange` and P1b recycle explicitly NOT DONE).
5. Commit series: `routing:`, `core:`, `amqp:`, `perf:` logical slices (spec §36).

---

## 7. Deferred — P1b (BufferPool recycle) — separate reviewed package

Full buffer **reuse** needs a correct release path at every message-death site:
`ack`, drop-on-full, reject-to-nothing, `delete_queue` drain, shutdown drain — plus
a proven **pool-outlives-queues** lifecycle invariant (no `Buffer` may outlive the
pool that must reclaim it; avoid a `Buffer`→pool back-reference aliasing trap).
That ownership surface is exactly what the audit rated higher-risk; it is
deliberately isolated so the safe copy-cut win banks first. P1a's size-classed
`acquire` is the first step; P1b adds the symmetric `release` + invariant +
exhaustion/balance tests.

---

## 8. Known limitations preserved / surfaced (not hidden)

- `basic.deliver`/`get-ok` `exchange` remains empty (no `Envelope` exchange field;
  requires a schema change + fan-out capture → separate package).
- Content properties (delivery_mode, content-type, etc.) still property-flags=0
  on the wire (field-table serialization is out of scope here).
- Buffer recycle (vs the copy-cut alone) not delivered until P1b.

Each is stated in the report and the confidence matrix as NOT DONE / NOT PROVEN,
never silently omitted.
