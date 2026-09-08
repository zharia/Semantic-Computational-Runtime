# Transport abstraction for Hyrx messaging.
#
# Every transport must preserve:
# - message identity
# - routing semantics
# - delivery semantics
# - acknowledgement semantics
# - ordering guarantees
# - backpressure semantics
# - failure semantics

from std.collections import Dict, List

# Shared byte-transport contract for a live connection (TCP or UDS).
#
# This is the ONLY abstraction the AMQP listener is allowed to lean on when it
# serves bytes off a socket: `conn_id`/`recv_bytes`/`send_bytes`/`close` have
# identical signatures on TCPConnection (tcp.mojo) and UDSConnection (uds.mojo),
# so a single serving implementation can drive either backend. Mojo 1.0.0 needs
# a trait (its `interface`) to resolve these calls through a `Type: Trait` bound
# — a generic with no bound fails ("value has no attribute"). It carries no
# behavior, only the required surface, and imposes no flare dependency.
trait AMQPConn(Movable, Deinitable):
    def conn_id(ref self) -> UInt64:
        """Stable id for the broker's per-connection state."""
        ...

    def recv_bytes(mut self, max_bytes: Int) raises -> List[UInt8]:
        """One read of up to `max_bytes`; empty result means EOF."""
        ...

    def send_bytes(mut self, var data: List[UInt8]) raises -> Int:
        """Write every byte of `data` (consumed); returns bytes written."""
        ...

    def close(mut self):
        """Close the connection."""
        ...


struct TransportConfig:
    """Configuration for a transport."""
    var max_connections: Int
    var max_frame_size: Int
    var send_buffer_size: Int
    var recv_buffer_size: Int

    def __init__(out self):
        self.max_connections = 1024
        self.max_frame_size = 131072  # 128 KB
        self.send_buffer_size = 65536
        self.recv_buffer_size = 65536

struct TransportStats:
    """Statistics for a transport."""
    var bytes_sent: Int
    var bytes_received: Int
    var messages_sent: Int
    var messages_received: Int
    var connections_active: Int
    var connections_total: Int

    def __init__(out self):
        self.bytes_sent = 0
        self.bytes_received = 0
        self.messages_sent = 0
        self.messages_received = 0
        self.connections_active = 0
        self.connections_total = 0

struct TransportConnection:
    """Represents one transport connection (client endpoint)."""
    var _id: UInt64
    var _connected: Bool
    var _bytes_sent: Int
    var _bytes_received: Int

    def __init__(out self, conn_id: UInt64):
        self._id = conn_id
        self._connected = True
        self._bytes_sent = 0
        self._bytes_received = 0

    def is_connected(ref self) -> Bool:
        return self._connected

    def disconnect(mut self):
        self._connected = False

    def id(ref self) -> UInt64:
        return self._id

    def bytes_sent(ref self) -> Int:
        return self._bytes_sent

    def bytes_received(ref self) -> Int:
        return self._bytes_received
