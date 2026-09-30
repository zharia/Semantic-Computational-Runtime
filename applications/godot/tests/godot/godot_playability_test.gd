# godot_playability_test.gd — scripted input run against the live island scene.
#
# Spec: milestone_0002 §7 exit criterion 3 ("Playable: mouse-look, WASD
# movement, sprint, jump; player walks on terrain without falling through;
# verified by scripted input run").
#
# Run (headless game-mode is fine):
#   timeout 300 godot --headless --path applications/godot/godot \
#       -s applications/godot/tests/godot/godot_playability_test.gd
# (or the runner: bash applications/godot/tests/godot/godot_playability_test.sh)
#
# Input injection strategy (recorded per spec note):
#   * Movement/sprint/jump use Input.action_press()/action_release() against
#     the project.godot input map — this exercises the REAL path
#     player_input.gd -> ScrSim.submit_input (AP-8: no direct world writes).
#   * Mouse-look tries Input.parse_input_event(InputEventMouseMotion) with the
#     mouse captured; if the headless display server does not deliver motion
#     events (probe: rotation.y unchanged), it FALLS BACK to calling
#     ScrSim.submit_input(0,0,dx,0,...) directly for the turn leg and prints
#     `TURN-MODE=direct` so the deviation is visible in the log.
#
# Assertions (PASS/FAIL lines; exit 0 iff all pass):
#   A. decode/content: terrain chunks > 0, scr_meta has sea_level/spawn,
#      HUD text starts with "tick " (else the snapshot pipeline is dead and
#      nothing downstream is meaningful).
#   B. horizontal movement > 2.0 world units (walk/sprint work).
#   C. camera y stayed within [sea_level - 1, peak_height + eye + 5] for the
#      whole run (no fall-through; bounds read from scr_meta, not hardcoded).
#   D. jump raised camera y ≥ 0.5 above the settled baseline.
#   E. turn changed camera yaw by > 0.1 rad (mouse-look path works).
#   F. editing leg (0007): submit_edit uplink rc, HOTBAR slot selection
#      mirrored to HUD, terrain mesh content changed by dig and by place,
#      TARGET readout left "SKY / AIR", prop pool materialized.
extends SceneTree

var island: Node = null
var cam: Node3D = null
var sim: Node = null

var _fail_count := 0
var _y_min := INF
var _y_max := -INF

func _initialize() -> void:
	_run()

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		print("FAIL: ", msg)
		_fail_count += 1

func _sample_y() -> void:
	if cam == null:
		return
	_y_min = minf(_y_min, cam.global_position.y)
	_y_max = maxf(_y_max, cam.global_position.y)

