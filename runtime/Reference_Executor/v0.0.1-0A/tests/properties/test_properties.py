from hypothesis import given, strategies as st
from scr_reference.execution.executor import ReferenceExecutor
from scr_reference.model import Entity, SemanticField, Transformation

@given(st.integers(-1000,1000), st.integers(-100,100))
def test_increment_additive(initial, amount):
    f=SemanticField(); f.add_entity(Entity("x","Integer",initial))
    r=ReferenceExecutor(f).execute([Transformation("t","increment","x",amount)])
    assert r.field.require_entity("x").value==initial+amount

@given(st.integers(-1000,1000))
def test_set_replaces(value):
    f=SemanticField(); f.add_entity(Entity("x","Integer",0))
    r=ReferenceExecutor(f).execute([Transformation("t","set","x",value)])
    assert r.field.require_entity("x").value==value
