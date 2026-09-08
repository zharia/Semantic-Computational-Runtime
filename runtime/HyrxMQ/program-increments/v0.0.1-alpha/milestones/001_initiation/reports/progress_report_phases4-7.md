# Progress Report — HyrxMQ Phases 4–7 (Transports → AMQP → Broker)

**Date:** 2026-09-08
**Milestone:** 001_initiation
**Spec version:** v0.0.1-alpha
**Prior report:** `progress_report.md` (Phases 0–3)

---

## Audit correction (milestone 0003, 2026-09-08) — supersedes this report's overclaims

Milestone 0003 re-audited phases 4–7. The Addendum and Layer Status below
marked the network / AMQP / broker paths **PROVEN** because our own integration
tests round-tripped through our **own** codec driven by our **own** client. That
evidence class is *functionally self-consistent*, not spec conformance or
interoperability. Ground truth now (see
`../0003_phase-1-7-audit/reports/{amqp_conformance,interop_rabbitmq,confidence_matrix}.md`):

- **Real AMQP client interop = NOT PROVEN / BLOCKED.** A real client (pika 1.4.4)
  connects at TCP but cannot complete the handshake: HyrxMQ does not consume the
  8-octet protocol header nor send `connection.start`/`tune`. RabbitMQ
  differential is likewise BLOCKED (reference baseline `pika_lifecycle.py`
  passes 18/18 vs RabbitMQ 4.3.5; the HyrxMQ column stops at REACH@TCP).
- **AMQP 0-9-1 method-ID bug (now known):** every connection-class id and
  `channel.open` used sequential ids (…,1..6,10,11) instead of the spec decimal
  indices (10/11/30/31/40/50/51), and the phase-6 tests asserted the wrong
  values — so the §5 "e2e" only ever matched our own dialect.
- **§5 "implemented method subset" is wrong:** `connection.{start,start-ok,
  tune,tune-ok}` and `close-ok` are NOT implemented on the wire (never sent);
  `connection.open`/`channel.open` are dispatched only at the wrong id and are
  unreachable to a real client. Negotiation and state-transition enforcement:
  NOT IMPLEMENTED.
- **Transport socket I/O (TCP/UDS, real loopback): FUNCTIONALLY PROVEN** — this
  claim stands. The AMQP-over-TCP broker e2e is FUNCTIONALLY PROVEN (in-repo,
  self-consistent), not INTEROPERABILITY PROVEN.

Replace every "PROVEN" in the body with **FUNCTIONALLY PROVEN** and read
§5/§11 accordingly. The report body is kept unedited for history; this note is
authoritative. Concurrency (single-threaded), persistence (unimplemented),
auth/TLS (absent) and clean-machine systemd (syntax-validated only) remain NOT
PROVEN. See `confidence_matrix.md` for the full state.

---

## Addendum (post flare integration, 2026-09-08)

The socket blocker reported below is **resolved** via ADR-0005: the vendored
flare library backs the Hyrx transport contract (`src/hyrx/transport/tcp.mojo`,
`uds.mojo`), `AMQPListener` (`src/hyrxmq/listener.mojo`) runs the broker accept
loop over that contract (never importing flare outside `transport/`), and
`tests/integration/{flare_smoke,amqp_over_tcp,broker_tcp_e2e}.mojo` prove TCP,
UDS, AMQP-over-TCP, and a full broker round-trip (connect → open → declare →
publish → deliver → ack) over real sockets in-process. Suite: 28/28 PASS.
Still NOT PROVEN after this unblock: TLS; real-AMQP-client conformance and the
RabbitMQ differential (Phase 8); systemd validation on a clean machine. The
sections below were written pre-flare; superseded claims are marked and the
Layer Status table (§11) reflects the addendum state.

---

## 1. Summary

Implemented the transport layer (Phase 4), Hyrx-native network transport (Phase 5), the AMQP 0-9-1 adapter (Phase 6), and the first HyrxMQ standalone broker vertical slice (Phase 7).

All layers compile and every socket-independent path is unit-tested. Original count **25/25 tests pass across Phases 0–7 with zero regressions** (now 28/28 including the three integration socket tests — see Addendum).

~~**The network data path is NOT PROVEN** because Mojo 1.0.0 (ed45d567) ships no socket/networking stdlib.~~ **Superseded by the Addendum:** the network data path (TCP + UDS + AMQP-over-TCP + broker end-to-end) is PROVEN through the flare-backed transport contract. TLS and clean-machine systemd validation remain NOT PROVEN. This is reported honestly per spec §36.

---

## 2. Implemented

### Phase 4 — Local Transports (`src/hyrx/transport/`, 427 lines)
| File | Content |
|------|---------|
| `transport.mojo` | `TransportConfig`, `TransportStats`, `TransportConnection` — transport-independent abstraction (real) |
| `uds.mojo` | `UDSListener`, `UDSConnection` — Unix domain socket (flare-backed; I/O proven by integration tests) |

