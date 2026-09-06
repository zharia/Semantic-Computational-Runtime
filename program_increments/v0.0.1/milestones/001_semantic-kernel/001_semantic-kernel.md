# SCR Development Instruction — Semantic Kernel Phase

You are working on the Semantic Computational Runtime (SCR) repository:

`https://github.com/zharia/Semantic-Computational-Runtime`

## Objective

Implement the next architectural phase of SCR defined by:

* `program_increments/v0.0.1/104_golden-path.md`
* `program_increments/v0.0.1/105_gp_implementation_contract.md`
* `program_increments/v0.0.1/106_semantic_kernel_contract.md`

The objective is to establish the **formal semantic kernel** as the verified foundation for the SCR Golden Path.

Do not jump directly into building a custom MLIR dialect, runtime architecture, or large Mojo abstraction layer.

The correct development direction is:

```text
Existing Semantic Specifications
        ↓
106 Semantic Kernel Contract
        ↓
Lean Formalisation
        ↓
Lean Verification
        ↓
Mojo Semantic Kernel
        ↓
Reference Executor
        ↓
Semantic Equivalence
        ↓
MLIR Representation
        ↓
Lowering / Provider / Runtime
```

This phase ends before unnecessary downstream architecture is invented.

---

# 1. First: inspect the repository

Before modifying code, inspect the current repository thoroughly.

In particular inspect:

```text
seed/
docs/
lib/
runtime/
program_increments/v0.0.1/
```

Identify:

* existing semantic definitions;
* existing Lean definitions;
* existing Lean proofs;
* existing SCRFormal modules;
* existing Mojo implementation;
* existing reference executor;
* existing tests;
* existing numeric semantics;
* existing identity/state/value/entity definitions;
* existing semantic field definitions;
* existing MLIR work;
* existing documentation that may already define kernel concepts.

Do not assume that the descriptions above are the current repository state.

The repository is authoritative for determining what already exists.

---

# 2. Reconcile before implementing

Read:

```text
104_golden-path.md
105_gp_implementation_contract.md
106_semantic_kernel_contract.md
```

and compare them against the existing semantic specifications.

Determine:

1. which existing documents are authoritative for each kernel concept;
2. whether the concepts in `106` already exist elsewhere;
3. whether terminology conflicts exist;
4. whether duplicate semantic definitions exist;
5. whether existing Lean definitions already cover part of the kernel;
6. whether existing implementation concepts incorrectly precede semantic definitions;
7. whether any current implementation contradicts the new contract.

Do not create duplicate definitions simply because `106` names a concept.

If an existing authoritative definition already exists, reuse or reconcile it.

If there is a contradiction, document it and determine which specification is authoritative.

Do not silently resolve semantic contradictions in favour of existing code.

---

# 3. Produce a semantic reconciliation report

Before substantial implementation work, produce a concise report at an appropriate location in the repository, or as the development result if repository conventions do not provide a suitable location.

The report must contain a matrix similar to:

| Kernel Concept | Existing Definition | Authoritative Source | Lean Exists | Mojo Exists | Tests Exist | Action |
| -------------- | ------------------- | -------------------- | ----------- | ----------- | ----------- | ------ |
| Entity         |                     |                      |             |             |             |        |
| Identity       |                     |                      |             |             |             |        |
| Value          |                     |                      |             |             |             |        |
| Relationship   |                     |                      |             |             |             |        |
| State          |                     |                      |             |             |             |        |
| Transformation |                     |                      |             |             |             |        |
| Constraint     |                     |                      |             |             |             |        |
| Context        |                     |                      |             |             |             |        |
| Time           |                     |                      |             |             |             |        |
| Observation    |                     |                      |             |             |             |        |

Do not fill this matrix with assumptions.

Use the actual repository contents.

---

# 4. Establish the Lean semantic kernel

After reconciliation, implement or complete the minimum Lean semantic kernel required by `106`.

The kernel should cover, at minimum:

