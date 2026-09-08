# Tests for transport abstraction.

from std.collections import Optional
from hyrx.transport.transport import TransportConfig, TransportStats, TransportConnection

from hyrx.testing import check

def test_config_defaults() raises:
    var config = TransportConfig()
    check(config.max_connections == 1024, "L8 expect: config.max_connections == 1024")
    check(config.max_frame_size == 131072, "L9 expect: config.max_frame_size == 131072")
    check(config.send_buffer_size == 65536, "L10 expect: config.send_buffer_size == 65536")
    check(config.recv_buffer_size == 65536, "L11 expect: config.recv_buffer_size == 65536")
    print("  config defaults: OK")

def test_stats_init() raises:
    var stats = TransportStats()
    check(stats.bytes_sent == 0, "L16 expect: stats.bytes_sent == 0")
    check(stats.bytes_received == 0, "L17 expect: stats.bytes_received == 0")
    check(stats.messages_sent == 0, "L18 expect: stats.messages_sent == 0")
    check(stats.messages_received == 0, "L19 expect: stats.messages_received == 0")
    check(stats.connections_active == 0, "L20 expect: stats.connections_active == 0")
    check(stats.connections_total == 0, "L21 expect: stats.connections_total == 0")
    print("  stats init: OK")

def test_connection_lifecycle() raises:
    var conn = TransportConnection(1)
    check(conn.is_connected(), "L26 expect: conn.is_connected()")
    check(conn.id() == 1, "L27 expect: conn.id() == 1")
    check(conn.bytes_sent() == 0, "L28 expect: conn.bytes_sent() == 0")
    check(conn.bytes_received() == 0, "L29 expect: conn.bytes_received() == 0")

    conn.disconnect()
    check(not conn.is_connected(), "L32 expect: not conn.is_connected()")
    print("  connection lifecycle: OK")

def test_multiple_connections() raises:
    var c1 = TransportConnection(100)
    var c2 = TransportConnection(200)
    check(c1.id() == 100, "L38 expect: c1.id() == 100")
    check(c2.id() == 200, "L39 expect: c2.id() == 200")
    c1.disconnect()
    check(not c1.is_connected(), "L41 expect: not c1.is_connected()")
    check(c2.is_connected(), "L42 expect: c2.is_connected()")
    print("  multiple connections: OK")

def main() raises:
    print("TRANSPORT_TEST")
    test_config_defaults()
    test_stats_init()
    test_connection_lifecycle()
    test_multiple_connections()
    print("TRANSPORT_TEST=PASS")
