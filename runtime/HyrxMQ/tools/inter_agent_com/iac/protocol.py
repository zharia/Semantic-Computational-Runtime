"""Wire protocol for inter-agent communication (IAC) over AMQP/RabbitMQ.

Codifies three things the whole tool shares:
  1. the exchange/queue topology (names are derived, never hand-typed),
  2. the message envelope (a small, fixed JSON schema),
  3. the routing-key / binding conventions each kind uses.

Nothing here touches the network — this module is pure data, so it is trivially
testable offline (see ../smoke_test.py).
"""

from __future__ import annotations

import json
import uuid
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

PROTOCOL_VERSION = 1

# --- Topology names ---------------------------------------------------------
# direct   : point-to-point, routing_key == recipient agent name
# broadcast: fanout, every agent's queue is bound -> one write, all receive
# events   : topic, agents bind patterns -> classified pub/sub (task.*, ctrl.*)
EXCHANGE_DIRECT = "iac.direct"
EXCHANGE_BROADCAST = "iac.broadcast"
EXCHANGE_EVENTS = "iac.events"

QUEUE_PREFIX = "iac.q."


def queue_name(agent: str) -> str:
    """The one queue that belongs to `agent`."""
    return f"{QUEUE_PREFIX}{agent}"


def default_event_patterns(agent: str) -> List[str]:
    """Topic bindings an agent gets by default: events addressed to it plus
    control messages targeted at it. Broadcast needs no pattern (fanout)."""
    return [f"{agent}.#", f"ctrl.{agent}", "ctrl.*"]


# --- Message kinds ----------------------------------------------------------
KIND_MSG = "msg"              # point-to-point
KIND_BROADCAST = "broadcast"  # to all agents
KIND_EVENT = "event"          # topic-classified
KIND_REQUEST = "request"      # expects a response (correlation_id set)
KIND_RESPONSE = "response"    # answers a request
KIND_CTRL = "ctrl"            # control / lifecycle (presence, shutdown, ...)

ALL_KINDS = (
    KIND_MSG, KIND_BROADCAST, KIND_EVENT,
    KIND_REQUEST, KIND_RESPONSE, KIND_CTRL,
)


def _new_id() -> str:
    return uuid.uuid4().hex


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


@dataclass
class Envelope:
    """The single envelope every IAC message uses.

    Fields
    ------
    kind    : one of ALL_KINDS.
    frm     : sending agent's name.
    to      : recipient agent name (p2p/request/response); None for broadcast/event.
    subject : short human-readable label (like an email subject).
    body    : free JSON dict — the payload. Keep it small (AMQP frame limit).
    id      : unique message id (also the correlation anchor for replies).
    ts      : ISO-8601 UTC send time.
    reply_to: agent name that wants the response (set by request()).
    correlation_id: id of the request a response answers.
    """

    kind: str
    frm: str
    subject: str
    to: Optional[str] = None
    body: Dict[str, Any] = field(default_factory=dict)
    id: str = field(default_factory=_new_id)
    ts: str = field(default_factory=_now)
    reply_to: Optional[str] = None
    correlation_id: Optional[str] = None
    v: int = PROTOCOL_VERSION

    def dumps(self) -> str:
        return json.dumps(asdict(self), separators=(",", ":"), ensure_ascii=False)

    @classmethod
    def loads(cls, raw) -> "Envelope":
        if isinstance(raw, (bytes, bytearray)):
            raw = raw.decode("utf-8")
        data = json.loads(raw)
        ver = data.get("v", 0)
        if ver != PROTOCOL_VERSION:
            raise ValueError(f"IAC protocol version mismatch: got {ver!r}, want {PROTOCOL_VERSION}")
        # ignore unknown keys so the schema can grow without breaking readers
        known = {f for f in cls.__dataclass_fields__}  # type: ignore[attr-defined]
        return cls(**{k: v for k, v in data.items() if k in known})

    # convenience for readers
    def is_response_for(self, request_id: str) -> bool:
        return self.kind == KIND_RESPONSE and self.correlation_id == request_id
