# Milestone 005 Specification: MLIR Material & STC Dialect

## 1. Scope & Objective
Define the declarative TableGen MLIR operations and compiler lowerings for material properties and spatial STC cellular transitions.

## 2. Dialect Operations
- `scr.material.lookup`: Resolves compile-time physical or optical constants.
- `scr.material.eval_hookean`: Computes 3D symmetric Cauchy stress tensor from input strain tensor.
- `stc.stencil_load`: Gathers neighborhood state voxels according to stencil pattern (N6, N18, N26).
- `stc.rule_apply`: Evaluates state transition predicate and outputs next-generation material index.

## 3. Lowering Target
- Target dialects: `scf.parallel`, `affine.load`, `memref`, `gpu.launch_kernel`.
