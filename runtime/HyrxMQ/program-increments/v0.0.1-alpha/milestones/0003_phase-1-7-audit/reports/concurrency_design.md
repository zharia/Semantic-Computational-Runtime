# Concurrency Design (audit §8) — READ-ONLY analysis

**Date:** 2026-09-08 · **Toolchain:** Mojo 1.0.0 (ed45d567), repo pixi env · **Status:** design only; no code changed.
**Method:** every Mojo capability claim below is from a probe actually executed in this environment (`pixi run mojo`). Raw probes: `/tmp/opencode/hyrxmq_probe/` (this session).

---

## 1. Current state — facts, not vibes

**There is no concurrency anywhere in the product.** `grep -rn "Thread|spawn|atomic|Atomic" src/ --include="*.mojo"` → zero matches. The process is single-threaded end to end.

Shared mutable state, all reachable from one thread today:

| State | Location | Mutated by |
|---|---|---|
| Router topology: `_exchanges`, `_queues`, `_consumers`, `_next_consumer_id`, `_messages_routed` | `src/hyrx/core/router.mojo:24-28` | every declare/bind/publish/consume/ack (all `mut self`) |
| Queue internals: `_inbox`, `_outbox`, `_unacked`, `_next_delivery_tag` | `src/hyrx/core/queue.mojo:53-58` | enqueue/dequeue/ack/reject; two-stack FIFO `_transfer()` pops-reverses the whole inbox (`queue.mojo:75-78`) |
| Engine counters + `BufferPool` slabs/free-lists | `src/hyrx/embedded/api.mojo:81-87`, `buffer_pool.mojo:21-26` | publish/consume path |
| Connection registry: `conn_id → AMQPConnectionState`, `conn_id → consumer` | `src/hyrxmq/amqp_service.mojo:224-260,341` | every frame dispatch |
| Listener slots: `_conns/_codecs/_closed` lists, `_next_conn_id` | `listener.mojo:32-49`, `tcp.mojo:39` | accept/serve |

Connection handling is **strictly serialized**: `AMQPListener.serve_forever` (`listener.mojo:152-159`) accepts one connection and serves it to EOF/close before the next exists at all; `recv_bytes` (`tcp.mojo:127-138`) wraps a blocking `stream.read`. A real accept-loop would have to touch *all* rows above: `accept` mutates `_conns`/`_next_conn_id`; frame dispatch mutates `_service` → broker → engine → Router → Queue. There is no read/write split; every hot-path method is `mut self` on the one Router.

**Pool fact (relevant to later work):** `BufferPool.acquire()`/`release()` have **zero call sites outside `buffer_pool.mojo` itself**; the routing path allocates a fresh `Buffer` per destination queue and copies the payload byte-by-byte (`router.mojo:140-145`). The pool is stats-only today. Under any threading design the single shared pool would itself be a global contention point; today it is simply unwired.

---

## 2. Ownership domains (audit §8 list)

- **Message payload:** `Message` owns its `Buffer` (`message.mojo:54-71`); ownership transfers by move (`^`). Routing does **not** share payloads — `Router.publish` *copies* the payload into a new `Message` per destination queue (`router.mojo:132-147`). After routing, no two queues alias one buffer. This is ideal for concurrency: payload ownership crosses any future boundary by move, one owner at a time.
- **Queue:** owned by the Router's `_queues` Dict; the Queue owns its messages through inbox/outbox/unacked (`queue.mojo:3-13`); `Delivery` is a tag-only claim token (`queue.mojo:35-49`); payload reads return a **snapshot copy** (`buffer.mojo:61-70` `as_view`), so a reader never aliases live queue memory.
- **Exchange:** owned by Router; owns its `List[Binding]`; `match()` returns copied queue-name strings — read-only w.r.t. messages (`exchange.mojo:160-186`).
- **Consumer:** pure value type in Router's `_consumers` Dict (`consumer.mojo:10-27`); prefetch/active-delivery counters mutate per delivery/ack.
- **Connection:** socket + per-slot `AMQPFrameCodec` are per-connection (listener `_conns/_codecs`); **but** per-connection protocol state (`_conns` in `amqp_service.mojo`) and the engine it drives are global. So: *transport is naturally per-connection; semantics are globally shared through the one Router.*

