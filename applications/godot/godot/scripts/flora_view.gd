# flora_view.gd — presentation view for the §10 FLORA snapshot section.
#
# Sprint 03 (milestone 0010, R1–R8): the view expands each species' grammar
# through phenome_expand.gd and renders bucketed, LOD-aware MultiMeshes.
# This script is PRESENTATION ONLY:
#   - placement/count/scale/species/stage/seed come from the wire (adapter
#     validated the bytes; sim owns every semantic choice — 0006 AP-11);
#   - colors arrive from the adapter's catalog mirror (0006 AP-14);
#   - no sway phase is stored anywhere — flora_wing.gdshader animates on
#     shader TIME (0006 AP-12, spec §3.4).
# Absent FLORA never clears this view (invariant 5): the adapter simply does
# not call apply_flora() when the change-driven section is missing.
#
# Wire (104_contract §4.3 §10): u32 count + count·32 B records —
# f32 x/y/z @0, f32 yaw @12, f32 scale @16, u32 species_id @20,
# u32 variant_seed @24, u8 stage @28, pad[3] @29.
#
# Mesh cache (R2): key = (species, bucket, stage) with
# bucket = posmod(hash(variant_seed), 16). The expansion seed is the bucket
# id itself, so a cache entry is deterministic regardless of which plant
# created it first. Each entry holds one ArrayMesh per LOD band (depth,
# depth-1, depth-2, floor 1 — see phenome_expand.lod_depth), built lazily;
# band switches therefore never create a new cache key.
extends Node3D

const SHADER_PATH := "res://shaders/flora_wing.gdshader"
const GRAMMAR_PATH := "res://data/phenome_grammars.json"
const HEADER_BYTES := 4
const RECORD_BYTES := 32
const SPECIES_MAX := 7
const BUCKET_COUNT := 16
const CACHE_MAX := 112          # 7 species · 16 buckets (LRU bound)
const LOD_NEAR_M := 30.0        # band 0 | band 1 boundary
const LOD_FAR_M := 60.0         # band 1 | band 2 boundary
const LOD_HYSTERESIS_M := 2.0   # per-band switch margin
const DEFAULT_TRAIT_MILLIS := [500, 500]  # median traits (wire has none)

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

const Expander := preload("res://scripts/phenome_expand.gd")

var _expander: Expander = null
var _grammars_ok := false

var _groups := {}        # [species, bucket, stage] -> {instances, members, meshes}
var _band_nodes := {}    # [species, bucket, stage, band] -> MultiMeshInstance3D
var _cache := {}         # [species, bucket, stage] -> {meshes: [3], used: int}
var _plant_band := {}    # plant hash -> band (hysteresis across emissions)
var _materials := {}     # species_id -> ShaderMaterial
var _base_albedo := {}   # species_id -> Color (pre-wetness)
var _wetness_gain := 1.0

var _payload_count := 0
var _payload_bytes := 0
var _apply_count := 0
var _expansion_count := 0   # cache key creations (R3 test: stable)
var _lod_build_count := 0   # per-band lazy mesh builds
var _eviction_count := 0
var _clock := 0
var _total_expand_usec := 0
var _lod_usec_max := 0

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
	_payload_bytes = bytes.size()
	_apply_count += 1

	_ensure_expander()

	# Group plants by cache key (display transform only: pos + yaw + scale).
	var groups := {} # key -> Array[Dictionary]
	var live_plants := {}
	var n := 0
	for i in count:
		var o := HEADER_BYTES + RECORD_BYTES * i
		var species := int(bytes.decode_u32(o + 20))
		if species < 1 or species > SPECIES_MAX:
			push_error("flora_view: species_id outside [1,7] — record ignored")
			continue
		if not _expander.grammar_by_species(species).is_empty():
			pass  # grammar present — normal path
		else:
			push_error("flora_view: no grammar for species %d — ignored" % species)
			continue
		var seed := int(bytes.decode_u32(o + 24))
		var stage := int(bytes.decode_u8(o + 28))
		var pos := Vector3(bytes.decode_float(o), bytes.decode_float(o + 4),
				bytes.decode_float(o + 8))
		var yaw := bytes.decode_float(o + 12)
		var s := bytes.decode_float(o + 16)
		var key := [species, posmod(hash(seed), BUCKET_COUNT), stage]
		var ph := hash([species, pos.x, pos.y, pos.z])
		if not groups.has(key):
			groups[key] = []
		groups[key].append({
			"pos": pos, "yaw": yaw, "scale": s, "plant": ph,
			"band": int(_plant_band.get(ph, -1)),
		})
		live_plants[ph] = true
		n += 1
	_payload_count = n

	# Colors may track a MATERIALS refresh (catalog is authoritative).
	for key in materials.keys():
		_update_material(int(key), materials[key])

	# Drop groups and band nodes whose key vanished from this emission.
	for key in _groups.keys():
		if not groups.has(key):
			_groups.erase(key)
			_erase_group_nodes(key)
	for key in groups.keys():
		_groups[key] = {
			"key": key,
			"instances": groups[key],
			"members": [[], [], []],
			"meshes": [null, null, null],
		}


	# Prune hysteresis state for plants that left the payload.
	for ph in _plant_band.keys():
		if not live_plants.has(ph):
			_plant_band.erase(ph)


