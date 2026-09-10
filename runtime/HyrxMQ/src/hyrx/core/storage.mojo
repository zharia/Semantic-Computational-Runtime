# Pluggable storage (milestone 0018).
#
# The filesystem seam is a SINGLE trait (`FileSystemOps`): the storage layer
# NEVER opens/reads/appends/truncates anything outside it. The DEFAULT tier
# (`disabled`) constructs no storage activity at all, so a disabled serving
# path is byte-identical to today's. The `file` tier routes every byte
# through the SUPPLIED functions, so the filesystem is redirectable (POSIX
# impl, embedded VFS, test fakes). Only `SystemFileSystemOps` names libc
# file symbols (precedent: vendor/flare libc glue + hyrx ffi).
#
# Journal framing (SHARED by MemoryStorage and FileStorage — byte-identical
# format so FileStorage[FakeOps] proves the file path without a device):
#
#   record := u32 total_len BE      (total_len = 2 + len(body))
#             u16 record_type BE
#             body
#             u32 crc32 BE          (IEEE CRC-32 over type+body bytes)
#   string field := u16 byte-length + bytes
#   number field := u64 big-endian (all journaled values non-negative)
#   payload field := u32 byte-length + bytes
#
#   Message `seq` = the global 0-based ordinal of the message's MSG record
#   (each durable message is journaled as exactly ONE MSG record, so the
#   ordinals are stable identities; ACK/REDELIVER/REMOVE tombstones carry
#   that ordinal — the "offset chain" — and an empty/out-of-order tombstone
#   is a no-op).
#
# Record types (u16): 1 DECLARE_QUEUE, 2 DECLARE_EXCHANGE, 3 BIND,
#   4 DELETE_QUEUE, 5 PURGE, 6 MSG, 7 ACK, 8 REDELIVER, 9 REMOVE,
#   10 DELETE_EXCHANGE.
#
# LIMITS (documented; compaction is milestone 0020):
# - Append-only WAL, no segment rotation: the file GROWS for the whole run;
#   ACK/REMOVE tombstones and the corrupt-tail truncate never reclaim
#   mid-file bytes. Durable write-path journal volume is bounded by what the
#   client lifecycle requires (declares, persistent publishes + their
#   resolution tombstones), not by any rotation schedule.
# - Journal-before-enqueue (write-ahead): a capacity refusal AFTER the write
#   leaves one record the live queue refused; recovery materializes it and
#   the publish-side trim re-resolves it.
# - x-max-length is not re-capable at recovery materialization.
# - monotonic() enqueue stamps are journaled but NOT re-used (monotonic is
#   per-boot); recovery stamps fresh, so x-message-ttl ages restart.
# - No per-record fsync is issued by the storage layer itself; the SUPPLIED
#   FileSystemOps implementation owns the durability cadence.

from std.ffi import (
    external_call,
    c_int,
    c_size_t,
    c_ssize_t,
    get_errno,
)
from std.memory import UnsafePointer, stack_allocation
from std.sys.info import platform_map
from std.collections import List, Dict
from std.time import monotonic

from hyrx.core.message import Message


# ---- storage-mode codes ------------------------------------------------------

def STORAGE_MODE_DISABLED() -> Int:
    """DEFAULT: no storage class exists; zero fs activity anywhere."""
    return 0


def STORAGE_MODE_MEMORY() -> Int:
    """RAM journal: byte-identical framing, no device."""
    return 1


def STORAGE_MODE_FILE() -> Int:
    """WAL pages appended through the injected FileSystemOps."""
    return 2


# ---- record-type constants ---------------------------------------------------

def RECORD_DECLARE_QUEUE() -> UInt16:
    return UInt16(1)


def RECORD_DECLARE_EXCHANGE() -> UInt16:
    return UInt16(2)


def RECORD_BIND() -> UInt16:
    return UInt16(3)


def RECORD_DELETE_QUEUE() -> UInt16:
    return UInt16(4)


def RECORD_PURGE() -> UInt16:
    return UInt16(5)


def RECORD_MSG() -> UInt16:
    return UInt16(6)


def RECORD_ACK() -> UInt16:
    return UInt16(7)


def RECORD_REDELIVER() -> UInt16:
    return UInt16(8)


def RECORD_REMOVE() -> UInt16:
    return UInt16(9)


def RECORD_DELETE_EXCHANGE() -> UInt16:
    return UInt16(10)


def _MAX_PATH_BYTES() -> Int:
    return 1024


def _MAX_STR_BYTES() -> Int:
    return 1024


# ---- big-endian primitives ---------------------------------------------------

def _put_u16(mut dst: List[UInt8], v: UInt16):
    dst.append(UInt8((Int(v) >> 8) & 0xFF))
    dst.append(UInt8(Int(v) & 0xFF))


def _put_u32(mut dst: List[UInt8], v: UInt32):
    dst.append(UInt8((Int(v) >> 24) & 0xFF))
    dst.append(UInt8((Int(v) >> 16) & 0xFF))
    dst.append(UInt8((Int(v) >> 8) & 0xFF))
    dst.append(UInt8(Int(v) & 0xFF))


def _put_u64(mut dst: List[UInt8], v: UInt64):
    dst.append(UInt8((Int(v) >> 56) & 0xFF))
    dst.append(UInt8((Int(v) >> 48) & 0xFF))
    dst.append(UInt8((Int(v) >> 40) & 0xFF))
    dst.append(UInt8((Int(v) >> 32) & 0xFF))
    dst.append(UInt8((Int(v) >> 24) & 0xFF))
    dst.append(UInt8((Int(v) >> 16) & 0xFF))
    dst.append(UInt8((Int(v) >> 8) & 0xFF))
    dst.append(UInt8(Int(v) & 0xFF))


def _get_u16(ref src: List[UInt8], pos: Int) -> Int:
    """Big-endian u16 read; -1 past the end."""
    if pos + 2 > len(src):
        return -1
    return (Int(src[pos]) << 8) | Int(src[pos + 1])


def _get_u32(ref src: List[UInt8], pos: Int) -> Int:
    """Big-endian u32 read; -1 past the end."""
    if pos + 4 > len(src):
        return -1
    return (
        (Int(src[pos]) << 24)
        | (Int(src[pos + 1]) << 16)
        | (Int(src[pos + 2]) << 8)
        | Int(src[pos + 3])
    )


