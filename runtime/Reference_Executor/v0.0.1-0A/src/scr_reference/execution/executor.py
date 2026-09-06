from __future__ import annotations
from dataclasses import dataclass, field as dc_field
from ..model.field import SemanticField
from ..model.observation import Observation
from ..model.transformation import Transformation
from ..operations.registry import OperationRegistry, default_registry
from ..validation.constraints import validate_constraints
from .state import ExecutionState
from .trace import ExecutionTrace, TraceEntry

class ExecutionError(Exception): pass

@dataclass
class ExecutionResult:
    field: SemanticField
    observations: list[Observation] = dc_field(default_factory=list)
    trace: ExecutionTrace = dc_field(default_factory=ExecutionTrace)

class ReferenceExecutor:
    def __init__(self, field: SemanticField, registry: OperationRegistry | None = None):
        self.field = field
        self.registry = registry or default_registry()
        self.state = ExecutionState()
        self.trace = ExecutionTrace()
        self.observations: list[Observation] = []

    def execute(self, transformations: list[Transformation], observations=None) -> ExecutionResult:
        validate_constraints(self.field)
        self.state.status = "running"
        for transformation in transformations:
            candidate = self.field.snapshot()
            before = candidate.require_entity(transformation.target).value
            try:
                self.registry.execute(transformation.operation, candidate, transformation.target, transformation.argument)
                validate_constraints(candidate)
            except Exception as exc:
                self.state.status = "failed"
                raise ExecutionError(f"Transformation {transformation.id!r} failed: {exc}") from exc
            self.field = candidate
            self.state.step += 1
            after = self.field.require_entity(transformation.target).value
            self.trace.add(TraceEntry(self.state.step, transformation.id, transformation.operation, transformation.target, before, after))
        if observations:
            for entity_id, property_name in observations:
                entity = self.field.require_entity(entity_id)
                value = entity.value if property_name == "value" else entity.properties[property_name]
                self.observations.append(Observation(self.state.step, entity_id, property_name, value))
        self.state.status = "complete"
        return ExecutionResult(self.field, self.observations, self.trace)
