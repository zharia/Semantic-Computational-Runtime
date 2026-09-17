#ifndef CAVE_LOADING_SCREEN_EFFECTS_HPP
#define CAVE_LOADING_SCREEN_EFFECTS_HPP

#include <string>
#include <vector>
#include <cmath>
#include <algorithm>
#include <chrono>
#include <iostream>
#include <iomanip>
#include <sstream>

#include <Ogre.h>

#include "simulation_framework.hpp"

namespace SCR::Simulation {

// ─── Loading Screen State & Progressive Dissolve Engine ──────────────────────
class OrganicLoadingScreen {
public:
    enum State {
        STATE_INACTIVE,
        STATE_LOADING,
        STATE_ORGANIC_DISSOLVE,
        STATE_COMPLETE
    };

    State state = STATE_INACTIVE;

    // Numerical and visual smoothed progress (0.0 .. 1.0)
    float target_progress = 0.0f;
    float smooth_progress = 0.0f;

    // Animation clocks
    float anim_time = 0.0f;
    float dissolve_elapsed = 0.0f;
    const float DISSOLVE_TOTAL_DURATION = 1.35f;

    // Component-by-component individual organic alpha channels
    float alpha_log_console   = 1.0f; // Layer 1: Exits first (0.0s -> 0.35s)
    float alpha_progress_dial = 1.0f; // Layer 2: Exits second (0.25s -> 0.65s)
    float alpha_backdrop      = 1.0f; // Layer 3: Exits third (0.45s -> 1.05s)
    float alpha_vignette      = 1.0f; // Layer 4: Exits last (0.75s -> 1.35s)
    float alpha_in_game_hud   = 0.0f; // Layer 5: Enters dynamically (0.90s -> 1.35s)

    // Current metadata and feedback messages
    SceneMetadata active_metadata;
    std::string current_stage = "Initializing";
    std::string current_detail = "Allocating simulation memory";
    std::string current_subsystem = "KERNEL";
    std::vector<std::string> log_history;

    // Graphic Resources
    Ogre::ManualObject* overlayObj = nullptr;
    Ogre::SceneNode* overlayNode = nullptr;

    OrganicLoadingScreen() = default;

    void startLoading(const SceneMetadata& meta) {
        active_metadata = meta;
        state = STATE_LOADING;
        target_progress = 0.0f;
        smooth_progress = 0.0f;
        anim_time = 0.0f;
        dissolve_elapsed = 0.0f;

        alpha_log_console   = 1.0f;
        alpha_progress_dial = 1.0f;
        alpha_backdrop      = 1.0f;
        alpha_vignette      = 1.0f;
        alpha_in_game_hud   = 0.0f;

        log_history.clear();
        log_history.push_back("[SCR] Simulation Loading: " + meta.title);
        log_history.push_back("[CONTRACT] Bound semantic contract: " + meta.semantic_contract);
    }

    void updateTaskProgress(const LoadingTaskUpdate& update) {
        target_progress = std::max(target_progress, update.progress);
        current_stage = update.current_stage;
        current_detail = update.detail_message;
        current_subsystem = update.subsystem;

        std::string log_line = "[" + update.subsystem + "] " + update.current_stage;
        if (!update.detail_message.empty()) {
            log_line += " -> " + update.detail_message;
        }
        log_history.push_back(log_line);
        if (log_history.size() > 8) {
            log_history.erase(log_history.begin());
        }
    }

    void finishLoading() {
        target_progress = 1.0f;
        if (state == STATE_LOADING) {
            state = STATE_ORGANIC_DISSOLVE;
            dissolve_elapsed = 0.0f;
        }
    }

