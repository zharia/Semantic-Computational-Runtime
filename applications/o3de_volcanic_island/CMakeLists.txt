cmake_minimum_required(VERSION 3.20)

# O3DE project: SCR Volcanic Island
# Demonstrates SCR semantic framework running in O3DE engine

# Point to O3DE cmake infrastructure
set(O3DE_PATH "/opt/O3DE/26.05")
list(APPEND CMAKE_MODULE_PATH "${O3DE_PATH}/cmake")
list(APPEND CMAKE_MODULE_PATH "${O3DE_PATH}/cmake/3rdParty")

# Include O3DE platform detection
include(Platform/${PAL_PLATFORM_NAME}/platform_detection)

project(SCR_VolcanicIsland LANGUAGES C CXX)

# Set project-specific settings
set(LY_PROJECT_NAME "SCR_VolcanicIsland")
set(LY_PROJECT_NAME_LOWER "scr_volcanic_island")

# Default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

# Compiler settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include O3DE common cmake
include(Common)

# Set O3DE paths
set(LY_3RDPARTY_PATH "${O3DE_PATH}/3rdParty" CACHE PATH "3rdParty")
set(LY_PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")

# Add subdirectories
add_subdirectory(Gem)
add_subdirectory(Source)
