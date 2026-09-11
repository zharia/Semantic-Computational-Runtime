# Persistence

## Principle

Persistence is an optional, explicit cost centre.

Durable messaging must provide crash-consistent semantics without forcing all in-process ephemeral messages through disk.

## Candidate architecture

- write-ahead log
- append-only segments
- indexes
- checkpoints
- recovery scanner
- compaction policy if required
- configurable durability mode

## Durability modes

At minimum distinguish conceptually:

- ephemeral
- buffered durable
- durable/flush-bounded
- strict durability

Exact semantics must be specified before implementation.

## Recovery requirements

Validated by `tests/phase8/storage_test.mojo` and
`tests/phase10/persistence_crash_test.mojo`:

- clean shutdown — **TESTED** (sync-before-replay equivalence; v0.0.3)
- crash during append — **TESTED** (torn-tail detection + truncation)
- crash during rotation — **NOT TESTED** (no segment rotation)
- crash during checkpoint — **NOT TESTED** (no checkpoint mechanism)
- partial final record — **TESTED** (test_crash_tail_recovery + phase10 framing corruption)
- corrupted record — **TESTED** (CRC-32 rejection; phase10 body-byte flip fails closed)
- missing segment — **NOT TESTED** (no segment rotation)
- disk full — **PARTIALLY TESTED** (phase10 FailingOps raises on append; cleaner error path)
- permission failure — **NOT TESTED**
- interrupted fsync — **NOT TESTED** (FakeOps.sync is a no-op)
- replay after unclean termination — **TESTED** (idempotent replay after truncation)
- WAL write-ahead (unrouted message recovered) — **TESTED** (phase10)
- ack / remove tombstones — **TESTED** (phase10)
- multi-queue persistence — **TESTED** (phase10; durable recovered, non-durable not materialized)

## Performance

Measure separately:

- no persistence
- buffered persistence
- strict durability

Do not use durable benchmarks to characterize the latency of the in-memory engine.

## Data integrity

Use checksums or equivalent integrity mechanisms where appropriate.

Recovery must fail safely rather than silently producing incorrect topology or message state.
