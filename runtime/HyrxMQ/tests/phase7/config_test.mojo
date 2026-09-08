# Phase 7 — HyrxMQ configuration tests.

from std.collections import List

from hyrxmq.config import HyrxMQConfig, KeyValuePair, parse_config_line


from hyrx.testing import check

def test_defaults() raises:
    var cfg = HyrxMQConfig()
    check((cfg.port == 5672), "default port")
    check((cfg.frame_max == 131072), "default frame_max")
    check((cfg.max_connections == 1024), "default max_connections")
    check((cfg.heartbeat_secs == 60), "default heartbeat")
    check((cfg.default_queue_capacity == 1024), "default queue capacity")
    check((cfg.listen_host == "0.0.0.0"), "default listen_host")
    check((cfg.vhost == "/"), "default vhost")
    check((cfg.node_name == "hyrxmq@localhost"), "default node_name")


def test_parse_line() raises:
    var kv = parse_config_line("port = 5672")
    check((kv.key == "port"), "parse key")
    check((kv.value == "5672"), "parse value")

    var kv2 = parse_config_line("node_name=hyrx1")
    check((kv2.key == "node_name"), "parse key no-space")
    check((kv2.value == "hyrx1"), "parse value no-space")


def test_parse_invalid_raises() raises:
    var raised = False
    try:
        _ = parse_config_line("just a key without equals")
    except:
        raised = True
    check(raised, "line without '=' must raise")

    var raised2 = False
    try:
        _ = parse_config_line("   = value")
    except:
        raised2 = True
    check(raised2, "empty key must raise")


def test_from_key_values() raises:
    var entries = List[KeyValuePair]()
    entries.append(KeyValuePair("port", "9999"))
    entries.append(KeyValuePair("node_name", "alpha"))
    entries.append(KeyValuePair("frame_max", "4096"))
    var cfg = HyrxMQConfig.from_key_values(entries^)
    check((cfg.port == 9999), "from_kv port")
    check((cfg.node_name == "alpha"), "from_kv node_name")
    check((cfg.frame_max == 4096), "from_kv frame_max")
    # unset keys keep defaults
    check((cfg.heartbeat_secs == 60), "from_kv keeps default")


def test_from_lines_and_comments() raises:
    var lines = List[String]()
    lines.append("# a comment")
    lines.append("port = 5673")
    lines.append("")
    lines.append("vhost = /prod")
    var cfg = HyrxMQConfig.from_lines(lines^)
    check((cfg.port == 5673), "from_lines port")
    check((cfg.vhost == "/prod"), "from_lines vhost")


def test_bad_int_raises() raises:
    var lines = List[String]()
    lines.append("port = notanumber")
    var raised = False
    try:
        var cfg = HyrxMQConfig.from_lines(lines^)
    except:
        raised = True
    check(raised, "non-integer port must raise")


def test_validate() raises:
    var entries = List[KeyValuePair]()
    entries.append(KeyValuePair("port", "99999"))
    var cfg = HyrxMQConfig.from_key_values(entries^)
    var raised = False
    try:
        cfg.validate()
    except:
        raised = True
    check(raised, "out-of-range port must fail validate")


def main() raises:
    test_defaults()
    test_parse_line()
    test_parse_invalid_raises()
    test_from_key_values()
    test_from_lines_and_comments()
    test_bad_int_raises()
    test_validate()
    print("PHASE7_CONFIG_TEST=PASS")
