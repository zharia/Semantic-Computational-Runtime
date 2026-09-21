# SCR Volcanic Island - Source CMakeLists.txt

ly_add_target(
    NAME SCR_VolcanicIsland.GameLauncher EXECUTABLE
    NAMESPACE Gem
    FILES_CMAKE
        volcanicislandgame_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::SCRIntegration.Clients
            AZ::AzCore
            AZ::AzFramework
            AZ::AzGameFramework
)

# Gem module for the game
ly_add_target(
    NAME SCR_VolcanicIsland.Gem MODULE
    NAMESPACE Gem
    FILES_CMAKE
        volcanicislandgamegem_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::SCRIntegration.Clients
            AZ::AzCore
            AZ::AzFramework
)

# Register the game launcher
ly_create_gem(
    NAME SCR_VolcanicIsland
    NAMESPACE Gem
    FILES_CMAKE
        volcanicislandgame_shared_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::SCR_VolcanicIsland.Gem
)
