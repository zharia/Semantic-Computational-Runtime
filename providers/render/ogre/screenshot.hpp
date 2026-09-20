#pragma once
/**
 * SCR Auto Screenshot — Timed screenshot capture
 * ─────────────────────────────────────────────────────────────────────────────
 * Captures a screenshot at the next frame after construction.
 * Used for automated capture loops.
 */

#include <OGRE/Ogre.h>
#include <string>

namespace SCR {

class AutoScreenshot {
public:
    AutoScreenshot(Ogre::RenderWindow* window, const std::string& filename)
        : window_(window), filename_(filename), requested_(true) {}

    void capture_next_frame() { requested_ = true; }

    void update() {
        if (requested_ && window_) {
            window_->writeContentsToFile(filename_);
            requested_ = false;
        }
    }

    bool is_pending() const { return requested_; }

private:
    Ogre::RenderWindow* window_;
    std::string filename_;
    bool requested_;
};

} // namespace SCR
