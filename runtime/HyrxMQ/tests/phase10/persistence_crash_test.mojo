# Phase 10 — persistence crash / corruption / multi-queue / I/O-failure tests.
#
# Extends the 0018 storage coverage (tests/phase8/storage_test.mojo) with the
# failure-mode matrix the WAL semantics rest on:
#   1. write-ahead: a MSG record recovers even when no queue received it;
#   2. ACK tombstone: one resolved ordinal drops, the rest survive;
#   3. REMOVE tombstone: an expiry/dead-letter outcome never resurrects;
#   4. CRC corruption: a flipped body byte fails closed (no silent accept);
#   5. framing corruption: a bogus length prefix yields no fabricated records;
#   6. multi-queue: N durable declares + bindings + per-queue counts recover,
#      a NON-durable declare is retained by the builder but NEVER materialized
#      by Router.recover (the real contract, verified by reading the code);
#   7. I/O failure: FileStorage drives a FailingOps whose append raises; the
#      raise propagates and no partial/corrupt state is silently accepted;
#   8. empty journal: zero records and complete == True.
#
# Mojo `assert` is inert in this toolchain, so every check goes through
# `hyrx.testing.check` (a raise-based failure).

from std.collections import List

from hyrx.core.router import Router
from hyrx.core.storage import (
    FileSystemOps,
    FileStorage,
    MemoryStorage,
    MessageJournal,
    ParsedJournal,
    RecoveredTopology,
    RecoveryBuilder,
    parse_journal,
)
from hyrx.testing import check


# ---- local helpers -----------------------------------------------------------

def fake_body(flag: Int) -> List[UInt8]:
    """A deterministic payload byte pattern (byte-faithful checks)."""
    var b = List[UInt8]()
    b.append(UInt8(flag * 17 + 3))
    b.append(UInt8(0xFE))
    if flag % 2 == 0:
        b.append(UInt8(flag))
    return b^


def bytes_eq(a: List[UInt8], b: List[UInt8]) -> Bool:
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def queue_idx(ref topo: RecoveredTopology, name: String) -> Int:
    """Index of a recovered queue by name, or -1."""
    for i in range(len(topo.queues)):
        if topo.queues[i].name == name:
            return i
    return -1


def recover_topo(var parsed: ParsedJournal) raises -> RecoveredTopology:
    """Fold one parsed journal through the RecoveryBuilder."""
    var b = RecoveryBuilder()
    b.apply(parsed^)
    return b.finalize()


# ---- the redirectable working filesystem (all bytes land in RAM) -------------

struct FakeOps(Movable, Deinitable, FileSystemOps):
    var pages: List[UInt8]
    var opens: Int
    var appends: Int
    var syncs: Int
    var truncates: Int

    def __init__(out self):
        self.pages = List[UInt8]()
        self.opens = 0
        self.appends = 0
        self.syncs = 0
        self.truncates = 0

    def read_all(mut self, var path: String) raises -> List[UInt8]:
        return self.pages.copy()

    def exists(mut self, var path: String) -> Bool:
        return len(self.pages) > 0

    def open_append(mut self, var path: String) raises -> Int:
        self.opens += 1
        return 7  # the opaque fake handle

    def append(mut self, handle: Int, var data: List[UInt8]) raises:
        self.appends += 1
        for i in range(len(data)):
            self.pages.append(data[i])

    def sync(mut self, handle: Int) raises:
        self.syncs += 1

    def truncate(mut self, handle: Int, length: Int) raises:
        self.truncates += 1
        while len(self.pages) > length:
            _ = self.pages.pop()

    def close(mut self, handle: Int):
        pass


# ---- the failing filesystem (append raises; optional torn half-write) --------

struct FailingOps(Movable, Deinitable, FileSystemOps):
    var pages: List[UInt8]
    var appends: Int
    var truncates: Int
    var fail_at: Int  # the 1-based append ordinal that raises (-1 = never)
    var partial: Bool  # when true, write HALF the bytes before raising

    def __init__(out self, fail_at: Int, partial: Bool):
        self.pages = List[UInt8]()
        self.appends = 0
        self.truncates = 0
        self.fail_at = fail_at
        self.partial = partial

    def read_all(mut self, var path: String) raises -> List[UInt8]:
        return self.pages.copy()

    def exists(mut self, var path: String) -> Bool:
        return len(self.pages) > 0

    def open_append(mut self, var path: String) raises -> Int:
        return 7

    def append(mut self, handle: Int, var data: List[UInt8]) raises:
        self.appends += 1
        if self.fail_at >= 0 and self.appends >= self.fail_at:
            if self.partial:
                var half = len(data) // 2
                for i in range(half):
                    self.pages.append(data[i])
            raise "simulated io failure on append"
        for i in range(len(data)):
            self.pages.append(data[i])

    def sync(mut self, handle: Int) raises:
        pass

    def truncate(mut self, handle: Int, length: Int) raises:
        self.truncates += 1
        while len(self.pages) > length:
            _ = self.pages.pop()

    def close(mut self, handle: Int):
        pass


