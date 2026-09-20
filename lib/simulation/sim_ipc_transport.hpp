#ifndef CAVE_SIM_IPC_TRANSPORT_HPP
#define CAVE_SIM_IPC_TRANSPORT_HPP

#include <cstdint>
#include <cstring>
#include <vector>
#include <string>
#include <cerrno>
#include <iostream>

#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <utility>

#include "simulation/sim_ipc_protocol.hpp"

namespace SCR::IPC {

/**
 * AF_UNIX transport layer for framed IPC messages.
 * Sends/receives MessageHeader + payload. Supports SCM_RIGHTS FD passing.
 * No OGRE dependencies.
 */
class IpcTransport {
public:
    IpcTransport() : fd_(-1) {}
    explicit IpcTransport(int fd) : fd_(fd) {}
    ~IpcTransport() { disconnect(); }

    // Non-copyable, movable
    IpcTransport(const IpcTransport&) = delete;
    IpcTransport& operator=(const IpcTransport&) = delete;

    IpcTransport(IpcTransport&& o) noexcept : fd_(o.fd_) { o.fd_ = -1; }
    IpcTransport& operator=(IpcTransport&& o) noexcept {
        if (this != &o) { disconnect(); fd_ = o.fd_; o.fd_ = -1; }
        return *this;
    }

    // -- Connection -------------------------------------------------------------

