/**
 * SCR Math / Noise — Multi-Scale Spectral Noise Synthesis
 * ─────────────────────────────────────────────────────────────────────────────
 * Application-layer implementation of SCR-LIB-MATH-NOISE (lib/202_Math/Noise/).
 *
 * Provides:
 *   SCR::Noise::PermTable          — shared deterministic permutation table
 *   SCR::Noise::GradientNoise3D    — gradient noise primitive (Perlin-class)
 *   SCR::Noise::CellularNoise2D    — Voronoi F1/F2-F1 (rock cracks, biome edges)
 *   SCR::Noise::RidgedMultifractal — ridged octaves (cliffs, ridgelines, bark)
 *   SCR::Noise::SpectralSynthesizer— FBM + domain warp + ridged mix
 *   SCR::Noise::CurlField2D        — divergence-free 2D curl (river paths)
 *
 * Semantic invariants (from 101_definition.md):
 *   - All functions are pure (no mutable state per sample)
 *   - Identical (x, z, seed, params) → identical output
 *   - Output ranges are as declared per type
 */

#ifndef SCR_MULTI_SCALE_NOISE_HPP
#define SCR_MULTI_SCALE_NOISE_HPP

#include <vector>
#include <cmath>
#include <algorithm>
#include <random>
#include <array>
#include <functional>

namespace SCR::Noise {

// ─── Permutation Table ───────────────────────────────────────────────────────
// Shared deterministic hash table. Seed is expanded to fill 512-entry double
// table for fast 3D indexing without wrapping.

struct PermTable {
    std::array<int,512> p;

    explicit PermTable(uint32_t seed=1337) {
        std::array<int,256> base;
        for(int i=0;i<256;i++) base[i]=i;
        std::mt19937 g(seed);
        std::shuffle(base.begin(),base.end(),g);
        for(int i=0;i<256;i++){p[i]=base[i]; p[256+i]=base[i];}
    }

    int operator[](int i) const { return p[i&511]; }
};

// ─── Interpolation Kernels ────────────────────────────────────────────────────

inline float smoothstep(float t) { return t*t*(3.f-2.f*t); }
inline float quintic(float t)    { return t*t*t*(t*(t*6.f-15.f)+10.f); }
inline float lerp(float t,float a,float b){ return a+t*(b-a); }

// ─── GradientNoise3D ─────────────────────────────────────────────────────────
// Standard 3D Perlin gradient noise. Output ∈ [-1, 1].

class GradientNoise3D {
    PermTable pt;
    static float grad(int h,float x,float y,float z){
        int hh=h&15; float u=hh<8?x:y; float v=hh<4?y:hh==12||hh==14?x:z;
        return ((hh&1)?-u:u)+((hh&2)?-v:v);
    }
public:
    explicit GradientNoise3D(uint32_t seed=1337):pt(seed){}

    float sample(float x,float y,float z) const {
        int X=((int)std::floor(x))&255;
        int Y=((int)std::floor(y))&255;
        int Z=((int)std::floor(z))&255;
        float xf=x-std::floor(x), yf=y-std::floor(y), zf=z-std::floor(z);
        float u=quintic(xf), v=quintic(yf), w=quintic(zf);
        int A=pt[X]+Y, AA=pt[A]+Z, AB=pt[A+1]+Z;
        int B=pt[X+1]+Y, BA=pt[B]+Z, BB=pt[B+1]+Z;
        return lerp(w,
            lerp(v,lerp(u,grad(pt[AA],xf,yf,zf),  grad(pt[BA],xf-1,yf,zf)),
                   lerp(u,grad(pt[AB],xf,yf-1,zf), grad(pt[BB],xf-1,yf-1,zf))),
            lerp(v,lerp(u,grad(pt[AA+1],xf,yf,zf-1),grad(pt[BA+1],xf-1,yf,zf-1)),
                   lerp(u,grad(pt[AB+1],xf,yf-1,zf-1),grad(pt[BB+1],xf-1,yf-1,zf-1))));
    }

    /** FBM wrapper for convenience. Output ∈ [-1, 1]. */
    float fbm(float x,float y,float z,int oct=6,float lac=2.f,float gain=.5f) const {
        float s=0,f=1,a=1,ma=0;
        for(int i=0;i<oct;i++){s+=sample(x*f,y*f,z*f)*a;ma+=a;f*=lac;a*=gain;}
        return ma>0?s/ma:0.f;
    }
};

// ─── CellularNoise2D ─────────────────────────────────────────────────────────
// Voronoi / Worley noise. Produces F1 (smooth regions) and F2-F1 (cracks).
// Output: F1 ∈ [0, ~1.4], F2-F1 ∈ [0, ~0.6].

struct CellResult { float f1, f2, f2_f1; float cell_id; };

class CellularNoise2D {
    PermTable pt;

