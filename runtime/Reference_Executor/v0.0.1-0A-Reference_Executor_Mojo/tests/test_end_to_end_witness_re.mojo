"""End-to-End Witness with Constraint Failure — Reference Executor.

Mirrors the kernel end-to-end witness exactly:
  CounterDefinition → Counter c1,c2 → Constraints → Relationship
  → Transform (+3 success) → Transform (-12 constraint failure)
  → Transform (-2 success) → Observe → Verify
"""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from scr_reference.entity import Entity
from scr_reference.entity_definition import EntityDefinition
from scr_reference.entity_instance import EntityInstance
from scr_reference.execution import (
    EMIT,
    INCREMENT,
    SET_INT,
    Executor,
    Transformation,
)
from scr_reference.field import SemanticField
from scr_reference.constraint import NonNegativeConstraint
from scr_reference.context import SemanticContext
from scr_reference.value import Value, value_int
from scr_reference.relationship import Relationship


# ---------------------------------------------------------------
# Canonical End-to-End Witness (RE mirror)
# ---------------------------------------------------------------

def _build_counter_definition() -> EntityDefinition:
    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    return defn^


def _setup_witness_executor() raises -> Executor:
    """Full witness setup wrapped in Executor."""
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

    # Constraints
    field.add_non_negative_constraint(NonNegativeConstraint("c1", "value"))
    field.add_non_negative_constraint(NonNegativeConstraint("c2", "value"))

    # Relationship: r1 LINKS c1 → c2
    field.add_relationship(Relationship("r1", "LINKS", "c1", "c2"))

    # Context
    var ctx = SemanticContext(0, "end-to-end-witness")
    field.set_context(ctx)

    return Executor(field)


# ---------------------------------------------------------------
# Tests
# ---------------------------------------------------------------

def test_witness_initial_state_re() raises:
    """Initial state matches the semantic program definition."""
    var executor = _setup_witness_executor()

    var e1 = executor.field.get_entity("c1")
    assert_equal(e1.id, "c1")
    assert_equal(e1.kind, "Counter")

    var e2 = executor.field.get_entity("c2")
    assert_equal(e2.id, "c2")
    assert_equal(e2.kind, "Counter")

    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 10)

    assert_equal(executor.state.logical_step, 0)
    assert_equal(executor.context.logical_step, 0)
    assert_equal(executor.context.label, "end-to-end-witness")

    assert_equal(executor.field.relationship_count(), 1)
    var rel = executor.field.get_relationship("r1")
    assert_equal(rel.source, "c1")
    assert_equal(rel.target, "c2")
    assert_equal(rel.relation, "LINKS")


def test_witness_constraint_blocks_negative_re() raises:
    """Constraint blocks transformation that would make value negative."""
    var executor = _setup_witness_executor()

    with assert_raises(contains="constraint violation"):
        executor.execute(Transformation(INCREMENT, "c2", "value", -12))

    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 0)


def test_witness_full_scenario_re() raises:
    """Full end-to-end scenario on RE: all 11 steps."""
    var executor = _setup_witness_executor()

    # Step 5: Transform c1: +3 → c1=8
    executor.execute(Transformation(INCREMENT, "c1", "value", 3))
    assert_equal(executor.field.get_int("c1", "value"), 8)
    assert_equal(executor.state.logical_step, 1)

    # Step 6: Transform c2: -12 → CONSTRAINT FAILURE
    var failed = False
    try:
        executor.execute(Transformation(INCREMENT, "c2", "value", -12))
    except:
        failed = True
    assert_true(failed)
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 1)

    # Step 7: Transform c2: -2 → c2=8
    executor.execute(Transformation(INCREMENT, "c2", "value", -2))
    assert_equal(executor.field.get_int("c2", "value"), 8)
    assert_equal(executor.state.logical_step, 2)

    # Step 8: Observe c1 → 8
    executor.execute(Transformation(EMIT, "c1", "value"))
    assert_equal(value_int(executor.state.observations[0].value), 8)
    assert_equal(executor.state.observations[0].entity_id, "c1")

    # Step 9: Observe c2 → 8
    executor.execute(Transformation(EMIT, "c2", "value"))
    assert_equal(value_int(executor.state.observations[1].value), 8)
    assert_equal(executor.state.observations[1].entity_id, "c2")

    # Step 10: Verify final state
    assert_equal(executor.field.get_int("c1", "value"), 8)
    assert_equal(executor.field.get_int("c2", "value"), 8)
    assert_equal(executor.state.logical_step, 2)
    assert_equal(executor.context.logical_step, 2)
    assert_equal(len(executor.state.observations), 2)


def test_witness_identity_preserved_re() raises:
    """Entity identity persists across all transformations on RE."""
    var executor = _setup_witness_executor()

    executor.execute(Transformation(INCREMENT, "c1", "value", 3))
    executor.execute(Transformation(INCREMENT, "c2", "value", -2))

    var e1 = executor.field.get_entity("c1")
    var e2 = executor.field.get_entity("c2")
    assert_equal(e1.id, "c1")
    assert_equal(e1.kind, "Counter")
    assert_equal(e2.id, "c2")
    assert_equal(e2.kind, "Counter")


def test_witness_constraint_failure_distinct_from_noop_re() raises:
    """Constraint failure is observably distinct from a no-op on RE."""
    var executor = _setup_witness_executor()

    var violated = False
    try:
        executor.execute(Transformation(INCREMENT, "c2", "value", -12))
    except:
        violated = True
    assert_true(violated)
    assert_equal(executor.state.logical_step, 0)

    # Successful no-op (set to same value): no raise, time advances
    executor.execute(Transformation(SET_INT, "c2", "value", 10))
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 1)


def test_witness_relationship_independent_re() raises:
    """Relationship persists independently of transformations on RE."""
    var executor = _setup_witness_executor()

    executor.execute(Transformation(INCREMENT, "c1", "value", 3))
    executor.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(executor.field.relationship_count(), 1)
    var rel = executor.field.get_relationship("r1")
    assert_equal(rel.source, "c1")
    assert_equal(rel.target, "c2")


def test_witness_observations_noninterfering_re() raises:
    """Observations do not advance time on RE."""
    var executor = _setup_witness_executor()

    executor.execute(Transformation(INCREMENT, "c1", "value", 3))
    executor.execute(Transformation(EMIT, "c1", "value"))
    executor.execute(Transformation(EMIT, "c1", "value"))

    assert_equal(executor.state.logical_step, 1)
    assert_equal(len(executor.state.observations), 2)
    assert_equal(executor.field.get_int("c1", "value"), 8)


def test_witness_determinism_re() raises:
    """Same scenario produces identical results on RE."""
    var exec_a = _setup_witness_executor()
    var exec_b = _setup_witness_executor()

    exec_a.execute(Transformation(INCREMENT, "c1", "value", 3))
    exec_a.execute(Transformation(INCREMENT, "c2", "value", -2))

    exec_b.execute(Transformation(INCREMENT, "c1", "value", 3))
    exec_b.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(exec_a.field.get_int("c1", "value"), exec_b.field.get_int("c1", "value"))
    assert_equal(exec_a.field.get_int("c2", "value"), exec_b.field.get_int("c2", "value"))
    assert_equal(exec_a.state.logical_step, exec_b.state.logical_step)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