    bool connect(const std::string& socket_path) {
        if (fd_ >= 0) disconnect();

        fd_ = ::socket(AF_UNIX, SOCK_STREAM, 0);
        if (fd_ < 0) {
            std::cerr << "[IPC Transport] socket() failed: " << std::strerror(errno) << std::endl;
            return false;
        }

        sockaddr_un addr{};
        addr.sun_family = AF_UNIX;
        std::strncpy(addr.sun_path, socket_path.c_str(), sizeof(addr.sun_path) - 1);

        if (::connect(fd_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
            std::cerr << "[IPC Transport] connect(" << socket_path << ") failed: "
                      << std::strerror(errno) << std::endl;
            ::close(fd_);
            fd_ = -1;
            return false;
        }

        return true;
    }

    void disconnect() {
        if (fd_ >= 0) {
            ::close(fd_);
            fd_ = -1;
        }
    }

    bool isConnected() const { return fd_ >= 0; }
    int  getSocket() const { return fd_; }

    // -- Framed message I/O -----------------------------------------------------

    bool send(MessageType type, const void* payload, size_t size) {
        if (fd_ < 0) return false;
        if (size > UINT16_MAX) return false;

        MessageHeader hdr{};
        hdr.type         = static_cast<uint8_t>(type);
        hdr.reserved     = 0;
        hdr.payload_size = static_cast<uint16_t>(size);
        hdr.generation   = 0;
        hdr.sequence     = 0;
        hdr.checksum     = 0;

        // Send header
        if (!sendAll(&hdr, sizeof(hdr))) return false;

        // Send payload
        if (size > 0 && payload) {
            if (!sendAll(payload, size)) return false;
        }

        return true;
    }

    /**
     * Receive a framed message. Blocks until header + payload available.
     * Returns payload size on success, -1 on error/disconnect.
     */
    ssize_t receive(MessageHeader& header, std::vector<uint8_t>& payload) {
        if (fd_ < 0) return -1;

        // Read header
        if (!recvAll(&header, sizeof(header))) return -1;

        // Read payload
        payload.clear();
        if (header.payload_size > 0) {
            payload.resize(header.payload_size);
            if (!recvAll(payload.data(), header.payload_size)) return -1;
        }

        return static_cast<ssize_t>(header.payload_size);
    }

    /**
     * Receive with timeout (milliseconds). Returns payload size, 0 on timeout, -1 on error.
     */
    ssize_t receiveTimed(MessageHeader& header, std::vector<uint8_t>& payload, int timeout_ms) {
        if (fd_ < 0) return -1;

        // Wait for header with timeout
        ssize_t ready = waitForReadable(timeout_ms);
        if (ready <= 0) return ready; // 0 = timeout, -1 = error

        // Read header
        if (!recvAll(&header, sizeof(header))) return -1;

        // Read payload
        payload.clear();
        if (header.payload_size > 0) {
            payload.resize(header.payload_size);
            if (!recvAll(payload.data(), header.payload_size)) return -1;
        }

        return static_cast<ssize_t>(header.payload_size);
    }

    // -- File descriptor passing (SCM_RIGHTS) -----------------------------------

    /**
     * Send a file descriptor with an accompanying size descriptor.
     */
    bool sendFd(int fd, size_t size) {
        if (fd_ < 0 || fd < 0) return false;

        // Payload: the size of the shared region
        size_t payload_size = sizeof(size);
        uint8_t payload_buf[sizeof(size)];
        std::memcpy(payload_buf, &size, sizeof(size));

        // Build control message
        alignas(struct cmsghdr) char cbuf[CMSG_SPACE(sizeof(int))];
        std::memset(cbuf, 0, sizeof(cbuf));

        struct iovec iov{};
        iov.iov_base = payload_buf;
        iov.iov_len  = payload_size;

        struct msghdr msg{};
        msg.msg_iov    = &iov;
        msg.msg_iovlen = 1;
        msg.msg_control    = cbuf;
        msg.msg_controllen = sizeof(cbuf);

        struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
        cmsg->cmsg_level = SOL_SOCKET;
        cmsg->cmsg_type  = SCM_RIGHTS;
        cmsg->cmsg_len   = CMSG_LEN(sizeof(int));
        *reinterpret_cast<int*>(CMSG_DATA(cmsg)) = fd;

        ssize_t sent = ::sendmsg(fd_, &msg, 0);
        return sent >= 0;
    }

    /**
     * Receive a file descriptor. Returns fd on success, -1 on error.
     * size receives the accompanying region size.
     */
    int receiveFd(size_t& size) {
        if (fd_ < 0) return -1;

        uint8_t payload_buf[sizeof(size)];
        alignas(struct cmsghdr) char cbuf[CMSG_SPACE(sizeof(int))];
        std::memset(cbuf, 0, sizeof(cbuf));

        struct iovec iov{};
        iov.iov_base = payload_buf;
        iov.iov_len  = sizeof(payload_buf);

        struct msghdr msg{};
        msg.msg_iov    = &iov;
        msg.msg_iovlen = 1;
        msg.msg_control    = cbuf;
        msg.msg_controllen = sizeof(cbuf);

        ssize_t received = ::recvmsg(fd_, &msg, 0);
        if (received <= 0) return -1;

        struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
        if (!cmsg ||
            cmsg->cmsg_level != SOL_SOCKET ||
            cmsg->cmsg_type  != SCM_RIGHTS ||
            cmsg->cmsg_len   != CMSG_LEN(sizeof(int))) {
            return -1;
        }

        int recv_fd = *reinterpret_cast<int*>(CMSG_DATA(cmsg));
        std::memcpy(&size, payload_buf, sizeof(size));
        return recv_fd;
    }

    // -- Shared memory (memfd) zero-copy bulk transfer -------------------------

    /**
     * Create a memfd file descriptor backed by anonymous memory.
     * Returns fd on success, -1 on error.
     */
    int createSharedMemory(size_t size) {
        int fd = ::memfd_create("scr_shm", MFD_CLOEXEC);
        if (fd < 0) {
            std::cerr << "[IPC Transport] memfd_create() failed: "
                      << std::strerror(errno) << std::endl;
            return -1;
        }
        if (::ftruncate(fd, static_cast<off_t>(size)) < 0) {
            std::cerr << "[IPC Transport] ftruncate() failed: "
                      << std::strerror(errno) << std::endl;
            ::close(fd);
            return -1;
        }
        return fd;
    }

    /**
     * Map a shared memory file descriptor into process address space.
     * Returns pointer on success, MAP_FAILED on error.
     */
    void* mapSharedMemory(int fd, size_t size) {
        void* ptr = ::mmap(nullptr, size, PROT_READ | PROT_WRITE,
                           MAP_SHARED, fd, 0);
        if (ptr == MAP_FAILED) {
            std::cerr << "[IPC Transport] mmap() failed: "
                      << std::strerror(errno) << std::endl;
            return MAP_FAILED;
        }
        return ptr;
    }

    /**
     * Unmap a previously mapped shared memory region.
     */
    void unmapSharedMemory(void* ptr, size_t size) {
        if (ptr && ptr != MAP_FAILED) {
            ::munmap(ptr, size);
        }
    }

    /**
     * Send bulk data via shared memory. Creates a memfd, copies data into it,
     * then sends the FD via SCM_RIGHTS. Returns true on success.
     */
    bool sendBulkData(const void* data, size_t size) {
        if (fd_ < 0 || !data || size == 0) return false;

        int shm_fd = createSharedMemory(size);
        if (shm_fd < 0) return false;

        // Map, copy data, unmap
        void* mapped = ::mmap(nullptr, size, PROT_WRITE, MAP_SHARED, shm_fd, 0);
        if (mapped == MAP_FAILED) {
            std::cerr << "[IPC Transport] sendBulkData mmap() failed: "
                      << std::strerror(errno) << std::endl;
            ::close(shm_fd);
            return false;
        }
        std::memcpy(mapped, data, size);
        ::munmap(mapped, size);

        // Send FD + size via existing SCM_RIGHTS mechanism
        bool ok = sendFd(shm_fd, size);
        ::close(shm_fd);
        return ok;
    }

    /**
     * Receive bulk data via shared memory. Receives an FD via SCM_RIGHTS,
     * maps it, and returns the mapped pointer + size.
     * Caller is responsible for calling unmapSharedMemory + close on the fd.
     * Returns {nullptr, 0} on error.
     */
    std::pair<void*, size_t> receiveBulkData() {
        if (fd_ < 0) return {nullptr, 0};

        size_t shm_size = 0;
        int shm_fd = receiveFd(shm_size);
        if (shm_fd < 0 || shm_size == 0) return {nullptr, 0};

        void* mapped = ::mmap(nullptr, shm_size, PROT_READ | PROT_WRITE,
                              MAP_SHARED, shm_fd, 0);
        ::close(shm_fd);

        if (mapped == MAP_FAILED) {
            std::cerr << "[IPC Transport] receiveBulkData mmap() failed: "
                      << std::strerror(errno) << std::endl;
            return {nullptr, 0};
        }

        return {mapped, shm_size};
    }

private:
    // -- Helpers ----------------------------------------------------------------

    bool sendAll(const void* data, size_t len) {
        const uint8_t* ptr = static_cast<const uint8_t*>(data);
        size_t remaining = len;
        while (remaining > 0) {
            ssize_t sent = ::send(fd_, ptr, remaining, MSG_NOSIGNAL);
            if (sent <= 0) {
                if (errno == EINTR) continue;
                return false;
            }
            ptr += sent;
            remaining -= static_cast<size_t>(sent);
        }
        return true;
    }

    bool recvAll(void* data, size_t len) {
        uint8_t* ptr = static_cast<uint8_t*>(data);
        size_t remaining = len;
        while (remaining > 0) {
            ssize_t recvd = ::recv(fd_, ptr, remaining, 0);
            if (recvd <= 0) {
                if (recvd == 0) return false; // peer closed
                if (errno == EINTR) continue;
                return false;
            }
            ptr += recvd;
            remaining -= static_cast<size_t>(recvd);
        }
        return true;
    }

    ssize_t waitForReadable(int timeout_ms) {
        struct pollfd pfd{};
        pfd.fd     = fd_;
        pfd.events = POLLIN;
        return ::poll(&pfd, 1, timeout_ms);
    }

    int fd_;
};

/**
 * RAII wrapper for shared memory regions (memfd + mmap).
 * Owns the fd and mapped pointer; unmaps and closes on destruction.
 * Non-copyable, movable.
 */
struct SharedMemoryRegion {
    int    fd   = -1;
    void*  ptr  = nullptr;
    size_t size = 0;

