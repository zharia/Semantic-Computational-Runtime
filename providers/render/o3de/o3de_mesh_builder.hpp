#ifndef SCR_O3DE_MESH_BUILDER_HPP
#define SCR_O3DE_MESH_BUILDER_HPP

#include <vector>
#include <cstdint>
#include <Atom/RPI.Public/Scene.h>
#include <Atom/RPI.Public/Material/Material.h>
#include <Atom/Feature/Mesh/MeshFeatureProcessorInterface.h>
#include <Atom/RPI.Reflect/Buffer/BufferAsset.h>
#include <Atom/RPI.Reflect/Buffer/BufferAssetCreator.h>
#include <Atom/RPI.Reflect/Buffer/BufferAssetView.h>
#include <Atom/RPI.Reflect/Model/ModelAsset.h>
#include <Atom/RPI.Reflect/Model/ModelAssetCreator.h>
#include <Atom/RPI.Reflect/Model/ModelLodAsset.h>
#include <Atom/RPI.Reflect/Model/ModelLodAssetCreator.h>
#include <Atom/RPI.Reflect/Model/ModelMaterialSlot.h>
#include <Atom/RPI.Reflect/Material/MaterialAsset.h>
#include <Atom/RHI.Reflect/ShaderSemantic.h>
#include <AzCore/Asset/AssetManager.h>
#include <AzCore/Asset/AssetManagerBus.h>
#include <AzCore/Math/Vector3.h>
#include <AzCore/Math/Vector2.h>
#include <AzCore/Math/Aabb.h>
#include <AzCore/Math/Transform.h>

namespace SCR::Render::O3DE {

struct MeshVertex {
    AZ::Vector3 position;
    AZ::Vector3 normal;
    AZ::Vector3 tangent;
    float tangent_w;
    AZ::Vector2 uv;
    MeshVertex() = default;
    MeshVertex(AZ::Vector3 p, AZ::Vector3 n, AZ::Vector3 t, float w, AZ::Vector2 u)
        : position(p), normal(n), tangent(t), tangent_w(w), uv(u) {}
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
        AZ::Vector3 n(nx, ny, nz);
        AZ::Vector3 t = n.Cross(AZ::Vector3(0.0f, 0.0f, 1.0f));
        if (t.IsZero()) t = n.Cross(AZ::Vector3(1.0f, 0.0f, 0.0f));
        t.NormalizeSafe();
        return MeshVertex(AZ::Vector3(px, py, pz), n, t, 1.0f, AZ::Vector2(u, v));
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

