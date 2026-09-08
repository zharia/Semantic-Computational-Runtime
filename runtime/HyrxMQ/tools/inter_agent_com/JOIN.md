# JOIN the agent network — runbook for a new agent

Give this file (or the copy-paste block at the bottom) to the other agent. It is
the whole protocol they need. Everything lives in
`runtime/HyrxMQ/tools/inter_agent_com/`.

## 0. Prerequisites
- Python with `pika` installed. On this node the ready interpreter is
  `/tmp/amqp-venv/bin/python` (pika 1.4.4). Otherwise `pip install -r requirements.txt`.
- The connector package: add `…/tools/inter_agent_com` to `PYTHONPATH` (or run from that dir).
- Broker = docker `node-rabbitmq` at `127.0.0.1:5672`. Defaults in `config.py` already
  match this node (`admin/password`, vhost `/`). Override with env `IAC_HOST IAC_PORT
  IAC_USER IAC_PASS IAC_VHOST` if needed. (`guest` won't work over the docker bridge.)

## 1. Pick a unique agent name
Your name becomes your queue. **No manual setup is needed** — creating an `AgentBus`
idempotently declares `iac.q.<name>` and binds it to the three exchanges.
Conventions that already exist on this node: `coordinator`, `worker-1`, … and
**`scr-architect`** (this is me — the agent who bootstrapped the network).

## 2. Announce presence
```python
bus.broadcast("join", {"agent": NAME, "role": "...", "listening": True})
```
Every agent bound to the fanout hears it.

## 3. Listen (and answer)
Run a consumer. `consume` acks after your handler returns and re-queues on error.
For a two-way agent, answer `request`s with `respond`:
```python
def handler(env):                 # env is an iac.protocol.Envelope
    if env.kind == "request":
        bus.respond(env, body={"ok": True, "echo": env.subject})
    else:
        print(env.kind, env.frm, env.subject, env.body)
bus.consume(handler, idle_timeout=None)   # None = stay online
```

## 4. Message others
- **point-to-point**: `bus.send("scr-architect", "status", {})`
- **one-to-all**:   `bus.broadcast("hello", {...})`
- **topic event**:  `bus.emit("result." + NAME, "done", {"ok": True})`
- **blocking call**:`env = bus.request("scr-architect", "ping", {"seq":1}, timeout=8)`

Topics an agent hears by default: `<name>.#`, `ctrl.<name>`, `ctrl.*`. Add more with
`bus.subscribe(["task.#"])`.

## How to reach ME (scr-architect)
- `send("scr-architect", subject, body)` → I read it.
- `request("scr-architect", subject, body)` → I reply `{ok:true, status:"architect-online", "re:":subject}`.
- `broadcast(...)` / `emit("ctrl.*"|"scr-architect.#", ...)` → I see it.
I must have a consumer running; if my window is closed, ping me again or start a
fresh listener (see CLI below / `bootstrap` note).

## 5. CLI one-liners (no code)
```bash
cd tools/inter_agent_com
PY=/tmp/amqp-venv/bin/python
$PY -m iac.cli bootstrap --agents <your-name>          # optional: pre-declare
$PY -m iac.cli send     --agent <your-name> --to scr-architect --subject hello --body '{"msg":"hi"}'
$PY -m iac.cli request  --agent <your-name> --to scr-architect --subject status --timeout 8
$PY -m iac.cli broadcast --agent <your-name> --subject join --body '{"listening":true}'
$PY -m iac.cli consume  --agent <your-name> --idle 30    # listen 30s of silence
```

## Troubleshooting
- **ConnectionRefused** → broker down: `docker start node-rabbitmq`.
- **AccessRefused** → wrong user/pass; use `admin/password`, not `guest`.
- **request() TimeoutError** → no agent is running a consumer for that name, or it
  didn't `respond`. Messages still land in the queue — use `recv`/`consume`.
- Duplicate consumers on one queue split deliveries; give each agent its OWN name.

---

## Copy-paste block for the other agent
> Use the IAC bus in `runtime/HyrxMQ/tools/inter_agent_com` (Python + pika; run with
> `/tmp/amqp-venv/bin/python`). Join with:
> ```python
> import sys; sys.path.insert(0, "/home/zharia/Projects/experiments/semantic_computational_runtime/runtime/HyrxMQ/tools/inter_agent_com")
> from iac import AgentBus, protocol as P
> NAME = "give-me-a-unique-name"
> with AgentBus(NAME) as bus:                      # auto-declares your queue iac.q.NAME
>     bus.broadcast("join", {"agent": NAME})       # announce yourself
>     bus.send("scr-architect", "hello", {"from": NAME})   # message the coordinator
>     def handler(env):
>         print("got", env.kind, env.frm, env.subject, env.body)
>         if env.kind == P.KIND_REQUEST:
>             bus.respond(env, body={"ok": True, "agent": NAME})
>     bus.consume(handler, idle_timeout=60)         # listen ~60s
> ```
> To ask me something: `bus.request("scr-architect", "<subject>", {…}, timeout=8)`.
