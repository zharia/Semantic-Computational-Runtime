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

Test:

- clean shutdown
- crash during append
- crash during rotation
- crash during checkpoint
- partial final record
- corrupted record
- missing segment
- disk full
- permission failure
- interrupted fsync
- replay after unclean termination

## Performance

Measure separately:

- no persistence
- buffered persistence
- strict durability

Do not use durable benchmarks to characterize the latency of the in-memory engine.

## Data integrity

Use checksums or equivalent integrity mechanisms where appropriate.

Recovery must fail safely rather than silently producing incorrect topology or message state.
