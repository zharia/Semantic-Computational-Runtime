struct SemanticIdentity(Copyable, Writable):
    var entity_id: String
    var representation_tag: String

    def __init__(out self, entity_id: String, representation_tag: String = "default"):
        self.entity_id = entity_id
        self.representation_tag = representation_tag

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Identity(", self.entity_id, ")")
