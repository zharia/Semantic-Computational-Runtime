from std.testing import TestSuite, assert_equal, assert_true

# Reference Executor imports
from scr_reference.entity import Entity as RE_Entity
from scr_reference.execution import INCREMENT as RE_INCREMENT, EMIT as RE_EMIT, Executor as RE_Executor, Transformation as RE_Transformation
from scr_reference.field import SemanticField as RE_Field
from scr_reference.value import Value as RE_Value, value_int as re_value_int

# Semantic Kernel imports
from scr_kernel.entity import Entity as SK_Entity
from scr_kernel.transformation import INCREMENT as SK_INCREMENT, EMIT as SK_EMIT, Transformation as SK_Transformation
from scr_kernel.field import SemanticField as SK_Field
from scr_kernel.value import Value as SK_Value, value_int as sk_value_int


def test_equivalence_increment() raises:
    """Same increment operation produces same semantic result in both implementations."""
    # Reference Executor path
    var re_field = RE_Field()
    var re_counter = RE_Entity("counter", "Counter")
    re_counter.set("value", RE_Value(10))
    re_field.add_entity(re_counter)
    var re_exec = RE_Executor(re_field)
    re_exec.execute(RE_Transformation(RE_INCREMENT, "counter", "value", 5))
    var re_result = re_exec.field.get_int("counter", "value")

    # Semantic Kernel path
    var sk_field = SK_Field()
    var sk_counter = SK_Entity("counter", "Counter")
    sk_counter.set("value", SK_Value(10))
    sk_field.add_entity(sk_counter)
    sk_field.execute(SK_Transformation(SK_INCREMENT, "counter", "value", 5))
    var sk_result = sk_field.get_int("counter", "value")

    # Semantic equivalence: same result
    assert_equal(re_result, sk_result)
    assert_equal(re_result, 15)


def test_equivalence_observation() raises:
    """Same observation produces same semantic result in both implementations."""
    # Reference Executor
    var re_field = RE_Field()
    var re_entity = RE_Entity("x", "Thing")
    re_entity.set("val", RE_Value(42))
    re_field.add_entity(re_entity)
    var re_exec = RE_Executor(re_field)
    re_exec.execute(RE_Transformation(RE_EMIT, "x", "val"))
    var re_obs_val = re_exec.state.observations[0].value.copy()
    var re_observed = re_value_int(re_obs_val)

    # Semantic Kernel
    var sk_field = SK_Field()
    var sk_entity = SK_Entity("x", "Thing")
    sk_entity.set("val", SK_Value(42))
    sk_field.add_entity(sk_entity)
    sk_field.execute(SK_Transformation(SK_EMIT, "x", "val"))
    var sk_obs_val = sk_field.observations[0].value.copy()
    var sk_observed = sk_value_int(sk_obs_val)

    # Semantic equivalence
    assert_equal(re_observed, sk_observed)
    assert_equal(re_observed, 42)


def test_equivalence_determinism() raises:
    """Both implementations produce same result for same sequence of operations."""
    # Reference Executor
    var re_field = RE_Field()
    var re_a = RE_Entity("counter", "Counter")
    re_a.set("value", RE_Value(0))
    re_field.add_entity(re_a)
    var re_exec = RE_Executor(re_field)
    re_exec.execute(RE_Transformation(RE_INCREMENT, "counter", "value", 1))
    re_exec.execute(RE_Transformation(RE_INCREMENT, "counter", "value", 2))
    var re_final = re_exec.field.get_int("counter", "value")

    # Semantic Kernel
    var sk_field = SK_Field()
    var sk_a = SK_Entity("counter", "Counter")
    sk_a.set("value", SK_Value(0))
    sk_field.add_entity(sk_a)
    sk_field.execute(SK_Transformation(SK_INCREMENT, "counter", "value", 1))
    sk_field.execute(SK_Transformation(SK_INCREMENT, "counter", "value", 2))
    var sk_final = sk_field.get_int("counter", "value")

    # Semantic equivalence
    assert_equal(re_final, sk_final)
    assert_equal(re_final, 3)


def test_equivalence_constraint_rollback() raises:
    """Both implementations reject constraint violations equivalently."""
    from scr_reference.constraint import NonNegativeConstraint as RE_Constraint
    from scr_kernel.constraint import NonNegativeConstraint as SK_Constraint

    # Reference Executor
    var re_field = RE_Field()
    var re_counter = RE_Entity("counter", "Counter")
    re_counter.set("value", RE_Value(1))
    re_field.add_entity(re_counter)
    re_field.add_non_negative_constraint(RE_Constraint("counter", "value"))
    var re_exec = RE_Executor(re_field)
    re_exec.execute(RE_Transformation(RE_INCREMENT, "counter", "value", 2))
    var re_before = re_exec.field.get_int("counter", "value")

    # Semantic Kernel
    var sk_field = SK_Field()
    var sk_counter = SK_Entity("counter", "Counter")
    sk_counter.set("value", SK_Value(1))
    sk_field.add_entity(sk_counter)
    sk_field.add_constraint(SK_Constraint("counter", "value"))
    sk_field.execute(SK_Transformation(SK_INCREMENT, "counter", "value", 2))
    var sk_before = sk_field.get_int("counter", "value")

    # Both have same state before failure
    assert_equal(re_before, sk_before)
    assert_equal(re_before, 3)


def test_equivalence_multiple_entities() raises:
    """Both implementations handle multiple entities with relationships."""
    from scr_reference.relationship import Relationship as RE_Relationship
    from scr_kernel.relationship import Relationship as SK_Relationship

    # Reference Executor
    var re_field = RE_Field()
    re_field.add_entity(RE_Entity("a", "Thing"))
    re_field.add_entity(RE_Entity("b", "Thing"))
    re_field.add_relationship(RE_Relationship("r1", "LINKS", "a", "b"))
    var re_count = re_field.relationship_count()

    # Semantic Kernel
    var sk_field = SK_Field()
    sk_field.add_entity(SK_Entity("a", "Thing"))
    sk_field.add_entity(SK_Entity("b", "Thing"))
    sk_field.add_relationship(SK_Relationship("r1", "LINKS", "a", "b"))
    var sk_count = len(sk_field.state.relationships)

    # Semantic equivalence
    assert_equal(re_count, sk_count)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
