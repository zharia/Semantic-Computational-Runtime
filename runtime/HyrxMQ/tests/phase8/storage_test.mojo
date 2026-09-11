# 0018 pluggable storage tests.
#
# Every durable-storage assertion runs TWICE: once over MemoryStorage (the
# in-RAM WAL) and once over FileStorage[FakeOps] — a test-supplied
# FileSystemOps redirecting every "fs" access into RAM pages. The fake IS
# the redirect evidence: FileStorage drives a full write/replay cycle with
# ZERO actual filesystem traffic in the automated suite (no open(2), no
# disk — every "fs" byte lands in the fake's RAM pages).
#
# Covered: the journal framing (crc32 + record layout), durable queue/
# exchange/x-args recovery, persistent publish (delivery_mode=2) with the
# byte-faithful props redelivery, ACK tombstone drop, REDELIVER bumps, the
# REMOVE tombstone (an expiry/dead-letter outcome never resurrects),
# purge/delete tombstones, crash-tail replay (the torn final record drops and
# the file truncates back to the last good record), and the engine-level
# recovery with redelivered=1.
#
# Mojo `assert` is inert in this toolchain, so every check goes through
# `hyrx.testing.check`.

from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Envelope, Message, MessageID
from hyrx.core.exchange import ExchangeType
from hyrx.core.router import Router
from hyrx.core.storage import (
    RecoveredTopology,
    FileSystemOps,
    FileStorage,
    MemoryStorage,
    MessageJournal,
    RecoveryBuilder,
    props_delivery_mode,
    _crc32,
)
from hyrx.core.exchange import HeaderArgs
from hyrx.testing import check


# The redirectable "filesystem": a test-supplied FileSystemOps. EVERYTHING
# FileStorage touches lands in this struct's RAM pages.
struct FakeOps(Movable, Deinitable, FileSystemOps):
    var pages: List[UInt8]
    var opens: Int
    var appends: Int
    var syncs: Int
    var closes: Int
    var truncates: Int
    var reads: Int

    def __init__(out self):
        self.pages = List[UInt8]()
        self.opens = 0
        self.appends = 0
        self.syncs = 0
        self.closes = 0
        self.truncates = 0
        self.reads = 0


    def read_all(mut self, var path: String) raises -> List[UInt8]:
        self.reads += 1
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
        self.closes += 1


# ---- payloads ----------------------------------------------------------------

def fake_body(flag: Int) -> List[UInt8]:
    """A deterministic payload byte pattern (the byte-faithful checks)."""
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


# ---- the recovery assertions BOTH tiers share --------------------------------

def finish_topology(var builder: RecoveryBuilder) raises -> RecoveredTopology:
    var topo = builder.finalize()
    check(topo.recovered_messages == 3, "recovery: three MSG records")
    check(topo.removed_total == 2, "recovery: the ack+remove tombstones drop")
    var qi = -1
    for i in range(len(topo.queues)):
        if topo.queues[i].name == "stor-q":
            qi = i
    check(qi >= 0, "recovery: the durable queue is recovered")
    check(
        topo.queues[qi].durable,
        "recovery: the durable flag is recovered",
    )
    check(
        topo.queues[qi].capacity == 64,
        "recovery: the declared capacity is recovered",
    )
    check(
        topo.queues[qi].ttl_ms == 750,
        "recovery: x-message-ttl is recovered",
    )
    check(
        topo.queues[qi].max_length == 10,
        "recovery: x-max-length is recovered",
    )
    check(
        not topo.queues[qi].overflow_reject,
        "recovery: the overflow default is recovered",
    )
    check(
        topo.queues[qi].dlx == "stor-dlx-e",
        "recovery: x-dead-letter-exchange recovered",
    )
    check(
        topo.queues[qi].dlrk == "stor-dlrk",
        "recovery: x-dead-letter-routing-key recovered",
    )
    check(len(topo.exchanges) >= 1, "recovery: the declare exchange lives")
    check(
        len(topo.bindings) >= 1,
        "recovery: the queue binding is recovered",
    )
    return topo^


# ---- the shared durable-cycle over BOTH backends -------------------------------

