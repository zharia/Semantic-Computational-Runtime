# HyrxMQ Confidence Audit — FINAL REPORT (§35) + SELF-ASSESSMENT (§34)

**Milestone:** 0003 — Phase 1–7 confidence audit
**Date:** 2026-09-08
**Toolchain:** Mojo 1.0.0 (ed45d567) · Linux 7.1.8-1-cachyos x86_64 · nproc 12
**Author:** final synthesis. Evidence = the nine reports in this directory
(`baseline.md`, `architecture_audit.md`, `amqp_conformance.md`,
`concurrency_design.md`, `security_audit.md`, `persistence_readiness.md`,
`benchmarks.md`, `config_systemd.md`, `interop_rabbitmq.md`) + orchestrator-run
ground truth. No code was re-investigated or edited for this file.

**Reading rule (§37):** Evidence outranks implementation; an explicit NOT PROVEN
outranks a false PASS. Where a claim is not proven it is written NOT PROVEN.
"Strongly indicated" is used only where a measurement supports but a profiler
does not prove it.

---

## Verified ground truth (orchestrator-run — authoritative over earlier in-report numbers)

| Fact | Value | Citation |
|---|---|---|
| Full suite | **37 pass / 0 fail** (`bash scripts/test_all.sh`) — added `tests/phase7/content_reassembly_test.mojo` + interop harness | orchestrator run |
| Assertion quality | all checks are real runtime assertions; no vacuous asserts | `baseline.md` §B1–B5 |
| Topic matcher | fixed — `#` = zero-or-more (word-recursive) | `src/hyrx/core/exchange.mojo:72-76` |
| AMQP method ids | corrected to spec decimal (e.g. `CONNECTION_OPEN = MethodID(10,40)`) | verified vs fetched `amqp0-9-1.xml`; `amqp_conformance.md` §1.2 |
| Routing authority | exactly ONE `Router()` | `src/hyrx/embedded/api.mojo:90` |
| flare confinement | only `src/hyrx/transport/{tcp,uds}.mojo` | `architecture_audit.md` §2.5 / ADR-0005 |
| Codec | bounded — `max_frame_size` enforced, oversized rejected (independently proven) | `security_audit.md` §2/§7 fix-1; `tests/phase6/frame_codec_bounds.mojo` |
| Listener | fail-closed — Malformed → connection closed, broker survives | `security_audit.md` §7 fix-2; `tests/integration/listener_hostile.mojo` |
| BufferView | renamed **BufferSnapshot** (it copies — proven by experiment) | `persistence_readiness.md` §1.3 |
| Real client (basic path) | pika 1.4.4 vs our broker (5699) = **9/9 PASS** (handshake + basic publish/consume/get/ack + 9000-byte multi-frame body byte-equal); vs LIVE RabbitMQ 4.3.5 = 9/9 (harness) + 18/18 (full lifecycle reference) | `negotiation_impl.md` Update, `interop_rabbitmq.md` Update |
| Perf (direct) | ~280k msg/s interleaved (256 B single run 276k–340k band) | `benchmarks.md` B1/B2 |
| Perf (transport) | UDS ~2.4×, TCP ~4.3×, AMQP/TCP ~7× vs direct | `benchmarks.md` B2 |
| Perf (fan-out) | copy slope +2.38 µs/dest (256 B) | `benchmarks.md` B3 |
| Mojo std concurrency | NO threads/mutex/CAS-resolved in std | `concurrency_design.md` §3 |
| Mojo profilers | NO perf/valgrind/strace → syscall/cache NOT PROVEN | `benchmarks.md` B4 |
| Mojo file API | NO os/file → config-from-disk NOT AVAILABLE | `config_systemd.md` Part A |

Divergence note: individual reports quote the suite count at the moment they ran
(27→34→35→36→37). **37 pass / 0 fail** is the final, authoritative figure (35→36
added the connection-negotiation test; 36→37 added
`tests/phase7/content_reassembly_test.mojo` + the interop harness); earlier counts
are historical, not contradictions.

---

## Executive Summary

Reviewed: HyrxMQ phases 0–7 (core semantics, ownership, routing, queueing,
UDS/TCP transports, framing, AMQP adapter/service, config/systemd packaging)
against a spec-mandated confidence gate.

**Net confidence change — three movements:**

1. **Test validity went from untrustworthy to trustworthy.** Baseline bare
   `assert` was proven inert (a false assert did not fail a test); 13 print-only
   / vacuous test files were migrated to real runtime `check()`, exposing two
   latent test-expectation bugs and one genuine source bug (topic `#`). The
   suite is now 37/0 with proven-failing negatives.
2. **Several prior "PROVEN" claims were downgraded, honestly — then the narrow
   basic path was re-proven with a real client.** "AMQP / network / broker e2e
   PROVEN" was first corrected to *functionally proven against our own codec and
   our own test client only* (a real pika client could not complete the
   handshake). After connection negotiation + content-frame reassembly landed
   this session, pika 1.4.4 completes the handshake and drives
   publish/consume/get/ack with multi-frame bodies (9/9 vs our broker AND 9/9 vs
   the RabbitMQ reference), so that **narrow basic path is now INTEROPERABILITY
   PROVEN** — not the broad surface. Concurrency, persistence, systemd
   clean-machine lifecycle, management, auth/TLS and true fuzzing remain NOT
   PROVEN.
3. **Real security defects were found and fixed** at the byte/framing layer:
   unbounded codec accumulation (a genuine AMQP header alone parsed as a
   ~1.3 GiB frame) and an uncaught `raise` that let one ~9-byte frame kill the
   broker. Both are now bounded / fail-closed and negative-tested.

The architecture is clean (single routing authority, no upward deps, flare
confined, management off the hot path). The AMQP layer was self-consistent but
incomplete; **connection negotiation + content-frame reassembly have since
landed this session**, so a real pika client reaches the basic methods
(INTEROPERABILITY PROVEN, basic path). It does not yet speak the *broad* AMQP
surface to real clients: auth/TLS, error/edge/confirmation differential, field
tables/properties, async push and the deliver envelope fidelity gap remain — see
Decisions and Recommended Next Phase.

---

## Baseline

Pre-audit state (`baseline.md`, `architecture_audit.md` §1, ADR-0005 header,
`docs/*` claims):

- Build/test harness existed: `pixi run build` → `mojo build -I src -I vendor/flare
  src/hyrx/main.mojo`; tests via `bash scripts/test_all.sh`.
- Baseline suite reported green, **but was not trustworthy**: bare `assert` in a
  Mojo 1.0 runtime-false test did **not** fail (probe printed after the assert,
  exit 0). 13 of 28 reviewed test files were VACUOUS (print-only or inert
  `assert`); only 15 used genuine `raise`/`assert_equal` checks.
- Prior reports and ADR-0005 claimed **network / AMQP / broker e2e PROVEN**. That
  framing was unbacked by any real client and by method-IDs that did not match
  the AMQP 0-9-1 schema.
- AMQP connection-class and channel-open method IDs were encoded with a
  sequential scheme (1,2,3,4,5,6,10,11) instead of the spec's decimal indices
  (10,11,30,31,40,50,51) — baked into the test oracle, so CI never caught it
  (`amqp_conformance.md` §1.2).
- Frame codec had **no bound** on `frame size` and the listener had **no
  exception handler**; `max_connections`/`frame_max`/`channel_max`/`heartbeat`
  were declared-but-unenforced (`security_audit.md` §3).
- Architecture: two routing substrates reachable from the broker (engine
  `Router` + a private `Router` inside `AMQPAdapter`) — a latent second-authority
  violation (`architecture_audit.md` F-3).

Baseline verdict in one line: *implementation looked complete; evidence did not
support the claims.*

---

## Findings

Grouped by severity. Each cites the report that establishes it and the file:line
where relevant. **FIXED** = remediated during the audit (verified in ground
truth); **DEFECT(open)** = real, unremediated, carried forward.

### CRITICAL

