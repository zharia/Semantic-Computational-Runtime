# HyrxMQ Project-Wide Confidence Matrix (audit §28)

Milestone 0003 (phase 1–7 confidence audit). Ground truth = the nine audit
reports in this directory (`baseline.md`, `architecture_audit.md`,
`amqp_conformance.md`, `concurrency_design.md`, `security_audit.md`,
`persistence_readiness.md`, `benchmarks.md`, `config_systemd.md`,
`interop_rabbitmq.md`, `negotiation_impl.md`). No code changed by this file; it
records state. AMQP negotiation + content-frame status reflects the
**orchestrator-measured pika 1.4.4 result this session** (`negotiation_impl.md`
Update, `interop_rabbitmq.md` Update), cited as ground truth.

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
The **AMQP layer** is functionally self-consistent *and*, for a narrow basic
path, **INTEROPERABILITY PROVEN**: a real independent client (pika 1.4.4)
completes connection negotiation (8-octet header echo → `connection.start`/
start-ok with SASL PLAIN **parsed but not validated** → tune/tune-ok →
open/open-ok) and drives `basic.publish`/`consume`/`get`/`ack` with multi-frame
content reassembly byte-exact against the compiled binary
(`negotiation_impl.md`, `interop_rabbitmq.md` Update). Every earlier "network /
AMQP / broker e2e PROVEN" claim in the 001_initiation reports and ADR-0005
remains downgraded to *functionally proven against our own codec and our own
test client* (§27); the pika result upgrades **only the narrow basic path** to
INTEROPERABILITY PROVEN, never a general or unqualified "compatible". The broad
AMQP surface (close/secure/heartbeats/field tables/properties, error and edge
differential, async push, auth enforcement, TLS) is **NOT PROVEN**, and the
RabbitMQ differential stays NOT PROVEN (only a narrow same-client pass was
captured). Concurrency,
persistence, systemd clean-machine lifecycle, management, auth/TLS and true
fuzzing are all NOT PROVEN (deferred with evidence, unimplemented, or
syntax-only). Performance is BENCHMARKED for the in-repo matrix and copy/fan-out
costs; syscall- and cache-level attribution is NOT PROVEN (no profiler).

## Matrix

