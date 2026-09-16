# Implementation Binding (`SCR-APP-BINDING`)

**Path:** `lib/804_Application/ImplementationBinding/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

An **Implementation Binding** explicitly connects a semantic entity, capability, or Operation to an Executable Artifact (e.g. Mojo module, MLIR pass, WASM component, native shared object, or GPU kernel) without embedding technology assumptions into the semantic model.

```text
ImplementationBinding
├── Semantic Target (Operation, Service)
├── Executable Artifact
├── Execution Contract
└── Priority / Selection Rules
```

## 2. Invariants

- **`APP-BND-001` (Binding Explicitness)**: The mapping between semantic operations and executable realization must be explicitly declared.
- **`APP-BND-002` (Language Independence)**: The semantic ontology remains agnostic to whether an implementation is written in Mojo, C++, Rust, or MLIR.
- **`APP-BND-003` (Multi-Implementation)**: A single semantic operation may bind to multiple executable artifacts for different execution substrates.
