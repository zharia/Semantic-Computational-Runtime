---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-MATH-NOISE
name: Stochastic Spectral Noise Synthesis

version: 0.1.0
status: operational

created: 2026-09-16
updated: 2026-09-16

parent: SCR-LIB-MATH
authority: SCR
domain: semantic-library
---

# SCR Math: Stochastic Spectral Noise Synthesis

## Summary

Deterministic stochastic functions mapping spatial coordinates to scalar or vector
outputs across one or more frequency bands. Used as input signals for procedural
geometry synthesis, material distribution, and environmental simulation.

---

## 1. Semantic Definition

A **noise function** is a deterministic function N: ℝⁿ → ℝ parameterised by a
seed that produces spatially coherent, statistically uniform outputs with no
preferred direction (isotropy), no preferred position (stationarity), and
band-limited spectral content.

A noise function is **NOT**:
- a pseudo-random number generator (no spatial coherence)
- a hash function (no continuity requirement)
- a stored texture (representation ≠ concept)
- an implementation detail (noise is a semantic signal)

---

## 2. Noise Taxonomy

### 2.1 GradientNoise

Maps lattice vertices to pseudo-random unit gradient vectors; interpolated
smoothly between vertices. Spectrum peaks at a single frequency band.

**Contract:**
- `sample(x, y, z, seed) → f ∈ [-1, 1]`
- Continuous and differentiable at all non-lattice points
- Period 256 in each axis (permutation table)

### 2.2 CellularNoise (Voronoi / Worley)

Scatters feature points in space; output is a function of the distances to
the nearest k feature points (F₁, F₂, F₂-F₁).

**Contract:**
- `sample(x, z, seed, mode) → (f1, f2) ∈ [0, ∞)`
- F₁: distance to nearest feature point (smooth regions)
- F₂-F₁: distance between two nearest (crack / cell-boundary patterns)
- Deterministic: feature point positions computed from cell hash

### 2.3 RidgedNoise (Ridged Multifractal)

Signed absolute value inversion of gradient noise: r(x) = 1 - |2·N(x) - 1|.
Applied per octave with spectral weight. Produces sharp ridges.

**Contract:**
- `sample(x, y, z, octaves, lacunarity, gain, seed) → f ∈ [0, 1]`
- Ridges are maxima (not minima); values near 1 are ridge crests

### 2.4 SpectralOctaves (Fractal Brownian Motion)

Sum of N gradient noise samples at geometrically increasing frequencies
(lacunarity) and decreasing amplitudes (gain = persistence).

**Contract:**
- `fbm(x, y, z, octaves, lacunarity, gain, seed) → f ∈ [-1, 1]`
- Each octave i: amplitude = gain^i, frequency = lacunarity^i
- Result normalised by total amplitude

### 2.5 DomainWarp

Recursive displacement of input coordinates by a noise field before sampling.
Produces organic, non-Euclidean distortions. Quilez (2002) technique.

**Contract:**
- `warp(x, z, amplitude, frequency, iterations, seed) → (x', z')`
- Each iteration: p' = p + amplitude · N(p · frequency)
- Deterministic; reversible only when amplitude → 0

### 2.6 CurlNoise2D

Divergence-free 2D vector field derived from the curl of a scalar potential.
∇ × ψ(x,z) = (∂ψ/∂z, -∂ψ/∂x). Used for erosion channels, river paths, lava flows.

**Contract:**
- `curl(x, z, frequency, seed) → (dx, dz)` with ||(dx, dz)|| ≈ 1
- Vector field has zero divergence: ∂dx/∂x + ∂dz/∂z = 0
- Streamlines do not cross or terminate (topology preservation)

---

## 3. Multi-Scale Spectral Synthesis

A **SpectralSynthesizer** combines multiple noise types across frequency bands
with a parameterised blend:

```
h(x,z) = base_fbm(x,z)
        + warp_strength * DomainWarp(x, z)
        + ridge_weight  * RidgedNoise(x, z)  [on high-slope regions]
        + cell_weight   * CellularNoise(x, z) [for rock crack detail]
```

**Invariant:** The synthesizer is a pure function of (x, z, seed, params).
No mutable state. Identical inputs → identical output.

---

## 4. Semantic Invariants

1. All noise functions are **deterministic** given the same seed
2. All noise functions are **band-limited**: spectral energy ≡ 0 above Nyquist frequency for the implementation lattice
3. **Seed independence**: noise functions with different seeds are statistically independent
4. **Scale invariance**: `sample(x·s, z·s) / sample(x, z)` approximates a known power law
5. Noise functions do not carry **units** — they are dimensionless signals; the caller supplies physical interpretation

---

## 5. Provider Contract

An implementation of these functions MUST:
- Accept a `uint32_t seed` and produce identical output for the same seed
- Produce output in the declared range
- Be callable from CPU single-thread, CPU multi-thread, and GPU kernel contexts
- Not allocate heap memory during sample evaluation

---

## 6. Relationships

| Relation | Target | Kind |
|---|---|---|
| depends-on | SCR-LIB-MATH-RANDOM | uses permutation table |
| depends-on | SCR-LIB-MATH-INTERPOLATION | uses smooth-step interpolants |
| consumed-by | SCR-LIB-SPATIAL-VOXEL-SYNTHESIS | terrain height signal |
| consumed-by | SCR-LIB-TOPOLOGY-WFC | entropy seeding |
