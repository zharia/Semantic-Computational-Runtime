# IPC server session — milestone 0008 (0008 AP-15..18).
#
# One process, one session, single client (0008 §1.1 connection model):
#   1. bind a filesystem Unix-domain socket (stale file unlinked first),
#   2. accept one client, require HELLO as the first frame,
#   3. reply HELLO_OK iff proto/abi/schema all match the running core,
#      else ERROR + close (loud refusal — §3.2 / 0008 AP-17),
#   4. run the session loop: INPUT/EDIT/CMD_TICK upstream, one SNAPSHOT
#      (exact `scr_sim_snapshot_write` bytes) per executed tick downstream,
#      ACK for INPUT/EDIT, BYE/EOF ends the session.
#
# Pacing (0008 §1.1): the server owns the fixed 60 Hz timestep.
#   wall  — one fixed tick every WALL_TICK_NS of wall time (catch-up bounded),
#   manual — exactly `CMD_TICK{n}` fixed ticks, snapshot per tick.
# Effective mode = CLI `--pace manual` OR HELLO flag SCR_IPC_FLAG_MANUAL_PACE.
# A tick is one `runtime_step(FIXED_DT, input)` call, so both modes produce
# byte-identical snapshot sequences for the same inputs (0008 §3.4).
#
# Backpressure (0008 §3.2): the client socket is non-blocking; the writer
# keeps at most one in-flight frame plus one pending snapshot slot — a newer
# snapshot OVERWRITES an unsent pending one (latest-wins coalescing; seq is
# assigned when a snapshot frame starts sending, so coalesced snapshots leave
# gaps, never duplicates). The client drops `seq <= last_applied`.
#
# AP-1: no engine types here (scripts/check_layout.sh gate 1 covers every
# .mojo under src/mojo, so this directory is in scope). AP-4: the socket path
# arrives via argv at runtime only — never a source literal.
#
# Buffer policy: every Buf leaks on purpose (one fixed block per session,
# same rationale as sim/runtime.mojo — `dealloc` only accepts an Allocation).

from std.ffi import external_call, c_int, c_char
from std.memory import Layout, alloc, Pointer
from std.collections import List
from std.time import sleep

from transport.framing import (
    SCR_SIM_IPC_PROTO_VER,
    FRAME_MAGIC,
    FRAME_HEADER_BYTES,
    FT_HELLO,
    FT_HELLO_OK,
    FT_ERROR,
    FT_SNAPSHOT,
    FT_INPUT,
    FT_EDIT,
    FT_ACK,
    FT_BYE,
    FT_CMD_TICK,
    FLAG_MANUAL_PACE,
    FLAG_EDIT_CAP,
    KNOWN_FLAGS,
    INPUT_PAYLOAD_BYTES,
    EDIT_PAYLOAD_BYTES,
    MAX_CTRL_FRAME_BYTES,
    ERR_PROTOCOL,
    ERR_VERSION,
    ERR_MALFORMED,
    ERR_BUSY,
    ERR_CAPABILITY,
    ERR_PACE,
    ERR_INTERNAL,
    FrameHeader,
    decode_header,
    decode_payload,
    frame_total,
    encode_error_frame,
    encode_hello_ok,
    encode_u32_frame,
    parse_hello,
    parse_u32_payload,
)
from sim.input import InputBatch
from sim.parameters import ABI_VERSION, SCHEMA_VERSION, FIXED_DT, SCR_ERR_QUEUE_FULL
from sim.runtime import (
    runtime_init,
    runtime_shutdown,
    runtime_step,
    runtime_snapshot_size,
    runtime_snapshot_write,
    runtime_edit_submit,
)
from snapshot.types import get_f32

# --- POSIX constants (Linux; verified environment, 0008 §8) ---------------

comptime AF_UNIX: Int = 1
comptime SOCK_STREAM: Int = 1
comptime SUN_PATH_MAX: Int = 108
comptime ACCEPT_BACKLOG: Int = 4
comptime F_SETFL: Int = 4
comptime O_NONBLOCK: Int = 2048  # 04000 octal on Linux
comptime MSG_NOSIGNAL: Int = 16384  # 0x4000
comptime EAGAIN_CODE: Int = 11  # Linux: EAGAIN == EWOULDBLOCK
comptime EINTR_CODE: Int = 4

# --- session sizing --------------------------------------------------------

comptime SNAP_CAP: Int = 4194304  # 4 MiB per staging buffer (fixture: 249680 B)
comptime RX_SCRATCH_CAP: Int = 65536
# Server-side cap on CLIENT frame payloads (INPUT/EDIT/CMD_TICK are <= 20 B;
# anything above this is refused loudly before it is buffered).
comptime RX_MAX_PAYLOAD: Int = 65536
comptime RX_MAX_BUFFER: Int = 131072
comptime HANDSHAKE_TIMEOUT_MS: Int = 5000
comptime MAX_CMD_TICK: UInt32 = 1000000
comptime WALL_TICK_NS: UInt64 = 16666666  # 1/60 s (pacing only, not sim dt)
comptime IDLE_SLEEP_S: Float64 = 0.001
comptime CLOSE_FLUSH_MS: Int = 1000
comptime BUSY_FLUSH_MS: Int = 250
comptime MAX_TX_BYTES_PER_FLUSH: Int = 262144

