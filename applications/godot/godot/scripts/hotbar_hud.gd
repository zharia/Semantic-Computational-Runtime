# hotbar_hud.gd — presentation view for the §12 HOTBAR snapshot section.
#
# Milestone 0007 (spec §1.1 rendering lock, §5): the 9-slot hotbar panel
# under the `scr_hotbar` host node. This script is PRESENTATION ONLY:
#   - slot ids/names/colours arrive from the adapter (validated §12 bytes;
#     names/colours resolved through the adapter's catalog mirror — 0007
#     AP-13: this script never names a material, never hard-codes a slot
#     list, and never touches world state — AP-8);
#   - selection arrives as the §12 `selected_index` (sim state; the HUD is
#     a read-only projection — A01_Render/HUD §1, invariant 10);
#   - intent goes the other way: player_input.gd submits {op, select_slot}
#     through ScrSim.submit_edit(); this script never submits anything.
#
# Node construction happens here (0006 §5 precedent: scene scripts own
# node layout): 9 slot entries built once in _ready(), updated in place.
extends HBoxContainer

const SLOT_COUNT := 9 # HOTBAR_SLOT_COUNT (sim parameter table)

var _panels: Array[PanelContainer] = []
var _labels: Array[Label] = []
var _swatches: Array[ColorRect] = []
var _style_normal: StyleBoxFlat
var _style_selected: StyleBoxFlat


func _ready() -> void:
	# Display-only chrome (plume-albedo precedent: presentation constants
	# live here, sim tunables live in src/mojo/sim/parameters.mojo).
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.06, 0.07, 0.09, 0.72)
	_style_normal.set_corner_radius_all(4)
	_style_normal.set_content_margin_all(6.0)
	_style_selected = StyleBoxFlat.new()
	_style_selected.bg_color = Color(0.10, 0.13, 0.17, 0.92)
	_style_selected.border_color = Color(0.95, 0.80, 0.35, 1.0)
	_style_selected.set_border_width_all(2)
	_style_selected.set_corner_radius_all(4)
	_style_selected.set_content_margin_all(6.0)

	for i in SLOT_COUNT:
		var panel := PanelContainer.new()
		panel.name = "Slot_%d" % (i + 1)
		panel.add_theme_stylebox_override("panel", _style_normal)

		var swatch := ColorRect.new()
		swatch.name = "Swatch"
		swatch.custom_minimum_size = Vector2(20, 20)
		swatch.color = Color(0.5, 0.5, 0.5, 1.0)
		panel.add_child(swatch)

		var label := Label.new()
		label.name = "Label"
		label.text = "%d" % (i + 1)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("outline_size", 3)
		panel.add_child(label)

		add_child(panel)
		_panels.append(panel)
		_labels.append(label)
		_swatches.append(swatch)


## Rebuild every slot from a validated HOTBAR payload (every snapshot, or
## whenever the selection changes — the adapter latches the call).
## `ids`/`names`/`colors` are resolved by the adapter (catalog mirror,
## 0007 AP-13); this function only lays them out on screen.
func apply_hotbar(selected_index: int, ids: PackedInt32Array,
		names: PackedStringArray, colors: PackedColorArray) -> void:
	var n := mini(SLOT_COUNT, ids.size())
	for i in n:
		var name_txt: String = str(ids[i])
		if i < names.size():
			name_txt = names[i]
		_labels[i].text = "%d  %s\n#%d" % [i + 1, name_txt, ids[i]]
		if i < colors.size():
			_swatches[i].color = colors[i]
		_panels[i].add_theme_stylebox_override(
				"panel", _style_selected if i == selected_index else _style_normal)
		# Read-only display flag (test introspection; HUD stays a projection).
		_panels[i].set_meta("selected", i == selected_index)
