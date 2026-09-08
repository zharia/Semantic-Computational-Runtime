# Real-AMQP-Client Interop + RabbitMQ Differential (audit §11, §12, §17, §33)

**Package:** HyrxMQ — real-client interoperability suite & RabbitMQ reference differential
**Date:** 2026-09-08
**Harness owner scope:** `src/hyrxmq/main_listen.mojo`, `scripts/interop/*`, `tests/interop/*`, this report.
No other `src/` file was created or edited (config.mojo / broker.mojo / listener.mojo / amqp_service.mojo / frame_codec.mojo left untouched). The reference RabbitMQ docker container was **not** restarted/modified/stopped and `scripts/run_rabbit.sh` was **not** edited.

---

## 0. Environment & exact versions (from real runs)

| Component | Value | Source |
|-----------|-------|--------|
| Reference broker | RabbitMQ **4.3.5** | `server_properties` over the AMQP handshake (see §2) |
| Broker platform | **Erlang/OTP 27.3.4.17** | `server_properties` |
| Broker container | `rabbitmq:4-management` / `node-rabbitmq`, host `127.0.0.1`, AMQP `5672`, mgmt `15672`, creds `admin`/`password` | `docker ps` + live connect |
| Real client | **pika 1.4.4** (Python 3.14 venv `/tmp/amqp-venv`) | `pika.__version__` |
| Compiler | **Mojo 1.0.0 (ed45d567)** | `pixi run mojo --version` |

`admin/password` verified by a live connect; `guest/guest` is **refused** by the broker (`(403) ACCESS_REFUSED - Login was refused using authentication mechanism PLAIN`), confirming auth is actually enforced.

---

## 1. Port override (§11 unblock, also serves §17 env override) — in `main_listen.mojo` ONLY

The reference RabbitMQ owns TCP 5672, so the HyrxMQ listen binary must bind elsewhere **without** editing `config.mojo` (owned by another package). Smallest change: endpoint resolution moved into `main_listen.mojo`.

Precedence implemented:
```
port:  $HYRXMQ_PORT   ->   argv[1] int   ->   5673   (hardcoded fallback)
host:  $HYRXMQ_HOST   ->   127.0.0.1     (loopback default; config.mojo's 0.0.0.0 default is narrowed here so the probe client reaches it on 127.0.0.1)
```
- `Int(env)` on a malformed value **raises** (fail-loud: never silently bind the wrong port).
- Uses `std.os.getenv` / `std.sys.argv` (Mojo stdlib). **flare is not imported directly**; the socket still comes from `AMQPListener -> hyrx.transport.tcp` (transport contract, ADR-0005).
- `cfg.validate()` is now called so an out-of-range port is rejected before bind.
- This env override is the same lever §17 (environment-driven configuration) asks for.

Diff: `git diff --stat` → `src/hyrxmq/main_listen.mojo | 30 ++++++++++++++++++` (1 file, +30 lines, 0 deletions; no other `src/` change is mine).

Real resolution checks (binary launched, `"listening on ..."` line captured, process killed each time):

```
no env, no argv (=5673)      -> HyrxMQ hyrxmq@localhost listening on 127.0.0.1:5673
HYRXMQ_PORT=5699             -> HyrxMQ hyrxmq@localhost listening on 127.0.0.1:5699
argv=5711                    -> HyrxMQ hyrxmq@localhost listening on 127.0.0.1:5711
env5723 overrides argv5711   -> HyrxMQ hyrxmq@localhost listening on 127.0.0.1:5723
bad HYRXMQ_PORT (fail-loud)  -> Unhandled exception ... 'String is not convertible to integer with base 10: notanumber'  (no bind)
```

Build command (compiles clean; only pre-existing flare/listener deprecation warnings):
```
pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen
```

---

## 2. RabbitMQ reference baseline — `scripts/interop/pika_lifecycle.py` (MUST pass)

Exercises the §11 lifecycle with a real pika client against `127.0.0.1:5672` and prints a per-step table. Exit 0 iff every step PASS (a real gate, not print-and-hope).

