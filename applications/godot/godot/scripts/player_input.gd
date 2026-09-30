# player_input.gd — raw input capture + uplink to the simulation.
#
# SCOPE (milestone_0002 spec §2 AP-8, invariant 1/2; milestone_0007 §3.2):
# this script contains ZERO gameplay logic. It never moves nodes, never
# touches world state, never reads/writes sim fields. It only:
#   1. captures/releases the mouse (click = capture, Esc = release),
#   2. accumulates mouse-look deltas while captured,
#   3. reads the input map (project.godot `input` actions) and forwards the
#      raw intent vector EVERY physics frame to ScrSim.submit_input(...),
#   4. (0007) forwards raw edit intent to ScrSim.submit_edit(op,
#      select_slot): LMB while captured = dig (op 1), RMB while captured =
#      place (op 2), keys 1-9 = select slot, wheel up/down = cycle slot.
#      The script never names materials or cells — the sim resolves both
#      from its raycast + hotbar state (0007 AP-12/AP-13). All device
#      mapping is intent passthrough, presented here because this script
#      is the scene's single input-capture point.
# Locomotion integration (walk/sprint/jump/gravity) lives in the sim:
# src/mojo/sim/subjects.mojo. Sign conventions (contract, 104_contract §5):
#   move_x = +right, move_y = +forward, look_dx/dy = mouse pixels (device
#   space: +x = mouse right, +y = mouse down). The device->world mapping
#   (yaw positive = left/CCW, so mouse right DECREASES yaw) and MOUSE_SENSITIVITY
#   are applied by the sim input decode — see subjects.mojo collect_intent.
#   This script stays a raw passthrough (AP-8: no gameplay logic).
extends Node3D

@export var sim_path: NodePath = NodePath("ScrSim")

var _sim: Node = null
var _look_accum: Vector2 = Vector2.ZERO

func _ready() -> void:
	_sim = get_node_or_null(sim_path)
	if _sim == null:
		push_warning("player_input: ScrSim node not found — uplink disabled")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					_submit_edit(1, 0) # dig (0007: captured click = op 1)
				else:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_RIGHT:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					_submit_edit(2, 0) # place (0007: op 2)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					_cycle_slot(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					_cycle_slot(-1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
		else:
			# Keys 1-9 = direct slot select (0007 §5 Sprint-03). Physical
			# keycode so the row works on any layout.
			var digit := _digit_of(event.physical_keycode)
			if digit >= 1:
				_submit_edit(0, digit)
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Accumulated here, flushed every physics frame (adapter also
		# accumulates across frames and resets after batching — see
		# scr_godot_adapter.cpp submit_input). Pixels, not radians.
		_look_accum += event.relative

func _physics_process(_delta: float) -> void:
	if _sim == null:
		return
	# Input.get_vector(neg_x, pos_x, neg_y, pos_y): y = back − forward,
	# so −v.y = +1 when W/up is held (sim: move_y = +forward).
	var v: Vector2 = Input.get_vector("move_left", "move_right",
	                                  "move_forward", "move_back")
	_sim.submit_input(v.x, -v.y, _look_accum.x, _look_accum.y,
	                  Input.is_action_pressed("jump"),
	                  Input.is_action_pressed("sprint"),
	                  false, false)
	_look_accum = Vector2.ZERO

# --- 0007 edit intent passthrough -----------------------------------------
# `select_slot`: 0 = no change, 1..9 = select (sim validates, AP-13).
# `op`: 0 none, 1 dig, 2 place. Never materials, never cells (AP-12).

func _submit_edit(op: int, select_slot: int) -> void:
	if _sim == null or not _sim.has_method("submit_edit"):
		return
	_sim.submit_edit(op, select_slot)

## Wheel cycle: next slot relative to the LAST DECODED sim selection
## (display mirror, bound read-only by the adapter) — the sim still
## validates and applies the intent (AP-12/AP-13).
func _cycle_slot(delta: int) -> void:
	if _sim == null or not _sim.has_method("get_hotbar_selected_slot"):
		return
	var current: int = _sim.get_hotbar_selected_slot()
	# wrapi(x, 1, 10) yields 1..9 — cycle wraps at the ends.
	_submit_edit(0, wrapi(current + delta, 1, 10))

## KEY_1..KEY_9 -> 1..9, anything else -> 0.
func _digit_of(keycode: Key) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return int(keycode - KEY_1) + 1
	return 0
