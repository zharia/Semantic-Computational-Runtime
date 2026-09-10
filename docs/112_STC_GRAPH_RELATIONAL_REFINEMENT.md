# STC Graph-Relational Refinement

**Document ID:** SCR-DOC-STC-112  
**Status:** Normative refinement / pre-STC-002 gate  
**Version:** 0.1.0

## Purpose

STC-001 established that the initial transition calculus was insufficient in at least two respects: outcome data alone cannot express sequential state evolution, and outcome data alone cannot establish semantic independence.

This refinement does **not** assume that the answer is to add `ResultState` and `Footprint` as permanent primitives.

The stronger question is:

> Is a semantic computation fundamentally a typed graph relation from semantic input to semantic output?

A mathematical function already has this structure:

\[
f:X\rightarrow Y
\]

with graph

\[
G_f=\{(x,f(x))\mid x\in X\}.
\]

A general semantic computation may be relational rather than functional:

\[
R_\tau\subseteq I_\tau\times O_\tau.
\]

A deterministic function is the special case of the relation. Nondeterminism is branching from an input to multiple distinguishable outputs.

The graph hypothesis is **not yet normative**. It must be falsified before STC-002.

## Existing authority

The existing SCR ontology remains authoritative: State, Transformation, Operation, Delta where already defined, Relationship, Hypergraph, Observation, and Equivalence.

No parallel ontology is permitted.

The current formal `SCR.Transition` is a functional alias from State and Transformation to `Option State`, and is therefore insufficient as the complete STC model for nondeterministic semantics. STC-001 already established this limitation.

## Central hypothesis

Investigate whether semantic computation can be represented as:

\[
I\xrightarrow{\tau}O
\]

or, for a relational transformation,

\[
R_\tau\subseteq I_\tau\times O_\tau.
\]

The endpoints may themselves be semantic structures, including states or semantic graphs.

The transformation is the semantic edge; it is not merely an implementation record of an execution event.

Determine whether outcome, successor state, delta, failure, and observation are independent semantic primitives or projections/properties of this graph relation.

## Competing models

Evaluate:

1. **STC-001 factoring:** `OutcomeOf` plus `ResultState`.
2. **Transition-result relation:** a relation whose consequence contains outcome and successor state.
3. **Typed semantic graph:** a transformation-labelled relation from semantic input to semantic output, with outcomes, deltas and observations derived or typed as appropriate.

Do not select a model in advance.

## Required counterexamples

Implement and document at least:

- CX-GRAPH-001: identical outcome, different successor state.
- CX-GRAPH-002: equivalent outcomes, distinguishable successor state.
- CX-GRAPH-003: distinguishable outcomes, equivalent successor state.
- CX-GRAPH-004: different transformations, same endpoints.
- CX-GRAPH-005: different representations, same semantic graph.
- CX-GRAPH-006: nondeterministic branching.
- CX-GRAPH-007: admissible partial input.
- CX-GRAPH-008: semantic failure with a meaningful successor.
- CX-GRAPH-009: no-op.
- CX-GRAPH-010: relational composition.
- CX-GRAPH-011: composition associativity.
- CX-GRAPH-012: conditional branching.
- CX-GRAPH-013: independent semantic edges.
- CX-GRAPH-014: non-commuting edges.
- CX-GRAPH-015: causal dependency without physical ordering.
- CX-GRAPH-016: temporal ordering without causality.
- CX-GRAPH-017: causality without wall-clock ordering.
- CX-GRAPH-018: observation of state.
- CX-GRAPH-019: observation of the transformation edge.
- CX-GRAPH-020: provenance-sensitive observation/equivalence.

Each counterexample must record its identical premises, distinguishing semantic fact, and conclusion.

## Determinism

Compare outcome determinism, successor-state determinism, endpoint determinism, transition-result determinism, and observational determinism. Do not assume the STC-001 outcome-only definition is sufficient.

## Partiality and failure

Determine whether partiality means absence of an admissible edge, an incomplete semantic consequence, or another semantic condition.

Determine whether failure is absence of an edge, a typed semantic outcome, a state-changing edge, or a combination.

Physical realization failure remains outside STC.

## Composition

Test whether semantic composition is naturally relational graph composition:

\[
Q\circ R=\{(x,z)\mid \exists y,(x,y)\in R\land(y,z)\in Q\}.
\]

Test deterministic, nondeterministic, partial, failure, conditional, and topology-changing cases. Test associativity semantically, not by representation equality.

