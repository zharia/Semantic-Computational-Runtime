from std.collections import Dict
from .entity_definition import EntityDefinition
from .entity import Entity
from .value import Value

struct EntityInstance(Copyable, Writable):
    var entity: Entity
    var definition_type: String

    def __init__(out self, entity_id: String, definition_type: String):
        self.entity = Entity(entity_id, definition_type)
        self.definition_type = definition_type

    def set(mut self, name: String, val: Value):
        self.entity.set(name, val)

    def get(self, name: String) raises -> Value:
        return self.entity.get(name)

    def conforms(self, defn: EntityDefinition) -> Bool:
        if self.definition_type != defn.type_id:
            return False
        return defn.conforms(self.entity.properties)

    def write_to(self, mut writer: Some[Writer]):
        writer.write("EntityInstance(", self.entity.id, ": ", self.definition_type, ")")
