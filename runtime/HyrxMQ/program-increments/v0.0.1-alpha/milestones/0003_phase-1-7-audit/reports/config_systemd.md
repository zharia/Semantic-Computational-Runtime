# Config Hardening (§17) + systemd Validation (§16) — HyrxMQ

**Scope:** `src/hyrxmq/config.mojo` + new `tests/phase7/config_invalid_test.mojo`.
**Out of scope (not touched):** `src/hyrxmq/main_listen.mojo` (owned by the
sibling env-override package), broker/listener/frame_codec/amqp_service/core,
any `systemctl start`, any Docker/RabbitMQ container. No file outside the
ownership list was edited.

**Suite:** `bash scripts/test_all.sh` → `TOTAL pass=35 fail=0` (was 34/0; the
added `config_invalid_test.mojo` is the +1, all existing config tests still
pass).

---

## Part A — §17 Configuration

### Config strategy (honest, current state)

| Surface | Status | Detail |
|---------|--------|--------|
| Defaults | AVAILABLE | `HyrxMQConfig()` sets host `0.0.0.0`, port `5672`, max_connections `1024`, frame_max `131072`, heartbeat `60`, queue_capacity `1024`, vhost `/`, node `hyrxmq@localhost`. |
| Parse from lines | AVAILABLE | `from_lines(List[String])` / `from_key_values(List[KeyValuePair])`. Pure, no I/O. |
| **File load from disk** | **NOT AVAILABLE** | Probe on this Mojo 1.0.0 build: `from os import Dir` → *"unable to locate module 'os'"*; `from sys import program` → *"unable to locate module 'sys'"*. No portable file-read. `load_from_file` is intentionally absent (see config.mojo NOTE). When the stdlib lands it must read bytes → `from_lines`. |
| Env-var override | STRATEGY (owned elsewhere) | The sibling package is adding `HYRXMQ_HOST`/`HYRXMQ_PORT` at the `main_listen.mojo` entry layer — **not implemented in this change** (that file is another package's ownership). Config layer stays pure; env/argv are the override path at the executable boundary. |
| CLI override | NOT YET | No argument parser wired into config; future entry-layer work. |
| Secret handling | NONE | No password/TLS-cert fields exist. **Not claimed.** |
| Reload semantics | NONE | Config is read once at startup; no SIGHUP reload. **Not claimed.** |
| Validation | AVAILABLE | Two layers — see below. |

### Validation layering

- **Type/structure layer — `apply()`** (`src/hyrxmq/config.mojo`): now REJECTS
  unknown fields and empty values, and coerces integers through `_require_int`
  which raises a **key-named** error instead of letting `Int()`'s raw message
  escape.
- **Value/range layer — `validate()`**: physical bounds (port, positives,
  non-negative heartbeat) plus defense-in-depth non-empty checks for
  `listen_host`/`vhost`/`node_name` (catches fields mutated directly, bypassing
  `apply`).

### §17 invalid-case coverage (all assert the ACTUAL result)

| §17 case | Before | After | Where |
|----------|--------|-------|-------|
| Unknown field | **silently ignored** (§17 gap) | **rejected** — `apply` raises `config: unknown field '<k>'` | config.mojo `apply` else-branch |
| Invalid type `port=abc` | `Int()` raised (no panic) but generic msg | **clean, key-named** `config: invalid integer for 'port' (got 'abc')` — caught, never a process panic | config.mojo `_require_int` |
| Out-of-range `port=99999` | caught | caught `validate()` | `validate` (pre-existing) |
| Out-of-range `frame_max=0` | caught | caught | `validate` (pre-existing) |
| Out-of-range `max_connections=-5` | caught | caught | `validate` (pre-existing) |
| Missing/empty value | **silently accepted** (empty string set) | **rejected** at `apply` (`config: empty value for '<k>'`) AND at `validate` for the string fields | `_require_text`/`_require_int` + `validate` |
| Duplicate field `port=1\nport=2` | **FIRST-wins** — latent bug: `pop()` reversed processing | **deterministic LAST-wins** — source-order application | `from_lines`/`from_key_values` |
| Invalid endpoint/host | not checked | empty/blank `listen_host` rejected by `apply` and `validate` | `_require_text` + `validate` |

**Negative proof** (`config_invalid_test.mojo`): every invalid input above
raises a *catchable* Mojo `raise` (asserted via `try/except`); a fully valid
config parses **and** `validate()`s with no failure. Because a hard panic would
abort the binary non-zero before the `PHASE7_CONFIG_INVALID_TEST=PASS` line, the
test's clean exit-0 + PASS line is itself evidence no invalid path panics.

### `validate()` / config changes — file:line (post-edit `src/hyrxmq/config.mojo`)

- Header policy comment rewritten (unknowns rejected, empty rejected, last-wins).
- `_require_text` / `_require_int` helpers added (new module-level fns, ~L44-70).
- `apply()` (≈L100): every int key → `_require_int`; every string key →
  `_require_text`; trailing `else: raise "config: unknown field ..."`.
- `from_key_values` (≈L135) / `from_lines` (≈L152): switched from reversed
  `pop()` drain to **in-order index application** (last-wins), then drain to
  consume the owned list.
- `validate()` (≈L176): added `listen_host`/`vhost`/`node_name` non-empty
  checks; existing range checks unchanged.

### Not enforceable here

- Env-var / CLI override and file-load are **entry-layer**, and file I/O has no
  stdlib support in this build — validated only to the point of *documenting*
  the gap, not shipping a loader. Secret/reload: intentionally absent.

---

## Part B — §16 systemd validation (read-only, no root)

### 1. `systemd-analyze verify packaging/systemd/hyrxmq.service`

```
nix-daemon.socket: Failed to open /etc/systemd/system/nix-daemon.socket: No such file or directory
hyrxmq.service: Command /usr/local/bin/hyrxmq-listen is not executable: No such file or directory
RC=1
```

**Classification**
- Line 1 (`nix-daemon.socket`): **host noise**, not our unit — a stray
  reference to a Nix socket that isn't in `/etc/systemd/system`. Ignore.
- Line 2 (`hyrxmq.service`): **warning**, expected — the unit's
  `ExecStart=/usr/local/bin/hyrxmq-listen` is not installed on this host.
- **No syntax errors** were reported for the unit → **unit SYNTAX is valid**.
- `RC=1` is caused by the ExecStart warning above; it does **not** indicate a
  malformed unit.
- Note: `verify` does *not* check `User=`/`Group=` existence — silence there is
  not proof those principals are valid.

### 2. Standalone startup/ready evidence (NOT systemd)

Built the non-listening self-check binary (from `src/hyrxmq/main.mojo`, which
does **not** open a socket — so it never collides with the live RabbitMQ on
5672):

```
pixi run mojo build -I src -I vendor/flare src/hyrxmq/main.mojo -o build/hyrxmq   # RC=0
./build/hyrxmq   # under timeout 20
```
```
HyrxMQ hyrxmq@localhost starting
HyrxMQ hyrxmq@localhost ready (... AMQP-over-TCP + broker handshake proven in tests/integration; TLS NOT PROVEN)
self-check=PASS (declare/publish/deliver/ack in-process)
status: ready=True queues=0 health=ok
run RC=0
```

The broker **starts, reports ready, self-checks, and exits 0 without hanging**.
This proves the application startup/ready path **outside** systemd. It is **not**
the `hyrxmq-listen` accept-loop binary, and it is **not** systemd-managed —
so it is *partial* evidence, not a systemd lifecycle proof. The listen binary
`build/hyrxmq-listen` exists but was **deliberately not run** (it binds 5672,
which a live RabbitMQ already holds — running it would be a false signal).

### 3. Prerequisite gap (recorded honestly)

`id hyrxmq` → *no such user*; `getent group hyrxmq` → **ABSENT**. The
`User=`/`Group=` in the unit cannot resolve on this host. Creating the
`hyrxmq` system user/group is a **packaging prerequisite** (`sysusers.d` /
`%post`), still outstanding. No `systemctl start` / sudo was attempted.

### §16 checklist — validated vs NOT PROVEN

| Lifecycle item | Status | Basis |
|----------------|--------|-------|
| Unit file syntax | **VALIDATED** | `systemd-analyze verify`: no errors; one expected ExecStart-not-installed warning |
| ExecStart binary installed at `/usr/local/bin` | **NOT PROVEN** | absent on host (verify warning) |
| `hyrxmq` user/group creation | **NOT PROVEN** | principals ABSENT here; packaging must create |
| Application startup / ready | **PARTIAL (non-systemd)** | `build/hyrxmq` starts+ready+self-check, exit 0 |
| Listen accept-loop startup | **NOT PROVEN** | `hyrxmq-listen` not run (5672 held by RabbitMQ); entry file not owned by this change |
| `systemctl` start/stop/restart | **NOT PROVEN** | root/`systemctl start` not attempted |
| Journal logging | **NOT PROVEN** | requires an actual systemd-managed run |
| Signal handling (SIGTERM shutdown) | **NOT PROVEN** | not exercised under systemd |
| Sandbox enforcement (`ProtectSystem`/`NoNewPrivileges`/`PrivateTmp`/`RestrictAddressFamilies`) | **NOT PROVEN** | only *declared*; not run |
| Resource controls (`MemoryMax`/`LimitNOFILE`) | **NOT PROVEN** | only *declared*; not run |
| Config loading under systemd | **NOT PROVEN** | env/argv override path is sibling-owned; file-load unavailable in this Mojo build |

### §16 honest outcome

> **SYSTEMD: CLEAN-MACHINE VALIDATED → NOT YET MET.**

Validated: the unit is *syntactically* correct, and the broker's own
startup/ready/self-check path works standalone. **Not** validated: the full
systemd-managed lifecycle (install → user/group → start → bind → journal →
stop/restart → sandbox → resource limits → config-under-systemd). That gate
needs a clean machine with the packaging install step, the `hyrxmq` user/group,
and a bindable listen entry point. Do not overclaim beyond the table above.