def _get_u64(ref src: List[UInt8], pos: Int) -> Int:
    """Big-endian u64 read; -1 past the end."""
    if pos + 8 > len(src):
        return -1
    var v = 0
    for i in range(8):
        v = (v << 8) | Int(src[pos + i])
    return v


def _put_str(mut dst: List[UInt8], var s: String):
    var b = s.as_bytes()
    var n = len(b)
    if n > 0xFFFF:
        n = 0xFFFF  # journal strings are short keys/paths; clamp defensively
    _put_u16(dst, UInt16(n))
    for i in range(n):
        dst.append(b[i])


def _copy_slice(ref src: List[UInt8], start: Int, count: Int) -> List[UInt8]:
    """Owned byte copy of src[start:start+count]; empty when malformed."""
    var out = List[UInt8]()
    if start < 0 or count < 0 or start + count > len(src):
        return out^
    for i in range(count):
        out.append(src[start + i])
    return out^


struct StrField:
    """Decode result of one string field (next = -1 when malformed)."""

    var text: String
    var after: Int

    def __init__(out self, var text: String, after: Int):
        self.text = text^
        self.after = after


def _get_str(ref src: List[UInt8], pos: Int) -> StrField:
    """Decode one u16-prefixed string field starting at pos."""
    var n = _get_u16(src, pos)
    if n < 0 or n > _MAX_STR_BYTES() or pos + 2 + n > len(src):
        var empty = String("")
        return StrField(empty^, -1)
    var s = String()
    for i in range(n):
        s.append(Codepoint(src[pos + 2 + i]))
    return StrField(s^, pos + 2 + n)


# ---- record body builders (SHARED by every write surface) -------------------

def _dj_body(var name: String, durable: Bool, capacity: Int, ttl_ms: Int, max_length: Int, overflow: Bool, var dlx: String, var dlrk: String) -> List[UInt8]:
    """DECLARE_QUEUE body: name,durable,capacity,ttl,max_length,overflow,dlx,dlrk."""
    var body = List[UInt8]()
    _put_str(body, name^)
    body.append(UInt8(1 if durable else 0))
    _put_u64(body, UInt64(capacity))
    _put_u64(body, UInt64(ttl_ms))
    _put_u64(body, UInt64(max_length))
    body.append(UInt8(1 if overflow else 0))
    _put_str(body, dlx^)
    _put_str(body, dlrk^)
    return body^


def _dx_body(var name: String, type_code: Int) -> List[UInt8]:
    var body = List[UInt8]()
    _put_str(body, name^)
    _put_u64(body, UInt64(type_code))
    return body^


def _bind_body(var exchange: String, var destination: String, var routing_key: String, e2e: Bool) -> List[UInt8]:
    var body = List[UInt8]()
    _put_str(body, exchange^)
    _put_str(body, destination^)
    _put_str(body, routing_key^)
    body.append(UInt8(1 if e2e else 0))
    return body^


def _qname_body(var name: String) -> List[UInt8]:
    var body = List[UInt8]()
    _put_str(body, name^)
    return body^


def _msg_body(var queue: String, var rk: String, prop_flags: UInt16, prop_bytes: List[UInt8], payload: List[UInt8], stamp_ns: Int) -> List[UInt8]:
    """MSG body: queue,rk,props(u32+n),payload(u32+n),enqueue stamp."""
    var body = List[UInt8]()
    _put_str(body, queue^)
    _put_str(body, rk^)
    _put_u16(body, prop_flags)
    _put_u32(body, UInt32(len(prop_bytes)))
    for i in range(len(prop_bytes)):
        body.append(prop_bytes[i])
    _put_u32(body, UInt32(len(payload)))
    for i in range(len(payload)):
        body.append(payload[i])
    _put_u64(body, UInt64(stamp_ns))
    return body^


def _seq_body(seq: Int) -> List[UInt8]:
    var body = List[UInt8]()
    _put_u64(body, UInt64(seq))
    return body^


# ---- CRC-32 -------------------------------------------------------------------

def _crc32(ref data: List[UInt8]) -> UInt32:
    """IEEE CRC-32 (reflected, poly 0xEDB88320, init/xorout 0xFFFFFFFF).

    Bitwise form; identical values to the classic 256-entry table
    implementation (RabbitMQ's store-crc parity). The canonical check vector
    ("123456789" -> 0xCBF43926) is asserted in tests/phase8/storage_test.
    """
    var crc = UInt32(0xFFFFFFFF)
    for i in range(len(data)):
        crc = crc ^ UInt32(Int(data[i]))
        for _ in range(8):
            if crc & 1 != 0:
                crc = (crc >> 1) ^ UInt32(0xEDB88320)
            else:
                crc = crc >> 1
    return crc ^ UInt32(0xFFFFFFFF)


# ---- framing -------------------------------------------------------------------

struct JournalRecord:
    """One decoded journal record; seq = its 0-based ordinal identity."""

    var rtype: Int
    var seq: UInt64
    var body: List[UInt8]

    def __init__(out self, t: Int, s: UInt64, var b: List[UInt8]):
        self.rtype = t
        self.seq = s
        self.body = b^


def _encode_frame(var body: List[UInt8], rtype: UInt16) -> List[UInt8]:
    """[u32 total_len][u16 type][body][u32 crc32 over type+body]."""
    var frame = List[UInt8]()
    _put_u32(frame, UInt32(2 + len(body)))
    _put_u16(frame, rtype)
    for i in range(len(body)):
        frame.append(body[i])
    var crc_src = List[UInt8]()
    _put_u16(crc_src, rtype)
    for i in range(len(body)):
        crc_src.append(body[i])
    _put_u32(frame, _crc32(crc_src^))
    return frame^


struct ParsedJournal:
    """Bounded-scan outcome: good records + where the good prefix ends."""

    var records: List[JournalRecord]
    var good_end: Int
    var complete: Bool

    def __init__(
        out self,
        var records: List[JournalRecord],
        good_end: Int,
        complete: Bool,
    ):
        self.records = records^
        self.good_end = good_end
        self.complete = complete


