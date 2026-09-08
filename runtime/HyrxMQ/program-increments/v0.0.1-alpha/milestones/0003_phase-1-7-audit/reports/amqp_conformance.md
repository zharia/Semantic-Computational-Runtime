# AMQP 0-9-1 Conformance Audit — HyrxMQ (Audit §10)

**Scope:** read-only conformance research + implementation audit. Groundwork for §13 (negative/fuzz) and §25 (delivery review). No source files modified except this report.
**Method:** claims derived from authoritative specs (below), not memory (audit §32 / §10 "Do not infer protocol behavior from memory").

---

## 0. Sources (exact URLs — cite per claim)

| ID | Source | URL | Used for |
|----|--------|-----|----------|
| S1 | AMQP 0-9-1 machine-readable XML schema | https://www.rabbitmq.com/resources/specs/amqp0-9-1.xml | frame-type constants, frame-end, class/method **indices**, domain types, per-method **field lists** |
| S2 | AMQP 0-9-1 prose spec (RabbitMQ-hosted PDF) | https://www.rabbitmq.com/resources/specs/amqp0-9-1.pdf | §2.3.4 protocol header, §2.3.5.1 frame layout, §2.3.5.2 **content-header byte layout** |
| S3 | RabbitMQ "Protocol Extensions" | https://www.rabbitmq.com/docs/extensions | which features are RabbitMQ extensions vs AMQP |
| S4 | RabbitMQ "Confirms / Consumer Acks" | https://www.rabbitmq.com/docs/confirms | `basic.nack` is an extension; `multiple` bit; publisher confirms |
| S5 | rabbitmq AMQP 0-9-1 reference (generated from S1) | https://github.com/rabbitmq/amqp-0-9-1-spec/blob/main/docs/amqp-0-9-1-reference.md | method parameter detail (tune, open) |

**Key normative facts used:**
- Frame types / constants (S1): `frame-method=1, frame-header=2, frame-body=3, frame-heartbeat=8, frame-end=206 (=0xCE), frame-min-size=4096`.
- Frame layout (S2 §2.3.5.1): `type(1) + channel(2) + size(4) + payload(size) + frame-end(1)`; `size` = payload length only.
- Content-header layout (S2 §2.3.5.2), verbatim:
  `class-id(short) | weight(short,=0) | body-size(long long) | property-flags(short) | property-list...`
- `basic.nack`, publisher confirms (`confirm.*`), blocked connections, consumer cancellation, consumer priorities, direct reply-to = **RabbitMQ extensions, not AMQP 0-9-1** (S3/S4). `basic.nack` is not in the S1 schema (grep count 0).

Implementation files audited: `src/hyrx/amqp/{constants,frame_codec,field_table,connection_state,adapter}.mojo`, `src/hyrxmq/{amqp_service,listener}.mojo`.

---

## LAYER 1 — Protocol encoding correctness

### 1.1 Frame format (outer envelope) — **CORRECT**
`frame_codec.mojo:66-104` parses `type(1)+channel(2 BE)+size(4 BE)` then requires `7+size+1` bytes, extracts `payload[7 .. 7+size)`, verifies end octet `== 0xCE`. Matches S2 §2.3.5.1 and S1 `frame-end=206`. `FRAME_END()=0xCE` (`constants.mojo:29-30`) is correct (206 = 0xCE). Encoders (`encode_method_frame` 106-136, `encode_body_frame` 177-199, `encode_heartbeat` 201-213) emit the correct envelope. **No deviation** at the envelope layer.

### 1.2 Method-ID encoding — **WRONG (headline bug)**
`constants.mojo:32-113` encodes **connection-class and channel-open method IDs with a sequential numbering (1,2,3,4,5,6,10,11) instead of the spec's decimal indices (10,11,30,31,40,50,51)**. Verified against S1 method `index=` attributes:

