from std.collections import Dict
from .entity_definition import EntityDefinition
from .identity import SemanticIdentity
from .value import Value

struct EntityInstance(Copyable, Writable):
    var identity: SemanticIdentity
    var definition_type: String
    var values: Dict[String, Value]

    def __init__(out self, entity_id: String, definition_type: String):
        self.identity = SemanticIdentity(entity_id)
        self.definition_type = definition_type
        self.values = Dict[String, Value]()

    def set(mut self, name: String, val: Value):
        self.values[name] = val

    def get(self, name: String) raises -> Value:
        if name not in self.values:
            raise Error("semantic property not found: " + name)
        return self.values[name].copy()

    def conforms(self, defn: EntityDefinition) -> Bool:
        if self.definition_type != defn.type_id:
            return False
        return defn.conforms(self.values)

    def write_to(self, mut writer: Some[Writer]):
        writer.write("EntityInstance(", self.identity.entity_id, ": ", self.definition_type, ")")
