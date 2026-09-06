# lib/

> Directory documentation for the current SCR library tree.

**Path:** `lib/`

**Documentation role:** Repository inventory

## Purpose

Root directory of the SCR semantic library. Contains all computational domain libraries for the Semantic Computational Runtime.

## Current Contents

The directory contains the following top-level domain directories:

- `000_meta` — Repository metadata and control-plane infrastructure
- `101_Core` — Foundational semantic domain
- `201_Data` — Data structures and information
- `202_Math` — Mathematical computation
- `203_Graph` — Graph structures and algorithms
- `301_Field` — Field semantics
- `302_Geometry` — Geometric structures and operations
- `303_Topology` — Topological structures
- `401_Morphology` — Morphological computation
- `501_Physics` — Physical laws and quantities
- `502_Dynamics` — Dynamic systems
- `503_Simulation` — Simulation framework
- `601_Agent` — Agent semantics
- `602_Neural` — Neural computation
- `603_Perception` — Perception
- `604_Control` — Control systems
- `701_Optimization` — Optimization
- `702_Learning` — Machine learning
- `703_Adaptation` — Adaptation
- `704_Evolution` — Evolution
- `705_Ecology` — Ecology
- `801_Spatial` — Spatial structures and indexing
- `802_Stream` — Streaming computation
- `901_Analysis` — Cross-cutting analysis
- `902_Interfaces` — Cross-cutting interfaces
- `903_Lowering` — MLIR lowering infrastructure
- `904_Providers` — Execution providers
- `905_Transforms` — Transformations
- `A01_Render` — Rendering

## Current Role

Root container for the entire SCR semantic library hierarchy. Each child directory represents a computational domain or cross-cutting infrastructure area.

## Scope Boundary

This is the filesystem root of the library. The semantic hierarchy is defined by domain relationships, not by directory nesting.

## Notes

The directory hierarchy is organizational. Semantic relationships between domains are defined in their respective 101_definition.md files, not inferred from filesystem placement.
