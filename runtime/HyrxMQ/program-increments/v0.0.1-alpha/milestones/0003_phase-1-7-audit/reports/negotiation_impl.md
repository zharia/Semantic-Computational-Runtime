# AMQP 0-9-1 Connection Negotiation — Implementation & Real-Client Evidence (audit §36)

**Package:** HyrxMQ — connection negotiation (protocol header + start/start-ok/tune/tune-ok/open/open-ok)
**Date:** 2026-09-08
**Rule followed:** §36 — *evidence outranks code*. The acceptance gate is a **real `pika`
client** completing the handshake against the compiled binary, not a unit test alone.

## Environment / exact versions (from real runs)

| Component | Value | Source |
|-----------|-------|--------|
| Compiler | **Mojo 1.0.0 (ed45d567)** | `pixi run mojo --version` |
| Real client | **pika 1.4.4** (Python 3.14 venv `/tmp/amqp-venv`) | `pika.__version__` |
| Reference broker | RabbitMQ 4.3.5, container `node-rabbitmq`, `127.0.0.1:5672` | `docker ps` — **UP 7 hours, never touched** |
| Our broker port | **5699** (via `HYRXMQ_PORT`), `127.0.0.1` | distinct from RabbitMQ's 5672 |

## 1. Commands (exact)

```
# build the listen binary (env port already honored by main_listen.mojo)
pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen

# real-client gate: starts broker on 5699, runs pika, ALWAYS tears it down + verifies the
# port is released (scripts/interop/run_pika_negotiation.sh traps on the REAL binary PID)
bash scripts/interop/run_pika_negotiation.sh
```

## 2. Byte-level evidence (captured from the running binary, big-endian)

Protocol header echo (server replies with the SAME 8 octets the client sent):
```
client -> 414d515000000901      ("AMQP\x00\x00\x09\x01")
server -> 414d515000000901      (echoed verbatim, before connection.start)
```

`connection.start` (10,10) on channel 0 — first server frame (raw hex, 36 bytes):
```
01 0000 0000001c  000a 000a  00 09 00000000 00000005 504c41494e 00000005 656e5f5553  ce
type ch size      class meth ver ver table   len=5 "PLAIN"  len=5 "en_US"   frame-end
```
Decoded: `class_id=10 method_id=10`, version 0/9, server-properties table len=0 (empty,
spec-legal), `mechanisms(longstr)="PLAIN"`, `locales(longstr)="en_US"`.

`connection.tune` (10,30) and `connection.open-ok` (10,41) are asserted **byte-exact** by
`tests/phase7/connection_negotiation_test.mojo`:
- tune = 20 bytes; args `channel-max 0x07FF (2047)`, `frame-max 0x00020000 (131072)`,
  `heartbeat 0x0000 (0)`.
- open-ok = **13 bytes** = 7 hdr + 4 (class+method) + **1** (single empty reserved short-string)
  + 1 end. The old reply wrote an extra empty long-string (4 bytes) → 17 bytes, which
  desynchronizes a real client. **FIXED: open-ok is now exactly one reserved short-string.**

## 3. Real-pika result (pasted verbatim, HANDSHAKE GATE: PASS)

```
[PASS] connect (header/start/start-ok/tune/tune-ok/open/open-ok)  :: handshake completed in 4 ms
[PASS] channel.open  :: channel_number=1
[PASS] exchange.declare  :: direct 'hyrx.nego.x'
[PASS] queue.declare  :: queue=hyrx.nego.q msg_count=0 consumer_count=0
[PASS] queue.bind  :: hyrx.nego.x -[hyrx.key]-> hyrx.nego.q
[PASS] basic.publish  :: publish method + separate HEADER/BODY frames sent; the broker read the
                         method (empty INLINE body) and consumed the content frames WITHOUT
                         reassembling them
[FAIL] delivery received (basic_get)  :: BLOCKED (NOT IMPLEMENTED): the broker never answers
                         basic.get-ok -> basic.get deadlocks: timed out after 8s ...
[FAIL] basic.ack  :: skipped (no delivery to ack)
--------------------------------------------------------------------------------------------
HANDSHAKE GATE: PASS
teardown ok: broker <pid> gone, port 5699 released, RabbitMQ :5672 untouched
```

**A real pika 1.4.4 client now completes the full negotiation** header → connection.start →
start-ok → tune → tune-ok → open → open-ok (4 ms) and proceeds through channel.open,
exchange.declare, queue.declare, queue.bind.

