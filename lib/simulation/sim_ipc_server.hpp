#ifndef CAVE_SIM_IPC_SERVER_HPP
#define CAVE_SIM_IPC_SERVER_HPP

// Simulation-side IPC server.
// Manages renderer connections, produces snapshots, receives input.
// Header-only. No OGRE dependencies.

#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <deque>
#include <mutex>
#include <thread>
#include <atomic>
#include <iostream>
#include <algorithm>

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>

#include <nlohmann/json.hpp>

#include "simulation/sim_ipc_protocol.hpp"
#include "simulation/sim_ipc_transport.hpp"
#include "simulation/sim_ipc_world.hpp"

namespace SCR::IPC {

// ---------------------------------------------------------------------------
// SimIpcServer
// ---------------------------------------------------------------------------

class SimIpcServer {
public:
    explicit SimIpcServer(WorldModel& world)
        : world_(world) {}

    ~SimIpcServer() { stop(); }

    // Non-copyable
    SimIpcServer(const SimIpcServer&) = delete;
    SimIpcServer& operator=(const SimIpcServer&) = delete;

    // -- Lifecycle -------------------------------------------------------------

    bool start(const std::string& socket_path) {
        if (running_.load()) return true;

        socket_path_ = socket_path;
        ::unlink(socket_path_.c_str());

        server_fd_ = ::socket(AF_UNIX, SOCK_STREAM, 0);
        if (server_fd_ < 0) {
            std::cerr << "[SimIpcServer] socket() failed: "
                      << std::strerror(errno) << std::endl;
            return false;
        }

        // Non-blocking accept socket
        int flags = ::fcntl(server_fd_, F_GETFL, 0);
        ::fcntl(server_fd_, F_SETFL, flags | O_NONBLOCK);

        sockaddr_un addr{};
        addr.sun_family = AF_UNIX;
        std::strncpy(addr.sun_path, socket_path_.c_str(),
                     sizeof(addr.sun_path) - 1);

        if (::bind(server_fd_, reinterpret_cast<sockaddr*>(&addr),
                   sizeof(addr)) < 0) {
            std::cerr << "[SimIpcServer] bind(" << socket_path_
                      << ") failed: " << std::strerror(errno) << std::endl;
            ::close(server_fd_);
            server_fd_ = -1;
            return false;
        }

        if (::listen(server_fd_, 8) < 0) {
            std::cerr << "[SimIpcServer] listen() failed: "
                      << std::strerror(errno) << std::endl;
            ::close(server_fd_);
            server_fd_ = -1;
            return false;
        }

        running_.store(true);
        accept_thread_ = std::thread(&SimIpcServer::acceptLoop, this);
        std::cout << "[SimIpcServer] Listening on " << socket_path_
                  << std::endl;
        return true;
    }

    void stop() {
        if (!running_.exchange(false)) return;

        if (accept_thread_.joinable()) {
            accept_thread_.join();
        }

        if (server_fd_ >= 0) {
            ::close(server_fd_);
            server_fd_ = -1;
        }

        ::unlink(socket_path_.c_str());

        // Close all client fds
        {
            std::lock_guard<std::mutex> lock(clients_mutex_);
            for (auto& c : clients_) {
                if (c.fd >= 0) ::close(c.fd);
            }
            clients_.clear();
        }

        std::cout << "[SimIpcServer] Stopped." << std::endl;
    }

    // -- Snapshot broadcast ----------------------------------------------------

    void pushSnapshot() {
        nlohmann::json snap = world_.getFullSnapshot();
        SnapshotHeader shdr = world_.getSnapshotHeader();
        std::vector<uint8_t> payload = nlohmann::json::to_msgpack(snap);

        std::lock_guard<std::mutex> lock(clients_mutex_);
        for (auto& c : clients_) {
            c.sequence++;
            sendFramed(c.fd, MessageType::SNAPSHOT_FULL,
                       shdr.generation, c.sequence, payload);
            c.last_sent_generation = shdr.generation;
        }
    }