## Wet-surface gain (same k the terrain uses, docs/04 §6 WETNESS_TINT):
## multiplies the catalog base albedo so rain darkens foliage in place.
func set_wetness_gain(k: float) -> void:
	_wetness_gain = k
	for species in _materials.keys():
		var base: Color = _base_albedo.get(species, Color(1, 1, 1))
		_materials[species].set_shader_parameter("albedo_color",
				Color(base.r * k, base.g * k, base.b * k, 1.0))


# ---------------------------------------------------------------------------
# LOD (R4): per-instance distance bands with hysteresis, refilled per frame
# only when membership changes. Mesh lookups never expand while cached.
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _groups.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	var cam := _camera_pos()
	for key in _groups.keys():
		var grp: Dictionary = _groups[key]
		var instances: Array = grp.instances
		var members: Array = [[], [], []]
		for i in instances.size():
			var inst: Dictionary = instances[i]
			var d := cam.distance_to(inst.pos)
			var band := lod_band_for_distance(d, int(inst.band))
			inst.band = band
			_plant_band[inst.plant] = band
			members[band].append(i)
		for band in 3:
			_refresh_band(grp, band, members[band])
	var dt := Time.get_ticks_usec() - t0
	if dt > _lod_usec_max:
		_lod_usec_max = dt


## R4 boundaries with hysteresis: switch up only beyond upper+h, down only
## below the previous boundary-h. `current` == -1 means unknown → enter by
## the plain thresholds (h applies only to leaving a band).
static func lod_band_for_distance(d: float, current: int) -> int:
	var b := current
	if b < 0:
		if d > LOD_FAR_M:
			return 2
		if d > LOD_NEAR_M:
			return 1
		return 0
	while b < 2 and d > _band_upper(b) + LOD_HYSTERESIS_M:
		b += 1
	while b > 0 and d < _band_upper(b - 1) - LOD_HYSTERESIS_M:
		b -= 1
	return b


static func _band_upper(b: int) -> float:
	match b:
		0:
			return LOD_NEAR_M
		1:
			return LOD_FAR_M
	return INF


func _refresh_band(grp: Dictionary, band: int, members: Array) -> void:
	var key: Array = grp.key
	var old: Array = grp.members[band]
	if members.is_empty():
		# Empty band: clear any stale MultiMesh (old instances would double
		# count plants that moved band/key) and never build its mesh.
		grp.members[band] = members
		grp.meshes[band] = null
		var full := [key[0], key[1], key[2], band]
		if _band_nodes.has(full):
			var n0: MultiMeshInstance3D = _band_nodes[full]
			n0.multimesh = null
			n0.visible = false
		return
	var mesh := _mesh_for(int(key[0]), int(key[1]), int(key[2]), band)
	if members == old and grp.meshes[band] == mesh:
		return
	grp.members[band] = members
	grp.meshes[band] = mesh
	var node := _band_node(key, band)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = members.size()
	var instances: Array = grp.instances
	for j in members.size():
		var inst: Dictionary = instances[members[j]]
		var s := float(inst.scale)
		var basis := Basis(Vector3.UP, float(inst.yaw)).scaled(Vector3(s, s, s))
		mm.set_instance_transform(j, Transform3D(basis, inst.pos))
	node.multimesh = mm
	node.material_override = _material_for(int(key[0]))
	node.visible = true


