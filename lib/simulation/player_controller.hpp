#pragma once
/**
 * SCR PlayerControllerSubSystem — FPS controller with enhanced physics
 * ─────────────────────────────────────────────────────────────────────────────
 * Ported from fps_controller.hpp. Handles input→movement, collision, water, sliding.
 * Reads all constants from SCR::Config.
 */

#include "simulation/simulation_systems_core.hpp"
#include "simulation_config.hpp"
#include "simulation/spatial_semantics.hpp"

namespace SCR::Simulation {

namespace {
    inline float rangeRandom(float lo, float hi) {
        float r = (float)std::rand() / (float)RAND_MAX;
        return lo + r * (hi - lo);
    }
}

class PlayerControllerSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "PlayerController"; }

    void initialize(SystemContext& ctx) override {
        auto* cam = ctx.renderCtx.getCamera<Ogre::Camera>();
        if (cam) {
            cam->getParentSceneNode()->setPosition(Ogre::Vector3(0, Config::EYE_HEIGHT, 0));
        }
        pos_ = Spatial::Vector3D(0, Config::EYE_HEIGHT, 0);
        yaw_ = 0.0f;
        pitch_ = 0.0f;
        velocity_ = Spatial::Vector3D(0, 0, 0);
        on_ground_ = false;
        jump_timer_ = 0.0f;
        breath_timer_ = 0.0f;
        shake_timer_ = 0.0f;
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        dt = std::min(dt, Config::MAX_FRAME_DT);

        // ── Ground check (raycast down from stored position) ──
        on_ground_ = (pos_.y <= Config::EYE_HEIGHT + Config::STEP_HEIGHT + 0.05f);

        // ── Water check ──
        in_water_ = (water_surface_y_ > 0.0f && pos_.y < water_surface_y_ + 0.4f);

        // ── Movement input (computed from stored yaw) ──
        float fwd_x = -std::sin(yaw_);
        float fwd_z = -std::cos(yaw_);
        float rgt_x =  std::cos(yaw_);
        float rgt_z = -std::sin(yaw_);

        Spatial::Vector3D wish_dir(0, 0, 0);
        if (input.move_forward) {
            wish_dir += Spatial::Vector3D(fwd_x, 0, fwd_z);
        }
        if (input.move_backward) {
            wish_dir -= Spatial::Vector3D(fwd_x, 0, fwd_z);
        }
        if (input.move_left) {
            wish_dir += Spatial::Vector3D(rgt_x, 0, rgt_z);
        }
        if (input.move_right) {
            wish_dir -= Spatial::Vector3D(rgt_x, 0, rgt_z);
        }
        wish_dir.y = 0;
        if (wish_dir.length() > 1e-4f) wish_dir = wish_dir.normalized();

        float speed = input.sprint ? Config::SPRINT_SPEED : Config::WALK_SPEED;
        if (in_water_) speed *= Config::WATER_SPEED_MULT;

        // ── Acceleration ──
        Spatial::Vector3D target_vel = wish_dir * speed;
        if (on_ground_) {
            velocity_.x += (target_vel.x - velocity_.x) * Config::GROUND_ACCEL * dt;
            velocity_.z += (target_vel.z - velocity_.z) * Config::GROUND_ACCEL * dt;
            float friction = 1.0f - Config::GROUND_FRICTION * dt;
            velocity_.x *= std::max(0.0f, friction);
            velocity_.z *= std::max(0.0f, friction);
        } else {
            float current_speed = Spatial::Vector3D(velocity_.x, 0, velocity_.z).length();
            float add_speed = speed - current_speed;
            if (add_speed > 0) {
                float accel = Config::AIR_ACCEL * current_speed * dt;
                accel = std::min(accel, add_speed);
                velocity_.x += wish_dir.x * accel;
                velocity_.z += wish_dir.z * accel;
            }
            velocity_.x *= (1.0f - 0.15f * dt);
            velocity_.z *= (1.0f - 0.15f * dt);
        }

        // ── Gravity ──
        if (in_water_) {
            velocity_.y -= 1.0f * dt; // Gentle sink
            velocity_.y *= Config::WATER_DRAG;
        } else {
            float grav_mult = 1.0f;
            if (velocity_.y > 0.5f) {
                grav_mult = input.jump ? Config::GRAVITY_ASCENT_MULT : Config::GRAVITY_DESCENT_MULT;
            } else if (std::abs(velocity_.y) < Config::RAYCAST_STEP) {
                grav_mult = Config::GRAVITY_APEX_MULT;
            }
            velocity_.y += Config::GRAVITY * grav_mult * dt;
            velocity_.y = std::max(velocity_.y, Config::TERMINAL_VELOCITY);
        }

        // ── Jump ──
        jump_timer_ -= dt;
        if (input.jump) jump_timer_ = Config::JUMP_BUFFER;

        if (jump_timer_ > 0.0f) {
            if (on_ground_) {
                velocity_.y = Config::JUMP_VELOCITY;
                jump_timer_ = 0.0f;
                shake_timer_ = 0.2f; // Landing shake
            } else if (can_double_jump_) {
                velocity_.y = Config::DOUBLE_JUMP_VELOCITY;
                can_double_jump_ = false;
                jump_timer_ = 0.0f;
            }
        }

        if (on_ground_) can_double_jump_ = true;

        // ── Apply velocity ──
        pos_ += velocity_ * dt;
        pos_.y = std::max(pos_.y, Config::EYE_HEIGHT); // Floor clamp

        // ── Camera rotation (store cumulative yaw/pitch) ──
        yaw_ += -input.mouse_dx * Config::MOUSE_SENSITIVITY;
        pitch_ += -input.mouse_dy * Config::MOUSE_SENSITIVITY;
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        auto* cam = renderCtx.getCamera<Ogre::Camera>();
        if (!cam) return;

        auto* camNode = cam->getParentSceneNode();
        if (!camNode) return;

        // ── Head bob ──
        float speed_ratio = velocity_.length() / Config::SPRINT_SPEED;
        float bob_freq = Config::HEAD_BOB_FREQUENCY * speed_ratio;
        breath_timer_ += dt;
        float bob_y = std::sin(breath_timer_ * bob_freq) * Config::HEAD_BOB_AMPLITUDE * speed_ratio;
        float bob_x = std::cos(breath_timer_ * bob_freq * 0.5f) * Config::HEAD_BOB_AMPLITUDE * 0.5f * speed_ratio;

        // ── Breathing ──
        float breath = std::sin(breath_timer_ * Config::BREATHING_FREQUENCY) * Config::BREATHING_AMPLITUDE;

        Spatial::Vector3D final_pos = pos_;
        final_pos.y += bob_y + breath;

        // ── Camera shake decay ──
        if (shake_timer_ > 0) {
            shake_timer_ -= dt;
            float shake_intensity = Config::SHAKE_INTENSITY * (shake_timer_ / 0.2f);
            final_pos.x += rangeRandom(-shake_intensity, shake_intensity);
            final_pos.y += rangeRandom(-shake_intensity, shake_intensity);
        }

        camNode->setPosition(Ogre::Vector3(final_pos.x, final_pos.y, final_pos.z));
        auto q = Spatial::Quaternion::fromEuler(pitch_, yaw_, 0.0f);
        camNode->setOrientation(Ogre::Quaternion(q.w, q.x, q.y, q.z));
    }

    void set_water_surface(float y) { water_surface_y_ = y; }
    bool is_on_ground() const { return on_ground_; }
    bool is_in_water() const { return in_water_; }
    Spatial::Vector3D get_velocity() const { return velocity_; }

private:
    Spatial::Vector3D pos_;
    float yaw_ = 0.0f;
    float pitch_ = 0.0f;
    Spatial::Vector3D velocity_ = Spatial::Vector3D(0, 0, 0);
    bool on_ground_ = false;
    bool in_water_ = false;
    bool can_double_jump_ = true;
    float water_surface_y_ = 0.0f;
    float jump_timer_ = 0.0f;
    float breath_timer_ = 0.0f;
    float shake_timer_ = 0.0f;
};

} // namespace SCR::Simulation