```text
Entity
Identity
Value
Relationship
State
Transformation
Constraint
Context
Time
Observation
```

The exact Lean structures should be derived from the existing semantic specifications.

Do not invent an unrelated type system merely because it is convenient.

The Lean layer is a **formal semantic model**, not a second runtime.

Avoid encoding:

* Mojo implementation details;
* memory layouts;
* MLIR syntax;
* LLVM details;
* CPU architecture;
* renderer state;
* provider-specific mechanisms;

unless an existing semantic specification explicitly requires them.

---

# 5. Establish the initial formal properties

Formalise the smallest useful set of kernel properties.

At minimum investigate:

```text
identity preservation
state validity
constraint preservation
transformation validity
observation non-interference
temporal consistency
determinism where specified
```

Do not manufacture theorem statements merely to make the implementation appear formally verified.

Each theorem should correspond to an actual semantic claim.

Where a property cannot yet be formally established because the semantic specification is incomplete, record that fact instead of weakening the theorem.

---

# 6. Verify with Lean

The repository currently has an established Lean build.

Run the appropriate project checks.

At minimum establish that:

```text
lake build SCRFormal
```

continues to succeed after the changes.

More importantly, ensure that the new semantic kernel definitions and proofs are actually imported and checked by the build.

Do not consider source files containing theorem declarations to be evidence of verification unless Lean actually checks them.

Record the verification result.

---

# 7. Do NOT create a custom MLIR dialect

This instruction is explicit.

Do not recreate the deleted:

```text
105_gp_dialect_example.md
```

architecture in code.

Do not introduce operations such as:

```text
scr.create_particle
scr.create_state
scr.step
scr.get_time
scr.get_particles
```

unless a later implementation investigation demonstrates an actual semantic necessity.

Do not create a C++/TableGen SCR dialect merely because SCR has semantic concepts that could be given MLIR names.

`105_gp_implementation_contract.md` explicitly requires custom MLIR constructs to be justified by demonstrated representation pressure.

That decision belongs later.

---

# 8. Do NOT prematurely build the Mojo kernel

Mojo is the primary preferred implementation language, but implementation should follow semantic reconciliation and formalisation.

Do not create a large Mojo semantic object hierarchy before determining what the authoritative semantic model actually requires.

Once the Lean kernel is coherent, inspect the existing Mojo implementation and determine what can directly implement the verified semantic contracts.

Prefer the smallest executable manifestation.

Do not duplicate the semantic model unnecessarily in Mojo.

---

# 9. Preserve semantic/representation separation

Pay particular attention to:

```text
semantic identity
semantic value
semantic state
semantic relationship
semantic transformation
```

versus:

```text
memory address
pointer
array index
allocation
machine type
buffer
runtime object
MLIR value
LLVM value
```

The latter are representations or manifestations.

Do not allow physical implementation choices to silently become semantic definitions.

---

# 10. Preserve numeric semantics

Read and respect the existing numeric semantics specification.

Do not define kernel semantics directly in terms of:

```text
f32
f64
i32
i64
```

unless those types are explicitly required as representations by a higher-level semantic contract.

Numeric semantics must remain conceptually:

```text
semantic numeric quantity
        ↓
numeric contract
        ↓
representation
```

not:

```text
machine type
        ↓
semantic meaning
```

If existing code violates this principle, identify it in the reconciliation report rather than silently changing semantics.

---

# 11. Preserve explicit temporal semantics

Time must remain semantic where temporal behaviour is defined.

Keep distinct:

```text
semantic time
wall-clock time
frame time
processing time
scheduling time
latency
```

Do not introduce implementation-specific time semantics merely to make a test pass.

If a requirement such as:

```text
dt > 0
```

is needed, trace it to the authoritative semantic specification before enforcing it at the implementation level.

---

# 12. Observation must remain non-authoritative

Ensure that observation is downstream from semantic state.

The architecture must remain:

```text
Semantic State
      ↓
Observation
      ↓
Manifestation
```