Command:
```
/tmp/amqp-venv/bin/python scripts/interop/pika_lifecycle.py
```

**Real output (run twice, identical 18/18):**
```
HyrxMQ interop REFERENCE baseline
  client : pika 1.4.4
  broker : 127.0.0.1:5672 vhost='/'
[PASS] connect  :: in 5 ms; server=RabbitMQ v4.3.5 (Erlang/OTP 27.3.4.17)
[PASS] authenticate (negative)  :: refused via ProbableAuthenticationError
[PASS] open vhost '/'  :: vhost='/'
[PASS] channel.open  :: channel_number=1
[PASS] exchange.declare  :: direct 'hyrx.interop.x'
[PASS] queue.declare  :: msg_count=0 consumer_count=0 (exclusive)
[PASS] queue.bind  :: hyrx.interop.x -[hyrx.key]-> hyrx.interop.q
[PASS] basic.publish  :: body-A
[PASS] basic.consume  :: auto_ack=False, inactivity_timeout=3s
[PASS] delivery received  :: body=b'body-A' exchange='hyrx.interop.x' rk='hyrx.key' redelivered=False
[PASS] basic.ack  :: delivery_tag=1
[PASS] prefetch/QoS (basic.qos)  :: prefetch_count=10
[PASS] delivery received (B, pre-nack)  :: body=b'body-B'
[PASS] basic.nack(requeue=True)  :: delivery_tag=2
[PASS] redelivery observed  :: body=b'body-B' redelivered=True
[PASS] channel.close  :: closed
[PASS] connection.close  :: closed
[PASS] reconnect  :: reconnected (fresh conn+channel)

===================== BASELINE RESULT TABLE =====================
STEP                              STATE  DETAIL
------------------------------------------------------------------------------
connect                           PASS   in 5 ms; server=RabbitMQ v4.3.5 (Erlang/OTP 27.3.4.17)
authenticate (negative)           PASS   refused via ProbableAuthenticationError
open vhost '/'                    PASS   vhost='/'
channel.open                      PASS   channel_number=1
exchange.declare                  PASS   direct 'hyrx.interop.x'
queue.declare                     PASS   msg_count=0 consumer_count=0 (exclusive)
queue.bind                        PASS   hyrx.interop.x -[hyrx.key]-> hyrx.interop.q
basic.publish                     PASS   body-A
basic.consume                     PASS   auto_ack=False, inactivity_timeout=3s
delivery received                 PASS   body=b'body-A' exchange='hyrx.interop.x' rk='hyrx.key' redelivered=False
basic.ack                         PASS   delivery_tag=1
prefetch/QoS (basic.qos)         PASS   prefetch_count=10
delivery received (B, pre-nack)  PASS   body=b'body-B'
basic.nack(requeue=True)         PASS   delivery_tag=2
redelivery observed               PASS   body=b'body-B' redelivered=True
channel.close                     PASS   closed
connection.close                  PASS   closed
reconnect                         PASS   reconnected (fresh conn+channel)
------------------------------------------------------------------------------
TOTAL 18   PASS 18   FAIL 0
BASELINE VERDICT: PASS
```
**Baseline verdict: PASS (18/18).** Harness validated; correct AMQP behavior captured (note the genuine `redelivered=True` flag after nack-with-requeue).

**Real RabbitMQ 4.3.5 behavior discovered during authoring:** a transient **non-exclusive** queue is now **rejected** —
`ConnectionClosedByBroker: (541, 'INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated. By default, this feature is not permitted anymore.')`.
The harness uses an **exclusive** queue (permitted, auto-cleaned) to reflect current broker policy; verified no leftover `hyrx.interop.*` artifacts on the broker after the run (passive re-declare → `ChannelClosedByBroker`). This is a *RabbitMQ-behavior* fact for §12, not a HyrxMQ gap.

---

## 3. HyrxMQ under the SAME client — `scripts/interop/hyrx_probe.py` (failure evidence)

Starts `build/hyrxmq-listen` as a subprocess with `HYRXMQ_HOST=127.0.0.1 HYRXMQ_PORT=<freeport>`, waits for bind, then points the real client at it. Subprocess is always killed (try/finally); post-kill port-release is asserted.

