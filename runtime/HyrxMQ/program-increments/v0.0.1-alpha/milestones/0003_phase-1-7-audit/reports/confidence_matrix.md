# HyrxMQ Project-Wide Confidence Matrix (audit §28)

Milestone 0003 (phase 1–7 confidence audit). Ground truth = the nine audit
reports in this directory (`baseline.md`, `architecture_audit.md`,
`amqp_conformance.md`, `concurrency_design.md`, `security_audit.md`,
`persistence_readiness.md`, `benchmarks.md`, `config_systemd.md`,
`interop_rabbitmq.md`). No code changed; this file only records state.

Confidence ∈ {HIGH, MEDIUM, LOW, NOT PROVEN}. Per §28, HIGH is **not** granted
for tests existing: it requires genuine runtime assertions, and — for
performance — real runs, and — for interoperability — a real client. §27
vocabulary is used: IMPLEMENTED / TESTED / FUNCTIONALLY PROVEN / BENCHMARKED /
INTEROPERABILITY PROVEN / NOT PROVEN.

## Executive confidence summary

Hyrx's **in-process core** (memory/ownership, routing, queueing) and its
**real loopback transports** (TCP/UDS via the flare-backed transport contract)
are FUNCTIONALLY PROVEN by runtime-checked tests (`baseline.md` §B4;
`tests/phase1/*`, `tests/phase2/*`, `tests/integration/socket_behavior.mojo`).
The **AMQP layer is functionally self-consistent only**: the frame envelope is
byte-correct and the codec is bounded and negative-tested, but a REAL AMQP
client (pika) connects at TCP and **cannot complete the handshake** — HyrxMQ
never consumes the 8-octet protocol header nor originates `connection.start`
(`interop_rabbitmq.md` STEP A/B). Therefore AMQP connection negotiation,
real-client interoperability and the RabbitMQ differential are **NOT
PROVEN / BLOCKED**, and every earlier "network / AMQP / broker e2e PROVEN"
claim in the 001_initiation reports and ADR-0005 is downgraded to *functionally
proven against our own codec and our own test client* (§27). Concurrency,
persistence, systemd clean-machine lifecycle, management, auth/TLS and true
fuzzing are all NOT PROVEN (deferred with evidence, unimplemented, or
syntax-only). Performance is BENCHMARKED for the in-repo matrix and copy/fan-out
costs; syscall- and cache-level attribution is NOT PROVEN (no profiler).

## Matrix

