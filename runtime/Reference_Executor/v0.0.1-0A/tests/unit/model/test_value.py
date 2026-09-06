from scr_reference.model.value import Value
def test_value_inference():
    assert Value.infer(True).type=="Boolean"
    assert Value.infer(1).type=="Integer"
    assert Value.infer(1.5).type=="Real"
    assert Value.infer("x").type=="Text"
    assert Value.infer([1]).type=="Sequence"
    assert Value.infer(None).type=="Null"