## Independence and causality

Re-evaluate the STC-001 definition `causallyDependent := ¬ independent`.

Investigate read, write, influence, and observation footprints separately. Separate semantic independence, causal dependency, conflict, and temporal ordering. Physical resource overlap is not a semantic footprint unless the field explicitly makes it semantic.

## Observation and equivalence

Test observation against outcome, successor state, transformation edge, endpoint, and path.

Test state equivalence separately from transition-result equivalence. Observation remains context-indexed.

## Primitive-elimination rule

For every proposed primitive answer:

> What semantic distinction becomes impossible if this primitive is removed?

A primitive survives only if a minimal counterexample demonstrates that the existing SCR ontology and surviving relations cannot express that distinction.

Convenience is not evidence.

## Required repository deliverables

Create:

- `docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`
- `SCRFormal/SCR/STCGraphCounterexamples.lean`

Update minimally:

- `docs/107_SEMANTIC_TRANSITION_CALCULUS.md`
- `docs/109_SMM_LIBRARY_CROSSWALK.md`

Produce a refinement report identifying the surviving model, rejected models, eliminated primitives, surviving primitives, unresolved questions, and proposed minimum STC-002 kernel.

Do not start STC-002.

## Gate

STC-002 remains blocked until the graph hypothesis is tested; existing State/Transformation/Delta/Relationship/Hypergraph concepts are audited; ResultState and OutcomeOf are justified or eliminated; determinism, nondeterminism, partiality, failure, composition, associativity, observation, equivalence, independence and causality are tested; and every surviving primitive has survived elimination by counterexample.

A successful result may contain fewer primitives than STC-001.


---

# Refinement Results (STC-001.5) — executed `SCRFormal/SCR/STCGraphCounterexamples.lean`

All statements below are machine-checked (Lean 4.19; full build green;
axiom audit: standard `propext`/`Quot.sound` only, no
`Classical.choice`, no `sorry`, no custom axioms).

## 1. STC-001 assumptions

`OutcomeOf` as transition carrier (A1); `ResultState` as separate
added relation (A2); `Applicable`/`Consents` Prop predicates (A3);
hand-carried composition (A4); `Footprint`/`Overlap` with
`causallyDependent := ¬independent` (A5); derived observation (A6).

## 2. Graph hypothesis

Formalized as `GMachine(T,S,C,K)` with `Out : T → Type` (τ-typed
consequence domains) and the single relation
`edge : ∀ τ, K → S → C → Out τ → Prop`. Admissibility (`Applicable`,
`Consents`, `admissible`, `rejected`) is REUSED from `SCR.STC`
verbatim — no parallel ontology (instruction hard constraint).

## 3. Ontology audit

`State`/`Context`/`Transformation`/`Relationship`/`Equivalence`
untouched. **Delta**: no committed Lean implementation exists in
either formal project; the graph derives the semantic delta as the
endpoint span of a consequence (`(s, s′)` via `succRel`) —
classification DERIVED (candidate); mapping to `101_Core` Delta
remains OPEN and must be verified against the Seed definition, not
assumed. Hypergraph: labels/edge families align with
`203_Graph` direction; no graph ontology imported into STC.

## 4. Counterexample results (CX-GRAPH-001 … 020 → `A.cxgN`)

- **001** `cxg1`: `tickA` vs `dblA` from (4,7) — identical emitted
  value 4, successors (5,7) vs (8,7). COUNTEREXAMPLE to A1;
  evidences typed consequence over value.
- **002** `cxg2`: parity-equivalent values, distinguishable
  successors: outcome-level equivalence cannot identify
  transitions. COUNTEREXAMPLE (≡ must lift to edges/paths).
- **003** `cxg3`: `getB`/`getB2` — distinguishable values,
  identical successors: pure `S → S` graphs REFUTED; `Out τ` typing
  NECESSARY.
- **004** `cxg4_same_endpoints` + `cxg4_labels_distinct`: endpoint-
  identical transformations distinguished by LABEL only: unlabelled
  `R ⊆ I × O` REJECTED.
- **005** representations: STC-001 `Repr` + `toG` translation; the
  reverse translation exists only for output-homogeneous machines
  (§17) — the type asymmetry is itself evidence `Out : T → Type` is
  the right grain.
- **006** `cxg6`: `coin` — one input, two successors: relational
  edges represent nondeterminism natively.