    AZ::Data::Asset<AZ::RPI::ModelAsset> createModelAsset(
        AZ::Data::Instance<AZ::RPI::Material> material,
        const char* name) const
    {
        if (vertices.empty() || indices.empty() || !material) return {};

        static uint32_t nextId = 1;
        uint32_t id = nextId++;
        AZ::Uuid baseGuid = AZ::Uuid::Create();

        AZ::Data::Asset<AZ::RPI::BufferAsset> vertexBufferAsset;
        {
            AZ::RPI::BufferAssetCreator creator;
            creator.Begin(AZ::Data::AssetId(baseGuid, id * 10 + 1));
            creator.SetBufferName(AZStd::string(name) + "_VB");
            AZ::RHI::BufferDescriptor vDesc;
            vDesc.m_byteCount = vertices.size() * sizeof(MeshVertex);
            vDesc.m_bindFlags = AZ::RHI::BufferBindFlags::InputAssembly;
            creator.SetBuffer(vertices.data(), vertices.size() * sizeof(MeshVertex), vDesc);
            creator.SetUseCommonPool(AZ::RPI::CommonBufferPoolType::StaticInputAssembly);
            creator.SetBufferViewDescriptor(AZ::RHI::BufferViewDescriptor::CreateStructured(
                0, static_cast<uint32_t>(vertices.size()), sizeof(MeshVertex)));
            creator.End(vertexBufferAsset);
        }

        AZ::Data::Asset<AZ::RPI::BufferAsset> indexBufferAsset;
        {
            AZ::RPI::BufferAssetCreator creator;
            creator.Begin(AZ::Data::AssetId(baseGuid, id * 10 + 2));
            creator.SetBufferName(AZStd::string(name) + "_IB");
            AZ::RHI::BufferDescriptor iDesc;
            iDesc.m_byteCount = indices.size() * sizeof(uint32_t);
            iDesc.m_bindFlags = AZ::RHI::BufferBindFlags::InputAssembly;
            creator.SetBuffer(indices.data(), indices.size() * sizeof(uint32_t), iDesc);
            creator.SetUseCommonPool(AZ::RPI::CommonBufferPoolType::StaticInputAssembly);
            creator.SetBufferViewDescriptor(AZ::RHI::BufferViewDescriptor::CreateStructured(
                0, static_cast<uint32_t>(indices.size()), sizeof(uint32_t)));
            creator.End(indexBufferAsset);
        }

        uint32_t vcount = static_cast<uint32_t>(vertices.size());
        AZ::RHI::BufferViewDescriptor vertViewDesc = AZ::RHI::BufferViewDescriptor::CreateStructured(
            0, vcount, sizeof(MeshVertex));
        AZ::RPI::BufferAssetView posView(vertexBufferAsset, vertViewDesc);
        AZ::RPI::BufferAssetView normView(vertexBufferAsset, vertViewDesc);
        AZ::RPI::BufferAssetView tangentView(vertexBufferAsset, vertViewDesc);
        AZ::RPI::BufferAssetView uvView(vertexBufferAsset, vertViewDesc);
        AZ::RHI::BufferViewDescriptor indexViewDesc = AZ::RHI::BufferViewDescriptor::CreateStructured(
            0, static_cast<uint32_t>(indices.size()), sizeof(uint32_t));
        AZ::RPI::BufferAssetView indexView(indexBufferAsset, indexViewDesc);

        AZ::Data::Asset<AZ::RPI::ModelLodAsset> lodAsset;
        {
            AZ::RPI::ModelLodAssetCreator creator;
            creator.Begin(AZ::Data::AssetId(baseGuid, id * 10 + 3));
            creator.AddLodStreamBuffer(vertexBufferAsset);
            creator.SetLodIndexBuffer(indexBufferAsset);

            creator.BeginMesh();
            creator.SetMeshAabb(computeBounds());
            creator.SetMeshMaterialSlot(0);
            creator.SetMeshIndexBuffer(indexView);

            {
                AZ::RPI::ModelLodAsset::Mesh::StreamBufferInfo info;
                info.m_semantic = AZ::RHI::ShaderSemantic(AZ::Name("POSITION"), 0);
                info.m_bufferAssetView = posView;
                creator.AddMeshStreamBuffer(info);
            }
            {
                AZ::RPI::ModelLodAsset::Mesh::StreamBufferInfo info;
                info.m_semantic = AZ::RHI::ShaderSemantic(AZ::Name("NORMAL"), 0);
                info.m_bufferAssetView = normView;
                creator.AddMeshStreamBuffer(info);
            }
            {
                AZ::RPI::ModelLodAsset::Mesh::StreamBufferInfo info;
                info.m_semantic = AZ::RHI::ShaderSemantic(AZ::Name("TANGENT"), 0);
                info.m_bufferAssetView = tangentView;
                creator.AddMeshStreamBuffer(info);
            }
            {
                AZ::RPI::ModelLodAsset::Mesh::StreamBufferInfo info;
                info.m_semantic = AZ::RHI::ShaderSemantic(AZ::Name("TEXCOORD_0"), 0);
                info.m_bufferAssetView = uvView;
                creator.AddMeshStreamBuffer(info);
            }

            creator.EndMesh();
            creator.End(lodAsset);
        }

        AZ::Data::Asset<AZ::RPI::ModelAsset> modelAsset;
        {
            AZ::RPI::ModelAssetCreator creator;
            creator.Begin(AZ::Data::AssetId(baseGuid, id * 10 + 4));
            creator.SetName(name);
            creator.AddLodAsset(AZStd::move(lodAsset));

            AZ::RPI::ModelMaterialSlot slot;
            slot.m_stableId = 0;
            slot.m_defaultMaterialAsset = material->GetAsset();
            creator.AddMaterialSlot(slot);

            creator.End(modelAsset);
        }

        return modelAsset;
    }
};

struct MaterialCache {
    AZ::Data::Instance<AZ::RPI::Material> terrain;
    AZ::Data::Instance<AZ::RPI::Material> lava;
    AZ::Data::Instance<AZ::RPI::Material> ocean;
    AZ::Data::Instance<AZ::RPI::Material> smoke;
    AZ::Data::Instance<AZ::RPI::Material> vegetation;
    AZ::Data::Instance<AZ::RPI::Material> cloud;
    AZ::Data::Asset<AZ::RPI::MaterialAsset> cloud_asset;
    bool loaded = false;

    static MaterialCache& instance() {
        static MaterialCache s_instance;
        return s_instance;
    }

