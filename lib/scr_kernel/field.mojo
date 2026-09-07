from std.collections import Dict, List
from .constraint import NonNegativeConstraint
from .entity import Entity
from .observation import Observation
from .relationship import Relationship
from .state import SemanticState
from .transformation import Transformation, SET_INT, INCREMENT, EMIT
from .value import Value, value_int

struct SemanticField(Copyable):
    var state: SemanticState
    var constraints: List[NonNegativeConstraint]
    var observations: List[Observation]

    def __init__(out self):
        self.state = SemanticState()
        self.constraints = List[NonNegativeConstraint]()
        self.observations = List[Observation]()

    def add_entity(mut self, entity: Entity) raises:
        self.state.add_entity(entity)

    def add_relationship(mut self, rel: Relationship) raises:
        self.state.add_relationship(rel)

    def add_constraint(mut self, constraint: NonNegativeConstraint):
        self.constraints.append(constraint.copy())

    def get_entity(self, id: String) raises -> Entity:
        return self.state.get_entity(id)

    def get_int(self, entity_id: String, property_name: String) raises -> Int:
        return self.state.get_int(entity_id, property_name)

    def validate_state(self, state: SemanticState) raises:
        for constraint in self.constraints:
            var value = state.get_int(
                constraint.entity_id,
                constraint.property_name,
            )
            constraint.validate(value)

    def validate(self) raises:
        self.validate_state(self.state)

    def execute(mut self, transformation: Transformation) raises:
        var candidate = self.state.copy()

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
            self.state = candidate^
            self.state.logical_step += 1

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
            self.validate_state(candidate)
            self.state = candidate^
            self.state.logical_step += 1

        elif transformation.operation == EMIT:
            var entity = candidate.get_entity(transformation.entity_id)
            var val = entity.get(transformation.property_name)
            self.observations.append(
                Observation(
                    self.state.logical_step,
                    transformation.entity_id,
                    transformation.property_name,
                    val,
                )
            )
        else:
            raise Error("unknown semantic transformation")
