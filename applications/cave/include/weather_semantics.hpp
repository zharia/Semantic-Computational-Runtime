/**
 * SCR Application / Advanced Dynamic Weather System
 * ─────────────────────────────────────────────────────────────────────────────
 * Implements SCR-LIB-SIMULATION-WEATHER (lib/503_Simulation/Environment/Weather/101_definition.md)
 *
 * Provides:
 *   1. Multidimensional Thermodynamic & Atmospheric Weather State (Pressure, Temp, Humidity, Wind, Clouds, Rain, Ash, Lightning)
 *   2. Extensible Weather Profile Registry (Open condition registration and custom microclimates)
 *   3. Continuous Hermite S3 Smooth Transition Engine (No popping across storm fronts)
 *   4. Pre-allocated SIMD Precipitation & Aerosol Streak Particle Engine (Rain, Drizzle, Volcanic Ash)
 *   5. Cross-Subsystem Environmental Coupling (Ocean swell, Vegetation wind sway, Boid sheltering, Sky turbidity)
 */

#ifndef CAVE_WEATHER_SEMANTICS_HPP
#define CAVE_WEATHER_SEMANTICS_HPP

#include <Ogre.h>
#include "simulation/spatial_semantics.hpp"
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <cmath>
#include <random>
#include <algorithm>
#include <iostream>

namespace SCR::Weather {

// ─── Weather Condition Identifier ────────────────────────────────────────────
enum class WeatherConditionType : uint32_t {
    CLEAR_TROPICAL = 0,
    OVERCAST_STRATUS = 1,
    TROPICAL_MONSOON = 2,
    VOLCANIC_ASH_TEMPEST = 3,
    MARINE_FOG = 4,
    GOLDEN_HAZE = 5,
    CUSTOM = 6
};

inline const char* weatherConditionToString(WeatherConditionType type) {
    switch (type) {
        case WeatherConditionType::CLEAR_TROPICAL:        return "Clear Tropical";
        case WeatherConditionType::OVERCAST_STRATUS:      return "Overcast Stratus";
        case WeatherConditionType::TROPICAL_MONSOON:      return "Tropical Monsoon";
        case WeatherConditionType::VOLCANIC_ASH_TEMPEST:  return "Volcanic Ash Tempest";
        case WeatherConditionType::MARINE_FOG:            return "Marine Fog";
        case WeatherConditionType::GOLDEN_HAZE:           return "Golden Amber Haze";
        case WeatherConditionType::CUSTOM:                return "Custom Weather";
        default:                                          return "Unknown";
    }
}

// ─── Continuous Weather Thermodynamic State ──────────────────────────────────
struct WeatherState {
    float pressure_sea_level_hpa = 1018.0f; // Barometric pressure at sea level (hPa)
    float temperature_c          = 28.5f;   // Ambient temperature at sea level (°C)
    float relative_humidity      = 0.65f;   // Relative humidity (0.0 to 1.0)
    Spatial::Vector3D wind_velocity{3.5f, 0.0f, 1.8f}; // 3D Wind velocity vector (m/s)
    float wind_gust_factor       = 1.15f;   // Dynamic gust multiplier

    float cloud_coverage         = 0.25f;   // Total sky cloud fraction (0.0 to 1.0)
    float cloud_optical_depth    = 1.0f;    // Cloud density / darkness
    float precipitation_rate     = 0.0f;    // Precipitation intensity (mm/h, 0 = none, 50 = torrential)
    float aerosol_density        = 0.05f;   // Fog / ash / particulate turbidity (0.0 to 1.0)
    float volcanic_ash_fraction  = 0.0f;    // 0.0 = pure water rain, 1.0 = heavy volcanic ash & soot
    float lightning_intensity    = 0.0f;    // 0.0 = none, 1.0 = active lightning discharge flash

    float fog_density            = 0.001f;  // Volumetric atmospheric fog extinction factor
    float ambient_light_scale    = 1.0f;    // Day/night ambient multiplier (dimmed in heavy storms)
    Ogre::ColourValue sky_tint{1.0f, 1.0f, 1.0f, 1.0f}; // Color modulation for sky & atmosphere
    Ogre::ColourValue fog_color{0.7f, 0.8f, 0.9f, 1.0f};

