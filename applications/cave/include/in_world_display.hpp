#ifndef CAVE_IN_WORLD_DISPLAY_HPP
#define CAVE_IN_WORLD_DISPLAY_HPP

#include <Ogre.h>

#include "wayland_compositor.hpp"
#include "dmabuf_c_api.h"
#include <iostream>
#include <vector>
#include <cmath>

namespace SCR::Display {

enum class DisplayMode {
    FLOATING_HOLOGRAM,
    OBSIDIAN_MONOLITH,
    TACTICAL_HUD_ATTACHED
};

class InWorldDisplaySystem {
public:
    DisplayMode display_mode = DisplayMode::FLOATING_HOLOGRAM;
    DmaBufHandle dmabuf_handle_ = nullptr;
    int current_prime_fd_ = -1;
    bool is_visible = false;

    InWorldDisplaySystem() = default;
    ~InWorldDisplaySystem() {
        if (dmabuf_handle_) {
            dmabuf_destroy_handle(dmabuf_handle_);
            dmabuf_handle_ = nullptr;
        }
    }

    void initialize(Ogre::SceneManager* scnMgr, const Ogre::Vector3& world_pos, const Ogre::Vector3& look_target) {
        scnMgr_ = scnMgr;
        screen_pos_ = world_pos;
        look_target_ = look_target;
        is_visible = false;

        // Compute orientation facing target
        Ogre::Vector3 fwd = (look_target - world_pos).normalisedCopy();
        Ogre::Vector3 up(0, 1, 0);
        Ogre::Vector3 right = up.crossProduct(fwd).normalisedCopy();
        up = fwd.crossProduct(right).normalisedCopy();

        screen_normal_ = fwd;
        screen_right_ = right;
        screen_up_ = up;

        createFallbackTexture();
        createDisplayMaterial();
    }

    void summonInFrontOf(const Ogre::Vector3& eye_pos, const Ogre::Vector3& view_dir, float distance = 2.5f) {
        Ogre::Vector3 fwd = view_dir.normalisedCopy();
        // Keep screen vertically upright
        fwd.y = 0.0f;
        if (fwd.squaredLength() < 1e-4f) fwd = Ogre::Vector3(0, 0, 1);
        fwd.normalise();

        screen_pos_ = eye_pos + fwd * distance;
        look_target_ = eye_pos;

        Ogre::Vector3 normal = -fwd; // screen faces towards player
        Ogre::Vector3 up(0, 1, 0);
        Ogre::Vector3 right = normal.crossProduct(up).normalisedCopy();

        screen_normal_ = normal;
        screen_right_ = right;
        screen_up_ = up;
        is_visible = true;
    }

    void hide() {
        is_visible = false;
    }

    void update(Ogre::ManualObject* displayMesh, float dt, Wayland::WaylandCompositor& compositor) {
        if (!scnMgr_ || !displayMesh) return;
        (void)dt;

        Wayland::CompositorSurface* surf = compositor.getPrimarySurface();
        bool has_active_client = (surf != nullptr && surf->is_mapped && surf->buffer.width > 0 && surf->buffer.height > 0);

        if (is_visible && has_active_client) {
            updateClientTexture(surf);
            renderDisplayMesh(displayMesh, true, surf);
        } else {
            displayMesh->clear();
        }
    }

    /**
     * Intersects a camera view ray with the in-world 3D display quad.
     * Returns true if ray hits the screen, setting out_u and out_v in [0, 1].
     */
    bool raycast(const Ogre::Ray& ray, float& out_u, float& out_v, float& out_dist) const {
        if (!is_visible) return false;

        // Plane intersection: (p - p0) . n = 0
        float denom = ray.getDirection().dotProduct(screen_normal_);
        if (std::abs(denom) < 1e-4f) return false;

        float t = (screen_pos_ - ray.getOrigin()).dotProduct(screen_normal_) / denom;
        if (t <= 0.0f || t > 50.0f) return false; // Max interaction reach 50m

        Ogre::Vector3 hit = ray.getPoint(t);
        Ogre::Vector3 rel = hit - screen_pos_;

        float proj_x = rel.dotProduct(screen_right_);
        float proj_y = rel.dotProduct(screen_up_);

        float half_w = screen_width_ * 0.5f;
        float half_h = screen_height_ * 0.5f;

        if (proj_x >= -half_w && proj_x <= half_w && proj_y >= -half_h && proj_y <= half_h) {
            out_u = (proj_x + half_w) / screen_width_;
            out_v = 1.0f - ((proj_y + half_h) / screen_height_); // UV Y flipped
            out_dist = t;
            return true;
        }

        return false;
    }

