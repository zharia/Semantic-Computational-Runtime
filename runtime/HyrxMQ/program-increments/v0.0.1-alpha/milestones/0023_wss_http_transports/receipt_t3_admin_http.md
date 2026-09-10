# 0023 T3 receipt — admin-HTTP transport (optional k8s plane)

**Task:** plan.md T3 (admin HTTP). **Mode:** implemented (coordinator-inline).
**Suite:** NOT RUN for this chunk (DO-BUILD deferred per task order; suite base
46/0 unchanged — no existing behavior touched: admin tier default-OFF and the
new files are additive).

## Hunks

| File | Change |
|------|--------|
| `src/hyrx/transport/http_admin.mojo` | NEW. `AdminHttpListener` + `AdminHttpHandler` over the vendored flare `HttpServer` (ADR-0005 containment: all flare http wiring lives here; `hyrxmq` files still never import flare). Constants: `ADMIN_HTTP_DEFAULT_PORT()` = 25673 (plan default), `ADMIN_HTTP_HEALTH_PATH()` = `/health`, `ADMIN_HTTP_STATS_PATH()` = `/stats`, `ADMIN_HTTP_TRANSPORT_KIND()` = `admin-http`. |
| `src/hyrxmq/main_listen.mojo` | ADD `_resolve_admin_http` (env `HYRXMQ_ADMIN_HTTP` → `cfg.admin_http_port`; 0/absent = OFF; malformed raises), `_admin_http_requested`, `_refuse_admin_http`; in `main()`: resolve + (configured ⇒ fail loud BEFORE any bind, including before the WSS branch). Unconfigured boot is byte-identical to before. |
| `src/hyrxmq/config.mojo` | NO CHANGE. Verified the T1/T2 rows are already complete: field `admin_http_port` (default 0), `apply("admin_http_port")` via `_require_int`, `__copyinit__` row, `validate()` range check 0..65535. Env override lives at the entry-point layer (`main_listen`), matching the `HYRXMQ_WSS_LISTEN` pairing. |

## Endpoint list + response shapes

All served by `AdminHttpListener.serve_forever()` on ITS OWN port (flare
`HttpServer` reactor; HTTP/1.1 keep-alive per flare). No AMQP semantics, no
fs, no state changes anywhere on this plane.

| Row | Request | Response |
|-----|---------|----------|
| health | `GET /health` (exact path after query strip) | `200` `text/plain; charset=utf-8` body `ok` |
| stats | `GET /stats` (exact path after query strip) | `200` `application/json`, body = `{"status":"ok","node":"<node>","vhost":"<vhost>","transport":"admin-http","port":<bound port>}` (fixed key order; minimal JSON escaping: `\` `"` `\n` `\r` `\t`, other control bytes `\u00xx`) |
| 404 | everything else (any path, any non-GET method on the two paths) | `404` `text/plain` `Not Found` |

**Stats-row honesty (the task's sanctioned half-work).** `/stats` carries the
static broker identity + this tier's own endpoint state — NOT live engine
counters. The embedded-api accessor list was read (HyrxStats:
`messages_published/delivered/acknowledged/rejected`, `active_queues`,
`active_consumers`, `pool_stats`; plus `BrokerStatus` node/vhost/queues/
consumers on `hyrxmq.status`): those counters live inside the PRIMARY serving
loop's `AMQPService`. With one serving loop per process there is no concurrent
cross-loop read in this build, and `AdminHttpHandler` implements flare's
borrowed-self `Handler.serve` (no mutation in the request path, so no
per-request counter either). Faking either would violate the 0023 honesty
rule — recorded, not shipped.

## Multi-tier boot-state declaration (HONEST)

**One serving loop per process** (the same toolchain reality the WSS tier
already declared on this milestone). Consequently, when
`HYRXMQ_ADMIN_HTTP != 0` (or config `admin_http_port != 0`):

- main_listen **fails loud before binding anything** (`_refuse_admin_http`),
  carrying the normative reason. No bound-but-unserved port, no faked
  multi-listener passthrough, nothing half-bound.
- Considered and REJECTED for this chunk:
  - **(a) admin takes the loop** (the WSS-style takeover shape): semantically
    wrong — the admin plane exists to observe the data plane; giving it the
    single loop would silently stop all AMQP/WSS serving.
  - **(b) concurrent loops via pthreads** (flare `Scheduler` exists and would
    run the reactor off-thread): the broker counters would be read
    cross-thread with no synchronization — a data race, not a feature.
- Working surface: `AdminHttpListener` is complete (bind/start/stop/serve +
  stat accessors) and is exercised STANDALONE — the T4 conformance rows drive
  it in its own process (`HYRXMQ_ADMIN_HTTP` is intentionally not enough to
  boot it inside the listen binary until the concurrency shape lands).

## Needs-probe items

1. **Synchronized counter handoff** — how the primary loop publishes a
   snapshot (atomic cell / lock-swapped `BrokerStatus` snapshot struct) that
   the admin reactor can read; this unlocks the full `/stats` row
   (HyrxStats/queue/pool readouts mirrored).
2. **Reactor-side request counters** — flare `Handler.serve` takes borrowed
   self; a live per-request counter needs an interior-mutability cell (probe
   Mojo 1.0 support) or a reactor hook.
3. **Thread-model coexistence** — main-thread primary loop + admin reactor
   thread (flare `Scheduler`), including shutdown ordering; gate for lifting
   the main_listen refusal.
4. **`http_admin.mojo` compile check** — file not built this chunk (task
   order); first `mojo build` should confirm the `serve[AdminHttpHandler]`
   overload resolution (arity-1 `Handler` overload) and `IpAddr.parse`
   behavior for the configured host.

## Explicitly NOT claimed

- NOT claimed: concurrent admin-HTTP + primary serving (single-loop build;
  refusal is the shipped boot state).
- NOT claimed: live engine counters on `/stats` (identity row only; see
  needs-probe 1).
- NOT claimed: TLS on the admin plane (flare `bind_tls` exists; 0023 scoped
  the admin plane to plaintext probes).
- NOT claimed: config UI / management UI planes (excluded per plan.md).
- NOT claimed: any fs use (zero fs in this chunk; `/health` + `/stats` are
  computed from constructor state).
- NOT claimed: suite/perf rows for the admin tier (T4; perf stays
  observation-tier per plan.md).