| Area | Implementation | Tests | Evidence | Confidence | Remaining |
|---|---|---|---|---|---|
| Core | IMPLEMENTED | TESTED (runtime `check`, post-B4 repair) | `baseline.md` §B3/B4 (inert `assert`→`check`); `tests/phase1/{buffer,buffer_pool,message}_test.mojo` | HIGH | `latency_histogram`/`queue` expectations were corrected in §B4 (never executed before) |
| Ownership | IMPLEMENTED (move + copy, no aliasing) | TESTED | `tests/phase2/routing_matrix_test.mojo` asserts publish COPIES per destination, original consumed; `tests/phase1/buffer_test.mojo` move | MEDIUM | D1: fan-out zeroes `MessageID` + drops headers (`persistence_readiness.md` §1.1/§2.1); envelope not readable back |
| Routing | IMPLEMENTED | TESTED (runtime matrix) | `tests/phase2/{exchange,router,routing_matrix}_test.mojo`; direct/fanout/topic wildcard asserted | MEDIUM | headers exchange = stub (D10 `exchange.mojo:202-206`); topic `#` zero-or-more escalation (`baseline.md` §B4.3); copy-not-share (D2) |
| Queueing | IMPLEMENTED | TESTED | `tests/phase2/queue_test.mojo` FIFO two-stack, ack, reject→tail requeue; §B5 negative proof (capacity counts unacked) | HIGH | reject requeue is tail (D9); delivery-tag namespace per-process (§1.2) |
| Backpressure | IMPLEMENTED (window tracked) | TESTED (unit) | `tests/phase5/flow_control_test.mojo`, `tests/phase2/bounded_resource_test.mojo` | MEDIUM | flow-control policy sits in transport and is production-dead (F-4); queue-full = silent drop; no push-on-publish (pull-on-subscribe only, §25) |
| UDS | IMPLEMENTED (flare provider) | TESTED | `tests/phase4/uds_test.mojo`, `tests/integration/{socket_behavior,flare_smoke}.mojo` real loopback | HIGH | socket mode umask-accidental; no `chmod`/`SO_PEERCRED` (`security_audit.md` §4) |
| TCP | IMPLEMENTED (flare provider) | TESTED | `tests/phase5/tcp_test.mojo`, `tests/integration/{socket_behavior,broker_tcp_e2e}.mojo`; `socket_negative.mojo` | HIGH | `max_connections` now enforced but process-kill under load NOT PROVEN |
| Hyrx framing | IMPLEMENTED (pure data) | TESTED | `tests/phase5/framing_test.mojo` (5 frame types + encode/decode) | MEDIUM | `FRAME_TYPE_ACK/REJECT/FLOW_CONTROL` production-dead; §24-forbidden ack semantics below transport (F-4) |
| AMQP codec | IMPLEMENTED (frame envelope byte-correct) | TESTED (bounded + negative) | `amqp_conformance.md` §1.1; `tests/phase6/{frame_codec_test,frame_codec_bounds,field_table}.mojo` | MEDIUM | content-header omits `weight` (§1.3); field tables dead code (3 types only, §1.4); NOT verified against an independent implementation |
| AMQP state machine | PARTIAL (type exists, transitions inert) | NOT PROVEN (negotiation unexercised) | `amqp_conformance.md` §2; `negotiate()` never called (`connection_state.mojo:71-76`); `connection_state_test.mojo` unit-only | LOW | server never sends start/tune; no transition gate on dispatch; close-ok never emitted |
| Real AMQP clients | NOT IMPLEMENTED (negotiation absent) | NOT TESTED | `interop_rabbitmq.md` §3: pika 1.4.4 → `IncompatibleProtocolError: StreamLostError` at header; harness built | NOT PROVEN | 5-blocker handshake gap (see "Release blockers") |
| RabbitMQ differential | BLOCKED | NOT TESTED (HyrxMQ side) | `interop_rabbitmq.md` §2/§4: reference `pika_lifecycle.py` 18/18 vs RabbitMQ 4.3.5; HyrxMQ column stops at REACH@TCP | NOT PROVEN | blocked-at-negotiation; frame-level handlers proven only by self-client `broker_tcp_e2e` |
| Concurrency | NOT IMPLEMENTED (single-threaded) | N/A | `concurrency_design.md` §1/§7: zero thread/atomic in `src/`; CAS unresolvable, no std Mutex/channel | NOT PROVEN | EXPLICITLY DEFERRED WITH EVIDENCE; §6 test list unmet |
| Persistence | NOT IMPLEMENTED | N/A | `persistence_readiness.md` §0/§5: no WAL/fsync/checkpoint/recovery; `durable` flag dead (D11) | NOT PROVEN | recovery-readiness = NEEDS-DESIGN-FIXES (identity, tag namespace, non-silent overflow) |
| Failure semantics | PARTIAL (containment) | TESTED (in-repo) | `tests/integration/{socket_negative,listener_hostile}.mojo` (invalid type, ~4 GiB header, undeclared-queue raise, over-max_connections → survive); `bounded_resource_test.mojo` (queue exhaustion) | MEDIUM | process-kill/SIGTERM under systemd NOT PROVEN; queue-full fate silent (D3/D4) |
| Security | PARTIAL baseline (bounds + fail-closed + hardening; NO auth/TLS) | TESTED (in-repo negative) | `frame_codec_bounds.mojo` (frame-type + size ceiling 131072), `listener_hostile.mojo` (max_connections); `hyrxmq.service` authored | MEDIUM | auth/SASL/TLS/authorization ABSENT (§5); live-listen crash behavior + systemd enforcement NOT PROVEN |
| Systemd | UNIT AUTHORED (not deployed) | syntax-only | `config_systemd.md` §1: `systemd-analyze verify` = no syntax errors; §16: lifecycle NOT PROVEN | NOT PROVEN | clean-machine install→user→start→bind→journal→stop/restart→sandbox→limits NOT PROVEN |
| Management | NONE (read-only status projection only) | N/A | `architecture_audit.md` §4: no HTTP/CLI/admin server; `status()` is a counter projection, off the hot path | NOT PROVEN | management API not built; §26 forward constraint (must not become routing authority) not yet in docs (F-15) |
| Performance | BENCHMARKED | TESTED (real runs) | `benchmarks.md`: interleaved direct, transport matrix (UDS+4.85µs/TCP+10.9µs/AMQP+19.9µs vs direct), fan-out copy (~150–200 MiB/s, 2 copies/dest) | MEDIUM | syscalls/msg + cache-miss/IPC NOT PROVEN (no `perf`/`valgrind`/`strace`, §B4); copy path is measured hotspot, not profiler-proven sole bottleneck |
| Fuzzing | PARTIAL (hand-written negative cases) | TESTED | `socket_negative.mojo`, `frame_codec_bounds.mojo`, `listener_hostile.mojo` cover `amqp_conformance.md` §13 targets | NOT PROVEN | no fuzzer harness / no coverage tool → NOT PROVEN as true fuzzing; state-machine fuzz (§13.7) outstanding |

