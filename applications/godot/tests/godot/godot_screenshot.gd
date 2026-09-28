# godot_screenshot.gd — automated island screenshot + content/plume/lava checks.
#
# Spec: milestone_0002 §7 exit criterion 2 (luminance capture) and
#       milestone_0003 §7 exit criterion 8 (plume presence via a region check
#       around the caldera centre) + lava rendering evidence.
#
# Run (RENDERED game mode — a display/GPU is required; do NOT pass --headless):
#   timeout 300 godot --path applications/godot/godot \
#       -s applications/godot/tests/godot/godot_screenshot.gd -- \
#       --png=applications/godot/build/island.png \
#       --png2=applications/godot/build/island_crater.png
# (or use the runner: bash applications/godot/tests/godot/godot_screenshot.sh)
#
# Night-glow procedure (docs/04 §8) reuses this script with --expect-glow.
#
# Exit codes: 0 PASS · 1 scene/content assertion failed · 2 capture failed ·
#             3 image blank (luminance check failed).
#
# Phases
#   A. Tick-wait: run until the HUD reports tick >= --tick-min (default 1900).
#      Rationale (docs/04 §8): seed-1 effusion is active on ticks 1500..2099;
#      the plume needs `lifetime` (6 s) of emission to reach steady state, so
#      1900 + 60 settle frames captures a fully developed plume at ~1960.
#      Spawn-view capture -> --png.
#   B. Crater-view capture -> --png2 (the caldera floor is occluded from the
#      spawn camera by the rim, so the lava assertion needs its own view;
#      camera_follow is a documented debug aid — temporarily disabled).
#   A2. Sun-aimed sky capture -> --png3 (0004 §7 "sun visible in frame").
#      DEVIATION (recorded in docs/04 §8.4): the §1.1-locked solar arc puts
#      the noon sun at SUN_ELEVATION_MAX = 1.2 rad (68.75 deg) while the spawn
#      camera is pitch ~0 with a 70 deg FOV (half-angle 35 deg), so the disc
#      cannot enter the pitch-0 spawn frame — it sits 33.75 deg above the top
#      edge (0002 already logged this as an honest gap; 0004 §1.1 locked the
#      arc instead of the camera). The sub-capture therefore keeps the spawn
#      POSITION and aims the camera along the sun's +Z (the adapter's
#      documented DirectionalLight3D convention), proving the disc renders
#      from SKY bytes. The spawn view itself is asserted untouched.
#   C. Rain-window capture -> --png4: camera_follow restored, wait until the
#      sim reports a tick inside the seed-1 precipitation window, capture the
#      spawn view again and assert overcast sky + falling streaks.
#
# Assertions (beyond raw luminance):
#   * Terrain Chunk_* children, scr_meta fields, HUD text (0002 pipeline).
#   * Node state: scr_plume emitting == (rate > 0), amount == rate*lifetime,
#     lifetime/spread/initial velocity/turbulence from the PLUME section;
#     scr_crater_lava transform + lava shader uniforms from VOLCANO;
#     scr_crater_glow energy == sim glow (0 by day, > 0 with --expect-glow).
#   * Plume region check (0003 §7): non-sky pixels in the crater-above column
#     (rows 0.02H..0.12H x cols 0.40W..0.60W) vs a per-row sky reference taken
#     from the left/right image margins (fog makes the horizon row-dependent).
#   * Lava region check (phase B): warm pixels (R>=120, R>=G+25, R>=B+60)
#     near the projected centre of the scr_crater_lava node.
#   * Night glow (--expect-glow, phase A): warm pixels in the volcano
#     silhouette band — the crater light spills onto the outer flank (no
#     shadows, omni_range covers it) and must stand out above background.
#
# All thresholds are display-verification constants, not gameplay values;
# provenance recorded in docs/04_simulation_engine.md §8.
extends SceneTree

