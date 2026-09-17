#ifndef CAVE_VDB_ISLAND_MESHER_HPP
#define CAVE_VDB_ISLAND_MESHER_HPP

#include <openvdb/openvdb.h>
#include <openvdb/tools/VolumeToMesh.h>

#include <Ogre.h>
#include <OgreManualObject.h>

#include "spatial_semantics.hpp"
#include "semantic_materials.hpp"
#include "procedural_island.hpp"

#include <vector>
#include <cmath>
#include <iostream>

namespace SCR::VDB {

/**
 * OpenVDB Volumetric Isosurface Adapter for Volcanic Island Simulation.
 * Uses OpenVDB sparse B-tree volumeToMesh for natural terrain, volcanic peaks,
 * caldera bowl, and beaches, and streams directly into OGRE 3D GPU vertex buffers.
 */
class VdbIslandMesher {
public:
    /**
     * Extracts and constructs the continuous smooth natural volcanic island terrain.
     */
    static void buildNaturalIslandMesh(
        Ogre::ManualObject* manualObj,
        const Island::VoxelIsland& island,
        float isovalue = 0.0f,
        float adaptivity = 0.02f
    ) {
        if (!manualObj) return;

        openvdb::initialize();

        // 1. Create OpenVDB FloatGrid for Island Density
        // Background is -1.0 (air/void), positive inside solid terrain
        openvdb::FloatGrid::Ptr grid = openvdb::FloatGrid::create(-1.0f);
        grid->setName("VolcanicIslandDensityGrid");
        grid->setTransform(openvdb::math::Transform::createLinearTransform(island.voxel_size));

        auto accessor = grid->getAccessor();

        int dx = island.dim_x;
        int dy = island.dim_y;
        int dz = island.dim_z;

        // Sample density directly from continuous island geomorphology field
        for (int z = 0; z <= dz; ++z) {
            for (int y = 0; y <= dy; ++y) {
                for (int x = 0; x <= dx; ++x) {
                    float signed_val = island.sampleContinuousDensity((float)x, (float)y, (float)z);
                    accessor.setValue(openvdb::Coord(x, y, z), signed_val);
                }
            }
        }

        // 2. Multi-Threaded Adaptive Volume-To-Mesh Polygonization
        std::vector<openvdb::Vec3s> points;
        std::vector<openvdb::Vec3I> triangles;
        std::vector<openvdb::Vec4I> quads;

        openvdb::tools::volumeToMesh(
            *grid, points, triangles, quads,
            (double)isovalue, (double)adaptivity, true
        );

        std::cout << "[OpenVDB] Island Isosurface extracted: " << points.size() << " vertices, "
                  << triangles.size() << " triangles, " << quads.size() << " quads (adaptivity: " << adaptivity << ").\n";

        // 3. Stream Polygons into OGRE ManualObject
        manualObj->clear();
        manualObj->begin("SCR/VolcanicIslandMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        const auto& reg = Material::MaterialRegistry::instance();

        auto get_density = [&](float sx, float sy, float sz) -> float {
            openvdb::Coord c((int)std::floor(sx), (int)std::floor(sy), (int)std::floor(sz));
            return accessor.getValue(c);
        };

        // Compute Vertex Normals via Central Differences on the Density Field
        std::vector<Ogre::Vector3> ogre_normals;
        ogre_normals.reserve(points.size());

        for (const auto& p : points) {
            float eps = 0.5f;
            float dx_val = get_density(p.x() + eps, p.y(), p.z()) - get_density(p.x() - eps, p.y(), p.z());
            float dy_val = get_density(p.x(), p.y() + eps, p.z()) - get_density(p.x(), p.y() - eps, p.z());
            float dz_val = get_density(p.x(), p.y(), p.z() + eps) - get_density(p.x(), p.y(), p.z() - eps);

            // Terrain normal points outward towards decreasing density (-gradient)
            Ogre::Vector3 n(-dx_val, -dy_val, -dz_val);
            if (n.squaredLength() > 1e-6f) n.normalise();
            else n = Ogre::Vector3::UNIT_Y;
            ogre_normals.push_back(n);
        }

        // Emit Vertices with Material-Aware Albedo and Slope Blending
        for (size_t i = 0; i < points.size(); ++i) {
            const auto& p = points[i];
            const auto& n = ogre_normals[i];

            int vx = std::max(0, std::min(dx - 1, (int)std::floor(p.x())));
            int vy = std::max(0, std::min(dy - 1, (int)std::floor(p.y())));
            int vz = std::max(0, std::min(dz - 1, (int)std::floor(p.z())));

            uint16_t mat_code = island.getVoxel(vx, vy, vz);
            if (mat_code == Material::MAT_AIR || mat_code == Material::MAT_WATER) {
                // If isosurface falls in air/water boundary, determine biome by altitude and slope
                float slope = 1.0f - std::max(0.0f, n.y); // 0 = flat, 1 = vertical cliff

                if (p.y() <= island.sea_level + 1.8f) {
                    mat_code = Material::MAT_SAND;
                } else if (p.y() >= 24.0f) {
                    float dist_c = std::sqrt(std::pow(p.x() - island.center_x, 2) + std::pow(p.z() - island.center_z, 2));
                    if (dist_c < island.caldera_radius) mat_code = Material::MAT_OBSIDIAN;
                    else mat_code = Material::MAT_BASALT;
                } else if (slope > 0.45f) {
                    mat_code = Material::MAT_BASALT; // Steep rock cliffs
                } else if (p.y() >= 10.0f && p.y() <= 20.0f) {
                    mat_code = Material::MAT_FOLIAGE; // Tropical vegetation
                } else {
                    mat_code = Material::MAT_DIRT;
                }
            }

            const auto& mat = reg.get(mat_code);

            manualObj->position(p.x(), p.y(), p.z());
            manualObj->normal(n.x, n.y, n.z);
            manualObj->textureCoord(p.x() * 0.15f, p.z() * 0.15f);

            // Shading Color with slight natural ambient variation
            float ao = std::max(0.65f, std::min(1.0f, 0.7f + n.y * 0.3f));
            manualObj->colour(mat.albedo.r * ao, mat.albedo.g * ao, mat.albedo.b * ao, 1.0f);
        }

        // Triangles
        for (const auto& tri : triangles) {
            manualObj->triangle(tri[0], tri[1], tri[2]);
        }

        // Quads
        for (const auto& quad : quads) {
            manualObj->triangle(quad[0], quad[1], quad[2]);
            manualObj->triangle(quad[0], quad[2], quad[3]);
        }

        manualObj->end();
        std::cout << "[OGRE] Smooth natural volcanic island mesh committed to GPU buffer.\n";
    }

    /**
     * Builds the translucent animated ocean water surface plane at sea level.
     */
    static void buildOceanWaterMesh(
        Ogre::ManualObject* oceanObj,
        float sea_level = 8.0f,
        float min_x = -120.0f, float max_x = 200.0f,
        float min_z = -120.0f, float max_z = 200.0f,
        int grid_res = 40
    ) {
        if (!oceanObj) return;

        oceanObj->clear();
        oceanObj->begin("SCR/OceanWaterMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        float step_x = (max_x - min_x) / grid_res;
        float step_z = (max_z - min_z) / grid_res;

        uint32_t vert_idx = 0;
        for (int j = 0; j < grid_res; ++j) {
            float z0 = min_z + j * step_z;
            float z1 = z0 + step_z;

            for (int i = 0; i < grid_res; ++i) {
                float x0 = min_x + i * step_x;
                float x1 = x0 + step_x;

                // 4 corners of the quad
                oceanObj->position(x0, sea_level, z0);
                oceanObj->normal(0.0f, 1.0f, 0.0f);
                oceanObj->textureCoord(x0 * 0.05f, z0 * 0.05f);
                oceanObj->colour(0.08f, 0.58f, 0.76f, 0.72f);

                oceanObj->position(x0, sea_level, z1);
                oceanObj->normal(0.0f, 1.0f, 0.0f);
                oceanObj->textureCoord(x0 * 0.05f, z1 * 0.05f);
                oceanObj->colour(0.08f, 0.58f, 0.76f, 0.72f);

                oceanObj->position(x1, sea_level, z1);
                oceanObj->normal(0.0f, 1.0f, 0.0f);
                oceanObj->textureCoord(x1 * 0.05f, z1 * 0.05f);
                oceanObj->colour(0.08f, 0.58f, 0.76f, 0.72f);

                oceanObj->position(x1, sea_level, z0);
                oceanObj->normal(0.0f, 1.0f, 0.0f);
                oceanObj->textureCoord(x1 * 0.05f, z0 * 0.05f);
                oceanObj->colour(0.08f, 0.58f, 0.76f, 0.72f);

                // Two triangles: (0, 1, 2) and (0, 2, 3)
                oceanObj->triangle(vert_idx, vert_idx + 1, vert_idx + 2);
                oceanObj->triangle(vert_idx, vert_idx + 2, vert_idx + 3);
                vert_idx += 4;
            }
        }

        oceanObj->end();
        std::cout << "[OGRE] Ocean water plane committed (" << grid_res * grid_res * 2 << " triangles).\n";
    }

    /**
     * Builds the discrete culled voxel block mesh representation (Toggle Mode M).
     */
    static void buildDiscreteIslandMesh(
        Ogre::ManualObject* manualObj,
        const Island::VoxelIsland& island
    ) {
        if (!manualObj) return;

        manualObj->clear();
        manualObj->begin("SCR/DiscreteBlockMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        const auto& reg = Material::MaterialRegistry::instance();
        size_t vert_count = 0;

        auto addFace = [&](float x, float y, float z, int dir, const Material::ColorRGB& col) {
            Ogre::Vector3 v[4];
            Ogre::Vector3 norm;

            switch (dir) {
                case 0: // +X
                    v[0] = Ogre::Vector3(x+1, y,   z);   v[1] = Ogre::Vector3(x+1, y+1, z);
                    v[2] = Ogre::Vector3(x+1, y+1, z+1); v[3] = Ogre::Vector3(x+1, y,   z+1);
                    norm = Ogre::Vector3::UNIT_X;
                    break;
                case 1: // -X
                    v[0] = Ogre::Vector3(x, y,   z+1); v[1] = Ogre::Vector3(x, y+1, z+1);
                    v[2] = Ogre::Vector3(x, y+1, z);   v[3] = Ogre::Vector3(x, y,   z);
                    norm = Ogre::Vector3::NEGATIVE_UNIT_X;
                    break;
                case 2: // +Y (Top)
                    v[0] = Ogre::Vector3(x,   y+1, z);   v[1] = Ogre::Vector3(x,   y+1, z+1);
                    v[2] = Ogre::Vector3(x+1, y+1, z+1); v[3] = Ogre::Vector3(x+1, y+1, z);
                    norm = Ogre::Vector3::UNIT_Y;
                    break;
                case 3: // -Y (Bottom)
                    v[0] = Ogre::Vector3(x,   y, z+1); v[1] = Ogre::Vector3(x,   y, z);
                    v[2] = Ogre::Vector3(x+1, y, z);   v[3] = Ogre::Vector3(x+1, y, z+1);
                    norm = Ogre::Vector3::NEGATIVE_UNIT_Y;
                    break;
                case 4: // +Z
                    v[0] = Ogre::Vector3(x+1, y,   z+1); v[1] = Ogre::Vector3(x+1, y+1, z+1);
                    v[2] = Ogre::Vector3(x,   y+1, z+1); v[3] = Ogre::Vector3(x,   y,   z+1);
                    norm = Ogre::Vector3::UNIT_Z;
                    break;
                case 5: // -Z
                    v[0] = Ogre::Vector3(x,   y,   z); v[1] = Ogre::Vector3(x,   y+1, z);
                    v[2] = Ogre::Vector3(x+1, y+1, z); v[3] = Ogre::Vector3(x+1, y,   z);
                    norm = Ogre::Vector3::NEGATIVE_UNIT_Z;
                    break;
            }

            manualObj->position(v[0]); manualObj->normal(norm); manualObj->colour(col.r, col.g, col.b, col.a);
            manualObj->position(v[1]); manualObj->normal(norm); manualObj->colour(col.r, col.g, col.b, col.a);
            manualObj->position(v[2]); manualObj->normal(norm); manualObj->colour(col.r, col.g, col.b, col.a);
            manualObj->position(v[3]); manualObj->normal(norm); manualObj->colour(col.r, col.g, col.b, col.a);

            manualObj->triangle(vert_count, vert_count + 1, vert_count + 2);
            manualObj->triangle(vert_count, vert_count + 2, vert_count + 3);
            vert_count += 4;
        };

        for (int y = 0; y < island.dim_y; ++y) {
            for (int z = 0; z < island.dim_z; ++z) {
                for (int x = 0; x < island.dim_x; ++x) {
                    uint16_t mat_code = island.getVoxel(x, y, z);
                    if (mat_code == Material::MAT_AIR || mat_code == Material::MAT_WATER) continue;

                    const auto& mat = reg.get(mat_code);

                    if (!island.isSolid(x + 1, y, z)) addFace(x, y, z, 0, mat.albedo);
                    if (!island.isSolid(x - 1, y, z)) addFace(x, y, z, 1, mat.albedo);
                    if (!island.isSolid(x, y + 1, z)) addFace(x, y, z, 2, mat.albedo);
                    if (!island.isSolid(x, y - 1, z)) addFace(x, y, z, 3, mat.albedo);
                    if (!island.isSolid(x, y, z + 1)) addFace(x, y, z, 4, mat.albedo);
                    if (!island.isSolid(x, y, z - 1)) addFace(x, y, z, 5, mat.albedo);
                }
            }
        }

        manualObj->end();
        std::cout << "[OGRE] Discrete voxel island mesh generated (" << vert_count / 4 << " visible quads).\n";
    }
};

} // namespace SCR::VDB

#endif // CAVE_VDB_ISLAND_MESHER_HPP
