// test_sim_ipc.cpp — End-to-end IPC integration test for SCR v0.0.4
//
// Proves: "Simulation continues if renderer is killed.
//          Renderer reconstructs after reconnect from consistent snapshot plus deltas."
//
// Standalone binary. g++ -std=c++17. No OGRE dependencies.

#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <cstring>

#include <unistd.h>
#include <sys/socket.h>

#include <nlohmann/json.hpp>

#include "simulation/sim_ipc_transport.hpp"
#include "simulation/sim_ipc_world.hpp"
#include "simulation/sim_ipc_server.hpp"
#include "simulation/sim_ipc_client.hpp"

using json = nlohmann::json;
using namespace SCR::IPC;

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

static const char* SOCKET_PATH = "/tmp/scr_ipc_test.sock";

static int g_passed = 0;
static int g_failed = 0;

#define CHECK(name, expr) do {                                        \
    if (expr) { std::cout << "  PASS  " << (name) << "\n"; g_passed++; } \
    else      { std::cout << "  FAIL  " << (name) << "\n"; g_failed++; } \
} while (0)

// ---------------------------------------------------------------------------
// World state helpers
// ---------------------------------------------------------------------------

static void tickWorld(WorldModel& world, uint64_t tick) {
    float t = static_cast<float>(tick);

    // Player position moves forward each tick
    json pos;
    pos["x"] = t * 0.5f;
    pos["y"] = 0.0f;
    pos["z"] = t * 1.0f;
    world.updateEntity("player:1", pos);

    // Time-of-day advances (wraps at 24h)
    float hours = std::fmod(t * 0.1f, 24.0f);
    json tod;
    tod["hours"] = hours;
    world.updateEntity("world:time", tod);

    world.commit(tick, t * (1.0f / 60.0f));
}

