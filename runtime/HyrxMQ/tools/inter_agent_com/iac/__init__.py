"""Inter-Agent Communication (IAC) — a small RabbitMQ/AMQP message bus.

Public API:
    from iac import AgentBus, connect, Config, Envelope
    from iac import bootstrap_topology          # declare exchanges+queues

See protocol.md for the wire format and topology conventions.
"""

from . import protocol
from .bus import AgentBus, connect
from .config import Config
from .protocol import Envelope
from .topology import (
    bootstrap as bootstrap_topology,
    declare_exchanges,
    ensure_agent_queue,
    teardown_agent,
)

__all__ = [
    "AgentBus", "connect", "Config", "Envelope",
    "bootstrap_topology", "declare_exchanges", "ensure_agent_queue",
    "teardown_agent", "protocol",
]
__version__ = "0.1.0"