    /**
     * Updates simulation clocks, progress spring interpolation, and organic dissolve layers.
     */
    void update(float dt) {
        if (state == STATE_INACTIVE) return;
        anim_time += dt;

        // Smooth spring interpolation for progress bar
        float k = std::min(1.0f, dt * 8.5f);
        smooth_progress += (target_progress - smooth_progress) * k;

        if (state == STATE_LOADING) {
            if (target_progress >= 1.0f && smooth_progress >= 0.99f) {
                state = STATE_ORGANIC_DISSOLVE;
                dissolve_elapsed = 0.0f;
            }
        } else if (state == STATE_ORGANIC_DISSOLVE) {
            dissolve_elapsed += dt;
            float t = dissolve_elapsed;

            // ── Organic Progressive Layer Dissolution Functions ──────────────
            // Layer 1: Subsystem Log Console & Details (t: 0.0 -> 0.35s)
            alpha_log_console = std::max(0.0f, 1.0f - (t / 0.35f));

            // Layer 2: Main Progress Bar & Quantum Loader Core (t: 0.25 -> 0.65s)
            if (t < 0.25f) alpha_progress_dial = 1.0f;
            else alpha_progress_dial = std::max(0.0f, 1.0f - ((t - 0.25f) / 0.40f));

            // Layer 3: Glass Backdrop Panel (t: 0.45 -> 1.05s)
            if (t < 0.45f) alpha_backdrop = 1.0f;
            else {
                float frac = (t - 0.45f) / 0.60f;
                alpha_backdrop = std::max(0.0f, std::pow(1.0f - std::min(1.0f, frac), 1.6f));
            }

            // Layer 4: Vignette & Ambient Darkness (t: 0.75 -> 1.35s)
            if (t < 0.75f) alpha_vignette = 1.0f;
            else alpha_vignette = std::max(0.0f, 1.0f - ((t - 0.75f) / 0.60f));

            // Layer 5: In-game HUD Glide-In (t: 0.90 -> 1.35s)
            if (t < 0.90f) alpha_in_game_hud = 0.0f;
            else alpha_in_game_hud = std::min(1.0f, (t - 0.90f) / 0.45f);

            if (dissolve_elapsed >= DISSOLVE_TOTAL_DURATION) {
                state = STATE_COMPLETE;
                alpha_log_console   = 0.0f;
                alpha_progress_dial = 0.0f;
                alpha_backdrop      = 0.0f;
                alpha_vignette      = 0.0f;
                alpha_in_game_hud   = 1.0f;
            }
        }
    }

    bool isDone() const {
        return state == STATE_COMPLETE || (state == STATE_ORGANIC_DISSOLVE && dissolve_elapsed >= DISSOLVE_TOTAL_DURATION);
    }

