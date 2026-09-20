#ifndef CAVE_SEMANTIC_MATERIALS_HPP
#define CAVE_SEMANTIC_MATERIALS_HPP

#include <string>
#include <vector>
#include <unordered_map>
#include <cstdint>
#include <fstream>
#include <iostream>

#if __has_include(<nlohmann/json.hpp>)
#include <nlohmann/json.hpp>
#define SCR_HAS_NLOHMANN_JSON 1
#else
#define SCR_HAS_NLOHMANN_JSON 0
#endif

/**
 * SCR Semantic Materials Registry (PI-CAVE-001 / Milestone 001).
 * Directly ingests normative contracts from lib/A01_Render/Material/materials_catalog.json
 * and lib/A01_Render/Material/material_reactions.json.
 */
namespace SCR::Material {

struct ColorRGB {
    float r, g, b, a;
    ColorRGB(float r = 1.0f, float g = 1.0f, float b = 1.0f, float a = 1.0f) : r(r), g(g), b(b), a(a) {}
};

struct MaterialContract {
    uint16_t code;
    std::string id;
    std::string name;
    std::string category;
    
    // Optical properties (BSDF Shading Closure)
    ColorRGB albedo;
    ColorRGB emission;
    float roughness;
    float metallic;
    float ior;
    float transmission;

    // Physical & Constitutive properties
    float density_kg_m3;
    float youngs_modulus_gpa;
    float mohs_hardness;
    float friction_coefficient;
    float restitution;
    float blast_resistance_j;
    float thermal_conductivity_w_mk;
    float specific_heat_j_kgk;

    bool is_solid;
    bool is_fluid;
    bool is_transparent;
    bool flammable;
};

// Canonical Voxel Type Codes for Fast In-Memory Dispatch
enum VoxelTypeCode : uint16_t {
    MAT_AIR = 0,
    MAT_BEDROCK = 1,
    MAT_GRANITE = 2,
    MAT_LIMESTONE = 3,
    MAT_BASALT = 4,
    MAT_OBSIDIAN = 5,
    MAT_GOLD_ORE = 6,
    MAT_IRON_ORE = 7,
    MAT_QUARTZ = 8,
    MAT_CALCITE = 9,
    MAT_WATER = 10,
    MAT_LAVA = 11,
    MAT_DIRT = 12,
    MAT_MOSS = 13,
    MAT_ICE = 14,
    MAT_SAND = 15,
    MAT_COPPER_ORE = 16,
    MAT_DIORITE = 17,
    MAT_SANDSTONE = 18,
    MAT_COBBLESTONE = 19,
    MAT_FOLIAGE = 20,
    MAT_BAMBOO = 21,
    MAT_SULFUR = 22,
    MAT_ASH = 23,
    MAT_PUMICE = 24,
    MAT_TUFF = 25,
    MAT_WOOD = 26,    // Tropical hardwood trunk
    MAT_SHRUB = 27,   // Dense undergrowth shrub
    MAT_FERN = 28,    // Jungle floor fern
    MAT_PALM = 29     // Palm tree trunk
};

struct STCReactionRule {
    std::string reaction_id;
    std::string primary_mat;
    std::string adjacent_mat;
    std::string outcome_mat;
    float energy_released_j;
};

class MaterialRegistry {
public:
    static MaterialRegistry& instance() {
        static MaterialRegistry reg;
        return reg;
    }

    const MaterialContract& get(uint16_t code) const {
        auto it = by_code.find(code);
        if (it != by_code.end()) return it->second;
        return air_contract;
    }

    const MaterialContract& get(const std::string& id) const {
        auto it = by_id.find(id);
        if (it != by_id.end()) return it->second;
        return air_contract;
    }

    bool has(const std::string& id) const {
        return by_id.find(id) != by_id.end();
    }

    size_t totalRegistered() const {
        return by_id.size();
    }

    // Evaluate STC transition when two voxels share a topological face
    uint16_t evaluateFaceAdjacencySTC(uint16_t primary_code, uint16_t adjacent_code) const {
        const auto& p = get(primary_code);
        const auto& a = get(adjacent_code);

        for (const auto& r : stc_reactions) {
            if (r.primary_mat == p.id && r.adjacent_mat == a.id) {
                return get(r.outcome_mat).code;
            }
        }
        return primary_code; // No phase change
    }

    const std::vector<STCReactionRule>& getReactions() const {
        return stc_reactions;
    }

private:
    MaterialContract air_contract;
    std::unordered_map<uint16_t, MaterialContract> by_code;
    std::unordered_map<std::string, MaterialContract> by_id;
    std::vector<STCReactionRule> stc_reactions;
    uint16_t next_dynamic_code = 100;