Shared-memory transport deliberately **not implemented**: spec §12 / TRANSPORTS.md require benchmark evidence before adding SHM. No baseline exists yet to justify its complexity.

### Phase 5 — Hyrx Network Transport (`src/hyrx/transport/`)
| File | Content |
|------|---------|
| `framing.mojo` | Hyrx-native wire framing: `FrameHeader`/`Frame` (type+len+payload), 5 frame types (MESSAGE/ACK/REJECT/HEARTBEAT/FLOW_CONTROL). **Real, pure data.** |
| `flow_control.mojo` | `FlowWindow` — send/recv window tracking. **Real, pure state.** |
| `tcp.mojo` | `TCPListener`, `TCPConnection`, `TCPClient` — baseline external transport (flare-backed; I/O proven by integration tests) |

Note: Hyrx framing is **separate from** AMQP framing — internal representation is not AMQP frames (spec §5).

### Phase 6 — AMQP 0-9-1 Adapter (`src/hyrx/amqp/`, 823 lines)
| File | Content |
|------|---------|
| `constants.mojo` | Frame types, method class/IDs, reply codes (real) |
| `field_table.mojo` | `FieldTable`/`FieldValue` — typed key-value maps for method args (real; iteration via `List[_keys]` to dodge Mojo 1.0 Dict-copy constraints) |
| `frame_codec.mojo` | `AMQPFrame`/`MethodFrame`/`HeaderFrame` + `AMQPFrameCodec` — incremental byte-stream parser (`feed_bytes`/`try_parse_frame`) and encoders (real) |
| `connection_state.mojo` | `AMQPConnectionState`, `AMQPChannelState` — lifecycle state machines (real) |
| `adapter.mojo` | `AMQPAdapter` — translates AMQP ops to Hyrx core ops (real) |

AMQP is an **adapter over Hyrx**; core/transport/embedded contain zero `amqp` references.

### Phase 7 — HyrxMQ Vertical Slice (`src/hyrxmq/`, 848 lines)
| File | Content |
|------|---------|
| `config.mojo` | `HyrxMQConfig` + `parse_config_line`/`from_key_values`/`from_lines`/`validate` (real; disk `load_from_file` intentionally absent — no portable file API) |
| `status.mojo` | `BrokerStatus` — plain status data (real) |
| `broker.mojo` | `HyrxMQBroker` — owns a single `HyrxEngine` (sole routing authority), composes `AMQPAdapter`; topology/publish/consume/ack/status/shutdown (real) |
| `amqp_service.mojo` | `AMQPService.handle_frame(conn_id, frame)` — feeds AMQP bytes, dispatches to broker, returns encoded response bytes (real, tested without sockets); basic.consume flushes pending messages as basic.deliver frames (pull-on-subscribe slice) |
| `listener.mojo` | `AMQPListener` — broker accept loop over the Hyrx TCP transport contract (flare-backed); no message semantics, glue only (post flare integration; e2e-proven) |
| `main.mojo` | Standalone entry `run_selfcheck()` + `main()`; prints ready, exits 0, no hang. Accept loop is the SEPARATE `main_listen.mojo` entry (listen binary) |
| `packaging/systemd/hyrxmq.service` | Hardened unit: NoNewPrivileges, ProtectSystem=strict, ProtectHome, PrivateTmp, RestrictAddressFamilies, Restart=on-failure, dedicated user/group |
| `config/hyrxmq.conf.example` | `key = value` config sample |

### Cross-cutting fix
`src/hyrx/embedded/api.mojo` (+16 lines): surfaced a `read_payload` passthrough to `Router` — required by the AMQP `basic.deliver` byte round-trip. Added to the existing embedded API rather than duplicating a second routing substrate in the product layer.

---

## 3. Tested

Command: `pixi run mojo run -I src -I vendor/flare <file>` (Mojo 1.0.0). Independently re-run after implementation. (flare emits ~26–81 deprecation warnings per compile; expected, ADR-0005.)

```
Phase 4  transport_test, uds_test                        2/2 PASS
Phase 5  framing_test, tcp_test, flow_control_test       3/3 PASS
Phase 6  amqp_constants, field_table, frame_codec,
         connection_state, adapter                       5/5 PASS
Phase 7  config, broker, amqp_service, status_health,
         main_smoke                                      5/5 PASS
Phases 0–3 (regression)                                  10/10 PASS
Integration flare_smoke, amqp_over_tcp,
          broker_tcp_e2e (post flare)                     3/3 PASS
---------------------------------------------------------------
TOTAL                                                    28/28 PASS, 0 FAIL
```

Phase 6+ tests use a runtime `check(cond, msg)` helper that raises on failure (verified: exit=1 on false, exit=0 on pass).

