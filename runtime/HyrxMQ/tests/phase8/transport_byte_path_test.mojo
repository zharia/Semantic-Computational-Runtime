# Byte-exactness guard over the LIVE transport read path (recv_bytes).

# Increment 0007 replaced the per-octet read loop in TCPConnection.recv_bytes
# (and UDSConnection.recv_bytes) with one blocking read into an
# unsafe_uninit_length buffer plus a `resize` shrink when `got != max_bytes`.
# Nothing outside docker/E2E drove that function over a real socket at
# 64 KiB/128 KiB, so this file is the byte-path guard for the transport
# contract itself: real loopback sockets, real kernel buffers, exact compare.
#
# Single-threaded bind -> connect -> accept, the ordering already used by
# tests/integration/socket_behavior.mojo: `connect` completes against the
# listener backlog, so `accept_connection` never needs to be polled and no
# sleep is required anywhere.
#
# Deadlock discipline: every exchange alternates writes and draining reads, so
# the amount of undrained data in flight is bounded by one write chunk (at most
# 16384 octets) and can never fill the socket buffers while nobody reads.
#
# Mojo `assert` is inert in this toolchain (see src/hyrx/testing.mojo), so every
# assertion goes through `check`; a false condition raises and exits non-zero.

from std.collections import List, Optional

from hyrx.testing import check
from hyrx.transport.tcp import TCPConnection, TCPListener
from hyrx.transport.transport import TransportConfig


# ---------- pattern + byte helpers (same generator as byte_path_test) ----------

def pat_byte(i: Int) -> UInt8:
    """Deterministic pattern byte: (i*31+7) % 256."""
    return UInt8((i * 31 + 7) % 256)


def pattern(n: Int) -> List[UInt8]:
    """A fresh owned list holding the first n pattern bytes."""
    var out = List[UInt8](capacity=n)
    for i in range(n):
        out.append(pat_byte(i))
    return out^


def eq(a: List[UInt8], b: List[UInt8]) -> Bool:
    """Byte-for-byte equality; both lists are consumed."""
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def append_all(mut dst: List[UInt8], var src: List[UInt8]):
    for i in range(len(src)):
        dst.append(src[i])


def read_max() -> Int:
    """The `max_bytes` every guarded read uses — the size that hits the fix."""
    return 65536


def size_count() -> Int:
    """Number of guarded sizes."""
    return 13


def size_at(i: Int) -> Int:
    """Guarded size set: 0,1,2,3,7,8,127,128,255,4096,16384,65536,131072."""
    if i == 0:
        return 0
    elif i == 1:
        return 1
    elif i == 2:
        return 2
    elif i == 3:
        return 3
    elif i == 4:
        return 7
    elif i == 5:
        return 8
    elif i == 6:
        return 127
    elif i == 7:
        return 128
    elif i == 8:
        return 255
    elif i == 9:
        return 4096
    elif i == 10:
        return 16384
    elif i == 11:
        return 65536
    return 131072


# ---------- the exchange driver ----------

def exchange(
    mut client: TCPConnection,
    mut server: Optional[TCPConnection],
    size: Int,
    write_chunk: Int,
    mut acc: List[UInt8],
    mut partial_reads: Int,
    mut full_reads: Int,
) raises:
    """Push `size` pattern octets client -> server, accumulating in `acc`.

    The client writes at most `write_chunk` octets per `send_bytes` before the
    server is allowed to drain, so in-flight data stays bounded. Every server
    read is `recv_bytes(read_max())`, the exact call the 0007 fix changed:
    `partial_reads` counts the reads that returned fewer than `read_max()`
    octets (the shrink branch), `full_reads` the reads that filled the request.
    """
    var written = 0
    while written < size or len(acc) < written:
        if written < size:
            var n = write_chunk
            if size - written < n:
                n = size - written
            var part = List[UInt8](capacity=n)
            for i in range(n):
                part.append(pat_byte(written + i))
            check(
                client.send_bytes(part^) == n,
                "exchange: send_bytes reports the octet count",
            )
            written += n
        if len(acc) < written:
            var chunk = server.value().recv_bytes(read_max())
            check(
                len(chunk) > 0,
                "exchange: EOF before the pattern was complete",
            )
            if len(chunk) == read_max():
                full_reads += 1
            else:
                partial_reads += 1
            append_all(acc, chunk^)


