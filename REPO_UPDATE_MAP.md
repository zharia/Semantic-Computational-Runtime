# SCR Repository Update Map — Semantic Algebra Closure

## Purpose

This document maps the proposed closure work onto the existing repository without prematurely overwriting existing documents.

The development agent must inspect the current repository before editing. Existing files may have evolved beyond the assumptions in this package.

## 1. Add the closure programme

Create:

```text
program_increments/v0.0.1/algebra_closure/
```

using the documents in this package as the initial normative/candidate corpus.

Every document must receive the repository's standard version/status metadata where applicable.

## 2. Add a closure specification

Create a canonical normative document under `docs/` using the repository's current numbering convention.

Recommended title:

`SCR Semantic Algebra — Closed Specification`

Do not hard-code a filename number until the agent has inspected the current highest normative document.

The document should consolidate the final accepted definitions after the closure process.

## 3. Add a primitive inventory

Create a normative inventory mapping:

```text
semantic term
definition
Lean symbol
source specification
laws
counterexamples
status
```

## 4. Add a machine-readable closure manifest

Recommended:

```text
program_increments/v0.0.1/algebra_closure/closure_manifest.yaml
```

Each criterion should include:

- id;
- category;
- status;
- canonical definition;
- Lean theorem/property;
- counterexample coverage;
- evidence path;
- source document.

## 5. Add formal module structure

Inspect the current `SCRFormal` project.

Do not create a second Lean project.

Extend the existing canonical formal project.

The agent must reconcile existing STC/SMM definitions rather than creating duplicate ontology modules.

## 6. Add counterexample corpus

Create a dedicated formal counterexample area using the repository's current convention.

Counterexamples must become regression tests.

## 7. Update existing semantic documents

Reconcile, rather than blindly replace:

- Semantic Field specification;
- Semantic Machine Model;
- STC documents;
- semantic kernel contract;
- numeric semantics;
- Golden Path;
- representation boundary documents;
- formal ontology merge documentation.

Where an older document contains an obsolete definition, either:

1. update it to the canonical definition; or
2. explicitly mark it superseded and point to the canonical definition.

No contradictory active definitions may remain.

## 8. Update Golden Path

The Golden Path must be rewritten so that its semantic source is:

```text
Closed Semantic Algebra
    ↓
Formal Semantic Model
    ↓
Reference Semantics
    ↓
Implementation/Representation
```

The Golden Path must not invent semantic concepts.

## 9. Update SMM/STC relationship

The repository must explicitly define the relationship between:

- Semantic Machine Model;
- Semantic Transition Calculus;
- Semantic Field.

The goal is one ontology with different formal/architectural views, not competing semantic authorities.

## 10. Update 005

Milestone 005 should be corrected to reference the closed semantic algebra.

Do not expand 005 indefinitely.

If 005 implementation work is now superseded by algebra closure, document that transition explicitly rather than continuing to add conceptual requirements into 005.

## 11. Update README

The README should state that SCR is currently in a semantic/formal closure phase before broader runtime implementation.

## 12. Do not implement downstream systems

Do not use this package as permission to implement EGS/providers/runtime/distribution.

The output of this phase is the semantic authority from which those systems will later be derived.
