#ifndef CAVE_WAYLAND_COMPOSITOR_HPP
#define CAVE_WAYLAND_COMPOSITOR_HPP

#include <wayland-server.h>
#include <wayland-server-protocol.h>
#include "xdg_shell_protocol.h"
#include <xkbcommon/xkbcommon.h>

#include <vector>
#include <string>
#include <memory>
#include <unordered_map>
#include <iostream>
#include <cstring>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <cstdlib>
#include <csignal>
#include <sys/types.h>

namespace SCR::Wayland {

struct SurfaceBuffer {
    int width = 0;
    int height = 0;
    int stride = 0;
    uint32_t format = 0;
    std::vector<uint8_t> pixels;
    bool has_new_data = false;
    uint32_t frame_count = 0;
};

struct CompositorSurface {
    uint32_t id = 0;
    struct wl_resource* surface_resource = nullptr;
    struct wl_resource* xdg_surface_resource = nullptr;
    struct wl_resource* xdg_toplevel_resource = nullptr;
    
    std::string title = "Wayland Client";
    std::string app_id = "generic";
    int configured_width = 1280;
    int configured_height = 720;
    bool is_mapped = false;
    
    SurfaceBuffer buffer;
    int dmabuf_prime_fd = -1;
    struct wl_resource* pending_buffer = nullptr;
    struct wl_list frame_callbacks;
};

class WaylandCompositor {
public:
    static WaylandCompositor& get() {
        static WaylandCompositor instance;
        return instance;
    }

    bool initialize(const std::string& requested_socket = "wayland-scr-0") {
        if (initialized_) return true;

        const char* xdg_dir = std::getenv("XDG_RUNTIME_DIR");
        if (!xdg_dir || std::strlen(xdg_dir) == 0) {
            uid_t uid = getuid();
            std::string user_run = "/run/user/" + std::to_string(uid);
            struct stat st;
            if (stat(user_run.c_str(), &st) == 0 && S_ISDIR(st.st_mode)) {
                setenv("XDG_RUNTIME_DIR", user_run.c_str(), 1);
            } else {
                setenv("XDG_RUNTIME_DIR", "/tmp", 1);
            }
        }

        display_ = wl_display_create();
        if (!display_) {
            std::cerr << "[Wayland] Failed to create Wayland display server." << std::endl;
            return false;
        }

        loop_ = wl_display_get_event_loop(display_);

        // 1. Add Display Socket
        if (wl_display_add_socket(display_, requested_socket.c_str()) != 0) {
            // Fallback to auto socket if requested is occupied
            const char* auto_sock = wl_display_add_socket_auto(display_);
            if (!auto_sock) {
                std::cerr << "[Wayland] Failed to bind Wayland socket." << std::endl;
                return false;
            }
            socket_name_ = auto_sock;
        } else {
            socket_name_ = requested_socket;
        }

        std::cout << "================================================================================" << std::endl;
        std::cout << "[Wayland] Embedded Compositor Active on WAYLAND_DISPLAY=" << socket_name_ << std::endl;
        std::cout << "================================================================================" << std::endl;

        // 2. Initialize Core Wayland Globals
        if (wl_display_init_shm(display_) != 0) {
            std::cerr << "[Wayland] Failed to initialize wl_shm." << std::endl;
            return false;
        }

        compositor_global_ = wl_global_create(
            display_, &wl_compositor_interface, 4, this, bindCompositor
        );
        xdg_wm_base_global_ = wl_global_create(
            display_, &xdg_wm_base_interface, 2, this, bindXdgWmBase
        );
        seat_global_ = wl_global_create(
            display_, &wl_seat_interface, 7, this, bindSeat
        );

        // 3. Initialize XKB Context & Keymap for Keyboard Input Sharing
        initXKB();

        initialized_ = true;
        return true;
    }

    void shutdown() {
        if (!initialized_) return;

        if (keymap_fd_ >= 0) {
            close(keymap_fd_);
            keymap_fd_ = -1;
        }
        if (xkb_keymap_) {
            xkb_keymap_unref(xkb_keymap_);
            xkb_keymap_ = nullptr;
        }
        if (xkb_context_) {
            xkb_context_unref(xkb_context_);
            xkb_context_ = nullptr;
        }

        if (seat_global_) wl_global_destroy(seat_global_);
        if (xdg_wm_base_global_) wl_global_destroy(xdg_wm_base_global_);
        if (compositor_global_) wl_global_destroy(compositor_global_);

        if (display_) {
            wl_display_destroy(display_);
            display_ = nullptr;
        }

        initialized_ = false;
        std::cout << "[Wayland] Compositor shutdown complete." << std::endl;
    }

