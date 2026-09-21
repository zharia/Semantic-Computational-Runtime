# SCR Volcanic Island - O3DE Implementation

A volcanic island simulation running in O3DE using the Semantic Computational Runtime (SCR) framework.

## Overview

This project demonstrates the SCR semantic framework integrated with O3DE's Entity Component System (ECS). The volcanic island is composed of semantic entities with explicit contracts:

- **Terrain** - Ground plane
- **Volcano** - Central mountain
- **Lava Flows** - Erupting lava streams
- **Water** - Ocean surrounding the island
- **Camera** - Viewer perspective

Each entity has:
- **SCR SID** - Semantic Identity Coordinate (authority, domain, coordinate)
- **SCR Transform** - Similarity transform (position, rotation, scale)
- **O3DE Component** - Mapped to O3DE's TransformComponent

## Architecture

```
SCR Semantic Definition
    ↓
SCR SID (1, 1, 1001)
    ↓
SCR Integration Component
    ↓
O3DE Entity + TransformComponent
    ↓
O3DE Renderer (Vulkan)
```

## SCR ↔ O3DE Coordinate Mapping

| SCR | O3DE | Description |
|-----|------|-------------|
| +X | +X | Right |
| +Y | +Z | Up |
| +Z | +Y | Forward |

## Building

### Prerequisites
- O3DE 26.05 installed at `/opt/O3DE/26.05/`
- GCC 16 (or compatible)
- CMake 3.20+
- Ninja build system

### Build Commands

```bash
# Configure and build
./build.sh

# Or manually:
mkdir build && cd build
cmake .. -G "Ninja Multi-Config" -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

### Running

```bash
# Run the volcanic island
./build/bin/Linux/profile/Default/SCR_VolcanicIsland.GameLauncher
```

## Project Structure

```
o3de_volcanic_island/
├── CMakeLists.txt              # Project root
├── build.sh                    # Build script
├── README.md                   # This file
├── Gem/
│   ├── CMakeLists.txt          # Gem build config
│   ├── Include/
│   │   └── SCRIntegration/
│   │       └── SCRIntegrationBus.h
│   └── Source/
│       └── SCRIntegrationComponent.cpp
└── Source/
    ├── CMakeLists.txt          # Source build config
    └── VolcanicIslandSetup.cpp # Scene setup
```

## SCR Integration

The SCR Integration Gem provides:

### SCRIntegrationComponent
- Attaches to O3DE entities
- Manages SCR SID ↔ O3DE EntityId mapping
- Converts SCR transforms to O3DE transforms
- Handles lifecycle (activate/deactivate)

### Coordinate Conversion
```cpp
// SCR to O3DE
AZ::Vector3 o3dePos = SCR::Integration::scrToO3DE(scrPos);

// O3DE to SCR
SCR::Integration::SCR_Position scrPos = SCR::Integration::o3deToSCR(o3dePos);
```

## Entity Setup

Each entity is created with:
1. SCR SID (unique identifier)
2. SCR Transform (canonical coordinates)
3. O3DE TransformComponent
4. SCR Integration Component

Example:
```cpp
auto* entity = aznew AZ::Entity("Volcano");
auto* scrComponent = aznew SCR::Integration::SCRIntegrationComponent();
scrComponent->SetSID({1, 1, 2001});
scrComponent->SetSCRTransform({{0, 50, 0}, {1, 0, 0, 0}, 1.0});
entity->AddComponent(scrComponent);
```

## Testing

The SCR framework has been validated with:
- 168 unit tests
- 28 Lean formal proofs
- Integration tests across O3DE and ROS2 providers

## References

- [O3DE Documentation](https://www.o3de.org/docs/)
- [SCR Framework](../program_increments/)
- [v0.0.4 Audit Report](../program_increments/v0.0.4/audit_report.md)
