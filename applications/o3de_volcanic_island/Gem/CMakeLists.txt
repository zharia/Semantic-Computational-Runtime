# SCR Integration Gem for O3DE
# Maps SCR semantic contracts to O3DE ECS

o3de_gem_setup("SCRIntegration")

include(${pal_dir}/PAL_${PAL_PLATFORM_NAME_LOWERCASE}.cmake)

if(NOT PAL_TRAIT_SCRINTEGRATION_SUPPORTED)
    return()
endif()

ly_add_target(
    NAME SCRIntegration.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        scrintegration_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
)

ly_add_target(
    NAME SCRIntegration ${PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        scrintegration_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            Include
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::SCRIntegration.Static
            AZ::AzCore
            AZ::AzFramework
)

ly_add_source_properties(
SOURCES
    Source/SCRIntegrationModule.cpp
PROPERTY COMPILE_DEFINITIONS
    VALUES
        O3DE_GEM_NAME=SCRIntegration
        O3DE_GEM_VERSION=0.0.4)

ly_create_alias(NAME SCRIntegration.Builders NAMESPACE Gem TARGETS Gem::SCRIntegration)
ly_create_alias(NAME SCRIntegration.Tools    NAMESPACE Gem TARGETS Gem::SCRIntegration)
ly_create_alias(NAME SCRIntegration.Clients  NAMESPACE Gem TARGETS Gem::SCRIntegration)
ly_create_alias(NAME SCRIntegration.Servers  NAMESPACE Gem TARGETS Gem::SCRIntegration)
ly_create_alias(NAME SCRIntegration.Unified  NAMESPACE Gem TARGETS Gem::SCRIntegration)
