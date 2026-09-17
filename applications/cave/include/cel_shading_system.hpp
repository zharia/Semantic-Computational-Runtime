#ifndef CAVE_CEL_SHADING_SYSTEM_HPP
#define CAVE_CEL_SHADING_SYSTEM_HPP

#include <Ogre.h>
#include <OgreMaterialManager.h>
#include <OgreHighLevelGpuProgramManager.h>
#include <OgreGpuProgramParams.h>
#include <iostream>
#include <string>

namespace SCR::Render {

enum class CelShadingMode {
    STYLED_CEL_4TIER = 0,
    BOLD_COMIC_2TIER = 1,
    CLASSIC_PHONG    = 2
};

class CelShadingSystem {
public:
    static inline CelShadingMode current_mode = CelShadingMode::STYLED_CEL_4TIER;

    static void initializeCelShading(bool enable_outlines = false) {
        auto mm = Ogre::MaterialManager::getSingletonPtr();
        auto& gpuMgr = Ogre::HighLevelGpuProgramManager::getSingleton();

        // ─────────────────────────────────────────────────────────────────────
        // 1. GLSL Vertex Shader: Cel / Toon Surface
        // ─────────────────────────────────────────────────────────────────────
        Ogre::HighLevelGpuProgramPtr vp;
        if (!gpuMgr.resourceExists("SCR/CelSurfaceVP", Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)) {
            vp = gpuMgr.createProgram(
                "SCR/CelSurfaceVP",
                Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
                "glsl",
                Ogre::GPT_VERTEX_PROGRAM
            );
            vp->setSource(R"(
uniform mat4 worldViewProj;
uniform mat4 world;
uniform mat4 worldIT;
uniform vec4 lightPosition;
uniform vec3 cameraPosition;

attribute vec4 vertex;
attribute vec3 normal;
attribute vec4 colour;
attribute vec2 uv0;

varying vec3 vWorldNormal;
varying vec3 vWorldPos;
varying vec4 vColor;
varying vec3 vLightDir;
varying vec3 vViewDir;
varying vec2 vUv;

void main() {
    gl_Position = worldViewProj * vertex;
    vec4 worldPos = world * vertex;
    vWorldPos = worldPos.xyz;
    vWorldNormal = normalize((worldIT * vec4(normal, 0.0)).xyz);
    vColor = colour;
    vUv = uv0;

    if (lightPosition.w == 0.0) {
        vLightDir = normalize(lightPosition.xyz);
    } else {
        vLightDir = normalize(lightPosition.xyz - worldPos.xyz);
    }

    vViewDir = normalize(cameraPosition - worldPos.xyz);
}
)");
            auto params = vp->getDefaultParameters();
            params->setNamedAutoConstant("worldViewProj", Ogre::GpuProgramParameters::ACT_WORLDVIEWPROJ_MATRIX);
            params->setNamedAutoConstant("world", Ogre::GpuProgramParameters::ACT_WORLD_MATRIX);
            params->setNamedAutoConstant("worldIT", Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_WORLD_MATRIX);
            params->setNamedAutoConstant("lightPosition", Ogre::GpuProgramParameters::ACT_LIGHT_POSITION, 0);
            params->setNamedAutoConstant("cameraPosition", Ogre::GpuProgramParameters::ACT_CAMERA_POSITION);
        }

        // ─────────────────────────────────────────────────────────────────────
        // 2. GLSL Fragment Shader: Vibrant Cel / Toon Surface
        // ─────────────────────────────────────────────────────────────────────
        Ogre::HighLevelGpuProgramPtr fp;
        if (!gpuMgr.resourceExists("SCR/CelSurfaceFP", Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)) {
            fp = gpuMgr.createProgram(
                "SCR/CelSurfaceFP",
                Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
                "glsl",
                Ogre::GPT_FRAGMENT_PROGRAM
            );
            fp->setSource(R"(
uniform vec4 lightDiffuseColour;
uniform vec4 lightSpecularColour;
uniform vec4 ambientLightColour;

varying vec3 vWorldNormal;
varying vec3 vWorldPos;
varying vec4 vColor;
varying vec3 vLightDir;
varying vec3 vViewDir;
varying vec2 vUv;

void main() {
    vec3 N = normalize(vWorldNormal);
    vec3 L = normalize(vLightDir);
    vec3 V = normalize(vViewDir);
    vec3 H = normalize(L + V);

    float NdotL = dot(N, L);

    // ── 4-Tier Quantized Cel Light Steps (Vibrant Stylized Anime / Ghibli Aesthetic)
    float band0 = smoothstep(-0.25, -0.15, NdotL);
    float band1 = smoothstep( 0.05,  0.15, NdotL);
    float band2 = smoothstep( 0.40,  0.50, NdotL);
    float band3 = smoothstep( 0.72,  0.82, NdotL);
    float celStep = 0.42 + 0.22 * band0 + 0.20 * band1 + 0.16 * band2 + 0.10 * band3;

    // ── High-Contrast Cel Specular Hot-Spot ──────────────────────────────────
    float NdotH = max(0.0, dot(N, H));
    float spec = smoothstep(0.88, 0.94, NdotH) * 0.45;

    // ── Stylized Fresnel Rim Contour (Anime Edge Glow) ──────────────────────
    float NdotV = max(0.0, dot(N, V));
    float rim = pow(1.0 - NdotV, 2.5);
    float rimGlow = smoothstep(0.50, 0.85, rim) * 0.35;

    // ── Hemispherical Sky Ambient ───────────────────────────────────────────
    float hemiLight = clamp(0.75 + 0.25 * N.y, 0.65, 1.0);

    // ── Composite Color with Rich Saturation ────────────────────────────────
    vec3 baseColor = vColor.rgb;
    vec3 ambient = ambientLightColour.rgb;
    vec3 lightCol = lightDiffuseColour.rgb;

    vec3 diffuse = baseColor * (ambient * 0.75 + lightCol * celStep * 0.90) * hemiLight;
    vec3 highlight = (lightSpecularColour.rgb * spec) + (lightDiffuseColour.rgb * rimGlow * 0.4);

    vec3 finalRgb = diffuse + highlight;
    gl_FragColor = vec4(finalRgb, vColor.a);
}
)");
            auto params = fp->getDefaultParameters();
            params->setNamedAutoConstant("lightDiffuseColour", Ogre::GpuProgramParameters::ACT_LIGHT_DIFFUSE_COLOUR, 0);
            params->setNamedAutoConstant("lightSpecularColour", Ogre::GpuProgramParameters::ACT_LIGHT_SPECULAR_COLOUR, 0);
            params->setNamedAutoConstant("ambientLightColour", Ogre::GpuProgramParameters::ACT_AMBIENT_LIGHT_COLOUR);
        }

        // ─────────────────────────────────────────────────────────────────────
        // 3. Apply Cel-Shading Passes to Target Materials
        // ─────────────────────────────────────────────────────────────────────
        auto applyCelShadingToMaterial = [&](const std::string& matName) {
            Ogre::MaterialPtr m = mm->getByName(matName);
            if (!m) {
                m = mm->create(matName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            }
            m->removeAllTechniques();
            Ogre::Technique* tech = m->createTechnique();

            // Cel Shaded Surface Pass
            Ogre::Pass* pSurface = tech->createPass();
            pSurface->setName("CelSurfacePass");
            pSurface->setCullingMode(Ogre::CULL_NONE);
            pSurface->setDepthWriteEnabled(true);
            pSurface->setDepthCheckEnabled(true);
            pSurface->setVertexProgram("SCR/CelSurfaceVP");
            pSurface->setFragmentProgram("SCR/CelSurfaceFP");
        };

        applyCelShadingToMaterial("SCR/VolcanicIslandMaterial");
        applyCelShadingToMaterial("SCR/DiscreteBlockMaterial");

        std::cout << "[CelShading] Initialized 4-tier Quantized Cel Shading + Specular + Fresnel Rim.\n";
    }
};

} // namespace SCR::Render

#endif // CAVE_CEL_SHADING_SYSTEM_HPP
