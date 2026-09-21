# SCR Integration Gem for O3DE
# Maps SCR semantic contracts to O3DE ECS

o3de_gem_setup("SCRIntegration")

# Gem dependencies
ly_add_target(
    NAME SCRIntegration Gem
    NAMESPACE Gem
    FILES_CMAKE
        scrintegration_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
)

# SCR Integration component
ly_add_target(
    NAME SCRIntegration.Clients PRIVATE
    NAMESPACE Gem
    FILES_CMAKE
        scrintegration_clients_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            Include
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::SCRIntegration Gem
            AZ::AzCore
            AZ::AzFramework
)

# Gem module
ly_create_gem(
    NAME SCRIntegration
    NAMESPACE Gem
    FILES_CMAKE
        scrintegration_shared_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::SCRIntegration.Clients
)
