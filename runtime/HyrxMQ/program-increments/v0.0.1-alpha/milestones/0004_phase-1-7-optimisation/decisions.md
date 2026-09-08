# 0004 — Architectural Decision Record (unblocks the execution board)

**Resolves:** `sprints/00_execution_board.md` → "Required decisions 1–3"
**Status:** decisions made → board may resume at Sprint 01
**Date:** 2026-09-08
**Governing rule:** implementation convenience must never silently redefine
computational semantics (project invariant). Every resolution below is chosen so
**observable publish/deliver behaviour and queue boundedness do not change**; only
waste is removed.

> Note on provenance: two of these decisions correct claims made in the 0004
> `spec.md` (and one in the 0003 audit §4.3) that were asserted from a skim rather
> than verified (§32). The executing agent's checks caught them; they are fixed
> here rather than defended. See D3 and the Amendments section.

---

## D1 — Queue count contract (blocks Sprint 03 / WP-C)

**Question (board):** may `Queue.depth()` change from pending-only `Int` to
pending+unacked `UInt64`, or must a new `total_count()`/`message_count()` API carry
the AMQP get-ok meaning?

**Evidence:**
- `src/hyrx/core/queue.mojo:144` `depth(): Int = inbox+outbox` — **pending only**,
  the established meaning.
- `src/hyrx/core/queue.mojo:72` `_total_count(): Int = pending+unacked` — the
  backpressure predicate (`enqueue` uses it at `:86`) and the engine management
  metric (audit §22).
- `src/hyrxmq/amqp_service.mojo:941` `write_u32(gargs, 0)` + header `:50` — get-ok
  `message-count` is hardwired 0 "engine has no depth read-back."

**Resolution — do NOT touch `depth()`:**
- `Queue.depth()` **stays** pending-only, **stays** `Int`. It already *is* the
  quantity AMQP `basic.get-ok.message-count` denotes (RabbitMQ reports the number
  of **ready** messages remaining, excluding unacked).
- Add **no** competing `total_count()` — `_total_count()` already exists and is a
  *different*, legitimate quantity (the engine-side management/backpressure count).
  The two counts stay distinct and separately named; never conflated.
- Surface the pending count to the service through the engine boundary only:
  `EmbeddedEngine::queue_message_count(id: MessageID-like/queue) -> Int` returning
  the **post-pop** `depth()` (count after the get has removed its message), plus
  `queue_routing_key(delivery_tag)` wrapping the existing
  `Queue.read_routing_key(tag)` (`queue.mojo:123`).
- **Width at the wire:** keep `Int` internally; the single conversion `Int→UInt32`
  happens **only** at the `write_u32(gargs, …)` site, saturating-guarded by the
  queue-capacity bound (`capacity ≤ default_queue_capacity ≤ Int`). No `UInt64`
  is introduced in the core; the board's "pending+unacked `UInt64`" variant is
  **rejected** as both a semantic change and a needless width widening.