- **007** `cxg7`: `hang` admissible ∧ edge-less: `gPartial` ∧
  `¬gRejected` — consents IRREDUCIBLE (§9).
- **008** `cxg8`: `failRoll` — failure-marked consequence WITH
  state change: failure is typed consequence, not absence.
- **009** `cxg9`: `okNoop` vs `failStay` — same everything except
  mark: EQUIVALENCE to STC-001 outcome model here.
- **010** `cxg10`: relational composition witness.
- **011** `gCompose_assoc_left`/`gCompose_assoc_right`: three-edge
  chains factor both ways — associativity STRUCTURAL (A4 burden
  removed). REFINEMENT.
- **012** `gBranch` + `cxg12`: conditional branching is composition
  guarded on consequences. DERIVED.
- **013** `cxg13_compatible_pair`: `tickA`/`tickCopy` compatible on
  (3,7) — both chains land at (5,7).
- **014** `cxg14_order_sensitive`: `tickA`/`dblA` order-SENSITIVE
  (10 vs 9).
- **015** `cxg15` (reuses 014): dependence defined with NO ordering
  primitive in the kernel.
- **016** `cxg16_temporal_without_causal` + 013: chain exists
  (temporal order realizable) for a compatible pair: ordering ≠
  dependence.
- **017** `cxg17_no_wallclock`: context carries a wall-clock tag no
  edge reads — every edge fact transports across tags.
- **018** `cxg18_state_observation`: state-distinction via emitted-
  value reachability (`gStateDistinct`). DERIVED.
- **019** `cxg19_edge_observation`: `getB`/`getB2` — state-level
  identical, edge-level distinct: edge observation NOT reducible to
  state observation.
- **020** `cxg20_provenance` + `cxg4`: same endpoints, same
  consequence, different label paths: provenance = path labelling.
  DERIVED.

## 5. ResultState analysis

Verdict: DEMOTED from primitive (A2) to consequence structure
(`GSuccOut.succRel`). Successor structure is irreducible to outcome
VALUES (001, 002) but needs no separate relation (005/§6): it lives
in the typed consequence. The relational (non-functional) successor
is REQUIRED: `cxg_reject_successor_function` refutes any
`Out → Option S` selection (`coin` lands twice).

## 6. OutcomeOf analysis

Not primitive: it is a projection of the edge (`GValueOut`), or the
edge itself when `Out τ` is chosen as the outcome domain
(`outcomeViaEdge`, `fromG_wellformed`: STC-001's admissibility law is
the graph law verbatim). STC-001 `OutcomeOf` retained for
compatibility only; STC-002 must not re-promote it.

## 7. Delta analysis

As §3: DERIVED endpoint-span candidate; `101_Core` Delta mapping
OPEN.

## 8. Determinism

Five notions separated: value (003 refutes sufficiency), successor
(006 refutes universality), consequence, transition-result,
observational (via ≡). Determinism is always "deterministic IN a
projection" — no single primary notion (record for STC-002).

## 9. Partiality / failure

Rejection is NOT missing-edge (007); failure is typed, may change
state (008); partiality = admissible ∧ consequence-less (007);
realization/physical failure remain outside (STC-001 `Prov` result
carried over unchanged — availability enters only via consent or
consequence absence in elevated contexts). REJECTED: single
"missing edge" failure notion.

## 10. Composition / associativity

Relational graph composition with successor-chaining; associativity
structural (011); refusal semantics preserved (a consequence with no
successor cannot continue — cf. STC-001
`compose_refused_odd_middle`).

## 11. Observation / equivalence

State- and edge-observation distinct (018/019); outcome-level ≡
insufficient (002) → edge equivalence required, with successor
congruence — the STC-001 GAP G4 setoid/congruence package survives
INTACT and now also covers `succRel`. Context-indexing preserved
throughout (no context-blind law used).

## 12. Footprint / independence

013 separates compatibility (behaviour) from non-overlap
(structure): compatible ⇏ independent. `Footprint`/`Overlap`
RETAINED, reclassified as the interference annotation; NOT the seat
of causality (A5 rejected, §13).

## 13. Causality / temporal semantics

STC-001 `causallyDependent := ¬independent` REJECTED (013; it
conflates two distinct relations). Candidate replacement (ASSUMPTION,
falsifiable, under-reporting acknowledged): `gOrderSensitive` —
order-sensitivity of composition (014). Temporal ordering = chain
realizability, distinct from dependence (016); wall-clock irrelevant
(017). FINAL definition deferred to STC-002 with provenance
machinery.

