/**
 * SCR Exotic Volcanic Island Explorer
 * ─────────────────────────────────────────────────────────────────────────────
 * Open-air first-person explorer of a procedural exotic volcanic island.
 * Uses SCR Spatial Semantics + SCR Material Catalog + OpenVDB + OGRE 3D.
 *
 * Biome coverage: beach → coastal palms → dense rainforest → basalt cliffs
 *                → caldera rim → magma lake / lava river
 *
 * All collision detection is dual-mode:
 *   • Discrete voxel occupancy (fast path)
 *   • Continuous OpenVDB density at eye position (wall-clip guard)
 */

#include <Ogre.h>
#include <OgreApplicationContext.h>
#include <OgreInput.h>
#include <OgreRTShaderSystem.h>
#include <Overlay/OgreImGuiOverlay.h>
#include <Overlay/OgreOverlayManager.h>
#include <Overlay/OgreOverlaySystem.h>
#include <Bites/OgreImGuiInputListener.h>

#include "spatial_semantics.hpp"
#include "semantic_materials.hpp"
#include "procedural_island.hpp"
#include "vdb_island_mesher.hpp"
#include "vdb_chunk_manager.hpp"
#include "hierarchical_wfc.hpp"
#include "ocean_simulation.hpp"
#include "volumetric_clouds.hpp"
#include "volcanic_effects.hpp"
#include "procedural_vegetation.hpp"
#include "boid_semantics.hpp"
#include "horizon_planet_parallax.hpp"
#include "island_hud.hpp"
#include "cel_shading_system.hpp"
#include "wayland_compositor.hpp"
#include "in_world_display.hpp"
#include "nautical_navigation.hpp"

#include <iostream>
#include <fstream>
#include <iomanip>
#include <chrono>
#include <memory>
#include <cmath>
#include <sstream>

using namespace Ogre;
using namespace OgreBites;
using namespace SCR;

// ─── Thin Island-aware FPS controller ───────────────────────────────────────
// Wraps the same physics and camera logic from fps_controller.hpp but operates
// on VoxelIsland rather than VoxelCave.
namespace SCR::IslandController {

struct IslandRayHit {
    bool hit = false;
    int vx,vy,vz;
    float distance;
    SCR::Spatial::Vector3D normal;
    SCR::Spatial::Vector3D hit_point;
    SCR::Spatial::LatticeCoord3D place_coord;
    uint16_t material_code = Material::MAT_AIR;
};

class IslandPlayer {
public:
    Spatial::Point3D  position;
    Spatial::Vector3D velocity;
    float yaw=0.f, pitch=0.f, roll=0.f, target_roll=0.f;

    // Dimensions and Eye Heights (1/2 Scale for 4x Relative Exploration Acreage)
    float eye_height_standing = 0.80f;   // Scaled from 1.60m
    float eye_height_sliding  = 0.425f;  // Scaled from 0.85m
    float current_eye_height  = 0.80f;
    float eye_height_velocity = 0.0f;    // 2nd-order spring velocity
    float smooth_eye_y        = 0.0f;
    float player_radius       = 0.15f;   // Scaled from 0.30m
    float player_height       = 0.90f;   // Scaled from 1.80m

    // Professional Kinematic Parameters (m/s at 1/2 Scale)
    float walk_speed           = 3.75f;  // Scaled from 7.5m/s
    float sprint_speed         = 7.25f;  // Scaled from 14.5m/s
    float crouch_speed         = 2.1f;   // Scaled from 4.2m/s
    float jump_velocity        = 5.8f;   // Scaled from 11.6m/s (~1.7m jump height)
    float double_jump_velocity = 5.4f;   // Scaled from 10.8m/s
    float double_jump_thrust   = 3.4f;   // Scaled from 6.8m/s
    float gravity              = -10.0f; // Scaled from -20.0m/s^2 (preserves natural trajectory curve)
    float ground_accel         = 16.0f;  // Momentum buildup (s^-1)
    float ground_friction      = 8.5f;   // Braking deceleration (s^-1)
    float air_accel            = 8.0f;   // Responsive air strafing
    float air_speed_cap        = 7.75f;  // Scaled from 15.5m/s
    float slide_friction       = 1.4f;   // Low friction for long slides

    // State Tracking
    bool is_grounded     = false;
    bool in_water        = false;
    bool can_double_jump = true;
    bool is_sliding      = false;
    float slide_timer    = 0.0f;
    float coyote_timer   = 0.0f;   // Grace period after leaving ledges (180ms)
    float jump_buffer    = 0.0f;   // Input buffering before landing (150ms)
    bool prev_jump_input = false;  // Edge detector for double-jump

    // 2nd-Order Landing Spring Absorber
    float landing_spring_disp = 0.0f; // Vertical displacement (m)
    float landing_spring_vel  = 0.0f; // Spring velocity (m/s)

    // Dynamic Micro-Movements & Head-Bobbing
    float head_bob_time=0, head_bob_x=0, head_bob_y=0, head_bob_tilt=0;
    float shake_intensity=0, shake_timer=0;
    float shake_rot_pitch=0, shake_rot_yaw=0, shake_offset_x=0, shake_offset_y=0;
    float breathing_phase=0, prev_vy=0;
    float double_jump_fx = 0.0f;

    // SCR Spatial Reference Frames
    Spatial::ReferenceFrame body_frame, eye_frame;

    IslandPlayer(Spatial::Point3D p)
        : position(p), velocity(0,0,0), smooth_eye_y(p.y + 1.6f),
          body_frame("player_body","island_lattice_frame"),
          eye_frame("player_eye","player_body") {}

    void triggerHeadShake(float intensity=0.06f){
        shake_intensity=std::min(.22f, shake_intensity+intensity);
        shake_timer=0;
    }

    Spatial::Point3D getEyePosition() const {
        float cos_y=std::cos(yaw), sin_y=std::sin(yaw);
        float world_x = position.x + (head_bob_x + shake_offset_x) * cos_y;
        float world_z = position.z - (head_bob_x + shake_offset_x) * sin_y;
        float breath_y = std::sin(breathing_phase) * 0.004f;
        float world_y = smooth_eye_y + head_bob_y - landing_spring_disp + shake_offset_y + breath_y;
        return Spatial::Point3D(world_x, world_y, world_z);
    }

    Spatial::Quaternion getEyeOrientation() const {
        return Spatial::Quaternion::fromEuler(
            pitch+shake_rot_pitch, yaw+shake_rot_yaw, roll+head_bob_tilt);
    }

    Spatial::Vector3D getForward() const {
        float tp=pitch+shake_rot_pitch, ty=yaw+shake_rot_yaw;
        return Spatial::Vector3D(-std::sin(ty)*std::cos(tp), std::sin(tp), -std::cos(ty)*std::cos(tp)).normalized();
    }
    Spatial::Vector3D getHorizFwd() const {
        return Spatial::Vector3D(-std::sin(yaw),0,-std::cos(yaw)).normalized();
    }
    Spatial::Vector3D getRight() const {
        return Spatial::Vector3D(std::cos(yaw),0,-std::sin(yaw)).normalized();
    }

    void rotate(float dy, float dp){
        yaw   += dy;
        pitch += dp;
        pitch  = std::max(-1.48f,std::min(1.48f,pitch));
        // Dynamic angular roll tilt on high-speed mouse turns
        target_roll -= dy * 0.022f;
        target_roll  = std::max(-0.065f, std::min(0.065f, target_roll));
    }

    /**
     * Authoritative Ground Elevation at (x, z):
     * Samples the natural continuous OpenVDB island geomorphology + solid voxel blocks.
     */
    static float getGroundHeight(float x, float z, float cur_y, const Island::VoxelIsland& isl) {
        float h_geo = isl.getIslandHeight(x, z);

        int ix = (int)std::floor(x);
        int iz = (int)std::floor(z);
        float h_vox = -999.0f;

        if (isl.inBounds(ix, 0, iz)) {
            int search_top = std::min(isl.dim_y - 1, (int)std::ceil(std::max(cur_y + 1.8f, h_geo + 2.0f)));
            int search_bot = std::max(0, (int)std::floor(std::min(cur_y - 4.0f, h_geo - 2.0f)));

            for (int y = search_top; y >= search_bot; --y) {
                uint16_t v = isl.getVoxel(ix, y, iz);
                if (v != Material::MAT_AIR && v != Material::MAT_WATER && v != Material::MAT_FOLIAGE &&
                    v != Material::MAT_FERN && v != Material::MAT_SHRUB && v != Material::MAT_ASH) {
                    const auto& mat = Material::MaterialRegistry::instance().get(v);
                    if (mat.is_solid) {
                        h_vox = float(y + 1);
                        break;
                    }
                }
            }
        }
        return std::max(h_geo, h_vox);
    }