# ---- 1. write-ahead: MSG recovers with no queue receiving it -----------------

def test_write_ahead_recovers_unrouted_msg() raises:
    var j1 = MessageJournal.memory()
    _ = j1.write_enqueue(
        "wal-q", "wal-rk", UInt16(0x1000), List[UInt8](), fake_body(1), 5
    )
    # The message was NEVER given to a live Queue — only the journal knows it.
    var j2 = MessageJournal.memory_from_bytes(j1.mem_pages())
    var topo = recover_topo(j2.replay())
    check(topo.recovered_messages == 1, "wal: the write-ahead MSG recovers")
    var qi = queue_idx(topo, "wal-q")
    check(qi >= 0, "wal: the bare queue is materialized from the MSG record")
    check(len(topo.queues[qi].msgs) == 1, "wal: exactly one live message")
    check(
        bytes_eq(topo.queues[qi].msgs[0].payload, fake_body(1)),
        "wal: the recovered payload is byte-exact",
    )
    check(
        topo.queues[qi].msgs[0].routing_key == "wal-rk",
        "wal: the recovered routing key rides",
    )


# ---- 2. ACK tombstone: one ordinal drops, the other survives -----------------

def test_ack_tombstone_on_replay() raises:
    var j = MessageJournal.memory()
    var s0 = j.write_enqueue(
        "ack-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(1), 10
    )
    var s1 = j.write_enqueue(
        "ack-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(2), 11
    )
    check(s0 == 0, "ack: the first message ordinal is 0")
    check(s1 == 1, "ack: the second message ordinal is 1")

    var jbase = MessageJournal.memory_from_bytes(j.mem_pages())
    var base = recover_topo(jbase.replay())
    check(base.recovered_messages == 2, "ack: baseline has both MSG records")
    var bqi = queue_idx(base, "ack-q")
    check(len(base.queues[bqi].msgs) == 2, "ack: baseline live set is 2")

    var j2 = MessageJournal.memory_from_bytes(j.mem_pages())
    _ = j2.write_ack(s0)
    var after = recover_topo(j2.replay())
    check(after.recovered_messages == 2, "ack: both MSG records still replay")
    check(after.removed_total == 1, "ack: the ACK resolves exactly one")
    var qi = queue_idx(after, "ack-q")
    check(len(after.queues[qi].msgs) == 1, "ack: one message dropped")
    check(
        bytes_eq(after.queues[qi].msgs[0].payload, fake_body(2)),
        "ack: the SECOND message survives",
    )


# ---- 3. REMOVE tombstone never resurrects ------------------------------------

def test_remove_tombstone_on_replay() raises:
    var j = MessageJournal.memory()
    var s = j.write_enqueue(
        "rm-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(7), 1
    )
    var j2 = MessageJournal.memory_from_bytes(j.mem_pages())
    _ = j2.write_remove(s)
    var topo = recover_topo(j2.replay())
    check(topo.recovered_messages == 1, "remove: the MSG record replays")
    check(topo.removed_total == 1, "remove: the REMOVE tombstone resolves")
    var qi = queue_idx(topo, "rm-q")
    check(qi >= 0, "remove: the queue is present")
    check(len(topo.queues[qi].msgs) == 0, "remove: it never resurrects")


# ---- 4. CRC corruption fails closed ------------------------------------------

def test_crc_corruption_fails_closed() raises:
    var j = MessageJournal.memory()
    _ = j.write_enqueue(
        "crc-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(1), 1
    )
    _ = j.write_enqueue(
        "crc-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(2), 2
    )
    _ = j.write_enqueue(
        "crc-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(3), 3
    )
    var good = j.mem_pages()
    var baseline = parse_journal(good)
    check(len(baseline.records) == 3, "crc: the clean journal has 3 records")
    check(baseline.complete, "crc: the clean journal is complete")

    # frame = [u32 total_len][u16 type][body][u32 crc]; body starts at offset 6.
    var corrupted = good.copy()
    corrupted[6] = UInt8((Int(corrupted[6]) + 1) & 0xFF)
    var p = parse_journal(corrupted)
    check(len(p.records) == 0, "crc: the corrupt first record is rejected")
    check(not p.complete, "crc: the CRC mismatch ends the replay")
    check(p.good_end == 0, "crc: the good prefix stops before the bad record")

    # a fresh storage replay must also fail closed and drop the bad tail
    var j2 = MessageJournal.memory_from_bytes(corrupted^)
    var p2 = j2.replay()
    check(len(p2.records) == 0, "crc: the storage replay rejects it too")
    check(not p2.complete, "crc: the storage replay is incomplete")
    check(len(j2.mem_pages()) == 0, "crc: the corrupt tail is truncated away")