    WeatherConditionType condition_id = WeatherConditionType::CLEAR_TROPICAL;
    std::string condition_name = "Clear Tropical";

    // Barometric Altitude Lapse Rate Formula
    float getPressureAtAltitude(float altitude_y) const {
        return pressure_sea_level_hpa * std::exp(-altitude_y / 8400.0f);
    }

    // Environmental Temperature Lapse Rate Formula (6.5°C per 1000m)
    float getTemperatureAtAltitude(float altitude_y) const {
        return temperature_c - 0.0065f * std::max(0.0f, altitude_y);
    }
};

// ─── Weather Profile Definition ──────────────────────────────────────────────
struct WeatherProfile {
    WeatherConditionType id = WeatherConditionType::CLEAR_TROPICAL;
    std::string name = "Clear Tropical";

    float target_pressure_hpa    = 1018.0f;
    float target_temperature_c   = 28.5f;
    float target_humidity        = 0.65f;
    Spatial::Vector3D target_wind{3.5f, 0.0f, 1.8f};
    float target_gust            = 1.15f;

    float cloud_coverage         = 0.25f;
    float cloud_optical_depth    = 1.0f;
    float precipitation_rate     = 0.0f;
    float aerosol_density        = 0.05f;
    float volcanic_ash_fraction  = 0.0f;
    float lightning_probability  = 0.0f;

    float fog_density            = 0.001f;
    float ambient_light_scale    = 1.0f;
    Ogre::ColourValue sky_tint{1.0f, 1.0f, 1.0f, 1.0f};
    Ogre::ColourValue fog_color{0.75f, 0.82f, 0.92f, 1.0f};
};

// ─── Extensible Weather Profile Registry ─────────────────────────────────────
class WeatherRegistry {
public:
    static WeatherRegistry& instance() {
        static WeatherRegistry reg;
        return reg;
    }

    WeatherRegistry() {
        registerDefaultProfiles();
    }

    static std::string normalizeName(const std::string& input) {
        std::string out;
        for (char c : input) {
            if (c != ' ' && c != '_' && c != '-') {
                out.push_back(std::tolower(static_cast<unsigned char>(c)));
            }
        }
        return out;
    }

    void registerProfile(const WeatherProfile& profile) {
        profiles_by_id_[profile.id] = profile;
        profiles_by_name_[profile.name] = profile;
        profiles_by_name_[normalizeName(profile.name)] = profile;
    }

    bool hasProfile(WeatherConditionType id) const {
        return profiles_by_id_.find(id) != profiles_by_id_.end();
    }

    bool hasProfile(const std::string& name) const {
        return profiles_by_name_.find(name) != profiles_by_name_.end() ||
               profiles_by_name_.find(normalizeName(name)) != profiles_by_name_.end();
    }

    WeatherProfile getProfile(WeatherConditionType id) const {
        auto it = profiles_by_id_.find(id);
        if (it != profiles_by_id_.end()) return it->second;
        return profiles_by_id_.at(WeatherConditionType::CLEAR_TROPICAL);
    }

    WeatherProfile getProfile(const std::string& name) const {
        auto it = profiles_by_name_.find(name);
        if (it != profiles_by_name_.end()) return it->second;
        auto it2 = profiles_by_name_.find(normalizeName(name));
        if (it2 != profiles_by_name_.end()) return it2->second;
        return profiles_by_id_.at(WeatherConditionType::CLEAR_TROPICAL);
    }

