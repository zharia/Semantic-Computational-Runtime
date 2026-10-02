# Spec test — IPC framing codec + HELLO verdict (milestone 0008 §3.2 /
# 0008 AP-15..AP-18, invariant: payload-blind framing + loud refusal).
#
# Covers:
#   - round-trip of every frame type the wire carries (header fields,
#     payload bytes verbatim = AP-16, frame_total consistency),
#   - malformed input fails loudly, never coerced (104_contract §8):
#     bad magic, unknown type, absurd length, truncation, bad HELLO size,
#     u32 read out of range,
#   - ERROR payload codec incl. msg_len cross-check,
#   - evaluate_hello decision matrix: exact match accepted; any
#     proto/abi/schema mismatch => ERR_VERSION; unknown flag bits =>
#     ERR_CAPABILITY (no silent acceptance); manual/edit flags propagate.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error => TestSuite FAIL.

from std.collections import List
from std.testing import TestSuite

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
    MAX_ERROR_MSG_BYTES,
    ERR_VERSION,
    ERR_CAPABILITY,
    put_u32_le,
    get_u32_le,
    encode_header,
    encode_frame,
    encode_u32_frame,
    encode_hello,
    encode_hello_ok,
    encode_error_frame,
    decode_header,
    decode_payload,
    frame_total,
    parse_hello,
    parse_u32_payload,
    parse_error_payload,
)
from server.session import evaluate_hello


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _u32_at(buf: List[UInt8], off: Int) raises -> UInt32:
    return get_u32_le(buf, off, len(buf))


def _expect_raise_malformed_header(buf: List[UInt8]) raises -> Bool:
    try:
        _ = decode_header(buf, 0)
        return False
    except e:
        return True


def _pattern(n: Int) -> List[UInt8]:
    """Deterministic byte pattern for verbatim round-trip checks."""
    var out = List[UInt8]()
    for i in range(n):
        out.append(UInt8((i * 7 + 3) & 0xFF))
    return out^


# --- round-trips ------------------------------------------------------------

def test_header_and_payload_roundtrip() raises:
    var frame = encode_frame(FT_INPUT, 42, _pattern(INPUT_PAYLOAD_BYTES))
    _check(len(frame) == FRAME_HEADER_BYTES + INPUT_PAYLOAD_BYTES, "INPUT frame size")
    var h = decode_header(frame, 0)
    _check(h.ftype == FT_INPUT, "header type")
    _check(h.seq == 42, "header seq")
    _check(h.length == UInt32(INPUT_PAYLOAD_BYTES), "header length")
    _check(frame_total(h) == len(frame), "frame_total == frame bytes")
    var payload = decode_payload(frame, h)
    _check(len(payload) == INPUT_PAYLOAD_BYTES, "payload size")
    for i in range(INPUT_PAYLOAD_BYTES):
        _check(
            payload[i] == _pattern(INPUT_PAYLOAD_BYTES)[i],
            "AP-16 payload byte " + String(i) + " verbatim",
        )


def test_magic_and_seq_fields_on_the_wire() raises:
    var frame = encode_frame(FT_BYE, 0xFFFFFFFF, List[UInt8]())
    # magic 'SCRT' little-endian on the wire: 53 43 52 54
    _check(frame[0] == 0x53, "magic byte 0 'S'")
    _check(frame[1] == 0x43, "magic byte 1 'C'")
    _check(frame[2] == 0x52, "magic byte 2 'R'")
    _check(frame[3] == 0x54, "magic byte 3 'T'")
    _check(_u32_at(frame, 0) == FRAME_MAGIC, "magic u32")
    _check(_u32_at(frame, 4) == FT_BYE, "type field")
    _check(_u32_at(frame, 8) == 0xFFFFFFFF, "seq field full range")
    _check(_u32_at(frame, 12) == 0, "BYE length 0")


def test_hello_roundtrip() raises:
    var flags = FLAG_MANUAL_PACE | FLAG_EDIT_CAP
    var frame = encode_hello(7, SCR_SIM_IPC_PROTO_VER, 2, 6, flags)
    _check(len(frame) == FRAME_HEADER_BYTES + 16, "HELLO frame size 32")
    var h = decode_header(frame, 0)
    _check(h.ftype == FT_HELLO, "type HELLO")
    _check(h.seq == 7, "seq 7")
    var payload = decode_payload(frame, h)
    var parsed = parse_hello(payload^)
    _check(parsed[0] == SCR_SIM_IPC_PROTO_VER, "proto round-trip")
    _check(parsed[1] == 2, "abi round-trip")
    _check(parsed[2] == 6, "schema round-trip")
    _check(parsed[3] == flags, "flags round-trip")


