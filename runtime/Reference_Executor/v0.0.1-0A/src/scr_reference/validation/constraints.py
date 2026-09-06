from __future__ import annotations
from typing import Any
from ..model.constraint import Constraint
from ..model.field import SemanticField

class ConstraintViolation(Exception):
    def __init__(self, constraint: Constraint):
        self.constraint = constraint
        super().__init__(f"Constraint violated: {constraint.entity}.{constraint.property} {constraint.operator} {constraint.value!r}")

def _value(field: SemanticField, constraint: Constraint) -> Any:
    entity = field.require_entity(constraint.entity)
    if constraint.property == "value": return entity.value
    if constraint.property in entity.properties: return entity.properties[constraint.property]
    raise KeyError(f"Unknown property: {constraint.entity}.{constraint.property}")

def _evaluate(actual: Any, operator: str, expected: Any) -> bool:
    if operator == "==": return actual == expected
    if operator == "!=": return actual != expected
    if operator == "<": return actual < expected
    if operator == "<=": return actual <= expected
    if operator == ">": return actual > expected
    if operator == ">=": return actual >= expected
    if operator == "in": return actual in expected
    raise ValueError(f"Unsupported constraint operator: {operator}")

def validate_constraints(field: SemanticField) -> None:
    for constraint in field.constraints:
        actual = _value(field, constraint)
        if not _evaluate(actual, constraint.operator, constraint.value):
            raise ConstraintViolation(constraint)
