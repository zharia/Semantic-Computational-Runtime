# Minimal JSON parser — Mojo 1.0.0 has no std.json module (verified:
# `from std.json import *` fails to locate module) and no `enum` keyword
# (parser rejects `enum` at file scope). JSON kinds are integer codes.
# Covers RFC 8259: objects, arrays, strings (escapes incl. \uXXXX → UTF-8
# with surrogate pairs), numbers (exp form), true/false/null.
#
# parse_json(text) raises Error on invalid input. Pure function of input.

from std.collections import List

comptime JSON_NULL: Int = 0
comptime JSON_BOOL: Int = 1
comptime JSON_NUMBER: Int = 2
comptime JSON_STRING: Int = 3
comptime JSON_ARRAY: Int = 4
comptime JSON_OBJECT: Int = 5


struct JsonValue(Copyable, Movable, Deinitable):
    var kind: Int
    var num: Float64
    var flag: Bool
    var string: String
    var items: List[JsonValue]  # array elements / object values
    var keys: List[String]  # object keys (insertion order)

    def __init__(out self, kind: Int):
        self.kind = kind
        self.num = 0.0
        self.flag = False
        self.string = ""
        self.items = List[JsonValue]()
        self.keys = List[String]()

    def __deinit__(deinit self):
        pass

    def is_object(self) -> Bool:
        return self.kind == JSON_OBJECT

    def is_array(self) -> Bool:
        return self.kind == JSON_ARRAY

    def len(self) -> Int:
        return len(self.items)

    def get(self, key: String) raises -> JsonValue:
        """Object member lookup; raises if the key is absent."""
        for i in range(len(self.keys)):
            if self.keys[i] == key:
                return self.items[i].copy()
        raise Error("json: missing key '" + key + "'")

    def has(self, key: String) -> Bool:
        for i in range(len(self.keys)):
            if self.keys[i] == key:
                return True
        return False

    def at(self, index: Int) raises -> JsonValue:
        if index < 0 or index >= len(self.items):
            raise Error("json: index out of range")
        return self.items[index].copy()

    def as_float(self) raises -> Float64:
        if self.kind != JSON_NUMBER:
            raise Error("json: not a number")
        return self.num

    def as_int(self) raises -> Int:
        if self.kind != JSON_NUMBER:
            raise Error("json: not a number")
        return Int(self.num)

    def as_string(self) raises -> String:
        if self.kind != JSON_STRING:
            raise Error("json: not a string")
        return self.string.copy()

    def as_bool(self) raises -> Bool:
        if self.kind != JSON_BOOL:
            raise Error("json: not a bool")
        return self.flag


# ---------------------------------------------------------------------------
# Decoder
# ---------------------------------------------------------------------------

