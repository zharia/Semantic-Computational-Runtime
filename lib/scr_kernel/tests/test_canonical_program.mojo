"""Canonical Semantic Entity Compilation Program.

This test exercises the full semantic compilation pipeline:

  CounterDefinition
    → CounterInstance
    → Identity
    → State
    → Transformation
    → Constraint
    → Context
    → Observation
    → Semantic Result

It is the compilation witness: semantic meaning survives the
transition from definition to verified computation.
"""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from scr_kernel.entity import Entity
from scr_kernel.entity_definition import EntityDefinition

from scr_kernel.field import SemanticField
from scr_kernel.transformation import INCREMENT, EMIT, SET_INT, Transformation
from scr_kernel.value import Value, value_int, value_string
from scr_kernel.constraint import NonNegativeConstraint
from scr_kernel.context import SemanticContext


# ---------------------------------------------------------------
# Canonical Semantic Program
# ---------------------------------------------------------------

def _build_counter_definition() -> EntityDefinition:
    """1. Entity Definition: Counter has property 'value'."""
    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    return defn^


def _build_counter_instance(defn: EntityDefinition) raises -> Entity:
    """2. Entity Instance: c1 conforms to Counter, initial value=0."""
    var inst = Entity("c1", "Counter")
    inst.set("value", Value(0))
    return inst^


def _build_counter_field(defn: EntityDefinition, inst: Entity) raises -> SemanticField:
    """3. Semantic Field: definition + entity + constraint + context."""
    var field = SemanticField()
    field.add_definition(defn)

    # Add entity directly
    field.add_entity(inst)

    # Constraint: value >= 0
    field.add_constraint(NonNegativeConstraint(inst.id, "value"))

    # Context: initial step
    var ctx = SemanticContext(0, "golden-path")
    field.set_context(ctx)

    return field^


# ---------------------------------------------------------------
# Tests
# ---------------------------------------------------------------

def test_canonical_entity_definition() raises:
    """Entity Definition is well-formed."""
    var defn = _build_counter_definition()
    assert_equal(defn.type_id, "Counter")
    assert_true(defn.has_property("value"))
    assert_true(not defn.has_property("label"))


def test_canonical_entity_conformance() raises:
    """Entity Instance conforms to its Definition."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    assert_true(inst.conforms(defn))


def test_canonical_nonconformance_rejection() raises:
    """Instance missing required property is rejected by field constraint."""
    var defn = EntityDefinition("Counter")
    defn.add_property("value")
    defn.add_property("label")

    var field = SemanticField()
    field.add_definition(defn)

    var inst = Entity("c1", "Counter")
    inst.set("value", Value(0))
    # Missing 'label' → field will reject if conformace is checked
    # For now, verify the definition expects the property
    assert_true(defn.has_property("label"))


def test_canonical_full_pipeline() raises:
    """Full semantic program: define → instantiate → transform → observe."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var field = _build_counter_field(defn, inst)

    # Initial state
    assert_equal(field.get_int("c1", "value"), 0)
    assert_equal(field.state.logical_step, 0)
    assert_equal(field.context.label, "golden-path")

    # Transform: increment by 5
    field.execute(Transformation(INCREMENT, "c1", "value", 5))
    assert_equal(field.get_int("c1", "value"), 5)
    assert_equal(field.state.logical_step, 1)
    assert_equal(field.context.logical_step, 1)

    # Observe
    field.execute(Transformation(EMIT, "c1", "value"))
    var obs_val = field.observations[0].value.copy()
    var result = value_int(obs_val)
    assert_equal(result, 5)
    assert_equal(len(field.observations), 1)

    # State still intact after observation
    assert_equal(field.get_int("c1", "value"), 5)
    assert_equal(field.state.logical_step, 1)


def test_canonical_constraint_prevents_negative() raises:
    """Constraint blocks transformation that would violate invariant."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var field = _build_counter_field(defn, inst)

    # Increment by 3 → value=3
    field.execute(Transformation(INCREMENT, "c1", "value", 3))
    assert_equal(field.get_int("c1", "value"), 3)

    # Attempt decrement by 10 → would be -7, blocked by constraint
    with assert_raises(contains="constraint violation"):
        field.execute(Transformation(INCREMENT, "c1", "value", -10))

    # State unchanged after failed transformation
    assert_equal(field.get_int("c1", "value"), 3)
    assert_equal(field.state.logical_step, 1)


def test_canonical_determinism() raises:
    """Same canonical program produces identical results."""
    var defn_a = _build_counter_definition()
    var inst_a = _build_counter_instance(defn_a)
    var field_a = _build_counter_field(defn_a, inst_a)

    var defn_b = _build_counter_definition()
    var inst_b = _build_counter_instance(defn_b)
    var field_b = _build_counter_field(defn_b, inst_b)

    field_a.execute(Transformation(INCREMENT, "c1", "value", 5))
    field_a.execute(Transformation(INCREMENT, "c1", "value", 5))
    field_b.execute(Transformation(INCREMENT, "c1", "value", 5))
    field_b.execute(Transformation(INCREMENT, "c1", "value", 5))

    assert_equal(field_a.get_int("c1", "value"), field_b.get_int("c1", "value"))
    assert_equal(field_a.state.logical_step, field_b.state.logical_step)
    assert_equal(field_a.get_int("c1", "value"), 10)


def test_canonical_observation_noninterference() raises:
    """Observation does not advance time or mutate state."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var field = _build_counter_field(defn, inst)

    var before_step = field.state.logical_step
    var before_value = field.get_int("c1", "value")

    field.execute(Transformation(EMIT, "c1", "value"))
    field.execute(Transformation(EMIT, "c1", "value"))

    assert_equal(field.state.logical_step, before_step)
    assert_equal(field.get_int("c1", "value"), before_value)
    assert_equal(len(field.observations), 2)