    void load() {
        if (loaded) return;

        auto load_asset = [](const char* path) -> AZ::Data::Asset<AZ::RPI::MaterialAsset> {
            AZ::Data::AssetId assetId;
            AZ::Data::AssetType matType = azrtti_typeid<AZ::RPI::MaterialAsset>();
            AZ::Data::AssetCatalogRequestBus::BroadcastResult(
                assetId,
                &AZ::Data::AssetCatalogRequestBus::Events::GetAssetIdByPath,
                path, matType, true);
            if (!assetId.IsValid()) {
                return {};
            }
            return AZ::Data::AssetManager::Instance().GetAsset<AZ::RPI::MaterialAsset>(
                assetId, AZ::Data::AssetLoadBehavior::PreLoad);
        };

        auto load_one = [&load_asset](const char* path) -> AZ::Data::Instance<AZ::RPI::Material> {
            auto asset = load_asset(path);
            if (!asset.Get()) {
                return nullptr;
            }
            return AZ::RPI::Material::FindOrCreate(asset);
        };

        terrain = load_one("assets/materials/terrain_basalt.azmaterial");
        lava = load_one("assets/materials/lava_molten.azmaterial");
        ocean = load_one("assets/materials/ocean_water.azmaterial");
        smoke = load_one("assets/materials/smoke_ash.azmaterial");
        vegetation = load_one("assets/materials/vegetation_green.azmaterial");
        cloud_asset = load_asset("assets/materials/cloud_deck.azmaterial");
        cloud = cloud_asset.Get() ? AZ::RPI::Material::FindOrCreate(cloud_asset) : nullptr;
        loaded = true;
    }
};

struct O3deMeshHandle {
    AZ::Render::MeshFeatureProcessorInterface::MeshHandle handle;
    bool valid = false;
};

struct ModelCache {
    AZ::Data::Asset<AZ::RPI::ModelAsset> sphere;
    AZ::Data::Asset<AZ::RPI::ModelAsset> plane;
    bool sphere_ready = false;
    bool plane_ready = false;
    bool loading_started = false;

    void startLoading() {
        if (loading_started) return;
        loading_started = true;
        auto startLoad = [](const char* path, AZ::Data::Asset<AZ::RPI::ModelAsset>& out, bool& ready) {
            AZ::Data::AssetId assetId;
            AZ::Data::AssetCatalogRequestBus::BroadcastResult(
                assetId, &AZ::Data::AssetCatalogRequestBus::Events::GetAssetIdByPath,
                path, azrtti_typeid<AZ::RPI::ModelAsset>(), true);
            if (!assetId.IsValid()) {
                return;
            }
            out = AZ::Data::AssetManager::Instance().GetAsset<AZ::RPI::ModelAsset>(
                assetId, AZ::Data::AssetLoadBehavior::QueueLoad);
            ready = true;
        };
        // Catalog root is Cache/linux — product paths are relative to it
        startLoad("models/sphere.fbx.azmodel", sphere, sphere_ready);
        startLoad("models/occlusioncullingplane.fbx.azmodel", plane, plane_ready);
    }

    bool isReady() { return sphere_ready && sphere.Get(); }
};

inline O3deMeshHandle submitMesh(
    AZStd::shared_ptr<AZ::RPI::Scene> scene,
    const MeshData& mesh,
    AZ::Data::Instance<AZ::RPI::Material> material,
    const AZ::Transform& transform,
    const AZ::Vector3& scale,
    const char* name,
    bool use_plane = false)
{
    O3deMeshHandle result;
    if (!scene || !material) return result;

    auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
    if (!fp) return result;

    static ModelCache models;
    models.startLoading();
    if (use_plane) {
        if (!models.plane_ready) return result;
    } else {
        if (!models.isReady()) return result;
    }

    AZ::Data::Asset<AZ::RPI::ModelAsset> modelAsset = use_plane ? models.plane : models.sphere;

    AZ::Render::MeshHandleDescriptor desc(modelAsset, material);
    result.handle = fp->AcquireMesh(desc);
    if (!result.handle.IsNull()) {
        fp->SetTransform(result.handle, transform, scale);
        result.valid = true;
    }

    return result;
}

// Submit a flat plane (cloud decks). Prefers the occlusion-culling plane model.
inline O3deMeshHandle submitPlane(
    AZStd::shared_ptr<AZ::RPI::Scene> scene,
    AZ::Data::Instance<AZ::RPI::Material> material,
    const AZ::Transform& transform,
    const AZ::Vector3& scale,
    const char* name)
{
    return submitMesh(scene, MeshData(), material, transform, scale, name, true);
}

// Submit a runtime-built procedural mesh (heightfield terrain, lava ribbon,
// plume column). Builds a ModelAsset from MeshData and acquires it directly.
// Uses the same Buffer/Index/Model creation as the sphere path — the only
// addition over createModelAsset is direct acquire without a cached asset.
inline O3deMeshHandle submitMeshData(
    AZStd::shared_ptr<AZ::RPI::Scene> scene,
    const MeshData& mesh,
    AZ::Data::Instance<AZ::RPI::Material> material,
    const AZ::Transform& transform,
    const AZ::Vector3& scale,
    const char* name)
{
    O3deMeshHandle result;
    if (!scene || !material) return result;

    auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
    if (!fp) return result;

    auto modelAsset = mesh.createModelAsset(material, name);
    if (!modelAsset) return result;

    AZ::Render::MeshHandleDescriptor desc(modelAsset, material);
    result.handle = fp->AcquireMesh(desc);
    if (!result.handle.IsNull()) {
        fp->SetTransform(result.handle, transform, scale);
        result.valid = true;
    }

    return result;
}

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_MESH_BUILDER_HPP
