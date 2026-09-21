#ifndef SCR_O3DE_VOLCANIC_ISLAND_SCENE_HPP
#define SCR_O3DE_VOLCANIC_ISLAND_SCENE_HPP

#include "simulation/simulation_framework.hpp"
#include "simulation/simulation_systems_core.hpp"
#include "o3de/o3de_subsystems.hpp"

namespace SCR::Render::O3DE {

class O3deVolcanicIslandScene : public Simulation::ISimulationScene {
public:
    std::shared_ptr<Simulation::ConcurrentSystemCoordinator> coordinator;

    O3deVolcanicIslandScene();

    Simulation::SceneMetadata getMetadata() const override;
    void prepare(Simulation::LoadingContext& ctx) override;
    void attachRenderer(Simulation::RenderContext& ctx) override;
    void detachRenderer(Simulation::RenderContext& ctx) override;
    void update(float dt, const Simulation::UserInputState& input) override;
    void renderPresentation(Simulation::RenderContext& ctx, float alpha) override;
    bool handleKeyPress(int key, bool down, bool is_alt, bool is_ctrl) override;
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_VOLCANIC_ISLAND_SCENE_HPP