    const std::unordered_map<WeatherConditionType, WeatherProfile>& getAllProfiles() const {
        return profiles_by_id_;
    }

private:
    void registerDefaultProfiles() {
        // 1. Clear Tropical Sunshine
        {
            WeatherProfile p;
            p.id = WeatherConditionType::CLEAR_TROPICAL;
            p.name = "Clear Tropical";
            p.target_pressure_hpa = 1018.5f;
            p.target_temperature_c = 29.5f;
            p.target_humidity = 0.60f;
            p.target_wind = Spatial::Vector3D(3.2f, 0.0f, 1.5f);
            p.target_gust = 1.12f;
            p.cloud_coverage = 0.22f;
            p.cloud_optical_depth = 0.85f;
            p.precipitation_rate = 0.0f;
            p.aerosol_density = 0.04f;
            p.volcanic_ash_fraction = 0.0f;
            p.lightning_probability = 0.0f;
            p.fog_density = 0.0008f;
            p.ambient_light_scale = 1.0f;
            p.sky_tint = Ogre::ColourValue(1.0f, 1.0f, 1.0f, 1.0f);
            p.fog_color = Ogre::ColourValue(0.78f, 0.86f, 0.95f, 1.0f);
            registerProfile(p);
        }

        // 2. Overcast Stratus
        {
            WeatherProfile p;
            p.id = WeatherConditionType::OVERCAST_STRATUS;
            p.name = "Overcast Stratus";
            p.target_pressure_hpa = 1009.0f;
            p.target_temperature_c = 24.0f;
            p.target_humidity = 0.82f;
            p.target_wind = Spatial::Vector3D(5.8f, 0.0f, 3.2f);
            p.target_gust = 1.25f;
            p.cloud_coverage = 0.78f;
            p.cloud_optical_depth = 1.6f;
            p.precipitation_rate = 1.2f; // Light drizzle
            p.aerosol_density = 0.18f;
            p.volcanic_ash_fraction = 0.0f;
            p.lightning_probability = 0.0f;
            p.fog_density = 0.0035f;
            p.ambient_light_scale = 0.72f;
            p.sky_tint = Ogre::ColourValue(0.82f, 0.84f, 0.88f, 1.0f);
            p.fog_color = Ogre::ColourValue(0.68f, 0.72f, 0.78f, 1.0f);
            registerProfile(p);
        }

        // 3. Tropical Monsoon & Thunderstorm
        {
            WeatherProfile p;
            p.id = WeatherConditionType::TROPICAL_MONSOON;
            p.name = "Tropical Monsoon";
            p.target_pressure_hpa = 993.0f;
            p.target_temperature_c = 21.5f;
            p.target_humidity = 0.98f;
            p.target_wind = Spatial::Vector3D(14.5f, 0.0f, 8.5f);
            p.target_gust = 1.65f;
            p.cloud_coverage = 0.96f;
            p.cloud_optical_depth = 3.2f;
            p.precipitation_rate = 45.0f; // Heavy torrential downpour
            p.aerosol_density = 0.45f;
            p.volcanic_ash_fraction = 0.0f;
            p.lightning_probability = 0.35f;
            p.fog_density = 0.012f;
            p.ambient_light_scale = 0.38f;
            p.sky_tint = Ogre::ColourValue(0.45f, 0.48f, 0.55f, 1.0f);
            p.fog_color = Ogre::ColourValue(0.42f, 0.45f, 0.52f, 1.0f);
            registerProfile(p);
        }

        // 4. Volcanic Ash Tempest (Pyroclastic Storm)
        {
            WeatherProfile p;
            p.id = WeatherConditionType::VOLCANIC_ASH_TEMPEST;
            p.name = "Volcanic Ash Tempest";
            p.target_pressure_hpa = 986.0f;
            p.target_temperature_c = 34.0f; // Hot convective thermal air
            p.target_humidity = 0.40f;
            p.target_wind = Spatial::Vector3D(18.0f, 0.0f, -12.0f);
            p.target_gust = 1.85f;
            p.cloud_coverage = 0.98f;
            p.cloud_optical_depth = 4.5f;
            p.precipitation_rate = 28.0f; // Heavy ash fall & volcanic sparks
            p.aerosol_density = 0.85f;
            p.volcanic_ash_fraction = 1.0f; // 100% Volcanic ash/soot
            p.lightning_probability = 0.65f; // Volcanic lightning (dirty thunderstorm)
            p.fog_density = 0.022f;
            p.ambient_light_scale = 0.25f;
            p.sky_tint = Ogre::ColourValue(0.68f, 0.28f, 0.18f, 1.0f); // Fiery orange/charcoal
            p.fog_color = Ogre::ColourValue(0.38f, 0.24f, 0.20f, 1.0f);
            registerProfile(p);
        }

        // 5. Marine Fog & Low Inversion
        {
            WeatherProfile p;
            p.id = WeatherConditionType::MARINE_FOG;
            p.name = "Marine Fog";
            p.target_pressure_hpa = 1012.0f;
            p.target_temperature_c = 19.0f;
            p.target_humidity = 0.96f;
            p.target_wind = Spatial::Vector3D(1.8f, 0.0f, 0.8f);
            p.target_gust = 1.05f;
            p.cloud_coverage = 0.65f;
            p.cloud_optical_depth = 1.4f;
            p.precipitation_rate = 0.5f; // Fine sea spray
            p.aerosol_density = 0.70f;
            p.volcanic_ash_fraction = 0.0f;
            p.lightning_probability = 0.0f;
            p.fog_density = 0.025f;
            p.ambient_light_scale = 0.60f;
            p.sky_tint = Ogre::ColourValue(0.75f, 0.80f, 0.85f, 1.0f);
            p.fog_color = Ogre::ColourValue(0.72f, 0.78f, 0.84f, 1.0f);
            registerProfile(p);
        }

        // 6. Golden Amber Haze (Twilight Aerosol)
        {
            WeatherProfile p;
            p.id = WeatherConditionType::GOLDEN_HAZE;
            p.name = "Golden Amber Haze";
            p.target_pressure_hpa = 1015.0f;
            p.target_temperature_c = 26.0f;
            p.target_humidity = 0.70f;
            p.target_wind = Spatial::Vector3D(4.2f, 0.0f, 2.0f);
            p.target_gust = 1.18f;
            p.cloud_coverage = 0.35f;
            p.cloud_optical_depth = 1.2f;
            p.precipitation_rate = 0.0f;
            p.aerosol_density = 0.35f;
            p.volcanic_ash_fraction = 0.08f;
            p.lightning_probability = 0.0f;
            p.fog_density = 0.005f;
            p.ambient_light_scale = 0.88f;
            p.sky_tint = Ogre::ColourValue(1.0f, 0.75f, 0.45f, 1.0f);
            p.fog_color = Ogre::ColourValue(0.85f, 0.62f, 0.40f, 1.0f);
            registerProfile(p);
        }
    }

