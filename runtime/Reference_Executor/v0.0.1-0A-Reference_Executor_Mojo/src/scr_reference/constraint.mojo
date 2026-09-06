struct NonNegativeConstraint(Copyable):
    var entity_id: String
    var property_name: String

    def __init__(
        out self,
        entity_id: String,
        property_name: String,
    ):
        self.entity_id = entity_id
        self.property_name = property_name

    def validate(self, value: Int) raises:
        if value < 0:
            raise Error(
                "constraint violation: "
                + self.entity_id
                + "."
                + self.property_name
                + " must be >= 0"
            )

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            "NonNegative(",
            self.entity_id,
            ".",
            self.property_name,
            ")",
        )
