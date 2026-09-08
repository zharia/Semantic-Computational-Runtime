#!/usr/bin/env python3
"""Command-line surface for the IAC bus (thin wrapper over iac.AgentBus).

Run either way:
    python -m iac.cli <cmd> ...            (from tools/inter_agent_com/)
    python tools/inter_agent_com/iac/cli.py <cmd> ...

Examples:
    iac bootstrap --agents coordinator,worker-1,worker-2
    iac send      --from coordinator --to worker-1 --subject job --body '{"n":1}'
    iac broadcast --from coordinator --subject hello --body '{"msg":"standup"}'
    iac emit      --from worker-1 --topic result.worker-1 --subject done --body '{"ok":true}'
    iac recv      --agent worker-1 --timeout 5
    iac consume   --agent worker-1 --count 10
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# allow `python cli.py` (not just -m) by adding the package parent
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from iac import AgentBus, bootstrap_topology  # noqa: E402
from iac.config import Config  # noqa: E402
import pika  # noqa: E402


def _load_body(args) -> dict:
    if getattr(args, "body", None):
        return json.loads(args.body)
    if getattr(args, "file", None):
        text = Path(args.file).read_text()
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return {"text": text}
    return {}


def _show(env, raw=False):
    if raw:
        print(json.dumps(env.__dict__, indent=2, default=str))
    else:
        print(f"[{env.kind}] {env.frm} -> {env.to or '*'}  subject={env.subject!r}")
        if env.body:
            print("  body:", json.dumps(env.body, ensure_ascii=False))


def cmd_bootstrap(args):
    cfg = Config.from_env()
    conn = pika.BlockingConnection(cfg.connection_params())
    ch = conn.channel()
    agents = [a.strip() for a in args.agents.split(",") if a.strip()]
    bootstrap_topology(ch, agents)
    print(f"exchanges + queues ready for: {', '.join(agents) or '(exchanges only)'}")
    conn.close()


def cmd_send(args):
    with AgentBus(args.agent) as bus:
        _show_bus_id(bus.send(args.to, args.subject, _load_body(args)), args)


def cmd_broadcast(args):
    with AgentBus(args.agent) as bus:
        _show_bus_id(bus.broadcast(args.subject, _load_body(args)), args)


def cmd_emit(args):
    with AgentBus(args.agent) as bus:
        _show_bus_id(bus.emit(args.topic, args.subject, _load_body(args)), args)


def cmd_request(args):
    with AgentBus(args.agent) as bus:
        env = bus.request(args.to, args.subject, _load_body(args), timeout=args.timeout)
        _show(env, raw=args.raw)


def cmd_recv(args):
    with AgentBus(args.agent,
                  event_patterns=args.patterns or None) as bus:
        got = bus.recv(timeout=args.timeout)
        if got is None:
            print("(no message within timeout)")
            return
        env, method = got
        _show(env, raw=args.raw)
        if args.ack:
            bus.ack(method)
        else:
            bus.nack(method, requeue=True)


def cmd_consume(args):
    with AgentBus(args.agent, event_patterns=args.patterns or None) as bus:
        n = bus.consume(lambda e: _show(e, raw=args.raw),
                        max_messages=args.count, idle_timeout=args.idle)
        print(f"({n} message(s) consumed)")


def _show_bus_id(mid, args):
    if getattr(args, "quiet", False):
        return
    print(f"sent id={mid}")


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(prog="iac", description="Inter-Agent Communication bus")
    sub = ap.add_subparsers(dest="cmd", required=True)

    def add_common(p, agent=True):
        if agent:
            p.add_argument("--agent", "--from", dest="agent", required=True,
                           help="this agent's name")
        p.add_argument("--body", help="JSON body string")
        p.add_argument("--file", help="read body from file (JSON, else {text:...})")
        p.add_argument("--raw", action="store_true", help="full envelope JSON")
        p.add_argument("--quiet", action="store_true")

    b = sub.add_parser("bootstrap", help="declare exchanges + agent queues")
    b.add_argument("--agents", default="", help="comma-separated agent names")
    b.set_defaults(fn=cmd_bootstrap)

    s = sub.add_parser("send", help="point-to-point")
    add_common(s); s.add_argument("--to", required=True); s.add_argument("--subject", required=True)
    s.set_defaults(fn=cmd_send)

    bc = sub.add_parser("broadcast", help="to all agents")
    add_common(bc); bc.add_argument("--subject", required=True)
    bc.set_defaults(fn=cmd_broadcast)

    e = sub.add_parser("emit", help="topic event")
    add_common(e); e.add_argument("--topic", required=True); e.add_argument("--subject", required=True)
    e.set_defaults(fn=cmd_emit)

    r = sub.add_parser("request", help="blocking request/response")
    add_common(r); r.add_argument("--to", required=True); r.add_argument("--subject", required=True)
    r.add_argument("--timeout", type=float, default=15.0)
    r.set_defaults(fn=cmd_request)

    rv = sub.add_parser("recv", help="receive one message")
    add_common(rv); rv.add_argument("--timeout", type=float, default=5.0)
    rv.add_argument("--patterns", nargs="*", help="extra topic bindings")
    rv.add_argument("--ack", action="store_true", help="ack it (default requeue)")
    rv.set_defaults(fn=cmd_recv)

    c = sub.add_parser("consume", help="consume until --count or idle")
    add_common(c)
    c.add_argument("--count", type=int, default=None)
    c.add_argument("--patterns", nargs="*"); c.add_argument("--idle", type=float, default=2.0)
    c.set_defaults(fn=cmd_consume)

    return ap


def main(argv=None):
    args = build_parser().parse_args(argv)
    args.fn(args)


if __name__ == "__main__":
    main()