var _png_path := "res://../build/island.png"
var _png2_path := "res://../build/island_crater.png"
var _png3_path := "res://../build/island_sun.png"
var _png4_path := "res://../build/island_rain.png"
# Seed-1 precipitation window is ticks 1801..8100 (test_weather.mojo
# SEED1_FIRST_RAIN_TICK); 4200 sits mid-MONSOON (cover 0.97, precip 0.8).
var _rain_tick := 4200
var _settle_frames := 60
var _tick_min := 1900
var _expect_glow := false
var _lava_centre := Vector3.ZERO
var _lava_cam: Camera3D = null

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--png="):
			_png_path = a.trim_prefix("--png=")
		elif a.begins_with("--png2="):
			_png2_path = a.trim_prefix("--png2=")
		elif a.begins_with("--png3="):
			_png3_path = a.trim_prefix("--png3=")
		elif a.begins_with("--png4="):
			_png4_path = a.trim_prefix("--png4=")
		elif a.begins_with("--rain-tick="):
			_rain_tick = maxi(0, int(a.trim_prefix("--rain-tick=")))
		elif a.begins_with("--frames="):
			_settle_frames = maxi(1, int(a.trim_prefix("--frames=")))
		elif a.begins_with("--tick-min="):
			_tick_min = maxi(0, int(a.trim_prefix("--tick-min=")))
		elif a.begins_with("--expect-glow"):
			_expect_glow = true
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

	# --- phase A: tick-wait to a fully developed plume ----------------------
	var hud := _first_in_group("scr_hud") as Label
	var tick := -1
	var waited := 0
	var frame_cap := _tick_min + 2000
	while true:
		tick = _tick_now(hud)
		if tick >= _tick_min:
			break
		if waited > frame_cap:
			_fail(1, "sim stuck: tick %d never reached %d" % [tick, _tick_min]); return
		if waited % 600 == 0:
			print("SCREENSHOT: waiting for tick >= %d (now %d)" % [_tick_min, tick])
		waited += 1
		await process_frame
	print("SCREENSHOT: tick target reached: %d" % tick)

	# Settle by TICK, not by frames: on a slow render loop Godot executes
	# several fixed physics ticks per rendered frame (observed ~4), so a
	# frame-based settle raced past the effusion window (ticks 1500..2099).
	var settle_target := _tick_min + 40
	while _tick_now(hud) < settle_target:
		if _tick_now(hud) >= 2100:
			_fail(1, "settled past effusion window (tick %d >= 2100)" % _tick_now(hud)); return
		await process_frame

	# Node state MUST be asserted at capture time (window + sim continue to
	# run while PNGs are written and pixels are scanned).
	var state_tick := _tick_now(hud)
	print("SCREENSHOT: state assertions at tick %d" % state_tick)
	if state_tick < _tick_min or state_tick >= 2100:
		_fail(1, "capture tick %d outside effusing window [1900,2100)" % state_tick); return
	if not _check_node_state():
		return

	# --- capture ALL views back to back BEFORE any heavy checks -------------
	var img: Image = await _capture()
	if img == null:
		return
	# Night-glow run (SCR_EXPECT_GLOW): the sun is below the horizon and the
	# sky is dark, so the sun-disc sub-capture and the rain-window capture are
	# daytime-only assertions — both are skipped (docs/04 §8.4).
	var img_sun: Image = null
	if not _expect_glow:
		img_sun = await _capture_sun()
		if img_sun == null:
			return
	var img2: Image = await _capture_crater()
	if img2 == null:
		return

	# --- phase A checks ------------------------------------------------------
	var err := _save_png(img, _png_path)
	if err != OK:
		_fail(2, "save_png(%s) failed err=%d" % [_png_path, err]); return
	if not _check_luminance(img, "spawn"):
		return

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

	if hud == null or not String(hud.text).begins_with("tick "):
		_fail(1, "scr_hud text not set by adapter (snapshot not applied)"); return
	print("SCREENSHOT: hud = ", hud.text)

	# Night run: the sky is now derived from the SKY palette and is dark, and
	# the (unlit) ash plume is dark too — a colour-deviation region check has
	# no contrast left. Plume PRESENCE is still asserted by _check_node_state
	# (emitting / amount / lifetime / velocity). Day run keeps the region
	# check. (docs/04 §8.4)
	if not _expect_glow and not _check_plume_region(img):
		return

	if _expect_glow and not _check_glow_region(img):
		return

	# --- phase A2 checks (sun disc, docs/04 §8.4 deviation) ------------------
	if img_sun != null:
		err = _save_png(img_sun, _png3_path)
		if err != OK:
			_fail(2, "save_png(%s) failed err=%d" % [_png3_path, err]); return
		if not _check_sun_disc(img_sun):
			return

	# --- phase B checks ------------------------------------------------------
	err = _save_png(img2, _png2_path)
	if err != OK:
		_fail(2, "save_png(%s) failed err=%d" % [_png2_path, err]); return
	if not _check_lava_region(img2):
		return

	# --- phase C: rain-window capture (daytime only) -------------------------
	if not _expect_glow and not await _capture_and_check_rain():
		return

	print("SCREENSHOT: PASS")
	quit(0)

