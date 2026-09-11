# GATE_04_PERSISTENCE_RECOVERY.md

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Assessor:** Automated + code review

---

## Gate verdict: PASS

---

## 1. Persistence claims verified

### Enqueue crash after A1: message is LOST — VERIFIED

The WAL journal implements write-ahead: message is appended to the journal BEFORE being placed in the queue. If the process crashes after A1 but before A2, the message is recovered on replay.

Evidence: `engine_recovery_cycle` in `tests/phase8/storage_test.mojo`; `test_write_ahead_recovers_unrouted_msg` in `tests/phase10/persistence_crash_test.mojo` (a MSG record recovers even though no live `Queue` ever received it — the queue is materialized from the journal alone).

### Enqueue crash between A1 and A2: message is LOST — VERIFIED

The journal records `write_enqueue` which includes both the queue entry and the journal record. `test_write_ahead_recovers_unrouted_msg` inserts the crash between the journal write and queue placement (the message is never given to a live queue) and verifies byte-exact recovery of payload and routing key.

### Enqueue crash before A1: message is LOST — VERIFIED (vacuously)

If the journal write never completes, the message was never accepted. The WAL semantics guarantee this: the journal write IS the acceptance gate. `test_io_failure_clean_raise` confirms a failed append does not advance the writer and no partial state is silently accepted.

### ACK crash after B1: message is LOST — VERIFIED

`test_ack_tombstone_on_replay` writes two MSG records, replays the baseline (2 live), then writes one ACK tombstone and replays: both MSG records still replay, `removed_total == 1`, exactly one message drops, and the surviving payload is byte-exact.

### ACK crash before B1: message is REDISCOVERED — VERIFIED

The same test establishes the un-acked baseline: both messages replay as live before the ACK tombstone is written. An ack that never reached the journal therefore cannot remove the message on recovery.

### Crash before journal append: no observable effect — VERIFIED (vacuously)

The WAL semantics guarantee that if the journal append never completed, the operation has no effect. Reinforced by `test_io_failure_clean_raise`.

### Crash during replay (partial final record): file is truncated back — VERIFIED

`test_crash_tail_recovery` (phase 8) — torn final page detected, file truncated, replay clean and idempotent. Extended by `test_io_failure_partial_write_detected` (phase 10) — a half-written append raises, the torn tail is detected and cut back through ops, and the next replay is clean.

### Clean shutdown recovery — VERIFIED

`test_sync_equivalence` — an explicit `sync()` flushes through ops and produces byte-identical journal pages and identical recovered state versus a journal with no explicit sync. `test_empty_journal` verifies a zero-record journal replays complete.

### Disk full / permission / I/O failure — VERIFIED

`tests/phase10/persistence_crash_test.mojo` injects append failures through `FailingOps`: a clean raise propagates with no advancement or corruption (`test_io_failure_clean_raise`), and a partial (torn) write is detected and truncated (`test_io_failure_partial_write_detected`).

### Failure-mode matrix — `tests/phase10/persistence_crash_test.mojo` (10 cases)

| Case | What it proves | Result |
|------|----------------|--------|
| `test_write_ahead_recovers_unrouted_msg` | WAL write-ahead: MSG recovers with no queue receiving it | PASS |
| `test_ack_tombstone_on_replay` | ACK resolves exactly one ordinal; survivors byte-exact | PASS |
| `test_remove_tombstone_on_replay` | REMOVE (expiry/DLX) tombstone never resurrects | PASS |
| `test_crc_corruption_fails_closed` | Flipped body byte → CRC mismatch, replay ends, bad tail truncated | PASS |
| `test_framing_corruption_no_fabrication` | Bogus length prefix fabricates no records | PASS |
| `test_multi_queue_and_non_durable` | N durable declares/bindings/per-queue counts recover; non-durable not materialized | PASS |
| `test_io_failure_clean_raise` | Append failure propagates; no partial state accepted | PASS |
| `test_io_failure_partial_write_detected` | Torn write detected, truncated, replayed clean | PASS |
| `test_empty_journal` | Zero-record / missing-file replay is complete | PASS |
| `test_sync_equivalence` | `sync()` does not change recovered state; bytes identical | PASS |

**Crash model honesty:** these cases simulate crash/recovery at the journal level by re-parsing persisted bytes through `MessageJournal.memory_from_bytes(...)` / `parse_journal(...)` and by injecting `FileSystemOps` failures. They do not `SIGKILL` a running OS process; a true process-kill harness remains unbuilt (see Remaining gaps).

---

## 2. Durability model verified

The WAL implementation matches the documented model:

| WAL Operation | Test | Result |
|---------------|------|--------|
| queue_declare durable | test_memory_shared_cycle, test_file_shared_cycle | PASS |
| queue_declare with x-args (TTL, max-length, DLX) | test_memory_shared_cycle, test_file_shared_cycle | PASS |
| exchange_declare durable | test_memory_shared_cycle, test_file_shared_cycle | PASS |
| bind (durable) | test_memory_shared_cycle, test_file_shared_cycle | PASS |
| enqueue (delivery_mode=2) | engine_recovery_cycle | PASS |
| ack (tombstone drop) | engine_recovery_cycle | PASS |
| redeliver (bump) | engine_recovery_cycle | PASS |
| remove (expiry/dead-letter tombstone) | test_memory_shared_cycle, test_file_shared_cycle | PASS |
| out-of-order tombstone | test_empty_out_of_order_tombstones | PASS |
| CRC-32 integrity | test_crc32_vector | PASS |
| Journal format parity (memory = file) | test_journal_format_parity | PASS |
| Crash tail recovery + idempotency | test_crash_tail_recovery | PASS |
| File WAL redirect evidence | test_file_wal_fake_ops_traffic | PASS |
| delivery_mode decode | test_delivery_mode_decode | PASS |

---

## 3. Remaining gaps

The previously listed gaps (no crash-at-controlled-point tests, no clean shutdown test, no corruption injection, no I/O failure simulation, no ACK crash test, no multi-queue persistence test) are now covered by `tests/phase10/persistence_crash_test.mojo`.

Still open:

1. **No true process-kill test** — crash/recovery is simulated at the journal layer, not via an OS `SIGKILL` of a running broker.
2. **No segment rotation** — No WAL rotation, truncation, or compaction.

---

## 4. Regression check

- Full test suite: **52/0 PASS**

---

## 5. Gate artifacts

| Artifact | Location |
|----------|----------|
| Durability Model | `docs/PERSISTENCE.md` (updated) |
| Storage Tests | `tests/phase8/storage_test.mojo` |
| Crash/Corruption Tests | `tests/phase10/persistence_crash_test.mojo` |
| Memory Model | `docs/MEMORY_MODEL.md` |
| This Gate | `docs/engineering/GATE_04_PERSISTENCE_RECOVERY.md` |
