#ifndef CAVE_FPS_CONTROLLER_HPP
#define CAVE_FPS_CONTROLLER_HPP

#include "spatial_semantics.hpp"
#include "procedural_cave.hpp"
#include <cmath>
#include <algorithm>

namespace SCR::Controller {

struct RayHit {
    bool hit;
    int voxel_x, voxel_y, voxel_z;
    SCR::Spatial::Vector3D hit_point;
    SCR::Spatial::Vector3D normal;
    uint16_t material_code;
    float distance;
    SCR::Spatial::LatticeCoord3D place_coord;
};

/**
 * FPSController with Advanced Biomechanical Micro-Movements:
 * - Dynamic Head-Tilt (Roll) on lateral strafing and angular turns
 * - Procedural Head-Shake micro-vibrations on landing impact and mining recoil
 * - Multi-harmonic Head-Bobbing and rhythmic lateral sway on locomotion
 * - Idle thoracic breathing undulation and buoyancy sway
 */
class FPSController {
public:
    SCR::Spatial::Point3D position;   // Base of player bounding box
    SCR::Spatial::Vector3D velocity;
    float yaw;                        // Radians
    float pitch;                      // Radians
    float roll;                       // Radians (Head-Tilt)
    float target_roll;
    bool is_grounded;
    bool in_water;

    // Advanced Micro-Movement States
    float head_bob_time;
    float head_bob_x;
    float head_bob_y;
    float head_bob_tilt;

    float shake_intensity;
    float shake_timer;
    float shake_freq;
    float shake_decay;
    float shake_rot_pitch;
    float shake_rot_yaw;
    float shake_offset_x;
    float shake_offset_y;

    float breathing_phase;
    float landing_impact_dip;
    float prev_vy;

    // Spatial Reference Frames (Hierarchy: Cave Lattice -> Player Body -> Camera Eye)
    SCR::Spatial::ReferenceFrame player_body_frame;
    SCR::Spatial::ReferenceFrame camera_eye_frame;

    // Player physical dimensions
    float player_radius;
    float player_height;
    float eye_height;

    // Kinematic settings
    float walk_speed;
    float sprint_speed;
    float jump_velocity;
    float double_jump_velocity;
    float double_jump_thrust;
    float gravity;
    bool  can_double_jump;
    float coyote_timer;
    float jump_buffer;
    bool  prev_jump_input;

    FPSController(const SCR::Spatial::Point3D& spawn = SCR::Spatial::Point3D(24, 6, 24))
        : position(spawn), velocity(0, 0, 0), yaw(0.0f), pitch(0.0f), roll(0.0f), target_roll(0.0f),
          is_grounded(false), in_water(false),
          head_bob_time(0.0f), head_bob_x(0.0f), head_bob_y(0.0f), head_bob_tilt(0.0f),
          shake_intensity(0.0f), shake_timer(0.0f), shake_freq(24.0f), shake_decay(9.0f),
          shake_rot_pitch(0.0f), shake_rot_yaw(0.0f), shake_offset_x(0.0f), shake_offset_y(0.0f),
          breathing_phase(0.0f), landing_impact_dip(0.0f), prev_vy(0.0f),
          player_body_frame("player_body_frame", "cave_lattice_frame"),
          camera_eye_frame("camera_eye_frame", "player_body_frame"),
          player_radius(0.15f), player_height(0.90f), eye_height(0.80f),
          walk_speed(3.75f), sprint_speed(7.25f), jump_velocity(5.8f),
          double_jump_velocity(5.4f), double_jump_thrust(3.4f), gravity(-10.0f),
          can_double_jump(true), coyote_timer(0.0f), jump_buffer(0.0f), prev_jump_input(false) {
        updateSpatialFrames();
    }

    void triggerHeadShake(float intensity = 0.08f) {
        shake_intensity = std::min(0.25f, shake_intensity + intensity);
        shake_timer = 0.0f;
    }

