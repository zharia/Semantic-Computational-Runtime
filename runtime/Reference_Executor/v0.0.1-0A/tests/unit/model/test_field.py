import pytest
from scr_reference.model import Entity, Relationship, SemanticField
from scr_reference.model.field import DuplicateEntity, UnknownEntity

def test_add_and_resolve_entity():
    f=SemanticField(); f.add_entity(Entity("x","Integer",1)); assert f.require_entity("x").value==1

def test_duplicate_entity_rejected():
    f=SemanticField(); f.add_entity(Entity("x","Integer",1))
    with pytest.raises(DuplicateEntity): f.add_entity(Entity("x","Integer",2))

def test_unknown_entity_rejected():
    with pytest.raises(UnknownEntity): SemanticField().require_entity("missing")

def test_relationship_requires_endpoints():
    f=SemanticField(); f.add_entity(Entity("a","Thing")); f.add_entity(Entity("b","Thing"))
    f.add_relationship(Relationship("a","relates","b")); assert len(f.relationships)==1
