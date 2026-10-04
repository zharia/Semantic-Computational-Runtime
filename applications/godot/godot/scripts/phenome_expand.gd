# phenome_expand.gd — milestone 0010 Sprint 03: pure turtle L-system
# expander (spec R1/R2/R5/R6/R7; invariants 1/2/3/4/5).
#
# Pure function: (grammar, variant_seed, stage, traits[, lod depth reduction])
# => identical discrete derivation + identical ArrayMesh geometry, run twice.
# Grammar vocabulary is SINGLE-SOURCED in res://data/phenome_grammars.json
# (AP-23): this script parses productions/params/modulation/tropism from that
# file and hardcodes NO production, NO depth table and NO modulation value.
# The reference expander src/mojo/phenome/expand.mojo consumes the same JSON —
# conformance axis = the discrete symbol string (AP-24: integer/rational only,
# never float geometry).
#
# Derivation semantics (lib/401_Morphology/Procedural §1.4; JSON `semantics`):
#   depth = stage_depths[stage]; axiom (variant_seed folds into axiom
#   parameter 0 as jitter = seed mod axiom_jitter_mod — declared grammar
#   variability, Procedural §1.6); then exactly `depth` simultaneous
#   (parallel, context-free) replacement steps; modules with no production
#   persist (stationary). Parameters are exact rationals throughout
#   (Vector2i = num/den, reduced). The discrete derivation is produced as a
#   side-output (render()) for conformance — same format as
#   tests/fixtures/phenome/goldens.txt.
#
# LOD (R4): depth_reduction 0/1/2 lowers the iteration depth for far bands
# (mid = depth-1, far = depth-2, floor 1; a depth-0 stage stays 0). LOD is
# presentation only — chosen at render, never stored anywhere else.
#
# Tropism (JSON `tropism`, Procedural §1.7): the reference derivation does
# NOT consume it (JSON semantics statement) — this renderer expander does:
# after every drawn segment the turtle heading rotates toward the declared
# direction by coefficient_milli/1000 rad per world-unit of segment length
# (display mapping; the conformance axis is unaffected).
#
# ---------------------------------------------------------------------------
# Wind-weight vertex channel (R5, AP-19): per-vertex flexibility weight is
# stored in the VERTEX COLOR channel (r = g = b = weight, a = 1) —
# COLOR is otherwise unused (albedo comes from the shader uniform, so the
# channel cannot leak into shading). Trunk/axis segments bake ≈ 0.1 (rigid),
# fronds/leaves bake 1.0 (flexible). flora_wing.gdshader reads COLOR.r and
# scales the TIME-based sway amplitude by it. Sway phase stays TIME-driven
# display-only; nothing here is state, nothing enters the wire.
# ---------------------------------------------------------------------------
#
# Float geometry constants below (length unit, radii, branch angles) are
# REPRESENTATION choices only (MORPHOLOGY-INV-016): they shape the mesh, not
# the grammar. Determinism of geometry is per implementation (AP-24).
extends RefCounted

const MAX_MODULES := 65536

# --- representation constants (display only; not grammar semantics) ---------
const LENGTH_UNIT := 0.12          # world units per grammar length parameter
const STEM_RADIUS_SCALE := 0.006   # A(n) radius = n * scale
const STEM_RADIUS_MIN := 0.02
const STEM_RADIUS_MAX := 0.14
const TRUNK_RADIUS_SCALE := 0.02   # T(len, dens) radius = dens * scale
const TRUNK_RADIUS_MIN := 0.02
const TRUNK_RADIUS_MAX := 0.22
const FROND_LEN_SCALE := 0.7       # F(n): blade length = n * unit * scale
const FROND_WIDTH_SCALE := 0.3
const LEAF_SIZE_SCALE := 0.06      # L(p): leaf size = clamp(p * scale, ...)
const LEAF_SIZE_MIN := 0.06
const LEAF_SIZE_MAX := 0.9
const RING_SIDES := 5              # cylinder facets
const BRANCH_TILT_RAD := 0.62      # '[' tilts the heading off the parent
const BRANCH_ROLL_RAD := 2.399963229728653  # golden angle: sibling azimuth
const WIND_SEGMENT := 0.1          # trunk/axis flexibility
const WIND_LEAF := 1.0             # frond/leaf flexibility

