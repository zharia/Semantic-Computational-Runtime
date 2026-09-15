# HyrxMQ Interface Benchmark: TCP vs WebSocket

Generated: 2026-09-15T11:31:13+00:00  
Run stamp: `20260915-132712`  
Matrix: **quick**

## Methodology

One compiled Go binary (`benchmarks/interfaces/go`, module `hyrxmq-interfaces`) drives BOTH transports through the same `Transport` interface `{Write,Read,Close}`. `TCPTransport` wraps a `net.Conn` with `TCP_NODELAY`; `WSTransport` wraps a gorilla `*websocket.Conn` (one binary write per call; reads concatenate WS payloads into a byte stream). The raw AMQP 0-9-1 client in `amqp.go` speaks only to `Transport`, so the only difference between the TCP and WS runs is `--transport`.

Topology: one goroutine per connection; each opens its own connection + channel + exchange/queue, so concurrent workers never contend on one queue. `publish` is fire-and-forget to a bindingless direct exchange; `pubget` publishes a batch then drains it with `basic.get(auto_ack)`; `confirm` waits for a per-publish `basic.ack`; `latency` is publish -> get -> ack per message. Payload 64 B..256 KiB, concurrency 1/4/16, rotated run order, medians across reps. Broker `/proc/<pid>/stat` and `VmRSS` are sampled around the matrix.

## WSS tier status: BLOCKED

- WSSAMQPListener refuses to start: HYRXMQ_WSS_TLS_MODE=none (no cert source); and with a cert its serve_forever raises because event_driven_serving()=True reads the raw fd
- The shipped `hyrxmq-listen` refuses `HYRXMQ_WSS_TLS_MODE=none` (no cert source) and, with a cert, its `WSSAMQPListener.serve_forever` raises because the default `event_driven_serving()` loop reads the raw fd and cannot de-frame WebSocket bytes.
- A benchmark-only launcher (`ws_broker.mojo`, no `src/` changes) was built to compose the same `WSSListener` + `AMQPConnServing[WSSConnection]` with the legacy WSS loop. Its probe result is recorded below; the WS carrier's blocking read contract (`recv_bytes` waits for a full ~131 KB quota or peer CLOSE/EOF) deadlocks a normal request/response client.

**No WebSocket comparison numbers are reported because the transport is not serviceable in this build.** The TCP matrix below is real and complete.

### Evidence (exact, reproducible)

```text
$ HYRXMQ_WSS_LISTEN=<p> HYRXMQ_WSS_TLS_MODE=none ./build/hyrxmq-listen
Unhandled exception: WSSAMQPListener.start: no cert source configured
  (wss_tls_mode=none); the wss tier refuses to start.

$ HYRXMQ_WSS_LISTEN=<p> HYRXMQ_WSS_TLS_MODE=path \
    HYRXMQ_WSS_TLS_PATH=cert.pem HYRXMQ_WSS_TLS_KEY=key.pem ./build/hyrxmq-listen
HyrxMQ hyrxmq@localhost listening on wss://127.0.0.1:<p>
Unhandled exception: WSSAMQPListener.serve_forever: event-driven serving
  reads the raw fd (plaintext seam) and is not valid on the TLS-carrying
  wss tier; use the legacy loop (event_driven_serving = False)

$ HYRXMQ_WSS_LISTEN=<p> ./build/hyrxmq-ws-bench   # plaintext ws:// launcher
HyrxMQ ws_broker (plaintext ws://, legacy WSS loop) listening on ws://...
$ timeout 8 ./ifbench -transport ws -url 127.0.0.1:<p> -probe   # timed out
hyrxmq: connection.start-ok mechanism=PLAIN authcid=admin locale=en_US
  (logged only after the client gave up; WSSConnection.recv_bytes blocked
   waiting for its full frame_max+8 byte quota)
```

## Throughput (msgs/sec, medians)

| workload | payload | conc | TCP msgs/sec | TCP wall s |
|---|---:|---:|---:|---:|
| publish | 64 | 1 | 524100.5 | 0.9 |
| publish | 16384 | 1 | 80000.0 | 0.9 |
| pubget | 64 | 1 | 22222.2 | 0.081 |
| pubget | 16384 | 1 | 17307.7 | 0.104 |
| confirm | 64 | 1 | 13235.3 | 0.136 |
| confirm | 16384 | 1 | 10778.4 | 0.167 |
| latency | 64 | 1 | 16666.7 | 0.108 |
| latency | 16384 | 1 | 12162.2 | 0.148 |

## WebSocket overhead ratio (WS / TCP)

Not computed: no WS measurements (tier blocked).

## Latency (microseconds, medians)

| conc | payload | transport | p50 | p95 | p99 | p99.9 |
|---:|---:|---|---:|---:|---:|---:|
| 1 | 64 | tcp | 38 | 91 | 216 | 1708 |
| 1 | 16384 | tcp | 55 | 130 | 363 | 1759 |

## Broker resource usage

| broker | CPU ticks (u+s) delta | CPU seconds | final RSS KiB |
|---|---:|---:|---:|
| tcp | 586 | 5.86 | 34928 |
| ws | 0 | 0.00 | 16372 |

CPU ticks are `utime+stime` from `/proc/<pid>/stat`; RSS from `/proc/<pid>/status` `VmRSS`. CPU covers the whole matrix, not a single cell.

## Caveats

- **WebSocket cells are absent, not zero.** The WSS tier could not serve the probe in this build, so no WS number exists to compare. This is a broker/transport limitation, not a measured overhead.

- The WS carrier's server read (`WSSConnection.recv_bytes`) returns only when it has a full `frame_max+8` quota or sees a peer CLOSE/EOF. A normal request/response AMQP client therefore deadlocks; the bundled `tests/phase9/wss_test.mojo` avoids this only by pinning `frame_max` small and pre-writing batches.

- `publish` uses a bindingless exchange, so it measures producer + carrier cost with nothing stored.

- `pubget`, `confirm` and `latency` include broker queue operations and are not pure transport cost; they are still identical across transports.

- `HYRXMQ_FRAME_MAX` is set equal for both tiers so large bodies chunk identically.

- Single machine, loopback, no TLS: absolute values are indicative, ratios are the point.

