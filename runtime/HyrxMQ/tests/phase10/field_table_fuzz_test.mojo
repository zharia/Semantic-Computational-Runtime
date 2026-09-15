# Phase 10 — AMQP field-table fuzz / adversarial test.
#
# Requirement: an untrusted field table (the `arguments` of exchange.declare /
# queue.declare / basic.consume, or a content property table) must not crash the
# process or drive an unbounded allocation. This test builds VALID field tables
# (all edge value types, deeply nested tables, huge declared sizes), then
# bit-flips / byte-replaces / truncates / duplicates them with a deterministic
# LCG and feeds every mutant through the two table readers:
#   - FieldTable.from_bytes (the in-memory decoder), and
#   - ByteReader.read_table (the frame-argument decoder).
#
# Both readers are bounds-checked: a malformed table either decodes as far as
# its bytes reach or raises a catchable error. A segfault or an uncaught raise
# aborts Mojo, so the final FIELD_TABLE_FUZZ_TEST=PASS line itself proves the
# process survived all mutants (default 10000; override with HYRXMQ_FUZZ_ITERS).

from std.collections import Dict, List
from std.os import getenv

from hyrx.amqp.field_table import FieldTable
from hyrxmq.amqp_service import ByteReader
from hyrx.testing import check


def resolve_iters(var env_name: String, default: Int) raises -> Int:
    """Iteration count: HYRXMQ_FUZZ_ITERS when set, else `default`.

    Keeps the historical default when no override is present; a malformed
    value fails loud rather than silently running a smaller bar."""
    var v = getenv(env_name, "")
    if len(v.bytes()) == 0:
        return default
    return Int(v)


# ---- deterministic LCG (glibc params, period 2^32) ----

struct LCG:
    """Linear congruential generator — deterministic, 32-bit period."""
    var state: UInt32

    def __init__(out self, seed: UInt32):
        self.state = seed

    def next(mut self) -> UInt32:
        self.state = self.state * 1103515245 + 12345
        return self.state

    def next_range(mut self, lo: Int, hi: Int) -> Int:
        """Return lo..hi inclusive, deterministic."""
        var span = hi - lo + 1
        if span <= 0:
            return lo
        var r = self.next()
        return lo + Int(r % UInt32(span))


# ---- helpers ----

def list_copy(ref src: List[UInt8]) -> List[UInt8]:
    """Copy a byte list (Mojo 1.0 List has no .copy())."""
    var result = List[UInt8](capacity=len(src))
    for i in range(len(src)):
        result.append(src[i])
    return result^


def simple_hash(var msg: String) -> UInt64:
    """FNV-1a hash of a string — used to deduplicate crash signatures."""
    var h: UInt64 = 0xCBF29CE484222325
    var b = msg.as_bytes()
    for i in range(len(b)):
        h = h ^ UInt64(b[i])
        h = h * 0x100000001B3
    return h


def _be_u16(v: UInt16) -> List[UInt8]:
    var b = List[UInt8]()
    b.append(UInt8((v >> 8) & 0xFF))
    b.append(UInt8(v & 0xFF))
    return b^


def _be_u32(v: UInt32) -> List[UInt8]:
    var b = List[UInt8]()
    b.append(UInt8((v >> 24) & 0xFF))
    b.append(UInt8((v >> 16) & 0xFF))
    b.append(UInt8((v >> 8) & 0xFF))
    b.append(UInt8(v & 0xFF))
    return b^


def _be_u64(v: UInt64) -> List[UInt8]:
    var b = List[UInt8]()
    for shift in [UInt64(56), UInt64(48), UInt64(40), UInt64(32), UInt64(24), UInt64(16), UInt64(8), UInt64(0)]:
        b.append(UInt8((v >> shift) & 0xFF))
    return b^


def _longstr(var s: String) -> List[UInt8]:
    """AMQP long-string: 4-byte BE length + bytes."""
    var sb = s.as_bytes()
    var out = _be_u32(UInt32(len(sb)))
    for i in range(len(sb)):
        out.append(sb[i])
    return out^


def _append_shortstr(mut b: List[UInt8], var s: String):
    var sb = s.as_bytes()
    b.append(UInt8(len(sb)))
    for i in range(len(sb)):
        b.append(sb[i])


def _field(mut body: List[UInt8], var key: String, t: UInt8, var val: List[UInt8]):
    """One field-table entry: shortstr key + type octet + value bytes."""
    _append_shortstr(body, key^)
    body.append(t)
    for i in range(len(val)):
        body.append(val[i])


