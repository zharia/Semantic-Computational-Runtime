---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-MORPHOLOGY-PROCEDURAL
title: Morphology Procedural
name: Morphology Procedural

version: 0.2.0
status: operational

created: 2026-09-05
updated: 2026-10-03

parent: SCR-LIB-MORPHOLOGY
authority: SCR
domain: semantic-library
---

# SCR Morphology: Procedural

## Summary

Grammar-based, fractally recursive, and parametric procedural generation of structures: a procedural morphology is a finite generative grammar — alphabet of parameterised modules, axiom, context-free parametric production rules — whose bounded, deterministic derivations describe form as a compact generative description.

## Purpose

Define the normative semantics of procedural morphology — what a morphological grammar is and what its derivations mean — so that every provider expanding a grammar conforms to one morphological contract, independent of expansion algorithm, provider, or rendering.

## Scope

In scope: grammar alphabet (modules with parameters), axiom, parametric production rules, derivation-step semantics, iteration depth, termination bounds, determinism, tropism as a parametric term, and conformance to the parent Morphology invariants. Out of scope: growth over developmental time (`SCR-LIB-MORPHOLOGY-GROWTH` — time advancement belongs to the consuming domain), trait-to-form mapping (`SCR-LIB-EVOLUTION-PHENOTYPE`), ecological membership, field, and stage policy (`SCR-LIB-ECOLOGY-FLORA`), representation/provider/rendering concerns (MORPHOLOGY independence invariants), and any graph-rewriting contract beyond these grammar semantics.

## Core Concepts

1. **Alphabet** (§1.1) — the finite declared set of parameterised modules from which every derivation is built.
2. **Axiom** (§1.2) — the declared initial sentential form of a grammar.
3. **Production rules** (§1.3) — context-free parametric replacements applied simultaneously to every module.
4. **Derivation step and iteration depth** (§1.4) — one simultaneous replacement; depth is the declared number of steps from the axiom.
5. **Termination bounds** (§1.5) — a declared finite depth bound; every declared derivation terminates.
6. **Determinism** (§1.6) — same grammar, same axiom, same depth ⇒ identical derivation, on any provider.
7. **Tropism** (§1.7) — a directional response expressed as a declared parametric term of the grammar.
8. **Relation to branching, growth, and compact description** (§1.8) — grammar semantics sit between parent §18 Branching, §25 Growth, and §17 Repetition without redefining them.

---

## 1. Semantic Definition

**Procedural** is a first-class subdomain of SCR Morphology (`SCR-LIB-MORPHOLOGY`). It defines procedural morphology: form described by a generative grammar rather than by explicit enumeration of its instances.

Morphology defines the structural organisation and form of entities independently of transient rendering engines, physical memory formats, or vendor graphics APIs. The grammar model specified here is the parametric, context-free class of Lindenmayer-style (L-system) morphological grammars, stated in SCR semantic terms.

This document addresses `SCR-LIB-MORPHOLOGY` §70 Open Semantic Questions **11 (Procedural morphology)** and **12 (Morphological grammars)**. The parent definition remains unedited and authoritative over everything it already defines — notably §18 Branching (one structure divides into multiple related structures), §25 Growth ("rule-based growth" listed among the modes of growth), and §17 Repetition (line 577: repeated structure MAY be represented as a compact generative description rather than explicitly materialised instances).

### 1.1 Alphabet — Modules with Parameters

- The **alphabet** of a grammar is a finite, declared set of **modules** (symbols). A derivation produces only modules from the declared alphabet; the alphabet is closed.
- Each module has a fixed name and an ordered, typed parameter list. Parameters are the only carriers of magnitude in a derivation; a module occurrence is fully identified by its name plus its parameter values.
- Parameters used for conformance carry exact declared numeric types (integer or rational) where their values participate in equivalence claims; any floating-point interpretation belongs to representation, not to grammar meaning (`MORPHOLOGY-INV-016`).

### 1.2 Axiom

- The **axiom** is the declared initial sentential form: a finite string of alphabet modules carrying concrete parameter values.
- The axiom is part of the grammar. No provider supplies an ad hoc initial form.

### 1.3 Parametric Production Rules (Context-Free)

- A **production rule** maps a predecessor module to a successor: a finite string of alphabet modules whose parameter expressions are functions of the predecessor's parameters and of declared constants.
- Rules are **context-free**: the predecessor is a single module, and no neighbouring modules condition applicability. Any context-sensitive extension is a semantic revision of this definition, not a provider choice.
- Every module name MUST have a declared rule, or be declared stationary (rewritten to itself).
- Where predicate-guarded alternatives are declared for one module, rule selection MUST be deterministic under a precedence declared in the grammar — never provider discretion.
- The grammar is the meaning of the derivation: implementations parse and apply the declared rules; they MUST NOT supplement, infer, or retune rules outside the grammar. A production that exists only in one provider's code is not part of the semantics.

### 1.4 Derivation Step and Iteration Depth

- A **derivation step** replaces every module of the current sentential form by the successor of its rule, simultaneously (parallel replacement), yielding the next sentential form. One step is a pure function `(grammar, form) → form`.
- The **derivation of depth `n`** is the axiom followed by exactly `n` successive steps.
- **Iteration depth** is a declared, non-negative integer input to derivation. Implementations MUST NOT infer, clamp, or extend depth implicitly; any bound applied by a consuming domain (for example a per-stage depth table) is that domain's declared semantics, not the grammar's.
- The **form** — the sentential string of module occurrences with parameter values — is the morphological result of a derivation. Geometry, meshes, and turtle state are representations of a form, never the form itself (`MORPHOLOGY-INV-016`, `MORPHOLOGY-INV-018`).
- Equivalence of derivations is asserted over the discrete symbol string and exact parameter values (`MORPHOLOGY-INV-011`: the equivalence relation is identified — structural equality of the sentential form). Floating-point determinism of any rendered geometry is per-provider and is not part of grammar equivalence.

