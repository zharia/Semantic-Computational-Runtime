# godot_render_stall_test.gd — 0008 §7 "Render thread never blocks on I/O".
#
# Measures the wall-clock gap between consecutive main-loop iterations
# (process_frame) and physics iterations (physics_frame) while the shell
# SIGSTOPs the sim server for 2 s. If any socket syscall sat on the frame
# path, the gap would balloon to the length of the stall; the contract's
# bound is FRAME_DT_CLAMP = 0.05 s (docs/04 §8).
#
# Contract: 0008 AP-15 (structural grep, done in the .sh) + this measured
# stall test. Run by tests/godot/godot_render_stall_test.sh.
#
# Verdict lines:
#   PASS: max physics frame gap 0.0xx s < 0.05 s
#   PASS: max process frame gap 0.0xx s < 0.05 s
#   SCR-TEST: STALL PASS|FAIL
# Exit 0 iff every gap stayed under the clamp.
extends SceneTree

const FRAME_DT_CLAMP := 0.05

var _running := true
var _max_phys := 0.0
var _max_proc := 0.0

func _initialize() -> void:
	_run()

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		print("FAIL: ", msg)

func _first(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _sample_phys() -> void:
	var last := Time.get_ticks_usec()
	while _running:
		await physics_frame
		var now := Time.get_ticks_usec()
		_max_phys = maxf(_max_phys, float(now - last) / 1000000.0)
		last = now

func _sample_proc() -> void:
	var last := Time.get_ticks_usec()
	while _running:
		await process_frame
		var now := Time.get_ticks_usec()
		_max_proc = maxf(_max_proc, float(now - last) / 1000000.0)
		last = now

func _run() -> void:
	var window := float(OS.get_environment("SCR_TEST_WINDOW"))
	if window <= 0.0:
		window = 14.0

	var ps: PackedScene = load("res://scenes/island.tscn")
	if ps == null:
		print("FAIL: island.tscn failed to load")
		quit(1)
		return
	root.add_child(ps.instantiate())

	# Warm up: scene construction, first snapshot, HUD populated. The measured
	# window only starts once the steady state is reached.
	await _frames(60)
	if _first("scr_hud") == null:
		print("FAIL: scr_hud missing")
		quit(1)
		return
	print("SCR-TEST: window open (measuring for ", window, " s)")

	# Both samplers run as fire-and-forget coroutines: each awaits its own
	# signal every iteration, so they never block each other or this driver.
	_sample_phys()
	_sample_proc()
	await create_timer(window).timeout
	_running = false
	await _frames(3) # let both loops see _running == false and return

	_check(_max_phys < FRAME_DT_CLAMP,
	       "max physics frame gap %.4f s < %.2f s" % [_max_phys, FRAME_DT_CLAMP])
	_check(_max_proc < FRAME_DT_CLAMP,
	       "max process frame gap %.4f s < %.2f s" % [_max_proc, FRAME_DT_CLAMP])
	if _max_phys < FRAME_DT_CLAMP and _max_proc < FRAME_DT_CLAMP:
		print("SCR-TEST: STALL PASS")
		quit(0)
	else:
		print("SCR-TEST: STALL FAIL")
		quit(1)
