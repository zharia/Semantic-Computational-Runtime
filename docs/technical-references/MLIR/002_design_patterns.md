**MLIR Dialect Design Patterns**

MLIR dialects are the primary extension mechanism in the framework. A dialect is a namespace that groups related operations, types, attributes, and interfaces. Good dialect design is widely regarded as more art than pure science, but several recurring patterns and principles have emerged from upstream MLIR and large production systems.

### 1. Core Categories of Dialects

Experienced designers commonly classify dialects into a few useful buckets:

| Category              | Purpose                                      | Examples                          | Design Emphasis                     |
|-----------------------|----------------------------------------------|-----------------------------------|-------------------------------------|
| **Edge / Import**     | Faithful modeling of an external representation | LLVM, SPIR-V, TensorFlow Graph   | 1:1 mapping, easy round-tripping   |
| **Computation**       | Pure computational operations                | `arith`, `math`, `complex`       | Side-effect free where possible, foldable |
| **Structural / Control** | Control flow, regions, scoping            | `scf`, `cf`, `func`              | Clear region/block structure       |
| **Abstraction / Mid-level** | Domain-oriented structured computation  | `linalg`, `tosa`, `vector`       | Preserve high-level structure for optimization |
| **Target / Backend**  | Hardware- or ABI-specific                    | `gpu`, `nvvm`, `rocdl`, `spirv`  | Lowering target, often with attributes for hardware details |
| **Paradigm**          | Cross-cutting programming model              | `async`, `omp`, `acc`            | Interfaces + traits for generic transforms |

A single compilation pipeline often mixes several of these.

### 2. Key Design Principles

**Preserve high-level information as long as possible**  
Lower only when you gain something (better analysis, better codegen, or necessity). Premature lowering destroys optimization opportunities.

**Prefer structured over unstructured**  
Ops with explicit regions, iterators, or payload (e.g. `linalg.generic`) are easier to analyze and transform than opaque “call-like” ops.

**Separate structure from computation**  
Keep control-flow / region structure in one set of dialects and pure computation in another. This enables generic passes (inlining, CSE, etc.) to work across domains.

**Use Interfaces and Traits aggressively**  
- Traits capture simple properties (`Pure`, `Commutative`, `SameOperandsAndResultType`, …).  
- Interfaces capture richer behavior (`SideEffectInterfaces`, `MemoryEffectOpInterface`, `InferTypeOpInterface`, `DestinationStyleOpInterface`, etc.).  

Generic passes should almost always be written against interfaces, not concrete ops.

**Make verification strong and early**  
Every op should verify its invariants. Bad IR should be rejected as close to the source as possible.

**Canonicalization is a first-class citizen**  
Every dialect should define fold methods and/or rewrite patterns so that the global canonicalizer can clean the IR.

**Dependent dialects must be declared**  
If your dialect creates ops or uses types from another dialect, list it in `dependentDialects`. This ensures correct loading order.

### 3. Common Structural Patterns

**Hourglass shape**  
High-level domain dialect(s) → a small set of mid-level structured dialects → low-level target dialects.  
Classic example: high-level ML ops → `linalg` / `tensor` / `memref` → `vector` / `gpu` / `llvm`.

**Payload + Structure**  
Ops that carry a region of “payload” computation plus metadata about iteration space, indexing maps, etc. (`linalg.generic`, `scf.forall`, many OpenMP/ACC constructs).

**Type system extension**  
Define dialect-specific types when the builtin types (`tensor`, `memref`, `vector`, integers, floats) are insufficient. Keep the type hierarchy shallow and use interfaces for genericity.

**Attribute-driven behavior**  
Prefer attributes for configuration that does not change the core semantics of an op (e.g., fast-math flags, memory access kinds, pipeline stages).

**One-to-one vs. intentional deviation**  
When modeling an existing IR (SPIR-V, LLVM, …), stay close to the original for serialization fidelity, but deviate when MLIR mechanisms (regions, attributes, interfaces) give a clearer or more optimizable representation.

### 4. Practical Implementation Patterns

- Define the dialect itself in one `.td` file; put ops, types, and attributes in separate files for clean layering.
- Use ODS (Operation Definition Specification) + TableGen almost exclusively for new dialects.
- Prefer `kEmitAccessorPrefix_Prefixed` for generated getters/setters.
- Provide both a custom assembly format (readable) and rely on the generic form as a fallback.
- Register canonicalization patterns both per-op and (when useful) at the dialect level.
- Implement `materializeConstant` if the dialect has constant-like ops.
- Use declarative rewrite rules (DRR) for simple pattern-based lowerings and canonicalizations; fall back to C++ `RewritePattern`s for complex logic.

### 5. Relevance to Semantic Computational Runtime (SCR)

SCR’s architecture maps naturally onto these patterns:

- The **Semantic Model** (Hypergraph, Fields, Morphology, etc.) sits *above* MLIR and should remain independent of any particular dialect.
- When SCR needs an MLIR representation, the natural approach is:
  1. One or more **high-level semantic dialects** that stay close to the SCR semantic contracts (nodes, hyperedges, regions, operations, deltas, capabilities…).
  2. Progressive lowering into existing mid-level dialects (`linalg`, `scf`, `arith`, `tensor`/`memref`, etc.) or custom structured dialects.
  3. Final lowering to target dialects (`llvm`, `gpu`, etc.) or external providers.

Design advice specific to SCR:

- Resist the urge to put the entire semantic hypergraph model into a single giant dialect.
- Prefer a small set of focused dialects plus heavy use of interfaces so that generic SCR passes (capability analysis, provider selection, etc.) can operate without knowing every concrete op.
- Keep the pure semantic definitions (the `101_definition` documents) as the source of truth; the MLIR dialects are a *representation*, not the definition of meaning.

### Summary of Best Practice

Good MLIR dialect design optimizes for:

1. Clarity of the represented abstraction  
2. Ability to write powerful, generic transformations  
3. Clean progressive lowering  
4. Strong verification  
5. Composability with the rest of the ecosystem  

The most successful dialects are those that make the *next* transformation or lowering step obvious and safe, while preserving the information that higher-level analyses need.
