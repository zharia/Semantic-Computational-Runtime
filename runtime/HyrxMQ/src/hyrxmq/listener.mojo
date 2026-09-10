# HyrxMQ AMQP listener (Phase 7 unblock; UDS front end added for the fair
# UDS benchmark cell).

# Glue layer: real socket bytes <-> AMQP frames <-> AMQPService (the broker's
# frame front-end). It performs NO message semantics of its own — routing
# authority stays with the single HyrxMQBroker composed by AMQPService.

# Provider containment (ADR-0005): the socket comes from `hyrx.transport`
# (our TCPListener/UDSListener wrappers over flare); this file must never
# import flare directly.

# Transport-agnostic serving (compile mechanism, evidence in the task report):
# Mojo 1.0.0 rejects a struct-scope `@parameter if` type alias and rejects
# method calls on an unconstrained generic ("value has no attribute"). The one
# form that compiles for these non-copyable, deinit-owning connections is a
# trait bound: `AMQPConnServing[Conn: AMQPConn]`. TCPConnection and
# UDSConnection both already expose `conn_id`/`recv_bytes`/`send_bytes`/`close`
# with identical signatures, so a single serving body drives either backend.
# `AMQPListener` (TCP) and `UDSAMQPListener` (UDS) are thin wrappers that each
# own only the concrete transport; the header -> handshake -> content frame
# state machine lives once, in `AMQPConnServing`.

from std.collections import Dict, List, Optional

from std.ffi import c_int, c_size_t, c_ssize_t, external_call, get_errno, ErrNo
from std.sys.info import CompilationTarget

from hyrx.transport.transport import TransportConfig, AMQPConn
from hyrx.transport.tcp import TCPListener, TCPConnection
from hyrx.transport.uds import UDSListener, UDSConnection
from hyrx.transport.poll import EventPoller, PollEvent
from hyrx.transport.wss import WSSListener, WSSConnection, WssConfig

from hyrx.core.feature_flags import event_driven_serving

from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.amqp.constants import (
    CONNECTION_CLOSE,
    CONNECTION_OPEN_OK,
    FRAME_HEARTBEAT,
    FRAME_METHOD,
    MethodID,
)

from hyrxmq.amqp_service import AMQPService
from hyrxmq.config import HyrxMQConfig
from hyrx.core.storage import FileSystemOps, MessageJournal
from hyrxmq.status import BrokerStatus


# One read chunk per socket step; the codec reassembles across steps.
def _READ_SIZE() -> Int:
    return 65536


# The 8-octet AMQP 0-9-1 protocol header (amqp0-9-1.xml §1.4.2.2): the literal
# "AMQP" (0x41 0x4D 0x51 0x50) followed by \\x00 \\x00 (the deprecated
# line/term/version fields, zeroed) then 0x09 0x01 (major=0 / minor=9 /
# revision=1 encoded as \\x09 \\x01 per the header spec — the wire bytes are
# exactly 41 4D 51 50 00 00 09 01). This is NOT a frame: the first octet 'A'
# (0x41) is not a legal frame_type, so these bytes must be consumed by the
# header stage and never handed to the frame codec.
def PROTOCOL_HEADER_LEN() -> Int:
    return 8


def _protocol_header() -> List[UInt8]:
    var h = List[UInt8]()
    h.append(0x41)  # 'A'
    h.append(0x4D)  # 'M'
    h.append(0x51)  # 'Q'
    h.append(0x50)  # 'P'
    h.append(0x00)
    h.append(0x00)
    h.append(0x09)
    h.append(0x01)
    return h^


# Per-slot serving phase. A connection is advanced header → handshake → ready.
def PHASE_HEADER() -> Int:
    """Awaiting the 8-octet protocol header (not yet fed to the codec)."""
    return 0


def PHASE_HANDSHAKING() -> Int:
    """Header accepted + connection.start sent; awaiting start-ok/tune-ok/open."""
    return 1


def PHASE_READY() -> Int:
    """open-ok sent; business methods flow (and negotiation is behind us)."""
    return 2


def _resp_is_open_ok(ref resp: List[UInt8]) -> Bool:
    """True when the reply's FIRST frame is connection.open-ok (10,41).

    Byte glue only: a method frame is type 1 with class/method ids at payload
    offsets [7:9]/[9:11] (7 = the fixed frame header). The handshake is complete
    once open-ok reaches the client; we never gate business methods on phase, so
    this is only used to move a slot from HANDSHAKING to READY.
    """
    if len(resp) < 11:
        return False
    if resp[0] != FRAME_METHOD():
        return False
    var class_id = (UInt16(resp[7]) << 8) | UInt16(resp[8])
    var method_id = (UInt16(resp[9]) << 8) | UInt16(resp[10])
    return MethodID(class_id, method_id) == CONNECTION_OPEN_OK()


def _resp_is_connection_close(ref resp: List[UInt8]) -> Bool:
    """True when the reply's FIRST frame is a SERVER-initiated
    connection.close (10,50) — the same byte glue as _resp_is_open_ok.

    0017 T4: when the service answers a HANDSHAKE frame (connection.start-ok)
    with the normative connection.close 403 ACCESS_REFUSED, the socket is
    closed right after those bytes hit the wire (rabbit parity: the broker
    closes after sending the close; it does not wait for the client's
    close-ok). The client-initiated close path is UNAFFECTED: there the reply
    is close-ok (10,51) and the teardown key is the inbound frame instead."""
    if len(resp) < 11:
        return False
    if resp[0] != FRAME_METHOD():
        return False
    var class_id = (UInt16(resp[7]) << 8) | UInt16(resp[8])
    var method_id = (UInt16(resp[9]) << 8) | UInt16(resp[10])
    return MethodID(class_id, method_id) == CONNECTION_CLOSE()


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


