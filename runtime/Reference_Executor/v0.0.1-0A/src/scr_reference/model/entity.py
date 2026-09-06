from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any

@dataclass
class Entity:
    id: str
    type: str
    value: Any = None
    properties: dict[str, Any] = field(default_factory=dict)