**Consequence:** the unit that wants to be thread-private is the (socket, codec) pair; the unit that is unavoidably shared is topology (exchanges/binds/queue existence); the unit worth making *exclusive* to a worker is a single Queue plus its consumers.

---

## 3. What this Mojo 1.0 toolchain actually provides (probed, not assumed)

| Probe (exact import) | Result |
|---|---|
| `from threading import Thread` | **error: unable to locate module 'threading'** |
| `from concurrency import *` | **error: unable to locate module 'concurrency'** |
| `import sys` / `from sys.atomic import ...` | **error: unable to locate module 'sys'** (same for `std.sys.threading`, `std.sys.atomic`) |
| `from std.os.sync import Mutex` / `from std.os.thread import Thread` / `from std.sync import *` / `from std.threading import *` | **unable to locate** — no std mutex, no std thread |
| `from std.atomic import Atomic, Ordering` | **WORKS.** `var a = Atomic[DType.uint64](0)`; `a.store[ordering=Ordering.RELEASE](5)`; `a.load[ordering=Ordering.ACQUIRE]()`; `a.fetch_add[ordering=Ordering.RELAXED](1)` — *executed*, printed `5`/`5`. Ordering members are UPPERCASE (`Ordering.relaxed` errors). Static pointer-based form also works: `Atomic[DType.int64].load[ordering=Ordering.ACQUIRE](ptr)` (the pattern flare uses). |
| CAS: `a.compare_exchange_strong(...)`, `a.compare_exchange[order=Ordering.RELAXED](0,1)` | `compare_exchange` *exists* but **no overload resolved** with any form tried this session. **CAS: unproven.** |
| OS threads via std | none |
| OS threads via vendored flare (internal): `from flare.runtime._thread import ThreadHandle` (`vendor/flare/flare/runtime/_thread.mojo`, raw `pthread_create` FFI, move-only handle, thin **non-capturing** start routine, must `join()`) | **WORKS end-to-end.** Cross-thread probe (`p16_mt_e2e.mojo`): spawn thread, worker release-stores `42` through `Atomic[DType.uint64].store[ordering=Ordering.RELEASE]`, main thread joins, acquire-loads → **printed `cross-thread value: 42`**. |
| flare public runtime (`flare.runtime`) | `Scheduler` (epoll/io-uring reactor + pinned worker threads), `Pool`, `block_in_pool`, `TimerWheel`, `_pbuf_ring` (atomic ring buffer) — all *exist in-tree*; our wrapper (`src/hyrx/transport/tcp.mojo`) currently uses flare only for blocking socket I/O and never its reactor. |
| Syntax note | `fn` removed: *"'fn' has been removed; use 'def' instead"*. `List[T]` requires `T: Copyable` (flare's own note; it stores `ThreadHandle` in an `UnsafePointer` array because handles are move-only) → **move-only `Queue`/`Message` cannot live in std `List`; any handoff structure needs pointer/arena plumbing.** |

**Verdict on the pivotal constraint:** threads + release/acquire atomics are *real and working* in this toolchain — but only as **unsafe-by-convention FFI** (flare-internal `ThreadHandle`, raw pointers, thin non-capturing entry, manual join) on top of `std.atomic` cells. There is **no std Mutex/channel/async task model, and CAS is unconfirmed**. Multi-threaded correctness would rest entirely on hand-rolled discipline, with no race-detection tooling in the Mojo toolchain to check it. Single-threaded event-loop concurrency, however, is available *today* with zero thread-safety requirements.

---

## 4. Candidate models, judged against the above

| Model | Requires | Verdict vs this toolchain + ownership |
|---|---|---|
| **Single event loop** (one thread, non-blocking I/O via flare reactor, interleaved per-connection steps) | flare `Scheduler`/reactor only; no shared-state mutation across threads; no atomics, no locks, no CAS | **Fully buildable.** Preserves the one-owner-per-value invariant (INV-011) for free: Router stays thread-confined. Fixes connection *fairness/churn* (the §8 complaint) without touching routing semantics. No multi-core scaling of the hot path. |
| **Sharded queues** (N queue-shards each owned by a worker thread) | threads (FFI), atomic handoff, CAS or ticket locks, per-shard pools | Buildable *only* with unsafe handoff (no std lock, CAS unproven) + `List`-copyable obstacle (§3). Fan-out/topic exchanges match across shards → a publish touches multiple shards → multi-queue write ordering = deadlock/atomicity hazard the current semantics never defined. |
| **Connection-per-worker** (thread per connection calling engine directly) | global Router lock (or full re-architecture) | **Worst fit.** Every `mut self` Router call becomes a critical section; see §5. Also breaks move-only payload aliasing safety by design. Reject. |
| **Queue-ownership / actor** (queue + its consumers confined to an owner thread; topology on a control thread; messages cross via handoff ring) | same as sharded + per-queue delivery-tag/ack routing to the owning thread; wakeups | **Right long-term shape** — matches §2 exactly (payload moves by value into an owner; ack returns to the same owner; `match()` result is a list of (queue→actor) handoffs, no shared mutation). Cost: same hard primitives gap; needs a mailbox (`flare.runtime._pbuf_ring` exists as a starting point but is flare-internal). |
| **Work-stealing** | atomic deques + CAS + scheduler | No usable foundation for move-only queues; no measurement demanding it (INV-009). Reject for now. |
| **Hybrid (event-loop accept + queue-actors for delivery)** | both of the above, in stages | **Recommended target** — see §5. |

**Why not by fashion:** connection-per-worker is the classic accident (it *looks* like the serialized code "just needs threads"); the ownership table in §2 shows why it multi-locks the one globally shared struct. Sharding is tempting but the *semantics* of cross-shard fan-out atomicity are undefined — that is exactly "implementation convenience redefining semantics" (governing principle).

---

## 5. Hot-path synchronization analysis

**Where the global lock would go:** one mutex around `HyrxEngine`/`Router` — i.e. every `publish`, `consume`, `acknowledge`, `reject`, `declare_*`, `bind_*`. Why that is bad, concretely:

1. `publish` + `consume` + `ack` all serialize on it → throughput ceiling = single critical section, and the §8-mandated "simultaneous publish/consume/ack" test degenerates to interleaved singles.
2. Contention lives on **hot cache lines that mutation already dirties**: `_queues`/`_unacked` Dict buckets, `_inbox/_outbox` List headers (`queue.mojo`), `_next_delivery_tag`, `_messages_routed`. Every lock handoff ping-pongs exactly these lines across cores.
3. The byte-by-byte payload copy per destination (`router.mojo:143-144`) inside the critical section makes the lock **hold time proportional to message size** — worst-case convoying.
4. Topology (`declare`) would share the lock with data plane → violates INV-012 (management off the hot path).

**How the recommended shapes reduce it:**
- *Single event loop:* **zero** locks. One thread touches engine state; per-connection state is private by construction; the codec lists already are per-slot.
- *Queue-ownership:* one lock-free handoff (fetch_add-based MPSC ring — fetch_add verified working) **per queue**, between the router thread (enqueue side) and the queue-owner thread (dequeue side). Ack/reject is a small message back to the same owner. Topology never shared: reads on a frozen/CoW snapshot. `_next_consumer_id`, `_messages_routed`, pool stats → per-owner atomics on **padded, isolated cache lines** (`std.atomic` cells suffice; no CAS needed for counters — `fetch_add` verified).
- Cache locality: per-queue ownership keeps inbox/outbox/unacked lines hot on one core; payload copies (`Buffer` → new `Message`) become owner-local; per-worker arenas replace the single `BufferPool` (which is unwired anyway — §1 — so sharding it later costs nothing).

---

## 6. Recommended model + phased plan (design only — nothing implemented)

**Phase A (immediate, honest): single event loop.** Replace serialized `accept_and_serve_one` with flare-reactor-driven interleaving of many non-blocking connections on the reactor thread; engine stays thread-confined. Gains: connection churn + simultaneous connections (real §8 pain) without a single atomic. Zero thread-safety surface.
**Phase B (deferred, gated): queue-ownership actors.** One owner thread per queue shard, MPSC handoff rings, ack-return path, control thread for topology. Preconditions (all currently unmet): std (or audited in-tree) mutex/channel or *proven* CAS; a `Pointer`-based mailbox for move-only `Message`; a race-detection story; §8 tests green.
**Do not:** global-mutex Router, connection-per-worker, work-stealing — see §4.

**Concrete tests that MUST pass before any concurrency claim (audit §8 list, made executable):**
1. **many producers → one queue:** K threads each produce N messages into one queue (via handoff ring); assert `count == K*N`, no duplicates (unique payload tags), per-producer FIFO preserved, global order explicitly *not* guaranteed.
2. **one producer → many consumers:** M consumers on one queue with prefetch P; assert every message delivered to ≥1 consumer, each ack destroys exactly one; requeue-after-reject delivered again with incremented `delivery_count` (`queue.mojo:100`, `message.mojo:85-87`).
3. **many producers → many queues** via fanout/topic exchange: assert every bound queue receives every matching publish (router semantics preserved under concurrency — the cross-shard atomicity question of §4 must be answered *first*, per spec §"never redefine semantics for convenience").
4. **connection churn:** 10³ connect/close cycles interleaved with traffic; assert no leaked listener slots (`listener.mojo:77-88`), conn ids monotonic, `status()` counters exact.
5. **simultaneous publish/consume/ack:** the three ops driven from separate threads continuously; assert `published == routed+unrouted`, `delivered == acked + rejected + unacked + in-flight`, bounded queue depth ≤ capacity (INV-010, `queue.mojo:85`).
6. All of 1-5 under **flare `ThreadHandle` spawn/join** with `std.atomic` assertions; repeated ≥10⁴ iterations; plus one sanitizer story (Mojo toolchain has no TSan integration → run `mojo build` binary under `valgrind --tool=helgrind`/`drd` and say so honestly if inconclusive).

---

## 7. Gate statement for §33

> **CONCURRENCY: EXPLICITLY DEFERRED WITH EVIDENCE**

Evidence, all verified this session in this exact toolchain (Mojo 1.0.0 ed45d567):

1. **Nothing concurrent exists to validate** — zero thread/atomic references in `src/` (grep); all hot-path state is one `mut self` Router (§1); "concurrency correctness" tests would be tests of an absent feature.
2. **The toolchain lacks a safe concurrency foundation** — `threading`, `sync`, Mutex, channels, async all *unable to locate* (§3 probe table); working pieces are `std.atomic` fetch_add/load/store (executed, correct) and raw `pthread` FFI inside vendored flare (cross-thread release-store/acquire-load executed: `cross-thread value: 42`), with **CAS unresolvable** in-session, `List` incompatible with move-only payloads, and no race-detection tooling. Threads here are an *unsafe library*, not a language guarantee.
3. **The deferral is bounded and planned:** Phase A (single event loop) needs none of the missing primitives and is the next honest step; Phase B preconditions and the §6 test list are recorded so the future work is verifiable, not aspirational.

Per audit §33 this is the satisfied branch of "VALIDATED OR EXPLICITLY DEFERRED WITH EVIDENCE". No concealment, no overstated claim of concurrency.
