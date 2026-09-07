struct SemanticIdentity(Copyable, Writable):
    var entity_id: String

    def __init__(out self, entity_id: String):
        self.entity_id = entity_id

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Identity(", self.entity_id, ")")
