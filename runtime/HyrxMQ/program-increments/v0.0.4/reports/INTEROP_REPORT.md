# HyrxMQ Multi-Client AMQP Interoperability Report

**Date:** 2026-09-14 (UTC)
**Broker commit:** `cf9dfb3340a1` (`feat: complete enforcement gaps + live K8s lifecycle validation`)
**Broker artifact:** `build/hyrxmq-listen` (advertises `product=HyrxMQ`, `version=4.3.5`,
`platform=Mojo` in `connection.start` server-properties)
**Reference broker:** RabbitMQ container `ecstatic_khayyam` — **not touched** during this run
**Ports:** pika gate on `5699`, multi-client suite on `5698`; RabbitMQ's `5672` never bound/used

> **Headline:** the shipped multi-client suite reports **0 of 3** non-pika clients passing.
> The primary blocker is a wire-level handshake divergence (`protocol-header echo`) that the
> `pika` client tolerates but `amqplib`, the RabbitMQ Java client, and `amqp091-go` do not.
> A secondary runner bug (`localhost` → IPv6) independently breaks the Java client, and a
> known content-frame gap stops all consumers short of delivery.

---

## 1. Per-client results (as actually observed)

| Client | Runner result | Evidence |
|--------|---------------|----------|
| **pika** (Python 3.14.7, pika 1.4.4) | **PASS** | `run_pika_negotiation.sh` exit `0`; `HANDSHAKE GATE: PASS`; all 8 steps PASS |
| **node** (Node v26.8.2, amqplib 0.10.9) | **FAIL** (RC 1) | `NODE_INTEROP=FAIL` → `fatal: connect: timed out after 10000ms` |
| **java** (OpenJDK 21.0.12, amqp-client 5.21.0) | **FAIL** (RC 1) | `JAVA_INTEROP=FAIL` → `fatal: ConnectException: Connection refused` |
| **go** (go1.27.1, amqp091-go v1.10.0) | **FAIL** (RC 1) | `GO_INTEROP=FAIL` → `dial amqp://admin:password@127.0.0.1:5698/: Exception (501) Reason: "frame could not be parsed"` |

Suite summary line as emitted by `scripts/interop/run_multi_interop.sh`:

```
============ MULTI-CLIENT INTEROP RESULT ============
CLIENT    RC    STATE
node      1     FAIL
java      1     FAIL
go        1     FAIL
====================================================
MULTI_INTEROP=FAIL
```

### pika negotiation gate (independent, port 5699) — PASS

All eight recorded steps passed, including the content steps:

```
[PASS] connect (header/start/start-ok/tune/tune-ok/open/open-ok)  :: handshake completed
[PASS] channel.open                                                :: channel_number=1
[PASS] exchange.declare                                            :: direct 'hyrx.nego.x'
[PASS] queue.declare                                               :: queue=hyrx.nego.q
[PASS] queue.bind                                                  :: hyrx.nego.x -[hyrx.key]-> hyrx.nego.q
[PASS] basic.publish                                               :: method read; HEADER/BODY frames consumed
[PASS] delivery received (basic_get)                               :: body=b'body-A' rk='hyrx.key'
[PASS] basic.ack                                                   :: delivery_tag=1
HANDSHAKE GATE: PASS
teardown ok: broker gone, port 5699 released, RabbitMQ :5672 untouched
```

---

## 2. Root causes

### RC-1 — Broker emits an 8-byte protocol-header echo before `connection.start` (primary)

On every new TCP connection the broker writes the client's 8-byte AMQP protocol header
(`41 4d 51 50 00 00 09 01` = `AMQP\0\0\9\1`) back to the client **before** the
`connection.start` method frame. Captured on the wire (all clients receive the same bytes):

```
C->B  8 bytes: 414d515000000901            (client protocol header)
B->C  8 bytes: 414d515000000901            (broker ECHO)
B->C 401 bytes: 01000000000189000a000a..   (connection.start, well-formed)
```

- **pika tolerates it**: `pika/frame.py` explicitly recognises a leading `AMQP` protocol
  header (`if data_in[0:4] == b'AMQP'`) and skips it. Handshake therefore completes.
- **amqplib 0.10.9 does not**: `lib/frame.js::parseFrame` treats byte 0 as a frame *type*
  (`0x41` = 65) and bytes 3–6 as a 4-byte frame size (`0x50000009`, ~1.3 GB), so it waits
  forever for a frame that never completes. `strace` confirms the client read the full
  409 bytes and then sent nothing:
  ```
  write(21, "AMQP\0\0\t\1", 8) = 8
  read(21, "AMQP\0\0\t\1\1\0\0\0\0\1\211\0\n\0\n...", 65536) = 409
  ```
- **RabbitMQ Java client 5.21.0 and amqp091-go v1.10.0 likewise do not strip the echo**:
  each stalls (Java: `IOException: null`; Go: server replies `501 frame could not be parsed`).

**Proof of causality (strip-proxy experiment).** A local TCP proxy that removes only the
broker's 8-byte echo was interposed. With the echo removed, all three clients advance past
the handshake:

- node: `connected`, `declared direct 'node-ex'`, `published 10 messages`,
  `publisher confirms OK (broker acked all 10)` → fails later only on deliveries.
- go: `connected`, `declared`, `basic.qos prefetch=10 OK`, `published 10`,
  `publisher confirms OK` → fails later only on deliveries.
