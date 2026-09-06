from scr_reference.entity import Entity
from scr_reference.execution import (
    EMIT,
    INCREMENT,
    Executor,
    Transformation,
)
from scr_reference.field import SemanticField
from scr_reference.value import Value, value_int

def main() raises:
    var field = SemanticField()

    var counter = Entity("counter", "Counter")
    counter.set("value", Value(0))
    field.add_entity(counter)

    var executor = Executor(field)

    executor.execute(
        Transformation(INCREMENT, "counter", "value", 5)
    )
    executor.execute(
        Transformation(INCREMENT, "counter", "value", 7)
    )
    executor.execute(
        Transformation(EMIT, "counter", "value")
    )

    var final_value = executor.field.get_int(
        "counter",
        "value",
    )

    print("Final value:", final_value)
    print("Logical step:", executor.state.logical_step)
