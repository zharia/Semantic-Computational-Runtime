#ifndef CAVE_SIM_IPC_SERVER_HPP
#define CAVE_SIM_IPC_SERVER_HPP

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

namespace SCR::IPC {

struct IPCRequest {
    int64_t id = 0;
    std::string method;
    nlohmann::json params;
    int client_fd = -1;
};

using CommandHandler = std::function<nlohmann::json(const std::string& method, const nlohmann::json& params, bool& success, std::string& error_msg)>;

class SimIPCServer {
public:
    SimIPCServer(const std::string& socket_path = "/tmp/scr_sim_hub.sock")
        : socket_path_(socket_path), running_(false), server_fd_(-1) {}

    ~SimIPCServer() {
        stop();
    }

    bool start(const std::string& path = "") {
        if (!path.empty()) {
            socket_path_ = path;
        }
        if (running_.load()) return true;

        // Unlink old socket file if it exists
        ::unlink(socket_path_.c_str());

        server_fd_ = ::socket(AF_UNIX, SOCK_STREAM, 0);
        if (server_fd_ < 0) {
            std::cerr << "[IPC Server] Failed to create UNIX domain socket: " << std::strerror(errno) << std::endl;
            return false;
        }

        // Set non-blocking on server socket
        int flags = ::fcntl(server_fd_, F_GETFL, 0);
        ::fcntl(server_fd_, F_SETFL, flags | O_NONBLOCK);

        sockaddr_un addr;
        std::memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        std::strncpy(addr.sun_path, socket_path_.c_str(), sizeof(addr.sun_path) - 1);

        if (::bind(server_fd_, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            std::cerr << "[IPC Server] Failed to bind to " << socket_path_ << ": " << std::strerror(errno) << std::endl;
            ::close(server_fd_);
            server_fd_ = -1;
            return false;
        }

        if (::listen(server_fd_, 8) < 0) {
            std::cerr << "[IPC Server] Failed to listen: " << std::strerror(errno) << std::endl;
            ::close(server_fd_);
            server_fd_ = -1;
            return false;
        }

        running_.store(true);
        worker_thread_ = std::thread(&SimIPCServer::networkLoop, this);
        std::cout << "[IPC Server] Listening for remote simulation commands on " << socket_path_ << std::endl;
        return true;
    }

    void stop() {
        if (!running_.exchange(false)) return;

        if (worker_thread_.joinable()) {
            worker_thread_.join();
        }

        if (server_fd_ >= 0) {
            ::close(server_fd_);
            server_fd_ = -1;
        }

        ::unlink(socket_path_.c_str());

        std::lock_guard<std::mutex> lock(clients_mutex_);
        for (int cfd : active_clients_) {
            if (cfd >= 0) ::close(cfd);
        }
        active_clients_.clear();
        std::cout << "[IPC Server] Stopped." << std::endl;
    }

    /**
     * Called on the main render thread to process queued IPC commands synchronously.
     */
    void processQueuedCommands(CommandHandler handler) {
        std::vector<IPCRequest> batch;
        {
            std::lock_guard<std::mutex> lock(queue_mutex_);
            while (!incoming_queue_.empty()) {
                batch.push_back(std::move(incoming_queue_.front()));
                incoming_queue_.pop_front();
            }
        }

        for (auto& req : batch) {
            bool success = true;
            std::string error_msg;
            nlohmann::json result_json;

            try {
                result_json = handler(req.method, req.params, success, error_msg);
            } catch (const std::exception& e) {
                success = false;
                error_msg = e.what();
            } catch (...) {
                success = false;
                error_msg = "Unknown internal error in IPC handler";
            }

            nlohmann::json resp;
            resp["id"] = req.id;
            if (success) {
                resp["status"] = "ok";
                resp["result"] = result_json;
            } else {
                resp["status"] = "error";
                resp["error"] = error_msg;
            }

            sendResponse(req.client_fd, resp);
        }
    }

    bool isRunning() const { return running_.load(); }
    const std::string& getSocketPath() const { return socket_path_; }

private:
    std::string socket_path_;
    std::atomic<bool> running_;
    int server_fd_;
    std::thread worker_thread_;

    std::mutex queue_mutex_;
    std::deque<IPCRequest> incoming_queue_;

    std::mutex clients_mutex_;
    std::vector<int> active_clients_;

    void sendResponse(int client_fd, const nlohmann::json& response) {
        if (client_fd < 0) return;
        std::string serialized = response.dump() + "\n";
        ssize_t sent = ::send(client_fd, serialized.data(), serialized.size(), MSG_NOSIGNAL);
        (void)sent;
    }

    void networkLoop() {
        std::map<int, std::string> client_buffers;

        while (running_.load()) {
            std::vector<struct pollfd> poll_fds;

            // Add server socket
            struct pollfd pfd;
            pfd.fd = server_fd_;
            pfd.events = POLLIN;
            pfd.revents = 0;
            poll_fds.push_back(pfd);

            // Add active clients
            {
                std::lock_guard<std::mutex> lock(clients_mutex_);
                for (int cfd : active_clients_) {
                    struct pollfd cpfd;
                    cpfd.fd = cfd;
                    cpfd.events = POLLIN | POLLHUP | POLLERR;
                    cpfd.revents = 0;
                    poll_fds.push_back(cpfd);
                }
            }

            int poll_ret = ::poll(poll_fds.data(), poll_fds.size(), 50); // 50ms timeout
            if (poll_ret <= 0) continue;

            // Check new incoming connections on server_fd
            if (poll_fds[0].revents & POLLIN) {
                while (true) {
                    sockaddr_un client_addr;
                    socklen_t client_len = sizeof(client_addr);
                    int client_fd = ::accept(server_fd_, (struct sockaddr*)&client_addr, &client_len);
                    if (client_fd < 0) {
                        break; // No more pending connections
                    }

                    // Set non-blocking on client socket
                    int flags = ::fcntl(client_fd, F_GETFL, 0);
                    ::fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);

                    {
                        std::lock_guard<std::mutex> lock(clients_mutex_);
                        active_clients_.push_back(client_fd);
                    }
                    client_buffers[client_fd] = "";
                }
            }

            // Check client fds
            std::vector<int> disconnected_clients;
            for (size_t i = 1; i < poll_fds.size(); ++i) {
                int cfd = poll_fds[i].fd;
                short revents = poll_fds[i].revents;

                if (revents & (POLLIN)) {
                    char buf[4096];
                    while (true) {
                        ssize_t bytes_read = ::recv(cfd, buf, sizeof(buf) - 1, 0);
                        if (bytes_read > 0) {
                            buf[bytes_read] = '\0';
                            client_buffers[cfd].append(buf, bytes_read);

                            // Process complete line-delimited JSON commands
                            size_t newline_pos;
                            while ((newline_pos = client_buffers[cfd].find('\n')) != std::string::npos) {
                                std::string line = client_buffers[cfd].substr(0, newline_pos);
                                client_buffers[cfd].erase(0, newline_pos + 1);

                                // Trim carriage return if present
                                if (!line.empty() && line.back() == '\r') {
                                    line.pop_back();
                                }
                                if (line.empty()) continue;

                                try {
                                    auto parsed = nlohmann::json::parse(line);
                                    IPCRequest req;
                                    req.id = parsed.value("id", (int64_t)0);
                                    req.method = parsed.value("method", "");
                                    req.params = parsed.value("params", nlohmann::json::object());
                                    req.client_fd = cfd;

                                    std::lock_guard<std::mutex> lock(queue_mutex_);
                                    incoming_queue_.push_back(std::move(req));
                                } catch (const std::exception& e) {
                                    nlohmann::json err_resp;
                                    err_resp["id"] = 0;
                                    err_resp["status"] = "error";
                                    err_resp["error"] = std::string("JSON parse error: ") + e.what();
                                    sendResponse(cfd, err_resp);
                                }
                            }
                        } else if (bytes_read == 0) {
                            // Connection closed by client
                            disconnected_clients.push_back(cfd);
                            break;
                        } else {
                            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                                disconnected_clients.push_back(cfd);
                            }
                            break;
                        }
                    }
                } else if (revents & (POLLHUP | POLLERR | POLLNVAL)) {
                    disconnected_clients.push_back(cfd);
                }
            }

            // Cleanup disconnected clients
            if (!disconnected_clients.empty()) {
                std::lock_guard<std::mutex> lock(clients_mutex_);
                for (int cfd : disconnected_clients) {
                    ::close(cfd);
                    client_buffers.erase(cfd);
                    active_clients_.erase(
                        std::remove(active_clients_.begin(), active_clients_.end(), cfd),
                        active_clients_.end()
                    );
                }
            }
        }
    }
};

} // namespace SCR::IPC

#endif // CAVE_SIM_IPC_SERVER_HPP
