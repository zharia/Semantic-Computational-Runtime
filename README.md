# Semantic Computational Runtime


<div align="center">

![Byte Money](./assets/public/images/BM-logos-20.svg)<br />[Primary Site](https://bytemoney.co.za)

![Mojo Lang](./assets/public/images/Mojo-Logo.jpg)<br />[Mojo Lang](https://medium.com/@furcifer/mojo-e1-background-and-history-mojo-programming-language-aca2b59eb719)

</div>

<br />

<div align="center">

![Mojo](https://img.shields.io/badge/Mojo-1.0.0-FF6B1B?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSIyIj48cGF0aCBkPSJNNCAyMEwyMCA0IiBzdHJva2Utd2lkdGg9IjMiLz48cGF0aCBkPSJNNCAyMEwxMiAyMEwyMCA0IiBmaWxsPSIjRkY2QjFCIi8+PC9zdmc+&labelColor=1a1a2e)
![Lean 4](https://img.shields.io/badge/Lean_4-4.34-0065FF?style=for-the-badge&logo=lean&logoColor=white&labelColor=1a1a2e)
![MLIR](https://img.shields.io/badge/MLIR-LLVM_22-33CC99?style=for-the-badge&logo=llvm&logoColor=white&labelColor=1a1a2e)
![License](https://img.shields.io/badge/License-Apache_2.0-blue?style=for-the-badge&labelColor=1a1a2e)

**Semantic Computational Runtime**

*Engineer outward from the Semantic Field.*

</div>

---

## What is SCR?

The Semantic Computational Runtime (SCR) is a computational architecture where **semantic structure is primary and physical execution is its manifestation**.

SCR models computation as the **transformation of semantic structure within a Semantic Field** — not as instruction sequences on passive memory.

A computational Semantic Field induces an implementation-independent **Semantic Machine**. The Semantic Machine defines the semantic state, context, transformations, constraints, outcomes, and equivalence relations that determine what computation means.

Physical implementations are realizations of that abstract machine. The **Reference Executor** is a canonical executable witness; **EGS** is the operational execution environment; **providers** realize semantic capabilities; **MLIR** represents and lowers computation; and **Mojo** implements semantic contracts.

**Meaning precedes representation. Representation precedes physical realization.**

```text
Semantic Field
      ↓
Semantic Machine Model
      ↓
Semantic Transition Calculus
      ↓
Executable Semantic Hypergraph
      ↓
Reference Executor / Conforming Implementations
      ↓
EGS
      ↓
Capability Resolution
      ↓
Providers
      ↓
Physical Manifestation
```

### Abstract Machine Boundary

SCR defines an implementation-independent abstract machine boundary, but it is not reducible to a conventional virtual machine architecture. JVM, CLR, ECMAScript, and RISC-V provide useful precedents for separating machine semantics from implementation; SCR generalizes the principle to semantic hypergraphs and Semantic Fields.

---

## Current Status

**Milestone 005 COMPLETE** — Representation Preservation and Executable Equivalence

| Component | Status |
|-----------|--------|
| Lean Formal Model | ✅ 12 theorems, BUILD PASS |
| Mojo Semantic Kernel | ✅ 47 tests PASS |
| Reference Executor | ✅ 35 tests PASS |
| Semantic Equivalence | ✅ 15 tests PASS |
| Multi-Entity Support | ✅ 14 tests PASS |
| MLIR Representation | ✅ Verified, lowered, executed |
| Differential Execution | ✅ MLIR ≡ Mojo ≡ Reference Executor |

```bash
# Lean
lake build SCRFormal              # BUILD PASS (8882 jobs)

# Mojo (82 tests total)
uv run mojo run -I src tests/     # ALL PASS

# MLIR → Execution
bash test_differential.sh         # 2/2 PASS
```

---

## Technology Stack

| Layer | Technology | Role |
|-------|-----------|------|
| **Formal Verification** | Lean 4 | Semantic theorems, invariant proofs |
| **Implementation** | Mojo 1.0 | Semantic kernel, runtime |
| **Reference** | Mojo 1.0 | Semantic oracle (ground truth) |
| **Representation** | MLIR (LLVM 22) | Canonical computational representation |
| **Lowering** | mlir-opt, llc, gcc | MLIR → executable code |
| **Testing** | Mojo TestSuite | 82 tests + 2 differential execution |

---

## Quick Start

```bash
# Clone
git clone https://github.com/zharia/Semantic-Computational-Runtime.git
cd Semantic-Computational-Runtime

# Lean build
lake build SCRFormal

# Mojo tests
cd runtime/Reference_Executor/v0.0.1-0A-Reference_Executor_Mojo
uv run mojo run -I src tests/test_reference_executor.mojo

# MLIR differential execution
bash program_increments/v0.0.1/milestones/001_semantic-kernel/test_differential.sh
```

---

## Repository Structure

```text
SCR/
├── formal/SCR/           # Lean formal model (Basic.lean, Canonical.lean)
├── lib/scr_kernel/       # Mojo semantic kernel
│   ├── entity.mojo       # Entity
│   ├── entity_definition.mojo
│   ├── entity_instance.mojo
│   ├── field.mojo        # SemanticField
│   ├── transformation.mojo
│   ├── constraint.mojo
│   ├── context.mojo
│   ├── observation.mojo
│   └── tests/            # 47 kernel tests
├── runtime/Reference_Executor/
│   ├── src/scr_reference/  # Reference Executor
│   └── tests/              # 35 RE + equivalence tests
├── seed/                 # Foundational semantic knowledge
├── docs/                 # System specifications
└── program_increments/v0.0.1/
    ├── 104_golden-path.md
    ├── 105_gp_implementation_contract.md
    ├── 106_semantic_kernel_contract.md
    ├── milestones/       # Development milestones
    └── reports/          # Verification reports (003-005)
```

---

## Core Concepts

### Semantic Field

$$
\mathcal{F} = (E, R, T, C, S, K, M)
$$

* **E** — entities
* **R** — relationships
* **T** — transformations
* **C** — context
* **S** — state
* **K** — constraints
* **M** — manifestation / physical realization

> **M** is a realization dimension. It must not be interpreted as the source of semantic meaning.

### Semantic Machine

A computational Semantic Field induces an implementation-independent Semantic Machine: the semantic state, context, transformations, constraints, outcomes, and equivalence relations that determine what computation means. Physical implementations are realizations of that abstract machine.

### Semantic Primacy

> **Meaning precedes representation.**

The semantic contract defines what a computation means.
MLIR, LLVM, and machine code are representations of that meaning — not the meaning itself.

### Representation Independence

```
Semantic State
      ↓
Physical Manifestation
      ↓
memref / tensor / SSA / storage / ...
```

The same semantic state can be represented by different physical mechanisms without changing meaning.

---

## Verification Matrix

| Property | Lean | Mojo | RE | MLIR | Lowered | Differential |
|----------|------|------|----|------|---------|--------------|
| Identity | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Entity Definition | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Entity Instance | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Value | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| State | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Transformation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Constraint | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Constraint Failure | - | ✅ | ✅ | ✅ | ✅ | ✅ |
| SemanticTime | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Context | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Observation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Multiple Entities | - | ✅ | ✅ | ✅ | ✅ | ✅ |
| Relationship | - | ✅ | ✅ | ✅ | ✅ | ✅ |
| Provenance | - | - | - | ✅ | ✅ | ✅ |
| Determinism | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## The Canonical Witness

The repository contains a verified end-to-end semantic compilation artifact:

```text
CounterDefinition
    ↓
Counter c1 (value=5)
Counter c2 (value=10)
    ↓
Relationship: c1 --LINKS--> c2
    ↓
Transform c1: +3 → c1=8
Transform c2: -2 → c2=8
    ↓
Constraint: value ≥ 0
    ↓
Observe: c1=8, c2=8
    ↓
Lean Verification (12 theorems)
    ↓
Mojo Implementation (47 tests)
    ↓
Reference Executor (35 tests)
    ↓
Semantic Equivalence (15 tests)
    ↓
Canonical MLIR (verified)
    ↓
MLIR Lowering → LLVM → Native Code
    ↓
Execution → c1=8, c2=8
    ↓
Differential Verification: PASS
```

---

## Engineering Principles

### Semantic Field Primacy

> **All higher-level structures MUST be derived from the Semantic Field.**

### No Custom Dialect

Standard MLIR dialects (arith, memref, scf, func) plus unregistered attributes for metadata. No custom `scr.*` operations.

### Reference Executor is Oracle

If MLIR execution disagrees with the Reference Executor:
1. Determine which implementation is incorrect
2. Use semantic specification as authority
3. Correct the incorrect implementation
4. Add regression test

### Abstract Machine Boundary

> Semantic Machine semantics MUST remain independent of physical realization.

### Realization Transparency

> Replacing a physical provider with another provider satisfying the same semantic capability MUST NOT require modification of the semantic computation.

### Conformance by Observation

> Implementations are judged by semantic observation and equivalence, not by implementation structure.

### No Infrastructure-Derived Ontology

> Runtime components MUST NOT become semantic primitives merely because implementations contain components with corresponding names.

### Falsification Before Expansion

> A new semantic primitive requires a demonstrated semantic counterexample showing that the existing semantic vocabulary and transition calculus cannot express the required behaviour.

---

## Documentation

| Document | Purpose |
|----------|---------|
| `104_golden-path.md` | Vertical slice specification |
| `105_gp_implementation_contract.md` | Implementation constraints |
| `106_semantic_kernel_contract.md` | Semantic kernel contract |
| `AGENTS.md` | Agent operating policy |
| `reports/005/` | Milestone 005 verification |

---

## What SCR Is Not

SCR is not fundamentally:
* an object-oriented runtime
* a conventional virtual machine
* a graph database
* a message broker
* a programming language

SCR may contain or use all of these. None of them defines SCR.

> SCR does define an abstract machine semantics, but that abstract machine is not itself a conventional VM implementation.

---

## License

Apache License 2.0

---

<div align="center">

**Engineer outward from the Semantic Field.**

</div>