**Why:** redefining `depth()` would silently change a load-bearing value (it is
`enqueue`'s sibling and an established read API) to satisfy a wire hint — the exact
anti-pattern the invariant forbids. get-ok's ready-count is already available
without any redefinition.

**Obligation:** negative proof — a test that publishes 3, `basic_get`s 1, and
asserts the get-ok `message-count == 2` (pending after the pop) and a **non-empty**
routing key equal to the published key; both must fail against the current
`write_u32(…,0)`/`rk=""`.

---

## D2 — Pool contract before P1b (blocks Sprint 02 / WP-B)

**Question (board):** how is the engine-owned pool injected into the router, and on
size-class exhaustion (no release path) must publish direct-allocate, reject, or
fail? (Spec defined only oversize fallback.)

**Evidence:**
- `src/hyrx/core/buffer_pool.mojo:60` `acquire()` **raises** "BufferPool: exhausted"
  at `max_slabs`; there is **no** `release` wired into the live path yet (P1b).
- `src/hyrx/embedded/api.mojo:82/91` — the **engine owns** `BufferPool(slab=4096,
  max_slabs=64)`, currently **stats-only** (`:192 self._pool.stats()`), not used by
  `publish`.
- `src/hyrx/core/router.mojo` — the `Router` lives in **core** and does **not** hold
  the pool.

**Resolution — P1a does not route the hot path through the recycling pool:**
- **Exhaustion behaviour = direct allocation. Never reject, never raise.**
  Rationale: publish's *only* existing negative outcome is queue backpressure
  (`enqueue` returns `False` when `_total_count() ≥ capacity`). Allocation
  exhaustion is a **performance-resource** condition, not a correctness one; making
  it reject would silently drop deliverable messages, and making it raise would
  abort the fan-out loop mid-publish. Both change observable semantics — forbidden.
  So the permanent contract (P1a *and* P1b) is: **try the pool; on any
  exhaustion/oversize, fall back to a fresh correctly-sized `Buffer`.** Queue
  capacity remains the sole reason publish returns `False`.
- **Injection in P1a = none.** Because there is no `release`, the pool can never
  refill, so routing `acquire` through it in P1a yields **zero** reuse and would
  only (a) drain 64×16=1024 buffers then direct-allocate forever, and (b) force a
  mutable borrow of an engine-owned pool into the core `Router` (a lifetime/aliasing
  problem in Mojo, deferred-with-evidence by the audit). P1a therefore keeps the
  router on **plain direct allocation**, sized exactly (no capacity padding).
- **P1b injection contract (future, recorded so P1a doesn't paint a corner):** when
  release lands, inject a **core-owned trait** `BufferAllocator` (implemented by
  `BufferPool`) into `Router` by borrow, *not* the concrete engine type — preserving
  `src/hyrx/core/**` independence. The `acquire`/`release` pair becomes symmetric
  and the size-class buckets start paying off; direct-alloc stays as the ceiling.
- **Consequence for Sprint 02 scope:** the *measurable* P1a win is the **bulk copy**
  (one pass, correct length) + the **single-destination move**. The "size-classed
  pool acquire" is deferred to P1b (or reduced in P1a to a no-op allocator seam).
  Do **not** claim recycle/throughput-from-pooling in this increment.

**Obligation:** a test that fills a bounded queue to capacity and asserts publish
returns `False` **only** for that reason, and that an oversized message (>4096 slab)
still publishes correctly via direct alloc; plus a no-stale-bytes check that a
sized `Buffer` copy is byte-identical to source at every destination.

---

## D3 — Listener parsing contract (Sprint 04 / WP-D remainder)

**Question (board):** `_serve_step` parses once before reading (already-buffered
frame) and once after reading (new data). What single-parse restructuring retains
both cases and the current partial-frame behaviour?

**Evidence (`src/hyrxmq/listener.mojo`):**
- `:272` `frame = try_parse_frame()` — drain an **already-buffered** complete frame,
  dispatching **without** a blocking `recv`.
- `:290` `try_parse_frame()` after `recv_bytes`+`feed_bytes` — parse **newly read**
  bytes; if still short → `SERVE_PARTIAL()` (`:292`).

**Resolution — restructure to a single parse; the two parses are NOT redundant:**
- Both call sites implement **drain-buffered-else-read**: when one `recv` returns
  1.5 frames (TCP coalescing), the next `serve_one_frame` must dispatch the second
  buffered frame *without* touching the socket; forcing a `recv` there would block
  a slot that already holds a complete frame and stall the round-robin poller.
- **No correct single-parse restructuring exists that retains both cases.** Any
  "fold" collapses the non-blocking drain into the blocking read and *changes
  partial-frame behaviour*. The board's framing of the task as "fold to one" is
  therefore **withdrawn as a mis-specification**.
- **Sprint 04 status:** the only valid WP-D item — removing the dead `try/except`
  around the non-raising `close()` calls — is **already implemented and green**
  (phase-7 AMQP service regression passes; socket tests compile but are
  execution-denied in this sandbox, matching the audit environment note). Sprint 04
  is otherwise a **no-op**; mark its "parser-loop cleanup" requirement **cancelled
  with evidence**, not pending.

**Obligation:** none new (behaviour unchanged). A compile-only confirmation that
`_serve_step` still yields `SERVE_PARTIAL` on a sub-frame read (covered by the
phase-7 service test).

---

## Amendments to apply (I was read-only; these are the edits)

1. `spec.md §WP-D` — delete "fold `_serve_step` double-parse into one"; keep the
   dead-`try` item (done). Add a one-line rationale + pointer to D3.
2. `spec.md §WP-B` — split into **B1** (bulk copy + single-dest move, hot path stays
   direct-alloc — the measured win) and **B2/seam** (pool `acquire`+`release`
   deferred to P1b; document exhaustion→direct-alloc as the permanent contract).
   Remove any P1a recycle/throughput-from-pooling claim.
3. `spec.md §WP-C` — change "add `Queue.depth()`" (it exists) to "**surface**
   `depth()` post-pop via `EmbeddedEngine::queue_message_count`+`queue_routing_key`;
   `Int→UInt32` at the wire only; `_total_count()` stays the management metric."
4. `0003 audit §4.3`/defect list — annotate the "wasted pass" note as a **retired
   misdiagnosis** (first parse = non-blocking buffered drain), superseded by D3 here.

## Board state after this record

- Sprint 01 (WP-A): **Ready** (independent of D1–D3).
- Sprint 02 (WP-B1): **Unblocked** — copy-cut + single-dest move; **no pool wiring**.
- Sprint 03 (WP-C): **Unblocked** — use D1's surfacing contract.
- Sprint 04 (WP-D): **Complete** — dead-`try` done; parser item cancelled per D3.
- Sprint 05: proceeds after 01–03; benchmarks re-measure the copy-cut only.
- **P1b** (pool `release` + recycling + allocator-injection) remains a separate
  reviewed package.

**Recommended resume order:** Sprint 01 → Sprint 02/B1 → Sprint 03 → Sprint 05
(re-measure fan-out + fair matrix; expect byte-copy ceiling ↑ and the 4 KiB/16 KiB
crossover to narrow — reported honestly, baseline updated only after review).