func _tick_now(hud: Label) -> int:
	if hud != null and String(hud.text).begins_with("tick "):
		return int(String(hud.text).trim_prefix("tick ").split(" ")[0])
	return -1

func _capture() -> Image:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		_fail(2, "viewport image unavailable")
		return null
	return img

func _save_png(img: Image, path: String) -> Error:
	var out := path
	if out.begins_with("res://") or out.begins_with("user://"):
		out = ProjectSettings.globalize_path(out)
	elif not out.begins_with("/"):
		out = OS.get_environment("PWD") + "/" + out
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var err := img.save_png(out)
	if err == OK:
		print("SCREENSHOT: wrote ", out)
	return err

func _check_luminance(img: Image, tag: String) -> bool:
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
	print("SCREENSHOT: %s %dx%d mean_luminance=%.2f stddev=%.2f" % [tag, w, h, mean, stddev])
	# Night run (SCR_EXPECT_GLOW): the sky gradient is now DERIVED from the
	# SKY palette (0004), so a night frame is legitimately dark — 0002's
	# static bright skybox is gone (docs/04 §8.4). Thresholds drop to a
	# "not a black frame" floor; the glow-region check carries the night
	# assertion.
	var mean_min := 10.0
	var std_min := 5.0
	if _expect_glow:
		mean_min = 3.0
		std_min = 1.5
	if mean <= mean_min:
		_fail(3, "%s mean luminance %.2f <= %.1f (blank/dark frame)" % [tag, mean, mean_min]); return false
	if stddev <= std_min:
		_fail(3, "%s stddev %.2f <= %.1f (uniform frame, no content)" % [tag, stddev, std_min]); return false
	return true

