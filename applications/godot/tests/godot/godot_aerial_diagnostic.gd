# godot_aerial_diagnostic.gd — top-down (aerial) capture of the island.
#
# PURPOSE (defect triage: "half the island looks like missing"):
#   The normal screenshot is taken from the spawn camera, where fog, the
#   ocean plane and the crater rim all overlap. This script instead parks the
#   camera straight down over the island centre at high altitude, so the whole
#   ±96 u island footprint is in frame and missing/visible terrain is obvious.
#
# The adapter rewrites the scr_camera transform from the PLAYER section every
# physics frame, so the camera can only be driven manually after switching the
# adapter's debug property `camera_follow` off (adapter default true; the main
# scene never sets it — see scr_godot_adapter.cpp file header).
#
# Run (RENDERED mode — needs a display/GPU; never --headless):
#   timeout 300 godot --path applications/godot/godot \
#       -s applications/godot/tests/godot/godot_aerial_diagnostic.gd -- \
#       --png=applications/godot/build/aerial.png
#
# Options:
#   --png=PATH       output PNG (default res://../build/aerial.png)
#   --frames=N       physics frames to settle before capture (default 60)
#   --alt=U          camera altitude above y=0 (default 160 — fits ±96 island)
#   --fog=0|1        disable the WorldEnvironment fog (default 1 = fog on)
#   --ocean=0|1      hide the Ocean node (default 1 = ocean shown)
#   --cull=0|1       0 = set every terrain surface material to CULL_DISABLED
#                    (default 1 = engine default CULL_BACK) — used to isolate
#                    back-face culling as the cause of invisible terrain.
#   --pos=X,Y,Z      override the camera world position (default: 0,alt,0)
#   --rot=X,Y,Z      override the camera rotation in DEGREES
#                    (default: -90,0,0 = straight down)
#                    e.g. a low oblique view over the sea:
#                      --pos=-10,4,-120 --rot=-8,180,0
#
# Exit codes: 0 capture ok · 1 scene/scene-contract failure · 2 capture failed.
extends SceneTree

var _png := "res://../build/aerial.png"
var _frames := 60
var _alt := 160.0
var _fog := true
var _ocean := true
var _cull := true
var _has_pos := false
var _has_rot := false
var _pos := Vector3.ZERO
var _rot_deg := Vector3.ZERO

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--png="):
			_png = a.trim_prefix("--png=")
		elif a.begins_with("--frames="):
			_frames = maxi(1, int(a.trim_prefix("--frames=")))
		elif a.begins_with("--alt="):
			_alt = float(a.trim_prefix("--alt="))
		elif a.begins_with("--fog="):
			_fog = a.trim_prefix("--fog=") != "0"
		elif a.begins_with("--ocean="):
			_ocean = a.trim_prefix("--ocean=") != "0"
		elif a.begins_with("--cull="):
			_cull = a.trim_prefix("--cull=") != "0"
		elif a.begins_with("--pos="):
			var p := a.trim_prefix("--pos=").split(",")
			if p.size() == 3:
				_pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
				_has_pos = true
		elif a.begins_with("--rot="):
			var r := a.trim_prefix("--rot=").split(",")
			if r.size() == 3:
				_rot_deg = Vector3(float(r[0]), float(r[1]), float(r[2]))
				_has_rot = true
	_run()

func _fail(code: int, msg: String) -> void:
	print("AERIAL: FAIL — ", msg)
	quit(code)

