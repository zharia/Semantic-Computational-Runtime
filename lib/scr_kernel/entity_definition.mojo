from std.collections import Dict, List
from .value import Value

struct EntityDefinition(Copyable, Writable):
    var type_id: String
    var value_schema: List[String]

    def __init__(out self, type_id: String):
        self.type_id = type_id
        self.value_schema = List[String]()

    def add_property(mut self, name: String):
        self.value_schema.append(name)

    def has_property(self, name: String) -> Bool:
        for i in range(len(self.value_schema)):
            if self.value_schema[i] == name:
                return True
        return False

    def conforms(self, values: Dict[String, Value]) -> Bool:
        for i in range(len(self.value_schema)):
            if self.value_schema[i] not in values:
                return False
        return True

    def write_to(self, mut writer: Some[Writer]):
        writer.write("EntityDefinition(", self.type_id, ")")
