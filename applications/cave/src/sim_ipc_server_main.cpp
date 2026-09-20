/**
 * scr_sim_ipc_server — Headless Simulation + IPC Server
 * ─────────────────────────────────────────────────────────────────────────────
 * Runs simulation without graphics, exposes AF_UNIX IPC socket for remote
 * renderers. Combines headless simulation loop with SimIpcServer.
 *
 * Usage: scr_sim_ipc_server [socket_path] [ticks_per_scene]
 *   socket_path: AF_UNIX socket path (default: /tmp/scr_ipc.sock)
 *   ticks_per_scene: ticks per scene (default: 0 = infinite)
 */

#include <iostream>
#include <memory>
#include <chrono>
#include <string>
#include <thread>
#include <atomic>
#include <csignal>
#include <cstring>
#include <cmath>

#include "simulation/simulation_framework.hpp"
#include "simulation/sim_ipc_server.hpp"
#include "simulation/sim_ipc_world.hpp"

#include "scene_volcanic_island.hpp"
#include "scene_karst_cave.hpp"
#include "scene_ocean_lab.hpp"
#include "scene_atmospheric_lab.hpp"

using namespace SCR::Simulation;
using namespace SCR::IPC;

static std::atomic<bool> g_running{true};

static void signalHandler(int) {
    g_running.store(false);
}

static void printBanner() {
    std::cout << "╔══════════════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║  SCR Headless IPC Server — v0.0.4                                      ║\n";
    std::cout << "║  Runs simulation without graphics, exposes IPC socket for renderers.    ║\n";
    std::cout << "╚══════════════════════════════════════════════════════════════════════════╝\n\n";
}

int main(int argc, char* argv[]) {
    printBanner();

    std::string socket_path = "/tmp/scr_ipc.sock";
    int ticks_per_scene = 0; // 0 = infinite

    if (argc > 1) socket_path = argv[1];
    if (argc > 2) ticks_per_scene = std::atoi(argv[2]);

    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);

    // Register scenes
    auto& reg = SimulationRegistry::instance();
    reg.registerScene(
        VolcanicIslandScene().getMetadata(),
        []() { return std::make_unique<VolcanicIslandScene>(); }
    );
    reg.registerScene(
        KarstCaveScene().getMetadata(),
        []() { return std::make_unique<KarstCaveScene>(); }
    );
    reg.registerScene(
        OceanLabScene().getMetadata(),
        []() { return std::make_unique<OceanLabScene>(); }
    );
    reg.registerScene(
        AtmosphericLabScene().getMetadata(),
        []() { return std::make_unique<AtmosphericLabScene>(); }
    );

    auto& scenes = reg.getScenes();
    std::cout << "[Server] Registered " << scenes.size() << " scenes\n";
    for (auto& entry : scenes) {
        std::cout << "  - " << entry.metadata.id << "\n";
    }

    // Create world model and IPC server
    WorldModel world;
    SimIpcServer server(world);

    if (!server.start(socket_path)) {
        std::cerr << "[Server] FAILED to start IPC server on " << socket_path << "\n";
        return 1;
    }
    std::cout << "[Server] IPC server listening on " << socket_path << "\n";
    std::cout << "[Server] Ticks per scene: " << (ticks_per_scene > 0 ? std::to_string(ticks_per_scene) : "infinite") << "\n";

    // Simulation parameters
    const float fixed_dt = 1.0f / 60.0f;
    uint64_t global_tick = 0;

    // Run scenes
    for (size_t si = 0; si < scenes.size() && g_running.load(); ++si) {
        auto scene = reg.createScene(static_cast<int>(si));
        if (!scene) continue;

        auto meta = scene->getMetadata();
        std::cout << "\n[Server] Scene " << (si+1) << "/" << scenes.size()
                  << ": " << meta.title << "\n";

        // Prepare
        LoadingContext loadCtx([](const LoadingTaskUpdate& u) {
            if (u.progress >= 0.99f) {
                std::cout << "  [" << u.subsystem << "] " << u.current_stage << "\n";
            }
        });

        auto t0 = std::chrono::high_resolution_clock::now();
        scene->prepare(loadCtx);
        auto t1 = std::chrono::high_resolution_clock::now();
        float prepare_ms = std::chrono::duration<float, std::milli>(t1 - t0).count();
        std::cout << "  [PREPARE] Done in " << prepare_ms << " ms\n";

        // Create input state (no renderer, so input is always zeroed)
        UserInputState input_state;

        // Run ticks
        std::cout << "  [SIMULATE] Running" << (ticks_per_scene > 0 ? " " + std::to_string(ticks_per_scene) : "") << " ticks...\n";
        auto sim_start = std::chrono::high_resolution_clock::now();

        int ticks_done = 0;
        while (g_running.load()) {
            // Update input state (zeroed — no renderer in headless mode)
            input_state = UserInputState{};
            scene->update(fixed_dt, input_state);

            // Commit world state for IPC clients
            float sim_time = static_cast<float>(global_tick) * fixed_dt;
            world.commit(global_tick, sim_time);

            global_tick++;
            ticks_done++;

            if (ticks_per_scene > 0 && ticks_done >= ticks_per_scene) break;

            // Periodic status
            if (ticks_done % 5000 == 0) {
                auto now = std::chrono::high_resolution_clock::now();
                float elapsed = std::chrono::duration<float>(now - sim_start).count();
                float ms_per_tick = (elapsed * 1000.0f) / ticks_done;
                std::cout << "  [SIMULATE] tick " << global_tick
                          << " (" << ms_per_tick << " ms/tick)\n";
            }
        }

        auto sim_end = std::chrono::high_resolution_clock::now();
        float sim_ms = std::chrono::duration<float, std::milli>(sim_end - sim_start).count();
        std::cout << "  [SIMULATE] Done: " << sim_ms << " ms total, "
                  << (sim_ms / ticks_done) << " ms/tick\n";
    }

    std::cout << "\n[Server] Shutting down...\n";
    server.stop();
    std::cout << "[Server] Done. Total ticks: " << global_tick << "\n";
    return 0;
}