    const Ogre::Vector3& getPosition() const { return screen_pos_; }
    void setPosition(const Ogre::Vector3& p) { screen_pos_ = p; }
    void setOrientation(const Ogre::Vector3& fwd, const Ogre::Vector3& up, const Ogre::Vector3& right) {
        screen_normal_ = fwd;
        screen_up_ = up;
        screen_right_ = right;
    }

    float getWidth() const { return screen_width_; }
    float getHeight() const { return screen_height_; }

private:
    // ── Built-in 8x8 Bitmap Font for In-World Wayland Terminal Display ───────
    static void drawChar8x8(uint32_t* dst, int pitch, int width, int height, int start_x, int start_y, char c, uint32_t color, int scale = 2) {
        // Standard 8x8 font representation for ASCII 32..126
        static const uint8_t font8x8[96][8] = {
            {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}, // ' '
            {0x18,0x3C,0x3C,0x18,0x18,0x00,0x18,0x00}, // '!'
            {0x66,0x66,0x24,0x00,0x00,0x00,0x00,0x00}, // '"'
            {0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00}, // '#'
            {0x18,0x3E,0x60,0x3C,0x06,0x7C,0x18,0x00}, // '$'
            {0x00,0x66,0xA6,0xD8,0x1B,0x65,0x66,0x00}, // '%'
            {0x38,0x6C,0x38,0x76,0xDC,0xCC,0x76,0x00}, // '&'
            {0x18,0x18,0x30,0x00,0x00,0x00,0x00,0x00}, // '''
            {0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00}, // '('
            {0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00}, // ')'
            {0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00}, // '*'
            {0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00}, // '+'
            {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30}, // ','
            {0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00}, // '-'
            {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00}, // '.'
            {0x00,0x06,0x0C,0x18,0x30,0x60,0x40,0x00}, // '/'
            {0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00}, // '0'
            {0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00}, // '1'
            {0x3C,0x66,0x06,0x1C,0x30,0x60,0x7E,0x00}, // '2'
            {0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00}, // '3'
            {0x0C,0x1C,0x3C,0x6C,0xFE,0x0C,0x0C,0x00}, // '4'
            {0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0x00}, // '5'
            {0x3C,0x66,0x60,0x7C,0x66,0x66,0x3C,0x00}, // '6'
            {0x7E,0x06,0x0C,0x18,0x30,0x30,0x30,0x00}, // '7'
            {0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0x00}, // '8'
            {0x3C,0x66,0x66,0x3E,0x06,0x66,0x3C,0x00}, // '9'
            {0x00,0x18,0x18,0x00,0x18,0x18,0x00,0x00}, // ':'
            {0x00,0x18,0x18,0x00,0x18,0x18,0x30,0x00}, // ';'
            {0x0C,0x18,0x30,0x60,0x30,0x18,0x0C,0x00}, // '<'
            {0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00}, // '='
            {0x30,0x18,0x0C,0x06,0x0C,0x18,0x30,0x00}, // '>'
            {0x3C,0x66,0x06,0x1C,0x18,0x00,0x18,0x00}, // '?'
            {0x3C,0x66,0x6E,0x6E,0x60,0x62,0x3C,0x00}, // '@'
            {0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00}, // 'A'
            {0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00}, // 'B'
            {0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00}, // 'C'
            {0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00}, // 'D'
            {0x7E,0x60,0x60,0x7C,0x60,0x60,0x7E,0x00}, // 'E'
            {0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0x00}, // 'F'
            {0x3C,0x66,0x60,0x6E,0x66,0x66,0x3C,0x00}, // 'G'
            {0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00}, // 'H'
            {0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00}, // 'I'
            {0x0E,0x06,0x06,0x06,0x06,0x66,0x3C,0x00}, // 'J'
            {0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00}, // 'K'
            {0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00}, // 'L'
            {0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00}, // 'M'
            {0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00}, // 'N'
            {0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00}, // 'O'
            {0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00}, // 'P'
            {0x3C,0x66,0x66,0x66,0x6E,0x3C,0x0E,0x00}, // 'Q'
            {0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00}, // 'R'
            {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00}, // 'S'
            {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00}, // 'T'
            {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00}, // 'U'
            {0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00}, // 'V'
            {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00}, // 'W'
            {0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00}, // 'X'
            {0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00}, // 'Y'
            {0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00}, // 'Z'
            {0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00}, // '['
            {0x00,0x60,0x30,0x18,0x0C,0x06,0x02,0x00}, // '\'
            {0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00}, // ']'
            {0x18,0x3C,0x66,0x00,0x00,0x00,0x00,0x00}, // '^'
            {0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0x00}, // '_'
            {0x30,0x18,0x0C,0x00,0x00,0x00,0x00,0x00}, // '`'
            {0x00,0x00,0x3C,0x06,0x3E,0x66,0x3B,0x00}, // 'a'
            {0x60,0x60,0x7C,0x66,0x66,0x66,0x7C,0x00}, // 'b'
            {0x00,0x00,0x3C,0x66,0x60,0x66,0x3C,0x00}, // 'c'
            {0x06,0x06,0x3E,0x66,0x66,0x66,0x3E,0x00}, // 'd'
            {0x00,0x00,0x3C,0x66,0x7E,0x60,0x3C,0x00}, // 'e'
            {0x0E,0x18,0x7E,0x18,0x18,0x18,0x18,0x00}, // 'f'
            {0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x7C}, // 'g'
            {0x60,0x60,0x7C,0x66,0x66,0x66,0x66,0x00}, // 'h'
            {0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00}, // 'i'
            {0x06,0x00,0x0E,0x06,0x06,0x66,0x3C,0x00}, // 'j'
            {0x60,0x60,0x66,0x6C,0x78,0x6C,0x66,0x00}, // 'k'
            {0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00}, // 'l'
            {0x00,0x00,0x66,0x7F,0x7B,0x63,0x63,0x00}, // 'm'
            {0x00,0x00,0x7C,0x66,0x66,0x66,0x66,0x00}, // 'n'
            {0x00,0x00,0x3C,0x66,0x66,0x66,0x3C,0x00}, // 'o'
            {0x00,0x00,0x7C,0x66,0x66,0x7C,0x60,0x60}, // 'p'
            {0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x06}, // 'q'
            {0x00,0x00,0x7C,0x66,0x60,0x60,0x60,0x00}, // 'r'
            {0x00,0x00,0x3E,0x60,0x3C,0x06,0x7C,0x00}, // 's'
            {0x18,0x18,0x7E,0x18,0x18,0x18,0x0E,0x00}, // 't'
            {0x00,0x00,0x66,0x66,0x66,0x66,0x3B,0x00}, // 'u'
            {0x00,0x00,0x66,0x66,0x66,0x3C,0x18,0x00}, // 'v'
            {0x00,0x00,0x63,0x6B,0x7F,0x3E,0x36,0x00}, // 'w'
            {0x00,0x00,0x66,0x3C,0x18,0x3C,0x66,0x00}, // 'x'
            {0x00,0x00,0x66,0x66,0x66,0x3E,0x06,0x7C}, // 'y'
            {0x00,0x00,0x7E,0x0C,0x18,0x30,0x7E,0x00}, // 'z'
            {0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00}, // '{'
            {0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00}, // '|'
            {0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00}, // '}'
            {0x76,0xDC,0x00,0x00,0x00,0x00,0x00,0x00}, // '~'
            {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}
        };

        if (c < 32 || c > 126) c = ' ';
        const uint8_t* glyph = font8x8[c - 32];

        // Draw shadow first
        uint32_t shadow_color = 0xFF040810;
        for (int r = 0; r < 8; ++r) {
            uint8_t row_bits = glyph[r];
            if (!row_bits) continue;
            for (int col = 0; col < 8; ++col) {
                if (row_bits & (0x80 >> col)) {
                    for (int dy = 0; dy < scale; ++dy) {
                        for (int dx = 0; dx < scale; ++dx) {
                            int px = start_x + col * scale + dx + 1;
                            int py = start_y + r * scale + dy + 1;
                            if (px >= 0 && px < width && py >= 0 && py < height) {
                                dst[py * pitch + px] = shadow_color;
                            }
                        }
                    }
                }
            }
        }

        // Draw foreground
        for (int r = 0; r < 8; ++r) {
            uint8_t row_bits = glyph[r];
            if (!row_bits) continue;
            for (int col = 0; col < 8; ++col) {
                if (row_bits & (0x80 >> col)) {
                    for (int dy = 0; dy < scale; ++dy) {
                        for (int dx = 0; dx < scale; ++dx) {
                            int px = start_x + col * scale + dx;
                            int py = start_y + r * scale + dy;
                            if (px >= 0 && px < width && py >= 0 && py < height) {
                                dst[py * pitch + px] = color;
                            }
                        }
                    }
                }
            }
        }
    }

