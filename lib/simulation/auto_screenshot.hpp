#pragma once
/**
 * SCR AutoScreenshotSubSystem — Timed screenshot capture
 */

#include "simulation/simulation_systems_core.hpp"
#include "render/ogre/screenshot.hpp"

namespace SCR::Simulation {

class AutoScreenshotSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "AutoScreenshot"; }

    void initialize(SystemContext& ctx) override {
        auto* win = ctx.renderCtx.getWindow<Ogre::RenderWindow>();
        if (win) {
            screenshot_ = std::make_unique<AutoScreenshot>(win, "scr_screenshot.png");
        }
    }

    void set_interval(float seconds) { interval_ = seconds; }
    void request_capture() { if (screenshot_) screenshot_->capture_next_frame(); }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        timer_ += dt;
        if (timer_ >= interval_ && screenshot_) {
            screenshot_->capture_next_frame();
            timer_ = 0.0f;
        }
    }

private:
    std::unique_ptr<AutoScreenshot> screenshot_;
    float interval_ = 10.0f;
    float timer_ = 0.0f;
};

} // namespace SCR::Simulation
