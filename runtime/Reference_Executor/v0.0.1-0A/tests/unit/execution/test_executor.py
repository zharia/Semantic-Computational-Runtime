import pytest
from scr_reference.execution.executor import ExecutionError, ReferenceExecutor
from scr_reference.model import Constraint, Entity, SemanticField, Transformation

def counter(value=0):
    f=SemanticField(); f.add_entity(Entity("counter","Integer",value)); return f

def test_execution_and_trace():
    r=ReferenceExecutor(counter()).execute([Transformation("one","increment","counter",1),Transformation("two","increment","counter",1)],[("counter","value")])
    assert r.field.require_entity("counter").value==2
    assert r.observations[0].value==2
    assert len(r.trace.entries)==2

def test_constraint_failure_is_atomic():
    f=counter(9); f.add_constraint(Constraint("counter","value","<=",10)); e=ReferenceExecutor(f)
    with pytest.raises(ExecutionError): e.execute([Transformation("bad","increment","counter",2)])
    assert e.field.require_entity("counter").value==9

def test_initial_constraint_failure():
    f=counter(11); f.add_constraint(Constraint("counter","value","<=",10))
    with pytest.raises(Exception): ReferenceExecutor(f).execute([])

def test_property_observation():
    f=counter(3); f.require_entity("counter").properties["unit"]="count"
    r=ReferenceExecutor(f).execute([], [("counter","unit")]); assert r.observations[0].value=="count"

def test_status_complete():
    e=ReferenceExecutor(counter()); e.execute([]); assert e.state.status=="complete"
