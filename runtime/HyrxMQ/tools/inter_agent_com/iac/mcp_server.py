#!/usr/bin/env python3
"""IAC MCP server — expose the inter-agent bus as agent tools (stdio transport).

Run:  python -m iac.mcp_server
The opencode/ MCP client launches this process; every tool call is JSON-RPC over
stdin/stdout. It reuses ``iac.AgentBus`` so the wire protocol stays single-sourced.

Concurrency model
-----------------
pika's BlockingConnection is NOT thread-safe, and FastMCP may run sync tools on a
threadpool. So one **owner thread** owns the sole bus connection: it drains the
queue into a thread-safe mailbox and serially executes publish/subscribe commands
submitted by tool handlers. Tools themselves never touch the broker directly.

Identity
--------
Joins as env ``IAC_AGENT``; if unset, a unique ``mcp-<host>-<pid>`` so concurrent
agent sessions never collide on one queue (two consumers would split deliveries).
"""

from __future__ import annotations

import base64
import json
import os
import queue
import socket
import threading
import time
from collections import deque
from concurrent.futures import Future
from dataclasses import asdict
from typing import List, Optional

from mcp.server.fastmcp import FastMCP  # type: ignore[import-not-found]

from iac import AgentBus, protocol as P
from iac.config import Config


def _agent_name() -> str:
    n = os.getenv("IAC_AGENT")
    if n:
        return n
    host = socket.gethostname().split(".")[0]
    return f"mcp-{host}-{os.getpid()}"


AGENT = _agent_name()
mcp = FastMCP("iac")


# --------------------------------------------------------------------------- #
#  Bus owner (single thread; sole user of the pika connection)
# --------------------------------------------------------------------------- #
class _Owner(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True, name="iac-bus-owner")
        self.bus: Optional[AgentBus] = None
        self._cmds: "queue.Queue" = queue.Queue()
        self.mailbox: deque = deque(maxlen=500)
        self.requests: dict = {}          # id -> received request Envelope
        self.cond = threading.Condition()
        self.connected = threading.Event()
        self.errors = 0
        self.received = 0
        self._stop = False

    def run(self):
        self._connect()
        while not self._stop:
            self._drain_cmds()
            bus = self.bus
            if bus is None:
                self._reconnect()
                continue
            try:
                got = bus.recv(timeout=0.1)
            except Exception:
                self.errors += 1
                self._reconnect()
                continue
            if got is not None:
                env, method = got
                if env.kind == P.KIND_REQUEST:
                    self.requests[env.id] = env
                with self.cond:
                    self.mailbox.append(env)
                    self.cond.notify_all()
                self.received += 1
                try:
                    bus.ack(method)               # at-most-once into mailbox
                except Exception:
                    self.errors += 1

    def _connect(self):
        self.bus = AgentBus(AGENT, config=Config.from_env())
        self.connected.set()

    def _reconnect(self):
        self.connected.clear()
        old = self.bus
        if old is not None:
            try:
                old.close()
            except Exception:
                pass
        for _ in range(20):
            try:
                self._connect()
                return
            except Exception:
                time.sleep(0.5)

    def _drain_cmds(self):
        for _ in range(64):
            try:
                fut, fn = self._cmds.get_nowait()
            except queue.Empty:
                break
            try:
                fut.set_result(fn(self.bus))
            except Exception as exc:  # surface to the caller thread
                fut.set_exception(exc)

    def submit(self, fn, timeout=15.0):
        fut: Future = Future()
        self._cmds.put((fut, fn))
        return fut.result(timeout=timeout)


_OWNER = _Owner()


def _coerce(body):
    if body is None:
        return {}
    if isinstance(body, str):
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            return {"text": body}
    return body


def _publish(kind, *, to=None, topic=None, subject, body, reply_to=None,
             correlation_id=None) -> str:
    env = P.Envelope(kind=kind, frm=AGENT, to=to, subject=subject,
                     body=_coerce(body), reply_to=reply_to,
                     correlation_id=correlation_id)

    def op(bus):
        if kind in (P.KIND_MSG, P.KIND_REQUEST, P.KIND_RESPONSE):
            bus._publish(P.EXCHANGE_DIRECT, to, env)
        elif kind == P.KIND_BROADCAST:
            bus._publish(P.EXCHANGE_BROADCAST, "", env)
        else:  # event / ctrl on the topic exchange
            bus._publish(P.EXCHANGE_EVENTS, topic or f"ctrl.{AGENT}", env)

    _OWNER.submit(op)
    return env.id


def _mailbox_scan(pred):
    with _OWNER.cond:
        return [e for e in _OWNER.mailbox if pred(e)]


def _mailbox_remove(env):
    with _OWNER.cond:
        try:
            _OWNER.mailbox.remove(env)
        except ValueError:
            pass


# --------------------------------------------------------------------------- #
#  Tools
# --------------------------------------------------------------------------- #
@mcp.tool()
def whoami() -> dict:
    """This agent's bus identity + connection health."""
    return {"agent": AGENT, "connected": _OWNER.connected.is_set(),
            "queue": P.queue_name(AGENT), "received": _OWNER.received,
            "errors": _OWNER.errors, "mailbox_len": len(_OWNER.mailbox)}


@mcp.tool()
def send(to: str, subject: str, body: Optional[dict] = None) -> dict:
    """Point-to-point message to another agent (by name)."""
    return {"id": _publish(P.KIND_MSG, to=to, subject=subject, body=body)}


