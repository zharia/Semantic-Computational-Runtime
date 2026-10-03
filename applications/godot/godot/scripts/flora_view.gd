# flora_view.gd — presentation view for the §10 FLORA snapshot section.
#
# Milestone 0006 (spec §1.1 rendering lock, §5): one MultiMeshInstance3D per
# species under the `scr_flora` host node. This script is PRESENTATION ONLY:
#   - placement/count/scale/species come from the wire (adapter validated the
#     bytes; sim owns every semantic choice — 0006 AP-11);
#   - colors arrive from the adapter's catalog mirror (0006 AP-14);
#   - no sway phase is stored anywhere — flora_wing.gdshader animates on
#     shader TIME (0006 AP-12, spec §3.4).
# Absent FLORA never clears this view (invariant 5): the adapter simply does
# not call apply_flora() when the change-driven section is missing (0009 §3.2
# — emitted on count/species/pose/yaw change or an instance scale delta >=
# FLORA_EMIT_EPS vs the last emission). Every call re-reads `scale` from the
# wire and rebuilds the MultiMesh transforms, so growth is visible per
# snapshot without any scene-side aging.
#
# Wire (104_contract §4.3 §10): u32 count + count·24 B records —
# f32 x/y/z, f32 yaw, f32 scale, u32 species_id (1..7).
extends Node3D

const SHADER_PATH := "res://shaders/flora_wing.gdshader"
const HEADER_BYTES := 4
const RECORD_BYTES := 24
const SPECIES_MAX := 7

# Display-only sway amplitudes per species shape (u at full height).
# Scene-side constants (plume-albedo precedent); NOT sim tunables.
const SWAY := {
	1: 0.10, # PALM_CLUSTER  — flexible trunk, wide fronds
	2: 0.10, # PALM_SOLO
	3: 0.14, # BAMBOO_GROVE  — stiff culm, whole stalk leans
	4: 0.06, # CANOPY_TREE   — rigid bole, crown rustles
	5: 0.06, # CANOPY_CLUSTER
	6: 0.05, # SHRUB
	7: 0.03, # FERN_CARPET   — ground cover
}

var _nodes := {}      # species_id (int) -> MultiMeshInstance3D
var _meshes := {}     # species_id -> ArrayMesh (built once, scaled per instance)
var _materials := {}  # species_id -> ShaderMaterial
var _base_albedo := {} # species_id -> Color (pre-wetness)
var _wetness_gain := 1.0

# ---------------------------------------------------------------------------
# Adapter entry points (adapter/scr_godot_adapter.cpp "Scene interface")
# ---------------------------------------------------------------------------

## Rebuild every species group from a validated FLORA payload.
## `materials`: Dictionary species(int) -> {albedo: Color, roughness: float}.
func apply_flora(bytes: PackedByteArray, materials: Dictionary) -> void:
	if bytes.size() < HEADER_BYTES:
		return
	var count := int(bytes.decode_u32(0))
	if bytes.size() < HEADER_BYTES + RECORD_BYTES * count:
		push_error("flora_view: truncated FLORA payload — ignored")
		return

	# Group transforms by species (display transform only: pos + yaw + scale).
	var groups := {} # species -> Array[Transform3D]
	for i in count:
		var o := HEADER_BYTES + RECORD_BYTES * i
		var species := int(bytes.decode_u32(o + 20))
		if species < 1 or species > SPECIES_MAX:
			push_error("flora_view: species_id outside [1,7] — record ignored")
			continue
		var pos := Vector3(bytes.decode_float(o), bytes.decode_float(o + 4),
				bytes.decode_float(o + 8))
		var yaw := bytes.decode_float(o + 12)
		var s := bytes.decode_float(o + 16)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
		if not groups.has(species):
			groups[species] = []
		groups[species].append(Transform3D(basis, pos))

	# Colors may track a MATERIALS refresh (catalog is authoritative).
	for key in materials.keys():
		_update_material(int(key), materials[key])

	# Drop groups whose species vanished from this emission, rebuild the rest.
	for species in _nodes.keys():
		if not groups.has(species):
			_nodes[species].queue_free()
			_nodes.erase(species)
	for species in groups.keys():
		_refresh_group(int(species), groups[species])