- **C-1 Unbounded codec accumulation → remote memory DoS.** `AMQPFrameCodec`
  grew `_buffer` without limit; a 7-byte header with `size=0xFFFFFFFF` retained
  ~4 GiB/conn, and even a *well-formed* 8-octet AMQP header parsed as a ~1.3 GiB
  frame because no header gate existed. **FIXED** — `max_frame_size` enforced,
  oversized rejected, independently proven (`security_audit.md` §2(a), §7 fix-1;
  `tests/phase6/frame_codec_bounds.mojo`).
- **C-2 Uncaught `raise` in parse/dispatch → broker death.** Bad frame-end
  (`frame_codec`) and `register_consumer: queue not found` (`router.mojo:161-162`)
  propagated to `main()`; one ~9-byte frame killed every connection.
  **FIXED** — listener fail-closed: Malformed → connection socket closed,
  broker survives (`security_audit.md` §2(c), §7 fix-2;
  `tests/integration/listener_hostile.mojo`).
- **C-3 AMQP handshake absent → no real client can connect.** No 8-octet header
  consumption, server never originates `connection.start`/`tune`, SASL absent.
  Was **DEFECT(open, root blocker)**; confirmed by pika: TCP `REACHED`, header
  sent, broker replies nothing → `IncompatibleProtocolError: StreamLostError`
  (`interop_rabbitmq.md` §3, history). **NOW IMPLEMENTED + REAL-CLIENT VERIFIED
  (basic path):** header echo + start/start-ok + tune/tune-ok + open/open-ok +
  content-frame reassembly; pika 1.4.4 9/9 vs our broker and 9/9 vs RabbitMQ
  (`negotiation_impl.md` Update). Remaining handshake surface —
  `connection.close`/`secure`, non-zero heartbeats, field tables, auth
  enforcement, TLS — is still NOT PROVEN (see C-4, M-4).
- **C-4 No authentication / authorization / TLS.** No SASL, no credential store,
  vhost is a cosmetic display string, no TLS. **DEFECT(open, out of audit scope —
  documented absence; `security_audit.md` §5).** Any byte source is implicitly
  fully privileged.

### HIGH

- **H-1 AMQP method-ID non-conformance** (connection class + channel.open).
  **FIXED** to spec decimal, verified against `amqp0-9-1.xml`
  (`amqp_conformance.md` §1.2; ground truth `CONNECTION_OPEN=MethodID(10,40)`).
- **H-2 Content-header frame omitted `weight`, mis-offset `body_size`.**
  Latent (broker inlines body, header/body path unused on happy path).
  **PARTIALLY addressed** via content-header work; still a wire deviation
  against spec `class|weight|body-size|flags|props` (`amqp_conformance.md` §1.3).
- **H-3 `max_connections` declared-but-unenforced + slot leak.** **FIXED** —
  now enforced, over-limit accepted socket closed, refusals counted
  (`persistence_readiness.md` §Q38; `security_audit.md` §7 fix-4;
  `tests/integration/listener_hostile.mojo`).
- **H-4 Routing authority duplicated** — broker assembled a second `Router`
  inside `AMQPAdapter`, mutated by `protocol_selfcheck`, invisible to `status()`.
  **FIXED** — single routing authority: exactly one `Router()`
  (`architecture_audit.md` F-3; ground truth `embedded/api.mojo:90`).
- **H-5 systemd `Restart=on-failure` with no `RestartSec`/`StartLimit*`/`MemoryMax`/
  `LimitNOFILE`** → converts a remote crash into a crash-restart flap and leaves
  the memory-DoS backstop absent. **PARTIAL** — hardening directives authored;
  clean-machine enforcement NOT PROVEN (`security_audit.md` §6;
  `config_systemd.md` §1 checklist).
- **H-6 Message identity is a constant `MessageID(0)`** everywhere; fan-out
  clones zero the id and drop headers (defect D1) → durable recovery and
  producer-visible ack are impossible to specify on current state.
  **DEFECT(open)** (`persistence_readiness.md` §1.1, §2 gap-1).

### MEDIUM

- **M-1 Queue-full = silent drop.** Enqueue-at-capacity destroys the moved copy
  and `publish` return cannot distinguish "no bindings" from "full everywhere"
  (D3/D4). **DEFECT(open)** (`persistence_readiness.md` §2 gap-3, Q37;
  `security_audit.md` T-7).
- **M-2 Delivery-tag namespace per-process from 0** → post-restart tag collision;
  reject requeues to the tail (D9). **DEFECT(open)** (`persistence_readiness.md` §1.2).
- **M-3 `basic.ack` conflates the `multiple` bit with a consumer id**;
  `basic.consume` does not skip `reserved-1` (queue-name misparse);
  `basic.publish`/`deliver` inline bodies (bits-as-body). **PARTIALLY FIXED** —
  single-authority refactor + spec ids, and content-frame (HEADER/BODY)
  reassembly now IMPLEMENTED + pika-verified for the basic path (multi-frame
  body byte-equal). Wire deviations that remain NOT PROVEN: `ack` multiple-bit,
  `consume` reserved-1, and the deliver/get-ok **envelope fidelity gap**
  (empty `exchange`/`routing-key`, `delivery_tag=0`, content-header
  property-flags=0) — see "Remaining NOT PROVEN" item 13.
  (`amqp_conformance.md` L3).
- **M-4 Field tables dead / 3 types only.** `field_table.mojo` never imported on
  the wire path; supports only `'S'`,`'I'`,`'t'`; unknown type octet silently
  truncates. **DEFECT(open)** (`amqp_conformance.md` §1.4).
- **M-5 Transport package holds §24-forbidden messaging verbs** — `framing.mojo`
  `FRAME_TYPE_ACK/REJECT/FLOW_CONTROL` + `flow_control.mojo` policy, both
  production-dead. **DEFECT(open)** (`architecture_audit.md` F-4).
- **M-6 UDS socket mode umask-accidental; no `chmod`/`SO_PEERCRED`;**
  unlink→bind TOCTOU race. **DEFECT(open)** (`security_audit.md` §4).
- **M-7 No management/control-plane server** (read-only status projection only);
  §26 non-authority constraint not yet in docs (F-15). **DEFECT(open, unimplemented)**
  (`architecture_audit.md` §4).

### LOW / TECHNICAL DEBT

- **L-1 Transport contract has no trait** — duck-typed providers, ~50 duplicated
  read-helper lines (`architecture_audit.md` F-5); `max_frame_size` misnamed in
  transport config (F-6); duplicate message-lifecycle construction (F-8);
  `BufferPool` unwired (F-14). All **DEFECT(open, debt)**.
- **L-2 Doc-vs-implementation mismatches** (F-9 product-name in library
  docstrings; F-12 docs certifying second substrate as single-authority).
  **FIXED** where the ground truth reflects the corrected state; doc-truth
  corrections enumerated under Changes Made.
- **L-3 No automated architecture gate** — import direction / flare confinement
  held by comment discipline only (F-11). **DEFECT(open)**; recommend a grep-based
  boundary test in `scripts/check.sh`.

---

## Changes Made

Every implementation / test / documentation change made during the audit
(enumerated; net effect verified by ground truth):

**Tests / test validity**
1. **Test-validity migration ×13** — converted 327 bare `assert` → `check()`
   across 12 files + real checks added to phase0; migrated 14 valid files'
   duplicate local `def check` to `from hyrx.testing import check` (one
   mechanism); kept all `*_PASS` markers (`baseline.md` §B4).
2. Exposed + corrected two latent test-expectation bugs: `latency_histogram_test`
   (never-executed 50/250/25 → correct 51/96/100/260/26/20), `queue_test`
   (capacity counts unacked — full-after-dequeue + slot-opens-after-ack).
3. **Negative proofs** added: `tests/_selftest/assertion_mechanism_test.mojo`
   (exit 0) + `assertion_negfail.mojo` (false check → exit 1, code-after absent);
   value-flip proofs on flow_control/framing/transport (0→1→0).
4. New runtime-assertion tests: `tests/phase6/frame_codec_bounds.mojo`,
   `tests/integration/listener_hostile.mojo`, `tests/integration/socket_negative.mojo`,
   `tests/phase7/config_invalid_test.mojo`.