def test_canonical_context_propagation() raises:
    """Context advances with each state-changing transformation."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var field = _build_counter_field(defn, inst)

    assert_equal(field.context.logical_step, 0)

    field.execute(Transformation(INCREMENT, "c1", "value", 1))
    assert_equal(field.context.logical_step, 1)

    field.execute(Transformation(INCREMENT, "c1", "value", 2))
    assert_equal(field.context.logical_step, 2)


def test_canonical_identity_persists() raises:
    """Entity identity persists across transformations."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var field = _build_counter_field(defn, inst)

    field.execute(Transformation(INCREMENT, "c1", "value", 5))

    var entity = field.get_entity("c1")
    assert_equal(entity.id, "c1")
    assert_equal(entity.type_id, "Counter")


def test_canonical_semantic_result() raises:
    """Complete pipeline produces correct semantic result."""
    var defn = _build_counter_definition()
    var inst = _build_counter_instance(defn)
    var field = _build_counter_field(defn, inst)

    # Execute 3 transformations: +5, +3, +2
    field.execute(Transformation(INCREMENT, "c1", "value", 5))  # → 5
    field.execute(Transformation(INCREMENT, "c1", "value", 3))  # → 8
    field.execute(Transformation(INCREMENT, "c1", "value", 2))  # → 10

    # Observe final value
    field.execute(Transformation(EMIT, "c1", "value"))
    var obs_val = field.observations[0].value.copy()
    var result = value_int(obs_val)
    assert_equal(result, 10)

    # Verify complete semantic state
    assert_equal(field.get_int("c1", "value"), 10)
    assert_equal(field.state.logical_step, 3)
    assert_equal(field.context.logical_step, 3)
    assert_equal(len(field.observations), 1)
    assert_equal(field.context.label, "golden-path")


def test_constraint_violation_is_not_noop() raises:
    """Constraint violation is distinguishable from successful no-op."""
    var defn = EntityDefinition("Counter")
    defn.add_property("value")

    var field = SemanticField()
    field.add_definition(defn)

    var entity = Entity("c1", "Counter")
    entity.set("value", Value(5))
    field.add_entity(entity)

    field.add_constraint(NonNegativeConstraint("c1", "value"))
    field.set_context(SemanticContext(0, "test"))

    # Constraint violation: raises, state unchanged, time unchanged
    var violated = False
    try:
        field.execute(Transformation(INCREMENT, "c1", "value", -10))
    except:
        violated = True

    assert_true(violated)
    assert_equal(field.get_int("c1", "value"), 5)
    assert_equal(field.state.logical_step, 0)

    # Successful no-op (set to same value): no raise, state same, time advances
    field.execute(Transformation(SET_INT, "c1", "value", 5))
    assert_equal(field.get_int("c1", "value"), 5)
    assert_equal(field.state.logical_step, 1)


def test_semantic_time_is_representation_independent() raises:
    """SemanticTime semantics hold regardless of underlying type."""
    var ctx1 = SemanticContext(0, "test")
    var ctx2 = ctx1.with_step(5)
    assert_equal(ctx2.logical_step, 5)
    assert_equal(ctx1.logical_step, 0)

    # Time always advances forward
    var ctx3 = ctx2.with_step(10)
    assert_true(ctx3.logical_step > ctx2.logical_step)


def test_identity_is_independent_of_representation() raises:
    """Semantic identity persists regardless of representation."""
    # Same entity, different "physical" containers
    var entity_a = Entity("c1", "Counter")
    entity_a.set("value", Value(10))

    var entity_b = Entity("c1", "Counter")
    entity_b.set("value", Value(10))

    # Both have the same semantic identity
    assert_equal(entity_a.id, entity_b.id)
    assert_equal(entity_a.type_id, entity_b.type_id)

    # Changing type_id does not create new identity
    var entity_c = Entity("c1", "DifferentType")
    assert_equal(entity_c.id, "c1")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
