# SIGKILL persistence test template (Phase 10).
#
# Tests persistence across a simulated crash (process exit without fsync).
# The WAL framing and recovery logic are validated without external signals.
#
# IMPORTANT: Actual SIGKILL cannot be sent from within a Mojo process.
# A real SIGKILL test requires external orchestration (Docker kill, shell
# script, or CI pipeline). See program-increments/v0.0.4/reports/
# SIGKILL_TEST_PLAN.md for the full external procedure.
#
# This file is a COMPILABLE TEMPLATE for the in-process portion of the
# SIGKILL resilience validation. It exercises the same recovery path that
# runs after an actual SIGKILL restart, proving the WAL semantics hold.
#
# Mojo `assert` is inert in this toolchain, so every check goes through
# `hyrx.testing.check`.

from std.collections import List

from hyrx.core.storage import (
    MessageJournal,
    RecoveryBuilder,
    RecoveredTopology,
    ParsedJournal,
    parse_journal,
)
from hyrx.testing import check


# ---- helpers ------------------------------------------------------------------

def recover_topo(var parsed: ParsedJournal) raises -> RecoveredTopology:
    """Fold one parsed journal through the RecoveryBuilder."""
    var b = RecoveryBuilder()
    b.apply(parsed^)
    return b.finalize()


# ---- 1. messages survive when sync_storage() was called ----------------------

def test_sync_before_crash() raises:
    """Messages survive a crash when sync_storage() was called.

    In the real broker, journal.sync() flushes the WAL to durable storage.
    After a SIGKILL + restart, recovery replays the synced WAL and recovers
    all synced records. This test proves the recovery path works by writing
    to a MemoryStorage journal (byte-identical framing) and replaying.
    """
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "persist-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(100):
        _ = journal.write_enqueue(
            "persist-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )

    # In real broker: journal.sync() would be called here before the crash.
    # MemoryStorage has no sync (it's RAM), but the framing is byte-identical.

    # Simulate restart: create a new journal from the same pages.
    var pages = journal.mem_pages()
    var fresh = MessageJournal.memory_from_bytes(pages^)
    var topo = recover_topo(fresh.replay())
    check(
        topo.recovered_messages == 100,
        "sigkill: all 100 messages survive a simulated crash",
    )


# ---- 2. unsync'd tail truncation (torn write) --------------------------------

def test_unsyncd_tail_truncation() raises:
    """A partial final record truncates to the last good record.

    This is the WAL's crash-recovery invariant: a torn write (crash between
    append start and completion) is detected by CRC mismatch and the file
    is truncated back to the last valid record. The truncated records are
    lost — this is the documented trade-off of no per-record fsync.

    Full coverage of this path is in:
      - tests/phase8/storage_test.mojo (test_crash_tail_recovery)
      - tests/phase10/persistence_crash_test.mojo (test_io_failure_*)
    """
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "tail-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(10):
        _ = journal.write_enqueue(
            "tail-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )

    # Append a torn partial record (3 bytes of a frame header, no body/crc)
    var pages = journal.mem_pages()
    pages.append(UInt8(0))
    pages.append(UInt8(0))
    pages.append(UInt8(0))

    var fresh = MessageJournal.memory_from_bytes(pages^)
    var p = fresh.replay()
    check(not p.complete, "sigkill: the torn tail is detected")
    check(
        len(p.records) == 11,
        "sigkill: 11 good records survive the torn tail",
    )

    # Recovery still works: 1 DECLARE + 10 MSG = 11 records, 10 messages
    var topo = recover_topo(p^)
    check(
        topo.recovered_messages == 10,
        "sigkill: all 10 messages recovered after tail truncation",
    )


# ---- 3. compaction after simulated crash recovery ----------------------------

def test_compaction_after_crash_recovery() raises:
    """After crash recovery, compaction strips tombstones from the WAL.

    In a real SIGKILL scenario, some messages may have been ACK'd before
    the crash. Recovery replays both the ACK and MSG records. Compaction
    then strips the resolved tombstones, reducing WAL size for the next run.
    """
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "postcrash-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(50):
        _ = journal.write_enqueue(
            "postcrash-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(25):
        _ = journal.write_ack(i + 1)

    # Simulate crash + restart
    var pages = journal.mem_pages()
    var fresh = MessageJournal.memory_from_bytes(pages^)

    # Recovery
    var topo = recover_topo(fresh.replay())
    check(
        topo.recovered_messages == 50,
        "sigkill+compact: 50 messages in pre-compaction WAL",
    )
    check(
        topo.removed_total == 25,
        "sigkill+compact: 25 ACK tombstones resolved",
    )

    # Compaction
    var before = len(fresh.mem_pages())
    var reclaimed = fresh.compact()
    check(reclaimed > 0, "sigkill+compact: compaction reclaims bytes")
    check(len(fresh.mem_pages()) < before, "sigkill+compact: WAL shrunk")

    # Post-compaction recovery
    var p2 = fresh.replay()
    var topo2 = recover_topo(p2^)
    check(
        topo2.recovered_messages == 25,
        "sigkill+compact: 25 live messages after compaction",
    )
    check(
        topo2.removed_total == 0,
        "sigkill+compact: no tombstones in compacted WAL",
    )


# ---- 4. write-ahead invariant under crash simulation -------------------------

def test_write_ahead_invariant() raises:
    """A MSG record recovers even when no queue was declared.

    The write-ahead invariant: journal-before-enqueue. A crash after the
    MSG write but before the queue receives the message still recovers
    the message (the RecoveryBuilder creates a bare queue from the MSG).
    """
    var journal = MessageJournal.memory()
    # MSG without a preceding DECLARE_QUEUE — the write-ahead case.
    _ = journal.write_enqueue(
        "wal-q", "wal-rk", UInt16(0x1000), List[UInt8](), List[UInt8](), 5
    )

    var pages = journal.mem_pages()
    var fresh = MessageJournal.memory_from_bytes(pages^)
    var topo = recover_topo(fresh.replay())
    check(
        topo.recovered_messages == 1,
        "sigkill(wal): the write-ahead MSG recovers without a declare",
    )


def main() raises:
    test_sync_before_crash()
    test_unsyncd_tail_truncation()
    test_compaction_after_crash_recovery()
    test_write_ahead_invariant()
    print("SIGKILL_TEST=PASS")
