from __future__ import annotations
from collections.abc import Callable
from typing import Any
from ..model.field import SemanticField

class OperationError(Exception): pass
Operation = Callable[[SemanticField, str, Any], None]

class OperationRegistry:
    def __init__(self) -> None: self._operations: dict[str, Operation] = {}
    def register(self, name: str, operation: Operation) -> None:
        if name in self._operations: raise ValueError(f"Operation already registered: {name}")
        self._operations[name] = operation
    def execute(self, name: str, field: SemanticField, target: str, argument: Any) -> None:
        try: operation = self._operations[name]
        except KeyError as exc: raise OperationError(f"Unknown operation: {name}") from exc
        operation(field, target, argument)

def _set(field, target, argument): field.require_entity(target).value = argument

def _increment(field, target, argument):
    entity = field.require_entity(target)
    if not isinstance(entity.value, int) or isinstance(entity.value, bool): raise OperationError("increment requires an Integer value")
    if not isinstance(argument, int) or isinstance(argument, bool): raise OperationError("increment requires an Integer argument")
    entity.value += argument

def _add(field, target, argument):
    entity = field.require_entity(target)
    try: entity.value += argument
    except TypeError as exc: raise OperationError("add operands are incompatible") from exc

def _multiply(field, target, argument):
    entity = field.require_entity(target)
    try: entity.value *= argument
    except TypeError as exc: raise OperationError("multiply operands are incompatible") from exc

def _append(field, target, argument):
    entity = field.require_entity(target)
    if not isinstance(entity.value, list): raise OperationError("append requires a Sequence value")
    entity.value.append(argument)

def _emit(field, target, argument): field.require_entity(target)

def default_registry():
    registry = OperationRegistry()
    for name, fn in {"set":_set,"increment":_increment,"add":_add,"multiply":_multiply,"append":_append,"emit":_emit}.items():
        registry.register(name, fn)
    return registry
