"""End-to-End Witness with Constraint Failure.

Single canonical witness exercising the full semantic program:
  CounterDefinition → Counter c1,c2 → Constraints → Relationship
  → Transform (+3 success) → Transform (-12 constraint failure)
  → Transform (-2 success) → Observe → Verify

This is the milestone 005 Section 22 witness.
"""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true

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
# Canonical End-to-End Witness
# ---------------------------------------------------------------

def _build_counter_definition() -> EntityDefinition:
    """Counter has property 'value'."""
    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    return defn^


def _setup_witness() raises -> SemanticField:
    """Full witness setup: definition, two counters, constraints, relationship."""
    var field = SemanticField()
    var defn = _build_counter_definition()
    field.add_definition(defn)

    # Counter c1, initial value = 5
    var c1 = Entity("c1", "Counter")
    c1.set("value", Value(5))
    field.add_entity(c1)

    # Counter c2, initial value = 10
    var c2 = Entity("c2", "Counter")
    c2.set("value", Value(10))
    field.add_entity(c2)

    # Constraints: c1.value >= 0, c2.value >= 0
    field.add_constraint(NonNegativeConstraint("c1", "value"))
    field.add_constraint(NonNegativeConstraint("c2", "value"))

    # Relationship: r1 LINKS c1 → c2
    field.add_relationship(Relationship("r1", "LINKS", "c1", "c2"))

    # Context: initial step, label
    var ctx = SemanticContext(0, "end-to-end-witness")
    field.set_context(ctx)

    return field^


# ---------------------------------------------------------------
# Tests
# ---------------------------------------------------------------

def test_witness_initial_state() raises:
    """Initial state matches the semantic program definition."""
    var field = _setup_witness()

    # Entity identity
    var e1 = field.get_entity("c1")
    assert_equal(e1.id, "c1")
    assert_equal(e1.kind, "Counter")

    var e2 = field.get_entity("c2")
    assert_equal(e2.id, "c2")
    assert_equal(e2.kind, "Counter")

    # Initial values
    assert_equal(field.get_int("c1", "value"), 5)
    assert_equal(field.get_int("c2", "value"), 10)

    # Time at zero
    assert_equal(field.state.logical_step, 0)
    assert_equal(field.context.logical_step, 0)
    assert_equal(field.context.label, "end-to-end-witness")

    # Relationship stored
    assert_equal(len(field.state.relationships), 1)
    var rel = field.state.relationships["r1"].copy()
    assert_equal(rel.source, "c1")
    assert_equal(rel.target, "c2")
    assert_equal(rel.kind, "LINKS")


def test_witness_constraint_blocks_negative() raises:
    """Constraint blocks transformation that would make value negative."""
    var field = _setup_witness()

    # Transform c2: -12 would go to -2, CONSTRAINT FAILURE
    with assert_raises(contains="constraint violation"):
        field.execute(Transformation(INCREMENT, "c2", "value", -12))

    # c2 unchanged after failed transformation
    assert_equal(field.get_int("c2", "value"), 10)
    # Time not advanced
    assert_equal(field.state.logical_step, 0)


def test_witness_full_scenario() raises:
    """Full end-to-end scenario: all 11 steps."""
    var field = _setup_witness()

    # Step 1-4: Setup already done (definition, c1, c2, constraints, relationship)

    # Step 5: Transform c1: +3 → c1=8 (success)
    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.state.logical_step, 1)

    # Step 6: Transform c2: -12 → CONSTRAINT FAILURE → c2 unchanged
    var failed = False
    try:
        field.execute(Transformation(INCREMENT, "c2", "value", -12))
    except:
        failed = True
    assert_true(failed)
    assert_equal(field.get_int("c2", "value"), 10)
    assert_equal(field.state.logical_step, 1)

    # Step 7: Transform c2: -2 → c2=8 (success)
    field.execute(Transformation(INCREMENT, "c2", "value", -2))
    assert_equal(field.get_int("c2", "value"), 8)
    assert_equal(field.state.logical_step, 2)

    # Step 8: Observe c1 → 8
    field.execute(Transformation(EMIT, "c1", "value"))
    assert_equal(value_int(field.observations[0].value), 8)
    assert_equal(field.observations[0].entity_id, "c1")

    # Step 9: Observe c2 → 8
    field.execute(Transformation(EMIT, "c2", "value"))
    assert_equal(value_int(field.observations[1].value), 8)
    assert_equal(field.observations[1].entity_id, "c2")

    # Step 10: Verify final state
    assert_equal(field.get_int("c1", "value"), 8)
    assert_equal(field.get_int("c2", "value"), 8)
    # 2 successful transforms (time = 2)
    assert_equal(field.state.logical_step, 2)
    assert_equal(field.context.logical_step, 2)
    # 2 observations
    assert_equal(len(field.observations), 2)


def test_witness_identity_preserved() raises:
    """Entity identity persists across all transformations."""
    var field = _setup_witness()

    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    field.execute(Transformation(INCREMENT, "c2", "value", -2))

    var e1 = field.get_entity("c1")
    var e2 = field.get_entity("c2")
    assert_equal(e1.id, "c1")
    assert_equal(e1.kind, "Counter")
    assert_equal(e2.id, "c2")
    assert_equal(e2.kind, "Counter")


def test_witness_constraint_failure_distinct_from_noop() raises:
    """Constraint failure is observably distinct from a no-op."""
    var field = _setup_witness()

    # Constraint failure: raises, time unchanged
    var violated = False
    try:
        field.execute(Transformation(INCREMENT, "c2", "value", -12))
    except:
        violated = True
    assert_true(violated)
    assert_equal(field.state.logical_step, 0)

    # Successful no-op (set to same value): no raise, time advances
    field.execute(Transformation(SET_INT, "c2", "value", 10))
    assert_equal(field.get_int("c2", "value"), 10)
    assert_equal(field.state.logical_step, 1)


def test_witness_relationship_independent_of_transforms() raises:
    """Relationship persists independently of transformations."""
    var field = _setup_witness()

    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    field.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(len(field.state.relationships), 1)
    var rel = field.state.relationships["r1"].copy()
    assert_equal(rel.source, "c1")
    assert_equal(rel.target, "c2")


def test_witness_observations_noninterfering() raises:
    """Observations do not advance time or mutate state."""
    var field = _setup_witness()

    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    field.execute(Transformation(EMIT, "c1", "value"))
    field.execute(Transformation(EMIT, "c1", "value"))

    assert_equal(field.state.logical_step, 1)
    assert_equal(len(field.observations), 2)
    assert_equal(field.get_int("c1", "value"), 8)


def test_witness_determinism() raises:
    """Same scenario produces identical results."""
    var field_a = _setup_witness()
    var field_b = _setup_witness()

    field_a.execute(Transformation(INCREMENT, "c1", "value", 3))
    field_a.execute(Transformation(INCREMENT, "c2", "value", -2))

    field_b.execute(Transformation(INCREMENT, "c1", "value", 3))
    field_b.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(field_a.get_int("c1", "value"), field_b.get_int("c1", "value"))
    assert_equal(field_a.get_int("c2", "value"), field_b.get_int("c2", "value"))
    assert_equal(field_a.state.logical_step, field_b.state.logical_step)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
