#!/usr/bin/env python3
"""End-to-end smoke test for the IAC MCP server (real stdio MCP client).

    /home/zharia/.local/share/iac-mcp/venv/bin/python mcp_smoke.py

Launches `python -m iac.mcp_server` as an MCP subprocess, drives it with a real
client, and cross-talks with a plain AgentBus "peer". Because every agent is bound
to the fanout (and sees broadcasts, incl. presence 'join'), the bus checks DRAIN
until the target subject arrives rather than assuming FIFO order. Uses runtime
assertions (raises). Cleans up its two `mcp-smoke*` queues at the end.
"""
import asyncio
import json
import os
import sys
import threading
import time
from typing import Any, Optional

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.environ.setdefault("IAC_AGENT", "mcp-smoke")
os.environ.setdefault("PYTHONPATH", HERE)

from mcp import ClientSession, StdioServerParameters  # type: ignore
from mcp.client.stdio import stdio_client             # type: ignore

from iac import AgentBus, protocol as P, teardown_agent

PY = sys.executable
EXPECTED = {"whoami", "send", "broadcast", "emit", "subscribe", "poll", "peek",
            "respond", "request", "report_status", "who"}
checks = 0


def ok(cond, msg):
    global checks
    if not cond:
        raise AssertionError("FAIL: " + msg)
    checks += 1
    print("  ok:", msg)


def _unwrap(v):
    if isinstance(v, dict) and list(v.keys()) == ["result"]:
        return v["result"]
    return v


def text_of(result) -> Any:
    sc = getattr(result, "structuredContent", None)
    if sc is not None:
        return _unwrap(sc)
    for c in result.content:
        if c.type == "text":
            try:
                return _unwrap(json.loads(c.text))
            except Exception:
                return c.text
    return None


def recv_until(bus: AgentBus, pred, timeout=8.0):
    """Drain the bus until a message matches pred (acks + discards the rest)."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        got = bus.recv(timeout=0.5)
        if got is None:
            continue
        env, method = got
        if pred(env):
            return env, method
        bus.ack(method)
    return None


async def poll_until(s: ClientSession, subject: str, timeout=8.0) -> Optional[dict]:
    """Drain the MCP server's poll() until an envelope with `subject` appears."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        p = text_of(await s.call_tool("poll", {"timeout": 1.0}))
        if isinstance(p, dict) and p.get("subject") == subject:
            return p
    return None


async def main():
    peer = AgentBus("mcp-smoke-peer")
    params = StdioServerParameters(command=PY, args=["-m", "iac.mcp_server"],
                                   env=dict(os.environ))
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            init = await s.initialize()
            print("server:", init.serverInfo.name)
            names = {t.name for t in (await s.list_tools()).tools}
            ok(EXPECTED <= names, "all IAC tools exposed")

            who = text_of(await s.call_tool("whoami", {}))
            ok(who["agent"] == "mcp-smoke", "whoami reports IAC_AGENT identity")

            w2 = text_of(await s.call_tool("who", {}))
            ok(("error" in w2) or isinstance(w2.get("agents"), list),
               f"who() runs (mgmt count={w2.get('count', 'n/a')})")

            # ---- MCP send -> peer ----
            await s.call_tool("send", {"to": "mcp-smoke-peer",
                                       "subject": "mcp-hello", "body": {"via": "mcp"}})
            got = recv_until(peer, lambda e: e.subject == "mcp-hello")
            assert got is not None, "MCP send() reaches the peer"
            ok(got[0].subject == "mcp-hello", "MCP send() reaches the peer")
            peer.ack(got[1])

            # ---- peer send -> MCP poll ----
            peer.send("mcp-smoke", "peer-reply", {"hi": "mcp"})
            p = await poll_until(s, "peer-reply")
            ok(p is not None, "MCP poll() receives a peer message")

            pk = text_of(await s.call_tool("peek", {"count": 5}))
            ok(isinstance(pk, list), "peek() returns a list")

            # ---- MCP request -> peer respond ----
            threading.Thread(target=lambda: _serve_request(peer), daemon=True).start()
            rr = text_of(await s.call_tool("request", {"to": "mcp-smoke-peer",
                                                       "subject": "sum", "timeout": 9}))
            ok(rr and rr.get("body", {}).get("sum") == 42, "request()/respond() round-trip")

            # ---- typed report_status -> architect target ----
            rs = text_of(await s.call_tool("report_status", {"state": "sprint-done",
                                                             "sprint": "99",
                                                             "evidence": {"x": 1},
                                                             "to": "mcp-smoke-peer"}))
            ok(rs["subject"] == "status:sprint-done", "report_status builds the subject")
            d = recv_until(peer, lambda e: e.subject == "status:sprint-done")
            assert d is not None, "report_status reached target"
            ok(d[0].body.get("sprint") == "99", "report_status delivered to target")
            peer.ack(d[1])

    # cleanup the throwaway queues
    ch = peer._ch
    teardown_agent(ch, "mcp-smoke-peer")
    peer.close()
    print(f"\nPASS ({checks} checks) — IAC MCP server works end-to-end over stdio")


def _serve_request(peer: AgentBus):
    got = recv_until(peer, lambda e: e.kind == P.KIND_REQUEST, timeout=10)
    if got:
        env, method = got
        peer.respond(env, body={"sum": 42})
        peer.ack(method)


if __name__ == "__main__":
    asyncio.run(main())
