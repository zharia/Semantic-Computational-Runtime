# IPC framing codec — milestone 0008 §3.2 (0008 AP-15..18).
#
# Little-endian frame:
#   u32 magic  = 0x54524353  ('S C R T' as bytes)
#   u32 type   (1..9)
#   u32 seq    (per-sender monotonic counter)
#   u32 length (payload byte count)
#   u8  payload[length]
#
# Frame types (0008 §3.2):
#   1 HELLO      C->S  {u32 proto, u32 abi, u32 schema, u32 flags}   16 B
#   2 HELLO_OK   S->C  {u32 proto, u32 abi, u32 schema}              12 B
#   3 ERROR      both  {u32 code, u32 msg_len, bytes msg}
#   4 SNAPSHOT   S->C  payload = exact RenderSnapshot bytes
#   5 INPUT      C->S  payload = scr_input_batch (20 B)
#   6 EDIT       C->S  payload = scr_edit_batch (4 B)
#   7 ACK        S->C  {u32 ack_seq}
#   8 BYE        both  no payload
#   9 CMD_TICK   C->S  {u32 n}   (manual pace only)
#
# AP-1: this module is engine-free (checked by scripts/check_layout.sh gate 1
# over all of src/mojo) and payload-blind — framing wraps bytes it never
# alters (0008 invariant 1 / AP-16).
#
# Malformed rejection (loud, never coerced — 104_contract §8): bad magic,
# unknown type, length above MAX_PAYLOAD, or a truncated buffer when the
# caller has the full frame all raise Error.

from std.collections import List

# --- protocol identity -----------------------------------------------------

comptime SCR_SIM_IPC_PROTO_VER: UInt32 = 1

# --- wire constants --------------------------------------------------------

comptime FRAME_MAGIC: UInt32 = 0x54524353  # bytes 'S','C','R','T' (LE)
comptime FRAME_HEADER_BYTES: Int = 16
# Absurd-length cap: a header claiming more than this is rejected outright
# (allocations are sized from validated lengths only). Snapshots are ~250 KB
# at schema 7 (fixture 249024 B) — 16 MiB is >= 64x headroom.
comptime MAX_PAYLOAD: UInt32 = 16777216

comptime FT_HELLO: UInt32 = 1
comptime FT_HELLO_OK: UInt32 = 2
comptime FT_ERROR: UInt32 = 3
comptime FT_SNAPSHOT: UInt32 = 4
comptime FT_INPUT: UInt32 = 5
comptime FT_EDIT: UInt32 = 6
comptime FT_ACK: UInt32 = 7
comptime FT_BYE: UInt32 = 8
comptime FT_CMD_TICK: UInt32 = 9
comptime FT_MIN: UInt32 = 1
comptime FT_MAX: UInt32 = 9

# HELLO flags (0008 §3.2): bit0 = SCR_IPC_FLAG_MANUAL_PACE,
# bit1 = SCR_IPC_FLAG_EDIT_CAP (client declares edit uplink capability —
# "capability-flagged; absent => ERROR", §3.2 type 6).
comptime FLAG_MANUAL_PACE: UInt32 = 1
comptime FLAG_EDIT_CAP: UInt32 = 2
comptime KNOWN_FLAGS: UInt32 = 3

# Fixed payload sizes (validated exactly).
comptime HELLO_PAYLOAD_BYTES: Int = 16
comptime HELLO_OK_PAYLOAD_BYTES: Int = 12
comptime INPUT_PAYLOAD_BYTES: Int = 20
comptime EDIT_PAYLOAD_BYTES: Int = 4
comptime ACK_PAYLOAD_BYTES: Int = 4
comptime CMD_TICK_PAYLOAD_BYTES: Int = 4
comptime ERROR_HEADER_BYTES: Int = 8  # code + msg_len
comptime MAX_ERROR_MSG_BYTES: Int = 1024
comptime MAX_CTRL_FRAME_BYTES: Int = 16 + ERROR_HEADER_BYTES + 1024

# ERROR codes (payload field `code`).
comptime ERR_PROTOCOL: UInt32 = 1   # wrong/absent HELLO, bad frame type order
comptime ERR_VERSION: UInt32 = 2    # proto/abi/schema mismatch
comptime ERR_MALFORMED: UInt32 = 3  # magic/type/length violation
comptime ERR_BUSY: UInt32 = 4       # single-client server already has a client
comptime ERR_CAPABILITY: UInt32 = 5 # unknown HELLO flag / EDIT without cap
comptime ERR_PACE: UInt32 = 6       # CMD_TICK in wall mode / absurd n
comptime ERR_INTERNAL: UInt32 = 7   # server-side runtime failure


