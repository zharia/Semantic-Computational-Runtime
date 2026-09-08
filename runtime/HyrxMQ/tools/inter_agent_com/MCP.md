# IAC MCP Server — the bus as agent tools

A stdio [Model Context Protocol](https://modelcontextprotocol.io) server that
exposes the Inter-Agent Communication bus to any MCP client (e.g. opencode), so
agents collaborate with **first-class tools** instead of hand-written Python
snippets. It reuses `iac.AgentBus`, so the wire protocol stays single-sourced in
`protocol.py` / `bus.py`.

## Run / register
Started by an MCP client (not usually by hand). In this repo it is registered in
`.opencode/opencode.json`:
```json
"iac": {
  "type": "local",
  "command": ["/home/zharia/.local/share/iac-mcp/venv/bin/python", "-m", "iac.mcp_server"],
  "cwd":     ".../runtime/HyrxMQ/tools/inter_agent_com",
  "environment": { "PYTHONPATH": ".../tools/inter_agent_com" },
  "enabled": true
}
```
The client launches the process and talks JSON-RPC over its stdin/stdout.
Reloading the config starts the server (new tools appear in the session).

## Provisioning (one-time)
The venv holds `pika` + `mcp<2` (FastMCP v1; `mcp` 2.x renamed the API):
```bash
uv venv /home/zharia/.local/share/iac-mcp/venv --python 3.12
VIRTUAL_ENV=/home/zharia/.local/share/iac-mcp/venv uv pip install "pika>=1.3,<2" "mcp<2"
```

## Identity — unique per session
Joins as `IAC_AGENT`; if unset, `mcp-<host>-<pid>` (e.g. `mcp-sneaky-bat-3079194`).
**Each opencode/MCP session is therefore its own bus agent**, so concurrent
agents never collide. Two consumers on one queue would split deliveries — that is
why identity is unique and why this server must **not** share a name with an
`agentd` instance. `whoami` reports the live identity.

## Concurrency model (why it is safe)
pika's `BlockingConnection` is not thread-safe and FastMCP runs sync tools on a
threadpool. So a single **owner thread** owns the one connection: it drains the
queue into a thread-safe mailbox and serially executes publish/subscribe commands
that tools submit. Tools never touch the broker directly, so there is no
cross-thread AMQP use. On a transient broker error the owner reconnects instead of
dying.

## Tools
| tool | args | purpose |
|------|------|---------|
| `whoami` | – | identity + connection/mailbox health |
| `who` | – | list live agents (RabbitMQ mgmt API `:15672`) |
| `send` | `to, subject, body?` | point-to-point |
| `broadcast` | `subject, body?` | to every agent |
| `emit` | `topic, subject, body?` | topic event |
| `subscribe` | `patterns[]` | add topic bindings |
| `poll` | `timeout?` | next received envelope (destructive) or null |
| `peek` | `count?` | last N envelopes, non-destructive |
| `respond` | `correlation_id, body?, subject?` | answer a stored request |
| `request` | `to, subject, body?, timeout?` | blocking call (prefer send+poll) |
| `report_status` | `state, sprint?, to?, files?, evidence?, question?, options?, recommendation?` | emit protocol-valid `status:<state>` |

`body` is a JSON object. Messages received are auto-acked into the mailbox
(at-most-once for the buffer), so `poll`/`peek` never block the tool call beyond
the short `timeout`.

## Collaboration pattern
```
send/emit/report_status            -> fire-and-forget to peers/architect
poll (loop) / peek                 -> non-blocking read of what arrived
report_status("sprint-done", ...)  -> typed status: reports to scr-architect
```
`request` is provided but discouraged for long flows (it blocks the tool call).

## Coexistence with agentd.py
- `agentd.py` = headless scripted responder (auto-answers requests, mirrors to an
  inbox file) — good for an always-on service identity (e.g. `scr-architect`).
- `mcp_server.py` = LLM-in-the-loop — the model decides per message. Run them as
  **different agent names**.

## Verify
`/home/zharia/.local/share/iac-mcp/venv/bin/python mcp_smoke.py` — drives the
server with a real MCP stdio client and cross-talks with a plain `AgentBus`
peer; 9 assertions (identity, tool surface, send, poll, peek, request↔respond,
report_status). Currently passing.
