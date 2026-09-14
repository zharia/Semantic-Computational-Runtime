# Phase 10 — WAL hardening tests (corruption / truncation / empty / missing).
#
# The journal framing (src/hyrx/core/storage.mojo) is fail-closed: a torn tail
# or a CRC mismatch ends the replay at `good_end`; records BEFORE the bad
# record survive. These tests pin that contract against byte-level damage.
#
# Scenarios:
#   1. corrupted record   — flip a mid-journal byte; the live prefix survives,
#                           the tail is bounded, no crash.
#   2. truncated record   — a valid journal cut mid-record parses gracefully.
#   3. empty journal      — zero bytes -> zero records, complete == True.
#   4. missing segment    — FileSystemOps at a nonexistent path -> 0 records,
#                           complete == True, no crash.
#   5. compaction idem    — compact() twice -> identical size.
#
# Mojo `assert` is inert in this toolchain, so every check goes through
# `hyrx.testing.check` (a raise-based failure).

from std.collections import List

from hyrx.core.storage import (
    FileStorage,
    MessageJournal,
    ParsedJournal,
    RecoveredTopology,
    RecoveryBuilder,
    SystemFileSystemOps,
    parse_journal,
)
from hyrx.testing import check


# ---- helpers ------------------------------------------------------------------

def build_valid_journal(msgs: Int) raises -> List[UInt8]:
    """A valid RAM WAL: DECLARE_QUEUE + `msgs` MSG records."""
    var j = MessageJournal.memory()
    _ = j.write_queue_declare(
        "hq", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(msgs):
        var payload = List[UInt8]()
        payload.append(UInt8(0x40 + i))
        _ = j.write_enqueue("hq", "rk", UInt16(0), List[UInt8](), payload^, i)
    return j.mem_pages()


def prefix_of(ref src: List[UInt8], length: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(length):
        out.append(src[i])
    return out^


def recover_topo(var parsed: ParsedJournal) raises -> RecoveredTopology:
    var b = RecoveryBuilder()
    b.apply(parsed^)
    return b.finalize()


# ---- 1. corrupted record: live prefix survives, tail bounded ------------------

def test_corrupted_record() raises:
    var pages = build_valid_journal(5)
    var n = len(pages)
    check(n > 0, "corrupt: built journal is non-empty")

    # Flip one byte near the middle: the record it lands in fails CRC.
    var mid = n // 2
    pages[mid] = pages[mid] ^ 0xFF

    var parsed = parse_journal(pages)
    check(not parsed.complete, "corrupt: parse flagged incomplete (fail-closed)")
    check(parsed.good_end <= n, "corrupt: good_end within the journal")
    check(len(parsed.records) >= 1, "corrupt: live records before corruption survive")
    for i in range(len(parsed.records)):
        check(
            parsed.records[i].seq == UInt64(i),
            "corrupt: surviving prefix seq is contiguous",
        )

    # The good prefix must itself reparse as a COMPLETE journal.
    var live = len(parsed.records)
    var prefix = prefix_of(pages, parsed.good_end)
    var reparse = parse_journal(prefix)
    check(reparse.complete, "corrupt: good_end prefix reparses complete")
    check(
        len(reparse.records) == live,
        "corrupt: good_end prefix holds the same live records",
    )

    var topo = recover_topo(parsed^)
    check(
        topo.recovered_messages <= live,
        "corrupt: recovery never fabricates records",
    )


# ---- 2. truncated record: mid-record cut parses gracefully --------------------

def test_truncated_record() raises:
    var pages = build_valid_journal(5)
    var cut = len(pages) - 3  # cut inside the final record
    check(cut > 0, "truncate: journal longer than the cut")

    var truncated = prefix_of(pages, cut)
    var parsed = parse_journal(truncated)
    check(not parsed.complete, "truncate: incomplete tail detected")
    check(parsed.good_end <= cut, "truncate: good_end bounded by the cut")
    check(len(parsed.records) >= 1, "truncate: earlier records survive")

    var live = len(parsed.records)
    var prefix = prefix_of(truncated, parsed.good_end)
    var reparse = parse_journal(prefix)
    check(reparse.complete, "truncate: good_end prefix reparses complete")
    check(
        len(reparse.records) == live,
        "truncate: no record lost between parse and reparse",
    )


# ---- 3. empty journal: zero bytes, complete -----------------------------------

def test_empty_journal() raises:
    var empty = List[UInt8]()
    var parsed = parse_journal(empty)
    check(len(parsed.records) == 0, "empty: zero records")
    check(parsed.complete, "empty: complete == True")
    check(parsed.good_end == 0, "empty: good_end == 0")


# ---- 4. missing segment: nonexistent path, no crash ---------------------------

def test_missing_segment() raises:
    # A path that is not created by this test. A stale file would only make
    # the assertions weaker (a non-empty journal), so we also assert the
    # expected EMPTY recovery directly.
    var ops = SystemFileSystemOps()
    var missing = String("/tmp/hyrx_wal_missing_segment_2f8c1a.wal")
    var storage = FileStorage[SystemFileSystemOps](ops^, missing^)

    var parsed = storage.replay()
    check(len(parsed.records) == 0, "missing: no records recovered")
    check(parsed.complete, "missing: complete == True")
    check(storage.records_written() == 0, "missing: records_written == 0")

    var topo = recover_topo(parsed^)
    check(topo.recovered_messages == 0, "missing: zero recovered messages")


# ---- 5. compaction idempotency: second compact is a no-op ---------------------

def test_compaction_idempotency() raises:
    var j = MessageJournal.memory()
    _ = j.write_queue_declare(
        "idem-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(20):
        _ = j.write_enqueue(
            "idem-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(10):
        _ = j.write_ack(i + 1)

    _ = j.compact()
    var size_first = len(j.mem_pages())

    var reclaimed2 = j.compact()
    var size_second = len(j.mem_pages())

    check(reclaimed2 == 0, "idem: second compact reclaims 0 bytes")
    check(size_second == size_first, "idem: size unchanged after second compact")


def main() raises:
    test_corrupted_record()
    test_truncated_record()
    test_empty_journal()
    test_missing_segment()
    test_compaction_idempotency()
    print("WAL_HARDENING_TEST=PASS")