    void dispatch(int timeout_ms = 0) {
        if (!initialized_ || !display_ || !loop_) return;

        // Flush all clients and process pending events
        wl_display_flush_clients(display_);
        wl_event_loop_dispatch(loop_, timeout_ms);
    }

    const std::string& getSocketName() const { return socket_name_; }
    bool isInitialized() const { return initialized_; }

    // Surface Queries
    size_t getSurfaceCount() const { return surfaces_.size(); }

    CompositorSurface* getPrimarySurface() {
        if (surfaces_.empty()) return nullptr;
        return &surfaces_.begin()->second;
    }

    std::unordered_map<uint32_t, CompositorSurface>& getSurfaces() {
        return surfaces_;
    }

    // Evdev Keycode Translation
    static uint32_t sdlToEvdev(int sym) {
        if (sym >= 'a' && sym <= 'z') {
            static const uint32_t letter_map[] = {
                30, 48, 46, 32, 18, 33, 34, 35, 23, 36, 37, 38, 50, // a-m
                49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44  // n-z
            };
            return letter_map[sym - 'a'];
        }
        if (sym >= 'A' && sym <= 'Z') {
            static const uint32_t letter_map[] = {
                30, 48, 46, 32, 18, 33, 34, 35, 23, 36, 37, 38, 50,
                49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44
            };
            return letter_map[sym - 'A'];
        }
        if (sym >= '1' && sym <= '9') return (sym - '1') + 2; // KEY_1..KEY_9
        if (sym == '0') return 11; // KEY_0
        if (sym == 13 || sym == 10 || sym == 0x0D) return 28; // KEY_ENTER
        if (sym == 27) return 1;   // KEY_ESC
        if (sym == 8) return 14;   // KEY_BACKSPACE
        if (sym == 9) return 15;   // KEY_TAB
        if (sym == 32) return 57;  // KEY_SPACE
        if (sym == '-') return 12; // KEY_MINUS
        if (sym == '=') return 13; // KEY_EQUAL
        if (sym == '[') return 26; // KEY_LEFTBRACE
        if (sym == ']') return 27; // KEY_RIGHTBRACE
        if (sym == '\\') return 43; // KEY_BACKSLASH
        if (sym == ';') return 39; // KEY_SEMICOLON
        if (sym == '\'') return 40; // KEY_APOSTROPHE
        if (sym == '`') return 41; // KEY_GRAVE
        if (sym == ',') return 51; // KEY_COMMA
        if (sym == '.') return 52; // KEY_DOT
        if (sym == '/') return 53; // KEY_SLASH
        if (sym == ((1 << 30) | 0x52) || sym == 1073741906) return 103; // KEY_UP
        if (sym == ((1 << 30) | 0x50) || sym == 1073741904) return 105; // KEY_LEFT
        if (sym == ((1 << 30) | 0x4F) || sym == 1073741903) return 106; // KEY_RIGHT
        if (sym == ((1 << 30) | 0x51) || sym == 1073741905) return 108; // KEY_DOWN
        return 0;
    }

    // Process Launching Helpers
    pid_t launchTerminal() {
        // Try multiple wayland terminal emulators in order
        return launchClient("foot || weston-terminal || alacritty || kitty || xterm");
    }

    pid_t launchDemo() {
        return launchClient("weston-flower || weston-smoke || weston-gears || glxgears");
    }

    pid_t launchEditor() {
        return launchClient("weston-editor || gedit || mousepad || xedit");
    }

    pid_t launchClient(const std::string& command) {
        if (!initialized_) {
            if (!initialize("wayland-scr-0")) {
                std::cerr << "[Wayland] Cannot launch client: compositor failed to initialize." << std::endl;
                return -1;
            }
        }

        pid_t pid = fork();
        if (pid == 0) {
            // Child process: set environment and exec
            setenv("WAYLAND_DISPLAY", socket_name_.c_str(), 1);
            setenv("GDK_BACKEND", "wayland", 1);
            setenv("QT_QPA_PLATFORM", "wayland", 1);
            setenv("SDL_VIDEODRIVER", "wayland", 1);
            setenv("CLUTTER_BACKEND", "wayland", 1);

            execl("/bin/sh", "sh", "-c", command.c_str(), (char*)nullptr);
            _exit(127);
        }
        std::cout << "[Wayland] Launched client PID " << pid << " -> " << command << " (WAYLAND_DISPLAY=" << socket_name_ << ")" << std::endl;
        if (pid > 0) {
            active_pids_.push_back(pid);
        }
        return pid;
    }