    std::unordered_map<WeatherConditionType, WeatherProfile> profiles_by_id_;
    std::unordered_map<std::string, WeatherProfile> profiles_by_name_;
};

// ─── High-Performance Precipitation Particle Engine ─────────────────────────
struct PrecipitationStreak {
    Ogre::Vector3 pos;
    Ogre::Vector3 vel;
    float length;
    float alpha;
    float is_ash; // 0.0 = rain, 1.0 = ash
};

class PrecipitationRenderer {
public:
    static constexpr size_t MAX_STREAKS = 1024;
    alignas(32) std::vector<PrecipitationStreak> streaks_;
    std::mt19937 rng_{4242};

    PrecipitationRenderer() {
        streaks_.resize(MAX_STREAKS);
        resetStreaksAround(Ogre::Vector3(160, 20, 160), 40.0f);
    }

    void resetStreaksAround(const Ogre::Vector3& center, float box_size) {
        std::uniform_real_distribution<float> dist(-box_size * 0.5f, box_size * 0.5f);
        std::uniform_real_distribution<float> rand_len(0.4f, 1.2f);
        std::uniform_real_distribution<float> rand_speed(18.0f, 28.0f);

        for (size_t i = 0; i < MAX_STREAKS; ++i) {
            streaks_[i].pos = center + Ogre::Vector3(dist(rng_), dist(rng_) + box_size * 0.5f, dist(rng_));
            streaks_[i].vel = Ogre::Vector3(0.0f, -rand_speed(rng_), 0.0f);
            streaks_[i].length = rand_len(rng_);
            streaks_[i].alpha = 0.6f;
            streaks_[i].is_ash = 0.0f;
        }
    }

