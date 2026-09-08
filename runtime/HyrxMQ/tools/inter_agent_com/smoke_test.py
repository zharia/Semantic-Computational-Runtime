#!/usr/bin/env python3
"""Self-test for the IAC connector.

Default (OFFLINE, no network, safe to run anytime):
    python smoke_test.py
  -> exercises the pure-Python protocol: envelope round-trip, version guard,
     name/pattern derivation, forward-compat.

Optional (LIVE — connects to the broker AND declares iac.* topology + creates
two `smoke-*` queues; only run this deliberately):
    python smoke_test.py --live
  -> point-to-point, broadcast, topic emit/subscribe, and request/respond
     (the last across a background thread, since request() blocks).
"""

from __future__ import annotations

import json
import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from iac import protocol as P
from iac.protocol import Envelope


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)
    print(f"  ok: {msg}")


# --------------------------------------------------------------------------- #
def offline_tests():
    print("offline protocol tests:")
    e = Envelope(kind=P.KIND_MSG, frm="a", to="b", subject="hi", body={"x": 1})
    rt = Envelope.loads(e.dumps())
    check(rt.frm == "a" and rt.to == "b" and rt.subject == "hi"
          and rt.body == {"x": 1} and rt.id == e.id, "envelope round-trips")
    check(P.queue_name("worker-1") == "iac.q.worker-1", "queue name derived")
    check("worker-1.#" in P.default_event_patterns("worker-1"),
          "default patterns address the agent")
    tampered = e.dumps().replace('"v":1', '"v":999', 1)
    try:
        Envelope.loads(tampered)
        check(False, "version mismatch should raise")
    except ValueError:
        check(True, "version mismatch raises ValueError")
    extra = json.loads(e.dumps())
    extra["future_field"] = 7                       # forward-compat
    check(Envelope.loads(json.dumps(extra)).id == e.id,
          "unknown future keys are ignored")


# --------------------------------------------------------------------------- #
def _recv1(bus, timeout=5.0):
    got = bus.recv(timeout=timeout)
    if got is None:
        raise AssertionError("no message within timeout")
    print("  ok: a message arrived")
    return got  # (env, method)


def live_tests():
    from iac import AgentBus, teardown_agent
    print("live broker tests (declaring iac.* topology):")
    with AgentBus("smoke-a") as a, AgentBus("smoke-b", event_patterns=["b.#"]) as b:
        # point-to-point
        a.send("b", "ping", {"n": 1})
        env, m = _recv1(b)
        check(env.kind == P.KIND_MSG and env.body["n"] == 1, "p2p delivered intact")
        b.ack(m)

        # broadcast reaches both (sender is subscribed to fanout too)
        a.broadcast("standup", {"room": 1})
        ea, ma = _recv1(a)
        eb, mb = _recv1(b)
        check(ea.kind == P.KIND_BROADCAST and eb.kind == P.KIND_BROADCAST,
              "broadcast reached both")
        b.ack(mb)

        # topic emit -> only the subscriber with a matching binding
        b.subscribe(["news.#"])
        a.emit("news.tech", "hi", {"k": "v"})
        en, mn = _recv1(b)
        check(en.kind == P.KIND_EVENT and en.subject == "hi", "topic event delivered")
        b.ack(mn)

        # request()/respond() — b answers in a background thread; a blocks on request
        def _serve():
            def h(e):
                if e.kind == P.KIND_REQUEST:
                    b.respond(e, body={"sum": e.body["a"] + e.body["b"]})
            b.consume(h, max_messages=1, idle_timeout=5)

        t = threading.Thread(target=_serve, daemon=True)
        t.start()
        resp = a.request("b", "sum", {"a": 2, "b": 3}, timeout=6)
        t.join(timeout=2)
        check(resp.kind == P.KIND_RESPONSE and resp.body["sum"] == 5,
              "request/response round-trip")

        # tidy the smoke queues (leaves shared iac.* exchanges in place)
        teardown_agent(a._ch, "smoke-a")
        teardown_agent(b._ch, "smoke-b")
    print("  live tests done")


if __name__ == "__main__":
    offline_tests()
    if "--live" in sys.argv[1:]:
        live_tests()
    print("PASS")
