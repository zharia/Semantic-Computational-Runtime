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


# serve_one_frame() outcome codes.
def SERVE_DISPATCHED() -> Int:
    """A frame was parsed and dispatched."""
    return 1


def SERVE_PARTIAL() -> Int:
    """The socket yielded a partial frame only; keep serving."""
    return 0


def SERVE_CLOSED() -> Int:
    """The peer reached EOF/close; the slot is finished."""
    return -1


def SERVE_FAILED() -> Int:
    """A protocol/handler/transport error failed the connection closed.

    The broker itself stays alive and keeps accepting: a hostile frame is
    per-connection damage only (audit §13/§29).
    """
    return -2


struct AMQPListener:
    """Broker accept-loop over the Hyrx TCP transport contract."""

    var _transport: TCPListener
    var _service: AMQPService
    var _conns: List[Optional[TCPConnection]]
    var _codecs: List[AMQPFrameCodec]
    var _closed: List[Bool]
    var _running: Bool
    var _frame_max: Int
    var _max_connections: Int
    var _active: Int
    var _refused: Int

    def __init__(out self, var config: HyrxMQConfig):
        var tcfg = TransportConfig()
        tcfg.max_connections = config.max_connections
        tcfg.max_frame_size = config.frame_max
        # NOTE: tcfg.max_connections is descriptive here; the transport wrapper
        # does not enforce it (TECH DEBT: enforce in one place). The authority
        # is this listener's accept gate below (_max_connections).
        self._max_connections = config.max_connections
        # Enforced ceiling handed to every per-connection codec. Real
        # connection.tune frame_max negotiation is NOT IMPLEMENTED, so this is
        # a fixed ceiling taken from the validated configuration.
        self._frame_max = config.frame_max
        # port == 0 asks the kernel for an ephemeral port; see port().
        self._transport = TCPListener(config.listen_host, config.port, tcfg^)
        self._service = AMQPService(config^)
        self._conns = List[Optional[TCPConnection]]()
        self._codecs = List[AMQPFrameCodec]()
        self._closed = List[Bool]()
        self._running = False
        self._active = 0
        self._refused = 0

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

    def active_connections(ref self) -> Int:
        """Connections currently open (not yet failed/closed)."""
        return self._active

    def refused_connections(ref self) -> Int:
        """Accepts dropped because the connection ceiling was reached."""
        return self._refused

    def accept_one(mut self) raises -> Int:
        """Accept one pending connection; return its slot index.

        Blocks until a client has connected (bind -> connect -> accept).

        Returns -1 when the connection is REFUSED: the configured
        `max_connections` ceiling is reached, so the accepted socket is closed
        immediately without any AMQP handling (fail closed: the client sees a
        connect followed by EOF; the broker keeps listening).
        """
        var conn = self._transport.accept_connection()
        if not conn.__bool__():
            raise "AMQPListener.accept_one: accept returned no connection"
        if self._active >= self._max_connections:
            self._refused += 1
            self._drop(conn^)
            return -1
        var slot = len(self._conns)
        self._conns.append(conn^)
        self._codecs.append(AMQPFrameCodec(self._frame_max))
        self._closed.append(False)
        self._active += 1
        return slot

    def _drop(mut self, var conn: Optional[TCPConnection]):
        """Close an accepted connection that will never be served."""
        if conn.__bool__():
            try:
                conn.value().close()
            except:
                pass

    def _close_slot(mut self, slot: Int):
        """Best-effort socket close for a slot; never propagates an error."""
        if self._closed[slot]:
            return
        self._closed[slot] = True
        self._active -= 1
        if self._conns[slot].__bool__():
            try:
                self._conns[slot].value().close()
            except:
                pass

    def serve_one_frame(mut self, slot: Int) -> Int:
        """Advance one connection by at most one frame. NEVER raises.

        Returns SERVE_DISPATCHED (1) when a frame was dispatched (response, if
        any, written), SERVE_PARTIAL (0) when the socket yielded a partial
        frame only, SERVE_CLOSED (-1) on EOF/close and SERVE_FAILED (-2) when
        any recv/parse/handle error occurred — in the latter two cases the
        connection is closed here and the listener keeps serving other
        connections. No malformed frame, undeclared-queue raise or socket error
        can reach the accept loop or terminate the process.
        """
        try:
            return self._serve_step(slot)
        except:
            if slot >= 0 and slot < len(self._closed):
                self._close_slot(slot)
            return SERVE_FAILED()

    def _serve_step(mut self, slot: Int) raises -> Int:
        """The one-frame step; every error is the caller's to fail closed."""
        if slot < 0 or slot >= len(self._conns):
            raise "AMQPListener.serve_one_frame: bad slot"
        if self._closed[slot]:
            return SERVE_CLOSED()
        if not self._conns[slot].__bool__():
            return SERVE_CLOSED()

        # Ownership note (Mojo 1.0): non-copyable values are reached through
        # chained calls on the containers, never bound to `var` (implicit copy).
        var frame = self._codecs[slot].try_parse_frame()
        if not frame.__bool__():
            # Read no more than the codec can still hold: if the configured
            # frame_max is below _READ_SIZE(), an oversized read would make the
            # codec reject a perfectly well-behaved client.
            var want = _READ_SIZE()
            var room = (
                self._codecs[slot].frame_limit()
                + 8
                - self._codecs[slot].buffered_bytes()
            )
            if want > room:
                want = room
            var chunk = self._conns[slot].value().recv_bytes(want)
            if len(chunk) == 0:
                self._close_slot(slot)
                return SERVE_CLOSED()
            self._codecs[slot].feed_bytes(chunk^)
            frame = self._codecs[slot].try_parse_frame()
            if not frame.__bool__():
                return SERVE_PARTIAL()

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
            self._close_slot(slot)
        return SERVE_DISPATCHED()

    def accept_and_serve_one(mut self) raises -> Int:
        """Accept one connection and serve frames until the peer closes it.

        Returns the number of frames dispatched. Blocks while the client
        keeps the connection open; terminates on EOF, connection.close or a
        failed (hostile) connection. A refused accept counts as zero frames:
        the loop returns and the next client is accepted."""
        var slot = self.accept_one()
        if slot < 0:
            return 0
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
        is process-level (systemd signal), documented in the unit.

        Fail-closed containment (audit §13/§29): per-connection damage is fully
        absorbed by serve_one_frame(), so NO malformed frame, handler raise or
        socket error on a connection can reach here. The only raises left are
        accept-layer ones (listener not usable); those intentionally exit to
        main() so systemd restarts the unit under its StartLimit* rate limit —
        the alternative (spinning on a dead listener) is worse, and Mojo 1.0
        exposes no portable sleep here to back off.
        """
        while self._running:
            _ = self.accept_and_serve_one()
