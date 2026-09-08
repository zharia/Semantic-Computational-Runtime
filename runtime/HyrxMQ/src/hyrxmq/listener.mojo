# HyrxMQ AMQP-over-TCP listener (Phase 7 unblock).

# Glue layer: real TCP bytes <-> AMQP frames <-> AMQPService (the broker's
# frame front-end). It performs NO message semantics of its own — routing
# authority stays with the single HyrxMQBroker composed by AMQPService.

# Provider containment (ADR-0005): the socket comes from
# `hyrx.transport.tcp` (our TCPListener/TCPConnection wrapper over flare); this
# file must never import flare directly.

from std.collections import List, Optional

from hyrx.transport.transport import TransportConfig
from hyrx.transport.tcp import TCPListener, TCPConnection

from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.amqp.constants import CONNECTION_CLOSE, FRAME_METHOD, MethodID

from hyrxmq.amqp_service import AMQPService
from hyrxmq.config import HyrxMQConfig
from hyrxmq.status import BrokerStatus


# One read chunk per socket step; the codec reassembles across steps.
def _READ_SIZE() -> Int:
    return 65536


struct AMQPListener:
    """Broker accept-loop over the Hyrx TCP transport contract."""

    var _transport: TCPListener
    var _service: AMQPService
    var _conns: List[Optional[TCPConnection]]
    var _codecs: List[AMQPFrameCodec]
    var _closed: List[Bool]
    var _running: Bool

    def __init__(out self, var config: HyrxMQConfig):
        var tcfg = TransportConfig()
        tcfg.max_connections = config.max_connections
        tcfg.max_frame_size = config.frame_max
        # port == 0 asks the kernel for an ephemeral port; see port().
        self._transport = TCPListener(config.listen_host, config.port, tcfg^)
        self._service = AMQPService(config^)
        self._conns = List[Optional[TCPConnection]]()
        self._codecs = List[AMQPFrameCodec]()
        self._closed = List[Bool]()
        self._running = False

    # ---- lifecycle ----

    def start(mut self) raises -> Bool:
        """Start the broker service and bind the TCP listener."""
        self._service.start()
        var ok = self._transport.start()
        self._running = ok
        return ok

    def port(mut self) raises -> Int:
        """The actual bound port (reflects the ephemeral port when 0)."""
        return self._transport.port()

    def stop(mut self):
        self._running = False
        self._transport.stop()
        self._service.shutdown()

    def health(mut self) -> String:
        return self._service.health()

    def status(mut self) -> BrokerStatus:
        return self._service.status()

    # ---- serving ----

    def accept_one(mut self) raises -> Int:
        """Accept one pending connection; return its slot index.

        Blocks until a client has connected (bind -> connect -> accept)."""
        var conn = self._transport.accept_connection()
        if not conn.__bool__():
            raise "AMQPListener.accept_one: accept returned no connection"
        var slot = len(self._conns)
        self._conns.append(conn^)
        self._codecs.append(AMQPFrameCodec())
        self._closed.append(False)
        return slot

    def serve_one_frame(mut self, slot: Int) raises -> Int:
        """Advance one connection by at most one frame.

        Returns 1 when a frame was dispatched (response, if any, written),
        0 when the socket yielded a partial frame only, -1 on EOF/close.
        The step API lets a single-threaded test interleave client writes
        with server progress; nothing can block unboundedly when the peer
        is in the same process and has already written."""
        if slot < 0 or slot >= len(self._conns):
            raise "AMQPListener.serve_one_frame: bad slot"
        if self._closed[slot]:
            return -1
        if not self._conns[slot].__bool__():
            return -1

        # Ownership note (Mojo 1.0): non-copyable values are reached through
        # chained calls on the containers, never bound to `var` (implicit copy).
        var frame = self._codecs[slot].try_parse_frame()
        if not frame.__bool__():
            var chunk = self._conns[slot].value().recv_bytes(_READ_SIZE())
            if len(chunk) == 0:
                self._conns[slot].value().close()
                self._closed[slot] = True
                return -1
            self._codecs[slot].feed_bytes(chunk^)
            frame = self._codecs[slot].try_parse_frame()
            if not frame.__bool__():
                return 0

        # Close-detection is byte glue only: class/method ids of a method
        # frame, no routing semantics.
        var p = frame.value().payload_copy()
        var is_close = False
        if frame.value().frame_type == FRAME_METHOD() and len(p) >= 4:
            var class_id = (UInt16(p[0]) << 8) | UInt16(p[1])
            var method_id = (UInt16(p[2]) << 8) | UInt16(p[3])
            is_close = MethodID(class_id, method_id) == CONNECTION_CLOSE()

        var conn_id = self._conns[slot].value().conn_id()
        var resp = self._service.handle_frame(conn_id, frame.value())
        if resp.__bool__():
            self._conns[slot].value().send_bytes(resp.value().copy())

        if is_close:
            self._conns[slot].value().close()
            self._closed[slot] = True
        return 1

    def accept_and_serve_one(mut self) raises -> Int:
        """Accept one connection and serve frames until the peer closes it.

        Returns the number of frames dispatched. Blocks while the client
        keeps the connection open; terminates on EOF or connection.close."""
        var slot = self.accept_one()
        var served = 0
        while self._running:
            var rc = self.serve_one_frame(slot)
            if rc < 0:
                break
            served += rc
        return served

    def serve_forever(mut self) raises:
        """The binary's accept loop: one connection at a time, to completion.

        Vertical-slice serialization: each client is served fully before the
        next is accepted. stop() cannot preempt a blocked accept(); shutdown
        is process-level (systemd signal), documented in the unit."""
        while self._running:
            _ = self.accept_and_serve_one()
