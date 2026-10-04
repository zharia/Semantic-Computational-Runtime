---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-EVOLUTION-PHENOTYPE
title: Phenotype
name: Phenotype

version: 0.1.0
status: draft

created: 2026-10-03
updated: 2026-10-03

parent: SCR-LIB-EVOLUTION
authority: SCR
domain: semantic-library
---

# SCR Evolution: Phenotype

## Purpose

Phenotype is the SCR Evolution subdomain for the genotype-to-phenotype mapping: how an individual's trait vector (genotype) determines parameters of the form it expresses (phenotype), as a pure deterministic function — distinct from selection, distinct from growth.

## Scope

In scope: the genotype (per-instance trait vector) as mapping input; the phenotype (declared form parameters) as mapping output; the pure deterministic mapping between them; its determinism and reproducibility; the firewall that keeps selection, growth, and ecology membership outside this subdomain. Out of scope: selection, viability, and fitness decisions (authoritative in `SCR-LIB-EVOLUTION`); growth over developmental time (`SCR-LIB-MORPHOLOGY-GROWTH`); grammar and derivation semantics (`SCR-LIB-MORPHOLOGY-PROCEDURAL`); population membership, establishment, and stage policy (`SCR-LIB-ECOLOGY`, `SCR-LIB-ECOLOGY-FLORA`); reproduction and cross-generational inheritance (`503_Simulation/Reproduction` remains untouched).

## Core Concepts

1. **Genotype** (§1.1) — the individual's trait vector; an output of variation and an input to the mapping (`EVOLUTION-INV-004`).
2. **Phenotype** (§1.2) — the declared form parameters that determine morphological form.
3. **Mapping** (§1.3) — a pure deterministic function genotype → phenotype; documented, explicit, value-exact.
4. **Distinction from selection** (§1.4) — the mapping never decides persistence.
5. **Distinction from growth** (§1.5) — the mapping never advances developmental time or accretes form.
6. **Determinism** (§1.6) — same genotype ⇒ identical phenotype, replayable (`EVOLUTION-INV-018`).

---

## 1. Semantic Definition

**Phenotype** is a subdomain of SCR Evolution (`SCR-LIB-EVOLUTION`). It closes the parent's expected-subdomain gap: the parent 101's own "Expected Subdomains" tree lists `phenotype` alongside `genotype`, `variation`, and `selection`.

Evolution distinguishes variation, selection, and inheritance (`EVOLUTION-INV-004`, `EVOLUTION-INV-005`, `EVOLUTION-INV-006`). The phenotype is the leg on which variation becomes expressed as form: variation produces the genotype; this subdomain maps genotype to phenotype; selection — elsewhere — decides which individuals persist. The mapping sits strictly between variation and selection and performs neither.

### 1.1 Genotype (Trait Vector)

- A **genotype** is an individual's **trait vector**: a finite, declared set of named trait values (for example tolerances to volcanic ash and to drought) carried by that individual.
- The genotype is an **output of variation** — produced upstream (`EVOLUTION-INV-004`: variation remains distinguishable from selection; this mapping neither produces variation nor applies selection).
- A change to the trait vector is variation, not mapping. The mapping consumes the trait vector as given input state.

### 1.2 Phenotype (Form Parameters)

- The **phenotype** is a declared set of **form parameters**: the parameter values that determine the morphological form the individual expresses (for example trunk diameter, crown density, leaf count, droop angle).
- The phenotype is a **description of form**. It is not geometry, not a mesh, not a rendered appearance; it is subordinate to morphological representation, provider, and rendering independence (`MORPHOLOGY-INV-016`, `MORPHOLOGY-INV-017`, `MORPHOLOGY-INV-018`).
- Position, age, growth magnitude, and population membership are not phenotype: they are ecological and developmental state, authoritative elsewhere (§1.5, §2).

### 1.3 Genotype → Phenotype Mapping

- The mapping is a **pure function**: genotype (trait vector) → phenotype (form parameters). The same genotype yields the same phenotype, always.
- The mapping is **documented and explicit**: every influence of a trait on a form parameter is declared (for example ash tolerance modulates trunk diameter and crown density; drought tolerance modulates leaf count and droop angle). No implicit coupling and no code-only constants: a modulation that exists only in an implementation is not part of the semantics.
- Inputs beyond the trait vector MUST be declared explicitly (`EVOLUTION-INV-011`, Environmental Integrity): where environmental or contextual conditions participate at all, they are explicit declared inputs of the mapping — never ambient side channels.
- A trait declared not to influence form maps to no form parameter; declared-but-unused traits remain reserved — no speculative mappings are invented to fill them.
- The mapping's output supplies **form parameters** that modulate the grammar of `SCR-LIB-MORPHOLOGY-PROCEDURAL`. Grammar meaning (alphabet, axiom, productions, derivation) stays authoritative there; this subdomain supplies modulated parameters, it does not define productions.

### 1.4 Distinction from Selection

