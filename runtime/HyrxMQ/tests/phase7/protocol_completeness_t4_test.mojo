# Phase 7 / 0017 T4 — extension/reliability classes + auth + heartbeat.
#
# Feeds encoded AMQP frames through AMQPService.handle_frame (feed-bytes /
# get-bytes, no sockets) and checks the encoded responses. Every behavior
# below carries its NEGATIVE PROOF where the spec demands a refusal:
#
#   1.  auth: WRONG password → the normative SERVER-initiated
#       connection.close (10,50) reply-code 403 ACCESS_REFUSED with the
#       reference close text + failing method (10,11), and NO tune reply
#       (nothing is served after the refusal); no connection state created.
#   2.  auth: good admin/password → connection.tune (10,30), heartbeat=60.
#   3.  confirm.select → select-ok; EVERY completed publish is basic.ack
#       (60,80) with the 1-based per-channel counter, multiple=0, tags 1,2;
#       WITHOUT the select the same publish produces NO reply (negative).
#   4.  tx.select → select-ok; publishes STAGE (router storage stays empty —
#       negative asserted); tx.commit pushes them through; tx.rollback
#       DROPS the staging (negative: nothing delivered).
#   5.  tx + confirm: acks with continuing tags at commit, commit-ok LAST.
#   6.  heartbeat frame (type 8) → immediate heartbeat echo.

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    AMQPService,
    write_short_string,
    write_u16,
    write_u32,
)
from hyrx.amqp.constants import (
    MethodID,
)
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec

from hyrx.testing import check


def build_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) raises -> AMQPFrame:
    """Encode a method frame to wire bytes, then decode back to an AMQPFrame."""
    var wire = AMQPFrameCodec.encode_method_frame(
        chan, class_id, method_id, args^
    )
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "build_frame: could not decode"
    return AMQPFrame(
        fr.value().frame_type, fr.value().channel, fr.value().payload_copy()
    )


def reserved() -> List[UInt8]:
    """The deprecated reserved-1 'ticket' short: two zero octets (u16 0)."""
    var a = List[UInt8]()
    a.append(0)
    a.append(0)
    return a^


def method_id_at(ref wire: List[UInt8], off: Int) -> MethodID:
    """Class/method ids of the METHOD frame that starts at byte `off`."""
    if off + 11 > len(wire) or wire[off] != 1:
        return MethodID(0, 0)
    return MethodID(
        (UInt16(wire[off + 7]) << 8) | UInt16(wire[off + 8]),
        (UInt16(wire[off + 9]) << 8) | UInt16(wire[off + 10]),
    )


def declare_queue_ok(mut svc: AMQPService, conn_id: UInt64, chan: UInt16, var q: String) raises:
    """Feed one queue.declare (passive=0, empty arguments table)."""
    var dargs = reserved()
    write_short_string(dargs, q^)
    dargs.append(0)  # bits: passive/durable/exclusive/auto-delete/no-wait
    dargs.append(0)  # arguments table: u32 length 0 — FOUR octets
    dargs.append(0)
    dargs.append(0)
    dargs.append(0)
    _ = svc.handle_frame(
        conn_id, build_frame(chan, UInt16(50), UInt16(10), dargs^)^
    )


def publish_wire(
    mut svc: AMQPService,
    conn_id: UInt64,
    chan: UInt16,
    var ex: String,
    var rk: String,
    body_len: Int,
) raises -> Optional[List[UInt8]]:
    """Feed a REAL publish (METHOD + HEADER + BODY frames, zero-filled body)
    and return the reply bytes for the completing BODY frame (None if none)."""
    var pargs = reserved()
    write_short_string(pargs, ex^)
    write_short_string(pargs, rk^)
    pargs.append(0)  # bits: mandatory / immediate
    _ = svc.handle_frame(conn_id, build_frame(chan, UInt16(60), UInt16(40), pargs^)^)
    var hdr = AMQPFrameCodec.encode_header_frame(
        chan, UInt16(60), UInt64(body_len), UInt16(0), List[UInt8]()
    )
    var hcodec = AMQPFrameCodec()
    hcodec.feed_bytes(hdr^)
    var hf = hcodec.try_parse_frame()
    if not hf.__bool__():
        raise "publish_wire: header did not decode"
    _ = svc.handle_frame(conn_id, hf.value())
    var bbody = List[UInt8]()
    for i in range(body_len):
        bbody.append(0)
    var bcodec = AMQPFrameCodec()
    bcodec.feed_bytes(AMQPFrameCodec.encode_body_frame(chan, bbody^)^)
    var bf = bcodec.try_parse_frame()
    if not bf.__bool__():
        raise "publish_wire: body did not decode"
    return svc.handle_frame(conn_id, bf.value())


