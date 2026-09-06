from std.collections import Dict, List

from .constraint import NonNegativeConstraint
from .entity import Entity
from .relationship import Relationship
from .value import Value, value_int

struct SemanticField(Copyable):
    var entities: Dict[String, Entity]
    var relationships: Dict[String, Relationship]
    var non_negative_constraints: List[NonNegativeConstraint]

    def __init__(out self):
        self.entities = Dict[String, Entity]()
        self.relationships = Dict[String, Relationship]()
        self.non_negative_constraints = List[NonNegativeConstraint]()

    def add_entity(mut self, entity: Entity) raises:
        if entity.id in self.entities:
            raise Error("semantic identity already exists: " + entity.id)
        self.entities[entity.id] = entity.copy()

    def add_relationship(
        mut self,
        relationship: Relationship,
    ) raises:
        if relationship.id in self.relationships:
            raise Error(
                "relationship identity already exists: "
                + relationship.id
            )
        if relationship.source not in self.entities:
            raise Error(
                "relationship source does not exist: "
                + relationship.source
            )
        if relationship.target not in self.entities:
            raise Error(
                "relationship target does not exist: "
                + relationship.target
            )
        self.relationships[relationship.id] = relationship.copy()

    def relationship_count(self) -> Int:
        return len(self.relationships)


    def relationship_ids(self) -> List[String]:
        var ids = List[String]()
        for id in self.relationships.keys():
            ids.append(id)
        return ids.copy()

    def get_relationship(self, id: String) raises -> Relationship:
        return self.relationships[id].copy()

    def add_non_negative_constraint(
        mut self,
        constraint: NonNegativeConstraint,
    ):
        self.non_negative_constraints.append(constraint.copy())

    def get_entity(self, id: String) raises -> Entity:
        if id not in self.entities:
            raise Error("semantic entity not found: " + id)
        return self.entities[id].copy()

    def get_int(
        self,
        entity_id: String,
        property_name: String,
    ) raises -> Int:
        var entity = self.get_entity(entity_id)
        var value = entity.get(property_name)
        return value_int(value)

    def set_value(
        mut self,
        entity_id: String,
        property_name: String,
        value: Value,
    ) raises:
        if entity_id not in self.entities:
            raise Error("semantic entity not found: " + entity_id)

        var entity = self.entities[entity_id].copy()
        entity.set(property_name, value)
        self.entities[entity_id] = entity^

    def validate(self) raises:
        for constraint in self.non_negative_constraints:
            var value = self.get_int(
                constraint.entity_id,
                constraint.property_name,
            )
            constraint.validate(value)
