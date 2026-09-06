import pytest
from scr_reference.model import Entity, SemanticField
from scr_reference.operations.registry import OperationError, default_registry

def field():
    f=SemanticField(); f.add_entity(Entity("x","Integer",2)); return f

def test_set():
    f=field(); default_registry().execute("set",f,"x",5); assert f.require_entity("x").value==5

def test_increment():
    f=field(); default_registry().execute("increment",f,"x",3); assert f.require_entity("x").value==5

def test_add():
    f=field(); default_registry().execute("add",f,"x",3); assert f.require_entity("x").value==5

def test_multiply():
    f=field(); default_registry().execute("multiply",f,"x",3); assert f.require_entity("x").value==6

def test_append():
    f=SemanticField(); f.add_entity(Entity("s","Sequence",[])); default_registry().execute("append",f,"s","a"); assert f.require_entity("s").value==["a"]

def test_emit():
    f=field(); default_registry().execute("emit",f,"x",None)

def test_unknown_operation():
    with pytest.raises(OperationError): default_registry().execute("missing",field(),"x",None)

def test_increment_rejects_wrong_value():
    f=SemanticField(); f.add_entity(Entity("x","Text","2"))
    with pytest.raises(OperationError): default_registry().execute("increment",f,"x",1)

def test_increment_rejects_bool():
    f=SemanticField(); f.add_entity(Entity("x","Boolean",True))
    with pytest.raises(OperationError): default_registry().execute("increment",f,"x",1)

def test_duplicate_registration():
    r=default_registry()
    with pytest.raises(ValueError): r.register("set",lambda *_:None)
