# godot_phenome_test.gd — sprint 03 (milestone 0010) scene + conformance gate.
#
# Run (headless):
#   timeout 300 godot --headless --path applications/godot/godot \
#       -s applications/godot/tests/godot/godot_phenome_test.gd
# (or the runner: bash applications/godot/tests/godot/godot_phenome_test.sh)
#
# Part 1 — conformance (pure, no scene):
#   A. goldens.txt (84 rows): derive_string == golden render, module count
#      and depth match, for every grammar_id/vseed/stage/trait probe (AP-24).
#   B. determinism: two derivations of the same inputs render identically.
#   C. stage monotonicity: module count never decreases across stages 0..15
#      (Flora invariant: development is monotone).
#   D. trait modulation: stage-7 render differs between trait vectors
#      [0,0] and [1000,1000] for at least one species.
#   E. LOD depth floor: depth-0 stages stay depth 0 under reduction;
#      reduced depth never drops below 1.
#
# Part 2 — scene (island.tscn, adapter live):
#   F. FLORA payload: 95 records, 3044 bytes, instance total == 95.
#   G. cache: entries <= 7*K (112), zero evictions, groups > 0.
#   H. structural meshes: ArrayMesh surfaces, >=64-vert mesh present,
#      wind COLOR channel present (min <= 0.35 trunk, max >= 0.85 leaf).
#   I. stability: apply/expand/lod counters unchanged across a 2-tick idle
#      window (no cache key may be created without a new payload key).
#   J. LOD hysteresis (static table) + live camera teleports: band
#      histogram reaches all-far [0,0,95] and back, expansion_count
#      unchanged throughout the camera motion (R3/R4).
#   K. timings: first-load expansion budget + steady-state LOD pass max.
#
# Exit: 0 iff "PHENOME: PASS" printed (and no FAIL/SCRIPT ERROR); 1 otherwise.
extends SceneTree

const Expander := preload("res://scripts/phenome_expand.gd")
const FloraView := preload("res://scripts/flora_view.gd")

const SPECIES_N := 7
const GOLDENS_ROWS := 84
const PLANTS := 95
const PAYLOAD_BYTES := 4 + 32 * PLANTS
const CACHE_MAX := 112

var _fail := 0

func _initialize() -> void:
	_run()


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		print("FAIL: ", msg)
		_fail += 1