    void updateSpatialFrames() {
        // Player Body Frame: translation = position, rotation = yaw around Y
        player_body_frame.local_transform = Spatial::TransformSE3(
            position,
            Spatial::Quaternion::fromEuler(0.0f, yaw, 0.0f)
        );

        // Camera Eye Frame with composite micro-movements
        float total_pitch = pitch + shake_rot_pitch;
        float total_yaw = shake_rot_yaw; // local yaw offset
        float total_roll = roll + head_bob_tilt;

        float breath_y = std::sin(breathing_phase) * 0.007f;
        float eye_y_offset = eye_height + head_bob_y + breath_y - landing_impact_dip + shake_offset_y;
        float eye_x_offset = head_bob_x + shake_offset_x;

        camera_eye_frame.local_transform = Spatial::TransformSE3(
            Spatial::Point3D(eye_x_offset, eye_y_offset, 0.0f),
            Spatial::Quaternion::fromEuler(total_pitch, total_yaw, total_roll)
        );
    }

    SCR::Spatial::Point3D getEyePosition() const {
        float breath_y = std::sin(breathing_phase) * 0.007f;
        float cur_eye_y = eye_height + head_bob_y + breath_y - landing_impact_dip + shake_offset_y;
        float cur_eye_x = head_bob_x + shake_offset_x;

        // Transform local camera eye offset by body orientation (yaw)
        float cos_y = std::cos(yaw);
        float sin_y = std::sin(yaw);
        float world_x = position.x + cur_eye_x * cos_y;
        float world_z = position.z - cur_eye_x * sin_y;
        float world_y = position.y + cur_eye_y;

        return SCR::Spatial::Point3D(world_x, world_y, world_z);
    }

    SCR::Spatial::Quaternion getEyeOrientation() const {
        float total_pitch = pitch + shake_rot_pitch;
        float total_yaw = yaw + shake_rot_yaw;
        float total_roll = roll + head_bob_tilt;
        return SCR::Spatial::Quaternion::fromEuler(total_pitch, total_yaw, total_roll);
    }

    SCR::Spatial::Vector3D getForwardVector() const {
        float total_pitch = pitch + shake_rot_pitch;
        float total_yaw = yaw + shake_rot_yaw;
        return SCR::Spatial::Vector3D(
            -std::sin(total_yaw) * std::cos(total_pitch),
            std::sin(total_pitch),
            -std::cos(total_yaw) * std::cos(total_pitch)
        ).normalized();
    }

    SCR::Spatial::Vector3D getRightVector() const {
        float total_yaw = yaw + shake_rot_yaw;
        return SCR::Spatial::Vector3D(
            std::cos(total_yaw),
            0.0f,
            -std::sin(total_yaw)
        ).normalized();
    }

    SCR::Spatial::Vector3D getHorizontalForward() const {
        return SCR::Spatial::Vector3D(
            -std::sin(yaw),
            0.0f,
            -std::cos(yaw)
        ).normalized();
    }

    void rotate(float delta_yaw, float delta_pitch) {
        yaw += delta_yaw;
        pitch += delta_pitch;
        pitch = std::max(-1.48f, std::min(1.48f, pitch));

        // Dynamic roll micro-tilt during sharp angular camera turns
        target_roll -= delta_yaw * 0.018f;
        target_roll = std::max(-0.08f, std::min(0.08f, target_roll));

        updateSpatialFrames();
    }

    SCR::Spatial::AABB3D getBoundingBox(const SCR::Spatial::Point3D& pos) const {
        return SCR::Spatial::AABB3D(
            SCR::Spatial::Point3D(pos.x - player_radius, pos.y, pos.z - player_radius),
            SCR::Spatial::Point3D(pos.x + player_radius, pos.y + player_height, pos.z + player_radius)
        );
    }

