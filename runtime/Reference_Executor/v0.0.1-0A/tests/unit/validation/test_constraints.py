import pytest
from scr_reference.model import Constraint, Entity, SemanticField
from scr_reference.validation.constraints import ConstraintViolation, validate_constraints

@pytest.mark.parametrize("op,expected", [("==",5),("!=",4),("<",6),("<=",5),(">",4),(">=",5),("in",[1,5,9])])
def test_operators(op,expected):
    f=SemanticField(); f.add_entity(Entity("x","Integer",5)); f.add_constraint(Constraint("x","value",op,expected)); validate_constraints(f)

def test_violation():
    f=SemanticField(); f.add_entity(Entity("x","Integer",11)); f.add_constraint(Constraint("x","value","<=",10))
    with pytest.raises(ConstraintViolation): validate_constraints(f)

def test_unknown_operator():
    f=SemanticField(); f.add_entity(Entity("x","Integer",1)); f.add_constraint(Constraint("x","value","???",1))
    with pytest.raises(ValueError): validate_constraints(f)

def test_property_constraint():
    f=SemanticField(); f.add_entity(Entity("x","Thing",properties={"limit":5})); f.add_constraint(Constraint("x","limit","==",5)); validate_constraints(f)
