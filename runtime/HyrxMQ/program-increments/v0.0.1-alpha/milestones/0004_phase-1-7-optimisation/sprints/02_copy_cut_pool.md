# Sprint 02 — Publish Copy Cut and Pool Acquire (WP-B)

Status: **done (B1)** — single bulk copy (`Buffer.from_buffer_copy`) + single-dest
move; pool `acquire`/`release` recycling deferred to P1b (decision D2; direct
allocation stays on the hot path).

## Contract

Fan-out destinations retain independent payload ownership and byte-identical
logical contents. A normal multi-destination path makes one copy per accepted
destination; an accepted single destination receives the consumed source
message without a payload copy. Queue capacity, frame limits, and existing
drop-on-full behavior must remain explicit.

## Planned slice

1. Add a Buffer-to-Buffer bulk-copy constructor/helper that allocates capacity
   and appends source bytes once, without a `resize` zero-fill pass.
2. Add a Message helper for the one-pass payload clone and update fan-out to
   avoid `Message.payload()`/`BufferSnapshot` in the clone path.
3. Add a non-consuming Queue capacity preflight. After filtering missing queue
   names, use it to move `msg` only for one accepting destination; otherwise
   retain `msg` for the copy path. `enqueue` itself consumes a rejected message,
   so it cannot be used as the guard.
4. Define and implement size-classed `BufferPool.acquire(min_capacity)` plus
   direct allocation for oversize payloads. Do not add release/recycle in this
   increment.

## Required tests

- bulk-copy exact length and bytes;
- no stale bytes, including a shorter payload after a larger capacity buffer;
- single-destination moved payload fidelity;
- full single destination falls back without losing the source; and
- oversize pool fallback fidelity.

## Feedback / blocker evidence

- `BufferPool` is currently a fixed-size pool owned by `HyrxEngine`; `Router`
  owns queues and has no pool reference. No production route calls it.
- With P1b deferred, every acquired buffer remains owned by a queue. The
  existing pool exhausts after `16 * max_slabs` acquisitions. The specification
  requires oversize fallback but does not define normal-class exhaustion.
- Passing the engine pool to router publishing, moving pool ownership into the
  router, and direct-allocating on ordinary exhaustion have materially different
  boundedness/telemetry behavior. Decision required before implementation.