def start_ok_response(
    mut svc: AMQPService, conn_id: UInt64, var user: String, var pw: String
) raises -> Optional[List[UInt8]]:
    """Feed connection.start-ok (PLAIN + SASL response for user/pw)."""
    var resp = List[UInt8]()
    resp.append(0)  # authzid NUL
    for b in user.bytes():
        resp.append(b)
    resp.append(0)
    for b in pw.bytes():
        resp.append(b)
    var sargs = List[UInt8]()
    write_u32(sargs, 0)  # client-properties: empty table
    write_short_string(sargs, "PLAIN")
    write_u32(sargs, UInt32(len(resp)))
    for i in range(len(resp)):
        sargs.append(resp[i])
    write_short_string(sargs, "en_US")
    return svc.handle_frame(
        conn_id, build_frame(UInt16(0), UInt16(10), UInt16(11), sargs^)^
    )


def test_auth_refuses_unknown_password() raises:
    """NEGATIVE PROOF: a wrong password gets the normative SERVER-initiated
    connection.close 403 ACCESS_REFUSED with the reference close text +
    failing method (10,11), and NOTHING is served after it."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    var resp = start_ok_response(svc, UInt64(900), "admin", "WRONG-pass")
    check(resp.__bool__(), "refused login must emit a reply")
    var wire = resp.value().copy()
    check(
        method_id_at(wire, 0) == MethodID(10, 50),
        "refused login: SERVER-initiated connection.close (10,50), not tune",
    )
    # reply-code (short) = 403 = 0x0193 big-endian at args offset [11:13].
    check(wire[11] == 0x01 and wire[12] == 0x93, "reply-code is 403 ACCESS_REFUSED")
    # reply-text: shortstr = 1-byte length at [13], then the bytes.
    check(wire[13] == 108, "normative close text length")
    var prefix_ok = (
        wire[14] == 65  # 'A'
        and wire[15] == 67  # C
        and wire[16] == 67  # C
        and wire[17] == 69  # E
        and wire[18] == 83  # S
        and wire[19] == 83  # S
        and wire[20] == 95  # _
        and wire[21] == 82  # R
        and wire[22] == 69  # E
        and wire[23] == 70  # F
        and wire[24] == 85  # U
        and wire[25] == 83  # S
        and wire[26] == 69  # E
        and wire[27] == 68  # D
    )
    check(prefix_ok, "close text spells ACCESS_REFUSED")
    # The failing method is connection.start_ok (10,11): the two trailing
    # shorts before frame-end (frame total = 7 + 4 + 2 + 1 + 108 + 4 + 1).
    check(len(wire) == 127, "exact frame length (close + text + fail method)")
    check(
        wire[122] == 0 and wire[123] == 10 and wire[124] == 0 and wire[125] == 11,
        "failing method is connection.start_ok (10,11)",
    )
    check(wire[126] == 0x0CE, "ends with frame-end")
    # Negative: NO connection state was created for the refused connection
    # (the refusal happens BEFORE serving anything, tune included).
    check(not svc.connection_is_open(UInt64(900)), "refused conn never opened")


def test_auth_accepts_default_user() raises:
    """admin/password (the config default users table) reaches tune."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    var resp = start_ok_response(svc, UInt64(901), "admin", "password")
    check(resp.__bool__(), "accepted login must answer")
    var wire = resp.value().copy()
    check(
        method_id_at(wire, 0) == MethodID(10, 30),
        "accepted login: connection.tune (10,30)",
    )
    check(wire[17] == 0x00 and wire[18] == 60, "tune heartbeat is 60 (0017 T4)")
    check(svc.advertised_heartbeat() == 60, "advertised = config")