**Source / correctness**
5. **Topic matcher fix** — `_topic_match` `#` now zero-or-more (word-recursive),
   matching its own docstring and AMQP 0-9-1 (`exchange.mojo:72-76`).
6. **AMQP spec-ids** — connection-class + channel.open method ids corrected to
   spec decimal (`MethodID(10,40)` etc.), verified against `amqp0-9-1.xml`;
   the wrong-id test oracle corrected.
7. **Content-header + single-authority refactor** — content-header path aligned;
   broker reduced to exactly one `Router()` (`embedded/api.mojo:90`); adapter's
   private `Router` removed/injected (F-2/F-3).
8. **BufferSnapshot rename** — `BufferView` → `BufferSnapshot` (it copies —
   proven by experiment), so the name no longer lies about aliasing
   (`persistence_readiness.md` §1.3).
9. **Fan-out double-copy fix** — the per-destination path's two redundant
   byte-copies identified; content-header/single-authority work + D2 copy analysis
   recorded (`benchmarks.md` B3; `persistence_readiness.md` §1.3). *Optimization
   itself deferred (§20/ADR-0008: measure-then-change).*
10. **`unbind_queue` compile fix** (unblocked the routing surface).
11. **Codec bounds + validation** — `AMQPFrameCodec` given a max-size ctor field;
    oversized rejected before accumulation; frame-type checked
    (`security_audit.md` §7 fix-1).
12. **Listener fail-closed + max_connections** — per-frame step wrapped; any
    raise closes that connection only, broker survives; `max_connections` enforced
    with counted refusals (`security_audit.md` §7 fix-2/4).
13. **Config validation hardening** — `apply()` rejects unknown fields / empty
    values / key-named int errors; `from_lines`/`from_key_values` last-wins
    deterministic; `validate()` non-empty host/vhost/node checks
    (`config_systemd.md` Part A).

**Docs / packaging / tooling**
14. **systemd hardening directives** authored (MemoryMax/LimitNOFILE/RestartSec/
    StartLimit*/CapabilityBoundingSet/Restrict*/UMask/RuntimeDirectory — as far as
    authored without clean-machine proof) (`security_audit.md` §6;
    `config_systemd.md` Part B).
15. **Interop harness + scripts** — `scripts/interop/pika_lifecycle.py`,
    `scripts/interop/hyrx_probe.py`, port/env override in
    `src/hyrxmq/main_listen.mojo` (+30 lines only).
16. **Benchmarks** — `benchmarks/{interleaved_direct,transport_matrix,fanout_copy,profiling_probe}.mojo`
    + 4 `bench-*` pixi tasks.
17. **Doc truth corrections** — F-9/F-12/F-15 docstrings and `docs/*` reconciled to
    actual layering; every non-claim ("TLS NOT PROVEN", "negotiation NOT
    IMPLEMENTED") recorded honestly in reports and module headers.

---

## Tests

Exact commands:

```sh
bash scripts/test_all.sh
pixi run mojo run -I src -I vendor/flare <file>     # per-file runner used by the suite
```

**Result:** `bash scripts/test_all.sh` → **37 pass / 0 fail** (exit 0; was 35 —
the connection-negotiation test then `tests/phase7/content_reassembly_test.mojo`
were added).
Suite traverses only `tests/phase0..7/**/*.mojo` + `tests/integration/*.mojo`;
`tests/_selftest` and `scripts/interop` are excluded (verified in `test_all.sh`).

**Runtime-assertion mechanism proof** (`baseline.md` §B2):
- Probe (`/tmp/opencode/audit-assert-probe.mojo`): runtime-false bare `assert`
  → **still prints, EXIT=0** ⇒ bare `assert` is INERT in this runtime.
- `raise`-based `check()` → **EXIT=1** (genuine). `std.testing.assert_equal` →
  raises, EXIT=1.
- `tests/_selftest/assertion_mechanism_test.mojo` → exit 0 / `ASSERTION_MECHANISM_PASS`.

**Negative proofs** (`baseline.md` §B4.5):
- `tests/_selftest/assertion_negfail.mojo`: false `check()` → exit 1 and the
  `NEGFAIL_AFTER_MUST_NOT_PRINT` line is **absent** (execution stopped at the
  failing check) — proves checks fail hard, not print-and-pass.
- Value flips on already-green files: `flow_control` L7 1024→1025 (0→1→0),
  `framing` L24 8→9 (0→1→0), `transport` L8 1024→1023 (0→1→0) — each restored.
- `config_invalid_test.mojo`: every invalid config input raises a *catchable*
  `raise` (try/except asserted); clean exit 0 + PASS line proves no invalid path
  panics.

Interpretation: 37/0 is meaningful precisely because the assertion mechanism was
itself proven to fail closed, then the vacuous files were converted to use it.

---

## Protocol Validation (AMQP 0-9-1)

Method: claims from the authoritative spec (`amqp0-9-1.xml` + RabbitMQ PDF), not
memory (`amqp_conformance.md` §0).

- **Method ids: spec-corrected.** Connection-class and `channel.open` ids now use
  the spec decimal indices (start=10/10, tune=10/30, tune-ok=10/31, open=10/40,
  open-ok=10/41, close=10/50, close-ok=10/51, channel.open=20/10/11), verified
  against `amqp0-9-1.xml`. The wrong-id oracle that hid the bug is corrected
  (ground truth `CONNECTION_OPEN=MethodID(10,40)`).
- **Framing: bounded + tested.** Outer envelope (`type1|chan2|size4|payload|0xCE`)
  byte-correct vs spec §2.3.5.1 (`amqp_conformance.md` §1.1). Frame size now
  bounded and oversized-rejected (`tests/phase6/frame_codec_bounds.mojo`,
  ceiling 131072 + bad frame-type). `frame-end=0xCE(=206)` correct.
- **State machine: ADVANCING (basic path real-client verified).** Header
  consumption + `connection.start`/start-ok + `tune`/tune-ok + gated
  `open`/open-ok now originate and are driven by a real pika client
  (`negotiation_impl.md`); content-frame reassembly IMPLEMENTED. Still open:
  `set_state()` accepts any transition (no gate on dispatch), `close`/`close-ok`
  and `secure` never emitted, `frame_max`/`heartbeat` renegotiation not honored,
  non-zero heartbeats absent, field tables not serialized
  (`amqp_conformance.md` §2). A real client now **does** reach the basic methods.
- **Content-header / field tables:** inbound/outbound content HEADER+BODY frames
  reassembled/emitted for the basic path (pika-verified); but wire
  **property-flags=0** observed on outbound (no delivery_mode/content_type/etc.
  fidelity), `message_count=0`, and field tables remain 3-type and dead-code on
  the wire (M-4). Property/field-table fidelity **NOT PROVEN**.
- **Compatibility matrix counts** (`amqp_conformance.md` §10):
  **SUPPORTED 0 · PARTIALLY SUPPORTED 15 · NOT IMPLEMENTED 30** (+ RabbitMQ-interop
  layer NOT TESTED). These §10 numbers **predate** this session's
  negotiation+content work and are the report's own method-level classification;
  do **not** restate them as current without re-deriving §10. What is measured
  now (this session, `negotiation_impl.md` Update): header +
  start/start-ok + tune/tune-ok + open/open-ok + channel.open + basic
  publish/consume/get/ack + multi-frame content are **INTEROPERABILITY PROVEN**
  for the basic path via pika 1.4.4.

Gate §33 "AMQP PROTOCOL VALIDATION PASS": **PARTIALLY satisfied** — self-consistent
codec + spec ids, and a **narrow basic path now real-client verified** (pika);
the **broad** surface (close/secure/heartbeat/field-tables/error-edge/
auth-enforcement/TLS) has no real-client conformance (see Interoperability,
RabbitMQ Differential).

---

## RabbitMQ Differential (§12)

**Status: NOT PROVEN (broad differential) — narrow same-client basic pass captured.**

- The reference column is real: `pika_lifecycle.py` runs the §11 lifecycle against
  RabbitMQ 4.3.5 and passes **18/18** (connect→auth(negative)→vhost→channel.open→
  declare→bind→publish→consume→deliver→ack→prefetch→nack/requeue→redelivery→
  channel.close→connection.close→reconnect), including genuine `redelivered=True`
  (`interop_rabbitmq.md` §2). Docker untouched.
- **New (this session):** the *same independent client* (pika 1.4.4) runs a narrow
  basic-path check (`pika_content.py`) against **both** brokers at 9/9 — our broker
  (5699) and the RabbitMQ reference (5672) — for handshake + publish/consume/get/ack
  + 9000-byte multi-frame body byte-equal (`interop_rabbitmq.md` Update,
  `negotiation_impl.md` Update). This is a **same-client pass captured on both
  sides**, NOT a full HyrxMQ-vs-RabbitMQ differential.
- **What is still NOT PROVEN:** the true **error/edge differential** — bad-auth 403,
  `basic.nack` requeue+redelivery, `basic.cancel→cancel-ok`,
  `channel.close`/`connection.close→close-ok`, qos enforcement, confirmations — was
  **NOT RUN** against HyrxMQ by a real client. The §4 matrix in `interop_rabbitmq.md`
  (pre-negotiation) remains the record for that broad surface.
- Envelope/property fidelity **differs and is NOT PROVEN**: our broker emits
  `exchange=''`, `routing-key=''`, `delivery_tag=0` and property-flags=0 where
  RabbitMQ populated exchange/rk, an incrementing tag and properties (root cause:
  core `Delivery` has no envelope read-back — D1).
- **Gate branch:** recorded as **NOT PROVEN**, not fabricated as PASS. Do not claim a
  RabbitMQ differential until the error/edge cases are actually run against HyrxMQ.

---

## Interoperability (§11)

**Status: PASS (basic path) — INTEROPERABILITY PROVEN for the narrow basic path
via an independent client. Broader surface NOT PROVEN.**

- Real client: **pika 1.4.4** (Python 3.14 venv) — an independent AMQP client, not
  our test client.
- vs **RabbitMQ 4.3.5**: full lifecycle **PASS (18/18)** and the narrow basic path
  **9/9** — harness validated.
- vs **our broker** (`build/hyrxmq-listen`, `HYRXMQ_PORT=5699`): basic path
  **9/9 PASS** (`PIKA_CONTENT(hyrx) VERDICT: PASS`) — pika completes the full
  handshake (header echo → start/start-ok → tune/tune-ok → open/open-ok →
  channel.open → exchange/queue declare → bind), then `basic.publish` +
  `basic.consume` delivery body byte-exact (`b'hello-hyrx'`), `basic_get`
  byte-exact, `get-empty` honored, `basic.ack` accepted, and a **9000-byte body
  reassembled across multiple content-body frames** (`frame_max=4096`) byte-equal.
  Command: `HYRXMQ_PORT=5699 /tmp/amqp-venv/bin/python
  scripts/interop/pika_content.py hyrx` (and `... rabbit`). RabbitMQ `:5672`
  untouched. Evidence: `negotiation_impl.md` Update, `interop_rabbitmq.md` Update.
- **Prior state (history, now SUPERSEDED):** `hyrx_probe.py` §3 — TCP `REACHED`,
  header sent, broker replied nothing → `IncompatibleProtocolError:
  StreamLostError`. That was the pre-negotiation blocker; negotiation + content
  reassembly have since landed and the basic path is real-client verified.
- **Scope discipline:** this is **INTEROPERABILITY PROVEN for the basic path only**,
  not a general interoperability claim and never an unqualified "RabbitMQ
  compatible". The gaps recorded in "Remaining NOT PROVEN" (auth enforcement, TLS,
  error/edge differential, field tables/properties, async push, deliver envelope
  fidelity) are **not** covered by the 9/9 result and are observed *inside* the
  passing run.

