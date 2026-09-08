# 06 — MLIR Policy and MLIR-First Representation

---

## MLIR Policy

SCR is built on MLIR.

Use MLIR's mechanisms wherever they appropriately express the required semantics:

```
Dialect
Operation
Type
Attribute
Region
Block
Interface
Trait
Verification
Rewrite
Canonicalization
Dialect Conversion
Analysis
Transform
Lowering
```

Before creating SCR-specific compiler infrastructure, ask:

```
Can MLIR express this directly?
Can an existing MLIR mechanism express this?
Does SCR require additional semantics?
Would a new abstraction duplicate existing MLIR functionality?
```

Do not build a parallel compiler framework merely because a custom abstraction is convenient.

---

## MLIR-First Representation Policy

SCR is built on MLIR, not beside it. MLIR is the canonical compiler representation substrate.

### Core rules

1. MLIR is the canonical compiler IR. SCR does not maintain a parallel IR.
2. Semantic concepts are represented through MLIR dialects, types, operations, attributes, interfaces, traits, verification, analyses, transformations, and lowering.
3. New abstractions must first be evaluated against MLIR before creating SCR-specific infrastructure.
4. New SCR dialects/interfaces/passes are preferred over new independent representation systems.
5. Rust structures must not become a shadow IR. They are permitted for configuration, APIs, handles, builder state, analysis results, diagnostics, metadata, provider configuration, runtime state, and interoperability.
6. JSON/YAML artifacts (101_definition.md, 102_status.yaml, 103_library.graph.json) must not become a canonical execution IR. They remain control-plane metadata.
7. Agents must stop and request architectural review if a second IR appears necessary.
8. Documentation terminology must never imply a second IR (e.g. "Semantic IR", "Domain IR", "SCR IR").
9. Any proposed deviation from MLIR as the sole representation substrate requires explicit architectural approval.

### Decision procedure for new abstractions

Before creating any SCR-specific infrastructure, ask:

1. Is it already an MLIR concept? → Use MLIR directly.
2. Can it be expressed using an existing MLIR dialect? → Use or compose existing MLIR dialects.
3. Can an SCR dialect express it? → Create/extend an SCR dialect.
4. Can an MLIR interface/trait/attribute express it? → Use MLIR interface/trait/attribute.
5. Can an MLIR analysis/pass/transformation express it? → Implement as MLIR compiler infrastructure.
6. Is the requirement genuinely semantic and missing from MLIR? → Extend SCR's MLIR dialect/interface ecosystem.
7. Is an entirely new representation still being proposed? → Stop. Document why MLIR is insufficient and obtain explicit architectural approval.

### Terminology

Use these terms consistently:

| Term | Meaning |
|------|---------|
| Semantic Model | Conceptual specification of computational meaning |
| Semantic MLIR | MLIR representation of SCR semantics |
| SCR Dialect | MLIR dialect defining SCR/domain semantics |
| SCR Interface | MLIR interface expressing a semantic capability/contract |
| Operation | MLIR operation carrying semantic computation |
| Type | MLIR/SCR semantic type |
| Attribute | MLIR/SCR semantic metadata |
| Analysis | Analysis over MLIR/SCR semantics |
| Transformation | Semantics-preserving or explicitly semantic MLIR transformation |
| Lowering | Progressive transformation toward concrete execution |
| Provider | Concrete implementation of a semantic contract |
| Runtime | Execution orchestration and resource management |
| Representation | Concrete or MLIR representation of semantic information |
| Semantic Graph | Conceptual relationship structure; not a second IR |
| Library Architecture Graph | Control-plane metadata graph; not an execution IR |

Avoid: "SCR IR", "Semantic IR", "Domain IR", "Custom IR", "Intermediate Representation" (when referring to anything other than MLIR itself).
