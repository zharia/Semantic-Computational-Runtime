# HyrxMQ Security Audit (milestone 0003, spec §18)

**Type:** READ-ONLY audit. No code or test changes were made.
**Date:** 2026-09-08
**Files examined:** `docs/SECURITY.md`, `packaging/systemd/hyrxmq.service`,
`src/hyrx/transport/{transport,tcp,uds}.mojo`, `src/hyrxmq/{listener,amqp_service,config,broker,main_listen,status}.mojo`,
`src/hyrx/core/{queue,buffer_pool,router}.mojo`, `src/hyrx/amqp/{frame_codec,connection_state}.mojo`,
`src/hyrx/amqp/adapter.mojo`, `src/hyrx/embedded/api.mojo`, `vendor/flare/flare/uds/listener.mojo`.

---

## 0. Reachability of the attack surface (read this first — it sets confidence)

The honest picture is **more exposed than "negotiation incomplete ⇒ theoretical"**.

Two layers must be separated:

1. **AMQP session layer** (declare/publish/consume semantics, tuning, auth).
   NOT REACHABLE by a real client: the 8-octet protocol header is never checked,
   SASL `connection.start/start-ok/secure/secure-ok` and `tune/tune-ok` are not
   implemented, and `close/close-ok` is absent
   (`src/hyrx/amqp/connection_state.mojo:7-21`, `src/hyrxmq/amqp_service.mojo:26-41`).
   Any risk that requires a *completed, spec-exact AMQP session* is **latent**.

2. **Byte/framing layer** (`AMQPFrameCodec` fed by `AMQPListener`).
   **REACHABLE NOW by any raw TCP peer.** `serve_forever` → `accept_and_serve_one`
   → `serve_one_frame` (`src/hyrxmq/listener.mojo:152-159`, `138-150`, `90-136`)
   calls `try_parse_frame()`/`feed_bytes()` on socket bytes with **no protocol-header
   gate and no connection-state gate**. `handle_frame` dispatches methods even when
   no connection is open (`src/hyrxmq/amqp_service.mojo:36-38`, and no state check
   in `handle_frame`, `amqp_service.mojo:231-375`). `main_listen.mojo` binds
   `0.0.0.0:5672` (`config.mojo:65-66`) via `serve_forever`.

**Consequence:** findings S-1 (unbounded accumulation) and S-2 (uncaught raise in
the parse/dispatch path) are **reachable** at the byte level, not theoretical. They
are gated only by deployment of the listen binary, which the unit file itself marks
unvalidated on a clean machine (`packaging/systemd/hyrxmq.service:1-9`). Confidence
in those two findings is therefore **HIGH for code path, NOT PROVEN at runtime** —
no live execution was performed in this read-only audit. §9/§13 must prove them by
running `hyrxmq-listen` against a raw socket.

---

## 1. Threat model for the current attack surface