@mcp.tool()
def broadcast(subject: str, body: Optional[dict] = None) -> dict:
    """Send to every agent (fanout)."""
    return {"id": _publish(P.KIND_BROADCAST, subject=subject, body=body)}


@mcp.tool()
def emit(topic: str, subject: str, body: Optional[dict] = None) -> dict:
    """Publish a classified event on the topic exchange (routing key = topic)."""
    return {"id": _publish(P.KIND_EVENT, topic=topic, subject=subject, body=body)}


@mcp.tool()
def subscribe(patterns: List[str]) -> dict:
    """Bind additional topic patterns (e.g. task.#, result.worker-1) to this queue."""
    _OWNER.submit(lambda bus: bus.subscribe(list(patterns)))
    return {"patterns": list(patterns)}


@mcp.tool()
def poll(timeout: float = 1.0) -> Optional[dict]:
    """Return the next received envelope (destructive), or null on timeout."""
    deadline = time.monotonic() + max(0.0, timeout)
    with _OWNER.cond:
        while not _OWNER.mailbox:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return None
            _OWNER.cond.wait(remaining)
        env = _OWNER.mailbox.popleft()
    return asdict(env)


@mcp.tool()
def peek(count: int = 20) -> List[dict]:
    """Return the last N buffered envelopes without consuming them."""
    with _OWNER.cond:
        items = list(_OWNER.mailbox)[-count:]
    return [asdict(e) for e in items]


@mcp.tool()
def respond(correlation_id: str, body: Optional[dict] = None,
            subject: Optional[str] = None) -> dict:
    """Answer a received request by its correlation_id (its envelope id)."""
    req = _OWNER.requests.get(correlation_id)
    if req is None:
        raise ValueError(f"no stored request with id {correlation_id}")
    target = req.reply_to or req.frm
    return {"id": _publish(P.KIND_RESPONSE, to=target, subject=subject or req.subject,
                           body=body, correlation_id=correlation_id)}


@mcp.tool()
def request(to: str, subject: str, body: Optional[dict] = None,
            timeout: float = 5.0) -> dict:
    """Send a request and wait briefly for the correlated response.

    Prefer async send+poll for collaboration; blocking fits only live responders.
    """
    rid = _publish(P.KIND_REQUEST, to=to, subject=subject, body=body,
                   reply_to=AGENT, correlation_id=None)
    deadline = time.monotonic() + max(0.1, timeout)
    while time.monotonic() < deadline:
        matches = _mailbox_scan(
            lambda e, _r=rid: e.kind == P.KIND_RESPONSE and e.correlation_id == _r)
        if matches:
            env = matches[0]
            _mailbox_remove(env)
            return asdict(env)
        time.sleep(0.05)
    raise TimeoutError(f"no response from {to!r} within {timeout}s (req {rid})")


@mcp.tool()
def report_status(state: str, sprint: Optional[str] = None,
                  to: str = "scr-architect", files: Optional[List[str]] = None,
                  evidence: Optional[dict] = None, question: Optional[str] = None,
                  options: Optional[List[str]] = None,
                  recommendation: Optional[str] = None) -> dict:
    """Emit a protocol-valid status:<state> message to the architect.

    state e.g. 'sprint-start' | 'sprint-done' | 'sprint-blocked' | 'question' |
    'test-failure'. Builds the agreed subject + body so reports stay uniform.
    """
    body = {}
    for key, val in (("sprint", sprint), ("files", files), ("evidence", evidence),
                     ("question", question), ("options", options),
                     ("my_recommendation", recommendation)):
        if val is not None:
            body[key] = val
    sid = _publish(P.KIND_MSG, to=to, subject=f"status:{state}", body=body)
    _publish(P.KIND_EVENT, topic=f"status.{to}", subject=state, body=body)
    return {"id": sid, "to": to, "subject": f"status:{state}"}


@mcp.tool()
def who() -> dict:
    """List live agents via the RabbitMQ management API (queues iac.q.*)."""
    cfg = Config.from_env()
    host = os.getenv("IAC_MGMT_HOST", "127.0.0.1")
    port = os.getenv("IAC_MGMT_PORT", "15672")
    url = f"http://{host}:{port}/api/queues"
    creds = base64.b64encode(f"{cfg.user}:{cfg.password}".encode()).decode()
    import urllib.request
    try:
        req = urllib.request.Request(url, headers={"Authorization": "Basic " + creds})
        with urllib.request.urlopen(req, timeout=5) as r:
            data = json.loads(r.read().decode())
        agents = []
        for q in data:
            name = q.get("name", "")
            if name.startswith(P.QUEUE_PREFIX):
                agents.append({"agent": name[len(P.QUEUE_PREFIX):],
                               "messages": q.get("messages", 0),
                               "consumers": q.get("consumers", 0)})
        agents.sort(key=lambda a: a["agent"])
        return {"count": len(agents), "agents": agents}
    except Exception as exc:
        return {"error": f"management API unreachable: {exc!r}", "agents": []}


# --------------------------------------------------------------------------- #
def main() -> None:
    import logging
    logging.getLogger().setLevel(logging.WARNING)
    for name in ("pika", "pika.adapters", "asyncio"):
        logging.getLogger(name).setLevel(logging.WARNING)
    _OWNER.start()
    _OWNER.connected.wait(10)
    try:
        _publish(P.KIND_BROADCAST, subject="join",
                 body={"agent": AGENT, "role": "mcp", "transport": "stdio",
                       "listening": True})
    except Exception:
        pass
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
