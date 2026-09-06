from __future__ import annotations
from dataclasses import asdict, dataclass
from typing import Any

@dataclass(frozen=True)
class TraceEntry:
    step: int
    transformation_id: str
    operation: str
    target: str
    before: Any
    after: Any

@dataclass
class ExecutionTrace:
    entries: list[TraceEntry]
    def __init__(self): self.entries = []
    def add(self, entry): self.entries.append(entry)
    def as_dict(self): return [asdict(e) for e in self.entries]