# ---- 5. framing corruption yields no fabricated records ----------------------

def test_framing_corruption_no_fabrication() raises:
    var j = MessageJournal.memory()
    _ = j.write_enqueue(
        "frm-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(1), 1
    )
    _ = j.write_enqueue(
        "frm-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(2), 2
    )
    var good = j.mem_pages()

    var corrupted = good.copy()
    corrupted[0] = UInt8(0xFF)  # huge length prefix
    corrupted[1] = UInt8(0xFF)
    corrupted[2] = UInt8(0xFF)
    corrupted[3] = UInt8(0xFF)
    var p = parse_journal(corrupted)
    check(len(p.records) == 0, "framing: no records fabricated")
    check(not p.complete, "framing: the bogus prefix ends the replay")
    check(p.good_end == 0, "framing: the good prefix is empty")

    var j2 = MessageJournal.memory_from_bytes(corrupted^)
    var p2 = j2.replay()
    check(len(p2.records) == 0, "framing: the storage replay fabricates nothing")
    check(not p2.complete, "framing: the storage replay is incomplete")


# ---- 6. multi-queue + non-durable contract -----------------------------------

def test_multi_queue_and_non_durable() raises:
    var j = MessageJournal.memory()
    _ = j.write_queue_declare("mq-1", True, 16, 0, 0, False, "d", "k")
    _ = j.write_queue_declare("mq-2", True, 32, 0, 0, False, String(""), String(""))
    _ = j.write_queue_declare("mq-3", False, 8, 0, 0, False, String(""), String(""))
    _ = j.write_exchange_declare("mq-ex", 1)
    _ = j.write_bind("mq-ex", "mq-1", "r1", False)
    _ = j.write_bind("mq-ex", "mq-2", "r2", False)
    _ = j.write_enqueue("mq-1", "r1", UInt16(0x1000), List[UInt8](), fake_body(1), 1)
    _ = j.write_enqueue("mq-1", "r1", UInt16(0x1000), List[UInt8](), fake_body(2), 2)
    _ = j.write_enqueue("mq-2", "r2", UInt16(0x1000), List[UInt8](), fake_body(3), 3)

    var pages = j.mem_pages()
    var topo = recover_topo(parse_journal(pages))
    check(topo.recovered_messages == 3, "multi: three messages recover")
    check(len(topo.bindings) == 2, "multi: two bindings recover")
    check(len(topo.exchanges) >= 1, "multi: the exchange recovers")

    var i1 = queue_idx(topo, "mq-1")
    var i2 = queue_idx(topo, "mq-2")
    var i3 = queue_idx(topo, "mq-3")
    check(i1 >= 0, "multi: mq-1 recovered")
    check(i2 >= 0, "multi: mq-2 recovered")
    check(topo.queues[i1].durable and topo.queues[i2].durable, "multi: both durable")
    check(len(topo.queues[i1].msgs) == 2, "multi: mq-1 has 2 messages")
    check(len(topo.queues[i2].msgs) == 1, "multi: mq-2 has 1 message")

    # REAL CONTRACT: RecoveryBuilder keeps the non-durable declare (it is a
    # topology record); Router.recover materializes DURABLE queues only.
    check(i3 >= 0, "multi: the builder retains the non-durable declare")
    check(not topo.queues[i3].durable, "multi: mq-3 is marked non-durable")

    var r = Router(4096, 64, False)
    r.attach_journal(MessageJournal.memory_from_bytes(j.mem_pages()))
    var recovered = r.recover()
    check(recovered == 3, "multi(router): three messages recovered")
    check(r.has_queue("mq-1"), "multi(router): mq-1 materialized")
    check(r.has_queue("mq-2"), "multi(router): mq-2 materialized")
    check(
        not r.has_queue("mq-3"),
        "multi(router): the non-durable queue is NOT materialized",
    )
    check(r.queue_depth("mq-1") == 2, "multi(router): mq-1 depth is 2")
    check(r.queue_depth("mq-2") == 1, "multi(router): mq-2 depth is 1")


