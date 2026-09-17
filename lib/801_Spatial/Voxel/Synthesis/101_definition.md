---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-SPATIAL-VOXEL-SYNTHESIS
name: Voxel Synthesis — WFC/Noise to Lattice Adapter

version: 0.1.0
status: operational

created: 2026-09-16
updated: 2026-09-16

parent: SCR-LIB-SPATIAL-VOXEL
authority: SCR
domain: semantic-library
---

# SCR Spatial Voxel: Synthesis Adapter

## Summary

Semantic adapter that bridges WFC tile solutions and spectral noise terrain
signals into concrete voxel material assignments on the SCR 3D lattice.

---

## 1. Semantic Definition

The **VoxelSynthesisPipeline** is a pure function:

```
(x: int, z: int, biome: BiomeTile, feature: FeatureTile,
 height: float, noise_context: NoiseContext)
→ MaterialColumn: [(y_start, y_end, material_code)]
```

It is the **sole authoritative mapping** from abstract tile states to voxel
materials. Provider implementations may not introduce additional material
assignments outside this pipeline.

### Inputs

- `(x, z)`: lattice column coordinates
- `biome`: the Scale-0 WFC tile covering this column
- `feature`: the Scale-1 WFC tile for this exact column
- `height`: terrain surface height in metres (from SpectralSynthesizer)
- `noise_context`: provides fine-detail variation signals at this (x, z)

### Output

An ordered list of (y_range, material) segments filling the column from bedrock
to surface, then placing feature objects above surface.

---

## 2. Biome → Material Mapping (Normative)

| Biome | Surface Material | Sub-surface | Deep |
|---|---|---|---|
| DEEP_OCEAN | BASALT | BASALT | BASALT |
| SHALLOW_WATER | SAND | BASALT | BASALT |
| BEACH | SAND | SAND | BASALT |
| COASTAL_JUNGLE | DIRT | DIRT | BASALT |
| DENSE_RAINFOREST | DIRT | DIRT | BASALT |
| VOLCANIC_SLOPE | BASALT (ridged) | BASALT | BASALT |
| CALDERA_RIM | ASH/SULFUR/OBSIDIAN | BASALT | BASALT |
| CALDERA_LAKE | LAVA | OBSIDIAN | BASALT |
| LAVA_RIVER | LAVA | OBSIDIAN | BASALT |

Fine-detail modulation within a biome is permitted using the noise_context but
MUST NOT override the biome surface material with a material from a different
biome (e.g., sand in the caldera).

---

## 3. Feature → Flora Object Mapping (Normative)

| Feature | Voxel Objects Placed |
|---|---|
| PALM_CLUSTER | 2–4 palm trunks (MAT_PALM) + foliage crowns (MAT_FOLIAGE) |
| PALM_SOLO | 1 palm trunk + foliage crown |
| BAMBOO_GROVE | 2–6 bamboo columns (MAT_BAMBOO) |
| CANOPY_TREE | 1 hardwood trunk (MAT_WOOD) + 3-layer spheroid canopy (MAT_FOLIAGE) |
| CANOPY_CLUSTER | 2–3 canopy trees with overlapping crowns |
| SHRUB | 1–3 voxel dense shrub (MAT_SHRUB) |
| FERN_CARPET | Ground-cover ferns (MAT_FERN) across 1–4 column footprint |
| BASALT_BOULDER | Ellipsoid basalt mass (MAT_BASALT) |
| PUMICE_BOULDER | Ellipsoid pumice mass (MAT_PUMICE) |
| OBSIDIAN_SHARD | Jagged vertical obsidian column (MAT_OBSIDIAN) |
| SULFUR_VENT | Sulfur mound + ash ring (MAT_SULFUR, MAT_ASH) |
| ASH_FLAT | Ash surface layer (MAT_ASH), no standing object |
| LAVA_POOL | Lava fill to surface (MAT_LAVA) |

---

## 4. Semantic Invariants

1. The pipeline is a pure function: no side effects, no mutable global state
2. Features are placed **above** the terrain surface (y > height), never embedded
3. Bedrock (y=0) is always MAT_BEDROCK; this is not overridable by biome or feature
4. Water fills all cells from terrain height to sea_level where height < sea_level
5. The pipeline never reads from the voxel grid it is writing (write-once semantics)

---

## 5. Relationships

| Relation | Target | Kind |
|---|---|---|
| depends-on | SCR-LIB-TOPOLOGY-WFC | tile state input |
| depends-on | SCR-LIB-MATH-NOISE | noise_context input |
| depends-on | SCR-LIB-RENDER-MATERIAL | material code vocabulary |
| implements | SCR-LIB-SPATIAL-VOXEL | writes to 3D lattice |
