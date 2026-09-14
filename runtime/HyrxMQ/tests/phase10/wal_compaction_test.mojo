# WAL compaction tests (milestone 0020).
#
# Verifies that compact() rebuilds the journal from only live records,
# reclaiming bytes from resolved tombstones, and is idempotent.
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


# ---- 1. compaction reclaims bytes from resolved tombstones --------------------

def test_compaction_reclaims_bytes() raises:
    """100 MSG + 50 ACK tombstones → compact strips tombstones and dead MSGs."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "comp-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(100):
        _ = journal.write_enqueue(
            "comp-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(50):
        _ = journal.write_ack(i + 1)  # seq 1..50 (seq 0 = DECLARE)

    var before = journal.mem_pages()
    var before_size = len(before)
    check(before_size > 0, "compaction: pre-compact WAL is non-empty")

    var reclaimed = journal.compact()
    check(reclaimed > 0, "compaction: positive bytes reclaimed")

    var after = journal.mem_pages()
    var after_size = len(after)
    check(after_size < before_size, "compaction: page size decreased")
    check(
        after_size + reclaimed == before_size,
        "compaction: reclaimed + after == before",
    )


# ---- 2. compaction preserves recovery semantics -------------------------------

def test_compaction_preserves_recovery() raises:
    """After compaction, recovery still produces the correct live set."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "recov-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(100):
        _ = journal.write_enqueue(
            "recov-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(50):
        _ = journal.write_ack(i + 1)  # ack first 50 messages

    _ = journal.compact()

    var recovered = journal.replay()
    var builder = RecoveryBuilder()
    builder.apply(recovered^)
    var topo = builder.finalize()
    check(topo.recovered_messages == 50, "compaction: 50 live messages remain")
    check(topo.removed_total == 0, "compaction: no tombstones in compacted WAL")


# ---- 3. compaction is idempotent ---------------------------------------------

def test_compaction_idempotent() raises:
    """Second compact() reclaims 0 bytes and produces identical page size."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "idem-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(100):
        _ = journal.write_enqueue(
            "idem-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(50):
        _ = journal.write_ack(i + 1)

    _ = journal.compact()
    var after_first = journal.mem_pages()
    var size_first = len(after_first)

    var reclaimed2 = journal.compact()
    var after_second = journal.mem_pages()
    var size_second = len(after_second)

    check(reclaimed2 == 0, "compaction: second call reclaims 0 bytes")
    check(
        size_second == size_first,
        "compaction: page size unchanged after idempotent call",
    )


# ---- 4. empty journal is a no-op ---------------------------------------------

def test_compaction_empty_journal() raises:
    """Compaction on an empty WAL is a no-op (returns 0)."""
    var journal = MessageJournal.memory()
    var reclaimed = journal.compact()
    check(reclaimed == 0, "compaction: empty WAL returns 0")
    var pages = journal.mem_pages()
    check(len(pages) == 0, "compaction: empty WAL stays empty")


# ---- 5. topology-only compaction preserves declarations -----------------------

def test_compaction_topology_only() raises:
    """Compaction on topology-only WAL preserves declarations."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "topo-q", True, 32, 100, 5, True, "dlx-e", "dlrk"
    )
    _ = journal.write_exchange_declare("topo-ex", 1)
    _ = journal.write_bind("topo-ex", "topo-q", "rk1", False)

    var reclaimed = journal.compact()
    check(reclaimed == 0, "compaction: topology-only reclaims 0")

    var recovered = journal.replay()
    var builder = RecoveryBuilder()
    builder.apply(recovered^)
    var topo = builder.finalize()
    check(len(topo.queues) == 1, "compaction: topology-only preserves queue")
    check(len(topo.exchanges) == 1, "compaction: topology-only preserves exchange")
    check(len(topo.bindings) == 1, "compaction: topology-only preserves binding")
    check(topo.queues[0].dlx == "dlx-e", "compaction: queue dlx preserved")
    check(topo.queues[0].dlrk == "dlrk", "compaction: queue dlrk preserved")


# ---- 6. all messages ACK'd → topology-only compacted WAL ----------------------

