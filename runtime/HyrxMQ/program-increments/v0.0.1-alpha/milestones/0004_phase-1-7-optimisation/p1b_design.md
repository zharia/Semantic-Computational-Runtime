# P1b — BufferPool recycling: design, requirements, and rollout plan

**Author:** scr-architect (coordinator). **Status:** DESIGN — implementation HELD.
**Depends on:** Sprints 01–03 landed, reviewed, and **committed** in the shared tree.
**Owner of implementation:** opencode-k3 (single source writer). Coordinator reviews
the tree; does not edit source.

---

## 0. Why this is held and designed separately

P1b is the one change in increment 0004 that alters **object lifetime**. A defect
here does not fail loudly — it silently corrupts a payload (stale bytes) or crashes
later (use-after-free / double-return). Per the governing principle, we specify and
gate it, and build it only on a committed, green baseline. It is **last**, after the
zero-risk copy-cut (Sprints 01–03) is proven.

## 1. Verified current state (the shared tree, as reviewed)

- **Pool is off the message path.** `BufferPool` exists
  (`src/hyrx/core/buffer_pool.mojo`) and `EmbeddedEngine` owns it
  (`src/hyrx/embedded/api.mojo:82`), but nothing in `publish`/`Queue` calls
  `acquire`/`release`. Buffers are allocated directly
  (`Buffer.from_buffer_copy` / `Message.payload_copy`). `MEMORY_MODEL.md` D12
  confirms this.
- **`__deinit__` is a no-op** (`src/hyrx/core/buffer.mojo`) and, after a move
  (`var b = a^`), the source's `__deinit__` is not called. So reclamation is
  already implicit-only — you **cannot** recycle a Buffer out of its own destructor.
- **Single-destination move is live** (`router.publish`: `has_capacity()` preflight →
  `enqueue_prechecked(msg^)`) and transfers the **publisher's original** buffer —
  that buffer was never pool-acquired and must **never** be released to the pool.
- **Multi-destination copies** use `msg.payload_copy()` (direct allocation).
- **Two latent `BufferPool` bugs for reuse:**
  - `acquire()` returns a buffer **without resetting logical length** → a small
    message written over a previously-large reused buffer can read stale tail bytes.
  - `release()` always returns the buffer to the **last slab**, ignoring which
    size-class it came from → wrong under multiple classes (double-count, class
    drift, `_in_use` corruption).

## 2. Requirements (dependable + professional)

R1. **Preserve observable semantics.** Publish still returns the number of
    destinations; capacity-reject still silently drops *that destination's copy*;
    queue boundedness (`_total_count >= capacity`) unchanged. No new failure mode
    (allocation must not raise or reject a publish — see decisions.md D2).
R2. **Exactly-once reclamation.** Every pool-acquired buffer is released to the
    pool exactly once, and only when it is genuinely dead (no alias, no later use).
R3. **Origin-correctness.** Only buffers the pool handed out go back to it; the
    publisher's moved original and any direct-allocated oversize buffer never do.
R4. **No stale bytes / correct length.** A reused buffer's logical `size()` equals
    the newly written payload; readers see no prior payload.
R5. **Boundedness preserved.** Pooled bytes ≤ Σ(per-class max_slabs·16·class_size);
    oversize never pooled. Queue capacity + frame_max remain the true ceilings.
R6. **Lifetime order.** The pool outlives every Queue that can release into it —
    guaranteed structurally, not by luck of field order.
R7. **No dependency additions; `core` independence intact** (`src/hyrx/core/**`
    imports nothing AMQP/socket/flare/broker).

## 3. Design (the safe shape)

**3.1 Explicit release, never `__deinit__`.** Reclamation is an operation on an
owned `Buffer`, so it must happen at a controlled move site, with the pool reached
as an **argument** (`ref BufferPool`), never a stored back-reference (avoids
multi-`Queue`-mutable-borrow aliasing and the field-order hazard).

**3.2 Origin tag.** Add `Buffer._pooled: Bool` set `True` only by
`BufferPool.acquire*`. `release` **ignores** non-pooled buffers (and asserts
`_in_use` bookkeeping). This makes every death site call one uniform
`release_or_drop(buf, ref pool)` without knowing provenance — and protects the
single-dest move + direct-allocated oversize buffers (R3).

**3.3 Size classes + reset-on-acquire.** Extend the pool to power-of-two classes:
- `acquire(min_bytes) -> Buffer`: pick the smallest class ≥ min_bytes (≤ a max
  class); **reset logical length to 0** on return (fixes R4); track `_in_use`.