def test_hello_ok_roundtrip() raises:
    var frame = encode_hello_ok(1, SCR_SIM_IPC_PROTO_VER, 2, 6)
    _check(len(frame) == FRAME_HEADER_BYTES + 12, "HELLO_OK size 28")
    var h = decode_header(frame, 0)
    _check(h.ftype == FT_HELLO_OK, "type HELLO_OK")
    var payload = decode_payload(frame, h)
    _check(len(payload) == 12, "HELLO_OK payload 12")
    _check(_u32_at(payload, 0) == SCR_SIM_IPC_PROTO_VER, "proto")
    _check(_u32_at(payload, 4) == 2, "abi")
    _check(_u32_at(payload, 8) == 6, "schema")


def test_error_roundtrip_and_msg_cap() raises:
    var frame = encode_error_frame(9, ERR_VERSION, "abi mismatch: client 1, server 2")
    var h = decode_header(frame, 0)
    _check(h.ftype == FT_ERROR, "type ERROR")
    var payload = decode_payload(frame, h)
    var parsed = parse_error_payload(payload^)
    _check(parsed[0] == ERR_VERSION, "error code round-trip")
    _check(
        parsed[1] == "abi mismatch: client 1, server 2", "error message round-trip"
    )
    # msg longer than 1024 B: frame stays bounded, code preserved, msg truncated
    # loudly at the cap (encode logs the full message on the server side too).
    var long_msg = String()
    for _ in range(MAX_ERROR_MSG_BYTES + 500):
        long_msg = long_msg + "x"
    var big = encode_error_frame(10, 7, long_msg)
    var bh = decode_header(big, 0)
    var bp = decode_payload(big, bh)
    var bparsed = parse_error_payload(bp^)
    _check(bparsed[0] == 7, "code survives msg truncation")
    _check(
        len(bparsed[1].bytes()) == MAX_ERROR_MSG_BYTES, "msg capped at 1024 B"
    )
    _check(len(big) <= MAX_CTRL_FRAME_BYTES, "ERROR frame <= ctrl buffer")


def test_u32_frames_roundtrip() raises:
    var ack = encode_u32_frame(FT_ACK, 3, 0xDEADBEEF)
    var h = decode_header(ack, 0)
    _check(h.ftype == FT_ACK, "ACK type")
    _check(h.seq == 3, "ACK seq")
    var p = decode_payload(ack, h)
    _check(parse_u32_payload(p^, 4, "ACK") == 0xDEADBEEF, "ACK value round-trip")
    var tick = encode_u32_frame(FT_CMD_TICK, 1, 600)
    var th = decode_header(tick, 0)
    var tp = decode_payload(tick, th)
    _check(parse_u32_payload(tp^, 4, "CMD_TICK") == 600, "CMD_TICK n round-trip")


def test_edit_and_snapshot_frame_sizes() raises:
    var edit = encode_frame(FT_EDIT, 5, _pattern(EDIT_PAYLOAD_BYTES))
    var eh = decode_header(edit, 0)
    _check(eh.length == UInt32(EDIT_PAYLOAD_BYTES), "EDIT payload 4")
    var snap_bytes = List[UInt8]()
    for i in range(1024):
        snap_bytes.append(UInt8(i & 0xFF))
    var snap = encode_frame(FT_SNAPSHOT, 6, snap_bytes^)
    var sh = decode_header(snap, 0)
    _check(sh.ftype == FT_SNAPSHOT, "SNAPSHOT type")
    _check(sh.length == 1024, "SNAPSHOT length")
    var sp = decode_payload(snap, sh)
    for i in range(1024):
        _check(sp[i] == UInt8(i & 0xFF), "SNAPSHOT byte " + String(i))


# --- malformed fails loudly -------------------------------------------------

