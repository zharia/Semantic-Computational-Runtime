# Phase 10 — vhost routing boundary test.
#
# Proves AMQPService._vhost_scope partitions exchange/queue keys by the
# connection's vhost, and that the DEFAULT vhost "/" stays backward
# compatible (bare names, no prefix). Prefix-agnostic by design: isolation
# is observed through basic.get behavior, never by asserting the separator
# string.

from std.collections import List

from hyrxmq.config import HyrxMQConfig, UserRecord
from hyrxmq.amqp_service import AMQPService, write_short_string, write_u32
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec

from hyrx.testing import check


def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def build_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) raises -> AMQPFrame:
    var wire = AMQPFrameCodec.encode_method_frame(chan, class_id, method_id, args^)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "build_frame: could not decode"
    return AMQPFrame(
        fr.value().frame_type, fr.value().channel, fr.value().payload_copy()
    )


def reserved() -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)
    return a^


def append_empty_table(mut a: List[UInt8]):
    # arguments: empty field table (u32 length 0).
    a.append(0)
    a.append(0)
    a.append(0)
    a.append(0)


def write_longstr_bytes(mut out: List[UInt8], var data: List[UInt8]):
    write_u32(out, UInt32(len(data)))
    for i in range(len(data)):
        out.append(data[i])


def start_ok_frame(conn_id: UInt64, var user: String, var passwd: String, mut svc: AMQPService) raises:
    """Feed a connection.start-ok (10,11) SASL PLAIN frame for `user`."""
    var args = List[UInt8]()
    write_u32(args, 0)  # client-properties: empty table
    write_short_string(args, "PLAIN")  # mechanism
    var resp = List[UInt8]()
    resp.append(0)  # empty authzid
    for b in bytes_of(user):
        resp.append(b)
    resp.append(0)
    for b in bytes_of(passwd):
        resp.append(b)
    write_longstr_bytes(args, resp^)
    write_short_string(args, "en_US")  # locale
    var fr = build_frame(UInt16(0), UInt16(10), UInt16(11), args^)
    _ = svc.handle_frame(conn_id, fr^)


def declare_queue_on(mut svc: AMQPService, conn_id: UInt64, var q: String) raises:
    var qargs = reserved()
    write_short_string(qargs, q^)
    qargs.append(0)
    append_empty_table(qargs)
    _ = svc.handle_frame(conn_id, build_frame(UInt16(1), UInt16(50), UInt16(10), qargs^))


def declare_exchange_on(mut svc: AMQPService, conn_id: UInt64, var ex: String) raises:
    var eargs = reserved()
    write_short_string(eargs, ex^)
    write_short_string(eargs, "direct")
    eargs.append(0)
    append_empty_table(eargs)
    _ = svc.handle_frame(conn_id, build_frame(UInt16(1), UInt16(40), UInt16(10), eargs^))


def publish_frames(
    mut svc: AMQPService,
    conn_id: UInt64,
    chan: UInt16,
    var ex: String,
    var rk: String,
    var body: List[UInt8],
) raises:
    """Feed a REAL basic.publish over the wire: METHOD + HEADER + BODY."""
    var pargs = reserved()
    write_short_string(pargs, ex^)
    write_short_string(pargs, rk^)
    pargs.append(0)  # bits: mandatory/immediate
    _ = svc.handle_frame(conn_id, build_frame(chan, UInt16(60), UInt16(40), pargs^))

    var hdr = AMQPFrameCodec.encode_header_frame(
        chan, UInt16(60), UInt64(len(body)), UInt16(0), List[UInt8]()
    )
    var hcodec = AMQPFrameCodec()
    hcodec.feed_bytes(hdr^)
    var hf = hcodec.try_parse_frame()
    if not hf.__bool__():
        raise "publish_frames: header frame did not decode"
    _ = svc.handle_frame(conn_id, hf.value())

    var bargs = List[UInt8]()
    for i in range(len(body)):
        bargs.append(body[i])
    var bwire = AMQPFrameCodec.encode_body_frame(chan, bargs^)
    var bcodec = AMQPFrameCodec()
    bcodec.feed_bytes(bwire^)
    var bf = bcodec.try_parse_frame()
    if not bf.__bool__():
        raise "publish_frames: body frame did not decode"
    _ = svc.handle_frame(conn_id, bf.value())


def get_method_id(mut svc: AMQPService, conn_id: UInt64, var q: String) raises -> UInt16:
    """Feed basic.get (60,70); return the reply method id (71=get-ok, 72=get-empty)."""
    var a = reserved()
    write_short_string(a, q^)
    a.append(0)  # no-ack bit clear
    var resp = svc.handle_frame(conn_id, build_frame(UInt16(1), UInt16(60), UInt16(70), a^))
    if not resp.__bool__():
        raise "basic.get produced no reply"
    var w = resp.value().copy()
    if len(w) < 11:
        raise "basic.get reply too short to carry method id"
    return (UInt16(w[9]) << 8) | UInt16(w[10])


def test_default_vhost_backward_compat() raises:
    """Default vhost '/' keeps bare names (backward compatibility)."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    # Conn 1 is unauthenticated → _vhost_scope returns the bare name.
    declare_queue_on(svc, UInt64(1), "q1")
    check(svc._broker.has_queue("q1"), "default vhost '/' keeps bare queue name 'q1'")

    declare_exchange_on(svc, UInt64(1), "ex1")
    check(svc._broker.has_exchange("ex1"), "default vhost '/' keeps bare exchange name 'ex1'")

    print("VHOST_DEFAULT_COMPAT_TEST=PASS")


def test_vhost_isolation_same_named_queue() raises:
    """Same queue name on two vhosts sees isolated resources."""
    var cfg = HyrxMQConfig()
    cfg.users = List[UserRecord]()
    cfg.users.append(UserRecord("admin", "password"))  # vhost "/"
    cfg.users.append(UserRecord("test", "secret", "/testB", True, True, True))
    var svc = AMQPService(cfg^)
    svc.start()

    start_ok_frame(UInt64(1), "admin", "password", svc)
    start_ok_frame(UInt64(2), "test", "secret", svc)
    check(svc._conn_vhost[UInt64(1)] == "/", "conn 1 vhost '/'")
    check(svc._conn_vhost[UInt64(2)] == "/testB", "conn 2 vhost '/testB'")

    declare_queue_on(svc, UInt64(1), "shared-q")
    declare_queue_on(svc, UInt64(2), "shared-q")

    # Publish on conn 1 ('/') into the default exchange with rk 'shared-q'.
    var body = List[UInt8]()
    body.append(0xAA)
    body.append(0xBB)
    publish_frames(svc, UInt64(1), UInt16(1), "", "shared-q", body^)

    # vhost '/' queue has the message (get-ok = 71).
    var mid_a = get_method_id(svc, UInt64(1), "shared-q")
    check(mid_a == UInt16(71), "vhost '/' returns get-ok (has message)")

    # The same-named queue on '/testB' is EMPTY (get-empty = 72) — isolation.
    var mid_b = get_method_id(svc, UInt64(2), "shared-q")
    check(mid_b == UInt16(72), "vhost '/testB' returns get-empty (isolated)")

    print("VHOST_ISOLATION_TEST=PASS")


def main() raises:
    test_default_vhost_backward_compat()
    test_vhost_isolation_same_named_queue()
    print("PHASE10_VHOST_ISOLATION_TEST=PASS")