    SharedMemoryRegion() = default;

    explicit SharedMemoryRegion(size_t s) : size(s) {
        fd = ::memfd_create("scr_shm", MFD_CLOEXEC);
        if (fd < 0) {
            std::cerr << "[SharedMemoryRegion] memfd_create() failed: "
                      << std::strerror(errno) << std::endl;
            fd = -1;
            size = 0;
            return;
        }
        if (::ftruncate(fd, static_cast<off_t>(size)) < 0) {
            std::cerr << "[SharedMemoryRegion] ftruncate() failed: "
                      << std::strerror(errno) << std::endl;
            ::close(fd);
            fd = -1;
            size = 0;
            return;
        }
        ptr = ::mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (ptr == MAP_FAILED) {
            std::cerr << "[SharedMemoryRegion] mmap() failed: "
                      << std::strerror(errno) << std::endl;
            ::close(fd);
            fd = -1;
            ptr = nullptr;
            size = 0;
            return;
        }
    }

    ~SharedMemoryRegion() { destroy(); }

    SharedMemoryRegion(SharedMemoryRegion&& o) noexcept
        : fd(o.fd), ptr(o.ptr), size(o.size) {
        o.fd = -1;
        o.ptr = nullptr;
        o.size = 0;
    }

    SharedMemoryRegion& operator=(SharedMemoryRegion&& o) noexcept {
        if (this != &o) {
            destroy();
            fd = o.fd;
            ptr = o.ptr;
            size = o.size;
            o.fd = -1;
            o.ptr = nullptr;
            o.size = 0;
        }
        return *this;
    }

    SharedMemoryRegion(const SharedMemoryRegion&) = delete;
    SharedMemoryRegion& operator=(const SharedMemoryRegion&) = delete;

    bool valid() const { return ptr != nullptr && size > 0; }

private:
    void destroy() {
        if (ptr && ptr != MAP_FAILED) {
            ::munmap(ptr, size);
        }
        if (fd >= 0) {
            ::close(fd);
        }
        fd = -1;
        ptr = nullptr;
        size = 0;
    }
};

} // namespace SCR::IPC

#endif // CAVE_SIM_IPC_TRANSPORT_HPP