    /**
     * Checks if a solid vertical obstacle (e.g. tree trunk, bedrock wall) blocks horizontal movement.
     */
    static bool isHorizontalBlocked(float x, float y, float z, float radius, const Island::VoxelIsland& isl) {
        float offsets[4][2] = {
            {0.0f, 0.0f},
            {radius * 0.7f, 0.0f},
            {-radius * 0.7f, 0.0f},
            {0.0f, radius * 0.7f}
        };

        for (int i = 0; i < 4; ++i) {
            float cx = x + offsets[i][0];
            float cz = z + offsets[i][1];
            int ix = (int)std::floor(cx);
            int iz = (int)std::floor(cz);

            for (float h_off : {0.8f, 1.4f}) {
                int iy = (int)std::floor(y + h_off);
                if (isl.inBounds(ix, iy, iz)) {
                    uint16_t v = isl.getVoxel(ix, iy, iz);
                    if (v == Material::MAT_WOOD || v == Material::MAT_PALM || v == Material::MAT_BEDROCK) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    void update(float dt, bool fwd, bool back, bool left, bool right,
                bool jump_key, bool sprint_key, bool slide_key,
                const Island::VoxelIsland& isl,
                float ocean_wave_height = 9.0f)
    {
        dt = std::min(dt, 0.05f);

        // Edge detection for jump input & jump buffering
        bool jump_edge = jump_key && !prev_jump_input;
        prev_jump_input = jump_key;

        if (jump_edge) {
            jump_buffer = 0.15f; // Buffer jump for 150ms
        } else if (jump_buffer > 0.0f) {
            jump_buffer -= dt;
        }

        // Water check: submerged under Gerstner ocean waves or in water voxel
        int ex = (int)position.x, ey = (int)(position.y + 0.6f), ez = (int)position.z;
        in_water = (isl.getVoxel(ex, ey, ez) == Material::MAT_WATER) || (position.y < ocean_wave_height - 0.2f);

        // ── 1. Horizontal Wish Direction & Speed Setup ────────────────────────
        Spatial::Vector3D wish_dir(0, 0, 0);
        if (fwd)   wish_dir += getHorizFwd();
        if (back)  wish_dir -= getHorizFwd();
        if (right) wish_dir += getRight();
        if (left)  wish_dir -= getRight();

        bool has_wish_input = wish_dir.lengthSq() > 1e-4f;
        if (has_wish_input) {
            wish_dir = wish_dir.normalized();
        }

        // Slide State Machine
        float horiz_speed = std::sqrt(velocity.x * velocity.x + velocity.z * velocity.z);
        if (is_grounded && sprint_key && slide_key && !is_sliding && horiz_speed > 3.0f) {
            is_sliding = true;
            slide_timer = 1.4f;
            // Kinetic slide launch kick
            velocity.x += wish_dir.x * 1.9f;
            velocity.z += wish_dir.z * 1.9f;
            triggerHeadShake(0.04f);
        }

        if (is_sliding) {
            slide_timer -= dt;
            if (slide_timer <= 0.0f || horiz_speed < 1.6f || !slide_key) {
                is_sliding = false;
            }
        }

        // Target target speed
        float target_speed = walk_speed;
        if (is_sliding) {
            target_speed = sprint_speed + 1.0f;
        } else if (sprint_key && has_wish_input) {
            target_speed = sprint_speed;
        } else if (slide_key) {
            target_speed = crouch_speed;
        }

        if (in_water) target_speed *= 0.65f;

        // ── 2. Professional Acceleration, Friction & Air Strafe Dynamics ──────
        if (is_grounded) {
            coyote_timer = 0.18f; // Reset coyote timer (180ms)
            can_double_jump = true;

            if (is_sliding) {
                // Low friction slide + downhill slope gravity acceleration
                float h_center = isl.getIslandHeight(position.x, position.z);
                float h_dx = isl.getIslandHeight(position.x + 0.5f, position.z) - isl.getIslandHeight(position.x - 0.5f, position.z);
                float h_dz = isl.getIslandHeight(position.x, position.z + 0.5f) - isl.getIslandHeight(position.x, position.z - 0.5f);
                
                // Downhill acceleration vector
                velocity.x += -h_dx * 9.0f * dt;
                velocity.z += -h_dz * 9.0f * dt;

                // Slide friction
                float friction_factor = std::max(0.0f, 1.0f - slide_friction * dt);
                velocity.x *= friction_factor;
                velocity.z *= friction_factor;
            } else if (has_wish_input) {
                // Ground Acceleration toward wish velocity
                Spatial::Vector3D target_vel = wish_dir * target_speed;
                float blend = std::min(1.0f, ground_accel * dt);
                velocity.x += (target_vel.x - velocity.x) * blend;
                velocity.z += (target_vel.z - velocity.z) * blend;
            } else {
                // Ground Friction Braking
                float friction_factor = std::max(0.0f, 1.0f - ground_friction * dt);
                velocity.x *= friction_factor;
                velocity.z *= friction_factor;
            }
        } else {
            // Airborne: Source-style Air-Strafing and low air-drag momentum preservation
            coyote_timer = std::max(0.0f, coyote_timer - dt);

            if (has_wish_input) {
                float current_proj = velocity.x * wish_dir.x + velocity.z * wish_dir.z;
                float add_speed = std::max(0.0f, air_speed_cap - current_proj);
                float accel_speed = std::min(add_speed, air_accel * target_speed * dt);

                velocity.x += wish_dir.x * accel_speed;
                velocity.z += wish_dir.z * accel_speed;
            }

            // Minimal air drag (0.15s^-1)
            float air_drag = std::max(0.0f, 1.0f - 0.15f * dt);
            velocity.x *= air_drag;
            velocity.z *= air_drag;
        }

        // Head-tilt roll on lateral strafe / high-speed turns
        float lateral_speed = velocity.x * getRight().x + velocity.z * getRight().z;
        float strafe_tilt = -lateral_speed * 0.0070f;
        target_roll = strafe_tilt;
        roll += (target_roll - roll) * std::min(1.0f, dt * 10.0f);

        // ── 3. Smooth Step-Climbing & Terrain Traversal ────────────────────────
        // ── 3. Smooth Step-Climbing, Mantling & Terrain Traversal ───────────────
        const float max_step_up = 0.65f; // Scaled auto-step height
        float cur_ground = getGroundHeight(position.x, position.z, position.y, isl);

        // X movement
        float nx = position.x + velocity.x * dt;
        float gx = getGroundHeight(nx, position.z, position.y, isl);
        bool can_move_x = is_grounded ? ((gx - cur_ground) <= max_step_up) : (position.y + 0.35f >= gx);
        if (can_move_x && !isHorizontalBlocked(nx, position.y, position.z, player_radius, isl)) {
            position.x = nx;
            cur_ground = gx;
            if (is_grounded) {
                position.y = gx;
            } else if (position.y < gx) {
                position.y = gx; // Mantle onto rock ledge
            }
        } else {
            velocity.x = 0.0f;
        }

        // Z movement
        float nz = position.z + velocity.z * dt;
        float gz = getGroundHeight(position.x, nz, position.y, isl);
        bool can_move_z = is_grounded ? ((gz - cur_ground) <= max_step_up) : (position.y + 0.35f >= gz);
        if (can_move_z && !isHorizontalBlocked(position.x, position.y, nz, player_radius, isl)) {
            position.z = nz;
            cur_ground = gz;
            if (is_grounded) {
                position.y = gz;
            } else if (position.y < gz) {
                position.y = gz; // Mantle onto rock ledge
            }
        } else {
            velocity.z = 0.0f;
        }

        // ── 4. Vertical Dynamics, Double-Jump & Ground Physics ─────────────────
        prev_vy = velocity.y;
        float final_ground = getGroundHeight(position.x, position.z, position.y, isl);

        if (in_water) {
            can_double_jump = true;
            is_grounded = false;
            velocity.y *= 0.85f;
            float depth = ocean_wave_height - position.y;
            float buoyancy = std::max(-1.25f, std::min(4.5f, (depth - 0.2f) * 7.5f));
            velocity.y += buoyancy * dt;

            if (jump_key) {
                if (position.y >= ocean_wave_height - 0.25f && jump_edge) {
                    velocity.y = jump_velocity; // Surface water exit leap!
                    is_grounded = false;
                    jump_buffer = 0.0f;
                    can_double_jump = true;
                } else {
                    velocity.y = 2.9f; // Swimming ascent (scaled)
                }
            }
            position.y += velocity.y * dt;

            if (position.y < final_ground) {
                position.y = final_ground;
                velocity.y = 0.0f;
                is_grounded = true;
            }
        } else {
            // Jump execution: Primary Jump (with Coyote Time) vs Double Jump
            if (jump_buffer > 0.0f) {
                if (is_grounded || coyote_timer > 0.0f) {
                    // Primary Jump
                    velocity.y = jump_velocity;
                    is_grounded = false;
                    coyote_timer = 0.0f;
                    jump_buffer = 0.0f;
                    can_double_jump = true;
                    position.y += 0.04f;
                    triggerHeadShake(0.030f);
                    landing_spring_vel -= 0.3f;
                } else if (can_double_jump) {
                    // Kinetic Double Jump (Mid-Air Thrust Launch)
                    velocity.y = double_jump_velocity;
                    can_double_jump = false;
                    jump_buffer = 0.0f;

                    // Directional kinetic thrust boost
                    Spatial::Vector3D boost_dir = has_wish_input ? wish_dir : getHorizFwd();
                    velocity.x += boost_dir.x * double_jump_thrust;
                    velocity.z += boost_dir.z * double_jump_thrust;

                    triggerHeadShake(0.065f);
                    double_jump_fx = 1.0f;
                    landing_spring_vel -= 0.6f; // Visual spring bounce
                }
            }

            if (!is_grounded) {
                // Natural Trajectory Curve with Apex Float & Kinetic Descent (Scaled for 1/2 gravity)
                float eff_gravity = gravity;
                if (std::abs(velocity.y) < 1.6f) {
                    eff_gravity = gravity * 0.65f; // Apex float / natural crest hang-time
                } else if (velocity.y > 1.6f) {
                    eff_gravity = jump_key ? (gravity * 0.90f) : (gravity * 1.55f); // Variable jump ascent
                } else {
                    eff_gravity = gravity * 1.25f; // Kinetic, weighted downward descent
                }

                velocity.y += eff_gravity * dt;
                velocity.y = std::max(velocity.y, -18.0f);
                position.y += velocity.y * dt;

                if (position.y <= final_ground) {
                    position.y = final_ground;
                    // Landing Impact absorption with 2nd-order spring
                    if (prev_vy < -2.0f) {
                        float impact = std::min(0.6f, std::abs(prev_vy) * 0.045f);
                        landing_spring_vel += impact * 8.0f;
                        triggerHeadShake(std::min(0.12f, std::abs(prev_vy) * 0.007f));
                    }
                    velocity.y = 0.0f;
                    is_grounded = true;
                }
            } else {
                // Grounded: Stick to surface or detect drop-off
                float h_diff = final_ground - position.y;
                if (h_diff > -0.45f && h_diff <= max_step_up) {
                    position.y = final_ground;
                    velocity.y = 0.0f;
                    is_grounded = true;
                } else if (h_diff < -0.45f) {
                    is_grounded = false; // Walked off a ridge
                } else {
                    position.y = final_ground;
                    velocity.y = 0.0f;
                }
            }
        }

        // ── 5. 2nd-Order Critically Damped Harmonic Spring Camera Dynamics ────
        // A. Dynamic Eye Height (Standing vs Sliding / Crouching)
        float target_eh = is_sliding ? eye_height_sliding : eye_height_standing;
        float eh_force = (target_eh - current_eye_height) * 120.0f - eye_height_velocity * 22.0f;
        eye_height_velocity += eh_force * dt;
        current_eye_height += eye_height_velocity * dt;

        // B. Landing Spring Oscillator (m*y'' + c*y' + k*y = 0)
        float spring_force = -landing_spring_disp * 140.0f - landing_spring_vel * 18.0f;
        landing_spring_vel += spring_force * dt;
        landing_spring_disp += landing_spring_vel * dt;
        landing_spring_disp = std::max(-0.125f, std::min(0.20f, landing_spring_disp));

        // C. Smooth Vertical Elevation Blend
        float target_eye_y = position.y + current_eye_height;
        if (std::abs(smooth_eye_y - target_eye_y) > 6.0f) {
            smooth_eye_y = target_eye_y; // Spawn snap
        } else {
            float blend_rate = is_grounded ? 20.0f : 24.0f;
            smooth_eye_y += (target_eye_y - smooth_eye_y) * std::min(1.0f, dt * blend_rate);
        }

        // ── 6. Natural Figure-8 Lissajous View Bobbing ────────────────────────
        if (has_wish_input && is_grounded && !in_water && !is_sliding) {
            float speed_ratio = std::min(1.5f, horiz_speed / walk_speed);
            float bob_freq = 8.5f * speed_ratio;
            head_bob_time += dt * bob_freq;

            float intensity = sprint_key ? 0.012f : 0.007f;
            head_bob_y = std::sin(head_bob_time * 2.0f) * intensity;
            head_bob_x = std::cos(head_bob_time) * intensity * 0.75f;
            head_bob_tilt = std::sin(head_bob_time) * intensity * 0.50f;
        } else {
            float decay = std::max(0.0f, 1.0f - dt * 10.0f);
            head_bob_x *= decay;
            head_bob_y *= decay;
            head_bob_tilt *= decay;
        }

        // Thoracic breathing & micro camera shake decay
        breathing_phase += dt * (in_water ? 1.0f : 1.4f);
        if (shake_intensity > 1e-4f) {
            shake_timer += dt;
            shake_intensity = std::max(0.0f, shake_intensity - 9.0f * dt);
            shake_offset_x = shake_intensity * std::sin(shake_timer * 22.0f * 1.35f) * 0.04f;
            shake_offset_y = shake_intensity * std::cos(shake_timer * 22.0f) * 0.04f;
            shake_rot_pitch = shake_intensity * std::sin(shake_timer * 22.0f * 0.88f) * 0.05f;
            shake_rot_yaw = shake_intensity * std::cos(shake_timer * 22.0f * 1.12f) * 0.04f;
        } else {
            shake_intensity = shake_offset_x = shake_offset_y = shake_rot_pitch = shake_rot_yaw = 0.0f;
        }
    }

    IslandRayHit castRay(const Island::VoxelIsland& isl, float maxd = 14.f) const {
        IslandRayHit r;
        auto eye = getEyePosition();
        auto dir = getForward();
        int x = (int)std::floor(eye.x), y = (int)std::floor(eye.y), z = (int)std::floor(eye.z);
        int sx = dir.x >= 0 ? 1 : -1, sy = dir.y >= 0 ? 1 : -1, sz = dir.z >= 0 ? 1 : -1;
        float tdx = dir.x != 0 ? std::abs(1.f / dir.x) : 1e30f;
        float tdy = dir.y != 0 ? std::abs(1.f / dir.y) : 1e30f;
        float tdz = dir.z != 0 ? std::abs(1.f / dir.z) : 1e30f;
        float tmx = sx > 0 ? (x + 1.f - eye.x) * tdx : (eye.x - x) * tdx;
        float tmy = sy > 0 ? (y + 1.f - eye.y) * tdy : (eye.y - y) * tdy;
        float tmz = sz > 0 ? (z + 1.f - eye.z) * tdz : (eye.z - z) * tdz;
        float dist = 0; Spatial::Vector3D norm(0, 0, 0);
        while (dist < maxd) {
            uint16_t v = isl.getVoxel(x, y, z);
            if (isl.isSolid(x, y, z) || v == Material::MAT_WATER || v == Material::MAT_LAVA) {
                r.hit = true; r.vx = x; r.vy = y; r.vz = z; r.material_code = v; r.distance = dist;
                r.normal = norm; r.hit_point = {eye.x + dir.x * dist, eye.y + dir.y * dist, eye.z + dir.z * dist};
                r.place_coord = {x + (int)norm.x, y + (int)norm.y, z + (int)norm.z};
                return r;
            }
            if (tmx < tmy) {
                if (tmx < tmz) { dist = tmx; tmx += tdx; x += sx; norm = {float(-sx), 0, 0}; }
                else { dist = tmz; tmz += tdz; z += sz; norm = {0, 0, float(-sz)}; }
            } else {
                if (tmy < tmz) { dist = tmy; tmy += tdy; y += sy; norm = {0, float(-sy), 0}; }
                else { dist = tmz; tmz += tdz; z += sz; norm = {0, 0, float(-sz)}; }
            }
        }
        return r;
    }
};

} // namespace SCR::IslandController

// ─── Application ────────────────────────────────────────────────────────────
class VolcanicIslandApp : public ApplicationContext, public InputListener {
public:
    SceneManager*  scnMgr     = nullptr;
    Camera*        cam        = nullptr;
    SceneNode*     camNode    = nullptr;
    Light*         sunLight   = nullptr;
    Light*         caldGlow   = nullptr;
    Light*         headlamp   = nullptr;
    ManualObject*  islandMesh = nullptr;
    SceneNode*     islandNode = nullptr;
    ManualObject*  oceanMesh  = nullptr;
    SceneNode*     oceanNode  = nullptr;
    ManualObject*  skyMesh    = nullptr;
    SceneNode*     skyNode    = nullptr;
    ManualObject*  lavaMesh   = nullptr;
    SceneNode*     lavaNode   = nullptr;
    ManualObject*  smokeMesh  = nullptr;
    SceneNode*     smokeNode  = nullptr;
    ManualObject*  vegMesh    = nullptr;
    SceneNode*     vegNode    = nullptr;
    ManualObject*  boidMesh   = nullptr;
    SceneNode*     boidNode   = nullptr;
    ManualObject*  hudMesh    = nullptr;
    SceneNode*     hudNode    = nullptr;
    ManualObject*  parallaxMesh = nullptr;
    SceneNode*     parallaxNode = nullptr;

    static constexpr size_t NUM_FIREFLY_LIGHTS = 6;
    std::vector<Light*>     firefly_lights;
    std::vector<SceneNode*> firefly_nodes;

    std::unique_ptr<Island::VoxelIsland>           island;
    std::unique_ptr<IslandController::IslandPlayer> player;
    std::unique_ptr<WFC::HierarchicalSolver>        wfc_solver;  // holds biome map for HUD

    SCR::HUD::IslandHUD hud;
    SCR::Ocean::SeaOfThievesWater ocean;
    SCR::Sky::VolumetricAtmosphere sky_system;
    SCR::Atmosphere::HorizonPlanetParallaxSystem parallax_system;
    SCR::Volcano::VolcanicLavaFlow   lava_system;
    SCR::Volcano::VolcanicSmokePlume smoke_system;
    SCR::Vegetation::IslandVegetationSystem veg_system;
    SCR::Boids::MultiSpeciesBoidSystem boid_system;
    std::unique_ptr<SCR::VDB::VdbChunkManager> chunk_manager;

    // Embedded 3D Linux Wayland Compositor Display
    SCR::Display::InWorldDisplaySystem wayland_display;
    ManualObject* displayMesh = nullptr;
    SceneNode*    displayNode = nullptr;
    bool screen_focused = false;
    float screen_u = 0.5f, screen_v = 0.5f;

    // ImGui overlay & input chain
    Ogre::ImGuiOverlay*          imgui_overlay  = nullptr;
    OgreBites::ImGuiInputListener* imgui_input  = nullptr;
    OgreBites::InputListenerChain  input_chain;

    enum MeshMode { MESH_SMOOTH, MESH_VOXEL } mesh_mode = MESH_SMOOTH;

    uint16_t hotbar_mat = Material::MAT_BASALT;

    bool key_w=0,key_s=0,key_a=0,key_d=0,key_space=0,key_shift=0,key_alt=0,key_ctrl=0,key_c=0;
    float hud_alpha = 0.0f;

    float hud_timer=0,fps_acc=0;
    int   frame_cnt=0, total_frames=0;

    // ── Logging ───────────────────────────────────────────────────────────────
    std::ofstream log_file;

    void logLine(const std::string& msg){
        std::cout << msg << std::endl;
        if(log_file.is_open()) log_file << msg << "\n" << std::flush;
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    VolcanicIslandApp() : ApplicationContext("SCR_VolcanicIslandExplorer"),
                          input_chain(std::vector<OgreBites::InputListener*>{}) {}

    NativeWindowPair createWindow(const String& name, uint32_t w = 0, uint32_t h = 0, NameValuePairList miscParams = NameValuePairList()) override {
        uint32_t target_w = (w > 0) ? w : 1920;
        uint32_t target_h = (h > 0) ? h : 1080;
        miscParams["title"] = "SCR Volcanic Island Explorer (OpenVDB + OGRE 3D + ImGui HUD)";
        return ApplicationContext::createWindow(name, target_w, target_h, miscParams);
    }

    void setup() override {
        ApplicationContext::setup();

        // ── ImGui overlay init ─────────────────────────────────────────────────
        imgui_overlay = initialiseImGui();
        if(!imgui_overlay) {
            imgui_overlay = new Ogre::ImGuiOverlay();
            imgui_overlay->setZOrder(300);
            imgui_overlay->show();
            auto* ovl_mgr = Ogre::OverlayManager::getSingletonPtr();
            if(ovl_mgr) ovl_mgr->addOverlay(imgui_overlay);
        }

        // Ensure ImGui IO DisplaySize and Font Atlas are built immediately
        ImGuiIO& io = ImGui::GetIO();
        io.DisplaySize = ImVec2(1920.0f, 1080.0f);
        io.DeltaTime = 1.0f / 60.0f;
        if (io.Fonts->Fonts.empty()) {
            io.Fonts->AddFontDefault();
        }
        if (!io.Fonts->IsBuilt()) {
            unsigned char* pixels = nullptr;
            int width = 0, height = 0;
            io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);
        }

        if(getImGuiInputListener()) {
            input_chain = OgreBites::InputListenerChain({getImGuiInputListener(), this});
            addInputListener(&input_chain);
        } else {
            imgui_input = new OgreBites::ImGuiInputListener();
            input_chain = OgreBites::InputListenerChain({imgui_input, this});
            addInputListener(&input_chain);
        }

        // Persistent log
        log_file.open("applications/cave/island_explorer.log", std::ios::app);
        auto now=std::chrono::system_clock::now();
        auto t=std::chrono::system_clock::to_time_t(now);
        if(log_file.is_open()) log_file << "\n\n=== SESSION " << std::ctime(&t);

        if(getRenderWindow()) getRenderWindow()->resize(1920, 1080);

        auto* root=getRoot();
        scnMgr=root->createSceneManager();
        auto* sg=RTShader::ShaderGenerator::getSingletonPtr();
        if(sg) sg->addSceneManager(scnMgr);
        if(getOverlaySystem()) scnMgr->addRenderQueueListener(getOverlaySystem());

        // ── Tropical atmosphere ────────────────────────────────────────────────
        scnMgr->setAmbientLight(ColourValue(.28f,.34f,.42f));
        scnMgr->setFog(FOG_EXP2, ColourValue(.62f,.80f,.95f), 0.008f);

        logLine("\n================================================================================");
        logLine(" SCR Volcanic Island Explorer — OpenVDB Natural Isosurface & Semantic Flora");
        logLine("================================================================================");

        // ── Island generation ─────────────────────────────────────────────────
        island = std::make_unique<Island::VoxelIsland>(320,64,320);
        logLine("Generating procedural volcanic island (320x64x320 = 6,553,600 voxels)...");
        island->generateProceduralIsland(1337);

        // ── WFC biome solve for HUD minimap ──────────────────────────────────
        wfc_solver = std::make_unique<WFC::HierarchicalSolver>(island->dim_x, island->dim_z, 8);
        wfc_solver->solveBiomes(
            island->center_x, island->center_z,
            island->island_radius, island->caldera_radius,
            [&](int x,int z){
                float dx=float(x)-island->center_x, dz=float(z)-island->center_z;
                float r=std::sqrt(dx*dx+dz*dz);
                float th=std::atan2(dz,dx);
                float ad=std::abs(th-Island::VoxelIsland::RIVER_ANGLE);
                if(ad>3.14159f) ad=6.28318f-ad;
                return r<island->island_radius*.95f && r*ad<4.5f;
            }, 1337);
        // Feature layer (uses flora noise)
        wfc_solver->solveFeatures(
            [&](float x,float z){ return island->noise_flora.noise(x*.28f,0.f,z*.28f); }, 1337);

        // ── Player spawn on panoramic south beach ─────────────────────────────
        auto spawn=island->findBeachSpawnPosition();
        player=std::make_unique<IslandController::IslandPlayer>(spawn);
        float to_center_x = island->center_x - spawn.x;
        float to_center_z = island->center_z - spawn.z;
        player->yaw = std::atan2(-to_center_x, -to_center_z); // Face directly toward volcano center
        player->pitch = 0.14f; // Scenic elevation framing the volcano summit, lava and billowing smoke

        std::ostringstream ss;
        ss << "Player spawned at: (" << spawn.x << ", " << spawn.y << ", " << spawn.z << ") with panoramic vista of volcano.";
        logLine(ss.str());

        // ── HUD init (after island + WFC ready) ──────────────────────────────
        hud.init(scnMgr, *island, *wfc_solver);
        logLine("[HUD] Vector HUD overlay initialised — minimap + material inspector active.");

        // ── 2D Vector HUD ManualObject ────────────────────────────────────────
        hudMesh = scnMgr->createManualObject("IslandHUDMeshObj");
        hudMesh->setDynamic(true);
        hudMesh->setRenderQueueGroup(RENDER_QUEUE_OVERLAY);
        hudMesh->setUseIdentityProjection(true);
        hudMesh->setUseIdentityView(true);
        hudNode = scnMgr->getRootSceneNode()->createChildSceneNode("IslandHUDNode");
        hudNode->attachObject(hudMesh);

        // ── Camera ────────────────────────────────────────────────────────────
        cam=scnMgr->createCamera("IslandCam");
        cam->setNearClipDistance(0.05f);
        cam->setFarClipDistance(12000.f);
        cam->setAutoAspectRatio(true);
        camNode=scnMgr->getRootSceneNode()->createChildSceneNode("IslandCamNode");
        camNode->attachObject(cam);

        auto* vp=getRenderWindow()->addViewport(cam);
        vp->setBackgroundColour(ColourValue(.55f,.75f,.98f));

        // ── Lighting ─────────────────────────────────────────────────────────
        // Tropical sunlight (warm golden)
        sunLight=scnMgr->createLight("TropicalSun");
        sunLight->setType(Light::LT_DIRECTIONAL);
        sunLight->setDiffuseColour(ColourValue(1.f,.95f,.82f));
        sunLight->setSpecularColour(ColourValue(1.f,.98f,.90f));
        auto* sunNode=scnMgr->getRootSceneNode()->createChildSceneNode("SunNode");
        sunNode->setDirection(Vector3(-.4f,-1.f,-.6f).normalisedCopy());
        sunNode->attachObject(sunLight);

        // Caldera magma glow (deep orange, positioned above summit)
        caldGlow=scnMgr->createLight("CalderaGlow");
        caldGlow->setType(Light::LT_POINT);
        caldGlow->setDiffuseColour(ColourValue(1.f,.32f,.05f));
        caldGlow->setSpecularColour(ColourValue(1.f,.20f,0.f));
        caldGlow->setAttenuation(55.f,1.f,.055f,.025f);
        auto* cgNode=scnMgr->getRootSceneNode()->createChildSceneNode("CalderaGlowNode");
        cgNode->setPosition(island->center_x, island->peak_height+3.f, island->center_z);
        cgNode->attachObject(caldGlow);

        // Player headlamp (torch)
        headlamp=scnMgr->createLight("PlayerLamp");
        headlamp->setType(Light::LT_SPOTLIGHT);
        headlamp->setDiffuseColour(ColourValue(1.f,.95f,.85f));
        headlamp->setSpecularColour(ColourValue(1.f,1.f,1.f));
        headlamp->setSpotlightRange(Degree(28),Degree(55));
        headlamp->setAttenuation(60.f,1.f,.055f,.02f);
        camNode->attachObject(headlamp);

        // Nocturnal Bioluminescent Firefly Point Lights
        firefly_lights.clear();
        firefly_nodes.clear();
        for(size_t i = 0; i < NUM_FIREFLY_LIGHTS; ++i) {
            std::string name = "FireflyLight_" + std::to_string(i);
            Light* fl = scnMgr->createLight(name);
            fl->setType(Light::LT_POINT);
            fl->setDiffuseColour(ColourValue(0.25f, 1.0f, 0.40f));
            fl->setSpecularColour(ColourValue(1.0f, 0.95f, 0.35f));
            fl->setAttenuation(32.0f, 1.0f, 0.09f, 0.04f);
            fl->setVisible(false);

            SceneNode* fn = scnMgr->getRootSceneNode()->createChildSceneNode(name + "Node");
            fn->attachObject(fl);
            firefly_lights.push_back(fl);
            firefly_nodes.push_back(fn);
        }

        // ── Materials ─────────────────────────────────────────────────────────
        setupMaterials();

        // ── Meshes ────────────────────────────────────────────────────────────
        rebuildSkyMesh();
        rebuildParallaxMesh();
        rebuildIslandMesh();
        rebuildVegetationMesh();
        rebuildBoidMesh();
        rebuildLavaMesh();
        rebuildSmokeMesh();
        rebuildOceanMesh();

        // ── Embedded 3D Linux Wayland Compositor & In-World Screen ───────────
        Wayland::WaylandCompositor::get().initialize("wayland-scr-0");
        Vector3 screen_anchor(124.0f, 15.0f, 10.0f);
        Vector3 look_origin(124.0f, 15.0f, 12.0f);
        wayland_display.initialize(scnMgr, screen_anchor, look_origin);
        wayland_display.is_visible = false;

        displayMesh = scnMgr->createManualObject("WaylandDisplayMeshObj");
        displayMesh->setDynamic(true);
        wayland_display.update(displayMesh, 0.0f, Wayland::WaylandCompositor::get());
        displayNode = scnMgr->getRootSceneNode()->createChildSceneNode("WaylandDisplayNode");
        displayNode->attachObject(displayMesh);
        displayNode->setVisible(false);

        // ── Initial time of day (Celestial Night with Spherical Moon, Stars, Nebula & Fireflies) ──
        sky_system.setTimeOfDay(21.0f);
        player->pitch = 0.36f;
        player->yaw = std::atan2(-sky_system.moon_direction.x, -sky_system.moon_direction.z);

        // ── Update camera pose ────────────────────────────────────────────────
        updateCameraPose();

        setWindowGrab(true);

        logLine("\n[Controls]:");
        logLine("  WASD / Mouse : Move & Look");
        logLine("  SPACE        : Jump / Swim");
        logLine("  LSHIFT       : Sprint");
        logLine("  ALT          : Hold to show Tactical Vector HUD & Material Telemetry");
        logLine("  L            : Cycle Liquid Method (NVJOB Fast Dual-Flow / Gerstner / Cel-Shaded / Glass)");
        logLine("  [ / ]        : Time of Day (Dawn / Noon / Sunset / Starry Night)");
        logLine("  C            : Cycle Cloud Layer Preset (RDR2 Cumulus / Sunset / Ash Storm / Clear)");
        logLine("  F12 / P      : Screenshot");
        logLine("  LMB          : Mine / Excavate");
        logLine("  RMB          : Place material");
        logLine("  1..9         : Hotbar (Basalt,Sand,Foliage,Bamboo,Obsidian,Sulfur,Ash,Lava,Water)");
        logLine("  M            : Toggle Mesh (OpenVDB Natural / Voxel Blocks)");
        logLine("  T            : STC Thermodynamic reaction step (Lava+Water=Obsidian)");
        logLine("  R            : Regenerate island");
        logLine("  H            : Test head-shake");
        logLine("  ESC          : Exit");
        logLine("================================================================================\n");
    }

    void setupMaterials(){
        auto mm=MaterialManager::getSingletonPtr();

        auto make=[&](const std::string& name, bool transp=false){
            if(mm->getByName(name)) return;
            MaterialPtr m=mm->create(name,ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSpecular(.35f,.35f,.35f,1.f);
            p->setShininess(32.f);
            p->setShadingMode(SO_PHONG);
            p->setCullingMode(CULL_NONE); // Double-sided rendering so terrain and geometry are visible from any angle
            if(transp){
                p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
                p->setDepthWriteEnabled(false);
            }
        };

        make("SCR/VolcanicIslandMaterial");
        make("SCR/DiscreteBlockMaterial");

        // Initialize Cel / Toon Shading System with 4-Tier Diffuse Bands, Specular Hot-Spots & Fresnel Rim
        SCR::Render::CelShadingSystem::initializeCelShading(false);

        if(!mm->getByName("SCR/VolumetricSkyDomeMaterial")){
            MaterialPtr m=mm->create("SCR/VolumetricSkyDomeMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setLightingEnabled(false);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }

        if(!mm->getByName("SCR/VolcanicLavaMaterial")){
            MaterialPtr m=mm->create("SCR/VolcanicLavaMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSelfIllumination(0.35f, 0.12f, 0.02f);
            p->setSpecular(0.6f, 0.4f, 0.1f, 1.0f);
            p->setShininess(32.f);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_PHONG);
            p->setFog(true, FOG_NONE);
        }

        if(!mm->getByName("SCR/VolcanicSmokeMaterial")){
            MaterialPtr m=mm->create("SCR/VolcanicSmokeMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_FLAT);
            p->setFog(true, FOG_NONE);
        }

        if(!mm->getByName("SCR/OceanWaterMaterial")){
            MaterialPtr m=mm->create("SCR/OceanWaterMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }

        if(!mm->getByName("SCR/VegetationMaterial")){
            MaterialPtr m=mm->create("SCR/VegetationMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSpecular(0.2f, 0.35f, 0.15f, 1.0f);
            p->setShininess(16.f);
            p->setShadingMode(SO_PHONG);
            p->setCullingMode(CULL_NONE);
        }

        if(!mm->getByName("SCR/BoidSpeciesMaterial")){
            MaterialPtr m=mm->create("SCR/BoidSpeciesMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT|TVC_EMISSIVE);
            p->setAmbient(0.4f, 0.4f, 0.4f);
            p->setSpecular(0.6f, 0.6f, 0.6f, 1.0f);
            p->setShininess(32.f);
            p->setShadingMode(SO_GOURAUD);
            p->setCullingMode(CULL_NONE);
        }

        if(!mm->getByName("SCR/HUDMaterial")){
            MaterialPtr m=mm->create("SCR/HUDMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setLightingEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_FLAT);
            p->setFog(true, FOG_NONE);
        }

        if(!mm->getByName("SCR/HorizonParallaxMaterial")){
            MaterialPtr m=mm->create("SCR/HorizonParallaxMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p=m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE|TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(true);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }
    }

    void takeScreenshot(const std::string& filename = "applications/cave/island_screenshot.png"){
        if(getRenderWindow()){
            getRenderWindow()->writeContentsToFile(filename);
            logLine("[Screenshot] Captured high-resolution screenshot -> " + filename);
        }
    }

    void rebuildSkyMesh(){
        if(skyMesh){ scnMgr->destroyManualObject(skyMesh); skyMesh=nullptr; }
        if(skyNode){ scnMgr->destroySceneNode(skyNode); skyNode=nullptr; }
        skyMesh=scnMgr->createManualObject("SkyMeshObj");
        skyMesh->setDynamic(true);
        skyMesh->setRenderQueueGroup(RENDER_QUEUE_SKIES_EARLY);
        Spatial::Point3D cam_pos = player ? player->getEyePosition() : Spatial::Point3D(48, 15, 20);
        sky_system.updateSkyDomeMesh(skyMesh, 0.0f, *island, cam_pos);
        skyNode=scnMgr->getRootSceneNode()->createChildSceneNode("SkyNode");
        skyNode->attachObject(skyMesh);
        logLine("[Sky] RDR2-inspired multi-tier volumetric atmosphere dome initialized (24x36 geodesic dome).");
    }

    void rebuildParallaxMesh(){
        if(parallaxMesh){ scnMgr->destroyManualObject(parallaxMesh); parallaxMesh=nullptr; }
        if(parallaxNode){ scnMgr->destroySceneNode(parallaxNode); parallaxNode=nullptr; }
        scnMgr->setFog(Ogre::FOG_EXP, sky_system.horizon_color, 0.00018f, 200.0f, 8000.0f);
    }

    void rebuildIslandMesh(){
        if(islandMesh){ scnMgr->destroyManualObject(islandMesh); islandMesh=nullptr; }
        if(islandNode){ scnMgr->destroySceneNode(islandNode); islandNode=nullptr; }
        if(mesh_mode==MESH_SMOOTH){
            logLine("[Mesh] Dynamic Paged OpenVDB Volumetric Chunks active.");
            if(!chunk_manager) chunk_manager = std::make_unique<SCR::VDB::VdbChunkManager>();
            Spatial::Point3D pos = player ? player->position : Spatial::Point3D(48, 15, 20);
            chunk_manager->clearAllChunks(scnMgr);
            chunk_manager->update(Ogre::Vector3(pos.x, pos.y, pos.z), *island, scnMgr, 0.0f);
        } else {
            if(chunk_manager) chunk_manager->clearAllChunks(scnMgr);
            logLine("[Mesh] Generating discrete voxel island...");
            islandMesh=scnMgr->createManualObject("IslandMeshObj");
            islandMesh->setDynamic(true);
            VDB::VdbIslandMesher::buildDiscreteIslandMesh(islandMesh,*island);
            islandNode=scnMgr->getRootSceneNode()->createChildSceneNode("IslandNode");
            islandNode->attachObject(islandMesh);
        }
    }

    void rebuildVegetationMesh(){
        if(vegMesh){ scnMgr->destroyManualObject(vegMesh); vegMesh=nullptr; }
        if(vegNode){ scnMgr->destroySceneNode(vegNode); vegNode=nullptr; }
        vegMesh=scnMgr->createManualObject("VegetationMeshObj");
        vegMesh->setDynamic(true);
        veg_system.populateIsland(*island, *wfc_solver);
        veg_system.updateVegetationMesh(vegMesh, 0.0f);
        vegNode=scnMgr->getRootSceneNode()->createChildSceneNode("VegetationNode");
        vegNode->attachObject(vegMesh);
        logLine("[Vegetation] Procedural flora ecosystem synthesized (palms, canopy trees, slope bushes).");
    }

    void warpToIsland(Island::IslandBiomeType biome) {
        if (!island || !player) return;
        const auto& desc = Island::ArchipelagoRegistry::getDescriptor(biome);
        std::ostringstream ss; ss << "[Archipelago] Setting sail for: " << desc.name << " [" << desc.title_tag << "]";
        logLine(ss.str());

        island->setBiome(biome);
        island->generateProceduralIsland(1337 + (int)biome * 7919);

        if (chunk_manager) {
            chunk_manager->clearAllChunks(scnMgr);
        }

        rebuildVegetationMesh();
        rebuildBoidMesh();

        if (lavaNode) lavaNode->setVisible(biome == Island::IslandBiomeType::VOLCANO);
        if (smokeNode) smokeNode->setVisible(biome == Island::IslandBiomeType::VOLCANO);

        player->position = island->findBeachSpawnPosition();
        player->velocity = Spatial::Vector3D(0, 0, 0);

        if (chunk_manager && scnMgr) {
            chunk_manager->update(Ogre::Vector3(player->position.x, player->position.y, player->position.z), *island, scnMgr, 0.0f);
        }

        std::ostringstream arr_ss; arr_ss << "[Archipelago] Arrived at " << desc.name;
        logLine(arr_ss.str());
    }

    void warpToPartition(Spatial::PartitionType type) {
        if (!island || !player) return;
        switch (type) {
            case Spatial::PartitionType::CALDERA_SUMMIT:
                player->position = Spatial::Point3D(island->center_x, island->peak_height + 2.0f, island->center_z);
                break;
            case Spatial::PartitionType::RAINFOREST_CANOPY:
                player->position = Spatial::Point3D(island->center_x + 90.0f, island->getIslandHeight(island->center_x + 90.0f, island->center_z + 90.0f) + 1.2f, island->center_z + 90.0f);
                break;
            case Spatial::PartitionType::BASALT_CLIFFS:
                player->position = Spatial::Point3D(island->center_x - 90.0f, island->getIslandHeight(island->center_x - 90.0f, island->center_z - 90.0f) + 1.2f, island->center_z - 90.0f);
                break;
            case Spatial::PartitionType::CORAL_LAGOON:
                player->position = Spatial::Point3D(island->center_x + 85.0f, island->sea_level + 0.5f, island->center_z - 85.0f);
                break;
            case Spatial::PartitionType::SUBTERRANEAN_LAVA_TUBES:
                player->position = Spatial::Point3D(island->center_x, 4.0f, island->center_z);
                break;
            case Spatial::PartitionType::DEEP_OCEAN_ABYSS:
                player->position = Spatial::Point3D(island->center_x + 240.0f, island->sea_level + 0.5f, island->center_z + 240.0f);
                break;
            default:
                break;
        }
        player->velocity = Spatial::Vector3D(0, 0, 0);
        if (chunk_manager && scnMgr) {
            chunk_manager->update(Ogre::Vector3(player->position.x, player->position.y, player->position.z), *island, scnMgr, 0.0f);
        }
        std::ostringstream ss; ss << "[Partition] Fast travel -> " << Spatial::SpatialPartitionRegistry::getDescriptor(type).name;
        logLine(ss.str());
    }

    void rebuildBoidMesh(){
        if(boidMesh){ scnMgr->destroyManualObject(boidMesh); boidMesh=nullptr; }
        if(boidNode){ scnMgr->destroySceneNode(boidNode); boidNode=nullptr; }
        boidMesh=scnMgr->createManualObject("BoidMeshObj");
        boidMesh->setDynamic(true);
        boid_system.initialize(*island);
        boid_system.updateBoidMesh(boidMesh, 0.0f, *island);
        boidNode=scnMgr->getRootSceneNode()->createChildSceneNode("BoidNode");
        boidNode->attachObject(boidMesh);
        logLine("[Boids] Multi-species semantic flocking active (terns, tangs, ember moths, 4D luminaries).");
    }

    void rebuildLavaMesh(){
        if(lavaMesh){ scnMgr->destroyManualObject(lavaMesh); lavaMesh=nullptr; }
        if(lavaNode){ scnMgr->destroySceneNode(lavaNode); lavaNode=nullptr; }
        lavaMesh=scnMgr->createManualObject("LavaMeshObj");
        lavaMesh->setDynamic(true);
        lava_system.initRiverPath(*island);
        lava_system.updateLavaMesh(lavaMesh, 0.0f, *island);
        lavaNode=scnMgr->getRootSceneNode()->createChildSceneNode("LavaNode");
        lavaNode->attachObject(lavaMesh);
        logLine("[Lava] Molten cascading lava river initialized (incandescent flow + dynamic crust).");
    }

    void rebuildSmokeMesh(){
        if(smokeMesh){ scnMgr->destroyManualObject(smokeMesh); smokeMesh=nullptr; }
        if(smokeNode){ scnMgr->destroySceneNode(smokeNode); smokeNode=nullptr; }
        smokeMesh=scnMgr->createManualObject("SmokeMeshObj");
        smokeMesh->setDynamic(true);
        smokeMesh->setRenderQueueGroup(RENDER_QUEUE_MAIN + 1);
        smoke_system.updateSmokeMesh(smokeMesh, 0.0f, *island);
        smokeNode=scnMgr->getRootSceneNode()->createChildSceneNode("SmokeNode");
        smokeNode->attachObject(smokeMesh);
        logLine("[Smoke] Volcanic caldera smoke & ash plume initialized (turbulent convective chimney).");
    }

    void rebuildOceanMesh(){
        if(oceanMesh){ scnMgr->destroyManualObject(oceanMesh); oceanMesh=nullptr; }
        if(oceanNode){ scnMgr->destroySceneNode(oceanNode); oceanNode=nullptr; }
        oceanMesh=scnMgr->createManualObject("OceanMeshObj");
        oceanMesh->setDynamic(true);
        oceanMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);

        ocean = SCR::Ocean::SeaOfThievesWater(float(island->sea_level));
        Spatial::Point3D cam_pos = player ? player->getEyePosition() : Spatial::Point3D(48, 15, 20);
        Spatial::Vector3D sun_dir = Spatial::Vector3D(0.4f, 1.0f, 0.6f).normalized();
        ocean.updateOceanMesh(oceanMesh, 0.0f, *island, cam_pos, sun_dir);

        oceanNode=scnMgr->getRootSceneNode()->createChildSceneNode("OceanNode");
        oceanNode->attachObject(oceanMesh);
        logLine("[Ocean] Sea of Thieves multi-spectral dynamic ocean initialized (28,800 wave polygons, 6 Gerstner octaves).");
    }

    void updateCameraPose(){
        if(!player||!camNode) return;
        auto eye=player->getEyePosition();
        camNode->setPosition(eye.x,eye.y,eye.z);
        auto q=player->getEyeOrientation();
        camNode->setOrientation(Quaternion(q.w,q.x,q.y,q.z));
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    bool keyPressed(const KeyboardEvent& e) override {
        if(e.keysym.sym=='w'||e.keysym.sym=='W'||e.keysym.sym==SDLK_UP)    key_w=true;
        if(e.keysym.sym=='s'||e.keysym.sym=='S'||e.keysym.sym==SDLK_DOWN)  key_s=true;
        if(e.keysym.sym=='a'||e.keysym.sym=='A'||e.keysym.sym==SDLK_LEFT)  key_a=true;
        if(e.keysym.sym=='d'||e.keysym.sym=='D'||e.keysym.sym==SDLK_RIGHT) key_d=true;
        if(e.keysym.sym==SDLK_SPACE || e.keysym.sym==' ' || e.keysym.sym==32) key_space=true;
        if(e.keysym.sym==SDLK_LSHIFT)            key_shift=true;
        static constexpr int KEY_LCTRL = (1 << 30) | 0xE0;
        static constexpr int KEY_RCTRL = (1 << 30) | 0xE4;
        if(e.keysym.sym==KEY_LCTRL || e.keysym.sym==KEY_RCTRL || (e.keysym.mod & KMOD_CTRL)) key_ctrl=true;
        if(e.keysym.sym=='c' || e.keysym.sym=='C') key_c=true;
        static constexpr int KEY_LALT = (1 << 30) | 0xE2;
        static constexpr int KEY_RALT = (1 << 30) | 0xE6;
        if(e.keysym.sym==KEY_LALT || e.keysym.sym==KEY_RALT || (e.keysym.mod & KMOD_ALT)) key_alt=true;

        if(e.keysym.sym==SDLK_F12 || e.keysym.sym=='p' || e.keysym.sym=='P'){
            takeScreenshot();
        }

        // ── Unified Function Keys ───────────────────────────────────────────
        if(e.keysym.sym==SDLK_F1){
            logLine("[Wayland] Toggling terminal emulator (F1)...");
            wayland_display.is_visible = !wayland_display.is_visible;
            if (wayland_display.is_visible) {
                Vector3 eye(player->position.x, player->smooth_eye_y, player->position.z);
                float fwd_x = -std::sin(player->yaw) * std::cos(player->pitch);
                float fwd_y =  std::sin(player->pitch);
                float fwd_z = -std::cos(player->yaw) * std::cos(player->pitch);
                wayland_display.summonInFrontOf(eye, Vector3(fwd_x, fwd_y, fwd_z), 2.5f);
                Wayland::WaylandCompositor::get().launchTerminal();
            } else {
                if (displayMesh) displayMesh->clear();
            }
            if (displayNode) displayNode->setVisible(wayland_display.is_visible);
        }
        if(e.keysym.sym==SDLK_F2){
            logLine("[Wayland] Launching interactive demo (F2)...");
            wayland_display.is_visible = true;
            Vector3 eye(player->position.x, player->smooth_eye_y, player->position.z);
            float fwd_x = -std::sin(player->yaw) * std::cos(player->pitch);
            float fwd_y =  std::sin(player->pitch);
            float fwd_z = -std::cos(player->yaw) * std::cos(player->pitch);
            wayland_display.summonInFrontOf(eye, Vector3(fwd_x, fwd_y, fwd_z), 2.5f);
            if (displayNode) displayNode->setVisible(true);
            Wayland::WaylandCompositor::get().launchDemo();
        }
        if(e.keysym.sym==SDLK_F3){
            logLine("[Wayland] Launching text editor (F3)...");
            wayland_display.is_visible = true;
            Vector3 eye(player->position.x, player->smooth_eye_y, player->position.z);
            float fwd_x = -std::sin(player->yaw) * std::cos(player->pitch);
            float fwd_y =  std::sin(player->pitch);
            float fwd_z = -std::cos(player->yaw) * std::cos(player->pitch);
            wayland_display.summonInFrontOf(eye, Vector3(fwd_x, fwd_y, fwd_z), 2.5f);
            if (displayNode) displayNode->setVisible(true);
            Wayland::WaylandCompositor::get().launchEditor();
        }
        if(e.keysym.sym==SDLK_F4){
            logLine("[Wayland] Closing active clients (F4)...");
            wayland_display.is_visible = false;
            if (displayMesh) displayMesh->clear();
            if (displayNode) displayNode->setVisible(false);
            Wayland::WaylandCompositor::get().closeClients();
        }
        if(e.keysym.sym==SDLK_F5){
            sky_system.cyclePreset();
            logLine(std::string("[Sky] Cloud preset (F5) -> ") + sky_system.getPresetName());
        }
        if(e.keysym.sym==SDLK_F6){
            sky_system.setTimeOfDay(sky_system.time_of_day_hours + 1.0f);
            std::ostringstream ss; ss << "[Sky] Time of day (F6): " << std::fixed << std::setprecision(1) << sky_system.time_of_day_hours << "h";
            logLine(ss.str());
        }
        if(e.keysym.sym==SDLK_F7){
            sky_system.setTimeOfDay(sky_system.time_of_day_hours - 1.0f);
            std::ostringstream ss; ss << "[Sky] Time of day (F7): " << std::fixed << std::setprecision(1) << sky_system.time_of_day_hours << "h";
            logLine(ss.str());
        }
        if(e.keysym.sym==SDLK_F8){
            if(chunk_manager && island){
                logLine("[Storage] Saving World Partition State to Disk (F8)...");
                chunk_manager->saveWorld(
                    Ogre::Vector3(player->position.x, player->position.y, player->position.z),
                    sky_system.time_of_day_hours, 1337
                );
            }
        }
        if(e.keysym.sym==SDLK_F10){
            mesh_mode=(mesh_mode==MESH_SMOOTH)?MESH_VOXEL:MESH_SMOOTH;
            logLine(std::string("[Mesh] Toggle (F10) -> ")+(mesh_mode==MESH_SMOOTH?"OpenVDB Smooth":"Voxel Blocks"));
            rebuildIslandMesh();
        }

        // ── Alt + Number: Sea of Thieves Archipelago Island Voyages ─────────
        if(key_alt){
            if(e.keysym.sym=='1'){ warpToIsland(Island::IslandBiomeType::VOLCANO); }
            if(e.keysym.sym=='2'){ warpToIsland(Island::IslandBiomeType::JUNGLE); }
            if(e.keysym.sym=='3'){ warpToIsland(Island::IslandBiomeType::DESERT); }
            if(e.keysym.sym=='4'){ warpToIsland(Island::IslandBiomeType::GLACIAL_ICE); }
            if(e.keysym.sym=='5'){ warpToIsland(Island::IslandBiomeType::CORAL_ARCHIPELAGO); }
            if(e.keysym.sym=='6'){ warpToPartition(Spatial::PartitionType::DEEP_OCEAN_ABYSS); }
        }

        if(screen_focused){
            Wayland::WaylandCompositor::get().sendKey(uint32_t(e.keysym.sym & 0xFF), true);
        }

        if(e.keysym.sym=='['){
            sky_system.setTimeOfDay(sky_system.time_of_day_hours - 0.5f);
            std::ostringstream ss; ss << "[Sky] Time of day: " << std::fixed << std::setprecision(1) << sky_system.time_of_day_hours << "h";
            logLine(ss.str());
        }
        if(e.keysym.sym==']'){
            sky_system.setTimeOfDay(sky_system.time_of_day_hours + 0.5f);
            std::ostringstream ss; ss << "[Sky] Time of day: " << std::fixed << std::setprecision(1) << sky_system.time_of_day_hours << "h";
            logLine(ss.str());
        }
        if(e.keysym.sym=='k' || e.keysym.sym=='K'){
            sky_system.cyclePreset();
            logLine(std::string("[Sky] Cloud preset -> ") + sky_system.getPresetName());
        }

        if(e.keysym.sym=='m'||e.keysym.sym=='M'){
            mesh_mode=(mesh_mode==MESH_SMOOTH)?MESH_VOXEL:MESH_SMOOTH;
            logLine(std::string("[Mesh] Toggle -> ")+(mesh_mode==MESH_SMOOTH?"OpenVDB Smooth":"Voxel Blocks"));
            rebuildIslandMesh();
        }
        if(e.keysym.sym=='t'||e.keysym.sym=='T'){
            int n=island->stepSTCReactions();
            std::ostringstream ss; ss<<"[STC] "<<n<<" thermodynamic transitions.";
            logLine(ss.str());
            if(n>0){rebuildIslandMesh();}
        }
        if(e.keysym.sym=='r'||e.keysym.sym=='R'){
            logLine("[Regen] Regenerating volcanic island with new seed...");
            unsigned new_seed=(unsigned)std::chrono::system_clock::now().time_since_epoch().count();
            island->generateProceduralIsland(new_seed);
            rebuildIslandMesh();
            rebuildLavaMesh();
            rebuildSmokeMesh();
            auto sp=island->findBeachSpawnPosition();
            player->position=sp; player->velocity={0,0,0};
            player->yaw=3.14159265f; player->pitch=0.28f;
            // Re-solve WFC for new island geometry
            wfc_solver->solveBiomes(
                island->center_x, island->center_z,
                island->island_radius, island->caldera_radius,
                [&](int x,int z){
                    float dx=float(x)-island->center_x, dz=float(z)-island->center_z;
                    float r=std::sqrt(dx*dx+dz*dz), th=std::atan2(dz,dx);
                    float ad=std::abs(th-Island::VoxelIsland::RIVER_ANGLE);
                    if(ad>3.14159f) ad=6.28318f-ad;
                    return r<island->island_radius*.95f && r*ad<4.5f;
                }, new_seed);
            hud.rebake(*island, *wfc_solver);
        }
        if(e.keysym.sym=='h'||e.keysym.sym=='H'){ player->triggerHeadShake(.16f); logLine("[Micro] Head-shake."); }

        // Hotbar
        if(e.keysym.sym=='1') hotbar_mat=Material::MAT_BASALT;
        if(e.keysym.sym=='2') hotbar_mat=Material::MAT_SAND;
        if(e.keysym.sym=='3') hotbar_mat=Material::MAT_FOLIAGE;
        if(e.keysym.sym=='4') hotbar_mat=Material::MAT_BAMBOO;
        if(e.keysym.sym=='5') hotbar_mat=Material::MAT_OBSIDIAN;
        if(e.keysym.sym=='6') hotbar_mat=Material::MAT_SULFUR;
        if(e.keysym.sym=='7') hotbar_mat=Material::MAT_ASH;
        if(e.keysym.sym=='8') hotbar_mat=Material::MAT_LAVA;
        if(e.keysym.sym=='9') hotbar_mat=Material::MAT_WATER;

        // Liquid Rendering Method Switcher (NVJOB Dual-Flow / Gerstner / Cel-Shaded / Glass)
        if(e.keysym.sym=='l'||e.keysym.sym=='L'){
            ocean.cycleLiquidMethod();
            logLine(std::string("[LiquidSystem] Liquid rendering method -> ") + SCR::Ocean::getLiquidMethodName(ocean.active_method));
        }

        if(e.keysym.sym==SDLK_ESCAPE) getRoot()->queueEndRendering();
        return true;
    }
    bool keyReleased(const KeyboardEvent& e) override {
        static constexpr int KEY_LALT = (1 << 30) | 0xE2;
        static constexpr int KEY_RALT = (1 << 30) | 0xE6;
        if(e.keysym.sym=='w'||e.keysym.sym=='W'||e.keysym.sym==SDLK_UP)    key_w=false;
        if(e.keysym.sym=='s'||e.keysym.sym=='S'||e.keysym.sym==SDLK_DOWN)  key_s=false;
        if(e.keysym.sym=='a'||e.keysym.sym=='A'||e.keysym.sym==SDLK_LEFT)  key_a=false;
        if(e.keysym.sym=='d'||e.keysym.sym=='D'||e.keysym.sym==SDLK_RIGHT) key_d=false;
        if(e.keysym.sym==SDLK_SPACE || e.keysym.sym==' ' || e.keysym.sym==32) key_space=false;
        if(e.keysym.sym==SDLK_LSHIFT)            key_shift=false;
        static constexpr int KEY_LCTRL = (1 << 30) | 0xE0;
        static constexpr int KEY_RCTRL = (1 << 30) | 0xE4;
        if(e.keysym.sym==KEY_LCTRL || e.keysym.sym==KEY_RCTRL) key_ctrl=false;
        if(e.keysym.sym=='c' || e.keysym.sym=='C') key_c=false;
        if(e.keysym.sym==KEY_LALT || e.keysym.sym==KEY_RALT)   key_alt=false;
        if(screen_focused){
            Wayland::WaylandCompositor::get().sendKey(uint32_t(e.keysym.sym & 0xFF), false);
        }
        return true;
    }
    bool mouseMoved(const MouseMotionEvent& e) override {
        if(player) player->rotate(-e.xrel*.0028f,-e.yrel*.0028f);
        return true;
    }
    bool mousePressed(const MouseButtonEvent& e) override {
        if(screen_focused){
            Wayland::WaylandCompositor::get().sendPointerButton(0, (e.button == BUTTON_LEFT) ? 0x110 : 0x111, true);
            return true;
        }
        if(!player||!island) return true;
        const auto& reg=Material::MaterialRegistry::instance();
        auto hit=player->castRay(*island,12.f);
        if(e.button==BUTTON_LEFT && hit.hit && hit.material_code!=Material::MAT_BEDROCK){
            player->triggerHeadShake(.12f);
            island->setVoxel(hit.vx,hit.vy,hit.vz,Material::MAT_AIR);
            std::ostringstream ss; ss<<"[Mine] "<<reg.get(hit.material_code).name
                <<" at ("<<hit.vx<<","<<hit.vy<<","<<hit.vz<<")";
            logLine(ss.str());
            rebuildIslandMesh();
        } else if(e.button==BUTTON_RIGHT && hit.hit){
            int px=hit.place_coord.x,py=hit.place_coord.y,pz=hit.place_coord.z;
            if(island->inBounds(px,py,pz) && island->getVoxel(px,py,pz)==Material::MAT_AIR){
                island->setVoxel(px,py,pz,hotbar_mat);
                std::ostringstream ss; ss<<"[Place] "<<reg.get(hotbar_mat).name
                    <<" at ("<<px<<","<<py<<","<<pz<<")";
                logLine(ss.str());
                rebuildIslandMesh();
            }
        }
        return true;
    }

    // ── Frame ─────────────────────────────────────────────────────────────────
    bool frameRenderingQueued(const FrameEvent& e) override {
        if(!player||!island) return true;

        // Sync ImGui IO DisplaySize and DeltaTime with current render window
        ImGuiIO& io = ImGui::GetIO();
        if(getRenderWindow()) {
            io.DisplaySize = ImVec2(float(getRenderWindow()->getWidth()), float(getRenderWindow()->getHeight()));
        }
        io.DeltaTime = (e.timeSinceLastFrame > 1e-4f) ? e.timeSinceLastFrame : (1.0f / 60.0f);

        // Sample Gerstner ocean wave height at player position for buoyancy & swimming physics
        float wave_h = ocean.wave_set.sampleHeight(player->position.x, player->position.z, ocean.current_time);
        bool slide_active = key_ctrl || key_c;
        player->update(e.timeSinceLastFrame, key_w, key_s, key_a, key_d, key_space, key_shift, slide_active, *island, wave_h);
        updateCameraPose();

        // Update volumetric atmosphere and sky dome
        sky_system.updateSkyDomeMesh(skyMesh, e.timeSinceLastFrame, *island, player->getEyePosition());
        scnMgr->setFog(Ogre::FOG_EXP, sky_system.horizon_color, 0.00018f, 200.0f, 8000.0f);
        if(sunLight && sunLight->getParentSceneNode()){
            float t_night = std::max(0.0f, std::min(1.0f, (0.12f - sky_system.sun_direction.y) / 0.32f));
            float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);

            Spatial::Vector3D primary_dir = ((1.0f - night_factor) * sky_system.sun_direction + night_factor * sky_system.moon_direction).normalized();
            sunLight->getParentSceneNode()->setDirection(Vector3(
                -primary_dir.x,
                -primary_dir.y,
                -primary_dir.z
            ).normalisedCopy());
            sunLight->setDiffuseColour(sky_system.sun_color);
            sunLight->setSpecularColour(sky_system.sun_color * 0.85f);
        }
        scnMgr->setAmbientLight(sky_system.ambient_sky_color);

        // Animate procedural vegetation wind sway, molten lava river and smoke plume
        if(vegMesh) veg_system.updateVegetationMesh(vegMesh, e.timeSinceLastFrame);
        lava_system.updateLavaMesh(lavaMesh, e.timeSinceLastFrame, *island);
        smoke_system.updateSmokeMesh(smokeMesh, e.timeSinceLastFrame, *island);

        // ── Dispatch Wayland Compositor & In-World Display ───────────────────
        Wayland::WaylandCompositor::get().dispatch(0);

        if(cam){
            Ray center_ray = cam->getCameraToViewportRay(0.5f, 0.5f);
            float dist = 0.0f;
            screen_focused = wayland_display.raycast(center_ray, screen_u, screen_v, dist);
            if(screen_focused){
                auto* surf = Wayland::WaylandCompositor::get().getPrimarySurface();
                if(surf && surf->buffer.width > 0 && surf->buffer.height > 0){
                    int px = (int)(screen_u * float(surf->buffer.width));
                    int py = (int)(screen_v * float(surf->buffer.height));
                    Wayland::WaylandCompositor::get().sendPointerMotion(surf->id, px, py);
                }
            }
        }

        if(displayMesh){
            wayland_display.update(displayMesh, e.timeSinceLastFrame, Wayland::WaylandCompositor::get());
            if(displayNode) displayNode->setVisible(wayland_display.is_visible);
        }

        // Update multi-dimensional semantic boid flocks (2D shore sandpipers, 3D aerial/pelagic/vortex/fireflies, 4D hyperspatial luminaries)
        if(boidMesh) {
            boid_system.update(e.timeSinceLastFrame, *island);
            boid_system.updateBoidMesh(boidMesh, e.timeSinceLastFrame, *island);
        }

        // Update Nocturnal Firefly dynamic point lights across the island
        float night_intensity = std::max(0.0f, std::min(1.0f, (-sky_system.sun_direction.y + 0.05f) / 0.25f));
        auto firefly_positions = boid_system.getFireflyLightPositions(firefly_lights.size());
        for (size_t i = 0; i < firefly_lights.size(); ++i) {
            if (i < firefly_positions.size() && night_intensity > 0.02f) {
                firefly_lights[i]->setVisible(true);
                firefly_nodes[i]->setPosition(firefly_positions[i]);
                float pulse = 0.70f + 0.30f * std::sin(sky_system.simulation_time * 5.0f + float(i * 1.5f));
                ColourValue col_pulse = ColourValue(0.25f, 1.0f, 0.40f) * (night_intensity * pulse);
                firefly_lights[i]->setDiffuseColour(col_pulse);
            } else if (i < firefly_lights.size()) {
                firefly_lights[i]->setVisible(false);
            }
        }

        // Animate dynamic Sea of Thieves ocean mesh each frame (synchronised with solar / lunar direction)
        float t_ocean_night = std::max(0.0f, std::min(1.0f, (0.12f - sky_system.sun_direction.y) / 0.32f));
        float ocean_night_factor = t_ocean_night * t_ocean_night * (3.0f - 2.0f * t_ocean_night);
        Spatial::Vector3D active_light_dir = ((1.0f - ocean_night_factor) * sky_system.sun_direction + ocean_night_factor * sky_system.moon_direction).normalized();
        ocean.updateOceanMesh(oceanMesh, e.timeSinceLastFrame, *island, player->getEyePosition(), active_light_dir);

        // ── Per-frame Hardware-Accelerated Vector HUD Overlay ─────────────────
        fps_acc += 1.f / (e.timeSinceLastFrame > 1e-4f ? e.timeSinceLastFrame : 1.f);
        frame_cnt++;
        hud_timer += e.timeSinceLastFrame;

        if (hud_timer >= 0.05f) {
            float fps = fps_acc / frame_cnt;
            fps_acc = 0; frame_cnt = 0; hud_timer = 0;
            auto hit = player->castRay(*island, 14.f);
            hud.ray_hit = hit.hit;
            hud.ray_mat_code = hit.material_code;
            hud.ray_distance = hit.distance;
            hud.fps_display = fps;
        }

        // HUD only visible when ALT is held (otherwise hidden away with smooth holographic dissolve)
        float target_alpha = key_alt ? 1.0f : 0.0f;
        hud_alpha += (target_alpha - hud_alpha) * std::min(1.0f, e.timeSinceLastFrame * 14.0f);
        if (hud_alpha < 0.005f && !key_alt) hud_alpha = 0.0f;

        if (hud_alpha > 0.01f) {
            hud.renderVectorHUD(
                hudMesh,
                hud_alpha,
                e.timeSinceLastFrame,
                player->position.x, player->position.y, player->position.z,
                player->yaw, player->pitch,
                player->in_water,
                hud.ray_hit, hud.ray_mat_code, hud.ray_distance,
                hud.fps_display,
                hotbar_mat,
                "VOLCANIC_ISLAND"
            );
        } else {
            if (hudMesh) hudMesh->clear();
        }

        // Dynamic Paged OpenVDB Volumetric Chunk Streaming
        if (mesh_mode == MESH_SMOOTH && chunk_manager && island && player && scnMgr) {
            chunk_manager->update(Ogre::Vector3(player->position.x, player->position.y, player->position.z), *island, scnMgr, e.timeSinceLastFrame);
        }

        total_frames++;
        if (total_frames == 15) {
            takeScreenshot("applications/cave/island_screenshot_volcano.png");
            takeScreenshot("applications/cave/island_screenshot.png");
            warpToIsland(Island::IslandBiomeType::JUNGLE);
            sky_system.setTimeOfDay(12.0f);
            updateCameraPose();
        } else if (total_frames == 30) {
            takeScreenshot("applications/cave/island_screenshot_jungle.png");
            warpToIsland(Island::IslandBiomeType::DESERT);
            sky_system.setTimeOfDay(15.5f);
            updateCameraPose();
        } else if (total_frames == 45) {
            takeScreenshot("applications/cave/island_screenshot_desert.png");
            warpToIsland(Island::IslandBiomeType::GLACIAL_ICE);
            sky_system.setTimeOfDay(11.0f);
            updateCameraPose();
        } else if (total_frames == 60) {
            takeScreenshot("applications/cave/island_screenshot_ice.png");
            warpToIsland(Island::IslandBiomeType::CORAL_ARCHIPELAGO);
            sky_system.setTimeOfDay(13.0f);
            updateCameraPose();
        } else if (total_frames == 75) {
            takeScreenshot("applications/cave/island_screenshot_archipelago.png");
        }

        return true;
    }

    void shutdown() override {
        logLine("\n[Session ended]");
        if(chunk_manager){
            chunk_manager->cleanup(scnMgr);
            chunk_manager.reset();
        }
        removeInputListener(&input_chain);
        if(imgui_input){ delete imgui_input; imgui_input=nullptr; }
        auto* sg=RTShader::ShaderGenerator::getSingletonPtr();
        if(sg&&scnMgr) sg->removeSceneManager(scnMgr);
        ApplicationContext::shutdown();
    }
};

// ─── Fatal error logger ───────────────────────────────────────────────────────
void logFatal(const std::string& type, const std::string& detail){
    std::cerr<<"\n[FATAL "<<type<<"]\n"<<detail<<"\n";
    std::ofstream f("applications/cave/island_explorer.log",std::ios::app);
    if(f.is_open()) f<<"[FATAL "<<type<<"]\n"<<detail<<"\n\n";
}

int main(int argc, char** argv){
    setenv("SDL_VIDEODRIVER","x11",0);
    try {
        VolcanicIslandApp app;
        app.initApp();
        app.getRoot()->startRendering();
        app.closeApp();
    } catch(const Ogre::Exception& e){ logFatal("Ogre",e.getFullDescription()); return 1; }
      catch(const std::exception& e) { logFatal("std", e.what()); return 1; }
      catch(...)                      { logFatal("Unknown","Unknown exception."); return 1; }
    return 0;
}