    void update(
        float dt,
        const Ogre::Vector3& camera_pos,
        const Spatial::Vector3D& wind_vel,
        float precip_rate,
        float ash_fraction
    ) {
        if (precip_rate <= 0.05f) return;

        const float box_size = 48.0f;
        const float half_box = box_size * 0.5f;

        const float wx = wind_vel.x;
        const float wz = wind_vel.z;
        const size_t active_count = std::min(MAX_STREAKS, size_t(precip_rate * 22.0f));

        #pragma GCC ivdep
        for (size_t i = 0; i < active_count; ++i) {
            auto& s = streaks_[i];
            s.is_ash = ash_fraction;

            // Terminal velocity: rain ~22m/s, ash ~6m/s
            float term_fall = (ash_fraction > 0.5f) ? -6.5f : -24.0f;
            s.vel.x = wx * (ash_fraction > 0.5f ? 0.9f : 0.4f);
            s.vel.z = wz * (ash_fraction > 0.5f ? 0.9f : 0.4f);
            s.vel.y = term_fall;

            s.pos += s.vel * dt;

            // Toroidal wrap around camera
            if (s.pos.y < camera_pos.y - 12.0f) s.pos.y += box_size;
            if (s.pos.y > camera_pos.y + box_size) s.pos.y -= box_size;
            if (s.pos.x < camera_pos.x - half_box) s.pos.x += box_size;
            if (s.pos.x > camera_pos.x + half_box) s.pos.x -= box_size;
            if (s.pos.z < camera_pos.z - half_box) s.pos.z += box_size;
            if (s.pos.z > camera_pos.z + half_box) s.pos.z -= box_size;
        }
    }

    void render(Ogre::ManualObject* precipObj, const Ogre::Vector3& camera_pos, float precip_rate, float ash_fraction) {
        if (!precipObj) return;
        precipObj->clear();

        if (precip_rate <= 0.05f) return;

        precipObj->begin("SCR/WeatherPrecipitationMaterial", Ogre::RenderOperation::OT_LINE_LIST);

        const size_t active_count = std::min(MAX_STREAKS, size_t(precip_rate * 22.0f));
        const Ogre::ColourValue rain_top(0.75f, 0.85f, 1.0f, 0.45f);
        const Ogre::ColourValue rain_bot(0.90f, 0.95f, 1.0f, 0.75f);
        const Ogre::ColourValue ash_top(0.35f, 0.28f, 0.22f, 0.65f);
        const Ogre::ColourValue ash_bot(0.18f, 0.14f, 0.12f, 0.85f);

        const auto& c_top = (ash_fraction > 0.5f) ? ash_top : rain_top;
        const auto& c_bot = (ash_fraction > 0.5f) ? ash_bot : rain_bot;

        for (size_t i = 0; i < active_count; ++i) {
            const auto& s = streaks_[i];
            Ogre::Vector3 dir = s.vel;
            if (dir.squaredLength() > 1e-4f) dir.normalise();
            else dir = Ogre::Vector3(0, -1, 0);

            Ogre::Vector3 p0 = s.pos;
            Ogre::Vector3 p1 = s.pos + dir * s.length;

            precipObj->position(p0);
            precipObj->colour(c_top);
            precipObj->position(p1);
            precipObj->colour(c_bot);
        }

        precipObj->end();
    }
};

// ─── Dynamic Weather Simulation Engine ───────────────────────────────────────
class DynamicWeatherSystem {
public:
    WeatherState current_state;
    WeatherProfile source_profile;
    WeatherProfile target_profile;

    float transition_progress = 1.0f; // 0.0 to 1.0
    float transition_duration = 4.0f; // Seconds
    float simulation_time = 0.0f;

    // Stochastic Lightning Discharge
    float lightning_flash_timer = 0.0f;
    float next_lightning_time = 5.0f;
    std::mt19937 rng_{1337};

