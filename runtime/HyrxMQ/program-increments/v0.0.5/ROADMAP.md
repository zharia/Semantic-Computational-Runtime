# HyrxMQ v0.0.5 Roadmap

**Baseline:** v0.0.4 — commit `f4d646e`
**Status:** Planning
**Purpose:** Close the remaining expensive gaps left open by v0.0.4. The
v0.0.4 increment is shipped and signed off (`V0.0.4_SIGNOFF.md`); this roadmap
covers only what remains.

**Clustering remains an explicit non-goal.** Kubernetes stays the orchestration
substrate.

---

## Current state (v0.0.4)

- Test suite: **77 pass / 1 fail** (the failure is the deliberate
  `assertion_negfail.mojo` negative self-test).
- Performance: fastest of HyrxMQ, RabbitMQ 4.x and LavinMQ in a fair same-host
  Docker comparison (overall geomean 1.041 vs 1.244 vs 6.918); fastest in 50 of
  80 throughput cells.
- Persistence: WAL with CRC, recovery, compaction; SIGKILL and disk-failure
  harnesses pass; 1-hour soak pass; 1M-iteration fuzz bar pass.
- Security: SASL PLAIN, per-user vhost + ACLs, auth rate limiting, TLS policy
  guard, `HYRXMQ_USERS` env.
- Protocol: four independent AMQP clients interoperate
  (`MULTI_INTEROP=PASS`); headers exchanges, `basic.qos`, `frame_max` /
  `channel_max` negotiation now enforced.
- Deployment: Kubernetes manifests validated live on kind (probes, rollout,
  graceful termination exit 0).

The items below are the outstanding gaps, with the evidence that motivated each.

---

## Cost / risk legend

- **Cost:** S = hours, M = days, L = weeks.
- **Risk:** likelihood a naive change breaks a semantic invariant.

---

## M1 — Durability completeness

**Gate:** D (Durability)

### M1.1 WAL segment rotation
- **Gap:** the WAL is a single append-only log; it grows without bound for a
  long-lived broker. `compact()` reclaims tombstones but does not rotate.
- **Cost:** M · **Risk:** medium (recovery must span segments).
- **Acceptance:** a size/time rotation policy rolls to a new segment; recovery
  replays all segments in order; `compact()` can drop fully-tombstoned segments.
- **Evidence:** a rotation test; a recovery test over ≥3 segments; a soak with
  rotation enabled.

### M1.2 Kill during flush / during recovery
- **Gap:** the SIGKILL harness kills mid-publish only; no kill is injected at a
  forced `fsync` boundary or during replay.
- **Cost:** S · **Risk:** low.
- **Acceptance:** kill at the fsync boundary and during replay both recover to a
  consistent prefix; no torn record is accepted.
- **Evidence:** harness modes for `kill-at-flush` and `kill-during-recovery`.

### M1.3 Permission and read-only filesystem injection
- **Gap:** `disk_failure_harness.sh` covers a read-only directory; EACCES on an
  existing segment and mid-run EROFS are not isolated.
- **Cost:** S · **Risk:** low.
- **Acceptance:** EACCES at open and EROFS mid-run fail closed, broker stays up.
- **Evidence:** harness cases + in-process `FileSystemOps` fault injection.

---

## M2 — Security completion

**Gate:** C (Security)

### M2.1 Live TLS certificate-chain rejection
- **Gap:** `tls_verify_peer` / `tls_allow_self_signed` / `tls_ca_path` exist and
  a policy guard runs, but expired and self-signed chains are not exercised
  against a real handshake.
- **Cost:** M · **Risk:** medium (OpenSSL FFI).
- **Acceptance:** an expired client/server cert and a self-signed cert are
  rejected when policy disallows them and accepted when policy allows.
- **Evidence:** a TLS test with generated certs of each class.

### M2.2 TLS performance cells
- **Gap:** the three-broker benchmark is plaintext only. TLS overhead is not
  measured against RabbitMQ / LavinMQ.
- **Cost:** S · **Risk:** low.
- **Acceptance:** TLS cells added to the benchmark with a same-config
  comparison.
- **Evidence:** an updated `REPORT_*.md` including TLS cells.

### M2.3 Credential rotation without restart
- **Gap:** `HYRXMQ_USERS` is read at startup; rotating credentials requires a
  restart.
- **Cost:** M · **Risk:** medium.
- **Acceptance:** a reload path (signal or admin endpoint) re-reads the users
  table.
- **Evidence:** a rotation test.

---

## M3 — Protocol completeness

**Gate:** G (Robustness)

### M3.1 Server 2×-missed-heartbeat close
- **Gap:** server heartbeat is poll-driven, but a peer that stops sending is not
  disconnected after the negotiated 2-missed-heartbeat window.
- **Cost:** M · **Risk:** medium (needs a timer/age model on the poll cadence).
- **Acceptance:** a silent peer is closed after 2× the negotiated interval.
- **Evidence:** a test with a short heartbeat and a silent client.

### M3.2 Multi-consumer per connection
- **Gap:** the engine maps one consumer per connection (`_consumers:
  conn_id → cid`). A client cannot open several consumers on one connection.
- **Cost:** L · **Risk:** high (consumer identity, tags, prefetch per consumer).
- **Acceptance:** N consumers on one connection, each with its own tag,
  prefetch and delivery stream.
