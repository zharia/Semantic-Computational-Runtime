# Sprint 02: MaterialX Document & Nodegraph Generation

## 1. Objectives
Synthesize a standards-compliant XML MaterialX (version 1.38/1.39) document containing `open_pbr_surface` / `standard_surface` nodes, nodegraphs, and material outputs for all 96 SCR materials.

## 2. Invariants
- Valid XML syntax with root element `<materialx version="1.38">`.
- Distinct shader nodes and material nodes for each material ID.
- Color4 / Color3 values formatted with space-separated floats.
