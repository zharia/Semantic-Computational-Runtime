struct SemanticContext(Copyable):
    var logical_step: Int
    var label: String

    def __init__(out self, logical_step: Int = 0, label: String = "default"):
        self.logical_step = logical_step
        self.label = label

    def with_step(self, step: Int) -> SemanticContext:
        return SemanticContext(step, self.label)