func _first(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null

func _frames(n: int) -> void:
	for i in n:
		await physics_frame
		_sample_y()

# Content hash of every terrain chunk mesh — detects sim-driven rebuilds
# (0007 edit -> world_version bump -> TERRAIN resend -> chunk rebuild).
func _terrain_hash() -> int:
	var terrain: Node = _first("scr_terrain")
	if terrain == null:
		return 0
	var h := 17
	for c in terrain.get_children():
		if not String(c.name).begins_with("Chunk_"):
			continue
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var am := mi.mesh as ArrayMesh
		if am == null:
			continue
		for s in am.get_surface_count():
			var arrays := am.surface_get_arrays(s)
			h = hash(h * 31 + hash(arrays[Mesh.ARRAY_VERTEX]))
	return h

func _run() -> void:
	var ps: PackedScene = load("res://scenes/island.tscn")
	if ps == null:
		print("FAIL: island.tscn failed to load")
		quit(1); return
	island = ps.instantiate()
	root.add_child(island)
	await _frames(30)

	# --- A. pipeline / scene contract ---------------------------------------
	var terrain: Node = _first("scr_terrain")
	var chunks := 0
	if terrain != null:
		for c in terrain.get_children():
			if String(c.name).begins_with("Chunk_"):
				chunks += 1
	_check(chunks > 0, "A1 terrain chunks materialized (%d)" % chunks)

	var meta_n: Node = _first("scr_meta")
	var sea := 0.0
	var peak := 0.0
	if meta_n != null and meta_n.has_meta("sea_level") and meta_n.has_meta("peak_height"):
		sea = float(meta_n.get_meta("sea_level"))
		peak = float(meta_n.get_meta("peak_height"))
		_check(true, "A2 scr_meta present (sea_level=%.2f peak_height=%.2f)" % [sea, peak])
	else:
		_check(false, "A2 scr_meta sea_level/peak_height missing (TERRAIN_META not applied)")

	var hud := _first("scr_hud") as Label
	_check(hud != null and String(hud.text).begins_with("tick "),
	       "A3 HUD written by adapter (%s)" % (hud.text if hud != null else "null"))

	sim = _first("scr_sim")
	_check(sim != null and sim.has_method("submit_input"), "A4 ScrSim.submit_input available")
	cam = _first("scr_camera") as Camera3D
	_check(cam != null, "A5 scr_camera present")
	if cam == null or sim == null:
		print("PLAYABILITY: FAIL (%d check(s) failed; cannot continue)" % _fail_count)
		quit(1); return

	# eye height mirror of src/mojo/sim/parameters.mojo EYE_HEIGHT (test-side
	# duplication, same convention as the golden-fixture scripted inputs).
	const EYE_HEIGHT := 1.7
	var eye := EYE_HEIGHT
	var y_lo := sea - 1.0
	var y_hi := peak + eye + 5.0
	if meta_n == null or not meta_n.has_meta("peak_height"):
		print("NOTE: using fallback y bounds (meta absent)")

	# --- E (first, needs capture): mouse-look via parse_input_event ---------
	var yaw_before := cam.rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _frames(2)
	for i in 30:
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(10.0, 0.0)
		Input.parse_input_event(ev)
		await process_frame
	await _frames(4)
	var turn_mode := "motion"
	if absf(cam.rotation.y - yaw_before) < 0.1:
		turn_mode = "direct"
		print("NOTE: injected mouse motion produced no yaw change "
			+ "(headless display server) — TURN-MODE=direct, "
			+ "calling submit_input directly for the turn leg")
		# look_dx is in input units; sim applies MOUSE_SENSITIVITY (0.0025 rad/unit)
		# — 60 frames x 5.0 units x 0.0025 = 0.75 rad of yaw.
		for i in 60:
			sim.submit_input(0.0, 0.0, 5.0, 0.0, false, false, false, false)
			await physics_frame
	# Contract (104_contract §6): yaw positive = left. look_dx > 0 = look
	# right, so yaw must DECREASE — assert the SIGN, not just magnitude.
	var yaw_delta := cam.rotation.y - yaw_before
	_check(yaw_delta < -0.1,
	       "E mouse-look look_dx=+5.0 decreased yaw by %.3f rad (mode=%s)" % [-yaw_delta, turn_mode])
	print("INFO: turn mode = ", turn_mode)

	# --- baseline (settled, grounded) ---------------------------------------
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await _frames(30)
	var pos0 := cam.global_position
	var y_settle := cam.global_position.y

	# --- F. editing leg (milestone_0007 §7): uplink + dig + place ----------
	# Runs at spawn (dry land) BEFORE the movement legs: the dig ray is
	# aimed straight down, so it deterministically hits the column the
	# player stands on (sim-owned raycast, 0007 AP-12). Assertions: edit
	# uplink rc, HOTBAR selection mirrored into the HUD, terrain mesh
	# content actually changed after dig and again after place
	# (chunk-local rebuild), TARGET readout left "SKY / AIR", prop pool up.
	_check(sim.has_method("submit_edit") and sim.has_method("get_hotbar_selected_slot"),
	       "F1 ScrSim.submit_edit + get_hotbar_selected_slot available")
	var hotbar := _first("scr_hotbar")
	_check(hotbar != null and hotbar.has_method("apply_hotbar"),
	       "F2 scr_hotbar host present with apply_hotbar")
	var target_lbl := _first("scr_target") as Label
	_check(target_lbl != null, "F3 scr_target Label present")
	var props_n := _first("scr_props")
	_check(props_n != null and props_n.has_method("apply_props")
	       and props_n.get_child_count() >= 1,
	       "F4 scr_props pool materialized (%d node(s))"
	       % (props_n.get_child_count() if props_n != null else 0))

	# Select slot 3 (intent only — sim validates, 0007 AP-13).
	var rc_sel: int = sim.submit_edit(0, 3)
	await _frames(2)
	var slot_mirror: int = sim.get_hotbar_selected_slot()
	_check(rc_sel == 0 and slot_mirror == 3,
	       "F5 select_slot=3 accepted (rc=%d, mirror=%d)" % [rc_sel, slot_mirror])
	if hotbar != null and hotbar.get_child_count() >= 3:
		var sel_flag: bool = hotbar.get_child(2).get_meta("selected", false)
		_check(sel_flag, "F6 HUD shows slot 3 selected (scr_hotbar panel meta)")
		var names_ok := false
		for panel in hotbar.get_children():
			for c in panel.get_children():
				if c is Label and String(c.text).contains("Obsidian"):
					names_ok = true
		_check(names_ok, "F7 HUD slot 3 label carries catalog name (Obsidian)")

	# Aim straight down (look_dy > 0 = mouse down, sim pitch -= look_dy),
	# then capture the terrain mesh content, dig, place.
	for i in 50:
		sim.submit_input(0.0, 0.0, 0.0, 60.0, false, false, false, false)
		await physics_frame
	await _frames(4)
	if target_lbl != null:
		_check(String(target_lbl.text) != "SKY / AIR"
		       and String(target_lbl.text).contains("#"),
		       "F8 TARGET readout shows a hit after aiming down (%s)"
		       % target_lbl.text)
	var hash0 := _terrain_hash()
	var rc_dig: int = sim.submit_edit(1, 0) # dig
	_check(rc_dig == 0, "F9 dig submit accepted (rc=%d)" % rc_dig)
	await _frames(15)
	var hash1 := _terrain_hash()
	_check(hash1 != hash0, "F10 dig changed terrain mesh content (chunk-local rebuild)")

	var rc_sel2: int = sim.submit_edit(0, 2) # place with slot 2 material
	var rc_place: int = sim.submit_edit(2, 0)
	await _frames(2)
	_check(rc_sel2 == 0 and int(sim.get_hotbar_selected_slot()) == 2,
	       "F11 select_slot=2 accepted (rc=%d, mirror=%d)"
	       % [rc_sel2, int(sim.get_hotbar_selected_slot())])
	_check(rc_place == 0, "F12 place submit accepted (rc=%d)" % rc_place)
	await _frames(15)
	var hash2 := _terrain_hash()
	_check(hash2 != hash1, "F13 place changed terrain mesh content again")

	# --- D. jump (at spawn, on land) ---------------------------------------
	# Jump must be measured on land: the sim applies SWIM_JUMP_FACTOR (0.5)
	# with vertical damping in water (subjects.mojo), so a swim-jump only
	# rises ~0.4-0.5 u by design. Spawn is grounded on the beach.
	var y_peak_jump := y_settle
	Input.action_press("jump")
	await _frames(4)
	Input.action_release("jump")
	for i in 120:
		await physics_frame
		_sample_y()
		y_peak_jump = maxf(y_peak_jump, cam.global_position.y)
	_check(y_peak_jump >= y_settle + 0.5,
	       "D jump peak %.2f >= settle %.2f + 0.5" % [y_peak_jump, y_settle])

	# --- B. move forward (+ sprint) -----------------------------------------
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _frames(180)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await _frames(30)
	var pos1 := cam.global_position
	var horiz := Vector2(pos1.x - pos0.x, pos1.z - pos0.z).length()
	_check(horiz > 2.0, "B horizontal movement %.2f units > 2.0" % horiz)

	# --- C. bounds over the whole run ---------------------------------------
	_check(_y_min >= y_lo and _y_max <= y_hi,
	       "C camera y within [%.2f, %.2f] all run (min=%.2f max=%.2f)" % [y_lo, y_hi, _y_min, _y_max])

	print("PLAYABILITY SUMMARY: horizontal=%.2f jump_gain=%.2f y=[%.2f,%.2f] yaw_delta=%.3f fails=%d"
	      % [horiz, y_peak_jump - y_settle, _y_min, _y_max, cam.rotation.y - yaw_before, _fail_count])
	if _fail_count == 0:
		print("PLAYABILITY: PASS")
		quit(0)
	else:
		print("PLAYABILITY: FAIL (", _fail_count, " check(s) failed)")
		quit(1)
