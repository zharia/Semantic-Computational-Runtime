# Progress Report — M4 Persistence Crash Validation

**Date:** 2026-09-11
**Status:** COMPLETE
**Gate verdict:** PASS

**WHAT CHANGED:**
- `tests/phase10/persistence_crash_test.mojo` — NEW (462 lines), 9 cases

**WHAT WAS TESTED / HOW:**
| Case | Status | Evidence |
|------|--------|----------|
| WAL write-ahead recovers unrouted msg | PASS | MSG-only journal recovers via bare-queue materialization |
| ACK tombstone on replay | PASS | recovered=2, removed=1, survivor intact |
| REMOVE tombstone | PASS | tombstoned msg never resurrects |
| CRC corruption fails closed | PASS | flipped body byte → 0 records, complete=false, truncate |
| Framing corruption no fabrication | PASS | huge length prefix → 0 records, no crash |
| Multi-queue persistence | PASS | 2 durable + 1 non-durable; durable recovered, non-durable not materialized |
| I/O failure (pre-write) | PASS | raise propagates, writer not advanced, replay clean |
| I/O failure (partial write) | PASS | torn tail detected, good prefix survives, re-replay clean |
| Empty journal | PASS | 0 records, complete=true |
| sync equivalence | PASS | sync before replay == no-sync |

**KEY FINDINGS:**
- `RecoveryBuilder` retains a non-durable queue declare but `Router.recover()`
  does NOT materialize it — the durable filter is at recovery, not replay.
- Corruption is fail-closed: CRC mismatch and framing corruption both yield
  zero accepted records and a truncated tail, never fabricated state.
- Partial I/O writes are detected as torn tails and truncate back to the last
  good record — replay is idempotent after truncation.

**REGRESSION CHECK:**
- Full test suite: 52/0 PASS

**READY FOR NEXT MILESTONE?**
- YES
