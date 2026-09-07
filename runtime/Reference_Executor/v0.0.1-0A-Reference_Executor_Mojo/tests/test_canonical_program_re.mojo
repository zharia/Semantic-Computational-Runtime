"""Canonical Semantic Entity Compilation Program — Reference Executor.

Mirrors the kernel canonical program exactly:
  CounterDefinition → CounterInstance → Transform → Observe
"""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from scr_reference.entity import Entity
from scr_reference.entity_definition import EntityDefinition
from scr_reference.entity_instance import EntityInstance
from scr_reference.execution import (
    EMIT,
    INCREMENT,
    Executor,
    Transformation,
)
from scr_reference.field import SemanticField
from scr_reference.constraint import NonNegativeConstraint
from scr_reference.context import SemanticContext
from scr_reference.value import Value, value_int


# ---------------------------------------------------------------
# Canonical Semantic Program (RE mirror)
# ---------------------------------------------------------------

def _build_counter_definition() -> EntityDefinition:
    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    return defn^


def _build_counter_instance(defn: EntityDefinition) raises -> EntityInstance:
    var inst = EntityInstance("c1", "Counter")
    inst.set("value", Value(0))
    assert_true(inst.conforms(defn))
    return inst^


def _build_counter_executor(defn: EntityDefinition, inst: EntityInstance) raises -> Executor:
    var field = SemanticField()
    field.add_definition(defn)

    var entity = Entity(inst.entity.id, inst.definition_type)
    entity.set("value", inst.get("value"))
    field.add_entity(entity)

    field.add_non_negative_constraint(
        NonNegativeConstraint(inst.entity.id, "value")
    )

    var ctx = SemanticContext(0, "golden-path")
    field.set_context(ctx)

    return Executor(field)


# ---------------------------------------------------------------
# Tests
# ---------------------------------------------------------------

def test_canonical_full_pipeline_re() raises:
    """Full canonical program on Reference Executor."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var executor = _build_counter_executor(defn, inst)

    # Initial state
    assert_equal(executor.field.get_int("c1", "value"), 0)
    assert_equal(executor.state.logical_step, 0)

    # Transform: increment by 5
    executor.execute(Transformation(INCREMENT, "c1", "value", 5))
    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.state.logical_step, 1)

    # Observe
    executor.execute(Transformation(EMIT, "c1", "value"))
    var observed = executor.state.observations[0].value.copy()
    assert_equal(value_int(observed), 5)
    assert_equal(len(executor.state.observations), 1)

    # State still intact
    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.state.logical_step, 1)


def test_canonical_constraint_re() raises:
    """Constraint blocks negative value on RE."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var executor = _build_counter_executor(defn, inst)

    executor.execute(Transformation(INCREMENT, "c1", "value", 3))
    assert_equal(executor.field.get_int("c1", "value"), 3)

    with assert_raises(contains="constraint violation"):
        executor.execute(Transformation(INCREMENT, "c1", "value", -10))

    assert_equal(executor.field.get_int("c1", "value"), 3)
    assert_equal(executor.state.logical_step, 1)


def test_canonical_determinism_re() raises:
    """Same program produces identical results on RE."""
    var defn_a = _build_counter_definition()
    var inst_a = _build_counter_instance(defn_a)
    var exec_a = _build_counter_executor(defn_a, inst_a)

    var defn_b = _build_counter_definition()
    var inst_b = _build_counter_instance(defn_b)
    var exec_b = _build_counter_executor(defn_b, inst_b)

    exec_a.execute(Transformation(INCREMENT, "c1", "value", 5))
    exec_a.execute(Transformation(INCREMENT, "c1", "value", 3))

    exec_b.execute(Transformation(INCREMENT, "c1", "value", 5))
    exec_b.execute(Transformation(INCREMENT, "c1", "value", 3))

    assert_equal(exec_a.field.get_int("c1", "value"), exec_b.field.get_int("c1", "value"))
    assert_equal(exec_a.state.logical_step, exec_b.state.logical_step)


def test_canonical_semantic_result_re() raises:
    """Complete pipeline produces correct semantic result on RE."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var executor = _build_counter_executor(defn, inst)

    executor.execute(Transformation(INCREMENT, "c1", "value", 5))
    executor.execute(Transformation(INCREMENT, "c1", "value", 3))
    executor.execute(Transformation(INCREMENT, "c1", "value", 2))

    executor.execute(Transformation(EMIT, "c1", "value"))
    var result = executor.state.observations[0].value.copy()
    assert_equal(value_int(result), 10)
    assert_equal(executor.field.get_int("c1", "value"), 10)
    assert_equal(executor.state.logical_step, 3)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
