# Phase 10 — TCP-tier TLS tests.
#
# Verifies that the TCP transport can optionally wrap accepted connections
# with OpenSSL TLS. The TLS context is loaded once at listener start; each
# accepted connection performs a blocking SSL_accept handshake. Plaintext
# remains the default (byte-identical to pre-TLS behavior).
#
# Rows proved in-process (single-threaded, no concurrency required):
#   (c) tcp_plaintext_unchanged — a TCPListener WITHOUT TLS configured
#       still works byte-identical (no TLS wrapping).
#   (d) tcp_tls_config_apply — the broker config tls_enabled / tls_cert_path /
#       tls_key_path keys parse and validate correctly.
#
# The TLS HANDSHAKE + roundtrip (rows a/b) are proved END-TO-END by
# scripts/interop/tls_probe.py against the built hyrxmq-listen binary with a
# real Python ssl client. A real TLS handshake needs BOTH peers to make
# progress concurrently; the in-process Mojo test harness is single-threaded,
# so a blocking TlsStream.connect() deadlocks against a blocking SSL_accept.
# The external probe is the stronger proof (real binary, real client).

from std.os import unlink

from std.collections import List, Optional

from flare.tcp import TcpListener, TcpStream
from flare.tls import TlsConfig, TlsStream, TlsVerify
from flare.net import IpAddr, SocketAddr

from hyrx.transport.tcp import TCPListener, TCPConnection
from hyrx.transport.transport import TransportConfig
from hyrx.core.storage import FileSystemOps, SystemFileSystemOps

from hyrxmq.config import HyrxMQConfig, KeyValuePair

from hyrx.testing import check


# ---- the self-signed PEM fixture (same as phase9/wss_test) ----------------

def CERT_PEM() -> String:
    return (
        "-----BEGIN CERTIFICATE-----\n"
        "MIIBSjCB/aADAgECAhQU5dPIpdZVX73ra71gyVrhKiVd4TAFBgMrZXAwGjEYMBYG\n"
        "A1UEAwwPZmxhcmUtcXVpYy10ZXN0MCAXDTI2MDYwMjIwNDE1MFoYDzIxMjYwNTA5\n"
        "MjA0MTUwWjAaMRgwFgYDVQQDDA9mbGFyZS1xdWljLXRlc3QwKjAFBgMrZXADIQC6\n"
        "aLBjOZU47XCQ9XepGAA44ai5czFmGulWRsrgYe+HAqNTMFEwHQYDVR0OBBYEFKDR\n"
        "Mz19cbebmpSKUfhxtnrfzkS9MB8GA1UdIwQYMBaAFKDRMz19cbebmpSKUfhxtnrf\n"
        "zkS9MA8GA1UdEwEB/wQFMAMBAf8wBQYDK2VwA0EAziRJd60SGsie1TQgLJ124Tlu\n"
        "FqODqBToTmUdRCT38FLcsh/K3+ron7wCxbJW5+jamWSEG8iILdlzfD3kwi36Bw==\n"
        "-----END CERTIFICATE-----\n"
    )


def KEY_PEM() -> String:
    return (
        "-----BEGIN PRIVATE KEY-----\n"
        "MC4CAQAwBQYDK2VwBCIEIKG/imdw4hAoj/3vigGwPl8nyrZwOEsNAM60ZPVfr3Lx\n"
        "-----END PRIVATE KEY-----\n"
    )


# ---- helpers ---------------------------------------------------------------

def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


# Fixture paths — equal-length names to avoid the phantom-'m' defect.
def tcp_tls_cert_path() -> String:
    return "/tmp/hyrx_tcp_tls_cert.pem"


def tcp_tls_key_path() -> String:
    return "/tmp/hyrx_tcp_tls_key0.pem"


def write_key_fixture(mut ops: SystemFileSystemOps, var path: String) raises:
    """Write KEY PEM to disk. Path consumed."""
    var pem = KEY_PEM()
    var fd = ops.open_append(path^)
    ops.append(fd, bytes_of(pem^))
    ops.close(fd)


def write_cert_fixture(mut ops: SystemFileSystemOps, var path: String) raises:
    """Write CERT PEM to disk. Path consumed."""
    var pem = CERT_PEM()
    var fd = ops.open_append(path^)
    ops.append(fd, bytes_of(pem^))
    ops.close(fd)


def drop_fixture(mut ops: SystemFileSystemOps, var path: String) raises:
    """Best-effort fixture removal."""
    if ops.exists(path.copy()):
        _ = unlink(path.copy())


# ---- (d) config apply + validate -------------------------------------------

