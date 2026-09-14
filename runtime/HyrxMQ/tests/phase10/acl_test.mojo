# Phase 10 — ACL (UserRecord permission triple) tests.
#
# Unit-tests the 0025 M2 access-control surface WITHOUT a live broker:
#   - UserRecord 2-arg / 6-arg constructor forms (there is no 4-arg form;
#     the two provided overloads are `(user, passwd)` and
#     `(user, passwd, vhost, configure, write, read)`);
#   - denial fields (can_configure/can_write/can_read = False) survive
#     construction;
#   - __copyinit__ / copy() preserves every ACL field;
#   - HyrxMQConfig.copy() preserves the users table's ACL flags;
#   - the in-process SASL handshake path maps a UserRecord's ACL triple onto
#     the connection's _PermBits (no socket is opened).

from std.collections import List

from hyrxmq.config import HyrxMQConfig, UserRecord
from hyrxmq.amqp_service import AMQPService, _PermBits, write_short_string, write_u32
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


def write_longstr_bytes(mut out: List[UInt8], var data: List[UInt8]):
    write_u32(out, UInt32(len(data)))
    for i in range(len(data)):
        out.append(data[i])


def start_ok_frame(
    conn_id: UInt64, var user: String, var passwd: String, mut svc: AMQPService
) raises:
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


def test_default_ctor_grants_all() raises:
    """2-arg form: default vhost '/' + all ACL bits granted."""
    var u = UserRecord("admin", "password")
    check(u.username == "admin", "username preserved")
    check(u.password == "password", "password preserved")
    check(u.vhost == "/", "default vhost is '/'")
    check(u.can_configure, "default can_configure True")
    check(u.can_write, "default can_write True")
    check(u.can_read, "default can_read True")


def test_deny_configure() raises:
    """6-arg form: can_configure=False is stored verbatim."""
    var u = UserRecord("ro", "pw", "/v", False, True, True)
    check(not u.can_configure, "can_configure=False preserved")
    check(u.can_write, "can_write=True preserved")
    check(u.can_read, "can_read=True preserved")
    check(u.vhost == "/v", "explicit vhost preserved")


def test_deny_write_and_read() raises:
    """6-arg form: can_write/can_read=False are stored verbatim."""
    var u = UserRecord("sink", "pw", "/v", True, False, False)
    check(u.can_configure, "can_configure=True preserved")
    check(not u.can_write, "can_write=False preserved")
    check(not u.can_read, "can_read=False preserved")

    var none = UserRecord("nobody", "pw", "/v", False, False, False)
    check(
        not none.can_configure and not none.can_write and not none.can_read,
        "all-deny triple preserved",
    )


def test_copy_preserves_acl() raises:
    """copy() / __copyinit__ carries every ACL field."""
    var a = UserRecord("u", "p", "/vb", False, True, False)
    var b = a.copy()
    check(b.username == "u", "copy preserves username")
    check(b.password == "p", "copy preserves password")
    check(b.vhost == "/vb", "copy preserves vhost")
    check(not b.can_configure, "copy preserves can_configure=False")
    check(b.can_write, "copy preserves can_write=True")
    check(not b.can_read, "copy preserves can_read=False")

    # Independent copies: mutating the copy must not touch the original.
    b.can_read = True
    check(not a.can_read, "original ACL unaffected by copy mutation")


def test_permbits_mirrors_acl() raises:
    """The connection permission triple mirrors the user's ACL flags."""
    var u = UserRecord("u", "p", "/v", False, True, False)
    var pb = _PermBits(u.can_configure, u.can_write, u.can_read)
    check(not pb.configure, "_PermBits.configure mirrors can_configure")
    check(pb.write, "_PermBits.write mirrors can_write")
    check(not pb.read, "_PermBits.read mirrors can_read")


def test_config_copy_preserves_acl() raises:
    """HyrxMQConfig.copy() keeps the users table's ACL flags."""
    var cfg = HyrxMQConfig()
    cfg.users = List[UserRecord]()
    cfg.users.append(UserRecord("limited", "pw", "/vb", False, False, True))
    var c = cfg.copy()
    check(len(c.users) == 1, "copied config keeps one user")
    check(not c.users[0].can_configure, "copied config keeps can_configure=False")
    check(not c.users[0].can_write, "copied config keeps can_write=False")
    check(c.users[0].can_read, "copied config keeps can_read=True")
    check(c.users[0].vhost == "/vb", "copied config keeps vhost")


def test_conn_permissions_populated_on_auth() raises:
    """SASL PLAIN success records the user's ACL triple for the connection."""
    var cfg = HyrxMQConfig()
    cfg.users = List[UserRecord]()
    cfg.users.append(UserRecord("limited", "pw", "/vb", False, True, False))
    var svc = AMQPService(cfg^)
    svc.start()

    start_ok_frame(UInt64(7), "limited", "pw", svc)
    check(UInt64(7) in svc._conn_permissions, "auth success stores permissions")
    check(
        not svc._conn_permissions[UInt64(7)].configure,
        "connection configure denied (can_configure=False)",
    )
    check(
        svc._conn_permissions[UInt64(7)].write,
        "connection write granted (can_write=True)",
    )
    check(
        not svc._conn_permissions[UInt64(7)].read,
        "connection read denied (can_read=False)",
    )
    check(svc._conn_vhost[UInt64(7)] == "/vb", "connection vhost recorded")


def main() raises:
    test_default_ctor_grants_all()
    test_deny_configure()
    test_deny_write_and_read()
    test_copy_preserves_acl()
    test_permbits_mirrors_acl()
    test_config_copy_preserves_acl()
    test_conn_permissions_populated_on_auth()
    print("PHASE10_ACL_TEST=PASS")