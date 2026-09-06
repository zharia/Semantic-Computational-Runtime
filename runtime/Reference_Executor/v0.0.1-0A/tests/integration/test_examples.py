import pytest
from scr_reference.execution.executor import ReferenceExecutor
from scr_reference.serialization.json import load_program

@pytest.mark.parametrize("path",["examples/001_hello.json","examples/002_relationship.json","examples/003_transformation.json","examples/004_constraint.json"])
def test_examples_execute(path):
    f,t,o=load_program(path); r=ReferenceExecutor(f).execute(t,o)
    assert r.field is not None and r.observations is not None