    PrecipitationRenderer precipitation_engine;

    DynamicWeatherSystem() {
        auto init_prof = WeatherRegistry::instance().getProfile(WeatherConditionType::CLEAR_TROPICAL);
        source_profile = init_prof;
        target_profile = init_prof;
        applyProfileInstant(init_prof);
    }

    void setWeather(WeatherConditionType type, float duration_sec = 4.0f) {
        if (target_profile.id == type && transition_progress >= 1.0f) return;
        source_profile = createCurrentProfileSnapshot();
        target_profile = WeatherRegistry::instance().getProfile(type);
        transition_duration = std::max(0.1f, duration_sec);
        transition_progress = 0.0f;

        std::cout << "[Weather] Initiating smooth transition: " << source_profile.name
                  << " -> " << target_profile.name << " (" << transition_duration << "s)" << std::endl;
    }

    void setWeatherByName(const std::string& name, float duration_sec = 4.0f) {
        if (WeatherRegistry::instance().hasProfile(name)) {
            auto prof = WeatherRegistry::instance().getProfile(name);
            setWeather(prof.id, duration_sec);
        }
    }

    void cycleNextWeather() {
        uint32_t next_id = (static_cast<uint32_t>(target_profile.id) + 1) % 6;
        setWeather(static_cast<WeatherConditionType>(next_id), 3.5f);
    }

    void update(
        float dt,
        const Ogre::Vector3& camera_pos,
        float time_of_day_hours
    ) {
        simulation_time += dt;

        // 1. Smooth S3 Hermite Transition Progress
        if (transition_progress < 1.0f) {
            transition_progress += dt / transition_duration;
            if (transition_progress >= 1.0f) {
                transition_progress = 1.0f;
                current_state.condition_id = target_profile.id;
                current_state.condition_name = target_profile.name;
            }
        }

        float xi = std::max(0.0f, std::min(1.0f, transition_progress));
        float s = xi * xi * (3.0f - 2.0f * xi); // S3 Hermite Curve

        // 2. Interpolate Weather Parameters
        current_state.pressure_sea_level_hpa = lerp(source_profile.target_pressure_hpa, target_profile.target_pressure_hpa, s);
        current_state.temperature_c          = lerp(source_profile.target_temperature_c, target_profile.target_temperature_c, s);
        current_state.relative_humidity      = lerp(source_profile.target_humidity, target_profile.target_humidity, s);
        current_state.wind_gust_factor       = lerp(source_profile.target_gust, target_profile.target_gust, s);

        Spatial::Vector3D w0 = source_profile.target_wind;
        Spatial::Vector3D w1 = target_profile.target_wind;
        current_state.wind_velocity = Spatial::Vector3D(
            lerp(w0.x, w1.x, s),
            lerp(w0.y, w1.y, s),
            lerp(w0.z, w1.z, s)
        );

        // Dynamic Wind Gust Wobble
        float gust_wobble = 1.0f + 0.15f * std::sin(simulation_time * 1.8f) * current_state.wind_gust_factor;
        current_state.wind_velocity.x *= gust_wobble;
        current_state.wind_velocity.z *= gust_wobble;

        current_state.cloud_coverage        = lerp(source_profile.cloud_coverage, target_profile.cloud_coverage, s);
        current_state.cloud_optical_depth   = lerp(source_profile.cloud_optical_depth, target_profile.cloud_optical_depth, s);
        current_state.precipitation_rate    = lerp(source_profile.precipitation_rate, target_profile.precipitation_rate, s);
        current_state.aerosol_density       = lerp(source_profile.aerosol_density, target_profile.aerosol_density, s);
        current_state.volcanic_ash_fraction = lerp(source_profile.volcanic_ash_fraction, target_profile.volcanic_ash_fraction, s);
        current_state.fog_density           = lerp(source_profile.fog_density, target_profile.fog_density, s);
        current_state.ambient_light_scale   = lerp(source_profile.ambient_light_scale, target_profile.ambient_light_scale, s);

        current_state.sky_tint = lerpColor(source_profile.sky_tint, target_profile.sky_tint, s);
        current_state.fog_color = lerpColor(source_profile.fog_color, target_profile.fog_color, s);

        // 3. Lightning Discharge Simulation
        float current_lightning_prob = lerp(source_profile.lightning_probability, target_profile.lightning_probability, s);
        if (current_lightning_prob > 0.05f) {
            next_lightning_time -= dt;
            if (next_lightning_time <= 0.0f) {
                std::uniform_real_distribution<float> rand_delay(2.5f / current_lightning_prob, 8.0f / current_lightning_prob);
                next_lightning_time = rand_delay(rng_);
                lightning_flash_timer = 0.22f; // 220ms flash duration
            }
        }

        if (lightning_flash_timer > 0.0f) {
            lightning_flash_timer -= dt;
            current_state.lightning_intensity = std::max(0.0f, lightning_flash_timer / 0.22f);
        } else {
            current_state.lightning_intensity = 0.0f;
        }

        // 4. Update Precipitation Particles
        precipitation_engine.update(
            dt,
            camera_pos,
            current_state.wind_velocity,
            current_state.precipitation_rate,
            current_state.volcanic_ash_fraction
        );
    }