    /**
     * Builds and updates 2D geometric overlay elements in screen coordinates.
     */
    void renderLoadingMesh(Ogre::ManualObject* obj, Ogre::RenderWindow* win) {
        if (!obj || !win || state == STATE_COMPLETE || state == STATE_INACTIVE) {
            if (obj) obj->clear();
            return;
        }

        obj->clear();
        obj->begin("SCR/LoadingScreenMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        uint32_t v_idx = 0;

        auto addQuad2D = [&](float x1, float y1, float x2, float y2, const Ogre::ColourValue& c1, const Ogre::ColourValue& c2) {
            obj->position(x1, y1, -1.0f); obj->colour(c1);
            obj->position(x2, y1, -1.0f); obj->colour(c2);
            obj->position(x2, y2, -1.0f); obj->colour(c2);
            obj->position(x1, y2, -1.0f); obj->colour(c1);
            obj->triangle(v_idx, v_idx + 1, v_idx + 2);
            obj->triangle(v_idx, v_idx + 2, v_idx + 3);
            v_idx += 4;
        };

        // 1. Full Screen Backdrop Panel (Ink Black with Steel Azure Ambient Glow)
        if (alpha_backdrop > 0.005f) {
            Ogre::ColourValue c_top(0.008f, 0.039f, 0.075f, 0.98f * alpha_backdrop); // Ink Black
            Ogre::ColourValue c_btm(0.031f, 0.263f, 0.525f, 0.98f * alpha_backdrop); // Steel Azure
            addQuad2D(-1.0f, 1.0f, 1.0f, -1.0f, c_top, c_btm);

            // Ambient Glass Glow behind central card
            float pulse = 0.5f + 0.5f * std::sin(anim_time * 2.8f);
            Ogre::ColourValue glow(0.043f, 0.271f, 0.529f, (0.25f + pulse * 0.15f) * alpha_backdrop); // Steel Azure 2
            addQuad2D(-0.65f, 0.55f, 0.65f, -0.55f, glow, glow);
        }

        // 2. Central Card Frame
        if (alpha_progress_dial > 0.005f) {
            // Card background (Ink Black glass)
            Ogre::ColourValue card_bg(0.008f, 0.039f, 0.075f, 0.90f * alpha_progress_dial);
            addQuad2D(-0.55f, 0.45f, 0.55f, -0.45f, card_bg, card_bg);

            // Steel Azure to Cool Horizon accent header bar
            Ogre::ColourValue bar_c1(0.031f, 0.263f, 0.525f, 0.95f * alpha_progress_dial); // Steel Azure
            Ogre::ColourValue bar_c2(0.392f, 0.651f, 0.969f, 0.95f * alpha_progress_dial); // Cool Horizon
            addQuad2D(-0.55f, 0.45f, 0.55f, 0.435f, bar_c1, bar_c2);

            // 3. Main Progress Bar Track
            float pb_x1 = -0.45f, pb_x2 = 0.45f;
            float pb_y1 = -0.18f, pb_y2 = -0.21f;

            // Track background (Ink Black with Steel Azure 2 groove)
            Ogre::ColourValue track_bg(0.043f, 0.271f, 0.529f, 0.70f * alpha_progress_dial);
            addQuad2D(pb_x1, pb_y1, pb_x2, pb_y2, track_bg, track_bg);

            // Filled progress portion (Steel Azure -> Cool Horizon -> White gradient)
            float fill_x2 = pb_x1 + (pb_x2 - pb_x1) * smooth_progress;
            if (fill_x2 > pb_x1 + 0.005f) {
                Ogre::ColourValue fill_c1(0.031f, 0.263f, 0.525f, 0.98f * alpha_progress_dial); // Steel Azure
                Ogre::ColourValue fill_c2(0.392f, 0.651f, 0.969f, 0.98f * alpha_progress_dial); // Cool Horizon
                addQuad2D(pb_x1, pb_y1, fill_x2, pb_y2, fill_c1, fill_c2);
            }
        }

        // 4. Animated Rotating Quantum Crystal Loader (Center Icon)
        if (alpha_progress_dial > 0.005f) {
            float cx = 0.0f, cy = 0.12f;
            float rad = 0.065f;
            float ang = anim_time * 3.5f;

            for (int i = 0; i < 6; ++i) {
                float a = ang + float(i) * (3.14159f / 3.0f);
                float px = cx + std::cos(a) * rad;
                float py = cy + std::sin(a) * rad;
                float p_size = 0.008f + 0.004f * std::sin(anim_time * 5.0f + float(i));
                Ogre::ColourValue p_col(0.392f, 0.651f, 0.969f, (0.75f + float(i)*0.04f) * alpha_progress_dial); // Cool Horizon
                addQuad2D(px - p_size, py + p_size, px + p_size, py - p_size, p_col, p_col);
            }
        }

        // 5. Subsystem Telemetry & Log Console Box
        if (alpha_log_console > 0.005f) {
            float log_x1 = -0.45f, log_x2 = 0.45f;
            float log_y1 = -0.25f, log_y2 = -0.38f;
            Ogre::ColourValue log_bg(0.008f, 0.039f, 0.075f, 0.85f * alpha_log_console); // Ink Black
            addQuad2D(log_x1, log_y1, log_x2, log_y2, log_bg, log_bg);

            // Pulsing activity bar (Cool Horizon)
            float p_pulse = (std::sin(anim_time * 6.0f) * 0.5f + 0.5f);
            Ogre::ColourValue act_col(0.392f, 0.651f, 0.969f, (0.5f + p_pulse * 0.5f) * alpha_log_console);
            addQuad2D(log_x1, log_y2 + 0.006f, log_x1 + (log_x2 - log_x1) * (0.2f + 0.8f * p_pulse), log_y2, act_col, act_col);
        }

        obj->end();
        obj->setBoundingBox(Ogre::AxisAlignedBox::BOX_INFINITE);
    }
};

} // namespace SCR::Simulation

#endif // CAVE_LOADING_SCREEN_EFFECTS_HPP