| Area | Implementation | Tests | Evidence | Confidence | Remaining |
|---|---|---|---|---|---|
| Core | IMPLEMENTED | TESTED (runtime `check`, post-B4 repair) | `baseline.md` §B3/B4 (inert `assert`→`check`); `tests/phase1/{buffer,buffer_pool,message}_test.mojo` | HIGH | `latency_histogram`/`queue` expectations were corrected in §B4 (never executed before) |
| Ownership | IMPLEMENTED (move + copy, no aliasing) | TESTED | `tests/phase2/routing_matrix_test.mojo` asserts publish COPIES per destination, original consumed; `tests/phase1/buffer_test.mojo` move | HIGH | D1 **fixed in 0004 WP-A**: fan-out preserves `MessageID`+`headers`; envelope now readable back via `read_message_id`/`read_headers` (`routing_matrix_test.mojo`) |
| Routing | IMPLEMENTED | TESTED (runtime matrix) | `tests/phase2/{exchange,router,routing_matrix}_test.mojo`; direct/fanout/topic wildcard asserted; 0004 WP-A preserves `message_id`+`headers` per destination (pinned by `test_metadata_fidelity_*`) | HIGH | headers exchange = stub (D10 `exchange.mojo:202-206`); topic `#` zero-or-more escalation (`baseline.md` §B4.3); copy-cut done in 0004 WP-B (single bulk copy; pool recycle still P1b) |
| Queueing | IMPLEMENTED | TESTED | `tests/phase2/queue_test.mojo` FIFO two-stack, ack, reject→tail requeue; §B5 negative proof (capacity counts unacked) | HIGH | reject requeue is tail (D9); delivery-tag namespace per-process (§1.2) |
| Backpressure | IMPLEMENTED (window tracked) | TESTED (unit) | `tests/phase5/flow_control_test.mojo`, `tests/phase2/bounded_resource_test.mojo` | MEDIUM | flow-control policy sits in transport and is production-dead (F-4); queue-full = silent drop; no push-on-publish (pull-on-subscribe only, §25) |
| UDS | IMPLEMENTED (flare provider) | TESTED | `tests/phase4/uds_test.mojo`, `tests/integration/{socket_behavior,flare_smoke}.mojo` real loopback | HIGH | socket mode umask-accidental; no `chmod`/`SO_PEERCRED` (`security_audit.md` §4) |
| TCP | IMPLEMENTED (flare provider) | TESTED | `tests/phase5/tcp_test.mojo`, `tests/integration/{socket_behavior,broker_tcp_e2e}.mojo`; `socket_negative.mojo` | HIGH | `max_connections` now enforced but process-kill under load NOT PROVEN |
| Hyrx framing | IMPLEMENTED (pure data) | TESTED | `tests/phase5/framing_test.mojo` (5 frame types + encode/decode) | MEDIUM | `FRAME_TYPE_ACK/REJECT/FLOW_CONTROL` production-dead; §24-forbidden ack semantics below transport (F-4) |
| AMQP codec | IMPLEMENTED (frame envelope byte-correct) | TESTED (bounded + negative) | `amqp_conformance.md` §1.1; `tests/phase6/{frame_codec_test,frame_codec_bounds,field_table}.mojo` | MEDIUM | content-header omits `weight` (§1.3); field tables dead code (3 types only, §1.4); NOT verified against an independent implementation |
| AMQP state machine | ADVANCING: header echo + start/start-ok/tune/tune-ok/open/open-ok IMPLEMENTED; basic-class dispatch live — all driven by a real client | TESTED (byte-exact + real pika) | `negotiation_impl.md` §2–3 (start (10,10), tune (10,30), open-ok 13-byte (10,41)); pika 9/9 (`interop_rabbitmq.md` Update); `tests/phase7/connection_negotiation_test.mojo` | MEDIUM | close/secure/heartbeats/field-tables still missing; no transition gate on dispatch; frame_max/heartbeat renegotiation absent |
| Real AMQP clients | INTEROPERABILITY PROVEN (basic path): pika completes handshake + publish/consume/get/ack + multi-frame bodies | TESTED (real client, 9/9) | pika 1.4.4 **9/9 vs our broker** (incl. 9000-byte body across multiple content-body frames at frame_max=4096) AND 9/9 vs reference RabbitMQ 4.3.5; delivery body byte-exact `b'hello-hyrx'`; `negotiation_impl.md`, `interop_rabbitmq.md` Update; 0004 WP-C populates outgoing deliver/get-ok `routing-key` + `message-count` (proven by `tests/phase7/amqp_service_test.mojo`) | MEDIUM | narrow basic path only; outgoing basic.deliver/get-ok now carry the published `routing-key` + a populated post-pop `message-count` (0004 WP-C); `exchange=''` and content-header property-flags=0 remain (NOT DONE in 0004 — known limitation, §8 of spec); `delivery_tag` starts at 0 per queue by design; auth not enforced; TLS/async-push/error-edge differential NOT PROVEN |
| RabbitMQ differential | BLOCKED (broad surface) | NOT TESTED (error/edge differential) | `interop_rabbitmq.md` §2: reference `pika_lifecycle.py` 18/18 vs RabbitMQ 4.3.5; §Update: same-client basic path 9/9 vs **both** brokers — but the HyrxMQ-vs-RabbitMQ **error/edge** differential was NOT RUN | NOT PROVEN | only the narrow same-client basic pass captured; true error/edge/nack/cancel/close/confirm differential NOT RUN; envelope fidelity gap (empty exchange/rk/tag, props=0) |
| Concurrency | NOT IMPLEMENTED (single-threaded) | N/A | `concurrency_design.md` §1/§7: zero thread/atomic in `src/`; CAS unresolvable, no std Mutex/channel | NOT PROVEN | EXPLICITLY DEFERRED WITH EVIDENCE; §6 test list unmet |
| Persistence | NOT IMPLEMENTED | N/A | `persistence_readiness.md` §0/§5: no WAL/fsync/checkpoint/recovery; `durable` flag dead (D11) | NOT PROVEN | recovery-readiness = NEEDS-DESIGN-FIXES (identity, tag namespace, non-silent overflow) |
| Failure semantics | PARTIAL (containment) | TESTED (in-repo) | `tests/integration/{socket_negative,listener_hostile}.mojo` (invalid type, ~4 GiB header, undeclared-queue raise, over-max_connections → survive); `bounded_resource_test.mojo` (queue exhaustion) | MEDIUM | process-kill/SIGTERM under systemd NOT PROVEN; queue-full fate silent (D3/D4) |
| Security | PARTIAL baseline (bounds + fail-closed + hardening; NO auth/TLS) | TESTED (in-repo negative) | `frame_codec_bounds.mojo` (frame-type + size ceiling 131072), `listener_hostile.mojo` (max_connections); `hyrxmq.service` authored | MEDIUM | auth/SASL/TLS/authorization ABSENT (§5); live-listen crash behavior + systemd enforcement NOT PROVEN |
| Systemd | UNIT AUTHORED (not deployed) | syntax-only | `config_systemd.md` §1: `systemd-analyze verify` = no syntax errors; §16: lifecycle NOT PROVEN | NOT PROVEN | clean-machine install→user→start→bind→journal→stop/restart→sandbox→limits NOT PROVEN |
| Management | NONE (read-only status projection only) | N/A | `architecture_audit.md` §4: no HTTP/CLI/admin server; `status()` is a counter projection, off the hot path | NOT PROVEN | management API not built; §26 forward constraint (must not become routing authority) not yet in docs (F-15) |
| Performance | BENCHMARKED | TESTED (real runs) | `benchmarks.md`: interleaved direct, transport matrix (UDS+4.85µs/TCP+10.9µs/AMQP+19.9µs vs direct), fan-out copy (~150–200 MiB/s, 2 copies/dest) | MEDIUM | syscalls/msg + cache-miss/IPC NOT PROVEN (no `perf`/`valgrind`/`strace`, §B4); copy path is measured hotspot, not profiler-proven sole bottleneck |
| Fuzzing | PARTIAL (hand-written negative cases) | TESTED | `socket_negative.mojo`, `frame_codec_bounds.mojo`, `listener_hostile.mojo` cover `amqp_conformance.md` §13 targets | NOT PROVEN | no fuzzer harness / no coverage tool → NOT PROVEN as true fuzzing; state-machine fuzz (§13.7) outstanding |

