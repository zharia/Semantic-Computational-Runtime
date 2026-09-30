# fauna_view.gd — presentation view for the §11 FAUNA snapshot section.
#
# Milestone 0006 (spec §1.1 rendering lock, §5): birds are individual
# MeshInstance3D nodes (≤ 64, one per flock slot) under the `scr_fauna`
# host — per-node so heading/orientation is trivially debuggable.
# PRESENTATION ONLY:
#   - positions/yaw come from the wire (adapter validated the bytes; boid
#     motion, spawn/despawn and counts are sim-owned — 0006 AP-11);
#   - FAUNA arrives EVERY snapshot (104_contract §4.3 §11) — no caching
#     rule here, but nodes are pooled so no per-frame allocation;
#   - wing flap runs on shader TIME only (flora_wing.gdshader) — no flap
#     phase is read from the bytes (0006 AP-12, spec §3.4).
# Yaw convention (0002/0003 header): rotation.y = +yaw, no flip.
#
# Wire (104_contract §4.3 §11): u32 count + count·20 B records —
# f32 x/y/z, f32 yaw, u8 species_id (0 = seabird), u8×3 pad.
extends Node3D

const SHADER_PATH := "res://shaders/flora_wing.gdshader"
const HEADER_BYTES := 4
const RECORD_BYTES := 20
const BIRD_MAX := 64 # FLOCK_N_MAX (0006 AP-13)

# Bird display constant (plume-albedo precedent; NOT a sim tunable):
# white-grey seabird, visibly distinct against dark ocean basalt/sand.
const BIRD_ALBEDO := Color(0.90, 0.91, 0.93, 1.0)
const BIRD_ROUGHNESS := 0.65

var _pool: Array = [] # MeshInstance3D, indexed by flock slot (≤ BIRD_MAX)
var _mesh: ArrayMesh
var _material: ShaderMaterial


# ---------------------------------------------------------------------------
# Adapter entry point (adapter/scr_godot_adapter.cpp "Scene interface")
# ---------------------------------------------------------------------------

## Reposition the bird pool from a validated FAUNA payload (every snapshot).
func apply_fauna(bytes: PackedByteArray) -> void:
	if bytes.size() < HEADER_BYTES:
		return
	var count := int(bytes.decode_u32(0))
	if bytes.size() < HEADER_BYTES + RECORD_BYTES * count:
		push_error("fauna_view: truncated FAUNA payload — ignored")
		return
	if count > BIRD_MAX:
		push_error("fauna_view: count > FLOCK_N_MAX (64) — clamped for display")
		count = BIRD_MAX

	for i in count:
		var o := HEADER_BYTES + RECORD_BYTES * i
		var node := _bird(i)
		if not node.visible:
			node.visible = true
		# Display transform only: world position + yaw heading (no flip).
		node.position = Vector3(bytes.decode_float(o), bytes.decode_float(o + 4),
				bytes.decode_float(o + 8))
		node.rotation = Vector3(0.0, bytes.decode_float(o + 12), 0.0)
		# u8 species_id at o+16: 0 = seabird (only emitted species today);
		# other ids still render as the seabird mesh (representation is
		# tolerant; species semantics live in src/mojo).
	for i in range(count, _pool.size()):
		if _pool[i].visible:
			_pool[i].visible = false


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _bird(slot: int) -> MeshInstance3D:
	if slot < _pool.size():
		return _pool[slot]
	var node := MeshInstance3D.new()
	node.name = "Bird_%d" % slot
	node.mesh = _bird_mesh()
	node.material_override = _bird_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(node)
	_pool.append(node)
	return node


func _bird_material() -> ShaderMaterial:
	if _material != null:
		return _material
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("albedo_color", BIRD_ALBEDO)
	mat.set_shader_parameter("roughness_value", BIRD_ROUGHNESS)
	mat.set_shader_parameter("sway_amount", 0.0)
	mat.set_shader_parameter("flap_amount", 0.22) # u at wingtip (display)
	mat.set_shader_parameter("flap_speed", 7.0)
	_material = mat
	return mat


## Bird from boxes (Godot primitives => native CW winding): body along -Z
## (forward, matching the yaw convention), wings along ±X so the shader's
## flap term (lift ∝ |x|) bends the wingtips. Built once, shared by the pool.
func _bird_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var m := ArrayMesh.new()
	_add(m, _box(0.26, 0.22, 0.95), Vector3(0, 0, -0.05))   # body
	_add(m, _box(2.10, 0.05, 0.48), Vector3(0, 0.06, -0.02)) # wings
	_add(m, _box(0.46, 0.04, 0.30), Vector3(0, 0.04, 0.55))  # tail
	_add(m, _box(0.16, 0.16, 0.24), Vector3(0, 0.10, -0.55)) # head
	_mesh = m
	return m


func _add(dst: ArrayMesh, prim: PrimitiveMesh, origin: Vector3) -> void:
	var arrays: Array = prim.surface_get_arrays(0)
	var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for i in verts.size():
		verts[i] = verts[i] + origin
	arrays[Mesh.ARRAY_VERTEX] = verts
	dst.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b