def test_confirm_acks_every_publish() raises:
    """confirm.select → select-ok; EVERY completed publish is basic.ack with
    the 1-based per-channel counter, multiple=0; WITHOUT the select the same
    publish produces NO reply (negative proof, same test)."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    declare_queue_ok(svc, UInt64(7), UInt16(1), "t4.confirm.q")
    # confirm.select (85,10): nowait bit clear.
    var csargs = List[UInt8]()
    csargs.append(0)
    var resp = svc.handle_frame(
        UInt64(7), build_frame(UInt16(1), UInt16(85), UInt16(10), csargs^)^
    )
    check(resp.__bool__(), "confirm.select must answer")
    check(
        method_id_at(resp.value().copy(), 0) == MethodID(85, 11),
        "confirm.select-ok is (85,11)",
    )
    check(svc.confirms_enabled(UInt64(7), UInt16(1)), "confirm mode armed")
    # Publish #1 → ack tag 1, multiple=0. Ack frame (60,80) layout:
    # type1 chan2 size4 | class/method4 | tag u64 | octet | end1 (len 21).
    var r1 = publish_wire(svc, UInt64(7), UInt16(1), "", "t4.confirm.q", 4)
    check(r1.__bool__(), "confirm-mode publish must ack")
    var w1 = r1.value().copy()
    check(
        method_id_at(w1, 0) == MethodID(60, 80),
        "the confirm ack is basic.ack (60,80)",
    )
    check(w1[11] == 0 and w1[18] == 1, "confirm ack delivery-tag = 1 (1-based)")
    check(w1[19] == 0, "confirm ack multiple = 0")
    check(len(w1) == 21, "ack frame: u64 tag + single bit octet")
    # Publish #2 → ack tag 2 (the counter MUST NOT restart).
    var r2 = publish_wire(svc, UInt64(7), UInt16(1), "", "t4.confirm.q", 4)
    check(r2.__bool__(), "second publish also acked")
    var w2 = r2.value().copy()
    check(w2[11] == 0 and w2[18] == 2, "second confirm ack delivery-tag = 2")
    # NEGATIVE PROOF: a channel with NO confirm.select acks nothing.
    declare_queue_ok(svc, UInt64(7), UInt16(2), "t4.confirmq2")
    var r3 = publish_wire(svc, UInt64(7), UInt16(2), "", "t4.confirmq2", 8)
    check(
        not r3.__bool__(),
        "NEGATIVE: non-confirm channel publish has NO reply",
    )


def test_tx_commit_and_rollback() raises:
    """tx.select arms staging; commit REPLAYS through the router; rollback
    DROPS the staging (negative: the queue must stay empty)."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    declare_queue_ok(svc, UInt64(8), UInt16(1), "t4.tx.q")
    # tx.select (90,10): NO arguments.
    _ = svc.handle_frame(
        UInt64(8),
        build_frame(UInt16(1), UInt16(90), UInt16(10), List[UInt8]())^,
    )
    check(svc.tx_mode_enabled(UInt64(8), UInt16(1)), "tx mode armed")
    var r1 = publish_wire(svc, UInt64(8), UInt16(1), "", "t4.tx.q", 3)
    check(not r1.__bool__(), "staged publish: no wire reply")
    check(svc.tx_staged_count(UInt64(8), UInt16(1)) == 1, "one publish STAGED")
    check(
        svc._broker.queue_depth("t4.tx.q".copy()) == 0,
        "NEGATIVE: router storage EMPTY before commit",
    )
    # tx.commit (90,20) → commit-ok (90,21), staged pushed through.
    var r2 = svc.handle_frame(
        UInt64(8),
        build_frame(UInt16(1), UInt16(90), UInt16(20), List[UInt8]())^,
    )
    check(r2.__bool__(), "tx.commit must answer")
    check(
        method_id_at(r2.value().copy(), 0) == MethodID(90, 21),
        "tx.commit-ok is (90,21)",
    )
    check(
        svc._broker.queue_depth("t4.tx.q".copy()) == 1,
        "the staged message is IN router storage after commit",
    )
    # Rollback: stage one more, roll it back, assert it NEVER appeared.
    _ = publish_wire(svc, UInt64(8), UInt16(1), "", "t4.tx.q", 3)
    var r3 = svc.handle_frame(
        UInt64(8),
        build_frame(UInt16(1), UInt16(90), UInt16(30), List[UInt8]())^,
    )
    check(r3.__bool__(), "tx.rollback must answer")
    check(
        method_id_at(r3.value().copy(), 0) == MethodID(90, 31),
        "tx.rollback-ok is (90,31)",
    )
    check(
        svc.tx_staged_count(UInt64(8), UInt16(1)) == 0,
        "the staging is EMPTY after rollback",
    )
    check(
        svc._broker.queue_depth("t4.tx.q".copy()) == 1,
        "NEGATIVE: rollback did NOT deliver the dropped staging",
    )


