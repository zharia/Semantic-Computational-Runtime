# hud.gd — controls/capture hint line ONLY (attached to the Controls Label).
#
# The adapter owns the state line: group `scr_hud` Label gets
# "tick %d | gen %d | seed %d" every frame (scr_godot_adapter.cpp apply_hud).
# This script NEVER writes that label and never duplicates sim state (AP-8).
# It only swaps the static input-hint text with the mouse-capture state,
# which is device/presentation state, not world state.
extends Label

const HINT_CAPTURED := "WASD/arrows move | Shift sprint | Space jump | Esc release mouse"
const HINT_FREE := "Click to capture mouse | WASD/arrows move | Shift sprint | Space jump"

func _ready() -> void:
	text = HINT_FREE

func _process(_delta: float) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if captured and text != HINT_CAPTURED:
		text = HINT_CAPTURED
	elif not captured and text != HINT_FREE:
		text = HINT_FREE