func _band_node(key: Array, band: int) -> MultiMeshInstance3D:
	var full := [key[0], key[1], key[2], band]
	if _band_nodes.has(full):
		return _band_nodes[full]
	var node := MultiMeshInstance3D.new()
	node.name = "S%d_b%d_s%d_lod%d" % [key[0], key[1], key[2], band]
	node.visible = false
	add_child(node)
	_band_nodes[full] = node
	return node


func _erase_group_nodes(key: Array) -> void:
	for band in 3:
		var full := [key[0], key[1], key[2], band]
		if _band_nodes.has(full):
			_band_nodes[full].queue_free()
			_band_nodes.erase(full)


# ---------------------------------------------------------------------------
# Mesh cache (R2/R3)
# ---------------------------------------------------------------------------

func _mesh_for(species: int, bucket: int, stage: int, band: int) -> ArrayMesh:
	var ck := [species, bucket, stage]
	if not _cache.has(ck):
		# Evict BEFORE inserting: the new key (used=0) would be the LRU
		# victim of its own insertion, then the lookup below would miss.
		while _cache.size() >= CACHE_MAX:
			if not _evict_oldest():
				break
		_cache[ck] = {"meshes": [null, null, null], "used": 0}
		_expansion_count += 1
	var entry: Dictionary = _cache[ck]
	_clock += 1
	entry.used = _clock
	var cached: ArrayMesh = entry.meshes[band]
	if cached != null:
		return cached
	var g: Dictionary = _expander.grammar_by_species(species)
	var t0 := Time.get_ticks_usec()
	# Expansion seed is the bucket id: deterministic per cache key (R2).
	var m: ArrayMesh = _expander.expand(g, bucket, stage, DEFAULT_TRAIT_MILLIS, band)
	_total_expand_usec += Time.get_ticks_usec() - t0
	_lod_build_count += 1
	entry.meshes[band] = m
	return m


## Erase one LRU cache entry. Returns false only if the cache is empty.
func _evict_oldest() -> bool:
	var oldest_key: Variant = null
	var oldest_used := 0x7FFFFFFFFFFFFFFF
	for k in _cache.keys():
		var u: int = _cache[k].used
		if u < oldest_used:
			oldest_used = u
			oldest_key = k
	if oldest_key == null:
		return false
	_cache.erase(oldest_key)
	_eviction_count += 1
	return true


# ---------------------------------------------------------------------------
# Introspection (sprint 03 scene gate)
# ---------------------------------------------------------------------------

func payload_count() -> int:
	return _payload_count


func payload_bytes() -> int:
	return _payload_bytes


func instance_total() -> int:
	var n := 0
	for key in _groups.keys():
		for band in 3:
			var full := [key[0], key[1], key[2], band]
			if _band_nodes.has(full):
				var node: MultiMeshInstance3D = _band_nodes[full]
				if node.multimesh != null:
					n += node.multimesh.instance_count
	return n


## Plant world positions in group order. Read from the wire-derived state,
## NOT from MultiMesh transforms — headless (dummy renderer) cannot read
## instance transforms back (they return identity).
func instance_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for key in _groups.keys():
		for inst in _groups[key].instances:
			out.append(inst.pos)
	return out


func band_histogram() -> Array:
	var h := [0, 0, 0]
	for key in _groups.keys():
		for band in 3:
			var full := [key[0], key[1], key[2], band]
			if _band_nodes.has(full):
				var node: MultiMeshInstance3D = _band_nodes[full]
				if node.multimesh != null:
					h[band] += node.multimesh.instance_count
	return h


func group_count() -> int:
	return _groups.size()


func cache_size() -> int:
	return _cache.size()


func expansion_count() -> int:
	return _expansion_count


func lod_build_count() -> int:
	return _lod_build_count


func eviction_count() -> int:
	return _eviction_count


func apply_count() -> int:
	return _apply_count


func total_expand_usec() -> int:
	return _total_expand_usec


func lod_usec_max() -> int:
	return _lod_usec_max


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _ensure_expander() -> void:
	if _expander != null:
		return
	_expander = Expander.new()
	_grammars_ok = _expander.load_grammars(GRAMMAR_PATH)
	if not _grammars_ok:
		push_error("flora_view: failed to load %s" % GRAMMAR_PATH)


func _camera_pos() -> Vector3:
	if not is_inside_tree():
		return Vector3.ZERO
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	return cam.global_position


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