    static int getCharAdvance(char c, int scale) {
        if (c == ' ') return 4 * scale;
        if (c == 'i' || c == 'l' || c == '1' || c == '.' || c == ':' || c == ';' || c == '!' || c == '|' || c == '\'' || c == '`' || c == ',')
            return 5 * scale;
        if (c == '(' || c == ')' || c == '[' || c == ']' || c == '{' || c == '}' || c == '<' || c == '>')
            return 6 * scale;
        if (c == 'r' || c == 't' || c == 'f' || c == 'j' || c == '-')
            return 6 * scale;
        if (c == 'M' || c == 'W' || c == 'm' || c == 'w' || c == '@' || c == '%' || c == '#')
            return 9 * scale;
        return 7 * scale;
    }

    static void drawString(uint32_t* dst, int pitch, int width, int height, int start_x, int start_y, const std::string& text, uint32_t color, int scale = 2) {
        int cur_x = start_x;
        for (char c : text) {
            if (c == ' ') {
                cur_x += getCharAdvance(' ', scale);
            } else {
                drawChar8x8(dst, pitch, width, height, cur_x, start_y, c, color, scale);
                cur_x += getCharAdvance(c, scale) + 1;
            }
        }
    }

    void createFallbackTexture() {
        tex_width_ = 1280;
        tex_height_ = 720;
        texture_name_ = "SCR/WaylandDisplayTexture";

        auto& tm = Ogre::TextureManager::getSingleton();
        if (tm.resourceExists(texture_name_)) {
            tm.remove(texture_name_);
        }

        display_tex_ = tm.createManual(
            texture_name_,
            Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
            Ogre::TEX_TYPE_2D,
            tex_width_, tex_height_,
            0,
            Ogre::PF_BYTE_BGRA,
            Ogre::TU_DYNAMIC_WRITE_ONLY_DISCARDABLE
        );

        // Fill with futuristic cyberpunk standby wallpaper & interactive instructions
        Ogre::HardwarePixelBufferSharedPtr pixelBuffer = display_tex_->getBuffer();
        pixelBuffer->lock(Ogre::HardwareBuffer::HBL_DISCARD);
        const Ogre::PixelBox& pb = pixelBuffer->getCurrentLock();
        uint32_t* dst = reinterpret_cast<uint32_t*>(pb.data);

        for (int y = 0; y < tex_height_; ++y) {
            for (int x = 0; x < tex_width_; ++x) {
                // Cyberpunk dark slate background with fine blueprint grid
                bool major_grid = (x % 64 == 0) || (y % 64 == 0) || (x == tex_width_ - 1) || (y == tex_height_ - 1);
                bool minor_grid = (x % 16 == 0) || (y % 16 == 0);
                
                uint8_t r = 8 + (y * 12 / tex_height_);
                uint8_t g = 14 + (x * 12 / tex_width_);
                uint8_t b = 28 + (y * 24 / tex_height_);
                uint8_t a = 255;

                if (major_grid) {
                    r = 30; g = 100; b = 180;
                } else if (minor_grid) {
                    r = 16; g = 38; b = 64;
                }

                dst[y * pb.rowPitch + x] = (a << 24) | (r << 16) | (g << 8) | b;
            }
        }

        // Draw HUD Frame & Header
        uint32_t col_cyan    = 0xFF00E5FF; // BGRA format
        uint32_t col_gold    = 0xFFFFD700;
        uint32_t col_green   = 0xFF00FF66;
        uint32_t col_white   = 0xFFFFFFFF;
        uint32_t col_dim     = 0xFF88AACC;

        int p = pb.rowPitch;
        int w = tex_width_;
        int h = tex_height_;

        std::string sock = Wayland::WaylandCompositor::get().getSocketName();
        if (sock.empty()) sock = "wayland-scr-0";

        drawString(dst, p, w, h, 60, 50,  "================================================================================", col_cyan, 2);
        drawString(dst, p, w, h, 60, 75,  ("       SCR WAYLAND COMPOSITOR 3D HOST  |  WAYLAND_DISPLAY=" + sock).c_str(), col_gold, 2);
        drawString(dst, p, w, h, 60, 100, "================================================================================", col_cyan, 2);

        drawString(dst, p, w, h, 60, 150, "STATUS:  STANDBY -- WAITING FOR WAYLAND CLIENT TO ATTACH BUFFER", col_green, 2);
        drawString(dst, p, w, h, 60, 180, ("SOCKET:  $XDG_RUNTIME_DIR/" + sock).c_str(), col_white, 2);
        drawString(dst, p, w, h, 60, 210, "FORMAT:  wl_shm ARGB8888 / XRGB8888  |  Target Surface: 1280x720 60Hz", col_dim, 2);

        drawString(dst, p, w, h, 60, 260, "--------------------------------------------------------------------------------", col_dim, 2);
        drawString(dst, p, w, h, 60, 285, "QUICK APPLICATION LAUNCH SHORTCUTS (PRESS KEY):", col_gold, 2);
        drawString(dst, p, w, h, 60, 310, "--------------------------------------------------------------------------------", col_dim, 2);

        drawString(dst, p, w, h, 80, 340, "[ F1 ]  Launch Wayland Terminal Emulator  (foot / weston-terminal / alacritty)", col_white, 2);
        drawString(dst, p, w, h, 80, 375, "[ F2 ]  Launch Wayland Interactive Demo   (weston-flower / weston-smoke)", col_white, 2);
        drawString(dst, p, w, h, 80, 410, "[ F3 ]  Launch Wayland Text Editor        (weston-editor)", col_white, 2);
        drawString(dst, p, w, h, 80, 445, "[ F4 ]  Reset / Close Active Wayland Client Window", col_white, 2);

        drawString(dst, p, w, h, 60, 485, "--------------------------------------------------------------------------------", col_dim, 2);
        drawString(dst, p, w, h, 60, 510, "HOW TO INTERACT WITH APPLICATIONS ON THIS SURFACE:", col_gold, 2);
        drawString(dst, p, w, h, 60, 535, "--------------------------------------------------------------------------------", col_dim, 2);

        drawString(dst, p, w, h, 80, 560, "* Aim your center reticle directly at this screen to position mouse pointer.", col_cyan, 2);
        drawString(dst, p, w, h, 80, 590, "* Left-Click to click GUI buttons or focus interactive terminal input.", col_cyan, 2);
        drawString(dst, p, w, h, 80, 620, "* Type on your keyboard while looking at the screen to send keystrokes.", col_cyan, 2);

        drawString(dst, p, w, h, 60, 670, ("External: In any shell run ->  WAYLAND_DISPLAY=" + sock + " <app_name> &").c_str(), col_green, 2);

        pixelBuffer->unlock();
    }

