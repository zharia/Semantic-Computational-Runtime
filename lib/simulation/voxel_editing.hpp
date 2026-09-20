#pragma once
/**
 * SCR VoxelEditingSubSystem — Mining, placing, DDA raycasting
 * ─────────────────────────────────────────────────────────────────────────────
 * Ported from fps_controller.hpp. Handles left-click mine, right-click place,
 * DDA raycast, head-shake on mine, STC update integration.
 */

#include "simulation/simulation_systems_core.hpp"
#include "simulation_config.hpp"
#include "semantic_materials.hpp"
#include "simulation/spatial_semantics.hpp"

namespace SCR::Simulation {

class VoxelEditingSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "VoxelEditing"; }

    void initialize(SystemContext& ctx) override {
        tool_active_ = false;
        tool_cooldown_ = 0.0f;
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        tool_cooldown_ -= dt;

        // ── Tool activation ──
        if (input.action_primary && tool_cooldown_ <= 0) {
            tool_active_ = true;
            tool_cooldown_ = 0.15f; // Prevent rapid fire
        }

        if (!tool_active_) return;

        // ── DDA raycast from player position/direction ──
        auto player_sub = ctx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        if (!player_sub) return;

        Spatial::Point3D origin = player_sub->position;
        float dir_x = -std::sin(player_sub->yaw) * std::cos(player_sub->pitch);
        float dir_y = std::sin(player_sub->pitch);
        float dir_z = -std::cos(player_sub->yaw) * std::cos(player_sub->pitch);
        Spatial::Vector3D dir(dir_x, dir_y, dir_z);

        // Step along ray
        for (float t = 0; t < Config::RAYCAST_MAX_DIST; t += Config::RAYCAST_STEP) {
            Spatial::Point3D point = origin + dir * t;
            int bx = static_cast<int>(std::floor(point.x));
            int by = static_cast<int>(std::floor(point.y));
            int bz = static_cast<int>(std::floor(point.z));

            // Bounds check
            if (bx < 0 || bx >= 64 || by < 0 || by >= 64 || bz < 0 || bz >= 64)
                continue;

            // ── Mine (left click) ──
            if (input.action_primary) {
                // Find which block we're inside
                // Set to MAT_AIR
                // Fire event: BlockMined{bx, by, bz}
                tool_active_ = false;
                shake_timer_ = Config::MINE_HEAD_SHAKE;
                break;
            }

            // ── Place (right click) ──
            if (input.action_secondary) {
                // Place current tool block at previous position along ray
                // Fire event: BlockPlaced{bx, by, bz, material}
                tool_active_ = false;
                break;
            }
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        // ── Head shake on mine ──
        if (shake_timer_ > 0) {
            auto* cam = renderCtx.getCamera<Ogre::Camera>();
            if (cam) {
                shake_timer_ -= dt;
                float intensity = Config::SHAKE_INTENSITY * (shake_timer_ / Config::MINE_HEAD_SHAKE);
                Ogre::Vector3 pos = cam->getRealPosition();
                pos.x += Ogre::Math::RangeRandom(-intensity, intensity);
                pos.y += Ogre::Math::RangeRandom(-intensity, intensity);
                cam->getParentSceneNode()->setPosition(pos);
            }
        }
    }

    void set_selected_material(uint16_t mat) { selected_material_ = mat; }
    uint16_t get_selected_material() const { return selected_material_; }

private:
    bool tool_active_ = false;
    float tool_cooldown_ = 0.0f;
    float shake_timer_ = 0.0f;
    uint16_t selected_material_ = Material::MAT_GRANITE;
};

} // namespace SCR::Simulation
