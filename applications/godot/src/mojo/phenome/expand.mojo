# Reference expander (milestone_0010 Sprint 01, R5/R6) — DISCRETE derivation
# only: (grammar, variant_seed, stage, traits) → symbol string with
# integer/rational parameters. Test-side conformance tool: NEVER called in
# the sim tick path (no import from sim/* at runtime; only tests and the
# golden generator use it — expansion cost is out of every tick budget).
#
# Grammar data is SINGLE-SOURCED in godot/data/phenome_grammars.json
# (AP-23): parse_grammars(text) consumes the file; this module invents no
# production, no depth and no modulation value of its own. Cross-language
# conformance axis = this discrete derivation (AP-24: integer/rational
# symbols, never float geometry — the renderer expander must reproduce the
# same strings).
#
# Derivation semantics (lib/401_Morphology/Procedural; JSON `semantics`):
#   depth = stage_depths[stage]; start from the axiom (variant_seed enters
#   as an axiom-parameter jitter — declared grammar variability per
#   Procedural §1.6), then exactly `depth` simultaneous (parallel,
#   context-free) replacement steps; modules without a production for their
#   name persist (stationary). Params are exact rationals throughout.
#
# Determinism: pure functions of (grammar text, inputs) — run-twice
# identical by construction (invariant 2 / INV-018, AP-20).

from std.collections import List

from materials.json import (
    JSON_NUMBER,
    JSON_ARRAY,
    JSON_OBJECT,
    JsonValue,
    parse_json,
)
from sim.parameters import PHENOME_EXPAND_MAX_MODULES, STAGE_MAX
from sim.phenome import trait_quantize

# Expression node kinds (JSON `expr` grammar — see parse_expr).
comptime EXPR_CONST: Int = 0  # bare number → integer constant
comptime EXPR_PAIR: Int = 1  # [num, den] → rational literal
comptime EXPR_REF: Int = 2  # {"ref": <lhs param>}
comptime EXPR_PARAM: Int = 3  # {"param": <grammar param>}


# ---------------------------------------------------------------------------
# Exact rational arithmetic (AP-24: integer-exact conformance axis)
# ---------------------------------------------------------------------------


def _gcd(a: Int, b: Int) -> Int:
    var x = a
    if x < 0:
        x = -x
    var y = b
    if y < 0:
        y = -y
    while y != 0:
        var t = x % y
        x = y
        y = t
    return x