---

## Concurrency

**Status: EXPLICITLY DEFERRED WITH EVIDENCE** (satisfies gate §33 "VALIDATED OR
EXPLICITLY DEFERRED WITH EVIDENCE"; `concurrency_design.md` §7).

Evidence, all probed in this exact toolchain:
- **Nothing concurrent exists to validate** — zero `Thread|spawn|atomic` in
  `src/`; all hot-path state is one `mut self` `Router`. Concurrency tests would
  test an absent feature.
- **Toolchain lacks a safe foundation** — `threading`, `sync`, Mutex, channels,
  async all *unable to locate*; working pieces are `std.atomic`
  fetch_add/load/store (executed correct) and raw `pthread` FFI inside vendored
  flare (cross-thread release-store/acquire-load executed: `cross-thread value: 42`),
  with **CAS unresolvable** in-session and `List` incompatible with move-only
  payloads. No race-detection tooling (no TSan).
- **Bounded plan recorded** — Phase A = single event loop (needs none of the
  missing primitives; the honest next step); Phase B = queue-ownership actors
  with an explicit precondition list and a §6 test list so the future work is
  verifiable, not aspirational. Rejected: global-Router-mutex, connection-per-worker,
  work-stealing.

---

## Failure Testing

- **Socket / abrupt disconnect:** `tests/integration/socket_negative.mojo` +
  `listener_hostile.mojo` — invalid frame-type, ~4 GiB header, undeclared-queue
  consume, over-`max_connections` → connection closed, **broker survives**.
- **Queue-exhaustion silent drop:** `bounded_resource_test.mojo` — capacity bound
  counts unacked (`queue.mojo:71-73`); confirms drop-on-full and that `publish`
  return cannot distinguish full-vs-unroutable (M-1/D3/D4) — the drop is real and
  now *tested as a known gap*, not hidden.
- **Hostile parse:** `frame_codec_bounds.mojo` (size ceiling 131072 + bad
  frame-type) — proves the codec rejects oversized/malformed frames.
- **NOT PROVEN:** process kill / SIGTERM shutdown under systemd; live crash-vs-
  graceful-exit behavior of the listen binary on a raw socket; connection-storm
  head-of-line behavior under real load. The §13 fuzz targets
  (`amqp_conformance.md` §13) remain a hand-written subset, not a fuzzer.

---

## Security

**Threat model** (`security_audit.md` §1): two layers must be separated.
The **AMQP session layer** (auth/tune/declare…) is *not reachable by a real
client* (negotiation absent) → risk latent. The **byte/framing layer** is
*reachable now by any raw TCP peer* (`main_listen` binds 0.0.0.0:5672;
`try_parse_frame`/`handle_frame` run with no header or state gate). So the
bounded-resource and uncaught-raise findings are code-path-real, not theoretical.

**What got fixed (this audit):**
- **Bounds** — `frame_max` now reaches the codec; oversized frames rejected before
  accumulation (kills C-1 remote memory DoS). Independently proven.
- **Fail-closed** — per-frame parse/dispatch wrapped; malformed → connection
  closed, broker survives (kills C-2 one-frame-crash). `max_connections` enforced
  (H-3). Queue-depth bound enforced (count; bytes still open).
- **systemd hardening** — directives authored (MemoryMax/LimitNOFILE/RestartSec/
  StartLimit*/CapabilityBoundingSet/Restrict*/UMask/RuntimeDirectory).

**What remains NOT PROVEN / ABSENT (do not claim otherwise):**
- **Auth / SASL / authorization / TLS: NOT IMPLEMENTED** (C-4). Any byte source is
  implicitly fully privileged. No security-event logging.
- Queue **bytes** / message **size** bounds absent (count only); topology/consumer
  counts unbounded (`security_audit.md` §3).
- **Sandbox/resource-limit ENFORCEMENT NOT PROVEN** — declared only; no clean-host
  run. UDS mode umask-accidental, no `SO_PEERCRED` (M-6).
- Live-listen crash behavior not executed.

Gate §33 "SECURITY BASELINE VALIDATED": **PARTIAL** — byte-layer bounds +
fail-closed are now implemented and negative-tested; auth/TLS/sandbox-enforcement
NOT PROVEN. A "secure" or "security baseline validated" claim is **not** made.

---

## Systemd

(`config_systemd.md` Part B)

- **Unit syntax: VALIDATED** — `systemd-analyze verify` reports **no syntax
  errors**; the only diagnostic is the expected "ExecStart binary not installed"
  warning (RC=1 from that warning, not a malformed unit).
- **Application startup/ready/self-check: PROVEN (non-systemd)** —
  `build/hyrxmq` (the non-listening self-check binary, binds nothing, avoids the
  live RabbitMQ on 5672) starts, reports ready, self-checks declare/publish/
  deliver/ack in-process, exits 0 without hanging.
- **NOT PROVEN (clean machine):** `hyrxmq` user/group creation (principals absent
  on host — `sysusers.d` prerequisite outstanding), listen accept-loop startup,
  `systemctl` start/stop/restart, journal logging, SIGTERM handling, sandbox
  enforcement (ProtectSystem/NoNewPrivileges/PrivateTmp/RestrictAddressFamilies),
  resource controls (MemoryMax/LimitNOFILE), config-under-systemd.

Gate §33 "SYSTEMD CLEAN-MACHINE VALIDATED": **NOT MET.** No overclaim.

---

## Performance

All numbers are **actual single runs** in this environment (no averaging; variance
band stated). `bash scripts/test_all.sh` = 34/0 was unchanged by benchmark
addition (the interop/negotiation/content tests are in-repo, not benchmarks; the
current authoritative tree is **37/0**) — no benchmark entered the suite.

### Measured (BENCHMARKED)

Interleaved direct, 256 B (steady-state, bounded depth) — `benchmarks.md` B1:
| payload | msgs/s | MiB/s | p50 | p99 |
|---|---:|---:|---:|---:|
| 64 B | 716 765 | 43.7 | 1.00 µs | 1.68 µs |
| 256 B | 276 073 | 67.4 | 2.38 µs | 3.91 µs |
| 1 024 B | 85 005 | 83.0 | 7.29 µs | 12.23 µs |
| 4 096 B | 23 474 | 91.7 | 26.95 µs | 43.60 µs |

Run-to-run variance: 256 B re-ran at 340 435; 64 B at 828 017 (~20% higher). Treat
as a **band**, not a regression. "~280k msg/s direct" = the 256 B single-run band.

Transport matrix, 256 B, 20k cycles (loopback ping-pong) — B2:
| transport | p50 | msgs/s | overhead vs direct |
|---|---:|---:|---:|
| direct | 3.36 µs | 280 144 | baseline |
| UDS | 8.21 µs | 117 943 | +4.85 µs (~2.4×) |
| Hyrx TCP | 14.28 µs | 67 460 | +10.92 µs (~4.3×) |
| AMQP/TCP | 23.27 µs | 40 094 | +19.91 µs (~7×; codec +8.99 µs over TCP) |

Overheads are near-constant from 64 B→256 B → per-message transport/protocol cost,
not bandwidth cost.

Fan-out copy slope (engine `publish()` p50) — B3: D=1→100 ≈ 90× at every payload;
marginal **+2.38 µs/dest at 256 B** ≈ 2×256 B at **~198 MiB/s**; isolated copy model
matches within ~10% ⇒ the per-destination added cost **is** the two scalar per-byte
copy loops (`router.mojo:170,177-180`), which run at ~145–165 MiB/s vs a GiB/s memcpy.

Phase decomposition (B4a): `route` (publish = match + 2×copy) is 56–65% of the
direct cycle and grows with payload; `deliver`/`ack` flat ~160/100 ns (token +
destroy, no copy). `/proc` (B4b): direct/fan-out 100% user time (sys≈0);
transport matrix **~35% kernel time** (socket send/recv + kernel copy).

### NOT PROVEN (no profiler in toolchain — perf/valgrind/strace/ltrace absent)

- **syscalls/msg** — needs strace/perf; the 35% kernel share is a proxy only.
- **cache misses / IPC** — needs `perf stat`; the ~150–250 MiB/s copy rate is
  *strongly indicated* scalar-loop + bounds-check bound, **not** proven
  memory-bandwidth/cache bound.
- **off-CPU / wakeup cost per message** — voluntary ctxt ≈ 0 argues negligible; not
  measured per-message.
- **allocations/msg** — derived ≥3/publish by code reading; not profiler-confirmed.

Per §20/ADR-0008, the copy path is stated as an **implementation-level hotspot /
strongly-indicated dominant term at high destinations×payload**, never a
profiler-proven "measured bottleneck." **AMQP-TLS not benchmarked** (TLS not
implemented). Gate §33 "PERFORMANCE REPRODUCIBLE BASELINE": **PASS** (commands +
numbers given); profiler-level attribution explicitly NOT PROVEN.

---

## Architecture Audit

§4 boundary table (`architecture_audit.md` §1), post-fix status:

| Boundary | Expected | Actual | Status |
|---|---|---|---|
| Core → AMQP | none | core imports std + `hyrx.core.*` only; `grep amqp/frame` → 0 | **OK** |
| Core → TCP | none | no socket code; only a routing-docstring "Bind" | **OK** |
| Core → simulation | none | creature/agent/world/rabbit → 0 hits | **OK** |
| AMQP → Core | delegation | adapter delegates to Router — **second `Router` now removed; single authority** | **OK (was VIOLATION)** |
| Transport → Core | contract only | zero `hyrx.core` imports; flare confined to `{tcp,uds}.mojo` | **OK** |
| Broker → Core | yes | all live-path semantics → one `HyrxEngine` → **exactly one `Router()`** (`embedded/api.mojo:90`) | **OK (was VIOLATION)** |

**The fixed VIOLATION:** `architecture_audit.md` F-3 — the broker composed a
second routing substrate (`AMQPAdapter` → private `Router()`), mutated by
`protocol_selfcheck`, producing topology invisible to `status()`/engine counters.
**Now resolved:** single routing authority, exactly one `Router()` (ground truth
`embedded/api.mojo:90`). Also resolved: F-2 (AMQP translation duplicated in
Layer 5) collapsed into the single-authority refactor; H-1/F-1 divergent
exchange-type maps aligned by the spec-id work.

**Direction compliance:** no upward/import-cycle edges — `grep hyrxmq src/hyrx/`
returns comment text only ⇒ INV-005 holds. Transport carries **zero** core coupling
(stronger than "contract only"). Management is a read-only counter projection,
**off the hot path** (no per-frame status/config calls) ⇒ INV-012 holds.

**Open architecture items (not defects in direction, debt/violations-by-wording):**
F-4 (§24-forbidden verbs in dead transport modules), F-5 (no transport trait),
F-6 (misnamed `max_frame_size`), F-8 (dup message lifecycle), F-10 (listener
inspects method ids), F-11 (no automated boundary gate), F-13/F-14/F-15 (model-
borrow doc note, unwired pool, mgmt non-authority clause). Prioritized F-4 → F-5 →
F-11 → docs set.

Gate §33 ARCHITECTURE / CORE SEMANTICS / OWNERSHIP / TRANSPORT: **PASS** (OWNERSHIP
with the D1/D2 copy-not-share caveats logged under MEDIUM findings).

---

## Compatibility Matrix

Reference: **`confidence_matrix.md`** (this directory) is the authoritative §28
matrix — reproduced here as summary; link it, do not duplicate every cell.

Tally across 20 areas: **HIGH 4 · MEDIUM 10 · LOW 0 · NOT PROVEN 6.**
- **HIGH:** Core, Queueing, UDS, TCP (runtime-checked tests / real loopback).
- **MEDIUM:** Ownership, Routing, Backpressure, Hyrx framing, AMQP codec, Failure
  semantics, Security, Performance — **plus AMQP state machine (LOW→MEDIUM: header/
  start/tune/open + basic dispatch implemented and driven by a real client;
  close/secure/heartbeats/field-tables still missing)** and **Real AMQP clients
  (NOT PROVEN→MEDIUM: INTEROPERABILITY PROVEN for the basic path via pika 9/9,
  but only that narrow path — broad surface unproven)**.
- **NOT PROVEN (6):** RabbitMQ differential, Concurrency, Persistence, Systemd,
  Management, Fuzzing.

Post-fix AMQP §10 method classification (`amqp_conformance.md` §10, pre-dates this
session — do not restate as current without re-deriving): SUPPORTED 0 / PARTIAL 15
/ NOT-IMPL 30. **Measured this session** (`negotiation_impl.md` Update): the basic
path is real-client verified; this is recorded as **INTEROPERABILITY PROVEN (basic
path)**, and **no** "RabbitMQ compatible" / "AMQP PROVEN" / HIGH upgrade is made.
§34-Q33 answer: **yes, the matrix has been updated** — see `confidence_matrix.md`.

---

## Remaining NOT PROVEN Items (explicit list)

1. **AMQP connection negotiation** — header/start/start-ok/tune/tune-ok/open/open-ok +
   basic dispatch now IMPLEMENTED + real-client verified (basic path,
   `negotiation_impl.md` Update). Still NOT PROVEN: bad-auth 403 observability
   (SASL parsed, not validated), `connection.close`/`secure`, non-zero heartbeats,
   frame_max/heartbeat renegotiation.
2. **Real-client interoperability — broad surface.** The narrow basic path is now
   INTEROPERABILITY PROVEN (pika 9/9 vs our broker AND 9/9 vs RabbitMQ); error/edge,
   nack/cancel/close, qos enforcement and confirmations remain NOT PROVEN (never run
   against HyrxMQ by a real client).
3. **RabbitMQ differential, HyrxMQ column** — only the same-client basic pass was
   captured on both brokers; the true error/edge/nack/cancel/close/confirm
   differential vs HyrxMQ was **NOT RUN** → NOT PROVEN.
4. **Concurrency correctness** — deferred; no threads/mutex/CAS in Mojo 1.0 std.
5. **Persistence / durable recovery** — not implemented; no file/fsync surface in toolchain.
6. **Systemd clean-machine lifecycle** — install→user/group→start→bind→journal→
   stop/restart→sandbox→resource limits.
7. **Management API** — none exists (read-only projection only); §26 non-authority
   constraint not yet in docs (F-15).
8. **Auth / SASL / authorization / TLS** — SASL PLAIN is now *parsed* on the
   negotiation path but **no credential is validated** (any PLAIN accepted);
   authorization and TLS remain absent.
9. **True fuzzing / coverage-guided harness** — only hand-written negative cases;
   state-machine fuzz (§13.7) outstanding.
10. **syscalls/msg, cache misses/IPC, off-CPU cost, allocations/msg, live crash-vs-
     graceful-exit, process-kill under systemd, connection-storm under real load.**
11. **Field tables / content properties on the wire** (field tables dead code,
    3 types; outbound content-header property-flags=0, message_count=0);
    `basic.cancel→cancel-ok`, `basic.nack` requeue+redelivery,
    `channel.close`/`connection.close→close-ok` replies remain NOT PROVEN
    (`basic.qos→qos-ok`, `basic.get-empty` are now implemented).
12. **Config file-load from disk** — no os/file in Mojo 1.0 std (env/argv override
     is the only current path).
13. **Deliver/get-ok envelope fidelity (next small correctness item).** On the
     passing pika run our broker emits `basic.deliver`/`basic.get-ok` with
     `exchange=''`, `routing-key=''`, `delivery_tag=0` (start-at-0) where RabbitMQ
     populated exchange/rk and an incrementing tag. Root cause: the core `Delivery`
     carries **no envelope (exchange/routing-key/message-id) read-back accessor** —
     consistent with audit finding **D1** (router zeroes message_id/headers on
     fan-out). Fix = add an envelope read-back on `Delivery`, then populate the
     deliver/get-ok envelope, delivery-tag and content-header property flags.

---

## Risks (ranked by severity)

1. **No auth/TLS (C-4) — now LIVE, top risk.** Negotiation + content landed (C-3
   resolved for the basic path), so a real client can connect to a broker that
   accepts **any PLAIN credential** (SASL parsed, not validated) with **no TLS**.
   Pair the reachable path with at least SASL-PLAIN validation + loopback default
   before any external deployment.
2. **Interop is proven only for the narrow basic path.** The broad surface
   (error/edge differential, nack/cancel/close, qos enforcement, field
   tables/properties, async push, deliver envelope fidelity) is self-consistent /
   NOT PROVEN. Highest residual business risk: generalizing the pika basic-path
   PASS into an unqualified "RabbitMQ compatible" claim.
3. **Residual resource gaps (M-1, H-5).** Queue-full silent drop (undocumented
   message loss) + systemd crash-restart flap risk if limits/RestartSec unenforced.
4. **Persistence is architecturally blocked on identity/semantics (H-6, M-1, M-2).**
   A WAL built today would faithfully log destruction and collide tags — must fix
   semantics *before* a log format.
5. **Concurrency toolchain gap (C, §3).** Multi-thread correctness would rest on
   hand-rolled FFI discipline with no race detection — do not ship threads until the
   §6 preconditions are met.
6. **No automated architecture gate (L-3).** Single-authority/flare-confinement now
   holds but is protected by comment discipline; a regression would pass CI.
7. **Measurement blind spots (perf NOT PROVEN).** Optimizations can be misdirected
   without profiler access.

---

## Decisions (ADRs)

- **ADR-009 (Flare) — ACCEPTED / honored.** flare v0.10.0 pinned submodule; only
  `src/hyrx/transport/*` imports it, never `src/hyrx/core` (`docs/DECISIONS.md`
  ADR-009 / `docs/decisions/0005-flare-transport-dependency.md`). Confined as
  specified (ground truth; `architecture_audit.md` §2.5).
- **ADR-0002 / ADR-007 — reinforced.** AMQP stays an adapter boundary, not internal
  representation; "compatibility is measured" — the audit honors this by recording
  interop as BLOCKED, not compatible.
- **ADR-0008 — honored.** Optimization deferred pending measurement; fan-out copy
  hotspot is *measured* but not yet refactored (memcpy/Candidate plan recorded, not
  applied).
- **New decision this audit implies (recommend recording as ADR-0010):**
  > **"AMQP connection negotiation was the single prerequisite gating real-client
  > interop."** Header consumption + start/start-ok (SASL PLAIN parsed) +
  > tune/tune-ok + open/open-ok + channel.open + **content-frame reassembly** have
  > now landed and are **real-client verified for the basic path** (pika 1.4.4, 9/9
  > vs our broker and 9/9 vs RabbitMQ — `negotiation_impl.md` Update). This converts
  > §11 from BLOCKED to **PASS (basic path)**. What ADR-0010 still forbids: an
  > unqualified "AMQP compatible" / "RabbitMQ compatible" / broad "real-client
  > PROVEN" / "systemd lifecycle VALIDATED" claim — the broad error/edge differential,
  > auth **enforcement**, TLS, field tables/properties, async push and the deliver
  > envelope fidelity gap are NOT PROVEN. This must be paired with the §13 fuzzer
  > (now reachable) and a documented auth posture before any external deployment.

---

## Self-Assessment (§34 — all 48 questions)

### Architecture (1–7)

1. **Hyrx independence from simulation preserved?** YES — `grep` for
   creature/simulation/agent/perception/cognition/motor/world/rabbit in `src/` → 0
   hits; INV-006 demonstrated, not inferred (`architecture_audit.md` Q1).
2. **Did I accidentally make AMQP an internal dependency?** NO for Core (0 AMQP
   imports). Previously the translation authority leaked to Layer 5 with a private
   `Router` (F-2/F-3) — **now resolved by the single-authority refactor**; Core is
   wire-free, AMQP is a boundary (`docs/DECISIONS.md` ADR-003).
3. **Did I make TCP mandatory inside Core?** NO — Core imports std + core only; all
   socket material is behind `hyrx/transport/*` (ADR-005). In-process path needs no
   networking.
4. **Did I introduce HyrxMQ responsibilities into Core?** NO functionally (no broker
   lifecycle/vhost/node/status/config in Core). Docstring product-name inversions
   (F-9) corrected under doc-truth changes.
5. **Did I introduce premature distributed-system architecture?** NO — grep
   cluster/consensus/distributed/replicat → 0 functional hits; heartbeat is dead
   code, not a distribution mechanism. INV-007 intact.
6. **Is Hyrx usable in-process without networking?** YES — `hyrx/core` +
   `hyrx/embedded` depend on std only; `HyrxEngine` requires no transport/flare/
   socket. Canonical INV-002 path; exercised by the `build/hyrxmq` self-check.
7. **Is HyrxMQ still a product built around Hyrx?** YES directionally —
   `hyrxmq → hyrx` only, never the reverse; the "single Hyrx engine per broker"
   caveat (second router) is **resolved** to exactly one `Router()`.

### Correctness (8–12)

8. **Invariants actually demonstrated?** INV-005 (no reverse deps — grep), INV-006
   (no simulation), INV-007 (no premature distribution), INV-002 (in-process),
   INV-012 (management off hot path, read-only projection) — DEMONSTRATED
   statically + by runtime-checked tests. Queue FIFO/ack/reject-to-tail and
   bounded-count DEMONSTRATED (`tests/phase2/queue_test.mojo`, §B4).
9. **Invariants only inferred?** "Broker = one routing authority **for all reaches**"
   was inferred-then-fixed (adapter second-router removed). Deterministic *global*
   order under concurrency is inferred-only (no concurrency exists). Byte-level
   memory bounds are declared; queue **byte** bounds remain inferred/absent (M-1).
10. **Failure paths untested?** Process kill/SIGTERM under systemd; live-listen
    crash-vs-graceful-exit on raw socket; connection storm under load; state-machine
    out-of-order method fuzz; field-table corruption. All NOT PROVEN.
11. **Queue and routing semantics deterministic?** YES for the single-threaded path —
    per-queue FIFO is an emergent property of the two-stack layout; routing is a
    pure function of topology + routing-key (direct/fanout/topic now spec-conformant
    for `#`). NOT PROVEN across threads (none exist).
12. **Ownership transitions explicit?** YES — payload moves by `^`, reads return an
    explicit **copy** (renamed `BufferSnapshot`, proven by experiment), no silent
    aliasing (INV-011). Caveat: fan-out copies rather than shares (D2) — correct but
    costly; `MessageID`/headers dropped on fan-out clones (D1, open).

### Testing (13–17)

13. **All test assertions genuinely runtime assertions?** YES post-repair — inert
    bare `assert` proven, all 13 vacuous files migrated to `check()` (single shared
    mechanism); negatives proven to exit 1 (`baseline.md` §B2/B4/B5).
14. **Which previous tests were potentially vacuous?** 13: phase0 print-only;
    phase1×3 / phase2×4 / phase3×2 / phase4 transport / phase5 framing+flow (bare
    inert `assert`). All repaired.
15. **New negative tests?** `frame_codec_bounds.mojo`, `listener_hostile.mojo`,
    `socket_negative.mojo`, `config_invalid_test.mojo`, `_selftest/assertion_negfail
    .mojo`; value-flip proofs on flow_control/framing/transport.
16. **Concurrent tests?** NONE — concurrency is EXPLICITLY DEFERRED WITH EVIDENCE
    (no toolchain foundation); the §6 concurrency test list is specified for when
    Phase A lands, not faked.
17. **Fault-injection tests?** Frame-level hostile input (bad end byte, ~4 GiB
    size, bad frame-type, over-limit connections, undeclared-queue raise) → broker
    survives. **NOT PROVEN:** true fuzzing, state-machine illegal-transition
    injection, sanitizer-based fault injection.

### Performance (18–27)

18. **Measured bottleneck?** The **per-byte payload copy inside `Router.publish`** —
    measured: 62% of the direct cycle at 256 B (B4a), fan-out slope +2.38 µs/dest,
    isolated copy 145–165 MiB/s (B3). Measured as *cost*, not profiler-attributed sole
    system bottleneck.
19. **Only a strongly-indicated hotspot?** That the copy loop is bounded by scalar
    per-element bounds-checks (not memory bandwidth) — **strongly indicated**, not
    profiler-proven (no `perf stat`/cache counters). Per-transport overhead being
    syscall/kernel-copy bound: strongly indicated by B4b 35% kernel time, not
    syscall-counted.
20. **Allocations/message?** ≥3 per publish (source Buffer + snapshot + owned
    Buffer/destination) — derived by code reading; **NOT profiler-confirmed**.
21. **Copies/message?** 2 full payload writes per destination at D=1 (copy #1
    `msg.payload()`→snapshot, copy #2 per-byte rebuild) — **measured** by slope match
    to isolated copy; bytes/publish ≈ 2×destinations×payload.
22. **Syscalls/message?** **NOT PROVEN** — no `strace`/`perf trace`; the 35% kernel
    CPU share in the transport matrix is a proxy only.
23. **p99 latency?** Measured (B1/B2): direct 256 B p99 = 3.91 µs; UDS 12.80 µs;
    TCP 20.92 µs; AMQP/TCP 36.27 µs (single run; p99.9 also recorded).
24. **Under sustained load?** Interleaved steady-state (depth ~0–1) measured to
    98k cycles — no queue growth, throughput stable within band. Sustained multi-
    connection load / soak NOT PROVEN (single-threaded serialized server).
25. **Many producers?** NOT PROVEN — no concurrency; a real multi-producer test
    requires the deferred thread foundation. Single-threaded interleaving only.
26. **Many consumers?** NOT PROVEN for concurrent consumers; pull-on-subscribe flush
    is capped at `_CONSUME_FLUSH_MAX=128` (bounded, tested), not async push to many.
27. **What optimization produced a measured improvement?** NONE applied this audit
    (ADR-0008: measure first). The copy-fix / Candidate-C / memcpy plan is *recommended
    with measured slope*, not implemented — so no optimization improvement is claimed.

### Compatibility (28–33)

28. **AMQP features genuinely tested?** Frame envelope (byte-correct vs spec),
    bounded codec + frame-type/end validation (negative-tested), field_table subset
    (3 types, unit-tested but dead on wire), and — **new this session** — the
    connection-negotiation bytes (start/tune/open-ok exact) plus a **real pika 1.4.4
    client driving the basic path (9/9 vs our broker, 9/9 vs RabbitMQ)**.
29. **AMQP features only implemented (not genuinely tested against a client)?** The
    basic path (header, start/start-ok, tune/tune-ok, open/open-ok, channel.open,
    exchange/queue declare, bind, basic publish/consume/get/ack, multi-frame content)
    is now **real-client verified**. Still only implemented / NOT reached by a real
    client: `connection.close`/`secure`, non-zero heartbeats, `basic.cancel→cancel-ok`,
    `basic.nack` requeue+redelivery, qos **enforcement**, field tables/properties,
    bad-auth 403, TLS.
30. **RabbitMQ behaviors demonstrated?** Against RabbitMQ itself the reference
    baseline holds (auth refused→403, transient-non-exclusive→541, redelivery flag,
    nack/requeue) — RabbitMQ facts. **New:** pika against *our* broker demonstrates
    handshake + basic publish/consume/get/ack + byte-exact multi-frame bodies; but
    auth-403, nack/requeue and redelivery were **not** demonstrated on our broker.
31. **RabbitMQ behaviors inferred?** The narrow basic path is now **observed** on both
    brokers (same client, 9/9 each). The broader HyrxMQ-vs-RabbitMQ differential
    (error/edge, nack/cancel/close, qos enforcement, envelope/property fidelity) is
    still **inferred, not observed** — not run against HyrxMQ.
32. **Features intentionally different?** YES, documented: pull-on-subscribe flush
    (no async push-to-idle-subscriber), numeric consumer tags, unparsed field tables,
    single static vhost, and the deliver **envelope/property fidelity gap**
    (empty exchange/rk, delivery_tag=0, property-flags=0 — core `Delivery` has no
    envelope read-back, D1). NOTE: "inline-body publish/deliver (no multi-frame
    content)" is **now superseded** — content-frame reassembly is implemented and
    pika-verified for the basic path.
33. **Compatibility matrix updated?** YES — `confidence_matrix.md` (§28) now shows
    AMQP state machine LOW→MEDIUM and Real AMQP clients NOT PROVEN→INTEROPERABILITY
    PROVEN (basic path, MEDIUM); tally HIGH 4 · MEDIUM 10 · LOW 0 · NOT PROVEN 6.
    The `amqp_conformance.md` §10 counts (SUPPORTED 0 / PARTIAL 15 / NOT-IMPL 30)
    predate this session and must be re-derived before restating. **No**
    "RabbitMQ compatible" / "AMQP PROVEN" claim is recorded.

### Reliability (34–39)

34. **Abrupt disconnect?** Nothing reclaims stranded unacked messages — consumer-
    unregistered messages stay owned by the Queue with no reclaim trigger (D8);
    no close/cancel handshake. Single-node ⇒ RAM data safe, delivery stranded.
35. **Process termination?** ALL messages + ALL topology lost — `shutdown()` flips a
    flag only; no flush target. Ephemeral-only is the honest current state.
36. **Resource exhaustion?** Queue depth bound enforced (count, incl. unacked);
    frame size now bounded; **bytes/message-size/topology-count unbounded**;
    BufferPool unwired; none of the three exhaustion paths block or raise.
37. **Queue exhaustion?** Per-destination copy destroyed **silently** — enqueue
    returns `False` on a moved message; publish return cannot distinguish
    "no bindings" from "full everywhere" (M-1/D3/D4). Tested as a known gap.
38. **Connection storms?** Fail-closed accept gate — over `max_connections` the
    socket is closed immediately without AMQP handling, refusals counted; serialized
    accept loop ⇒ head-of-line starvation risk; process-level storm soak NOT PROVEN.
39. **Persistence failure?** N/A — persistence not implemented, no failure path
    exists. Hidden prerequisite: no portable file/fsync surface in this Mojo build.

### Security (40–43)

40. **Hostile protocol inputs tested?** YES at **frame level** — bad end byte,
    oversized size, bad frame-type, over-limit connections, undeclared-queue raise →
    broker survives (bounds + fail-closed). **NO real-client fuzzing / no
    coverage-guided harness** — state-machine fuzz outstanding.
41. **Resource-exhaustion attacks considered?** YES — remote memory DoS (fixed),
    connection storm (gate added), queue depth (enforced), O(N²) codec copy
    (identified, low priority). Bytes-per-queue and message-size ceilings still ABSENT.
42. **systemd sandbox validated?** NO — directives authored + `systemd-analyze
    verify` syntax-clean, but **enforcement NOT PROVEN** (no clean-host run; `verify`
    does not check `User=`).
43. **Credentials / secrets handled safely?** No secrets exist to mishandle yet
    (config = compiled-in defaults; no secret read). But **no auth/TLS/credential
    store at all** (C-4), and no secret/`EnvironmentFile` policy for when they land.
    Do NOT claim credentials handled — there are none.

### Documentation (44–48)

44. **Docs describe actual behavior?** Now YES for the corrected items (F-9/F-12
    product-name / second-substrate claims reconciled; module headers state
    "negotiation NOT IMPLEMENTED", "TLS NOT PROVEN"). Residual: docs must not
    certify the dead transport framing/flow modules as live (§F-4 open).
45. **Unsupported features explicit?** YES — `amqp_conformance.md` §10 lists NOT
    IMPLEMENTED 30; `security_audit.md` §5 states auth/TLS NOT IMPLEMENTED;
    `persistence_readiness.md` §0 states persistence NOT IMPLEMENTED.
46. **Benchmark claims reproducible?** YES — exact commands (`pixi run bench-*`) +
    files + single-run numbers + variance band given; NOT-PROVEN metrics labelled.
47. **All architectural decisions recorded?** Substantially — ADR-001…009 cover
    simulation-independence, core-precedes-product, AMQP-as-boundary, single-node,
    linux/systemd, transport-independence, compat-measured, optimize-measured,
    flare-pinned. The audit *implies* a new ADR-0010 (negotiation-is-the-gate),
    recommended above.
48. **Remaining uncertainties visible?** YES — this file's "Remaining NOT PROVEN
    Items" + `confidence_matrix.md` NOT PROVEN rows (7) + per-report §28 confidence
    tables; nothing concealed.

---

## Recommended Next Phase

**Gate status (§33):** ARCHITECTURE PASS · CORE SEMANTICS PASS · OWNERSHIP PASS ·
TEST VALIDITY PASS · TRANSPORT PASS · CONCURRENCY EXPLICITLY DEFERRED WITH EVIDENCE ·
AMQP **PARTIALLY SATISFIED** (self-consistent codec + spec ids; **basic path now
real-client verified**, broad surface not) · REAL CLIENT INTEROP **PASS (basic
path)** — pika 1.4.4 9/9 vs our broker + 9/9 vs RabbitMQ, multi-frame body
byte-equal (`negotiation_impl.md` Update); auth/TLS/error-edge/field-tables/async-
push and deliver envelope fidelity NOT PROVEN · RABBITMQ DIFFERENTIAL **NOT PROVEN**
(only the narrow same-client basic pass captured; true error/edge differential NOT
RUN) ·
FAILURE SEMANTICS **VALIDATED (in-repo containment; process/systemd NOT PROVEN)** ·
SECURITY **BASELINE PARTIAL** (bounds+fail-closed enforced; auth/TLS/sandbox NOT
PROVEN) · SYSTEMD **NOT MET** (syntax + self-check only) · PERFORMANCE REPRODUCIBLE
BASELINE PASS (profiler-level NOT PROVEN) · DOCUMENTATION ACCURATE PASS ·
SELF-ASSESSMENT COMPLETE PASS.

**Recommendation — do NOT open a new major feature phase yet.** The gate is honest
but not fully green. Connection negotiation + content-frame reassembly landed this
session and the **basic path is real-client verified (pika 9/9)**, so interop is no
longer a hard BLOCKED — but auth/TLS, the error/edge differential, field
tables/properties, async push and the deliver envelope fidelity gap remain, and
systemd e2e + real-client performance are still gated.

**Next increment (in priority order):**
1. **Deliver/get-ok envelope fidelity (next small correctness item).** Core
   `Delivery` has no envelope read-back accessor → outgoing deliver/get-ok carry
   `exchange=''`, `routing-key=''`, `delivery_tag=0` and content-header
   property-flags=0 (audit D1). Add an envelope read-back on `Delivery`; populate
   exchange/rk, an incrementing delivery-tag and the property flags; re-run
   `pika_content.py` and assert parity with the RabbitMQ reference columns.
2. **Remaining `*_ok` / method surface:** `basic.cancel→cancel-ok`, `basic.nack`
   requeue+redelivery, `channel.close`/`connection.close→close-ok`, and qos
   *enforcement* (beyond the qos-ok reply).
3. **Error/edge differential:** run the full `pika_lifecycle.py`-style matrix against
   HyrxMQ (bad-auth 403, nack/requeue/redelivery, close handshake) — fill the §12
   HyrxMQ column beyond the narrow basic pass.
4. **Field tables / content properties on the wire** (currently 3-type dead code,
   property-flags=0).
5. **Async push-to-idle-subscriber** (only publish-before-subscribe proven).

**Pairing constraints (non-negotiable):**
- **Auth now matters immediately** — unlike the pre-negotiation state where the byte
  layer was the only reachable surface, a real client can now complete the handshake
  against a broker that accepts **any PLAIN credential** (SASL parsed, not validated).
  Ship **at least SASL-PLAIN validation + loopback default** before any external
  deployment (risk #2).
- Add the **§13 fuzzer / state-machine illegal-transition tests** now that the path
  is reachable (previously un-runnable without a handshake).
- Then attempt the **clean-machine systemd** validation (user/group via
  `sysusers.d`, listen entry, journal, stop/restart, sandbox+limits) and capture
  real-client performance numbers. Only the enumerated items above, once measured,
  may move the *broad* interoperability/systemd claims — and **never** an unqualified
  "RabbitMQ compatible".

Persistence, concurrency (Phase A event loop), and the copy-optimization
(memcpy/Candidate-C/A/B) are the *following* phases, each with its own preconditions
recorded above. Evidence outranks implementation: fix the gate, then proceed.
