# Readiness demux for the event-driven serving path (0015).
#
# Wraps the vendored flare Reactor (flare.runtime: a level-triggered
# epoll / kqueue event loop) behind a hyrx-owned API so the AMQP
# listener (src/hyrxmq/listener.mojo) never imports flare directly
# (ADR-0005: flare is confined to the transport layer — this file IS
# part of that layer).
#
# Semantics preserved by the flare Reactor and re-exposed here:
# - Level-triggered readiness (a socket with pending data keeps firing).
# - Tokens are caller-chosen UInt64 values round-tripped unchanged;
#   the event-driven loop uses the raw fd integer as its token.
# - poll() with a positive timeout returns within that many ms, so
#   the serving loop stays responsive to `_running`.
# - Internal wakeup fd events are surfaced to the caller and MUST be
#   skipped (PollEvent.wakeup).
# - remove() tolerates ONE deregistration failure: EBADF from the
#   registered-but-closed race (the serve path may close the socket
#   before the loop deregisters it); every other error propagates.

from std.collections import List
from std.ffi import c_int

from flare.runtime import INTEREST_READ, Reactor
from flare.runtime.event import Event


# One readiness event, transport-layer shape. Flare's Event type does not
# cross this boundary: the listener imports only THIS module.
@fieldwise_init
struct PollEvent(Copyable, ImplicitlyCopyable, Movable):
    """One readiness event from the poller (level-triggered)."""

    var token: UInt64
    """The registration token (the raw fd integer in the serving loop)."""

    var readable: Bool
    """The fd has data to read (EPOLLIN / EVFILT_READ)."""

    var hup: Bool
    """The peer closed its end (EPOLLRDHUP/HUP / EV_EOF)."""

    var failed: Bool
    """An error condition on the fd (EPOLLERR / EV_ERROR)."""

    var wakeup: Bool
    """Internal reactor wakeup event; the caller MUST skip it."""


struct EventPoller(Movable):
    """A level-triggered readiness registry over listener + conn fds.

    Ownership: the poller owns the OS poller fd (the flare Reactor closes
    it on deinit). Registered socket fds remain owned by the transports;
    the loop passes borrowed fd integers only.
    """

    var _reactor: Reactor

    def __init__(out self) raises:
        """Create the poller (wakeup fd pre-registered internally)."""
        self._reactor = Reactor()

    def add(mut self, fd: Int, token: UInt64) raises:
        """Register ``fd`` for READ readiness under ``token``, level-triggered.
        (i.e. EPOLLIN-level; the fd keeps firing while data remains).

        Raises on a duplicate registration or an OS error."""
        self._reactor.register(c_int(fd), token, INTEREST_READ)

    def remove(mut self, fd: Int) raises -> Bool:
        """Deregister ``fd`` at slot teardown. Raises if not registered.

        Returns True after the Reactor's clean ``epoll_ctl DEL``. The ONE
        tolerated failure is the registered-but-closed race: the serve
        path may have already closed the socket, so the DEL hits a dead
        fd and the Reactor raises ``NetworkError(errno 9)`` (EBADF) while
        its registry still holds the fd (the internal pop is skipped on
        that raise). close() already dropped the kernel-side interest, so
        only that bookkeeping entry is stale: purge it (the same pop the
        Reactor performs after a successful DEL) and return False. Every
        other error is re-raised unchanged."""
        var cfd = c_int(fd)
        var stale_ebadf = False
        try:
            self._reactor.unregister(cfd)
        except e:
            # Reactor.unregister is bare-raises, so the typed error's
            # fields are erased at this catch site; discriminate on the
            # rendered NetworkError errno prefix (flare/net/error.mojo
            # write_to format) — the same String(e).startswith approach
            # flare/errors.mojo map_handler_error uses.
            if not String(e).startswith("NetworkError(errno 9)"):
                raise e^
            stale_ebadf = True
        if stale_ebadf:
            # Reaching the DEL proves unregister found the fd on the
            # registry and raised BEFORE its pop; the entry is present
            # and stale (the fd number must not poison a future add()).
            if cfd in self._reactor._registered:
                _ = self._reactor._registered.pop(cfd)
            return False
        return True

    def is_registered(self, fd: Int) -> Bool:
        """True if ``fd`` is currently on the registry."""
        return self._reactor.is_registered(c_int(fd))

    def wait(
        mut self, mut out: List[PollEvent], timeout_ms: Int
    ) raises -> Int:
        """Wait up to ``timeout_ms`` for ready fds; append events to ``out``.

        ``out`` is cleared first; returns the number appended. Internal
        wakeup events are still delivered — the caller filters via
        ``PollEvent.wakeup`` (kept explicit on purpose)."""
        out.clear()
        var events = List[Event]()
        var n = self._reactor.poll(timeout_ms, events)
        for i in range(n):
            var ev = events[i]
            out.append(
                PollEvent(
                    token=ev.token,
                    readable=ev.is_readable(),
                    hup=ev.is_hup(),
                    failed=ev.is_error(),
                    wakeup=ev.is_wakeup(),
                )
            )
        return n
