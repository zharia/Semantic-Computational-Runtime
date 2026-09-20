#ifndef CAVE_NAUTICAL_NAVIGATION_HPP
#define CAVE_NAUTICAL_NAVIGATION_HPP

#include <string>
#include <vector>
#include <cmath>
#include <iomanip>
#include <sstream>
#include "simulation/island_biome_types.hpp"

namespace SCR::Navigation {

struct NauticalState {
    float heading_degrees = 0.0f; // 0=North, 90=East, 180=South, 270=West
    std::string cardinal_direction = "N";
    float speed_knots = 0.0f;
    float world_x = 0.0f;
    float world_z = 0.0f;

    // Sighted / active island
    std::string nearest_island_name;
    std::string nearest_island_tag;
    Island::IslandBiomeType nearest_biome = Island::IslandBiomeType::VOLCANO;
    float nearest_island_dist = 0.0f;
    float nearest_island_bearing = 0.0f;
    std::string nearest_island_cardinal = "N";
    bool in_territorial_waters = false;

    // Territory change detection
    bool entered_new_territory = false;
    std::string announcement_title;
    std::string announcement_tag;
    float announcement_timer = 0.0f;
};

class NauticalNavigator {
private:
    float prev_x_ = 0.0f;
    float prev_z_ = 0.0f;
    Island::IslandBiomeType last_territory_biome_ = Island::IslandBiomeType::COUNT;

public:
    static std::string degreesToCardinal(float deg) {
        // Normalize 0..360
        while (deg < 0.0f) deg += 360.0f;
        while (deg >= 360.0f) deg -= 360.0f;

        static const char* cardinals[] = {
            "N", "NNE", "NE", "ENE",
            "E", "ESE", "SE", "SSE",
            "S", "SSW", "SW", "WSW",
            "W", "WNW", "NW", "NNW"
        };
        int idx = (int)std::floor((deg + 11.25f) / 22.5f) % 16;
        return cardinals[idx];
    }

    NauticalState update(float cur_x, float cur_z, float yaw_rad, float dt) {
        NauticalState state;
        state.world_x = cur_x;
        state.world_z = cur_z;

        // Heading: in our coordinate system, yaw=0 looks in -Z (North), yaw=pi/2 looks in -X (West)
        // Convert to compass degrees (0=North, 90=East, 180=South, 270=West)
        float heading_deg = -yaw_rad * (180.0f / 3.14159265f);
        while (heading_deg < 0.0f) heading_deg += 360.0f;
        while (heading_deg >= 360.0f) heading_deg -= 360.0f;
        state.heading_degrees = heading_deg;
        state.cardinal_direction = degreesToCardinal(heading_deg);

        // Speed in nautical knots (1 m/s ~= 1.94384 knots)
        if (dt > 0.0001f) {
            float dist_moved = std::sqrt((cur_x - prev_x_) * (cur_x - prev_x_) + (cur_z - prev_z_) * (cur_z - prev_z_));
            float speed_mps = dist_moved / dt;
            state.speed_knots = speed_mps * 1.94384f;
        }
        prev_x_ = cur_x;
        prev_z_ = cur_z;

        // Find nearest island
        float nearest_dist = 0.0f;
        const auto& nearest = Island::ArchipelagoRegistry::findNearestIsland(cur_x, cur_z, nearest_dist);
        state.nearest_island_name = nearest.name;
        state.nearest_island_tag = nearest.title_tag;
        state.nearest_biome = nearest.biome;
        state.nearest_island_dist = nearest_dist;

        // Island bearing calculation
        float dx = nearest.world_center.x - cur_x;
        float dz = nearest.world_center.z - cur_z;
        float bearing_rad = std::atan2(dx, -dz); // 0 = North, pi/2 = East
        float bearing_deg = bearing_rad * (180.0f / 3.14159265f);
        while (bearing_deg < 0.0f) bearing_deg += 360.0f;
        state.nearest_island_bearing = bearing_deg;
        state.nearest_island_cardinal = degreesToCardinal(bearing_deg);

        // Check if player entered territorial waters (within 1.5x island radius)
        state.in_territorial_waters = (nearest_dist <= nearest.island_radius * 1.45f);

        if (state.in_territorial_waters) {
            if (last_territory_biome_ != nearest.biome) {
                last_territory_biome_ = nearest.biome;
                state.entered_new_territory = true;
                state.announcement_title = nearest.name;
                state.announcement_tag = nearest.title_tag;
                state.announcement_timer = 5.0f; // 5 second banner
            }
        } else {
            if (nearest_dist > nearest.island_radius * 1.6f) {
                last_territory_biome_ = Island::IslandBiomeType::COUNT;
            }
        }

        return state;
    }
};

} // namespace SCR::Navigation

#endif // CAVE_NAUTICAL_NAVIGATION_HPP