def parse_journal(ref pages: List[UInt8]) raises -> ParsedJournal:
    """Sequential bounded parse with integrity checks.

    Stops at the first bad/partial record (fail-closed): a torn tail (crash
    between the append start and its completion) or a CRC mismatch ends the
    replay; everything past `good_end` is the partial final entry the caller
    truncates (resume-from-truncate).
    """
    var records = List[JournalRecord]()
    var pos = 0
    var good_end = 0
    var seq = UInt64(0)
    var complete = True
    while True:
        var remaining = len(pages) - pos
        if remaining == 0:
            break
        if remaining < 6:
            complete = False
            break
        var body_len = _get_u32(pages, pos)
        if body_len < 2 or remaining < (4 + body_len + 4):
            complete = False
            break
        var rtype = _get_u16(pages, pos + 4)
        if rtype <= 0 or rtype > Int(RECORD_DELETE_EXCHANGE()):
            complete = False
            break
        var crc_stored = _get_u32(pages, pos + 4 + body_len)
        var crc_src = List[UInt8]()
        _put_u16(crc_src, UInt16(rtype))
        var b = _copy_slice(pages, pos + 6, body_len - 2)
        for i in range(len(b)):
            crc_src.append(b[i])
        if _crc32(crc_src^) != UInt32(crc_stored):
            complete = False
            break
        records.append(JournalRecord(Int(rtype), seq, b^))
        seq += UInt64(1)
        pos += 4 + body_len + 4
        good_end = pos
    return ParsedJournal(records^, good_end, complete)


# ---- durable-publish gate --------------------------------------------------------

def props_delivery_mode(prop_flags: UInt16, ref prop_bytes: List[UInt8]) -> Int:
    """Decode `delivery_mode` out of byte-faithful content properties.

    Walks the amqp0-9-1 flag word top-down: bit 15 content_type (shortstr:
    1 length byte + bytes), 14 content_encoding (shortstr), 13 headers
    (field table: u32 byte-length prefix), then bit 12 delivery_mode (one
    octet). Returns 0 = absent/undecodable, 1 = transient, 2 = persistent;
    every step is bounds-checked so a malformed body yields 0, never a crash.
    """
    var flags = Int(prop_flags)
    var pos = 0
    if flags & 0x8000 != 0:
        if pos >= len(prop_bytes):
            return 0
        var n = Int(prop_bytes[pos])
        pos += 1 + n
    if flags & 0x4000 != 0:
        if pos >= len(prop_bytes):
            return 0
        var n = Int(prop_bytes[pos])
        pos += 1 + n
    if flags & 0x2000 != 0:
        var tl = _get_u32(prop_bytes, pos)
        if tl < 0:
            return 0
        pos += 4 + tl
    if flags & 0x1000 != 0:
        if pos >= len(prop_bytes):
            return 0
        return Int(prop_bytes[pos])
    return 0


# ---- the filesystem seam ---------------------------------------------------------

trait FileSystemOps(Movable, Deinitable):
    """The ONLY filesystem seam in the storage layer.

    The USER supplies the implementation; the storage layer routes EVERY
    access through it, so the device is redirectable (POSIX impl, embedded
    VFS, test fake). MemoryStorage does not use it at all.
    """

    def read_all(mut self, var path: String) raises -> List[UInt8]:
        """Read the WHOLE file's bytes."""
        ...

    def exists(mut self, var path: String) -> Bool:
        """Whether the file exists."""
        ...

    def open_append(mut self, var path: String) raises -> Int:
        """Open (create) in append mode; the Int handle is opaque."""
        ...

    def append(mut self, handle: Int, var data: List[UInt8]) raises:
        """Append ALL bytes (full-write)."""
        ...

    def sync(mut self, handle: Int) raises:
        """Flush; the SUPPLIED fn owns its durability contract."""
        ...

    def truncate(mut self, handle: Int, length: Int) raises:
        """Truncate the handle's file to `length` bytes.

        NEGOTIATED from the plan sketch's one-arg `truncate(path)`: the
        corrupt-tail resume needs a byte length, and the write handle the
        storage layer already holds — so the op is handle-based."""
        ...

    def close(mut self, handle: Int):
        """Release the handle (best-effort; close-path errors must not break
        recovery)."""
        ...


# ---- the POSIX implementation (the ONLY libc glue in this layer) -----------------

comptime _pm = platform_map[T=Int, ...]

comptime _C_O_RDONLY: c_int = c_int(_pm["O_RDONLY", linux=0, macos=0]())
comptime _C_O_WRONLY: c_int = c_int(_pm["O_WRONLY", linux=1, macos=1]())
comptime _C_O_CREAT: c_int = c_int(_pm["O_CREAT", linux=0o100, macos=0o1000]())
comptime _C_O_APPEND: c_int = c_int(
    _pm["O_APPEND", linux=0o2000, macos=0o2000]()
)
comptime _C_F_OK: c_int = 0


def _cstr(var s: String) raises -> UnsafePointer[UInt8, MutUntrackedOrigin]:
    """NUL-terminated stack copy of a path (bounded)."""
    if len(s.as_bytes()) >= _MAX_PATH_BYTES():
        raise "storage: path longer than the " + String(_MAX_PATH_BYTES()) + " byte cap"
    var b = s.as_bytes()
    var n = len(b)
    var buf = stack_allocation[_MAX_PATH_BYTES(), UInt8]()
    for i in range(n):
        buf[i] = b[i]
    buf[n] = 0
    return buf


def _fail(op: String) raises:
    var e = get_errno()
    raise "storage: " + op + " failed (errno " + String(e.value) + ")"


@always_inline
def _pl_open(path: UnsafePointer[UInt8, _], flags: c_int, mode: c_int) -> c_int:
    return external_call["open", c_int](
        path.unsafe_bitcast[NoneType](), flags, mode
    )


@always_inline
def _pl_close(fd: c_int) -> c_int:
    return external_call["close", c_int](fd)


@always_inline
def _pl_access(path: UnsafePointer[UInt8, _], mode: c_int) -> c_int:
    return external_call["access", c_int](path.unsafe_bitcast[NoneType](), mode)


@always_inline
def _pl_write(
    fd: c_int, buf: UnsafePointer[UInt8, _], n: c_size_t
) -> c_ssize_t:
    """libc pwrite(2) — offset encoded by an O_APPEND fd: each call appends
    (the plan's named symbol; the stdlib's competing `write` binding is
    avoided entirely on this file)."""
    return external_call["pwrite", c_ssize_t](
        fd, buf.unsafe_bitcast[NoneType](), n, c_ssize_t(0)
    )


@always_inline
def _pl_read(
    fd: c_int, buf: UnsafePointer[UInt8, _], n: c_size_t, at: c_ssize_t
) -> c_ssize_t:
    """libc pread(2) (position-independent full-file reads)."""
    return external_call["pread", c_ssize_t](
        fd, buf.unsafe_bitcast[NoneType](), n, at
    )