| Class | Method | Spec index (S1) | `constants.mojo` | Correct? |
|-------|--------|-----------------|------------------|----------|
| connection | start | **10** | `MethodID(10,1)` (L34) | ✗ |
| connection | start-ok | **11** | `MethodID(10,2)` (L37) | ✗ |
| connection | secure / secure-ok | 20 / 21 | absent | — |
| connection | tune | **30** | `MethodID(10,3)` (L40) | ✗ |
| connection | tune-ok | **31** | `MethodID(10,4)` (L43) | ✗ |
| connection | open | **40** | `MethodID(10,5)` (L46) | ✗ |
| connection | open-ok | **41** | `MethodID(10,6)` (L49) | ✗ |
| connection | close | **50** | `MethodID(10,10)` (L52) | ✗ |
| connection | close-ok | **51** | `MethodID(10,11)` (L55) | ✗ |
| channel | open | **10** | `MethodID(20,1)` (L59) | ✗ |
| channel | open-ok | **11** | `MethodID(20,2)` (L62) | ✗ |
| channel | close / close-ok | 40 / 41 | `MethodID(20,40)/(20,41)` (L65,L68) | ✓ |
| exchange | declare / declare-ok | 10 / 11 | `(40,10)/(40,11)` | ✓ |
| queue | declare/declare-ok/bind/bind-ok | 10/11/20/21 | `(50,10/11/20/21)` | ✓ |
| basic | consume/consume-ok | 20/21 | `(60,20/21)` | ✓ |
| basic | cancel/cancel-ok | 30/31 | `(60,30/31)` | ✓ (encoded only) |
| basic | publish / deliver | 40 / 60 | `(60,40)/(60,60)` | ✓ |
| basic | ack | 80 | `(60,80)` | ✓ |
| basic | nack | *not in AMQP* (RabbitMQ ext=120) | `(60,120)` (L101) | ext only |

**Consequence:** `amqp_service.mojo:221-227` dispatches on `CONNECTION_OPEN()`=(10,**5**) and `CONNECTION_TUNE_OK()`=(10,**4**); the reply frames emit the same wrong IDs (`_reply_open` → (10,6)). A real client sends `connection.open` as class 10 method **40**; the broker's matcher never fires → falls to "unhandled method: no reply" (`amqp_service.mojo:306-307`). **Handshake is impossible with any spec-conformant client.** The self-tests assert the buggy values (`tests/phase6/amqp_constants_test.mojo:21-34` checks `CONNECTION_OPEN()==MethodID(10,5)`), so the bug is **baked into the test oracle** — a direct violation of audit rule 11 ("Test contracts, not merely implementations"). This report is the first place the wrongness is recorded against S1.

### 1.3 Content-header frame — **WRONG (missing `weight`, misaligned offset)**
Per S2 §2.3.5.2 the header payload is `class-id(short) weight(short) body-size(longlong) property-flags(short) props`.
- `encode_header_frame` (`frame_codec.mojo:152-169`): writes `class-id(2) + body-size(8) + props` — **omits the 2-byte `weight` field entirely** and never emits a separate `property-flags` short (assumes caller packs it into `properties`). Encoded header frames are malformed relative to the spec.
- `parse_header_frame_payload` (`frame_codec.mojo:228-248`): reads `class-id=payload[0:2]` then `body_size=payload[2:10]`. Because `weight` occupies `payload[2:4]`, `body_size` is read from the **wrong offset** (weight + first 6 body-size bytes). Struct `HeaderFrame` (`frame_codec.mojo:41-50`) has no `weight` field.
- Note: this whole header/body path is **unused by the broker** (see L3 — publish/deliver use inline body), so the bug is latent, not currently on the happy path.

### 1.4 Field table / basic types — **PARTIAL + DEAD CODE**
`field_table.mojo` supports only three value types: `'S'` long-string (4-byte length, L138-147), `'I'` signed 32-bit BE (L148-153), `'t'` bool (L154-158). Encoding for those three matches S1 domain types. **Missing** all other spec/RabbitMQ table types: octet `b`, short `s`, long-long `l`, float `f`, double `d`, decimal `D`, timestamp `T`, nested table `F`, field-array `A`, void `V`, byte-array `x`. No field-array implementation at all.
- Table length uses 4-byte `long` prefix (`to_bytes` L160-165, `from_bytes` L179-184) — matches spec `table = long + entries`. ✓ for the supported subset.
- **Robustness:** `from_bytes` on an unrecognized type octet does `break` (L244-245) — a malformed table is **silently truncated**, no error raised.
- **DEAD CODE:** `field_table.mojo` is **never imported anywhere in `src/`** (grep: 0 importers). Therefore the wire path **never encodes or parses any field table** — `connection.start` server-properties, `peer-properties`, exchange/queue `arguments`, and basic message `headers` are all absent from the protocol path.