    void closeClients() {
        std::cout << "[Wayland] Closing " << active_pids_.size() << " active client processes..." << std::endl;
        for (pid_t p : active_pids_) {
            if (p > 0) {
                kill(p, SIGTERM);
            }
        }
        active_pids_.clear();
    }

    void ensureKeyboardFocus(uint32_t surface_id) {
        auto it = surfaces_.find(surface_id);
        if (it == surfaces_.end()) return;
        if (active_keyboard_surface_id_ != surface_id) {
            for (auto* kbd : keyboard_resources_) {
                if (active_keyboard_surface_id_ != 0) {
                    auto old_it = surfaces_.find(active_keyboard_surface_id_);
                    if (old_it != surfaces_.end() && old_it->second.surface_resource) {
                        wl_keyboard_send_leave(kbd, next_serial_++, old_it->second.surface_resource);
                    }
                }
                struct wl_array keys;
                wl_array_init(&keys);
                wl_keyboard_send_enter(kbd, next_serial_++, it->second.surface_resource, &keys);
                wl_array_release(&keys);
            }
            active_keyboard_surface_id_ = surface_id;
        }
    }

    // Input Injection
    void sendPointerMotion(uint32_t surface_id, int x, int y) {
        auto it = surfaces_.find(surface_id);
        if (it == surfaces_.end()) return;

        uint32_t time_ms = getTimestampMs();
        for (auto* pointer : pointer_resources_) {
            if (active_surface_id_ != surface_id) {
                if (active_surface_id_ != 0) {
                    auto old_it = surfaces_.find(active_surface_id_);
                    if (old_it != surfaces_.end() && old_it->second.surface_resource) {
                        wl_pointer_send_leave(pointer, next_serial_++, old_it->second.surface_resource);
                    }
                }
                wl_pointer_send_enter(pointer, next_serial_++, it->second.surface_resource, wl_fixed_from_int(x), wl_fixed_from_int(y));
                active_surface_id_ = surface_id;
            }
            wl_pointer_send_motion(pointer, time_ms, wl_fixed_from_int(x), wl_fixed_from_int(y));
            wl_pointer_send_frame(pointer);
        }
        ensureKeyboardFocus(surface_id);
    }

    void sendPointerButton(uint32_t surface_id, uint32_t button, bool pressed) {
        uint32_t time_ms = getTimestampMs();
        uint32_t state = pressed ? WL_POINTER_BUTTON_STATE_PRESSED : WL_POINTER_BUTTON_STATE_RELEASED;
        uint32_t serial = next_serial_++;

        if (surface_id != 0) {
            ensureKeyboardFocus(surface_id);
        }

        for (auto* pointer : pointer_resources_) {
            wl_pointer_send_button(pointer, serial, time_ms, button, state);
            wl_pointer_send_frame(pointer);
        }
    }

    void sendKey(int sdl_sym, bool pressed) {
        uint32_t evdev_code = sdlToEvdev(sdl_sym);
        if (evdev_code == 0) return;

        if (!surfaces_.empty()) {
            ensureKeyboardFocus(surfaces_.begin()->first);
        }

        uint32_t time_ms = getTimestampMs();
        uint32_t state = pressed ? WL_KEYBOARD_KEY_STATE_PRESSED : WL_KEYBOARD_KEY_STATE_RELEASED;
        uint32_t serial = next_serial_++;

        for (auto* kbd : keyboard_resources_) {
            wl_keyboard_send_key(kbd, serial, time_ms, evdev_code, state);
        }
    }

private:
    WaylandCompositor() = default;
    ~WaylandCompositor() { shutdown(); }

    uint32_t getTimestampMs() {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        return (uint32_t)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
    }

