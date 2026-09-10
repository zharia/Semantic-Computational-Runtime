# STC-001 Formal Crosswalk

Mappings: SMM/STC concept → existing SCR concept (Core ontology /
docs) → existing Lean representation → decision + reason.
Per spec §5, every decision is one of:
`REUSE` (existing primitive suffices) / `DERIVE` (definable from
existing) / `REFINE` (existing needs added structure) /
`GAP` (genuine missing distinction, counterexample-backed) /
`REJECT` (must NOT exist in the semantic layer).

Formal artifacts: `SCRFormal/SCR/STC.lean` (kernel),
`STCLaws.lean` (abstract laws), `STCExamples.lean` (five semantic
machines), `STCCounterexamples.lean` (falsifications CX-*).

| SMM/STC concept | Existing SCR concept | Lean (inner SCRFormal) | Decision | Reason |
|---|---|---|---|---|
| Semantic state 𝒮 | `101_Core` state | `SCR.State` (entities+relationships), `State.lean` | REUSE (as instantiation) | STC is type-parametric over S; `SCR.State` is a valid state domain; CX-EQV shows bare data equality is NOT semantic identity — states must be read through ≡, not as themselves |
| Semantic context 𝒞 | `101_Core` context, docs/106 §6 "reuse Core Context" | `SCR.Context`/`SemanticField.contexts`, `Field.lean` | REUSE | Contexts are per-field interpretation domains; machines carry their own C (Example: one-point contexts). docs/106 §6 followed: no parallel context ontology |
| Semantic transformation 𝒯 | `101_Core` transformation | `SCR.Transformation` (record with id/op/target/arg), `Transformation.lean` | REUSE (as instantiation) + REFINE (record vs. behaviour) | Kernel T is abstract; the committed record is descriptive data — its SEMANTIC content is supplied by `OutcomeOf` instantiation (record alone is not the transformation's meaning: correct per docs/106 §7) |
| Constraint 𝒦 | `101_Core` constraints | none in inner Lean | GAP→REFINE | No committed Lean constraint object. `Consents K T S C` relation added (docs/106 §8). Constraint ENVIRONMENTS (elements of K) deliberately kept abstract |
| Outcome 𝒪 | `101_Core` events/error/result (partial) | absent (only `Option State` via `SCR.Transition` alias) | GAP→REFINE | docs/106 §10 outcome algebra missing. `OutcomeOf` relational class + `IsFailure` added. **The functional alias is FALSIFIED as an outcome model (CX-NDet)** |
| Transition δ | `101_Core` transition/delta; `SCR.Transition` alias | `SCR.Transition` (function type) | DERIVE + REJECT | δ = `instantiate τ s c κ` as a TUPLE (docs/106 §9 "not a new primitive"). REJECT: a dedicated `STCTransition` type; REJECT the committed function alias as the STC transition object (CX-NDet: single-valued cannot express M(δ) ⊆ O) |
| Observation | docs/106 §15; root `formal/` has `Observation` struct | inner: absent | DERIVE | `partialTransition`/determinism phrased through outcome sets; state observation via designated probes — **probe construction derived from kernel members (STC.probeDistinction); no new primitive (resolves spec §12 primitivity)** |
| Equivalence ≡ | `101_Core` equivalence | `SCR.Equivalence` (`a = b`) | REFINE | CX-EQV: equality distinguishes permutation-identical field content ⇒ context-indexed `Equiv C` (docs/106 §16) required; setoid laws via `EquivLaws` witness |
| Identity | `101_Core` identity | `SCR.Identity` (`SameIdentity`) | REUSE | STC-001 needs no new identity machinery; identity obligations (docs/107 §16) recorded OPEN O-4 (see report) |
| Relationship | `203_Graph` / `SCR.Relationship` | `Relationship.lean` | REUSE (outside kernel) | Relationships live in state domains, not in the kernel — correct boundary (docs/106 §29) |
| Composition | `101_Core` composition | root `formal/`: `Transformation.comp` (functional) | REFINE→GAP | Kernel-level composition needs outcome→state structure: `ResultState` + GAP G1. `Transformation.comp` is the FUNCTIONAL special case (deterministic machines only). **CX-RESULT: not derivable from the tuple** |
| Independence ⊥ | docs/106 §12 `δ₁ ⊥ δ₂` | absent | GAP G3 | **CX-IND: commutation not a function of outcome data** ⇒ `Footprint`/`Overlap` refinement (minimal: two relations, no new carriers). Machine soundness law `FootprintsSound` (commutation) — stated structurally, proven for the Pair machine |
| Causality ≺ | `101_Core` causal relations | absent | DEFER | STC-001 does not formalize causality (docs/107 §13). Nothing in STC-001 results blocks it: causal order is expected to be stateable as a relation over transitions (derived tuples) + footprint overlap. Recorded OPEN O-3 |
| Temporal order | `101_Core` temporal; root `SemanticTime` | absent inner | DEFER | Spec §16 question stands; no counterexample encountered yet that needs time. OPEN O-3 |
| Conformance ⊨ | docs/106 §16, spec §13 | absent | DEFER (STC-002) | Requires the state-level ≡ congruence package (GAP G4, STCLaws.lean OPEN O-2) before `Obs(I(δ)) ≡ Obs(SMM(δ))` is well-typed in the kernel |
| Failure taxonomy | docs/106 §11 | absent | REFINED into kernel | Row 1 Rejected (DERIVED: ¬admissible, `rejected_no_outcome` PROVEN); row 2 semantic failure (`IsFailure` OUTCOME, Div machine PROVEN); rows 3–4 (realization/physical) **INEXPRESSIBLE in kernel by design** (spec §19 firewall holds: cannot be smuggled) |
| `Outcome → state` projection | none | none | GAP G1 refinement (`ResultState`) | multi-valued retained: multiple realization states for one semantic outcome (docs/106 §10) |
| Deterministic predicate | `SCR.Invariants.Deterministic` (function-based) | `Invariants.lean` | REFINE | Old: `step s t = some s₁ → = some s₂ → s₁ = s₂` (trivially true for functions — VACUOUS on its own model); new: `deterministic δ` = all outcomes ≡_C — nontrivial for relational M, coincides with old on functional machines |
| `InvariantId` enum | `SCR.Invariants` | `Invariants.lean` | REJECT (as formal content) | Bare String-like enum, no propositions — decorative, carries no proof obligation (spec §32: vacuous). Left in place (no unrelated churn); STC laws live in `STCLaws.lean` |
| Scheduler/provider/EGS/memory | implementation | n/a | REJECT | Not formalized anywhere in STC-001 (spec §1.3, §26, §33, §41 — anti-laundering) |

## Kernel verdict (preview — full text in `report.md`)

The published kernel `⟨S, C, T, K, O, ≡⟩` is **sound but not
minimal-complete**:

- SUFFICIENT for: applicability, admissibility, rejection/failure/
  partiality taxonomy, determinism/nondeterminism, observation (via
  probes), contextual equivalence.
- INSUFFICIENT (counterexample-backed) for:
  1. sequential composition — needs `ResultState` (G1, CX-RESULT);
  2. independence/concurrency — needs `Footprint` + `Overlap`
     (G3, CX-IND);
  3. conformance statements over states — needs state-domain ≡ with
     congruences (G4, STCLaws OPEN O-2).
