"""Formal Semantic Conformance Probe Suite (STC-002 / RE Milestone).

Executes the exact 12 ground-truth conformance cases specified and machine-checked
in Lean (`SCRFormal/SCR/REConformance.lean`).
"""

from std.testing import (
    TestSuite,
    assert_equal,
    assert_raises,
    assert_true,
)

from scr_reference.constraint import NonNegativeConstraint
from scr_reference.context import SemanticContext
from scr_reference.entity import Entity
from scr_reference.execution import (
    EMIT,
    INCREMENT,
    SET_INT,
    Executor,
    Transformation,
)
from scr_reference.field import SemanticField
from scr_reference.value import Value, value_int


def _make_field(c1_val: Int, c2_val: Int) raises -> SemanticField:
    var field = SemanticField()

    var e1 = Entity("c1", "Counter")
    e1.set("value", Value(c1_val))
    field.add_entity(e1)

    var e2 = Entity("c2", "Counter")
    e2.set("value", Value(c2_val))
    field.add_entity(e2)

    field.add_non_negative_constraint(NonNegativeConstraint("c1", "value"))
    field.add_non_negative_constraint(NonNegativeConstraint("c2", "value"))

    var ctx = SemanticContext(0, "formal-conformance")
    field.set_context(ctx)

    return field^


# Case 1: Canonical increment on counter 1
def test_case1_inc1_positive() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    executor.execute(Transformation(INCREMENT, "c1", "value", 3))

    assert_equal(executor.field.get_int("c1", "value"), 8)
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 1)
    assert_equal(len(executor.state.observations), 0)
    assert_equal(len(executor.state.trace), 1)


# Case 2: Decrement on counter 2 preserving non-negativity
def test_case2_inc2_negative_valid() raises:
    var field = _make_field(8, 10)
    var executor = Executor(field)
    executor.state.logical_step = 1

    executor.execute(Transformation(INCREMENT, "c2", "value", -2))

    assert_equal(executor.field.get_int("c1", "value"), 8)
    assert_equal(executor.field.get_int("c2", "value"), 8)
    assert_equal(executor.state.logical_step, 2)
    assert_equal(len(executor.state.observations), 0)


# Case 3: Decrement violating non-negativity rolls back
def test_case3_inc1_negative_invalid() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    with assert_raises(contains="constraint violation"):
        executor.execute(Transformation(INCREMENT, "c1", "value", -10))

    # Transactional rollback verification
    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 0)
    assert_equal(len(executor.state.trace), 0)


# Case 4: Set valid value
def test_case4_set1_valid() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    executor.execute(Transformation(SET_INT, "c1", "value", 7))

    assert_equal(executor.field.get_int("c1", "value"), 7)
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 1)


# Case 5: Set negative value rolls back
def test_case5_set1_invalid() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    with assert_raises(contains="constraint violation"):
        executor.execute(Transformation(SET_INT, "c1", "value", -1))

    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 0)


# Case 6: Emit counter 1 preserves values and records observation
def test_case6_emit1() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    executor.execute(Transformation(EMIT, "c1", "value"))

    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 10)
    assert_equal(executor.state.logical_step, 0)
    assert_equal(len(executor.state.observations), 1)
    var obs = executor.state.observations[0].value.copy()
    assert_equal(value_int(obs), 5)


# Case 7: Full canonical program execution (inc1 5, inc2 3, emit1, emit2)
def test_case7_canonical_program() raises:
    var field = _make_field(0, 0)
    var executor = Executor(field)

    executor.execute(Transformation(INCREMENT, "c1", "value", 5))
    executor.execute(Transformation(INCREMENT, "c2", "value", 3))
    executor.execute(Transformation(EMIT, "c1", "value"))
    executor.execute(Transformation(EMIT, "c2", "value"))

    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 3)
    assert_equal(executor.state.logical_step, 2)
    assert_equal(len(executor.state.observations), 2)
    var obs1 = executor.state.observations[0].value.copy()
    var obs2 = executor.state.observations[1].value.copy()
    assert_equal(value_int(obs1), 5)
    assert_equal(value_int(obs2), 3)


# Case 8: Program aborts on constraint violation at step 2 with state preserved
def test_case8_program_fail_stop() raises:
    var field = _make_field(0, 0)
    var executor = Executor(field)

    executor.execute(Transformation(INCREMENT, "c1", "value", 5))
    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.state.logical_step, 1)

    with assert_raises(contains="constraint violation"):
        executor.execute(Transformation(INCREMENT, "c1", "value", -10))

    # State halted at step 1
    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 0)
    assert_equal(executor.state.logical_step, 1)
    assert_equal(len(executor.state.observations), 0)


# Case 9: Unknown transformation rejected cleanly
def test_case9_unknown_op() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    with assert_raises(contains="unknown semantic transformation"):
        executor.execute(Transformation(999, "c1", "value", 0))

    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.state.logical_step, 0)


# Case 10: Emit initial state then increment
def test_case10_emit_before_inc() raises:
    var field = _make_field(0, 0)
    var executor = Executor(field)

    executor.execute(Transformation(EMIT, "c2", "value"))
    executor.execute(Transformation(INCREMENT, "c2", "value", 5))

    assert_equal(executor.field.get_int("c1", "value"), 0)
    assert_equal(executor.field.get_int("c2", "value"), 5)
    assert_equal(executor.state.logical_step, 1)
    assert_equal(len(executor.state.observations), 1)
    var obs = executor.state.observations[0].value.copy()
    assert_equal(value_int(obs), 0)


# Case 11: Set to boundary zero succeeds
def test_case11_set2_zero_boundary() raises:
    var field = _make_field(5, 10)
    var executor = Executor(field)

    executor.execute(Transformation(SET_INT, "c2", "value", 0))

    assert_equal(executor.field.get_int("c1", "value"), 5)
    assert_equal(executor.field.get_int("c2", "value"), 0)
    assert_equal(executor.state.logical_step, 1)


# Case 12: Sequential increment chain
def test_case12_sequential_inc_chain() raises:
    var field = _make_field(0, 0)
    var executor = Executor(field)

    executor.execute(Transformation(INCREMENT, "c1", "value", 1))
    executor.execute(Transformation(INCREMENT, "c1", "value", 2))
    executor.execute(Transformation(INCREMENT, "c1", "value", 3))

    assert_equal(executor.field.get_int("c1", "value"), 6)
    assert_equal(executor.field.get_int("c2", "value"), 0)
    assert_equal(executor.state.logical_step, 3)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
