/**
 * SCR Application / Procedural Vegetation & Geological System
 * ─────────────────────────────────────────────────────────────────────────────
 * Algorithmic procedural generation of trees, flora, and geological formations
 * based on EZ-Tree parametric branching (https://github.com/dgreenheck/ez-tree),
 * botanical morphogenesis, and spatial grove ecology.
 *
 * Implements:
 *   1. EZ-Tree Parametric Branching Engine (recursive levels, phototropism, da Vinci conservation)
 *   2. 6 Distinct Tree Varieties / Presets:
 *      - Tropical Banyan / Ancient Hardwood Oak (wide canopy, multi-dome foliage)
 *      - Coastal Coconut Palm (curved trunk, golden-angle phyllotaxis fronds)
 *      - Highland Araucaria / Conifer Pine (excurrent trunk, tiered needle collars)
 *      - Weeping River Willow / Mangrove (drooping pendulous canopy)
 *      - Flowering Parasol Acacia / Jacaranda (flat umbrella crown with vibrant blossoms)
 *      - Slender White Birch / Aspen (slender pale trunk, airy shimmering leaves)
 *   3. Understory Flora: Tropical Bushes, Flowering Shrubs, Volcanic Slope Ferns
 *   4. Geological Formations: Faceted Boulders, Mossy Rock Clumps, Basalt Crags
 *   5. Grove & Clump Clustered Spatial Ecology (distinct stands, wide open vistas)
 *   6. Dynamic GPU Mesh Synthesis with multi-harmonic wind sway deformation.
 */

#ifndef CAVE_PROCEDURAL_VEGETATION_HPP
#define CAVE_PROCEDURAL_VEGETATION_HPP

#include <Ogre.h>
#include "spatial_semantics.hpp"
#include "procedural_island.hpp"
#include "hierarchical_wfc.hpp"

#include <vector>
#include <string>
#include <cmath>
#include <random>
#include <algorithm>
#include <iostream>

namespace SCR::Vegetation {

struct VegetationVertex {
    Ogre::Vector3 position;
    Ogre::Vector3 normal;
    Ogre::ColourValue color;
    float wind_weight; // 0.0 at base/ground, 1.0 at tips
};

// ─── Weber-Penn Crown Envelopes & Morphological Profiles ──────────────────────
enum class CrownShape {
    CONICAL = 0,             // Conifers, firs, larches
    SPHERICAL = 1,           // Oaks, maples, hardwoods
    HEMISPHERICAL = 2,       // Banyans, tropical canopies
    CYLINDRICAL = 3,         // Columnar pines
    TAPERED_CYLINDRICAL = 4, // Birches, aspens
    FLAME = 5,               // Italian cypresses, Lombardy poplars
    INVERSE_CONICAL = 6,     // Umbrella thorn acacias, dragon blood trees
    VASE = 7                 // American elms, weeping willows
};

inline float evaluateCrownEnvelope(float y_rel, CrownShape shape) {
    float y = std::max(0.0f, std::min(1.0f, y_rel));
    switch (shape) {
        case CrownShape::CONICAL:
            return 1.0f - y;
        case CrownShape::SPHERICAL:
            return std::sqrt(std::max(0.0f, 1.0f - std::pow(2.0f * y - 1.0f, 2.0f)));
        case CrownShape::HEMISPHERICAL:
            return std::sqrt(std::max(0.0f, 1.0f - y * y));
        case CrownShape::CYLINDRICAL:
            return 1.0f;
        case CrownShape::TAPERED_CYLINDRICAL:
            return 0.5f + 0.5f * (1.0f - y);
        case CrownShape::FLAME:
            return (y < 0.7f) ? (y / 0.7f) : ((1.0f - y) / 0.3f);
        case CrownShape::INVERSE_CONICAL:
            return 0.25f + 0.75f * y;
        case CrownShape::VASE:
            return 0.35f + 0.65f * std::sin(y * 3.14159f * 0.5f);
        default:
            return 1.0f;
    }
}

// ─── Procedural Entity Archetypes ─────────────────────────────────────────────
enum class FloraType {
    BANYAN_OAK_TREE,
    COASTAL_PALM_TREE,
    HIGHLAND_CONIFER_TREE,
    WEEPING_WILLOW_TREE,
    PARASOL_ACACIA_TREE,
    SLENDER_BIRCH_TREE,
    DRAGON_BLOOD_TREE,
    VOLCANIC_TREE_FERN,
    JOSHUA_TREE_YUCCA,
    CLIFF_JUNIPER_BONSAI,
    TROPICAL_BUSH,
    SLOPE_FERN,
    MOSSY_ROCK_CLUMP,
    COASTAL_BOULDER,
    VOLCANIC_CRAG
};

struct FloraInstance {
    FloraType type;
    Spatial::Point3D pos;
    float scale;
    float rotation_yaw;
    float lean_angle;
    float lean_yaw;
    unsigned seed;
};

// ─── Weber-Penn / EZ-Tree Configuration & Preset Parameters ───────────────────
enum class FoliageStyle {
    CLUSTERED_DOMES,     // Hardwood / Oak / Banyan puffy crowns
    CONICAL_TIERS,       // Pine / Conifer tiered horizontal skirts
    WEEPING_STREAMERS,   // Willow / Mangrove hanging pendulous clumps
    PARASOL_CANOPY,      // Acacia flat umbrella canopy with blossoms
    SLENDER_AIRY,        // Birch / Aspen light scattered foliage
    PALM_FRONDS,         // Tropical palm radial arching blades
    DRAGON_UMBRELLA,     // Dense succulent geometric umbrella
    FERN_ROSETTE,        // Multi-tier radiating fern fronds
    JOSHUA_SPIKES        // Forked branches with spiky rosettes
};

struct BranchLevelConfig {
    int children_count;      // number of child branches per parent
    float start_ratio;       // normalized spawn position along parent (0.0 to 1.0)
    float split_angle_deg;   // branching angle relative to parent vector (deg)
    float length_ratio;      // child length relative to parent
    float radius_ratio;      // child radius relative to parent
    float gnarliness;        // random angular perturbation
    float phototropism;      // upward (+Y) or downward (-Y) growth bias
};

struct TreePresetConfig {
    std::string name;
    CrownShape crown_shape;        // Weber-Penn analytical envelope
    int branch_levels;             // recursion depth (1, 2, or 3)
    float trunk_height;            // base trunk height (meters)
    float trunk_radius;            // base trunk radius (meters)
    int trunk_segments;            // height segments
    int radial_sides;              // cylinder sides (5 to 8)
    float trunk_taper;             // radius reduction factor
    float trunk_gnarl;             // trunk organic curvature
    float phototropism;            // upward growth bias
    BranchLevelConfig level1;      // Primary scaffold limbs
    BranchLevelConfig level2;      // Secondary twigs / foliage anchors

    FoliageStyle foliage_style;
    float foliage_radius;
    int foliage_clusters;
    Ogre::ColourValue bark_dark;
    Ogre::ColourValue bark_light;
    Ogre::ColourValue leaf_top;
    Ogre::ColourValue leaf_mid;
    Ogre::ColourValue leaf_shadow;
    Ogre::ColourValue blossom_color;
    bool has_blossoms;
};

// ─── Weber-Penn Presets Library ───────────────────────────────────────────────
class TreePresets {
public:
    static TreePresetConfig getBanyanOak() {
        TreePresetConfig p;
        p.name = "Rainforest Banyan / Hardwood Oak";
        p.crown_shape = CrownShape::HEMISPHERICAL;
        p.branch_levels = 3;
        p.trunk_height = 8.5f;
        p.trunk_radius = 0.65f;
        p.trunk_segments = 5;
        p.radial_sides = 7;
        p.trunk_taper = 0.35f;
        p.trunk_gnarl = 0.18f;
        p.phototropism = 0.45f;

        p.level1 = {3, 0.45f, 48.0f, 0.68f, 0.58f, 0.22f, 0.35f};
        p.level2 = {2, 0.55f, 40.0f, 0.60f, 0.55f, 0.25f, 0.40f};

        p.foliage_style = FoliageStyle::CLUSTERED_DOMES;
        p.foliage_radius = 2.4f;
        p.foliage_clusters = 3;
        p.bark_dark   = Ogre::ColourValue(0.38f, 0.26f, 0.16f);
        p.bark_light  = Ogre::ColourValue(0.55f, 0.40f, 0.26f);
        p.leaf_top    = Ogre::ColourValue(0.20f, 0.46f, 0.18f);
        p.leaf_mid    = Ogre::ColourValue(0.14f, 0.36f, 0.12f);
        p.leaf_shadow = Ogre::ColourValue(0.06f, 0.24f, 0.08f);
        p.has_blossoms = false;
        return p;
    }

    static TreePresetConfig getHighlandConifer() {
        TreePresetConfig p;
        p.name = "Highland Araucaria / Conifer Pine";
        p.crown_shape = CrownShape::CONICAL;
        p.branch_levels = 2;
        p.trunk_height = 11.5f;
        p.trunk_radius = 0.52f;
        p.trunk_segments = 7;
        p.radial_sides = 6;
        p.trunk_taper = 0.65f;
        p.trunk_gnarl = 0.05f;
        p.phototropism = 0.85f;

        p.level1 = {5, 0.30f, 75.0f, 0.42f, 0.38f, 0.08f, -0.15f};
        p.level2 = {2, 0.50f, 35.0f, 0.45f, 0.45f, 0.10f, 0.0f};

        p.foliage_style = FoliageStyle::CONICAL_TIERS;
        p.foliage_radius = 1.8f;
        p.foliage_clusters = 2;
        p.bark_dark   = Ogre::ColourValue(0.32f, 0.20f, 0.15f);
        p.bark_light  = Ogre::ColourValue(0.48f, 0.32f, 0.22f);
        p.leaf_top    = Ogre::ColourValue(0.14f, 0.40f, 0.22f);
        p.leaf_mid    = Ogre::ColourValue(0.08f, 0.30f, 0.16f);
        p.leaf_shadow = Ogre::ColourValue(0.04f, 0.20f, 0.10f);
        p.has_blossoms = false;
        return p;
    }

