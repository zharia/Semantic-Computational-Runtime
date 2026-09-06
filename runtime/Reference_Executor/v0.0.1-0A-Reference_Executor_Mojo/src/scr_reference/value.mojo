from std.utils import Variant

comptime Value = Variant[Int, Float64, Bool, String]

def value_int(mut value: Value) raises -> Int:
    if value.isa[Int]():
        return value[Int]
    raise Error("semantic value is not Int")

def value_float(mut value: Value) raises -> Float64:
    if value.isa[Float64]():
        return value[Float64]
    raise Error("semantic value is not Float64")

def value_bool(mut value: Value) raises -> Bool:
    if value.isa[Bool]():
        return value[Bool]
    raise Error("semantic value is not Bool")

def value_string(mut value: Value) raises -> String:
    if value.isa[String]():
        return value[String]
    raise Error("semantic value is not String")

def value_kind(mut value: Value) -> String:
    if value.isa[Int]():
        return "Int"
    elif value.isa[Float64]():
        return "Float64"
    elif value.isa[Bool]():
        return "Bool"
    return "String"

def value_text(mut value: Value) -> String:
    if value.isa[Int]():
        return String(value[Int])
    elif value.isa[Float64]():
        return String(value[Float64])
    elif value.isa[Bool]():
        return String(value[Bool])
    return value[String]