static void runTicks(WorldModel& world, SimIpcServer& server,
                     uint64_t start, uint64_t count) {
    for (uint64_t t = start; t < start + count; ++t) {
        tickWorld(world, t);
        server.pushSnapshot();
    }
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

int main() {
    std::cout << "=================================================================\n";
    std::cout << "  SCR v0.0.4  END-TO-END IPC INTEGRATION TEST\n";
    std::cout << "=================================================================\n\n";

    // -- Step 1: Create WorldModel -----------------------------------------
    std::cout << "[Step 1] Create WorldModel\n";
    WorldModel world;
    CHECK("WorldModel created", true);

    // -- Step 2: Start SimIpcServer ----------------------------------------
    std::cout << "[Step 2] Start SimIpcServer on " << SOCKET_PATH << "\n";
    ::unlink(SOCKET_PATH);
    SimIpcServer server(world);
    bool started = server.start(SOCKET_PATH);
    CHECK("Server starts", started);
    if (!started) {
        std::cout << "\nFATAL: server failed to start.\n";
        return 1;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));

    // -- Step 3: Simulate 100 ticks, no client -----------------------------
    std::cout << "[Step 3] Simulate 100 ticks (no client connected)\n";
    runTicks(world, server, 1, 100);

    CHECK("tick == 100",        world.getTick() == 100);
    CHECK("generation == 100",  world.getGeneration() == 100);

    // -- Step 4: Create SimIpcClient, connect ------------------------------
    std::cout << "[Step 4] Create SimIpcClient, connect\n";
    SimIpcClient client;
    bool connected = client.connect(SOCKET_PATH);
    CHECK("Client connects", connected);
    if (!connected) {
        std::cout << "\nFATAL: client failed to connect.\n";
        server.stop();
        ::unlink(SOCKET_PATH);
        return 1;
    }

    // Server accept-loop sends full snapshot on connect
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // -- Step 5: Verify full snapshot received, generation > 0 --------------
    std::cout << "[Step 5] Verify client receives full snapshot\n";
    bool changed = client.poll();
    uint64_t gen1 = client.getGeneration();
    CHECK("Client received snapshot",  changed);
    CHECK("Client generation > 0",     gen1 > 0);

    const auto& ws = client.getWorldState();
    CHECK("Snapshot has entities",
          ws.contains("entities") && ws["entities"].is_object());
    CHECK("Snapshot has player:1",
          ws["entities"].contains("player:1"));
    CHECK("Snapshot has world:time",
          ws["entities"].contains("world:time"));

    // -- Step 6: Send input from client, verify server receives it ----------
    std::cout << "[Step 6] Send input from client\n";
    InputState inp;
    inp.move_forward = true;
    inp.sprint       = true;
    inp.mouse_dx     = 3.14f;
    client.sendInput(inp);

    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    auto pending = server.drainInput();
    CHECK("Server received input", !pending.empty());
    if (!pending.empty()) {
        CHECK("input.move_forward == true",  pending[0].move_forward);
        CHECK("input.sprint == true",        pending[0].sprint);
        CHECK("input.mouse_dx ~ 3.14",
              std::abs(pending[0].mouse_dx - 3.14f) < 0.01f);
    }

    // -- Step 7: Simulate 50 more ticks, client connected -------------------
    std::cout << "[Step 7] Simulate 50 more ticks (client connected)\n";
    runTicks(world, server, 101, 50);

    client.poll();
    uint64_t gen2 = client.getGeneration();
    CHECK("Client generation advanced", gen2 > gen1);
    CHECK("Client generation == 150",   gen2 == 150);

    // -- Step 8: Kill client (abrupt disconnect — no SHUTDOWN) ---------------
    // Use IpcTransport directly so we close(fd) without sending SHUTDOWN.
    // Server detects the drop via POLLHUP/POLLERR.
    std::cout << "[Step 8] Kill client (abrupt disconnect)\n";
    {
        IpcTransport raw_client;
        bool raw_ok = raw_client.connect(SOCKET_PATH);
        CHECK("Raw client connects for abrupt kill", raw_ok);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        raw_client.disconnect(); // abrupt: close fd, no SHUTDOWN
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(150));

    // -- Step 9: Simulate 50 more ticks — server must NOT crash -------------
    std::cout << "[Step 9] Simulate 50 more ticks (server survival)\n";
    runTicks(world, server, 151, 50);

    // start() returns true when already running — proves server thread is alive
    CHECK("Server survived after client kill", server.start(SOCKET_PATH));
    CHECK("tick == 200",        world.getTick() == 200);
    CHECK("generation == 200",  world.getGeneration() == 200);

    // -- Step 10: Create new SimIpcClient, reconnect -----------------------
    std::cout << "[Step 10] Create new SimIpcClient, reconnect\n";
    SimIpcClient client2;
    bool connected2 = client2.connect(SOCKET_PATH);
    CHECK("New client connects", connected2);
    if (!connected2) {
        std::cout << "\nFATAL: new client failed to connect.\n";
        server.stop();
        ::unlink(SOCKET_PATH);
        return 1;
    }

    // Server sends full snapshot to new client on accept
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // -- Step 11: Verify new client receives full snapshot ------------------
    std::cout << "[Step 11] Verify new client receives full snapshot\n";
    bool changed2 = client2.poll();
    CHECK("New client received snapshot", changed2);

    const auto& ws2 = client2.getWorldState();
    CHECK("Reconnect snapshot has player:1",
          ws2.contains("entities") && ws2["entities"].contains("player:1"));
    CHECK("Reconnect snapshot has world:time",
          ws2.contains("entities") && ws2["entities"].contains("world:time"));

    // Verify state matches current world state (reconstruction from consistent state)
    json expected_player = world.getEntity("player:1");
    json got_player = ws2["entities"]["player:1"];
    CHECK("Reconstructed player position matches",
          std::abs(got_player["x"].get<float>() -
                   expected_player["x"].get<float>()) < 0.01f);

    json expected_time = world.getEntity("world:time");
    json got_time = ws2["entities"]["world:time"];
    CHECK("Reconstructed time-of-day matches",
          std::abs(got_time["hours"].get<float>() -
                   expected_time["hours"].get<float>()) < 0.01f);

    // -- Step 12: Verify generation counter is continuous -------------------
    std::cout << "[Step 12] Verify generation counter continuity\n";
    uint64_t gen3 = client2.getGeneration();
    CHECK("New client generation == 200 (matches world)",
          gen3 == world.getGeneration());

    // -- Step 13: Shared memory test -----------------------------------------
    std::cout << "[Step 13] Shared memory (memfd) zero-copy transfer\n";
    {
        // Create connected socket pair for FD passing
        int sv[2];
        CHECK("socketpair creates connected pair", ::socketpair(AF_UNIX, SOCK_STREAM, 0, sv) == 0);

        IpcTransport sender(sv[0]);
        IpcTransport receiver(sv[1]);

        // Create shared memory region
        size_t test_size = 4096;
        int fd = sender.createSharedMemory(test_size);
        CHECK("createSharedMemory returns valid fd", fd >= 0);

        // Map and write data
        void* ptr = sender.mapSharedMemory(fd, test_size);
        CHECK("mapSharedMemory returns valid pointer", ptr != nullptr);
        if (ptr) {
            std::memcpy(ptr, "SCR_SHARED_DATA_TEST", 21);
        }

        // Send via SCM_RIGHTS
        bool sent = sender.sendBulkData("SCR_SHARED_DATA_TEST", 21);
        CHECK("sendBulkData succeeds", sent);

        // Receive
        auto [recv_ptr, recv_size] = receiver.receiveBulkData();
        CHECK("receiveBulkData returns valid pointer", recv_ptr != nullptr);
        CHECK("receiveBulkData returns correct size", recv_size == 21);
        if (recv_ptr) {
            CHECK("received data matches sent data",
                  std::memcmp(recv_ptr, "SCR_SHARED_DATA_TEST", 21) == 0);
            receiver.unmapSharedMemory(recv_ptr, recv_size);
        }

        sender.unmapSharedMemory(ptr, test_size);
        ::close(fd);
        // sv[0] and sv[1] closed by transport destructors
    }

    // -- Step 14: Spatial subscription test -----------------------------------
    std::cout << "[Step 14] Spatial subscription (AABB filtering)\n";
    {
        // Create a world with entities at different positions
        WorldModel sub_world;
        json p1; p1["x"] = 10; p1["y"] = 0; p1["z"] = 10;
        json p2; p2["x"] = 100; p2["y"] = 0; p2["z"] = 100;
        json p3; p3["x"] = -50; p3["y"] = 0; p3["z"] = -50;
        sub_world.updateEntity("near:1", p1);
        sub_world.updateEntity("far:1", p2);
        sub_world.updateEntity("behind:1", p3);
        sub_world.commit(1, 0.016f);

        // Filter: only entities in [0,0,0] to [50,50,50]
        float aabb_min[3] = {0, -10, 0};
        float aabb_max[3] = {50, 10, 50};
        json filtered = sub_world.getFilteredDelta(0, aabb_min, aabb_max);

        bool has_near = filtered.contains("added") && filtered["added"].contains("near:1");
        bool has_far = filtered.contains("added") && filtered["added"].contains("far:1");
        bool has_behind = filtered.contains("added") && filtered["added"].contains("behind:1");

        CHECK("filtered delta has entity inside AABB", has_near);
        CHECK("filtered delta excludes entity outside AABB (far)", !has_far);
        CHECK("filtered delta excludes entity outside AABB (behind)", !has_behind);

        // Unfiltered should have all
        json all = sub_world.getDelta(0);
        CHECK("unfiltered delta has all entities",
              all.contains("added") &&
              all["added"].contains("near:1") &&
              all["added"].contains("far:1") &&
              all["added"].contains("behind:1"));
    }

    // -- Step 15: Summary ---------------------------------------------------
    std::cout << "\n=================================================================\n";
    if (g_failed == 0) {
        std::cout << "  ALL CHECKS PASSED  (" << g_passed << "/" << (g_passed + g_failed) << ")\n";
    } else {
        std::cout << "  SOME CHECKS FAILED  (" << g_passed << " passed, "
                  << g_failed << " failed)\n";
    }
    std::cout << "=================================================================\n";

    // -- Step 16: Clean up --------------------------------------------------
    std::cout << "\n[Step 16] Clean up\n";
    server.stop();
    ::unlink(SOCKET_PATH);
    std::cout << "Done.\n";

    return g_failed == 0 ? 0 : 1;
}
