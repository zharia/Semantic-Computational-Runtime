#ifndef CAVE_ISLAND_BIOME_TYPES_HPP
#define CAVE_ISLAND_BIOME_TYPES_HPP

#include <string>
#include <vector>
#include <cmath>

#include "simulation/spatial_semantics.hpp"
#include "simulation/semantic_materials.hpp"

namespace SCR::Island {

enum class IslandBiomeType {
    VOLCANO = 0,
    JUNGLE,
    DESERT,
    GLACIAL_ICE,
    CORAL_ARCHIPELAGO,
    COUNT
};

struct IslandDescriptor {
    IslandBiomeType biome;
    std::string name;
    std::string title_tag;
    std::string lore_description;
    Spatial::Point3D world_center; // Nautical world coordinates
    float island_radius;
    float peak_height;
    float sea_level;
    float vegetation_density;
    float boid_density;
    Material::ColorRGB water_shallow_color;
    Material::ColorRGB water_deep_color;
    Material::ColorRGB ambient_tint;
    Material::ColorRGB fog_color;
    float fog_density;
    float wave_amplitude;
    float temperature_celsius;
};

class ArchipelagoRegistry {
public:
    static const std::vector<IslandDescriptor>& getAllIslands() {
        static const std::vector<IslandDescriptor> islands = {
            {
                IslandBiomeType::VOLCANO,
                "The Ashen Reaches",
                "VOLCANIC CALDERA",
                "Active stratovolcano with boiling obsidian lava channels, sulfur fumaroles, and basalt sea cliffs.",
                Spatial::Point3D(0.0f, 0.0f, 0.0f),
                128.0f,
                64.0f,
                9.0f,
                0.65f,
                1.2f,
                Material::ColorRGB(0.04f, 0.28f, 0.36f, 0.72f), // Tropical reef teal
                Material::ColorRGB(0.01f, 0.08f, 0.20f, 0.95f), // Deep indigo
                Material::ColorRGB(1.0f, 0.88f, 0.76f),
                Material::ColorRGB(0.40f, 0.48f, 0.60f),
                0.0018f,
                0.85f,
                42.0f
            },
            {
                IslandBiomeType::JUNGLE,
                "The Ancient Rainforest",
                "DENSE TROPICAL CANOPY",
                "High-altitude mountainous rainforest with giant hardwood canopies, cascading mountain springs, and bamboo groves.",
                Spatial::Point3D(480.0f, 0.0f, 480.0f),
                136.0f,
                78.0f,
                9.0f,
                1.40f,
                1.5f,
                Material::ColorRGB(0.02f, 0.40f, 0.30f, 0.68f), // Emerald jade shallows
                Material::ColorRGB(0.01f, 0.12f, 0.18f, 0.95f),
                Material::ColorRGB(0.92f, 1.0f, 0.90f),
                Material::ColorRGB(0.28f, 0.52f, 0.42f),
                0.0028f,
                0.65f,
                29.0f
            },
            {
                IslandBiomeType::DESERT,
                "The Shores of Gold",
                "ARID SAND DUNES & OASIS",
                "Sweeping wind-carved golden dunes, monumental sandstone sea arches, and turquoise oasis lagoons.",
                Spatial::Point3D(520.0f, 0.0f, -420.0f),
                120.0f,
                48.0f,
                9.0f,
                0.35f,
                0.8f,
                Material::ColorRGB(0.08f, 0.45f, 0.52f, 0.60f), // Aquamarine
                Material::ColorRGB(0.02f, 0.10f, 0.25f, 0.95f),
                Material::ColorRGB(1.0f, 0.95f, 0.80f),
                Material::ColorRGB(0.70f, 0.58f, 0.42f),
                0.0015f,
                0.55f,
                38.0f
            },
            {
                IslandBiomeType::GLACIAL_ICE,
                "The Frozen Wilds",
                "ARCTIC GLACIERS & PACK ICE",
                "Towering translucent glacial blue ice shelves, snow-capped rock needles, and frozen coastal crevasses.",
                Spatial::Point3D(-480.0f, 0.0f, 480.0f),
                140.0f,
                82.0f,
                9.0f,
                0.20f,
                0.7f,
                Material::ColorRGB(0.18f, 0.48f, 0.62f, 0.75f), // Glacial cyan
                Material::ColorRGB(0.03f, 0.09f, 0.22f, 0.96f),
                Material::ColorRGB(0.85f, 0.92f, 1.0f),
                Material::ColorRGB(0.65f, 0.75f, 0.88f),
                0.0032f,
                0.95f,
                -12.0f
            },
            {
                IslandBiomeType::CORAL_ARCHIPELAGO,
                "Sunken Coral Atolls",
                "INTERCONNECTED REEF ISLETS",
                "A circular chain of five white-sand islets surrounding an expansive crystal turquoise lagoon and living coral reefs.",
                Spatial::Point3D(-460.0f, 0.0f, -460.0f),
                150.0f,
                36.0f,
                9.0f,
                0.90f,
                1.8f,
                Material::ColorRGB(0.10f, 0.55f, 0.60f, 0.55f), // Ultra crystal turquoise
                Material::ColorRGB(0.01f, 0.12f, 0.28f, 0.95f),
                Material::ColorRGB(1.0f, 1.0f, 0.92f),
                Material::ColorRGB(0.40f, 0.62f, 0.72f),
                0.0012f,
                0.70f,
                27.0f
            }
        };
        return islands;
    }

    static const IslandDescriptor& getDescriptor(IslandBiomeType biome) {
        const auto& all = getAllIslands();
        for (const auto& isl : all) {
            if (isl.biome == biome) return isl;
        }
        return all[0];
    }

    static const IslandDescriptor& findNearestIsland(float world_x, float world_z, float& out_distance) {
        const auto& all = getAllIslands();
        float min_dist_sq = 1e12f;
        size_t best_idx = 0;
        for (size_t i = 0; i < all.size(); ++i) {
            float dx = world_x - all[i].world_center.x;
            float dz = world_z - all[i].world_center.z;
            float d2 = dx * dx + dz * dz;
            if (d2 < min_dist_sq) {
                min_dist_sq = d2;
                best_idx = i;
            }
        }
        out_distance = std::sqrt(min_dist_sq);
        return all[best_idx];
    }
};

} // namespace SCR::Island

#endif // CAVE_ISLAND_BIOME_TYPES_HPP