### 1.5 String encoding — **truncation hazard**
Short-string writer casts length to `UInt8(len(b))` (`amqp_service.mojo:72`; `field_table.mojo:131`); names/keys/strings > 255 octets silently corrupt. `read_short_string` (`amqp_service.mojo:126-135`) reads a 1-byte length but advances `pos` past the end without error when `pos+j>=len` (pads, keeps counting) — lenient, not spec-strict.

---

## LAYER 2 — Protocol state-machine correctness

- **AMQP protocol header not handled.** S2 §2.3.4 requires the client to first send the 8-octet header `AMQP\0\0\x09\x01`; the server replies with its own. `listener.mojo:107-115` feeds raw socket bytes straight into `AMQPFrameCodec.try_parse_frame()`; no header detection exists anywhere in `src/` (grep: none). A real client's header octets are parsed as a frame → protocol error before any method.
- **Server negotiation never initiated.** `connection.start`/`connection.secure` are **never sent** by the service; `connection.tune` is **never sent**. `amqp_service.mojo:221-227` only reacts to `open` (wrong id) and swallows `tune-ok`. The state machine (`connection_state.mojo`) defines TUNE_SENT/TUNE_RECEIVED/START_* states but `negotiate()` (`connection_state.mojo:71-76`, the only code that sets `TUNE_RECEIVED`) **is never called**.
- **No transition validation.** `set_state()` (`connection_state.mojo:62-66`) accepts any state; nothing checks that `open` arrives after `tune-ok`, or that methods on channel 0 precede channel.open, or that connection is OPEN before channel/exchange/basic methods. A client may send `basic.publish` as its first frame and the broker will process it.
- **Channel state machine inert.** `CHANNEL_OPEN` (`amqp_service.mojo:230-238`) replies `open-ok` but **stores no channel state**; there is no per-channel registry (consumers keyed by `conn_id` only, `amqp_service.mojo:150`, 287). `AMQPChannelState` is only exercised in unit tests, never in the dispatch path. `channel.close`/`close-ok` are **never handled** by the service (no branch; fall to L306).
- **Close semantics incomplete.** `connection.close` is detected only in `listener.mojo:119-135` as "close the socket" glue (again on the wrong method id); the broker **never replies `close-ok`**, and `connection.close`/`close-ok` state transitions are unenforced.
- **frame_max / heartbeat unenforced.** Negotiated limits (`connection_state.mojo:49-57`) are stored but never consulted; `encode_heartbeat` is never called; no heartbeat send/receive logic (spec §2.3.5.6 / S1 heartbeat). 

Summary: a state-machine **shape** exists; the **enforcement** and the **server-initiated handshake** do not. Legal-transition enforcement: **absent.**

---

## LAYER 3 — Broker semantic correctness (implemented methods)

Field lists verified against S1. Arg parsing uses `ByteReader` (`amqp_service.mojo:82-142`).

