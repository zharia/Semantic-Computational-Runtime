# Inter-Agent Communication (IAC)

A **basic, Python-based message bus** so agents on this node can collaborate
through the local RabbitMQ broker (`node-rabbitmq`, docker, `127.0.0.1:5672`).
Design priorities: **simplicity** and **collaboration** — one queue per agent, a
fixed JSON envelope, and every common operation codified as a function.

```
tools/inter_agent_com/
├── iac/
│   ├── protocol.py    # envelope + topology names (pure, offline-testable)
│   ├── config.py      # broker connection from env (defaults = this node)
│   ├── topology.py    # idempotent exchange/queue/binding bootstrap
│   ├── bus.py         # AgentBus: send/broadcast/emit/request/recv/consume/...
│   ├── cli.py         # command-line surface (also `python -m iac`)
│   ├── mcp_server.py  # MCP stdio server: the bus as agent tools (`-m iac.mcp_server`)
│   └── __main__.py
├── agentd.py          # headless "stay online" responder + inbox mirror
├── examples/ping_pong.py
├── smoke_test.py      # offline (default) + live (--live) self-test
├── mcp_smoke.py       # end-to-end test of the MCP server via a real client
├── protocol.md        # wire format + topology spec
├── MCP.md             # MCP server: tools, identity, provisioning, coexistence
├── JOIN.md            # runbook to onboard a new agent
└── requirements.txt   # pika
```

## Quickstart

```bash
# pika lives in this venv on the node; use it (or pip install -r requirements.txt)
PY=/tmp/amqp-venv/bin/python

# 0. no-network self-check of the protocol
$PY smoke_test.py

# 1. declare the shared topology + a few agent queues (mutates the broker)
$PY -m iac.cli bootstrap --agents coordinator,worker-1,worker-2

# 2. point-to-point, from a shell
$PY -m iac.cli send      --agent coordinator --to worker-1 --subject job --body '{"n":1}'
$PY -m iac.cli recv      --agent worker-1 --timeout 5 --ack

# 3. one-to-all and topic events
$PY -m iac.cli broadcast --agent coordinator --subject standup --body '{"room":1}'
$PY -m iac.cli emit      --agent worker-1 --topic result.worker-1 --subject done

# 4. two agents talking in Python (blocking request/response)
$PY examples/ping_pong.py
```

## Using it as a library

```python
from iac import AgentBus

with AgentBus("coordinator") as coord:           # queue+bindings are auto-declared
    coord.send("worker-1", "job", {"id": 42})    # point-to-point
    coord.broadcast("status", {"phase": "running"})
    coord.emit("task.new", "new-job", {"id": 42})  # topic
    reply = coord.request("worker-1", "sum", {"nums": [1, 2, 3]}, timeout=8)
    print(reply.body)                            # {'sum': 6}

with AgentBus("worker-1") as w:
    w.consume(lambda env: print(env.subject))    # acks on success, requeues on error
```

`send / broadcast / emit / request / respond / recv / consume / subscribe /
unsubscribe / ctrl` are the codified common functions — every agent uses these, so
the protocol is applied uniformly.

## MCP server (agent tools)

`python -m iac.mcp_server` runs a stdio MCP server that exposes the bus as
first-class tools (`whoami, who, send, broadcast, emit, subscribe, poll, peek,
respond, request, report_status`) — so agents collaborate without writing Python.
It is registered in the workspace `.opencode/opencode.json` (`mcp.iac`) and joins
as a **unique per-session** agent (`IAC_AGENT`, else `mcp-<host>-<pid>`). See
[`MCP.md`](MCP.md) for provisioning, the single-owner-thread concurrency model, and
how it coexists with `agentd.py`. Verify with `mcp_smoke.py` (real MCP client).

## Configuration (env)

| Var            | Default      | Meaning                     |
|----------------|--------------|-----------------------------|
| `IAC_HOST`     | `127.0.0.1`  | broker host                 |
| `IAC_PORT`     | `5672`       | broker port                 |
| `IAC_USER`     | `admin`      | SASL user                   |
| `IAC_PASS`     | `password`   | SASL password               |
| `IAC_VHOST`    | `/`          | virtual host                |
| `IAC_HEARTBEAT`| `60`         | AMQP heartbeat (s)          |
| `IAC_PREFETCH` | `1`          | per-consumer prefetch       |

Defaults match **this node's** container. `guest` is *not* used: RabbitMQ allows it
only over loopback and the container is reached over the docker bridge. For another
broker set `IAC_HOST`/`IAC_USER`/`IAC_PASS`.

## Scope & safety

- **Bootstrap is a mutation.** `bootstrap`/first-`AgentBus(...)` declare
  `iac.*` exchanges and `iac.q.<agent>` durable queues on the broker. They are
  idempotent and namespaced, but they do touch the shared container — run
  deliberately, not in a tight loop.
- **This is a coordination plane, not a data plane.** Keep `body` small
  (< `frame_max`, 128 KiB by default here); pass references/ids, not blobs.
- Single-threaded, synchronous (pika `BlockingConnection`) on purpose — the
  simplest thing that supports real collaboration. Blocking `request()` is
  answered by a *different* thread/process consuming the target queue.
- **Not durable coordination infra**: queues survive broker restart, but there is
  no auth/ACL isolation between agents (all share the `/` vhost) — trust boundary
  is the broker credentials. See `protocol.md` for delivery semantics.
```
