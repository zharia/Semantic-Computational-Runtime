from dataclasses import dataclass

@dataclass(frozen=True)
class Relationship:
    source: str
    type: str
    target: str