struct _Parser(Movable, Deinitable):
    var data: List[UInt8]
    var pos: Int

    def __init__(out self, var data: List[UInt8]):
        self.data = data^
        self.pos = 0

    def __deinit__(deinit self):
        pass

    def eof(self) -> Bool:
        return self.pos >= len(self.data)

    def peek(self) -> UInt8:
        return self.data[self.pos]

    def advance(mut self):
        self.pos += 1

    def skip_ws(mut self):
        while not self.eof():
            var b = self.data[self.pos]
            if b == 0x20 or b == 0x09 or b == 0x0A or b == 0x0D:
                self.pos += 1
            else:
                return

    def expect(mut self, byte_val: UInt8) raises:
        if self.eof() or self.data[self.pos] != byte_val:
            raise Error("json: expected byte at offset " + String(self.pos))
        self.pos += 1

    def parse_value(mut self) raises -> JsonValue:
        self.skip_ws()
        if self.eof():
            raise Error("json: unexpected end of input")
        var b = self.peek()
        if b == 0x7B:  # {
            return self.parse_object()
        if b == 0x5B:  # [
            return self.parse_array()
        if b == 0x22:  # "
            var out = JsonValue(JSON_STRING)
            out.string = self.parse_string()
            return out^
        if b == 0x74:  # t
            self.parse_literal("true")
            var out = JsonValue(JSON_BOOL)
            out.flag = True
            return out^
        if b == 0x66:  # f
            self.parse_literal("false")
            var out = JsonValue(JSON_BOOL)
            out.flag = False
            return out^
        if b == 0x6E:  # n
            self.parse_literal("null")
            return JsonValue(JSON_NULL)
        return self.parse_number()

    def parse_literal(mut self, lit: String) raises:
        for c in lit.bytes():
            if self.eof() or self.data[self.pos] != c:
                raise Error("json: invalid literal at offset " + String(self.pos))
            self.pos += 1

    def parse_object(mut self) raises -> JsonValue:
        self.expect(0x7B)  # {
        var out = JsonValue(JSON_OBJECT)
        self.skip_ws()
        if not self.eof() and self.peek() == 0x7D:  # }
            self.advance()
            return out^
        while True:
            self.skip_ws()
            if self.eof() or self.peek() != 0x22:
                raise Error("json: expected object key at offset " + String(self.pos))
            var key = self.parse_string()
            self.skip_ws()
            self.expect(0x3A)  # :
            var value = self.parse_value()
            out.keys.append(key)
            out.items.append(value^)
            self.skip_ws()
            if self.eof():
                raise Error("json: unterminated object")
            var c = self.peek()
            if c == 0x2C:  # ,
                self.advance()
                continue
            if c == 0x7D:  # }
                self.advance()
                return out^
            raise Error("json: expected ',' or '}' at offset " + String(self.pos))

    def parse_array(mut self) raises -> JsonValue:
        self.expect(0x5B)  # [
        var out = JsonValue(JSON_ARRAY)
        self.skip_ws()
        if not self.eof() and self.peek() == 0x5D:  # ]
            self.advance()
            return out^
        while True:
            var value = self.parse_value()
            out.items.append(value^)
            self.skip_ws()
            if self.eof():
                raise Error("json: unterminated array")
            var c = self.peek()
            if c == 0x2C:  # ,
                self.advance()
                continue
            if c == 0x5D:  # ]
                self.advance()
                return out^
            raise Error("json: expected ',' or ']' at offset " + String(self.pos))

    def parse_number(mut self) raises -> JsonValue:
        var start = self.pos
        if not self.eof() and self.peek() == 0x2D:  # -
            self.advance()
        var digits = 0
        while not self.eof():
            var c = self.peek()
            if c >= 0x30 and c <= 0x39:
                self.advance()
                digits += 1
            else:
                break
        if digits == 0:
            raise Error("json: invalid number at offset " + String(start))
        if not self.eof() and self.peek() == 0x2E:  # .
            self.advance()
            while not self.eof():
                var c = self.peek()
                if c >= 0x30 and c <= 0x39:
                    self.advance()
                else:
                    break
        if not self.eof() and (self.peek() == 0x65 or self.peek() == 0x45):  # e E
            self.advance()
            if not self.eof() and (self.peek() == 0x2B or self.peek() == 0x2D):
                self.advance()
            while not self.eof():
                var c = self.peek()
                if c >= 0x30 and c <= 0x39:
                    self.advance()
                else:
                    break
        var text = String()
        for i in range(start, self.pos):
            text = text + chr(Int(self.data[i]))
        var out = JsonValue(JSON_NUMBER)
        out.num = _parse_float(text)
        return out^

    def parse_string(mut self) raises -> String:
        self.expect(0x22)  # "
        var result = String()
        while True:
            if self.eof():
                raise Error("json: unterminated string")
            var b = self.data[self.pos]
            if b == 0x22:  # closing quote
                self.advance()
                return result^
            if b == 0x5C:  # backslash
                self.advance()
                if self.eof():
                    raise Error("json: dangling escape")
                var e = self.data[self.pos]
                self.advance()
                if e == 0x22:
                    result = result + '"'
                elif e == 0x5C:
                    result = result + "\\"
                elif e == 0x2F:
                    result = result + "/"
                elif e == 0x62:
                    result = result + chr(0x08)
                elif e == 0x66:
                    result = result + chr(0x0C)
                elif e == 0x6E:
                    result = result + chr(0x0A)
                elif e == 0x72:
                    result = result + chr(0x0D)
                elif e == 0x74:
                    result = result + chr(0x09)
                elif e == 0x75:
                    var cp = self.parse_hex4()
                    if cp >= 0xD800 and cp <= 0xDBFF:
                        # High surrogate: expect a following low surrogate.
                        if (
                            self.pos + 1 < len(self.data)
                            and self.data[self.pos] == 0x5C
                            and self.data[self.pos + 1] == 0x75
                        ):
                            self.pos += 2
                            var lo = self.parse_hex4()
                            cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00)
                    result = result + chr(cp)
                else:
                    raise Error("json: invalid escape at offset " + String(self.pos))
            else:
                var next_pos = _utf8_step(self.data, self.pos)
                result = result + _decode_utf8_char(self.data, self.pos, next_pos)
                self.pos = next_pos

    def parse_hex4(mut self) raises -> Int:
        var v = 0
        for _ in range(4):
            if self.eof():
                raise Error("json: truncated \\u escape")
            var c = self.data[self.pos]
            self.pos += 1
            var d: Int
            if c >= 0x30 and c <= 0x39:
                d = Int(c - 0x30)
            elif c >= 0x61 and c <= 0x66:
                d = Int(c - 0x61) + 10
            elif c >= 0x41 and c <= 0x46:
                d = Int(c - 0x41) + 10
            else:
                raise Error("json: bad hex digit in \\u escape")
            v = (v << 4) + d
        return v