**Evidence obtained without sockets:** frame encode/decode round-trip; `queue.declare`→`declare-ok`, `connection.open`→`open-ok`, `channel.open`→`open-ok` response generation; a `basic.publish` frame with inline body reaching the broker and being delivered with byte-matching payload; broker health state machine (starting→ok→degraded); status counters sourced from the engine; config line parsing/validation.

**Socket-path evidence (post flare):** ephemeral TCP bind + OS-assigned port read-back; real accept; incremental codec reassembly across 64-byte reads; full broker drive over a live socket — open-ok → declare-ok → consume-ok → `basic.deliver` with byte-matching payload → ack with advanced broker counters (`tests/integration/broker_tcp_e2e.mojo`); UDS echo (`flare_smoke`).

---

## 4. Benchmarked

No new benchmarks in Phases 4–7. The socket blocker that previously made transport I/O unmeasurable is gone (flare-backed transports are live); throughput/latency baselines are still **not measured** — deferred per ADR-0004 (measure before optimizing), next increment.

---

## 5. Compatibility

AMQP 0-9-1 conformance vs a real RabbitMQ client is **NOT PROVEN** — the socket blocker is gone (the broker binds and is driven e2e by our own client); what remains is a third-party/pinned reference client and a pinned reference broker (Phase 8 scope). The implemented method subset is: connection.{start,start-ok,tune,tune-ok,open,open-ok}, channel.{open,open-ok}, exchange.declare, queue.{declare,declare-ok,bind,bind-ok}, basic.{publish,consume,consume-ok,deliver,ack}. No compatibility claim made (spec §33).

---

## 6. Documentation

- This report (+ dated addendum).
- `src/hyrx/transport/tcp.mojo` + `uds.mojo` headers document the flare provider backing the transport contract (ADR-0005).
- The accept loop is implemented: `src/hyrxmq/listener.mojo`; the network-serving binary entry is `src/hyrxmq/main_listen.mojo` (kept separate from the non-hanging `main.mojo`); the systemd unit targets the listen binary.

---

## 7. Remaining

**Previously blocking — RESOLVED (see addendum):** Mojo 1.0 socket stdlib absence. Resolved by ADR-0005: flare-vendored TCP/UDS behind the Hyrx transport contract; broker accept loop + e2e proven.

**Remaining NOT PROVEN:**
- TLS (Phase 11; OpenSSL/zlib gating per ADR-0005).
- Real AMQP client conformance / RabbitMQ differential (Phase 8).
- Systemd unit validated on a clean machine (unit + listen binary exist; lifecycle unverified).

**Per-phase follow-ups (not blocking correctness):**
- Wire shared memory **only if** a benchmark justifies it (spec §12).
- Transport benchmarks now measurable but not yet run (ADR-0004); interleaved producer/consumer sustained benchmark; many-producer/many-consumer; contention (spec §11).
- Negative/fuzz testing of AMQP codec: malformed frames, oversized/truncated input, invalid state, unexpected method (spec §14 — Phase 8+).
- Multi-connection serving: the listener serializes clients (one connection to completion); concurrency is a follow-up with contention evidence.
- Disk config loading (no portable file API in Mojo 1.0; config exercised from in-memory lines).

---

## 8. Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| ~~No socket stdlib~~ → flare provider (ADR-0005) bus-factor 1; network e2e now proven | Medium | Pinned vendor; provider confined to `src/hyrx/transport/` (grep-enforced); e2e regression test |
| Mojo 1.0 `assert` is compile-time-only → phase 0–3 tests "assert" vacuously | Medium | Phase 6–7 use runtime `check()`; recommend retrofitting older tests |
| Two routing authorities (Engine + AMQPAdapter) if misused | Medium | Broker holds Engine as sole authority; Adapter's own substrate only exercised in isolated `protocol_selfcheck()` |
| Payload byte-per-byte copies in Router publish | Low | Known Phase 3 design; optimize in Phase 9 |

---

## 9. Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D7 | Transport abstraction is plain structs (no traits) | Mojo 1.0 lacks trait/protocol for this use; matches core style |
| D8 | Separate Hyrx framing from AMQP framing | spec §5 — AMQP frames are never canonical internal form |
| D9 | `read_payload` passthrough added to embedded API, not duplicated | Preserve single routing authority; avoid shadow routing in product layer |
| D10 | `FieldTable` keeps a `List[String]` of keys for iteration | Mojo 1.0 Dict iteration/copy semantics blocked pure-`__copyinit__` |
| D11 | SHM transport deferred | spec §12: complexity must earn its place via benchmark; no baseline yet |
| D12 | Network path reported NOT PROVEN, not silently faked | spec §36 honesty requirement |
| D13 | flare vendored as transport **provider** under the Hyrx contract (ADR-0005) | unblocks sockets without redefining transport semantics; containment keeps provider substitutable |
| D14 | Delivery flushes at consume (pull-on-subscribe), bodies inline in method args | documented slice representation choice; no change to publish/consume/ack semantics |