func _check_node_state() -> bool:
	# --- scr_plume ---------------------------------------------------------
	var plume_n: Node = _first_in_group("scr_plume")
	if plume_n == null:
		_fail(1, "group scr_plume absent from island.tscn"); return false
	var plume := plume_n as GPUParticles3D
	if plume == null:
		_fail(1, "scr_plume is not a GPUParticles3D"); return false
	if not plume.emitting:
		_fail(1, "scr_plume.emitting == false at effusing tick (PLUME not applied)"); return false
	if plume.amount != 360:
		_fail(1, "scr_plume.amount = %d, expected 360 (rate 60/s x lifetime 6 s)" % plume.amount); return false
	if absf(plume.lifetime - 6.0) > 0.001:
		_fail(1, "scr_plume.lifetime = %f, expected 6.0" % plume.lifetime); return false
	var pm := plume.process_material as ParticleProcessMaterial
	if pm == null:
		_fail(1, "scr_plume.process_material is not a ParticleProcessMaterial"); return false
	if absf(pm.initial_velocity_min - 8.5) > 0.001 or absf(pm.initial_velocity_max - 8.5) > 0.001:
		_fail(1, "plume initial velocity %f/%f, expected 8.5" % [pm.initial_velocity_min, pm.initial_velocity_max]); return false
	if absf(pm.spread - 15.0) > 0.001:
		_fail(1, "plume spread %f, expected 15.0" % pm.spread); return false
	if not pm.turbulence_enabled:
		_fail(1, "plume turbulence_enabled == false (PLUME.turbulence not applied)"); return false
	# Godot velocity-influence turbulence collapses the buoyant column
	# (docs/04 §8): the adapter gates the noise field on PLUME.turbulence but
	# must hold the influence channel at 0 — guard against regressions here.
	if pm.turbulence_influence_min > 0.0001 or pm.turbulence_influence_max > 0.0001:
		_fail(1, "plume turbulence influence %f/%f, expected 0 (column collapse)" %
		      [pm.turbulence_influence_min, pm.turbulence_influence_max]); return false
	if pm.gravity != Vector3.ZERO:
		_fail(1, "plume gravity %s, expected zero (buoyant display = velocity only)" % str(pm.gravity)); return false
	print("SCREENSHOT: plume emitting amount=%d lifetime=%.1f v0=%.2f spread=%.1f turbulence_enabled=%s influence=%.2f" %
	      [plume.amount, plume.lifetime, pm.initial_velocity_min, pm.spread, str(pm.turbulence_enabled), pm.turbulence_influence_min])

	# --- scr_crater_lava ---------------------------------------------------
	var lava_n: Node = _first_in_group("scr_crater_lava")
	if lava_n == null:
		_fail(1, "group scr_crater_lava absent from island.tscn"); return false
	var lava := lava_n as MeshInstance3D
	if lava == null:
		_fail(1, "scr_crater_lava is not a MeshInstance3D"); return false
	var mat := lava.material_override as ShaderMaterial
	if mat == null:
		_fail(1, "scr_crater_lava.material_override is not a ShaderMaterial"); return false
	var emissive := float(mat.get_shader_parameter("emissive_intensity"))
	var crust := float(mat.get_shader_parameter("crust_fraction"))
	var radius := float(mat.get_shader_parameter("radius"))
	if emissive <= 0.0:
		_fail(1, "lava emissive_intensity %f <= 0 (VOLCANO not applied)" % emissive); return false
	if crust < 0.0 or crust > 1.0:
		_fail(1, "lava crust_fraction %f outside [0,1]" % crust); return false
	if absf(lava.scale.x - radius) > 0.01 or absf(lava.scale.z - radius) > 0.01:
		_fail(1, "lava scale %s != shader radius %f (transform/uniform disagree)" % [str(lava.scale), radius]); return false
	var meta_chk: Node = _first_in_group("scr_meta")
	var sea := float(meta_chk.get_meta("sea_level")) if meta_chk != null else -1.0
	if lava.global_position.y <= sea:
		_fail(1, "lava lake y %f not above sea_level %f" % [lava.global_position.y, sea]); return false
	print("SCREENSHOT: lava emissive=%.3f crust=%.3f radius=%.2f pos=%s" %
	      [emissive, crust, radius, str(lava.global_position)])

	# --- scr_crater_glow ---------------------------------------------------
	var glow_n: Node = _first_in_group("scr_crater_glow")
	if glow_n == null:
		_fail(1, "group scr_crater_glow absent from island.tscn"); return false
	var glow := glow_n as OmniLight3D
	if glow == null:
		_fail(1, "scr_crater_glow is not an OmniLight3D"); return false
	if _expect_glow:
		if glow.light_energy <= 0.05:
			_fail(1, "night run: crater glow light_energy = %f, expected > 0" % glow.light_energy); return false
	else:
		if glow.light_energy > 0.0001:
			_fail(1, "day run: crater glow light_energy = %f, expected 0 (sim night_factor)" % glow.light_energy); return false
	print("SCREENSHOT: crater glow light_energy=%.3f" % glow.light_energy)
	return true

