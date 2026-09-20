#ifndef CAVE_PROCEDURAL_CAVE_HPP
#define CAVE_PROCEDURAL_CAVE_HPP

#include "simulation/spatial_semantics.hpp"
#include "simulation/semantic_materials.hpp"
#include <vector>
#include <cmath>
#include <random>
#include <algorithm>
#include <iostream>

namespace SCR::Cave {

// Deterministic 3D coherent noise implementation (Perlin / FBM)
class FastNoise3D {
private:
    int p[512];

    static float fade(float t) { return t * t * t * (t * (t * 6 - 15) + 10); }
    static float lerp(float t, float a, float b) { return a + t * (b - a); }
    static float grad(int hash, float x, float y, float z) {
        int h = hash & 15;
        float u = h < 8 ? x : y;
        float v = h < 4 ? y : h == 12 || h == 14 ? x : z;
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
    }

public:
    FastNoise3D(unsigned int seed = 1337) {
        std::vector<int> permutation(256);
        for (int i = 0; i < 256; ++i) permutation[i] = i;
        std::mt19937 rng(seed);
        std::shuffle(permutation.begin(), permutation.end(), rng);
        for (int i = 0; i < 256; ++i) {
            p[i] = permutation[i];
            p[256 + i] = permutation[i];
        }
    }

    float noise(float x, float y, float z) const {
        int X = (int)std::floor(x) & 255;
        int Y = (int)std::floor(y) & 255;
        int Z = (int)std::floor(z) & 255;

        x -= std::floor(x);
        y -= std::floor(y);
        z -= std::floor(z);

        float u = fade(x);
        float v = fade(y);
        float w = fade(z);

        int A = p[X] + Y, AA = p[A] + Z, AB = p[A + 1] + Z;
        int B = p[X + 1] + Y, BA = p[B] + Z, BB = p[B + 1] + Z;

        return lerp(w, lerp(v, lerp(u, grad(p[AA], x, y, z),
                                     grad(p[BA], x - 1, y, z)),
                            lerp(u, grad(p[AB], x, y - 1, z),
                                 grad(p[BB], x - 1, y - 1, z))),
                    lerp(v, lerp(u, grad(p[AA + 1], x, y, z - 1),
                                 grad(p[BA + 1], x - 1, y, z - 1)),
                         lerp(u, grad(p[AB + 1], x, y - 1, z - 1),
                              grad(p[BB + 1], x - 1, y - 1, z - 1))));
    }

    float fbm(float x, float y, float z, int octaves = 4, float lacunarity = 2.0f, float gain = 0.5f) const {
        float sum = 0.0f;
        float freq = 1.0f;
        float amp = 1.0f;
        float max_amp = 0.0f;

        for (int i = 0; i < octaves; ++i) {
            sum += noise(x * freq, y * freq, z * freq) * amp;
            max_amp += amp;
            freq *= lacunarity;
            amp *= gain;
        }
        return sum / max_amp;
    }
};

/**
 * VoxelCave: Structured 3D Discrete Spatial Lattice (SCR Spatial Domain S).
 * Situated in explicit CaveLattice ReferenceFrame with discrete Z^3 coordinates,
 * 6-connected topological adjacencies, and semantic material bindings.
 */
class VoxelCave {
public:
    int dim_x, dim_y, dim_z;
    float voxel_size;
    std::vector<uint16_t> voxels;
    SCR::Spatial::ReferenceFrame reference_frame;

    FastNoise3D noise_main;
    FastNoise3D noise_ore;
    FastNoise3D noise_tunnel;

    VoxelCave(int dx = 48, int dy = 24, int dz = 48, float v_size = 1.0f)
        : dim_x(dx), dim_y(dy), dim_z(dz), voxel_size(v_size),
          voxels(dx * dy * dz, Material::MAT_AIR),
          reference_frame("cave_lattice_frame", "world_reference_frame"),
          noise_main(1337), noise_ore(1438), noise_tunnel(1539) {}

    inline int index(int x, int y, int z) const {
        return (y * dim_z + z) * dim_x + x;
    }

    bool inBounds(int x, int y, int z) const {
        return x >= 0 && x < dim_x && y >= 0 && y < dim_y && z >= 0 && z < dim_z;
    }

    bool inBounds(const Spatial::LatticeCoord3D& c) const {
        return inBounds(c.x, c.y, c.z);
    }