## 14. Primitive-elimination matrix

| Candidate | Distinction at stake | Minimal counterexample | Expressible without? | Conclusion |
|---|---|---|---|---|
| `OutcomeOf` primitive | — | 001 | YES (projection) | DEMOTE |
| `ResultState` | successor | 001/002 | YES (consequence field) | DEMOTE |
| hand composition laws | associativity burden | 011 | YES (relational) | REPLACE |
| `Footprint`/`Overlap` | interference structure | 013 | NO | RETAIN (reclassified) |
| `causallyDependent := ¬independent` | conflations | 013 | YES (`gOrderSensitive`) | REJECT |
| `Applicable`/`Consents` | rejection vs dangling | 007 | NO | RETAIN (reused) |
| labels / `Out τ` typing | identity / observation edges | 004, 003 | NO | REQUIRED |
| unlabelled `R ⊆ I×O` | transformation identity | 004 | — | REJECTED |
| successor-as-function | nondet successors | `cxg_reject_successor_function` | — | REJECTED |
| provenance machinery | same-state chains | 020 | YES (paths) | DERIVED |

## 15. Surviving model

`GMachine` = typed, labelled, relational edge carrier + reused
admissibility + projection classes (`GValueOut`/`GSuccOut`/
`GFailureOut`) + path provenance + footprint annotation for
interference + open causal candidate. ONE relation where STC-001
used two; two primitives demoted to projections; consents and
applicability unchanged.

## 16. Rejected models

(1) outcome-value-as-transition; (2) pure `S → S` graphs;
(3) unlabelled edge unions; (4) functional successors; (5)
rejection-as-missing-edge; (6) causality-as-non-independence;
(7) hand-carried associativity laws.

## 17. Remaining gaps

- Graph→STC-001 reverse translation needs output homogeneity (the
  recorded type-level inexpressibility asymmetry).
- Edge/path equivalence relation + congruences (absorbs G4, now
  covering `succRel`).
- Causal-dependence final definition (§13 candidate under-reports
  commuting read-dependencies — decision deferred with evidence).
- `101_Core` Delta ↔ endpoint-span mapping.
- Context-typed input domains (`Switch`-style context-dependent
  applicability under `I_τ` typing) — representable, untested.
- Hypergraph endpoints ("endpoints may be semantic graphs",
  `203_Graph`): states kept abstract here; structure-valued endpoints
  untested.

## 18. Proposed minimum STC-002 kernel

`GMachine` (§15) + (i) consequence equivalence with successor
congruence, (ii) path equivalence, (iii) decidability classes for
oracle conformance (STC-001 `Oracle`/`Realization` carried over),
(iv) causal-dependence decision per §13, (v) re-derivation of the
five STC-001 machines and the `Witness` golden path over the new
carrier (migration, not replacement, until proven).

## 19. Gate decision

**STC-002 remains BLOCKED.** The graph-relational hypothesis
SURVIVES falsification as the transition carrier (typed, labelled,
relational successor; associativity structural) and DEMOTES
`OutcomeOf`/`ResultState` to projections, while REJECTING
`causallyDependent := ¬independent` and five alternative
decompositions (§16). The gate's remaining clauses — equivalence/
congruence package, causal decision, Delta mapping — are open with
exactly-identified missing structure (no assumption laundering).
Abstractions removed by this increment: four rejected, two demoted
to projections pending STC-002 re-derivation; none deleted from the
codebase (STC-001 preserved; the instruction's completion condition
is honoured).

---

# Gate Closure (STC-002 part 1 — Lawful Equivalence & Migration)

Executed in `SCRFormal/SCR/STCGraphLaws.lean` and
`SCRFormal/SCR/STCGraphMigration.lean` (full build green; axioms:
propext/Quot.sound, Classical.choice only in two case-analysis
witnesses; zero `sorry`). Each §17/§19 gate clause: resolved status
with machine-checked evidence.