def _wrap_table(var body: List[UInt8]) -> List[UInt8]:
    """Prefix a field-table body with its 4-byte BE length."""
    var out = _be_u32(UInt32(len(body)))
    for i in range(len(body)):
        out.append(body[i])
    return out^


# ---- seed builders ----

def build_flat_table() raises -> List[UInt8]:
    """A valid table with the three DECODED types (string/int/bool)."""
    var ft = FieldTable()
    ft.set_string("alpha", "hello")
    ft.set_int("beta", 12345)
    ft.set_bool("gamma", True)
    ft.set_string("delta", "")
    ft.set_int("neg", -1)
    ft.set_bool("off", False)
    return ft.to_bytes()


def build_all_types_body() -> List[UInt8]:
    """Body exercising every AMQP 0-9-1 field type octet (edge types included).

    The reader only DECODES S/I/t; the remaining type octets are unknown value
    markers that must terminate the field scan cleanly (never crash).
    """
    var body = List[UInt8]()

    var b_t = List[UInt8]()
    b_t.append(1)
    _field(body, "bool", UInt8(116), b_t^)  # 't'

    var b_i8 = List[UInt8]()
    b_i8.append(0x80)
    _field(body, "int8", UInt8(98), b_i8^)  # 'b'

    var b_u8 = List[UInt8]()
    b_u8.append(0xFF)
    _field(body, "uint8", UInt8(66), b_u8^)  # 'B'

    _field(body, "int16", UInt8(115), _be_u16(0xFFFF))  # 's'
    _field(body, "uint16", UInt8(117), _be_u16(0x1234))  # 'u'
    _field(body, "int32", UInt8(73), _be_u32(0xFFFFFFFF))  # 'I'
    _field(body, "uint32", UInt8(105), _be_u32(0xDEADBEEF))  # 'i'
    _field(body, "int64", UInt8(108), _be_u64(0xFFFFFFFFFFFFFFFF))  # 'l'

    var b_f = List[UInt8]()
    b_f.append(0x7F)
    b_f.append(0x80)
    b_f.append(0x00)
    b_f.append(0x01)
    _field(body, "float", UInt8(102), b_f^)  # 'f'

    _field(body, "double", UInt8(100), _be_u64(0x400921FB54442D18))  # 'd'

    var b_dec = List[UInt8]()
    b_dec.append(2)  # scale
    for i in range(4):
        b_dec.append(0xAB)
    _field(body, "decimal", UInt8(68), b_dec^)  # 'D'

    _field(body, "longstr", UInt8(83), _longstr("field-table-string"))  # 'S'

    var arr_body = List[UInt8]()
    _field(arr_body, "e0", UInt8(116), _one_byte(1))
    _field(arr_body, "e1", UInt8(83), _longstr("x"))
    _field(body, "array", UInt8(65), _wrap_table(arr_body^))  # 'A' (len-prefixed)

    var nested_inner = List[UInt8]()
    _field(nested_inner, "k", UInt8(83), _longstr("v"))
    _field(body, "table", UInt8(70), _wrap_table(nested_inner^))  # 'F'

    _field(body, "stamp", UInt8(84), _be_u64(0x0000018A00000000))  # 'T'

    var b_void = List[UInt8]()
    _field(body, "void", UInt8(86), b_void^)  # 'V'

    return body^


def _one_byte(v: UInt8) -> List[UInt8]:
    var b = List[UInt8]()
    b.append(v)
    return b^


def build_nested_table(depth: Int) -> List[UInt8]:
    """A table nested `depth` levels deep (recursion-bound probe; depth 12)."""
    var inner = List[UInt8]()
    _field(inner, "leaf", UInt8(83), _longstr("leaf-value"))
    var current = _wrap_table(inner^)
    for _ in range(depth):
        var body = List[UInt8]()
        _field(body, "n", UInt8(70), current^)
        current = _wrap_table(body^)
    return current^


def build_huge_declared() -> List[UInt8]:
    """A declared body length of 0xFFFFFFFF with NO body (allocation bound)."""
    return _be_u32(UInt32(0xFFFFFFFF))


def build_huge_declared_body() -> List[UInt8]:
    """A 0xFFFFFFFF declared length with a short, real body after it."""
    var out = _be_u32(UInt32(0xFFFFFFFF))
    for i in range(16):
        out.append(UInt8(0x40 + (i & 0x0F)))
    return out^


def build_seed_table(idx: Int, mut lcg: LCG) raises -> List[UInt8]:
    """Return one of 7 seed tables by index."""
    if idx == 0:
        return build_flat_table()
    elif idx == 1:
        return _wrap_table(build_all_types_body())
    elif idx == 2:
        return build_nested_table(12)
    elif idx == 3:
        return build_huge_declared()
    elif idx == 4:
        return build_huge_declared_body()
    elif idx == 5:
        return build_garbage(lcg.next(), 8)
    else:
        return List[UInt8]()


