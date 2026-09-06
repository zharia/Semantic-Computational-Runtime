# Rendering Semantics

## 1. Rendering is observation

Rendering is a transformation from semantic state into a perceptual or display representation. It MUST NOT become the source of semantic truth.

\[
R : \mathcal{S} \rightarrow \mathcal{P}
\]

where `S` is semantic state and `P` is a presentation representation.

## 2. Scene and presentation

A renderer may consume geometry, morphology, lighting, material, camera, temporal and perceptual semantics. It may select meshes, textures, buffers, shaders or other representations.

## 3. Incremental rendering

Only semantically changed regions SHOULD be recomputed where the representation permits. Dirty state is an optimisation unless explicitly exposed as semantic state.

## 4. Multiple renderers

Different renderers MAY target raster, vector, terminal, WebGPU, WebGL, offline images, scientific visualisation or other output domains while consuming the same semantic model.

## 5. Determinism

Where rendering is declared reproducible, camera, sampling, ordering, numerical precision and provider behaviour must be controlled sufficiently to satisfy the visual contract.