def test_compaction_all_ackd() raises:
    """When all messages are ACK'd, compact WAL has only topology records."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "allack-q", True, 100, 0, 0, False, String(""), String("")
    )
    for i in range(10):
        _ = journal.write_enqueue(
            "allack-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(10):
        _ = journal.write_ack(i + 1)  # ack all 10 messages

    var reclaimed = journal.compact()
    check(reclaimed > 0, "compaction(all-ackd): bytes reclaimed")

    var recovered = journal.replay()
    var builder = RecoveryBuilder()
    builder.apply(recovered^)
    var topo = builder.finalize()
    check(
        topo.recovered_messages == 0,
        "compaction(all-ackd): no MSG records in compacted WAL",
    )
    check(
        topo.removed_total == 0,
        "compaction(all-ackd): no tombstones remain",
    )


# ---- 7. mixed tombstone types ------------------------------------------------

def test_compaction_mixed_tombstones() raises:
    """ACK + REMOVE + REDELIVER tombstones all stripped by compaction."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "mix-q", True, 100, 0, 0, False, String(""), String("")
    )
    # seq 1 = first MSG, seq 2 = second, seq 3 = third, seq 4 = fourth
    _ = journal.write_enqueue("mix-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), 10)
    _ = journal.write_enqueue("mix-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), 20)
    _ = journal.write_enqueue("mix-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), 30)
    _ = journal.write_enqueue("mix-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), 40)
    _ = journal.write_ack(1)       # seq 1: ACK
    _ = journal.write_redeliver(2)  # seq 2: REDELIVER (bumps but stays live)
    _ = journal.write_remove(3)     # seq 3: REMOVE

    var before = len(journal.mem_pages())
    _ = journal.compact()
    var after = len(journal.mem_pages())
    check(after < before, "compaction(mixed): size decreased")

    var recovered = journal.replay()
    var builder = RecoveryBuilder()
    builder.apply(recovered^)
    var topo = builder.finalize()
    # seq 0 = DECLARE, seq 1..4 = MSG, seq 5..7 = tombstones
    # After replay: seq 1 removed (ACK), seq 2 bumped (REDELIVER), seq 3 removed (REMOVE)
    # Live: seq 2 and seq 4 → 2 messages
    check(
        topo.recovered_messages == 2,
        "compaction(mixed): 2 MSG records in compacted WAL",
    )
    check(
        topo.removed_total == 0,
        "compaction(mixed): no tombstones in compacted WAL",
    )
    # The live set after recovery of the compacted WAL: msgs from stamp 20 and 40
    var qi = -1
    for i in range(len(topo.queues)):
        if topo.queues[i].name == "mix-q":
            qi = i
    check(qi >= 0, "compaction(mixed): queue present")
    check(
        len(topo.queues[qi].msgs) == 2,
        "compaction(mixed): 2 live messages remain",
    )


# ---- 8. compacted WAL is self-consistent across repeated compactions ----------

def test_compaction_deep_idempotency() raises:
    """Four successive compactions all return 0 after the first."""
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "deep-q", True, 50, 0, 0, False, String(""), String("")
    )
    for i in range(50):
        _ = journal.write_enqueue(
            "deep-q", "rk", UInt16(0), List[UInt8](), List[UInt8](), i
        )
    for i in range(25):
        _ = journal.write_ack(i + 1)

    var first = journal.compact()
    check(first > 0, "compaction(deep): first call reclaims bytes")

    var size_after_first = len(journal.mem_pages())
    for round in range(4):
        var r = journal.compact()
        check(r == 0, "compaction(deep): round " + String(round + 2) + " reclaims 0")
        check(
            len(journal.mem_pages()) == size_after_first,
            "compaction(deep): size stable on round " + String(round + 2),
        )


def main() raises:
    test_compaction_reclaims_bytes()
    test_compaction_preserves_recovery()
    test_compaction_idempotent()
    test_compaction_empty_journal()
    test_compaction_topology_only()
    test_compaction_all_ackd()
    test_compaction_mixed_tombstones()
    test_compaction_deep_idempotency()
    print("WAL_COMPACTION_TEST=PASS")