    bool collidesWithCave(const SCR::Spatial::Point3D& test_pos, const Cave::VoxelCave& cave) const {
        auto aabb = getBoundingBox(test_pos);
        int min_x = (int)std::floor(aabb.min.x);
        int max_x = (int)std::floor(aabb.max.x);
        int min_y = (int)std::floor(aabb.min.y);
        int max_y = (int)std::floor(aabb.max.y);
        int min_z = (int)std::floor(aabb.min.z);
        int max_z = (int)std::floor(aabb.max.z);

        // 1. Discrete voxel occupancy check
        for (int x = min_x; x <= max_x; ++x) {
            for (int y = min_y; y <= max_y; ++y) {
                for (int z = min_z; z <= max_z; ++z) {
                    if (cave.isSolid(x, y, z)) {
                        return true;
                    }
                }
            }
        }

        // 2. Continuous density check at the eye point — catches smooth OpenVDB
        //    geometry that protrudes into nominally-air voxels.
        float eye_density = cave.sampleContinuousDensity(
            test_pos.x, test_pos.y + eye_height, test_pos.z);
        if (eye_density > -0.05f) return true;

        return false;
    }

    /**
     * Returns how far the eye is inside solid geometry (positive = penetrating).
     * Used by the per-frame camera clearance guard.
     */
    float eyePenetrationDepth(const Cave::VoxelCave& cave) const {
        auto eye = getEyePosition();
        float d = cave.sampleContinuousDensity(eye.x, eye.y, eye.z);
        return d; // positive = inside mesh
    }

