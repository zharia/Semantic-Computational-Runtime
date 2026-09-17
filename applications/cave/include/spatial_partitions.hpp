#ifndef CAVE_SPATIAL_PARTITIONS_HPP
#define CAVE_SPATIAL_PARTITIONS_HPP

#include <string>
#include <vector>
#include <cmath>
#include <algorithm>
#include <Ogre.h>

namespace SCR::Spatial {

enum class PartitionType {
    CALDERA_SUMMIT = 0,
    RAINFOREST_CANOPY,
    BASALT_CLIFFS,
    CORAL_LAGOON,
    SUBTERRANEAN_LAVA_TUBES,
    DEEP_OCEAN_ABYSS,
    COUNT
};

struct SpatialPartitionDescriptor {
    PartitionType type;
    std::string name;
    std::string code;
    std::string description;
    Ogre::ColourValue ambient_tint;
    Ogre::ColourValue fog_color;
    float fog_density;
    float vegetation_density;
    float boid_density;
    float wave_energy;
    float temperature_celsius;
    float humidity_percent;
};

class SpatialPartitionRegistry {
public:
    static const SpatialPartitionDescriptor& getDescriptor(PartitionType type) {
        static const SpatialPartitionDescriptor descriptors[] = {
            {
                PartitionType::CALDERA_SUMMIT,
                "Caldera Summit & Magma Vent",
                "CALDERA_SUMMIT",
                "High-altitude active volcanic caldera with boiling obsidian lava lake and sulfur vents.",
                Ogre::ColourValue(1.0f, 0.45f, 0.18f),
                Ogre::ColourValue(0.40f, 0.18f, 0.08f),
                0.0035f,
                0.0f,
                1.5f, // Magma ember boids
                0.0f,
                480.0f,
                12.0f
            },
            {
                PartitionType::RAINFOREST_CANOPY,
                "North-East Rainforest Canopy",
                "RAINFOREST_CANOPY",
                "Humid subtropical rainforest with dense Weber-Penn canopy, bamboo groves, and mossy basalt.",
                Ogre::ColourValue(0.20f, 0.85f, 0.40f),
                Ogre::ColourValue(0.12f, 0.35f, 0.22f),
                0.0018f,
                1.0f,
                1.2f, // Tropic terns & fireflies
                0.15f,
                29.0f,
                88.0f
            },
            {
                PartitionType::BASALT_CLIFFS,
                "South-West Basalt Cliffs & Tidal Surf",
                "BASALT_CLIFFS",
                "Vertical hexagonal columnar basalt cliffs pounded by heavy ocean surf and sea spray.",
                Ogre::ColourValue(0.35f, 0.50f, 0.65f),
                Ogre::ColourValue(0.20f, 0.30f, 0.45f),
                0.0022f,
                0.25f,
                0.8f,
                0.95f,
                24.0f,
                75.0f
            },
            {
                PartitionType::CORAL_LAGOON,
                "Coral Lagoon & Reef Shoals",
                "CORAL_LAGOON",
                "Shallow crystal turquoise atoll with live coral gardens, white sandbars, and reef schools.",
                Ogre::ColourValue(0.10f, 0.90f, 0.85f),
                Ogre::ColourValue(0.08f, 0.45f, 0.55f),
                0.0012f,
                0.40f,
                1.8f, // Reef tang fish schools
                0.35f,
                28.0f,
                82.0f
            },
            {
                PartitionType::SUBTERRANEAN_LAVA_TUBES,
                "Subterranean Lava Tubes & Caves",
                "SUBTERRANEAN_LAVA_TUBES",
                "Deep volcanic karst cavern network with bioluminescent crystals and thermal channels.",
                Ogre::ColourValue(0.75f, 0.25f, 0.95f),
                Ogre::ColourValue(0.15f, 0.05f, 0.25f),
                0.0065f,
                0.05f,
                0.4f,
                0.0f,
                65.0f,
                95.0f
            },
            {
                PartitionType::DEEP_OCEAN_ABYSS,
                "Deep Ocean & Pelagic Abyss",
                "DEEP_OCEAN_ABYSS",
                "Endless open deep ocean waters with long-period swell waves and atmospheric horizon mist.",
                Ogre::ColourValue(0.08f, 0.25f, 0.55f),
                Ogre::ColourValue(0.05f, 0.15f, 0.35f),
                0.0015f,
                0.0f,
                0.6f, // Pelagic 4D luminaries
                1.0f,
                22.0f,
                90.0f
            }
        };

        size_t idx = static_cast<size_t>(type);
        if (idx >= static_cast<size_t>(PartitionType::COUNT)) {
            idx = 0;
        }
        return descriptors[idx];
    }

    /**
     * Determines the spatial partition for any 3D coordinate in the world.
     */
    static PartitionType evaluatePartition(
        float x, float y, float z,
        float center_x = 160.0f, float center_z = 160.0f,
        float peak_height = 64.0f, float sea_level = 9.0f
    ) {
        float dx = x - center_x;
        float dz = z - center_z;
        float r = std::sqrt(dx * dx + dz * dz);
        float angle = std::atan2(dz, dx); // [-PI, PI]

        // 1. Subterranean check: inside island radius and beneath sea level / cavern depth
        if (r < 220.0f && y < sea_level - 1.5f) {
            return PartitionType::SUBTERRANEAN_LAVA_TUBES;
        }

        // 2. Caldera Summit: high altitude near center peak
        if (r < 36.0f && y >= peak_height - 18.0f) {
            return PartitionType::CALDERA_SUMMIT;
        }

        // 3. Deep Ocean: far out beyond outer partition perimeters
        if (r > 260.0f) {
            return PartitionType::DEEP_OCEAN_ABYSS;
        }

        // 4. Directional Biomes:
        // North-East Quad (angle in [-0.2, 2.2]): Rainforest
        // South-West Quad (angle in [2.2, PI] or [-PI, -1.8]): Basalt Sea Cliffs
        // South-East Quad (angle in [-1.8, -0.2]): Coral Lagoon & Atolls
        if (angle > -0.2f && angle < 2.2f) {
            if (y > sea_level + 0.8f) {
                return PartitionType::RAINFOREST_CANOPY;
            } else {
                return PartitionType::CORAL_LAGOON;
            }
        } else if (angle >= 2.2f || angle <= -1.8f) {
            if (y > sea_level + 1.2f) {
                return PartitionType::BASALT_CLIFFS;
            } else {
                return PartitionType::CORAL_LAGOON;
            }
        } else {
            return PartitionType::CORAL_LAGOON;
        }
    }
};

} // namespace SCR::Spatial

#endif // CAVE_SPATIAL_PARTITIONS_HPP