# Plume: non-sky pixels in the crater-above column (0003 §7 region check).
# Sky reference per row = median of the left/right 5% margin columns; the
# plume window sits above the rim silhouette, so deviation there is plume.
func _check_plume_region(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var data := _rgba(img)
	var r0 := int(0.02 * h)
	var r1 := int(0.12 * h)
	var c0 := int(0.40 * w)
	var c1 := int(0.60 * w)
	var margin := int(0.05 * w)
	var rows_hit := 0
	var px_hit := 0
	var row := r0
	while row < r1:
		# Per-channel sky reference: median of each channel separately over
		# the left/right margin columns. (A summed-median reference divides
		# the sky sum by 3 and misreads every chromatic sky pixel as a hit.)
		var rr := PackedInt32Array()
		var gg := PackedInt32Array()
		var bb := PackedInt32Array()
		var xm := 0
		while xm < margin:
			var i3 := (row * w + xm) * 4
			rr.append(int(data[i3]))
			gg.append(int(data[i3 + 1]))
			bb.append(int(data[i3 + 2]))
			var i3r := (row * w + (w - 1 - xm)) * 4
			rr.append(int(data[i3r]))
			gg.append(int(data[i3r + 1]))
			bb.append(int(data[i3r + 2]))
			xm += 4
		rr.sort()
		gg.sort()
		bb.sort()
		var ref_r := rr[rr.size() / 2]
		var ref_g := gg[gg.size() / 2]
		var ref_b := bb[bb.size() / 2]
		var row_hits := 0
		var col := c0
		while col < c1:
			var i3 := (row * w + col) * 4
			var dev: int = absi(int(data[i3]) - ref_r) + \
				absi(int(data[i3 + 1]) - ref_g) + absi(int(data[i3 + 2]) - ref_b)
			# Summed per-channel deviation > 60 (i.e. avg > 20/ch): catches
			# both the grey-ramp shift (plume over sky) and chromatic offsets
			# (ash grey over blue sky) without the sum-of-channels bug above.
			if dev > 60:
				row_hits += 1
				px_hit += 1
			col += 4
		if row_hits >= 10:
			rows_hit += 1
		row += 1
	print("SCREENSHOT: plume window rows_with_10plus_hits=%d of %d, deviating_px=%d" %
	      [rows_hit, r1 - r0, px_hit])
	if rows_hit < 5:
		_fail(1, "plume region check failed: %d rows with >=10 deviating px (need 5)" % rows_hit); return false
	return true

# Night glow: warm pixels (R clearly above B) in the volcano silhouette band.
func _check_glow_region(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var data := _rgba(img)
	var r0 := int(0.10 * h)
	var r1 := int(0.75 * h)
	var c0 := int(0.30 * w)
	var c1 := int(0.70 * w)
	var warm := 0
	var row := r0
	while row < r1:
		var col := c0
		while col < c1:
			var i3 := (row * w + col) * 4
			var r := int(data[i3])
			var g := int(data[i3 + 1])
			var b := int(data[i3 + 2])
			if r >= 70 and r - b >= 30 and r >= g - 10:
				warm += 1
			col += 4
		row += 2
	print("SCREENSHOT: glow band warm_px=%d" % warm)
	# Dome box (crater-above silhouette): warm count + max r-b + luminance.
	var d_warm10 := 0
	var d_maxrb := -999
	var d_lum := 0.0
	var d_n := 0
	for yy3 in range(85, 130):
		for xx3 in range(560, 780):
			var j3 := (yy3 * w + xx3) * 4
			var rr := int(data[j3])
			var gg := int(data[j3 + 1])
			var bb := int(data[j3 + 2])
			if rr - bb > d_maxrb:
				d_maxrb = rr - bb
			if rr >= 70 and rr - bb >= 10 and rr >= gg - 10:
				d_warm10 += 1
			d_lum += 0.2126 * rr + 0.7152 * gg + 0.0722 * bb
			d_n += 1
	var f_lum := 0.0
	var f_n := 0
	for yy4 in range(200, 260):
		for xx4 in range(300, 450):
			var j4 := (yy4 * w + xx4) * 4
			f_lum += 0.2126 * int(data[j4]) + 0.7152 * int(data[j4 + 1]) 				+ 0.0722 * int(data[j4 + 2])
			f_n += 1
	print("SCREENSHOT: dome warm10=%d max_r_minus_b=%d lum=%.1f | flank lum=%.1f" %
	      [d_warm10, d_maxrb, d_lum / maxf(float(d_n), 1.0),
	       f_lum / maxf(float(f_n), 1.0)])
	if d_warm10 < 50 or d_maxrb < 25:
		_fail(1, "night glow check failed: dome warm10=%d max_r-b=%d (need >=50 / >=25)" %
			[d_warm10, d_maxrb]); return false
	return true

# Phase A2 (0004 §7, documented deviation — see file header): keep the spawn
# position, aim the camera at the sun disc.
#
# AIM CONSTRUCTION: the adapter orients the DirectionalLight3D with
#   rotation = (-sun_elevation, sun_azimuth, 0) so that the node's +Z axis
#   points AT the sun (scr_godot_adapter.cpp file header). Godot cameras look
#   along -Z, so `look_at(cam_position + sun_basis_z * 500, UP)` puts the disc
#   exactly at the frame centre; the up-vector keeps the horizon level.
func _capture_sun() -> Image:
	var island: Node = root.get_child(0)
	var driver := island.get_node_or_null("ScrSim")
	if driver != null and driver.has_method("set_camera_follow"):
		driver.set("camera_follow", false)
	var sun := _first_in_group("scr_sun") as DirectionalLight3D
	var cam := _first_in_group("scr_camera") as Camera3D
	if sun == null or cam == null:
		_fail(1, "sun sub-capture: missing scr_sun / scr_camera"); return null
	var meta: Node = _first_in_group("scr_meta")
	var spawn: Vector3 = Vector3(-10.0, 0.7, -87.0)
	if meta != null and meta.has_meta("spawn_position"):
		spawn = meta.get_meta("spawn_position")
	cam.global_position = spawn + Vector3(0.0, 8.0, 0.0)
	var dir: Vector3 = sun.global_transform.basis.z.normalized()
	cam.look_at(cam.global_position + dir * 500.0, Vector3.UP)
	print("SCREENSHOT: sun sub-capture dir=%s elev=%.4f rad at tick %d" %
		[str(dir), -sun.rotation.x, _tick_now(_first_in_group("scr_hud") as Label)])
	for i in 8:
		await process_frame
	print("SCREENSHOT: sun aim cam_pos=%s cam_fwd=%s follow=%s hud=%s" %
		[str(cam.global_position), str(-cam.global_transform.basis.z.normalized()),
		 str(driver != null and driver.get("camera_follow") != false),
		 _tick_now(_first_in_group("scr_hud") as Label)])
	return await _capture()

# Sun disc = high-luminance cluster at frame centre (the aim puts it there)
# against an edge reference taken from the same rows. Thresholds are display
# verification constants measured on 2026-09-28 (docs/04 §8.4).
func _check_sun_disc(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var data := _rgba(img)
	var r0 := int(0.36 * h)
	var r1 := int(0.64 * h)
	var c0 := int(0.42 * w)
	var c1 := int(0.58 * w)
	var edge_c1 := int(0.10 * w)
	var edge_c0 := int(0.90 * w)
	var centre := _box(data, w, r0, r1, c0, c1)
	var left := _box(data, w, r0, r1, 0, edge_c1)
	var right := _box(data, w, r0, r1, edge_c0, w)
	var ref := maxf(left, right)
	var bright := 0
	var mx := 0
	var row := r0
	while row < r1:
		var col := c0
		while col < c1:
			var i3 := (row * w + col) * 4
			var lum := int(0.299 * data[i3] + 0.587 * data[i3 + 1] + 0.114 * data[i3 + 2])
			if lum >= 235:
				bright += 1
			if lum > mx:
				mx = lum
			col += 2
		row += 2
	print("SCREENSHOT: sun disc centre=%.2f edge_ref=%.2f delta=%.2f bright>=235=%d max=%d" %
		[centre, ref, centre - ref, bright, mx])
	if centre - ref < 20.0:
		_fail(1, "sun disc check failed: centre-edge delta %.2f < 20.0" % (centre - ref)); return false
	if bright < 300:
		_fail(1, "sun disc check failed: %d bright px in centre box (need 300)" % bright); return false
	return true

# Phase C: restore the player camera, wait for a tick inside the seed-1
# precipitation window, capture the spawn view and assert the weather.
func _capture_and_check_rain() -> bool:
	var island: Node = root.get_child(0)
	var driver := island.get_node_or_null("ScrSim")
	if driver != null and driver.has_method("set_camera_follow"):
		driver.set("camera_follow", true)
	var hud := _first_in_group("scr_hud") as Label
	var guard := _rain_tick + 4000
	var waited := 0
	while true:
		var t := _tick_now(hud)
		if t >= _rain_tick:
			break
		if waited > guard:
			_fail(1, "rain wait: tick %d never reached %d" % [t, _rain_tick]); return false
		if waited % 600 == 0:
			print("SCREENSHOT: waiting for rain tick >= %d (now %d)" % [_rain_tick, t])
		waited += 1
		await process_frame
	var t2 := _tick_now(hud)
	# Seed-1 precipitation window (test_weather.mojo): 1801..8100.
	if t2 < 1801 or t2 > 8100:
		_fail(1, "rain capture tick %d outside seed-1 precipitation window" % t2); return false
	for i in 60:
		await process_frame
	var rain_tick := _tick_now(hud)
	var img: Image = await _capture()
	if img == null:
		return false
	var err := _save_png(img, _png4_path)
	if err != OK:
		_fail(2, "save_png(%s) failed err=%d" % [_png4_path, err]); return false
	if not _check_luminance(img, "rain"):
		return false
	print("SCREENSHOT: rain capture at tick %d (window 1801..8100)" % rain_tick)
	return _check_rain_region(img)

# Rain: overcast sky (bright background) + falling-streak pixels in a fixed
# right-of-plume sky box, plus a horizontal/vertical gradient ratio test that
# favours vertical structures (streaks are thin and elongated along Y).
# Region: rows 0..185, cols 0.61W..0.98W — clear of the HUD (rows < 80,
# cols < 660), the plume column (cols 560..730) and the terrain silhouette
# (lowest right-hand crest is ~row 195 in the spawn framing).
func _check_rain_region(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var data := _rgba(img)
	var r1 := mini(186, h)
	var c0 := int(0.61 * w)
	var c1 := int(0.98 * w)
	var lums := PackedFloat32Array()
	var row := 0
	while row < r1:
		var col := c0
		while col < c1:
			var i3 := (row * w + col) * 4
			lums.append(0.299 * data[i3] + 0.587 * data[i3 + 1] + 0.114 * data[i3 + 2])
			col += 1
		row += 1
	var sorted := lums.duplicate()
	sorted.sort()
	var med := sorted[sorted.size() / 2]
	var streak := 0
	for v in lums:
		if v <= med - 25.0:
			streak += 1
	# Gradient energy: |d/dx| across columns vs |d/dy| down rows.
	var hsum := 0.0
	var vsum := 0.0
	var hn := 0
	var vn := 0
	row = 0
	while row < r1 - 1:
		var col := c0
		while col < c1 - 1:
			var i3 := (row * w + col) * 4
			var i3x := (row * w + col + 1) * 4
			var i3y := ((row + 1) * w + col) * 4
			var l := 0.299 * data[i3] + 0.587 * data[i3 + 1] + 0.114 * data[i3 + 2]
			var lx := 0.299 * data[i3x] + 0.587 * data[i3x + 1] + 0.114 * data[i3x + 2]
			var ly := 0.299 * data[i3y] + 0.587 * data[i3y + 1] + 0.114 * data[i3y + 2]
			hsum += absf(lx - l)
			vsum += absf(ly - l)
			hn += 1
			vn += 1
			col += 1
		row += 1
	var hg := hsum / maxf(float(hn), 1.0)
	var vg := vsum / maxf(float(vn), 1.0)
	var ratio := hg / maxf(vg, 0.0001)
	print("SCREENSHOT: rain box median_lum=%.1f streak_px=%d (%.2f%%) hgrad=%.3f vgrad=%.3f ratio=%.3f" %
		[med, streak, 100.0 * float(streak) / maxf(float(lums.size()), 1.0), hg, vg, ratio])
	if med < 190.0:
		_fail(1, "rain box median luminance %.1f < 190 (overcast sky missing)" % med); return false
	if streak < 400:
		_fail(1, "rain streak check failed: %d deviating px (need 400)" % streak); return false
	if ratio < 1.10:
		_fail(1, "rain streak orientation failed: h/v gradient ratio %.3f < 1.10" % ratio); return false
	return true

func _box(data: PackedByteArray, w: int, r0: int, r1: int, c0: int, c1: int) -> float:
	var n := 0
	var sum := 0.0
	var row := r0
	while row < r1:
		var col := c0
		while col < c1:
			var i3 := (row * w + col) * 4
			sum += 0.299 * data[i3] + 0.587 * data[i3 + 1] + 0.114 * data[i3 + 2]
			n += 1
			col += 4
		row += 4
	return sum / maxf(float(n), 1.0)

# Phase B: disable the camera rig driver (documented debug aid), place the
# camera above the crater looking down at the lava disc, capture. Checks run
# later in _run so both images are grabbed before the effusion window closes.
func _capture_crater() -> Image:
	var island: Node = root.get_child(0)
	var driver := island.get_node_or_null("ScrSim")
	if driver != null and driver.has_method("set_camera_follow"):
		driver.set("camera_follow", false)
	var lava := _first_in_group("scr_crater_lava") as MeshInstance3D
	var cam := _first_in_group("scr_camera") as Camera3D
	if lava == null or cam == null:
		_fail(1, "phase B: missing scr_crater_lava / scr_camera"); return null
	_lava_centre = lava.global_position
	_lava_cam = cam
	# Stand *inside* the crater (rim crest ~y38, disc edge r~20): from
	# lava+(24,26,24) the sightline to the lake crosses the near rim ~8 u
	# below its crest and only shows sulfur terrain. +16,+24,+16 keeps the
	# camera above the inner wall and looks down onto the disc (46 deg).
	cam.global_position = _lava_centre + Vector3(16.0, 24.0, 16.0)
	cam.look_at(_lava_centre, Vector3.UP)
	for i in 5:
		await process_frame
	return await _capture()

# Lava: warm pixels within 90 px of the projected centre of the lava disc.
func _check_lava_region(img: Image) -> bool:
	var cam := _lava_cam as Camera3D
	if cam == null:
		_fail(1, "phase B: crater camera missing"); return false
	var w := img.get_width()
	var h := img.get_height()
	var sp := cam.unproject_position(_lava_centre)
	var data := _rgba(img)
	var rad := 90.0
	var warm := 0
	var r0 := clampi(int(sp.y - rad), 0, h - 1)
	var r1 := clampi(int(sp.y + rad), 0, h - 1)
	var c0 := clampi(int(sp.x - rad), 0, w - 1)
	var c1 := clampi(int(sp.x + rad), 0, w - 1)
	var row := r0
	while row <= r1:
		var col := c0
		while col <= c1:
			var dx := float(col) - sp.x
			var dy := float(row) - sp.y
			if dx * dx + dy * dy <= rad * rad:
				var i3 := (row * w + col) * 4
				var r := int(data[i3])
				var g := int(data[i3 + 1])
				var b := int(data[i3 + 2])
				if r >= 120 and r >= g + 25 and r >= b + 60:
					warm += 1
			col += 1
		row += 1
	print("SCREENSHOT: crater view warm_px=%d around projected lava centre %s" % [warm, str(sp)])
	if warm < 400:
		_fail(1, "lava region check failed: %d warm px (need 400) in crater view" % warm); return false
	return true

func _rgba(img: Image) -> PackedByteArray:
	var rgba := img.duplicate()
	rgba.convert(Image.FORMAT_RGBA8)
	return rgba.get_data()

func _first_in_group(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null