@always_inline
def _pl_fsync(fd: c_int) -> c_int:
    return external_call["fsync", c_int](fd)


@always_inline
def _pl_ftruncate(fd: c_int, length: c_size_t) -> c_int:
    return external_call["ftruncate", c_int](fd, length)


struct SystemFileSystemOps(FileSystemOps):
    """POSIX implementation. The SINGLE storage struct naming the libc
    symbols (open/access/read/write/fsync/ftruncate/close)."""

    def __init__(out self):
        pass

    def read_all(mut self, var path: String) raises -> List[UInt8]:
        """Read the whole file; a missing file raises (the caller pre-checks
        exists() so a fresh store sees an EMPTY replay, not an error)."""
        var p = _cstr(path^)
        var fd = _pl_open(p, _C_O_RDONLY, c_int(0))
        if fd < 0:
            _fail("open(read)")
        var out = List[UInt8]()
        var chunk = stack_allocation[8192, UInt8]()
        var at = c_ssize_t(0)
        while True:
            var got = _pl_read(fd, chunk, c_size_t(8192), at)
            if got < 0:
                _fail("pread")
            if got == 0:
                break
            for i in range(Int(got)):
                out.append(chunk[i])
            at += got
        if _pl_close(fd) < 0:
            _fail("close(read)")
        return out^

    def exists(mut self, var path: String) -> Bool:
        """Whether the file exists (access F_OK).

        Non-raising: a probe failure reads as not-found, never a panic."""
        var found = False
        try:
            var p = _cstr(path^)
            found = _pl_access(p, _C_F_OK) == 0
        except:
            return False
        return found

    def open_append(mut self, var path: String) raises -> Int:
        """Open/create the journal path O_APPEND (Int handle)."""
        var p = _cstr(path^)
        var fd = _pl_open(
            p,
            c_int(_C_O_WRONLY | _C_O_CREAT | _C_O_APPEND),
            c_int(0o644),
        )
        if fd < 0:
            _fail("open(append)")
        return Int(fd)

    def append(mut self, handle: Int, var data: List[UInt8]) raises:
        """Write ALL bytes (full-write loop)."""
        var n = len(data)
        if n == 0:
            return
        var bp = stack_allocation[8192, UInt8]()
        var sent = 0
        while sent < n:
            var chunk = n - sent
            if chunk > 8192:
                chunk = 8192
            for i in range(chunk):
                bp[i] = data[sent + i]
            var got = _pl_write(c_int(handle), bp, c_size_t(chunk))
            if got <= 0:
                _fail("write")
            sent += Int(got)

    def sync(mut self, handle: Int) raises:
        """fsync (the durability cadence belongs to the supplied fn)."""
        if _pl_fsync(c_int(handle)) < 0:
            _fail("fsync")

    def truncate(mut self, handle: Int, length: Int) raises:
        """ftruncate to length (resume-from-truncate)."""
        if _pl_ftruncate(c_int(handle), c_size_t(length)) < 0:
            _fail("ftruncate")

    def close(mut self, handle: Int):
        """Best-effort close (never raises: recovery must not break on it)."""
        _ = _pl_close(c_int(handle))


# ---- the two WAL backends ---------------------------------------------------------

struct MemoryStorage(Movable):
    """In-RAM WAL: byte-identical journal semantics, zero filesystem use."""

    var _page: List[UInt8]
    var _records: Int

    def __init__(out self):
        self._page = List[UInt8]()
        self._records = 0

    def write_bytes(mut self, rtype: UInt16, var body: List[UInt8]) raises -> Int:
        """Append one framed record; returns its seq (0-based ordinal)."""
        var seq = self._records
        var frame = _encode_frame(body^, rtype)
        for i in range(len(frame)):
            self._page.append(frame[i])
        self._records += 1
        return seq

    def write_queue_declare(
        mut self, var name: String, durable: Bool, capacity: Int,
        ttl_ms: Int, max_length: Int, overflow: Bool, var dlx: String,
        var dlrk: String,
    ) raises -> Int:
        """DECLARE_QUEUE via the RAM WAL."""
        var b = _dj_body(
            name^, durable, capacity, ttl_ms, max_length, overflow,
            dlx^, dlrk^,
        )
        return self.write_bytes(RECORD_DECLARE_QUEUE(), b^)

    def write_exchange_declare(mut self, var name: String, type_code: Int) raises -> Int:
        var b = _dx_body(name^, type_code)
        return self.write_bytes(RECORD_DECLARE_EXCHANGE(), b^)

    def write_exchange_delete(mut self, var name: String) raises -> Int:
        var b = _qname_body(name^)
        return self.write_bytes(RECORD_DELETE_EXCHANGE(), b^)

    def write_bind(
        mut self, var exchange: String, var destination: String,
        var routing_key: String, e2e: Bool,
    ) raises -> Int:
        var b = _bind_body(exchange^, destination^, routing_key^, e2e)
        return self.write_bytes(RECORD_BIND(), b^)

    def write_delete_queue(mut self, var name: String) raises -> Int:
        var b = _qname_body(name^)
        return self.write_bytes(RECORD_DELETE_QUEUE(), b^)

    def write_purge(mut self, var name: String) raises -> Int:
        var b = _qname_body(name^)
        return self.write_bytes(RECORD_PURGE(), b^)

    def write_enqueue(
        mut self, var queue: String, var rk: String, prop_flags: UInt16,
        prop_bytes: List[UInt8], payload: List[UInt8], stamp_ns: Int,
    ) raises -> Int:
        """MSG record via the RAM WAL; returns the message's seq."""
        var b = _msg_body(
            queue^, rk^, prop_flags, prop_bytes.copy(), payload.copy(), stamp_ns
        )
        return self.write_bytes(RECORD_MSG(), b^)

    def write_ack(mut self, seq: Int) raises -> Int:
        return self.write_bytes(RECORD_ACK(), _seq_body(seq)^)

    def write_redeliver(mut self, seq: Int) raises -> Int:
        return self.write_bytes(RECORD_REDELIVER(), _seq_body(seq)^)

    def write_remove(mut self, seq: Int) raises -> Int:
        return self.write_bytes(RECORD_REMOVE(), _seq_body(seq)^)

    def replay(mut self) raises -> ParsedJournal:
        """Parse; a corrupt/partial tail is cut in-RAM. Idempotent."""
        var p = parse_journal(self._page)
        if not p.complete:
            self._truncate_prefix(p.good_end)
        self._records = len(p.records)
        return p^

    def _truncate_prefix(mut self, length: Int):
        """Drop the page beyond `length` (the in-RAM tail truncate)."""
        var kept = List[UInt8]()
        for i in range(length):
            kept.append(self._page[i])
        self._page = kept^

    def truncate_tail(mut self, length: Int):
        """Resets the page to its `length`-byte prefix (REPLAY must be the
        caller's _records sync)."""
        self._truncate_prefix(length)
        self._records = 0

    def records_written(ref self) -> Int:
        return self._records

    def journal_bytes(ref self) -> List[UInt8]:
        """Owned copy of the RAM journal pages (test/introspection)."""
        return self._page.copy()