Command:
```
/tmp/amqp-venv/bin/python scripts/interop/hyrx_probe.py
```
**Real output (reproducible; exit code 4 = BLOCKED-as-expected):**
```
HyrxMQ interop probe
  binary  : .../build/hyrxmq-listen
  port    : 5699 (chosen free)
  broker  : pid=2801499 ready=True (accepted)

--- STEP A: real client, raw AMQP protocol header ---
   tcp_connect_ms:        0
   tcp_connect:           OK
   broker_preheader_bytes: b''
   after_header:          closed (EOF)
   header_response:       (none/EOF)

--- STEP B: pika BlockingConnection full handshake ---
   pika_version:          1.4.4
   exc_type:              IncompatibleProtocolError
   exc_msg:               StreamLostError: ('Transport indicated EOF',)
   stage:                 method (header sent, no connection.start reply)

--- VERDICT ---
   TCP connect            : REACHED
   AMQP protocol header    : sent by client, NO connection.start from broker
   Failure stage           : method (header sent, no connection.start reply)
   -> HyrxMQ does NOT implement connection negotiation;
      a real AMQP client cannot complete the handshake.

--- BROKER STDERR ---
(empty)
--- broker held port 5699? post-kill check ---
   port released (OK)

PROBE EXIT CODE: 4  (0=unexpected-pass, 4=blocked-as-expected)
```

### Exact failure point
- **TCP connect: REACHED.** The HyrxMQ listener `accept()`s the socket (transport works — consistent with the passing `broker_tcp_e2e` frame-level integration tests).
- **Protocol header / first-method: the handshake dies here.** The client writes the 8-octet header `AMQP\x00\x00\x09\x01` and then blocks waiting for the broker's `connection.start`. The broker sends **no bytes**, then **closes the socket (EOF)**. pika surfaces this as `IncompatibleProtocolError: StreamLostError ('Transport indicated EOF')`.
- **Cause (one line):** HyrxMQ never consumes the 8-octet protocol header and never originates `connection.start`/SASL negotiation; it hands the header straight to the frame codec (`try_parse_frame`), which cannot parse 8 raw header octets as a framed method and (fail-closed) closes the per-connection socket. Broker stays alive (stderr empty, process survives) — matches the design in `amqp_service.mojo` lines 26–29 ("NOT IMPLEMENTED: connection negotiation: the 8-octet protocol header, SASL connection.start/start-ok/secure/secure-ok and tune/tune-ok ... close/close-ok").

No port is left held: post-kill check prints `port released (OK)` on every run.

---

## 4. Differential matrix (§12)

Legend for **HyrxMQ-result**:
- `REACH` — client observes the same success as RabbitMQ
- `BLOCKED@<stage>` — a real client cannot get here (dies earlier in the handshake)
- `FRAME-LEVEL-OK` — the method is dispatched by `AMQPService.handle_frame` in unit/e2e tests (synthetic frames), but **not reachable by a real client** until negotiation exists
- `GAP` — not implemented at all (deliberate, honest)
- `EXT(n/a)` — RabbitMQ-only extension; matching it is **not** an AMQP correctness requirement

