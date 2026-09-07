from .value import Value

struct Observation(Copyable):
    var step: Int
    var entity_id: String
    var property_name: String
    var value: Value

    def __init__(out self, step: Int, entity_id: String, property_name: String, val: Value):
        self.step = step
        self.entity_id = entity_id
        self.property_name = property_name
        self.value = val