    float sampleContinuousDensity(float x, float y, float z) const {
        if (x <= 1.0f || x >= dim_x - 1.0f || z <= 1.0f || z >= dim_z - 1.0f || y <= 1.0f || y >= dim_y - 1.0f) {
            return 2.0f; // Boundary bedrock shell
        }
        float nx = x / 14.0f;
        float ny = y / 8.0f;
        float nz = z / 14.0f;
        float density = noise_main.fbm(nx, ny, nz, 4, 2.0f, 0.5f);

        float tx = noise_tunnel.fbm(x / 10.0f, y / 10.0f, z / 10.0f, 2);
        float ty = noise_tunnel.fbm((x + 50) / 10.0f, (y + 50) / 10.0f, (z + 50) / 10.0f, 2);
        float worm_dist = std::sqrt(tx * tx + ty * ty);

        if (worm_dist < 0.18f) return -1.0f; // Hollow worm tunnel
        return density + 0.05f; // Positive = solid rock, negative = hollow air
    }

    uint16_t getVoxel(int x, int y, int z) const {
        if (!inBounds(x, y, z)) return Material::MAT_BEDROCK;
        return voxels[index(x, y, z)];
    }

    uint16_t getVoxel(const Spatial::LatticeCoord3D& c) const {
        return getVoxel(c.x, c.y, c.z);
    }

    void setVoxel(int x, int y, int z, uint16_t mat) {
        if (inBounds(x, y, z)) {
            voxels[index(x, y, z)] = mat;
        }
    }

    void setVoxel(const Spatial::LatticeCoord3D& c, uint16_t mat) {
        setVoxel(c.x, c.y, c.z, mat);
    }

    bool isSolid(int x, int y, int z) const {
        uint16_t mat = getVoxel(x, y, z);
        return Material::MaterialRegistry::instance().get(mat).is_solid;
    }

    SCR::Spatial::AABB3D getWorldAABB() const {
        return SCR::Spatial::AABB3D(
            SCR::Spatial::Point3D(0, 0, 0),
            SCR::Spatial::Point3D(dim_x * voxel_size, dim_y * voxel_size, dim_z * voxel_size)
        );
    }

    SCR::Spatial::Point3D findSpawnPosition() const {
        float max_clearance = -999.0f;
        SCR::Spatial::Point3D best_pos(dim_x * 0.5f, 6.0f, dim_z * 0.5f);

        for (int y = 2; y < dim_y - 4; ++y) {
            for (int z = 4; z < dim_z - 4; ++z) {
                for (int x = 4; x < dim_x - 4; ++x) {
                    if (!isSolid(x, y - 1, z)) continue; // Must have solid ground
                    if (isSolid(x, y, z) || isSolid(x, y + 1, z) || isSolid(x, y + 2, z)) continue;

                    float px = x + 0.5f, py = y + 1.6f, pz = z + 0.5f; // Eye position
                    float d_eye = sampleContinuousDensity(px, py, pz);
                    if (d_eye > -0.15f) continue; // Eye must not touch or be in wall

                    float d_fwd = sampleContinuousDensity(px, py, pz - 1.2f);
                    float d_back = sampleContinuousDensity(px, py, pz + 1.2f);
                    float d_left = sampleContinuousDensity(px - 1.2f, py, pz);
                    float d_right = sampleContinuousDensity(px + 1.2f, py, pz);

                    float worst_d = std::max({d_eye, d_fwd, d_back, d_left, d_right});
                    float score = -worst_d; // More negative = deeper in open air chamber

                    if (score > max_clearance) {
                        max_clearance = score;
                        best_pos = SCR::Spatial::Point3D(px, y + 0.1f, pz);
                    }
                }
            }
        }
        return best_pos;
    }

    /**
     * Executes one STC (State-Transition-Closure) discrete cellular reaction step.
     * Evaluates face-sharing 6-neighborhoods (N6) for thermodynamic phase changes:
     * e.g., Molten Lava + Water -> Quenched Obsidian / Cobblestone + Steam release.
     */
    int stepSTCReactions() {
        int reaction_count = 0;
        std::vector<uint16_t> next_voxels = voxels;
        const auto& reg = Material::MaterialRegistry::instance();

        for (int y = 1; y < dim_y - 1; ++y) {
            for (int z = 1; z < dim_z - 1; ++z) {
                for (int x = 1; x < dim_x - 1; ++x) {
                    uint16_t current = getVoxel(x, y, z);
                    if (current == Material::MAT_AIR) continue;

                    // Check all 6 face-sharing neighbors (Direction6)
                    for (int d = 0; d < 6; ++d) {
                        auto off = Spatial::getDirectionOffset((Spatial::Direction6)d);
                        int nx = x + off.x;
                        int ny = y + off.y;
                        int nz = z + off.z;

                        uint16_t neighbor = getVoxel(nx, ny, nz);
                        uint16_t outcome = reg.evaluateFaceAdjacencySTC(current, neighbor);
                        if (outcome != current) {
                            next_voxels[index(x, y, z)] = outcome;
                            reaction_count++;
                            break;
                        }
                    }
                }
            }
        }

        if (reaction_count > 0) {
            voxels = std::move(next_voxels);
        }
        return reaction_count;
    }