- **Evidence:** an interop test with multiple consumers per connection across
  pika + Go.

### M3.3 Remaining protocol methods
- **Gap:** SASL `secure`/`secure-ok` (10,20/10,21) and `channel.flow`
  (20,20) are not implemented; `channel.flow` currently returns `*_ok`.
- **Cost:** S · **Risk:** low.
- **Acceptance:** the methods behave per amqp0-9-1.xml; unimplemented ones reply
  with the normative not-implemented error rather than a false `*_ok`.
- **Evidence:** protocol-state tests for each.

---

## M4 — Performance completion

**Gate:** G (Performance)

### M4.1 Close the 25 ownership-bound cells
- **Gap:** HyrxMQ is behind in 25 of 80 cells (all ≤1.31×): fanout (per-destination
  payload copy), small-payload pubget (per-get dict churn), large-payload
  publish (the single codec→payload memcpy), 256 KiB pubget.
- **Cost:** L · **Risk:** high. Requires a shared, ref-counted immutable payload
  buffer for fan-out and a borrowed/offset payload for the codec path, while
  proving no double-release and preserving per-destination ownership.
- **Acceptance:** fastest or tied (≤2%) in every cell.
- **Evidence:** `REPORT_*.md` with no cell behind.

### M4.2 Multi-core serving (`SO_REUSEPORT`)
- **Gap:** serving is single-threaded; throughput plateaus at high concurrency
  while multi-threaded brokers keep scaling. `flare` already exposes
  `SO_REUSEPORT`.
- **Cost:** L · **Risk:** high (shared state across threads: router, consumers,
  WAL).
- **Acceptance:** N listener workers scale throughput with cores; no data race.
- **Evidence:** scaling curves to 64+ connections.

### M4.3 Per-connection queue merge
- **Gap:** the pubget cost is dominated by repeated consumer+queue lookups (each
  doing `in` + `[]` double hashing) per get.
- **Cost:** S · **Risk:** low.
- **Acceptance:** one combined lookup per delivery.
- **Evidence:** measured improvement on small-payload pubget.

---

## M5 — Operationalisation completion

**Gate:** E (Operational readiness)

### M5.1 Multi-tier concurrency (thread model)
- **Gap:** `main_listen` serves one transport tier at a time (UDS **or** TCP);
  running the admin HTTP tier concurrently needs a thread model and a
  synchronised shutdown.
- **Cost:** L · **Risk:** high.
- **Acceptance:** AMQP (TCP), UDS, WSS and admin HTTP serve concurrently in one
  process with a single graceful-shutdown sequence.
- **Evidence:** a live test enabling all tiers.

### M5.2 Structured log sinks
- **Gap:** structured logging renders records but has no sink or rotation;
  correlation IDs exist but are not threaded through the frame paths.
- **Cost:** M · **Risk:** low.
- **Acceptance:** configurable sink (file/stdout) with size-based rotation;
  correlation ID per connection on every record.
- **Evidence:** log-rotation test.

---

## M6 — Interoperability matrix

**Gate:** F (Interoperability)

### M6.1 Extended client matrix
- **Gap:** pika, amqplib, RabbitMQ Java and `amqp091-go` pass; the protocol
  matrix (confirms, QoS, mandatory/return, heartbeat, reconnect) is not run for
  every client.
- **Cost:** M · **Risk:** low.
- **Acceptance:** each client exercises the full protocol matrix.
- **Evidence:** an interop matrix report per client × feature.

### M6.2 Long-running reconnect / failover
- **Gap:** reconnect is exercised per-client, not under sustained churn.
- **Cost:** S · **Risk:** low.
- **Acceptance:** clients reconnect and resume through repeat broker restarts.
- **Evidence:** a churn harness report.

---

## Explicit non-goals (unchanged)

Broker clustering, cluster membership, consensus, leader election, distributed
queue/exchange state, cross-node replication, cluster-wide routing/scheduling/
discovery/failover. These are Kubernetes/orchestration concerns.

---

## Suggested sequencing

```
M4.3 (cheap perf)
  ↓
M1.2 / M1.3 / M3.3 / M2.2 / M6.2   (low-cost closes)
  ↓
M1.1 WAL rotation
  ↓
M2.1 TLS chain · M3.1 heartbeat close · M4.1 perf cells
  ↓
M3.2 multi-consumer · M5.1 multi-tier thread model · M4.2 multi-core
  ↓
release checkpoint
```

## Exit criteria for v0.0.5

- All M1–M3 acceptance items met with evidence.
- Every three-broker benchmark throughput cell fastest or tied (≤2%).
- Multi-consumer and multi-tier concurrency proven under load.
- Sign-off report with an honest known-gaps table.

---

## References

- `program-increments/v0.0.4/reports/V0.0.4_SIGNOFF.md` — v0.0.4 verdict + gaps
- `program-increments/v0.0.4/reports/RELEASE_CHECKLIST.md` — evidence index
- `benchmarks/perf/three_broker/REPORT_FINAL2.md` — performance baseline
- `program-increments/v0.0.4/reports/PERF_OPTIMIZATION.md` — hot-path history
- `KUBERNETES.md`, `CHANGELOG.md`, `RELEASE_NOTES.md`