# ---- 7. I/O failure injection ------------------------------------------------

def test_io_failure_clean_raise() raises:
    var ops = FailingOps(2, False)
    var wal = FileStorage[FailingOps](ops^, "fail://clean")
    _ = wal.write_bytes(UInt16(6), fake_body(1))
    check(wal._ops.appends == 1, "io-failure: the first append lands")

    var raised = False
    try:
        _ = wal.write_bytes(UInt16(6), fake_body(2))
    except:
        raised = True
    check(raised, "io-failure: the append raise propagates")
    check(
        wal.records_written() == 1,
        "io-failure: the failed append did not advance the writer",
    )
    var p = wal.replay()
    check(p.complete, "io-failure: no partial state silently accepted")
    check(len(p.records) == 1, "io-failure: exactly the first record replays")
    check(p.records[0].rtype == 6, "io-failure: the good record type round-trips")
    check(
        bytes_eq(p.records[0].body, fake_body(1)),
        "io-failure: the good record body round-trips",
    )


def test_io_failure_partial_write_detected() raises:
    var ops = FailingOps(2, True)
    var wal = FileStorage[FailingOps](ops^, "fail://partial")
    _ = wal.write_bytes(UInt16(6), fake_body(1))

    var raised = False
    try:
        _ = wal.write_bytes(UInt16(6), fake_body(2))
    except:
        raised = True
    check(raised, "io-failure(partial): the raise propagates")
    var p = wal.replay()
    check(not p.complete, "io-failure(partial): the torn tail is detected")
    check(len(p.records) == 1, "io-failure(partial): the good prefix survives")
    check(
        wal._ops.truncates == 1,
        "io-failure(partial): the torn tail is cut back through ops",
    )
    var p2 = wal.replay()
    check(p2.complete, "io-failure(partial): the replay after truncate is clean")
    check(len(p2.records) == 1, "io-failure(partial): still one good record")


# ---- 8. empty journal --------------------------------------------------------

def test_empty_journal() raises:
    var ms = MemoryStorage()
    var p = ms.replay()
    check(len(p.records) == 0, "empty: the memory WAL has zero records")
    check(p.complete, "empty: the memory WAL replay is complete")

    var empty_pages = List[UInt8]()
    var p2 = parse_journal(empty_pages)
    check(len(p2.records) == 0, "empty: parsing zero pages yields zero records")
    check(p2.complete, "empty: parsing zero pages is complete")

    var fs = FileStorage[FakeOps](FakeOps(), "empty://x")
    var p3 = fs.replay()
    check(len(p3.records) == 0, "empty: a missing file yields zero records")
    check(p3.complete, "empty: a missing file replay is complete")


# ---- extra: sync() does not change the recovered state -----------------------

def test_sync_equivalence() raises:
    var ops_a = FakeOps()
    var wa = FileStorage[FakeOps](ops_a^, "sync://a")
    _ = wa.write_enqueue("sq", "rk", UInt16(0x1000), List[UInt8](), fake_body(5), 9)
    _ = wa.write_ack(0)
    var pa = wa.replay()

    var ops_b = FakeOps()
    var wb = FileStorage[FakeOps](ops_b^, "sync://b")
    _ = wb.write_enqueue("sq", "rk", UInt16(0x1000), List[UInt8](), fake_body(5), 9)
    _ = wb.write_ack(0)
    wb.sync()
    var pb = wb.replay()

    check(wb._ops.syncs == 1, "sync: the explicit sync flushed through ops")
    check(len(pa.records) == len(pb.records), "sync: record counts match")
    check(pa.complete and pb.complete, "sync: both replays are complete")
    check(
        bytes_eq(wa._ops.pages, wb._ops.pages),
        "sync: the journal bytes are identical with/without sync",
    )
    var ta = recover_topo(pa^)
    var tb = recover_topo(pb^)
    check(
        ta.recovered_messages == tb.recovered_messages,
        "sync: the recovered message count is identical",
    )
    check(
        ta.removed_total == tb.removed_total,
        "sync: the resolved tombstone count is identical",
    )


def main() raises:
    test_write_ahead_recovers_unrouted_msg()
    test_ack_tombstone_on_replay()
    test_remove_tombstone_on_replay()
    test_crc_corruption_fails_closed()
    test_framing_corruption_no_fabrication()
    test_multi_queue_and_non_durable()
    test_io_failure_clean_raise()
    test_io_failure_partial_write_detected()
    test_empty_journal()
    test_sync_equivalence()
    print("PERSISTENCE_CRASH_TEST=PASS")