# Fairness dose (0015): the max number of RECEIVING reads (recv(2)/
# recv(2)+MSG_DONTWAIT) issued against ONE slot in a single ready-cycle
# before the loop rotates to the next ready fd. Under a burst the slot is
# re-fired by the level-triggered poller right after, so throughput is
# unharmed but other ready connections get a turn within one deadline
# window.
#
# 0015 dose-wedge fix: the dose budget now counts READS, not frames. A
# single read can coalesce many frames (the batched client sends its whole
# burst in one write), and the last read leaves those frames in the
# CODEC's user-space backlog — at which point the kernel buffer is empty
# and level-triggered epoll will NOT re-fire: a frame-count dose with a
# dry fd strands complete frames in the backlog forever (the propagated
# epoll_wait(100)=0 wedge). Parseable backlog frames are therefore drained
# without counting against the read budget, up to the absolute frame cap
# below.
#
# NOT the following (bounded below): parse-only frame dispatch after the
# read budget is exhausted. The absolute frame cap bounds how much work
# one dose can perform; a hostile 7-octet-heartbeat flood can still strand
# (defer indefinitely), which is the same per-connection damage class the
# FAIL path already accepts — the cap keeps the dose from becoming an
# unbounded always-serve loop.
def _FAIRNESS_DOSE() -> Int:
    return 8


# The absolute frame cap per dose: 8 reads can coalesce at most ~576
# KB into the backlog; one max-sized find_burst (32 x frame_max(131072)
# publish groups + gets) is <= ~160 frames, so the cap only bites on
# pathological micro-frame input.
def _DOSE_FRAME_CAP() -> Int:
    return 4096


# Poll timeout (0015): the readiness wait is bounded so `_running` (stop())
# stays responsive while idle.
def _POLL_TIMEOUT_MS() -> Int:
    return 100


# ---- 0015 dose-wedge fix: the event tier's non-blocking read seam ----

# recv(2) per-call non-blocking flag (MSG_DONTWAIT, Linux 0x40 / macOS 0x80).
# The socket's own state is NEVER changed (the fd stays blocking), so the
# legacy tier's recv(2) — flags 0 — is untouched; only the dose path opts
# into a would-block-able read, per call, like flare does for its batched
# drains. Retained as a comptime constant in the flare POSIX-handler style
# (listener.mojo imports no flare symbol; this is a local libc binding of
# the one syscall the dose needs).
def _MSG_DONTWAIT() -> Int:
    if CompilationTarget.is_linux():
        return 0x40
    return 0x80


def _recv_dontwait(fd: Int, buf: UnsafePointer[UInt8, _], want: Int) raises -> Int:
    """One recv(2) with MSG_DONTWAIT on the slot's borrowed fd. NEVER blocks.

    Outcome codes (the EAGAIN escalation path):
    - ``> 0``: that many bytes were received (written into ``buf``).
    - ``0``  : orderly EOF — the caller closes the slot (same semantics as
      a 0-byte blocking read today).
    - ``-1`` : EAGAIN/EWOULDBLOCK — the kernel buffer is dry. This is the
      poller's job, not the dose's: the caller returns SERVE_PARTIAL and
      the LEVEL-TRIGGERED registry re-fires the fd when the peer's next
      bytes arrive. No spin: the registry only fires on actual readiness.
    - every other failure raises (EINTR is retried in-line); the
      serve_one_frame try/except then fails the connection closed, as the
      blocking path already does.

    ADR-0005 note: the fd is the transport's own (poll_fd()), owned and
    closed by the connection — this call only ever READS from it, the same
    borrowed-fd shape the poller already uses for readiness.
    """
    while True:
        var got = external_call["recv", c_ssize_t](
            c_int(fd),
            buf.unsafe_bitcast[NoneType](),
            c_size_t(want),
            c_int(_MSG_DONTWAIT()),
        )
        if got >= 0:
            return Int(got)
        var e = get_errno()
        if e == ErrNo.EINTR:
            continue
        if e == ErrNo.EAGAIN or e == ErrNo.EWOULDBLOCK:
            return -1
        raise (
            "AMQPConnServing: event-dose recv failed on fd "
            + String(fd)
            + " (errno " + String(Int(e.value)) + ")"
        )


