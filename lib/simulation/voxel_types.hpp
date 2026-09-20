#pragma once
/**
 * SCR Voxel Types — Core voxel data structures
 * ─────────────────────────────────────────────────────────────────────────────
 * Thin wrapper over simulation_framework.hpp VoxelData/VoxelChunk.
 * Provides convenience aliases and chunk metadata.
 */

#include "simulation/simulation_framework.hpp"

namespace SCR::Voxel {

using VoxelData = SCR::Simulation::VoxelData;
using VoxelChunk = SCR::Simulation::VoxelChunk;

struct ChunkMeta {
    int cx, cy, cz;
    bool dirty = false;
    float last_access_time = 0.0f;
};

} // namespace SCR::Voxel