| Gate clause | Status | Evidence |
|---|---|---|
| Composition determinism (old G4 / O-2) | CLOSED | `gCompose_deterministic` (+ `gCompose_deterministic_sym`, `compose_value_deterministic`): proven from named machine conditions `stepDet`, `succFunOnClass`; non-vacuity via `tickA_stepDet`/`tickA_succFun` (hold) vs `coin_not_stepDet` (fails) |
| Consequence equivalence + congruences | CLOSED (value, successor); OPEN (continuation) | `GConsEquiv`/`GConsSetoid`/`GConsValueCongruent` used in theorems; continuation-congruence statement deferred INSIDE STC-002 (no padding class exists — deliberate) |
| Path equivalence | CLOSED (span+label pair) | `Chain`, `chain_append` (composition by append); spans for behaviour, label sequences for identity (CXG20) |
| Causality decision | RESOLVED with evidence | `E.sep_order_no_conflict`, `E.sep_conflict_no_order`, `E.sep_enablement_no_order`: conflict, enablement, and successor order-sensitivity pairwise independent. DECISION: causal dependence := enablement ∪ conflict; successor order-sensitivity is a shadow (SEP 3 proves under-reporting). STC-001's `causallyDependent := ¬independent` formally out |
| Delta ↔ `101_Core` §23 mapping | RESOLVED | `D.delta_gt_span`: equal endpoint spans, unequal semantic deltas — delta rides the consequence (payload), span is its graph-level projection; CORE-INV-012 hierarchy preserved; consequence = STC carrier of `S₁ = S₀ ⊕ Δ` |
| Context-typed input domains | RESOLVED | `SW.domains_derive` + CXG7: extensional typed domains derive from the edge; consents remain irreducible (refusal ≠ dangling). Verdict: typing captures domains, NOT refusals |
| Golden path re-derivation over graph carrier | CLOSED | `Migration.wm_golden_composition` (steps 1–2 via `toG`), `wm_golden_observation` (step 3), committed `SCR.State` ontology carried verbatim. Demotion of `OutcomeOf`/`ResultState` is now EVIDENCE-BACKED REFINEMENT; STC-001 retained (refine, not delete) |
| Hypergraph endpoints (203_Graph bridge) | PARTIAL | the migrated states ARE entity/relationship structures — endpoints carry semantic graphs; a dedicated hyperedge machine is scheduled inside STC-002 |

**Gate decision: RELEASED for STC-002 adoption proper** (kernel
promotion, continuation congruence, richer causality algebra,
deprecation decisions on `SCR.STC` pair). The anti-gate conditions
that produced this outcome stand: no kernel was silently redefined;
every surviving primitive (`Applicable`, `Consents`, edge, labels,
typed outputs, footprint-as-interference) survived explicit
elimination tests (§14 matrix extended by E1–E3, D, SW results).

---

# Follow-through (1c, 1d, 1e) — Remaining Items Closed

| Item (§17 line) | Was | Now | Evidence |
|---|---|---|---|
| Causal-dependence algebra | decision + successor-shadow only | **algebra separated**: successor-shadow and value-TRACE shadow are INCOMPARABLE; both distinct from conflict and enablement; the structural account (enablement ∪ conflict) confirmed observationally incomplete BY DESIGN, shadows are witnesses not definitions | `STCGraphCausality` — `CA.trace_sees_what_succ_shadow_misses`, `CA.succ_shadow_blind`, `Z.shadows_incomparable_1`, `CF.conflict_structural`, `CF.cf_trace_blind` |
| Schema witness strengthening | `CanonicalConstraint := v = v` (historical record) | **bound-constraint schema witness added**: decidable non-negativity, tryEvolve success/failure on real arithmetic, non-vacuous preservation law | `SCR/Canonical.lean` — `tryEvolve_bound_success`, `tryEvolve_bound_failure`, `shift_preserves_bound` |
| Hyperedge endpoints | PARTIAL | **closed additively**: graph machine over `SCR.State` endpoints (relationship-preserving entity edges, total); and one consequence spanning three distinct successors — multi-endpoint edges already representable in the relational-successor carrier (design vindicated; the fan-out breaks `succFunOnClass` exactly as the laws predict) | `STCGraphHyperedges` — `HEG.total`, `HEG.relationships_preserved`, `FAN.hyperedge_fanout`, `FAN.not_succFun` |

Still open (named, unchanged): continuation-congruence generalization beyond
successor congruence (1a showed it needs nothing more — CLOSED as
derivation); internal hypergraph incidence structure inside states —
executable-hypergraph milestone scope, not kernel scope; the
"sensitivity without any read/write overlap" reverse separation —
CONJECTURE open.

Build: ALL green. Axioms: propext/Quot.sound only, no choice, no
sorry. Kernel (docs/106 §32) unchanged by these items — they
complete the trajectory's STC-002 remainder.
