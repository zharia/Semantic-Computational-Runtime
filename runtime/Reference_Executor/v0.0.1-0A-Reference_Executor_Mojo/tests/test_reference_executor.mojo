from std.testing import (
    TestSuite,
    assert_equal,
    assert_raises,
    assert_true,
)

from scr_reference.constraint import NonNegativeConstraint
from scr_reference.entity import Entity
from scr_reference.execution import (
    EMIT,
    INCREMENT,
    Executor,
    Transformation,
)
from scr_reference.field import SemanticField
from scr_reference.relationship import Relationship
from scr_reference.value import Value, value_int, value_string


def test_entity_identity() raises:
    var field = SemanticField()
    field.add_entity(Entity("e1", "Thing"))

    var entity = field.get_entity("e1")

    assert_equal(entity.id, "e1")
    assert_equal(entity.kind, "Thing")


def test_duplicate_entity_identity_is_rejected() raises:
    var field = SemanticField()
    field.add_entity(Entity("e1", "Thing"))

    with assert_raises(contains="semantic identity already exists"):
        field.add_entity(Entity("e1", "OtherThing"))


def test_relationship_requires_existing_entities() raises:
    var field = SemanticField()
    field.add_entity(Entity("a", "Thing"))

    with assert_raises(contains="relationship target does not exist"):
        field.add_relationship(
            Relationship(
                "r1",
                "CONNECTS",
                "a",
                "missing",
            )
        )


def test_relationship_is_stored() raises:
    var field = SemanticField()
    field.add_entity(Entity("a", "Thing"))
    field.add_entity(Entity("b", "Thing"))

    field.add_relationship(
        Relationship("r1", "CONNECTS", "a", "b")
    )

    assert_equal(len(field.relationships), 1)


def test_increment_transforms_state() raises:
    var field = SemanticField()

    var counter = Entity("counter", "Counter")
    counter.set("value", Value(10))
    field.add_entity(counter)

    var executor = Executor(field)

    executor.execute(
        Transformation(INCREMENT, "counter", "value", 5)
    )

    assert_equal(
        executor.field.get_int("counter", "value"),
        15,
    )
    assert_equal(executor.state.logical_step, 1)
    assert_equal(len(executor.state.trace), 1)


def test_observation_does_not_advance_time() raises:
    var field = SemanticField()

    var entity = Entity("x", "Thing")
    entity.set("value", Value(42))
    field.add_entity(entity)

    var executor = Executor(field)

    executor.execute(
        Transformation(EMIT, "x", "value")
    )

    assert_equal(executor.state.logical_step, 0)
    assert_equal(len(executor.state.observations), 1)

    var observed = executor.state.observations[0].value.copy()
    assert_equal(value_int(observed), 42)


def test_constraint_failure_rolls_back() raises:
    var field = SemanticField()

    var counter = Entity("counter", "Counter")
    counter.set("value", Value(1))
    field.add_entity(counter)

    field.add_non_negative_constraint(
        NonNegativeConstraint("counter", "value")
    )

    var executor = Executor(field)

    executor.execute(
        Transformation(INCREMENT, "counter", "value", 2)
    )

    with assert_raises(contains="constraint violation"):
        executor.execute(
            Transformation(INCREMENT, "counter", "value", -10)
        )

    assert_equal(
        executor.field.get_int("counter", "value"),
        3,
    )
    assert_equal(executor.state.logical_step, 1)
    assert_equal(len(executor.state.trace), 1)


def test_failed_transformation_does_not_create_observation() raises:
    var field = SemanticField()

    var counter = Entity("counter", "Counter")
    counter.set("value", Value(1))
    field.add_entity(counter)

    field.add_non_negative_constraint(
        NonNegativeConstraint("counter", "value")
    )

    var executor = Executor(field)

    with assert_raises(contains="constraint violation"):
        executor.execute(
            Transformation(INCREMENT, "counter", "value", -5)
        )

    assert_equal(len(executor.state.observations), 0)
    assert_equal(len(executor.state.trace), 0)


def test_determinism() raises:
    var field_a = SemanticField()
    var field_b = SemanticField()

    var a = Entity("counter", "Counter")
    a.set("value", Value(0))
    field_a.add_entity(a)

    var b = Entity("counter", "Counter")
    b.set("value", Value(0))
    field_b.add_entity(b)

    var executor_a = Executor(field_a)
    var executor_b = Executor(field_b)

    executor_a.execute(
        Transformation(INCREMENT, "counter", "value", 1)
    )
    executor_a.execute(
        Transformation(INCREMENT, "counter", "value", 2)
    )

    executor_b.execute(
        Transformation(INCREMENT, "counter", "value", 1)
    )
    executor_b.execute(
        Transformation(INCREMENT, "counter", "value", 2)
    )

    assert_equal(
        executor_a.field.get_int("counter", "value"),
        executor_b.field.get_int("counter", "value"),
    )
    assert_equal(
        executor_a.state.logical_step,
        executor_b.state.logical_step,
    )
    assert_equal(
        len(executor_a.state.trace),
        len(executor_b.state.trace),
    )


def test_semantic_value_round_trip() raises:
    var field = SemanticField()

    var message = Entity("message", "Message")
    message.set("text", Value("semantic"))
    field.add_entity(message)

    var executor = Executor(field)

    executor.execute(
        Transformation(EMIT, "message", "text")
    )

    var observed = executor.state.observations[0].value.copy()

    assert_equal(value_string(observed), "semantic")
    assert_true(observed.isa[String]())


def test_unknown_operation_is_rejected() raises:
    var field = SemanticField()

    var entity = Entity("x", "Thing")
    entity.set("value", Value(1))
    field.add_entity(entity)

    var executor = Executor(field)

    with assert_raises(contains="unknown semantic transformation"):
        executor.execute(
            Transformation(999, "x", "value")
        )


def test_missing_entity_is_rejected() raises:
    var field = SemanticField()
    var executor = Executor(field)

    with assert_raises(contains="semantic entity not found"):
        executor.execute(
            Transformation(INCREMENT, "missing", "value", 1)
        )


def test_missing_property_is_rejected() raises:
    var field = SemanticField()

    var entity = Entity("x", "Thing")
    field.add_entity(entity)

    var executor = Executor(field)

    with assert_raises(contains="semantic property not found"):
        executor.execute(
            Transformation(INCREMENT, "x", "missing", 1)
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
