from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class Observation:
    step: int
    entity: str
    property: str
    value: Any
