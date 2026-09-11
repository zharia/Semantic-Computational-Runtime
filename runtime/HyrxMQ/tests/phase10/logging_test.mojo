# Phase 10 — structured logging + graceful-shutdown primitive tests.
#
# Covers src/hyrxmq/logging.mojo (JSON record rendering, escaping, level
# ranking/filtering) and the AMQPListener in-process shutdown seam
# (running accessor, begin_shutdown, flush_storage no-op when no journal).

from hyrxmq.logging import log_json, log_level_rank, should_log
from hyrxmq.listener import AMQPListener
from hyrxmq.config import HyrxMQConfig
from hyrx.core.storage import MessageJournal

from hyrx.testing import check


def expect_contains(haystack: String, needle: String, message: String) raises:
    check(
        haystack.find(needle) >= 0,
        message + " :: missing " + needle,
    )


def last_char(s: String) -> String:
    var n = len(s.bytes())
    return String(s[byte = n - 1 : n])


def test_log_json_shape() raises:
    var rec = log_json(
        "INFO", "broker", "listening", "\"queue\":\"q1\""
    )
    check(rec.find("{") == 0, "record starts with '{'")
    check(last_char(rec) == "}", "record ends with '}'")
    expect_contains(rec, "\"level\":\"INFO\"", "level present")
    expect_contains(rec, "\"component\":\"broker\"", "component present")
    expect_contains(rec, "\"message\":\"listening\"", "message present")
    expect_contains(rec, "\"fields\":{\"queue\":\"q1\"}", "fields spliced")
    expect_contains(rec, "\"timestamp\":", "timestamp present")
    check(rec.find("\n") < 0, "record is a single line")


def test_log_json_escaping() raises:
    var rec = log_json("WARN", "listener", "a\"b\\c", "")
    expect_contains(rec, "\"message\":\"a\\\"b\\\\c\"", "quote/backslash escaped")
    check(rec.find("\n") < 0, "escaped record stays one line")
    expect_contains(rec, "\"fields\":{}", "empty fields object")


def test_log_levels() raises:
    check(log_level_rank("DEBUG") == 0, "DEBUG rank 0")
    check(log_level_rank("INFO") == 1, "INFO rank 1")
    check(log_level_rank("WARN") == 2, "WARN rank 2")
    check(log_level_rank("ERROR") == 3, "ERROR rank 3")
    check(log_level_rank("NOPE") == -1, "unknown rank -1")

    check(should_log("WARN", "WARN"), "at threshold logs")
    check(should_log("WARN", "ERROR"), "above threshold logs")
    check(not should_log("WARN", "INFO"), "below threshold filtered")
    check(should_log("DEBUG", "DEBUG"), "DEBUG passes DEBUG")
    check(not should_log("ERROR", "WARN"), "WARN filtered at ERROR")
    check(not should_log("INFO", "NOPE"), "unknown level never logs")


def test_begin_shutdown() raises:
    var cfg = HyrxMQConfig()
    cfg.port = 0  # ephemeral bind; no fixed-port collision
    var listener = AMQPListener(cfg^)
    check(not listener.running(), "not running before start")
    check(listener.start(), "listener binds and starts")
    check(listener.running(), "running after start")
    listener.begin_shutdown()
    check(not listener.running(), "begin_shutdown clears the running flag")
    listener.flush_storage()  # no journal attached => no-op, no raise
    listener.stop()
    check(not listener.running(), "stop clears the running flag")


def test_flush_storage_with_journal() raises:
    var cfg = HyrxMQConfig()
    var listener = AMQPListener(cfg^)
    listener.attach_journal(MessageJournal.memory())
    listener.flush_storage()  # memory tier: sync is a no-op, never raises


def main() raises:
    test_log_json_shape()
    test_log_json_escaping()
    test_log_levels()
    test_begin_shutdown()
    test_flush_storage_with_journal()
    print("PHASE10_LOGGING_TEST=PASS")