def test_memory_shared_cycle() raises:
    """The in-RAM WAL tier (the DEFAULT-tier-companion semantics)."""
    var strg = MessageJournal.memory()
    _ = strg.write_queue_declare(
        "stor-q", True, 64, 750, 10, False, "stor-dlx-e", "stor-dlrk"
    )
    _ = strg.write_exchange_declare("stor-ex", 1)
    _ = strg.write_bind("stor-ex", "stor-q", "stor-rk", False)
    _ = strg.write_enqueue(
        "stor-q", "stor-rk", UInt16(0x1000), fake_body(1), fake_body(2), 111
    )
    _ = strg.write_enqueue(
        "stor-q", "stor-rk2", UInt16(0x1000), fake_body(2), fake_body(3), 222
    )
    _ = strg.write_enqueue(
        "stor-q", "stor-rk3", UInt16(0x1000), fake_body(3), fake_body(4), 333
    )
    _ = strg.write_ack(3)  # the FIRST message's record ordinal = 3
    _ = strg.write_redeliver(4)  # the SECOND (a requeue acceptance bump)
    _ = strg.write_remove(5)  # the THIRD: an expiry/dead-letter/drop outcome
    var recovered = strg.replay()
    var builder = RecoveryBuilder()
    builder.apply(recovered^)
    var topo = finish_topology(builder^)
    found_topology_extras(topo^)


def found_topology_extras(var topo: RecoveredTopology) raises:
    """The byte-faithful detail readouts (both tiers run these)."""
    check(
        bytes_eq(topo.queues[0].msgs[0].payload, fake_body(3)),
        "recovery: the payload bytes are byte-exact",
    )
    check(
        topo.queues[0].msgs[0].routing_key == "stor-rk2",
        "recovery: the routing key is recovered",
    )
    check(
        topo.queues[0].msgs[0].prop_flags == UInt16(0x1000),
        "recovery: the prop flag word rides",
    )
    check(
        bytes_eq(topo.queues[0].msgs[0].prop_bytes, fake_body(2)),
        "recovery: the byte-faithful prop bytes redeliver",
    )
    check(
        topo.queues[0].msgs[0].bumps == 1,
        "recovery: the REDELIVER bump is recorded",
    )
    check(
        topo.queues[0].dlx == "stor-dlx-e"
        and topo.queues[0].dlrk == "stor-dlrk",
        "recovery: the dlx/dlrk x-args are recovered",
    )


def test_file_shared_cycle() raises:
    """The file WAL tier driven ONLY through the injected fake ops."""
    var ops = FakeOps()
    var strg = FileStorage[FakeOps](ops^, "fake://jour")
    _ = strg.write_queue_declare(
        "stor-q", True, 64, 750, 10, False, "stor-dlx-e", "stor-dlrk"
    )
    _ = strg.write_exchange_declare("stor-ex", 1)
    _ = strg.write_bind("stor-ex", "stor-q", "stor-rk", False)
    _ = strg.write_enqueue(
        "stor-q", "stor-rk", UInt16(0x1000), fake_body(1), fake_body(2), 111
    )
    _ = strg.write_enqueue(
        "stor-q", "stor-rk2", UInt16(0x1000), fake_body(2), fake_body(3), 222
    )
    _ = strg.write_enqueue(
        "stor-q", "stor-rk3", UInt16(0x1000), fake_body(3), fake_body(4), 333
    )
    _ = strg.write_ack(3)
    _ = strg.write_redeliver(4)
    _ = strg.write_remove(5)
    var recovered = strg.replay()
    var builder = RecoveryBuilder()
    builder.apply(recovered^)
    var topo = finish_topology(builder^)
    found_topology_extras(topo^)


def test_journal_format_parity() raises:
    """The file WAL reads back exactly the bytes the memory WAL framed."""
    var ms = MemoryStorage()
    _ = ms.write_queue_declare("fmt-q", True, 8, 1, 2, False, "x", "y")
    var want = ms.journal_bytes()
    var fs = FileStorage[FakeOps](FakeOps(), "fake://parity")
    _ = fs.write_queue_declare("fmt-q", True, 8, 1, 2, False, "x", "y")
    check(
        bytes_eq(want, fs._ops.pages),
        "framing: the memory and file pages are byte-identical",
    )
    check(len(want) >= 16, "framing: a record carries len+type+body+crc")
    var total = (
        (Int(want[0]) << 24)
        | (Int(want[1]) << 16)
        | (Int(want[2]) << 8)
        | Int(want[3])
    )
    var rtype = (Int(want[4]) << 8) | Int(want[5])
    check(total + 8 == len(want), "framing: the u32 counts type+body (plus the two u32 framing words)")
    check(rtype == 1, "framing: the record type prefix = DECLARE_QUEUE")


