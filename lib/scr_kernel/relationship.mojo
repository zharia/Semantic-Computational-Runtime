struct Relationship(Copyable, Writable):
    var id: String
    var kind: String
    var source: String
    var target: String

    def __init__(out self, id: String, kind: String, source: String, target: String):
        self.id = id
        self.kind = kind
        self.source = source
        self.target = target

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Relationship(", self.id, ": ", self.source, " -", self.kind, "-> ", self.target, ")")