struct FileStorage[Ops: FileSystemOps](Movable):
    """Injectable WAL: framed journal pages appended through the SUPPLIED
    FileSystemOps (the only storage class that touches a fs at all; and even
    then exclusively through the injected trait object)."""

    var _ops: Self.Ops
    var _path: String
    var _fd: Int  # -1 = not opened yet (LAZY; construction touches no fs)
    var _records: Int

    def __init__(out self, var ops: Self.Ops, var path: String):
        self._ops = ops^
        self._path = path^
        self._fd = -1
        self._records = 0

    def write_queue_declare(
        mut self, var name: String, durable: Bool, capacity: Int,
        ttl_ms: Int, max_length: Int, overflow: Bool, var dlx: String,
        var dlrk: String,
    ) raises -> Int:
        var b = _dj_body(
            name^, durable, capacity, ttl_ms, max_length, overflow,
            dlx^, dlrk^,
        )
        return self.write_bytes(RECORD_DECLARE_QUEUE(), b^)

    def write_exchange_declare(mut self, var name: String, type_code: Int) raises -> Int:
        var b = _dx_body(name^, type_code)
        return self.write_bytes(RECORD_DECLARE_EXCHANGE(), b^)

    def write_exchange_delete(mut self, var name: String) raises -> Int:
        var b = _qname_body(name^)
        return self.write_bytes(RECORD_DELETE_EXCHANGE(), b^)

    def write_bind(
        mut self, var exchange: String, var destination: String,
        var routing_key: String, e2e: Bool,
    ) raises -> Int:
        var b = _bind_body(exchange^, destination^, routing_key^, e2e)
        return self.write_bytes(RECORD_BIND(), b^)

    def write_delete_queue(mut self, var name: String) raises -> Int:
        var b = _qname_body(name^)
        return self.write_bytes(RECORD_DELETE_QUEUE(), b^)

    def write_purge(mut self, var name: String) raises -> Int:
        var b = _qname_body(name^)
        return self.write_bytes(RECORD_PURGE(), b^)

    def write_enqueue(
        mut self, var queue: String, var rk: String, prop_flags: UInt16,
        prop_bytes: List[UInt8], payload: List[UInt8], stamp_ns: Int,
    ) raises -> Int:
        var b = _msg_body(queue^, rk^, prop_flags, prop_bytes.copy(), payload.copy(), stamp_ns)
        return self.write_bytes(RECORD_MSG(), b^)

    def write_ack(mut self, seq: Int) raises -> Int:
        return self.write_bytes(RECORD_ACK(), _seq_body(seq)^)

    def write_redeliver(mut self, seq: Int) raises -> Int:
        return self.write_bytes(RECORD_REDELIVER(), _seq_body(seq)^)

    def write_remove(mut self, seq: Int) raises -> Int:
        return self.write_bytes(RECORD_REMOVE(), _seq_body(seq)^)

    def _ensure_open(mut self) raises:
        if self._fd < 0:
            self._fd = self._ops.open_append(self._path)

    def write_bytes(mut self, rtype: UInt16, var body: List[UInt8]) raises -> Int:
        """Append one framed record via the injected ops; returns its seq
        (0-based ordinal = the count before this record)."""
        var seq = self._records
        self._ensure_open()
        var frame = _encode_frame(body^, rtype)
        self._ops.append(self._fd, frame^)
        self._records += 1
        return seq

    def sync(mut self) raises:
        """Durability flush through the injected ops (no-op until opened)."""
        if self._fd >= 0:
            self._ops.sync(self._fd)

    def replay(mut self) raises -> ParsedJournal:
        """Bounded scan + resume-from-truncate through the injected ops.

        A corrupt/partial tail (crash between the append start and its
        completion) is dropped and the file is ftruncate'd back to `good_end`
        via the same injected ops; the replay is idempotent.
        """
        if not self._ops.exists(self._path):
            self._records = 0
            var empty = ParsedJournal(List[JournalRecord](), 0, True)
            return empty^
        var pages = self._ops.read_all(self._path)
        var p = parse_journal(pages^)
        if not p.complete:
            self._ensure_open()
            self._ops.truncate(self._fd, p.good_end)
        self._records = len(p.records)
        return p^

    def records_written(ref self) -> Int:
        return self._records

    def close(mut self):
        """Close the handle through the injected ops (idempotent)."""
        if self._fd >= 0:
            self._ops.close(self._fd)
            self._fd = -1


# ---- recovery: the forward-replay state builder ------------------------------------

struct RecoveredMessage:
    """One still-live recovered message (the materialization marks the
    recovered-redelivered approximation per the 0017-T2 semantics)."""

    var seq: UInt64
    var routing_key: String
    var prop_flags: UInt16
    var prop_bytes: List[UInt8]
    var payload: List[UInt8]
    var stamp_ns: Int
    var bumps: Int  # REDELIVER tombstone count

    def __init__(
        out self,
        seq: UInt64,
        var rk: String,
        flags: UInt16,
        var props: List[UInt8],
        var payload: List[UInt8],
        stamp: Int,
    ):
        self.seq = seq
        self.routing_key = rk^
        self.prop_flags = flags
        self.prop_bytes = props^
        self.payload = payload^
        self.stamp_ns = stamp
        self.bumps = 0


struct RecoveredQueue:
    """A queue's last-declare configuration + its still-live messages."""

    var name: String
    var durable: Bool
    var capacity: Int
    var ttl_ms: Int
    var max_length: Int
    var overflow_reject: Bool
    var dlx: String
    var dlrk: String
    var msgs: List[RecoveredMessage]

    def __init__(
        out self,
        var name: String,
        durable: Bool,
        capacity: Int,
        ttl_ms: Int,
        max_length: Int,
        overflow_reject: Bool,
        var dlx: String,
        var dlrk: String,
    ):
        self.name = name^
        self.durable = durable
        self.capacity = capacity
        self.ttl_ms = ttl_ms
        self.max_length = max_length
        self.overflow_reject = overflow_reject
        self.dlx = dlx^
        self.dlrk = dlrk^
        self.msgs = List[RecoveredMessage]()