---

## 10. Self-Assessment (spec §35)

### Architecture
1. **Hyrx independent of simulation?** Yes — no simulation concepts anywhere.
2. **AMQP accidentally an internal dependency?** No — `amqp/` imports `core/`; core has zero `amqp` refs.
3. **TCP mandatory inside Hyrx Core?** No — routing needs no socket; the flare provider is confined to `src/hyrx/transport/` (contract boundary, ADR-0005).
4. **HyrxMQ responsibilities leaked into Hyrx Core?** No — broker/product code lives in `src/hyrxmq/`; `grep hyrxmq src/hyrx/` = none.
5. **Premature distributed architecture?** No — single-node, single routing authority.

### Correctness
6. **Invariants proven:** AMQP frame round-trip; method dispatch to broker; publish→route→deliver→ack byte-identical payload through the broker **and over a real TCP socket e2e**; health state transitions; config parse/validate; flow window accounting.
7. **Assumptions:** flare's blocking read/write do not alter transport semantics (contract tests pass on it); AMQP byte layout follows the 0-9-1 spec as encoded (not yet diffed against a third-party client).
8. **Untested failure paths:** malformed/truncated/oversized frames, invalid method state, mid-frame abrupt disconnect, connection storms, real client interop.

### Performance
9. **Measured bottleneck:** none new — sockets are now measurable; transport benchmarks not yet run (ADR-0004).
10. **Evidence for optimizations:** none claimed; no optimization performed.
11. **Allocations/message:** unchanged from Phase 3 (1 buffer + 1 clone/destination).
12. **Copies/message:** 1 payload copy/destination (Router.publish).
13. **Contention:** not measured (listener serializes connections; concurrency suite pending).
14. **Tail latency:** not measured for transports.
15. **Optimization improved target workload?** N/A — none applied.

### Compatibility
16. **AMQP features genuinely tested:** method/frame codec, connection/channel state, publish/deliver/ack path — at byte level and end-to-end over a real socket with our own client; NOT against a third-party AMQP client.
17. **RabbitMQ behaviors inferred vs demonstrated:** all inferred (Phase 8 will build evidence). No differential test run.
18. **Compatibility matrix updated?** Not updated — no evidence yet (correctly withheld, spec §33).

### Reliability
19. **Memory exhaustion:** BufferPool raises at max slabs; Queue returns False at capacity (unchanged). Not exercised through transport.
20. **Connection storms:** not exercised — listener exists (serialized accept loop).
21. **Process termination:** broker `shutdown()` clears state; no persistence to lose.
22. **Disk failure:** N/A — no disk path wired.

### Security
23. **Hostile inputs tested:** none — fuzzing/negative AMQP is Phase 8/14 scope. Codec has length-bounded parse but malformed-input suite pending.
24. **Privileges required by service:** none for current code; systemd unit declares dedicated non-privileged `hyrxmq` user/group.
25. **systemd restrictions validated?** No — bindable listen binary exists (`build/hyrxmq-listen`); unit not yet run on a clean machine.

### Documentation
26. **Docs describe actual behavior?** Yes — stale "stubbed/NOT PROVEN" transport claims replaced with flare-provider wording; remaining NOT-PROVEN items documented in file headers, ADR-0005 and this report.
27. **Unsupported features explicit?** Yes — SHM deferred; TLS, third-party AMQP client conformance/RabbitMQ differential, clean-machine systemd, disk config marked NOT PROVEN. Socket I/O is PROVEN.
28. **Benchmark results reproducible?** No new benchmarks; Phase 3 direct baseline remains the reference.

---

## 11. Layer Status

```
Hyrx Core      ✅ complete, tested
Hyrx Embedded  ✅ complete, tested (+read_payload)
Hyrx Local     ✅ UDS via flare transport contract — I/O PROVEN (integration tests)
Hyrx Network   ✅ TCP via flare transport contract — I/O PROVEN; framing+flow-control tested
AMQP 0-9-1     🟡 codec/state/adapter + AMQP-over-TCP e2e PROVEN; third-party client conformance NOT PROVEN; TLS NOT PROVEN
HyrxMQ         🟡 broker + listener + handshake/declare/publish/deliver/ack e2e over real TCP PROVEN; clean-machine systemd NOT PROVEN; listen binary exists (main_listen.mojo)
```

**Next:** Phase 8 — pinned RabbitMQ differential + third-party AMQP client conformance; transport benchmarks (now measurable); systemd validation on a clean machine; then TLS (Phase 11).

*(Layer table reflects the post-flare addendum state.)*