## 4. How far pika reaches + what still fails (honest)

- **Handshake gate: PASS.** The negotiation itself is proven against a real client.
- `basic.publish`: the client sends `basic.publish` + separate **content HEADER(2)/BODY(3)
  frames**. The broker parses the publish *method* (Phase 7 slice reads an INLINE body → the
  routed message body is empty) and *discards* the HEADER/BODY frames without reassembling
  them. No client-side error (publish is async), but the message content is **NOT PROVEN
  through pika** — real multi-frame content reassembly is **not implemented**.
- `basic.get` / delivery / `basic.ack`: **FAIL**. `basic.get-ok` (50,40/41 reply), the content
  HEADER/BODY frames of a `basic.deliver`, and the `basic.consume` spec layout (our handler
  does not consume the leading reserved-1 short-string) are **not implemented**. A pika
  `basic_get` therefore blocks on an unanswered synchronous method. This is reported as a
  genuine gap; publish success was **not faked**.

## 5. Auth & heartbeat status

- **Auth: parsed, NOT validated.** `connection.start-ok` is decoded with
  `read_table_skip` + `read_short_string` (mechanism) + `read_long_string` (SASL PLAIN
  response) + `read_short_string` (locale). The SASL PLAIN `\0 authcid \0 passwd` response is
  split to recover the authcid for logging only (`authcid=admin` in the broker log). Any
  PLAIN credential is accepted. **No credentials are checked** (no auth backend). A
  credential-checking broker would reject `bad password`; HyrxMQ currently would not — the
  reference Rabbit *does* reject it (see interop_rabbitmq.md), so this is a known
  conformance gap, not a claim of parity.
- **heartbeat advertised = 0 (REQUIRED for the sync path).** There is **no heartbeat timer**,
  so a non-zero value would make a real client wait for heartbeats that never arrive; 0
  disables them. Non-zero heartbeats are **NOT IMPLEMENTED**.
- **channel-max advertised = 2047; frame-max = config.frame_max** (default 131072, validated
  positive; spec `frame-min-size` ≥4096 not separately clamped here — see gap below).

## 6. Files changed

| File | Change |
|------|--------|
| `src/hyrxmq/amqp_service.mojo` | `ByteReader.read_long_string`/`read_table_skip`; `write_u16`/`write_long_string`/`write_table`; `connection_start_frame`, `_reply_tune`, `_sasl_plain_authcid`; `handle_frame` START_OK→tune (state TUNE_SENT), TUNE_OK (record, no reply), OPEN; **open-ok fix** (single empty short-string); `_frame_max`. |
| `src/hyrxmq/listener.mojo` | per-slot phase machine PHASE_HEADER→HANDSHAKING→READY; header consumed **before** the codec; header echo + connection.start; open-ok detection → READY; fail-closed header-mismatch. |
| `src/hyrx/amqp/connection_state.mojo` | NOT-IMPLEMENTED header rewritten: header/start/start-ok/tune/tune-ok/open/open-ok now IMPLEMENTED; secure/close/heartbeat/frame_max-renegotiation/auth still missing. |
| `tests/integration/broker_tcp_e2e.mojo` | `do_handshake` client helper (header+start+start-ok+tune+tune-ok+open+open-ok, asserting (10,10)/(10,30)/(10,41)). |
| `tests/integration/listener_hostile.mojo` | every hostile case handshakes first; **new negative case F: bad protocol header → SERVE_FAILED, broker alive, good client still handshakes**. |

New tests: `tests/phase7/connection_negotiation_test.mojo` (3 cases: start-ok→tune exact bytes,
tune-ok no-reply+state, open→open-ok exact 13-byte length), plus the bad-header case in
listener_hostile. **`bash scripts/test_all.sh`: TOTAL pass=36 fail=0** (was 35/0; +1 negotiation
file). Bounded-parse behavior in `frame_codec`/`feed_bytes` unchanged (no regression).

## 7. Known gaps introduced/left (do not overclaim)

- `config.validate()` enforces `frame_max > 0` but not the spec `frame-min-size` of 4096; the
  small-`frame_max` hostile test (1024) is a synthetic client and tolerates it, but a real
  client requires ≥4096. NOT clamped in tune.
- frame_max/heartbeat **renegotiation** (honoring a smaller tune-ok) not implemented; the codec
  ceiling stays at the configured value.
