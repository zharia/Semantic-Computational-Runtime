from std.collections import Dict
from .entity_definition import EntityDefinition
from .value import Value

struct Entity(Copyable, Writable):
    var id: String
    var type_id: String
    var properties: Dict[String, Value]

    def __init__(out self, id: String, type_id: String):
        self.id = id
        self.type_id = type_id
        self.properties = Dict[String, Value]()

    def set(mut self, name: String, value: Value):
        self.properties[name] = value

    def has(self, name: String) -> Bool:
        return name in self.properties

    def get(self, name: String) raises -> Value:
        if not self.has(name):
            raise Error("semantic property not found: " + name)
        return self.properties[name].copy()

    def conforms(self, defn: EntityDefinition) -> Bool:
        if self.type_id != defn.type_id:
            return False
        return defn.conforms(self.properties)

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Entity(", self.id, ": ", self.type_id, ")")