| Method | Handler | Semantic finding |
|--------|---------|------------------|
| `connection.open` (10,40) | L221-225 | Sets state OPEN, replies `open-ok`. **Ignores** client `virtual-host`, `capabilities`, `reserved-2` (never reads them). Reply adds a stray long-string (`_reply_open` L358-368); S1 `open-ok` has only `reserved-1:shortstr`. Wrong id → unreachable. |
| `connection.tune-ok` (10,31) | L226-227 | Consumed, no reply — but never preceded by `tune`, wrong id. |
| `channel.open` (20,10) | L230-238 | Replies `open-ok` (empty longstr field ≈ correct per S1 `channel.open-ok: reserved-1:longstr`). Wrong id; no channel recorded. |
| `exchange.declare` (40,10) | L241-251 | Reads reserved-1 ✓, name, type. Maps direct/fanout/topic; **unknown type silently falls back to `direct`** (`adapter.mojo:33-35`) — `headers`/`x-*` types become wrong type, no error. Ignores `passive/durable/auto-delete/no-wait/arguments`. **Always replies declare-ok even when client set `no-wait`** → violates S1 `no-wait` ("do not send reply method"). Return value of `declare_exchange` discarded. |
| `queue.declare` (50,10) | L254-258 | Reads reserved-1 ✓, name. Ignores `passive/durable/exclusive/auto-delete/no-wait/arguments`; fixed capacity 1024 (`adapter.mojo:42`). Always replies declare-ok (no-wait violation). |
| `queue.bind` (50,20) | L261-272 | Reads reserved-1, queue, exchange, routing-key ✓. Ignores no-wait/arguments. Correct mapping to router.bind_queue. |
| `basic.publish` (60,40) | L275-281 | Reads reserved-1, exchange, routing-key, then **treats all remaining bytes as inline body** — so the `mandatory`/`immediate` **bits octet is prepended to the body** (spurious leading byte). `mandatory` ignored → **no `basic.return`** path for unroutable messages. Content header/body frames ignored → a spec-conformant publish (method+header+body) delivers a **zero-length body**. Documented inline-body slice choice (`amqp_service.mojo:11-17`), but it is a wire deviation. |
| `basic.consume` (60,20) | L284-297 | **Does not skip `reserved-1` short** before the queue name (`amqp_service.mojo:285` reads `read_short_string()` as queue). Real consume = `reserved-1(short) queue(shortstr) …`, so the queue name is **mis-parsed** (reads length byte from reserved-1 → wrong/empty name). Ignores `no-local/no-ack/exclusive/no-wait/arguments`. `no-ack` consumers still require ack. Always replies `consume-ok` even under `no-wait`. |
| `basic.deliver` (60,60) | L311-344 | Emits `consumer-tag(shortstr) delivery-tag(longlong) redelivered(octet) exchange(shortstr) routing-key(shortstr) body-inline`. `exchange` and `routing-key` **hardcoded empty** (L331-332) — delivery metadata wrong. As a content method it **must be followed by content header + body frames** (S1/S2 §2.3.5.2); broker inlines body instead. See §25 review. |
| `basic.ack` (60,80) | L300-304 | Reads `delivery-tag(longlong)` ✓ then `read_octet()` and uses it as the **consumer id** (L302-303). S1 `basic.ack` = `delivery-tag(longlong) multiple(bit)` — there is **no consumer-id field**; the broker conflates the `multiple` batch bit with a Hyrx consumer id → acks routed to wrong/nonexistent consumer. `multiple` batching unsupported. |
| `basic.cancel`/`cancel-ok` | constants only | Encoded; **no dispatch branch** → unhandled. |
| `basic.nack`/`reject` | constants + `adapter.reject` | `reject` exists in adapter (`adapter.mojo:91-95`) but service dispatch never calls NACK/REJECT. `nack` is a RabbitMQ extension (S3/S4), not required for AMQP conformance. |
| unknown / unimplemented method | L306-307 | **Silently no reply.** S1 hard-error `not-implemented=540` / `command-invalid=503` / `unexpected-frame=505` are defined (`constants.mojo:119-126` defines 502/540/541) but never raised. An unimplemented *synchronous* method should reply `connection.close`/`channel.close` with 540 — missing. |

`tx` class (90) and RabbitMQ `confirm` class: **entirely absent** (grep: 0).

**Adapter-level semantic notes:** routing key carried, but `Envelope` uses `MessageID(0)` always (`adapter.mojo:55`); exchange `durable` flag discarded (`adapter.mojo:36` passes only name+type); `declare_queue` fixed cap 1024.

---

## LAYER 4 — RabbitMQ interoperability — **NOT TESTED**

