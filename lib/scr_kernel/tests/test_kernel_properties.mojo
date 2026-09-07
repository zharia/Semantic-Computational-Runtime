from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from scr_kernel.entity import Entity
from scr_kernel.field import SemanticField
from scr_kernel.transformation import INCREMENT, EMIT, SET_INT, Transformation
from scr_kernel.value import Value, value_int, value_string
from scr_kernel.constraint import NonNegativeConstraint
from scr_kernel.relationship import Relationship


def test_identity_persistence() raises:
    """Entity identity persists across property mutations."""
    var field = SemanticField()
    var e = Entity("e1", "Thing")
    e.set("x", Value(10))
    field.add_entity(e)

    field.execute(Transformation(INCREMENT, "e1", "x", 5))

    var result = field.get_entity("e1")
    assert_equal(result.id, "e1")
    assert_equal(result.kind, "Thing")


def test_duplicate_identity_rejection() raises:
    """Duplicate entity identity is rejected."""
    var field = SemanticField()
    field.add_entity(Entity("e1", "Thing"))

    with assert_raises(contains="semantic identity already exists"):
        field.add_entity(Entity("e1", "Other"))


def test_relationship_endpoints_must_exist() raises:
    """Relationship with missing endpoint is rejected."""
    var field = SemanticField()
    field.add_entity(Entity("a", "Thing"))

    with assert_raises(contains="relationship target does not exist"):
        field.add_relationship(Relationship("r1", "LINKS", "a", "missing"))


def test_state_validity() raises:
    """Valid state construction produces inspectable entities."""
    var field = SemanticField()
    field.add_entity(Entity("x", "Thing"))
    var result = field.get_entity("x")
    assert_equal(result.id, "x")


def test_invalid_entity_rejection() raises:
    """Missing entity is rejected."""
    var field = SemanticField()
    with assert_raises(contains="semantic entity not found"):
        field.get_entity("missing")


def test_transformation_changes_state() raises:
    """Valid transformation changes state according to contract."""
    var field = SemanticField()
    var e = Entity("c", "Counter")
    e.set("v", Value(0))
    field.add_entity(e)

    field.execute(Transformation(INCREMENT, "c", "v", 7))

    assert_equal(field.get_int("c", "v"), 7)


def test_failed_transformation_no_partial_mutation() raises:
    """Failed transformation does not partially mutate authoritative state."""
    var field = SemanticField()
    var e = Entity("c", "Counter")
    e.set("v", Value(1))
    field.add_entity(e)
    field.add_constraint(NonNegativeConstraint("c", "v"))

    with assert_raises(contains="constraint violation"):
        field.execute(Transformation(INCREMENT, "c", "v", -5))

    # State unchanged
    assert_equal(field.get_int("c", "v"), 1)


def test_constraint_preservation() raises:
    """Valid transformation preserves constraints."""
    var field = SemanticField()
    var e = Entity("c", "Counter")
    e.set("v", Value(5))
    field.add_entity(e)
    field.add_constraint(NonNegativeConstraint("c", "v"))

    field.execute(Transformation(INCREMENT, "c", "v", 3))

    assert_equal(field.get_int("c", "v"), 8)


def test_observation_no_time_advance() raises:
    """Observation does not advance semantic time."""
    var field = SemanticField()
    var e = Entity("x", "Thing")
    e.set("v", Value(42))
    field.add_entity(e)

    field.execute(Transformation(EMIT, "x", "v"))

    assert_equal(field.state.logical_step, 0)
    assert_equal(len(field.observations), 1)


def test_observation_preserves_state() raises:
    """Observation does not mutate authoritative state."""
    var field = SemanticField()
    var e = Entity("x", "Thing")
    e.set("v", Value(42))
    field.add_entity(e)

    field.execute(Transformation(EMIT, "x", "v"))
    field.execute(Transformation(EMIT, "x", "v"))

    # State unchanged
    assert_equal(field.get_int("x", "v"), 42)
    assert_equal(field.state.logical_step, 0)
    assert_equal(len(field.observations), 2)


def test_determinism() raises:
    """Same inputs produce same outputs."""
    var field_a = SemanticField()
    var a = Entity("c", "Counter")
    a.set("v", Value(0))
    field_a.add_entity(a)

    var field_b = SemanticField()
    var b = Entity("c", "Counter")
    b.set("v", Value(0))
    field_b.add_entity(b)

    field_a.execute(Transformation(INCREMENT, "c", "v", 1))
    field_a.execute(Transformation(INCREMENT, "c", "v", 2))

    field_b.execute(Transformation(INCREMENT, "c", "v", 1))
    field_b.execute(Transformation(INCREMENT, "c", "v", 2))

    assert_equal(field_a.get_int("c", "v"), field_b.get_int("c", "v"))
    assert_equal(field_a.state.logical_step, field_b.state.logical_step)


def test_unknown_operation_rejection() raises:
    """Unknown operation is rejected."""
    var field = SemanticField()
    var e = Entity("x", "Thing")
    e.set("v", Value(1))
    field.add_entity(e)

    with assert_raises(contains="unknown semantic transformation"):
        field.execute(Transformation(999, "x", "v"))


def test_semantic_value_round_trip() raises:
    """Semantic value round-trips through observation."""
    var field = SemanticField()
    var e = Entity("msg", "Message")
    e.set("text", Value("semantic"))
    field.add_entity(e)

    field.execute(Transformation(EMIT, "msg", "text"))

    var observed = field.observations[0].value.copy()
    assert_equal(value_string(observed), "semantic")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
