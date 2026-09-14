# M3: Persistence & Failure Durability

**Gate:** D (Durability)
**Spec:** Sections 27-31

## Sprint 3.1 — WAL Hardening
- [x] WAL with CRC protection (storage.mojo)
- [x] Recovery replay (router.mojo:recover)
- [ ] WAL compaction (tombstone reclaim)
- [ ] Segment rotation
- [ ] Disk-full behavior (graceful rejection)
- [ ] Corrupted record handling

## Sprint 3.2 — Real Process-Kill Testing
- [ ] SIGKILL harness (kill during publish → restart → verify state)
- [ ] Kill during flush
- [ ] Kill during recovery
- [ ] State comparison framework

## Sprint 3.3 — Persistence Failure Matrix
- [ ] Missing segment handling
- [ ] Truncated segment handling
- [ ] Permission failure
- [ ] Read-only filesystem

## Exit Criteria
- [ ] WAL compaction works
- [ ] Real SIGKILL recovery verified
- [ ] Corruption detection works
