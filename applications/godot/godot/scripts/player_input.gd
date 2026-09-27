# player_input.gd — raw input capture + uplink to the simulation.
#
# SCOPE (milestone_0002 spec §2 AP-8, invariant 1/2): this script contains
# ZERO gameplay logic. It never moves nodes, never touches world state, never
# reads/writes sim fields. It only:
#   1. captures/releases the mouse (click = capture, Esc = release),
#   2. accumulates mouse-look deltas while captured,
#   3. reads the input map (project.godot `input` actions) and forwards the
#      raw intent vector EVERY physics frame to ScrSim.submit_input(...).
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
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
