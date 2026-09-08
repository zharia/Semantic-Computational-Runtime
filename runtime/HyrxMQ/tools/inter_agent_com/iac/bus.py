"""AgentBus — the shared client that codifies every common messaging operation.

Agents only ever talk through this class, so the protocol (topology, envelope,
routing conventions) is applied consistently. Synchronous (pika
BlockingConnection): each call is a straight-line request/response — the simplest
thing that supports real agent collaboration without an event loop.

    from iac import AgentBus
    with AgentBus("coordinator") as bus:
        bus.send("worker-1", "do-task", {"job": 42})
        bus.broadcast("status", {"phase": "starting"})
        env = bus.recv(timeout=5)          # None on timeout
        bus.emit("result.coordinator", "done", {"ok": True})
"""

from __future__ import annotations

import time
import uuid
from collections import deque
from typing import Callable, List, Optional, Tuple

import pika

from . import protocol as P
from .config import Config
from .topology import declare_exchanges, ensure_agent_queue

# A received message: (envelope, delivery-method). The method is needed to ack.
Received = Tuple[P.Envelope, object]


class AgentBus:
    def __init__(self, agent: str, config: Optional[Config] = None,
                 event_patterns: Optional[List[str]] = None, declare: bool = True):
        self.agent = agent
        self.cfg = config or Config.from_env()
        self.patterns: List[str] = list(
            event_patterns if event_patterns is not None else P.default_event_patterns(agent))
        self._pending: deque = deque()          # buffered (env, method) from request()
        self._conn = pika.BlockingConnection(self.cfg.connection_params())
        self._ch = self._conn.channel()
        self._ch.basic_qos(prefetch_count=self.cfg.prefetch)
        if declare:
            declare_exchanges(self._ch)
            ensure_agent_queue(self._ch, agent, self.patterns)

    # -- context manager ------------------------------------------------------
    def __enter__(self) -> "AgentBus":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    # -- internals ------------------------------------------------------------
    def _publish(self, exchange: str, routing_key: str, env: P.Envelope) -> None:
        props = pika.BasicProperties(
            delivery_mode=2,                       # persistent
            content_type="application/json",
            message_id=env.id,
            correlation_id=env.correlation_id,
            reply_to=env.reply_to,
            type=env.kind,
            app_id=env.frm,
            timestamp=int(time.time()),
        )
        self._ch.basic_publish(exchange=exchange, routing_key=routing_key,
                               body=env.dumps(), properties=props)

    def _fetch(self) -> Optional[Received]:
        """basic_get ONE message from the broker (does NOT touch _pending)."""
        method, _props, raw = self._ch.basic_get(queue=P.queue_name(self.agent),
                                                 auto_ack=False)
        if method is None:
            return None
        try:
            return P.Envelope.loads(raw), method
        except Exception:
            # Undecodable / foreign message: ack-and-drop so it does not loop.
            self._ch.basic_ack(delivery_tag=method.delivery_tag)
            return None

    def _next(self) -> Optional[Received]:
        """One message: pending buffer first, else a fresh basic_get."""
        if self._pending:
            return self._pending.popleft()
        return self._fetch()

    def _pump(self) -> None:
        self._conn.process_data_events()
        time.sleep(0.05)

    # -- point-to-point -------------------------------------------------------
    def send(self, to: str, subject: str, body: Optional[dict] = None) -> str:
        env = P.Envelope(kind=P.KIND_MSG, frm=self.agent, to=to,
                         subject=subject, body=body or {})
        self._publish(P.EXCHANGE_DIRECT, to, env)
        return env.id

    # -- one-to-all -----------------------------------------------------------
    def broadcast(self, subject: str, body: Optional[dict] = None) -> str:
        env = P.Envelope(kind=P.KIND_BROADCAST, frm=self.agent, to=None,
                         subject=subject, body=body or {})
        self._publish(P.EXCHANGE_BROADCAST, "", env)
        return env.id

    # -- topic event ----------------------------------------------------------
    def emit(self, topic: str, subject: str, body: Optional[dict] = None) -> str:
        """Publish a classified event on the topic exchange (rk = topic)."""
        env = P.Envelope(kind=P.KIND_EVENT, frm=self.agent, to=None,
                         subject=subject, body=body or {})
        self._publish(P.EXCHANGE_EVENTS, topic, env)
        return env.id

    # -- control --------------------------------------------------------------
    def ctrl(self, subject: str, to: Optional[str] = None, body: Optional[dict] = None) -> str:
        """Lifecycle/control notice; to=None broadcasts on the events 'ctrl' topic."""
        env = P.Envelope(kind=P.KIND_CTRL, frm=self.agent, to=to,
                         subject=subject, body=body or {})
        if to:
            self._publish(P.EXCHANGE_DIRECT, to, env)
        else:
            self._publish(P.EXCHANGE_EVENTS, f"ctrl.{self.agent}", env)
        return env.id

    # -- request / response (best-effort, single-threaded) --------------------
    def request(self, to: str, subject: str, body: Optional[dict] = None,
                timeout: float = 15.0) -> P.Envelope:
        req = P.Envelope(kind=P.KIND_REQUEST, frm=self.agent, to=to, subject=subject,
                         body=body or {}, reply_to=self.agent, correlation_id=None)
        req.correlation_id = req.id
        self._publish(P.EXCHANGE_DIRECT, to, req)
        deadline = time.monotonic() + timeout
        deferred = []
        try:
            while time.monotonic() < deadline:
                got = self._pending.popleft() if self._pending else self._fetch()
                if got is None:
                    self._pump()
                    continue
                env, method = got
                if env.kind == P.KIND_RESPONSE and env.correlation_id == req.id:
                    self.ack(method)
                    return env
                deferred.append(got)  # hold aside; do NOT re-read into _pending
        finally:
            for g in reversed(deferred):
                self._pending.appendleft(g)
        raise TimeoutError(f"no response from {to!r} within {timeout}s (req {req.id})")

    def respond(self, request: P.Envelope, body: Optional[dict] = None,
                subject: Optional[str] = None) -> str:
        if not request.reply_to:
            raise ValueError("request has no reply_to; cannot respond")
        env = P.Envelope(kind=P.KIND_RESPONSE, frm=self.agent, to=request.reply_to,
                         subject=subject or request.subject, body=body or {},
                         correlation_id=request.id)
        self._publish(P.EXCHANGE_DIRECT, request.reply_to, env)
        return env.id

    # -- receive --------------------------------------------------------------
    def ack(self, method) -> None:
        self._ch.basic_ack(delivery_tag=method.delivery_tag)

    def nack(self, method, requeue: bool = True) -> None:
        self._ch.basic_nack(delivery_tag=method.delivery_tag, requeue=requeue)

    def recv(self, timeout: Optional[float] = None,
             kinds: Optional[List[str]] = None) -> Optional[Received]:
        """Return (envelope, method) or None on timeout. Caller acks (or uses
        consume() which acks for you). If `kinds` is given, non-matching messages
        are held for a later call (never re-read into this loop)."""
        deadline = None if timeout is None else time.monotonic() + timeout
        deferred = []
        try:
            while True:
                got = self._pending.popleft() if self._pending else self._fetch()
                if got is not None:
                    if kinds is None or got[0].kind in kinds:
                        return got
                    deferred.append(got)
                if deadline is not None and time.monotonic() >= deadline:
                    return None
                self._pump()
        finally:
            for g in reversed(deferred):
                self._pending.appendleft(g)

    def consume(self, handler: Callable[[P.Envelope], None],
                max_messages: Optional[int] = None, idle_timeout: float = 1.0) -> int:
        """Consume loop: call handler(env); ack on success, nack+requeue on error.
        Stops after `max_messages` or after `idle_timeout` seconds of silence
        (the idle deadline resets on every delivery). `idle_timeout=None` runs
        until KeyboardInterrupt. Poll-based on basic_get, consistent with recv().
        """
        n = 0
        deadline = None if idle_timeout is None else time.monotonic() + idle_timeout
        try:
            while True:
                got = self._next()
                if got is not None:
                    env, method = got
                    try:
                        handler(env)
                    except Exception:
                        self.nack(method, requeue=True)  # re-deliver later
                        raise
                    self.ack(method)
                    n += 1
                    if max_messages is not None and n >= max_messages:
                        break
                    if idle_timeout is not None:
                        deadline = time.monotonic() + idle_timeout
                    continue
                if deadline is not None and time.monotonic() >= deadline:
                    break
                self._conn.process_data_events()
                time.sleep(0.05)
        except KeyboardInterrupt:
            pass
        return n

    # -- subscriptions --------------------------------------------------------
    def subscribe(self, patterns: List[str]) -> None:
        for pattern in patterns:
            self._ch.queue_bind(queue=P.queue_name(self.agent),
                                exchange=P.EXCHANGE_EVENTS, routing_key=pattern)
            if pattern not in self.patterns:
                self.patterns.append(pattern)

    def unsubscribe(self, pattern: str) -> None:
        self._ch.queue_unbind(queue=P.queue_name(self.agent),
                              exchange=P.EXCHANGE_EVENTS, routing_key=pattern)
        self.patterns = [p for p in self.patterns if p != pattern]

    # -- lifecycle ------------------------------------------------------------
    def close(self) -> None:
        try:
            if self._ch.is_open:
                self._ch.close()
        except Exception:
            pass
        try:
            if self._conn.is_open:
                self._conn.close()
        except Exception:
            pass


def connect(agent: str, **kw) -> AgentBus:
    """Sugar so callers can `from iac import connect`."""
    return AgentBus(agent, **kw)