# expression node kinds (JSON `semantics.expression`)
const EXPR_CONST := 0  # bare number
const EXPR_PAIR := 1   # [num, den] rational literal
const EXPR_REF := 2    # {"ref": <lhs param>}
const EXPR_PARAM := 3  # {"param": <grammar param>}

var grammars_by_species := {}  # int species_id -> grammar Dictionary
var grammars_by_id := {}       # String grammar_id -> grammar Dictionary


# ---------------------------------------------------------------------------
# Geometry builder (accumulates non-indexed triangles + wind-weight colors)
# ---------------------------------------------------------------------------

class Builder:
	extends RefCounted

	var verts := PackedVector3Array()
	var cols := PackedColorArray()

	func add_tri(a: Vector3, b: Vector3, c: Vector3, wind: float) -> void:
		verts.append(a)
		verts.append(b)
		verts.append(c)
		var col := Color(wind, wind, wind, 1.0)
		cols.append(col)
		cols.append(col)
		cols.append(col)

	func cylinder(p0: Vector3, p1: Vector3, r0: float, r1: float, wind: float) -> void:
		var d := p1 - p0
		var seg := d.length()
		if seg < 1e-5:
			return
		var axis := d / seg
		var ref := Vector3.RIGHT if absf(axis.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var u := axis.cross(ref).normalized()
		var v := axis.cross(u).normalized()
		var prev_b := Vector3.ZERO
		var prev_t := Vector3.ZERO
		for i in RING_SIDES + 1:
			var a := TAU * float(i) / float(RING_SIDES)
			var ca := cos(a)
			var sa := sin(a)
			var lateral := u * ca + v * sa
			var b := p0 + lateral * r0
			var t := p1 + lateral * r1
			if i > 0:
				add_tri(prev_b, b, t, wind)
				add_tri(prev_b, t, prev_t, wind)
			prev_b = b
			prev_t = t

	func quad(center: Vector3, axis_a: Vector3, axis_b: Vector3,
			half_a: float, half_b: float, wind: float) -> void:
		var p0 := center - axis_a * half_a - axis_b * half_b
		var p1 := center + axis_a * half_a - axis_b * half_b
		var p2 := center + axis_a * half_a + axis_b * half_b
		var p3 := center - axis_a * half_a + axis_b * half_b
		add_tri(p0, p1, p2, wind)
		add_tri(p0, p2, p3, wind)

	## Flat (per-face) normals — non-indexed triangles, faces in groups of 3.
	func to_mesh() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		if verts.size() < 3:
			return mesh
		var norms := PackedVector3Array()
		norms.resize(verts.size())
		var i := 0
		while i < verts.size():
			var a := verts[i]
			var b := verts[i + 1]
			var c := verts[i + 2]
			var nrm := (b - a).cross(c - a)
			if nrm.length_squared() > 1e-12:
				nrm = nrm.normalized()
			else:
				nrm = Vector3.UP
			norms[i] = nrm
			norms[i + 1] = nrm
			norms[i + 2] = nrm
			i += 3
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_COLOR] = cols
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


# ---------------------------------------------------------------------------
# Grammar parsing (JSON -> Dictionary; AP-23: JSON is the only vocabulary)
# ---------------------------------------------------------------------------