    static TreePresetConfig getWeepingWillow() {
        TreePresetConfig p;
        p.name = "Weeping Mangrove / River Willow";
        p.crown_shape = CrownShape::VASE;
        p.branch_levels = 3;
        p.trunk_height = 6.8f;
        p.trunk_radius = 0.58f;
        p.trunk_segments = 5;
        p.radial_sides = 6;
        p.trunk_taper = 0.30f;
        p.trunk_gnarl = 0.25f;
        p.phototropism = 0.10f;

        p.level1 = {3, 0.40f, 55.0f, 0.72f, 0.55f, 0.30f, 0.20f};
        p.level2 = {3, 0.35f, 65.0f, 0.75f, 0.50f, 0.35f, -0.75f};

        p.foliage_style = FoliageStyle::WEEPING_STREAMERS;
        p.foliage_radius = 2.2f;
        p.foliage_clusters = 3;
        p.bark_dark   = Ogre::ColourValue(0.28f, 0.26f, 0.22f);
        p.bark_light  = Ogre::ColourValue(0.44f, 0.40f, 0.34f);
        p.leaf_top    = Ogre::ColourValue(0.28f, 0.50f, 0.20f);
        p.leaf_mid    = Ogre::ColourValue(0.20f, 0.40f, 0.15f);
        p.leaf_shadow = Ogre::ColourValue(0.10f, 0.28f, 0.10f);
        p.has_blossoms = false;
        return p;
    }

    static TreePresetConfig getParasolAcacia() {
        TreePresetConfig p;
        p.name = "Flowering Parasol Acacia / Jacaranda";
        p.crown_shape = CrownShape::INVERSE_CONICAL;
        p.branch_levels = 3;
        p.trunk_height = 6.2f;
        p.trunk_radius = 0.50f;
        p.trunk_segments = 4;
        p.radial_sides = 6;
        p.trunk_taper = 0.25f;
        p.trunk_gnarl = 0.20f;
        p.phototropism = 0.25f;

        p.level1 = {4, 0.50f, 62.0f, 0.80f, 0.52f, 0.20f, 0.10f};
        p.level2 = {3, 0.45f, 45.0f, 0.65f, 0.50f, 0.25f, 0.35f};

        p.foliage_style = FoliageStyle::PARASOL_CANOPY;
        p.foliage_radius = 2.8f;
        p.foliage_clusters = 4;
        p.bark_dark   = Ogre::ColourValue(0.35f, 0.28f, 0.20f);
        p.bark_light  = Ogre::ColourValue(0.52f, 0.42f, 0.32f);
        p.leaf_top    = Ogre::ColourValue(0.26f, 0.48f, 0.20f);
        p.leaf_mid    = Ogre::ColourValue(0.18f, 0.38f, 0.14f);
        p.leaf_shadow = Ogre::ColourValue(0.08f, 0.25f, 0.08f);
        p.has_blossoms = true;
        p.blossom_color = Ogre::ColourValue(0.96f, 0.32f, 0.64f);
        return p;
    }

    static TreePresetConfig getBirchAspen() {
        TreePresetConfig p;
        p.name = "Slender White Birch / Aspen";
        p.crown_shape = CrownShape::TAPERED_CYLINDRICAL;
        p.branch_levels = 2;
        p.trunk_height = 9.2f;
        p.trunk_radius = 0.32f;
        p.trunk_segments = 6;
        p.radial_sides = 6;
        p.trunk_taper = 0.40f;
        p.trunk_gnarl = 0.12f;
        p.phototropism = 0.70f;

        p.level1 = {3, 0.62f, 38.0f, 0.55f, 0.50f, 0.18f, 0.50f};
        p.level2 = {2, 0.50f, 32.0f, 0.50f, 0.45f, 0.20f, 0.45f};

        p.foliage_style = FoliageStyle::SLENDER_AIRY;
        p.foliage_radius = 1.6f;
        p.foliage_clusters = 2;
        p.bark_dark   = Ogre::ColourValue(0.30f, 0.30f, 0.32f);
        p.bark_light  = Ogre::ColourValue(0.88f, 0.88f, 0.84f);
        p.leaf_top    = Ogre::ColourValue(0.32f, 0.52f, 0.20f);
        p.leaf_mid    = Ogre::ColourValue(0.22f, 0.42f, 0.15f);
        p.leaf_shadow = Ogre::ColourValue(0.12f, 0.30f, 0.10f);
        p.has_blossoms = false;
        return p;
    }

    static TreePresetConfig getDragonBloodTree() {
        TreePresetConfig p;
        p.name = "Socotra Dragon Blood Tree";
        p.crown_shape = CrownShape::INVERSE_CONICAL;
        p.branch_levels = 3;
        p.trunk_height = 5.8f;
        p.trunk_radius = 0.55f;
        p.trunk_segments = 4;
        p.radial_sides = 6;
        p.trunk_taper = 0.20f;
        p.trunk_gnarl = 0.15f;
        p.phototropism = 0.35f;

        p.level1 = {4, 0.70f, 42.0f, 0.60f, 0.65f, 0.15f, 0.40f};
        p.level2 = {3, 0.50f, 32.0f, 0.50f, 0.60f, 0.12f, 0.50f};

        p.foliage_style = FoliageStyle::DRAGON_UMBRELLA;
        p.foliage_radius = 3.2f;
        p.foliage_clusters = 4;
        p.bark_dark   = Ogre::ColourValue(0.40f, 0.30f, 0.25f);
        p.bark_light  = Ogre::ColourValue(0.62f, 0.48f, 0.38f);
        p.leaf_top    = Ogre::ColourValue(0.22f, 0.45f, 0.26f);
        p.leaf_mid    = Ogre::ColourValue(0.14f, 0.35f, 0.18f);
        p.leaf_shadow = Ogre::ColourValue(0.08f, 0.24f, 0.12f);
        p.has_blossoms = true;
        p.blossom_color = Ogre::ColourValue(0.85f, 0.22f, 0.18f); // Cinnabar red tips
        return p;
    }

    static TreePresetConfig getCliffJuniperBonsai() {
        TreePresetConfig p;
        p.name = "Basalt Cliff Juniper / Bonsai";
        p.crown_shape = CrownShape::VASE;
        p.branch_levels = 3;
        p.trunk_height = 4.2f;
        p.trunk_radius = 0.48f;
        p.trunk_segments = 5;
        p.radial_sides = 6;
        p.trunk_taper = 0.45f;
        p.trunk_gnarl = 0.45f; // Extreme twisted gnarled trunk
        p.phototropism = 0.15f;

        p.level1 = {3, 0.35f, 68.0f, 0.75f, 0.60f, 0.40f, 0.10f};
        p.level2 = {2, 0.40f, 45.0f, 0.55f, 0.52f, 0.35f, 0.25f};

        p.foliage_style = FoliageStyle::CLUSTERED_DOMES;
        p.foliage_radius = 1.4f;
        p.foliage_clusters = 3;
        p.bark_dark   = Ogre::ColourValue(0.32f, 0.22f, 0.18f);
        p.bark_light  = Ogre::ColourValue(0.55f, 0.42f, 0.32f);
        p.leaf_top    = Ogre::ColourValue(0.18f, 0.44f, 0.24f);
        p.leaf_mid    = Ogre::ColourValue(0.12f, 0.34f, 0.16f);
        p.leaf_shadow = Ogre::ColourValue(0.06f, 0.22f, 0.09f);
        p.has_blossoms = false;
        return p;
    }

    static TreePresetConfig getVolcanicTreeFern() {
        TreePresetConfig p;
        p.name = "Prehistoric Volcanic Tree Fern";
        p.crown_shape = CrownShape::HEMISPHERICAL;
        p.branch_levels = 1;
        p.trunk_height = 4.8f;
        p.trunk_radius = 0.36f;
        p.trunk_segments = 5;
        p.radial_sides = 6;
        p.trunk_taper = 0.12f;
        p.trunk_gnarl = 0.08f;
        p.phototropism = 0.65f;

        p.foliage_style = FoliageStyle::FERN_ROSETTE;
        p.foliage_radius = 3.2f;
        p.foliage_clusters = 1;
        p.bark_dark   = Ogre::ColourValue(0.24f, 0.18f, 0.12f);
        p.bark_light  = Ogre::ColourValue(0.40f, 0.30f, 0.20f);
        p.leaf_top    = Ogre::ColourValue(0.18f, 0.48f, 0.20f);
        p.leaf_mid    = Ogre::ColourValue(0.10f, 0.38f, 0.14f);
        p.leaf_shadow = Ogre::ColourValue(0.05f, 0.25f, 0.08f);
        p.has_blossoms = false;
        return p;
    }

