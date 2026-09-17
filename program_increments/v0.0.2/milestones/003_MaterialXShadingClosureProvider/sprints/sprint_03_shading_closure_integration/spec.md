# Sprint 03: Dynamic Shading Closure Integration

## 1. Objectives
Expose an object-oriented Python provider API (`MaterialXProvider`) that allows the SCR render pipeline and external tools to query shading networks, extract individual material fragments, and export customized subsets.

## 2. Invariants
- Queries for existing material IDs must return valid `<material>` and `<standard_surface>` XML elements.
- Unknown material IDs must raise `KeyError`.
