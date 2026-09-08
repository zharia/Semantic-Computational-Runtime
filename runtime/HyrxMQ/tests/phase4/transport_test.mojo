# Tests for transport abstraction.

from std.collections import Optional
from hyrx.transport.transport import TransportConfig, TransportStats, TransportConnection

def test_config_defaults() raises:
    var config = TransportConfig()
    assert config.max_connections == 1024
    assert config.max_frame_size == 131072
    assert config.send_buffer_size == 65536
    assert config.recv_buffer_size == 65536
    print("  config defaults: OK")

def test_stats_init() raises:
    var stats = TransportStats()
    assert stats.bytes_sent == 0
    assert stats.bytes_received == 0
    assert stats.messages_sent == 0
    assert stats.messages_received == 0
    assert stats.connections_active == 0
    assert stats.connections_total == 0
    print("  stats init: OK")

def test_connection_lifecycle() raises:
    var conn = TransportConnection(1)
    assert conn.is_connected()
    assert conn.id() == 1
    assert conn.bytes_sent() == 0
    assert conn.bytes_received() == 0

    conn.disconnect()
    assert not conn.is_connected()
    print("  connection lifecycle: OK")

def test_multiple_connections() raises:
    var c1 = TransportConnection(100)
    var c2 = TransportConnection(200)
    assert c1.id() == 100
    assert c2.id() == 200
    c1.disconnect()
    assert not c1.is_connected()
    assert c2.is_connected()
    print("  multiple connections: OK")

def main() raises:
    print("TRANSPORT_TEST")
    test_config_defaults()
    test_stats_init()
    test_connection_lifecycle()
    test_multiple_connections()
    print("TRANSPORT_TEST=PASS")
