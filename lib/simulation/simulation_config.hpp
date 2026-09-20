#pragma once
/**
 * SCR Simulation Configuration — Centralized Constants
 * ─────────────────────────────────────────────────────────────────────────────
 * Single source of truth for all simulation parameters.
 * Subsystems read from here; nothing is hardcoded in subsystem implementations.
 */

namespace SCR::Config {

// ── Physics ──────────────────────────────────────────────────────────────────
    constexpr float GRAVITY              = -10.0f;
    constexpr float GRAVITY_APEX_MULT    = 0.65f;    // Reduced gravity at jump apex
    constexpr float GRAVITY_ASCENT_MULT  = 0.90f;    // Reduced gravity during ascent
    constexpr float GRAVITY_DESCENT_MULT = 1.55f;    // Increased gravity during descent
    constexpr float GRAVITY_KINETIC_MULT = 1.25f;    // Fast-fall multiplier
    constexpr float TERMINAL_VELOCITY    = -28.0f;

// ── Jump ─────────────────────────────────────────────────────────────────────
    constexpr float JUMP_VELOCITY        = 7.5f;
    constexpr float DOUBLE_JUMP_VELOCITY = 6.5f;
    constexpr float COYOTE_TIME          = 0.18f;    // Grace period after leaving ground (s)
    constexpr float JUMP_BUFFER          = 0.15f;    // Pre-buffer for early press (s)

// ── Movement ─────────────────────────────────────────────────────────────────
    constexpr float WALK_SPEED           = 6.0f;
    constexpr float SPRINT_SPEED         = 8.5f;
    constexpr float WATER_SPEED_MULT     = 0.65f;
    constexpr float GROUND_ACCEL         = 16.0f;
    constexpr float GROUND_FRICTION      = 8.5f;
    constexpr float AIR_ACCEL            = 8.0f;
    constexpr float AIR_SPEED_CAP        = 1.5f;

// ── Collision ────────────────────────────────────────────────────────────────
    constexpr float STEP_HEIGHT          = 0.35f;
    constexpr float EYE_HEIGHT           = 1.5f;
    constexpr float PLAYER_HEIGHT        = 1.8f;
    constexpr float PLAYER_RADIUS        = 0.3f;
    constexpr float AABB_EPSILON         = 0.001f;

// ── Camera ───────────────────────────────────────────────────────────────────
    constexpr float MOUSE_SENSITIVITY    = 0.0028f;
    constexpr float PITCH_LIMIT          = 1.48f;    // Radians (~85 degrees)
    constexpr float NEAR_CLIP            = 0.05f;
    constexpr float FAR_CLIP_ISLAND      = 12000.0f;
    constexpr float FAR_CLIP_CAVE        = 300.0f;

// ── Head Bob ─────────────────────────────────────────────────────────────────
    constexpr float HEAD_BOB_AMPLITUDE   = 0.03f;
    constexpr float HEAD_BOB_FREQUENCY   = 8.0f;
    constexpr float HEAD_BOB_SPRINT_MULT = 1.3f;

// ── Camera Shake ─────────────────────────────────────────────────────────────
    constexpr float SHAKE_DECAY          = 3.0f;
    constexpr float SHAKE_INTENSITY      = 0.16f;

// ── Breathing ────────────────────────────────────────────────────────────────
    constexpr float BREATHING_AMPLITUDE  = 0.003f;
    constexpr float BREATHING_FREQUENCY  = 0.8f;

// ── Roll ─────────────────────────────────────────────────────────────────────
    constexpr float ROLL_STRAFE_MULT     = 0.015f;
    constexpr float ROLL_TURN_MULT       = 0.008f;
    constexpr float ROLL_DAMPING         = 4.0f;

// ── HUD ──────────────────────────────────────────────────────────────────────
    constexpr float HUD_UPDATE_RATE      = 20.0f;    // Hz
    constexpr float HUD_DISSOLVE_SPEED   = 14.0f;
    constexpr float FPS_SAMPLE_WINDOW    = 0.25f;    // Seconds

// ── Timing ───────────────────────────────────────────────────────────────────
    constexpr float PHYSICS_TICK_RATE    = 60.0f;
    constexpr float MAX_FRAME_DT         = 0.05f;    // Cap at 50ms

// ── Water ────────────────────────────────────────────────────────────────────
    constexpr float WATER_DENSITY        = 1000.0f;  // kg/m3
    constexpr float WATER_BUOYANCY       = 12.0f;
    constexpr float WATER_DRAG           = 0.85f;
    constexpr float WATER_SURFACE_LEAP   = 4.0f;

// ── Slide ────────────────────────────────────────────────────────────────────
    constexpr float SLIDE_DURATION       = 1.4f;     // Seconds
    constexpr float SLIDE_SPEED_MULT     = 1.4f;
    constexpr float SLIDE_FRICTION       = 2.0f;
    constexpr float SLIDE_SLOPE_GRAVITY  = 18.0f;

// ── Voxel ────────────────────────────────────────────────────────────────────
    constexpr float RAYCAST_STEP         = 0.35f;    // DDA step size
    constexpr float RAYCAST_MAX_DIST     = 18.0f;    // Max interaction distance
    constexpr float MINE_HEAD_SHAKE      = 0.16f;    // Head-shake intensity on mine

// ── Wayland ──────────────────────────────────────────────────────────────────
    constexpr int   WAYLAND_DISPLAY_W    = 1920;
    constexpr int   WAYLAND_DISPLAY_H    = 1080;

} // namespace SCR::Config
