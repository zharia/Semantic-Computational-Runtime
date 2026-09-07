from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from scr_kernel.entity import Entity
from scr_kernel.field import SemanticField
from scr_kernel.transformation import INCREMENT, EMIT, SET_INT, Transformation
from scr_kernel.value import Value, value_int, value_string
from scr_kernel.constraint import NonNegativeConstraint
from scr_kernel.relationship import Relationship
from scr_kernel.context import SemanticContext
from scr_kernel.entity_definition import EntityDefinition
from scr_kernel.entity_instance import EntityInstance


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


def test_entity_definition_valid() raises:
    var defn = SemanticField()
    from scr_kernel.entity_definition import EntityDefinition
    var counter_defn = EntityDefinition("Counter")
    counter_defn.add_property("value")
    defn.add_definition(counter_defn)
    assert_true("Counter" in defn.definitions)


def test_entity_instance_conforms_to_definition() raises:
    from scr_kernel.entity_definition import EntityDefinition
    from scr_kernel.entity_instance import EntityInstance

    var defn = EntityDefinition("Counter")
    defn.add_property("value")

    var inst = EntityInstance("c1", "Counter")
    inst.set("value", Value(10))

    assert_true(inst.conforms(defn))


def test_entity_instance_rejects_nonconformance() raises:
    from scr_kernel.entity_definition import EntityDefinition
    from scr_kernel.entity_instance import EntityInstance

    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    defn.add_property("label")

    var inst = EntityInstance("c1", "Counter")
    inst.set("value", Value(10))

    assert_true(not inst.conforms(defn))


def test_entity_instance_identity_independent() raises:
    from scr_kernel.entity_instance import EntityInstance

    var inst1 = EntityInstance("e1", "Thing")
    var inst2 = EntityInstance("e2", "Thing")

    assert_equal(inst1.definition_type, inst2.definition_type)
    assert_true(inst1.identity.entity_id != inst2.identity.entity_id)


def test_entity_definition_has_property() raises:
    from scr_kernel.entity_definition import EntityDefinition

    var defn = EntityDefinition("Person")
    defn.add_property("name")
    defn.add_property("age")

    assert_true(defn.has_property("name"))
    assert_true(defn.has_property("age"))
    assert_true(not defn.has_property("email"))


def test_context_propagates_through_transformations() raises:
    var field = SemanticField()
    var e = Entity("c", "Counter")
    e.set("v", Value(0))
    field.add_entity(e)

    var ctx = SemanticContext(0, "test")
    field.set_context(ctx)

    field.execute(Transformation(INCREMENT, "c", "v", 1))

    assert_equal(field.context.logical_step, 1)
    assert_equal(field.state.logical_step, 1)


def test_observation_does_not_change_state() raises:
    var field = SemanticField()
    var e = Entity("x", "Thing")
    e.set("v", Value(42))
    field.add_entity(e)

    var before = field.get_int("x", "v")
    field.execute(Transformation(EMIT, "x", "v"))
    var after = field.get_int("x", "v")

    assert_equal(before, after)
    assert_equal(len(field.observations), 1)
    assert_equal(field.state.logical_step, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