    MaterialRegistry() {
        // 1. Initialize Baseline Canonical Materials
        initBaseline();

        // 2. Ingest Full Semantic Catalog from JSON if available
        loadCatalogFromJSON();

        // 3. Ingest STC Material Reactions
        loadReactionsFromJSON();
    }

    void registerMat(const MaterialContract& mat) {
        by_code[mat.code] = mat;
        by_id[mat.id] = mat;
    }

    void initBaseline() {
        air_contract = {MAT_AIR, "air", "Void Atmosphere", "gas", 
                        ColorRGB(0,0,0,0), ColorRGB(0,0,0,0), 0.0f, 0.0f, 1.0f, 1.0f, 
                        1.225f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.026f, 1005.0f,
                        false, false, true, false};
        registerMat(air_contract);

        registerMat({MAT_BEDROCK, "rock.bedrock", "Deep Geological Bedrock", "rock",
                     ColorRGB(0.12f, 0.12f, 0.14f), ColorRGB(0,0,0), 0.95f, 0.05f, 1.60f, 0.0f,
                     3100.0f, 120.0f, 9.0f, 0.8f, 0.02f, 100000.0f, 3.2f, 790.0f,
                     true, false, false, false});

        registerMat({MAT_GRANITE, "rock.granite", "Granitic Plutonic Silicate", "rock",
                     ColorRGB(0.60f, 0.52f, 0.47f), ColorRGB(0,0,0), 0.88f, 0.0f, 1.54f, 0.0f,
                     2650.0f, 50.0f, 6.5f, 0.7f, 0.1f, 8000.0f, 2.8f, 820.0f,
                     true, false, false, false});

        registerMat({MAT_LIMESTONE, "rock.limestone", "Karst Calcite Limestone", "rock",
                     ColorRGB(0.82f, 0.78f, 0.72f), ColorRGB(0,0,0), 0.85f, 0.0f, 1.52f, 0.0f,
                     2500.0f, 35.0f, 3.5f, 0.65f, 0.15f, 4000.0f, 2.1f, 880.0f,
                     true, false, false, false});

        registerMat({MAT_BASALT, "rock.basalt", "Extrusive Basaltic Column", "rock",
                     ColorRGB(0.22f, 0.22f, 0.25f), ColorRGB(0,0,0), 0.90f, 0.02f, 1.58f, 0.0f,
                     2900.0f, 65.0f, 6.0f, 0.75f, 0.08f, 9500.0f, 2.2f, 840.0f,
                     true, false, false, false});

        registerMat({MAT_OBSIDIAN, "rock.obsidian", "Volcanic Vitreous Obsidian", "rock",
                     ColorRGB(0.11f, 0.08f, 0.16f), ColorRGB(0,0,0), 0.15f, 0.10f, 1.50f, 0.0f,
                     2400.0f, 70.0f, 5.5f, 0.5f, 0.4f, 6000.0f, 1.3f, 830.0f,
                     true, false, false, false});

        registerMat({MAT_GOLD_ORE, "ore.gold_ore", "Native Gold Quartz Matrix", "ore",
                     ColorRGB(0.95f, 0.78f, 0.15f), ColorRGB(0,0,0), 0.25f, 0.95f, 0.18f, 0.0f,
                     5200.0f, 78.0f, 3.0f, 0.4f, 0.2f, 5000.0f, 310.0f, 130.0f,
                     true, false, false, false});

        registerMat({MAT_IRON_ORE, "ore.iron_ore", "Banded Hematite Iron Ore", "ore",
                     ColorRGB(0.55f, 0.35f, 0.28f), ColorRGB(0,0,0), 0.65f, 0.80f, 2.80f, 0.0f,
                     4800.0f, 160.0f, 5.5f, 0.6f, 0.15f, 7000.0f, 75.0f, 450.0f,
                     true, false, false, false});

        registerMat({MAT_QUARTZ, "mineral.quartz", "Prismatic Crystalline Quartz", "mineral",
                     ColorRGB(0.88f, 0.96f, 0.98f, 0.85f), ColorRGB(0,0,0), 0.10f, 0.0f, 1.54f, 0.85f,
                     2650.0f, 75.0f, 7.0f, 0.4f, 0.3f, 3500.0f, 7.5f, 740.0f,
                     true, false, true, false});

        registerMat({MAT_CALCITE, "mineral.calcite", "Iceland Spar Calcite Crystal", "mineral",
                     ColorRGB(0.92f, 0.92f, 0.88f), ColorRGB(0,0,0), 0.20f, 0.0f, 1.49f, 0.40f,
                     2710.0f, 35.0f, 3.0f, 0.5f, 0.2f, 2500.0f, 4.2f, 850.0f,
                     true, false, false, false});

        registerMat({MAT_WATER, "fluid.water", "Subterranean Aquifer Water", "fluid",
                     ColorRGB(0.12f, 0.52f, 0.88f, 0.65f), ColorRGB(0,0,0), 0.05f, 0.0f, 1.333f, 0.95f,
                     1000.0f, 2.2f, 0.0f, 0.05f, 0.0f, 1000.0f, 0.6f, 4184.0f,
                     false, true, true, false});

        registerMat({MAT_LAVA, "fluid.lava", "Molten Basalt Magma", "fluid",
                     ColorRGB(1.0f, 0.28f, 0.02f), ColorRGB(1.0f, 0.45f, 0.05f), 0.40f, 0.0f, 1.55f, 0.0f,
                     2800.0f, 5.0f, 0.0f, 0.3f, 0.0f, 2000.0f, 1.5f, 1200.0f,
                     false, true, false, false});

        registerMat({MAT_DIRT, "soil.dirt", "Organic Cavern Loam", "soil",
                     ColorRGB(0.38f, 0.26f, 0.16f), ColorRGB(0,0,0), 0.92f, 0.0f, 1.45f, 0.0f,
                     1450.0f, 0.05f, 1.5f, 0.65f, 0.05f, 500.0f, 0.25f, 800.0f,
                     true, false, false, false});

        registerMat({MAT_MOSS, "organic.bioluminescent_moss", "Bioluminescent Cavern Moss", "organic",
                     ColorRGB(0.25f, 0.88f, 0.35f), ColorRGB(0.1f, 0.45f, 0.15f), 0.70f, 0.0f, 1.40f, 0.0f,
                     400.0f, 0.01f, 0.5f, 0.9f, 0.0f, 150.0f, 0.15f, 1500.0f,
                     true, false, false, true});

        registerMat({MAT_ICE, "cryo.ice", "Compact Glacial Ice", "cryo",
                     ColorRGB(0.75f, 0.88f, 0.98f, 0.90f), ColorRGB(0,0,0), 0.10f, 0.0f, 1.31f, 0.80f,
                     917.0f, 9.1f, 1.5f, 0.05f, 0.1f, 800.0f, 2.2f, 2090.0f,
                     true, false, true, false});

        registerMat({MAT_COBBLESTONE, "rock.cobblestone", "Fractured Cobblestone", "rock",
                     ColorRGB(0.48f, 0.48f, 0.48f), ColorRGB(0,0,0), 0.90f, 0.0f, 1.54f, 0.0f,
                     2500.0f, 40.0f, 5.0f, 0.8f, 0.1f, 6000.0f, 2.0f, 800.0f,
                     true, false, false, false});

        registerMat({MAT_SAND, "soil.sand", "Silica Sand Beach", "soil",
                     ColorRGB(0.85f, 0.78f, 0.58f), ColorRGB(0,0,0), 0.95f, 0.0f, 1.54f, 0.0f,
                     1600.0f, 0.1f, 2.0f, 0.6f, 0.05f, 400.0f, 0.3f, 830.0f,
                     true, false, false, false});

        registerMat({MAT_FOLIAGE, "botanical.foliage", "Tropical Jungle Canopy", "botanical",
                     ColorRGB(0.18f, 0.65f, 0.22f), ColorRGB(0,0,0), 0.85f, 0.0f, 1.42f, 0.0f,
                     250.0f, 0.05f, 0.5f, 0.7f, 0.02f, 100.0f, 0.15f, 1600.0f,
                     true, false, false, true});

        registerMat({MAT_BAMBOO, "botanical.bamboo", "Exotic Tropical Bamboo", "botanical",
                     ColorRGB(0.45f, 0.75f, 0.25f), ColorRGB(0,0,0), 0.70f, 0.0f, 1.45f, 0.0f,
                     600.0f, 15.0f, 3.0f, 0.5f, 0.1f, 800.0f, 0.20f, 1400.0f,
                     true, false, false, true});

        registerMat({MAT_SULFUR, "mineral.sulfur", "Geothermal Native Sulfur", "mineral",
                     ColorRGB(0.92f, 0.82f, 0.15f), ColorRGB(0,0,0), 0.60f, 0.0f, 1.95f, 0.05f,
                     2070.0f, 15.0f, 2.0f, 0.4f, 0.2f, 2000.0f, 0.205f, 710.0f,
                     true, false, false, true});

        registerMat({MAT_ASH, "mineral.ash", "Volcanic Tephra Ash", "mineral",
                     ColorRGB(0.32f, 0.32f, 0.34f), ColorRGB(0,0,0), 0.98f, 0.0f, 1.50f, 0.0f,
                     750.0f, 0.01f, 1.0f, 0.5f, 0.05f, 150.0f, 0.12f, 800.0f,
                     true, false, false, false});

        registerMat({MAT_PUMICE, "rock.pumice", "Vesicular Pumice", "rock",
                     ColorRGB(0.70f, 0.68f, 0.64f), ColorRGB(0,0,0), 0.92f, 0.0f, 1.50f, 0.0f,
                     650.0f, 15.0f, 5.5f, 0.85f, 0.1f, 2500.0f, 0.35f, 800.0f,
                     true, false, false, false});

        registerMat({MAT_TUFF, "rock.tuff", "Volcanic Lithic Tuff", "rock",
                     ColorRGB(0.42f, 0.40f, 0.38f), ColorRGB(0,0,0), 0.90f, 0.0f, 1.52f, 0.0f,
                     2100.0f, 30.0f, 4.5f, 0.7f, 0.15f, 5000.0f, 1.5f, 840.0f,
                     true, false, false, false});

        registerMat({MAT_WOOD, "wood.hardwood", "Tropical Hardwood Trunk", "wood",
                     ColorRGB(0.38f, 0.25f, 0.14f), ColorRGB(0,0,0), 0.88f, 0.0f, 1.45f, 0.0f,
                     800.0f, 12.0f, 3.5f, 0.6f, 0.05f, 1200.0f, 0.18f, 1700.0f,
                     true, false, false, true});

        registerMat({MAT_SHRUB, "botanical.foliage", "Tropical Shrub / Bush", "botanical",
                     ColorRGB(0.22f, 0.55f, 0.18f), ColorRGB(0,0,0), 0.88f, 0.0f, 1.42f, 0.0f,
                     180.0f, 0.03f, 0.5f, 0.7f, 0.02f, 80.0f, 0.13f, 1600.0f,
                     true, false, false, true});

        registerMat({MAT_FERN, "botanical.foliage", "Jungle Floor Fern", "botanical",
                     ColorRGB(0.32f, 0.72f, 0.28f), ColorRGB(0,0,0), 0.82f, 0.0f, 1.42f, 0.0f,
                     120.0f, 0.02f, 0.5f, 0.75f, 0.01f, 60.0f, 0.12f, 1600.0f,
                     true, false, false, true});

        registerMat({MAT_PALM, "botanical.bamboo", "Tropical Palm Trunk", "botanical",
                     ColorRGB(0.62f, 0.52f, 0.32f), ColorRGB(0,0,0), 0.78f, 0.0f, 1.44f, 0.0f,
                     550.0f, 10.0f, 2.5f, 0.55f, 0.08f, 700.0f, 0.19f, 1450.0f,
                     true, false, false, true});
    }

