from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class Constraint:
    entity: str
    property: str
    operator: str
    value: Any