### 1.5 Termination Bounds

- Every grammar MUST declare a finite maximum iteration depth — its **termination bound**.
- The alphabet is finite and every successor is a finite string, so each step yields a finite form; the depth bound makes every declared derivation finite and terminating.
- Derivation beyond the declared bound is outside the grammar's defined meaning; a provider MUST NOT continue deriving past it.

### 1.6 Determinism

- **Same grammar + same axiom + same iteration depth ⇒ identical derivation** — the same module sequence with the same parameter values — run twice, on any conforming provider.
- Derivation has no hidden state: it MUST NOT depend on evaluation order, wall-clock time, mutable random streams, or provider-specific behaviour. Any variability MUST be an explicit declared parameter of the grammar (for example a variant seed folded into axiom or production parameters) before derivation begins.
- Determinism is what makes provider substitution semantics-preserving (`MORPHOLOGY-INV-017`): replacing one expander with another preserves the morphological contract.

### 1.7 Tropism as Parametric Term

- A grammar MAY declare a **tropism** — a directional response of the structure to a declared direction (for example phototropism toward a light direction, or precession) — as a **parametric term**: named parameters (direction, coefficient, and the like) plus a declared deterministic expression by which the term contributes parameter values during derivation.
- Tropism enters the derivation as parameter values and therefore belongs to the discrete derivation — the conformance axis — not to ambient simulation state and not to renderer behaviour.
- The tropism's inputs MUST be declared: external conditions (a direction, a field value) are supplied to derivation as explicit arguments of the consuming contract, never read as implicit side channels.

### 1.8 Relation to Branching, Growth, and Compact Description

- Grammar-derived structure realises parent §18 **Branching**: one module's successor string may contain multiple successor modules, dividing one structure into multiple related structures.
- When a consuming domain advances iteration depth with developmental time, the resulting structure is "rule-based growth" in the sense of parent §25. Advancing time is the consuming domain's semantics (`SCR-LIB-MORPHOLOGY-GROWTH`, `SCR-LIB-ECOLOGY-FLORA`); the grammar itself has no clock.
- Grammar plus axiom plus depth is a compact generative description of repeated structure in the sense of parent §17 Repetition: derivations MAY be represented compactly rather than materialised as explicit instances. Representations of a derivation (symbol strings, meshes) never redefine its meaning (`MORPHOLOGY-INV-016`, `MORPHOLOGY-INV-018`).

---

## 2. Invariants Consumed

Relationship types and invariant references below are normative; this domain defines no new invariants — it consumes the parent's.

| Invariant | Source domain | How this domain satisfies it |
|---|---|---|
| `MORPHOLOGY-INV-001` Identity | `SCR-LIB-MORPHOLOGY` | Module occurrences in a derivation have stable semantic identity — name plus parameter values — across steps (§1.1, §1.4) |
| `MORPHOLOGY-INV-002` Structural Integrity | `SCR-LIB-MORPHOLOGY` | Declared structural relationships of a form remain valid across derivation steps; simultaneous replacement preserves declared structure (§1.3, §1.4) |
| `MORPHOLOGY-INV-003` Part-Whole Integrity | `SCR-LIB-MORPHOLOGY` | Composition expressed by productions keeps part-whole relationships semantically consistent (§1.3) |
| `MORPHOLOGY-INV-016` Representation Independence | `SCR-LIB-MORPHOLOGY` | The form is the discrete derivation; geometry, meshes, and turtle state are representations only and never define grammar meaning (§1.4, §1.8) |
| `MORPHOLOGY-INV-017` Provider Independence | `SCR-LIB-MORPHOLOGY` | Determinism: substituting the expander preserves the derivation contract (§1.6) |
| `MORPHOLOGY-INV-018` Rendering Independence | `SCR-LIB-MORPHOLOGY` | Rendered appearance never defines or redefines grammar or derivation meaning (§1.4, §1.6) |

---

## 3. Relationships to Other Domains

Relationship types below are restricted to the controlled vocabulary of `001_agents/02_graph_relationships.md`.

| Domain | Relationship | Meaning |
|---|---|---|
| `lib/401_Morphology` | `CONTAINS` | Morphology contains the Procedural subdomain (parent 101 front matter: `parent: SCR-LIB-MORPHOLOGY`); parent §18/§25/§17 (Repetition) remain authoritative context |
| `lib/101_Core/Identity` | `INTERACTS_WITH` | Supplies canonical `SemanticId` coordinates for morphological parts and features, including module and form identity |
| `lib/203_Graph/Hypergraph` | `INTERACTS_WITH` | Provides the canonical hypergraph representation for component hierarchies and relations |
| `lib/302_Geometry` | `INTERACTS_WITH` | Supplies spatial embeddings, coordinates, and metric boundaries for morphological forms derived from a grammar |
| `lib/303_Topology` | `INTERACTS_WITH` | Supplies topological connectivity, homology invariants, and continuity contracts for derived structure |

These relationships are semantic and do not automatically imply implementation dependencies.

---

# Definition Authority

This document establishes the normative semantic meaning of `Procedural` in SCR Morphology. Implementations, data structures, and compiler transforms are subordinate to the contracts specified herein.
