# Phase 10 — graceful shutdown tests (v0.0.4).
#
# Covers the pure-Mojo in-process shutdown seam:
#   - ShutdownState: request / is_requested / elapsed_ms lifecycle;
#   - AMQPListener: running() accessor, begin_shutdown() clears the running
#     flag, flush_storage() is a no-op when no journal is attached.
#
# Real OS SIGTERM/SIGINT delivery lives in a linked C shim
# (src/hyrxmq/shutdown_shim.c) polled by the serving loops. That path is NOT
# exercised here: `mojo run` (JIT) cannot link the native object, and this
# test intentionally stays link-free. The signal-to-flag wiring is verified
# at the executable layer by the pixi `hyrxmq-listen` build plus a
# kill -TERM process check (see CHANGELOG / shutdown.mojo).

from hyrxmq.shutdown import ShutdownState
from hyrxmq.listener import AMQPListener
from hyrxmq.config import HyrxMQConfig
from hyrx.core.storage import MessageJournal

from hyrx.testing import check


def test_shutdown_state_lifecycle() raises:
    var s = ShutdownState()
    check(not s.is_requested(), "shutdown not requested at init")
    check(s.elapsed_ms(1000) == 0, "elapsed_ms is 0 before request")

    s.request(1000)
    check(s.is_requested(), "requested after request()")
    check(s.elapsed_ms(1500) == 500, "elapsed_ms tracks since request")

    # A second request must NOT overwrite the first timestamp (idempotent).
    s.request(1200)
    check(s.elapsed_ms(1500) == 500, "second request keeps first timestamp")


def test_listener_flag_and_flush() raises:
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


def test_shutdown_state_drives_begin_shutdown() raises:
    # The signal bridge's shape: an OS signal flips a flag, the bridge calls
    # begin_shutdown() once. Here the flag is the pure-Mojo ShutdownState.
    var cfg = HyrxMQConfig()
    cfg.port = 0
    var listener = AMQPListener(cfg^)
    check(listener.start(), "listener starts for the bridge scenario")

    var state = ShutdownState()
    state.request(2000)
    if state.is_requested():
        listener.begin_shutdown()
    check(not listener.running(), "requested state stops the accept loop")
    listener.stop()


def test_flush_storage_with_journal() raises:
    var cfg = HyrxMQConfig()
    var listener = AMQPListener(cfg^)
    listener.attach_journal(MessageJournal.memory())
    listener.flush_storage()  # memory tier: sync is a no-op, never raises


def main() raises:
    test_shutdown_state_lifecycle()
    test_listener_flag_and_flush()
    test_shutdown_state_drives_begin_shutdown()
    test_flush_storage_with_journal()
    print("PHASE10_GRACEFUL_SHUTDOWN_TEST=PASS")
