#!/usr/bin/env python3
"""Minimal two-agent collaboration over the IAC bus.

Needs the live broker (declares iac.* topology, creates queues `coordinator`
and `worker-1`). Run with the pika-enabled interpreter, e.g.:

    /tmp/amqp-venv/bin/python examples/ping_pong.py

Shows the two idioms agents will use most:
  * fire-and-forget  : send / broadcast / emit  +  recv / consume
  * request/response : request() blocks for a correlated reply; respond() answers
"""

from __future__ import annotations

import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from iac import AgentBus, protocol as P


def worker(name: str, ready: threading.Event) -> None:
    """Serve requests: answer 'ping' and 'sum', otherwise acknowledge."""
    with AgentBus(name, event_patterns=[f"{name}.#", "task.#"]) as bus:
        def handler(env: P.Envelope) -> None:
            if env.kind == P.KIND_REQUEST:
                if env.subject == "ping":
                    bus.respond(env, body={"pong": True, "echo": env.body})
                elif env.subject == "sum":
                    nums = env.body.get("nums", [])
                    bus.respond(env, body={"sum": sum(nums)})
                print(f"  [{name}] responded to {env.subject!r} from {env.frm}")
            elif env.kind == P.KIND_BROADCAST:
                print(f"  [{name}] heard broadcast {env.subject!r}: {env.body}")
            else:
                print(f"  [{name}] got {env.kind} {env.subject!r}")

        ready.set()
        bus.consume(handler, idle_timeout=6.0)


def main() -> None:
    ready = threading.Event()
    t = threading.Thread(target=worker, args=("worker-1", ready), daemon=True)
    t.start()
    ready.wait(10)

    with AgentBus("coordinator") as coord:
        coord.broadcast("kickoff", {"note": "worker, wake up"})

        r = coord.request("worker-1", "ping", {"seq": 1}, timeout=8)
        print("ping   ->", r.body)

        r = coord.request("worker-1", "sum", {"nums": [3, 4, 5]}, timeout=8)
        print("sum    ->", r.body)

        coord.send("worker-1", "shutdown", {"please": True})
        t.join(timeout=8)


if __name__ == "__main__":
    main()