    void update(float dt, bool move_fwd, bool move_back, bool move_left, bool move_right, 
                bool jump, bool sprint, const Cave::VoxelCave& cave) {
        dt = std::min(dt, 0.05f); // Prevent tunneling

        // 1. Footing Material & Water Immersion Check
        int eye_x = (int)std::floor(position.x);
        int eye_y = (int)std::floor(position.y + 0.4f);
        int eye_z = (int)std::floor(position.z);
        in_water = (cave.getVoxel(eye_x, eye_y, eye_z) == Material::MAT_WATER);

        // 2. Jump Edge & Buffer Tracking
        bool jump_edge = jump && !prev_jump_input;
        prev_jump_input = jump;
        if (jump_edge) {
            jump_buffer = 0.15f;
        } else if (jump_buffer > 0.0f) {
            jump_buffer -= dt;
        }

        // 3. Kinematic Direction Calculation & Momentum Acceleration
        SCR::Spatial::Vector3D wish_dir(0, 0, 0);
        auto fwd = getHorizontalForward();
        auto right = getRightVector();

        if (move_fwd) wish_dir += fwd;
        if (move_back) wish_dir -= fwd;
        if (move_right) wish_dir += right;
        if (move_left) wish_dir -= right;

        float current_speed = sprint ? sprint_speed : walk_speed;
        if (in_water) current_speed *= 0.65f;

        bool has_wish_input = wish_dir.lengthSq() > 1e-4f;
        if (has_wish_input) {
            wish_dir = wish_dir.normalized();
        }

        if (is_grounded) {
            coyote_timer = 0.18f;
            can_double_jump = true;

            if (has_wish_input) {
                // Ground Acceleration toward wish velocity
                SCR::Spatial::Vector3D target_vel = wish_dir * current_speed;
                float blend = std::min(1.0f, 16.0f * dt);
                velocity.x += (target_vel.x - velocity.x) * blend;
                velocity.z += (target_vel.z - velocity.z) * blend;
            } else {
                // Ground Friction Braking
                float friction = std::max(0.0f, 1.0f - 8.5f * dt);
                velocity.x *= friction;
                velocity.z *= friction;
            }
        } else {
            // Airborne: Source-style Air-Strafing
            coyote_timer = std::max(0.0f, coyote_timer - dt);
            if (has_wish_input) {
                float current_proj = velocity.x * wish_dir.x + velocity.z * wish_dir.z;
                float add_speed = std::max(0.0f, sprint_speed - current_proj);
                float accel_speed = std::min(add_speed, 7.5f * current_speed * dt);
                velocity.x += wish_dir.x * accel_speed;
                velocity.z += wish_dir.z * accel_speed;
            }
            float air_drag = std::max(0.0f, 1.0f - 0.15f * dt);
            velocity.x *= air_drag;
            velocity.z *= air_drag;
        }

        // 4. Head-Tilt (Roll) Calculation on Lateral Strafe
        float lateral_speed = velocity.x * right.x + velocity.z * right.z;
        target_roll = -lateral_speed * 0.0035f;
        roll += (target_roll - roll) * std::min(1.0f, dt * 10.0f);

        // 5. Locomotion Head-Bobbing & Rhythmic Step Sway
        float horiz_speed = std::sqrt(velocity.x * velocity.x + velocity.z * velocity.z);
        if (has_wish_input && is_grounded) {
            float speed_ratio = std::min(1.5f, horiz_speed / walk_speed);
            float bob_freq = 8.8f * speed_ratio;
            head_bob_time += dt * bob_freq;
            head_bob_y = std::sin(head_bob_time * 2.0f) * (sprint ? 0.020f : 0.011f);
            head_bob_x = std::cos(head_bob_time) * (sprint ? 0.012f : 0.007f);
            head_bob_tilt = std::sin(head_bob_time) * (sprint ? 0.018f : 0.010f);
        } else {
            head_bob_x *= std::max(0.0f, 1.0f - dt * 10.0f);
            head_bob_y *= std::max(0.0f, 1.0f - dt * 10.0f);
            head_bob_tilt *= std::max(0.0f, 1.0f - dt * 10.0f);
        }

        // 6. Breathing Cycle & Fluid Undulation
        breathing_phase += dt * (in_water ? 1.2f : 1.8f);
        landing_impact_dip *= std::max(0.0f, 1.0f - dt * 9.0f);

        // 7. High-Frequency Head-Shake Micro-Vibrations
        if (shake_intensity > 1e-4f) {
            shake_timer += dt;
            shake_intensity = std::max(0.0f, shake_intensity - shake_decay * dt);

            shake_offset_x = shake_intensity * std::sin(shake_timer * shake_freq * 1.35f) * 0.06f;
            shake_offset_y = shake_intensity * std::cos(shake_timer * shake_freq) * 0.06f;
            shake_rot_pitch = shake_intensity * std::sin(shake_timer * shake_freq * 0.88f) * 0.075f;
            shake_rot_yaw = shake_intensity * std::cos(shake_timer * shake_freq * 1.12f) * 0.060f;
        } else {
            shake_intensity = shake_offset_x = shake_offset_y = shake_rot_pitch = shake_rot_yaw = 0.0f;
        }

        // 8. Ballistic Vertical Dynamics & Double-Jump Launch
        prev_vy = velocity.y;
        if (in_water) {
            can_double_jump = true;
            velocity.y *= 0.85f;
            if (jump) velocity.y = 2.25f;
            else velocity.y -= 1.0f * dt;
            is_grounded = false;
        } else {
            if (jump_buffer > 0.0f) {
                if (is_grounded || coyote_timer > 0.0f) {
                    velocity.y = jump_velocity;
                    is_grounded = false;
                    coyote_timer = 0.0f;
                    jump_buffer = 0.0f;
                    triggerHeadShake(0.04f);
                } else if (can_double_jump) {
                    velocity.y = double_jump_velocity;
                    can_double_jump = false;
                    jump_buffer = 0.0f;
                    auto boost_dir = has_wish_input ? wish_dir : fwd;
                    velocity.x += boost_dir.x * double_jump_thrust;
                    velocity.z += boost_dir.z * double_jump_thrust;
                    triggerHeadShake(0.065f);
                }
            }

            // Natural Trajectory Curve with Apex Float & Kinetic Descent
            float eff_gravity = gravity;
            if (std::abs(velocity.y) < 1.6f) {
                eff_gravity = gravity * 0.65f; // Apex float / natural crest hang-time
            } else if (velocity.y > 1.6f) {
                eff_gravity = jump ? (gravity * 0.90f) : (gravity * 1.55f); // Variable jump ascent
            } else {
                eff_gravity = gravity * 1.25f; // Kinetic, weighted downward descent
            }

            velocity.y += eff_gravity * dt;
            velocity.y = std::max(velocity.y, -18.0f);
        }

        // 8. Axis-Independent Collision Resolution with Auto-Stepping (Curb Climbing)
        const float step_height = 0.35f;

        // X-Axis
        float next_x = position.x + velocity.x * dt;
        if (!collidesWithCave(SCR::Spatial::Point3D(next_x, position.y, position.z), cave)) {
            position.x = next_x;
        } else {
            if (is_grounded && !collidesWithCave(SCR::Spatial::Point3D(next_x, position.y + step_height, position.z), cave)) {
                position.x = next_x;
                position.y += step_height * 0.5f;
            } else {
                velocity.x = 0.0f;
            }
        }

        // Z-Axis
        float next_z = position.z + velocity.z * dt;
        if (!collidesWithCave(SCR::Spatial::Point3D(position.x, position.y, next_z), cave)) {
            position.z = next_z;
        } else {
            if (is_grounded && !collidesWithCave(SCR::Spatial::Point3D(position.x, position.y + step_height, next_z), cave)) {
                position.z = next_z;
                position.y += step_height * 0.5f;
            } else {
                velocity.z = 0.0f;
            }
        }

        // Y-Axis
        float next_y = position.y + velocity.y * dt;
        if (!collidesWithCave(SCR::Spatial::Point3D(position.x, next_y, position.z), cave)) {
            position.y = next_y;
            is_grounded = false;
        } else {
            if (velocity.y < 0.0f) {
                // Landing impact: trigger head-shake & compression dip
                if (!is_grounded && prev_vy < -3.5f) {
                    float impact = std::min(0.20f, std::abs(prev_vy) * 0.016f);
                    triggerHeadShake(impact);
                    landing_impact_dip = std::min(0.22f, std::abs(prev_vy) * 0.022f);
                }
                is_grounded = true;
                position.y = std::ceil(position.y) - 0.001f;
            } else if (velocity.y > 0.0f) {
                position.y = std::floor(position.y) + 0.001f;
            }
            velocity.y = 0.0f;
        }

        // Robust iterative depenetration recovery:
        // If the player body is embedded in solid geometry, try to push them clear
        // by searching upward then horizontally before giving up.
        if (collidesWithCave(position, cave)) {
            bool escaped = false;
            // First, try pushing upward in small steps (most common case)
            for (int nudge = 1; nudge <= 8 && !escaped; ++nudge) {
                SCR::Spatial::Point3D try_pos = position;
                try_pos.y = std::ceil(position.y) + nudge * 0.15f;
                if (!collidesWithCave(try_pos, cave)) {
                    position = try_pos;
                    velocity.y = 0.0f;
                    is_grounded = true;
                    escaped = true;
                }
            }
            // If still stuck, try pushing horizontally toward the nearest open voxel
            if (!escaped) {
                const float horiz_step = 0.35f;
                static const std::pair<float,float> dirs[] = {{0,1},{0,-1},{1,0},{-1,0}};
                for (auto& [dx, dz] : dirs) {
                    if (escaped) break;
                    for (int k = 1; k <= 6 && !escaped; ++k) {
                        SCR::Spatial::Point3D try_pos = position;
                        try_pos.x += dx * horiz_step * k;
                        try_pos.z += dz * horiz_step * k;
                        if (!collidesWithCave(try_pos, cave)) {
                            position = try_pos;
                            velocity.x = 0.0f;
                            velocity.z = 0.0f;
                            escaped = true;
                        }
                    }
                }
            }
            // Last resort: zero velocity to prevent tunneling
            if (!escaped) {
                velocity = SCR::Spatial::Vector3D(0.0f, 0.0f, 0.0f);
            }
        }

        // Eye-in-mesh guard: even if the body is clear the camera eye can still clip
        // into a smooth OpenVDB surface. Slide the eye down until it is clear.
        {
            float pen = eyePenetrationDepth(cave);
            if (pen > -0.05f) {
                // Reduce eye_height temporarily until eye clears the surface
                float saved = eye_height;
                for (int step = 1; step <= 12; ++step) {
                    eye_height = saved - step * 0.1f;
                    if (eye_height < 0.3f) { eye_height = 0.3f; break; }
                    float new_pen = cave.sampleContinuousDensity(
                        position.x,
                        position.y + eye_height,
                        position.z);
                    if (new_pen <= -0.05f) break;
                }
                // Spring eye_height back to 1.6 m when clear
            } else {
                // Smoothly recover eye height toward nominal 1.6 m
                const float nominal_eye = 1.6f;
                eye_height = eye_height + (nominal_eye - eye_height) * std::min(1.0f, dt * 8.0f);
                if (eye_height > nominal_eye) eye_height = nominal_eye;
            }
        }

        updateSpatialFrames();
    }

