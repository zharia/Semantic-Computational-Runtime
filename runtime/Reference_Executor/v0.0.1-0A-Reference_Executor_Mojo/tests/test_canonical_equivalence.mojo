"""Canonical Semantic Equivalence Test.

Demonstrates that the canonical Counter program produces
identical semantic results on both the Reference Executor
and the Mojo Semantic Kernel.

This is the critical milestone artifact:
  Canonical Semantic Program
    → Reference Executor → Semantic State A
    → Mojo Kernel → Semantic State B
    → Semantic Equality
"""

from std.testing import TestSuite, assert_equal, assert_true

# Reference Executor imports
from scr_reference.entity import Entity as RE_Entity
from scr_reference.entity_definition import EntityDefinition as RE_Defn
from scr_reference.execution import (
    EMIT as RE_EMIT,
    INCREMENT as RE_INCREMENT,
    Executor as RE_Executor,
    Transformation as RE_Transformation,
)
from scr_reference.field import SemanticField as RE_Field
from scr_reference.constraint import NonNegativeConstraint as RE_Constraint
from scr_reference.context import SemanticContext as RE_Context
from scr_reference.value import Value as RE_Value, value_int as re_value_int

# Semantic Kernel imports
from scr_kernel.entity import Entity as SK_Entity
from scr_kernel.entity_definition import EntityDefinition as SK_Defn
from scr_kernel.field import SemanticField as SK_Field
from scr_kernel.transformation import INCREMENT as SK_INCREMENT, EMIT as SK_EMIT, Transformation as SK_Transformation
from scr_kernel.constraint import NonNegativeConstraint as SK_Constraint
from scr_kernel.context import SemanticContext as SK_Context
from scr_kernel.value import Value as SK_Value, value_int as sk_value_int


# ---------------------------------------------------------------
# Canonical program builders
# ---------------------------------------------------------------

def _build_re_executor() raises -> RE_Executor:
    """Build canonical program on Reference Executor."""
    var defn = RE_Defn("Counter")
    defn.add_property("value")

    var inst = RE_Entity("c1", "Counter")
    inst.set("value", RE_Value(0))

    var field = RE_Field()
    field.add_definition(defn)

    field.add_entity(inst)

    field.add_non_negative_constraint(RE_Constraint("c1", "value"))
    field.set_context(RE_Context(0, "golden-path"))

    return RE_Executor(field)


def _build_sk_executor() raises -> SK_Field:
    """Build canonical program on Mojo Semantic Kernel."""
    var defn = SK_Defn("Counter")
    defn.add_property("value")

    var inst = SK_Entity("c1", "Counter")
    inst.set("value", SK_Value(0))

    var field = SK_Field()
    field.add_definition(defn^)

    field.add_entity(inst)

    field.add_constraint(SK_Constraint("c1", "value"))
    field.set_context(SK_Context(0, "golden-path"))

    return field^


# ---------------------------------------------------------------
# Equivalence Tests
# ---------------------------------------------------------------

def test_canonical_equivalence_increment() raises:
    """Increment produces same result on RE and SK."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 5))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 5))

    assert_equal(re.field.get_int("c1", "value"), sk.get_int("c1", "value"))
    assert_equal(re.field.get_int("c1", "value"), 5)


def test_canonical_equivalence_multi_step() raises:
    """Multi-step transformation produces same result."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    # +5, +3, +2
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 5))
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 3))
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 2))

    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 5))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 3))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 2))

    assert_equal(re.field.get_int("c1", "value"), sk.get_int("c1", "value"))
    assert_equal(re.field.get_int("c1", "value"), 10)


def test_canonical_equivalence_observation() raises:
    """Observation reads same value on both implementations."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 5))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 5))

    re.execute(RE_Transformation(RE_EMIT, "c1", "value"))
    sk.execute(SK_Transformation(SK_EMIT, "c1", "value"))

    var re_obs_raw = re.state.observations[0].value.copy()
    var re_obs = re_value_int(re_obs_raw)
    var sk_obs_raw = sk.observations[0].value.copy()
    var sk_obs = sk_value_int(sk_obs_raw)

    assert_equal(re_obs, sk_obs)
    assert_equal(re_obs, 5)


def test_canonical_equivalence_constraint() raises:
    """Constraint violation behaves identically."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    # Both start at 0, increment by 3 → value=3
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 3))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 3))

    assert_equal(re.field.get_int("c1", "value"), sk.get_int("c1", "value"))

    # Both attempt to violate constraint: would go to -7
    # RE should raise, SK should raise
    var re_failed = False
    var sk_failed = False

    try:
        re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", -10))
    except:
        re_failed = True

    try:
        sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", -10))
    except:
        sk_failed = True

    assert_true(re_failed)
    assert_true(sk_failed)

    # Both remain at 3
    assert_equal(re.field.get_int("c1", "value"), sk.get_int("c1", "value"))
    assert_equal(re.field.get_int("c1", "value"), 3)


def test_canonical_equivalence_determinism() raises:
    """Same sequence produces same result on both."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    # Sequence: +1, +2, +3, +4
    for i in range(1, 5):
        re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", i))
        sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", i))

    assert_equal(re.field.get_int("c1", "value"), sk.get_int("c1", "value"))
    assert_equal(re.field.get_int("c1", "value"), 10)


def test_canonical_equivalence_time_advance() raises:
    """Logical step advances identically on both."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 1))
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 2))

    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 1))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 2))

    assert_equal(re.state.logical_step, sk.state.logical_step)
    assert_equal(re.state.logical_step, 2)


def test_canonical_equivalence_context() raises:
    """Context advances identically on both."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 1))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 1))

    assert_equal(re.state.logical_step, sk.state.logical_step)


def test_canonical_equivalence_full_pipeline() raises:
    """Complete pipeline: define → transform → observe → compare."""
    var re = _build_re_executor()
    var sk = _build_sk_executor()

    # Transform
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 5))
    re.execute(RE_Transformation(RE_INCREMENT, "c1", "value", 3))

    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 5))
    sk.execute(SK_Transformation(SK_INCREMENT, "c1", "value", 3))

    # Observe
    re.execute(RE_Transformation(RE_EMIT, "c1", "value"))
    sk.execute(SK_Transformation(SK_EMIT, "c1", "value"))

    # Compare all semantic state
    assert_equal(re.field.get_int("c1", "value"), sk.get_int("c1", "value"))
    assert_equal(re.state.logical_step, sk.state.logical_step)
    assert_equal(len(re.state.observations), len(sk.observations))

    var re_obs_raw = re.state.observations[0].value.copy()
    var re_obs = re_value_int(re_obs_raw)
    var sk_obs_raw = sk.observations[0].value.copy()
    var sk_obs = sk_value_int(sk_obs_raw)
    assert_equal(re_obs, sk_obs)
    assert_equal(re_obs, 8)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