# --- primitive helpers -----------------------------------------------------

def put_u32_le(mut buf: List[UInt8], v: UInt32):
    """Append `v` as 4 little-endian bytes."""
    buf.append(UInt8(v & 0xFF))
    buf.append(UInt8((v >> 8) & 0xFF))
    buf.append(UInt8((v >> 16) & 0xFF))
    buf.append(UInt8((v >> 24) & 0xFF))


def get_u32_le(buf: List[UInt8], off: Int, end: Int) raises -> UInt32:
    """Read 4 little-endian bytes at `off`; raises if `off + 4 > end`."""
    if off < 0 or off + 4 > end or end > len(buf):
        raise Error("framing: u32 read out of range (off=" + String(off) + ")")
    return (
        UInt32(buf[off])
        | (UInt32(buf[off + 1]) << 8)
        | (UInt32(buf[off + 2]) << 16)
        | (UInt32(buf[off + 3]) << 24)
    )


def is_known_type(ftype: UInt32) -> Bool:
    return ftype >= FT_MIN and ftype <= FT_MAX


# --- encode ----------------------------------------------------------------

def encode_header(ftype: UInt32, seq: UInt32, length: UInt32) raises -> List[UInt8]:
    """16-byte frame header (magic, type, seq, length)."""
    if length > MAX_PAYLOAD:
        raise Error("framing: payload length above cap")
    var out = List[UInt8]()
    put_u32_le(out, FRAME_MAGIC)
    put_u32_le(out, ftype)
    put_u32_le(out, seq)
    put_u32_le(out, length)
    return out^


def encode_frame(ftype: UInt32, seq: UInt32, payload: List[UInt8]) raises -> List[UInt8]:
    """Complete frame: header || payload. Payload bytes are copied verbatim
    (AP-16 — framing never transforms payload)."""
    if not is_known_type(ftype):
        raise Error("framing: unknown frame type " + String(ftype))
    if len(payload) > Int(MAX_PAYLOAD):
        raise Error("framing: payload above cap")
    var out = encode_header(ftype, seq, UInt32(len(payload)))
    for i in range(len(payload)):
        out.append(payload[i])
    return out^


def encode_u32_frame(ftype: UInt32, seq: UInt32, value: UInt32) raises -> List[UInt8]:
    """Frame with a single u32 payload (ACK, CMD_TICK)."""
    var p = List[UInt8]()
    put_u32_le(p, value)
    return encode_frame(ftype, seq, p^)


def encode_hello(
    seq: UInt32, proto: UInt32, abi: UInt32, schema: UInt32, flags: UInt32
) raises -> List[UInt8]:
    var p = List[UInt8]()
    put_u32_le(p, proto)
    put_u32_le(p, abi)
    put_u32_le(p, schema)
    put_u32_le(p, flags)
    return encode_frame(FT_HELLO, seq, p^)


def encode_hello_ok(
    seq: UInt32, proto: UInt32, abi: UInt32, schema: UInt32
) raises -> List[UInt8]:
    var p = List[UInt8]()
    put_u32_le(p, proto)
    put_u32_le(p, abi)
    put_u32_le(p, schema)
    return encode_frame(FT_HELLO_OK, seq, p^)


def encode_error_frame(seq: UInt32, code: UInt32, msg: String) raises -> List[UInt8]:
    """ERROR {u32 code, u32 msg_len, bytes msg} — msg capped at 1024 B."""
    var bytes = List[UInt8]()
    for b in msg.bytes():
        bytes.append(b)
    if len(bytes) > MAX_ERROR_MSG_BYTES:
        # Truncation of a diagnostic is loud, not silent: the code stays and
        # the caller logs the full message too.
        var cut = List[UInt8]()
        for i in range(MAX_ERROR_MSG_BYTES):
            cut.append(bytes[i])
        bytes = cut^
    var p = List[UInt8]()
    put_u32_le(p, code)
    put_u32_le(p, UInt32(len(bytes)))
    for i in range(len(bytes)):
        p.append(bytes[i])
    return encode_frame(FT_ERROR, seq, p^)


# --- decode ----------------------------------------------------------------