    // 3D DDA Voxel Raycast
    RayHit castRay(const Cave::VoxelCave& cave, float max_distance = 12.0f) const {
        RayHit result;
        result.hit = false;
        result.place_coord = SCR::Spatial::LatticeCoord3D(0, 0, 0);

        auto ray = SCR::Spatial::Ray3D(getEyePosition(), getForwardVector());
        
        int x = (int)std::floor(ray.origin.x);
        int y = (int)std::floor(ray.origin.y);
        int z = (int)std::floor(ray.origin.z);

        int step_x = (ray.direction.x >= 0) ? 1 : -1;
        int step_y = (ray.direction.y >= 0) ? 1 : -1;
        int step_z = (ray.direction.z >= 0) ? 1 : -1;

        float t_delta_x = (ray.direction.x != 0) ? std::abs(1.0f / ray.direction.x) : 1e30f;
        float t_delta_y = (ray.direction.y != 0) ? std::abs(1.0f / ray.direction.y) : 1e30f;
        float t_delta_z = (ray.direction.z != 0) ? std::abs(1.0f / ray.direction.z) : 1e30f;

        float t_max_x = (step_x > 0) ? (x + 1.0f - ray.origin.x) * t_delta_x : (ray.origin.x - x) * t_delta_x;
        float t_max_y = (step_y > 0) ? (y + 1.0f - ray.origin.y) * t_delta_y : (ray.origin.y - y) * t_delta_y;
        float t_max_z = (step_z > 0) ? (z + 1.0f - ray.origin.z) * t_delta_z : (ray.origin.z - z) * t_delta_z;

        float dist = 0.0f;
        SCR::Spatial::Vector3D normal(0, 0, 0);

        while (dist < max_distance) {
            if (cave.isSolid(x, y, z) || cave.getVoxel(x, y, z) == Material::MAT_WATER || cave.getVoxel(x, y, z) == Material::MAT_LAVA) {
                result.hit = true;
                result.voxel_x = x;
                result.voxel_y = y;
                result.voxel_z = z;
                result.material_code = cave.getVoxel(x, y, z);
                result.distance = dist;
                result.normal = normal;
                result.hit_point = ray.pointAt(dist);
                result.place_coord = SCR::Spatial::LatticeCoord3D(
                    x + (int)normal.x,
                    y + (int)normal.y,
                    z + (int)normal.z
                );
                return result;
            }

            if (t_max_x < t_max_y) {
                if (t_max_x < t_max_z) {
                    dist = t_max_x;
                    t_max_x += t_delta_x;
                    x += step_x;
                    normal = SCR::Spatial::Vector3D(-step_x, 0, 0);
                } else {
                    dist = t_max_z;
                    t_max_z += t_delta_z;
                    z += step_z;
                    normal = SCR::Spatial::Vector3D(0, 0, -step_z);
                }
            } else {
                if (t_max_y < t_max_z) {
                    dist = t_max_y;
                    t_max_y += t_delta_y;
                    y += step_y;
                    normal = SCR::Spatial::Vector3D(0, -step_y, 0);
                } else {
                    dist = t_max_z;
                    t_max_z += t_delta_z;
                    z += step_z;
                    normal = SCR::Spatial::Vector3D(0, 0, -step_z);
                }
            }
        }
        return result;
    }
};

} // namespace SCR::Controller

#endif // CAVE_FPS_CONTROLLER_HPP