    /**
     * Procedural Generation incorporating geological strata, ore vein clustering,
     * hydrothermal fluid bodies, and crystalline speleothems.
     */
    void generateProceduralCave(unsigned int seed = 42) {
        FastNoise3D noise_main(seed);
        FastNoise3D noise_ore(seed + 101);
        FastNoise3D noise_tunnel(seed + 202);

        for (int x = 0; x < dim_x; ++x) {
            for (int y = 0; y < dim_y; ++y) {
                for (int z = 0; z < dim_z; ++z) {
                    // 1. Boundary bedrock walls to enclose player
                    if (x == 0 || x == dim_x - 1 || z == 0 || z == dim_z - 1 || y == 0 || y == dim_y - 1) {
                        setVoxel(x, y, z, Material::MAT_BEDROCK);
                        continue;
                    }

                    // 2. Cavern density calculation
                    float nx = x / 14.0f;
                    float ny = y / 8.0f;
                    float nz = z / 14.0f;
                    float density = noise_main.fbm(nx, ny, nz, 4, 2.0f, 0.5f);

                    // Add worm tunnel carving
                    float tx = noise_tunnel.fbm(x / 10.0f, y / 10.0f, z / 10.0f, 2);
                    float ty = noise_tunnel.fbm((x + 50) / 10.0f, (y + 50) / 10.0f, (z + 50) / 10.0f, 2);
                    float worm_dist = std::sqrt(tx * tx + ty * ty);

                    bool is_hollow = (density < -0.05f) || (worm_dist < 0.18f);

                    if (is_hollow) {
                        // Subterranean water basin in low hollows
                        if (y <= 3) {
                            setVoxel(x, y, z, Material::MAT_WATER);
                        } else {
                            setVoxel(x, y, z, Material::MAT_AIR);
                        }
                    } else {
                        // Solid geological strata stratification
                        uint16_t rock_type;
                        if (y <= 2) {
                            rock_type = Material::MAT_BEDROCK;
                        } else if (y <= 5) {
                            rock_type = Material::MAT_BASALT;
                        } else if (y <= 12) {
                            rock_type = Material::MAT_GRANITE;
                        } else if (y <= 18) {
                            rock_type = Material::MAT_LIMESTONE;
                        } else {
                            rock_type = Material::MAT_DIRT;
                        }

                        // Ore vein intrusions via high-frequency noise
                        float ore_sample = noise_ore.noise(x * 0.25f, y * 0.25f, z * 0.25f);
                        if (ore_sample > 0.65f) {
                            rock_type = Material::MAT_GOLD_ORE;
                        } else if (ore_sample > 0.42f) {
                            rock_type = Material::MAT_IRON_ORE;
                        } else if (ore_sample < -0.65f) {
                            rock_type = Material::MAT_QUARTZ;
                        }

                        setVoxel(x, y, z, rock_type);
                    }
                }
            }
        }

        // Subterranean magma chamber in one corner (x=8..14, z=8..14, y=1..3)
        for (int lx = 8; lx <= 14; ++lx) {
            for (int lz = 8; lz <= 14; ++lz) {
                for (int ly = 1; ly <= 5; ++ly) {
                    if (ly <= 2) {
                        setVoxel(lx, ly, lz, Material::MAT_LAVA);
                    } else {
                        setVoxel(lx, ly, lz, Material::MAT_AIR);
                    }
                }
                // Vitrified Obsidian border rim
                setVoxel(lx, 1, 7, Material::MAT_OBSIDIAN);
                setVoxel(lx, 1, 15, Material::MAT_OBSIDIAN);
                setVoxel(7, 1, lz, Material::MAT_OBSIDIAN);
                setVoxel(15, 1, lz, Material::MAT_OBSIDIAN);
            }
        }

        // Stalactites (hanging calcite) and bioluminescent moss on ceilings
        for (int x = 2; x < dim_x - 2; ++x) {
            for (int z = 2; z < dim_z - 2; ++z) {
                for (int y = 5; y < dim_y - 2; ++y) {
                    if (isSolid(x, y + 1, z) && getVoxel(x, y, z) == Material::MAT_AIR) {
                        if ((x * 13 + z * 7) % 19 == 0) {
                            setVoxel(x, y, z, Material::MAT_CALCITE); // Stalactite
                            if (getVoxel(x, y - 1, z) == Material::MAT_AIR) {
                                setVoxel(x, y - 1, z, Material::MAT_CALCITE);
                            }
                        } else if ((x * 11 + z * 17) % 23 == 0) {
                            setVoxel(x, y, z, Material::MAT_MOSS); // Bioluminescent moss
                        }
                    }
                }
            }
        }

        std::cout << "[VoxelCave] Procedural cave generated with seed " << seed 
                  << " (" << dim_x << "x" << dim_y << "x" << dim_z << " lattice).\n";
    }
};

} // namespace SCR::Cave

#endif // CAVE_PROCEDURAL_CAVE_HPP
