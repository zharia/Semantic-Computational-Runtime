from .state import SemanticState
from .value import Value, value_int

comptime SET_INT = 1
comptime INCREMENT = 2
comptime EMIT = 3

struct Transformation(Copyable):
    var operation: Int
    var entity_id: String
    var property_name: String
    var operand: Int

    def __init__(out self, operation: Int, entity_id: String, property_name: String, operand: Int = 0):
        self.operation = operation
        self.entity_id = entity_id
        self.property_name = property_name
        self.operand = operand
