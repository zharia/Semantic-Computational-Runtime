#ifndef CAVE_VDB_CAVE_MESHER_HPP
#define CAVE_VDB_CAVE_MESHER_HPP

#include <openvdb/openvdb.h>
#include <openvdb/tools/VolumeToMesh.h>
#include <openvdb/tools/LevelSetSphere.h>

#include <Ogre.h>

#include "simulation/spatial_semantics.hpp"
#include "simulation/semantic_materials.hpp"
#include "procedural_cave.hpp"

#include <vector>
#include <cmath>
#include <iostream>

namespace SCR::VDB {

/**
 * OpenVDB Volumetric Isosurface Adapter for OGRE 3D (PI-CAVE-001H / Milestone 008).
 * Leverages OpenVDB's multi-threaded sparse B-tree volumeToMesh (Dual Contouring / Marching Cubes)
 * to generate organic, smooth cave geometry with adaptive polygon decimation and semantic material binding.
 */
class VdbCaveMesher {
public:
    static void buildNaturalCaveMesh(
        Ogre::ManualObject* manualObj,
        const Cave::VoxelCave& cave,
        float isovalue = 0.0f,
        float adaptivity = 0.02f
    ) {
        if (!manualObj) return;

        openvdb::initialize();

        // 1. Create OpenVDB FloatGrid for Cave Density
        // Background value is +1.0 (solid rock outside), negative is hollow cavern air
        openvdb::FloatGrid::Ptr grid = openvdb::FloatGrid::create(1.0f);
        grid->setName("CaveDensityIsoSurface");
        grid->setTransform(openvdb::math::Transform::createLinearTransform(cave.voxel_size));

        auto accessor = grid->getAccessor();

        int dx = cave.dim_x;
        int dy = cave.dim_y;
        int dz = cave.dim_z;

        // Sample density directly from authoritative cave field
        for (int z = 0; z <= dz; ++z) {
            for (int y = 0; y <= dy; ++y) {
                for (int x = 0; x <= dx; ++x) {
                    float signed_val = cave.sampleContinuousDensity((float)x, (float)y, (float)z);
                    accessor.setValue(openvdb::Coord(x, y, z), signed_val);
                }
            }
        }

        // 2. Execute OpenVDB Multi-Threaded Adaptive VolumeToMesh
        std::vector<openvdb::Vec3s> points;
        std::vector<openvdb::Vec3I> triangles;
        std::vector<openvdb::Vec4I> quads;

        openvdb::tools::volumeToMesh(
            *grid, points, triangles, quads,
            (double)isovalue, (double)adaptivity, true
        );

        std::cout << "[OpenVDB] Isosurface extracted: " << points.size() << " vertices, "
                  << triangles.size() << " triangles, " << quads.size() << " quads (adaptivity: " << adaptivity << ").\n";

        // 3. Stream Polygons into OGRE ManualObject
        manualObj->clear();
        manualObj->begin("SCR/SmoothCaveMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        const auto& reg = Material::MaterialRegistry::instance();

        // Compute Vertex Normals using central differences on the density field
        auto get_density = [&](float sx, float sy, float sz) -> float {
            openvdb::Coord c((int)std::floor(sx), (int)std::floor(sy), (int)std::floor(sz));
            return accessor.getValue(c);
        };

        std::vector<Ogre::Vector3> ogre_normals;
        ogre_normals.reserve(points.size());

        for (const auto& p : points) {
            float eps = 0.5f;
            float dx_val = get_density(p.x() + eps, p.y(), p.z()) - get_density(p.x() - eps, p.y(), p.z());
            float dy_val = get_density(p.x(), p.y() + eps, p.z()) - get_density(p.x(), p.y() - eps, p.z());
            float dz_val = get_density(p.x(), p.y(), p.z() + eps) - get_density(p.x(), p.y(), p.z() - eps);
            Ogre::Vector3 n(dx_val, dy_val, dz_val);
            if (n.squaredLength() > 1e-6f) n.normalise();
            else n = Ogre::Vector3::UNIT_Y;
            ogre_normals.push_back(n);
        }

        // Emit Vertices with Material-Aware Colors
        for (size_t i = 0; i < points.size(); ++i) {
            const auto& p = points[i];
            const auto& n = ogre_normals[i];

            // Sample semantic geological strata based on world position
            int vx = std::max(0, std::min(dx - 1, (int)std::floor(p.x())));
            int vy = std::max(0, std::min(dy - 1, (int)std::floor(p.y())));
            int vz = std::max(0, std::min(dz - 1, (int)std::floor(p.z())));

            uint16_t mat_code = cave.getVoxel(vx, vy, vz);
            if (mat_code == Material::MAT_AIR) {
                // Determine rock type from depth strata
                if (vy <= 2) mat_code = Material::MAT_BEDROCK;
                else if (vy <= 6) mat_code = Material::MAT_BASALT;
                else if (vy <= 12) mat_code = Material::MAT_GRANITE;
                else if (vy <= 18) mat_code = Material::MAT_LIMESTONE;
                else mat_code = Material::MAT_DIRT;
            }

            const auto& mat = reg.get(mat_code);

            // Position
            manualObj->position(p.x(), p.y(), p.z());
            // Normal
            manualObj->normal(n.x, n.y, n.z);
            // Texture Coord
            manualObj->textureCoord(p.x() * 0.25f, p.z() * 0.25f);
            // Shading Color from Material Contract
            manualObj->colour(mat.albedo.r, mat.albedo.g, mat.albedo.b, 1.0f);
        }

        // Triangles
        for (const auto& tri : triangles) {
            manualObj->triangle(tri[0], tri[1], tri[2]);
        }

        // Quads (split into 2 triangles: 0-1-2 and 0-2-3)
        for (const auto& quad : quads) {
            manualObj->triangle(quad[0], quad[1], quad[2]);
            manualObj->triangle(quad[0], quad[2], quad[3]);
        }

        manualObj->end();
        std::cout << "[OGRE] Smooth natural cave mesh committed to GPU vertex buffer.\n";
    }
};

} // namespace SCR::VDB

#endif // CAVE_VDB_CAVE_MESHER_HPP