## Wet-surface gain (same k the terrain uses, docs/04 §6 WETNESS_TINT):
## multiplies the catalog base albedo so rain darkens foliage in place.
func set_wetness_gain(k: float) -> void:
	_wetness_gain = k
	for species in _materials.keys():
		var base: Color = _base_albedo.get(species, Color(1, 1, 1))
		_materials[species].set_shader_parameter("albedo_color",
				Color(base.r * k, base.g * k, base.b * k, 1.0))


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _refresh_group(species: int, xforms: Array) -> void:
	var node: MultiMeshInstance3D
	if _nodes.has(species):
		node = _nodes[species]
	else:
		node = MultiMeshInstance3D.new()
		node.name = "Species_%d" % species
		add_child(node)
		_nodes[species] = node
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mesh_for(species)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	node.multimesh = mm
	node.material_override = _material_for(species)


func _update_material(species: int, entry: Dictionary) -> void:
	var mat := _material_for(species)
	var albedo: Color = entry.get("albedo", Color(0.5, 0.5, 0.5, 1.0))
	_base_albedo[species] = albedo
	mat.set_shader_parameter("albedo_color",
			Color(albedo.r * _wetness_gain, albedo.g * _wetness_gain,
			albedo.b * _wetness_gain, 1.0))
	mat.set_shader_parameter("roughness_value", float(entry.get("roughness", 0.85)))


func _material_for(species: int) -> ShaderMaterial:
	if _materials.has(species):
		return _materials[species]
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("sway_amount", float(SWAY.get(species, 0.05)))
	mat.set_shader_parameter("sway_speed", 1.1)
	mat.set_shader_parameter("flap_amount", 0.0)
	_materials[species] = mat
	return mat


## Per-species display meshes from Godot primitives (presentation only —
## sim never sees a mesh). One material covers every surface of the group,
## and each primitive contributes its own surface so no index merging is
## needed (winding stays Godot-native CW; simulation positions are NOT
## flipped, matching the adapter's ArrayMesh path).
func _mesh_for(species: int) -> ArrayMesh:
	if _meshes.has(species):
		return _meshes[species]
	var m := ArrayMesh.new()
	match species:
		1, 2: # palms: slender trunk + wide crown
			_add(m, _cylinder(0.14, 0.22, 3.4), Vector3(0, 1.7, 0))
			_add(m, _sphere(1.5, 0.55, 1.5), Vector3(0, 3.5, 0))
		3: # bamboo grove: three thin culms
			_add(m, _cylinder(0.06, 0.07, 3.4), Vector3(-0.35, 1.7, 0.10))
			_add(m, _cylinder(0.06, 0.07, 3.8), Vector3(0.25, 1.9, -0.20))
			_add(m, _cylinder(0.06, 0.07, 3.1), Vector3(0.05, 1.55, 0.35))
		4: # canopy tree: bole + big crown
			_add(m, _cylinder(0.18, 0.28, 2.6), Vector3(0, 1.3, 0))
			_add(m, _sphere(1.7, 1.3, 1.7), Vector3(0, 3.4, 0))
		5: # canopy cluster: one bole + three crowns
			_add(m, _cylinder(0.16, 0.24, 2.4), Vector3(0, 1.2, 0))
			_add(m, _sphere(1.2, 1.0, 1.2), Vector3(-0.7, 3.0, 0.3))
			_add(m, _sphere(1.3, 1.1, 1.3), Vector3(0.6, 3.3, -0.4))
			_add(m, _sphere(1.1, 0.9, 1.1), Vector3(0.1, 3.6, 0.7))
		6: # shrub: squashed bush
			_add(m, _sphere(1.0, 0.7, 1.0), Vector3(0, 0.55, 0))
		7: # fern carpet: flat wide disc
			_add(m, _cylinder(1.1, 1.25, 0.22), Vector3(0, 0.11, 0))
		_:
			_add(m, _sphere(1.0, 1.0, 1.0), Vector3(0, 1.0, 0))
	_meshes[species] = m
	return m


func _add(dst: ArrayMesh, prim: PrimitiveMesh, origin: Vector3) -> void:
	var arrays: Array = prim.surface_get_arrays(0)
	var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for i in verts.size():
		verts[i] = verts[i] + origin
	arrays[Mesh.ARRAY_VERTEX] = verts
	dst.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _cylinder(top_r: float, bottom_r: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = height
	return c


func _sphere(x: float, y: float, z: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = maxf(x, z)
	s.height = 2.0 * y
	return s