- **Selection decides differential persistence; the phenotype maps form.** The mapping never computes survival, viability, fitness, or establishment.
- The causal chain is one-directional: variation produces the genotype → the mapping produces the phenotype → selection filters individuals whose traits (with their expressed form) do or do not persist. The mapping is the middle leg and performs no filtering (`EVOLUTION-INV-004`, `EVOLUTION-INV-005` as context: selection remains distinguishable from variation).
- Where selection differentially acts on differently-formed individuals, that differential is selection's meaning, not the mapping's. The standing evolution/ecology firewall (`ECOLOGY-INV-013`, carried from 0009) is respected: this subdomain redefines no selection semantics.

### 1.5 Distinction from Growth

- **Growth** — constructive morphogenesis, developmental accretion, and volumetric expansion over time — is authoritative in `SCR-LIB-MORPHOLOGY-GROWTH`, consumed by `SCR-LIB-ECOLOGY-FLORA`.
- The mapping is **stateless with respect to development**: it does not advance time, does not accrete form, and does not read age or developmental stage. The trait-driven component of form is what the mapping defines; stage-driven complexity (iteration depth, structural development) is development, consumed by the growing domain and the grammar — not by the mapping.
- Consequently the same genotype maps to the same trait-driven form parameters at every stage of the individual's life; how that form develops over time is growth's meaning, not this subdomain's.

### 1.6 Determinism and Reproducibility

- The mapping is deterministic: same genotype ⇒ identical phenotype (parameter-value identical), run twice, on any conforming implementation. There is no mutable random stream in the mapping; any stochastic semantics lives upstream in variation, which declares its own.
- **Reproducibility** (`EVOLUTION-INV-018`): the genotype together with the declared mapping is sufficient state to reproduce the phenotype. Sufficient state, provenance, and environmental information are preserved wherever the result is claimed reproducible.

---

## 2. Semantic Firewall — Form Only

> **Phenotype maps form only. It does not redefine selection, growth, or ecology membership.**

This domain is a firewall-respecting consumer, not a re-definer:

- **Selection meaning stays in `SCR-LIB-EVOLUTION`** (`EVOLUTION-INV-004` variation/selection distinction; `ECOLOGY-INV-013` evolution distinction, carried from 0009): this subdomain MUST NOT decide persistence, viability, fitness, or establishment.
- **Growth meaning stays in `SCR-LIB-MORPHOLOGY-GROWTH`**: this subdomain MUST NOT redefine developmental accretion, volumetric expansion, or the advancement of developmental time.
- **Ecology membership meaning stays in `SCR-LIB-ECOLOGY` / `SCR-LIB-ECOLOGY-FLORA`**: this subdomain MUST NOT add or remove population instances, or redefine establishment, field, or stage policy.
- **Grammar meaning stays in `SCR-LIB-MORPHOLOGY-PROCEDURAL`**: this subdomain supplies form parameters; it MUST NOT define, infer, or retune productions.

Any semantic question not answered by this document is answered by the parent or by the authoritative domain named above — never by implementation convenience.

---

## 3. Invariants Consumed

| Invariant | Source domain | How this domain satisfies it |
|---|---|---|
| `EVOLUTION-INV-004` Variation Integrity | `SCR-LIB-EVOLUTION` | The mapping is the variation-to-form leg: traits (variation output) are consumed, never produced or selected here (§1.1, §1.3, §1.4) |
| `EVOLUTION-INV-011` Environmental Integrity | `SCR-LIB-EVOLUTION` | Any non-trait input to the mapping is an explicit declared input, never an implicit side channel (§1.3) |
| `EVOLUTION-INV-018` Reproducibility Integrity | `SCR-LIB-EVOLUTION` | Genotype plus declared mapping suffices to reproduce the phenotype; the mapping is a pure function (§1.3, §1.6) |
| `ECOLOGY-INV-013` Evolution Distinction | `SCR-LIB-ECOLOGY` | Firewall: phenotype maps form only; selection, growth, and ecology membership meanings stay authoritative elsewhere (§2) |

This domain defines no new invariants; it consumes the ones above.

---

## 4. Relationships to Other Domains

Relationship types below are restricted to the controlled vocabulary of `001_agents/02_graph_relationships.md`.

| Domain | Relationship | Meaning |
|---|---|---|
| `lib/704_Evolution` | `CONTAINS` | Evolution contains the Phenotype subdomain; the parent 101 front matter (`parent: SCR-LIB-EVOLUTION`) and the parent's Expected Subdomains tree (`phenotype`) establish the containment |
| `lib/401_Morphology/Procedural` | `INTERACTS_WITH` | The mapping supplies trait-modulated form parameters that enter grammar axiom/production parameters; Procedural remains authoritative over grammar and derivation semantics |
| `lib/705_Ecology/Flora` | `INTERACTS_WITH` | Flora instances carry trait vectors whose mapped form parameters drive per-instance structure; Flora states conformance only, phenotype meaning stays authoritative here |

These relationships are semantic and do not automatically imply implementation dependencies.

---

# Definition Authority

This document establishes the normative semantic meaning of `Phenotype` in SCR Evolution. Implementations, data structures, and compiler transforms are subordinate to the contracts specified herein.
