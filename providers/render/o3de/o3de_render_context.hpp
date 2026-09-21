#ifndef SCR_O3DE_RENDER_CONTEXT_HPP
#define SCR_O3DE_RENDER_CONTEXT_HPP

#include "simulation/simulation_systems_core.hpp"

namespace SCR::Render::O3DE {

// O3DE Atom RPI types stored in RenderContext void* pointers:
//   native_scene_manager  → AZ::RPI::Scene*
//   native_camera         → AZ::RPI::View*
//   native_window         → AZ::RPI::RenderPipeline*
//   native_viewport       → (unused / future)

inline void setScene(SCR::Simulation::RenderContext& ctx, void* scene) {
    ctx.native_scene_manager = scene;
}

inline void setView(SCR::Simulation::RenderContext& ctx, void* view) {
    ctx.native_camera = view;
}

inline void setPipeline(SCR::Simulation::RenderContext& ctx, void* pipeline) {
    ctx.native_window = pipeline;
}

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_RENDER_CONTEXT_HPP
