# IAC Wire Protocol (v1)

A small, fixed convention for agents to collaborate over one AMQP broker
(RabbitMQ). Everything is derived from a single **agent name** — you never hand-
type exchange or queue names.

## Topology

```
                         ┌──────────────────────── iac.direct (direct)
   agent "a" ──send──▶   │   rk = "<recipient>"        point-to-point
                         ├──▶  iac.q.a ──▶ a.consume / a.recv
                         │   └─ binds ─┐
   anyone ─broadcast─▶ iac.broadcast (fanout) ─┤  every agent queue
                         │                      │  receives every broadcast
   anyone ─emit──▶ iac.events (topic) rk="a.result", "ctrl.a", "task.new" ...
                                             │  agents bind patterns
                                             └─▶ only matching queues
```

| Exchange        | Type    | Routing key convention          | Purpose                     |
|-----------------|---------|---------------------------------|-----------------------------|
| `iac.direct`    | direct  | the recipient's agent name      | point-to-point send/request |
| `iac.broadcast` | fanout  | (ignored)                       | one-to-all announcements    |
| `iac.events`    | topic   | dotted, e.g. `task.#`,`ctrl.*`  | classified pub/sub          |

**Per-agent queue:** `iac.q.<agent>` — `durable`, non-auto-delete. On startup an
agent binds it to:
- `iac.direct`  with `rk = <agent>`              → gets its p2p mail
- `iac.broadcast` (no key)                        → hears all broadcasts
- `iac.events`  with its binding patterns         → defaults to `<agent>.#`, `ctrl.<agent>`, `ctrl.*`

Patterns are additive: `bus.subscribe(["result.#"])` binds more at runtime.

## Envelope

Every body is this JSON object (AMQP `content_type: application/json`,
`delivery_mode: 2` persistent). Duplicates are guarded by version `v`.

```jsonc
{
  "v": 1,
  "id": "<128-bit hex>",        // unique; also the request's correlation anchor
  "ts": "2026-09-08T12:00:00.000+00:00",
  "from": "coordinator",        // sender agent name
  "to":   "worker-1",           // recipient, or null for broadcast/event
  "kind": "msg",                // see below
  "subject": "assign-task",     // short label (routing-independent)
  "reply_to": null,             // set on `request`: who wants the answer
  "correlation_id": null,       // set on `response`: the request's id
  "body": { "job": 42 }         // free JSON payload (keep < frame_max)
}
```

### `kind` values and how they route

| kind        | sent via        | notes                                            |
|-------------|-----------------|--------------------------------------------------|
| `msg`       | direct          | ordinary point-to-point                          |
| `broadcast` | fanout          | to every agent                                   |
| `event`     | topic           | classified; only bound agents receive            |
| `request`   | direct          | sets `reply_to` + `correlation_id=id`            |
| `response`  | direct          | `correlation_id` = the request's `id`, `to`=requester |
| `ctrl`      | direct or topic | lifecycle (presence, shutdown, ...); addressed   |

## Delivery semantics

- **Ack:** `consume(handler)` acks after the handler returns and
  nack-**requeues** on exception (so a crash re-delivers).
- `recv(timeout)` hands you `(envelope, method)`; you `ack`/`nack` it. Default CLI
  `recv` requeues unless `--ack`.
- **Prefetch** = 1 (per-agent fairness) by default; env `IAC_PREFETCH`.
- **request()/respond():** `request` blocks, buffering any unrelated messages it
  passes so the next `recv` still sees them; matches a reply by `correlation_id`.
- Ordering is per-queue FIFO; broadcasts/events are best-effort (at-most-once for
  the transient case, at-least-once for persistent durable queues).

## Versioning & config

- `v` is checked on parse; **additive** fields are ignored by old readers (see the
  forward-compat test), so the `body` and envelope can grow without a hard bump.
- Connection is configured by env (see `README.md`): host/port/user/pass/vhost.
  No credentials are baked in beyond this node's defaults.