    void createDisplayMaterial() {
        material_name_ = "SCR/WaylandDisplayMaterial";
        auto& mm = Ogre::MaterialManager::getSingleton();
        if (mm.resourceExists(material_name_)) {
            mm.remove(material_name_);
        }

        mat_ = mm.create(material_name_, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        Ogre::Pass* p = mat_->getTechnique(0)->getPass(0);
        p->setLightingEnabled(false);
        p->setSceneBlending(Ogre::SBT_TRANSPARENT_ALPHA);
        p->setDepthWriteEnabled(false);
        p->setDepthCheckEnabled(true);
        p->setCullingMode(Ogre::CULL_NONE);
        p->setShadingMode(Ogre::SO_FLAT);

        Ogre::TextureUnitState* texUnit = p->createTextureUnitState(texture_name_);
        texUnit->setTextureFiltering(Ogre::TFO_BILINEAR);
    }

    void updateClientTexture(Wayland::CompositorSurface* surf) {
        if (!surf || surf->buffer.pixels.empty()) return;

        int w = surf->buffer.width;
        int h = surf->buffer.height;

        if (w != tex_width_ || h != tex_height_) {
            tex_width_ = w;
            tex_height_ = h;
            createFallbackTexture();
            if (mat_) {
                mat_->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName(texture_name_);
            }
        }

        // Hardware DMA-BUF Zero-Copy Path
        if (surf->dmabuf_prime_fd >= 0) {
            if (current_prime_fd_ != surf->dmabuf_prime_fd) {
                if (dmabuf_handle_) {
                    dmabuf_destroy_handle(dmabuf_handle_);
                }
                current_prime_fd_ = surf->dmabuf_prime_fd;
                dmabuf_handle_ = dmabuf_import_egl_image(current_prime_fd_, w, h, surf->buffer.stride, DRM_FORMAT_ARGB8888);
            }
        }

        if (surf->buffer.has_new_data && display_tex_) {
            Ogre::HardwarePixelBufferSharedPtr pixelBuffer = display_tex_->getBuffer();
            pixelBuffer->lock(Ogre::HardwareBuffer::HBL_DISCARD);
            const Ogre::PixelBox& pb = pixelBuffer->getCurrentLock();
            uint8_t* pDest = static_cast<uint8_t*>(pb.data);

            const uint8_t* pSrc = surf->buffer.pixels.data();
            int src_stride = surf->buffer.stride;
            int dst_stride = pb.rowPitch * 4;

            for (int row = 0; row < h; ++row) {
                std::memcpy(pDest + row * dst_stride, pSrc + row * src_stride, std::min(src_stride, dst_stride));
            }

            pixelBuffer->unlock();
            surf->buffer.has_new_data = false;
        }
    }

    void renderDisplayMesh(Ogre::ManualObject* mesh, bool has_client, Wayland::CompositorSurface* surf) {
        (void)has_client; (void)surf;
        mesh->clear();

        // 1. Render Screen Display Quad with Wayland Texture
        mesh->begin(material_name_, Ogre::RenderOperation::OT_TRIANGLE_LIST);

        float hw = screen_width_ * 0.5f;
        float hh = screen_height_ * 0.5f;

        Ogre::Vector3 p_bl = screen_pos_ - screen_right_ * hw - screen_up_ * hh;
        Ogre::Vector3 p_br = screen_pos_ + screen_right_ * hw - screen_up_ * hh;
        Ogre::Vector3 p_tr = screen_pos_ + screen_right_ * hw + screen_up_ * hh;
        Ogre::Vector3 p_tl = screen_pos_ - screen_right_ * hw + screen_up_ * hh;

        mesh->position(p_bl); mesh->normal(screen_normal_); mesh->textureCoord(0.0f, 1.0f);
        mesh->position(p_br); mesh->normal(screen_normal_); mesh->textureCoord(1.0f, 1.0f);
        mesh->position(p_tr); mesh->normal(screen_normal_); mesh->textureCoord(1.0f, 0.0f);
        mesh->position(p_tl); mesh->normal(screen_normal_); mesh->textureCoord(0.0f, 0.0f);

        // Front Face
        mesh->triangle(0, 1, 2);
        mesh->triangle(0, 2, 3);
        // Back Face (double-sided display)
        mesh->triangle(0, 2, 1);
        mesh->triangle(0, 3, 2);

        mesh->end();

        // 2. Render Futuristic Hologram Border Frame & Stand Pedestal
        mesh->begin("SCR/HUDMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        Ogre::ColourValue c_glow(0.15f, 0.75f, 1.00f, 0.85f);
        Ogre::ColourValue c_dark(0.08f, 0.12f, 0.20f, 0.95f);
        Ogre::ColourValue c_accent(1.00f, 0.65f, 0.15f, 0.90f);

        uint32_t frame_vert_idx = 0;
        float bw = 0.06f; // border width
        // Top Frame
        emitFrameBar(p_tl - screen_up_ * bw, p_tr - screen_up_ * bw, bw, c_glow, mesh, frame_vert_idx);
        // Bottom Frame
        emitFrameBar(p_bl, p_br, bw, c_glow, mesh, frame_vert_idx);
        // Left Frame
        emitFrameBar(p_bl, p_tl, bw, c_glow, mesh, frame_vert_idx);
        // Right Frame
        emitFrameBar(p_br, p_tr, bw, c_glow, mesh, frame_vert_idx);

        // Pedestal / Stand Pillar anchoring to the ground
        Ogre::Vector3 base_mid = screen_pos_ - screen_up_ * hh;
        Ogre::Vector3 ground_anchor = base_mid - Ogre::Vector3(0, 2.5f, 0);
        emitFrameBar(ground_anchor, base_mid, 0.12f, c_dark, mesh, frame_vert_idx);

        mesh->end();
    }

    static void emitFrameBar(const Ogre::Vector3& a, const Ogre::Vector3& b, float thick, const Ogre::ColourValue& col, Ogre::ManualObject* mesh, uint32_t& vert_idx) {
        Ogre::Vector3 dir = (b - a).normalisedCopy();
        Ogre::Vector3 up(0, 1, 0);
        Ogre::Vector3 side = dir.crossProduct(up).normalisedCopy() * (thick * 0.5f);
        if (side.squaredLength() < 1e-4f) side = Ogre::Vector3(thick * 0.5f, 0, 0);

        Ogre::Vector3 p0 = a - side;
        Ogre::Vector3 p1 = a + side;
        Ogre::Vector3 p2 = b + side;
        Ogre::Vector3 p3 = b - side;

        uint32_t base = vert_idx;
        mesh->position(p0); mesh->colour(col);
        mesh->position(p1); mesh->colour(col);
        mesh->position(p2); mesh->colour(col);
        mesh->position(p3); mesh->colour(col);

        mesh->triangle(base, base + 1, base + 2);
        mesh->triangle(base, base + 2, base + 3);
        vert_idx += 4;
    }

    Ogre::SceneManager* scnMgr_ = nullptr;
    Ogre::TexturePtr display_tex_;
    Ogre::MaterialPtr mat_;

    std::string texture_name_;
    std::string material_name_;
    int tex_width_ = 1280;
    int tex_height_ = 720;

    float screen_width_ = 6.4f;  // 6.4m wide in 3D world
    float screen_height_ = 3.6f; // 3.6m tall (16:9 aspect ratio)

    Ogre::Vector3 screen_pos_{124.0f, 13.0f, 48.0f};
    Ogre::Vector3 look_target_{124.0f, 11.0f, 42.0f};
    Ogre::Vector3 screen_normal_{0, 0, -1};
    Ogre::Vector3 screen_up_{0, 1, 0};
    Ogre::Vector3 screen_right_{1, 0, 0};
};

} // namespace SCR::Display

#endif // CAVE_IN_WORLD_DISPLAY_HPP
