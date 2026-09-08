# AMQP 0-9-1 field table implementation.
#
# Field tables are string-keyed maps with typed values.
# Used in connection.start, exchange.declare, queue.declare, etc.

from std.collections import Dict, List


struct FieldValue:
    """A typed value inside an AMQP field table."""
    var _type: UInt8  # 'S'=83, 'I'=73, 't'=116
    var _string_val: String
    var _int_val: Int
    var _bool_val: Bool

    def __init__(out self):
        self._type = 0
        self._string_val = ""
        self._int_val = 0
        self._bool_val = False

    @staticmethod
    def from_string(var value: String) -> FieldValue:
        var v = FieldValue()
        v._type = 83  # 'S'
        v._string_val = value^
        return v^

    @staticmethod
    def from_int(value: Int) -> FieldValue:
        var v = FieldValue()
        v._type = 73  # 'I'
        v._int_val = value
        return v^

    @staticmethod
    def from_bool(value: Bool) -> FieldValue:
        var v = FieldValue()
        v._type = 116  # 't'
        v._bool_val = value
        return v^

    def type_tag(ref self) -> Int:
        return Int(self._type)

    def is_string(ref self) -> Bool:
        return self._type == 83

    def is_int(ref self) -> Bool:
        return self._type == 73

    def is_bool(ref self) -> Bool:
        return self._type == 116

    def get_string(ref self) -> String:
        return self._string_val

    def get_int(ref self) -> Int:
        return self._int_val

    def get_bool(ref self) -> Bool:
        return self._bool_val


struct FieldTable:
    """AMQP field table (F-table). String-keyed map with typed values."""

    var _data: Dict[String, FieldValue]
    var _keys: List[String]

    def __init__(out self):
        self._data = Dict[String, FieldValue]()
        self._keys = List[String]()

    def set_string(mut self, var key: String, var value: String):
        if key not in self._data:
            var kcopy = key
            self._keys.append(kcopy^)
        self._data[key^] = FieldValue.from_string(value^)

    def set_int(mut self, var key: String, value: Int):
        if key not in self._data:
            var kcopy = key
            self._keys.append(kcopy^)
        self._data[key^] = FieldValue.from_int(value)

    def set_bool(mut self, var key: String, value: Bool):
        if key not in self._data:
            var kcopy = key
            self._keys.append(kcopy^)
        self._data[key^] = FieldValue.from_bool(value)

    def type_of(ref self, key: String) raises -> Int:
        """Type octet for key, or 0 if missing."""
        if key not in self._data:
            return 0
        return self._data[key].type_tag()

    def get_string(ref self, key: String) raises -> Optional[String]:
        if key not in self._data or not self._data[key].is_string():
            return Optional[String]()
        return Optional[String](self._data[key].get_string())

    def get_int(ref self, key: String) raises -> Optional[Int]:
        if key not in self._data or not self._data[key].is_int():
            return Optional[Int]()
        return Optional[Int](self._data[key].get_int())

    def get_bool(ref self, key: String) raises -> Optional[Bool]:
        if key not in self._data or not self._data[key].is_bool():
            return Optional[Bool]()
        return Optional[Bool](self._data[key].get_bool())

    def has_key(ref self, key: String) -> Bool:
        return key in self._data

    def size(ref self) -> Int:
        return len(self._keys)

    def to_bytes(ref self) raises -> List[UInt8]:
        """Serialize field table to bytes. Long-str format: 4-byte length prefix + pairs."""
        var result = List[UInt8]()

        # Collect all key-value bytes first to compute length
        var body = List[UInt8]()

        for i in range(len(self._keys)):
            var key = self._keys[i]
            # Field name: short-str (1-byte length + bytes)
            var key_bytes = key.as_bytes()
            body.append(UInt8(len(key_bytes)))
            for j in range(len(key_bytes)):
                body.append(key_bytes[j])

            # Field value: type octet + encoded value
            var vtype = self._data[key].type_tag()
            body.append(UInt8(vtype))
            if vtype == 83:  # string 'S'
                var sbytes = self._data[key].get_string().as_bytes()
                # long string: 4-byte length
                var slen = len(sbytes)
                body.append(UInt8((slen >> 24) & 0xFF))
                body.append(UInt8((slen >> 16) & 0xFF))
                body.append(UInt8((slen >> 8) & 0xFF))
                body.append(UInt8(slen & 0xFF))
                for j in range(slen):
                    body.append(sbytes[j])
            elif vtype == 73:  # integer 'I'
                var v = self._data[key].get_int()
                body.append(UInt8((v >> 24) & 0xFF))
                body.append(UInt8((v >> 16) & 0xFF))
                body.append(UInt8((v >> 8) & 0xFF))
                body.append(UInt8(v & 0xFF))
            elif vtype == 116:  # bool 't'
                if self._data[key].get_bool():
                    body.append(1)
                else:
                    body.append(0)

        # 4-byte length prefix (big-endian)
        var body_len = len(body)
        result.append(UInt8((body_len >> 24) & 0xFF))
        result.append(UInt8((body_len >> 16) & 0xFF))
        result.append(UInt8((body_len >> 8) & 0xFF))
        result.append(UInt8(body_len & 0xFF))
        for i in range(len(body)):
            result.append(body[i])

        return result^

    @staticmethod
    def from_bytes(data: List[UInt8]) raises -> FieldTable:
        """Deserialize field table from bytes."""
        var table = FieldTable()
        if len(data) < 4:
            return table^

        # Read 4-byte length prefix
        var body_len = (
            (Int(data[0]) << 24) |
            (Int(data[1]) << 16) |
            (Int(data[2]) << 8) |
            Int(data[3])
        )

        var pos = 4
        var end = 4 + body_len

        while pos < end:
            if pos >= len(data):
                break

            # Field name: short-str
            var name_len = Int(data[pos])
            pos += 1
            if pos + name_len > len(data):
                break
            var name = String()
            for j in range(name_len):
                name.append(Codepoint(data[pos + j]))
            pos += name_len

            if pos >= len(data):
                break

            # Field value type
            var vtype = Int(data[pos])
            pos += 1

            if vtype == 83:  # string 'S'
                if pos + 4 > len(data):
                    break
                var slen = (
                    (Int(data[pos]) << 24) |
                    (Int(data[pos + 1]) << 16) |
                    (Int(data[pos + 2]) << 8) |
                    Int(data[pos + 3])
                )
                pos += 4
                if pos + slen > len(data):
                    break
                var sval = String()
                for j in range(slen):
                    sval.append(Codepoint(data[pos + j]))
                pos += slen
                table.set_string(name^, sval^)
            elif vtype == 73:  # integer 'I'
                if pos + 4 > len(data):
                    break
                var ival = (
                    (Int(data[pos]) << 24) |
                    (Int(data[pos + 1]) << 16) |
                    (Int(data[pos + 2]) << 8) |
                    Int(data[pos + 3])
                )
                pos += 4
                table.set_int(name^, ival)
            elif vtype == 116:  # bool 't'
                if pos >= len(data):
                    break
                var bval = data[pos] != 0
                pos += 1
                table.set_bool(name^, bval)
            else:
                break

        return table^