| # | Threat (§18) | Attack surface today | Mitigations present (file:line) | Missing | Severity | Status |
|---|---|---|---|---|---|---|
| T-1 | Untrusted network client | TCP `0.0.0.0:5672`, raw bytes reach the codec | None beyond TCP bind | No protocol-header check, no per-connection byte/second budget, no idle timeout, no connection-state gate | HIGH | PARTIAL (bytes accepted ungated) |
| T-2 | Malformed AMQP client | `try_parse_frame` / `handle_frame` | `tests/phase6/frame_codec_test.mojo:298-310` proves a bad end byte **raises**; `ByteReader` is bounds-safe (`amqp_service.mojo:118-178`) | Raise is not caught anywhere ⇒ process death; no frame-type/channel validation; no protocol exception (`connection.close`) reply | CRITICAL | PARTIAL (detection yes, containment no) — see S-2 |
| T-3 | Credential attacker | n/a — no authentication exists | — | SASL PLAIN/EXTERNAL, user/credential store, vhost authz, failed-auth limits (`docs/SECURITY.md:12,19-27`) | CRITICAL (when exposed) | **NOT IMPLEMENTED** — no auth code in `src/` |
| T-4 | Resource-exhaustion attacker | `feed_bytes` accumulation; per-conn codec | `_CONSUME_FLUSH_MAX` = 128 (`amqp_service.mojo:75-76`, used `389`) | No cap on codec buffer growth, no `max_connections` enforcement, no MemoryMax in unit | HIGH | **ABSENT / UNENFORCED** — see S-1, §3 |
| T-5 | Oversized-message attacker | frame `size` field (UInt32) and `body_size` (UInt64) | `config.frame_max` exists and is validated positive (`config.mojo:68,146-147`) | `frame_max` never reaches the codec; `body_size` never range-checked (`frame_codec.mojo:276-285`) | HIGH | **PARTIAL** — declared, not enforced |
| T-6 | Connection storm | `accept_one` appends a slot per accept | `TransportConfig.max_connections = 1024` (`transport.mojo:22`, set `listener.mojo:41`) | Value never read by `TCPListener.accept_connection` (`tcp.mojo:84-95`); slot lists grow monotonically and are never reclaimed (`listener.mojo:84-88`); serialized accept loop ⇒ head-of-line starvation | HIGH | **ABSENT** — declared-unenforced |
| T-7 | Queue exhaustion | `publish` → `Queue.enqueue` | **Enforced**: capacity check returns `False` (`queue.mojo:80-88`, `_total_count` includes unacked `71-73`), wired from `config.default_queue_capacity` (`broker.mojo:50` → `api.mojo:112` → `router.mojo:63`) | Byte-based limit absent (count only ⇒ 1024 × arbitrarily large bodies); full-queue publish is a **silent drop** — no `basic.return`, no flow control, no confirm; `reject()` requeues without a redelivery-count cap ⇒ poison-message loop (`queue.mojo:130-136`) | MEDIUM | **IMPLEMENTED** (count bound) / PARTIAL (fate-on-full undocumented) |
| T-8 | Management-API attacker | No management API exists | Read-only projection only (`status.mojo:3-4`, `broker.mojo:138-154`); no per-frame management call | n/a | — | **NOT-REACHABLE-YET** (keep §26 constraint: management must not become routing authority) |
| T-9 | Local UDS attacker | `UDSListener.start` → `UnixListener.bind` (`uds.mojo:42-51`) | Stale-path unlink handled by flare (`vendor/flare/flare/uds/listener.mojo:132-134`) | No `chmod`/`fchmod` on the socket, no explicit `UMask=` in the unit ⇒ reachability depends on inherited umask; no `SO_PEERCRED` peer-uid check anywhere; path in a shared dir ⇒ squat/symlink race window between `unlink` and `bind` | MEDIUM | **PARTIAL** — see §4 |
| T-10 | Filesystem compromise | Config is compiled-in defaults only; **no file is read at start-up** (`main_listen.mojo:18`, `config.mojo:134-138`) | `ProtectSystem=strict`, `ProtectHome=true`, `PrivateTmp=true` (`hyrxmq.service:23-25`) | No `ReadWritePaths=`/`RuntimeDirectory=`/`StateDirectory=` (so no legitimate writable location under `strict` — which is also why the UDS path is unusable as packaged); no integrity/secret-file policy | LOW→MEDIUM | **PARTIAL** |
| T-11 | Service privilege escalation | Binary at `/usr/local/bin/hyrxmq-listen` (`hyrxmq.service:19`) | `User=`/`Group=hyrxmq` (`:20-21`), `NoNewPrivileges=true` (`:22`), `ProtectSystem=strict` ⇒ `/usr` read-only | `DynamicUser=` absent ⇒ user existence is an implicit install precondition; no `CapabilityBoundingSet=`, `AmbientCapabilities=`; no `RestrictNamespaces`, `RestrictSUIDSGID`, `ProtectKernel*`, `PrivateDevices`, `SystemCallFilter`; unit lifecycle NOT validated on a clean host (per its own header) | MEDIUM | **PARTIAL** — see §6 |

---