    static TreePresetConfig getJoshuaTree() {
        TreePresetConfig p;
        p.name = "Volcanic Joshua Tree / Yucca";
        p.crown_shape = CrownShape::FLAME;
        p.branch_levels = 3;
        p.trunk_height = 5.2f;
        p.trunk_radius = 0.42f;
        p.trunk_segments = 4;
        p.radial_sides = 6;
        p.trunk_taper = 0.20f;
        p.trunk_gnarl = 0.35f;
        p.phototropism = 0.45f;

        p.level1 = {2, 0.55f, 55.0f, 0.65f, 0.70f, 0.30f, 0.40f};
        p.level2 = {2, 0.45f, 48.0f, 0.60f, 0.65f, 0.25f, 0.50f};

        p.foliage_style = FoliageStyle::JOSHUA_SPIKES;
        p.foliage_radius = 1.6f;
        p.foliage_clusters = 2;
        p.bark_dark   = Ogre::ColourValue(0.45f, 0.38f, 0.28f);
        p.bark_light  = Ogre::ColourValue(0.68f, 0.58f, 0.44f);
        p.leaf_top    = Ogre::ColourValue(0.26f, 0.46f, 0.24f);
        p.leaf_mid    = Ogre::ColourValue(0.18f, 0.36f, 0.16f);
        p.leaf_shadow = Ogre::ColourValue(0.10f, 0.24f, 0.10f);
        p.has_blossoms = true;
        p.blossom_color = Ogre::ColourValue(0.92f, 0.90f, 0.75f);
        return p;
    }
};

// ─── Procedural Flora & Props Mesh Synthesizer ─────────────────────────────────
class FloraMeshBuilder {
public:
    inline static const Ogre::ColourValue COL_PALM_TRUNK     = Ogre::ColourValue(0.65f, 0.48f, 0.32f, 1.0f);
    inline static const Ogre::ColourValue COL_PALM_RING      = Ogre::ColourValue(0.45f, 0.32f, 0.22f, 1.0f);
    inline static const Ogre::ColourValue COL_PALM_FROND_TOP = Ogre::ColourValue(0.20f, 0.48f, 0.18f, 1.0f);
    inline static const Ogre::ColourValue COL_PALM_FROND_BOT = Ogre::ColourValue(0.12f, 0.38f, 0.14f, 1.0f);

    inline static const Ogre::ColourValue COL_BUSH_LUSH      = Ogre::ColourValue(0.18f, 0.45f, 0.16f, 1.0f);
    inline static const Ogre::ColourValue COL_BUSH_FLOWER    = Ogre::ColourValue(0.98f, 0.38f, 0.50f, 1.0f);
    inline static const Ogre::ColourValue COL_FERN_GREEN     = Ogre::ColourValue(0.20f, 0.48f, 0.20f, 1.0f);

