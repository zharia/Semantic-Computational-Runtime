from scr_reference.execution.executor import ReferenceExecutor
from scr_reference.serialization.json import load_program

def test_reference_behaviour():
    f,t,o=load_program("examples/003_transformation.json"); r=ReferenceExecutor(f).execute(t,o)
    assert r.field.require_entity("counter").value==2
    assert r.trace.entries[-1].after==2