Tally: HIGH 4 (Core, Queueing, UDS, TCP) · MEDIUM 8 (Ownership, Routing,
Backpressure, Hyrx framing, AMQP codec, Failure semantics, Security,
Performance) · LOW 1 (AMQP state machine) · NOT PROVEN 7 (Real AMQP clients,
RabbitMQ differential, Concurrency, Persistence, Systemd, Management, Fuzzing).

## Release blockers before claiming interoperability

The AMQP-0-9-1 requirements HyrxMQ must satisfy for a real client to reach the
methods it already dispatches (from `interop_rabbitmq.md` §6, in handshake
order; plus the §10 method-ID correction):

0. Use the **spec decimal method indices** for the connection class and
   `channel.open` (start=10/10, tune=10/30, tune-ok=10/31, open=10/40,
   open-ok=10/41, close=10/50, close-ok=10/51, channel.open=20/10,
   channel.open-ok=20/11), not the sequential ids; fix the test oracle that
   asserts the wrong values (`amqp_conformance.md` §1.2, rule 11).
1. **Consume the 8-octet protocol header** (`AMQP\x00\x00\x09\x01`) before any
   frame parse and reply by originating `connection.start`.
2. **SASL PLAIN** `connection.start` → `start-ok` (advertise mechanisms,
   validate credentials) so bad-auth rejection (403) is observable.
3. **`connection.tune` → `tune-ok`** round trip negotiating real
   `frame_max`/`heartbeat`/`channel_max`.
4. **`connection.open` → `open-ok`** gated after tune, and **`channel.open` →
   `channel.open-ok`**, so a real channel exists.
5. **Required synchronous `*_ok` replies** for the currently-silent methods:
   `basic.qos → qos-ok`, `basic.cancel → cancel-ok`, `basic.nack` (requeue +
   redelivery), and `channel.close`/`connection.close → close-ok`. (Publisher
   confirms = optional RabbitMQ extension, deferrable.)

After items 0–4 a real pika client completes connect→auth→tune→open→channel.open
and the §12 HyrxMQ column can be filled for the frame-level methods; after item
5 the full §11 lifecycle runs end-to-end. Only then may "AMQP 0-9-1
INTEROPERABILITY PROVEN" be claimed — still never an unqualified "RabbitMQ
compatible".