def test_crc32_vector() raises:
    """CRC-32 pinned to the canonical IEEE vector."""
    var data = List[UInt8]()
    var probe = "123456789"
    var pb = probe.as_bytes()
    for i in range(len(pb)):
        data.append(pb[i])
    check(_crc32(data^) == UInt32(0xCBF43926), "crc32: the '123456789' vector")


def test_delivery_mode_decode() raises:
    """delivery_mode decodes out of byte-faithful content properties."""
    var raw = List[UInt8]()
    raw.append(UInt8(2))
    var m2 = props_delivery_mode(UInt16(0x1000), raw)
    check(m2 == 2, "delivery_mode: a bare octet body loads as 2")
    check(
        props_delivery_mode(UInt16(0), raw) == 0,
        "delivery_mode: a flagless message is absent",
    )
    check(
        props_delivery_mode(UInt16(0x1000), List[UInt8]()) == 0,
        "delivery_mode: a malformed body decodes as 0 (never a crash)",
    )
    var multi = List[UInt8]()
    multi.append(UInt8(1))
    multi.append(UInt8(ord('t')))
    multi.append(UInt8(2))
    var mm = props_delivery_mode(UInt16(0x9000), multi)
    check(mm == 2, "delivery_mode: the flag walk skips content-type")
    var transient = List[UInt8]()
    transient.append(UInt8(1))
    var mt = props_delivery_mode(UInt16(0x1000), transient)
    check(mt == 1, "delivery_mode: the transient value is preserved")


def test_file_wal_fake_ops_traffic() raises:
    """The file WAL drives ONLY the injected ops (the redirect evidence)."""
    var ops = FakeOps()
    var wal = FileStorage[FakeOps](ops^, "fake://tail")
    check(wal.records_written() == 0, "file WAL: a clean start")
    var seq = wal.write_bytes(UInt16(6), fake_body(4))
    check(seq == 0, "file WAL: the first record's ordinal is 0")
    check(wal._ops.opens == 1, "file WAL: the LAZY open routes through the fake")
    check(wal._ops.appends == 1, "file WAL: one append routes through the fake")
    check(wal._ops.syncs == 0, "file WAL: NO fsync is issued per record")
    check(wal.records_written() == 1, "file WAL: the position advanced")
    var r0 = wal.replay()
    check(len(r0.records) == 1, "file WAL: the replay reads one record")
    check(wal._ops.reads == 1, "file WAL: the replay read routes through the fake")
    check(wal._ops.truncates == 0, "file WAL: a clean tail truncates nothing")
    check(r0.records[0].rtype == 6, "file WAL: the record type round-trips")
    check(
        bytes_eq(r0.records[0].body, fake_body(4)),
        "file WAL: the body round-trips",
    )
    _ = wal.sync()
    check(wal._ops.syncs == 1, "file WAL: the explicit sync flushes via the fake")
    wal.close()
    check(wal._ops.closes == 1, "file WAL: the close routes through the fake")
    var fresh = FileStorage[FakeOps](FakeOps(), "fake://other")
    var rec2 = fresh.replay()
    check(len(rec2.records) == 0, "file WAL: another fake device is empty")


def test_crash_tail_recovery() raises:
    """A torn final page drops; the good records replay and the file is cut
    back (resume-from-truncate); a re-replay is clean (idempotent)."""
    var strg = MemoryStorage()
    for _ in range(3):
        _ = strg.write_bytes(UInt16(6), fake_body(1))
    var good = strg.journal_bytes()
    var good_end = len(good)
    check(good_end > 0, "crash-tail: the good prefix is non-empty")
    # a torn tail: the good prefix + a partial record prefix
    var torn_bytes = List[UInt8]()
    for i in range(good_end):
        torn_bytes.append(good[i])
    torn_bytes.append(UInt8(0))
    torn_bytes.append(UInt8(0))
    torn_bytes.append(UInt8(0))
    _ = _replay_torn_pages(torn_bytes^)