Classification: **AMQP-requirement** (0-9-1 mandates it), **RabbitMQ-behavior** (this reference build's policy), **RabbitMQ-extension** (not in 0-9-1 core), **Hyrx-deliberate-gap** (documented representation/scope choice).

| Operation | RabbitMQ 4.3.5 result | HyrxMQ result (real client) | Class | Status |
|-----------|-----------------------|-----------------------------|-------|--------|
| TCP connect | accepted | **REACH** (accepted) | transport | ✅ MATCH |
| AMQP 8-octet protocol header | parsed, drives start | `BLOCKED@header` — header not consumed → EOF | **AMQP-requirement** | ❌ HyrxMQ fails a REQUIREMENT (the blocker) |
| connection.start / start-ok (SASL PLAIN) | full SASL negotiation | `BLOCKED` — never sent | **AMQP-requirement** | ❌ REQUIREMENT missing |
| Bad-credentials rejection (403) | refused via PLAIN | `BLOCKED` (no auth layer reached) | **AMQP/SASL requirement** | ❌ REQUIREMENT missing |
| tune / tune-ok (frame_max, heartbeat) | server tunes, enforces | tune-ok handled frame-level; server never sends tune; no enforcement | **AMQP-requirement** | ⚠️ partial/unreachable |
| connection.open (vhost "/") | vhost routed | `FRAME-LEVEL-OK` (single configured vhost) | **AMQP-requirement** (vhost) | ⚠️ unreachable via real client |
| channel.open | channel opened | `FRAME-LEVEL-OK` | **AMQP-requirement** | ⚠️ unreachable via real client |
| exchange.declare (direct) | declared | `FRAME-LEVEL-OK`; arguments/field-table not parsed | AMQP-requirement (+ field-table sub-gap) | ⚠️ partial |
| queue.declare | declared (transient non-exclusive **rejected 541**) | `FRAME-LEVEL-OK`; passive/durable/exclusive/auto-delete bits not read | **RabbitMQ-behavior** for the 541; AMQP-req for declare | ⚠️ partial; 541 is broker policy, not a HyrxMQ gap |
| queue.bind | bound | `FRAME-LEVEL-OK` | AMQP-requirement | ⚠️ unreachable via real client |
| basic.publish | multi-frame header/body | `FRAME-LEVEL-OK` (inline-body vertical slice, no content frames) | **Hyrx-deliberate-gap** | ⚠️ representation choice |
| basic.consume + delivery | push consumer, short-string consumer-tag | `FRAME-LEVEL-OK` (pull-on-subscribe; consumer tag = numeric engine id) | Hyrx-deliberate-gap + AMQP-req (consumer-tag) | ⚠️ partial |
| basic.ack | ack (supports multiple=true) | `FRAME-LEVEL-OK`; multiple=true not honored | AMQP-requirement | ⚠️ partial |
| prefetch / basic.qos → qos-ok | honored, qos-ok sent | `GAP` — no qos-ok reply, unenforced | **AMQP-requirement** | ❌ HyrxMQ fails a REQUIREMENT (must answer qos-ok) |
| basic.nack (requeue) | requeued; redelivery flagged | `GAP` — not dispatched | **AMQP 0-9-1 core** (widely relied on) | ❌ REQUIREMENT missing |
| basic.cancel → cancel-ok (consumer cancel) | cancels, cancel-ok | `GAP` — no cancel-ok reply | **AMQP-requirement** | ❌ REQUIREMENT missing |
| publisher confirms (confirm.select + broker ack) | RabbitMQ supports | `GAP` | **RabbitMQ-extension** | ➖ EXT(n/a) — HyrxMQ need NOT match to be 0-9-1-correct |
| channel.close / connection.close → *_ok | graceful handshake, *_ok | `GAP` (listener detects close bytes but sends no close-ok) | **AMQP-requirement** | ❌ REQUIREMENT missing |
| reconnect | fresh working session | `BLOCKED@header` | AMQP-requirement (transitive) | ❌ cannot reach |

### Where a difference matters vs where it does not
- **AMQP REQUIREMENTS HyrxMQ currently fails (real correctness gaps):** protocol-header recognition, SASL start/start-ok, tune round-trip, `basic.qos`→qos-ok enforcement, `basic.nack`, `basic.cancel`→cancel-ok, `channel.close`/`connection.close`→close-ok. A conformant AMQP-0-9-1 peer MUST be able to complete these.
- **RabbitMQ EXTENSIONS HyrxMQ need not match:** publisher confirms (`confirm.select`) — absent from 0-9-1 core, so its absence is not a conformance failure. (`basic.nack` is often grouped with extensions but is present in the 0-9-1 core set, so it is classified as a requirement gap above.)
- **RabbitMQ BEHAVIOR (policy), not a HyrxMQ gap:** the 4.3.5 rejection of transient non-exclusive queues (541) — HyrxMQ has no such policy and is not required to.
- **Hyrx-deliberate gaps (documented scope choices):** inline-body publish (no multi-frame content reassembly), pull-on-subscribe delivery, numeric consumer tags, unparsed field-tables. These are representation/scope decisions, listed honestly — not hidden failures — but each still blocks full 0-9-1 conformance once the handshake lands.

---

## 5. Gate status (§11, §12 — audit §33)

### §11 Real-client interop — **EXPLICITLY BLOCKED**
Evidence: `hyrx_probe.py` STEP A/B — TCP connects (`tcp_connect: OK`), client sends `AMQP\x00\x00\x09\x01`, broker replies nothing and EOFs; pika raises `IncompatibleProtocolError: StreamLostError ('Transport indicated EOF')`. Broker stays alive (stderr empty). This is a documented, precise block — **not** a silent skip and **not** a false PASS.

### §12 RabbitMQ differential — **EXPLICITLY BLOCKED** (matrix above is a *partial* differential)
The reference baseline (`pika_lifecycle.py`) passes 18/18, establishing the correct-behavior column. The HyrxMQ column cannot be filled by a *real client* beyond `REACH@TCP` because negotiation is absent. The frame-level handlers exist (proven by `tests/integration/broker_tcp_e2e.mojo`), but a real client cannot exercise them. So the differential is honestly recorded as **blocked-at-negotiation**, not fabricated as PASS.

*(Note: audit §32 satisfied — every number/log line above is from an actual run pasted verbatim; nothing is estimated.)*

---

## 6. To unblock real-client interop (BLOCKED → PASS)

Minimal set, in handshake order (all owned by other packages — **reported, not edited here**):

1. **Consume the 8-octet protocol header** (`AMQP\x00\x00\x09\x01`) before any frame parsing in the accept path (`listener`/`amqp_service`), and reply by originating `connection.start`.
2. **SASL PLAIN handler + `connection.start` → `start-ok`** (advertise mechanisms, accept PLAIN, validate credentials, send `connection.start-ok`) — this is what makes the negative-auth (403-on-bad-password) behavior observable and is an AMQP/SASL requirement.
3. **`connection.tune` → `tune-ok`** round trip with real `frame_max`/`heartbeat`/`channel_max` negotiation (today `tune-ok` is accepted but the server never sends `tune`; frame_max is a fixed config ceiling).
4. **`connection.open` → `connection.open-ok`** on the negotiation path (currently dispatched only for synthetic frames; must be gated after tune) and **`channel.open` → `channel.open-ok`** so a real channel can be established.
5. **Required synchronous `*_ok` replies** for the currently-silent methods so a real client doesn't hang: `basic.qos → qos-ok`, `basic.cancel → cancel-ok`, `basic.nack` handling (requeue+redelivery), and `channel.close`/`connection.close → close-ok`. (Publisher confirms = optional RabbitMQ-extension, deferrable.)

After items 1–4 a real pika client completes connect→auth→tune→open→channel.open and the §12 HyrxMQ column can be filled for the frame-level methods; after item 5 the full §11 lifecycle (including qos/nack/cancel/close) can run end-to-end.

---

## 7. Regression / hygiene

- `bash scripts/test_all.sh` (via `pixi run`): **35 PASS / 0 FAIL**, exit 0. The suite traverses only `tests/phase0..phase7/**/*.mojo` + `tests/integration/*.mojo` — it does **not** traverse `scripts/interop/` or `tests/interop/` (verified: `find … | grep interop` → none). No hanging test was added to the gate; all new interop code is out-of-band Python harnesses. (Current tree reports 35, one more than the 34 mentioned in the brief — a pre-existing/parallel-package test file; none of the delta is from this package.)
- Docker: untouched — `docker ps` shows `node-rabbitmq Up 6 hours` (no restart within session); `scripts/run_rabbit.sh` unmodified.
- File ownership respected: only `src/hyrxmq/main_listen.mojo` changed (+30), and only `scripts/interop/pika_lifecycle.py`, `scripts/interop/hyrx_probe.py` created. No subprocess left bound to a port (post-kill check `port released (OK)` every run).
