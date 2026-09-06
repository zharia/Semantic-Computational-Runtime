from dataclasses import dataclass

@dataclass
class ExecutionState:
    step: int = 0
    status: str = "ready"