## Load + parse `path` (res:// or absolute). Returns true on success.
func load_grammars(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("phenome_expand: cannot open grammar file %s" % path)
		return false
	return parse_grammars(f.get_as_text())


func parse_grammars(text: String) -> bool:
	grammars_by_species.clear()
	grammars_by_id.clear()
	var doc: Variant = JSON.parse_string(text)
	if not (doc is Dictionary):
		push_error("phenome_expand: grammar file is not a JSON object")
		return false
	if String(doc.get("format", "")) != "scr.phenome_grammars/1":
		push_error("phenome_expand: unexpected grammar file format")
		return false
	if int(doc.get("stage_max", -1)) != 15:
		push_error("phenome_expand: stage_max must be 15")
		return false
	var traits_v: Variant = doc.get("traits")
	if not (traits_v is Array) or (traits_v as Array).is_empty():
		push_error("phenome_expand: traits vocabulary missing")
		return false
	var trait_names: Array = []
	for t in traits_v as Array:
		trait_names.append(String(t))
	var species_v: Variant = doc.get("species")
	if not (species_v is Array) or (species_v as Array).is_empty():
		push_error("phenome_expand: species array missing")
		return false
	for entry in species_v as Array:
		var g := _parse_species(entry, trait_names)
		if g.is_empty():
			return false
		grammars_by_species[int(g.species_id)] = g
		grammars_by_id[String(g.grammar_id)] = g
	return true


func _parse_species(e: Variant, trait_names: Array) -> Dictionary:
	var g := {}
	if not (e is Dictionary):
		push_error("phenome_expand: species entry not an object")
		return {}
	g.species_id = int(e.get("species_id", 0))
	g.grammar_id = String(e.get("grammar_id", ""))
	if g.species_id < 1 or g.grammar_id.is_empty():
		push_error("phenome_expand: species_id/grammar_id missing")
		return {}
	g.traits = trait_names.duplicate()
	g.jitter_mod = int(e.get("axiom_jitter_mod", 0))
	if g.jitter_mod < 1:
		push_error("phenome_expand: axiom_jitter_mod must be >= 1 (%s)" % g.grammar_id)
		return {}
	var axiom_v: Variant = e.get("axiom")
	if not (axiom_v is Array) or (axiom_v as Array).is_empty():
		push_error("phenome_expand: axiom missing (%s)" % g.grammar_id)
		return {}
	g.axiom = []
	for tpl in axiom_v as Array:
		var t := _parse_tpl(tpl)
		if t.is_empty():
			return {}
		g.axiom.append(t)
	var prods_v: Variant = e.get("productions")
	if not (prods_v is Array):
		push_error("phenome_expand: productions missing (%s)" % g.grammar_id)
		return {}
	g.prods = {}
	for p in prods_v as Array:
		if not (p is Dictionary):
			push_error("phenome_expand: production not an object (%s)" % g.grammar_id)
			return {}
		var lhs := String(p.get("lhs", ""))
		var params_v: Variant = p.get("params")
		var rhs_v: Variant = p.get("rhs")
		if lhs.is_empty() or not (params_v is Array) \
				or not (rhs_v is Array) or (rhs_v as Array).is_empty():
			push_error("phenome_expand: malformed production (%s)" % g.grammar_id)
			return {}
		var rhs: Array = []
		for tpl in rhs_v as Array:
			var t := _parse_tpl(tpl)
			if t.is_empty():
				return {}
			rhs.append(t)
		var pnames: Array = []
		for pn in params_v as Array:
			pnames.append(String(pn))
		g.prods[lhs] = {"params": pnames, "rhs": rhs}
	var stat_v: Variant = e.get("stationary")
	if not (stat_v is Array):
		push_error("phenome_expand: stationary set missing (%s)" % g.grammar_id)
		return {}
	var depths_v: Variant = e.get("stage_depths")
	var mat_v: Variant = e.get("maturity")
	if not (depths_v is Array) or not (mat_v is Array) \
			or (depths_v as Array).size() != 16 or (mat_v as Array).size() != 16:
		push_error("phenome_expand: stage tables must have 16 rows (%s)" % g.grammar_id)
		return {}
	g.stage_depths = []
	var prev := -1
	for d in depths_v as Array:
		var di: Variant = _to_int(d)
		if di == null or int(di) < prev:
			push_error("phenome_expand: stage_depths must be non-decreasing (%s)" % g.grammar_id)
			return {}
		prev = int(di)
		g.stage_depths.append(int(di))
	prev = -1
	for m in mat_v as Array:
		var mi: Variant = _to_int(m)
		if mi == null or int(mi) <= prev:
			push_error("phenome_expand: maturity must strictly increase (%s)" % g.grammar_id)
			return {}
		prev = int(mi)
	if int((mat_v as Array)[0]) != 0:
		push_error("phenome_expand: maturity[0] must be 0 (%s)" % g.grammar_id)
		return {}
	var params_v: Variant = e.get("params")
	if not (params_v is Dictionary):
		push_error("phenome_expand: params object missing (%s)" % g.grammar_id)
		return {}
	g.params = {}
	for k in (params_v as Dictionary).keys():
		var pv: Variant = _to_int((params_v as Dictionary)[k])
		if pv == null:
			push_error("phenome_expand: grammar param must be an integer (%s)" % g.grammar_id)
			return {}
		g.params[String(k)] = int(pv)
	var mod_v: Variant = e.get("modulation")
	if not (mod_v is Dictionary):
		push_error("phenome_expand: modulation object missing (%s)" % g.grammar_id)
		return {}
	g.modulation = []
	for k in (mod_v as Dictionary).keys():
		var me: Variant = (mod_v as Dictionary)[k]
		if not (me is Dictionary):
			push_error("phenome_expand: modulation entry malformed (%s)" % g.grammar_id)
			return {}
		var tname := String(k)
		var tidx := trait_names.find(tname)
		if tidx < 0:
			push_error("phenome_expand: modulation trait not in vocabulary: %s" % tname)
			return {}
		var delta: Variant = _to_int(me.get("delta"))
		if delta == null:
			push_error("phenome_expand: modulation delta must be integer (%s)" % g.grammar_id)
			return {}
		g.modulation.append({
			"trait_idx": tidx,
			"param": String(me.get("param", "")),
			"delta": int(delta),
		})
	var tr: Variant = e.get("tropism")
	if not (tr is Dictionary):
		push_error("phenome_expand: tropism missing (%s)" % g.grammar_id)
		return {}
	var coef: Variant = _to_int(tr.get("coefficient_milli"))
	var dir_v: Variant = tr.get("direction")
	if coef == null or not (dir_v is Array) or (dir_v as Array).size() != 2:
		push_error("phenome_expand: tropism malformed (%s)" % g.grammar_id)
		return {}
	var d0: Variant = _to_int((dir_v as Array)[0])
	var d1: Variant = _to_int((dir_v as Array)[1])
	if d0 == null or d1 == null:
		push_error("phenome_expand: tropism direction must be integers (%s)" % g.grammar_id)
		return {}
	g.tropism = {
		"name": String(tr.get("name", "")),
		"param": String(tr.get("param", "")),
		"coef_milli": int(coef),
		"dir": Vector2(int(d0), int(d1)),
	}
	return g


func _parse_tpl(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		push_error("phenome_expand: module template must be an object")
		return {}
	var m := String((v as Dictionary).get("m", ""))
	if m.is_empty():
		push_error("phenome_expand: empty module name")
		return {}
	var exprs: Array = []
	var p_v: Variant = (v as Dictionary).get("p")
	if p_v != null:
		if not (p_v is Array):
			push_error("phenome_expand: module params must be an array")
			return {}
		for ev in p_v as Array:
			var e := _parse_expr(ev)
			if e.is_empty():
				return {}
			exprs.append(e)
	return {"m": m, "exprs": exprs}


static func _parse_expr(v: Variant) -> Dictionary:
	if v is int or v is float:
		var n: Variant = _to_int(v)
		if n == null:
			push_error("phenome_expand: non-integer expression constant %s" % str(v))
			return {}
		return {"k": EXPR_CONST, "i0": int(n), "i1": 1, "n": "", "mul": null, "div": null}
	if v is Array:
		if (v as Array).size() != 2:
			push_error("phenome_expand: rational literal must be [num, den]")
			return {}
		var rn: Variant = _to_int((v as Array)[0])
		var rd: Variant = _to_int((v as Array)[1])
		if rn == null or rd == null or int(rd) == 0:
			push_error("phenome_expand: bad rational literal")
			return {}
		return {"k": EXPR_PAIR, "i0": int(rn), "i1": int(rd), "n": "", "mul": null, "div": null}
	if v is Dictionary:
		var kind := -1
		var nm := ""
		if (v as Dictionary).has("ref"):
			kind = EXPR_REF
			nm = String((v as Dictionary)["ref"])
		elif (v as Dictionary).has("param"):
			kind = EXPR_PARAM
			nm = String((v as Dictionary)["param"])
		else:
			push_error("phenome_expand: expression object needs ref or param")
			return {}
		if nm.is_empty():
			push_error("phenome_expand: empty binding name")
			return {}
		var e := {"k": kind, "i0": 0, "i1": 1, "n": nm, "mul": null, "div": null}
		if (v as Dictionary).has("mul"):
			var mu := _parse_expr((v as Dictionary)["mul"])
			if mu.is_empty():
				return {}
			e.mul = mu
		if (v as Dictionary).has("div"):
			var dv := _parse_expr((v as Dictionary)["div"])
			if dv.is_empty():
				return {}
			e.div = dv
		return e
	push_error("phenome_expand: unsupported expression form %s" % str(v))
	return {}


## JSON numbers arrive as int or float; returns null when not an exact integer.
static func _to_int(v: Variant) -> Variant:
	if v is int:
		return int(v)
	if v is float:
		var f: float = v
		if f == floorf(f) and absf(f) < 9.0e15:
			return int(f)
	return null


# ---------------------------------------------------------------------------
# Exact rational arithmetic (AP-24: integer-exact conformance axis)
# ---------------------------------------------------------------------------

static func _gcd(a: int, b: int) -> int:
	var x := absi(a)
	var y := absi(b)
	while y != 0:
		var t := x % y
		x = y
		y = t
	return x


static func _rat(n: int, d: int) -> Vector2i:
	var dd := d
	if dd == 0:
		dd = 1
	var nn := n
	if dd < 0:
		nn = -nn
		dd = -dd
	var g := _gcd(nn, dd)
	if g > 1:
		nn = nn / g
		dd = dd / g
	return Vector2i(nn, dd)


static func _radd(a: Vector2i, b: Vector2i) -> Vector2i:
	var g := _gcd(a.y, b.y)
	var da := a.y / g
	var db := b.y / g
	return _rat(a.x * db + b.x * da, da * b.y)


static func _rmul(a: Vector2i, b: Vector2i) -> Vector2i:
	var g1 := _gcd(a.x, b.y)
	var g2 := _gcd(b.x, a.y)
	return _rat((a.x / g1) * (b.x / g2), (a.y / g2) * (b.y / g1))


static func _rdiv(a: Vector2i, b: Vector2i) -> Vector2i:
	return _rmul(a, Vector2i(b.y, b.x))


static func _rstr(a: Vector2i) -> String:
	if a.y == 1:
		return str(a.x)
	return "%d/%d" % [a.x, a.y]


static func _rtof(a: Vector2i) -> float:
	return float(a.x) / float(a.y)


# ---------------------------------------------------------------------------
# Evaluation + derivation
# ---------------------------------------------------------------------------

static func _eval(e: Dictionary, args: Dictionary, params: Dictionary) -> Vector2i:
	var base: Vector2i
	match int(e.k):
		EXPR_CONST:
			base = Vector2i(int(e.i0), 1)
		EXPR_PAIR:
			base = _rat(int(e.i0), int(e.i1))
		EXPR_REF, EXPR_PARAM:
			var nm: String = e.n
			if args.has(nm):
				base = args[nm]
			elif params.has(nm):
				base = params[nm]
			else:
				push_error("phenome_expand: unbound expression name %s" % nm)
				return Vector2i(0, 1)
		_:
			push_error("phenome_expand: bad expression kind")
			return Vector2i(0, 1)
	if e.mul != null:
		base = _rmul(base, _eval(e.mul, args, params))
	if e.div != null:
		var d := _eval(e.div, args, params)
		if d.x == 0:
			push_error("phenome_expand: division by zero")
			return base
		base = _rdiv(base, d)
	return base


static func _instantiate(tpl: Dictionary, args: Dictionary, params: Dictionary) -> Dictionary:
	var p: Array = []
	for e in tpl.exprs:
		p.append(_eval(e, args, params))
	return {"n": String(tpl.m), "p": p}


## Grammar-param bindings with trait modulation folded in (JSON `modulation`;
## modulated = (base·1000 + delta·trait_milli)/1000 — exact, AP-24).
func _grammar_params(g: Dictionary, trait_millis: Array) -> Dictionary:
	var params := {}
	for pname in g.params:
		var milli := int(g.params[pname]) * 1000
		for me in g.modulation:
			if String(me.param) == pname:
				var idx := int(me.trait_idx)
				var tm := int(trait_millis[idx]) if idx < trait_millis.size() else 500
				tm = clampi(tm, 0, 1000)
				milli += int(me.delta) * tm
		params[String(pname)] = _rat(milli, 1000)
	return params


## Stage -> iteration depth with LOD reduction (R4): near = depth,
## mid = depth-1, far = depth-2, floor 1; depth-0 stages stay 0.
func lod_depth(g: Dictionary, stage: int, depth_reduction: int) -> int:
	var depth := int(g.stage_depths[stage])
	if depth > 0 and depth_reduction > 0:
		depth = maxi(depth - depth_reduction, 1)
	return depth


func stage_depth(g: Dictionary, stage: int) -> int:
	return int(g.stage_depths[stage])


## The discrete derivation: Array of {"n": String, "p": Array[Vector2i]}.
## Pure in (g, vseed, stage, trait_millis, depth_reduction).
func modules(g: Dictionary, vseed: int, stage: int, trait_millis: Array,
		depth_reduction: int = 0) -> Array:
	if g.is_empty():
		push_error("phenome_expand: empty grammar")
		return []
	if stage < 0 or stage >= g.stage_depths.size():
		push_error("phenome_expand: stage out of range")
		return []
	if trait_millis.size() != g.traits.size():
		push_error("phenome_expand: trait vector width mismatch")
		return []
	var depth := lod_depth(g, stage, depth_reduction)
	var params := _grammar_params(g, trait_millis)

	var mods: Array = []
	for tpl in g.axiom:
		mods.append(_instantiate(tpl, {}, params))

	# variant_seed enters ONLY as axiom-parameter-0 jitter (Procedural §1.6).
	if not mods.is_empty() and not (mods[0].p as Array).is_empty() and g.jitter_mod > 1:
		var jitter := posmod(vseed, int(g.jitter_mod))
		if jitter != 0:
			var p0: Array = mods[0].p
			p0[0] = _radd(p0[0], Vector2i(jitter, 1))

	for _step in depth:
		var nxt: Array = []
		for mod in mods:
			var prod: Variant = g.prods.get(String(mod.n))
			if prod == null:
				nxt.append(mod)  # stationary / terminal symbol persists
				continue
			var args := {}
			var pnames: Array = prod.params
			var mod_p: Array = mod.p
			for i in pnames.size():
				args[String(pnames[i])] = mod_p[i] if i < mod_p.size() else Vector2i(0, 1)
			for tpl in prod.rhs:
				nxt.append(_instantiate(tpl, args, params))
		mods = nxt
		if mods.size() > MAX_MODULES:
			push_error("phenome_expand: derivation exceeds module cap")
			return mods
	return mods


## AP-24 conformance string: tokens space-separated, params in parentheses
## joined by commas, rationals as `num/den`. Identical format to
## render_derivation() in src/mojo/phenome/expand.mojo / goldens.txt.
static func render(mods: Array) -> String:
	var out := ""
	for i in mods.size():
		if i > 0:
			out += " "
		var m: Dictionary = mods[i]
		out += String(m.n)
		var p: Array = m.p
		if not p.is_empty():
			out += "("
			for j in p.size():
				if j > 0:
					out += ","
				out += _rstr(p[j])
			out += ")"
	return out


## Discrete derivation string — the conformance side-output.
func derive_string(g: Dictionary, vseed: int, stage: int, trait_millis: Array,
		depth_reduction: int = 0) -> String:
	return render(modules(g, vseed, stage, trait_millis, depth_reduction))


# ---------------------------------------------------------------------------
# Geometry (turtle interpretation of a derivation — representation only)
# ---------------------------------------------------------------------------

## expand() — pure: (grammar, variant_seed, stage, traits) -> ArrayMesh
## (+ optional LOD depth reduction). Same inputs ⇒ identical geometry.
func expand(g: Dictionary, vseed: int, stage: int, trait_millis: Array,
		depth_reduction: int = 0) -> ArrayMesh:
	var mods := modules(g, vseed, stage, trait_millis, depth_reduction)
	return _turtle(g, mods)


func _turtle(g: Dictionary, mods: Array) -> ArrayMesh:
	var b := Builder.new()
	var pos := Vector3.ZERO
	var fwd := Vector3.UP          # growth heading
	var side := Vector3.RIGHT      # lateral reference (⟂ fwd)
	var azimuth := 0.0             # persistent '[' roll (never popped)
	var stack: Array = []
	var coef := float(g.tropism.coef_milli) / 1000.0
	var dir := Vector3(g.tropism.dir.x, g.tropism.dir.y, 0.0)
	if dir.length_squared() < 1e-9:
		dir = Vector3.UP
	else:
		dir = dir.normalized()

	for mod in mods:
		var p: Array = mod.p
		match String(mod.n):
			"A":
				var units := _rtof(p[0]) if not p.is_empty() else 0.0
				var seg := units * LENGTH_UNIT
				if seg > 1e-5:
					var r := clampf(units * STEM_RADIUS_SCALE,
							STEM_RADIUS_MIN, STEM_RADIUS_MAX)
					b.cylinder(pos, pos + fwd * seg, r, r * 0.82, WIND_SEGMENT)
					pos += fwd * seg
					fwd = _tropism(fwd, side, dir, coef, seg)
			"T":
				var tu := _rtof(p[0]) if p.size() > 0 else 0.0
				var dens := _rtof(p[1]) if p.size() > 1 else 0.0
				var tseg := tu * LENGTH_UNIT
				if tseg > 1e-5:
					var tr := clampf(dens * TRUNK_RADIUS_SCALE,
							TRUNK_RADIUS_MIN, TRUNK_RADIUS_MAX)
					b.cylinder(pos, pos + fwd * tseg, tr, tr * 0.85, WIND_SEGMENT)
					pos += fwd * tseg
					fwd = _tropism(fwd, side, dir, coef, tseg)
			"F":
				# frond: two crossed blades radiating from the branch point
				var fl := (_rtof(p[0]) if not p.is_empty() else 0.0) \
						* LENGTH_UNIT * FROND_LEN_SCALE
				if fl > 1e-4:
					var w := fl * FROND_WIDTH_SCALE
					var centre := pos + fwd * (fl * 0.5)
					var side2 := fwd.cross(side)
					if side2.length_squared() > 1e-9:
						side2 = side2.normalized()
						b.quad(centre, fwd, side2, fl * 0.5, w * 0.5, WIND_LEAF)
					b.quad(centre, fwd, side, fl * 0.5, w * 0.5, WIND_LEAF)
			"L":
				# leaf: small crossed blades at the current turtle position
				var s := (_rtof(p[0]) if not p.is_empty() else 0.0) * LEAF_SIZE_SCALE
				s = clampf(s, LEAF_SIZE_MIN, LEAF_SIZE_MAX)
				var lside := fwd.cross(side)
				if lside.length_squared() > 1e-9:
					lside = lside.normalized()
					b.quad(pos, side, lside, s * 0.5, s * 0.4, WIND_LEAF)
				b.quad(pos, side, fwd, s * 0.5, s * 0.4, WIND_LEAF)
			"[":
				stack.append([pos, fwd, side])
				azimuth += BRANCH_ROLL_RAD
				side = _roll_side(fwd, azimuth)
				fwd = _tilt(fwd, side, BRANCH_TILT_RAD)
			"]":
				if not stack.is_empty():
					var st: Array = stack.pop_back()
					pos = st[0]
					fwd = st[1]
					side = st[2]
			_:
				# unknown/stationary glyph: no geometry (never rewrites form)
				pass
	return b.to_mesh()


## Lateral reference for the current heading, rolled by `azimuth` around it.
static func _roll_side(fwd: Vector3, azimuth: float) -> Vector3:
	var s := Vector3.UP.cross(fwd)
	if s.length_squared() < 1e-8:
		s = fwd.cross(Vector3.RIGHT)
	if s.length_squared() < 1e-8:
		return Vector3.RIGHT
	s = s.normalized()
	if absf(azimuth) < 1e-9:
		return s
	return Basis(fwd, azimuth) * s


static func _tilt(fwd: Vector3, axis: Vector3, angle: float) -> Vector3:
	if axis.length_squared() < 1e-9:
		return fwd
	return Basis(axis.normalized(), angle) * fwd


## Tropism (Procedural §1.7): rotate the heading toward the declared
## direction by coef rad per world-unit of segment; never overshoots.
static func _tropism(fwd: Vector3, side: Vector3, dir: Vector3,
		coef: float, seg_len: float) -> Vector3:
	var angle := coef * seg_len
	if angle <= 1e-6:
		return fwd
	var axis := fwd.cross(dir)
	if axis.length_squared() < 1e-10:
		return fwd
	var cur := fwd.angle_to(dir)
	angle = minf(angle, cur)
	if angle <= 1e-6:
		return fwd
	var rot := Basis(axis.normalized(), angle)
	side = rot * side
	return rot * fwd


# --- lookup helpers ----------------------------------------------------------

func grammar_by_species(species_id: int) -> Dictionary:
	return grammars_by_species.get(species_id, {})


func grammar_by_id(grammar_id: String) -> Dictionary:
	return grammars_by_id.get(grammar_id, {})


func species_count() -> int:
	return grammars_by_species.size()