    void loadCatalogFromJSON() {
#if SCR_HAS_NLOHMANN_JSON
        std::vector<std::string> search_paths = {
            "lib/A01_Render/Material/materials_catalog.json",
            "../../lib/A01_Render/Material/materials_catalog.json",
            "/home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/materials_catalog.json"
        };

        std::string valid_path = "";
        for (const auto& path : search_paths) {
            std::ifstream file(path);
            if (file.good()) {
                valid_path = path;
                break;
            }
        }

        if (valid_path.empty()) {
            std::cout << "[MaterialRegistry] Catalog JSON not found in search paths, using baseline.\n";
            return;
        }

        try {
            std::ifstream file(valid_path);
            nlohmann::json j;
            file >> j;

            if (j.contains("materials") && j["materials"].is_array()) {
                for (const auto& mat_j : j["materials"]) {
                    std::string id = mat_j.value("id", "");
                    if (id.empty()) continue;

                    std::string name = mat_j.value("name", id);
                    std::string category = mat_j.value("category", "unspecified");

                    // Physical
                    float density = 2500.0f;
                    float ym = 10.0f;
                    float hardness = 3.0f;
                    float friction = 0.6f;
                    float restitution = 0.1f;
                    float blast = 1000.0f;
                    float therm_cond = 1.0f;
                    float spec_heat = 800.0f;
                    bool flammable = false;

                    if (mat_j.contains("physical") && mat_j["physical"].is_object()) {
                        const auto& p = mat_j["physical"];
                        density = p.value("density_kg_m3", density);
                        ym = p.value("youngs_modulus_gpa", ym);
                        hardness = p.value("mohs_hardness", hardness);
                        friction = p.value("friction_coefficient", friction);
                        restitution = p.value("restitution", restitution);
                        blast = p.value("blast_resistance_j", blast);
                        therm_cond = p.value("thermal_conductivity_w_mk", therm_cond);
                        spec_heat = p.value("specific_heat_j_kgk", spec_heat);
                        flammable = p.value("flammable", flammable);
                    }

                    // Optical
                    ColorRGB alb(0.7f, 0.7f, 0.7f);
                    ColorRGB em(0.0f, 0.0f, 0.0f);
                    float rough = 0.8f;
                    float metal = 0.0f;
                    float ior = 1.5f;
                    float trans = 0.0f;

                    if (mat_j.contains("optical") && mat_j["optical"].is_object()) {
                        const auto& o = mat_j["optical"];
                        if (o.contains("base_color_srgb") && o["base_color_srgb"].is_array() && o["base_color_srgb"].size() >= 3) {
                            alb.r = o["base_color_srgb"][0].get<float>();
                            alb.g = o["base_color_srgb"][1].get<float>();
                            alb.b = o["base_color_srgb"][2].get<float>();
                        }
                        rough = o.value("roughness", rough);
                        metal = o.value("metallic", metal);
                        ior = o.value("ior", ior);
                        trans = o.value("transmission", trans);
                        float em_cd = o.value("emission_cd_m2", 0.0f);
                        if (em_cd > 0.0f) {
                            float factor = std::min(1.0f, em_cd / 1000.0f);
                            em = ColorRGB(alb.r * factor, alb.g * factor, alb.b * factor);
                        }
                    }

                    bool is_fluid = (category == "fluid" || category.find("fluid") != std::string::npos || id.find("fluid.") == 0);
                    bool is_solid = (!is_fluid && category != "gas" && id.find("gas.") != 0 && id != "air");
                    bool is_trans = (trans > 0.1f || id.find("glass") != std::string::npos);

                    // If existing code exists in registry, update properties; else assign new dynamic code
                    uint16_t code = next_dynamic_code++;
                    if (by_id.find(id) != by_id.end()) {
                        code = by_id[id].code;
                    }

                    MaterialContract contract{
                        code, id, name, category,
                        alb, em, rough, metal, ior, trans,
                        density, ym, hardness, friction, restitution, blast, therm_cond, spec_heat,
                        is_solid, is_fluid, is_trans, flammable
                    };
                    registerMat(contract);
                }
                std::cout << "[MaterialRegistry] Ingested " << by_id.size() << " materials from SCR semantic catalog: " << valid_path << "\n";
            }
        } catch (const std::exception& e) {
            std::cerr << "[MaterialRegistry] Warning loading catalog: " << e.what() << "\n";
        }
#endif
    }

