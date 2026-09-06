from scr_reference.execution.executor import ReferenceExecutor
from scr_reference.serialization.json import load_program

def test_golden_counter():
    f,t,o=load_program("examples/003_transformation.json"); r=ReferenceExecutor(f).execute(t,o)
    assert r.field.require_entity("counter").value==2
    assert [x.value for x in r.observations]==[2]

def test_golden_bounded_counter():
    f,t,o=load_program("examples/004_constraint.json"); r=ReferenceExecutor(f).execute(t,o)
    assert r.field.require_entity("counter").value==10
