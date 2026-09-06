from scr_reference.serialization.json import load_program
def test_load_program():
    f,t,o=load_program("examples/003_transformation.json")
    assert f.require_entity("counter").value==0
    assert len(t)==2
    assert o==[("counter","value")]