    static float hashFloat(int x,int z,int seed){
        unsigned h=unsigned(x*73856093)^unsigned(z*19349663)^unsigned(seed*2654435761u);
        h=(h^(h>>16))*0x45d9f3b; h=(h^(h>>16))*0x45d9f3b; h^=(h>>16);
        return float(h)/float(0xFFFFFFFFu);
    }
public:
    explicit CellularNoise2D(uint32_t seed=1337):pt(seed){}

    /**
     * Sample cellular noise at (px,pz).
     * frequency controls cell size (higher = smaller cells).
     * jitter [0,1] controls how irregular the cell points are.
     */
    CellResult sample(float px,float pz,float frequency=1.f,float jitter=.95f) const {
        float sx=px*frequency, sz=pz*frequency;
        int ix=(int)std::floor(sx), iz=(int)std::floor(sz);

        float f1=1e9f,f2=1e9f; float cid=0;
        for(int dz=-2;dz<=2;dz++) for(int dx=-2;dx<=2;dx++){
            int cx=ix+dx, cz=iz+dz;
            // Feature point within cell [cx, cz]
            float fx_off=hashFloat(cx,cz,17)*jitter;
            float fz_off=hashFloat(cx+137,cz+251,29)*jitter;
            float fpx=float(cx)+.5f+fx_off-.5f;
            float fpz=float(cz)+.5f+fz_off-.5f;
            float dist=std::sqrt((sx-fpx)*(sx-fpx)+(sz-fpz)*(sz-fpz));
            if(dist<f1){f2=f1;f1=dist;cid=hashFloat(cx,cz,7);}
            else if(dist<f2){f2=dist;}
        }
        return {f1,f2,f2-f1,cid};
    }

    /** Convenience: crack pattern (F2-F1), output ∈ [0, ~0.5]. */
    float crack(float px,float pz,float frequency=1.f) const {
        return sample(px,pz,frequency).f2_f1;
    }
};

// ─── RidgedMultifractal ───────────────────────────────────────────────────────
// Ridged noise: r = 1 - |noise(x)| per octave, with spectral weight.
// Output ∈ [0, 1]. Values near 1 are sharp ridges.

class RidgedMultifractal {
    GradientNoise3D g;
public:
    explicit RidgedMultifractal(uint32_t seed=1337):g(seed){}

    float sample(float x,float y,float z,
                 int octaves=6,float lacunarity=2.f,float gain=.5f,float offset=1.f) const {
        float result=0,weight=1,freq=1,amp=.5f,max_amp=0;
        for(int i=0;i<octaves;i++){
            float n=std::abs(g.sample(x*freq,y*freq,z*freq));
            n=offset-n;         // invert: ridges become peaks
            n*=n;               // sharpen
            n*=weight;          // spectral weight from previous octave
            result+=n*amp;
            max_amp+=amp;
            weight=std::min(1.f,std::max(0.f,n*2.f));  // weight next octave by signal
            freq*=lacunarity; amp*=gain;
        }
        return max_amp>0?result/max_amp:0.f;
    }
};

// ─── DomainWarp ───────────────────────────────────────────────────────────────
// Quilez-style recursive domain warping: p' = p + A·N(p·f)
// Produces organic distortions: river bends, coastal irregularities.

class DomainWarp {
    GradientNoise3D g1, g2;
public:
    explicit DomainWarp(uint32_t seed=1337):g1(seed),g2(seed^0xDEADBEEF){}

    /**
     * Warp 2D coordinates (x, z):
     *   iter=1: single warp pass (moderate organic feel)
     *   iter=2: double warp (strong turbulent feel)
     *   amplitude: displacement magnitude in voxel units
     *   frequency: input frequency (smaller = larger warp features)
     */
    std::pair<float,float> warp(float x,float z,
                                float amplitude=8.f,float frequency=0.04f,
                                int iterations=2) const {
        float wx=x, wz=z;
        for(int i=0;i<iterations;i++){
            float offx=g1.sample(wx*frequency, 0.f, wz*frequency)*amplitude;
            float offz=g2.sample(wx*frequency, 1.73f, wz*frequency)*amplitude;
            wx=x+offx; wz=z+offz;
            amplitude*=.6f; frequency*=2.f;
        }
        return {wx,wz};
    }
};

// ─── CurlField2D ─────────────────────────────────────────────────────────────
// Divergence-free 2D vector field: curl of scalar potential ψ(x,z).
// v = (∂ψ/∂z, -∂ψ/∂x) — approximated by finite differences.
// Streamlines preserve topology: no sources, no sinks.

struct CurlVector2D { float dx, dz; float magnitude() const { return std::sqrt(dx*dx+dz*dz); } };

class CurlField2D {
    GradientNoise3D psi; // scalar potential field
    static constexpr float EPS = 0.01f;
public:
    explicit CurlField2D(uint32_t seed=1337):psi(seed){}

