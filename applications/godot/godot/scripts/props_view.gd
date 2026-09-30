# props_view.gd — presentation view for the §14 RIGID_BODIES snapshot
# section.
#
# Milestone 0007 (spec §1.1 rendering lock, §3.5, §5): one pooled
# MeshInstance3D per rigid prop (≤ PROP_N_MAX = 16) under the `scr_props`
# host node. This script is PRESENTATION ONLY:
#   - position/euler/shape/size/material id come from the wire (the adapter
#     validated the bytes; physics, spawn anchors and contact resolution
#     are sim-owned — 0007 AP-12);
#   - colours arrive from the adapter's catalog mirror (0007 AP-13 /
#     spec §1.2: no colour is invented here);
#   - RIGID_BODIES arrives EVERY snapshot (104_contract §4.3 §14); nodes
#     are pooled so no per-frame allocation (0006 fauna precedent).
#
# Wire (104_contract §4.3 §14): u32 count + count·36 B records —
# f32×3 position, f32×3 euler (always 0 today), u32 shape (0 box,
# 1 sphere), f32 size (box half-extent / sphere radius), u32 material_id.
extends Node3D

const HEADER_BYTES := 4
const RECORD_BYTES := 36
const PROP_N_MAX := 16 # PROP_N_MAX (0007 §6 invariant 7 hard cap)

const FALLBACK_ALBEDO := Color(0.5, 0.5, 0.5, 1.0)

var _pool: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
# Display-latched shape/size per slot: meshes are rebuilt only on change.
var _shape: Array[int] = []
var _size: Array[float] = []


# ---------------------------------------------------------------------------
# Adapter entry point (adapter/scr_godot_adapter.cpp "Scene interface")
# ---------------------------------------------------------------------------

## Reposition the prop pool from a validated RIGID_BODIES payload (every
## snapshot). `colors`: Dictionary catalog id(int) -> Color (adapter-resolved).
func apply_props(bytes: PackedByteArray, colors: Dictionary) -> void:
	if bytes.size() < HEADER_BYTES:
		return
	var count := int(bytes.decode_u32(0))
	if bytes.size() < HEADER_BYTES + RECORD_BYTES * count:
		push_error("props_view: truncated RIGID_BODIES payload — ignored")
		return
	if count > PROP_N_MAX:
		push_error("props_view: count > PROP_N_MAX (16) — ignored")
		return

	for i in count:
		var o := HEADER_BYTES + RECORD_BYTES * i
		var node := _prop(i)
		if not node.visible:
			node.visible = true
		# Display transform: world position + euler passthrough (the
		# minimal model ships euler = 0 — 0007 §3.5).
		node.position = Vector3(bytes.decode_float(o), bytes.decode_float(o + 4),
				bytes.decode_float(o + 8))
		node.rotation = Vector3(bytes.decode_float(o + 12),
				bytes.decode_float(o + 16), bytes.decode_float(o + 20))
		var shape := int(bytes.decode_u32(o + 24))
		var size := bytes.decode_float(o + 28)
		var mat_id := int(bytes.decode_u32(o + 32))
		_shape_at(i, shape, size)
		var color: Color = FALLBACK_ALBEDO
		if colors.has(mat_id):
			color = colors[mat_id]
		if _materials[i].albedo_color != color:
			_materials[i].albedo_color = color
	for i in range(count, _pool.size()):
		if _pool[i].visible:
			_pool[i].visible = false


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _prop(slot: int) -> MeshInstance3D:
	if slot < _pool.size():
		return _pool[slot]
	var node := MeshInstance3D.new()
	node.name = "Prop_%d" % slot
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9
	node.material_override = mat
	_shape.append(-1) # -1 != any wire shape -> first _shape_at builds the mesh
	_size.append(0.0)
	_materials.append(mat)
	add_child(node)
	_pool.append(node)
	return node


## Rebuild the mesh only when (shape, size) changes for this slot.
func _shape_at(slot: int, shape: int, size: float) -> void:
	if slot < _shape.size() and _shape[slot] == shape and _size[slot] == size:
		return
	_shape[slot] = shape
	_size[slot] = size
	var mesh: Mesh
	if shape == 1: # PROP_SHAPE_SPHERE
		var sphere := SphereMesh.new()
		sphere.radius = size
		sphere.height = 2.0 * size
		sphere.radial_segments = 24
		sphere.rings = 12
		mesh = sphere
	else: # PROP_SHAPE_BOX — uniform half-extent -> full extent
		var box := BoxMesh.new()
		box.size = Vector3(2.0 * size, 2.0 * size, 2.0 * size)
		mesh = box
	_pool[slot].mesh = mesh
	_pool[slot].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
