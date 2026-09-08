# AGENTS.md — SCR Agent Operating Policy

**Project:** Semantic Computational Runtime (SCR)  
**Version:** 3.0.0  
**Date:** 2026-09-08

---

## SCR Identity

> **MLIR-based Language Runtime for Computational Semantics.**

Heterogeneous computational domains represented through explicit semantic contracts, compiled across heterogeneous execution substrates (CPU, GPU, accelerator, external library, distributed system).

---

## Governing Principle

> **Never allow implementation convenience to silently redefine computational semantics.**

Separate layers — do not collapse:
```
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Not-equals (invariant):
```
Specification ≠ Implementation    Status ≠ Specification
Representation ≠ Concept          Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning        Filesystem ≠ Semantic Architecture
```

---

## The 20 Mandatory Rules

1. Semantics are authoritative.
2. Implementation does not define meaning.
3. Status does not define meaning.
4. The filesystem is not the semantic architecture.
5. Relationships must be explicit.
6. Providers implement contracts; they do not own them.
7. Representations must preserve semantics.
8. Use MLIR rather than unnecessarily duplicating MLIR infrastructure.
9. Do not invent missing foundational semantics.
10. Specify before implementing when semantic behavior is new.
11. Test contracts, not merely implementations.
12. Distinguish semantic, numerical and bitwise equivalence.
13. Validate invariants explicitly.
14. Prefer minimal complete vertical slices.
15. Do not expand task scope without justification.
16. Derived artifacts must remain derived.
17. Optimization follows correctness and measurement.
18. External technologies remain subordinate to SCR contracts.
19. When architecture is genuinely ambiguous, stop and escalate.
20. The code is not the architecture.

---

## The Three Questions

Before changing SCR, answer:

1. **What does this mean?** — The semantic definition.
2. **What currently exists?** — The implementation and status.
3. **How do I prove the change is correct?** — The contract, tests and validation.

If any cannot be answered → investigate before implementing.

---

## Source-of-Truth Hierarchy

Resolve conflicts in order:
```
1. Normative project architecture/specification
2. Parent semantic domain definition
3. Child semantic domain definition
4. Explicit interface/contract specification
5. Specification tests
6. Current implementation
7. Comments
8. Documentation/examples
9. Agent assumptions
```

Control-plane files:
- `101_definition.md` → normative meaning (authoritative)
- `102_status.yaml` → engineering state (descriptive)
- `103_library.graph.json` → derived relationships (not authoritative)

---

## MLIR-First Policy

MLIR is the **sole canonical compiler IR**. SCR does not maintain a parallel IR.

Decision order:
1. Already an MLIR concept? → Use MLIR.
2. Existing MLIR dialect? → Use/compose it.
3. SCR dialect can express? → Create/extend SCR dialect.
4. MLIR interface/trait/attribute? → Use MLIR.
5. MLIR analysis/pass? → Implement as MLIR infrastructure.
6. Genuinely semantic and missing? → Extend SCR MLIR ecosystem.
7. New representation proposed? → **STOP. Get architectural approval.**

Forbid: "SCR IR", "Semantic IR", "Domain IR", "Custom IR"  
Rust/JSON/YAML are not shadow IRs. Use for config, APIs, handles, metadata only.

---

## When to Escalate

Stop and request clarification when:
- Two normative specifications conflict
- Required semantic distinction is undefined
- Implementation requires inventing domain semantics
- Proposed change alters a foundational invariant
- Provider limitation would weaken semantic contract
- Two architectural interpretations are materially incompatible
- Task requires changing source of truth outside assigned scope
- Security/persistence/identity/execution semantics unclear
- Correct behavior cannot be established from authoritative material

**Do not guess foundational architecture.**

---

## Context Optimization

- **Delegate** bulk mechanical work to subagents (`cavecrew-*`, `general`)
- **Inline** only for surgical 1-2 file edits, coordination, architecture reasoning
- **Summarize** subagent output in ≤5 lines in main context
- **Iterative review**: After task completion, up to 20 reviews looking for improvements; stop after 3 consecutive no-change rounds

---

## Full Reference

Detailed subject files in `001_agents/`:

| File | Subject |
|------|---------|
| `01_philosophy.md` | Governing principle, authority model, source-of-truth |
| `02_graph_relationships.md` | Repository graph, relationship vocabulary |
| `03_navigation.md` | Architecture navigation, task scoping, discovery |
| `04_development_lifecycle.md` | Lifecycle, inspection, missing semantics |
| `05_implementation_independence.md` | Technology independence, semantic vs physical |
| `06_mlir_policy.md` | MLIR policy, first-representation, terminology |
| `07_capabilities_operations.md` | Interfaces, operations, determinism, equivalence, invariants |
| `08_testing.md` | Testing philosophy, specification tests |
| `09_providers.md` | Provider requirements |
| `10_domain_concepts.md` | Fields, streams, rendering, simulation, graphs |
| `11_control_plane.md` | Control-plane files, derived artifacts |
| `12_engineering.md` | Dependencies, performance, concurrency, errors, serialization, security |
| `13_development_env.md` | Repository conventions, development environment |
| `14_implementation_principles.md` | Vertical slices, minimal implementation |
| `15_documentation.md` | Documentation policy |
| `16_escalation_completion.md` | Escalation, definition of done, change classification, review |
| `17_agent_behavior.md` | Failure modes, mental model, three questions |
| `18_final_rules.md` | 20 mandatory rules |
| `19_subagent_policy.md` | Subagent delegation, output discipline, context budget |
