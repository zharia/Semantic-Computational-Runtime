from std.collections import Dict

from .value import Value

struct Entity(Copyable):
    var id: String
    var kind: String
    var properties: Dict[String, Value]

    def __init__(out self, id: String, kind: String):
        self.id = id
        self.kind = kind
        self.properties = Dict[String, Value]()

    def set(mut self, name: String, value: Value):
        self.properties[name] = value

    def has(self, name: String) -> Bool:
        return name in self.properties

    def get(self, name: String) raises -> Value:
        if not self.has(name):
            raise Error("semantic property not found: " + name)
        return self.properties[name].copy()

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Entity(", self.id, ", ", self.kind, ")")