# ---------- 1: exact delivery at every guarded size ----------

def test_sizes_exact() raises:
    """recv_bytes(65536) accumulates the pattern exactly, 0 .. 131072 octets."""
    for si in range(size_count()):
        var size = size_at(si)
        var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
        check(listener.start(), "sizes: listener start")
        var client = TCPConnection.connect("127.0.0.1", listener.port())
        var server = listener.accept_connection()
        check(server.__bool__(), "sizes: connection accepted")

        var acc = List[UInt8]()
        var partial = 0
        var full = 0
        # One whole-pattern write up to 16 KiB; larger sizes go out in 16 KiB
        # writes drained between each, so the kernel buffers cannot deadlock.
        var chunk = size
        if chunk > 16384:
            chunk = 16384
        exchange(client, server, size, chunk, acc, partial, full)

        check(len(acc) == size, "sizes: octet count exact")
        var want = pattern(size)
        check(eq(want^, acc^), "sizes: bytes exact")
        check(partial + full > 0 or size == 0, "sizes: read path ran")

        server.value().close()
        client.close()
        listener.stop()


# ---------- 2: partial feed (shrink branch of the 0007 fix) ----------

def _feed_case(chunk: Int, size: Int) raises:
    """Send `size` octets in `chunk`-octet writes; the server must reassemble."""
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "feed: listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "feed: connection accepted")

    var acc = List[UInt8]()
    var partial = 0
    var full = 0
    exchange(client, server, size, chunk, acc, partial, full)

    check(len(acc) == size, "feed: octet count exact")
    var want = pattern(size)
    check(
        eq(want^, acc^),
        "feed: bytes exact under " + String(chunk) + "-octet writes",
    )
    # Octet-granular writes mean no read can ever see a full 64 KiB request, so
    # a zero count here would mean the shrink branch never executed.
    check(partial > 0, "feed: shrink branch (got != max_bytes) exercised")
    check(
        partial <= size,
        "feed: read count bounded by the octet count",
    )

    server.value().close()
    client.close()
    listener.stop()


def test_partial_feed_shrink_branch() raises:
    """65536 and 131072 octets arrive as single-octet and 3-octet writes."""
    _feed_case(1, 65536)
    _feed_case(3, 65536)
    _feed_case(1, 131072)
    _feed_case(3, 131072)


# ---------- 3: empty-read / EOF contract ----------

def test_empty_read_contract() raises:
    """A non-positive request reads nothing; a closed peer reads empty."""
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "eof: listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "eof: connection accepted")

    var size = 4096
    var acc = List[UInt8]()
    var partial = 0
    var full = 0
    exchange(client, server, size, size, acc, partial, full)
    var want = pattern(size)
    check(eq(want^, acc^), "eof: exchange complete before the close")

    # max_bytes <= 0 must short-circuit to an empty list without touching the
    # socket (a blocking read here would hang the test).
    check(
        len(server.value().recv_bytes(0)) == 0,
        "eof: recv_bytes(0) returns an empty list",
    )
    check(
        len(server.value().recv_bytes(-1)) == 0,
        "eof: recv_bytes(negative) returns an empty list",
    )

    client.close()  # FIN: the server side observes end of stream
    var eof = server.value().recv_bytes(read_max())
    check(len(eof) == 0, "eof: read after peer close returns an empty list")
    var again = server.value().recv_bytes(read_max())
    check(len(again) == 0, "eof: repeated read after close stays empty")

    server.value().close()
    listener.stop()


def main() raises:
    test_sizes_exact()
    test_partial_feed_shrink_branch()
    test_empty_read_contract()
    print("TRANSPORT_BYTE_PATH_TEST=PASS")