func _first(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null

func _run() -> void:
	var ps: PackedScene = load("res://scenes/island.tscn")
	if ps == null:
		_fail(1, "island.tscn failed to load"); return
	var island := ps.instantiate()
	root.add_child(island)

	# Let the adapter run _ready + N physics frames (snapshot applied).
	for i in _frames:
		await physics_frame

	# --- hand the camera over (adapter debug property, default true) --------
	var sim := _first("scr_sim")
	if sim == null or not sim.get("camera_follow") == true:
		_fail(1, "scr_sim node without camera_follow property (adapter not loaded?)"); return
	sim.set("camera_follow", false)
	print("AERIAL: camera_follow = ", sim.get("camera_follow"))

	var env_n := _first("scr_env")
	if env_n != null and env_n is WorldEnvironment:
		# apply_sky() rewrites fog_enabled/density/colour from the SKY section
		# on EVERY physics frame, so detach first — otherwise the --fog=0 flag
		# is silently reverted on the next tick.
		env_n.remove_from_group("scr_env")
		var env: Environment = (env_n as WorldEnvironment).environment
		if env != null:
			env.fog_enabled = _fog
			print("AERIAL: fog_enabled = ", env.fog_enabled, " (scr_env group detached)")

	var ocean_n := _first("scr_ocean")
	if ocean_n != null:
		ocean_n.visible = _ocean
		print("AERIAL: ocean visible = ", ocean_n.visible)

	# 0006: hide the bird pool. The aerial capture also feeds the 0005
	# check_shoreline_foam.py gate ("every bright pixel over open water is
	# shoreline foam"), and white seabirds over the ocean read as OFFSHORE
	# foam there — measured on the schema-5 fixture: 331 out-of-band px, all
	# flat (245,247,255), radius 98..112 u = the flock's orbit ring
	# (FLOCK waypoint r 88..108). Same display-condition class as --fog=0
	# (docs/04 §8.6); scr_flora stays visible — land pixels are filtered and
	# foliage never reached the bright threshold (all offenders were birds).
	var fauna_n := _first("scr_fauna")
	if fauna_n != null:
		fauna_n.visible = false
		print("AERIAL: fauna hidden = true (foam gate: birds must not read as foam)")

	var cam := _first("scr_camera") as Camera3D
	if cam == null:
		_fail(1, "scr_camera missing"); return

	# --- terrain inventory (what the TERRAIN section actually materialised) --
	var terrain := _first("scr_terrain")
	var chunks := 0
	var total_tris := 0
	var v_min := Vector3(INF, INF, INF)
	var v_max := Vector3(-INF, -INF, -INF)
	if terrain != null:
		for c in terrain.get_children():
			if not String(c.name).begins_with("Chunk_"):
				continue
			chunks += 1
			var mi := c as MeshInstance3D
			if mi == null or mi.mesh == null:
				print("AERIAL: %s has NO mesh" % c.name); continue
			var m := mi.mesh as ArrayMesh
			var aabb := mi.get_aabb()
			var tris := 0
			var surf := 0
			while surf < m.get_surface_count():
				var arr := m.surface_get_arrays(surf)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				tris += idx.size() / 3
				for v in verts:
					v_min = v_min.min(v)
					v_max = v_max.max(v)
				surf += 1
			total_tris += tris
			print("AERIAL: %s surf=%d tris=%d aabb=(%.1f,%.1f,%.1f)+(%.1f,%.1f,%.1f)"
				% [c.name, m.get_surface_count(), tris,
				   aabb.position.x, aabb.position.y, aabb.position.z,
				   aabb.size.x, aabb.size.y, aabb.size.z])
	print("AERIAL: chunks=%d total_tris=%d verts y in [%.2f, %.2f] x in [%.1f, %.1f] z in [%.1f, %.1f]"
		% [chunks, total_tris, v_min.y, v_max.y, v_min.x, v_max.x, v_min.z, v_max.z])
	if chunks < 1:
		_fail(1, "no Chunk_* meshes — TERRAIN not applied"); return

	# --- optional: disable back-face culling on the terrain materials --------
	# Surfaces share one StandardMaterial3D per material id (adapter cache),
	# so touching each distinct Ref is enough; we just set every surface.
	var cull_off := 0
	if not _cull and terrain != null:
		for c in terrain.get_children():
			var mi := c as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var m := mi.mesh as ArrayMesh
			for s in m.get_surface_count():
				var sm := m.surface_get_material(s)
				if sm is BaseMaterial3D and (sm as BaseMaterial3D).cull_mode != BaseMaterial3D.CULL_DISABLED:
					(sm as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
					cull_off += 1
	print("AERIAL: cull_mode=%s (materials switched to CULL_DISABLED: %d)"
		% ["BACK(default)" if _cull else "DISABLED", cull_off])

	# --- park the camera (default: straight down over the island centre) -----
	# Godot YXZ euler: rotation.x = -PI/2 points the camera -Z axis at -Y
	# (straight down); screen-up is world -Z, screen-right is world +X.
	var target_pos := Vector3(0.0, _alt, 0.0)
	var target_rot := Vector3(-PI / 2.0, 0.0, 0.0)
	if _has_pos:
		target_pos = _pos
	if _has_rot:
		target_rot = Vector3(deg_to_rad(_rot_deg.x), deg_to_rad(_rot_deg.y),
		                     deg_to_rad(_rot_deg.z))
	cam.global_position = target_pos
	cam.rotation = target_rot
	for i in 4:
		await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw

	# Prove the adapter did not fight back.
	if cam.global_position.distance_to(target_pos) > 0.01:
		_fail(1, "camera was overwritten (camera_follow not honoured): pos=%s"
			% str(cam.global_position)); return
	print("AERIAL: camera pos=%s rot=%s"
		% [str(cam.global_position), str(cam.rotation)])

	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		_fail(2, "viewport image unavailable"); return

	var out := _png
	if out.begins_with("res://") or out.begins_with("user://"):
		out = ProjectSettings.globalize_path(out)
	elif not out.begins_with("/"):
		out = OS.get_environment("PWD") + "/" + out
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var err := img.save_png(out)
	if err != OK:
		_fail(2, "save_png(%s) failed err=%d" % [out, err]); return
	print("AERIAL: wrote ", out, " ", img.get_width(), "x", img.get_height())
	print("AERIAL: PASS")
	quit(0)
