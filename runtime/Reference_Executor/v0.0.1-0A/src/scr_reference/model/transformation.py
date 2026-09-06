from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class Transformation:
    id: str
    operation: str
    target: str
    argument: Any = None
