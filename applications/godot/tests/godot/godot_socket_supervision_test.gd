# godot_socket_supervision_test.gd — driver for the 0008 Sprint 03 socket
# supervision gate (0008 §1.1 / §7 "supervised restart").
#
# Loads the real island scene and watches the HUD tick counter, which is the
# render thread's own view of the snapshot stream (adapter -> ScrSim -> HUD).
# That makes the assertions end-to-end: a restarted session only shows up here
# if the ADAPTER re-handshaked, the SERVER issued a fresh session and the
# RENDER THREAD consumed the post-restart snapshots.
#
# Window ($SCR_TEST_WINDOW, seconds): how long the cap/refusal modes hold the
# scene alive before quitting. Defaults: 6 (refusal), 20 (cap).
#
# Modes ($SCR_TEST_MODE):
#   restart  (default) wait for a running session, then wait for the shell to
#            kill -9 the server: expect the tick to RESET backwards (fresh
#            session, same seed) and then climb again (snapshots resumed).
#   cap      hold the scene alive while fake_server.py crash-loops; the
#            adapter must go FATAL after > 5 restarts / 30 s (shell asserts).
#   refusal  hold the scene alive while fake_server.py refuses the handshake;
#            the adapter must stay inert (shell asserts the log).
#
# Run (the shell wrapper sets the env and does the killing):
#   SCR_SIM_TRANSPORT=socket SCR_TEST_MODE=restart \
#     godot --headless --path applications/godot/godot \
#       -s applications/godot/tests/godot/godot_socket_supervision_test.gd
#
# Verdict lines: "SCR-TEST: SUPERVISION PASS" (restart mode), "PASS:/FAIL:"
# per check. Exit 0 iff no FAIL.
extends SceneTree

var _fail := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		print("FAIL: ", msg)
		_fail += 1

func _initialize() -> void:
	_run()

func _first(g: String) -> Node:
	var arr := get_nodes_in_group(g)
	return arr[0] if arr.size() > 0 else null

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

# "tick %d | gen %d | seed %d" (scripts/hud.gd) -> the tick, or -1.
func _tick(hud: Node) -> int:
	if hud == null:
		return -1
	var t := String((hud as Label).text) if hud is Label else ""
	if not t.begins_with("tick "):
		return -1
	var num := ""
	for ch in t.substr(5):
		if ch >= "0" and ch <= "9":
			num += ch
		else:
			break
	return int(num) if num != "" else -1

func _run() -> void:
	var mode := OS.get_environment("SCR_TEST_MODE")
	if mode == "":
		mode = "restart"
	var win := float(OS.get_environment("SCR_TEST_WINDOW"))

	var ps: PackedScene = load("res://scenes/island.tscn")
	if ps == null:
		print("FAIL: island.tscn failed to load")
		quit(1)
		return
	root.add_child(ps.instantiate())
	await _frames(15)

	if mode == "refusal":
		await create_timer(win if win > 0.0 else 6.0).timeout
		print("SCR-TEST: refusal window elapsed (adapter must be inert)")
		quit(0 if _fail == 0 else 1)
		return
	if mode == "cap":
		# 6 spawns x (spawn+handshake+EOF) + 100..1600 ms backoff ~= 4 s;
		# 20 s leaves a wide margin for the cap to trip and be reported.
		await create_timer(win if win > 0.0 else 20.0).timeout
		print("SCR-TEST: cap window elapsed")
		quit(0 if _fail == 0 else 1)
		return

	# --- mode=restart --------------------------------------------------------
	var hud: Node = _first("scr_hud")
	var last := -1
	var saw_running := false
	var reset_from := -1
	var reset_to := -1

	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		if hud == null:
			hud = _first("scr_hud")
		var t := _tick(hud)
		if t < 0:
			continue
		if not saw_running and t >= 3:
			saw_running = true
			print("SCR-TEST: session A running tick=", t)
		if saw_running and last >= 0 and t < last:
			reset_from = last
			reset_to = t
			print("SCR-TEST: tick reset ", reset_from, " -> ", reset_to)
			break
		last = t
	_check(saw_running, "session A produced snapshots (tick >= 3)")
	_check(reset_from >= 0, "tick reset observed (fresh session after kill)")
	if reset_from < 0:
		print("SCR-TEST: SUPERVISION FAIL")
		quit(1)
		return

	var resumed := false
	var resume_deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < resume_deadline:
		await physics_frame
		var t := _tick(hud)
		if t > reset_to + 5:
			resumed = true
			print("SCR-TEST: snapshots resumed at tick=", t)
			break
	_check(resumed, "snapshots resumed after the restart")

	if _fail == 0:
		print("SCR-TEST: SUPERVISION PASS")
	else:
		print("SCR-TEST: SUPERVISION FAIL")
	quit(0 if _fail == 0 else 1)