not:

```text
Semantic State
      ↓
Renderer / Runtime State
      ↓
authoritative state
```

Observation must not mutate authoritative semantic state unless explicitly required by the semantic contract.

---

# 13. Testing

Add or update tests corresponding to the actual kernel claims.

At minimum establish tests for:

* identity;
* entity construction/validity;
* value semantics;
* state;
* transformations;
* constraints;
* temporal state;
* observation;
* relevant invariants.

Tests should verify semantic behaviour rather than implementation layout.

Do not write tests whose primary purpose is to confirm a particular internal data structure unless that representation itself is normative.

---

# 14. Reference Executor

Inspect the existing Reference Executor.

If it already provides the required semantic behaviour, reuse it.

If it does not yet exist or is incomplete, do not build a large executor.

Define the smallest reference execution capability needed for the canonical Golden Path workload.

The Reference Executor is a semantic oracle.

Its purpose is clarity and semantic fidelity, not performance.

---

# 15. Canonical witness

Use the existing Golden Path particle workload only as a witness computation:

```text
Particle
├── identity
├── position
└── velocity
```

with:

```text
SimulationState
├── simulation_time
└── particles
```

and:

```text
position' = position + velocity × dt
```

represented conceptually as:

```text
advance(state, dt) → state'
```

Do not interpret this workload as the definition of SCR.

Do not build a physics engine.

Do not introduce unnecessary simulation abstractions.

The purpose is simply to demonstrate the semantic kernel.

---

# 16. Stop conditions

Stop and report rather than guessing if any of the following occur:

* existing specifications contradict `106`;
* the authoritative definition of a kernel concept cannot be determined;
* existing Lean architecture conflicts materially with the new contract;
* implementing a requirement appears to require inventing new semantics;
* an MLIR custom dialect appears necessary but the semantic reason is unclear;
* a Mojo abstraction would duplicate an existing authoritative semantic model;
* a theorem cannot be stated without inventing assumptions;
* repository architecture differs materially from the expected structure.

Do not paper over architectural uncertainty with implementation.

---

# 17. Required final state for this phase

The phase should result in:

```text
Authoritative semantic definitions identified
        ↓
Semantic Kernel reconciled
        ↓
Lean kernel implemented
        ↓
Kernel properties formalised
        ↓
Lean verification succeeds
        ↓
Existing implementation assessed
        ↓
Tests updated
```

A Mojo implementation may begin if the above is sufficiently established, but it must remain small and contract-driven.

MLIR, lowering, providers, and runtime integration are downstream work.

---

# 18. Required report back

When complete, report:

### A. Repository findings

What already existed.

### B. Semantic reconciliation

Which definitions were reused, changed, or identified as conflicting.

### C. Lean changes

Files changed and semantic concepts formalised.

### D. Verification

Exact verification/build commands used and whether they succeeded.

### E. Tests

Tests added/changed and results.

### F. Mojo status

What existing Mojo implementation already provides and what remains.

### G. Reference Executor status

What exists and what remains.

### H. MLIR status

Explicitly state whether any custom MLIR constructs were introduced.

The expected answer at this stage is preferably:

> No custom SCR MLIR dialect was introduced.

### I. Architectural issues

List anything discovered that requires a specification decision rather than an implementation decision.

### J. Next recommended step

Based on actual repository state, identify the smallest next implementation step.

---

# Governing rule

Throughout this task, apply the following rule:

> **Do not implement what has not been semantically defined. Do not formalise what has not been reconciled. Do not represent what does not need representation. Do not optimise what has not yet been proven correct.**

The objective is not to produce the most code.

The objective is to establish the first **verified semantic foundation** from which the rest of SCR can be derived.

The architectural direction is:

```text
Semantic Field
      ↓
Semantic Kernel
      ↓
Formal Verification
      ↓
Executable Implementation
      ↓
Reference Equivalence
      ↓
Representation
      ↓
Physical Execution
```

Engineer outward from the Semantic Field.
