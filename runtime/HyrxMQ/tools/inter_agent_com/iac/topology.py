"""Idempotent topology bootstrap.

Declare the shared exchanges and an individual agent's queue + bindings. Safe to
run repeatedly (RabbitMQ re-declares are no-ops when the arguments match).
"""

from __future__ import annotations

from typing import Iterable, List

import pika
from pika.adapters.blocking_connection import BlockingChannel

from . import protocol as P


def declare_exchanges(channel: BlockingChannel) -> None:
    channel.exchange_declare(exchange=P.EXCHANGE_DIRECT, exchange_type="direct", durable=True)
    channel.exchange_declare(exchange=P.EXCHANGE_BROADCAST, exchange_type="fanout", durable=True)
    channel.exchange_declare(exchange=P.EXCHANGE_EVENTS, exchange_type="topic", durable=True)


def ensure_agent_queue(channel: BlockingChannel, agent: str,
                       event_patterns: List[str]) -> str:
    """Create `agent`'s queue and attach it to all three exchanges.

      * direct   <- rk = <agent>          (point-to-point)
      * broadcast<- (fanout, no rk)        (all-agent)
      * events   <- each topic pattern     (pub/sub categories)

    Returns the queue name.
    """
    q = P.queue_name(agent)
    channel.queue_declare(queue=q, durable=True, auto_delete=False)
    channel.queue_bind(queue=q, exchange=P.EXCHANGE_DIRECT, routing_key=agent)
    channel.queue_bind(queue=q, exchange=P.EXCHANGE_BROADCAST)
    for pattern in event_patterns:
        channel.queue_bind(queue=q, exchange=P.EXCHANGE_EVENTS, routing_key=pattern)
    return q


def bootstrap(channel: BlockingChannel, agents: Iterable[str]) -> None:
    """Declare exchanges + a default set of agent queues in one call."""
    declare_exchanges(channel)
    for a in agents:
        ensure_agent_queue(channel, a, P.default_event_patterns(a))


def teardown_agent(channel: BlockingChannel, agent: str) -> None:
    """Delete one agent's queue (leaves shared exchanges intact)."""
    channel.queue_delete(queue=P.queue_name(agent))
