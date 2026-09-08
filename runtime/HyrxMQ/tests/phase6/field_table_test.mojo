# Tests for AMQP field table.
#
# Verifies set/get, type checking, serialization round-trip.

from hyrx.amqp.field_table import FieldTable, FieldValue


from hyrx.testing import check

def test_field_value_constructors() raises:
    """FieldValue static constructors tag values correctly."""
    var s = FieldValue.from_string("mojo")
    check((s.is_string()), "L11")
    check(not (s.is_int()), "L12")
    check((s.type_tag() == 83), "L13")
    var i = FieldValue.from_int(42)
    check((i.is_int()), "L15")
    check((i.get_int() == 42), "L16")
    var b = FieldValue.from_bool(True)
    check((b.is_bool()), "L18")
    check((b.get_bool()), "L19")


def test_set_get_string() raises:
    """String field set and get."""
    var ft = FieldTable()
    ft.set_string("product", "mojo")
    check((ft.type_of("product") == 83), "L26")
    var v = ft.get_string("product")
    check((v.__bool__()), "L28")
    check((v.value() == "mojo"), "L29")


def test_set_get_int() raises:
    """Integer field set and get."""
    var ft = FieldTable()
    ft.set_int("count", 42)
    check((ft.type_of("count") == 73), "L36")
    var v = ft.get_int("count")
    check((v.__bool__()), "L38")
    check((v.value() == 42), "L39")


def test_set_get_bool() raises:
    """Boolean field set and get."""
    var ft = FieldTable()
    ft.set_bool("durable", True)
    check((ft.type_of("durable") == 116), "L46")
    var v = ft.get_bool("durable")
    check((v.__bool__()), "L48")
    check((v.value() == True), "L49")


def test_missing_key() raises:
    """Missing key returns empty Optional."""
    var ft = FieldTable()
    ft.set_string("a", "hello")
    check((ft.type_of("b") == 0), "L56")
    check(not (ft.get_string("b").__bool__()), "L57")
    check(not (ft.get_int("b").__bool__()), "L58")
    check(not (ft.get_bool("b").__bool__()), "L59")


def test_wrong_type_returns_empty() raises:
    """Typed getter on mismatched field returns empty Optional."""
    var ft = FieldTable()
    ft.set_int("port", 5672)
    check(not (ft.get_string("port").__bool__()), "L66")
    check((ft.get_int("port").value() == 5672), "L67")


def test_has_key() raises:
    """Has_key checks existence."""
    var ft = FieldTable()
    ft.set_string("x", "y")
    check((ft.has_key("x")), "L74")
    check(not (ft.has_key("z")), "L75")


def test_size() raises:
    """Size tracks number of entries."""
    var ft = FieldTable()
    check((ft.size() == 0), "L81")
    ft.set_string("a", "1")
    check((ft.size() == 1), "L83")
    ft.set_int("b", 2)
    check((ft.size() == 2), "L85")
    ft.set_bool("c", True)
    check((ft.size() == 3), "L87")


def test_overwrite() raises:
    """Setting same key overwrites value."""
    var ft = FieldTable()
    ft.set_string("key", "old")
    ft.set_string("key", "new")
    check((ft.size() == 1), "L95")
    check((ft.get_string("key").value() == "new"), "L96")


def test_serialization_roundtrip_string() raises:
    """String field survives serialization round-trip."""
    var original = FieldTable()
    original.set_string("host", "localhost")
    var bytes = original.to_bytes()
    var restored = FieldTable.from_bytes(bytes^)
    check((restored.has_key("host")), "L105")
    var v = restored.get_string("host")
    check((v.__bool__()), "L107")
    check((v.value() == "localhost"), "L108")


def test_serialization_roundtrip_int() raises:
    """Integer field survives serialization round-trip."""
    var original = FieldTable()
    original.set_int("port", 5672)
    var bytes = original.to_bytes()
    var restored = FieldTable.from_bytes(bytes^)
    check((restored.has_key("port")), "L117")
    var v = restored.get_int("port")
    check((v.__bool__()), "L119")
    check((v.value() == 5672), "L120")


def test_serialization_roundtrip_bool() raises:
    """Boolean field survives serialization round-trip."""
    var original = FieldTable()
    original.set_bool("auto_ack", False)
    var bytes = original.to_bytes()
    var restored = FieldTable.from_bytes(bytes^)
    check((restored.has_key("auto_ack")), "L129")
    var v = restored.get_bool("auto_ack")
    check((v.__bool__()), "L131")
    check((v.value() == False), "L132")


def test_serialization_roundtrip_mixed() raises:
    """Multiple fields of different types survive round-trip."""
    var original = FieldTable()
    original.set_string("name", "test-exchange")
    original.set_int("priority", 5)
    original.set_bool("durable", True)
    var bytes = original.to_bytes()
    var restored = FieldTable.from_bytes(bytes^)
    check((restored.size() == 3), "L143")
    check((restored.get_string("name").value() == "test-exchange"), "L144")
    check((restored.get_int("priority").value() == 5), "L145")
    check((restored.get_bool("durable").value() == True), "L146")


def test_empty_serialization() raises:
    """Empty table serializes to 4-byte zero-length prefix."""
    var ft = FieldTable()
    var bytes = ft.to_bytes()
    check((len(bytes) == 4), "L153")
    check((bytes[0] == 0), "L154")
    check((bytes[1] == 0), "L155")
    check((bytes[2] == 0), "L156")
    check((bytes[3] == 0), "L157")


def main() raises:
    test_field_value_constructors()
    test_set_get_string()
    test_set_get_int()
    test_set_get_bool()
    test_missing_key()
    test_wrong_type_returns_empty()
    test_has_key()
    test_size()
    test_overwrite()
    test_serialization_roundtrip_string()
    test_serialization_roundtrip_int()
    test_serialization_roundtrip_bool()
    test_serialization_roundtrip_mixed()
    test_empty_serialization()
    print("PHASE6_FIELD_TABLE_TEST=PASS")
