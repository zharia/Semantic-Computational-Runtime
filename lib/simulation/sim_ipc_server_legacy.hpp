#ifndef CAVE_SIM_IPC_SERVER_COMPAT_HPP
#define CAVE_SIM_IPC_SERVER_COMPAT_HPP

#include <string>
#include <vector>
#include <deque>
#include <mutex>
#include <thread>
#include <atomic>
#include <functional>
#include <iostream>
#include <cstring>
#include <cerrno>

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>

#include <nlohmann/json.hpp>

/**
 * SimIPCServer — Legacy JSON-RPC Command Server (backward compat)
 * Kept for monolithic scr_simulation_hub. New IPC uses SimIpcServer.
 */
class SimIPCServer {
public:
    SimIPCServer(const std::string& socket_path = "/tmp/scr_sim_hub.sock")
        : socket_path_(socket_path), running_(false), server_fd_(-1) {}

    ~SimIPCServer() { stop(); }

    bool start(const std::string& path = "") {
        if (!path.empty()) socket_path_ = path;
        if (running_.load()) return true;

        ::unlink(socket_path_.c_str());
        server_fd_ = ::socket(AF_UNIX, SOCK_STREAM, 0);
        if (server_fd_ < 0) {
            std::cerr << "[IPC Server] socket: " << std::strerror(errno) << std::endl;
            return false;
        }

        int flags = ::fcntl(server_fd_, F_GETFL, 0);
        ::fcntl(server_fd_, F_SETFL, flags | O_NONBLOCK);

        sockaddr_un addr{};
        addr.sun_family = AF_UNIX;
        std::strncpy(addr.sun_path, socket_path_.c_str(), sizeof(addr.sun_path) - 1);

        if (::bind(server_fd_, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            std::cerr << "[IPC Server] bind " << socket_path_ << ": " << std::strerror(errno) << std::endl;
            ::close(server_fd_); server_fd_ = -1;
            return false;
        }

        if (::listen(server_fd_, 8) < 0) {
            std::cerr << "[IPC Server] listen: " << std::strerror(errno) << std::endl;
            ::close(server_fd_); server_fd_ = -1;
            return false;
        }

        running_.store(true);
        worker_thread_ = std::thread(&SimIPCServer::networkLoop, this);
        std::cout << "[IPC Server] Listening on " << socket_path_ << std::endl;
        return true;
    }

    void stop() {
        running_.store(false);
        if (worker_thread_.joinable()) worker_thread_.join();
        if (server_fd_ >= 0) { ::close(server_fd_); server_fd_ = -1; }
        ::unlink(socket_path_.c_str());
    }

    using CommandHandler = std::function<nlohmann::json(const std::string&, const nlohmann::json&, bool&, std::string&)>;

    void processQueuedCommands(CommandHandler handler) {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        while (!command_queue_.empty()) {
            auto req = std::move(command_queue_.front());
            command_queue_.pop_front();

            bool success = true;
            std::string error_msg;
            nlohmann::json result = handler(req.method, req.params, success, error_msg);

            nlohmann::json response;
            response["id"] = req.id;
            response["result"] = result;
            response["success"] = success;
            if (!error_msg.empty()) response["error"] = error_msg;

            std::string resp_str = response.dump() + "\n";
            std::lock_guard<std::mutex> clock(clients_mutex_);
            for (auto& c : clients_) {
                if (c.fd >= 0) {
                    ::send(c.fd, resp_str.c_str(), resp_str.size(), MSG_NOSIGNAL);
                }
            }
        }
    }

private:
    struct Client { int fd = -1; };

    void networkLoop() {
        while (running_.load()) {
            pollfd pfd{server_fd_, POLLIN, 0};
            int ret = ::poll(&pfd, 1, 100);
            if (ret > 0 && (pfd.revents & POLLIN)) {
                int client_fd = ::accept(server_fd_, nullptr, nullptr);
                if (client_fd >= 0) {
                    std::lock_guard<std::mutex> lock(clients_mutex_);
                    clients_.push_back({client_fd});
                }
            }

            std::lock_guard<std::mutex> clock(clients_mutex_);
            for (auto& c : clients_) {
                if (c.fd < 0) continue;
                pollfd cpfd{c.fd, POLLIN, 0};
                int cr = ::poll(&cpfd, 1, 0);
                if (cr > 0 && (cpfd.revents & POLLIN)) {
                    char buf[4096];
                    ssize_t n = ::recv(c.fd, buf, sizeof(buf) - 1, 0);
                    if (n <= 0) {
                        ::close(c.fd);
                        c.fd = -1;
                    } else {
                        buf[n] = '\0';
                        try {
                            auto j = nlohmann::json::parse(buf);
                            IPCRequest req;
                            req.id = j.value("id", int64_t(0));
                            req.method = j.value("method", "");
                            req.params = j.value("params", nlohmann::json::object());
                            req.client_fd = c.fd;
                            std::lock_guard<std::mutex> qlock(queue_mutex_);
                            command_queue_.push_back(std::move(req));
                        } catch (...) {}
                    }
                }
            }
            clients_.erase(std::remove_if(clients_.begin(), clients_.end(),
                [](const Client& c) { return c.fd < 0; }), clients_.end());
        }
    }

    struct IPCRequest {
        int64_t id = 0;
        std::string method;
        nlohmann::json params;
        int client_fd = -1;
    };

    std::string socket_path_;
    std::atomic<bool> running_;
    int server_fd_;
    std::thread worker_thread_;
    std::vector<Client> clients_;
    std::mutex clients_mutex_;
    std::deque<IPCRequest> command_queue_;
    std::mutex queue_mutex_;
};

#endif // CAVE_SIM_IPC_SERVER_COMPAT_HPP
