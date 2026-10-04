---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-ECOLOGY-FLORA
title: Flora
name: Flora

version: 0.1.0
status: draft

created: 2026-10-02
updated: 2026-10-03

parent: SCR-LIB-ECOLOGY
authority: SCR
domain: semantic-library
---

# SCR Ecology: Flora

## Purpose

Flora is the SCR Ecology subdomain for living plant populations: an explicit flora population over the terrain domain, a flora establishment field (a Field specialization), developmental growth conformance to Morphology Growth, selection-and-variation conformance to Evolution, and deterministic decision semantics.

## Scope

In scope: flora population membership (the instance list), the flora establishment field over the terrain-cell domain, growth conformance, selection-and-variation conformance, and deterministic decision semantics. Out of scope: reproduction and cross-generational inheritance/lineage (§1.4), ecological meaning owned by `SCR-LIB-ECOLOGY` and `SCR-LIB-EVOLUTION` (§2 firewall), representation/provider/rendering concerns (MORPHOLOGY/FIELD independence invariants).

## Core Concepts

1. **Flora population** (§1.1) — membership is the explicit instance list (`ECOLOGY-INV-003`).
2. **Flora field** (§1.2) — establishment suitability over the terrain-cell domain; a Field specialization, not a sampled texture.
3. **Growth** (§1.3) — developmental accretion per `SCR-LIB-MORPHOLOGY-GROWTH`; wire magnitudes are representations only.
4. **Selection & variation** (§1.4) — trait variation plus establishment/survival filtering per `SCR-LIB-EVOLUTION`; differential persistence without reproduction.
5. **Determinism** (§1.5) — pure functions of (seed, cell, world state, age); no mutable RNG stream; age is ecological time.
6. **Phenome conformance** (§1.6) — structure complexity is developmental (stage); the wire carries a compact generative description (`variant_seed` + `stage`), never geometry.

---

## 1. Semantic Definition

**Flora** is a subdomain of SCR Ecology (`SCR-LIB-ECOLOGY`). It defines the semantics of plant-like ecological participants: how they are counted as a population, where they may become established, how they grow over developmental time, and how trait variation and environmental selection govern their persistence.

Flora composes the parent domain's population, environment, ecological-state, and ecological-field semantics (`SCR-LIB-ECOLOGY` §1, §3, §9, §17) with growth conformance (`SCR-LIB-MORPHOLOGY-GROWTH`) and evolution conformance (`SCR-LIB-EVOLUTION`).

### 1.1 Flora Population

A **flora population** is a population in the sense of `SCR-LIB-ECOLOGY` §1: a collection of entities sharing a declared ecological criterion. For Flora the membership criterion is explicit and constructive:

- Population membership **is the instance list**: the set of established flora instances, each with an identity, an anchoring terrain cell, a species identity, an age, and a trait vector.
- Membership is enumerated, not inferred from rendering, storage, or sampling artefacts. The instance list is the authority on who is in the population (`ECOLOGY-INV-003`, Population Explicitness).
- Instances enter the population by establishment and leave it by death; both transitions are semantic state changes of the ecological state (`SCR-LIB-ECOLOGY` §9), distinct from the processes that produce them (`ECOLOGY-INV-009`).
- Population-level descriptions (composition, abundance, distribution) are derived from the instance list; they do not replace it.

### 1.2 Flora Field

The **flora field** is the establishment-suitability assignment over the terrain-cell domain. It is a Field specialization in the sense of `SCR-LIB-FIELDS` ("a field assigns, relates, or evolves meaningful information over a defined domain"):

- **Domain:** the declared terrain-cell domain (the set of terrain cells addressable in the world).
- **Value space:** establishment suitability — a declared scalar measure of whether flora may become established at a cell.
- **Meaning:** suitability is ecological meaning (a statement about establishment), not a storage layout. The flora field is **not** merely an array, grid, buffer, sampled texture, or heightmap of values; any such structure may only be a representation of the field, and a sample of a field is not the field (`FIELD-INV-001` Domain Identity, `FIELD-INV-003` Domain/Value Coherence, `FIELD-INV-008` Sampling Integrity, `FIELD-INV-004` Representation Independence).
- **Inputs:** the field is evaluated from declared environmental conditions — position, biome, terrain height, slope, moisture, declared environmental stress, and seed — all of which are explicit environmental conditions of `SCR-LIB-ECOLOGY` §3 (`ECOLOGY-INV-004`, Environment Explicitness).
- Establishment consumes the field: a candidate cell establishes only where suitability meets the declared threshold, together with the domain's hard band preconditions (biome eligibility, elevation above sea level, slope cap). Suitability and thresholds are semantics; their evaluation is deterministic (§1.5).