    void loadReactionsFromJSON() {
        // Built-in STC reaction defaults
        stc_reactions.push_back({"reaction.lava_water_quench", "fluid.lava", "fluid.water", "rock.obsidian", 15000.0f});
        stc_reactions.push_back({"reaction.water_lava_quench", "fluid.water", "fluid.lava", "rock.cobblestone", 8000.0f});

#if SCR_HAS_NLOHMANN_JSON
        std::vector<std::string> search_paths = {
            "lib/A01_Render/Material/material_reactions.json",
            "../../lib/A01_Render/Material/material_reactions.json",
            "/home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/material_reactions.json"
        };

        for (const auto& path : search_paths) {
            std::ifstream file(path);
            if (!file.good()) continue;

            try {
                nlohmann::json j;
                file >> j;
                if (j.contains("reactions") && j["reactions"].is_array()) {
                    for (const auto& r_j : j["reactions"]) {
                        std::string rid = r_j.value("id", "");
                        if (!r_j.contains("preconditions") || !r_j.contains("transformations")) continue;
                        
                        std::string prim = r_j["preconditions"].value("primary", "");
                        std::string adj = r_j["preconditions"].value("adjacent", "");
                        
                        if (r_j["transformations"].is_array() && !r_j["transformations"].empty()) {
                            std::string out = r_j["transformations"][0].value("outcome", "");
                            float energy = r_j["transformations"][0].value("energy_released_j", 0.0f);
                            if (!prim.empty() && !adj.empty() && !out.empty()) {
                                stc_reactions.push_back({rid, prim, adj, out, energy});
                            }
                        }
                    }
                    std::cout << "[MaterialRegistry] Loaded " << stc_reactions.size() << " STC reaction rules from: " << path << "\n";
                    break;
                }
            } catch (...) {}
        }
#endif
    }
};

} // namespace SCR::Material

#endif // CAVE_SEMANTIC_MATERIALS_HPP