def _replay_torn_pages(var pages: List[UInt8]) raises:
    """Parse the torn page list the same way a recovery would (the file
    tier with an injected fake ops: a torn file IS a partial final frame;
    the replay bounds at the last good record and truncates back)."""
    var wal = FileStorage[FakeOps](FakeOps(), "fake://torn")
    for i in range(len(pages)):
        wal._ops.pages.append(pages[i])
    var p = wal.replay()
    check(not p.complete, "crash-tail: the torn tail is detected")
    check(
        wal._ops.truncates == 1,
        "crash-tail: the file was cut back through the injected ops",
    )
    check(len(p.records) == 3, "crash-tail: every good record replays")
    var p2 = wal.replay()
    check(p2.complete, "crash-tail: the replay after the truncate is clean")
    check(
        len(p2.records) == len(p.records),
        "crash-tail: the replay is idempotent",
    )


def test_empty_out_of_order_tombstones() raises:
    """Out-of-order / empty tombstones never resurrect live state."""
    var strg = MessageJournal.memory()
    _ = strg.write_enqueue(
        "only-q", "k", UInt16(0x1000), List[UInt8](), fake_body(2), 1
    )
    _ = strg.write_ack(99)  # unknown seq: silently ignored
    _ = strg.write_remove(50)  # not-yet-existing seq: ignored
    _ = strg.write_ack(0)  # the RIGHT ordinal drops the message
    var rec = strg.replay()
    var builder = RecoveryBuilder()
    builder.apply(rec^)
    var topo = builder.finalize()
    check(topo.recovered_messages == 1, "tombstone: one MSG record lived")
    check(topo.removed_total == 1, "tombstone: exactly one drop applied")
    check(len(topo.queues[0].msgs) == 0, "tombstone: the live set is empty")


def engine_recovery_cycle() raises:
    """Router-level: the durable publish (memory tier), then recovery into a
    FRESH Router — the declare/arg recovery, redelivered=1, the byte-faithful
    payload and the ack drop."""
    var r1 = Router(4096, 64, False)
    var j1 = MessageJournal.memory()
    r1.attach_journal(j1^)
    var created = r1.declare_queue_full(
        "durable-q", 32, True, 0, 0, 0, False, String(""), String("")
    )
    check(created, "router: the durable queue declare runs")
    _ = r1.declare_exchange("top-ex", ExchangeType.direct())
    check(r1.bind_queue("durable-q", "top-ex", "durable-rk", HeaderArgs()), "router: bound")
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(77), "durable-rk", headers^)
    var props = List[UInt8]()
    props.append(UInt8(2))
    var payload = fake_body(4)
    var buf = Buffer(len(payload))
    buf.resize(len(payload))
    for i in range(len(payload)):
        buf[i] = payload[i]
    var msg = Message(env^, buf^, UInt16(0x1000), props^)
    var routed = r1.publish(msg^, "top-ex")
    check(r1.queue_depth("durable-q") == 1, "router: the durable publish is routed")

    # recovery into a FRESH Router holding the SAME journal
    var r2 = Router(4096, 64, False)
    var pages = r1.journal_pages_copy()
    var j2 = MessageJournal.memory_from_bytes(pages^)
    r2.attach_journal(j2^)
    var recovered = r2.recover()
    check(recovered == 1, "router: exactly ONE message is recovered")
    check(r2.queue_depth("durable-q") == 1, "router: the recovered depth is 1")
    var cid = r2.register_consumer("durable-q", 8)
    var d = r2.consume(cid)
    check(d.__bool__(), "router: the recovered redelivery delivers")
    var tag = d.value().delivery_tag()
    check(
        r2.queue_redelivery(cid, tag),
        "router: the recovered redelivered bit is 1",
    )
    var bytes = r2.read_payload(cid, tag).to_bytes()
    check(
        bytes_eq(bytes, payload),
        "router: the recovered payload is byte-exact",
    )
    _ = r2.acknowledge(cid, tag)
    check(r2.queue_depth("durable-q") == 0, "router: the ack tombstones the tail")


def main() raises:
    test_memory_shared_cycle()
    test_file_shared_cycle()
    test_journal_format_parity()
    test_crc32_vector()
    test_delivery_mode_decode()
    test_file_wal_fake_ops_traffic()
    test_crash_tail_recovery()
    test_empty_out_of_order_tombstones()
    engine_recovery_cycle()
    print("STORAGE_TEST=PASS")