struct RecoveredExchange:
    var name: String
    var type_code: Int

    def __init__(out self, var name: String, type_code: Int):
        self.name = name^
        self.type_code = type_code


struct RecoveredBinding:
    var exchange: String
    var destination: String
    var routing_key: String
    var e2e: Bool

    def __init__(
        out self,
        var exchange: String,
        var destination: String,
        var routing_key: String,
        e2e: Bool,
    ):
        self.exchange = exchange^
        self.destination = destination^
        self.routing_key = routing_key^
        self.e2e = e2e


struct RecoveredTopology:
    """The RecoveryBuilder's final live state (ordered, deterministic)."""

    var exchanges: List[RecoveredExchange]
    var queues: List[RecoveredQueue]
    var bindings: List[RecoveredBinding]
    var recovered_messages: Int
    var removed_total: Int
    var tail_truncated: Bool

    def __init__(out self):
        self.exchanges = List[RecoveredExchange]()
        self.queues = List[RecoveredQueue]()
        self.bindings = List[RecoveredBinding]()
        self.recovered_messages = 0
        self.removed_total = 0
        self.tail_truncated = False


struct RecoveryBuilder:
    """Forward-replay state builder for the recorder.

    One bounded pass over the ordered journal stream: declares last-wins,
    bindings appended, messages registered, ACK/REDELIVER/REMOVE tombstones
    resolve, purges/delete tombstones drop state. Computes the final live
    topology for the Router's materialization.
    """

    var _exchanges: List[RecoveredExchange]
    var _queues: List[RecoveredQueue]
    var _bindings: List[RecoveredBinding]
    var _owner: Dict[UInt64, String]  # msg seq -> queue name
    var _recovered: Int
    var _removed: Int
    var _tail: Bool

    def __init__(out self):
        self._exchanges = List[RecoveredExchange]()
        self._queues = List[RecoveredQueue]()
        self._bindings = List[RecoveredBinding]()
        self._owner = Dict[UInt64, String]()
        self._recovered = 0
        self._removed = 0
        self._tail = False

    def apply(mut self, var parsed: ParsedJournal) raises:
        """Consume the ordered journal stream (records are moved out)."""
        while len(parsed.records) > 0:
            var r = parsed.records.pop(0)
            var t = r.rtype
            if t == Int(RECORD_DECLARE_QUEUE()):
                self._apply_queue_declare(r^)
            elif t == Int(RECORD_DECLARE_EXCHANGE()):
                self._apply_exchange_declare(r^)
            elif t == Int(RECORD_BIND()):
                self._apply_bind(r^)
            elif t == Int(RECORD_DELETE_QUEUE()):
                self._apply_queue_delete(r^)
            elif t == Int(RECORD_DELETE_EXCHANGE()):
                self._apply_exchange_delete(r^)
            elif t == Int(RECORD_PURGE()):
                self._apply_purge(r^)
            elif t == Int(RECORD_MSG()):
                self._apply_msg(r^)
            elif t == Int(RECORD_ACK()):
                self._tombstone(_get_u64(r.body, 0))
            elif t == Int(RECORD_REMOVE()):
                self._tombstone(_get_u64(r.body, 0))
            elif t == Int(RECORD_REDELIVER()):
                self._apply_redeliver(_get_u64(r.body, 0))

    def _qi(ref self, name: String) -> Int:
        for i in range(len(self._queues)):
            if self._queues[i].name == name:
                return i
        return -1

    def _xi(ref self, name: String) -> Int:
        for i in range(len(self._exchanges)):
            if self._exchanges[i].name == name:
                return i
        return -1

    def _apply_queue_declare(mut self, var r: JournalRecord):
        """DECLARE_QUEUE: last-wins — REPLACE the configuration; messages
        recorded BEFORE this record STAY (an inequivalent redeclare cannot
        exist in a live journal: the 406 equivalence check runs beforehand,
        and a delete+redeclare pair is a fresh queue — the DELETE record
        already dropped the earlier message set)."""
        var b = r.body.copy()
        var pos = 0
        var name = _get_str(b, pos)
        if name.after < 0:
            return
        pos = name.after
        if pos >= len(b):
            return
        var durable = b[pos] != 0
        pos += 1
        var capacity = _get_u64(b, pos)
        if capacity < 0:
            return
        pos += 8
        var ttl = _get_u64(b, pos)
        if ttl < 0:
            return
        pos += 8
        var maxlen = _get_u64(b, pos)
        if maxlen < 0:
            return
        pos += 8
        if pos >= len(b):
            return
        var overflow = b[pos] != 0
        pos += 1
        var dlx = _get_str(b, pos)
        if dlx.after < 0:
            return
        pos = dlx.after
        var dlrk = _get_str(b, pos)
        if dlrk.after < 0:
            return
        var idx = self._qi(name.text)
        if idx >= 0:
            self._queues[idx].durable = durable
            self._queues[idx].capacity = Int(capacity)
            self._queues[idx].ttl_ms = Int(ttl)
            self._queues[idx].max_length = Int(maxlen)
            self._queues[idx].overflow_reject = overflow
            self._queues[idx].dlx = dlx.text.copy()
            self._queues[idx].dlrk = dlrk.text.copy()
            return
        var qq = RecoveredQueue(
            name.text.copy(), durable, Int(capacity), Int(ttl),
            Int(maxlen), overflow, dlx.text.copy(), dlrk.text.copy(),
        )
        self._queues.append(qq^)

    def _apply_exchange_declare(mut self, var r: JournalRecord):
        var b = r.body.copy()
        var name = _get_str(b, 0)
        if name.after < 0:
            return
        var tcode = _get_u64(b, name.after)
        if tcode < 0:
            return
        var ex = RecoveredExchange(name.text.copy(), Int(tcode))
        var idx = self._xi(name.text)
        if idx >= 0:
            self._exchanges[idx] = ex^
            return
        self._exchanges.append(ex^)

    def _apply_exchange_delete(mut self, var r: JournalRecord):
        var name = _get_str(r.body, 0)
        if name.after < 0:
            return
        for i in range(len(self._exchanges)):
            if self._exchanges[i].name == name.text:
                _ = self._exchanges.pop(i)
                return

    def _apply_queue_delete(mut self, var r: JournalRecord) raises:
        """DELETE_QUEUE: the queue AND its still-live messages vanish, so a
        dead queue never resurrects its old records."""
        var name = _get_str(r.body, 0)
        if name.after < 0:
            return
        var idx = self._qi(name.text)
        if idx >= 0:
            var q = self._queues.pop(idx)
            var seqs = List[UInt64]()
            for i in range(len(q.msgs)):
                seqs.append(q.msgs[i].seq)
            for i in range(len(seqs)):
                _ = self._owner.pop(seqs[i])
        # bindings referencing a deleted queue drop at materialization.
        return

    def _apply_purge(mut self, var r: JournalRecord) raises:
        """PURGE: every still-live ready message of that queue drops."""
        var name = _get_str(r.body, 0)
        if name.after < 0:
            return
        var idx = self._qi(name.text)
        if idx >= 0:
            var total = len(self._queues[idx].msgs)
            var seqs = List[UInt64]()
            for i in range(total):
                seqs.append(self._queues[idx].msgs[i].seq)
            for i in range(total):
                _ = self._owner.pop(seqs[i])
            self._queues[idx].msgs = List[RecoveredMessage]()

    def _apply_bind(mut self, var r: JournalRecord):
        var b = r.body.copy()
        var ex = _get_str(b, 0)
        if ex.after < 0:
            return
        var dest = _get_str(b, ex.after)
        if dest.after < 0:
            return
        var rk = _get_str(b, dest.after)
        if rk.after < 0:
            return
        var pos = rk.after
        if pos >= len(b):
            return
        var e2e = b[pos] != 0
        var bind = RecoveredBinding(ex.text.copy(), dest.text.copy(), rk.text.copy(), e2e)
        self._bindings.append(bind^)

    def _apply_msg(mut self, var r: JournalRecord):
        """MSG: register one still-live message (seq = record ordinal)."""
        var b = r.body.copy()
        var pos = 0
        var queue = _get_str(b, pos)
        if queue.after < 0:
            return
        pos = queue.after
        var rk = _get_str(b, pos)
        if rk.after < 0:
            return
        pos = rk.after
        var flags = _get_u16(b, pos)
        if flags < 0:
            return
        pos += 2
        var plen = _get_u32(b, pos)
        if plen < 0 or pos + 4 + plen > len(b):
            return
        var props = _copy_slice(b, pos + 4, plen)
        pos += 4 + plen
        var paylen = _get_u32(b, pos)
        if paylen < 0 or pos + 4 + paylen > len(b):
            return
        var payload = _copy_slice(b, pos + 4, paylen)
        pos += 4 + paylen
        var stamp = _get_u64(b, pos)
        if stamp < 0:
            stamp = 0
        var idx = self._qi(queue.text)
        if idx < 0:
            # defensive: a durable queue's declare record precedes every MSG
            # record; a missing state is created bare (durable, since only
            # durable queues journal messages).
            var bare = RecoveredQueue(
                queue.text.copy(), True, 1024, 0, 0, False,
                String(""), String(""),
            )
            self._queues.append(bare^)
            idx = self._qi(queue.text)
        var m = RecoveredMessage(
            r.seq, rk.text.copy(), UInt16(flags), props^, payload^, Int(stamp)
        )
        self._queues[idx].msgs.append(m^)
        self._owner[r.seq] = queue.text
        self._recovered += 1

    def _tombstone(mut self, seq: Int) raises:
        """ACK / REMOVE tombstone: one live message drops by ordinal.

        Empty/out-of-order tombstones (unknown seq) are ignored silently —
        the bounded replay keeps going deterministically."""
        if seq < 0:
            return
        var s = UInt64(seq)
        if s not in self._owner:
            return
        var qname = self._owner[s]
        var qi = self._qi(qname)
        if qi < 0:
            return
        var kept = List[RecoveredMessage]()
        while len(self._queues[qi].msgs) > 0:
            var m = self._queues[qi].msgs.pop(0)
            if m.seq == s:
                self._removed += 1
                _ = self._owner.pop(s)
            else:
                kept.append(m^)
        self._queues[qi].msgs = kept^

    def _apply_redeliver(mut self, seq: Int) raises:
        """REDELIVER tombstone: bump one live message's recovery counter."""
        if seq < 0:
            return
        var s = UInt64(seq)
        if s not in self._owner:
            return
        var qname = self._owner[s]
        var qi = self._qi(qname)
        if qi < 0:
            return
        for i in range(len(self._queues[qi].msgs)):
            if self._queues[qi].msgs[i].seq == s:
                self._queues[qi].msgs[i].bumps += 1
                return

    def finalize(mut self) -> RecoveredTopology:
        """Fold the replayed state into the materialization topology."""
        var topo = RecoveredTopology()
        while len(self._exchanges) > 0:
            topo.exchanges.append(self._exchanges.pop())
        while len(self._queues) > 0:
            topo.queues.append(self._queues.pop())
        while len(self._bindings) > 0:
            topo.bindings.append(self._bindings.pop())
        topo.recovered_messages = self._recovered
        topo.removed_total = self._removed
        topo.tail_truncated = self._tail
        return topo^


