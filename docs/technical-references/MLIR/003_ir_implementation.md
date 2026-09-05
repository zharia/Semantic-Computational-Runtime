**General Method: Integrating the SCR Semantic Library with MLIR**

Based on the normative definition in `lib/101_Core/IR/101_definition.md` and established MLIR dialect design patterns, here is a practical, layered method for integrating SCR’s semantic library with MLIR.

### Core Principle (from the definition)

> **IR represents meaning; it does not define meaning.**

The semantic definitions (`101_definition.md` files) remain the sole authority.  
Any MLIR representation is a *computational encoding* of that meaning, never its source.

---

### Recommended Integration Method

#### 1. Keep the Semantic Model Upstream of MLIR

```
Semantic Definition (101_definition.md)
        ↓
Semantic Model (pure SCR concepts)
        ↓
Domain IR (conceptual)
        ↓
MLIR Representation (dialects / existing ops)
        ↓
Analysis / Transformation / Lowering
        ↓
Providers / Runtime / Hardware
```

- Never let MLIR types, ops, or dialects become the definition of a semantic concept.
- The Semantic Hypergraph, Field, Morphology, etc. must remain understandable and usable without any MLIR dependency.

#### 2. Decide Representation Strategy per Domain (Do Not Force One Dialect)

The Core IR definition explicitly states that a domain **must not** be required to have exactly one MLIR dialect. Choose the lightest representation that preserves the required semantics:

| Strategy | When to use | Example |
|----------|-------------|---------|
| **Reuse existing MLIR**General Method: Integrating the SCR Semantic Library with MLIR**

Based on the normative definition in `lib/101_Core/IR/101_definition.md` and established MLIR dialect design patterns, here is a coherent, general method for integrating SCR’s semantic library with MLIR.

### Core Principle (from the definition)

> **IR represents meaning; it does not define meaning.**

The semantic definitions (`101_definition.md` files) remain the sole authority.  
Any MLIR representation is a *computational encoding* of that meaning, never a redefinition of it.

### Recommended Integration Architecture

```
Semantic Domain Definition (101_definition)
        ↓
Semantic Model
        ↓
Domain IR (conceptual)
        ↓
MLIR Realization (one or more of the following)
   ├── SCR-specific dialect(s)
   ├── Existing upstream dialects
   ├── Composition of both
   └── Custom types / interfaces / attributes
        ↓
Analysis / Transformation (via Interfaces + Traits)
        ↓
Progressive Lowering
        ↓
Providers / Runtime / Hardware
```

### Step-by-Step Method

**1. Keep the semantic model upstream and independent**  
Never let MLIR types, ops, or dialects become the source of truth for what a Field, Hyperedge, Morphology, etc. *means*. The Rust (or other) semantic library and the definition documents stay authoritative.

**2. Decide the representation strategy per domain**  
For each semantic domain ask:

- Does this need a dedicated SCR dialect?
- Can it be expressed primarily with existing dialects (`arith`, `scf`, `linalg`, `tensor`, `memref`, `func`, …) plus a thin SCR veneer?
- Is a hybrid the best fit?

The Core IR definition explicitly allows all three options. Prefer the lightest representation that still preserves the required semantic properties.

**3. Introduce SCR dialects only when they add real value**  
Useful criteria for creating a new dialect:

- The domain has distinctive structural or computational patterns that existing dialects cannot express cleanly.
- You need strong, domain-specific verification or canonicalization.
- Higher-level SCR analyses (capability analysis, provider selection, semantic equivalence) benefit from first-class ops/types.

Avoid “one dialect per domain” as a default. Many domains can share a small set of carefully designed SCR dialects plus interfaces.

**4. Map SCR concepts onto MLIR constructs using proven patterns**

| SCR Concept              | Preferred MLIR Mapping                          | Design Pattern Used                  |
|--------------------------|--------------------------------------------------|--------------------------------------|
| Semantic Type            | Dialect Type (`!scr.field`, `!scr.hyperedge`…)  | Custom type + interfaces            |
| Semantic Value           | SSA Value of the corresponding type             | Standard SSA                        |
| Attributes / Metadata    | Dialect Attributes or Properties                | Attribute vs. runtime value distinction |
| Semantic Operation       | Dialect Operation                               | ODS + Traits + Interfaces           |
| Structured computation   | Op with Regions                                 | Payload + Structure pattern         |
| Capabilities             | MLIR Interfaces / Traits                        | Interface-driven generic passes     |
| Invariants / Contracts   | Verifiers + Traits                              | Strong early verification           |
| Graph / Hypergraph structure | Custom types + ops, or existing graph-like dialects | Structural dialect                 |
| Progressive realization  | Conversion / Lowering passes                    | Hourglass + progressive lowering    |

**5. Heavy use of Interfaces (the most important pattern for SCR)**  
Define (or reuse) interfaces that capture SCR capabilities:

- `Dynamical`, `Parallelizable`, `Vectorizable`, `Differentiable`, `Streamable`, `Renderable`, `Composable`, etc.

Generic SCR passes (capability analysis, provider selection, legalization, etc.) should almost always be written against interfaces, not concrete ops. This is the standard MLIR way to keep the system extensible.

**6. Progressive lowering, not big-bang lowering**  
Follow the classic hourglass:

1. High-level SCR / domain IR (close to the semantic model)
2. Mid-level structured dialects (`linalg`, `scf`, `tensor`/`memref`, custom structured SCR dialects)
3. Low-level target dialects (`llvm`, `gpu`, `spirv`, …) or direct provider calls

Only lower when you gain analysis power, optimization opportunity, or the ability to reach a concrete provider.

**7. Verification and Canonicalization as first-class citizens**  
Every SCR op and type should:

- Verify its semantic contracts as early as possible.
- Participate in the global canonicalizer (fold methods + rewrite patterns).

This keeps the IR clean and prevents semantic drift.

**8. Explicit dependency management**  
Declare `dependentDialects` correctly.  
SCR dialects that emit or consume upstream ops must list those dialects.  
Never assume a dialect is loaded.

**9. Separation of concerns in the repository**  
Suggested layout that respects both SCR and MLIR conventions:

```
lib/<Domain>/
├── 101_definition/          ← semantic authority
├── IR/                      ← conceptual domain IR + MLIR mapping notes
│   ├── 101_definition.md
│   └── mlir/                ← actual .td / .cpp for the dialect(s)
├── 301_implementation/      ← runtime / semantic library (Rust, etc.)
└── ...
```

The MLIR artifacts are a *realization* of the Domain IR, not a replacement for it.

### Summary Method (one paragraph)

Treat every SCR semantic domain as defining a **conceptual Domain IR**. Realize that Domain IR in MLIR by the lightest combination of custom SCR dialects, upstream dialects, types, attributes, and (especially) interfaces that still preserves the required semantic properties. Keep the original semantic definitions as the sole authority. Drive all generic analyses and transformations through interfaces. Lower progressively through structured mid-level dialects toward concrete providers. Verify early and canonicalize aggressively. This approach stays faithful both to SCR’s “IR represents meaning; it does not define meaning” rule and to established MLIR dialect design patterns.