def test_tx_plus_confirm_acks_at_commit() raises:
    """tx AND confirm on one channel: acks with CONTINUING tags at commit,
    commit-ok LAST (ordering proof via fixed frame offsets)."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    declare_queue_ok(svc, UInt64(9), UInt16(1), "t4.txc.q")
    _ = svc.handle_frame(
        UInt64(9),
        build_frame(UInt16(1), UInt16(90), UInt16(10), List[UInt8]())^,
    )
    var csargs = List[UInt8]()
    csargs.append(0)
    _ = svc.handle_frame(
        UInt64(9), build_frame(UInt16(1), UInt16(85), UInt16(10), csargs^)^
    )
    _ = publish_wire(svc, UInt64(9), UInt16(1), "", "t4.txc.q", 2)
    _ = publish_wire(svc, UInt64(9), UInt16(1), "", "t4.txc.q", 2)
    check(
        svc.tx_staged_count(UInt64(9), UInt16(1)) == 2,
        "two publishes staged (no immediate acks)",
    )
    var r = svc.handle_frame(
        UInt64(9),
        build_frame(UInt16(1), UInt16(90), UInt16(20), List[UInt8]())^,
    )
    check(r.__bool__(), "commit must answer")
    var w = r.value().copy()
    # The commit batch = ack(tag1) 21 + ack(tag2) 21 + commit-ok 12 = 54.
    check(len(w) == 54, "2 confirm acks + commit-ok, fixed lengths, in order")
    check(
        method_id_at(w, 0) == MethodID(60, 80),
        "FIRST frame is the confirm basic.ack for staged publish 1",
    )
    check(w[11] == 0 and w[18] == 1, "first commit ack delivery-tag = 1")
    check(
        method_id_at(w, 21) == MethodID(60, 80),
        "SECOND frame is the confirm basic.ack for staged publish 2",
    )
    check(w[21 + 18] == 2, "second commit ack delivery-tag = 2 (continuing)")
    check(
        method_id_at(w, 42) == MethodID(90, 21),
        "LAST frame is tx.commit-ok AFTER the acks",
    )


def test_heartbeat_frame_echoed() raises:
    """A received heartbeat frame (type 8) is IMMEDIATELY answered with our
    own heartbeat frame (zero payload, end 0xCE)."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    var hcodec = AMQPFrameCodec()
    hcodec.feed_bytes(AMQPFrameCodec.encode_heartbeat(UInt16(0))^)
    var hf = hcodec.try_parse_frame()
    var resp = svc.handle_frame(UInt64(1), hf.value())
    check(resp.__bool__(), "heartbeat must be answered")
    var w = resp.value().copy()
    check(len(w) == 8, "heartbeat frame is 8 octets")
    check(w[0] == 8, "reply frame type is HEARTBEAT (8)")
    check(
        w[3] == 0 and w[4] == 0 and w[5] == 0 and w[6] == 0,
        "heartbeat payload size is 0",
    )
    check(w[7] == 0x0CE, "ends with frame-end")


def main() raises:
    test_auth_refuses_unknown_password()
    test_auth_accepts_default_user()
    test_confirm_acks_every_publish()
    test_tx_commit_and_rollback()
    test_tx_plus_confirm_acks_at_commit()
    test_heartbeat_frame_echoed()
    print("PHASE7_PROTOCOL_COMPLETENESS_T4_TEST=PASS")
