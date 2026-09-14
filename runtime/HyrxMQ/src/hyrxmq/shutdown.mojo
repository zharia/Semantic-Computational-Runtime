# HyrxMQ graceful shutdown coordination.
#
# Mojo 1.0 has no portable signal module and no module-level mutable globals.
# Shutdown state is held in a ShutdownState struct owned by the listener.
#
# Kubernetes graceful shutdown flow:
#   1. K8s sends SIGTERM after terminationGracePeriodSeconds (default 30s)
#   2. preStop hook can add extra drain time (sleep)
#   3. The listener's serve_forever() checks _running each iteration
#   4. stop() sets _running = False, breaking the accept loop
#   5. process exits cleanly after draining in-flight requests
#
# Real SIGTERM/SIGINT delivery (v0.0.4): because Mojo 1.0 forbids module-level
# mutable globals, the async-signal-safe flag cannot live in Mojo source. A
# tiny C shim (src/hyrxmq/shutdown_shim.c) owns a `volatile sig_atomic_t`,
# registers the handlers with signal(2), and exposes install/query/reset
# functions. The listen binary links the shim (`mojo build -Xlinker ...`; see
# the pixi `hyrxmq-listen` task). The serving loops poll
# `os_shutdown_requested()` and call `begin_shutdown()` when it flips, so the
# process drains and exits 0 within one poll timeout (~100 ms) of the signal.
# `mojo run` JIT cannot link native objects, so unit tests exercise only the
# pure-Mojo ShutdownState / listener-flag seam and never call these functions.

from std.ffi import c_int, external_call


def install_shutdown_signal_handler() raises -> Bool:
    """Install the SIGTERM/SIGINT handler via the linked C shim.

    Returns True when both handlers were installed. Only valid in binaries
    built with the shim linked (the pixi `hyrxmq-listen` target); under
    `mojo run` the symbol is absent, so callers must be built executables."""
    return external_call["hyrxmq_install_shutdown_signals", c_int]() == 0


def install_shutdown_signal_handler_exit() raises -> Bool:
    """Install an EXIT-ON-SIGNAL SIGTERM/SIGINT handler (PID 1 containers).

    Linux ignores signals without a handler for PID 1 — a container whose
    entrypoint is the process ignores SIGTERM and is SIGKILLed after the full
    grace period (exit 137). The web binary is that entrypoint, so it installs
    this variant: the C handler calls `_exit(0)` (async-signal-safe) for an
    immediate clean exit. The listen binary keeps the polling variant so it can
    drain storage. Only valid when the shim is linked."""
    return external_call["hyrxmq_install_shutdown_signals_exit", c_int]() == 0


def os_shutdown_requested() -> Bool:
    """True once SIGTERM/SIGINT has flipped the shim's flag."""
    return external_call["hyrxmq_shutdown_requested", c_int]() != 0


def reset_os_shutdown_flag():
    """Clear the shim flag (tests / re-arm after a handled signal)."""
    _ = external_call["hyrxmq_reset_shutdown_flag", NoneType]()


struct ShutdownState:
    """Mutable shutdown flag shared between listener and web handler."""

    var _flag: Bool
    var _requested_at_ms: Int

    def __init__(out self):
        self._flag = False
        self._requested_at_ms = 0

    def request(mut self, now_ms: Int):
        """Mark shutdown as requested."""
        if not self._flag:
            self._requested_at_ms = now_ms
        self._flag = True

    def is_requested(ref self) -> Bool:
        """True when shutdown has been requested."""
        return self._flag

    def elapsed_ms(ref self, now_ms: Int) -> Int:
        """Milliseconds since shutdown was requested. 0 if not requested."""
        if not self._flag:
            return 0
        return now_ms - self._requested_at_ms