    /**
     * Sample the curl field at (x, z) with given frequency.
     * Returns a unit-length 2D direction vector for a flow field.
     */
    CurlVector2D sample(float x,float z,float frequency=0.05f) const {
        float p00=psi.sample(x*frequency,            0.f, z*frequency);
        float p01=psi.sample(x*frequency,            0.f,(z+EPS)*frequency);
        float p10=psi.sample((x+EPS)*frequency, 0.f, z*frequency);
        // curl = (∂ψ/∂z, -∂ψ/∂x)
        float cdx=(p01-p00)/EPS;
        float cdz=-(p10-p00)/EPS;
        float len=std::sqrt(cdx*cdx+cdz*cdz)+1e-8f;
        return {cdx/len, cdz/len};
    }
};

// ─── SpectralSynthesizer ──────────────────────────────────────────────────────
// Combines FBM, domain warping, ridged noise, and cellular detail into a
// single coherent terrain height signal per (x, z).

struct SpectralParams {
    int   base_octaves   = 6;
    float lacunarity     = 2.f;
    float gain           = 0.5f;

    float domain_warp_amplitude  = 8.f;
    float domain_warp_frequency  = 0.035f;
    int   domain_warp_iterations = 2;

    float ridge_weight   = 0.4f;  // blend of ridged noise into output
    int   ridge_octaves  = 5;

    float cell_weight    = 0.08f; // F2-F1 crack detail on rocky surfaces
    float cell_frequency = 0.22f;
};

class SpectralSynthesizer {
    GradientNoise3D  base_noise;
    RidgedMultifractal ridge_noise;
    CellularNoise2D  cell_noise;
    DomainWarp       warp;
    uint32_t         seed;

public:
    explicit SpectralSynthesizer(uint32_t seed_=1337)
        : base_noise(seed_), ridge_noise(seed_^0xA5B6),
          cell_noise(seed_^0xC7D8), warp(seed_^0xE9FA), seed(seed_) {}

    /**
     * Full multi-scale terrain height signal at (x, z).
     * Returns a dimensionless value ∈ [-1, 1] to be scaled by caller.
     *
     * Pipeline:
     *   1. Domain warp coordinates (organic distortion)
     *   2. Base FBM on warped coords (macro terrain shape)
     *   3. Mix ridged noise (cliff ridges, rock faces)
     *   4. Add cellular detail (rock cracks on upper slopes)
     */
    float terrain(float x, float z, const SpectralParams& p = SpectralParams{}) const {
        // Step 1: domain warp
        auto [wx, wz] = warp.warp(x, z, p.domain_warp_amplitude,
                                  p.domain_warp_frequency, p.domain_warp_iterations);

        // Step 2: base FBM
        float base = base_noise.fbm(wx*0.04f, 0.f, wz*0.04f,
                                    p.base_octaves, p.lacunarity, p.gain);

        // Step 3: ridged noise contribution
        float ridge = ridge_noise.sample(wx*0.055f, 0.f, wz*0.055f,
                                         p.ridge_octaves, p.lacunarity, p.gain);

        // Step 4: cellular crack detail
        float cell = cell_noise.crack(wx, wz, p.cell_frequency) * 2.f - .5f;

        return base*(1.f-p.ridge_weight) + ridge*p.ridge_weight + cell*p.cell_weight;
    }

    /**
     * Multi-scale normal estimation at (x, z) — finite differences.
     * Returns (nx, nz) the horizontal gradient (slope direction).
     */
    std::pair<float,float> gradient(float x,float z,float eps=0.5f,
                                    const SpectralParams& p=SpectralParams{}) const {
        float h0=terrain(x,z,p);
        float hx=terrain(x+eps,z,p);
        float hz=terrain(x,z+eps,p);
        return {(hx-h0)/eps, (hz-h0)/eps};
    }
};

} // namespace SCR::Noise
#endif // SCR_MULTI_SCALE_NOISE_HPP