    void pushDelta() {
        std::lock_guard<std::mutex> lock(clients_mutex_);
        for (auto& c : clients_) {
            nlohmann::json delta;
            if (c.has_subscription) {
                delta = world_.getFilteredDelta(c.last_sent_generation,
                                                c.sub_aabb_min,
                                                c.sub_aabb_max);
            } else {
                delta = world_.getDelta(c.last_sent_generation);
            }
            if (delta.is_null()) continue;

            DeltaHeader dh;
            dh.base_generation  = delta["base_generation"].get<uint32_t>();
            dh.delta_generation = delta["delta_generation"].get<uint32_t>();
            dh.change_count     = delta["change_count"].get<uint32_t>();

            std::vector<uint8_t> payload = nlohmann::json::to_msgpack(delta);
            c.sequence++;
            sendFramed(c.fd, MessageType::SNAPSHOT_DELTA,
                       dh.delta_generation, c.sequence, payload);
            c.last_sent_generation = dh.delta_generation;
        }
    }

    // -- Client queries --------------------------------------------------------

    bool hasClients() const {
        std::lock_guard<std::mutex> lock(clients_mutex_);
        return !clients_.empty();
    }

    // -- Input drain -----------------------------------------------------------

    std::vector<InputState> drainInput() {
        std::lock_guard<std::mutex> lock(input_mutex_);
        std::vector<InputState> out = std::move(pending_input_);
        pending_input_.clear();
        return out;
    }

private:
    // -- Per-client state ------------------------------------------------------

    struct ClientInfo {
        int      fd                   = -1;
        uint32_t last_sent_generation = 0;
        uint32_t sequence             = 0;

        // Spatial subscription — empty = receive everything (backward compat)
        bool     has_subscription     = false;
        float    sub_aabb_min[3]      = {-1000.f, -1000.f, -1000.f};
        float    sub_aabb_max[3]      = {1000.f, 1000.f, 1000.f};
        uint32_t sub_flags            = 0;
    };

    // -- Accept + receive loop (runs in accept_thread_) ------------------------

    void acceptLoop() {
        while (running_.load()) {
            // Build poll set: server + all clients
            std::vector<struct pollfd> fds;
            fds.reserve(1 + clients_.size());

            struct pollfd spfd{};
            spfd.fd     = server_fd_;
            spfd.events = POLLIN;
            fds.push_back(spfd);

            {
                std::lock_guard<std::mutex> lock(clients_mutex_);
                for (auto& c : clients_) {
                    struct pollfd cpfd{};
                    cpfd.fd     = c.fd;
                    cpfd.events = POLLIN | POLLHUP | POLLERR;
                    fds.push_back(cpfd);
                }
            }

            int pret = ::poll(fds.data(), fds.size(), 50);
            if (pret <= 0) continue;

            // Accept new connections
            if (fds[0].revents & POLLIN) {
                while (true) {
                    sockaddr_un ca{};
                    socklen_t clen = sizeof(ca);
                    int cfd = ::accept(server_fd_,
                                       reinterpret_cast<sockaddr*>(&ca),
                                       &clen);
                    if (cfd < 0) break;

                    int flags = ::fcntl(cfd, F_GETFL, 0);
                    ::fcntl(cfd, F_SETFL, flags | O_NONBLOCK);

                    {
                        std::lock_guard<std::mutex> lock(clients_mutex_);
                        clients_.push_back(ClientInfo{cfd, 0, 0});
                    }

                    // Send full snapshot to new client immediately
                    nlohmann::json snap = world_.getFullSnapshot();
                    SnapshotHeader shdr = world_.getSnapshotHeader();
                    std::vector<uint8_t> payload =
                        nlohmann::json::to_msgpack(snap);

                    {
                        std::lock_guard<std::mutex> lock(clients_mutex_);
                        auto& back = clients_.back();
                        back.sequence++;
                        sendFramed(back.fd, MessageType::SNAPSHOT_FULL,
                                   shdr.generation, back.sequence, payload);
                        back.last_sent_generation = shdr.generation;
                    }

                    std::cout << "[SimIpcServer] Client connected (fd="
                              << cfd << ")" << std::endl;
                }
            }

            // Receive from clients
            std::vector<int> disconnected;
            for (size_t i = 1; i < fds.size(); ++i) {
                if (!(fds[i].revents & (POLLIN | POLLHUP | POLLERR))) {
                    continue;
                }
                if (fds[i].revents & (POLLHUP | POLLERR | POLLNVAL)) {
                    disconnected.push_back(fds[i].fd);
                    continue;
                }

                MessageHeader hdr{};
                std::vector<uint8_t> payload;
                ssize_t n = recvFramed(fds[i].fd, hdr, payload);
                if (n < 0) {
                    disconnected.push_back(fds[i].fd);
                    continue;
                }

                handleClientMessage(fds[i].fd, hdr, payload);
            }

            // Clean up disconnected clients
            if (!disconnected.empty()) {
                std::lock_guard<std::mutex> lock(clients_mutex_);
                for (int cfd : disconnected) {
                    ::close(cfd);
                    clients_.erase(
                        std::remove_if(clients_.begin(), clients_.end(),
                                       [cfd](const ClientInfo& c) {
                                           return c.fd == cfd;
                                       }),
                        clients_.end());
                    std::cout << "[SimIpcServer] Client disconnected (fd="
                              << cfd << ")" << std::endl;
                }
            }
        }
    }