## 2. Untrusted-input handling: `feed_bytes` + `try_parse_frame`

Answering the three questions posed, with line numbers.

### (a) Uncontrolled memory growth — **YES, confirmed**

`AMQPFrameCodec` holds a single `List[UInt8] _buffer` (`frame_codec.mojo:72`) built
with **no capacity argument and no limit field** (`frame_codec.mojo:74-75`).

* `feed_bytes` (`frame_codec.mojo:77-80`) appends every received byte, unconditionally.
  No cap, no check, no raise.
* `try_parse_frame` (`frame_codec.mojo:82-120`) reads a 4-byte big-endian length into
  `size: UInt32` (`frame_codec.mojo:92-97`), computes `total = 7 + Int(size) + 1`
  (`:100`) and, when the buffer is short, **returns None and keeps the bytes**
  (`:101-102`). It never compares `size` against any maximum.
* The listener feeds `65536`-byte chunks (`listener.mojo:25-26`, `:109`, `:114`) into
  that buffer in a loop (`listener.mojo:145-149`) with no byte budget and no deadline.

Cost to an attacker: send `type(1) channel(2) size=0xFFFFFFFF` (7 bytes) and then
trickle. The process retains up to ~4 GiB per connection before the parse can either
succeed or fail. The AMQP 0-9-1 negotiated `frame-size` ceiling (and `config.frame_max`,
default 131072, `config.mojo:68`) is **never consulted on this path** — `AMQPFrameCodec()`
is constructed with no arguments at `listener.mojo:86`, and
`grep -n "frame_max\|max_frame_size" src/hyrx/amqp/frame_codec.mojo` = **no hits**.
Even the well-formed first 8 octets of a genuine AMQP client header
(`AMQP\x00\x00\x09\x01`) are parsed as a frame with `size = 0x50_00_00_09` (≈1.3 GiB)
because no header detection exists — i.e. the growth trigger fires without any
adversary effort, which is also a correctness bug (§10).

Amplifier (secondary): `try_parse_frame` rebuilds the leftover buffer byte-by-byte
(`frame_codec.mojo:115-118`) and copies the payload byte-by-byte (`:105-107`), so a
pipelined stream of N frames costs O(N²) byte appends — CPU DoS on well-formed input.

### (b) Integer issues on `size` before the bounds check — **no exploitable overflow on this platform; one latent portability hazard**

