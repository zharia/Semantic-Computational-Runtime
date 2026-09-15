# Sprint 04: Volumetric Effect Rendering

**Parent Milestone:** [Milestone 009: PI-CAVE-001I Semantic Field Effects](../spec.md)  
**Derived from:** `spec.md` (Sections 56, 97)  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md)  
**Status:** Planned  

---

## 1. Mission

Implement volumetric raymarching in OGRE/OpenGL to visualize sparse OpenVDB/NanoVDB density fields as translucent smoke, compositing volumetric fluid elements seamlessly with 2D application surface quads.

---

## 2. Technical Specifications & Shader Pipeline

### 2.1 Volumetric Raymarching Shader
In the fragment shader for the volumetric bounding box:
```glsl
// fragment shader: smoke_raymarch.frag
uniform sampler3D u_densityGrid; // Or NanoVDB SSBO buffer
uniform vec3 u_lightDir;
uniform vec4 u_smokeColor;

void main() {
    vec3 rayOrigin = v_rayOrigin;
    vec3 rayDir = normalize(v_rayDir);
    
    float tNear, tFar;
    if (!intersectBox(rayOrigin, rayDir, u_boxMin, u_boxMax, tNear, tFar)) discard;
    
    float t = max(0.0, tNear);
    float stepSize = (tFar - tNear) / float(NUM_STEPS);
    
    vec4 accum = vec4(0.0);
    for (int i = 0; i < NUM_STEPS && t < tFar; ++i) {
        vec3 p = rayOrigin + t * rayDir;
        vec3 uvw = worldToGridUV(p);
        float density = texture(u_densityGrid, uvw).r;
        
        if (density > 0.001) {
            float alpha = density * stepSize * u_absorption;
            vec3 light = calculateLight(p, u_lightDir);
            accum.rgb += (1.0 - accum.a) * alpha * light * u_smokeColor.rgb;
            accum.a += (1.0 - accum.a) * alpha;
            if (accum.a >= 0.95) break;
        }
        t += stepSize;
    }
    gl_FragColor = accum;
}
```

### 2.2 Depth Buffer Integration
* Bind the scene depth buffer from the surface quad pass as an input texture to the raymarching pass.
* Constrain $t_{\text{far}} = \min(t_{\text{box\_far}}, t_{\text{depth\_buffer}})$ so that volumetric smoke terminates accurately behind opaque window surfaces.

---

## 3. Verification & Testing Tasks

1. **Occlusion Test:** Move smoke trail behind a window surface; verify that smoke is occluded and does not draw on top of window content.
2. **Volumetric Frame Rate Benchmark:** Raymarch a $256 \times 256 \times 256$ active bounding box; assert rendering overhead is $< 4\text{ms}$ per frame on modern GPU.
3. **Artifact Elimination:** Verify smooth integration without staircasing or banding artifacts.