    inline static const Ogre::ColourValue COL_ROCK_DARK      = Ogre::ColourValue(0.20f, 0.21f, 0.24f, 1.0f);
    inline static const Ogre::ColourValue COL_ROCK_LIGHT     = Ogre::ColourValue(0.42f, 0.44f, 0.48f, 1.0f);
    inline static const Ogre::ColourValue COL_MOSS_DARK      = Ogre::ColourValue(0.15f, 0.36f, 0.12f, 1.0f);
    inline static const Ogre::ColourValue COL_MOSS_LIGHT     = Ogre::ColourValue(0.26f, 0.48f, 0.18f, 1.0f);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. EZ-Tree Parametric Tree Builder
    // ─────────────────────────────────────────────────────────────────────────
    static void buildEzTree(
        const FloraInstance& inst,
        const TreePresetConfig& cfg,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        float h = cfg.trunk_height * inst.scale;
        float r_base = cfg.trunk_radius * inst.scale;
        float r_top = r_base * (1.0f - cfg.trunk_taper);
        int segs = cfg.trunk_segments;
        int sides = cfg.radial_sides;

        // Construct trunk spine with natural organic curvature
        std::vector<Ogre::Vector3> trunk_spine(segs + 1);
        std::vector<float> trunk_radii(segs + 1);
        float yaw = inst.rotation_yaw;

        for (int i = 0; i <= segs; ++i) {
            float t = float(i) / float(segs);
            float gnarl_x = std::sin(t * 3.14159f * 1.2f + float(inst.seed % 17)) * (cfg.trunk_gnarl * h * 0.4f);
            float gnarl_z = std::cos(t * 3.14159f * 1.5f + float(inst.seed % 23)) * (cfg.trunk_gnarl * h * 0.4f);
            float lean_x  = std::sin(t * 1.57f) * (inst.lean_angle * h * 0.35f) * std::cos(inst.lean_yaw);
            float lean_z  = std::sin(t * 1.57f) * (inst.lean_angle * h * 0.35f) * std::sin(inst.lean_yaw);

            trunk_spine[i] = Ogre::Vector3(
                inst.pos.x + gnarl_x + lean_x,
                inst.pos.y + t * h,
                inst.pos.z + gnarl_z + lean_z
            );
            trunk_radii[i] = (1.0f - t) * r_base + t * r_top;
        }

        // Emit Trunk Cylinder
        emitBranchCylinder(trunk_spine, trunk_radii, sides, cfg.bark_dark, cfg.bark_light, 0.25f, out_verts, out_indices);

        // Recursive Branch Generation
        struct BranchTip {
            Ogre::Vector3 pos;
            Ogre::Vector3 dir;
            float radius;
            float length;
            int level;
        };

        std::vector<BranchTip> current_tips;
        // Seed primary scaffold branches along upper trunk
        int n_branches = cfg.level1.children_count;
        for (int b = 0; b < n_branches; ++b) {
            float t_spawn = cfg.level1.start_ratio + (1.0f - cfg.level1.start_ratio) * (float(b) / float(n_branches));
            int idx = std::min(segs, int(t_spawn * segs));
            Ogre::Vector3 origin = trunk_spine[idx];
            float branch_r = trunk_radii[idx] * cfg.level1.radius_ratio;
            float branch_len = h * cfg.level1.length_ratio * (0.85f + 0.3f * float((inst.seed + b * 13) % 7) / 6.0f);

            float b_angle = yaw + float(b) * (6.2831853f / float(n_branches)) + 0.35f * std::sin(float(b + inst.seed));
            float split_rad = cfg.level1.split_angle_deg * 0.0174533f;

            Ogre::Vector3 b_dir(
                std::cos(b_angle) * std::sin(split_rad),
                std::cos(split_rad) + cfg.level1.phototropism * 0.35f,
                std::sin(b_angle) * std::sin(split_rad)
            );
            b_dir.normalise();

            // Build scaffold branch spine
            int b_segs = 3;
            std::vector<Ogre::Vector3> b_spine(b_segs + 1);
            std::vector<float> b_radii(b_segs + 1);
            for (int s = 0; s <= b_segs; ++s) {
                float st = float(s) / float(b_segs);
                b_spine[s] = origin + b_dir * (st * branch_len) + Ogre::Vector3(0.0f, cfg.level1.phototropism * st * st * 0.8f, 0.0f);
                b_radii[s] = (1.0f - st * 0.45f) * branch_r;
            }
            emitBranchCylinder(b_spine, b_radii, 5, cfg.bark_dark, cfg.bark_light, 0.45f, out_verts, out_indices);

            if (cfg.branch_levels >= 2) {
                // Spawn secondary twigs
                for (int c = 0; c < cfg.level2.children_count; ++c) {
                    float ct = cfg.level2.start_ratio + (1.0f - cfg.level2.start_ratio) * (float(c) / float(cfg.level2.children_count));
                    int c_idx = std::min(b_segs, int(ct * b_segs));
                    Ogre::Vector3 c_origin = b_spine[c_idx];
                    float c_r = b_radii[c_idx] * cfg.level2.radius_ratio;
                    float c_len = branch_len * cfg.level2.length_ratio;

                    float c_angle = b_angle + ((c % 2 == 0) ? 0.75f : -0.75f);
                    float c_split = cfg.level2.split_angle_deg * 0.0174533f;
                    Ogre::Vector3 c_dir(
                        std::cos(c_angle) * std::sin(c_split),
                        std::cos(c_split) + cfg.level2.phototropism,
                        std::sin(c_angle) * std::sin(c_split)
                    );
                    c_dir.normalise();

                    std::vector<Ogre::Vector3> c_spine(3);
                    std::vector<float> c_radii(3);
                    for (int s = 0; s < 3; ++s) {
                        float st = float(s) / 2.0f;
                        c_spine[s] = c_origin + c_dir * (st * c_len) + Ogre::Vector3(0.0f, cfg.level2.phototropism * st * 1.2f, 0.0f);
                        c_radii[s] = (1.0f - st * 0.5f) * c_r;
                    }
                    emitBranchCylinder(c_spine, c_radii, 4, cfg.bark_dark, cfg.bark_light, 0.65f, out_verts, out_indices);
                    current_tips.push_back({c_spine.back(), c_dir, c_radii.back(), c_len, 2});
                }
            } else {
                current_tips.push_back({b_spine.back(), b_dir, b_radii.back(), branch_len, 1});
            }
        }
        // Also add top leader tip
        current_tips.push_back({trunk_spine.back(), Ogre::Vector3(0, 1, 0), trunk_radii.back(), h * 0.35f, 0});

        // ─────────────────────────────────────────────────────────────────────
        // Foliage Synthesis based on Preset Style
        // ─────────────────────────────────────────────────────────────────────
        for (const auto& tip : current_tips) {
            float f_rad = cfg.foliage_radius * inst.scale;

            switch (cfg.foliage_style) {
                case FoliageStyle::CLUSTERED_DOMES: {
                    for (int k = 0; k < cfg.foliage_clusters; ++k) {
                        float angle = float(k) / float(cfg.foliage_clusters) * 6.2831853f;
                        float offset_d = (k == 0) ? 0.0f : f_rad * 0.45f;
                        Ogre::Vector3 center = tip.pos + Ogre::Vector3(std::cos(angle) * offset_d, (k == 0) ? 0.3f : 0.0f, std::sin(angle) * offset_d);
                        buildFoliageDome(center, f_rad * ((k == 0) ? 1.0f : 0.75f), cfg.leaf_top, cfg.leaf_mid, cfg.leaf_shadow, out_verts, out_indices);
                    }
                    break;
                }
                case FoliageStyle::CONICAL_TIERS: {
                    // Pine / Conifer tiered skirts
                    for (int tier = 0; tier < 3; ++tier) {
                        float tier_y = tip.pos.y - float(tier) * (f_rad * 0.65f);
                        float tier_r = f_rad * (0.6f + float(tier) * 0.35f);
                        buildConiferSkirt(Ogre::Vector3(tip.pos.x, tier_y, tip.pos.z), tier_r, cfg.leaf_top, cfg.leaf_shadow, out_verts, out_indices);
                    }
                    break;
                }
                case FoliageStyle::WEEPING_STREAMERS: {
                    // Willow pendulous cascading clusters
                    buildFoliageDome(tip.pos + Ogre::Vector3(0, 0.4f, 0), f_rad * 0.8f, cfg.leaf_top, cfg.leaf_mid, cfg.leaf_shadow, out_verts, out_indices);
                    for (int w = 0; w < 4; ++w) {
                        float wa = float(w) * 1.5708f + 0.3f;
                        Ogre::Vector3 hang_pos = tip.pos + Ogre::Vector3(std::cos(wa) * f_rad * 0.6f, -f_rad * 0.75f, std::sin(wa) * f_rad * 0.6f);
                        buildWeepingCascade(hang_pos, f_rad * 0.65f, cfg.leaf_mid, cfg.leaf_shadow, out_verts, out_indices);
                    }
                    break;
                }
                case FoliageStyle::PARASOL_CANOPY: {
                    // Flat acacia canopy with blossom highlights
                    buildParasolFoliage(tip.pos + Ogre::Vector3(0, 0.25f, 0), f_rad * 1.15f, cfg.leaf_top, cfg.leaf_mid, cfg.leaf_shadow, cfg.has_blossoms, cfg.blossom_color, out_verts, out_indices);
                    break;
                }
                case FoliageStyle::SLENDER_AIRY: {
                    buildFoliageDome(tip.pos, f_rad * 0.85f, cfg.leaf_top, cfg.leaf_mid, cfg.leaf_shadow, out_verts, out_indices);
                    break;
                }
                case FoliageStyle::DRAGON_UMBRELLA: {
                    // Dense succulent geometric umbrella crown with cinnabar red tips
                    buildFoliageDome(tip.pos + Ogre::Vector3(0, 0.25f, 0), f_rad * 1.25f, cfg.blossom_color, cfg.leaf_top, cfg.leaf_shadow, out_verts, out_indices);
                    break;
                }
                case FoliageStyle::FERN_ROSETTE: {
                    // Multi-tiered radiating fern fronds
                    const int N_FERN_FRONDS = 10;
                    for (int f = 0; f < N_FERN_FRONDS; ++f) {
                        float f_ang = float(f) / float(N_FERN_FRONDS) * 6.2831853f + inst.rotation_yaw;
                        uint32_t f_base = static_cast<uint32_t>(out_verts.size());
                        const int F_SEGS = 5;
                        for (int s = 0; s <= F_SEGS; ++s) {
                            float st = float(s) / float(F_SEGS);
                            float dist = st * f_rad;
                            float y_off = std::sin(st * 3.14159f * 0.5f) * 0.65f - st * st * 0.80f;
                            float fx = tip.pos.x + std::cos(f_ang) * dist;
                            float fz = tip.pos.z + std::sin(f_ang) * dist;
                            float fy = tip.pos.y + y_off;
                            float w = std::sin(st * 3.14159f) * 0.40f * inst.scale;
                            float px = -std::sin(f_ang) * w;
                            float pz =  std::cos(f_ang) * w;
                            Ogre::ColourValue col = (1.0f - st) * cfg.leaf_top + st * cfg.leaf_mid;
                            VegetationVertex vl{Ogre::Vector3(fx + px, fy, fz + pz), Ogre::Vector3(0, 1, 0), col, 0.4f + st * 0.6f};
                            VegetationVertex vr{Ogre::Vector3(fx - px, fy, fz - pz), Ogre::Vector3(0, 1, 0), col, 0.4f + st * 0.6f};
                            out_verts.push_back(vl);
                            out_verts.push_back(vr);
                        }
                        for (int s = 0; s < F_SEGS; ++s) {
                            uint32_t l0 = f_base + s * 2;
                            uint32_t r0 = l0 + 1;
                            uint32_t l1 = l0 + 2;
                            uint32_t r1 = l0 + 3;
                            out_indices.push_back(l0); out_indices.push_back(l1); out_indices.push_back(r1);
                            out_indices.push_back(l0); out_indices.push_back(r1); out_indices.push_back(r0);
                            out_indices.push_back(l0); out_indices.push_back(r1); out_indices.push_back(l1);
                            out_indices.push_back(l0); out_indices.push_back(r0); out_indices.push_back(r1);
                        }
                    }
                    break;
                }
                case FoliageStyle::JOSHUA_SPIKES: {
                    // Spiky rosettes at branch tips
                    buildFoliageDome(tip.pos, f_rad * 0.75f, cfg.has_blossoms ? cfg.blossom_color : cfg.leaf_top, cfg.leaf_mid, cfg.leaf_shadow, out_verts, out_indices);
                    break;
                }
                case FoliageStyle::PALM_FRONDS:
                    break;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Coastal Coconut Palm Builder
    // ─────────────────────────────────────────────────────────────────────────
    static void buildPalmTree(
        const FloraInstance& inst,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        float height = 7.8f * inst.scale;
        float base_radius = 0.34f * inst.scale;
        float top_radius  = 0.18f * inst.scale;
        int num_rings = 14;
        int sides = 6;

        std::vector<Ogre::Vector3> spine(num_rings + 1);
        std::vector<float> radii(num_rings + 1);

        for (int r = 0; r <= num_rings; ++r) {
            float t = float(r) / float(num_rings);
            float lean_mag = std::sin(t * 1.5708f) * (inst.lean_angle * height * 0.50f);
            float lx = std::cos(inst.lean_yaw) * lean_mag;
            float lz = std::sin(inst.lean_yaw) * lean_mag;

            spine[r] = Ogre::Vector3(inst.pos.x + lx, inst.pos.y + t * height, inst.pos.z + lz);
            radii[r] = (1.0f - t) * base_radius + t * top_radius;
        }

        emitBranchCylinder(spine, radii, sides, COL_PALM_TRUNK, COL_PALM_RING, 0.65f, out_verts, out_indices);

        // Coconut cluster at crown base
        Ogre::Vector3 crown = spine.back();
        int num_coconuts = 4 + (inst.seed % 3);
        for (int c = 0; c < num_coconuts; ++c) {
            float ca = float(c) / float(num_coconuts) * 6.2831853f + 0.35f;
            float cr = 0.28f * inst.scale;
            Ogre::Vector3 c_pos = crown + Ogre::Vector3(std::cos(ca) * cr, -0.20f * inst.scale, std::sin(ca) * cr);
            buildSingleRock(c_pos, 0.16f * inst.scale, Ogre::Vector3(0.85f, 1.15f, 0.85f), ca, inst.seed + c * 47, 0.0f, out_verts, out_indices);
        }

        // Crown Fronds (Golden Angle Phyllotaxis)
        const int NUM_FRONDS = 14;
        const float GOLDEN_ANGLE = 2.39996323f; // ~137.5°

        for (int f = 0; f < NUM_FRONDS; ++f) {
            float f_angle = float(f) * GOLDEN_ANGLE + inst.rotation_yaw;
            float droop_phase = float(f) / float(NUM_FRONDS);
            float frond_len = (3.8f + (f % 3) * 0.35f) * inst.scale;
            float droop = 1.1f + droop_phase * 0.9f;

            uint32_t frond_base = static_cast<uint32_t>(out_verts.size());
            const int FROND_SEGS = 6;

            for (int seg = 0; seg <= FROND_SEGS; ++seg) {
                float st = float(seg) / float(FROND_SEGS);
                float arc_r = st * frond_len;
                float arc_y = std::sin(st * 3.14159f * 0.6f) * 0.85f - std::pow(st, 2.0f) * droop;

                float fx = crown.x + std::cos(f_angle) * arc_r;
                float fz = crown.z + std::sin(f_angle) * arc_r;
                float fy = crown.y + arc_y;

                float blade_w = std::sin(st * 3.14159f) * 0.45f * inst.scale;
                float perp_x = -std::sin(f_angle);
                float perp_z =  std::cos(f_angle);

                Ogre::ColourValue col = (1.0f - st) * COL_PALM_FROND_TOP + st * COL_PALM_FROND_BOT;

                VegetationVertex vl, vr;
                vl.position = Ogre::Vector3(fx + perp_x * blade_w, fy, fz + perp_z * blade_w);
                vl.normal = Ogre::Vector3(0, 1, 0);
                vl.color = col;
                vl.wind_weight = 0.5f + st * 0.5f;

                vr.position = Ogre::Vector3(fx - perp_x * blade_w, fy, fz - perp_z * blade_w);
                vr.normal = Ogre::Vector3(0, 1, 0);
                vr.color = col;
                vr.wind_weight = 0.5f + st * 0.5f;

                out_verts.push_back(vl);
                out_verts.push_back(vr);
            }

            for (int seg = 0; seg < FROND_SEGS; ++seg) {
                uint32_t l0 = frond_base + seg * 2;
                uint32_t r0 = l0 + 1;
                uint32_t l1 = l0 + 2;
                uint32_t r1 = l0 + 3;

                out_indices.push_back(l0); out_indices.push_back(l1); out_indices.push_back(r1);
                out_indices.push_back(l0); out_indices.push_back(r1); out_indices.push_back(r0);
                out_indices.push_back(l0); out_indices.push_back(r1); out_indices.push_back(l1);
                out_indices.push_back(l0); out_indices.push_back(r0); out_indices.push_back(r1);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Understory Flora (Bushes & Ferns)
    // ─────────────────────────────────────────────────────────────────────────
    static void buildTropicalBush(
        const FloraInstance& inst,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        float r = 1.15f * inst.scale;
        int num_mounds = 3 + (inst.seed % 2);
        for (int m = 0; m < num_mounds; ++m) {
            float angle = float(m) / float(num_mounds) * 6.2831853f + float(inst.seed % 7);
            float dist = (m == 0) ? 0.0f : r * 0.45f;
            Ogre::Vector3 center(
                inst.pos.x + std::cos(angle) * dist,
                inst.pos.y + r * 0.65f,
                inst.pos.z + std::sin(angle) * dist
            );
            Ogre::ColourValue col_top = (m == 0 && (inst.seed % 3 == 0)) ? COL_BUSH_FLOWER : COL_BUSH_LUSH;
            buildFoliageDome(center, r * ((m == 0) ? 0.95f : 0.70f), col_top, COL_BUSH_LUSH * 0.8f, COL_BUSH_LUSH * 0.4f, out_verts, out_indices);
        }
    }

    static void buildSlopeFern(
        const FloraInstance& inst,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int fronds = 8;
        float r_len = 1.6f * inst.scale;
        Ogre::Vector3 center(inst.pos.x, inst.pos.y + 0.12f, inst.pos.z);

        for (int f = 0; f < fronds; ++f) {
            float angle = float(f) / float(fronds) * 6.2831853f + inst.rotation_yaw;
            uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

            for (int seg = 0; seg <= 4; ++seg) {
                float t = float(seg) / 4.0f;
                float dist = t * r_len;
                float y = center.y + std::sin(t * 3.14159f * 0.5f) * 0.45f - t * t * 0.35f;
                float fx = center.x + std::cos(angle) * dist;
                float fz = center.z + std::sin(angle) * dist;
                float w = std::sin(t * 3.14159f) * 0.28f * inst.scale;
                float px = -std::sin(angle) * w;
                float pz =  std::cos(angle) * w;

                VegetationVertex vl{Ogre::Vector3(fx + px, y, fz + pz), Ogre::Vector3(0, 1, 0), COL_FERN_GREEN, 0.4f + t * 0.6f};
                VegetationVertex vr{Ogre::Vector3(fx - px, y, fz - pz), Ogre::Vector3(0, 1, 0), COL_FERN_GREEN, 0.4f + t * 0.6f};
                out_verts.push_back(vl);
                out_verts.push_back(vr);
            }

            for (int seg = 0; seg < 4; ++seg) {
                uint32_t l0 = base_idx + seg * 2;
                uint32_t r0 = l0 + 1;
                uint32_t l1 = l0 + 2;
                uint32_t r1 = l0 + 3;
                out_indices.push_back(l0); out_indices.push_back(l1); out_indices.push_back(r1);
                out_indices.push_back(l0); out_indices.push_back(r1); out_indices.push_back(r0);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Geological Props (Faceted Boulders & Mossy Rock Clumps)
    // ─────────────────────────────────────────────────────────────────────────
    static void buildSingleRock(
        const Ogre::Vector3& center,
        float radius,
        const Ogre::Vector3& scale_axes,
        float yaw,
        unsigned seed,
        float moss_amount,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int lat_segs = 4;
        int lon_segs = 6;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        float cy = std::cos(yaw);
        float sy = std::sin(yaw);

        for (int lat = 0; lat <= lat_segs; ++lat) {
            float theta = (float(lat) / float(lat_segs)) * 3.14159265f;
            float sin_t = std::sin(theta);
            float cos_t = std::cos(theta);

            for (int lon = 0; lon <= lon_segs; ++lon) {
                float phi = (float(lon) / float(lon_segs)) * 6.2831853f;

                float pert = 1.0f + 0.26f * std::sin(phi * 2.0f + theta * 3.0f + float(seed % 17))
                                  + 0.14f * std::cos(phi * 4.0f - theta * 2.0f + float(seed % 31));

                float lx = sin_t * std::cos(phi) * radius * scale_axes.x * pert;
                float ly = cos_t * radius * scale_axes.y * 0.72f * pert;
                float lz = sin_t * std::sin(phi) * radius * scale_axes.z * pert;

                float rx = lx * cy - lz * sy;
                float rz = lx * sy + lz * cy;

                Ogre::Vector3 world_pos = center + Ogre::Vector3(rx, ly, rz);
                Ogre::Vector3 raw_norm(sin_t * std::cos(phi), cos_t, sin_t * std::sin(phi));
                float rnx = raw_norm.x * cy - raw_norm.z * sy;
                float rnz = raw_norm.x * sy + raw_norm.z * cy;
                Ogre::Vector3 normal = Ogre::Vector3(rnx, raw_norm.y, rnz).normalisedCopy();

                float t_up = std::max(0.0f, std::min(1.0f, (normal.y - 0.15f) / 0.55f));
                float m = t_up * moss_amount;

                Ogre::ColourValue rock_col = (1.0f - t_up) * COL_ROCK_DARK + t_up * COL_ROCK_LIGHT;
                Ogre::ColourValue moss_col = (1.0f - t_up) * COL_MOSS_DARK + t_up * COL_MOSS_LIGHT;
                Ogre::ColourValue vert_col = (1.0f - m) * rock_col + m * moss_col;

                VegetationVertex v{world_pos, normal, vert_col, 0.0f};
                out_verts.push_back(v);
            }
        }

        for (int lat = 0; lat < lat_segs; ++lat) {
            for (int lon = 0; lon < lon_segs; ++lon) {
                uint32_t i00 = base_idx + lat * (lon_segs + 1) + lon;
                uint32_t i01 = base_idx + (lat + 1) * (lon_segs + 1) + lon;
                uint32_t i11 = base_idx + (lat + 1) * (lon_segs + 1) + (lon + 1);
                uint32_t i10 = base_idx + lat * (lon_segs + 1) + (lon + 1);

                out_indices.push_back(i00); out_indices.push_back(i01); out_indices.push_back(i11);
                out_indices.push_back(i00); out_indices.push_back(i11); out_indices.push_back(i10);
            }
        }
    }

    static void buildRockClump(
        const FloraInstance& inst,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices,
        float moss_amount = 0.85f
    ) {
        float main_radius = 1.15f * inst.scale;
        Ogre::Vector3 center(inst.pos.x, inst.pos.y + main_radius * 0.42f, inst.pos.z);

        buildSingleRock(center, main_radius, Ogre::Vector3(1.1f, 0.85f, 1.0f), inst.rotation_yaw, inst.seed, moss_amount, out_verts, out_indices);

        int num_satellites = 2 + (inst.seed % 3);
        for (int i = 0; i < num_satellites; ++i) {
            float angle = float(i) / float(num_satellites) * 6.2831853f + float((inst.seed + i * 7) % 11) * 0.15f;
            float dist = main_radius * (0.85f + 0.35f * float((inst.seed + i * 13) % 7) / 6.0f);
            float sat_radius = main_radius * (0.35f + 0.30f * float((inst.seed + i * 19) % 5) / 4.0f);

            Ogre::Vector3 sat_pos(center.x + std::cos(angle) * dist, inst.pos.y + sat_radius * 0.35f, center.z + std::sin(angle) * dist);
            buildSingleRock(sat_pos, sat_radius, Ogre::Vector3(1.0f, 0.75f, 0.9f), inst.rotation_yaw + float(i), inst.seed + (i + 1) * 101, moss_amount * 0.9f, out_verts, out_indices);
        }
    }

private:
    static void emitBranchCylinder(
        const std::vector<Ogre::Vector3>& spine,
        const std::vector<float>& radii,
        int sides,
        const Ogre::ColourValue& col_dark,
        const Ogre::ColourValue& col_light,
        float max_wind_weight,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int num_rings = static_cast<int>(spine.size());
        if (num_rings < 2) return;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        for (int r = 0; r < num_rings; ++r) {
            float t = float(r) / float(num_rings - 1);
            Ogre::ColourValue col = (1.0f - t) * col_dark + t * col_light;

            for (int s = 0; s < sides; ++s) {
                float a = float(s) / float(sides) * 6.2831853f;
                float nx = std::cos(a);
                float nz = std::sin(a);
                Ogre::Vector3 p = spine[r] + Ogre::Vector3(nx * radii[r], 0.0f, nz * radii[r]);

                VegetationVertex v{p, Ogre::Vector3(nx, 0.15f, nz).normalisedCopy(), col, t * t * max_wind_weight};
                out_verts.push_back(v);
            }
        }

        for (int r = 0; r < num_rings - 1; ++r) {
            for (int s = 0; s < sides; ++s) {
                int next_s = (s + 1) % sides;
                uint32_t i00 = base_idx + r * sides + s;
                uint32_t i01 = base_idx + (r + 1) * sides + s;
                uint32_t i11 = base_idx + (r + 1) * sides + next_s;
                uint32_t i10 = base_idx + r * sides + next_s;

                out_indices.push_back(i00); out_indices.push_back(i01); out_indices.push_back(i11);
                out_indices.push_back(i00); out_indices.push_back(i11); out_indices.push_back(i10);
            }
        }
    }

    static void buildFoliageDome(
        const Ogre::Vector3& center,
        float radius,
        const Ogre::ColourValue& col_top,
        const Ogre::ColourValue& col_mid,
        const Ogre::ColourValue& col_bot,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int lat_segs = 4;
        int lon_segs = 7;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        for (int lat = 0; lat <= lat_segs; ++lat) {
            float theta = (float(lat) / float(lat_segs)) * 3.14159265f * 0.75f;
            float sin_t = std::sin(theta);
            float cos_t = std::cos(theta);
            float t_h = (1.0f + cos_t) * 0.5f;

            Ogre::ColourValue col = (t_h > 0.6f)
                ? ((t_h - 0.6f) / 0.4f * col_top + (1.0f - (t_h - 0.6f) / 0.4f) * col_mid)
                : (t_h / 0.6f * col_mid + (1.0f - t_h / 0.6f) * col_bot);

            for (int lon = 0; lon <= lon_segs; ++lon) {
                float phi = (float(lon) / float(lon_segs)) * 6.2831853f;
                float nx = sin_t * std::cos(phi);
                float ny = cos_t;
                float nz = sin_t * std::sin(phi);

                float pert = 1.0f + 0.12f * std::sin(phi * 3.0f + theta * 4.0f);
                Ogre::Vector3 pos = center + Ogre::Vector3(nx * radius * pert, ny * radius * 0.85f * pert, nz * radius * pert);
                // SeedThree Volumetric Dome Normal shading: blend geometric normal with radial dome normal
                Ogre::Vector3 radial_norm = (pos - center).normalisedCopy();
                Ogre::Vector3 geom_norm = Ogre::Vector3(nx, ny * 0.8f + 0.2f, nz).normalisedCopy();
                Ogre::Vector3 norm = (geom_norm * 0.30f + radial_norm * 0.70f).normalisedCopy();

                VegetationVertex v{pos, norm, col, 0.45f + t_h * 0.55f};
                out_verts.push_back(v);
            }
        }

        for (int lat = 0; lat < lat_segs; ++lat) {
            for (int lon = 0; lon < lon_segs; ++lon) {
                uint32_t i00 = base_idx + lat * (lon_segs + 1) + lon;
                uint32_t i01 = base_idx + (lat + 1) * (lon_segs + 1) + lon;
                uint32_t i11 = base_idx + (lat + 1) * (lon_segs + 1) + (lon + 1);
                uint32_t i10 = base_idx + lat * (lon_segs + 1) + (lon + 1);

                out_indices.push_back(i00); out_indices.push_back(i01); out_indices.push_back(i11);
                out_indices.push_back(i00); out_indices.push_back(i11); out_indices.push_back(i10);
            }
        }
    }

    static void buildConiferSkirt(
        const Ogre::Vector3& center,
        float radius,
        const Ogre::ColourValue& col_top,
        const Ogre::ColourValue& col_bot,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int sides = 8;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        // Apex vertex
        VegetationVertex apex{center + Ogre::Vector3(0, radius * 0.5f, 0), Ogre::Vector3(0, 1, 0), col_top, 0.65f};
        out_verts.push_back(apex);

        // Skirt rim vertices with volumetric outwards normal
        for (int s = 0; s <= sides; ++s) {
            float a = float(s) / float(sides) * 6.2831853f;
            float px = std::cos(a) * radius;
            float pz = std::sin(a) * radius;
            Ogre::Vector3 pos = center + Ogre::Vector3(px, -radius * 0.45f, pz);
            Ogre::Vector3 radial_norm = (pos - center).normalisedCopy();
            Ogre::Vector3 geom_norm = Ogre::Vector3(std::cos(a), 0.4f, std::sin(a)).normalisedCopy();
            Ogre::Vector3 norm = (geom_norm * 0.35f + radial_norm * 0.65f).normalisedCopy();

            VegetationVertex v{pos, norm, col_bot, 0.85f};
            out_verts.push_back(v);
        }

        for (int s = 0; s < sides; ++s) {
            uint32_t i0 = base_idx;
            uint32_t i1 = base_idx + 1 + s;
            uint32_t i2 = base_idx + 1 + (s + 1);
            out_indices.push_back(i0); out_indices.push_back(i1); out_indices.push_back(i2);
            // Double-sided
            out_indices.push_back(i0); out_indices.push_back(i2); out_indices.push_back(i1);
        }
    }

    static void buildWeepingCascade(
        const Ogre::Vector3& center,
        float radius,
        const Ogre::ColourValue& col_top,
        const Ogre::ColourValue& col_bot,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int sides = 6;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        for (int h = 0; h <= 2; ++h) {
            float ht = float(h) / 2.0f;
            float y = center.y - ht * (radius * 1.8f);
            float r = radius * (1.0f - ht * 0.4f);
            Ogre::ColourValue col = (1.0f - ht) * col_top + ht * col_bot;

            for (int s = 0; s < sides; ++s) {
                float a = float(s) / float(sides) * 6.2831853f;
                Ogre::Vector3 p = Ogre::Vector3(center.x + std::cos(a) * r, y, center.z + std::sin(a) * r);
                Ogre::Vector3 radial_norm = (p - center).normalisedCopy();
                Ogre::Vector3 norm = (Ogre::Vector3(std::cos(a), -0.2f, std::sin(a)) * 0.4f + radial_norm * 0.6f).normalisedCopy();
                VegetationVertex v{p, norm, col, 0.7f + ht * 0.3f};
                out_verts.push_back(v);
            }
        }

        for (int h = 0; h < 2; ++h) {
            for (int s = 0; s < sides; ++s) {
                int next_s = (s + 1) % sides;
                uint32_t i00 = base_idx + h * sides + s;
                uint32_t i01 = base_idx + (h + 1) * sides + s;
                uint32_t i11 = base_idx + (h + 1) * sides + next_s;
                uint32_t i10 = base_idx + h * sides + next_s;

                out_indices.push_back(i00); out_indices.push_back(i01); out_indices.push_back(i11);
                out_indices.push_back(i00); out_indices.push_back(i11); out_indices.push_back(i10);
            }
        }
    }

    static void buildParasolFoliage(
        const Ogre::Vector3& center,
        float radius,
        const Ogre::ColourValue& col_top,
        const Ogre::ColourValue& col_mid,
        const Ogre::ColourValue& col_shadow,
        bool has_blossoms,
        const Ogre::ColourValue& blossom_col,
        std::vector<VegetationVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int sides = 9;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        // Top canopy disk center
        Ogre::ColourValue center_col = has_blossoms ? blossom_col : col_top;
        VegetationVertex top_center{center + Ogre::Vector3(0, 0.35f, 0), Ogre::Vector3(0, 1, 0), center_col, 0.75f};
        out_verts.push_back(top_center);

        // Parasol rim vertices with radial dome normals
        for (int s = 0; s <= sides; ++s) {
            float a = float(s) / float(sides) * 6.2831853f;
            float px = std::cos(a) * radius;
            float pz = std::sin(a) * radius;
            Ogre::ColourValue rim_col = (has_blossoms && (s % 2 == 0)) ? blossom_col : col_mid;
            Ogre::Vector3 pos = center + Ogre::Vector3(px, -0.15f, pz);
            Ogre::Vector3 radial_norm = (pos - center).normalisedCopy();
            Ogre::Vector3 norm = (Ogre::Vector3(0, 0.8f, 0) * 0.35f + radial_norm * 0.65f).normalisedCopy();
            VegetationVertex v{pos, norm, rim_col, 0.85f};
            out_verts.push_back(v);
        }

        for (int s = 0; s < sides; ++s) {
            out_indices.push_back(base_idx);
            out_indices.push_back(base_idx + 1 + s);
            out_indices.push_back(base_idx + 1 + (s + 1));
            // Underside
            out_indices.push_back(base_idx);
            out_indices.push_back(base_idx + 1 + (s + 1));
            out_indices.push_back(base_idx + 1 + s);
        }
    }
};

// ─── Grove & Stand Spatial Ecology Clumping Manager ───────────────────────────
struct GroveDefinition {
    std::string name;
    float center_x;
    float center_z;
    float radius;
    FloraType primary_tree;
    int tree_count;
    int bush_count;
    int rock_count;
};

class IslandVegetationSystem {
public:
    std::vector<FloraInstance> flora_instances;
    float simulation_time = 0.0f;

    // Wind dynamics
    float wind_strength = 0.45f;
    float wind_speed    = 1.8f;
    Spatial::Vector3D wind_dir{1.0f, 0.0f, 0.4f};

    std::vector<VegetationVertex> base_vertices;
    std::vector<uint32_t>         mesh_indices;
    std::vector<Ogre::Vector3>    swayed_positions_;

    IslandVegetationSystem() {
        wind_dir = wind_dir.normalized();
    }

    /**
     * Procedurally populates the island with discrete ecological groves and clumps,
     * leaving open savanna clearings, volcanic scree, and sandy dunes.
     */
    void populateIsland(const Island::VoxelIsland& island, const WFC::HierarchicalSolver& wfc) {
        (void)wfc;
        flora_instances.clear();
        base_vertices.clear();
        mesh_indices.clear();

        std::mt19937 rng(133742);
        std::uniform_real_distribution<float> rand_01(0.0f, 1.0f);

        // ─────────────────────────────────────────────────────────────────────
        // 1. Define Discrete Ecological Groves across the Island
        // ─────────────────────────────────────────────────────────────────────
        std::vector<GroveDefinition> groves;

        if (island.biome_type == Island::IslandBiomeType::DESERT) {
            // Oasis palms & Joshua trees / Yuccas
            groves.push_back({"Central Oasis Date Palm Stand", island.center_x, island.center_z, 18.0f, FloraType::COASTAL_PALM_TREE, 18, 12, 6});
            groves.push_back({"South-West Dune Joshua Stand", island.center_x - island.island_radius * 0.35f, island.center_z - island.island_radius * 0.35f, 22.0f, FloraType::JOSHUA_TREE_YUCCA, 14, 8, 8});
            groves.push_back({"North-East Arch Joshua Stand", island.center_x + island.island_radius * 0.35f, island.center_z + island.island_radius * 0.35f, 20.0f, FloraType::JOSHUA_TREE_YUCCA, 12, 6, 10});
            groves.push_back({"East Dragon Blood Knoll", island.center_x + island.island_radius * 0.40f, island.center_z - island.island_radius * 0.15f, 20.0f, FloraType::DRAGON_BLOOD_TREE, 10, 8, 8});
        } else if (island.biome_type == Island::IslandBiomeType::GLACIAL_ICE) {
            // Alpine Pines & Birches & Glacial Rocks
            groves.push_back({"Glacial Foothill Pine Forest", island.center_x - island.island_radius * 0.30f, island.center_z - island.island_radius * 0.30f, 26.0f, FloraType::HIGHLAND_CONIFER_TREE, 20, 10, 12});
            groves.push_back({"North-East Conifer Stand", island.center_x + island.island_radius * 0.32f, island.center_z + island.island_radius * 0.28f, 24.0f, FloraType::HIGHLAND_CONIFER_TREE, 18, 8, 10});
            groves.push_back({"Arctic Aspen Glade", island.center_x + island.island_radius * 0.15f, island.center_z - island.island_radius * 0.35f, 20.0f, FloraType::SLENDER_BIRCH_TREE, 16, 12, 8});
        } else if (island.biome_type == Island::IslandBiomeType::CORAL_ARCHIPELAGO) {
            // Palm strands on all 5 islets
            for (int k = 0; k < 5; ++k) {
                float a = k * (6.2831853f / 5.0f);
                float ix = island.center_x + std::cos(a) * (island.island_radius * 0.60f);
                float iz = island.center_z + std::sin(a) * (island.island_radius * 0.60f);
                groves.push_back({"Atoll Islet Palm Grove", ix, iz, 18.0f, FloraType::COASTAL_PALM_TREE, 12, 10, 6});
            }
        } else if (island.biome_type == Island::IslandBiomeType::JUNGLE) {
            // Dense multi-canopy jungle
            groves.push_back({"Highland Banyan Canopy", island.center_x - 20.0f, island.center_z + 15.0f, 32.0f, FloraType::BANYAN_OAK_TREE, 22, 18, 12});
            groves.push_back({"East Rainforest Ridge", island.center_x + 35.0f, island.center_z - 20.0f, 28.0f, FloraType::BANYAN_OAK_TREE, 20, 16, 10});
            groves.push_back({"Valley Fern Grotto", island.center_x, island.center_z, 24.0f, FloraType::VOLCANIC_TREE_FERN, 16, 14, 8});
            groves.push_back({"Coastal Palm Fringe", island.center_x - island.island_radius * 0.45f, island.center_z - island.island_radius * 0.45f, 25.0f, FloraType::COASTAL_PALM_TREE, 16, 12, 6});
            groves.push_back({"Weeping Mangrove Basin", island.center_x + island.island_radius * 0.35f, island.center_z + island.island_radius * 0.35f, 24.0f, FloraType::WEEPING_WILLOW_TREE, 14, 10, 8});
        } else {
            // VOLCANO
            groves.push_back({"South-West Palm Beach Strand", island.center_x - island.island_radius * 0.45f, island.center_z - island.island_radius * 0.48f, 24.0f, FloraType::COASTAL_PALM_TREE, 16, 10, 8});
            groves.push_back({"South-East Palm Cove", island.center_x + island.island_radius * 0.42f, island.center_z - island.island_radius * 0.45f, 22.0f, FloraType::COASTAL_PALM_TREE, 14, 8, 6});
            groves.push_back({"West Lowland Banyan & Hardwood Forest", island.center_x - island.island_radius * 0.50f, island.center_z + island.island_radius * 0.05f, 28.0f, FloraType::BANYAN_OAK_TREE, 15, 14, 10});
            groves.push_back({"East Savanna Flowering Acacia Stand", island.center_x + island.island_radius * 0.48f, island.center_z + island.island_radius * 0.08f, 26.0f, FloraType::PARASOL_ACACIA_TREE, 14, 12, 6});
            groves.push_back({"North-West Weeping Willow Cove", island.center_x - island.island_radius * 0.35f, island.center_z + island.island_radius * 0.48f, 24.0f, FloraType::WEEPING_WILLOW_TREE, 12, 10, 8});
            groves.push_back({"North-East Slender Birch & Aspen Glade", island.center_x + island.island_radius * 0.32f, island.center_z + island.island_radius * 0.45f, 25.0f, FloraType::SLENDER_BIRCH_TREE, 15, 11, 7});
            groves.push_back({"South-East Highland Conifer Ridge", island.center_x + island.island_radius * 0.28f, island.center_z - island.island_radius * 0.20f, 22.0f, FloraType::HIGHLAND_CONIFER_TREE, 12, 8, 8});
            groves.push_back({"North Highland Conifer Stand", island.center_x - island.island_radius * 0.15f, island.center_z + island.island_radius * 0.32f, 20.0f, FloraType::HIGHLAND_CONIFER_TREE, 11, 7, 7});
            groves.push_back({"South-Central Floral Savanna", island.center_x - island.island_radius * 0.12f, island.center_z - island.island_radius * 0.35f, 22.0f, FloraType::PARASOL_ACACIA_TREE, 13, 10, 6});
            groves.push_back({"Dragon Blood Volcanic Scree Plateau", island.center_x - island.island_radius * 0.38f, island.center_z - island.island_radius * 0.22f, 20.0f, FloraType::DRAGON_BLOOD_TREE, 10, 6, 8});
            groves.push_back({"Prehistoric Tree Fern Moisture Pocket", island.center_x - island.island_radius * 0.22f, island.center_z + island.island_radius * 0.18f, 18.0f, FloraType::VOLCANIC_TREE_FERN, 12, 10, 5});
            groves.push_back({"Arid Joshua Tree Knoll", island.center_x + island.island_radius * 0.18f, island.center_z - island.island_radius * 0.40f, 19.0f, FloraType::JOSHUA_TREE_YUCCA, 10, 8, 7});
            groves.push_back({"Basalt Cliff Juniper Outcrop", island.center_x + island.island_radius * 0.44f, island.center_z + island.island_radius * 0.28f, 18.0f, FloraType::CLIFF_JUNIPER_BONSAI, 8, 6, 10});
        }

        // ─────────────────────────────────────────────────────────────────────
        // 2. Synthesize Clustered Entities within each Grove
        // ─────────────────────────────────────────────────────────────────────
        for (const auto& grove : groves) {
            // A. Spawn Clumped Trees
            for (int i = 0; i < grove.tree_count; ++i) {
                float angle = rand_01(rng) * 6.2831853f;
                float r_dist = std::sqrt(rand_01(rng)) * grove.radius;
                float fx = grove.center_x + std::cos(angle) * r_dist;
                float fz = grove.center_z + std::sin(angle) * r_dist;

                if (!isValidSpawnLocation(island, fx, fz)) continue;
                float h = island.getIslandHeight(fx, fz);

                FloraInstance inst;
                inst.type = grove.primary_tree;
                inst.pos = Spatial::Point3D(fx, h - 0.05f, fz);
                inst.scale = (1.0f + rand_01(rng) * 0.45f);
                inst.rotation_yaw = rand_01(rng) * 6.2831853f;
                inst.lean_angle = (grove.primary_tree == FloraType::COASTAL_PALM_TREE || grove.primary_tree == FloraType::CLIFF_JUNIPER_BONSAI)
                                  ? (0.18f + rand_01(rng) * 0.28f)
                                  : (rand_01(rng) * 0.06f);
                inst.lean_yaw   = std::atan2(fz - island.center_z, fx - island.center_x);
                inst.seed = static_cast<unsigned>(rng());
                flora_instances.push_back(inst);
            }

            // B. Spawn Understory Bushes & Ferns in the Grove
            for (int i = 0; i < grove.bush_count; ++i) {
                float angle = rand_01(rng) * 6.2831853f;
                float r_dist = std::sqrt(rand_01(rng)) * grove.radius;
                float fx = grove.center_x + std::cos(angle) * r_dist;
                float fz = grove.center_z + std::sin(angle) * r_dist;

                if (!isValidSpawnLocation(island, fx, fz)) continue;
                float h = island.getIslandHeight(fx, fz);

                FloraInstance inst;
                inst.type = (rand_01(rng) > 0.4f) ? FloraType::TROPICAL_BUSH : FloraType::SLOPE_FERN;
                inst.pos = Spatial::Point3D(fx, h - 0.03f, fz);
                inst.scale = (0.85f + rand_01(rng) * 0.45f);
                inst.rotation_yaw = rand_01(rng) * 6.2831853f;
                inst.lean_angle = 0.0f;
                inst.lean_yaw = 0.0f;
                inst.seed = static_cast<unsigned>(rng());
                flora_instances.push_back(inst);
            }

            // C. Spawn Mossy Rock Clumps in the Grove
            for (int i = 0; i < grove.rock_count; ++i) {
                float angle = rand_01(rng) * 6.2831853f;
                float r_dist = std::sqrt(rand_01(rng)) * (grove.radius * 1.1f);
                float fx = grove.center_x + std::cos(angle) * r_dist;
                float fz = grove.center_z + std::sin(angle) * r_dist;

                if (!isValidSpawnLocation(island, fx, fz)) continue;
                float h = island.getIslandHeight(fx, fz);

                FloraInstance inst;
                inst.type = (grove.primary_tree == FloraType::COASTAL_PALM_TREE) ? FloraType::COASTAL_BOULDER : FloraType::MOSSY_ROCK_CLUMP;
                inst.pos = Spatial::Point3D(fx, h - 0.05f, fz);
                inst.scale = (0.90f + rand_01(rng) * 0.50f);
                inst.rotation_yaw = rand_01(rng) * 6.2831853f;
                inst.lean_angle = 0.0f;
                inst.lean_yaw = 0.0f;
                inst.seed = static_cast<unsigned>(rng());
                flora_instances.push_back(inst);
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // 3. Open Glades & Volcanic Scree (Occasional Solitary Boulders & Ferns)
        // ─────────────────────────────────────────────────────────────────────
        for (int i = 0; i < 25; ++i) {
            float angle = rand_01(rng) * 6.2831853f;
            float r_dist = (0.25f + rand_01(rng) * 0.55f) * island.island_radius;
            float fx = island.center_x + std::cos(angle) * r_dist;
            float fz = island.center_z + std::sin(angle) * r_dist;

            if (!isValidSpawnLocation(island, fx, fz)) continue;
            float h = island.getIslandHeight(fx, fz);

            FloraInstance inst;
            inst.type = (h > 18.0f) ? FloraType::VOLCANIC_CRAG : ((h < 11.0f) ? FloraType::COASTAL_BOULDER : FloraType::MOSSY_ROCK_CLUMP);
            inst.pos = Spatial::Point3D(fx, h - 0.05f, fz);
            inst.scale = (1.00f + rand_01(rng) * 0.60f);
            inst.rotation_yaw = rand_01(rng) * 6.2831853f;
            inst.lean_angle = 0.0f;
            inst.lean_yaw = 0.0f;
            inst.seed = static_cast<unsigned>(rng());
            flora_instances.push_back(inst);
        }

        // ─────────────────────────────────────────────────────────────────────
        // 4. Batch Mesh Generation for All Synthesized Flora & Props
        // ─────────────────────────────────────────────────────────────────────
        for (const auto& inst : flora_instances) {
            switch (inst.type) {
                case FloraType::BANYAN_OAK_TREE:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getBanyanOak(), base_vertices, mesh_indices);
                    break;
                case FloraType::HIGHLAND_CONIFER_TREE:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getHighlandConifer(), base_vertices, mesh_indices);
                    break;
                case FloraType::WEEPING_WILLOW_TREE:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getWeepingWillow(), base_vertices, mesh_indices);
                    break;
                case FloraType::PARASOL_ACACIA_TREE:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getParasolAcacia(), base_vertices, mesh_indices);
                    break;
                case FloraType::SLENDER_BIRCH_TREE:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getBirchAspen(), base_vertices, mesh_indices);
                    break;
                case FloraType::DRAGON_BLOOD_TREE:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getDragonBloodTree(), base_vertices, mesh_indices);
                    break;
                case FloraType::VOLCANIC_TREE_FERN:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getVolcanicTreeFern(), base_vertices, mesh_indices);
                    break;
                case FloraType::JOSHUA_TREE_YUCCA:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getJoshuaTree(), base_vertices, mesh_indices);
                    break;
                case FloraType::CLIFF_JUNIPER_BONSAI:
                    FloraMeshBuilder::buildEzTree(inst, TreePresets::getCliffJuniperBonsai(), base_vertices, mesh_indices);
                    break;
                case FloraType::COASTAL_PALM_TREE:
                    FloraMeshBuilder::buildPalmTree(inst, base_vertices, mesh_indices);
                    break;
                case FloraType::TROPICAL_BUSH:
                    FloraMeshBuilder::buildTropicalBush(inst, base_vertices, mesh_indices);
                    break;
                case FloraType::SLOPE_FERN:
                    FloraMeshBuilder::buildSlopeFern(inst, base_vertices, mesh_indices);
                    break;
                case FloraType::MOSSY_ROCK_CLUMP:
                    FloraMeshBuilder::buildRockClump(inst, base_vertices, mesh_indices, 0.90f);
                    break;
                case FloraType::COASTAL_BOULDER:
                    FloraMeshBuilder::buildRockClump(inst, base_vertices, mesh_indices, 0.35f);
                    break;
                case FloraType::VOLCANIC_CRAG:
                    FloraMeshBuilder::buildRockClump(inst, base_vertices, mesh_indices, 0.15f);
                    break;
            }
        }

        std::cout << "[Vegetation] Weber-Penn botanical groves generated — " << flora_instances.size()
                  << " instances in " << groves.size() << " distinct stands ("
                  << base_vertices.size() << " vertices, "
                  << mesh_indices.size() / 3 << " triangles)." << std::endl;
    }

    /**
     * Updates and commits the vegetation mesh with 3-tier dynamic real-time wind sway:
     *   Tier 1: Low-frequency trunk sway (0.8 Hz)
     *   Tier 2: Mid-frequency branch wave (2.4 Hz)
     *   Tier 3: High-frequency leaf flutter (6.8 Hz)
     */
    void updateVegetationMesh(Ogre::ManualObject* vegObj, float dt) {
        if (!vegObj || base_vertices.empty()) return;
        simulation_time += dt;

        vegObj->clear();
        vegObj->begin("SCR/VegetationMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        float wind_time = simulation_time * wind_speed;
        const size_t N = base_vertices.size();
        if (swayed_positions_.size() != N) {
            swayed_positions_.resize(N);
        }

        const float wt08 = wind_time * 0.8f;
        const float wt24 = wind_time * 2.4f;
        const float wt68 = wind_time * 6.8f;
        const float wx = wind_dir.x;
        const float wz = wind_dir.z;
        const float ws = wind_strength;

        #pragma GCC ivdep
        for (size_t i = 0; i < N; ++i) {
            const auto& v = base_vertices[i];
            if (v.wind_weight <= 0.01f) {
                swayed_positions_[i] = v.position;
            } else {
                // Tier 1: Trunk sway
                float trunk_sway = std::sin(v.position.x * 0.12f + v.position.z * 0.12f + wt08) * (v.wind_weight * v.wind_weight);
                // Tier 2: Branch wave
                float branch_wave = std::sin(v.position.x * 0.32f - v.position.z * 0.28f + wt24) * (v.wind_weight * 0.45f);
                // Tier 3: High-frequency leaf flutter
                float leaf_flutter = (v.wind_weight > 0.45f)
                    ? std::sin(v.position.x * 1.8f + v.position.y * 2.2f + v.position.z * 1.6f + wt68) * (0.18f * v.wind_weight)
                    : 0.0f;

                float total_sway = (trunk_sway * 0.65f + branch_wave + leaf_flutter) * ws;

                swayed_positions_[i] = Ogre::Vector3(
                    v.position.x + wx * total_sway,
                    v.position.y - std::abs(total_sway) * 0.15f,
                    v.position.z + wz * total_sway
                );
            }
        }

        for (size_t i = 0; i < N; ++i) {
            vegObj->position(swayed_positions_[i]);
            vegObj->normal(base_vertices[i].normal);
            vegObj->colour(base_vertices[i].color);
        }

        for (uint32_t idx : mesh_indices) {
            vegObj->index(idx);
        }

        vegObj->end();
    }

private:
    static bool isValidSpawnLocation(const Island::VoxelIsland& island, float x, float z) {
        if (x < 6.0f || x > island.dim_x - 6.0f || z < 6.0f || z > island.dim_z - 6.0f) return false;
        float h = island.getIslandHeight(x, z);
        if (h < island.sea_level + 0.25f || h > 26.5f) return false;

        // Avoid active lava river channel
        float river_end_z = island.center_z - island.island_radius * 0.72f;
        if (z < island.center_z + 2.0f && z > river_end_z - 4.0f) {
            float dist_to_centerline = std::abs(x - (island.center_x + std::sin((island.center_z - z) * 0.15f) * 2.5f));
            if (dist_to_centerline < 5.5f) return false;
        }

        float slope = estimateTerrainSlope(island, x, z);
        if (slope > 0.82f) return false;

        return true;
    }

    static float estimateTerrainSlope(const Island::VoxelIsland& island, float x, float z) {
        float h0 = island.getIslandHeight(x, z);
        float hx = island.getIslandHeight(x + 1.0f, z);
        float hz = island.getIslandHeight(x, z + 1.0f);
        float dx = hx - h0;
        float dz = hz - h0;
        return std::sqrt(dx * dx + dz * dz);
    }
};

} // namespace SCR::Vegetation

#endif // CAVE_PROCEDURAL_VEGETATION_HPP