- `connection.close`/`close-ok`, `channel.close`/`close-ok`, `basic.qos-ok`, `basic.cancel-ok`,
  `basic.get-ok`, and content-frame (HEADER/BODY) reassembly remain **NOT IMPLEMENTED**.

## 8. Cleanup / safety confirmation

- The broker subprocess is bound **only to 5699** (never 5672) and is killed **by its real PID**
  on every run (`run_pika_negotiation.sh` trap; manual runs killed via `ss ... pid=` then
  `kill -KILL <pid>`). Post-run checks confirmed `port 5699 released`.
- **RabbitMQ untouched:** `docker ps` shows `node-rabbitmq` still `Up 7 hours`; `ss` confirms
  `127.0.0.1:5672` still listening; `run_rabbit.sh` and the container were never restarted,
  stopped, or edited.

---

## Update (post content-frame implementation): NEGOTIATION + CONTENT FRAMES — MEASURED PASS

**Date:** 2026-09-08 (later same session) · **Supersedes §4/§7 above for the basic path only.**
The gaps recorded above (content HEADER/BODY not reassembled; `basic.get-ok`/`qos-ok`/
`get-empty` unimplemented; `basic.get` deadlock) are now **closed and measured**. Sections
1–8 above are retained verbatim as history.

### What changed since §4/§7 (measured)

- **Content-frame reassembly IMPLEMENTED.** Inbound `basic.publish` now consumes method +
  content-header (reads `body-size`) + N content-body frames and reassembles them (property
  bytes skipped). Outbound `basic.deliver` and `basic.get-ok` emit method + header + body
  frames. `basic.get-empty` and `basic.qos-ok` implemented. `basic.get` (sync) +
  ack-by-tag wired.

### Real-client result (pika 1.4.4 — a genuine independent AMQP client)

| Target | Command | Result |
|--------|---------|--------|
| Reference LIVE RabbitMQ 4.3.5 (`:5672`, untouched) | `/tmp/amqp-venv/bin/python scripts/interop/pika_content.py rabbit` | **9/9 PASS** (harness sanity) |
| OUR broker (`build/hyrxmq-listen`, `HYRXMQ_PORT=5699`) | `HYRXMQ_PORT=5699 /tmp/amqp-venv/bin/python scripts/interop/pika_content.py hyrx` | **9/9 PASS** — `PIKA_CONTENT(hyrx) VERDICT: PASS` |

Passing steps vs our broker: `basic_consume` delivery body byte-exact (`b'hello-hyrx'`);
`basic_get` body byte-exact; `get-empty` honored; `basic.ack` accepted; a **9000-byte body
reassembled across MULTIPLE content-body frames** (`frame_max=4096`) byte-equal. RabbitMQ
`:5672` was never touched; our broker binds only 5699 and is torn down after the run.

- Compiler **Mojo 1.0.0 (ed45d567)**; real client **pika 1.4.4** (Python 3.14 venv
  `/tmp/amqp-venv`). Regression: `bash scripts/test_all.sh` → **37 / 0** (added
  `tests/phase7/content_reassembly_test.mojo` + interop harness).

### Observed in the passing run — explicit NOT PROVEN (do not hide)

- **Envelope fidelity: NOT PROVEN.** On OUR broker the outgoing
  `basic.deliver`/`basic.get-ok` carry `exchange=''`, `routing-key=''` and
  `delivery_tag=0` (start-at-0, single value observed), whereas RabbitMQ populated
  `exchange='hyrx.content.a.x'`, `rk='hyrx.key.a'` and an incrementing delivery-tag. Cause:
  the core `Delivery` carries no envelope (exchange/routing-key/message-id) read-back —
  consistent with prior audit finding **D1** (router drops `message_id`/headers on fan-out;
  engine exposes no envelope accessor).
- **Content-header property fidelity: NOT PROVEN.** Outbound property-flags=0 — no
  `delivery_mode`/`content_type`/etc.; `message_count=0`.
- **Still NOT PROVEN (unchanged):** auth enforcement (any PLAIN accepted), TLS, full
  RabbitMQ error/edge/confirmation **DIFFERENTIAL** (only this narrow basic-path interop is
  proven; broader differential NOT RUN), AMQP field-table/property serialization on the wire,
  publisher confirms, consumer cancellation, prefetch/QoS enforcement beyond the qos-ok reply,
  and fuzzing (hand-written negative cases only). Async push-to-idle-subscriber remains
  NOT PROVEN (sync single-connection model; only publish-before-subscribe proven).