Tally: HIGH 4 (Core, Queueing, UDS, TCP) · MEDIUM 10 (Ownership, Routing,
Backpressure, Hyrx framing, AMQP codec, AMQP state machine, Real AMQP clients,
Failure semantics, Security, Performance) · LOW 0 · NOT PROVEN 6 (RabbitMQ
differential, Concurrency, Persistence, Systemd, Management, Fuzzing).

## Release blockers before claiming interoperability

**DONE — measured this session** (`negotiation_impl.md` §1–3,
`interop_rabbitmq.md` Update): historical blockers 0–4 below (spec decimal ids;
consume 8-octet header + originate `connection.start`; SASL PLAIN
`start-ok` — *parsed, not validated*; `tune`/`tune-ok`; gated
`connection.open`→`open-ok` + `channel.open`), **plus content-frame
reassembly** (inbound HEADER/BODY consumed and reassembled; outbound
`basic.deliver`/`basic.get-ok` emit method+header+body; `basic.qos→qos-ok`,
`basic.get-empty` implemented). A real pika 1.4.4 client now reaches and drives
the basic methods: **9/9 vs our broker, 9/9 vs reference RabbitMQ 4.3.5**,
multi-frame body byte-equal. This is why "Real AMQP clients" moved to
INTEROPERABILITY PROVEN (basic path), MEDIUM.

**REMAINING blockers before a broader interoperability claim (all NOT PROVEN):**
1. **Auth enforcement** — SASL PLAIN parsed but *any* credential accepted; no
   observable 403-on-bad-auth (the RabbitMQ reference refuses `guest/guest`).
2. **TLS** — absent.
3. **Error / edge differential** — only the narrow same-client basic pass was
   captured against both brokers; the full error/edge/nack/cancel/close/confirm
   differential vs HyrxMQ was **NOT RUN**.
4. **Field tables / content properties on the wire** — content-header
   property-flags=0 observed; delivery_mode/content_type/etc. and field tables
   not serialized; message_count=0.
5. **Async push-to-idle-subscriber** — sync single-connection model; only
   publish-before-subscribe proven.
6. **Envelope fidelity gap** — outgoing `basic.deliver`/`basic.get-ok` carry
   empty `exchange`/`routing-key` and `delivery_tag=0`; see "Known limitations".

### Historical blocker list (items 0–4 now DONE; retained for provenance)

The AMQP-0-9-1 requirements HyrxMQ had to satisfy for a real client to reach the
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

Items 0–4 and the `basic.qos→qos-ok`/`basic.get-empty` subset of item 5 are
**DONE and real-client-verified**; `basic.cancel→cancel-ok`, `basic.nack`
requeue+redelivery, and `channel.close`/`connection.close → close-ok` remain
NOT PROVEN. Only the narrow basic path may be claimed INTEROPERABILITY PROVEN —
still never an unqualified "RabbitMQ compatible".

## Known limitations & follow-ups

- **Deliver envelope fidelity (partially closed in 0004 WP-C).** On OUR broker
  the passing pika run showed outgoing `basic.deliver`/`basic.get-ok` carrying
  `exchange=''`, `routing-key=''` and `delivery_tag=0` (start-at-0, single value
  observed), whereas RabbitMQ populated `exchange='hyrx.content.a.x'`,
  `rk='hyrx.key.a'` and an incrementing delivery-tag. Root cause was **D1** (router
  zeroed `message_id`/headers on fan-out; engine exposed no envelope accessor).
  **0004 WP-A + WP-C fix:** `Router.publish` now preserves `message_id`+`headers`;
  the engine surfaces `queue_routing_key`+`queue_message_count` through
  `EmbeddedEngine`→`HyrxMQBroker`→`AMQPService`, so outgoing deliver/get-ok now
  carry the **published `routing-key`** and a **populated post-pop `message-count`**
  (proven by `tests/phase7/amqp_service_test.mojo`). `exchange=''` and content-header
  property-flags=0 remain **NOT DONE** in 0004 (spec §8 known limitation) — recorded,
  not hidden. `delivery_tag` still starts at 0 per queue by design (engine tag
  counter), matching the prior observation and not a defect.
