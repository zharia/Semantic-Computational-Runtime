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