`Int(size)` at `frame_codec.mojo:100,106,110` widens a `UInt32` to a 64-bit `Int`,
so `7 + Int(size) + 1` cannot wrap on Linux x86-64; max `total` ≈ 4.29e9 + 8, which
fits. The bounds reasoning is sound: the payload loop end `7 + Int(size)` (`:106`) and
the end-byte index `self._buffer[7 + Int(size)]` (`:110`) are both reached only after
`len(self._buffer) >= total` (`:101-102`), so `7 + Int(size) ≤ len-1`. **No
out-of-bounds read is reachable via `size`.** Residual notes: (i) if `Int` were ever
32-bit, `7 + Int(size)` overflows for `size ≥ 2^31-8` — no guard exists, so the safety
is an implicit platform assumption, not a checked invariant (violates §13 "validate
invariants explicitly"); (ii) `HeaderFrame.body_size: UInt64` is assembled from the
wire without any bound (`frame_codec.mojo:276-285`) and no max-message-bytes limit
exists anywhere, so the queue-bytes axis of §7 is unbounded.

### (c) Panic/raise the listener does not catch — **YES: two uncaught raise paths ⇒ broker death**

`raise` sites reachable from untrusted bytes, and the absence of any handler
(`grep -n "try\|except" src/hyrxmq/listener.mojo src/hyrxmq/main_listen.mojo` →
no hits):

1. `frame_codec.mojo:112` — `raise "AMQP frame end byte mismatch"`. A peer sends a
   correctly-sized frame with any trailer other than `0xCE`. `try_parse_frame` is
   called unguarded at `listener.mojo:107` and `:115`; `serve_one_frame` (`raises`),
   `accept_and_serve_one` (`raises`) and `serve_forever` (`raises`) propagate to
   `main() raises` (`main_listen.mojo:17,32`). One ~9-byte frame kills the broker,
   every connection with it. Directly contradicts `docs/SECURITY.md:59`
   ("A malformed client must not crash the process"). The existing test only asserts
   the *raise* happens (`tests/phase6/frame_codec_test.mojo:298-310`) — it never
   asserts the *listener survives*, which is the actual security property.
2. `router.mojo:161-162` — `raise "register_consumer: queue not found"`, reached via
   `basic.consume` on an undeclared queue (`amqp_service.mojo:330-339` →
   `adapter.mojo:113-125` → `api.mojo:136-140` → `router.mojo:154-166`). Same
   uncaught propagation. A single hand-built frame crashes the process with no
   negotiation, no credentials, no state.
   Minor extras: `frame_codec.mojo:249` and `:275` (`weight must be zero`),
   `buffer_pool.mojo:61` (pool exhausted) are likewise `raises` with no catch, and the
   frame-end-byte check inside `parse_header_frame_payload` is a `raise` too.

Classification: **BUG / SECURITY ISSUE / MISSING VALIDATION** (spec §29). The Mojo
runtime behaviour of an error escaping `main()` (clean non-zero exit vs abort) is
**NOT PROVEN** here — §9/§13 must execute it. Either outcome is a release blocker
under §13 ("crash … connection leak … is a release blocker").

---

## 3. Bounded resources: declared vs enforced (spec §7 cross-check)

| Limit | Source | Enforced? | Where / gap | Status |
|---|---|---|---|---|
| Queue depth (message count) | `config.default_queue_capacity` (`config.mojo:60,70`) → `HyrxConfig` (`broker.mojo:47-54`) | **YES** | `queue.mojo:85-88` returns `False` on full; `_total_count` includes unacked (`queue.mojo:71-73`) | IMPLEMENTED |
| Queue bytes | none | **NO** | No byte counter in `Queue`/`QueueConfig` (`queue.mojo:21-32,50-66`) | ABSENT |
| Message size | none | **NO** | `HeaderFrame.body_size` unbounded (`frame_codec.mojo:276-285`); inline publish body takes all remaining payload bytes (`amqp_service.mojo:325`) | ABSENT |
| `frame_max` (codec) | `config.frame_max` (`config.mojo:58,68`), `HyrxMQConfig.validate` positivity only (`config.mojo:146-147`) | **NO** | Copied to `tcfg.max_frame_size` (`listener.mojo:42`) then **never read**; `AMQPFrameCodec` has no limit field (`frame_codec.mojo:72-80`); `AMQPConnectionState._frame_max` never gates anything (`connection_state.mojo:70,91-102`, self-documented `:17-18`) | **DECLARED-BUT-UNENFORCED** |
| `max_connections` | `config.max_connections` (`config.mojo:57,67`), `tcfg.max_connections` (`listener.mojo:41`) | **NO** | `TCPListener` stores `_config` but `accept_connection` never compares active count (`tcp.mojo:35-95`); `TransportConfig` is write-only on the listener side; slot lists never shrink (`listener.mojo:84-88`) | **DECLARED-BUT-UNENFORCED** |
| Channels per connection | `channel_max` | **NO** | Field exists, no tune round trip, no dispatch check (`connection_state.mojo:69,91-99`; `amqp_service.mojo:12-14` header) | **DECLARED-BUT-UNENFORCED** |
| Heartbeat / idle timeout | `config.heartbeat_secs` (`config.mojo:59,69`) | **NO** | Validated non-negative (`config.mojo:150-151`), never used; no timers, no read deadline | **DECLARED-BUT-UNENFORCED** |
| Buffer-pool `max_slabs` | `HyrxConfig._buffer_pool_max_slabs` = 64 (`api.mojo:28,38`, `broker.mojo:52`) | **YES, but dead** | `buffer_pool.mojo:60-61` raises on exhaustion; however the pool is not used by the publish/consume path (architecture_audit F-14) ⇒ not a real memory bound for the messaging hot path | PARTIAL |
| Consume flush per reply | `_CONSUME_FLUSH_MAX` = 128 | **YES** | `amqp_service.mojo:75-76,389` (bounded loop count; body size per frame still unbounded) | IMPLEMENTED |
| Exchange / queue / binding counts | none | **NO** | `router.mojo:39-92` inserts without limit ⇒ unbounded topology growth from repeated `*.declare`/`queue.bind` | ABSENT |
| Consumer count | none | **NO** | `router.mojo:154-166` | ABSENT |
| Codec buffer | none | **NO** | See §2(a) | ABSENT (critical) |
| Process memory / fds (OS) | none | **NO** | No `MemoryMax`, no `LimitNOFILE` in `hyrxmq.service`; note `max_connections=1024` exceeds the typical 1024 fd default ⇒ the *unconfigured* fd limit, not the app limit, binds first | ABSENT |

**Summary of declared-but-unenforced:** `frame_max`, `max_connections`,
`heartbeat_secs`, `channel_max`, `TransportConfig.{max_frame_size,max_connections}`,
`AMQPConnectionState.frame_max/channel_max/heartbeat`, `BufferPool.max_slabs` (enforced
in isolation, absent from the live path).

---

## 4. UDS local attack

* **No permission hardening in our code.** `UDSListener.start` calls
  `UnixListener.bind(self._path)` with defaults (`uds.mojo:42-51`) and never
  `chmod`/`fchmod`s the socket. `grep -n "chmod\|umask\|0o0\|SO_PEERCRED" src/hyrx/transport/uds.mojo`
  → no hits. The socket's mode is therefore whatever `bind(2)`+inherited umask produce.
  With the usual `umask 022` others lack write and cannot `connect`, but that protection
  is **accidental, not a control**: the systemd unit sets no `UMask=`
  (`hyrxmq.service:11-27`), so an environment change (e.g. `umask 0`, a container
  default) silently makes the broker's IPC socket world-connectable. Same for TCP: no
  `bind_address` restriction is applied by any code path other than the `0.0.0.0`
  default (`config.mojo:65`).
* **Path squatting / TOCTOU.** flare `unlink(2)`s the path before `bind(2)`
  (`vendor/flare/flare/uds/listener.mojo:132-134`) and `__deinit__` unlinks again
  (`:82-88`). The unlink is silent on failure. If the socket path lives in a
  world-writable directory, a local attacker who creates the path (or a symlink) first
  causes the broker to remove an attacker-named inode and rebind, and the unlink→bind
  gap is a race window. No check that the parent directory is private, and no owner/mode
  verification of a pre-existing file.
* **No peer authentication.** No `SO_PEERCRED`/`getpeereid` anywhere, so a UDS
  connection carries no local-identity assertion — this will matter exactly when authz
  is designed (§18 "local socket permissions"), because a broker that trusts "UDS ⇒ local
  ⇒ trusted" has no mechanism to prove the "local ⇒ which uid" step.
* Note: as packaged, the UDS path cannot even be used — `ProtectSystem=strict` with no
  `RuntimeDirectory=`/`ReadWritePaths=` leaves no writable location for the socket.
  Recommendation in §6/§7.

---

## 5. Credentials and TLS — NOT IMPLEMENTED (do not claim otherwise)

* **No authentication.** No SASL, no `connection.start`/`start-ok`/`secure`/`secure-ok`
  (`connection_state.mojo:10-12`; `amqp_service.mojo:27-29`); no user/credential store.
  `grep` for `sasl|tls|password|credential` over `src/` returns no code (only "authority"
  prose). **Any byte source is implicitly fully privileged.**
* **No authorization / vhosts.** `config.vhost` (`config.mojo:61,71`) is a display string
  in `status()` only (`broker.mojo:143`); it gates nothing. No resource/operation
  permissions (required by `docs/SECURITY.md:19-27`).
* **No TLS.** No TLS in the transport contract, `tcp.mojo`, or the unit; the unit header
  states TLS is not proven (`hyrxmq.service:6-9`). `docs/SECURITY.md:9-11` lists TLS as
  scope. **Status: NOT IMPLEMENTED.** Per spec §18:450 and §27, no security claim of any
  kind may be attached to the network path today, and every finding below is a claim
  about *absence of controls*, not about compromised controls.
* **Secrets.** No secret material is read (config is compiled-in defaults,
  `main_listen.mojo:18`, `config.mojo:134-138`), so there is no secret-exposure surface
  yet — and equally no `EnvironmentFile=`/secret-file policy for when there is.
* **Security event logging.** Absent. No security-relevant event is logged (only the
  start-up banner, `main_listen.mojo:24-31`). Rejected frames, malformed frames, full
  queues, and future auth failures are invisible ⇒ §18 "logging of security events" = ABSENT.

---

## 6. systemd hardening review (`packaging/systemd/hyrxmq.service`)

| Directive | Line | Assessment | Gap severity |
|---|---|---|---|
| `User=hyrxmq` / `Group=hyrxmq` | 20-21 | Good: dedicated service account (`docs/SECURITY.md:36`). But the account must pre-exist; unit header admits clean-machine lifecycle NOT PROVEN (`1-9`) | LOW (with `DynamicUser=` preferred) |
| `NoNewPrivileges=true` | 22 | Correct and effective anti-escalation primitive (T-11) | — |
| `ProtectSystem=strict` | 23 | Strong: `/usr`, `/etc`, `/var` read-only; protects the `ExecStart` binary. **But no writable path is granted**, so runtime dir, data dir and any UDS socket bind fail — a correctness blocker for the unit as shipped | MEDIUM (availability) |
| `ProtectHome=true` | 24 | Correct | — |
| `PrivateTmp=true` | 25 | Correct | — |
| `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6` | 26 | Correct and minimal for TCP+UDS; blocks `AF_NETLINK`/`AF_PACKET`/`AF_VSOCK`. Should also pin `IPAddressAllow=`/`Deny=` if the listen host is meant to be loopback-only | LOW |
| `Restart=on-failure` | 27 | Present, **but `RestartSec=` and `StartLimitIntervalSec`/`StartLimitBurst` are absent.** Combined with S-2 (one 9-byte frame ⇒ uncaught raise ⇒ exit) this converts a remote crash into a **crash-restart loop**: the broker flaps and never serves, and an attacker pays nothing to sustain it | **HIGH** |
| `Type=simple`, `ExecStart`, `[Install]` | 16,19,29-30 | Fine; `ExecStart` path is an absolute system path under `ProtectSystem=strict` | LOW |
| **Missing: `MemoryMax` / `MemoryHigh`** | — | The only effective backstop for S-1 (4 GiB/frame accumulation) and unbounded queues/bytes. Without it, one connection OOM-kills the host or the unit | **HIGH** |
| **Missing: `LimitNOFILE`** | — | Must exceed `max_connections` (1024) plus listeners; today the app limit is unenforced *and* the OS limit is default ⇒ fd exhaustion is the first failure, with unclear message fate (T-6) | MEDIUM-HIGH |
| **Missing: `ProtectKernelModules`, `ProtectKernelTunables`, `ProtectKernelLogs`, `ProtectControlGroups`, `ProtectClock`** | — | Cheap, compatible with operation; currently a container-escape/`/proc`-tamper surface | MEDIUM |
| **Missing: `RestrictNamespaces`, `RestrictSUIDSGID`, `RestrictRealtime`, `PrivateDevices`** | — | Reduce syscall/namespace/device surface from a process parsing untrusted bytes | MEDIUM |
| **Missing: `CapabilityBoundingSet=` / `AmbientCapabilities=`** | — | Broker needs none if bound to a high port, or only `CAP_NET_BIND_SERVICE` for 5672; `docs/SECURITY.md:40` lists "capability bounding" as a candidate control and it is not present | MEDIUM |
| **Missing: `SystemCallFilter=@system-service`** | — | The broker makes few syscalls; note flare uses raw `external_call` (`vendor/flare/flare/uds/_libc.mojo`) so this must be validated, not assumed (§32 no-guessing) | MEDIUM |
| **Missing: `ReadWritePaths=` / `RuntimeDirectory=` / `StateDirectory=`** | — | Required for a UDS path and any future durable state under `ProtectSystem=strict` | MEDIUM (availability) |
| **Missing: `UMask=`** | — | Directly closes the §4 "UDS reachability depends on inherited umask" accident | MEDIUM |
| **Missing: `WatchdogSec=` + `NotifyAccess=`, `ExecReload=`** | — | `serve_forever` cannot be preempted (`listener.mojo:155-157` documents that shutdown is process-level); a hung (not crashed) accept loop is undetectable and unrestartable | MEDIUM |
| **Missing: `PrivateNetwork=`/`IPAddressAllow=` for non-production**, `LogExtraFields`, `EnvironmentFile=` | — | Defense in depth; secret/config handling when config files land (§17) | LOW |
| **Missing: `Documentation=`, hardening of `Restart` on `stop()` semantics** | — | `stop()` cannot interrupt a blocked `accept()` (`listener.mojo:155-157`) ⇒ `TimeoutStopSec` should be explicit | LOW-MEDIUM |

**Verdict:** the shipped unit is a reasonable *starting* baseline (6 of the
`docs/SECURITY.md:33-42` candidates) but is **not adequate as a security boundary** for a
process that parses untrusted bytes: the three directives that would actually contain
S-1/S-2 and the connection-storm class (`MemoryMax`, `LimitNOFILE`, `RestartSec`/
`StartLimit*`) are all absent, and the strictness of `ProtectSystem=strict` is currently
paired with no writable path at all. Clean-machine validation (spec §16) has not been
performed, so all of the above is code-review, not runtime-validated.

---

## 7. Recommendations, ranked by severity (implement nothing here)

| Rank | Finding | Severity | Smallest fix | Owning audit WP |
|---|---|---|---|---|
| 1 | **S-1** Unbounded codec accumulation: `frame_codec.mojo:72-80,100-102` | CRITICAL | Give `AMQPFrameCodec` a `max_frame_size` ctor field, reject (raise/close) when `size > max` at `frame_codec.mojo:98` and when `len(_buffer) > max + 8` in `feed_bytes` (`:77-80`); pass `config.frame_max` at `listener.mojo:86` | **§7** (bounded resources) + **§13** (negative/fuzz), test in **§9** |
| 2 | **S-2** Uncaught `raise` in parse/dispatch kills the broker: `frame_codec.mojo:112`, `router.mojo:161-162`, no handler in `listener.mojo:107,115,129` | CRITICAL | Wrap the per-frame step in a `try` at `listener.mojo:107-129`, treat any raise as connection-fatal: close the socket, mark slot closed, continue serving; then add the missing gate (reject methods when state ≠ OPEN, `amqp_service.mojo:231`) | **§13** + **§14** (failure matrix) |
| 3 | No frame-length/state validation before parse; no protocol-header check ⇒ oversized `size` and genuine AMQP headers both treated as frames | HIGH | Check the 8-octet `AMQP\x00\x00\x09\x01` prefix at stream start, and validate `frame_type` against the known set, before feeding the codec | **§10** (conformance) + **§13** |
| 4 | `max_connections` declared-unenforced; connection slots never reclaimed (`listener.mojo:84-88`; `tcp.mojo:84-95`) | HIGH | Check `len(self._conns)` (live count) against `tcfg.max_connections` in `accept_one` and close/refuse beyond it; release slots on close | **§7** + **§9** |
| 5 | No message/queue **byte** bounds; `body_size` unchecked (`frame_codec.mojo:276-285`) | HIGH | Add max-body-size + max-queue-bytes to `QueueConfig`, enforced in `queue.mojo:80-88` | **§7** |
| 6 | Queue-full = silent drop, no `basic.return`/flow control/confirm | MEDIUM | Define and document fate-on-full; smallest honest step is an explicit doc + status counter, then a rejection signal on the publish path | **§7** + **§12** (RabbitMQ differential) |
| 7 | systemd: add `MemoryMax`/`MemoryHigh`, `LimitNOFILE`, `RestartSec=`+`StartLimit*`, `CapabilityBoundingSet=`, `RestrictNamespaces`, `RestrictSUIDSGID`, `ProtectKernel*`, `ProtectControlGroups`, `PrivateDevices`, `UMask=0077`, `ReadWritePaths=`/`RuntimeDirectory=`, `WatchdogSec=` | HIGH (given 1-2) | Unit-file edit only; validate on a clean host | **§16** (systemd validation) + **§18** |
| 8 | UDS socket mode is umask-accidental; no `SO_PEERCRED`; unlink→bind race (`uds.mojo:42-51`, `vendor/flare/flare/uds/listener.mojo:132-134`) | MEDIUM | Explicitly `chmod 0600` after bind (or set `UMask=` in the unit), require a private runtime dir, and read `SO_PEERCRED` into the connection record for future authz | **§9** + **§18** |
| 9 | Auth/authz/TLS entirely absent; vhost is cosmetic | CRITICAL (when reachable) | Specify before implementing (`docs/SECURITY.md:9-27`): SASL EXTERNAL for UDS, PLAIN over TLS for TCP, then vhost permission model. Do not advertise "secure" anywhere until tested (§18:450) | **§18** follow-up + **§10**/§11 (real-client interop requires auth) |
| 10 | No security-event logging (malformed frames, rejections, full queues, future auth failures) | MEDIUM | Add a counted/logged rejection path next to fix 2 | **§18** + **§27** (docs truth) |
| 11 | O(N²) byte-by-byte codec copy paths (`frame_codec.mojo:77-80,105-107,115-118`) ⇒ CPU DoS from well-formed pipelining | LOW-MEDIUM (measure first, spec §17/§20) | Replace with span/slice-based consume; requires a benchmark baseline before optimizing | **§19/§20** (performance) |

---

## 8. Confidence statement (spec §28 categories)

| Area | Confidence | Basis |
|---|---|---|
| S-1 unbounded-accumulation is a real code path | **HIGH** (static) | Direct read of `frame_codec.mojo:72-102` + `listener.mojo:107-115`; no cap symbol exists |
| S-2 uncaught-raise crash is a real code path | **HIGH** (static) | Propagation chain read end-to-end; no `try`/`except` in `src/hyrxmq/*` |
| S-2 crash ⇒ process termination (vs graceful exit vs abort) | **NOT PROVEN** | Not executed (read-only audit) — §13/§9 to demonstrate |
| Reachability by a remote raw-TCP peer | **MEDIUM-HIGH** | Code path reachable and ungated; listen binary not observed running; unit not validated (§16) |
| systemd directive semantics as listed | **NOT PROVEN** | `systemd-analyze security` / clean-host validation outstanding (§16, §32) |
| UDS mode is umask-derived | **MEDIUM** | No `chmod` in our or flare bind path; `bind(2)` mode behaviour not measured here |
| Absence of auth/TLS | **HIGH** | Exhaustive `grep` over `src/`; explicitly documented as NOT IMPLEMENTED in-module |

**Bottom line:** HyrxMQ currently has *protocol-level* boundedness claims that the code
does not honour (`frame_max`, `max_connections`, `channel_max`, `heartbeat_secs` all
declared-but-unenforced), and the one genuinely enforced bound (queue depth) protects
count but not bytes. The dominant risk is not a missing TLS stack — it is that
untrusted-byte parsing can grow memory without limit and can raise into an unhandled
path, in a unit configured to restart on failure. Both must become §13 negative/fuzz
tests before any "resource boundedness" or "security baseline" claim is made (spec §33:
`SECURITY BASELINE VALIDATED` is **NOT SATISFIED**).