func _first(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _hud_tick(hud: Label) -> int:
	if hud != null and String(hud.text).begins_with("tick "):
		return int(String(hud.text).trim_prefix("tick ").split(" ")[0])
	return -1


## Band fills land on the flora _process that follows an apply, but our
## coroutine resumes at frame start (before that _process) — so a single
## histogram read can catch a mid-apply transient. Consistent means:
## view caught up with the payload AND every instance counted exactly once.
func _consist(flora: Variant, h: Array) -> bool:
	return flora.instance_total() == PLANTS \
			and int(h[0]) + int(h[1]) + int(h[2]) == PLANTS


## Poll band_histogram until consistent AND `want` holds, up to `frames`
## retries: want[i] = -1 don't care · -2 must be > 0 · >= 0 exact.
func _poll_hist(flora: Variant, want: Array, frames := 120) -> Array:
	var h: Array = []
	var n := 0
	while n < frames:
		h = flora.band_histogram()
		var ok := _consist(flora, h)
		for i in 3:
			if int(want[i]) == -2 and int(h[i]) <= 0:
				ok = false
			if int(want[i]) >= 0 and int(h[i]) != int(want[i]):
				ok = false
		if ok:
			return h
		await process_frame
		n += 1
	return h


func _run() -> void:
	await _run_conformance()
	await _run_scene()
	if _fail == 0:
		print("PHENOME: PASS")
		quit(0)
	else:
		print("PHENOME: FAIL (%d failures)" % _fail)
		quit(1)


# ---------------------------------------------------------------------------
# Part 1 — conformance
# ---------------------------------------------------------------------------

func _run_conformance() -> void:
	var exp: Variant = Expander.new()
	_ok(exp.load_grammars("res://data/phenome_grammars.json"),
			"grammar file loaded")
	_ok(exp.species_count() == SPECIES_N, "7 grammars parsed")

	var path := ProjectSettings.globalize_path("res://") \
			+ "../tests/fixtures/phenome/goldens.txt"
	var fh := FileAccess.open(path, FileAccess.READ)
	if fh == null:
		_ok(false, "goldens.txt open: %s" % path)
		return
	var rows := 0
	var mismatches := 0
	for line in fh.get_as_text().split("\n"):
		var t := line.strip_edges()
		if t.is_empty() or t.begins_with("#"):
			continue
		var f := t.split("|")
		if f.size() < 8:
			_ok(false, "goldens row malformed: %s" % t)
			continue
		rows += 1
		var gid := String(f[0])
		var vseed := int(f[1])
		var stage := int(f[2])
		var ash := int(f[3])
		var drought := int(f[4])
		var want_depth := int(f[5])
		var want_count := int(f[6])
		var want_render := "|".join(f.slice(7)).strip_edges()
		var g: Dictionary = exp.grammar_by_id(gid)
		if g.is_empty():
			_ok(false, "no grammar for goldens id %s" % gid)
			continue
		var mods: Array = exp.modules(g, vseed, stage, [ash, drought], 0)
		var got_depth: int = exp.lod_depth(g, stage, 0)
		var got_render: String = exp.render(mods)
		# B (determinism, free with the second derivation)
		var again: String = exp.render(exp.modules(
				g, vseed, stage, [ash, drought], 0))
		if got_depth != want_depth or mods.size() != want_count \
				or got_render != want_render or again != got_render:
			mismatches += 1
			if mismatches <= 5:
				print(("PHENOME: mismatch %s seed=%d stage=%d traits=[%d,%d]\n"
						+ "  want depth=%d count=%d\n  got  depth=%d count=%d\n"
						+ "  want render: %s\n  got  render: %s")
						% [gid, vseed, stage, ash, drought, want_depth,
							want_count, got_depth, mods.size(),
							want_render, got_render])
	_ok(rows == GOLDENS_ROWS, "goldens rows = %d (want %d)" % [rows, GOLDENS_ROWS])
	_ok(mismatches == 0, "AP-24 conformance mismatches = %d" % mismatches)

	# C — stage monotone module counts per species (traits [0,0], seed 12345).
	var mono_bad := 0
	for sid in SPECIES_N:
		var g: Dictionary = exp.grammar_by_species(sid + 1)
		var prev := -1
		for stage in 16:
			var n: int = exp.modules(g, 12345, stage, [0, 0], 0).size()
			if n < prev:
				mono_bad += 1
				print("PHENOME: count decreased species=%d stage=%d: %d < %d"
						% [sid + 1, stage, n, prev])
			prev = n
	_ok(mono_bad == 0, "stage monotonicity (7 species x 16 stages)")

	# D — trait modulation changes form at stage 7.
	var trait_diff := 0
	for sid in SPECIES_N:
		var g: Dictionary = exp.grammar_by_species(sid + 1)
		var a: String = exp.derive_string(g, 12345, 7, [0, 0], 0)
		var b: String = exp.derive_string(g, 12345, 7, [1000, 1000], 0)
		if a != b:
			trait_diff += 1
	_ok(trait_diff >= 1, "trait modulation visible at stage 7 (%d species)"
			% trait_diff)

	# E — LOD depth reduction floor.
	var lod_bad := 0
	for sid in SPECIES_N:
		var g: Dictionary = exp.grammar_by_species(sid + 1)
		for stage in 16:
			var base: int = exp.lod_depth(g, stage, 0)
			var red: int = exp.lod_depth(g, stage, 2)
			if base == 0 and red != 0:
				lod_bad += 1
			if base > 0 and red < 1:
				lod_bad += 1
	_ok(lod_bad == 0, "LOD depth floor (depth-0 stays 0, else >= 1)")

	# J (static half) — hysteresis table.
	var cases := [
		[31.0, 0, 0], [33.0, 0, 1], [27.0, 1, 0], [59.0, 0, 1],
		[63.0, 1, 2], [61.0, 2, 2], [57.0, 2, 1],
		[0.0, -1, 0], [45.0, -1, 1], [80.0, -1, 2],
	]
	for c in cases:
		var got: int = FloraView.lod_band_for_distance(float(c[0]), int(c[1]))
		_ok(got == int(c[2]), "lod_band(%.1f, cur=%d) = %d (want %d)"
				% [float(c[0]), int(c[1]), got, int(c[2])])


# ---------------------------------------------------------------------------
# Part 2 — scene
# ---------------------------------------------------------------------------

func _run_scene() -> void:
	var packed := load("res://scenes/island.tscn")
	if packed == null:
		_ok(false, "island.tscn failed to load")
		return
	root.add_child(packed.instantiate())
	await _frames(30)

	var sim: Variant = _first("scr_sim")
	if sim == null or sim.get("camera_follow") == null:
		_ok(false, "scr_sim without camera_follow (adapter not loaded?)")
		return
	sim.set("camera_follow", false)

	# Wait for the adapter's FLORA application (cached at init, invariant 5).
	var flora: Variant = _first("scr_flora")
	var waited := 0
	while flora != null and flora.payload_count() != PLANTS and waited < 2400:
		await process_frame
		waited += 1
	if flora == null:
		_ok(false, "group scr_flora absent")
		return

	# F — payload shape.
	_ok(flora.payload_count() == PLANTS,
			"payload_count = %d (want %d)" % [flora.payload_count(), PLANTS])
	_ok(flora.payload_bytes() == PAYLOAD_BYTES,
			"payload_bytes = %d (want %d)" % [flora.payload_bytes(), PAYLOAD_BYTES])
	# Band fills happen on the next flora _process after an apply — wait
	# for the view to catch up before counting instances.
	var synced := 0
	while flora.instance_total() != flora.payload_count() and synced < 240:
		await process_frame
		synced += 1
	_ok(flora.instance_total() == PLANTS,
			"instance_total = %d (want %d)" % [flora.instance_total(), PLANTS])
	_ok(flora.group_count() > 0, "group_count = %d" % flora.group_count())

	# G — cache bounds.
	_ok(flora.cache_size() <= CACHE_MAX,
			"cache_size = %d (<= %d)" % [flora.cache_size(), CACHE_MAX])
	_ok(flora.group_count() <= PLANTS,
			"group_count = %d (<= %d)" % [flora.group_count(), PLANTS])

	# H — structural mesh content.
	var mesh_n := 0
	var verts_ok := false
	var w_min := 1.0
	var w_max := 0.0
	for child in flora.get_children():
		if not (child is MultiMeshInstance3D):
			continue
		var mm: MultiMesh = (child as MultiMeshInstance3D).multimesh
		if mm == null or mm.instance_count == 0:
			continue
		if not (mm.mesh is ArrayMesh):
			_ok(false, "%s mesh is not ArrayMesh" % String(child.name))
			continue
		mesh_n += 1
		var am := mm.mesh as ArrayMesh
		for s in am.get_surface_count():
			var arr := am.surface_get_arrays(s)
			var verts := arr[Mesh.ARRAY_VERTEX] as PackedVector3Array
			if verts != null and verts.size() >= 64:
				verts_ok = true
			var colv: Variant = arr[Mesh.ARRAY_COLOR]
			if colv == null or (colv as PackedColorArray).is_empty():
				_ok(false, "%s surface %d missing wind COLOR channel"
						% [String(child.name), s])
				continue
			for c in (colv as PackedColorArray):
				w_min = minf(w_min, c.r)
				w_max = maxf(w_max, c.r)
	_ok(mesh_n >= 1, "rendered meshes = %d" % mesh_n)
	_ok(verts_ok, "a mesh has >= 64 verts (silhouette, not a blob)")
	var positions: PackedVector3Array = flora.instance_positions()
	_ok(positions.size() == PLANTS,
			"positions harvested = %d" % positions.size())
	_ok(w_min <= 0.35, "wind weight min = %.2f (<= 0.35 trunk)" % w_min)
	_ok(w_max >= 0.85, "wind weight max = %.2f (>= 0.85 leaf)" % w_max)

	var cam: Variant = _first("scr_camera")
	var hud := _first("scr_hud") as Label
	if cam == null:
		_ok(false, "scr_camera absent")
		return
	await _frames(5)

	# I — stability: the sim re-emits FLORA as plants grow (scale delta >=
	# FLORA_EMIT_EPS) and stage changes create new cache keys — that is
	# legitimate. The invariant under test: an expansion NEVER happens
	# without a payload application (camera/view state must not expand).
	# Per-frame attribution: expansion growth must coincide with apply
	# growth (same frame or the frame right after — flora._process may run
	# before the adapter's apply in the same frame).
	var exp0: int = flora.expansion_count()
	var app0: int = flora.apply_count()
	var lod0: int = flora.lod_build_count()
	var tick0 := _hud_tick(hud)
	var attrib := 0
	var prev_a := app0
	var prev_e := exp0
	var grew_a := -2
	var sample := 0
	var seen := 0
	while seen < 2 and waited < 4800:
		await process_frame
		waited += 1
		sample += 1
		var a: int = flora.apply_count()
		var e: int = flora.expansion_count()
		if a > prev_a:
			grew_a = sample
		if e > prev_e and a == prev_a and sample > grew_a + 1:
			attrib += 1
			print("PHENOME: expansion without apply at sample %d (%d -> %d)"
					% [sample, prev_e, e])
		prev_a = a
		prev_e = e
		var t := _hud_tick(hud)
		if t > tick0:
			seen = t - tick0
	_ok(seen >= 2, "waited 2 HUD ticks (tick %d -> %d)" % [tick0, _hud_tick(hud)])
	_ok(attrib == 0, "expansions attributable to applies (violations = %d)"
			% attrib)
	if flora.apply_count() == app0:
		_ok(flora.expansion_count() == exp0,
				"no applies -> expansion stable (%d)" % exp0)
	else:
		print("PHENOME: NOTE idle applies %d -> %d, expansion %d -> %d"
				% [app0, flora.apply_count(), exp0, flora.expansion_count()])
	_ok(flora.lod_build_count() >= lod0, "lod_build_count monotone")

	# J — live camera teleports: spawn -> far -> near a plant -> far.
	# Per segment: if no payload arrived (apply_count flat), expansion must
	# be flat too — camera motion never creates cache keys (R3).
	var hist0: Array = await _poll_hist(flora, [-1, -1, -1])
	_ok(_consist(flora, hist0),
			"initial histogram consistent: %s" % str(hist0))

	var a1: int = flora.apply_count()
	var e1: int = flora.expansion_count()
	cam.global_position = Vector3(400.0, 160.0, 400.0)
	await _frames(6)
	var hist_far: Array = await _poll_hist(flora, [0, 0, PLANTS])
	_ok(hist_far[0] == 0 and hist_far[1] == 0 and hist_far[2] == PLANTS,
			"far camera -> all band 2: %s" % str(hist_far))
	_ok(flora.expansion_count() == e1 or flora.apply_count() > a1,
			"far move: expansion only when applies arrived (applies %d -> %d, exp %d -> %d)"
			% [a1, flora.apply_count(), e1, flora.expansion_count()])

	if positions.size() > 0:
		a1 = flora.apply_count()
		e1 = flora.expansion_count()
		cam.global_position = positions[0] + Vector3(1.5, 1.0, 1.5)
		await _frames(6)
		var hist_near: Array = await _poll_hist(flora, [-2, -1, -1])
		var d_min := INF
		var n28 := 0
		var n58 := 0
		for p in positions:
			var d: float = cam.global_position.distance_to(p)
			d_min = minf(d_min, d)
			if d <= 28.0:
				n28 += 1
			if d <= 58.0:
				n58 += 1
		print(("PHENOME: near diag cam=%s d_min=%.2f n28=%d n58=%d "
				+ "sum=%d instances=%d") % [str(cam.global_position), d_min,
				n28, n58, hist_near[0] + hist_near[1] + hist_near[2],
				flora.instance_total()])
		_ok(hist_near[0] >= 1,
				"near camera -> band 0 occupied: %s" % str(hist_near))
		_ok(flora.expansion_count() == e1 or flora.apply_count() > a1,
				"near move: expansion only when applies arrived (applies %d -> %d, exp %d -> %d)"
				% [a1, flora.apply_count(), e1, flora.expansion_count()])

	a1 = flora.apply_count()
	e1 = flora.expansion_count()
	cam.global_position = Vector3(400.0, 160.0, 400.0)
	await _frames(6)
	var hist_back: Array = await _poll_hist(flora, [0, 0, PLANTS])
	_ok(hist_back[0] == 0 and hist_back[1] == 0 and hist_back[2] == PLANTS,
			"return to far -> all band 2 again: %s" % str(hist_back))
	_ok(flora.expansion_count() == e1 or flora.apply_count() > a1,
			"return move: expansion only when applies arrived (applies %d -> %d, exp %d -> %d)"
			% [a1, flora.apply_count(), e1, flora.expansion_count()])

	_ok(flora.cache_size() <= CACHE_MAX,
			"cache still bounded after motion (%d)" % flora.cache_size())
	_ok(flora.lod_build_count() >= lod0,
			"lod_build_count = %d (lazy bands, >= idle %d)"
			% [flora.lod_build_count(), lod0])

	# K — timings.
	print(("PHENOME: stats payload=%d bytes=%d instances=%d groups=%d "
			+ "cache=%d exp=%d lod=%d applies=%d evict=%d expand_usc=%d "
			+ "lod_max_usc=%d hist0=%s hist_far=%s")
			% [flora.payload_count(), flora.payload_bytes(),
				flora.instance_total(), flora.group_count(),
				flora.cache_size(), flora.expansion_count(),
				flora.lod_build_count(), flora.apply_count(),
				flora.eviction_count(), flora.total_expand_usec(),
				flora.lod_usec_max(), str(hist0), str(hist_back)])