def _utf8_step(data: List[UInt8], pos: Int) -> Int:
    var b = data[pos]
    if b < 0x80:
        return pos + 1
    if b < 0xE0:
        return pos + 2
    if b < 0xF0:
        return pos + 3
    return pos + 4


def _decode_utf8_char(data: List[UInt8], start: Int, end: Int) -> String:
    var b = data[start]
    if b < 0x80:
        return String(chr(Int(b)))
    if b < 0xE0:
        return String(chr((Int(b & 0x1F) << 6) | Int(data[start + 1] & 0x3F)))
    if b < 0xF0:
        return String(
            chr(
                (Int(b & 0x0F) << 12)
                | (Int(data[start + 1] & 0x3F) << 6)
                | Int(data[start + 2] & 0x3F)
            )
        )
    _ = end
    return String(
        chr(
            (Int(b & 0x07) << 18)
            | (Int(data[start + 1] & 0x3F) << 12)
            | (Int(data[start + 2] & 0x3F) << 6)
            | Int(data[start + 3] & 0x3F)
        )
    )


def _parse_float(text: String) -> Float64:
    # Decimal (incl. exponent) parser — no locale/format dependencies.
    var bytes = List[UInt8]()
    for b in text.bytes():
        bytes.append(b)
    var i = 0
    var n = len(bytes)
    var sign = 1.0
    if i < n and bytes[i] == 0x2D:
        sign = -1.0
        i += 1
    var int_part = 0.0
    while i < n and bytes[i] >= 0x30 and bytes[i] <= 0x39:
        int_part = int_part * 10.0 + Float64(bytes[i] - 0x30)
        i += 1
    var frac = 0.0
    var frac_scale = 0.1
    if i < n and bytes[i] == 0x2E:
        i += 1
        while i < n and bytes[i] >= 0x30 and bytes[i] <= 0x39:
            frac += Float64(bytes[i] - 0x30) * frac_scale
            frac_scale *= 0.1
            i += 1
    var mantissa = int_part + frac
    if i < n and (bytes[i] == 0x65 or bytes[i] == 0x45):
        i += 1
        var exp_sign = 1
        if i < n and bytes[i] == 0x2B:
            i += 1
        elif i < n and bytes[i] == 0x2D:
            exp_sign = -1
            i += 1
        var exp_val = 0
        while i < n and bytes[i] >= 0x30 and bytes[i] <= 0x39:
            exp_val = exp_val * 10 + Int(bytes[i] - 0x30)
            i += 1
        var factor = 1.0
        if exp_sign == 1:
            for _ in range(exp_val):
                factor *= 10.0
        else:
            for _ in range(exp_val):
                factor *= 0.1
        mantissa *= factor
    return sign * mantissa


def parse_json(text: String) raises -> JsonValue:
    """Parse a JSON document; raises Error on invalid input."""
    var data = List[UInt8]()
    for c in text.bytes():
        data.append(c)
    var p = _Parser(data^)
    var v = p.parse_value()
    p.skip_ws()
    if not p.eof():
        raise Error("json: trailing data at offset " + String(p.pos))
    return v^
