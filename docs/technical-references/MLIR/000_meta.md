**MLIR and the Semantic Computational Runtime (SCR)**

### What is MLIR?

**MLIR** (Multi-Level Intermediate Representation) is a modern compiler infrastructure that lives inside the LLVM project. It was originally developed to address the challenges of compiling complex, heterogeneous workloads (especially machine learning) and has since become a general-purpose foundation for building domain-specific compilers.

Key characteristics:

- **Multi-level by design** — Code can exist at many different levels of abstraction inside the same IR.
- **Dialects** — Developers define custom “dialects” that introduce new operations, types, and attributes tailored to a particular domain.
- **Progressive lowering** — High-level, domain-friendly representations are gradually transformed into lower-level forms (often ending at LLVM IR) through a series of well-defined steps.
- **Shared infrastructure** — Verification, rewriting, analysis, transformation passes, and testing tools work uniformly across all dialects.
- **Heterogeneous targets** — Particularly strong at targeting CPUs, GPUs, accelerators, and other specialized hardware without forcing everything into a single low-level IR too early.

MLIR is not a programming language that end-users write. It is a toolkit for building compilers and intermediate representations.

### How MLIR relates to SCR

SCR is explicitly an **MLIR-based** system:

> “The Semantic Computational Runtime (SCR) is an open, MLIR-based computational environment…”  
> “SCR is built **on top of MLIR, not beside it**.”

**MLIR is a hard dependency of the SCR system** as currently designed. It provides the compiler infrastructure that allows semantic programs to be analyzed, transformed, lowered, and executed across different providers and hardware targets.

The intended architecture is:

```
Application
    ↓
Semantic Library / Semantic Model     ← SCR’s primary contribution
    ↓
Domain / Semantic IR
    ↓
MLIR (dialects, analysis, transformation, lowering)
    ↓
Providers / Adapters
    ↓
SCR Runtime
    ↓
Execution substrates (CPU, GPU, accelerators, external libraries…)
```

### Critical design rule

Although the overall SCR *system* depends on MLIR, the pure semantic model is deliberately kept independent of it:

> The semantic model is **upstream of MLIR**.  
> Core semantic domains (including the Semantic Hypergraph) **must not depend on MLIR internally**.

MLIR is treated as a powerful *representation and compilation substrate* that operates *on* the semantic model. It is not allowed to become the definition of the semantics themselves.

This separation is foundational to SCR’s claim that applications can express computational *meaning* independently of any particular implementation technology, library, or hardware target. The compiler and runtime (powered by MLIR) then determine how that meaning is realized.

**In short**

- MLIR is a hard dependency of the SCR compilation and runtime system.
- The semantic definitions themselves are intentionally written so they remain independent of MLIR.
- SCR supplies the meaning; MLIR supplies the machinery to represent, optimize, and execute that meaning.