# drain_rx() statuses
comptime DRAIN_OK: Int = 0
comptime DRAIN_EOF: Int = 1
comptime DRAIN_FATAL: Int = 2


# --- libc helpers ----------------------------------------------------------

def _errno() -> Int:
    var p = external_call["__errno_location", Pointer[mut=True, c_int, MutUntrackedOrigin]]()
    return Int(p[])


def _as_char(p: Pointer[mut=True, UInt8, MutUntrackedOrigin]) -> Pointer[
    mut=True, c_char, MutUntrackedOrigin
]:
    return Pointer[mut=True, c_char, MutUntrackedOrigin](
        unsafe_from_address=Int(p)
    )


def _advance(
    p: Pointer[mut=True, UInt8, MutUntrackedOrigin], n: Int
) -> Pointer[mut=True, UInt8, MutUntrackedOrigin]:
    return Pointer[mut=True, UInt8, MutUntrackedOrigin](
        unsafe_from_address=Int(p) + n
    )


def _would_block() -> Bool:
    var e = _errno()
    return e == EAGAIN_CODE or e == EINTR_CODE


def recv_some(
    fd: Int, buf: Pointer[mut=True, UInt8, MutUntrackedOrigin], cap: Int
) -> Int:
    """Non-blocking recv. Returns >0 bytes, 0 = EOF, -1 = hard error,
    -2 = would block (EAGAIN/EINTR)."""
    if cap <= 0:
        return -2
    var n = external_call["recv", c_int](
        c_int(fd), _as_char(buf), c_int(cap), c_int(0)
    )
    if Int(n) > 0:
        return Int(n)
    if Int(n) == 0:
        return 0
    if _would_block():
        return -2
    return -1


def send_raw(
    fd: Int, buf: Pointer[mut=True, UInt8, MutUntrackedOrigin], off: Int, len_: Int
) -> Int:
    """One non-blocking send of `len_` bytes at `off`.
    Returns bytes sent (>0), 0 = would block, -1 = hard error."""
    if len_ <= 0:
        return 0
    var n = external_call["send", c_int](
        c_int(fd),
        _as_char(_advance(buf, off)),
        c_int(len_),
        c_int(MSG_NOSIGNAL),
    )
    if Int(n) > 0:
        return Int(n)
    if Int(n) == 0:
        return 0
    if _would_block():
        return 0
    return -1


def set_nonblocking(fd: Int) raises:
    var rc = external_call["fcntl", c_int](
        c_int(fd), c_int(F_SETFL), c_int(O_NONBLOCK)
    )
    if Int(rc) < 0:
        raise Error("fcntl(F_SETFL, O_NONBLOCK) failed errno=" + String(_errno()))


def close_fd(fd: Int):
    if fd >= 0:
        _ = external_call["close", c_int](c_int(fd))


def unlink_path(path: String):
    var cpath = path + chr(0)
    _ = external_call["unlink", c_int](cpath.unsafe_ptr())


# --- fixed byte buffer -----------------------------------------------------

struct Buf(Movable, Deinitable):
    """Heap block with a raw pointer. Deliberately leaked on deinit (see the
    file header)."""

    var ptr: Pointer[mut=True, UInt8, MutUntrackedOrigin]
    var cap: Int

    def __init__(out self, n: Int):
        var al = alloc(Layout[UInt8](count=n))
        self.ptr = al^.unsafe_leak()
        self.cap = n

    def __deinit__(deinit self):
        pass


# --- handshake decision (pure — exercised by tests/mojo/test_framing.mojo) --

