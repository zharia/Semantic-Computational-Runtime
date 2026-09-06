from __future__ import annotations
from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class Value:
    type: str
    data: Any

    @classmethod
    def infer(cls, data: Any) -> "Value":
        if isinstance(data, bool): return cls("Boolean", data)
        if isinstance(data, int): return cls("Integer", data)
        if isinstance(data, float): return cls("Real", data)
        if isinstance(data, str): return cls("Text", data)
        if isinstance(data, list): return cls("Sequence", data)
        if data is None: return cls("Null", None)
        raise TypeError(f"Unsupported semantic value: {type(data).__name__}")