    // -- Message dispatch ------------------------------------------------------

    void handleClientMessage(int fd, const MessageHeader& hdr,
                             const std::vector<uint8_t>& payload) {
        auto type = static_cast<MessageType>(hdr.type);

        switch (type) {
            case MessageType::INPUT_STATE: {
                if (payload.empty()) break;
                auto j = nlohmann::json::from_msgpack(payload);
                InputState state;
                state.kind      = InputState::Kind::Input;
                state.client_fd = fd;
                state.move_forward   = j.value("move_forward", false);
                state.move_backward  = j.value("move_backward", false);
                state.move_left      = j.value("move_left", false);
                state.move_right     = j.value("move_right", false);
                state.move_up        = j.value("move_up", false);
                state.move_down      = j.value("move_down", false);
                state.sprint         = j.value("sprint", false);
                state.crouch         = j.value("crouch", false);
                state.jump           = j.value("jump", false);
                state.action_primary   = j.value("action_primary", false);
                state.action_secondary = j.value("action_secondary", false);
                state.show_hud         = j.value("show_hud", false);
                state.mouse_dx       = j.value("mouse_dx", 0.0f);
                state.mouse_dy       = j.value("mouse_dy", 0.0f);
                state.selected_hotbar_slot =
                    j.value("selected_hotbar_slot", 1);

                std::lock_guard<std::mutex> lock(input_mutex_);
                pending_input_.push_back(std::move(state));
                break;
            }
            case MessageType::CAMERA_UPDATE: {
                if (payload.empty()) break;
                auto j = nlohmann::json::from_msgpack(payload);
                InputState state;
                state.kind      = InputState::Kind::CameraUpdate;
                state.client_fd = fd;
                state.cam_x     = j.value("x", 0.0f);
                state.cam_y     = j.value("y", 0.0f);
                state.cam_z     = j.value("z", 0.0f);
                state.cam_yaw   = j.value("yaw", 0.0f);
                state.cam_pitch = j.value("pitch", 0.0f);

                std::lock_guard<std::mutex> lock(input_mutex_);
                pending_input_.push_back(std::move(state));
                break;
            }
            case MessageType::PING: {
                // Respond with PONG
                sendFramed(fd, MessageType::PONG, 0, 0, {});
                break;
            }
            case MessageType::SHUTDOWN: {
                // Client requesting graceful disconnect
                std::lock_guard<std::mutex> lock(clients_mutex_);
                clients_.erase(
                    std::remove_if(clients_.begin(), clients_.end(),
                                   [fd](const ClientInfo& c) {
                                       return c.fd == fd;
                                   }),
                    clients_.end());
                ::close(fd);
                break;
            }
            case MessageType::SUBSCRIBE_REGION: {
                if (payload.empty()) break;
                auto j = nlohmann::json::from_msgpack(payload);
                SubscriptionRequest req;
                from_json(j, req);
                std::lock_guard<std::mutex> lock(clients_mutex_);
                for (auto& c : clients_) {
                    if (c.fd == fd) {
                        c.has_subscription = true;
                        std::memcpy(c.sub_aabb_min, req.aabb_min, sizeof(float) * 3);
                        std::memcpy(c.sub_aabb_max, req.aabb_max, sizeof(float) * 3);
                        c.sub_flags = req.flags;
                        break;
                    }
                }
                break;
            }
            case MessageType::UNSUBSCRIBE_REGION: {
                std::lock_guard<std::mutex> lock(clients_mutex_);
                for (auto& c : clients_) {
                    if (c.fd == fd) {
                        c.has_subscription = false;
                        c.sub_aabb_min[0] = -1000.f;
                        c.sub_aabb_min[1] = -1000.f;
                        c.sub_aabb_min[2] = -1000.f;
                        c.sub_aabb_max[0] = 1000.f;
                        c.sub_aabb_max[1] = 1000.f;
                        c.sub_aabb_max[2] = 1000.f;
                        c.sub_flags = 0;
                        break;
                    }
                }
                break;
            }
            default:
                break;
        }
    }