struct AMQPConnServing[Conn: AMQPConn]:
    """The transport-agnostic per-connection serving state machine.

    Owns the broker front-end (AMQPService), the per-slot codecs/phase/
    header-buffer bookkeeping and the connection list. The concrete connection
    type (TCPConnection or UDSConnection) is a trait parameter only: every
    socket touch goes through the AMQPConn surface, so the header -> echo ->
    handshake -> content frame serving path is IDENTICAL for both transports.
    The transport object itself is NOT held here (accepting lives in the thin
    wrappers), because TCPListener and UDSListener have different accept
    signatures/return types.
    """

    var _service: AMQPService
    var _conns: List[Optional[Self.Conn]]
    var _codecs: List[AMQPFrameCodec]
    var _closed: List[Bool]
    var _phases: List[Int]
    var _hdrbuf: List[List[UInt8]]
    var _frame_max: Int
    var _max_connections: Int
    var _active: Int
    var _refused: Int
    # 0015 dose-wedge fix: transient per-serve flag read by serve_slot_dose
    # after each dose iteration — True when the last serve frame step issued
    # a socket READ (a frame served purely from the codec backlog leaves it
    # False, so parse-only dispatches do not consume the read budget).
    var _last_serve_read: Bool

    def __init__(out self, var config: HyrxMQConfig):
        # Enforced ceiling handed to every per-connection codec AND advertised in
        # the connection.tune frame_max field. The client may only request a
        # SMALLER value in tune-ok; we do not renegotiate the codec upward
        # (NOT IMPLEMENTED: frame_max renegotiation), so this ceiling is the
        # effective limit for the whole connection.
        self._frame_max = config.frame_max
        # The accept-gate authority (see register below): the transport wrapper
        # does not enforce max_connections (TECH DEBT: enforce in one place).
        self._max_connections = config.max_connections
        self._service = AMQPService(config^)
        self._conns = List[Optional[Self.Conn]]()
        self._codecs = List[AMQPFrameCodec]()
        self._closed = List[Bool]()
        self._phases = List[Int]()
        self._hdrbuf = List[List[UInt8]]()
        self._active = 0
        self._refused = 0
        self._last_serve_read = False

    # ---- broker service lifecycle (transport start/stop is the wrapper's) ----

    # ---- 0018: pluggable storage pass-throughs (additive) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the storage journal into the broker FRONT-END (the
        bootstrap wire; no fs access happens here)."""
        self._service.attach_journal(journal^)

    def recover_journal(mut self) raises -> Int:
        """Replay the injected journal into the engine before serving."""
        return self._service.recover_journal()

    def start_service(mut self) raises:
        self._service.start()

    def shutdown_service(mut self):
        self._service.shutdown()

    def status(mut self) -> BrokerStatus:
        return self._service.status()

    def health(mut self) -> String:
        return self._service.health()

    # ---- slot bookkeeping ----

    def active_connections(ref self) -> Int:
        """Connections currently open (not yet failed/closed)."""
        return self._active

    def refused_connections(ref self) -> Int:
        """Accepts dropped because the connection ceiling was reached."""
        return self._refused

    def register(mut self, var conn: Optional[Self.Conn]) raises -> Int:
        """Adopt an already-accepted connection; return its slot index.

        Called by the transport wrapper right after its `accept_connection()`.

        Returns -1 when the connection is REFUSED: the configured
        `max_connections` ceiling is reached, so the accepted socket is closed
        immediately without any AMQP handling (fail closed: the client sees a
        connect followed by EOF; the broker keeps listening).
        """
        if not conn.__bool__():
            raise "AMQPConnServing.register: accept returned no connection"
        if self._active >= self._max_connections:
            self._refused += 1
            self._drop(conn^)
            return -1
        var slot = len(self._conns)
        self._conns.append(conn^)
        self._codecs.append(AMQPFrameCodec(self._frame_max))
        self._closed.append(False)
        self._phases.append(PHASE_HEADER())
        self._hdrbuf.append(List[UInt8]())
        self._active += 1
        return slot

    def _drop(mut self, var conn: Optional[Self.Conn]):
        """Close an accepted connection that will never be served."""
        if conn.__bool__():
            conn.value().close()

    def _close_slot(mut self, slot: Int):
        """Best-effort socket close for a slot; never propagates an error."""
        if self._closed[slot]:
            return
        self._closed[slot] = True
        self._active -= 1
        if self._conns[slot].__bool__():
            self._conns[slot].value().close()

    def close_slot(mut self, slot: Int):
        """Public form of :meth:`_close_slot` (event-driven teardown).

        Idempotent: a slot already closed (e.g. by serve_one_frame itself
        on SERVE_CLOSED/SERVE_FAILED) is left untouched."""
        if slot < 0 or slot >= len(self._closed):
            return
        self._close_slot(slot)

    def slot_conn_fd(ref self, slot: Int) -> Int:
        """The raw fd of the slot's connection (event-driven registry key).

        Reuses the transport's own fd accessor through the AMQPConn trait
        (additive for 0015); returns -1 for a closed/empty slot so the
        event loop skips it."""
        if slot < 0 or slot >= len(self._closed):
            return -1
        if self._closed[slot]:
            return -1
        if not self._conns[slot].__bool__():
            return -1
        return self._conns[slot].value().poll_fd()

    def serve_slot_dose(mut self, slot: Int) -> Int:
        """Serve ONE readiness event's work from a slot. NEVER raises,
        NEVER blocks on a peer that is not sending (0015 dose-wedge fix).

        Loop shape:
        - every iteration serves one frame step through `_serve_dose_frame`
          (the try/except wrapper of `_serve_step` in NON-BLOCKING mode:
          reads are recv(2)+MSG_DONTWAIT on the slot's borrowed fd);
        - a step that completes a frame from the codec BACKLOG (no socket
          read) is "parse-only": it does not consume the read budget;
        - a step that actually READS consumes one of _FAIRNESS_DOSE()
          reads;
        - parse-only dispatches continue up to _DOSE_FRAME_CAP() frames so
          a burst the fd already delivered into the backlog is fully
          drained even when the kernel buffer is now empty (level-
          triggered epoll cannot re-fire a dry fd);
        - the loop ends on _recv_dontwait's EAGAIN => SERVE_PARTIAL: the
          single-threaded loop RETURNS and the readiness registry re-fires
          the fd when the peer's next bytes arrive — exactly the deferred
          shape the dose was designed for, with no fd asleep inside the
          loop and no other connection starved.

        Returns the last outcome code (SERVE_DISPATCHED only when the
        READ budget ran out mid-burst with kernel data still pending —
        the poller re-fires that right after; SERVE_PARTIAL is the
        would-block yield; teardown codes end the dose). Teardown itself
        is left to the caller (the loop owns the registry).
        """
        var last = SERVE_DISPATCHED()
        var frames = 0
        var reads = 0
        while frames < _DOSE_FRAME_CAP() and reads < _FAIRNESS_DOSE():
            last = self._serve_dose_frame(slot)
            if last != SERVE_DISPATCHED():
                break
            frames += 1
            if self._last_serve_read:
                reads += 1
        return last

    def _serve_dose_frame(mut self, slot: Int) -> Int:
        """The event-tier dose's one-frame step: serve_one_frame's try/
        except containment with `_serve_step` resolved to its NON-BLOCKING
        read mode (additive to 0015; the public serve_one_frame — the
        LEGACY tier's entry point — keeps its blocking read semantics
        unchanged)."""
        try:
            return self._serve_step(slot, True)
        except:
            if slot >= 0 and slot < len(self._closed):
                self._close_slot(slot)
            return SERVE_FAILED()

    # ---- serving (the one frame/header/handshake state machine) ----

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
            return self._serve_step(slot, False)
        except:
            if slot >= 0 and slot < len(self._closed):
                self._close_slot(slot)
            return SERVE_FAILED()

    def _serve_step(mut self, slot: Int, nb_event: Bool) raises -> Int:
        """The one-frame step; every error is the caller's to fail closed.

        ``nb_event`` selects the read seam: False (the LEGACY tier — the
        blocking `recv_bytes` path, byte-identical to before) or True (the
        event-driven dose — `_recv_dontwait`, which yields SERVE_PARTIAL
        on EAGAIN instead of parking the whole loop on a dry fd)."""
        if slot < 0 or slot >= len(self._conns):
            raise "AMQPConnServing.serve_one_frame: bad slot"
        if self._closed[slot]:
            return SERVE_CLOSED()
        if not self._conns[slot].__bool__():
            return SERVE_CLOSED()
        self._last_serve_read = False

        # Pre-frame handshake stage: the 8-octet protocol header is consumed
        # HERE, never fed to the codec (its first octet 'A'=0x41 is not a legal
        # frame_type and would be rejected as a bad frame).
        if self._phases[slot] == PHASE_HEADER():
            return self._step_header(slot, nb_event)

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

            var chunk: List[UInt8]
            if nb_event:
                # Event-tier read (0015 dose-wedge fix): recv(2) with
                # MSG_DONTWAIT. EAGAIN => SERVE_PARTIAL yield: the dose
                # RETURNS instead of parking the single-threaded loop on
                # a dry fd; the level-triggered registry re-fires the fd
                # when more bytes arrive. want <= 0 mirrors the blocking
                # path's recv_bytes-fails-closed behavior below.
                if want <= 0:
                    self._close_slot(slot)
                    return SERVE_CLOSED()
                var buf = List[UInt8](unsafe_uninit_length=want)
                var got = _recv_dontwait(
                    self._conns[slot].value().poll_fd(),
                    buf.unsafe_ptr(),
                    want,
                )
                if got == -1:
                    return SERVE_PARTIAL()
                if got == 0:
                    self._close_slot(slot)
                    return SERVE_CLOSED()
                self._last_serve_read = True
                if got < want:
                    buf.resize(unsafe_uninit_length=got)
                chunk = buf^
            else:
                # LEGACY tier: the blocking read, byte-identical to before.
                chunk = self._conns[slot].value().recv_bytes(want)
                self._last_serve_read = True
                if len(chunk) == 0:
                    self._close_slot(slot)
                    return SERVE_CLOSED()
            self._codecs[slot].feed_bytes(chunk^)
            frame = self._codecs[slot].try_parse_frame()
            if not frame.__bool__():
                return SERVE_PARTIAL()

        # --- 0017 T4 heartbeats (the MUTABLE frame timers live HERE, in the
        # serving loop — additive to both the fair-dose and event-driven
        # tiers; the 0015 serving-model flag state is UNCHANGED) ---
        # The MINIMAL client-heartbeat protocol: a received heartbeat frame
        # (type 8, zero payload) gets an IMMEDIATE heartbeat echo — the
        # cheap ping-pong that keeps the client's liveness timer satisfied.
        # NOT IMPLEMENTED (honest PARTIAL per receipt): server CYCLIC
        # heartbeats (no timer subsystem exists) and the 2x-miss close —
        # they need a background timer, which this loop deliberately does
        # not host. Heartbeat frames never reach the broker dispatch.
        if frame.value().frame_type == FRAME_HEARTBEAT():
            var echo = AMQPFrameCodec.encode_heartbeat(frame.value().channel)
            self._conns[slot].value().send_bytes(echo^)
            return SERVE_DISPATCHED()

        # Close-detection is byte glue only: class/method ids of a method
        # frame, no routing semantics.
        var p = frame.value().payload_copy()
        var is_close = False
        var server_close = False
        if frame.value().frame_type == FRAME_METHOD() and len(p) >= 4:
            var class_id = (UInt16(p[0]) << 8) | UInt16(p[1])
            var method_id = (UInt16(p[2]) << 8) | UInt16(p[3])
            is_close = MethodID(class_id, method_id) == CONNECTION_CLOSE()

        var conn_id = self._conns[slot].value().conn_id()
        var resp = self._service.handle_frame(conn_id, frame.value())
        if resp.__bool__():
            # open-ok detected pre-send (borrow-safe pattern)
            var open_ok = _resp_is_open_ok(resp.value())
            # server-initiated connection.close detected pre-send (0017 T4:
            # auth refusal 403 — the reply IS the close frame)
            server_close = _resp_is_connection_close(resp.value())

            # --- 0017 T1 CONNECTION_CLOSE teardown ordering (NORMATIVE) ---
            # amqp0-9-1.xml connection class: the server replies
            # connection.close-ok (10,51) FIRST and only then closes the
            # socket; the same rule holds when the server initiates (T4).
            # The dispatch above returns the close-ok as the response for the
            # connection.close frame, so the send below hits the wire BEFORE
            # the is_close teardown that follows — the "no 20 s hang, no
            # close-ok lost" property required by the 0017 e2e gate. The
            # bytes-only guarantee: resp is fully written here, then the slot
            # is closed in the is_close block after this branch. A service
            # raise between send and close is impossible (handle_frame
            # produced the bytes already).
            self._conns[slot].value().send_bytes(resp.value().copy())
            # Handshake completion is detected from the reply bytes only (no new
            # service coupling): an open-ok reply ends negotiation.
            if (
                self._phases[slot] == PHASE_HANDSHAKING()
                and open_ok
            ):
                self._phases[slot] = PHASE_READY()

        if is_close or server_close:
            # ONLY after the close-ok frames above were written (is_close:
            # the client's close got its close-ok; server_close: the 403
            # auth-refusal close itself — rabbit closes right after sending).
            # _close_slot is idempotent and never propagates an error; the
            # event-driven loop's deregister-before-close ordering is
            # preserved there.
            self._close_slot(slot)
        return SERVE_DISPATCHED()

    def _step_header(mut self, slot: Int, nb_event: Bool) raises -> Int:
        """Consume the 8-octet protocol header, then send start.

        Accumulates raw bytes across steps until 8 are held (so a client that
        dribbles the header is still handled). On a match, echoes the same 8
        octets back and sends connection.start, advancing to HANDSHAKING. On a
        mismatch the connection is failed closed (audit §14/§36: the header is
        a mandatory, non-negotiable preamble — a wrong header is a protocol
        error, not a frame error) while the broker keeps accepting.

        ``nb_event`` selects the read seam exactly as in `_serve_step`: in
        the event tier the header read is recv(2)+MSG_DONTWAIT, so a drib-
        bling client cannot park the loop inside the dose; EAGAIN here is
        the SERVE_PARTIAL yield and LEVEL-TRIGGERED re-fire supplies the
        rest of the header octets later.
        """
        self._last_serve_read = False
        while len(self._hdrbuf[slot]) < PROTOCOL_HEADER_LEN():
            var need = PROTOCOL_HEADER_LEN() - len(self._hdrbuf[slot])
            var chunk: List[UInt8]
            if nb_event:
                var buf = List[UInt8](unsafe_uninit_length=need)
                var got = _recv_dontwait(
                    self._conns[slot].value().poll_fd(),
                    buf.unsafe_ptr(),
                    need,
                )
                if got == -1:
                    return SERVE_PARTIAL()
                if got <= 0:
                    self._close_slot(slot)
                    return SERVE_CLOSED()
                self._last_serve_read = True
                buf.resize(unsafe_uninit_length=got)
                chunk = buf^
            else:
                chunk = self._conns[slot].value().recv_bytes(need)
                self._last_serve_read = True
                if len(chunk) == 0:
                    self._close_slot(slot)
                    return SERVE_CLOSED()
            for i in range(len(chunk)):
                self._hdrbuf[slot].append(chunk[i])

        var hdr = _protocol_header()
        for i in range(PROTOCOL_HEADER_LEN()):
            if self._hdrbuf[slot][i] != hdr[i]:
                # Header mismatch: close this connection, keep the broker alive.
                self._close_slot(slot)
                return SERVE_FAILED()

        # Match: echo the header octets, then the first server frame.
        self._conns[slot].value().send_bytes(hdr^)
        var start = self._service.connection_start_frame()
        self._conns[slot].value().send_bytes(start^)
        self._phases[slot] = PHASE_HANDSHAKING()
        return SERVE_DISPATCHED()


def _fill_tcfg(mut tcfg: TransportConfig, ref config: HyrxMQConfig):
    """Copy the listener-relevant ceiling from the broker config.

    NOTE: tcfg.max_connections is descriptive here; the transport wrapper does
    not enforce it (TECH DEBT: enforce in one place). The authority is the
    AMQPConnServing accept gate (`_max_connections`)."""
    tcfg.max_connections = config.max_connections
    tcfg.max_frame_size = config.frame_max


struct AMQPListener:
    """Broker accept-loop over the Hyrx TCP transport contract.

    Thin TCP front end: it owns the TCPListener and delegates all frame,
    header and handshake serving to a shared AMQPConnServing[TCPConnection], so
    the on-wire AMQP behavior is byte-identical to the pre-UDS implementation.
    """

    var _transport: TCPListener
    var _srv: AMQPConnServing[TCPConnection]
    var _running: Bool

    def __init__(out self, var config: HyrxMQConfig):
        var tcfg = TransportConfig()
        _fill_tcfg(tcfg, config)
        # port == 0 asks the kernel for an ephemeral port; see port().
        self._transport = TCPListener(config.listen_host, config.port, tcfg^)
        self._srv = AMQPConnServing[TCPConnection](config^)
        self._running = False

    # ---- 0018: pluggable storage pass-throughs (additive) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the storage journal before start() (the bootstrap wire)."""
        self._srv.attach_journal(journal^)

    def recover_journal(mut self) raises -> Int:
        """Replay the injected journal into the engine before start()."""
        return self._srv.recover_journal()

    # ---- lifecycle ----

    def start(mut self) raises -> Bool:
        """Start the broker service and bind the TCP listener."""
        self._srv.start_service()
        var ok = self._transport.start()
        self._running = ok
        return ok

    def port(mut self) raises -> Int:
        """The actual bound port (reflects the ephemeral port when 0).

        TCP-only: the UDS front end exposes `path()` instead (there is no port
        on a Unix domain socket)."""
        return self._transport.port()

    def transport_kind(ref self) -> String:
        """Discriminator so callers/tests know which endpoint accessor is valid."""
        return "tcp"

    def stop(mut self):
        self._running = False
        self._transport.stop()
        self._srv.shutdown_service()

    def health(mut self) -> String:
        return self._srv.health()

    def status(mut self) -> BrokerStatus:
        return self._srv.status()

    # ---- serving ----

    def active_connections(ref self) -> Int:
        return self._srv.active_connections()

    def refused_connections(ref self) -> Int:
        return self._srv.refused_connections()

    def accept_one(mut self) raises -> Int:
        """Accept one pending connection; return its slot index.

        Blocks until a client has connected (bind -> connect -> accept). Returns
        -1 when the connection is REFUSED at the `max_connections` ceiling (see
        AMQPConnServing.register: the socket is closed immediately, fail closed).
        """
        var conn = self._transport.accept_connection()
        return self._srv.register(conn^)

    def serve_one_frame(mut self, slot: Int) -> Int:
        """Advance one connection by at most one frame. NEVER raises.

        Delegates to the shared AMQPConnServing state machine (see that struct
        for the SERVE_* outcome contract).
        """
        return self._srv.serve_one_frame(slot)

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

        0015: when `event_driven_serving()` is True this instead runs
        :meth:`serve_event_driven` — one thread, rotating fairness across
        registered connections via a level-triggered readiness registry.
        Flag False => this legacy loop is byte-identical to before."""
        if event_driven_serving():
            self.serve_event_driven()
            return
        while self._running:
            _ = self.accept_and_serve_one()

    # ---- 0015: event-driven serving ----

    def serve_event_driven(mut self) raises:
        """Single-threaded readiness loop over the TCP accept fd and every
        registered connection fd (flag event_driven_serving = True).

        Per plan.md 0015: the registry holds the listener accept fd plus one
        entry per registered conn fd, level-triggered, timeout 100 ms so
        `_running` stays responsive. Listener-readable -> one bounded accept
        per readiness event (the level-triggered poller re-fires while more
        pendings); refused connections are handled by register() exactly as
        today (close + refuse, never registered). Conn-readable -> one
        fairness dose (max K frames, then rotate); teardown on
        SERVE_CLOSED/SERVE_FAILED goes through the SAME _close_slot path and
        the fd is deregistered. In-loop recv stays blocking BUT is only
        invoked after readiness reported data.

        The dose/teardown machinery is shared (parameterized by <Conn:
        AMQPConn> inside AMQPConnServing) — this wrapper contributes only
        the concrete accept routine, exactly like the legacy tier.
        """
        var poller = EventPoller()
        var lfd = self._transport.accept_fd()
        var ltoken = UInt64(Int(lfd))
        poller.add(lfd, ltoken)
        var slot_of_fd = Dict[UInt64, Int]()
        var events = List[PollEvent]()
        while self._running:
            var n = poller.wait(events, _POLL_TIMEOUT_MS())
            for i in range(n):
                var ev = events[i]
                if ev.wakeup:
                    continue
                if ev.token == ltoken:
                    self._accept_drain(poller, slot_of_fd)
                else:
                    self._serve_readiness(poller, slot_of_fd, events[i])


    def _accept_drain(
        mut self,
        mut poller: EventPoller,
        mut slot_of_fd: Dict[UInt64, Int],
    ) raises:
        """One accept per listener readiness; register the conn fd.

        Bounded by one per readiness event (the level-triggered registry
        re-fires while accepts remain). Refused connections return -1 from
        accept_one(): register() already closed that socket, nothing is
        registered."""
        if not self._running:
            return
        var slot = self.accept_one()
        if slot < 0:
            return
        var fd = self._srv.slot_conn_fd(slot)
        if fd < 0:
            # belt-and-braces: an unregistered-but-open slot would never be
            # served by the loop; close it the same way.
            self._srv.close_slot(slot)
            return
        var token = UInt64(Int(fd))
        poller.add(fd, token)
        slot_of_fd[token] = slot

    def _serve_readiness(
        mut self,
        mut poller: EventPoller,
        mut slot_of_fd: Dict[UInt64, Int],
        ref ev: PollEvent,
    ) raises:
        """Serve one conn readiness event: one dose, then rotate.

        Ordering rule (0015 EBADF crash): DEREGISTER BEFORE CLOSE. The
        Reactor's `epoll_ctl DEL` (via _deregister -> poller.remove) runs
        while the fd is STILL OPEN. The DEL that can still hit a dead fd —
        the serve path closed the socket inside the dose
        (registered-but-closed race) — EBADFs, and poller.remove tolerates
        exactly that, purging the stale registry entry; every other error
        propagates.
        Error/hup-only events tear the slot down in that order. A dose that
        reports SERVE_CLOSED/FAILED tears down the same way (close_slot is
        idempotent). Stale tokens (slot already torn down) are skipped."""
        if ev.token not in slot_of_fd:
            return
        var slot = slot_of_fd[ev.token]
        if ev.failed or (ev.hup and not ev.readable):
            self._deregister(poller, slot_of_fd, Int(ev.token))
            self._srv.close_slot(slot)
            return
        var rc = self._srv.serve_slot_dose(slot)
        if rc < 0:
            self._deregister(poller, slot_of_fd, Int(ev.token))
            self._srv.close_slot(slot)

    def _deregister(
        mut self,
        mut poller: EventPoller,
        mut slot_of_fd: Dict[UInt64, Int],
        fd: Int,
    ) raises:
        """Remove the fd from the readiness registry at slot teardown.

        Ordering (0015): `poller.remove` — the epoll_ctl DEL — runs FIRST,
        while the fd is still open (the caller must deregister before any
        close_slot), and is guarded by `is_registered` so it never raises on
        an absent fd. EBADF is tolerated at deregister only when the fd was
        already closed by the serve path (the registered-but-closed race);
        poller.remove purges the stale registry entry and returns False in
        that case, True after a clean DEL. Every other error propagates and
        the fd->slot mapping is then kept, so a failing remove cannot
        silently lose the mapping. The `slot_of_fd` entry is popped either
        way: once the registry outcome settles, the mapping must clear."""
        var token = UInt64(Int(fd))
        if poller.is_registered(fd):
            # True: clean DEL. False: EBADF tolerated, stale entry purged
            # by the poller. Either way the registry no longer holds the fd.
            _ = poller.remove(fd)
        if token in slot_of_fd:
            _ = slot_of_fd.pop(token)


struct UDSAMQPListener:
    """Broker accept-loop over the Hyrx Unix-domain-socket transport contract.

    The same connection-negotiation + content-frame serving path as AMQPListener,
    driven over a UDSConnection instead of a TCPConnection: it owns a UDSListener
    and delegates ALL serving to a shared AMQPConnServing[UDSConnection]. Only
    the accept/accessor surface differs (path() instead of port())."""

    var _transport: UDSListener
    var _srv: AMQPConnServing[UDSConnection]
    var _running: Bool

    def __init__(out self, var path: String, var config: HyrxMQConfig):
        var tcfg = TransportConfig()
        _fill_tcfg(tcfg, config)
        self._transport = UDSListener(path^, tcfg^)
        self._srv = AMQPConnServing[UDSConnection](config^)
        self._running = False

    # ---- 0018: pluggable storage pass-throughs (additive) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the storage journal before start() (the bootstrap wire)."""
        self._srv.attach_journal(journal^)

    def recover_journal(mut self) raises -> Int:
        """Replay the injected journal into the engine before start()."""
        return self._srv.recover_journal()

    # ---- lifecycle ----

    def start(mut self) raises -> Bool:
        """Start the broker service and bind the UDS listener."""
        self._srv.start_service()
        var ok = self._transport.start()
        self._running = ok
        return ok

    def path(ref self) -> String:
        """The bound Unix-socket path (the UDS analogue of TCP `port()`)."""
        return self._transport.path()

    def transport_kind(ref self) -> String:
        """Discriminator so callers/tests know which endpoint accessor is valid."""
        return "uds"

    def stop(mut self):
        self._running = False
        self._transport.stop()
        self._srv.shutdown_service()

    def health(mut self) -> String:
        return self._srv.health()

    def status(mut self) -> BrokerStatus:
        return self._srv.status()

    # ---- serving ----

    def active_connections(ref self) -> Int:
        return self._srv.active_connections()

    def refused_connections(ref self) -> Int:
        return self._srv.refused_connections()

    def accept_one(mut self) raises -> Int:
        """Accept one pending connection; return its slot index.

        Blocks until a client has connected (bind -> connect -> accept). Returns
        -1 when the connection is REFUSED at the `max_connections` ceiling (see
        AMQPConnServing.register: the socket is closed immediately, fail closed).
        """
        var conn = self._transport.accept_connection()
        return self._srv.register(conn^)

    def serve_one_frame(mut self, slot: Int) -> Int:
        """Advance one connection by at most one frame. NEVER raises."""
        return self._srv.serve_one_frame(slot)

    def accept_and_serve_one(mut self) raises -> Int:
        """Accept one connection and serve frames until the peer closes it."""
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

        0015: when `event_driven_serving()` is True this instead runs
        :meth:`serve_event_driven` — the same single-threaded readiness
        loop as the TCP front end, over the UDS listener fd + conn fds
        (a bound Unix socket fd works identically as a readiness source).
        Flag False => this legacy loop is byte-identical to before."""
        if event_driven_serving():
            self.serve_event_driven()
            return
        while self._running:
            _ = self.accept_and_serve_one()

    # ---- 0015: event-driven serving ----

    def serve_event_driven(mut self) raises:
        """Single-threaded readiness loop over the UDS accept fd and every
        registered connection fd (flag event_driven_serving = True).

        Identical registry design to the TCP front end (see
        AMQPListener.serve_event_driven): level-triggered, 100 ms timeout,
        one bounded accept per listener readiness, one fairness dose per
        conn readiness, serve-close-path teardown + deregistration. The
        UDS listener fd itself is registered the same way — a bound Unix
        domain socket is an ordinary pollable fd (unchanged under path
        rebinding, since stop()/rebind goes through a fresh start() +
        fresh loop)."""
        var poller = EventPoller()
        var lfd = self._transport.accept_fd()
        var ltoken = UInt64(Int(lfd))
        poller.add(lfd, ltoken)
        var slot_of_fd = Dict[UInt64, Int]()
        var events = List[PollEvent]()
        while self._running:
            var n = poller.wait(events, _POLL_TIMEOUT_MS())
            for i in range(n):
                var ev = events[i]
                if ev.wakeup:
                    continue
                if ev.token == ltoken:
                    self._accept_drain(poller, slot_of_fd)
                else:
                    self._serve_readiness(poller, slot_of_fd, events[i])


    def _accept_drain(
        mut self,
        mut poller: EventPoller,
        mut slot_of_fd: Dict[UInt64, Int],
    ) raises:
        """One accept per listener readiness; register the conn fd.

        Refused accepts return -1 (register already closed the socket)."""
        if not self._running:
            return
        var slot = self.accept_one()
        if slot < 0:
            return
        var fd = self._srv.slot_conn_fd(slot)
        if fd < 0:
            # belt-and-braces: an unregistered-but-open slot would never be
            # served by the loop; close it the same way.
            self._srv.close_slot(slot)
            return
        var token = UInt64(Int(fd))
        poller.add(fd, token)
        slot_of_fd[token] = slot

    def _serve_readiness(
        mut self,
        mut poller: EventPoller,
        mut slot_of_fd: Dict[UInt64, Int],
        ref ev: PollEvent,
    ) raises:
        """Serve one conn readiness event: one dose, then rotate.

        Same deregister-before-close ordering rule as the TCP front end (see
        AMQPListener._serve_readiness): poller.remove (epoll_ctl DEL) runs on
        the still-open fd, then close_slot; a DEL that EBADFs because the
        serve path already closed the fd (registered-but-closed race) is
        tolerated there — every other error propagates."""
        if ev.token not in slot_of_fd:
            return
        var slot = slot_of_fd[ev.token]
        if ev.failed or (ev.hup and not ev.readable):
            self._deregister(poller, slot_of_fd, Int(ev.token))
            self._srv.close_slot(slot)
            return
        var rc = self._srv.serve_slot_dose(slot)
        if rc < 0:
            self._deregister(poller, slot_of_fd, Int(ev.token))
            self._srv.close_slot(slot)

    def _deregister(
        mut self,
        mut poller: EventPoller,
        mut slot_of_fd: Dict[UInt64, Int],
        fd: Int,
    ) raises:
        """Remove the fd from the readiness registry at slot teardown.

        Ordering (0015): `poller.remove` — the epoll_ctl DEL — runs FIRST,
        while the fd is still open (the caller must deregister before any
        close_slot), and is guarded by `is_registered` so it never raises on
        an absent fd. EBADF is tolerated at deregister only when the fd was
        already closed by the serve path (the registered-but-closed race);
        poller.remove purges the stale registry entry and returns False in
        that case, True after a clean DEL. Every other error propagates and
        the fd->slot mapping is then kept, so a failing remove cannot
        silently lose the mapping. The `slot_of_fd` entry is popped either
        way: once the registry outcome settles, the mapping must clear."""
        var token = UInt64(Int(fd))
        if poller.is_registered(fd):
            # True: clean DEL. False: EBADF tolerated, stale entry purged
            # by the poller. Either way the registry no longer holds the fd.
            _ = poller.remove(fd)
        if token in slot_of_fd:
            _ = slot_of_fd.pop(token)

# ── 0023 T1/T2: the WSS front end (browser transport) ────────────────────


def _wss_config_from(ref config: HyrxMQConfig) raises -> WssConfig:
    """Project the broker config's 0023 WSS fields onto the tier config.

    Origin policy projection (0023): the broker-side allowlist is EMPTY
    by default, which maps to the tier's allow-all DEFAULT exactly (no
    configured list = everything allowed — the extensible starting
    point); a non-empty list switches the tier to list enforcement (any
    otherwise-originated Origin = the normative HTTP 403 row)."""
    var wcfg = WssConfig()
    wcfg.port = config.wss_listen
    wcfg.tls_mode = config.wss_tls_mode
    wcfg.tls_cert_path = config.wss_tls_path
    wcfg.tls_key_path = config.wss_tls_key_path
    if len(config.wss_origin_allowlist) != 0:
        wcfg.allow_all = False
        for i in range(len(config.wss_origin_allowlist)):
            wcfg.origin_allowlist.append(config.wss_origin_allowlist[i])
    return wcfg^


struct WSSAMQPListener[Ops: FileSystemOps]:
    """Broker accept-loop over the WSS transport contract (0023 T1/T2).

    Thin WSS front end, structurally the TCP/UDS twins: it owns a
    WSSListener (bind/start/accept + the TLS setup + the RFC 6455 /
    RFC 7395 upgrade — ALL of them inside hyrx.transport so THIS file
    never imports flare) and delegates ALL frame/header/handshake
    serving to the shared `AMQPConnServing[WSSConnection]`. The on-wire
    AMQP behavior is byte-identical to the TCP front end; only the byte
    carrier differs (WS binary frames over WSS/ws).

    Boot shape deviation (HONEST, 0023): this listener runs ONE serving
    loop at a time, like every tier today — the multi-tier (concurrent
    TCP + WSS) thread model is a documented NOT-YET on main_listen (see
    that file). `serve_forever` consults the SAME 0015 serving-model
    flag as the twins; the event-driven route is REFUSED for this tier:
    the dose reads the slot's borrowed fd directly (recv(2), a
    PLAINTEXT seam) — on a TLS carrier that consumes ciphertext. The
    legacy loop, which reads through `WSSConnection.recv_bytes`
    (TLS-aware), is the only correct seam here."""

    var _transport: WSSListener[Self.Ops]
    var _srv: AMQPConnServing[WSSConnection]
    var _running: Bool

    def __init__(out self, var config: HyrxMQConfig, var ops: Self.Ops) raises:
        var tcfg = TransportConfig()
        _fill_tcfg(tcfg, config)
        var wcfg = _wss_config_from(config)
        self._transport = WSSListener[Self.Ops](wcfg^, ops^)
        self._srv = AMQPConnServing[WSSConnection](config^)
        self._running = False

    # ---- 0018: pluggable storage pass-throughs (additive) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the storage journal before start() (the bootstrap wire)."""
        self._srv.attach_journal(journal^)

    def recover_journal(mut self) raises -> Int:
        """Replay the injected journal into the engine before start()."""
        return self._srv.recover_journal()

    # ---- lifecycle ----

    def start(mut self) raises -> Bool:
        """Start the broker service and bind the WSS listener.

        Normative refusals (0023): a tier configured with NO cert source
        (tls_mode "none" or an unset injected source after the full
        range of checks) does not start — the raise carries the reason
        and NOTHING is half-bound. The injected PEM-bytes mode cannot
        load in this vendor snapshot (see WSSListener.start's
        NEEDS-PROBE note); it fails before any bind as well."""
        if self._transport.tls_mode() == "none":
            raise (
                "WSSAMQPListener.start: no cert source configured "
                "(wss_tls_mode=none); the wss tier refuses to start. "
                "Set wss_tls_mode to injected or path."
            )
        self._srv.start_service()
        var ok = self._transport.start()
        self._running = ok
        return ok

    def port(mut self) raises -> Int:
        """The actual bound port (reflects an ephemeral bind with 0)."""
        return self._transport.port()

    def transport_kind(ref self) -> String:
        """Discriminator so callers/tests know which endpoint accessor is
        valid (the wss analogue of tcp/uds)."""
        return "wss"

    def stop(mut self):
        self._running = False
        self._transport.stop()
        self._srv.shutdown_service()

    def health(mut self) -> String:
        return self._srv.health()

    def status(mut self) -> BrokerStatus:
        return self._srv.status()

    # ---- serving ----

    def active_connections(ref self) -> Int:
        return self._srv.active_connections()

    def refused_connections(ref self) -> Int:
        return self._srv.refused_connections()

    def accept_one(mut self) raises -> Int:
        """Accept + upgrade one connection; return its slot index.

        A connection REJECTED at the upgrade (negotiated 400/403/404 row
        or a TLS/transport failure) comes back Optional-empty from the
        transport; it is per-connection damage only — the loop keeps
        listening and -1 is returned, exactly like a ceiling-refused
        accept on the other front ends."""
        var conn = self._transport.accept_connection()
        if not conn.__bool__():
            return -1
        return self._srv.register(conn^)

    def serve_one_frame(mut self, slot: Int) -> Int:
        """Advance one connection by at most one frame. NEVER raises."""
        return self._srv.serve_one_frame(slot)

    def accept_and_serve_one(mut self) raises -> Int:
        """Accept one connection and serve frames until the peer closes."""
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
        """The accept loop over the WSS listener.

        The 0015 serving-model flag is CONSULTED here (the same
        pairing as the TCP/UDS twins), but the event-driven dose is
        NORMATIVE-REFUSED for this tier: the dose's `_recv_dontwait`
        reads the borrowed fd (plaintext) and would corrupt a TLS
        carrier. Raise carries the reason; the legacy loop (reads via
        `WSSConnection.recv_bytes`) is the served path."""
        if event_driven_serving():
            raise (
                "WSSAMQPListener.serve_forever: event-driven serving "
                "reads the raw fd (plaintext seam) and is not valid on "
                "the TLS-carrying wss tier; use the legacy loop "
                "(event_driven_serving = False)"
            )
        while self._running:
            _ = self.accept_and_serve_one()