def test_malformed_fails_loudly() raises:
    # bad magic
    var good = encode_frame(FT_BYE, 1, List[UInt8]())
    var bad_magic = List[UInt8]()
    for i in range(len(good)):
        bad_magic.append(good[i])
    bad_magic[0] = 0x00
    _check(_expect_raise_malformed_header(bad_magic), "bad magic raises")

    # unknown type
    var bad_type = List[UInt8]()
    for i in range(len(good)):
        bad_type.append(good[i])
    bad_type[4] = 99
    _check(_expect_raise_malformed_header(bad_type), "unknown frame type raises")

    # absurd length (claims > MAX_PAYLOAD)
    var absurd = List[UInt8]()
    for _ in range(FRAME_HEADER_BYTES):
        absurd.append(0)
    for i in range(4):
        absurd[i] = UInt8((FRAME_MAGIC >> UInt32(8 * i)) & 0xFF)
    for i in range(4):
        absurd[4 + i] = UInt8((FT_SNAPSHOT >> UInt32(8 * i)) & 0xFF)
    absurd[12] = 0xFF
    absurd[13] = 0xFF
    absurd[14] = 0xFF
    absurd[15] = 0xFF
    _check(_expect_raise_malformed_header(absurd), "absurd length raises")

    # truncated header (< 16 bytes)
    var trunc = List[UInt8]()
    for i in range(FRAME_HEADER_BYTES - 1):
        trunc.append(good[i])
    _check(_expect_raise_malformed_header(trunc), "truncated header raises")

    # truncated payload: header claims 6 payload bytes, buffer holds only 3
    var short_payload = encode_frame(FT_INPUT, 1, _pattern(6))
    var sph = decode_header(short_payload, 0)
    var cut = List[UInt8]()
    for i in range(FRAME_HEADER_BYTES + 6 - 3):
        cut.append(short_payload[i])
    var trunc_raised = False
    var trunc_msg = String()
    try:
        _ = decode_payload(cut, sph)
    except e:
        trunc_raised = True
        trunc_msg = String(e)
    _check(trunc_raised, "truncated payload raises")
    _check(trunc_msg.find("truncated") >= 0, "truncation named in the error")

    # u32 read out of range
    var u32_raised = False
    try:
        _ = get_u32_le(good, len(good) - 2, len(good))
    except _:
        u32_raised = True
    _check(u32_raised, "u32 read past end raises")

    # HELLO payload of the wrong size
    var h15_raised = False
    try:
        _ = parse_hello(_pattern(15))
    except _:
        h15_raised = True
    _check(h15_raised, "HELLO payload size 15 raises")
    var h20_raised = False
    try:
        _ = parse_hello(_pattern(20))
    except _:
        h20_raised = True
    _check(h20_raised, "HELLO payload size 20 raises")

    # ERROR payload whose msg_len contradicts the actual length
    var err_frame = encode_error_frame(1, 2, "boom")
    var erh = decode_header(err_frame, 0)
    var erp = decode_payload(err_frame, erh)
    erp[4] = 0xFF  # lie about msg_len
    var lie_raised = False
    try:
        _ = parse_error_payload(erp^)
    except _:
        lie_raised = True
    _check(lie_raised, "contradictory ERROR msg_len raises")


def test_encode_rejects_bad_inputs() raises:
    var bad_type_raised = False
    try:
        _ = encode_frame(99, 1, List[UInt8]())
    except _:
        bad_type_raised = True
    _check(bad_type_raised, "unknown frame type raises on encode")
    var bad_len_raised = False
    try:
        _ = encode_header(FT_SNAPSHOT, 1, 0xFFFFFFFF)
    except _:
        bad_len_raised = True
    _check(bad_len_raised, "absurd length raises on encode")


def test_put_u32_le_is_little_endian() raises:
    var b = List[UInt8]()
    put_u32_le(b, 0x04030201)
    _check(len(b) == 4, "4 bytes")
    _check(b[0] == 0x01, "LE byte 0")
    _check(b[1] == 0x02, "LE byte 1")
    _check(b[2] == 0x03, "LE byte 2")
    _check(b[3] == 0x04, "LE byte 3")


# --- HELLO verdict matrix (server.session.evaluate_hello) -------------------

def test_hello_verdict_exact_match() raises:
    var d = evaluate_hello(SCR_SIM_IPC_PROTO_VER, 2, 6, 0, SCR_SIM_IPC_PROTO_VER, 2, 6)
    _check(d.ok, "exact match accepted")
    _check(d.message == "", "no message on success")
    _check(not d.manual, "manual not requested")
    _check(not d.edit_cap, "edit cap not requested")