No real AMQP client has been run against HyrxMQ. Based on L1–L3 the expected result is **handshake failure** (no protocol-header handling, server never sends `connection.start`, all connection method-IDs wrong). This layer stays **NOT TESTED**; §11/§12 must verify *after* the ID + handshake fixes, using at least one genuine client (pika / amqplib / RabbitMQ Java) across connect→auth→open vhost→channel→declare→bind→publish→consume→deliver→ack→close→reconnect, plus prefetch/QoS, redelivery, consumer cancellation, multiple consumers/channels, connection failure (§11 list). Differential against RabbitMQ reference (§12). No "AMQP compatible" claim may be made until then (audit §10/§11).

---

## §10 Compatibility matrix

Legend — Encoded = method id present & spec-correct in `constants.mojo`; State-machined = handshake/transition enforced; Broker-handled = dispatch branch exists and maps to Hyrx; Ext = RabbitMQ extension vs AMQP.

| Class.Method | In spec? | Encoded? | State-machined? | Broker-handled? | Classification | AMQP vs Ext | Evidence |
|---|---|---|---|---|---|---|---|
| connection.start | Yes (10,10) | ✗ id (10,1) | ✗ never sent | ✗ | NOT IMPLEMENTED | AMQP | constants.mojo:33-34; amqp_service (no send) |
| connection.start-ok | Yes (10,11) | ✗ id (10,2) | ✗ | ✗ | NOT IMPLEMENTED | AMQP | constants.mojo:36-37 |
| connection.secure / -ok | Yes (10,20/21) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant |
| connection.tune | Yes (10,30) | ✗ id (10,3) | ✗ never sent | ✗ | NOT IMPLEMENTED | AMQP | constants.mojo:39-40 |
| connection.tune-ok | Yes (10,31) | ✗ id (10,4) | ✗ | accept-noop (L226) | NOT IMPLEMENTED | AMQP | constants.mojo:42-43 |
| connection.open | Yes (10,40) | ✗ id (10,5) | ✗ | yes (L221) but unreachable | PARTIALLY SUPPORTED | AMQP | constants.mojo:45-46; amqp_service:221 |
| connection.open-ok | Yes (10,41) | ✗ id (10,6) | ✗ | emitted (L358) | PARTIALLY SUPPORTED | AMQP | amqp_service:358-368 |
| connection.close | Yes (10,50) | ✗ id (10,10) | partial (socket) | socket-glue only (L119) | PARTIALLY SUPPORTED | AMQP | constants.mojo:51-52; listener:119-135 |
| connection.close-ok | Yes (10,51) | ✗ id (10,11) | ✗ | ✗ never sent | NOT IMPLEMENTED | AMQP | constants.mojo:54-55 |
| channel.open | Yes (20,10) | ✗ id (20,1) | ✗ (no store) | yes (L230) | PARTIALLY SUPPORTED | AMQP | constants.mojo:58-59 |
| channel.open-ok | Yes (20,11) | ✗ id (20,2) | ✗ | emitted | PARTIALLY SUPPORTED | AMQP | amqp_service:230-238 |
| channel.flow / -ok | Yes (20,20/21) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant |
| channel.close / -ok | Yes (20,40/41) | ✓ | ✗ | ✗ (no branch) | NOT IMPLEMENTED | AMQP | constants.mojo:64-68 (id ok, no dispatch) |
| exchange.declare | Yes (40,10) | ✓ | ✗ | yes (L241) | PARTIALLY SUPPORTED | AMQP | amqp_service:241-251 (ignores flags/no-wait) |
| exchange.declare-ok | Yes (40,11) | ✓ | ✗ | yes | PARTIALLY SUPPORTED | AMQP | always-on (no-wait violation) |
| exchange.delete / -ok | Yes (40,20/21) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant |
| queue.declare | Yes (50,10) | ✓ | ✗ | yes (L254) | PARTIALLY SUPPORTED | AMQP | ignores flags/cap fixed |
| queue.declare-ok | Yes (50,11) | ✓ | ✗ | yes (L370) | PARTIALLY SUPPORTED | AMQP | no-wait violation |
| queue.bind | Yes (50,20) | ✓ | ✗ | yes (L261) | PARTIALLY SUPPORTED | AMQP | correct mapping, ignores args/no-wait |
| queue.bind-ok | Yes (50,21) | ✓ | ✗ | yes | PARTIALLY SUPPORTED | AMQP | — |
| queue.purge / delete / unbind (+ok) | Yes (50,30/40/50…) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant |
| basic.qos / qos-ok | Yes (60,10/11) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant (prefetch absent) |
| basic.consume | Yes (60,20) | ✓ | ✗ | yes (L284) but arg misparse | PARTIALLY SUPPORTED | AMQP | missing reserved-1 skip L285 |
| basic.consume-ok | Yes (60,21) | ✓ | ✗ | yes | PARTIALLY SUPPORTED | AMQP | consumer-tag=String(cid) |
| basic.cancel / cancel-ok | Yes (60,30/31) | ✓ | ✗ | ✗ (no branch) | NOT IMPLEMENTED | AMQP | constants:109-113 |
| basic.publish | Yes (60,40) | ✓ | ✗ | yes (L275) inline-body | PARTIALLY SUPPORTED | AMQP | bits-as-body; content frames ignored |
| basic.return | Yes (60,50) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | no mandatory handling |
| basic.deliver | Yes (60,60) | ✓ | ✗ | yes (L311) | PARTIALLY SUPPORTED | AMQP | empty exch/rkey; inline body |
| basic.get / get-ok / get-empty | Yes (60,70/71/72) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant |
| basic.ack | Yes (60,80) | ✓ | ✗ | yes (L300) but multiple=id bug | PARTIALLY SUPPORTED | AMQP | amqp_service:301-303 |
| basic.reject | Yes (60,90) | ✗ absent | ✗ | adapter only | NOT IMPLEMENTED | AMQP | adapter:91; no dispatch |
| basic.recover / -async / -ok | Yes (60,110/100/111) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | S1; no constant |
| basic.nack | **No — RabbitMQ ext** (idx 120) | ext id (60,120) | ✗ | ✗ | NOT IMPLEMENTED | **RabbitMQ ext** (S3/S4) | constants:100-101 |
| tx.select / commit / rollback (+ok) | Yes (90,10/20/30) | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | AMQP | grep 0 |
| confirm.select / select-ok | **No — RabbitMQ ext** | ✗ absent | ✗ | ✗ | NOT IMPLEMENTED | **RabbitMQ ext** (S3/S4) | grep 0 |
| RabbitMQ interoperability (whole layer) | — | — | — | — | **NOT TESTED** | — | no client run |

