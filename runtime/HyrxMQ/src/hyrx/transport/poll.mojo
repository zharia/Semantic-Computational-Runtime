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
# - add() is an UNCONDITIONAL replace: a recycled fd number still on the
#   registry (stale entry from any deregistration path that missed it —
#   e.g. serve_one_frame closing the socket internally) is purged before
#   the fresh registration, so registrations stay unique per fd number
#   and never crash the broker with "fd N is already registered".
# - Poller-owned vs reactor-internal: the poller tracks every fd it has
#   registered (_tracked) and only ever deregisters tracked fds; the
#   reactor's internal wakeup/eventfd is never added through this API
#   and so can never be unregistered through it.
# - remove() tolerates ONE deregistration failure: EBADF from the
#   registered-but-closed race (the serve path may close the socket
#   before the loop deregisters it); every other error propagates.

from std.collections import Dict, List
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

    var _tracked: Dict[Int, UInt64]
    """Poller-owned registrations: fd integer -> token, for every fd added
    through add() and not yet removed. Deregistration (remove() and add()'s
    replace purge) touches ONLY tracked fds, so the reactor's internal
    wakeup fd — never added through this API — can never be unregistered
    through it. Keyed by fd (the serving loop passes token == fd)."""

    def __init__(out self) raises:
        """Create the poller (wakeup fd pre-registered internally)."""
        self._reactor = Reactor()
        self._tracked = Dict[Int, UInt64]()

    def add(mut self, fd: Int, token: UInt64) raises:
        """Register ``fd`` for READ readiness under ``token``, level-triggered.
        (i.e. EPOLLIN-level; the fd keeps firing while data remains).

        UNCONDITIONAL replace semantics: if ``fd`` is still on the registry
        from a previous registration whose deregistration missed every
        teardown path (the fd number was recycled — the kernel dropped the
        closed socket's interest, the reactor's bookkeeping did not), it is
        purged first, then the fresh registration is installed. Registrations
        therefore stay unique per fd number; add() can never crash the broker
        with "fd N is already registered". The purge only ever touches fds
        the poller itself registered (_tracked) — a foreign registration,
        above all the reactor's internal wakeup fd, is never deregistered.

        Raises on an OS error (a non-benign purge failure propagates
        unchanged; the fd then cannot be registered)."""
        if fd in self._tracked:
            _ = self._try_unregister(fd, tolerate_already_gone=True)
        self._reactor.register(c_int(fd), token, INTEREST_READ)
        self._tracked[fd] = token

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
        other error is re-raised unchanged (add()'s replace purge is the
        more permissive caller — see _try_unregister)."""
        # Only a tracked fd is a poller registration; the reactor's
        # internal wakeup fd is therefore not removable through this API.
        if fd not in self._tracked:
            raise Error(
                "fd " + String(fd) + " was never registered through "
                "EventPoller.add"
            )
        _ = self._try_unregister(fd, tolerate_already_gone=False)
        _ = self._tracked.pop(fd)
        return True

    def _try_unregister(
        mut self, fd: Int, tolerate_already_gone: Bool
    ) raises -> Bool:
        """Attempt the Reactor DEL for ``fd``; purge its stale registry
        entry on the ONE failure class that proves the entry is already
        kernel-dead. Returns True after a clean DEL, False after a
        tolerated stale-purge.

        Discrimination caution (same as remove's EBADF tolerance — the
        Reactor's typed-error fields are erased at the catch site, so
        match the rendered NetworkError prefix, flare/net/error.mojo
        write_to format; swallow ONLY the specific benign cases below,
        re-raise everything else unchanged):
        - ``NetworkError(errno 9)`` EBADF: registered-but-closed race;
          the DEL hit a dead fd, the reactor's pop is skipped, the
          bookkeeping entry is stale -> purge it.
        - ``NetworkError(errno 2)`` ENOENT: the closed socket already
          dropped its kernel-side interest and the fd number was
          recycled before the DEL ran (the fd-reuse crash this purge
          exists for) -> same stale bookkeeping -> purge it.
          Tolerated only for add()'s replace purge.
        - ``NetworkError: fd N is not registered`` (no errno): reactor
          bookkeeping already clean; nothing to purge. Tolerated only
          for add()'s replace purge — a remove() of an unregistered fd
          stays a loud caller bug.
        """
        var cfd = c_int(fd)
        var stale_ebadf = False
        var stale_enoent = False
        try:
            self._reactor.unregister(cfd)
        except e:
            var s = String(e)
            if s.startswith("NetworkError(errno 9)"):
                stale_ebadf = True
            elif (
                tolerate_already_gone
                and s.startswith("NetworkError(errno 2)")
            ):
                stale_enoent = True
            elif (
                tolerate_already_gone
                and s.startswith("NetworkError: fd ")
                and " is not registered" in s
            ):
                # Reactor bookkeeping already clean: nothing to purge;
                # the caller (add's replace) only needed the entry gone.
                pass
            else:
                raise e^
        if stale_ebadf or stale_enoent:
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