- `release(buf)`: return to the buffer's **own class** (fix §1 bug), decrement.
- Oversize (> largest class) → caller `Buffer::from_buffer_copy` direct path
  (R1/R5). `acquire` **never raises** for exhaustion — it delegates to direct alloc
  (decisions.md D2).

**3.4 Lifetime order (R6).** Fix the inverted declaration: in `EmbeddedEngine`
declare `_pool` **before** `_router` so the pool is torn down last, AND (belt +
braces) drain+release queues explicitly in a real shutdown step before dropping the
pool. Today `broker.shutdown` does not drain; `Router.delete_queue`
(`router.mojo:70`) drops the whole queue on the deinit path and returns a vestigial
empty list — both must move to explicit drain.

## 4. Enumerated release (death) sites — every one, with today's file:line

| # | Site | File:line | Today | P1b action |
|---|------|-----------|-------|-----------|
| 1 | capacity-reject in fan-out | `Queue.enqueue` `queue.mojo:81` (early `return False`, msg dropped) | deinit frees | release the moved copy to pool |
| 2 | acknowledge | `Queue.acknowledge` `queue.mojo:162` | deinit frees | pop → release |
| 3 | queue delete | `Router.delete_queue` `router.mojo:70` (drops Queue) | deinit frees all | add `Queue.drain_and_release(ref pool)` before pop |
| 4 | engine shutdown | `EmbeddedEngine` teardown / `broker.shutdown` `broker.mojo:68` (currently no-op) | OS at exit | explicit drain-all, then drop pool |
| 5 | orphan-on-disconnect | `Router.unregister_consumer` (`audit D8`) | unacked msgs **never** freed until teardown | must requeue or release, else pool starvation — **see R-DEP** |

Non-death (do NOT release): `Queue.dequeue`→unacked (`:110`), `reject`→re-enqueue
(`:169`), `read_payload`/`read_routing_key`/`read_message_id`/`read_headers` (copies,
message stays owned).

## 5. Invariants to TEST (each needs a negative proof)

- **I-1 no-stale**: acquire a large-class buffer, fill fully, release, re-acquire
  for a small payload, write small, read back → only small bytes, `size()`==small.
- **I-2 balance**: after a deterministic publish/ack/delete soak of N pooled
  messages, `pool.stats().in_use == 0` and free-list total == allocated.
- **I-3 origin**: publisher's single-dest moved original is NOT returned to pool
  (`in_use` unchanged by that path); oversize direct-alloc NOT pooled.
- **I-4 exhaustion→direct**: drain the pool below capacity, keep publishing →
  publishes succeed, no raise/reject (R1).
- **I-5 order**: teardown drains every queue before pool drop; a release-after-drop
  is structurally impossible (flag + assert).
- **Negative proofs**: comment out site-2 release → I-2 fails; skip the reset in
  acquire → I-1 fails; reorder fields so pool deinits first → I-5 fails.

## 6. Rollout (phased, gated, reversible)

- **P0 (prereq).** Sprints 01–03 **committed** + `test_all.sh` 38/0 + approved.
- **P1.** Size-classed pool + `acquire`/`release` + reset, **pure unit tests**
  (`tests/phase1/buffer_pool_test.mojo` extended). Not wired. Gate: those tests.
- **P2.** `Buffer._pooled` + thread `ref BufferPool` into `Queue.enqueue`/
  `acknowledge`/`delete_queue` release sites; wire `publish` multi-dest to
  `acquire` (fall back direct on oversize/exhaustion). Feature-flag
  `config.buffer_pool_enabled` **default OFF**.
- **P3.** Real shutdown drain-all; fix `_pool`/`_router` order; handle D8 orphans
  (R-DEP). Leak-`in_use==0` test across all sites.
- **P4.** Flip flag ON behind the soak + perf re-measure (the honest win here is
  allocator-churn, since copies already fell in 01–03 — measure, do not assume).
- **Rollback.** `buffer_pool_enabled=false` → identical to P0 (direct alloc) with
  zero semantic change. Every phase keeps that switch.

**R-DEP (must resolve or explicitly bound):** orphan-on-disconnect (audit D8) means
unacked pooled buffers can be stranded indefinitely → pool starvation. P1b either
releases/requeues them on consumer-gone (recommended, and also fixes D8) or documents
a hard cap and proves no starvation. This is a decision for the implementer+coordinator
before P2.

## 7. What "when appropriate" means operationally

opencode-k3 starts P1b **only after**: (a) Sprints 01–03 committed + architect
`approve`, (b) this design reviewed by k3 for implementer risk with any
`status:question` answered, (c) R-DEP decided. Until then, P1b is documentation.
