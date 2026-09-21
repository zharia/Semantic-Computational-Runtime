#ifndef SCR_O3DE_MESH_BUILDER_HPP
#define SCR_O3DE_MESH_BUILDER_HPP

#include <vector>
#include <cstdint>
#include <Atom/RPI.Public/DynamicDraw/DynamicDrawInterface.h>
#include <Atom/RPI.Public/Material/Material.h>
#include <Atom/RPI.Public/Scene.h>
#include <AzCore/Math/Vector3.h>
#include <AzCore/Math/Vector2.h>
#include <AzCore/Math/Aabb.h>

namespace SCR::Render::O3DE {

struct MeshVertex {
    AZ::Vector3 position;
    AZ::Vector3 normal;
    AZ::Vector2 uv;

    MeshVertex() = default;
    MeshVertex(AZ::Vector3 p, AZ::Vector3 n, AZ::Vector2 u)
        : position(p), normal(n), uv(u) {}
};

struct MeshData {
    std::vector<MeshVertex> vertices;
    std::vector<uint32_t> indices;
    uint32_t vertex_count() const { return static_cast<uint32_t>(vertices.size()); }
    uint32_t index_count() const { return static_cast<uint32_t>(indices.size()); }

    void clear() { vertices.clear(); indices.clear(); }

    void addTriangle(uint32_t i0, uint32_t i1, uint32_t i2) {
        indices.push_back(i0);
        indices.push_back(i1);
        indices.push_back(i2);
    }

    void addQuad(uint32_t i0, uint32_t i1, uint32_t i2, uint32_t i3) {
        addTriangle(i0, i1, i2);
        addTriangle(i0, i2, i3);
    }

    static MeshVertex vert(float px, float py, float pz, float nx, float ny, float nz, float u, float v) {
        return MeshVertex(AZ::Vector3(px, py, pz), AZ::Vector3(nx, ny, nz), AZ::Vector2(u, v));
    }

    AZ::Aabb computeBounds() const {
        if (vertices.empty()) return AZ::Aabb::CreateNull();
        AZ::Vector3 min_v = vertices[0].position;
        AZ::Vector3 max_v = vertices[0].position;
        for (const auto& v : vertices) {
            min_v = min_v.GetMin(v.position);
            max_v = max_v.GetMax(v.position);
        }
        return AZ::Aabb::CreateFromMinMax(min_v, max_v);
    }

    void draw(AZ::Data::Instance<AZ::RPI::Material> material, AZStd::shared_ptr<AZ::RPI::Scene> scene) const {
        if (vertices.empty() || indices.empty() || !material || !scene) return;

        auto* dynDraw = AZ::RPI::GetDynamicDraw();
        if (!dynDraw) return;

        AZ::RPI::GeometryData geom;
        geom.m_vertexData = vertices.data();
        geom.m_vertexDataSize = static_cast<uint32_t>(vertices.size() * sizeof(MeshVertex));
        geom.m_vertexCount = static_cast<uint32_t>(vertices.size());
        geom.m_indexData = indices.data();
        geom.m_indexDataSize = static_cast<uint32_t>(indices.size() * sizeof(uint32_t));
        geom.m_indexCount = static_cast<uint32_t>(indices.size());

        dynDraw->DrawGeometry(material, geom, scene);
    }
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_MESH_BUILDER_HPP