def build_garbage(seed_val: UInt32, count: Int) -> List[UInt8]:
    """Generate `count` garbage bytes from a seed."""
    var g = LCG(seed_val)
    var data = List[UInt8](capacity=count)
    for _ in range(count):
        data.append(UInt8(g.next() & 0xFF))
    return data^


# ---- mutation strategies ----

def mutate_bit_flip(mut data: List[UInt8], mut lcg: LCG):
    if len(data) == 0:
        return
    var pos = lcg.next_range(0, len(data) - 1)
    var bit = lcg.next_range(0, 7)
    data[pos] = data[pos] ^ (UInt8(1) << UInt8(bit))


def mutate_byte_replace(mut data: List[UInt8], mut lcg: LCG):
    if len(data) == 0:
        return
    var count = lcg.next_range(1, min(3, len(data)))
    for _ in range(count):
        var pos = lcg.next_range(0, len(data) - 1)
        var val = lcg.next_range(0, 1)
        data[pos] = UInt8(0) if val == 0 else UInt8(0xFF)


def mutate_truncate(mut data: List[UInt8], mut lcg: LCG):
    if len(data) <= 1:
        return
    var cut = lcg.next_range(1, len(data) - 1)
    var result = List[UInt8](capacity=cut)
    for i in range(cut):
        result.append(data[i])
    data = result^


def mutate_duplicate(mut data: List[UInt8], mut lcg: LCG):
    if len(data) == 0:
        return
    var start = lcg.next_range(0, len(data) - 1)
    var seg_len = lcg.next_range(1, min(4, len(data) - start))
    var result = List[UInt8](capacity=len(data) + seg_len)
    for i in range(start):
        result.append(data[i])
    for i in range(start, start + seg_len):
        result.append(data[i])
    for i in range(start, start + seg_len):
        result.append(data[i])
    for i in range(start + seg_len, len(data)):
        result.append(data[i])
    data = result^


def apply_mutation(mut data: List[UInt8], mut lcg: LCG, mut_type: Int):
    if mut_type == 0:
        mutate_bit_flip(data, lcg)
    elif mut_type == 1:
        mutate_byte_replace(data, lcg)
    elif mut_type == 2:
        mutate_truncate(data, lcg)
    elif mut_type == 3:
        mutate_duplicate(data, lcg)


# ---- main ----

def main() raises:
    var lcg = LCG(UInt32(0x5EEDF00D))
    var seen_sigs = Dict[UInt64, Int]()
    var sig_keys = List[UInt64]()

    var iterations = resolve_iters("HYRXMQ_FUZZ_ITERS", 10000)
    if iterations < 0:
        iterations = 0
    var exceptions = 0
    var decoded_ok = 0

    for _ in range(iterations):
        # pick + build a seed table
        var seed_idx = lcg.next_range(0, 6)
        var data = build_seed_table(seed_idx, lcg)

        # pick + apply one mutation
        var mut_type = lcg.next_range(0, 3)
        apply_mutation(data, lcg, mut_type)

        var raised = False
        var exc_msg = String()

        # reader 1: the in-memory decoder (borrows the bytes).
        try:
            _ = FieldTable.from_bytes(data)
        except e:
            raised = True
            exc_msg = String(e)

        # reader 2: the frame-argument decoder (takes an owned copy).
        try:
            var br = ByteReader(list_copy(data))
            _ = br.read_table()
        except e:
            raised = True
            exc_msg = String(e)

        if raised:
            exceptions += 1
            var sig = simple_hash(exc_msg)
            if sig in seen_sigs:
                seen_sigs[sig] = seen_sigs[sig] + 1
            else:
                seen_sigs[sig] = 1
                sig_keys.append(sig)
        else:
            decoded_ok += 1

    var unique_signatures = len(sig_keys)

    print("===== FIELD TABLE FUZZ SUMMARY =====")
    print("iterations: " + String(iterations))
    print("exceptions: " + String(exceptions))
    print("clean_decodes: " + String(decoded_ok))
    print("unique_signatures: " + String(unique_signatures))
    print("===== END FUZZ =====")

    check(
        exceptions + decoded_ok == iterations,
        "every mutant produced a safe outcome (decode or caught error)",
    )

    # Reaching this point proves the process survived all mutants.
    check(True, "process survived " + String(iterations) + " field-table fuzz iterations")
    print("FIELD_TABLE_FUZZ_TEST=PASS")