- java: full handshake, `exchange.declare`/`queue.declare`/`queue.bind`, `confirm.select`,
  `basic.consume`, 10 `basic.publish`, and 10 `basic.ack` confirms on the wire → blocks
  waiting for deliveries.

So RC-1 is the *entire* reason for the node connect timeout and the go `501`, and the
*initial* reason Java never negotiates.

### RC-2 — Runner sends Java to `localhost` (IPv6) while the broker binds IPv4 (independent)

`scripts/interop/run_multi_interop.sh:140` sets `HYRX_HOST=localhost` for the Java client,
while node/go use `127.0.0.1` and the broker binds `127.0.0.1` only.

```
$ getent hosts localhost
::1             localhost
```

`localhost` resolves to `::1` (IPv6) on this host, where nothing listens, so Java fails
immediately with `ConnectException: Connection refused` before any AMQP bytes are exchanged.
Pointing Java at `127.0.0.1` gets it to the handshake (and then to RC-1).
This is a **runner configuration bug**, not a broker defect.

### RC-3 — `basic.consume` / `Basic.Deliver` content-frame reassembly not implemented

After RC-1 is neutralised, every client publishes successfully **and receives publisher
confirms**, but none receives a `Basic.Deliver` on its consumer:

- node: `fatal: deliveries: not satisfied within 10000ms`
- go:   `expected 10 deliveries, got 0`
- java: blocks in the delivery poll loop (killed at the 25 s bound)

The broker acknowledges the `basic.publish` method + HEADER/BODY frames (confirm acks
observed on the wire) but never pushes `basic.deliver`. This matches the gap documented in
`scripts/interop/pika_negotiation.py` (the Phase 7 vertical slice carries bodies inline and
does not reassemble separate content frames). `basic.return` (mandatory unroutable) is
therefore also unverified for node/java/go.

---

## 3. Protocol features verified per client

"Verified" = observed to complete without error in this run (for node/java/go, with RC-1
neutralised via the strip-proxy; the shipped runner does not include the strip).

| Feature | pika | node | java | go |
|---|---|---|---|---|
| `connection.start` handshake (tune/tune-ok/open) | ✅ | ✅* | ✅* | ✅* |
| `channel.open` | ✅ | ✅* | ✅* | ✅* |
| `exchange.declare` (direct) | ✅ | ✅* | ✅* | ✅* |
| `queue.declare` | ✅ | ✅* | ✅* | ✅* |
| `queue.bind` | ✅ | ✅* | ✅* | ✅* |
| `basic.publish` | ✅ | ✅* | ✅* | ✅* |
| `confirm.select` + publisher confirms | — | ✅* (10/10) | ✅* (10/10) | ✅* (10/10) |
| `basic.qos` (prefetch) | — | — | — | ✅* (prefetch=10) |
| `basic.consume` / `Basic.Deliver` | ❌ (not used) | ❌ | ❌ | ❌ |
| `basic.get` delivery body | ✅ | — | — | — |
| `basic.ack` | ✅ | ✅* (broker-side) | ✅* | ✅* |
| `basic.return` (mandatory unroutable) | — | ❌ | ❌ | ❌ |

`✅*` = verified only after the broker's protocol-header echo was stripped by a proxy.
`—` = not exercised by that client. The unqualified ✅ entries for pika are the only ones
observed against the unmodified broker.

---

## 4. Toolchain status

All four toolchains were present and usable; **no SKIPs**:

| Tool | Present | Notes |
|------|---------|-------|
| pika | pika 1.4.4 in `/tmp/amqp-venv` | venv created during this run |
| node | v26.8.2; amqplib 0.10.9 | `npm install` into `/tmp/node-interop` succeeded |
| java | javac/java 21.0.12; amqp-client 5.21.0 + slf4j-api 1.7.36 | jars cached in `/tmp/hyrxmq-java-interop` |
| go | go1.27.1; amqp091-go v1.10.0 | `go build -o /tmp/go_interop` succeeded |

Preconditions met: `build/hyrxmq-listen` and `build/libflare_tls.so` existed;
`build/shutdown_shim.o` present. Note the shipped runner does **not** build the Go client —
it only runs `/tmp/go_interop` if the binary already exists (it would otherwise report
`GO_INTEROP=FAIL` via skip); the binary was built explicitly for this run.

---

## 5. Cleanup / safety

- All broker instances started for this run (`5697`/`5698`/`5699`) were terminated by exact
  PID; no listeners remain on `5697`–`5699`.
- No `pkill -f` / `killall` was used. The reference container `ecstatic_khayyam` was never
  touched, and no `5672` listener was bound.
- Two `hyrxmq-listen` processes belonging to **other** work were left untouched
  (PID `1717031` on `:15675`, pre-existing; PID `1856933` on `:50121`, a separate concurrent
  soak test).

---

## 6. Recommendations (not implemented here)

1. **Remove the protocol-header echo** (or gate it to protocol-mismatch rejection only) so
   `connection.start` is the first frame on a successful negotiation. This unblocks
   amqplib/amqp091-go/RabbitMQ-Java.
2. **Fix the Java host in the runner** (`HYRX_HOST=127.0.0.1`, or bind the broker on both
   loopback families) — independent of RC-1.
3. **Implement content-frame reassembly for `basic.consume`/`Basic.Deliver`** (and
   `basic.return`) to close RC-3 and make the multi-client gates meaningful.