### Count by classification
- **SUPPORTED:** 0 — no method is simultaneously wire-ID-correct, state-machined, and semantically correct.
- **PARTIALLY SUPPORTED:** 15 — connection.open/-ok/close, channel.open/-ok, exchange.declare/-ok, queue.declare/-ok, queue.bind/-ok, basic.consume/-ok, publish, deliver, ack.
- **INTENTIONALLY UNSUPPORTED:** 0 formal — but two *documented slice deviations* exist: inline publish/deliver body (`amqp_service.mojo:11-17`), pull-on-subscribe flush (must not silently become final delivery architecture — audit §25).
- **NOT IMPLEMENTED:** 30 — all of connection negotiation (start/start-ok/secure/tune/tune-ok/close-ok), channel.flow/close, exchange.delete, queue.purge/delete/unbind, basic.qos/cancel/return/get/reject/recover, basic.nack (ext), tx.*, confirm.* (ext).
- **NOT TESTED:** 1 — the entire RabbitMQ-interoperability claim layer (§11/§12).

---

## §13 — Negative / fuzz targets for the CURRENT decoder (concrete TODO)

Derived by reading `try_parse_frame` (frame_codec:66-104), `parse_method_args`/`parse_header_frame_payload` (216-248), `field_table.from_bytes` (171-247), `ByteReader` (amqp_service:82-142). Do NOT write these tests now — handoff list for the §13 package.

