# Minimal editor-plugin glue for the scr_godot addon.
# Nothing is enabled here: the GDExtension (.gdextension) registers the ScrSim
# node class at engine startup; this script only satisfies plugin.cfg so the
# addon appears as a (disabled) plugin in the editor.
@tool
extends EditorPlugin


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