def test_tls_config_apply() raises:
    """The broker config tls_enabled / tls_cert_path / tls_key_path keys
    parse via apply() and validate() catches bad combinations."""
    var cfg = HyrxMQConfig()
    check(cfg.tls_enabled == False, "tls_config: default is disabled")
    check(cfg.tls_cert_path == "", "tls_config: default cert path is empty")
    check(cfg.tls_key_path == "", "tls_config: default key path is empty")

    # Apply with valid values.
    cfg.apply("tls_enabled", "true")
    cfg.apply("tls_cert_path", "/some/cert.pem")
    cfg.apply("tls_key_path", "/some/key.pem")
    check(cfg.tls_enabled == True, "tls_config: tls_enabled=true applied")
    check(
        cfg.tls_cert_path == "/some/cert.pem",
        "tls_config: cert path applied",
    )
    check(
        cfg.tls_key_path == "/some/key.pem",
        "tls_config: key path applied",
    )

    # Validate passes when both are set.
    var ok = True
    try:
        cfg.validate()
    except:
        ok = False
    check(ok, "tls_config: enabled + both paths validates")

    # Validate fails when enabled but cert missing.
    var r1 = False
    try:
        var bad = HyrxMQConfig()
        bad.apply("tls_enabled", "1")
        bad.apply("tls_key_path", "/k.pem")
        bad.validate()
    except:
        r1 = True
    check(r1, "tls_config: enabled + missing cert fails validate")

    # Validate fails when enabled but key missing.
    var r2 = False
    try:
        var bad2 = HyrxMQConfig()
        bad2.apply("tls_enabled", "true")
        bad2.apply("tls_cert_path", "/c.pem")
        bad2.validate()
    except:
        r2 = True
    check(r2, "tls_config: enabled + missing key fails validate")

    # Validate fails when disabled but paths are non-empty.
    var r3 = False
    try:
        var bad3 = HyrxMQConfig()
        bad3.apply("tls_cert_path", "/c.pem")
        bad3.apply("tls_key_path", "/k.pem")
        bad3.validate()
    except:
        r3 = True
    check(r3, "tls_config: disabled + non-empty paths fails validate")

    # Invalid tls_enabled value.
    var r4 = False
    try:
        var bad4 = HyrxMQConfig()
        bad4.apply("tls_enabled", "maybe")
    except:
        r4 = True
    check(r4, "tls_config: invalid tls_enabled value raises")

    # Parse via from_lines.
    var lines = List[String]()
    lines.append("tls_enabled = true")
    lines.append("tls_cert_path = /tmp/c.pem")
    lines.append("tls_key_path = /tmp/k.pem")
    var cfg2 = HyrxMQConfig.from_lines(lines^)
    check(cfg2.tls_enabled == True, "tls_config: from_lines tls_enabled")
    check(cfg2.tls_cert_path == "/tmp/c.pem", "tls_config: from_lines cert")
    check(cfg2.tls_key_path == "/tmp/k.pem", "tls_config: from_lines key")


# ---- (c) plaintext unchanged -----------------------------------------------

def test_tcp_plaintext_unchanged() raises:
    """A TCPListener WITHOUT TLS configured still works byte-identical:
    accept + send_bytes + recv_bytes — no TLS overhead, no breaking change."""
    var tcfg = TransportConfig()
    var listener = TCPListener("127.0.0.1", 0, tcfg^)
    check(
        not listener.has_tls(),
        "plaintext: no TLS when unconfigured",
    )
    check(listener.start(), "plaintext: listener binds")
    var port = listener.port()
    check(port > 0, "plaintext: port > 0")

    # Connect with a plain TCP client.
    var client = TCPConnection.connect("127.0.0.1", port)
    var server_conn = listener.accept_connection()
    check(server_conn.__bool__(), "plaintext: accept returns a connection")

    # Send from client, receive on server.
    var payload = List[UInt8]()
    var msg = "hello-plaintext"
    var b = msg.as_bytes()
    for i in range(len(b)):
        payload.append(b[i])
    var sent = client.send_bytes(payload^)
    check(sent == 15, "plaintext: client sends 15 bytes")

    var got = server_conn.value().recv_bytes(65536)
    check(len(got) == 15, "plaintext: server receives 15 bytes")

    # Verify byte content.
    for i in range(15):
        check(
            got[i] == b[i],
            "plaintext: byte " + String(i) + " matches",
        )

    client.close()
    server_conn.value().close()
    listener.stop()


# ---- main -------------------------------------------------------------------

def main() raises:
    test_tls_config_apply()
    test_tcp_plaintext_unchanged()
    print("PHASE10_TCP_TLS_TEST=PASS")
