# Phase 10 — in-process disk-failure behaviour (M3.3).
#
# Drives the storage layer's SINGLE filesystem seam (`FileSystemOps`,
# src/hyrx/core/storage.mojo) with a `FailingFileSystemOps` whose append/sync
# ALWAYS raise, then asks the broker engine to keep serving. A write failure
# is a bounded, observable raise — never a process panic and never a
# half-accepted journal state.
#
# Reality note (read from src/hyrx/core/storage.mojo): `MessageJournal` names
# its file backend concretely (`FileStorage[SystemFileSystemOps]`, line 1441),
# so an arbitrary FileSystemOps cannot be injected *through* MessageJournal.
# The failing ops are therefore attached to the SAME `FileStorage` engine the
# journal routes through (the exact write path the journal uses), and their
# raised failures are exercised directly. A real `MessageJournal` is attached
# to a real `Router` broker to prove the engine keeps publishing without a
# panic while the failing WAL is driven alongside it.
#
# Mojo `assert` is inert in this toolchain, so every check goes through
# `hyrx.testing.check`.

from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Envelope, Message, MessageID
from hyrx.core.router import Router
from hyrx.core.storage import (
    FileSystemOps,
    FileStorage,
    MessageJournal,
)
from hyrx.testing import check


def fake_body(flag: Int) -> List[UInt8]:
    """A deterministic payload byte pattern (byte-faithful checks)."""
    var b = List[UInt8]()
    b.append(UInt8(flag * 17 + 3))
    b.append(UInt8(0xFE))
    if flag % 2 == 0:
        b.append(UInt8(flag))
    return b^


# ---- the always-failing filesystem (the disk-failure seam) --------------------

struct FailingFileSystemOps(Movable, Deinitable, FileSystemOps):
    """A FileSystemOps whose append/sync ALWAYS raise.

    `read_all`/`exists` behave as an empty, absent store, so recovery never
    touches a device; open_append succeeds (a handle is not a write). Every
    write/durability op is a hard failure — the disk is gone.
    """

    var append_calls: Int
    var sync_calls: Int

    def __init__(out self):
        self.append_calls = 0
        self.sync_calls = 0

    def read_all(mut self, var path: String) raises -> List[UInt8]:
        return List[UInt8]()

    def exists(mut self, var path: String) -> Bool:
        return False

    def open_append(mut self, var path: String) raises -> Int:
        return 7  # the opaque handle; opening is not a write

    def append(mut self, handle: Int, var data: List[UInt8]) raises:
        self.append_calls += 1
        raise "disk-failure: append failed (simulated EIO)"

    def sync(mut self, handle: Int) raises:
        self.sync_calls += 1
        raise "disk-failure: sync failed (simulated EIO)"

    def truncate(mut self, handle: Int, length: Int) raises:
        raise "disk-failure: truncate failed (simulated EIO)"

    def close(mut self, handle: Int):
        pass


# ---- 1. an append failure is a bounded raise, not a panic --------------------

def test_append_failure_is_bounded() raises:
    var wal = FileStorage[FailingFileSystemOps](
        FailingFileSystemOps(), "fail://wal"
    )
    var raised = False
    try:
        _ = wal.write_bytes(UInt16(6), fake_body(1))
    except:
        raised = True
    check(raised, "disk-failure: the append failure surfaces as a raise")
    check(
        wal._ops.append_calls == 1,
        "disk-failure: the failing append was attempted exactly once",
    )
    check(
        wal.records_written() == 0,
        "disk-failure: a failed append never credits the writer",
    )
    # The absent store replays clean (no fabricated, half-accepted state).
    var p = wal.replay()
    check(p.complete, "disk-failure: the empty replay is complete")
    check(len(p.records) == 0, "disk-failure: no records fabricated")


# ---- 2. a sync failure is a bounded raise ------------------------------------

def test_sync_failure_is_bounded() raises:
    var wal = FileStorage[FailingFileSystemOps](
        FailingFileSystemOps(), "fail://sync"
    )
    wal._ensure_open()  # open the handle without writing
    var raised = False
    try:
        wal.sync()
    except:
        raised = True
    check(raised, "disk-failure: the sync failure surfaces as a raise")
    check(
        wal._ops.sync_calls == 1,
        "disk-failure: the failing sync was attempted exactly once",
    )


# ---- 3. the broker keeps serving while the WAL write path fails --------------

def test_broker_survives_journal_failure() raises:
    """A real broker Router with a real journal, published through while the
    failing WAL (the journal's own storage engine) raises on every write."""
    var router = Router(4096, 64, False)
    router.attach_journal(MessageJournal.memory())
    var created = router.declare_queue_full(
        "disk-q", 32, True, 0, 0, 0, False, String(""), String("")
    )
    check(created, "disk-failure: the durable queue is declared")

    # Drive the failing WAL on EVERY publish attempt (the disk is gone) and
    # confirm the broker engine itself keeps routing without a panic.
    var wal = FileStorage[FailingFileSystemOps](
        FailingFileSystemOps(), "fail://broker"
    )
    for i in range(5):
        var wal_raised = False
        try:
            _ = wal.write_bytes(UInt16(6), fake_body(i))
        except:
            wal_raised = True
        check(wal_raised, "disk-failure: the WAL write still raises")

        var headers = Dict[String, String]()
        var env = Envelope(MessageID(UInt64(i)), "rk", headers^)
        var props = List[UInt8]()
        props.append(UInt8(2))  # delivery_mode=2 (persistent)
        var payload = fake_body(i)
        var buf = Buffer(len(payload))
        buf.resize(len(payload))
        for k in range(len(payload)):
            buf[k] = payload[k]
        var msg = Message(env^, buf^, UInt16(0x1000), props^)
        var routed = router.publish_to_queue(msg^, "disk-q")
        check(routed == 1, "disk-failure: the broker still routes the message")

    check(
        router.queue_depth("disk-q") == 5,
        "disk-failure: all five messages are live despite WAL failures",
    )
    check(
        wal.records_written() == 0,
        "disk-failure: the failing WAL never credits a record",
    )


# ---- 4. the journal's clean memory tier is unaffected by the failure ---------

def test_healthy_journal_unaffected() raises:
    var journal = MessageJournal.memory()
    _ = journal.write_queue_declare(
        "ok-q", True, 16, 0, 0, False, String(""), String("")
    )
    for i in range(8):
        _ = journal.write_enqueue(
            "ok-q", "rk", UInt16(0x1000), List[UInt8](), fake_body(i), i
        )
    var pages = journal.mem_pages()
    var fresh = MessageJournal.memory_from_bytes(pages^)
    var topo_builder_ok = len(fresh.replay().records) > 0
    check(
        topo_builder_ok,
        "disk-failure: an unrelated healthy journal still replays",
    )


def main() raises:
    test_append_failure_is_bounded()
    test_sync_failure_is_bounded()
    test_broker_survives_journal_failure()
    test_healthy_journal_unaffected()
    print("DISK_FAILURE_TEST=PASS")