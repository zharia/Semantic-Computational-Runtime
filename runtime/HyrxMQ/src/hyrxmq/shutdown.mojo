# HyrxMQ graceful shutdown coordination.
#
# Mojo 1.0 has no portable signal module and no module-level globals.
# Shutdown state is held in a ShutdownState struct owned by the listener.
#
# Kubernetes graceful shutdown flow:
#   1. K8s sends SIGTERM after terminationGracePeriodSeconds (default 30s)
#   2. preStop hook can add extra drain time (sleep)
#   3. The listener's serve_forever() checks _running each iteration
#   4. stop() sets _running = False, breaking the accept loop
#   5. process exits cleanly after draining in-flight requests


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
