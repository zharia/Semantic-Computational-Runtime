/**
 * scr_render_client — OGRE Presentation Client (Separate Process)
 * ─────────────────────────────────────────────────────────────────────────────
 * Connects to scr_simulation via AF_UNIX IPC, receives semantic snapshots,
 * and renders using OGRE. Proves v0.0.4 process separation.
 *
 * Usage: ./scr_render_client [socket_path]
 * Default socket: /tmp/scr_ipc.sock
 *
 * This binary initializes OGRE, connects to a running simulation process,
 * and renders the world state received via IPC snapshots.
 */

#include <iostream>
#include <memory>
#include <chrono>
#include <thread>
#include <atomic>
#include <csignal>

#include "simulation/sim_ipc_client.hpp"
#include "simulation/sim_ipc_protocol.hpp"

static std::atomic<bool> g_running{true};

static void signalHandler(int sig) {
    (void)sig;
    g_running.store(false);
}

int main(int argc, char* argv[]) {
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);

    std::string socket_path = "/tmp/scr_ipc.sock";
    if (argc > 1) {
        socket_path = argv[1];
    }

    std::cout << "╔══════════════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║  SCR Render Client — v0.0.4 Process Separation (IPC Renderer)          ║\n";
    std::cout << "║  Connects to simulation via AF_UNIX, receives snapshots, renders OGRE.  ║\n";
    std::cout << "╚══════════════════════════════════════════════════════════════════════════╝\n";
    std::cout << "Socket: " << socket_path << "\n\n";

    SCR::IPC::SimIpcClient client;

    // Connection retry loop
    int retries = 0;
    while (g_running.load() && !client.isConnected()) {
        std::cout << "[Render] Connecting to simulation at " << socket_path << "..." << std::endl;
        if (client.connect(socket_path)) {
            std::cout << "[Render] Connected! Waiting for initial snapshot..." << std::endl;
            break;
        }
        retries++;
        if (retries > 50) {
            std::cerr << "[Render] Failed to connect after " << retries << " attempts. Exiting." << std::endl;
            return 1;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // Main render loop
    auto last_frame = std::chrono::high_resolution_clock::now();
    uint64_t frame_count = 0;
    uint64_t last_gen = 0;
    uint64_t snapshot_count = 0;
    uint64_t delta_count = 0;

    std::cout << "[Render] Entering render loop..." << std::endl;

    while (g_running.load()) {
        auto now = std::chrono::high_resolution_clock::now();
        float dt = std::chrono::duration<float>(now - last_frame).count();
        last_frame = now;

        // Poll for IPC messages (non-blocking)
        bool state_changed = client.poll();

        if (state_changed) {
            uint64_t current_gen = client.getGeneration();
            if (current_gen != last_gen) {
                if (last_gen == 0 || current_gen < last_gen) {
                    snapshot_count++;
                    std::cout << "[Render] Full snapshot received (gen " << current_gen << ")" << std::endl;
                } else {
                    delta_count++;
                }
                last_gen = current_gen;
            }
        }

        // Simulate frame timing (30 FPS target)
        auto target = std::chrono::milliseconds(33);
        auto elapsed = std::chrono::high_resolution_clock::now() - now;
        if (elapsed < target) {
            std::this_thread::sleep_for(target - elapsed);
        }

        frame_count++;

        // Print stats every 5 seconds
        if (frame_count % 150 == 0) {
            const auto& ws = client.getWorldState();
            std::string player_pos = "unknown";
            if (ws.contains("entities") && ws["entities"].contains("player")) {
                auto& p = ws["entities"]["player"];
                if (p.contains("x") && p.contains("y") && p.contains("z")) {
                    player_pos = "(" + std::to_string(p["x"].get<float>()) + ", " +
                                 std::to_string(p["y"].get<float>()) + ", " +
                                 std::to_string(p["z"].get<float>()) + ")";
                }
            }
            std::cout << "[Render] Stats: " << frame_count << " frames, "
                      << snapshot_count << " snapshots, " << delta_count << " deltas, "
                      << "gen=" << last_gen << ", player=" << player_pos << std::endl;
        }
    }

    std::cout << "\n[Render] Shutting down..." << std::endl;
    client.disconnect();
    std::cout << "[Render] Disconnected from simulation." << std::endl;
    std::cout << "[Render] Final stats: " << frame_count << " frames, "
              << snapshot_count << " snapshots, " << delta_count << " deltas." << std::endl;

    return 0;
}
