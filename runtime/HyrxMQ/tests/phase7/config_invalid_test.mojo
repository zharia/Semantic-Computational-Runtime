# Phase 7 — HyrxMQ configuration HARDENING tests (audit §17).
#
# These assert the ACTUAL result of every §17 "invalid config" case so a bad
# configuration fails SAFELY (a controlled, catchable `raise`) and CLEARLY
# (a key-named message), never as an uncaught process panic. The suite itself
# exits 0 only when every expected failure is genuinely detected, so it doubles
# as the §17 negative proof: invalid -> detected failure; valid -> success.
#
# `assert` is inert in this Mojo build (see hyrx/testing.md note), so every
# check is a raise-based `check()` from hyrx.testing.

from std.collections import List

from hyrxmq.config import HyrxMQConfig, KeyValuePair, parse_config_line

from hyrx.testing import check


def test_unknown_field_rejected() raises:
    # apply() rejects an unrecognized key (was silently ignored -> §17 gap).
    var cfg = HyrxMQConfig()
    var raised = False
    try:
        cfg.apply("bogus_field", "7")
    except:
        raised = True
    check(raised, "apply() must reject unknown field")

    # and via the parse path too.
    var lines = List[String]()
    lines.append("totally_unknown_key = 1")
    var raised2 = False
    try:
        _ = HyrxMQConfig.from_lines(lines^)
    except:
        raised2 = True
    check(raised2, "from_lines() must reject unknown field")


def test_invalid_type_no_panic() raises:
    # Non-integer for an integer key must raise a catchable, key-named error,
    # NOT abort the process. If this panicked the whole test binary would die
    # non-zero and never print PASS.
    var raised = False
    try:
        var cfg = HyrxMQConfig()
        cfg.apply("port", "abc")
    except:
        raised = True
    check(raised, "port='abc' must raise (not panic)")

    var raised2 = False
    try:
        var lines = List[String]()
        lines.append("frame_max = not_a_number")
        _ = HyrxMQConfig.from_lines(lines^)
    except:
        raised2 = True
    check(raised2, "frame_max='not_a_number' must raise (not panic)")


def test_out_of_range_values() raises:
    # Valid integer type but out-of-range value -> validate() flags it.
    var c1 = HyrxMQConfig()
    c1.port = 99999
    var r1 = False
    try:
        c1.validate()
    except:
        r1 = True
    check(r1, "port 99999 out of range must fail validate")

    var c2 = HyrxMQConfig()
    c2.frame_max = 0
    var r2 = False
    try:
        c2.validate()
    except:
        r2 = True
    check(r2, "frame_max 0 must fail validate")

    var c3 = HyrxMQConfig()
    c3.max_connections = -5
    var r3 = False
    try:
        c3.validate()
    except:
        r3 = True
    check(r3, "max_connections -5 must fail validate")

    var c4 = HyrxMQConfig()
    c4.default_queue_capacity = 0
    var r4 = False
    try:
        c4.validate()
    except:
        r4 = True
    check(r4, "default_queue_capacity 0 must fail validate")

    var c5 = HyrxMQConfig()
    c5.heartbeat_secs = -1
    var r5 = False
    try:
        c5.validate()
    except:
        r5 = True
    check(r5, "heartbeat_secs -1 must fail validate")

    # Reachable through the parse path too: 99999 parses as an int, then
    # validate() (not the type coercion) is what rejects the range.
    var lines = List[String]()
    lines.append("port = 99999")
    var parsed = HyrxMQConfig.from_lines(lines^)
    var rp = False
    try:
        parsed.validate()
    except:
        rp = True
    check(rp, "parse-then-validate must reject port 99999")


def test_missing_or_empty_value() raises:
    # Empty value for a key -> apply()/parse path raises (missing required value).
    var raised = False
    try:
        var cfg = HyrxMQConfig()
        cfg.apply("node_name", "")
    except:
        raised = True
    check(raised, "empty value for node_name must raise")

    var raised2 = False
    try:
        var lines = List[String]()
        lines.append("port =")
        _ = HyrxMQConfig.from_lines(lines^)
    except:
        raised2 = True
    check(raised2, "empty value for an int key must raise")

    var raised3 = False
    try:
        var cfg2 = HyrxMQConfig()
        cfg2.apply("port", "   ")
    except:
        raised3 = True
    check(raised3, "whitespace-only value must raise")


def test_duplicate_field_last_wins() raises:
    # Deterministic resolution (fixed the reversed-pop latent bug that made
    # the FIRST line win): later entries override earlier ones.
    var lines = List[String]()
    lines.append("port = 1")
    lines.append("port = 2")
    var cfg = HyrxMQConfig.from_lines(lines^)
    check((cfg.port == 2), "duplicate line must be last-wins")

    var entries = List[KeyValuePair]()
    entries.append(KeyValuePair("frame_max", "10"))
    entries.append(KeyValuePair("frame_max", "20"))
    var cfg2 = HyrxMQConfig.from_key_values(entries^)
    check((cfg2.frame_max == 20), "duplicate key/value must be last-wins")


def test_invalid_endpoint_host() raises:
    # Invalid/empty host rejected by apply() and (defense-in-depth) validate().
    var raised = False
    try:
        var cfg = HyrxMQConfig()
        cfg.apply("listen_host", "")
    except:
        raised = True
    check(raised, "empty listen_host must be rejected by apply")

    var c2 = HyrxMQConfig()
    c2.listen_host = "   "
    var raised2 = False
    try:
        c2.validate()
    except:
        raised2 = True
    check(raised2, "blank listen_host must fail validate")

    var c3 = HyrxMQConfig()
    c3.vhost = ""
    var raised3 = False
    try:
        c3.validate()
    except:
        raised3 = True
    check(raised3, "blank vhost must fail validate")

    var c4 = HyrxMQConfig()
    c4.node_name = ""
    var raised4 = False
    try:
        c4.validate()
    except:
        raised4 = True
    check(raised4, "blank node_name must fail validate")


def test_valid_config_succeeds() raises:
    # NEGATIVE PROOF counter-case: a fully valid config parses and validates
    # with no failure.
    var lines = List[String]()
    lines.append("# comment")
    lines.append("listen_host = 127.0.0.1")
    lines.append("port = 5673")
    lines.append("max_connections = 64")
    lines.append("frame_max = 4096")
    lines.append("heartbeat_secs = 30")
    lines.append("default_queue_capacity = 128")
    lines.append("vhost = /prod")
    lines.append("node_name = hyrx@node1")
    var cfg = HyrxMQConfig.from_lines(lines^)
    var ok = True
    try:
        cfg.validate()
    except:
        ok = False
    check(ok, "valid config must validate cleanly")
    check((cfg.port == 5673), "valid config port applied")
    check((cfg.listen_host == "127.0.0.1"), "valid config host applied")

    # parse_config_line still rejects structurally broken lines.
    var raised = False
    try:
        _ = parse_config_line("no equals sign here")
    except:
        raised = True
    check(raised, "line without '=' must raise")


def main() raises:
    test_unknown_field_rejected()
    test_invalid_type_no_panic()
    test_out_of_range_values()
    test_missing_or_empty_value()
    test_duplicate_field_last_wins()
    test_invalid_endpoint_host()
    test_valid_config_succeeds()
    print("PHASE7_CONFIG_INVALID_TEST=PASS")