    void initXKB() {
        xkb_context_ = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
        struct xkb_rule_names names = {"evdev", "pc105", "us", "", ""};
        xkb_keymap_ = xkb_keymap_new_from_names(xkb_context_, &names, XKB_KEYMAP_COMPILE_NO_FLAGS);
        if (!xkb_keymap_) return;

        char* keymap_str = xkb_keymap_get_as_string(xkb_keymap_, XKB_KEYMAP_FORMAT_TEXT_V1);
        keymap_size_ = strlen(keymap_str) + 1;

        keymap_fd_ = memfd_create("scr-wayland-xkb-keymap", MFD_CLOEXEC);
        if (keymap_fd_ >= 0) {
            if (ftruncate(keymap_fd_, keymap_size_) == 0) {
                void* p = mmap(nullptr, keymap_size_, PROT_READ | PROT_WRITE, MAP_SHARED, keymap_fd_, 0);
                if (p != MAP_FAILED) {
                    memcpy(p, keymap_str, keymap_size_);
                    munmap(p, keymap_size_);
                }
            }
        }
        free(keymap_str);
    }

    // ── Bind Callbacks ────────────────────────────────────────────────────────
    static void bindCompositor(struct wl_client* client, void* data, uint32_t version, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(data);
        struct wl_resource* resource = wl_resource_create(client, &wl_compositor_interface, version, id);
        wl_resource_set_implementation(resource, &compositor_impl_, comp, nullptr);
    }

    static void bindXdgWmBase(struct wl_client* client, void* data, uint32_t version, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(data);
        struct wl_resource* resource = wl_resource_create(client, &xdg_wm_base_interface, version, id);
        wl_resource_set_implementation(resource, &xdg_wm_base_impl_, comp, nullptr);
    }

    static void bindSeat(struct wl_client* client, void* data, uint32_t version, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(data);
        struct wl_resource* resource = wl_resource_create(client, &wl_seat_interface, version, id);
        wl_resource_set_implementation(resource, &seat_impl_, comp, nullptr);
        wl_seat_send_capabilities(resource, WL_SEAT_CAPABILITY_POINTER | WL_SEAT_CAPABILITY_KEYBOARD);
        wl_seat_send_name(resource, "scr-seat-0");
    }

    // ── Interface Implementations ─────────────────────────────────────────────
    static void compositorCreateSurface(struct wl_client* client, struct wl_resource* resource, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        struct wl_resource* surf_res = wl_resource_create(client, &wl_surface_interface, wl_resource_get_version(resource), id);
        
        uint32_t surf_id = comp->next_surface_id_++;
        CompositorSurface surf;
        surf.id = surf_id;
        surf.surface_resource = surf_res;
        wl_list_init(&surf.frame_callbacks);

        comp->surfaces_[surf_id] = surf;
        wl_resource_set_implementation(surf_res, &surface_impl_, comp, surfaceDestroy);
        std::cout << "[Wayland] Created wl_surface id=" << surf_id << std::endl;
    }

    static void compositorCreateRegion(struct wl_client* client, struct wl_resource* resource, uint32_t id) {
        (void)client; (void)resource; (void)id;
    }

    static void surfaceDestroy(struct wl_resource* resource) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        for (auto it = comp->surfaces_.begin(); it != comp->surfaces_.end(); ++it) {
            if (it->second.surface_resource == resource) {
                std::cout << "[Wayland] Destroyed surface id=" << it->first << std::endl;
                comp->surfaces_.erase(it);
                break;
            }
        }
    }

    static void surfaceAttach(struct wl_client* client, struct wl_resource* resource, struct wl_resource* buffer_resource, int32_t sx, int32_t sy) {
        (void)client; (void)sx; (void)sy;
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        for (auto& pair : comp->surfaces_) {
            if (pair.second.surface_resource == resource) {
                pair.second.pending_buffer = buffer_resource;
                break;
            }
        }
    }

    static void surfaceDamage(struct wl_client* client, struct wl_resource* resource, int32_t x, int32_t y, int32_t width, int32_t height) {
        (void)client; (void)resource; (void)x; (void)y; (void)width; (void)height;
    }

