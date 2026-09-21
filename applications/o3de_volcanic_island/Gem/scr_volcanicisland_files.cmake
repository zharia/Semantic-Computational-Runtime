set(FILES
    Include/SCR_VolcanicIsland/SCR_VolcanicIslandBus.h
    Include/SCR_VolcanicIsland/SCR_VolcanicIslandTypeIds.h
    Source/SCR_VolcanicIslandSystemComponent.cpp
    Source/SCR_VolcanicIslandSystemComponent.h
    Source/SCR_IntegrationComponent.cpp
    # O3DE Render Provider (replaces OGRE)
    ${CMAKE_CURRENT_LIST_DIR}/../../../providers/render/o3de/o3de_volcanic_island_scene.cpp
)