struct HandshakeDecision(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var ok: Bool
    var code: UInt32
    var message: String
    var manual: Bool
    var edit_cap: Bool

    def __init__(out self):
        self.ok = False
        self.code = 0
        self.message = ""
        self.manual = False
        self.edit_cap = False

    def __init__(
        out self, ok: Bool, code: UInt32, message: String, manual: Bool, edit_cap: Bool
    ):
        self.ok = ok
        self.code = code
        self.message = message
        self.manual = manual
        self.edit_cap = edit_cap

    def __deinit__(deinit self):
        pass


def evaluate_hello(
    proto: UInt32,
    abi: UInt32,
    schema: UInt32,
    flags: UInt32,
    own_proto: UInt32,
    own_abi: UInt32,
    own_schema: UInt32,
) -> HandshakeDecision:
    """Server-side HELLO verdict (0008 §3.2): HELLO_OK iff proto/abi/schema
    all match; unknown flag bits are refused loudly (nothing is accepted
    silently)."""
    if flags & ~KNOWN_FLAGS != 0:
        return HandshakeDecision(
            False,
            ERR_CAPABILITY,
            "unknown HELLO flag bits 0x" + _hex32(flags) + " (known 0x"
            + _hex32(KNOWN_FLAGS) + ")",
            False,
            False,
        )
    if proto != own_proto:
        return HandshakeDecision(
            False,
            ERR_VERSION,
            "proto mismatch: client " + String(proto) + ", server "
            + String(own_proto),
            False,
            False,
        )
    if abi != own_abi:
        return HandshakeDecision(
            False,
            ERR_VERSION,
            "abi mismatch: client " + String(abi) + ", server " + String(own_abi),
            False,
            False,
        )
    if schema != own_schema:
        return HandshakeDecision(
            False,
            ERR_VERSION,
            "schema mismatch: client " + String(schema) + ", server "
            + String(own_schema),
            False,
            False,
        )
    var manual = (flags & FLAG_MANUAL_PACE) != 0
    var edit_cap = (flags & FLAG_EDIT_CAP) != 0
    return HandshakeDecision(True, 0, "", manual, edit_cap)


def _hex32(v: UInt32) -> String:
    var digits = "0123456789abcdef"
    var dl = List[UInt8]()
    for b in digits.bytes():
        dl.append(b)
    var out = String()
    for shift in range(28, -1, -4):
        out = out + chr(Int(dl[Int((v >> UInt32(shift)) & 0xF)]))
    return out^


# --- listener --------------------------------------------------------------

def open_listener(path: String) raises -> Int:
    """AF_UNIX stream listener on `path`; the stale file is unlinked first
    (0008 §1.1/§1.2). Path comes from argv — never a source literal (AP-4)."""
    var pb = List[UInt8]()
    for b in path.bytes():
        pb.append(b)
    if len(pb) == 0:
        raise Error("socket path is empty")
    if len(pb) + 3 > SUN_PATH_MAX + 2:
        raise Error(
            "socket path too long (" + String(len(pb)) + " > "
            + String(SUN_PATH_MAX - 1) + ")"
        )

    unlink_path(path)  # stale-unlink before bind

    var fd = external_call["socket", c_int](
        c_int(AF_UNIX), c_int(SOCK_STREAM), c_int(0)
    )
    if Int(fd) < 0:
        raise Error("socket() failed errno=" + String(_errno()))

    var sa = Buf(SUN_PATH_MAX + 2)
    for i in range(sa.cap):
        sa.ptr[unsafe_offset=i] = 0
    sa.ptr[unsafe_offset=0] = 1  # sa_family_t AF_UNIX = 1 (LE, low byte)
    for i in range(len(pb)):
        sa.ptr[unsafe_offset=2 + i] = pb[i]

    var rc = external_call["bind", c_int](
        c_int(Int(fd)), _as_char(sa.ptr), c_int(2 + len(pb) + 1)
    )
    if Int(rc) != 0:
        var err = _errno()
        close_fd(Int(fd))
        raise Error("bind() failed errno=" + String(err))

    rc = external_call["listen", c_int](c_int(Int(fd)), c_int(ACCEPT_BACKLOG))
    if Int(rc) != 0:
        var err = _errno()
        close_fd(Int(fd))
        raise Error("listen() failed errno=" + String(err))

    set_nonblocking(Int(fd))
    return Int(fd)


def accept_one(lfd: Int, ready_msg: String) raises -> Int:
    """Block (10 ms slices) until the first client connects."""
    print(ready_msg)
    var sa = Buf(SUN_PATH_MAX + 2)
    var sl = Buf(8)
    # Buffers are uninitialized on alloc: the kernel READS *addrlen on entry,
    # so sl must hold the real buffer size (110 = sizeof sockaddr_un).
    for i in range(sl.cap):
        sl.ptr[unsafe_offset=i] = 0
    sl.ptr[unsafe_offset=0] = 110
    sl.ptr[unsafe_offset=1] = 0
    sl.ptr[unsafe_offset=2] = 0
    sl.ptr[unsafe_offset=3] = 0
    while True:
        var fd = external_call["accept", c_int](
            c_int(lfd), _as_char(sa.ptr), _as_char(sl.ptr)
        )
        if Int(fd) >= 0:
            return Int(fd)
        if not _would_block():
            raise Error("accept() failed errno=" + String(_errno()))
        sleep(0.01)


# --- session ---------------------------------------------------------------

struct Session(Movable, Deinitable):
    var lfd: Int
    var cfd: Int
    var sock_path: String
    var pace_cli_manual: Bool
    # handshake results
    var manual: Bool
    var edit_cap: Bool
    var client_proto: UInt32
    var client_abi: UInt32
    var client_schema: UInt32
    var client_flags: UInt32
    # upstream sim state
    var input: InputBatch
    var cmd_remaining: UInt64
    # rx
    var rx: List[UInt8]
    var rxb: Buf
    var acc_sa: Buf
    var acc_len: Buf
    # tx
    var snap0: Buf
    var snap1: Buf
    var hdr0: Buf
    var hdr1: Buf
    var ctrl: Buf
    var ctrl_len: Int
    var pend_snap: Int
    var pend_snap_len: Int
    var last_snap: Int
    var tx_busy: Bool
    var tx_kind: Int  # 0 = ctrl (header+payload contiguous), 1 = snapshot
    var tx_buf: Int
    var tx_phase: Int  # snapshot only: 0 = header, 1 = payload
    var tx_off: Int
    var tx_total: Int
    var tx_pay_len: Int
    var clockb: Buf
    # session outcome
    var next_seq: UInt32
    var bye_seen: Bool
    var eof_seen: Bool
    var fatal: Bool
    var fatal_msg: String
    var fatal_code: UInt32
    var ticks_executed: UInt64
    var snapshots_produced: UInt64

    def __init__(out self, lfd: Int, cfd: Int, path: String, pace_cli_manual: Bool):
        self.lfd = lfd
        self.cfd = cfd
        self.sock_path = path
        self.pace_cli_manual = pace_cli_manual
        self.manual = False
        self.edit_cap = False
        self.client_proto = 0
        self.client_abi = 0
        self.client_schema = 0
        self.client_flags = 0
        self.input = InputBatch()
        self.cmd_remaining = 0
        self.rx = List[UInt8]()
        self.rxb = Buf(RX_SCRATCH_CAP)
        self.acc_sa = Buf(SUN_PATH_MAX + 2)
        self.acc_len = Buf(8)
        # uninitialized alloc — prime the accept() out-params (see accept_one)
        for i in range(self.acc_len.cap):
            self.acc_len.ptr[unsafe_offset=i] = 0
        self.acc_len.ptr[unsafe_offset=0] = 110
        self.snap0 = Buf(SNAP_CAP)
        self.snap1 = Buf(SNAP_CAP)
        self.hdr0 = Buf(FRAME_HEADER_BYTES)
        self.hdr1 = Buf(FRAME_HEADER_BYTES)
        self.ctrl = Buf(MAX_CTRL_FRAME_BYTES)
        self.ctrl_len = 0
        self.pend_snap = -1
        self.pend_snap_len = 0
        self.last_snap = 1  # first produce picks buffer 0
        self.tx_busy = False
        self.tx_kind = 0
        self.tx_buf = 0
        self.tx_phase = 0
        self.tx_off = 0
        self.tx_total = 0
        self.tx_pay_len = 0
        self.clockb = Buf(16)
        self.next_seq = 1
        self.bye_seen = False
        self.eof_seen = False
        self.fatal = False
        self.fatal_msg = ""
        self.fatal_code = 0
        self.ticks_executed = 0
        self.snapshots_produced = 0

    def __deinit__(deinit self):
        pass

    # --- time ---------------------------------------------------------------

    def now_ns(self) -> UInt64:
        var rc = external_call["clock_gettime", c_int](
            c_int(1), _as_char(self.clockb.ptr)  # CLOCK_MONOTONIC
        )
        if Int(rc) != 0:
            return 0
        var sec: UInt64 = 0
        var nsec: UInt64 = 0
        for i in range(8):
            sec = sec | (UInt64(self.clockb.ptr[unsafe_offset=i]) << UInt64(8 * i))
        for i in range(8):
            nsec = nsec | (
                UInt64(self.clockb.ptr[unsafe_offset=8 + i]) << UInt64(8 * i)
            )
        return sec * 1000000000 + nsec

    # --- tx primitives ------------------------------------------------------

    def queue_ctrl(mut self, frame: List[UInt8]) raises:
        """Stage a control frame. Newest wins when one is already pending
        (ACK coalescing; ERROR/BYE are always queued at points that flush
        immediately afterwards)."""
        if len(frame) > self.ctrl.cap:
            raise Error("control frame exceeds buffer")
        for i in range(len(frame)):
            self.ctrl.ptr[unsafe_offset=i] = frame[i]
        self.ctrl_len = len(frame)

    def queue_error(mut self, code: UInt32, msg: String) raises:
        var frame = encode_error_frame(self.next_seq, code, msg)
        self.next_seq += 1
        self.queue_ctrl(frame^)
        print("[scr-sim-server] out ERROR code=" + String(code) + ": " + msg)

    def queue_hello_ok(mut self) raises:
        var frame = encode_hello_ok(
            self.next_seq, SCR_SIM_IPC_PROTO_VER, ABI_VERSION, SCHEMA_VERSION
        )
        self.next_seq += 1
        self.queue_ctrl(frame^)

    def queue_ack(mut self, ack_seq: UInt32) raises:
        var frame = encode_u32_frame(FT_ACK, self.next_seq, ack_seq)
        self.next_seq += 1
        self.queue_ctrl(frame^)

    def tx_idle(self) -> Bool:
        return (not self.tx_busy) and self.ctrl_len == 0 and self.pend_snap < 0

    def _start_tx(mut self) -> Bool:
        if self.ctrl_len > 0:
            self.tx_kind = 0
            self.tx_total = self.ctrl_len
            self.tx_off = 0
            self.ctrl_len = 0
            self.tx_busy = True
            return True
        if self.pend_snap >= 0:
            self.tx_kind = 1
            self.tx_buf = self.pend_snap
            self.tx_pay_len = self.pend_snap_len
            self.tx_phase = 0
            self.tx_off = 0
            self.tx_total = FRAME_HEADER_BYTES + self.tx_pay_len
            self.pend_snap = -1
            self.tx_busy = True
            return True
        return False

    def _tx_step(mut self, budget: Int) -> Int:
        """One send attempt. Returns bytes consumed (>= 0), -1 hard error
        (peer gone), -2 would block. 1 marks a phase/frame completion."""
        var base: Pointer[mut=True, UInt8, MutUntrackedOrigin] = self.ctrl.ptr
        var seg_len = self.tx_total
        if self.tx_kind == 1:
            if self.tx_phase == 0:
                if self.tx_buf == 0:
                    base = self.hdr0.ptr
                else:
                    base = self.hdr1.ptr
                seg_len = FRAME_HEADER_BYTES
            else:
                if self.tx_buf == 0:
                    base = self.snap0.ptr
                else:
                    base = self.snap1.ptr
                seg_len = self.tx_pay_len

        var remaining = seg_len - self.tx_off
        if remaining <= 0:
            if self.tx_kind == 0:
                self.tx_busy = False
                return 1
            if self.tx_phase == 0:
                self.tx_phase = 1
                self.tx_off = 0
                return 1
            self.tx_busy = False
            return 1

        var want = remaining
        if want > budget:
            want = budget
        var n = send_raw(self.cfd, base, self.tx_off, want)
        if n < 0:
            return -1
        if n == 0:
            return -2
        self.tx_off += n
        if self.tx_off >= seg_len:
            if self.tx_kind == 0:
                self.tx_busy = False
                return 1
            if self.tx_phase == 0:
                self.tx_phase = 1
                self.tx_off = 0
                return 1
            self.tx_busy = False
            return 1
        return n

    def flush_tx(mut self) raises -> Bool:
        """Drain pending bytes up to a bounded budget. False = peer gone."""
        var budget = MAX_TX_BYTES_PER_FLUSH
        while budget > 0:
            if not self.tx_busy:
                if not self._start_tx():
                    return True
            var r = self._tx_step(budget)
            if r == -1:
                return False
            if r == -2:
                return True
            if r > 0:
                budget -= r
            else:
                budget -= 1
        return True

    def flush_bounded(mut self, budget_ms: Int) raises -> Bool:
        var waited = 0
        while waited <= budget_ms:
            if not self.flush_tx():
                return False
            if self.tx_idle():
                return True
            sleep(0.01)
            waited += 10
        return self.tx_idle()

    # --- rx -----------------------------------------------------------------

    def fatal_stop(mut self, code: UInt32, msg: String) raises:
        self.fatal = True
        self.fatal_code = code
        self.fatal_msg = msg
        self.queue_error(code, msg)

    def consume_rx(mut self, n: Int):
        for i in range(n):
            self.rx.append(self.rxb.ptr[unsafe_offset=i])

    def drop_prefix(mut self, n: Int):
        var out = List[UInt8]()
        for i in range(n, len(self.rx)):
            out.append(self.rx[i])
        self.rx = out^

    def handle_frame(mut self, h: FrameHeader, payload: List[UInt8]) raises -> Bool:
        """Returns False when the session must stop (fatal)."""
        if h.ftype == FT_HELLO:
            self.fatal_stop(ERR_PROTOCOL, "HELLO after handshake")
            return False
        if h.ftype == FT_SNAPSHOT or h.ftype == FT_HELLO_OK or h.ftype == FT_ERROR:
            self.fatal_stop(
                ERR_PROTOCOL,
                "frame type " + String(h.ftype) + " is server-to-client only",
            )
            return False
        if h.ftype == FT_INPUT:
            if len(payload) != INPUT_PAYLOAD_BYTES:
                self.fatal_stop(
                    ERR_MALFORMED,
                    "INPUT payload is " + String(len(payload)) + " bytes, need "
                    + String(INPUT_PAYLOAD_BYTES),
                )
                return False
            try:
                self.input.move_x = get_f32(payload, 0)
                self.input.move_y = get_f32(payload, 4)
                self.input.look_dx = get_f32(payload, 8)
                self.input.look_dy = get_f32(payload, 12)
            except e:
                self.fatal_stop(ERR_MALFORMED, "INPUT non-finite float: " + String(e))
                return False
            self.input.jump = payload[16]
            self.input.sprint = payload[17]
            self.input.action_primary = payload[18]
            self.input.action_secondary = payload[19]
            self.queue_ack(h.seq)
            return True
        if h.ftype == FT_EDIT:
            if not self.edit_cap:
                self.fatal_stop(
                    ERR_CAPABILITY,
                    "EDIT frame without HELLO SCR_IPC_FLAG_EDIT_CAP",
                )
                return False
            if len(payload) != EDIT_PAYLOAD_BYTES:
                self.fatal_stop(
                    ERR_MALFORMED,
                    "EDIT payload is " + String(len(payload)) + " bytes, need "
                    + String(EDIT_PAYLOAD_BYTES),
                )
                return False
            var reserved = UInt32(payload[2]) | (UInt32(payload[3]) << 8)
            if reserved != 0:
                self.fatal_stop(ERR_MALFORMED, "EDIT reserved != 0")
                return False
            var rc = runtime_edit_submit(payload[0], payload[1])
            if rc == SCR_ERR_QUEUE_FULL:
                # Non-fatal, still loud: ERROR frame, session continues.
                self.queue_error(ERR_INTERNAL, "edit queue full — batch rejected")
                return True
            if rc != 0:
                self.fatal_stop(
                    ERR_INTERNAL, "scr_edit_submit failed with code " + String(rc)
                )
                return False
            self.queue_ack(h.seq)
            return True
        if h.ftype == FT_ACK:
            # Client-side ACK of our frames; no window accounting is required
            # yet (sprint 03/04). Nothing is silently invented in response.
            return True
        if h.ftype == FT_BYE:
            self.bye_seen = True
            return True
        if h.ftype == FT_CMD_TICK:
            if not self.manual:
                self.fatal_stop(ERR_PACE, "CMD_TICK outside a manual-pace handshake")
                return False
            var n = parse_u32_payload(payload, 4, "CMD_TICK")
            if n == 0 or n > MAX_CMD_TICK:
                self.fatal_stop(
                    ERR_PACE,
                    "CMD_TICK n=" + String(n) + " outside 1.." + String(MAX_CMD_TICK),
                )
                return False
            self.cmd_remaining = self.cmd_remaining + UInt64(n)
            return True
        self.fatal_stop(ERR_PROTOCOL, "unhandled frame type " + String(h.ftype))
        return False

    def process_rx(mut self) raises -> Bool:
        """Parse every complete frame buffered in `rx`. False = fatal."""
        while True:
            if len(self.rx) < FRAME_HEADER_BYTES:
                return True
            var h: FrameHeader
            try:
                h = decode_header(self.rx, 0)
            except e:
                self.fatal_stop(ERR_MALFORMED, String(e))
                return False
            if Int(h.length) > RX_MAX_PAYLOAD:
                self.fatal_stop(
                    ERR_MALFORMED,
                    "client frame payload " + String(h.length) + " > cap "
                    + String(RX_MAX_PAYLOAD),
                )
                return False
            var total = frame_total(h)
            if len(self.rx) < total:
                return True
            var payload = decode_payload(self.rx, h)
            self.drop_prefix(total)
            if not self.handle_frame(h, payload^):
                return False

    def drain_rx(mut self) raises -> Int:
        """Read until EAGAIN. Returns DRAIN_EOF (peer gone), DRAIN_FATAL,
        or DRAIN_OK."""
        if not self.process_rx():
            return DRAIN_FATAL
        while True:
            var n = recv_some(self.cfd, self.rxb.ptr, self.rxb.cap)
            if n == -2:
                return DRAIN_OK
            if n == 0:
                return DRAIN_EOF
            if n < 0:
                return DRAIN_EOF  # hard error == peer gone
            if len(self.rx) + n > RX_MAX_BUFFER:
                self.fatal_stop(
                    ERR_MALFORMED,
                    "client frame buffer overrun (" + String(len(self.rx) + n) + ")",
                )
                return DRAIN_FATAL
            self.consume_rx(n)
            if not self.process_rx():
                return DRAIN_FATAL

    # --- second-connection refusal -------------------------------------------

    def refuse_extra_client(mut self) raises:
        var fd = external_call["accept", c_int](
            c_int(self.lfd), _as_char(self.acc_sa.ptr), _as_char(self.acc_len.ptr)
        )
        if Int(fd) < 0:
            return
        var frame = encode_error_frame(
            self.next_seq,
            ERR_BUSY,
            "single-client server: a session is already active",
        )
        self.next_seq += 1
        var fb = Buf(len(frame))
        for i in range(len(frame)):
            fb.ptr[unsafe_offset=i] = frame[i]
        var off = 0
        var guard = 0
        while off < len(frame) and guard < 4:
            var n = send_raw(Int(fd), fb.ptr, off, len(frame) - off)
            if n < 0:
                break
            if n == 0:
                guard += 1
                sleep(0.01)
                continue
            off += n
        print("[scr-sim-server] refused a second concurrent connection")
        close_fd(Int(fd))

    # --- ticking ---------------------------------------------------------------

    def produce_snapshot(mut self) raises:
        var need = Int(runtime_snapshot_size())
        if need <= 0:
            self.fatal_stop(ERR_INTERNAL, "no snapshot after a tick")
            return
        if need > SNAP_CAP:
            self.fatal_stop(
                ERR_INTERNAL,
                "snapshot " + String(need) + " bytes > buffer " + String(SNAP_CAP),
            )
            return
        var dest: Int
        if self.pend_snap >= 0:
            dest = self.pend_snap  # latest-wins: overwrite the unsent slot
        elif self.tx_busy and self.tx_kind == 1:
            dest = 1 - self.tx_buf  # never touch the in-flight buffer
        else:
            dest = 1 - self.last_snap
        var dst: Pointer[mut=True, UInt8, MutUntrackedOrigin]
        var hdr: Pointer[mut=True, UInt8, MutUntrackedOrigin]
        if dest == 0:
            dst = self.snap0.ptr
            hdr = self.hdr0.ptr
        else:
            dst = self.snap1.ptr
            hdr = self.hdr1.ptr
        var written = Int(runtime_snapshot_write(dst, need))
        if written != need:
            self.fatal_stop(
                ERR_INTERNAL,
                "snapshot_write returned " + String(written) + ", expected "
                + String(need),
            )
            return
        var seq = self.next_seq
        self.next_seq += 1
        _write_u32_at(hdr, 0, FRAME_MAGIC)
        _write_u32_at(hdr, 4, FT_SNAPSHOT)
        _write_u32_at(hdr, 8, seq)
        _write_u32_at(hdr, 12, UInt32(need))
        self.pend_snap = dest
        self.pend_snap_len = need
        self.last_snap = dest
        self.snapshots_produced += 1
        print(
            "[scr-sim-server] tick=" + String(self.ticks_executed) + " seq="
            + String(seq) + " bytes=" + String(need)
        )

    def one_tick(mut self) raises:
        var ticks = Int(runtime_step(FIXED_DT, self.input))
        if ticks < 0:
            self.fatal_stop(
                ERR_INTERNAL, "scr_sim_step failed with code " + String(ticks)
            )
            return
        if ticks == 0:
            # Unreachable with dt = FIXED_DT (epsilon rule in sim/world.mojo);
            # kept honest instead of emitting a phantom snapshot.
            return
        if ticks > 1:
            print(
                "[scr-sim-server] note: step ran " + String(ticks)
                + " ticks (expected 1) — snapshot covers the whole step"
            )
        self.ticks_executed += UInt64(ticks)
        self.produce_snapshot()

    # --- handshake ---------------------------------------------------------------

    def handshake(
        mut self, own_proto: UInt32, own_abi: UInt32, own_schema: UInt32
    ) raises -> Bool:
        """Blocking-ish handshake over the non-blocking client fd.
        True = HELLO_OK queued and flushed; False = refused (ERROR flushed)
        or fatal."""
        set_nonblocking(self.cfd)
        var deadline = self.now_ns() + UInt64(HANDSHAKE_TIMEOUT_MS) * 1000000
        print(
            "[scr-sim-server] awaiting HELLO (own proto=" + String(own_proto)
            + " abi=" + String(own_abi) + " schema=" + String(own_schema) + ")"
        )
        while True:
            var verdict_status = self._handshake_attempt(own_proto, own_abi, own_schema)
            if verdict_status == 1:
                return True
            if verdict_status == 2:
                _ = self.flush_bounded(BUSY_FLUSH_MS)
                return False
            if self.now_ns() >= deadline:
                self.fatal_stop(ERR_PROTOCOL, "handshake timed out (no HELLO)")
                _ = self.flush_bounded(BUSY_FLUSH_MS)
                return False
            var n = recv_some(self.cfd, self.rxb.ptr, self.rxb.cap)
            if n == -2:
                sleep(0.002)
                continue
            if n <= 0:
                print("[scr-sim-server] EOF before HELLO")
                _ = self.flush_bounded(BUSY_FLUSH_MS)
                return False
            if len(self.rx) + n > RX_MAX_BUFFER:
                self.fatal_stop(ERR_MALFORMED, "handshake buffer overrun")
                _ = self.flush_bounded(BUSY_FLUSH_MS)
                return False
            self.consume_rx(n)

    def _handshake_attempt(
        mut self, own_proto: UInt32, own_abi: UInt32, own_schema: UInt32
    ) raises -> Int:
        """0 = need more bytes, 1 = accepted (HELLO_OK staged), 2 = refused
        (ERROR staged, `fatal` set)."""
        if len(self.rx) < FRAME_HEADER_BYTES:
            return 0
        var h: FrameHeader
        try:
            h = decode_header(self.rx, 0)
        except e:
            self._refuse_now(ERR_MALFORMED, "handshake: " + String(e))
            return 2
        if Int(h.length) > RX_MAX_PAYLOAD:
            self._refuse_now(
                ERR_MALFORMED,
                "handshake frame payload " + String(h.length) + " > cap",
            )
            return 2
        var total = frame_total(h)
        if len(self.rx) < total:
            return 0
        var payload = decode_payload(self.rx, h)
        if h.ftype != FT_HELLO:
            self._refuse_now(
                ERR_PROTOCOL,
                "first frame must be HELLO, got type " + String(h.ftype),
            )
            return 2
        var proto: UInt32
        var abi: UInt32
        var schema: UInt32
        var flags: UInt32
        try:
            var parsed = parse_hello(payload^)
            proto = parsed[0]
            abi = parsed[1]
            schema = parsed[2]
            flags = parsed[3]
        except e:
            self._refuse_now(ERR_MALFORMED, String(e))
            return 2
        self.client_proto = proto
        self.client_abi = abi
        self.client_schema = schema
        self.client_flags = flags
        var verdict = evaluate_hello(
            proto, abi, schema, flags, own_proto, own_abi, own_schema
        )
        if not verdict.ok:
            print(
                "[scr-sim-server] handshake REFUSED (client proto="
                + String(proto) + " abi=" + String(abi) + " schema="
                + String(schema) + " flags=0x" + _hex32(flags) + "): "
                + verdict.message
            )
            self._refuse_now(verdict.code, verdict.message)
            return 2
        self.manual = self.pace_cli_manual or verdict.manual
        self.edit_cap = verdict.edit_cap
        var edit_text = "0"
        if self.edit_cap:
            edit_text = "1"
        print(
            "[scr-sim-server] handshake OK (proto=" + String(proto) + " abi="
            + String(abi) + " schema=" + String(schema) + " flags=0x"
            + _hex32(flags) + " pace=" + _pace_name(self.manual) + " edit_cap="
            + edit_text + ")"
        )
        self.drop_prefix(total)
        self.queue_hello_ok()
        if not self.flush_bounded(CLOSE_FLUSH_MS):
            print("[scr-sim-server] peer vanished during HELLO_OK")
            return 2
        return 1

    def _refuse_now(mut self, code: UInt32, msg: String):
        # Marks the session fatal so `serve()` exits non-zero after the
        # refusal has been flushed (0008 AP-17: refusals are loud, never
        # silent; the client still reads the ERROR frame before we exit).
        self.fatal = True
        self.fatal_code = code
        self.fatal_msg = msg
        try:
            self.queue_error(code, msg)
        except e:
            print("[scr-sim-server] could not queue refusal: " + String(e))

    # --- session loop -------------------------------------------------------------

    def run(mut self) raises -> Int:
        """Returns the process exit code for this session."""
        var next_tick = self.now_ns() + WALL_TICK_NS
        while True:
            var st = self.drain_rx()
            if st == DRAIN_FATAL:
                _ = self.flush_bounded(CLOSE_FLUSH_MS)
                self.close_session()
                raise Error("session fatal: " + self.fatal_msg)
            if st == DRAIN_EOF or self.bye_seen:
                break
            self.refuse_extra_client()
            if not self.flush_tx():
                print("[scr-sim-server] peer closed during write")
                self.close_session()
                print(
                    "[scr-sim-server] session end ticks="
                    + String(self.ticks_executed) + " snapshots="
                    + String(self.snapshots_produced)
                )
                return 0
            if self.manual:
                if self.cmd_remaining > 0:
                    self.one_tick()
                    if self.fatal:
                        continue
                    self.cmd_remaining -= 1
                    continue
                sleep(IDLE_SLEEP_S)
            else:
                var now = self.now_ns()
                if now >= next_tick:
                    self.one_tick()
                    next_tick += WALL_TICK_NS
                    # Bound catch-up so a stalled host cannot queue a burst
                    # of hundreds of ticks in one pass.
                    if next_tick + 1000000000 < now:
                        next_tick = now + WALL_TICK_NS
                else:
                    var rem = next_tick - now
                    var nap = rem
                    if nap > 1000000:
                        nap = 1000000
                    sleep(Float64(nap) / 1000000000.0)

        if self.bye_seen:
            print("[scr-sim-server] client BYE — flushing and shutting down")
            _ = self.flush_bounded(CLOSE_FLUSH_MS)
        self.close_session()
        print(
            "[scr-sim-server] session end ticks=" + String(self.ticks_executed)
            + " snapshots=" + String(self.snapshots_produced)
        )
        return 0

    def close_session(mut self):
        close_fd(self.cfd)
        self.cfd = -1
        close_fd(self.lfd)
        self.lfd = -1
        unlink_path(self.sock_path)


def _write_u32_at(
    p: Pointer[mut=True, UInt8, MutUntrackedOrigin], off: Int, v: UInt32
):
    p[unsafe_offset=off] = UInt8(v & 0xFF)
    p[unsafe_offset=off + 1] = UInt8((v >> 8) & 0xFF)
    p[unsafe_offset=off + 2] = UInt8((v >> 16) & 0xFF)
    p[unsafe_offset=off + 3] = UInt8((v >> 24) & 0xFF)


def _pace_name(manual: Bool) -> String:
    if manual:
        return "manual"
    return "wall"


# --- top-level entry ---------------------------------------------------------

def serve(path: String, pace_manual: Bool, seed: UInt32) raises -> Int:
    """Full server lifecycle for one client session (returns exit code)."""
    print(
        "[scr-sim-server] start seed=" + String(seed) + " pace="
        + _pace_name(pace_manual) + " socket=" + path
    )
    var rc = runtime_init(seed)
    if rc != 0:
        raise Error("runtime init failed with code " + String(rc))
    var lfd = open_listener(path)
    var cfd: Int
    try:
        cfd = accept_one(lfd, "[scr-sim-server] listening — waiting for a client")
    except e:
        close_fd(lfd)
        unlink_path(path)
        runtime_shutdown()
        raise e
    var sess = Session(lfd, cfd, path, pace_manual)
    var ok = sess.handshake(SCR_SIM_IPC_PROTO_VER, ABI_VERSION, SCHEMA_VERSION)
    if not ok:
        sess.close_session()
        runtime_shutdown()
        if sess.fatal:
            raise Error("handshake refused: " + sess.fatal_msg)
        raise Error("handshake failed: client disconnected before HELLO completed")
    var code = sess.run()
    runtime_shutdown()
    return code