struct FrameHeader(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var ftype: UInt32
    var seq: UInt32
    var length: UInt32

    def __init__(out self):
        self.ftype = 0
        self.seq = 0
        self.length = 0

    def __init__(out self, ftype: UInt32, seq: UInt32, length: UInt32):
        self.ftype = ftype
        self.seq = seq
        self.length = length

    def __deinit__(deinit self):
        pass


def decode_header(buf: List[UInt8], start: Int) raises -> FrameHeader:
    """Parse + validate a header at `start`. Raises on bad magic, unknown
    type, length above MAX_PAYLOAD, or insufficient bytes."""
    if start < 0 or start + FRAME_HEADER_BYTES > len(buf):
        raise Error("framing: truncated header")
    var magic = get_u32_le(buf, start, len(buf))
    if magic != FRAME_MAGIC:
        raise Error(
            "framing: bad magic 0x" + _hex32(magic) + " (expected 0x54524353)"
        )
    var ftype = get_u32_le(buf, start + 4, len(buf))
    if not is_known_type(ftype):
        raise Error("framing: unknown frame type " + String(ftype))
    var seq = get_u32_le(buf, start + 8, len(buf))
    var length = get_u32_le(buf, start + 12, len(buf))
    if length > MAX_PAYLOAD:
        raise Error(
            "framing: absurd payload length " + String(length) + " > cap "
            + String(MAX_PAYLOAD)
        )
    return FrameHeader(ftype, seq, length)


def frame_total(header: FrameHeader) -> Int:
    """Total bytes of the frame (header + payload)."""
    return FRAME_HEADER_BYTES + Int(header.length)


def decode_payload(buf: List[UInt8], header: FrameHeader) raises -> List[UInt8]:
    """Payload view of a complete frame sitting at offset 0 of `buf`.
    Raises when `buf` does not hold the whole frame (truncated)."""
    var total = frame_total(header)
    if len(buf) < total:
        raise Error(
            "framing: truncated frame (have " + String(len(buf)) + ", need "
            + String(total) + ")"
        )
    var out = List[UInt8]()
    var n = Int(header.length)
    for i in range(n):
        out.append(buf[FRAME_HEADER_BYTES + i])
    return out^


def parse_hello(
    payload: List[UInt8],
) raises -> Tuple[UInt32, UInt32, UInt32, UInt32]:
    """HELLO payload -> (proto, abi, schema, flags). Exact size enforced."""
    if len(payload) != HELLO_PAYLOAD_BYTES:
        raise Error(
            "framing: HELLO payload is " + String(len(payload)) + " bytes, need "
            + String(HELLO_PAYLOAD_BYTES)
        )
    var proto = get_u32_le(payload, 0, len(payload))
    var abi = get_u32_le(payload, 4, len(payload))
    var schema = get_u32_le(payload, 8, len(payload))
    var flags = get_u32_le(payload, 12, len(payload))
    return proto, abi, schema, flags


def parse_u32_payload(payload: List[UInt8], expected: Int, what: String) raises -> UInt32:
    """Single-u32 payload parser (ACK, CMD_TICK) with exact size check."""
    if len(payload) != expected:
        raise Error(
            "framing: " + what + " payload is " + String(len(payload))
            + " bytes, need " + String(expected)
        )
    return get_u32_le(payload, 0, len(payload))


def parse_error_payload(payload: List[UInt8],) raises -> Tuple[UInt32, String]:
    """ERROR payload -> (code, message)."""
    if len(payload) < ERROR_HEADER_BYTES:
        raise Error("framing: ERROR payload truncated")
    var code = get_u32_le(payload, 0, len(payload))
    var msg_len = get_u32_le(payload, 4, len(payload))
    if Int(msg_len) + ERROR_HEADER_BYTES != len(payload):
        raise Error(
            "framing: ERROR msg_len " + String(msg_len)
            + " does not match payload " + String(len(payload))
        )
    var msg = String()
    for i in range(Int(msg_len)):
        msg = msg + chr(Int(payload[ERROR_HEADER_BYTES + i]))
    return code, msg^


def _hex32(v: UInt32) -> String:
    """Lowercase hex (no 0x) for diagnostics."""
    var digits = "0123456789abcdef"
    var dl = List[UInt8]()
    for b in digits.bytes():
        dl.append(b)
    var out = String()
    for shift in range(28, -1, -4):
        var nibble = Int((v >> UInt32(shift)) & 0xF)
        out = out + chr(Int(dl[nibble]))
    return out^