1. **Frame-size DoS / stall** — `size` up to 0xFFFFFFFF: `total=7+size+1` (frame_codec:84) is never checked against frame-max (unenforced) → parser waits for unbounded data or attempts huge copy. Feed a header with `size=0x7FFFFFFF`, small buffer → non-progress. Also `Int(size)` on 32-bit target overflow.
2. **Bad frame-end → uncaught raise** — end octet ≠ 0xCE raises (`frame_codec:96`); in `listener.serve_one_frame:107` the exception is **not caught** → whole connection/loop fault instead of a spec `frame-error(501)` hard close. Also test 0xCE inside a *truncated* frame (buffer exactly at boundary).
3. **Unknown frame type accepted** — `try_parse_frame` (frame_codec:74) does no type validation; `handle_frame` (amqp_service:208) silently drops non-method frames → no `unexpected-frame(505)`. Fuzz type ∈ {0,4,5,6,7,9,255}.
4. **Truncated / undersized payloads** — method frame with `size<4` (`parse_method_args:218` raises); header frame `size<10`; **misaligned header** given real class-id+weight layout (frame_codec:234 reads body_size from payload[2:10], wrong offset) → any well-formed spec header decodes to garbage. Fuzz field-truncated method args.
5. **Malformed field table** — `from_bytes:244` unknown type octet → **silent `break`** (partial table, no error); oversized 4-byte table/`'S'`/`'I'` lengths; negative `name_len`; table length ≠ actual entries; nested `F`/`A` absent. Feed type ∈ {0, 'A','F','T','V','x'} and corrupt length prefixes.
6. **Short-string > 255 & read past end** — `write_short_string` UInt8 truncation (amqp_service:72); `read_short_string` (126-135) advancing `pos` beyond buffer without error (silent padding) → oversized names/keys/routing-keys corrupt or loop.
7. **State-machine fuzz** — out-of-order methods: basic.publish before channel.open; connection.open before tune-ok; method on channel 0 vs N; open with wrong channel; consume with reserved-1 present (proves the L3 misparse); ack carrying `multiple=true`. Expect `not-allowed(530)`/`command-invalid(503)`/`channel-error(504)` — currently none emitted.
8. **Config / negotiation parser** — `connection.tune` values (channel_max=0, frame_max<4096 below frame-min-size per S1, heartbeat=0), never applied; malformed start-ok mechanisms/locales tables (peer-properties path is dead code).

---

## §25 groundwork — delivery-path review (current state)

- `basic.consume` replies `consume-ok` then **synchronously flushes up to 128 queued messages as `basic.deliver` frames** in the *same* reply (`amqp_service._flush_deliveries:311-344`, `_CONSUME_FLUSH_MAX=128`). Real clients expect consume-ok and deliveries as independent frames, and deliveries pushed asynchronously at publish time — must be verified against a real client.
- `basic.deliver` carries **empty exchange + empty routing-key** (Delivery does not propagate them, amqp_service:331-332) and an **inline body** (no content header/body frames) → delivery metadata loss.
- Messages arriving **after** the flush window are not pushed (no async pump) — pull-on-subscribe only. Ordering, prefetch/QoS, redelivery, consumer cancellation, multiple consumers, connection-loss requeue: all **unimplemented/untested** (§11 list). Do not let the vertical slice become the final delivery architecture (audit §25).

---

## Headline (one-paragraph)
The **frame envelope is byte-correct**, but every **connection-class + channel-open method ID is wrong** (sequential 1..6/10/11 vs spec 10/11/30/31/40/50/51) so no conformant client can hand-shake; the **content-header frame omits `weight` and mis-offsets `body-size`**; **field tables are dead code** (never on the wire) and support only 3 types; the **server never sends start/tune and enforces no state transitions**; `basic.ack` mistakes the `multiple` bit for a consumer id, `basic.consume` skips no `reserved-1`, `basic.publish`/`deliver` inline bodies (breaking content framing). All connection tests assert the buggy IDs, so CI never caught it. RabbitMQ interop is **NOT TESTED** and expected to fail at handshake.
