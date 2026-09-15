# Phase 7 — HYRXMQ_USERS environment-parsing tests.

from hyrxmq.config import HyrxMQConfig

from hyrx.testing import check


def test_default_keeps_admin() raises:
    var cfg = HyrxMQConfig()
    cfg.parse_users_env("")
    check((len(cfg.users) == 1), "empty spec keeps one default user")
    check((cfg.users[0].username == "admin"), "default username admin")
    check((cfg.users[0].password == "password"), "default password password")


def test_single_user_all_perms() raises:
    var cfg = HyrxMQConfig()
    cfg.parse_users_env("alice:secret")
    check((len(cfg.users) == 1), "one user parsed")
    check((cfg.users[0].username == "alice"), "username")
    check((cfg.users[0].password == "secret"), "password")
    check((cfg.users[0].vhost == "/"), "default vhost")
    check((cfg.users[0].can_configure), "configure default true")
    check((cfg.users[0].can_write), "write default true")
    check((cfg.users[0].can_read), "read default true")


def test_vhost_and_perms() raises:
    var cfg = HyrxMQConfig()
    cfg.parse_users_env("bob:pw:/vhost2:write,read")
    check((len(cfg.users) == 1), "one user")
    check((cfg.users[0].username == "bob"), "username bob")
    check((cfg.users[0].vhost == "/vhost2"), "vhost2")
    check((not cfg.users[0].can_configure), "configure false")
    check((cfg.users[0].can_write), "write true")
    check((cfg.users[0].can_read), "read true")


def test_two_users() raises:
    var cfg = HyrxMQConfig()
    cfg.parse_users_env("alice:secret,bob:secret2")
    check((len(cfg.users) == 2), "two users")
    check((cfg.users[0].username == "alice"), "first alice")
    check((cfg.users[1].username == "bob"), "second bob")


def test_malformed_raises() raises:
    var cfg = HyrxMQConfig()
    var raised = False
    try:
        cfg.parse_users_env("badentry")
    except:
        raised = True
    check(raised, "entry without ':' must raise")

    var cfg2 = HyrxMQConfig()
    var raised2 = False
    try:
        cfg2.parse_users_env("carol:pw:/v:teleport")
    except:
        raised2 = True
    check(raised2, "unknown permission must raise")


def main() raises:
    test_default_keeps_admin()
    test_single_user_all_perms()
    test_vhost_and_perms()
    test_two_users()
    test_malformed_raises()
    print("USERS_ENV_TEST=PASS")
