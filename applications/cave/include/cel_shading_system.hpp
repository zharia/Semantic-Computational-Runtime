#ifndef CAVE_CEL_SHADING_SYSTEM_HPP
#define CAVE_CEL_SHADING_SYSTEM_HPP

#include <Ogre.h>
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
        // 2. GLSL Fragment Shader: Vibrant Cel / Toon Surface with Underwater Caustics & Optical Extinction
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
uniform vec3 cameraPosition;
uniform float timeVal;

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

    // ── Smooth Stylized Cel Light Steps with Clean Shadow Termination
    float diffuseFactor = max(0.0, NdotL);
    float step1 = smoothstep(0.01, 0.08, diffuseFactor);
    float step2 = smoothstep(0.32, 0.42, diffuseFactor);
    float step3 = smoothstep(0.68, 0.78, diffuseFactor);
    float celStep = 0.40 * step1 + 0.35 * step2 + 0.25 * step3;

    // ── Subtle Cel Specular Highlight ───────────────────────────────────────
    float NdotH = max(0.0, dot(N, H));
    float spec = smoothstep(0.92, 0.97, NdotH) * 0.22 * step1;

    // ── Subtle Stylized Fresnel Rim Contour (tinted by baseColor) ───────────
    float NdotV = max(0.0, dot(N, V));
    float rim = pow(1.0 - NdotV, 3.5);
    float rimGlow = smoothstep(0.70, 0.95, rim) * 0.15;

    // ── Composite Base Shading ───────────────────────────────────────────────
    vec3 baseColor = vColor.rgb;
    vec3 ambient = ambientLightColour.rgb * 0.55;
    vec3 lightCol = lightDiffuseColour.rgb;

    vec3 diffuse = baseColor * (ambient + lightCol * celStep);
    vec3 rimLight = baseColor * (ambient + lightCol * 0.5) * rimGlow;
    vec3 specLight = lightSpecularColour.rgb * spec;
    vec3 finalRgb = max(baseColor * 0.05, diffuse + rimLight + specLight);

    // ── Underwater Optical Extinction & Animated Caustics ────────────────────
    const float SEA_LEVEL = 9.0;
    bool isUnderwater = (cameraPosition.y < SEA_LEVEL);

    if (isUnderwater) {
        float distToCam = length(cameraPosition - vWorldPos);
        float depthBelowSurface = max(0.0, SEA_LEVEL - vWorldPos.y);

        // Dynamic Animated Solar Caustic Ripple Web
        float c1 = sin(vWorldPos.x * 0.85 + vWorldPos.z * 0.75 + timeVal * 2.2) *
                   cos(vWorldPos.x * 0.65 - vWorldPos.z * 0.95 + timeVal * 1.8);
        float c2 = cos(vWorldPos.x * 1.35 - vWorldPos.z * 0.55 - timeVal * 2.6) *
                   sin(vWorldPos.x * 0.75 + vWorldPos.z * 1.45 + timeVal * 1.6);
        float caustic = max(0.0, (c1 + c2) * 0.5 + 0.15) * exp(-0.12 * depthBelowSurface) * 0.45;
        vec3 causticColor = vec3(0.25, 0.85, 0.95) * caustic;

        finalRgb += causticColor;

        // Multi-Spectral Optical Attenuation (Beer-Lambert in Water)
        vec3 absorption = vec3(0.035, 0.015, 0.008); // Red extinguishes first
        vec3 extinction = exp(-absorption * distToCam);
        vec3 abyssColor = vec3(0.02, 0.18, 0.32);

        finalRgb = finalRgb * extinction + abyssColor * (vec3(1.0) - extinction);
    }

    gl_FragColor = vec4(finalRgb, 1.0);
}
)");
            auto params = fp->getDefaultParameters();
            params->setNamedAutoConstant("lightDiffuseColour", Ogre::GpuProgramParameters::ACT_LIGHT_DIFFUSE_COLOUR, 0);
            params->setNamedAutoConstant("lightSpecularColour", Ogre::GpuProgramParameters::ACT_LIGHT_SPECULAR_COLOUR, 0);
            params->setNamedAutoConstant("ambientLightColour", Ogre::GpuProgramParameters::ACT_AMBIENT_LIGHT_COLOUR);
            params->setNamedAutoConstant("cameraPosition", Ogre::GpuProgramParameters::ACT_CAMERA_POSITION);
            params->setNamedAutoConstant("timeVal", Ogre::GpuProgramParameters::ACT_TIME_0_X, 1.0f);
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
        applyCelShadingToMaterial("SCR/VegetationMaterial");
        applyCelShadingToMaterial("SCR/BasaltRockMaterial");
        applyCelShadingToMaterial("SCR/VolcanicBoulderMaterial");

        std::cout << "[CelShading] Initialized 4-tier Quantized Cel Shading with Underwater Caustics & Optical Extinction.\n";
    }
};

} // namespace SCR::Render

#endif // CAVE_CEL_SHADING_SYSTEM_HPP
