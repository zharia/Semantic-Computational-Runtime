"""Multiple-Entity and Relationship Witnesses.

Demonstrates that multiple entities can coexist in a SemanticField
with independent identities, independent state, shared time,
and explicit relationships.
"""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from std.collections import List

from scr_kernel.entity import Entity
from scr_kernel.entity_definition import EntityDefinition
from scr_kernel.entity_instance import EntityInstance
from scr_kernel.field import SemanticField
from scr_kernel.transformation import INCREMENT, EMIT, SET_INT, Transformation
from scr_kernel.value import Value, value_int
from scr_kernel.constraint import NonNegativeConstraint
from scr_kernel.context import SemanticContext
from scr_kernel.relationship import Relationship


# ---------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------

def _build_counter_definition() -> EntityDefinition:
    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    return defn^


def _setup_two_counters() raises -> SemanticField:
    """Shared setup: two counters c1=5, c2=10."""
    var field = SemanticField()
    var defn = _build_counter_definition()
    field.add_definition(defn)

    var c1 = Entity("c1", "Counter")
    c1.set("value", Value(5))
    field.add_entity(c1)

    var c2 = Entity("c2", "Counter")
    c2.set("value", Value(10))
    field.add_entity(c2)

    return field^


# ---------------------------------------------------------------
# Multiple-Entity Tests
# ---------------------------------------------------------------

def test_multi_entity_independent_state() raises:
    """Transforming c1 does not affect c2."""
    var field = _setup_two_counters()

    field.execute(Transformation(INCREMENT, "c1", "value", 3))

    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.get_int("c2", "value"), 10)  # unchanged


def test_multi_entity_transform_c2() raises:
    """Transforming c2 does not affect c1."""
    var field = _setup_two_counters()

    field.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(field.get_int("c1", "value"), 5)  # unchanged
    assert_equal(field.get_int("c2", "value"), 8)


def test_multi_entity_sequential_transforms() raises:
    """Transform c1 then c2, both reach target values."""
    var field = _setup_two_counters()

    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    field.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.get_int("c2", "value"), 8)


def test_multi_entity_shared_time() raises:
    """Both entities share logical time."""
    var field = _setup_two_counters()

    field.execute(Transformation(INCREMENT, "c1", "value", 1))
    field.execute(Transformation(INCREMENT, "c2", "value", 1))

    assert_equal(field.state.logical_step, 2)


def test_multi_entity_independent_identities() raises:
    """Each entity has unique identity."""
    var field = _setup_two_counters()

    var e1 = field.get_entity("c1")
    var e2 = field.get_entity("c2")
    assert_equal(e1.id, "c1")
    assert_equal(e2.id, "c2")
    assert_true(e1.id != e2.id)


def test_multi_entity_shared_constraints() raises:
    """Constraint applies to both entities independently."""
    var field = SemanticField()
    var defn = _build_counter_definition()
    field.add_definition(defn)

    var c1 = Entity("c1", "Counter")
    c1.set("value", Value(5))
    field.add_entity(c1)

    var c2 = Entity("c2", "Counter")
    c2.set("value", Value(10))
    field.add_entity(c2)

    field.add_constraint(NonNegativeConstraint("c1", "value"))
    field.add_constraint(NonNegativeConstraint("c2", "value"))

    # Both valid increments
    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    field.execute(Transformation(INCREMENT, "c2", "value", -5))

    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.get_int("c2", "value"), 5)


def test_multi_entity_constraint_blocks_one() raises:
    """Constraint blocks one entity but not the other."""
    var field = SemanticField()
    var defn = _build_counter_definition()
    field.add_definition(defn)

    var c1 = Entity("c1", "Counter")
    c1.set("value", Value(5))
    field.add_entity(c1)

    var c2 = Entity("c2", "Counter")
    c2.set("value", Value(2))
    field.add_entity(c2)

    field.add_constraint(NonNegativeConstraint("c1", "value"))
    field.add_constraint(NonNegativeConstraint("c2", "value"))

    # c1 valid
    field.execute(Transformation(INCREMENT, "c1", "value", 3))

    # c2 would go to -3, blocked
    with assert_raises(contains="constraint violation"):
        field.execute(Transformation(INCREMENT, "c2", "value", -5))

    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.get_int("c2", "value"), 2)  # unchanged


def test_multi_entity_observations() raises:
    """Observations from different entities are independent."""
    var field = _setup_two_counters()

    field.execute(Transformation(EMIT, "c1", "value"))
    field.execute(Transformation(EMIT, "c2", "value"))

    assert_equal(len(field.observations), 2)
    assert_equal(value_int(field.observations[0].value), 5)
    assert_equal(value_int(field.observations[1].value), 10)


def test_multi_entity_determinism() raises:
    """Same operations on two fields produce same result."""
    var field_a = _setup_two_counters()
    var field_b = _setup_two_counters()

    field_a.execute(Transformation(INCREMENT, "c1", "value", 3))
    field_a.execute(Transformation(INCREMENT, "c2", "value", -2))

    field_b.execute(Transformation(INCREMENT, "c1", "value", 3))
    field_b.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(field_a.get_int("c1", "value"), field_b.get_int("c1", "value"))
    assert_equal(field_a.get_int("c2", "value"), field_b.get_int("c2", "value"))
    assert_equal(field_a.state.logical_step, field_b.state.logical_step)


# ---------------------------------------------------------------
# Relationship Tests
# ---------------------------------------------------------------

def test_relationship_semantics() raises:
    """Relationship between entities is semantically represented."""
    var field = _setup_two_counters()

    field.add_relationship(Relationship("r1", "LINKS", "c1", "c2"))

    assert_equal(len(field.state.relationships), 1)
    var rel = field.state.relationships["r1"].copy()
    assert_equal(rel.source, "c1")
    assert_equal(rel.target, "c2")
    assert_equal(rel.kind, "LINKS")


def test_relationship_endpoint_validation() raises:
    """Relationship with missing endpoint is rejected."""
    var field = SemanticField()
    var c1 = Entity("c1", "Counter")
    c1.set("value", Value(5))
    field.add_entity(c1)

    with assert_raises(contains="relationship target does not exist"):
        field.add_relationship(Relationship("r1", "LINKS", "c1", "missing"))


def test_relationship_source_validation() raises:
    """Relationship with missing source is rejected."""
    var field = SemanticField()
    var c2 = Entity("c2", "Counter")
    c2.set("value", Value(10))
    field.add_entity(c2)

    with assert_raises(contains="relationship source does not exist"):
        field.add_relationship(Relationship("r1", "LINKS", "missing", "c2"))


def test_relationship_independence() raises:
    """Relationship does not affect entity state."""
    var field = _setup_two_counters()
    field.add_relationship(Relationship("r1", "LINKS", "c1", "c2"))

    field.execute(Transformation(INCREMENT, "c1", "value", 3))

    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.get_int("c2", "value"), 10)
    assert_equal(len(field.state.relationships), 1)


def test_multiple_relationships() raises:
    """Multiple relationships can coexist."""
    var field = _setup_two_counters()

    field.add_relationship(Relationship("r1", "LINKS", "c1", "c2"))
    field.add_relationship(Relationship("r2", "DEPENDS", "c2", "c1"))

    assert_equal(len(field.state.relationships), 2)

    var rel1 = field.state.relationships["r1"].copy()
    assert_equal(rel1.kind, "LINKS")

    var rel2 = field.state.relationships["r2"].copy()
    assert_equal(rel2.kind, "DEPENDS")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