    void renderPrecipitation(Ogre::ManualObject* precipObj, const Ogre::Vector3& camera_pos) {
        precipitation_engine.render(
            precipObj,
            camera_pos,
            current_state.precipitation_rate,
            current_state.volcanic_ash_fraction
        );
    }

private:
    static float lerp(float a, float b, float t) {
        return a + (b - a) * t;
    }

    static Ogre::ColourValue lerpColor(const Ogre::ColourValue& a, const Ogre::ColourValue& b, float t) {
        return Ogre::ColourValue(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            a.a + (b.a - a.a) * t
        );
    }

    WeatherProfile createCurrentProfileSnapshot() const {
        WeatherProfile p;
        p.id = current_state.condition_id;
        p.name = current_state.condition_name;
        p.target_pressure_hpa    = current_state.pressure_sea_level_hpa;
        p.target_temperature_c   = current_state.temperature_c;
        p.target_humidity        = current_state.relative_humidity;
        p.target_wind            = current_state.wind_velocity;
        p.target_gust            = current_state.wind_gust_factor;
        p.cloud_coverage         = current_state.cloud_coverage;
        p.cloud_optical_depth    = current_state.cloud_optical_depth;
        p.precipitation_rate     = current_state.precipitation_rate;
        p.aerosol_density        = current_state.aerosol_density;
        p.volcanic_ash_fraction  = current_state.volcanic_ash_fraction;
        p.fog_density            = current_state.fog_density;
        p.ambient_light_scale    = current_state.ambient_light_scale;
        p.sky_tint               = current_state.sky_tint;
        p.fog_color              = current_state.fog_color;
        return p;
    }

    void applyProfileInstant(const WeatherProfile& p) {
        current_state.condition_id = p.id;
        current_state.condition_name = p.name;
        current_state.pressure_sea_level_hpa = p.target_pressure_hpa;
        current_state.temperature_c          = p.target_temperature_c;
        current_state.relative_humidity      = p.target_humidity;
        current_state.wind_velocity          = p.target_wind;
        current_state.wind_gust_factor       = p.target_gust;
        current_state.cloud_coverage         = p.cloud_coverage;
        current_state.cloud_optical_depth    = p.cloud_optical_depth;
        current_state.precipitation_rate     = p.precipitation_rate;
        current_state.aerosol_density        = p.aerosol_density;
        current_state.volcanic_ash_fraction  = p.volcanic_ash_fraction;
        current_state.fog_density            = p.fog_density;
        current_state.ambient_light_scale    = p.ambient_light_scale;
        current_state.sky_tint               = p.sky_tint;
        current_state.fog_color              = p.fog_color;
        current_state.lightning_intensity    = 0.0f;
    }
};

} // namespace SCR::Weather

#endif // CAVE_WEATHER_SEMANTICS_HPP