def _queue_names(ref qs: List[RecoveredQueue]) -> List[String]:
    var out = List[String]()
    for i in range(len(qs)):
        out.append(qs[i].name)
    return out^


# ---- the Router-facing journal -------------------------------------------------------

struct MessageJournal(Movable):
    """The single storage object the Router/engine holds.

    Modes:
      - disabled (DEFAULT): no fs access, no RAM pages, no write class; the
        write surfaces all return -1 and the replay is empty (today's path,
        byte-identical).
      - memory: a byte-identical RAM WAL (MemoryStorage).
      - file: a WAL appended through the injected SystemFileSystemOps
        (FileStorage[SystemFileSystemOps]); the handle opens LAZY at the
        first write, so configuring-but-unused storage touches no fs.
    """

    var _mode: Int
    var _mem: MemoryStorage
    var _file: FileStorage[SystemFileSystemOps]

    def __init__(out self):
        """The disabled DEFAULT."""
        self._mode = STORAGE_MODE_DISABLED()
        self._mem = MemoryStorage()
        var ops = SystemFileSystemOps()
        var empty = String("")
        self._file = FileStorage[SystemFileSystemOps](ops^, empty^)

    @staticmethod
    def memory() -> MessageJournal:
        """RAM mode."""
        var j = MessageJournal()
        j._mode = STORAGE_MODE_MEMORY()
        return j^

    @staticmethod
    def file(var path: String, var ops: SystemFileSystemOps) -> MessageJournal:
        """File mode through the injected ops."""
        var j = MessageJournal()
        j._mode = STORAGE_MODE_FILE()
        j._file = FileStorage[SystemFileSystemOps](ops^, path^)
        return j^

    def enabled(ref self) -> Bool:
        "Whether any storage class exists at all."
        return self._mode != 0

    def mode(ref self) -> Int:
        return self._mode

    @staticmethod
    def memory_from_bytes(var pages: List[UInt8]) -> MessageJournal:
        """A RAM journal seeded with pre-baked pages (a fresh-engine
        recovery fixture: the same WAL bytes, one new MessageJournal)."""
        var j = MessageJournal()
        j._mode = STORAGE_MODE_MEMORY()
        j._mem = MemoryStorage()
        for i in range(len(pages)):
            j._mem._page.append(pages[i])
        return j^

    # ---- write surface (the Router's ceremonial OWN recording surface) ----

    def write_queue_declare(
        mut self,
        var name: String,
        durable: Bool,
        capacity: Int,
        ttl_ms: Int,
        max_length: Int,
        overflow_reject: Bool,
        var dlx: String,
        var dlrk: String,
    ) raises -> Int:
        """The DECLARE_QUEUE record (x-args in one deterministic blob)."""
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, name^)
        body.append(UInt8(1 if durable else 0))
        _put_u64(body, UInt64(capacity))
        _put_u64(body, UInt64(ttl_ms))
        _put_u64(body, UInt64(max_length))
        body.append(UInt8(1 if overflow_reject else 0))
        _put_str(body, dlx^)
        _put_str(body, dlrk^)
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_DECLARE_QUEUE(), body^)
        return self._file.write_bytes(RECORD_DECLARE_QUEUE(), body^)

    def write_exchange_declare(
        mut self, var name: String, type_code: Int
    ) raises -> Int:
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, name^)
        _put_u64(body, UInt64(type_code))
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_DECLARE_EXCHANGE(), body^)
        return self._file.write_bytes(RECORD_DECLARE_EXCHANGE(), body^)

    def write_exchange_delete(mut self, var name: String) raises -> Int:
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, name^)
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_DELETE_EXCHANGE(), body^)
        return self._file.write_bytes(RECORD_DELETE_EXCHANGE(), body^)

    def write_bind(
        mut self,
        var exchange: String,
        var destination: String,
        var routing_key: String,
        e2e: Bool,
    ) raises -> Int:
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, exchange^)
        _put_str(body, destination^)
        _put_str(body, routing_key^)
        body.append(UInt8(1 if e2e else 0))
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_BIND(), body^)
        return self._file.write_bytes(RECORD_BIND(), body^)

    def write_delete_queue(mut self, var name: String) raises -> Int:
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, name^)
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_DELETE_QUEUE(), body^)
        return self._file.write_bytes(RECORD_DELETE_QUEUE(), body^)

    def write_purge(mut self, var name: String) raises -> Int:
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, name^)
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_PURGE(), body^)
        return self._file.write_bytes(RECORD_PURGE(), body^)

    def write_enqueue(
        mut self,
        var queue: String,
        var rk: String,
        prop_flags: UInt16,
        prop_bytes: List[UInt8],
        payload: List[UInt8],
        stamp_ns: Int,
    ) raises -> Int:
        """The MSG record: queue + routing key + props (bytes preserved for
        redelivery) + payload + the enqueue stamp. Returns the message's seq
        (the record ordinal) or -1 (disabled tier / skipped)."""
        if self._mode == 0:
            return -1
        var body = List[UInt8]()
        _put_str(body, queue^)
        _put_str(body, rk^)
        _put_u16(body, prop_flags)
        _put_u32(body, UInt32(len(prop_bytes)))
        for i in range(len(prop_bytes)):
            body.append(prop_bytes[i])
        _put_u32(body, UInt32(len(payload)))
        for i in range(len(payload)):
            body.append(payload[i])
        _put_u64(body, UInt64(stamp_ns))
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_MSG(), body^)
        return self._file.write_bytes(RECORD_MSG(), body^)

    def write_ack(mut self, seq: Int) raises -> Int:
        """The ACK tombstone (the delivery state is fresh-empty after it)."""
        if self._mode == 0 or seq < 0:
            return -1
        var body = List[UInt8]()
        _put_u64(body, UInt64(seq))
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_ACK(), body^)
        return self._file.write_bytes(RECORD_ACK(), body^)

    def write_redeliver(mut self, seq: Int) raises -> Int:
        """The REDELIVER bump marker (requeue acceptance)."""
        if self._mode == 0 or seq < 0:
            return -1
        var body = List[UInt8]()
        _put_u64(body, UInt64(seq))
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_REDELIVER(), body^)
        return self._file.write_bytes(RECORD_REDELIVER(), body^)

    def write_remove(mut self, seq: Int) raises -> Int:
        """The tombstone for expiry / dead-letter / drop outcomes (a
        requeued-removal marker verbatim)."""
        if self._mode == 0 or seq < 0:
            return -1
        var body = List[UInt8]()
        _put_u64(body, UInt64(seq))
        if self._mode == 1:
            return self._mem.write_bytes(RECORD_REMOVE(), body^)
        return self._file.write_bytes(RECORD_REMOVE(), body^)

    # ---- recovery surface ---------------------------------------------

    def replay(mut self) raises -> ParsedJournal:
        """Every journal record in order (the EMPTY disabled tier)."""
        if self._mode == 0:
            var empty = ParsedJournal(List[JournalRecord](), 0, True)
            return empty^
        if self._mode == 1:
            return self._mem.replay()
        return self._file.replay()

    def records_written(ref self) -> Int:
        """The total record count (the writer's next-ordinal position)."""
        if self._mode == 0:
            return 0
        if self._mode == 1:
            return self._mem.records_written()
        return self._file.records_written()

    def mem_pages(ref self) -> List[UInt8]:
        """Owned copy of the RAM WAL pages (a recovery fixture accessor)."""
        if self._mode == 1:
            return self._mem.journal_bytes()
        return List[UInt8]()

    def sync(mut self) raises:
        """Flush the file WAL (no-op elsewhere)."""
        if self._mode == 2:
            self._file.sync()

    def close(mut self):
        if self._mode == 2:
            self._file.close()
