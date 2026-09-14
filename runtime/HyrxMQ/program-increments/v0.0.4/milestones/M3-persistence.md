# M3: Persistence & Failure Durability

**Gate:** D (Durability)
**Status:** COMPLETE (core) — WAL compaction, real SIGKILL recovery and
corruption handling verified; segment rotation and permission/RO-fs cases remain.
**Spec:** Sections 27-31

## Sprint 3.1 — WAL Hardening
- [x] WAL with CRC protection (storage.mojo)
- [x] Recovery replay (router.mojo:recover)
- [x] WAL compaction (tombstone reclaim; idempotent `compact()`) — tested
  `tests/phase10/wal_compaction_test.mojo`
- [ ] Segment rotation — **NOT DONE**: single-log WAL, no rotation policy.
- [x] Disk-full behavior (graceful rejection) — `scripts/disk_failure_harness.sh`,
  `tests/phase10/disk_failure_test.mojo`
- [x] Corrupted record handling (fail-closed, live prefix survives) —
  `tests/phase10/wal_hardening_test.mojo`

## Sprint 3.2 — Real Process-Kill Testing
- [x] SIGKILL harness (`scripts/sigkill_harness.sh`) — kill mid-publish,
  restart on same WAL, count recovered. Verified 2026-09-14:
  `SIGKILL_HARNESS=PASS recovery: 10:10 50:50 90:90`.
- [ ] Kill during flush — **NOT DONE**: harness kills mid-publish, not at a
  forced fsync boundary.
- [ ] Kill during recovery — **NOT DONE**: no kill injected during replay.
- [x] State comparison framework — harness asserts recovered > 0 per timing;
  in-process path `tests/phase10/sigkill_test.mojo`.

## Sprint 3.3 — Persistence Failure Matrix
- [x] Missing segment handling — `wal_hardening_test.mojo` (`test_missing_segment`)
- [x] Truncated segment handling — `wal_hardening_test.mojo` (`test_truncated_record`)
- [ ] Permission failure — **NOT DONE**: no EACCES injection test.
- [ ] Read-only filesystem — **NOT DONE**: no EROFS injection test.

## Exit Criteria
- [x] WAL compaction works
- [x] Real SIGKILL recovery verified
- [x] Corruption detection works
- [ ] Segment rotation, permission / read-only-fs cases