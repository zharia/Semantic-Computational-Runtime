#!/usr/bin/env python3
"""agentd — stay online on the IAC bus as one agent.

Joins as `--agent NAME`, announces presence, then loops until `--max-runtime`
seconds elapse or a stop-file appears. For every message it:
  * appends a JSON line to the inbox (so a human/agent can read mail later), and
  * if the message is a `request`, replies via respond() with an "online" ack.

Usage:
    python agentd.py --agent scr-architect --inbox /tmp/iac/arch.inbox.jsonl \
                     --stop-file /tmp/iac/arch.stop --max-runtime 1200 &

Send a message:  touch the stop-file, or `kill <pid>` (also honoured).
"""

from __future__ import annotations

import argparse
import json
import os
import signal
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from iac import AgentBus, protocol as P

_STOP = {"flag": False}


def _install_signals():
    def _h(signum, _frame):
        _STOP["flag"] = True
    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            signal.signal(sig, _h)
        except ValueError:      # not on main thread
            pass


def _log(line: str):
    print(f"{time.strftime('%H:%M:%S')} {line}", flush=True)


def main() -> int:
    ap = argparse.ArgumentParser(description="IAC persistent agent daemon")
    ap.add_argument("--agent", required=True)
    ap.add_argument("--patterns", nargs="*", default=None,
                    help="extra topic bindings")
    ap.add_argument("--inbox", default="", help="append JSONL of received messages")
    ap.add_argument("--stop-file", default="", help="exit if this path exists")
    ap.add_argument("--max-runtime", type=float, default=1200.0,
                    help="hard self-stop seconds (safety; 0=unbounded)")
    ap.add_argument("--status", default="online")
    ap.add_argument("--announce", action="store_true", default=True,
                    help="broadcast join/leave presence")
    args = ap.parse_args()

    if args.inbox:
        Path(args.inbox).parent.mkdir(parents=True, exist_ok=True)
    _install_signals()

    bus = AgentBus(args.agent, event_patterns=args.patterns or None)
    if args.announce:
        bus.broadcast("join", {"agent": args.agent, "role": "agentd", "listening": True})
    _log(f"agentd[{args.agent}] joined; pid={os.getpid()}; "
         f"max_runtime={args.max_runtime}s")

    started = time.monotonic()
    n = answered = 0
    try:
        while True:
            if _STOP["flag"]:
                break
            if args.stop_file and os.path.exists(args.stop_file):
                _log("stop-file present; exiting")
                break
            if args.max_runtime and (time.monotonic() - started) >= args.max_runtime:
                _log("max-runtime reached; exiting")
                break

            got = bus.recv(timeout=1.0)
            if got is None:
                continue
            env, method = got
            n += 1
            if args.inbox:
                rec = {"ts": env.ts, "kind": env.kind, "from": env.frm,
                       "to": env.to, "subject": env.subject, "id": env.id,
                       "correlation_id": env.correlation_id, "body": env.body}
                with open(args.inbox, "a") as fh:
                    fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
            _log(f"#{n} [{env.kind}] {env.frm} -> {env.to or '*'} {env.subject!r} {env.body}")

            if env.kind == P.KIND_REQUEST and env.reply_to:
                bus.respond(env, body={"ok": True, "agent": args.agent,
                                       "status": args.status, "re": env.subject,
                                       "echo": env.body})
                answered += 1
                _log(f"  answered request for {env.reply_to} (id {env.id[:8]})")
            bus.ack(method)
    finally:
        if args.announce:
            try:
                bus.broadcast("leave", {"agent": args.agent, "heard": n})
            except Exception:
                pass
        bus.close()
        _log(f"agentd[{args.agent}] stopped; heard={n} answered={answered}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