struct Rat(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Exact rational num/den (den > 0, reduced). All derivation parameters
    live here — never floats (AP-24)."""

    var num: Int
    var den: Int

    def __init__(out self, n: Int, d: Int):
        var dd = d
        if dd == 0:
            dd = 1  # defensive; callers validate real divisors at parse time
        var nn = n
        if dd < 0:
            nn = -nn
            dd = -dd
        var g = _gcd(nn, dd)
        if g > 1:
            nn = nn // g
            dd = dd // g
        self.num = nn
        self.den = dd

    def __deinit__(deinit self):
        pass


def rat_add(a: Rat, b: Rat) -> Rat:
    """a + b with cross-reduction (intermediates stay small)."""
    var g = _gcd(a.den, b.den)
    var da = a.den // g
    var db = b.den // g
    return Rat(a.num * db + b.num * da, da * b.den)


def rat_mul(a: Rat, b: Rat) -> Rat:
    """a · b with cross-cancellation before multiplying (overflow guard)."""
    var g1 = _gcd(a.num, b.den)
    var g2 = _gcd(b.num, a.den)
    return Rat((a.num // g1) * (b.num // g2), (a.den // g2) * (b.den // g1))


def rat_div(a: Rat, b: Rat) -> Rat:
    """a / b (b ≠ 0 — callers guard)."""
    return rat_mul(a, Rat(b.den, b.num))


def rat_to_string(r: Rat) -> String:
    if r.den == 1:
        return String(r.num)
    return String(r.num) + "/" + String(r.den)


# ---------------------------------------------------------------------------
# Grammar model (mirrors phenome_grammars.json 1:1)
# ---------------------------------------------------------------------------


struct Expr(Copyable, Movable, Deinitable):
    """Parameter expression tree (JSON `expr`): base (const / rational /
    ref / param) plus optional applied `mul` and `div` scales —
    value = base * mul / div in that order (JSON `semantics.expression`)."""

    var kind: Int
    var i0: Int  # EXPR_CONST value | EXPR_PAIR numerator
    var i1: Int  # EXPR_PAIR denominator
    var name: String  # EXPR_REF / EXPR_PARAM binding name
    var mul: List[Expr]
    var div: List[Expr]

    def __init__(out self):
        self.kind = EXPR_CONST
        self.i0 = 0
        self.i1 = 1
        self.name = ""
        self.mul = List[Expr]()
        self.div = List[Expr]()

    def __deinit__(deinit self):
        pass


struct ModTpl(Copyable, Movable, Deinitable):
    """Module template: symbol name + parameter expressions (axiom element
    or production-rhs element)."""

    var m: String
    var exprs: List[Expr]

    def __init__(out self):
        self.m = ""
        self.exprs = List[Expr]()

    def __deinit__(deinit self):
        pass


struct Prod(Copyable, Movable, Deinitable):
    """Context-free parametric production lhs(params) → rhs."""

    var lhs: String
    var param_names: List[String]
    var rhs: List[ModTpl]

    def __init__(out self):
        self.lhs = ""
        self.param_names = List[String]()
        self.rhs = List[ModTpl]()

    def __deinit__(deinit self):
        pass


struct Grammar(Copyable, Movable, Deinitable):
    """One species' parsed grammar (JSON `species[]` entry + document-level
    trait vocabulary). Data only — no semantics invented here."""

    var species_id: Int
    var grammar_id: String
    var axiom: List[ModTpl]
    var axiom_jitter_mod: Int
    var productions: List[Prod]
    var stationary: List[String]
    var stage_depths: List[Int]
    var maturity: List[Int]
    var param_names: List[String]
    var param_values: List[Rat]
    var trait_names: List[String]  # document `traits` order (= trait vector)
    var mod_trait_idx: List[Int]  # modulation entry → trait_names index
    var mod_params: List[String]  # modulation entry → target param name
    var mod_deltas: List[Int]  # modulation entry → integer delta
    var tropism_name: String
    var tropism_param: String
    var tropism_coef_milli: Int
    var tropism_dir: List[Int]

    def __init__(out self):
        self.species_id = 0
        self.grammar_id = ""
        self.axiom = List[ModTpl]()
        self.axiom_jitter_mod = 1
        self.productions = List[Prod]()
        self.stationary = List[String]()
        self.stage_depths = List[Int]()
        self.maturity = List[Int]()
        self.param_names = List[String]()
        self.param_values = List[Rat]()
        self.trait_names = List[String]()
        self.mod_trait_idx = List[Int]()
        self.mod_params = List[String]()
        self.mod_deltas = List[Int]()
        self.tropism_name = ""
        self.tropism_param = ""
        self.tropism_coef_milli = 0
        self.tropism_dir = List[Int]()

    def __deinit__(deinit self):
        pass


struct DerivModule(Copyable, Movable, Deinitable):
    """One derivation symbol instance: name + exact rational params."""

    var name: String
    var params: List[Rat]

    def __init__(out self):
        self.name = ""
        self.params = List[Rat]()

    def __deinit__(deinit self):
        pass


struct EvalCtx(Copyable, Movable, Deinitable):
    """Expression bindings: production lhs args (arg_names/args) + grammar
    params (param_names/params)."""

    var arg_names: List[String]
    var args: List[Rat]
    var param_names: List[String]
    var params: List[Rat]

    def __init__(out self):
        self.arg_names = List[String]()
        self.args = List[Rat]()
        self.param_names = List[String]()
        self.params = List[Rat]()

    def __deinit__(deinit self):
        pass


# ---------------------------------------------------------------------------
# JSON → Grammar
# ---------------------------------------------------------------------------


def parse_expr(v: JsonValue) raises -> Expr:
    """JSON `expr` → Expr tree (see JSON `semantics.expression`)."""
    var e = Expr()
    if v.kind == JSON_NUMBER:
        var f = v.as_float()
        var n = v.as_int()
        if Float64(n) != f:
            raise Error("phenome: non-integer constant " + String(f))
        e.kind = EXPR_CONST
        e.i0 = n
        e.i1 = 1
        return e^
    if v.kind == JSON_ARRAY:
        if len(v.items) != 2:
            raise Error("phenome: rational literal must be [num, den]")
        var n0 = v.items[0].as_int()
        var d0 = v.items[1].as_int()
        if d0 == 0:
            raise Error("phenome: zero denominator in rational literal")
        e.kind = EXPR_PAIR
        e.i0 = n0
        e.i1 = d0
        return e^
    if v.kind == JSON_OBJECT:
        if v.has("ref"):
            e.kind = EXPR_REF
            e.name = v.get("ref").as_string()
        elif v.has("param"):
            e.kind = EXPR_PARAM
            e.name = v.get("param").as_string()
        else:
            raise Error("phenome: expression object needs ref or param")
        if v.has("mul"):
            e.mul.append(parse_expr(v.get("mul")))
        if v.has("div"):
            e.div.append(parse_expr(v.get("div")))
        if e.name.byte_length() == 0:
            raise Error("phenome: empty binding name")
        return e^
    raise Error("phenome: unsupported expression form")


def _parse_mod_tpl(v: JsonValue) raises -> ModTpl:
    if not v.is_object():
        raise Error("phenome: module template must be an object")
    var t = ModTpl()
    t.m = v.get("m").as_string()
    if t.m.byte_length() == 0:
        raise Error("phenome: empty module name")
    if v.has("p"):
        var ps = v.get("p")
        if not ps.is_array():
            raise Error("phenome: module params must be an array")
        for i in range(len(ps.items)):
            t.exprs.append(parse_expr(ps.at(i)))
    return t^


def _parse_prod(v: JsonValue) raises -> Prod:
    if not v.is_object():
        raise Error("phenome: production must be an object")
    var p = Prod()
    p.lhs = v.get("lhs").as_string()
    var ps = v.get("params")
    if not ps.is_array():
        raise Error("phenome: production params must be an array")
    for i in range(len(ps.items)):
        p.param_names.append(ps.at(i).as_string())
    var rhs = v.get("rhs")
    if not rhs.is_array() or len(rhs.items) == 0:
        raise Error("phenome: production rhs must be a non-empty array")
    for i in range(len(rhs.items)):
        p.rhs.append(_parse_mod_tpl(rhs.at(i)))
    return p^


def parse_grammars(text: String) raises -> List[Grammar]:
    """Parse phenome_grammars.json text → Grammars (AP-23: the JSON file is
    the only grammar vocabulary; this function only reads it). Takes TEXT —
    callers resolve any file path themselves (keeps this module free of
    filesystem/scene assumptions). Raises on structural violations:
    stage_max == STAGE_MAX, 16-entry stage tables, monotone depth/maturity
    tables with maturity[0] == 0, known trait keys, integer params."""
    var doc = parse_json(text)
    if doc.get("format").as_string() != "scr.phenome_grammars/1":
        raise Error("phenome: unexpected grammar file format")
    var stage_max = doc.get("stage_max").as_int()
    if stage_max != STAGE_MAX:
        raise Error("phenome: stage_max must equal STAGE_MAX")
    var trait_names = List[String]()
    var traits_v = doc.get("traits")
    if not traits_v.is_array() or len(traits_v.items) == 0:
        raise Error("phenome: traits vocabulary missing")
    for i in range(len(traits_v.items)):
        trait_names.append(traits_v.at(i).as_string())
    var species_v = doc.get("species")
    if not species_v.is_array() or len(species_v.items) == 0:
        raise Error("phenome: species array missing")
    var out = List[Grammar]()
    for si in range(len(species_v.items)):
        var e = species_v.at(si)
        var g = Grammar()
        for ti in range(len(trait_names)):
            g.trait_names.append(trait_names[ti])
        g.species_id = e.get("species_id").as_int()
        g.grammar_id = e.get("grammar_id").as_string()
        g.axiom_jitter_mod = e.get("axiom_jitter_mod").as_int()
        if g.axiom_jitter_mod < 1:
            raise Error("phenome: axiom_jitter_mod must be ≥ 1")
        var axiom_v = e.get("axiom")
        if not axiom_v.is_array() or len(axiom_v.items) == 0:
            raise Error("phenome: axiom missing")
        for i in range(len(axiom_v.items)):
            g.axiom.append(_parse_mod_tpl(axiom_v.at(i)))
        var prods_v = e.get("productions")
        if not prods_v.is_array():
            raise Error("phenome: productions missing")
        for i in range(len(prods_v.items)):
            g.productions.append(_parse_prod(prods_v.at(i)))
        var stat_v = e.get("stationary")
        if not stat_v.is_array():
            raise Error("phenome: stationary set missing")
        for i in range(len(stat_v.items)):
            g.stationary.append(stat_v.at(i).as_string())
        var depths_v = e.get("stage_depths")
        var mat_v = e.get("maturity")
        if (
            not depths_v.is_array()
            or not mat_v.is_array()
            or len(depths_v.items) != stage_max + 1
            or len(mat_v.items) != stage_max + 1
        ):
            raise Error("phenome: stage tables must have stage_max + 1 rows")
        for i in range(len(depths_v.items)):
            var d = depths_v.at(i).as_int()
            if i > 0 and d < g.stage_depths[i - 1]:
                raise Error("phenome: stage_depths must be non-decreasing")
            g.stage_depths.append(d)
        for i in range(len(mat_v.items)):
            var m = mat_v.at(i).as_int()
            if i == 0 and m != 0:
                raise Error("phenome: maturity[0] must be 0")
            if i > 0 and m <= g.maturity[i - 1]:
                raise Error("phenome: maturity table must be strictly increasing")
            g.maturity.append(m)
        var params_v = e.get("params")
        if not params_v.is_object():
            raise Error("phenome: params object missing")
        for ki in range(len(params_v.keys)):
            g.param_names.append(params_v.keys[ki])
            g.param_values.append(Rat(params_v.items[ki].as_int(), 1))
        var mod_v = e.get("modulation")
        if not mod_v.is_object():
            raise Error("phenome: modulation object missing")
        for ki in range(len(mod_v.keys)):
            var key = mod_v.keys[ki]
            var tidx = -1
            for ti in range(len(g.trait_names)):
                if g.trait_names[ti] == key:
                    tidx = ti
            if tidx < 0:
                raise Error("phenome: modulation trait not in vocabulary: " + key)
            var mv = mod_v.get(key)
            g.mod_trait_idx.append(tidx)
            g.mod_params.append(mv.get("param").as_string())
            g.mod_deltas.append(mv.get("delta").as_int())
        var tr = e.get("tropism")
        g.tropism_name = tr.get("name").as_string()
        g.tropism_param = tr.get("param").as_string()
        g.tropism_coef_milli = tr.get("coefficient_milli").as_int()
        var dir_v = tr.get("direction")
        for i in range(len(dir_v.items)):
            g.tropism_dir.append(dir_v.at(i).as_int())
        out.append(g^)
    return out^


def find_grammar(grammars: List[Grammar], grammar_id: String) raises -> Int:
    """Index of `grammar_id` in the parsed list (raises when absent)."""
    for i in range(len(grammars)):
        if grammars[i].grammar_id == grammar_id:
            return i
    raise Error("phenome: unknown grammar_id " + grammar_id)


# ---------------------------------------------------------------------------
# Evaluation
# ---------------------------------------------------------------------------


def _lookup(name: String, ctx: EvalCtx) raises -> Rat:
    for i in range(len(ctx.arg_names)):
        if ctx.arg_names[i] == name:
            return ctx.args[i]
    for i in range(len(ctx.param_names)):
        if ctx.param_names[i] == name:
            return ctx.params[i]
    raise Error("phenome: unbound expression name " + name)


def eval_expr(e: Expr, ctx: EvalCtx) raises -> Rat:
    """Evaluate one expression under the bindings — exact rational result."""
    var base: Rat
    if e.kind == EXPR_CONST:
        base = Rat(e.i0, 1)
    elif e.kind == EXPR_PAIR:
        base = Rat(e.i0, e.i1)
    elif e.kind == EXPR_REF or e.kind == EXPR_PARAM:
        base = _lookup(e.name, ctx)
    else:
        raise Error("phenome: bad expression kind " + String(e.kind))
    for i in range(len(e.mul)):
        base = rat_mul(base, eval_expr(e.mul[i], ctx))
    for i in range(len(e.div)):
        var d = eval_expr(e.div[i], ctx)
        if d.num == 0:
            raise Error("phenome: division by zero")
        base = rat_div(base, d)
    return base


def _grammar_params(g: Grammar, trait_millis: List[Int]) raises -> EvalCtx:
    """Base params + trait modulation folded in (JSON `modulation` map —
    R3 exactness: modulated = base·1000 + delta·trait_milli over 1000).
    Returns a ctx holding ONLY the grammar-param bindings."""
    if len(trait_millis) != len(g.trait_names):
        raise Error("phenome: trait vector width mismatch")
    var ctx = EvalCtx()
    for i in range(len(g.param_names)):
        var milli = g.param_values[i].num * 1000  # base params are integers
        for j in range(len(g.mod_params)):
            if g.mod_params[j] == g.param_names[i]:
                var tm = trait_millis[g.mod_trait_idx[j]]
                if tm < 0:
                    tm = 0
                if tm > 1000:
                    tm = 1000
                milli += g.mod_deltas[j] * tm
        ctx.param_names.append(g.param_names[i])
        ctx.params.append(Rat(milli, 1000))
    return ctx^


def _find_production(g: Grammar, name: String) -> Int:
    """Index of the production with lhs == name, or −1 (stationary)."""
    for i in range(len(g.productions)):
        if g.productions[i].lhs == name:
            return i
    return -1


def _bind_ctx(prod: Prod, args: List[Rat], pctx: EvalCtx) -> EvalCtx:
    """Per-module evaluation context: lhs args + shared grammar params."""
    var ctx = EvalCtx()
    for i in range(len(prod.param_names)):
        ctx.arg_names.append(prod.param_names[i])
        if i < len(args):
            ctx.args.append(args[i])
        else:
            ctx.args.append(Rat(0, 1))
    for i in range(len(pctx.param_names)):
        ctx.param_names.append(pctx.param_names[i])
        ctx.params.append(pctx.params[i])
    return ctx^


# ---------------------------------------------------------------------------
# Expansion (R5/R6)
# ---------------------------------------------------------------------------


def expand_derivation(
    g: Grammar, variant_seed_value: UInt32, stage: Int, trait_millis: List[Int]
) raises -> List[DerivModule]:
    """REFERENCE expansion — the discrete derivation for
    (grammar, variant_seed, stage, traits) (invariant 2). Deterministic,
    run-twice identical; NEVER used by the sim tick path (tests only).
    Module count is bounded by PHENOME_EXPAND_MAX_MODULES (a violation
    raises — grammar authoring error, not a runtime state)."""
    if stage < 0 or stage >= len(g.stage_depths):
        raise Error("phenome: stage out of range")
    var depth = g.stage_depths[stage]
    var pctx = _grammar_params(g, trait_millis)

    # Axiom: evaluate parameter expressions (empty lhs-arg bindings).
    var mods = List[DerivModule]()
    for ti in range(len(g.axiom)):
        var tpl = g.axiom[ti].copy()
        var ctx = _bind_ctx_prod_placeholder(tpl, pctx)
        var dm = DerivModule()
        dm.name = tpl.m
        for ei in range(len(tpl.exprs)):
            dm.params.append(eval_expr(tpl.exprs[ei], ctx))
        mods.append(dm^)

    # variant_seed enters the derivation as axiom-parameter jitter
    # (Procedural §1.6 declared variability — the ONLY seed use here).
    if len(mods) > 0 and len(mods[0].params) > 0 and g.axiom_jitter_mod > 1:
        var jitter = Int(variant_seed_value % UInt32(g.axiom_jitter_mod))
        if jitter != 0:
            mods[0].params[0] = rat_add(mods[0].params[0], Rat(jitter, 1))

    # Exactly `depth` simultaneous replacement steps (parallel rewrite).
    for _ in range(depth):
        var nxt = List[DerivModule]()
        for mi in range(len(mods)):
            var dm = mods[mi].copy()
            var pi = _find_production(g, dm.name)
            if pi < 0:
                nxt.append(dm^)  # stationary / terminal symbol persists
            else:
                var prod = g.productions[pi].copy()
                var ctx = _bind_ctx(prod, dm.params, pctx)
                for ri in range(len(prod.rhs)):
                    var tpl = prod.rhs[ri].copy()
                    var out_m = DerivModule()
                    out_m.name = tpl.m
                    for ei in range(len(tpl.exprs)):
                        out_m.params.append(eval_expr(tpl.exprs[ei], ctx))
                    nxt.append(out_m^)
        mods = nxt^
        if len(mods) > PHENOME_EXPAND_MAX_MODULES:
            raise Error("phenome: derivation exceeds module cap")
    return mods^


def _bind_ctx_prod_placeholder(tpl: ModTpl, pctx: EvalCtx) -> EvalCtx:
    """Axiom-element context: no lhs params, shared grammar params."""
    var ctx = EvalCtx()
    for i in range(len(pctx.param_names)):
        ctx.param_names.append(pctx.param_names[i])
        ctx.params.append(pctx.params[i])
    return ctx^


def expand_derivation_f64(
    g: Grammar, variant_seed_value: UInt32, stage: Int, ash: Float64, drought: Float64
) raises -> List[DerivModule]:
    """Convenience entry: quantizes the 0009 trait vector (index 0 = ash,
    1 = drought — JSON `traits` order, validated here) and expands."""
    if len(g.trait_names) != 2:
        raise Error("phenome: expected a two-trait vocabulary")
    if g.trait_names[0] != "ash_tolerance" or g.trait_names[1] != "drought_tolerance":
        raise Error("phenome: trait order must be ash, drought (0009 vector)")
    var millis = List[Int]()
    millis.append(trait_quantize(ash))
    millis.append(trait_quantize(drought))
    return expand_derivation(g, variant_seed_value, stage, millis)


def render_derivation(mods: List[DerivModule]) -> String:
    """Discrete conformance string: tokens separated by single spaces,
    params in parentheses joined by commas (rationals as `num/den`).
    This is the AP-24 conformance axis both implementations must match."""
    var out = String()
    for i in range(len(mods)):
        if i > 0:
            out = out + " "
        out = out + mods[i].name
        if len(mods[i].params) > 0:
            out = out + "("
            for pi in range(len(mods[i].params)):
                if pi > 0:
                    out = out + ","
                out = out + rat_to_string(mods[i].params[pi])
            out = out + ")"
    return out^


def derivation_module_count(mods: List[DerivModule]) -> Int:
    return len(mods)


def grammar_depth(g: Grammar, stage: Int) raises -> Int:
    """Stage → iteration depth (R6 table lookup; 0 ≤ stage ≤ STAGE_MAX)."""
    if stage < 0 or stage >= len(g.stage_depths):
        raise Error("phenome: stage out of range")
    return g.stage_depths[stage]
