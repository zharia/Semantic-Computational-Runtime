# Milestone 0008: IPC Transport Swap

**Program Increment:** v0.0.1
**Milestone:** 0008 — IPC Transport Swap (out-of-process simulation)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Planned
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract **unchanged — layout-neutral (asserted)** + Unix-domain-socket framing transport behind `ITransport`; in-process remains default (IPC opt-in)
**Scene Scope:** Core slice — same scene semantics, transport swapped; no content change
**Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (sibling — `104_contract.md` §2 was designed for exactly this swap)

---

## 1. Scope & Objective

Move the simulation core **out of the Godot process** without changing what crosses the boundary:

- **New server entry** in `applications/godot/src/mojo/server/` — the *same* sim core and encoder behind a new `main`, speaking a small framing protocol over a **Unix domain socket**, carrying the **existing snapshot bytes verbatim** plus input batches (and edit batches, if 0007 landed) upstream, with handshake/ack/error frames.
- **Adapter transport abstraction** — `ITransport` with two implementations (in-process `dlopen` = today's path; socket client = new), feeding the **same decode path**; adapter spawns and supervises the sim process.
- **AP-9 corrected at the new transport** — socket I/O runs on a worker thread with a lock-free latest-snapshot handoff; the render thread never blocks on I/O (structurally gated + measured).
- **Determinism is transport-independent** — same seed + same inputs ⇒ byte-identical snapshot sequence whether in-process or over the socket (strong exit test).

This fulfils the "IPC transport swap" row of [milestone 0002 spec §10](../milestone_0002_scene-initiation/spec.md) and the deferral note in `104_contract.md` §2.

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice | Rationale / recommended default |
|---|---|---|
| Process model | Out-of-process **sim server**: `src/mojo/server/main.mojo` (new entry over the existing core + `snapshot/encode`); binary `build/scr_sim_server` | Same semantic consumer, new main only — no fork of the core (Rule 15) |
| Endpoint | **Unix domain socket**, filesystem path resolved by the adapter at runtime from Godot `user://` (`OS.get_user_data_dir()`), passed to the server as argv; stale socket file unlinked before bind | Prompt-recommended default; keeps AP-4 (no absolute paths in sources — runtime argv is not source). Linux abstract namespace and **TCP loopback (127.0.0.1, ephemeral port via argv)** recorded as open alternatives, not defaults |
| Framing protocol | Header `u32 magic = 0x54524353 ('S C R T'), u32 type, u32 seq, u32 length, payload[length]` (little-endian). Types: `1 HELLO {proto, abi, schema, flags}`, `2 HELLO_OK {proto, abi, schema}`, `3 ERROR {code, u32 msg_len, msg}`, `4 SNAPSHOT {payload = RenderSnapshot bytes}`, `5 INPUT {payload = scr_input_batch (20 B)}`, `6 EDIT {payload = scr_edit_batch}` (capability-flagged; absent ⇒ ERROR), `7 ACK {ack_seq}`, `8 BYE`, `9 CMD_TICK {u32 n}` (manual pace only) | Minimal, explicit, testable without Godot; `SCR_SIM_IPC_PROTO_VER = 1` is independent of ABI/schema versions |
| Handshake / version gate | Client sends `HELLO{proto, abi, schema}`; server replies `HELLO_OK` **iff** all three match its own, else `ERROR` + close. Client likewise validates `HELLO_OK` against its compiled constants and refuses on mismatch — **same refusal semantics as the in-process `dlopen` gate** | Mirrors `104_contract.md` §3/§7 behavior at the new transport; version drift is loud, never silent |
| Payload neutrality (**layout-neutral claim**) | `SNAPSHOT` payload = the **exact existing snapshot byte stream** — envelope, section ids, section bytes, input batch: **this milestone changes no snapshot layout and does NOT bump `SCR_SIM_SCHEMA_VER` or `SCR_SIM_ABI_VERSION`** (asserted by test §7). Framing is a transport layer *above* the contract; 0006/0007 schema/ABI bumps (if executed) pass through untouched | Prompt requirement + `104_contract.md` §2 ("a later IPC transport must carry the same byte stream"). A sibling that changes layout rebases the *bytes*, not this protocol |
| Tick pacing | **Server owns the fixed 60 Hz timestep**; one `SNAPSHOT{seq}` per executed tick; `seq` strictly monotonic per session. **Coalescing:** if the socket is backpressured, the writer keeps only the newest snapshot (latest-wins); the client drops any `seq ≤ last_applied`. Optional `HELLO` flag `SCR_IPC_FLAG_MANUAL_PACE` ⇒ server executes exactly `CMD_TICK{n}` fixed ticks (client-commanded *count*, sim-owned *timestep*) — used by the determinism harness | Prompt-locked default (per-tick + coalescing + sequence numbers). Manual pace makes the byte-identical test well-defined without wall-clock coupling; it is an explicit capability flag, documented, not a semantic change |
| Transport abstraction | `ITransport` (C++) in the adapter: `InprocTransport` (existing `dlopen` + ABI calls) vs `SocketTransport` (connect, worker thread, framing); **one decode path** downstream of `read_snapshot()` | `lib/804_Application` Adapter substitutability (`APP-ADP-002`): swapping adapters must not change Port semantics |
| Selection & default | **Default = in-process** (byte-for-byte today's behavior). Opt-in: environment `SCR_SIM_TRANSPORT=socket` (env overrides scene/project setting `scr/transport`); anything else ⇒ in-process | Prompt-locked: safety default unchanged until explicit opt-in |
| Supervision | Adapter **spawns + supervises the server via OS API** (`posix_spawn`/`fork+exec`), server path from env `SCR_SIM_SERVER_BIN` (default `build/scr_sim_server`, repo-relative); on crash/EOF ⇒ restart with backoff `100 ms → 200 → 400 → 800 → 1600 ms` (cap 2 s); **> 5 restarts within 30 s ⇒ fatal error, stop stepping** (loud, honest) | Prompt-recommended default (adapter-owned lifecycle). Restart = fresh session with the **same seed** (world regenerates ⇒ TERRAIN/FLORA re-emit via presence rules; tick counter resets — logged loudly as a session restart) |
| Threading (AP-9) | Socket read/write + framing live on **one worker thread**; handoff to render thread = **seqlock double-buffer with atomic sequence** (lock-free latest-snapshot slot; reader retries on torn read); inputs/edits go the other way through an **SPSC ring (depth 16)** — if full, the adapter **merges new deltas into the newest queued batch** (never drops look deltas) | Render thread never does socket I/O, never blocks on a mutex held by the worker; AP-9's lesson applied at the new transport |
| Connection model | **Single client** per server; a second concurrent connection is refused with `ERROR`; server exits on `BYE` or client EOF | Simplest correct model; multi-client = successor |
| Determinism contract | Same seed + same input/edit sequence + fixed `dt` ⇒ **byte-identical snapshot sequence regardless of transport** (in-process vs socket, same tick count) | Direct consequence of the untouched encoder + transport-independent core; §7 makes it the strongest gate |
| Sibling rebasing (stated once) | If siblings 0003–0007 executed first, they may have bumped `SCR_SIM_SCHEMA_VER`/`SCR_SIM_ABI_VERSION`; this milestone **carries those values through the handshake unchanged** and never allocates section ids — layout remains whatever the then-current contract says | 0008 is layout-neutral by construction; nothing to rebase except the compared constants in tests |

### 1.2 Open decision — confirm before drafting final

- **Socket location:** default = **filesystem path under Godot `user://`** (portable, inspectable; adapter unlinks stale files before bind). Linux **abstract namespace** (`@scr-sim`) avoids stale files entirely but is Linux-only. Recommend filesystem path + unlink; confirm before finalizing (Rule 19).

### 1.3 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

The transport is an **implementation detail below the contract**: Port semantics (snapshot down, input/edit up) are unchanged, snapshot bytes are unchanged, determinism is unchanged. If swapping transports changes any of those, the swap is wrong.

---

## 2. Lessons & Anti-pattern Constraints (Normative)

### 2.1 Continuing normative constraints — milestone 0002 §2

[Milestone 0002 §2.1 AP-1 … AP-10](../milestone_0002_scene-initiation/spec.md) remain fully normative — linked, not re-tabled. **AP-9** ("no socket I/O on render thread") is the central constraint of this milestone and is re-verified with new, stronger gates (§7). AP-10 (provider control docs) governs the contract/`102` updates; AP-4 (no absolute paths) constrains server-path handling (runtime argv/env only).

### 2.2 New milestone-specific anti-patterns (this milestone only)

| # | Anti-pattern | Required correction |
|---|---|---|
| AP-15 | **Render-thread socket I/O** (AP-9 reborn at the new transport): `recv`/`send`/framing on the frame path | All socket I/O + framing on the worker thread; render thread reads the seqlock slot only. Gates: structural grep (no socket syscalls in the apply/frame path) + measured stall test (server SIGSTOP'd ⇒ frame time stays under `FRAME_DT_CLAMP`) |
| AP-16 | **Transport-aware payload** — encoder branches on transport, server "helpfully" re-wraps/normalizes bytes, client-side re-encoding | Single encoder; `SNAPSHOT` payload is copied verbatim end-to-end; exit gate: in-process vs socket sequences **byte-identical** |
| AP-17 | **Silent version drift** — connection accepted despite proto/abi/schema mismatch, or errors coerced into empty frames | Handshake refusal both directions; `ERROR` frames logged loudly; negative tests for both directions (§7) |
| AP-18 | **Orphan/zombie servers** — spawned process leaked on exit, no restart policy, no backoff (unbounded crash loops) | Adapter owns PID lifecycle (spawn, reap, restart-with-backoff, cap ⇒ fatal); crash/restart test asserts exactly one live server PID and recovery |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over milestone 0002 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot process                                                          │
│  godot/scenes/island.tscn ─ unchanged content (0006/0007 sections too) │
│  adapter/scr_godot_adapter.cpp                                          │
│    decode path ─ unchanged (read_snapshot → apply_*)                    │
│    ┌ ITransport ─────────────────────────────────────────────┐          │
│    │ InprocTransport: dlopen + scr_sim_* (today's behavior)  │          │
│    │ SocketTransport: connect → worker thread → seqlock slot │          │
│    └─────────────────────────────────────────────────────────┘          │
│    supervision: spawn/respawn scr_sim_server (backoff, PID accounting)  │
│    render thread: latest-slot read (non-blocking) + SPSC input ring     │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ Unix domain socket (opt-in; default in-proc)
                                │ frames: HELLO/HELLO_OK/ERROR, SNAPSHOT↓,
                                │ INPUT/EDIT↑, ACK, BYE, CMD_TICK
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ scr_sim_server (separate process) — src/mojo/server/                    │
│   server/main.mojo  : CLI entry (seed, socket path, pace mode)          │
│   server/session.mojo: handshake, framing loop, backpressure/coalescing,│
│                        fixed 60 Hz pacing (or CMD_TICK manual pace)    │
│   sim core + snapshot/encode : IDENTICAL code to in-process path        │
│   owns: world state, ticks, snapshot bytes (unchanged contract)         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Framing protocol (normative draft for `104_contract.md` §2 replacement)

Little-endian; frame = `magic('SCRT'=0x54524353) | type | seq | length | payload[length]`.

| Type | Dir | Payload | Semantics |
|---|---|---|---|
| 1 `HELLO` | C→S | `u32 proto, u32 abi, u32 schema, u32 flags` | First frame. `flags` bit0 = `SCR_IPC_FLAG_MANUAL_PACE` |
| 2 `HELLO_OK` | S→C | `u32 proto, u32 abi, u32 schema` | Sent iff all three match the server's own values; else (3) |
| 3 `ERROR` | both | `u32 code, u32 msg_len, bytes msg` | Loud refusal/diagnostic; sender closes after a fatal error |
| 4 `SNAPSHOT` | S→C | exact `RenderSnapshot` bytes | One per executed tick; `seq` monotonic per session; **payload byte-identical to the in-process `scr_sim_snapshot_write` output for the same tick** |
| 5 `INPUT` | C→S | `scr_input_batch` (20 B) | Applied to the tick(s) it precedes (same per-batch semantics as `scr_sim_step`) |
| 6 `EDIT` | C→S | `scr_edit_batch` (4 B, if 0007 landed) | Capability-flagged in `HELLO`; server without edit support ⇒ `ERROR` |
| 7 `ACK` | S→C | `u32 ack_seq` | Server confirms consumption (input/edit window accounting) |
| 8 `BYE` | both | — | Graceful shutdown; server exits after flushing |
| 9 `CMD_TICK` | C→S | `u32 n` | Only valid when `MANUAL_PACE` was handshaken: execute exactly `n` fixed ticks, emitting `SNAPSHOT` per tick |

**Version policy:** `SCR_SIM_IPC_PROTO_VER` (framing/handshake) changes only with framing changes. `abi`/`schema` mirror `scr_sim_abi_version()` / `scr_sim_schema_version()` of the *running* core. Mismatch ⇒ refuse (same behavior as the in-process gate). **This milestone changes neither `SCR_SIM_ABI_VERSION` nor `SCR_SIM_SCHEMA_VER`** (§1.1 layout-neutrality).

**Backpressure:** writer sends non-blocking; on `EAGAIN` it keeps only the newest snapshot frame (latest-wins coalescing); client discards stale `seq`. Inputs are reliable-ordered (UDS) — the SPSC ring merge-on-full rule (§1.1) prevents delta loss client-side.

### 3.3 Threading & handoff (AP-9/A P-15)

```text
render/physics frame thread          transport worker thread
  submit_input/edit ─► SPSC ring ──►  recv frame / send INPUT,EDIT
  read latest snapshot ◄── seqlock ◄──  recv SNAPSHOT → publish (odd/even seq)
  apply_* (O(snapshot), no I/O)
```

Seqlock slot: writer sets `seq` odd → fills buffer → sets even; reader reads `seq` (even), copies, re-reads `seq` — retry if changed or odd. Worst case = one retry; **no mutex, no block**.

### 3.4 Determinism across transports

Identical inputs to identical code ⇒ identical bytes. The socket path adds framing **around** the encoder output; it never touches payload bytes (AP-16). Pacing differences (wall-clock vs manual) affect *when* ticks run, not *what* a tick computes — so the harness compares **same tick count, same input/edit sequence**: in-process (`scr_sim_step(dt=1/60, input)` × N) vs socket (`CMD_TICK` + `INPUT` frames × N) ⇒ concatenated snapshot streams compared byte-for-byte (§7).

---

## 4. Semantic Library Consumption

| Domain / ID | Concept consumed (verified on disk) | Consumption mode |
|---|---|---|
| `SCR-APP-*` (`lib/804_Application/101_definition.md` + children) | Parent: §12 Port (inbound/outbound), §13 Adapter, §14 Provider, §15 Service–Port–Adapter–Provider Boundary. Children (**real short definitions, verified**): `Port/` — `APP-PRT-001` boundary explicitness (all dependencies cross declared Ports), **`APP-PRT-002` technology neutrality (Ports MUST NOT reference socket formats/IPC mechanisms)**; `Adapter/` — `APP-ADP-001` boundary isolation (technology must not contaminate core semantics), **`APP-ADP-002` substitutability (replacing an Adapter must not modify Port semantics)**; `Provider/` — `APP-PRV-001` provider subordination, `APP-PRV-002` no provider leakage beyond the Adapter, `APP-PRV-003` provider replacement | The whole milestone is a literal exercise in these invariants: the Port (snapshot down / input-edit up, `104_contract.md`) is unchanged; Unix sockets, `dlopen`, process spawning exist **only** behind `ITransport` (Adapter layer); the spawned server is a Provider-ish runtime subordinate to the contract. Conformance = structural review + byte-identity test (AP-2 style, §7) |
| `lib/503_Simulation` parent (`101_definition.md`) | Scope includes snapshots, state deltas, simulation streams, deterministic simulation, distributed simulation, reproducibility. **§Deterministic Simulation:** uniquely defined semantic trajectory given equivalent model/state/parameters/inputs/environment/temporal conditions; *implementation-level nondeterminism MUST be distinguished from semantic nondeterminism*. **§Distributed Simulation:** distribution MAY involve processes; *distributed execution MUST NOT alter semantic meaning merely because state is physically partitioned*. §Streaming, §Reproducibility/Provenance | Normative backing for §3.4 (transport = implementation-level concern, semantics identical) and for session-restart honesty (a restarted process is a new session, logged, not silently the same trajectory). **Honest note:** children `Snapshot/`, `State/`, `Synchronization/`, `Distributed/` are **structural stubs** (each `101_definition.md` states "No substantive semantic contract is inferred from the directory's existence alone") — therefore only the parent definition is cited; no child-specific semantics are invented |
| `SCR-LIB-IDENTITY` (`lib/101_Core/Identity/101_definition.md`) | §2 layer 9: **Manifestation** = "the ephemeral, runtime-specific representation (memory pointer, GPU buffer handle, actor ID, **socket**) that physically embodies the semantic entity during execution" — distinct from SID/semantic identity | The socket endpoint/PID is a *manifestation*, never an identity: session identity is established by the version handshake (`HELLO`), and process restart produces a new manifestation of the same seeded world (logged as session restart) |
| `lib/A01_Render/HUD`, `lib/705_Ecology`, `lib/601_Agent`, `lib/501_Physics` | — | Not consumed; content milestones (0006/0007) are transport-agnostic and pass through unchanged |

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── server/
│   │   ├── main.mojo                 # NEW: out-of-process entry (seed, --socket, --pace args)
│   │   └── session.mojo              # NEW: handshake, framing loop, pacing, backpressure, ACK/BYE
│   ├── transport/
│   │   └── framing.mojo              # NEW: frame codec (magic/type/seq/len + payload views) — no engine types
│   └── (sim core, snapshot/, export/ : UNCHANGED — shared with in-process path)
├── providers/render/graphics/godot/
│   ├── 104_contract.md               # §2 rewritten: framing protocol, handshake, pacing, neutrality assertion; §3 symbols unchanged
│   ├── 102_status.yaml               # + transport capability
│   └── adapter/
│       ├── scr_transport.h           # NEW: ITransport interface (read_snapshot/submit_input/submit_edit/connected)
│       ├── transport_inproc.cpp      # NEW: extracted dlopen path (behavior identical to today)
│       ├── transport_socket.cpp      # NEW: UDS client, worker thread, seqlock slot, SPSC ring
│       ├── scr_godot_adapter.cpp     # MOD: transport selection (env/setting), supervision, apply_* unchanged
│       ├── scr_godot_abi.h           # unchanged (ABI/schema values pass through)
│       └── SConstruct                # + new sources
├── scripts/
│   ├── build_sim_server.sh           # NEW: mojo build server/main.mojo → build/scr_sim_server
│   └── build_godot_provider.sh       # EXT: also builds server binary (single build entry)
├── tests/ipc/                        # NEW — headless, no Godot required
│   ├── ipc_harness.py                # frame client: handshake, INPUT/CMD_TICK, snapshot capture, error injection
│   ├── fake_server.py                # negative-test double (wrong schema/abi, stalls, dies)
│   ├── test_ipc_determinism.sh       # in-process vs socket byte-identical (N ticks, scripted inputs)
│   ├── test_ipc_version_refusal.sh   # wrong schema/abi both directions (harness ↔ server; fake_server ↔ adapter client)
│   └── test_ipc_crash_restart.sh     # kill server mid-run ⇒ respawn + handshake + snapshots resume; orphan check
├── tests/godot/
│   ├── godot_ipc_smoke.sh            # headless load with SCR_SIM_TRANSPORT=socket (0 ERROR lines)
│   └── godot_render_stall_test.sh    # server SIGSTOP ⇒ frame times stay < FRAME_DT_CLAMP; grep gate for socket syscalls
├── docs/04_simulation_engine.md      # + transport section (protocol, threading, supervision, determinism note)
├── docs/05_provider_boundary.md      # + binding: ITransport behind the Port (APP-PRT-002)
├── docs/06_roadmap.md                # + 0008 status row
└── program_increments/v0.0.1/milestone_0008_ipc-transport/spec.md   # this file
```

### Sprint 01 — Framing protocol + server entry (headless)

- `framing.mojo` codec + `server/{main,session}.mojo`: handshake, single-client accept, pacing (wall-clock 60 Hz + manual `CMD_TICK`), backpressure coalescing, ACK/BYE/ERROR.
- `ipc_harness.py` (pure Python client, no Godot) + `test_ipc_version_refusal.sh` (server-side direction: wrong proto/abi/schema ⇒ `ERROR` + close).
- Tests: framing round-trip, malformed-frame rejection, handshake matrix (match/mismatch × proto/abi/schema), one-tick snapshot byte-comparison against a direct encoder call.

### Sprint 02 — Adapter transport layer + threading

- `scr_transport.h`, `transport_inproc.cpp` (extracted, behavior-identical — in-process gates re-run to prove it), `transport_socket.cpp` (worker thread, seqlock slot, SPSC ring + merge-on-full).
- Transport selection: `SCR_SIM_TRANSPORT` env (overrides project setting `scr/transport`), default in-process.
- `test_ipc_determinism.sh`: N ticks, scripted inputs — in-process vs socket snapshot streams byte-identical (AP-16 gate).
- `godot_ipc_smoke.sh`: headless load with `SCR_SIM_TRANSPORT=socket`.

### Sprint 03 — Lifecycle, supervision + failure injection

- Adapter spawn/supervise (`SCR_SIM_SERVER_BIN`, argv socket path + seed), backoff restart, restart cap ⇒ fatal, PID reaping (AP-18).
- `fake_server.py`: wrong-schema client-direction refusal test; stall injection for the render-thread test.
- `test_ipc_crash_restart.sh` (kill mid-run ⇒ exactly one live server afterwards, handshake + snapshots resume, terrain presence rules re-delivered); `godot_render_stall_test.sh` (SIGSTOP stall ⇒ frame-time bound + structural grep gate).

### Sprint 04 — Docs + verification

- `104_contract.md` §2 replaced by the framing protocol + neutrality assertion (§3.2); `docs/04` transport/threading/determinism sections; `docs/05` Port-vs-transport boundary (`APP-PRT-002`); `docs/06` row.
- Full §7 gate run (all milestone 0002 gates in **both** transports) + item-by-item anti-pattern review (§2.1 AP-1..10 + §2.2 AP-15..18).

---

## 6. Formal Invariants

1. **Layout neutrality invariant:** this milestone changes no snapshot/uplink byte layout — `SCR_SIM_SCHEMA_VER`, `SCR_SIM_ABI_VERSION`, section ids, and the golden fixture are untouched; framing wraps bytes it never alters (AP-16, §7 test).
2. **Transport-independent determinism invariant:** same seed + same inputs (+ edits) + same tick count ⇒ byte-identical snapshot sequences for in-process and socket transports (`SCR-LIB-503` deterministic-simulation semantics: implementation nondeterminism ≠ semantic nondeterminism).
3. **Port semantics invariant:** `104_contract.md` downlink/uplink meanings unchanged; sockets/processes appear only inside the Adapter layer (`APP-PRT-002`, `APP-ADP-001/002`, `APP-PRV-001/002`).
4. **Version refusal invariant:** any proto/abi/schema mismatch ⇒ loud `ERROR` + refusal in both directions — behaviorally equivalent to the in-process startup gate (AP-17).
5. **Render-thread non-invariant-blocking invariant:** no socket I/O, no blocking locks on the frame path; render thread reads a lock-free latest slot (AP-9/AP-15, gated structurally + measured).
6. **Single-session invariant:** at most one connected client and one live server PID per adapter instance; spawn/reap/restart fully accounted (AP-18); > 5 restarts / 30 s ⇒ fatal, no crash loop.
7. **Safety default invariant:** without explicit opt-in (`SCR_SIM_TRANSPORT=socket` / `scr/transport = socket`), behavior is byte-for-byte the in-process path.
8. **Engine isolation invariant:** `src/mojo/server/`, `src/mojo/transport/` contain no Godot/engine types (AP-1 gate extended over the new directories).
9. **Path invariant:** no absolute paths in sources (AP-4) — socket path and server binary arrive via argv/env at runtime only.
10. **Honesty invariant:** session restart semantics (fresh world, same seed, tick reset) documented in `docs/04`; anything not implemented (TLS/auth, multi-client, cross-host) marked `TBD — future milestone` (§9).

---

## 7. Exit Criteria

All commands from repo root; `M=.venv/bin/mojo`.

- [ ] **Byte-identical in-process vs IPC snapshot sequences (automated, strongest gate):** `bash applications/godot/tests/ipc/test_ipc_determinism.sh` — same seed, scripted input sequence, N = 600 ticks; concatenates `SNAPSHOT` payloads from the socket session and `scr_sim_snapshot_write` outputs from the in-process run (via `tests/abi_smoke.py`-style FFI drive) and asserts **byte equality** (AP-16).
- [ ] **Schema/ABI mismatch refusal over IPC (automated, both directions):** `bash applications/godot/tests/ipc/test_ipc_version_refusal.sh` — (a) harness sends `HELLO{schema=99}` (and `abi=99`, `proto=99`) ⇒ server `ERROR` + close, no `SNAPSHOT` ever sent; (b) `fake_server.py` reports wrong `abi`/`schema` ⇒ adapter/client refuses loudly (ERR_PRINT + no frames applied) — mirrors `tests/test_schema_mismatch.sh` behavior.
- [ ] **Crash/restart recovery (automated):** `bash applications/godot/tests/ipc/test_ipc_crash_restart.sh` — kill server PID mid-run ⇒ adapter/harness observes EOF, restarts within backoff, re-handshakes, snapshots resume (fresh session logged, same seed); afterwards `pgrep -x scr_sim_server` shows **exactly one** live PID owned by the test (AP-18). Cap path exercised with `fake_server.py` crash-loop ⇒ fatal after > 5 restarts / 30 s.
- [ ] **Render thread never blocks on I/O (structural + measured):** (a) `bash applications/godot/tests/godot/godot_render_stall_test.sh` — with `SCR_SIM_TRANSPORT=socket` and the server `SIGSTOP`ped for 2 s, headless frame/physics-callback times stay `< FRAME_DT_CLAMP (0.05 s)` (asserted from script timings) and no `ERROR:` lines appear; (b) grep gate inside the script: zero socket syscalls (`socket|connect|recv|send|read|write`) in `scr_godot_adapter.cpp` apply/frame path (they exist only in `transport_socket.cpp` worker code).
- [ ] **Transport selectable, default in-process (automated):** default run (no env) ⇒ `godot_load_test.sh` PASS using `InprocTransport` (log line asserted); `SCR_SIM_TRANSPORT=socket bash applications/godot/tests/godot/godot_ipc_smoke.sh` ⇒ headless load PASS (0 `ERROR:` lines, log line asserts socket transport + handshake OK).
- [ ] **Server binary builds standalone (automated):** `bash applications/godot/scripts/build_sim_server.sh` ⇒ `build/scr_sim_server` exists and `python3 applications/godot/tests/ipc/ipc_harness.py --self-test` (handshake + 1 tick round-trip) passes without Godot.
- [ ] **Layout neutrality (automated + reviewed):** `SCR_SIM_ABI_VERSION` / `SCR_SIM_SCHEMA_VER` constants, `104_contract.md` §4/§5 byte tables, `src/mojo/snapshot/`, `src/mojo/export/abi.mojo` carry **no value changes from this milestone** (0008 performs **no fixture regeneration** — the fixture as inherited passes): `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_golden_fixture.mojo` PASS + `python3 applications/godot/tests/abi_smoke.py` PASS + `bash applications/godot/tests/test_schema_mismatch.sh` PASS, with the diff reviewed in Sprint 04.
- [ ] **All milestone 0002 gates green in both transports (automated):** the seven §8 procedures of `docs/04_simulation_engine.md` PASS — determinism/projection-purity/catalog/synthesis/Gerstner/golden-fixture headless (transport-independent), plus load/screenshot/playability gates re-run with `SCR_SIM_TRANSPORT=socket`.
- [ ] **Docs updated:** `104_contract.md` §2 (framing + neutrality assertion), `docs/04` (transport/threading/supervision/determinism), `docs/05` (Port vs transport), `docs/06` (0008 row).
- [ ] **Review pass:** §2.1 (AP-1..10) + §2.2 (AP-15..18) checked item-by-item; results appended to `docs/04`.

---

## 8. Dependencies

- **Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (Complete) — stabilized contract (`104_contract.md` §2 designed for this swap), C ABI, adapter decode path, determinism fixtures.
- **Content siblings (optional, pass-through):** [0006](../milestone_0006_ecology/spec.md), [0007](../milestone_0007_editing-physics/spec.md) — their sections/uplink frames ride the transport untouched; `EDIT` frame is capability-flagged (0007-dependent).
- **Semantic contracts:** `lib/804_Application` (+ `Port`, `Adapter`, `Provider`), `lib/503_Simulation` parent definition (children stubs — verified), `lib/101_Core/Identity`.
- **Contract surface:** [`providers/render/graphics/godot/104_contract.md`](../../../providers/render/graphics/godot/104_contract.md) (§2, §3, §7), [`docs/04_simulation_engine.md`](../../../docs/04_simulation_engine.md), [`docs/05_provider_boundary.md`](../../../docs/05_provider_boundary.md), [`docs/06_roadmap.md`](../../../docs/06_roadmap.md).
- **Toolchain:** unchanged (Mojo 1.0.0, Godot 4.7.2, godot-cpp; C++ toolchain for adapter — `docs/02_development_environment.md`); POSIX OS APIs for spawn/socket (Linux verified environment).

---

## 9. Out of Scope

- **TCP loopback / abstract-namespace endpoints** as defaults — recorded open alternatives (§1.1/§1.2); defaults are UDS filesystem path + in-process.
- Authentication, TLS/encryption, sandboxing of the child process — `TBD — future milestone` (local single-user trust model assumed; escalate before any network-exposed socket).
- Multi-client fanout, remote-host execution, compression/zero-copy shared memory, GPU interop — successors.
- Payload encoding changes (msgpack/protobuf), snapshot compression — forbidden by the layout-neutrality invariant (§6.1).
- Performance benchmarking/latency budgets beyond the render-thread stall gate — `TBD — future milestone` (carried from 0002 §9).
- MLIR dialect/lowering work (Rule 15).

---

## 10. Successor Milestones

| Intent | Triggering contracts |
|---|---|
| Hardened remote transport (TCP + auth) | `104_contract.md` §2 extension, `804_Application/{Port,Provider}` security semantics — Rule 10 requires a spec first |
| Multi-client / observer sessions | `503_Simulation` streaming + `804_Application` multi-port semantics |
| Content milestones riding the socket (flora, edits) | [0006](../milestone_0006_ecology/spec.md), [0007](../milestone_0007_editing-physics/spec.md) — pass-through, no transport work |
| Second scene (ocean/atmosphere lab parity) | `503_Simulation` scenarios (0002 §10) |

Exact sequencing beyond 0006/0007/0008: `TBD — future milestone` (Rule 10).
