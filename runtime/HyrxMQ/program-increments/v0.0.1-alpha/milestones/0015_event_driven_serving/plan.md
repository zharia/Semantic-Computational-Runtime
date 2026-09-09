# 0015 — event-driven multi-connection serving

**Status:** complete (shipped behind default-OFF flag; batched-flow wedge OPEN -> 0016)
**Mode:** coordinator; T1 delegated (general, discovery + implementation), verify = coordinator

## Why (0014 P1, measured)

Serialized serving: aggregate ≈ 1.0× single-conn ceiling; conn-2 wall stall ≈
full first-conn serving time. The slot machinery exists but only one slot is
pumped. Target: rotating fairness across slots via readiness demux, single
thread (no locks — Router state stays single-owner).

## Design (spec before code)

Single-threaded event loop inside `serve_forever` behind a new flag
`event_driven_serving` (default ON; False = legacy serial loop, byte path
identical — rollback tier):

1. **Discovery first** (the delegate MUST): identify the existing readiness
   primitive in vendored flare (`flare/runtime/io_uring.mojo` mentions
   epoll_wait→recvmsg→sendmsg; check its public surface, plus any Epoll type
   in runtime). Reuse flare's poller if public; otherwise a transport-local
   minimal epoll FFI (precedent: hyrx transport owns its libc glue). NO new
   third-party deps.
2. **Loop**: one `serve_forever` thread:
   - epoll fd holds: listener accept fd + one entry per registered conn fd
     (level-triggered; timeout 100 ms so `_running` stays responsive).
   - Listener readable → `accept_connection()` drain (bounded), `register()`
     per slot; refuse-at-ceiling path unchanged (register closes+refuses).
   - Conn fd readable → one `serve_one_frame(slot)` dose; keep serving that
     slot while it returns SERVE_DISPATCHED, **max K frames per slot per
     ready-cycle (K=8)** before rotating, to preserve fairness under bursts.
   - Slot teardown on SERVE_CLOSED/FAILED exactly as today (close_slot).
   - In-loop recv stays blocking BUT only invoked when epoll reported the
     fd readable (data present → recv returns ≥1 octet promptly; partial
     frames land as SERVE_PARTIAL as today). No socket O_NONBLOCK changes.
3. **Exposing fds**: add `def poll_fd(ref self) -> Int` (raw fd) to
   TCPConnection + UDSConnection (additive; registered conn fds only).
   Envelope through the AMQPConnServing slot registry: accept path keeps
   returning slots; event loop reads the fd per slot id.
4. **Send path untouched**: `send_bytes` blocking-write loop as today
   (completeness contract upheld; socket buffer full = transient block on
   the single thread — accepted, no partial-write semantics change).

## Verification plan (coordinator)

- Build; suite (44/0) — integration tests drive real serving through the new
  loop (flag ON); negative proof: corrupt the loop's slot-service dispatch
  (e.g. drop the epoll ready→serve branch) → e2e/integration must fail.
- Fairness: two prebuilt native benches concurrency pattern (100k/100k,
  0.05s stagger, wall = file-mtime deltas): aggregate must approach ~2× the
  1-conn ceiling (53k → ≥ 90k/s) with conn-2 stall ≈ ≤ its own window share.
- pika fair-pair sweep at a calm window + gate PASS (0013's noisy-window
  caveat documented; skip re-anchor if desktop load present — same rule).
- flag OFF rollback tier: suite 44/0 with the serial loop (post-change).

## Result (verified)

- Suite 44/0 both flag tiers; negative proof of the tail-order bug via
  strace (deregister-after-close produced epoll_ctl DEL EBADF -> process
  death; fixed deregister-before-close + stale-entry purge).
- Single-conn native: 50,708 (event) vs 50,852 (legacy) same window - parity.
- 2-conn fairness pair (100k/100k @64B, 0.05s stagger): 30,372 + 30,355 =
  60.7k aggregate, NO head-of-line stall (legacy: 53k aggregate + ~2 s
  conn-2 stall). Per-conn rate dips during conflation (dose interaction) -
  per-message round-trip floor bounds the closed loop.
- OPEN BUG (0016): the batched pika harness flow (256 in-flight) wedges at
  calibration on EVERY Hyrx cell with the event loop ON; reproducible only
  through harness machinery, not through single/pair native probes. The
  loop therefore ships default-OFF (legacy tier engaged) until root-caused.

## Explicitly NOT claimed

- No per-connection parallelism (single thread; no locks anywhere).
- No heartbeat/publisher-confirm semantics changes.
- Single-conn throughput parity verified; multi-conn aggregate gain 1.14x
  measured at the 64B pair (sub-2x for 1-in-flight cycles).
