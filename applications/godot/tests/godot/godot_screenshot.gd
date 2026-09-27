# godot_screenshot.gd — automated island screenshot + non-blank luminance check.
#
# Spec: milestone_0002 §7 exit criterion 2 ("automated screenshot (non-blank/
# luminance check) or documented manual capture").
#
# Run (RENDERED game mode — a display/GPU is required; do NOT pass --headless):
#   timeout 300 godot --path applications/godot/godot \
#       -s applications/godot/tests/godot/godot_screenshot.gd -- \
#       --frames=300 --png=applications/godot/build/island.png
# (or use the runner: bash applications/godot/tests/godot/godot_screenshot.sh)
#
# Exit codes: 0 PASS · 1 scene/content assertion failed · 2 capture failed ·
#             3 image blank (luminance check failed).
#
# Assertions beyond raw luminance (so a sky-only frame cannot pass while the
# island is missing):
#   * Terrain group has >= 1 Chunk_* child (adapter materialized the TERRAIN
#     section — proof the snapshot pipeline works end to end)
#   * scr_meta carries sea_level + spawn_position (TERRAIN_META applied)
#   * scr_hud label text starts with "tick " (HUD applied)
# Luminance thresholds (display-verification constants, not gameplay values):
#   mean > 10.0 and stddev > 5.0 over 8-bit luminance of a 64-row subsample.
extends SceneTree

var _png_path := "res://../build/island.png"  # globalized below (repo build/)
var _frames := 300

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--png="):
			_png_path = a.trim_prefix("--png=")
		elif a.begins_with("--frames="):
			_frames = maxi(1, int(a.trim_prefix("--frames=")))
	_run()

func _fail(code: int, msg: String) -> void:
	print("SCREENSHOT: FAIL — ", msg)
	quit(code)

func _run() -> void:
	var ps: PackedScene = load("res://scenes/island.tscn")
	if ps == null:
		_fail(1, "island.tscn failed to load"); return
	var island := ps.instantiate()
	root.add_child(island)

	# Let the adapter run _ready + several physics frames (snapshot apply).
	for i in 30:
		await physics_frame

	# --- run the scene for N frames, then capture ---------------------------
	for i in _frames:
		await process_frame
	await RenderingServer.frame_post_draw

	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		_fail(2, "viewport image unavailable"); return

	# --- luminance check (8-bit luma Y = 0.299R + 0.587G + 0.114B) ----------
	var w := img.get_width()
	var h := img.get_height()
	var rgba := img.duplicate()
	rgba.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = rgba.get_data()
	var n := 0
	var sum := 0.0
	var sumsq := 0.0
	var y := 0
	while y < h:
		var row := y * w * 4
		var x := 0
		while x < w:
			var i3 := row + x * 4
			var lum: float = 0.299 * float(data[i3]) + 0.587 * float(data[i3 + 1]) + 0.114 * float(data[i3 + 2])
			sum += lum
			sumsq += lum * lum
			n += 1
			x += 8
		y += 4
	var mean := sum / float(n)
	var stddev := sqrt(maxf(0.0, sumsq / float(n) - mean * mean))
	print("SCREENSHOT: %dx%d mean_luminance=%.2f stddev=%.2f" % [w, h, mean, stddev])

	var out := _png_path
	if out.begins_with("res://") or out.begins_with("user://"):
		out = ProjectSettings.globalize_path(out)
	elif not out.begins_with("/"):
		out = OS.get_environment("PWD") + "/" + out
	var dir := out.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var err := img.save_png(out)
	if err != OK:
		_fail(2, "save_png(%s) failed err=%d" % [out, err]); return
	print("SCREENSHOT: wrote ", out)

	if mean <= 10.0:
		_fail(3, "mean luminance %.2f <= 10.0 (blank/dark frame)" % mean); return
	if stddev <= 5.0:
		_fail(3, "stddev %.2f <= 5.0 (uniform frame, no content)" % stddev); return

	# --- content assertions -------------------------------------------------
	var chunks := 0
	var terrain: Node = _first_in_group("scr_terrain")
	if terrain != null:
		for c in terrain.get_children():
			if String(c.name).begins_with("Chunk_"):
				chunks += 1
	if chunks < 1:
		_fail(1, "no Chunk_* meshes under scr_terrain (snapshot TERRAIN not applied)"); return
	print("SCREENSHOT: terrain chunks = ", chunks)

	var meta_n: Node = _first_in_group("scr_meta")
	if meta_n == null or not meta_n.has_meta("sea_level") \
			or not meta_n.has_meta("spawn_position"):
		_fail(1, "scr_meta missing sea_level/spawn_position (TERRAIN_META not applied)"); return
	print("SCREENSHOT: meta sea_level=", meta_n.get_meta("sea_level"),
	      " spawn=", meta_n.get_meta("spawn_position"))

	var hud := _first_in_group("scr_hud") as Label
	if hud == null or not String(hud.text).begins_with("tick "):
		_fail(1, "scr_hud text not set by adapter (snapshot not applied)"); return
	print("SCREENSHOT: hud = ", hud.text)


	print("SCREENSHOT: PASS")
	quit(0)

func _first_in_group(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null
