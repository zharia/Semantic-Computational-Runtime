from std.collections import Dict, List
from .entity import Entity
from .relationship import Relationship
from .value import Value, value_int

struct SemanticState(Copyable):
    var entities: Dict[String, Entity]
    var relationships: Dict[String, Relationship]
    var logical_step: Int

    def __init__(out self):
        self.entities = Dict[String, Entity]()
        self.relationships = Dict[String, Relationship]()
        self.logical_step = 0

    def add_entity(mut self, entity: Entity) raises:
        if entity.id in self.entities:
            raise Error("semantic identity already exists: " + entity.id)
        self.entities[entity.id] = entity.copy()

    def get_entity(self, id: String) raises -> Entity:
        if id not in self.entities:
            raise Error("semantic entity not found: " + id)
        return self.entities[id].copy()

    def add_relationship(mut self, rel: Relationship) raises:
        if rel.source not in self.entities:
            raise Error("relationship source does not exist: " + rel.source)
        if rel.target not in self.entities:
            raise Error("relationship target does not exist: " + rel.target)
        self.relationships[rel.id] = rel.copy()

    def get_int(self, entity_id: String, property_name: String) raises -> Int:
        var entity = self.get_entity(entity_id)
        var val = entity.get(property_name)
        return value_int(val)

    def set_value(mut self, entity_id: String, property_name: String, val: Value) raises:
        if entity_id not in self.entities:
            raise Error("semantic entity not found: " + entity_id)
        var entity = self.entities[entity_id].copy()
        entity.set(property_name, val)
        self.entities[entity_id] = entity^