def test_hello_verdict_flags_propagate() raises:
    var d = evaluate_hello(
        SCR_SIM_IPC_PROTO_VER, 2, 6, FLAG_MANUAL_PACE, SCR_SIM_IPC_PROTO_VER, 2, 6
    )
    _check(d.ok, "manual flag accepted")
    _check(d.manual, "manual propagated")
    _check(not d.edit_cap, "edit cap off")

    var e = evaluate_hello(
        SCR_SIM_IPC_PROTO_VER, 2, 6, FLAG_EDIT_CAP, SCR_SIM_IPC_PROTO_VER, 2, 6
    )
    _check(e.ok, "edit flag accepted")
    _check(not e.manual, "manual off")
    _check(e.edit_cap, "edit cap propagated")

    var f = evaluate_hello(
        SCR_SIM_IPC_PROTO_VER, 2, 6, FLAG_MANUAL_PACE | FLAG_EDIT_CAP,
        SCR_SIM_IPC_PROTO_VER, 2, 6,
    )
    _check(f.ok and f.manual and f.edit_cap, "both flags accepted")


def test_hello_verdict_version_mismatch_refused() raises:
    var p = evaluate_hello(SCR_SIM_IPC_PROTO_VER + 1, 2, 6, 0, SCR_SIM_IPC_PROTO_VER, 2, 6)
    _check(not p.ok, "proto mismatch refused")
    _check(p.code == ERR_VERSION, "proto mismatch => ERR_VERSION")
    _check(not p.manual and not p.edit_cap, "refusal carries no flags")

    var a = evaluate_hello(SCR_SIM_IPC_PROTO_VER, 99, 6, 0, SCR_SIM_IPC_PROTO_VER, 2, 6)
    _check(not a.ok, "abi mismatch refused")
    _check(a.code == ERR_VERSION, "abi mismatch => ERR_VERSION")

    var s = evaluate_hello(SCR_SIM_IPC_PROTO_VER, 2, 7, 0, SCR_SIM_IPC_PROTO_VER, 2, 6)
    _check(not s.ok, "schema mismatch refused")
    _check(s.code == ERR_VERSION, "schema mismatch => ERR_VERSION")
    _check(
        s.message.find("schema mismatch") >= 0, "schema refusal names the field"
    )


def test_hello_verdict_unknown_flags_refused() raises:
    var u = evaluate_hello(
        SCR_SIM_IPC_PROTO_VER, 2, 6, 0x4, SCR_SIM_IPC_PROTO_VER, 2, 6
    )
    _check(not u.ok, "unknown flag bit refused")
    _check(u.code == ERR_CAPABILITY, "unknown flag => ERR_CAPABILITY")
    _check(u.message.find("0x00000004") >= 0, "refusal names the offending bits")

    # unknown bits together with a known one: still refused, still no flags
    var v = evaluate_hello(
        SCR_SIM_IPC_PROTO_VER, 2, 6, FLAG_MANUAL_PACE | 0x80,
        SCR_SIM_IPC_PROTO_VER, 2, 6,
    )
    _check(not v.ok, "known+unknown flags refused")
    _check(v.code == ERR_CAPABILITY, "=> ERR_CAPABILITY")
    _check(not v.manual and not v.edit_cap, "no flags honoured on refusal")

    _check(KNOWN_FLAGS == (FLAG_MANUAL_PACE | FLAG_EDIT_CAP), "known-flag mask")


def main() raises:
    TestSuite.discover_tests[
        (
            test_header_and_payload_roundtrip,
            test_magic_and_seq_fields_on_the_wire,
            test_hello_roundtrip,
            test_hello_ok_roundtrip,
            test_error_roundtrip_and_msg_cap,
            test_u32_frames_roundtrip,
            test_edit_and_snapshot_frame_sizes,
            test_malformed_fails_loudly,
            test_encode_rejects_bad_inputs,
            test_put_u32_le_is_little_endian,
            test_hello_verdict_exact_match,
            test_hello_verdict_flags_propagate,
            test_hello_verdict_version_mismatch_refused,
            test_hello_verdict_unknown_flags_refused,
        )
    ]().run()