    static void surfaceFrame(struct wl_client* client, struct wl_resource* resource, uint32_t callback_id) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        struct wl_resource* cb = wl_resource_create(client, &wl_callback_interface, 1, callback_id);
        for (auto& pair : comp->surfaces_) {
            if (pair.second.surface_resource == resource) {
                wl_callback_send_done(cb, comp->getTimestampMs());
                wl_resource_destroy(cb);
                break;
            }
        }
    }

    static void surfaceCommit(struct wl_client* client, struct wl_resource* resource) {
        (void)client;
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        for (auto& pair : comp->surfaces_) {
            if (pair.second.surface_resource == resource) {
                auto& s = pair.second;
                if (s.pending_buffer) {
                    struct wl_shm_buffer* shm_buf = wl_shm_buffer_get(s.pending_buffer);
                    if (shm_buf) {
                        int w = wl_shm_buffer_get_width(shm_buf);
                        int h = wl_shm_buffer_get_height(shm_buf);
                        int stride = wl_shm_buffer_get_stride(shm_buf);
                        uint32_t fmt = wl_shm_buffer_get_format(shm_buf);

                        s.buffer.width = w;
                        s.buffer.height = h;
                        s.buffer.stride = stride;
                        s.buffer.format = fmt;

                        size_t total_bytes = stride * h;
                        if (s.buffer.pixels.size() != total_bytes) {
                            s.buffer.pixels.resize(total_bytes);
                        }

                        wl_shm_buffer_begin_access(shm_buf);
                        const void* src = wl_shm_buffer_get_data(shm_buf);
                        std::memcpy(s.buffer.pixels.data(), src, total_bytes);
                        wl_shm_buffer_end_access(shm_buf);

                        s.buffer.has_new_data = true;
                        s.buffer.frame_count++;
                    }
                    wl_buffer_send_release(s.pending_buffer);
                    s.pending_buffer = nullptr;
                }
                break;
            }
        }
    }

    // XDG Shell WM Base
    static void xdgWmBaseDestroy(struct wl_client* client, struct wl_resource* resource) {
        (void)client; wl_resource_destroy(resource);
    }

    static void xdgWmBaseCreatePositioner(struct wl_client* client, struct wl_resource* resource, uint32_t id) {
        (void)client; (void)resource; (void)id;
    }

    static void xdgWmBaseGetXdgSurface(struct wl_client* client, struct wl_resource* resource, uint32_t id, struct wl_resource* surface_res) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        struct wl_resource* xdg_surf_res = wl_resource_create(client, &xdg_surface_interface, wl_resource_get_version(resource), id);
        wl_resource_set_implementation(xdg_surf_res, &xdg_surface_impl_, comp, nullptr);

        for (auto& pair : comp->surfaces_) {
            if (pair.second.surface_resource == surface_res) {
                pair.second.xdg_surface_resource = xdg_surf_res;
                break;
            }
        }
    }

    static void xdgWmBasePong(struct wl_client* client, struct wl_resource* resource, uint32_t serial) {
        (void)client; (void)resource; (void)serial;
    }

    // XDG Surface
    static void xdgSurfaceDestroy(struct wl_client* client, struct wl_resource* resource) {
        (void)client; wl_resource_destroy(resource);
    }

    static void xdgSurfaceGetToplevel(struct wl_client* client, struct wl_resource* resource, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        struct wl_resource* toplevel_res = wl_resource_create(client, &xdg_toplevel_interface, wl_resource_get_version(resource), id);
        wl_resource_set_implementation(toplevel_res, &xdg_toplevel_impl_, comp, nullptr);

        for (auto& pair : comp->surfaces_) {
            if (pair.second.xdg_surface_resource == resource) {
                pair.second.xdg_toplevel_resource = toplevel_res;
                
                // Send initial configure
                struct wl_array states;
                wl_array_init(&states);
                xdg_toplevel_send_configure(toplevel_res, pair.second.configured_width, pair.second.configured_height, &states);
                wl_array_release(&states);

                xdg_surface_send_configure(resource, comp->next_serial_++);
                pair.second.is_mapped = true;
                break;
            }
        }
    }

    static void xdgSurfaceGetPopup(struct wl_client* client, struct wl_resource* resource, uint32_t id, struct wl_resource* parent, struct wl_resource* positioner) {
        (void)client; (void)resource; (void)id; (void)parent; (void)positioner;
    }

    static void xdgSurfaceSetWindowGeometry(struct wl_client* client, struct wl_resource* resource, int32_t x, int32_t y, int32_t width, int32_t height) {
        (void)client; (void)resource; (void)x; (void)y; (void)width; (void)height;
    }

    static void xdgSurfaceAckConfigure(struct wl_client* client, struct wl_resource* resource, uint32_t serial) {
        (void)client; (void)resource; (void)serial;
    }

    // XDG Toplevel
    static void xdgToplevelDestroy(struct wl_client* client, struct wl_resource* resource) {
        (void)client; wl_resource_destroy(resource);
    }
    static void xdgToplevelSetParent(struct wl_client* c, struct wl_resource* r, struct wl_resource* p) { (void)c;(void)r;(void)p; }
    static void xdgToplevelSetTitle(struct wl_client* client, struct wl_resource* resource, const char* title) {
        (void)client;
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        for (auto& pair : comp->surfaces_) {
            if (pair.second.xdg_toplevel_resource == resource) {
                pair.second.title = title ? title : "";
                std::cout << "[Wayland] Surface id=" << pair.first << " title=\"" << pair.second.title << "\"" << std::endl;
                break;
            }
        }
    }
    static void xdgToplevelSetAppId(struct wl_client* client, struct wl_resource* resource, const char* app_id) {
        (void)client;
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        for (auto& pair : comp->surfaces_) {
            if (pair.second.xdg_toplevel_resource == resource) {
                pair.second.app_id = app_id ? app_id : "";
                std::cout << "[Wayland] Surface id=" << pair.first << " app_id=\"" << pair.second.app_id << "\"" << std::endl;
                break;
            }
        }
    }
    static void xdgToplevelShowWindowMenu(struct wl_client* c, struct wl_resource* r, struct wl_resource* s, uint32_t sr, int32_t x, int32_t y) { (void)c;(void)r;(void)s;(void)sr;(void)x;(void)y; }
    static void xdgToplevelMove(struct wl_client* c, struct wl_resource* r, struct wl_resource* s, uint32_t sr) { (void)c;(void)r;(void)s;(void)sr; }
    static void xdgToplevelResize(struct wl_client* c, struct wl_resource* r, struct wl_resource* s, uint32_t sr, uint32_t e) { (void)c;(void)r;(void)s;(void)sr;(void)e; }
    static void xdgToplevelSetMaxSize(struct wl_client* c, struct wl_resource* r, int32_t w, int32_t h) { (void)c;(void)r;(void)w;(void)h; }
    static void xdgToplevelSetMinSize(struct wl_client* c, struct wl_resource* r, int32_t w, int32_t h) { (void)c;(void)r;(void)w;(void)h; }
    static void xdgToplevelSetMaximized(struct wl_client* c, struct wl_resource* r) { (void)c;(void)r; }
    static void xdgToplevelUnsetMaximized(struct wl_client* c, struct wl_resource* r) { (void)c;(void)r; }
    static void xdgToplevelSetFullscreen(struct wl_client* c, struct wl_resource* r, struct wl_resource* o) { (void)c;(void)r;(void)o; }
    static void xdgToplevelUnsetFullscreen(struct wl_client* c, struct wl_resource* r) { (void)c;(void)r; }
    static void xdgToplevelSetMinimized(struct wl_client* c, struct wl_resource* r) { (void)c;(void)r; }

    // Seat
    static void seatGetPointer(struct wl_client* client, struct wl_resource* resource, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        struct wl_resource* p_res = wl_resource_create(client, &wl_pointer_interface, wl_resource_get_version(resource), id);
        wl_resource_set_implementation(p_res, &pointer_impl_, comp, pointerDestroy);
        comp->pointer_resources_.push_back(p_res);
    }

    static void seatGetKeyboard(struct wl_client* client, struct wl_resource* resource, uint32_t id) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(resource));
        struct wl_resource* k_res = wl_resource_create(client, &wl_keyboard_interface, wl_resource_get_version(resource), id);
        wl_resource_set_implementation(k_res, &keyboard_impl_, comp, keyboardDestroy);
        comp->keyboard_resources_.push_back(k_res);

        if (comp->keymap_fd_ >= 0) {
            wl_keyboard_send_keymap(k_res, WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1, comp->keymap_fd_, comp->keymap_size_);
        }
    }

    static void seatGetTouch(struct wl_client* c, struct wl_resource* r, uint32_t id) { (void)c;(void)r;(void)id; }
    static void seatRelease(struct wl_client* c, struct wl_resource* r) { (void)c; wl_resource_destroy(r); }

    static void pointerDestroy(struct wl_resource* res) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(res));
        for (auto it = comp->pointer_resources_.begin(); it != comp->pointer_resources_.end(); ++it) {
            if (*it == res) { comp->pointer_resources_.erase(it); break; }
        }
    }

    static void keyboardDestroy(struct wl_resource* res) {
        auto* comp = static_cast<WaylandCompositor*>(wl_resource_get_user_data(res));
        for (auto it = comp->keyboard_resources_.begin(); it != comp->keyboard_resources_.end(); ++it) {
            if (*it == res) { comp->keyboard_resources_.erase(it); break; }
        }
    }

    static void pointerSetCursor(struct wl_client* c, struct wl_resource* r, uint32_t s, struct wl_resource* sf, int32_t hx, int32_t hy) { (void)c;(void)r;(void)s;(void)sf;(void)hx;(void)hy; }
    static void pointerRelease(struct wl_client* c, struct wl_resource* r) { (void)c; wl_resource_destroy(r); }
    static void keyboardRelease(struct wl_client* c, struct wl_resource* r) { (void)c; wl_resource_destroy(r); }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
    // Static Interface Tables
    inline static const struct wl_compositor_interface compositor_impl_ = {
        compositorCreateSurface,
        compositorCreateRegion
    };

    inline static const struct wl_surface_interface surface_impl_ = {
        nullptr, // destroy
        surfaceAttach,
        surfaceDamage,
        surfaceFrame,
        nullptr, // set_opaque_region
        nullptr, // set_input_region
        surfaceCommit,
        nullptr, // set_buffer_transform
        nullptr, // set_buffer_scale
        nullptr, // damage_buffer
        nullptr  // offset
    };

    inline static const struct xdg_wm_base_interface xdg_wm_base_impl_ = {
        xdgWmBaseDestroy,
        xdgWmBaseCreatePositioner,
        xdgWmBaseGetXdgSurface,
        xdgWmBasePong
    };

    inline static const struct xdg_surface_interface xdg_surface_impl_ = {
        xdgSurfaceDestroy,
        xdgSurfaceGetToplevel,
        xdgSurfaceGetPopup,
        xdgSurfaceSetWindowGeometry,
        xdgSurfaceAckConfigure
    };

    inline static const struct xdg_toplevel_interface xdg_toplevel_impl_ = {
        xdgToplevelDestroy,
        xdgToplevelSetParent,
        xdgToplevelSetTitle,
        xdgToplevelSetAppId,
        xdgToplevelShowWindowMenu,
        xdgToplevelMove,
        xdgToplevelResize,
        xdgToplevelSetMaxSize,
        xdgToplevelSetMinSize,
        xdgToplevelSetMaximized,
        xdgToplevelUnsetMaximized,
        xdgToplevelSetFullscreen,
        xdgToplevelUnsetFullscreen,
        xdgToplevelSetMinimized
    };

    inline static const struct wl_seat_interface seat_impl_ = {
        seatGetPointer,
        seatGetKeyboard,
        seatGetTouch,
        seatRelease
    };

    inline static const struct wl_pointer_interface pointer_impl_ = {
        pointerSetCursor,
        pointerRelease
    };

    inline static const struct wl_keyboard_interface keyboard_impl_ = {
        keyboardRelease
    };
#pragma GCC diagnostic pop

    bool initialized_ = false;
    std::string socket_name_ = "wayland-scr-0";
    struct wl_display* display_ = nullptr;
    struct wl_event_loop* loop_ = nullptr;

    struct wl_global* compositor_global_ = nullptr;
    struct wl_global* xdg_wm_base_global_ = nullptr;
    struct wl_global* seat_global_ = nullptr;

    uint32_t next_surface_id_ = 1;
    uint32_t next_serial_ = 1;
    uint32_t active_surface_id_ = 0;
    uint32_t active_keyboard_surface_id_ = 0;

    std::unordered_map<uint32_t, CompositorSurface> surfaces_;
    std::vector<struct wl_resource*> pointer_resources_;
    std::vector<struct wl_resource*> keyboard_resources_;
    std::vector<pid_t> active_pids_;

    struct xkb_context* xkb_context_ = nullptr;
    struct xkb_keymap* xkb_keymap_ = nullptr;
    int keymap_fd_ = -1;
    size_t keymap_size_ = 0;
};

} // namespace SCR::Wayland

#endif // CAVE_WAYLAND_COMPOSITOR_HPP
