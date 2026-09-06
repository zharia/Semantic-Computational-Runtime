


struct Relationship(Copyable, Writable):
    var id: String
    var relation: String
    var source: String
    var target: String

    def __init__(
        out self,
        id: String,
        relation: String,
        source: String,
        target: String,
    ):
        self.id = id
        self.relation = relation
        self.source = source
        self.target = target

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            "Relationship(",
            self.id,
            ": ",
            self.source,
            " -",
            self.relation,
            "-> ",
            self.target,
            ")",
        )
