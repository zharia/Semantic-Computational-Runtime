from std.collections import List

from .field import SemanticField
from .value import Value

comptime SET_INT = 1
comptime INCREMENT = 2
comptime EMIT = 3

struct Transformation(Copyable):
    var operation: Int
    var entity_id: String
    var property_name: String
    var operand: Int

    def __init__(
        out self,
        operation: Int,
        entity_id: String,
        property_name: String,
        operand: Int = 0,
    ):
        self.operation = operation
        self.entity_id = entity_id
        self.property_name = property_name
        self.operand = operand

struct Observation(Copyable):
    var step: Int
    var entity_id: String
    var property_name: String
    var value: Value

    def __init__(
        out self,
        step: Int,
        entity_id: String,
        property_name: String,
        value: Value,
    ):
        self.step = step
        self.entity_id = entity_id
        self.property_name = property_name
        self.value = value

struct TraceEvent(Copyable):
    var step: Int
    var operation: Int
    var entity_id: String
    var property_name: String
    var before: Value
    var after: Value

    def __init__(
        out self,
        step: Int,
        operation: Int,
        entity_id: String,
        property_name: String,
        before: Value,
        after: Value,
    ):
        self.step = step
        self.operation = operation
        self.entity_id = entity_id
        self.property_name = property_name
        self.before = before
        self.after = after

struct ExecutionState(Copyable):
    var logical_step: Int
    var observations: List[Observation]
    var trace: List[TraceEvent]

    def __init__(out self):
        self.logical_step = 0
        self.observations = List[Observation]()
        self.trace = List[TraceEvent]()

struct Executor:
    var field: SemanticField
    var state: ExecutionState

    def __init__(out self, field: SemanticField):
        self.field = field.copy()
        self.state = ExecutionState()

    def execute(
        mut self,
        transformation: Transformation,
    ) raises:
        var candidate = self.field.copy()

        if transformation.operation == SET_INT:
            var before = candidate.get_int(
                transformation.entity_id,
                transformation.property_name,
            )

            candidate.set_value(
                transformation.entity_id,
                transformation.property_name,
                Value(transformation.operand),
            )
            candidate.validate()

            var after = candidate.get_int(
                transformation.entity_id,
                transformation.property_name,
            )

            var next_step = self.state.logical_step + 1
            self.state.logical_step = next_step
            self.state.trace.append(
                TraceEvent(
                    next_step,
                    transformation.operation,
                    transformation.entity_id,
                    transformation.property_name,
                    Value(before),
                    Value(after),
                )
            )

            self.field = candidate^

        elif transformation.operation == INCREMENT:
            var before = candidate.get_int(
                transformation.entity_id,
                transformation.property_name,
            )
            var after = before + transformation.operand

            candidate.set_value(
                transformation.entity_id,
                transformation.property_name,
                Value(after),
            )
            candidate.validate()

            var next_step = self.state.logical_step + 1
            self.state.logical_step = next_step
            self.state.trace.append(
                TraceEvent(
                    next_step,
                    transformation.operation,
                    transformation.entity_id,
                    transformation.property_name,
                    Value(before),
                    Value(after),
                )
            )

            self.field = candidate^

        elif transformation.operation == EMIT:
            var entity = candidate.get_entity(
                transformation.entity_id
            )
            var value = entity.get(transformation.property_name)

            self.state.observations.append(
                Observation(
                    self.state.logical_step,
                    transformation.entity_id,
                    transformation.property_name,
                    value,
                )
            )

        else:
            raise Error("unknown semantic transformation")
