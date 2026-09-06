from scr_reference.constraint import NonNegativeConstraint
from scr_reference.entity import Entity
from scr_reference.execution import INCREMENT, Executor, Transformation
from scr_reference.field import SemanticField
from scr_reference.value import Value

def main() raises:
    var field = SemanticField()

    var counter = Entity("counter", "Counter")
    counter.set("value", Value(2))
    field.add_entity(counter)

    field.add_non_negative_constraint(
        NonNegativeConstraint("counter", "value")
    )

    var executor = Executor(field)

    executor.execute(
        Transformation(INCREMENT, "counter", "value", 3)
    )

    var before_failure = executor.field.get_int(
        "counter",
        "value",
    )

    try:
        executor.execute(
            Transformation(INCREMENT, "counter", "value", -10)
        )
    except e:
        print("Expected constraint failure:", e)

    var after_failure = executor.field.get_int(
        "counter",
        "value",
    )

    print("Before failed transformation:", before_failure)
    print("After failed transformation:", after_failure)

    assert before_failure == after_failure
    assert executor.state.logical_step == 1
    assert len(executor.state.trace) == 1