### 1.3 Growth

Flora growth conforms to `SCR-LIB-MORPHOLOGY-GROWTH` (`SCR-LIB-MORPHOLOGY`): **constructive morphogenesis, developmental accretion, and volumetric expansion over time**.

- Every flora instance carries an age — developmental time since establishment — and a deterministic growth trajectory from age to mature form (a species growth curve monotonic to maturity, then stable).
- Growth is developmental accretion of the instance's morphological form; the population's age structure is ecological state over developmental time.
- **Representation independence:** any scalar magnitude carried to describe growth state (for example a `scale` value transmitted on the contract wire) is a *representation* of growth state only. It never defines, redefines, or bounds the meaning of growth (`MORPHOLOGY-INV-016` Representation Independence, `MORPHOLOGY-INV-017` Provider Independence, `MORPHOLOGY-INV-018` Rendering Independence). Visual appearance, rendering transforms, and carrier formats are subordinate to the growth contract.
- Growth algorithm, provider, and rendering substitution preserve the morphological contract (`MORPHOLOGY-INV-017`); observed appearance does not redefine growth meaning (`MORPHOLOGY-INV-018`).

### 1.4 Selection & Variation

Flora selection and variation conform to `SCR-LIB-EVOLUTION`. The scope is **selection and variation only** — differential persistence without reproduction:

- **Variation** (`EVOLUTION-INV-004`, Variation Integrity): each instance carries a per-instance trait vector (for example tolerances to volcanic ash and to drought) drawn as a pure function of seed and cell. Variation remains distinguishable from selection: traits are produced by variation; establishment and survival are decided by selection.
- **Selection** (`EVOLUTION-INV-005`, Selection Integrity): establishment selection filters candidates whose local stress exceeds their tolerances; survival selection removes instances whose sustained local stress exceeds their tolerances. Selection remains distinguishable from variation and from inheritance.
- **Viability** (`EVOLUTION-INV-009`, Viability Integrity): whether an instance persists under current conditions (viability) remains distinguishable from comparative fitness; this domain makes viability decisions, not scalar-fitness optimisation.
- **Environmental conditions** (`EVOLUTION-INV-011`, Environmental Integrity): the stress and moisture conditions driving selection are semantically represented inputs of the environment (`SCR-LIB-ECOLOGY` §3), not implicit side channels.
- **Reproducibility** (`EVOLUTION-INV-018`, Reproducibility Integrity): establishment, trait assignment, growth, and death are declared deterministic; sufficient state (seed, cells, ages, traits, environmental inputs) suffices to reproduce the declared result.
- **Inheritance and lineage — honest limitation** (`EVOLUTION-INV-006`, `EVOLUTION-INV-007`): inherited properties and ancestry are satisfied **trivially per instance** — a trait vector is constant over the instance's life, so the trait is trivially "inherited" by the same instance across its lifetime, and an instance's cell anchor trivially fixes its one-element lineage. **Cross-generational inheritance and lineage are OUT OF SCOPE**: they require reproduction, which this domain does not define. Generational evolution is a successor concern (`503_Simulation/Reproduction`, `601_Agent/Population` remain untouched).

Differential persistence without reproduction is still selection in the sense of `SCR-LIB-EVOLUTION`: variants (trait vectors) differ, environments filter, and the population composition changes accordingly.

### 1.5 Determinism

Flora semantics are deterministic under declared inputs:

- Establishment, trait assignment, growth, survival, and death are **pure functions** of (seed, cell, declared world state, age). The same inputs yield the same outputs; evaluation order does not matter.
- There is **no mutable RNG stream**: no stateful random source consumed in call order. Every decision is a pure hash-style function of its declared arguments, so runs are repeatable and order-independent (`ECOLOGY-INV-010` companion: `SCR-LIB-ECOLOGY` §43 declared-deterministic semantics are preserved).
- **Temporal explicitness** (`ECOLOGY-INV-010`, Temporal Explicitness): instance age is ecological/developmental time and MUST remain distinguishable from wall-clock and implementation time. Growth advances with ecological time, never with wall-clock time.
- Determinism is a property of the semantics; any stochastic variant must declare its stochastic semantics explicitly (`SCR-LIB-ECOLOGY` §43).

### 1.6 Phenome Conformance

Flora phenome conformance binds an instance's structural complexity to developmental stage and binds its carried description to the compact generative description:

- **Structure complexity is developmental.** An instance's structural complexity is quantified by a developmental **stage** derived from its age — quantized per species maturity curve, bounded, and consistent with age. Stage grows *branching complexity*; growth magnitude (§1.3) continues to describe volumetric expansion. The two are separate, explicit axes.
- **Stage is monotone.** Stage is non-decreasing in age: structure accretes and never regresses while the instance lives (death and regrowth are population transitions of §1.1, not stage steps). This preserves `ECOLOGY-INV-010` temporal explicitness — stage is ecological/developmental time, never wall-clock time — and keeps stage-driven derivation consistent with §1.5 determinism.
- **The wire carries a compact generative description.** Repeated structure is carried as `variant_seed` (the instance's generative identity) plus `stage` (its developmental depth) — a compact generative description per `SCR-LIB-MORPHOLOGY` §17 Repetition (line 577: "Repeated structure MAY be represented as a compact generative description rather than explicitly materialised instances"). **Geometry never crosses the wire**: no meshes, vertices, symbol strings, or internode lists. The generative description is a representation, subordinate to `MORPHOLOGY-INV-016`, `MORPHOLOGY-INV-017`, and `MORPHOLOGY-INV-018`.
- **Derivation is bounded by stage.** Stage bounds the iteration depth of the morphological grammar (`SCR-LIB-MORPHOLOGY-PROCEDURAL`: axiom, parametric production rules, declared termination bound); the same generative description yields the same structure (`EVOLUTION-INV-018` reproducibility, `MORPHOLOGY-INV-017` provider independence).

---

## 2. Semantic Firewall — ECOLOGY-INV-013

> **ECOLOGY-INV-013 (Evolution Distinction): Evolution MUST remain distinguishable from ecological dynamics.**

This domain is a firewall-respecting consumer, not a re-definer:

- **Evolution meaning belongs to `SCR-LIB-EVOLUTION`.** Trait variation, selection, viability, inheritance, lineage, and reproducibility are defined authoritatively in `704_Evolution`; Flora states conformance only (§1.4) and MUST NOT redefine evolution meaning here.
- **Population and environment meaning belong to `SCR-LIB-ECOLOGY`.** Population membership, environment, and ecological state are defined authoritatively in `705_Ecology`; Flora specializes them (§1.1, §1.2) and MUST NOT redefine them here.
- Flora adds only subdomain-specific definitions (population instance list, establishment field, growth/selection conformance, determinism). Any semantic question not answered by this document is answered by the parent or by the authoritative domain named above — never by implementation convenience.

---

## 3. Invariants Consumed

| Invariant | Source domain | How this domain satisfies it |
|---|---|---|
| `ECOLOGY-INV-003` Population Explicitness | `SCR-LIB-ECOLOGY` | Membership = explicit instance list (§1.1) |
| `ECOLOGY-INV-004` Environment Explicitness | `SCR-LIB-ECOLOGY` | Environmental inputs of field and selection are declared (§1.2, §1.4) |
| `ECOLOGY-INV-009` State Explicitness | `SCR-LIB-ECOLOGY` | Instance state distinguished from establishment/death processes (§1.1) |
| `ECOLOGY-INV-010` Temporal Explicitness | `SCR-LIB-ECOLOGY` | Age is ecological time, distinct from wall-clock time; deterministic semantics (§1.5) |
| `ECOLOGY-INV-013` Evolution Distinction | `SCR-LIB-ECOLOGY` | Firewall: evolution meaning stays with `704_Evolution` (§2) |
| `EVOLUTION-INV-004` Variation Integrity | `SCR-LIB-EVOLUTION` | Trait variation distinct from selection (§1.4) |
| `EVOLUTION-INV-005` Selection Integrity | `SCR-LIB-EVOLUTION` | Establishment/survival filter distinct from variation and inheritance (§1.4) |
| `EVOLUTION-INV-006` Inheritance Integrity | `SCR-LIB-EVOLUTION` | Trivial per instance (trait constant over instance life); cross-generational out of scope (§1.4) |
| `EVOLUTION-INV-007` Lineage Integrity | `SCR-LIB-EVOLUTION` | Trivial per instance (single-anchor lineage); cross-generational out of scope (§1.4) |
| `EVOLUTION-INV-009` Viability Integrity | `SCR-LIB-EVOLUTION` | Viability decisions, no scalar-fitness collapse (§1.4) |
| `EVOLUTION-INV-011` Environmental Integrity | `SCR-LIB-EVOLUTION` | Stress/moisture conditions explicit (§1.4) |
| `EVOLUTION-INV-018` Reproducibility Integrity | `SCR-LIB-EVOLUTION` | Pure functions of declared state; replayable (§1.4, §1.5) |
| `MORPHOLOGY-INV-012` State Integrity | `SCR-LIB-MORPHOLOGY` | Phenome conformance: stage monotone non-decreasing in age — developmental stage transitions produce valid, accreting morphological states; the wire carries the compact generative description (`variant_seed` + `stage`) per §17 Repetition (line 577), never geometry (§1.6) |
| `MORPHOLOGY-INV-016` Representation Independence | `SCR-LIB-MORPHOLOGY` | Growth meaning independent of carrier representation (§1.3) |
| `MORPHOLOGY-INV-017` Provider Independence | `SCR-LIB-MORPHOLOGY` | Growth algorithm/provider substitution preserves contract (§1.3) |
| `MORPHOLOGY-INV-018` Rendering Independence | `SCR-LIB-MORPHOLOGY` | Visual appearance does not define growth meaning (§1.3) |
| `FIELD-INV-001` Domain Identity | `SCR-LIB-FIELDS` | Terrain-cell domain well-defined (§1.2) |
| `FIELD-INV-003` Domain/Value Coherence | `SCR-LIB-FIELDS` | Suitability conforms to declared domain and value semantics (§1.2) |
| `FIELD-INV-004` Representation Independence | `SCR-LIB-FIELDS` | Field meaning independent of physical representation (§1.2) |
| `FIELD-INV-008` Sampling Integrity | `SCR-LIB-FIELDS` | A sample (texture/heightmap) is not the field (§1.2) |

This domain defines no new invariants; it consumes the ones above.

---

## 4. Relationships to Other Domains

Relationship types below are restricted to the controlled vocabulary of `001_agents/02_graph_relationships.md`.

| Domain | Relationship | Meaning |
|---|---|---|
| `lib/705_Ecology` | `CONTAINS` | Ecology contains the Flora subdomain; Flora specializes the parent's population and environment semantics |
| `lib/301_Field` | `REFINES` | The flora field is a Field specialization (establishment suitability over the terrain-cell domain) |
| `lib/401_Morphology/Growth` | `INTERACTS_WITH` | Growth conformance: developmental accretion and volumetric expansion over time |
| `lib/704_Evolution` | `INTERACTS_WITH` | Selection-and-variation conformance; evolution meaning remains authoritative in `704_Evolution` |
| `lib/705_Ecology` | `INTERACTS_WITH` | Flora populations interact with ecological fields and environment (fields influence populations, populations modify fields) |
| `lib/401_Morphology/Procedural` | `INTERACTS_WITH` | Phenome conformance: developmental stage bounds the grammar derivation (axiom, parametric production rules, iteration depth); the wire carries only the compact generative description (`variant_seed` + `stage`) per parent §17 Repetition (line 577), never geometry (§1.6) |

These relationships are semantic and do not automatically imply implementation dependencies.

---

# Definition Authority

This document establishes the normative semantic meaning of `Flora` in SCR Ecology. Implementations, data structures, and compiler transforms are subordinate to the contracts specified herein.
