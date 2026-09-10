# 0023 — optional WSS + admin-HTTP transports (browser + k8s tier)

**Status:** T1/T2 code shipped (46/0); ONE open defect — the WssConfig tls_key_path String gains a phantom trailing byte on the move into `WSSListener._cfg` (isolated via strace: `key.pemm` after the probe struct passes clean; the cert path + the config strings read 24 bytes correct). Next pass: fix the owned-String transfer (explicit `__moveinit__`/`__copyinit__` on WssConfig or copy-per-field in the listener ctor), then roll T3/T4 (admin HTTP + the conformance rows). Suite currently 46/0; basic wss flow works ONLY after the fix.
**Mode:** coordinator; T1/T2 delegated (general), T3/T4 next round, verify = coordinator

## Objective (user-stated)

Browser clients are part of the target market; kubernetes deployment is
supported (basic support only; clustering offloaded to k8s; focus stays
single-node optimization). Transport support = optional and configurable.
Both certificate models supported (injected bytes + a `path` convenience
function routed through the injected fs seam). No hard fs dependency
anywhere. HTTP added as a small OPTIONAL plane (admin surface only).
Origin policy = **allow-all by default**, extensible via config
(comments in code note this).

## Design (locked)

- Ports: wss = `5678`, admin HTTP = `25673`; both default **off** (`none`).
- wss: `TcpListener.accept` → `flare.tls.TlsStream` → WS handshake at
  `/ws` with `Sec-WebSocket-Protocol: amqp` (RFC 7395 binding; one binary
  WS message per AMQP frame) → `WSSConnection(AMQPConn)` bridge; the
  existing `AMQPConnServing` + 0017-protocol surface serves unchanged.
- Certs: `injected` mode = PEM bytes via config callback (zero fs);
  `path` mode = read-once-through the injected ops (the only fs use;
  convenience never hardcodes `open()`); no source configured → refuse to
  start the wss tier with the normative reason.
- admin HTTP: flare `HttpServer` on its own port; `/health` (k8s
  probes) + `/stats` (existing engine stats JSON). No config UI, no
  management UI, no AMQP data plane.
- Origin policy: allow-all default; `HYRXMQ_WSS_ORIGIN` allow-list is the
  recorded extension point (in-code comment per user instruction).
- Serving tiers: unchanged; the 0022 event-loop roll-forward stays
  independent.

## Verification program

- `tests/phase9/wss_test.mojo`: injected-certs path (no fs), path-mode
  through the ops seam with call counters, subprotocol-negotiation rows,
  byte-exact frame round trip, origin rows (default allow-all + a listed
  origin), close-code mapping, `/health` + `/stats` rows, and the
  no-fs-when-unconfigured counter assertion (0 seam calls).
- Python `websockets` conformance runner extending benchmarks/compat
  (ground truth = rabbit_web_amqp enabled ONLY on the disposable bench
  rabbit; node-rabbitmq untouched).
- Suite 46/0 base green; no pika-matrix regression; perf recorded as
  observation rows only.

## T4 state (session closing record)

- attempts: a 1178-line phase9 fixture was generated but its in-proc
  serving fixture hangs (the phase9 dir is NOT part of test_all's
  discovery list, so the suite stays 46/0; the file is left UNCOMMITTED
  as a starting point for the next round, the row set was verified
  byte-precise at the 0013-family shape and may be adapted once the
  in-proc serving loop is understood);
- the LIVE evidence recorded: the wss handshake verified end-to-end with
  real PEM certs (101 + the amqp subprotocol + the accept key) — the
  transport rows are real; the phase9 fixture = the pending piece.
- 0023-T4 remains the one OPEN item on the todo list.

## Explicitly NOT claimed

- Same-port ALPN multiplexing (deferred; h2 coupling).
- Management/config UI planes (excluded per user decision).
- Broker-side clustering (k8s carries it; deployment notes only).
- Perf gate rows for wss/http (observation tier only).
