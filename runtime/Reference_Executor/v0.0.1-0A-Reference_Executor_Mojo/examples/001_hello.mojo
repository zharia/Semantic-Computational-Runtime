from scr_reference.entity import Entity
from scr_reference.execution import EMIT, Executor, Transformation
from scr_reference.field import SemanticField
from scr_reference.value import Value, value_string

def main() raises:
    var field = SemanticField()

    var greeting = Entity("greeting", "Message")
    greeting.set(
        "text",
        Value("Hello, Semantic Field!"),
    )
    field.add_entity(greeting)

    var executor = Executor(field)

    executor.execute(
        Transformation(EMIT, "greeting", "text")
    )

    var observed = executor.state.observations[0].value.copy()

    print("SCR 0A")
    print("Observed:", value_string(observed))
