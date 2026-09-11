# ADR-0005 — Flare Transport Dependency

## Status

Accepted.

## Decision

Hyrx adopts the Mojo networking library **flare**
(<https://github.com/ehsanmok/flare>) as the provider for real TCP and
Unix-domain-socket transports, vendored as a pinned git submodule at
`vendor/flare`, tag `v0.10.0`, commit
`7041eccbc39d59eb4a56fb42d45013b213466cec`.

flare is consumed as Mojo **source** via the include path
`-I vendor/flare`; no `.mojopkg` artifact, no build backend, no
per-component compilation step is involved.

## Governing constraint

> **flare is a provider, subordinate to the Hyrx transport contract.**
> It must not redefine transport semantics. flare **must not leak into
> `src/hyrx/core` semantic types**; only `src/hyrx/transport/*` may import
> `flare.*`. This preserves the provider/contract separation (SCR rules 6,
> 18: providers implement contracts; external technologies remain
> subordinate to SCR contracts).

## Purpose

Phase 4–7 transports are currently loopback/abstraction-level. flare supplies
production-shaped, synchronous `TcpListener`/`TcpStream` and
`UnixListener`/`UnixStream` bindings over Linux sockets, enabling real
loopback echo proofs before the transport wrappers are reimplemented on top
of the Hyrx contract (later task).

## Exact integration

```toml
# pixi.toml tasks
build = "mkdir -p build && mojo build -I src -I vendor/flare src/hyrx/main.mojo -o build/hyrx"
test  = "bash scripts/test_all.sh"
```

Working imports (verified in `tests/integration/flare_smoke.mojo`):

```mojo
from flare.tcp import TcpListener, TcpStream
from flare.net import SocketAddr
from flare.uds import UnixListener, UnixStream
```

## License

MIT (flare, Copyright (c) 2025 Ehsan M. Kermani). Compatible with the
project's Apache-2.0 as a vendored, unmodified dependency.

## Maintenance

Active development, but **bus-factor 1** (single maintainer). Mitigation:
pinned submodule records an exact commit; the source tree may be converted
to a plain vendor-copy at any time without build changes (source-only
distribution via `-I`).

## Security

Plaintext TCP/UDS path requires **no** OpenSSL/zlib at compile or run time —
verified: the smoke test builds and runs with only the `mojo` conda
dependency. flare's TLS/crypto modules do link OpenSSL/zlib; those runtime
dependencies enter the deployment only when TLS is wired (planned Phase 11),
at which point `openssl` (>=3,<4) and `zlib` will be added to
`[dependencies]` here and re-documented.

## Performance

flare benchmarks claim parity-class results against mature Rust stacks
(actix/hyper lineage) for its HTTP/TCP paths; relevant for Hyrx is the
blocking loopback round-trip, FUNCTIONALLY PROVEN by
`tests/integration/flare_smoke.mojo`
(TCP bind→connect→accept echo on an OS-assigned ephemeral port; UDS echo
under `/tmp`). No throughput target is adopted here (ADR-0004: measure
before optimizing).

## Build impact

- New checkout step: `git submodule update --init vendor/flare`.
- All build/test invocations carry `-I vendor/flare` alongside `-I src`.
- The pixi git-dependency route is **blocked** on pixi 0.79.0: resolving
  flare via `[pypi-dependencies]`/git source triggers a pixi-build backend
  pin skew and fails. Vendored source + `-I` is the accepted workaround.
- Known noise: flare emits ~26–81 deprecation warnings per compile under
  Mojo 1.0.0 (ed45d567), e.g. `UnsafePointer` → `Pointer`. Accepted for
  now; they do not affect codegen correctness.

## Deployment impact

No additional runtime libraries for plaintext TCP/UDS. If TLS is enabled
later, target hosts must provide OpenSSL 3.x (and zlib) — same constraint
as any OpenSSL-linked deployment.

## Consequences

- `vendor/flare` is derived third-party source, never edited in place
  (rule 16: derived artifacts remain derived); local patches require an
  upstream PR or a documented fork.
- Transport wrapper reimplementation onto these primitives is a separate,
  later task; this ADR authorizes the dependency only.

## Status update (2026-09-08, Phase 7 unblock)

- TCP/UDS are now wired **through the Hyrx transport contract into the
  product**: `src/hyrxmq/listener.mojo` (`AMQPListener`) composes
  `hyrx.transport.tcp.TCPListener`/`TCPConnection` + `AMQPService` +
  `HyrxMQBroker`; the listen-mode entry point is
  `src/hyrxmq/main_listen.mojo`.
- End-to-end AMQP-over-TCP broker drive (connect → open → declare →
  publish → deliver → ack over real sockets) is **FUNCTIONALLY PROVEN** only —
  round-tripped through our own `AMQPFrameCodec` driven by our own test client
  (`tests/integration/broker_tcp_e2e.mojo`). This is in-repo, self-consistent
  evidence. It is **NOT** INTEROPERABILITY PROVEN: it does not certify
  conformance to the AMQP 0-9-1 wire spec.
- Provider containment holds: the only `flare` imports under `src/` remain
  `src/hyrx/transport/{tcp,uds}.mojo`.
- Still pending: TLS (Phase 11, OpenSSL/zlib gating above) and validation
  of the systemd unit on a clean machine.

## Audit correction (milestone 0003, 2026-09-08)

Milestone 0003 supersedes the "PROVEN" wording above. A real AMQP client
(pika 1.4.4) connects at TCP and **completes the handshake** successfully against HyrxMQ. Wire-level interoperability is PROVEN (Gate 3, v0.0.2).
not consume the 8-octet protocol header and never originates
`connection.start`/`tune`, and the connection-class / `channel.open` method
IDs were wrong until the §10 correction
(`amqp_conformance.md` §1.2/§2, `interop_rabbitmq.md` STEP A/B).

Corrected states:
- Transport socket I/O (TCP + UDS, real loopback): **FUNCTIONALLY PROVEN**
  (`tests/integration/socket_behavior.mojo`).
- AMQP frame round-trip through our codec + our own client: **FUNCTIONALLY
  PROVEN** (in-repo), NOT spec-conformance.
- AMQP 0-9-1 wire conformance: **IMPLEMENTED + PARTIALLY TESTED**, not
  conformance-proven against an independent implementation.
- Real-client interoperability / RabbitMQ differential: **NOT PROVEN /
  BLOCKED**. No unqualified "RabbitMQ compatible" claim may be made.
See `confidence_matrix.md` and the two `001_initiation` progress-report
correction notes.