    // -- Raw framed I/O --------------------------------------------------------

    bool sendFramed(int fd, MessageType type, uint32_t generation,
                    uint32_t sequence, const std::vector<uint8_t>& payload) {
        if (fd < 0) return false;

        MessageHeader hdr{};
        hdr.type         = static_cast<uint8_t>(type);
        hdr.reserved     = 0;
        hdr.payload_size = static_cast<uint16_t>(payload.size());
        hdr.generation   = generation;
        hdr.sequence     = sequence;
        hdr.checksum     = 0;

        // Send header
        if (!sendAll(fd, &hdr, sizeof(hdr))) return false;

        // Send payload
        if (!payload.empty()) {
            if (!sendAll(fd, payload.data(), payload.size())) return false;
        }
        return true;
    }

    ssize_t recvFramed(int fd, MessageHeader& hdr,
                       std::vector<uint8_t>& payload) {
        if (!recvAll(fd, &hdr, sizeof(hdr))) return -1;

        payload.clear();
        if (hdr.payload_size > 0) {
            payload.resize(hdr.payload_size);
            if (!recvAll(fd, payload.data(), hdr.payload_size)) return -1;
        }
        return static_cast<ssize_t>(hdr.payload_size);
    }

    static bool sendAll(int fd, const void* data, size_t len) {
        const uint8_t* ptr = static_cast<const uint8_t*>(data);
        size_t remaining = len;
        while (remaining > 0) {
            ssize_t sent = ::send(fd, ptr, remaining, MSG_NOSIGNAL);
            if (sent <= 0) {
                if (errno == EINTR) continue;
                return false;
            }
            ptr += sent;
            remaining -= static_cast<size_t>(sent);
        }
        return true;
    }

    static bool recvAll(int fd, void* data, size_t len) {
        uint8_t* ptr = static_cast<uint8_t*>(data);
        size_t remaining = len;
        while (remaining > 0) {
            ssize_t n = ::recv(fd, ptr, remaining, 0);
            if (n <= 0) {
                if (n == 0) return false; // peer closed
                if (errno == EINTR) continue;
                return false;
            }
            ptr += n;
            remaining -= static_cast<size_t>(n);
        }
        return true;
    }

    // -- State -----------------------------------------------------------------

    WorldModel& world_;
    std::string socket_path_;
    int         server_fd_ = -1;
    std::atomic<bool> running_{false};
    std::thread accept_thread_;

    mutable std::mutex clients_mutex_;
    std::vector<ClientInfo> clients_;

    mutable std::mutex input_mutex_;
    std::vector<InputState> pending_input_;
};

} // namespace SCR::IPC

#endif // CAVE_SIM_IPC_SERVER_HPP
