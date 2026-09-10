# STC-001 Completion Report

## 1. Executive Result

**STC survived formalization in Outcome A/B hybrid: the kernel is
SOUND but NOT MINIMAL-COMPLETE (Outcome B — model requires
refinement).**

Machine-checked in `SCRFormal/SCR/STC{,Laws,Examples,Counterexamples}.lean`:

- **Survived (formalized + proven):** applicability, admissibility
  (with `Admissible ⇒ Applicable` as a THEOREM), rejection/failure/
  partiality taxonomy (3 of 4 rows representable; rows 3–4 inexpressible
  by design), set-valued outcome relation `M(δ) ⊆ O`, determinism,
  nondeterminism, context-indexed equivalence, sequential composition
  (with refinement), observation (derived via probes).
- **FALSIFIED:** (i) the published kernel tuple ⟨S,C,T,K,O,≡⟩ as
  *sufficient* — composition and independence need extra structure
  (CX-RESULT, CX-IND); (ii) the committed functional transition alias
  `State → Transformation → Option State` as an outcome model
  (CX-NDet); (iii) committed `SCR.Equivalence` (= bare `=`) as semantic
  equivalence (CX-EQV); (iv) `SCR.Invariants.Deterministic` as
  non-vacuous (trivially true for functions — §32 violation).
- **UNCERTAIN (OPEN O-1..O-4):** full commutation law for footprint-
  independent transitions; composition-determinism congruence package
  (GAP G4); causality/temporal relations as kernel relations; identity
  obligations across transitions.

## 2. Baseline

- Inner `SCRFormal/` (Lean 4.19 + Mathlib v4.19.0): committed state did
  NOT build (lakefile targeted non-existent `SCRFormal`/`SCR.lean`;
  `ValidTransition` in `SCR/Transformation.lean` ill-typed). Repaired
  (see §14/H). After repair: **build green, 12 theorems-equivalent
  legacy content intact, no semantic changes to legacy modules.**
- Root `formal/` (Lean 4.34, `lake build SCRFormal`): 8882 jobs, green
  before and after this increment.
- Reference Executor / Mojo tests: untouched by STC-001 (spec §29
  formal-only increment).

## 3. SMM → STC Crosswalk

Full table: `crosswalk.md` (this directory). Decisions used:
REUSE / DERIVE / REFINE / GAP / REJECT per spec §5.
Headline: Transition = derived tuple (no new type); Outcome =
REFINE (new relational class, the tuple lacked O-semantics);
Equivalence = REFINE (context-indexed); Composition = GAP→refinement
`ResultState`; Independence = GAP→refinement `Footprint`+`Overlap`.

## 4. Existing Ontology Reuse

- `SCR.State`, `SCR.Entity`, `SCR.Relationship`, `SCR.Context`,
  `SCR.Transformation` remain the concrete instantiation domains;
  STC is a type-parametric calculus OVER them — no parallel ontology
  (spec §4 respected: no second State/Transition/Equivalence types).
- Composition of `SCR.Transformation`-style function machines is the
  DETERMINISTIC SPECIAL CASE of relational composition (not deleted —
  correct for its use: `tryEvolve` semantics).
- CX-EQV's states ARE `SCR.State` values — the counterexample is
  expressed entirely in the old ontology, per spec §5.

## 5. Genuine Semantic Gaps

| Gap | Why existing ontology insufficient | Counterexample | Candidate solutions | Selected | Reason |
|---|---|---|---|---|---|
| G1 `ResultState` | outcomes carry no state; composition ill-typed otherwise | CX-RESULT (`Res` namespace: two legal result structures, identical kernel data) | (a) functionalize M; (b) make outcomes pairs (o,s'); (c) relation `result` | (c) | keeps M(δ)⊆O intact; (b) re-introduces functional bias; multi-valued = multiple realizations |
| G3 `Footprint`+`Overlap` | independence not a function of outcome data | CX-IND (`IND` vs `Pair`: same outcome shape, opposite commutation) | (a) define ⊥ via outcome equality; (b) footprint relation | (b) | (a) refuted by CX-IND |
| G4 state-≡ + congruences | `Equiv.equiv c s₂ s₂'` for STATES does not typecheck | STCLaws OPEN O-2 analysis | (a) assumption class conjoining conclusion; (b) setoid/congruence package | (b), deferred to STC-002 | (a) = conclusion laundering (spec §32) |
| G0 outcome as kernel member | committed Lean had no outcome semantics at all | CX-NDet | Option State vs relation | relation | docs/106 §10 hypothesis CONFIRMED |

## 6. Counterexamples

See §5. Formally verified statements:
- `committed_equivalence_is_equality`, `cxeqv_ne`, `cxeqv_same_content`
- `ndet_outcomes`, `ndet_no_single_valued_realization`
- `outcomes_identical`, `composition_diverges`
- `each_deterministic`, `ind_not_commute_at_three`
Positive witnesses (assumption checks): `Counter.applicable_not_admissible`,
`Counter.dbl_not_applicable`, `Counter.rejected_has_no_outcome`,
`Div.div_zero_is_semantic_failure`, `Choice.toss_nondeterministic`,
`Loop.run_partial`, `Pair.independent_witness`, `Pair.pair_commutes`,
`Counter.compose_refused_odd_middle`, `Counter.compose_success`,
abstract: `admissible_imp_applicable`, `rejected_no_outcome`,
`rejected_not_partial`, `nondeterministic_not_deterministic`,
`deterministic_of_empty`, `rejected_compose_none`, `compose_exists`,
`nondet_witness_distinguish`, `singleton_outcomes_of_subsingleton`.

## 7. STC Formal Model

Kernel classes: `Applicable`, `Consents`, `OutcomeOf` (O as `outParam`),
`Equiv` (O as `outParam`), `IsFailure`, `OutcomeAdmissible` (machine
law: outcomes ⇒ admissible), `EquivLaws` (setoid witness structure),
`ResultState` (G1), `Footprint`/`Overlap` (G3), `FootprintsSound`
(machine commutation law, STC-002 to discharge generally).
Derived: `Transition := T × S × C × K` (tuple — NO new primitive),
`admissible`, `rejected`, `outcomes`, `deterministic`,
`nondeterministic`, `partialTransition`, `composeOutcome`,
`independent`, `probeDistinction` (observation from kernel only).

## 8. Proven Laws

PROVEN (structural, all machines): `admissible_imp_applicable`
(⇒ is definition-projection; conjunct independence shown in
`Counter`); `rejected_no_outcome` (from machine law);
`rejected_not_partial`; `nondeterministic_not_deterministic`;
`deterministic_of_empty` (+ its recorded WARNING: determinism alone
never certifies existence); `compose_exists`;
`rejected_compose_none`; `nondet_witness_distinguish`;
`singleton_outcomes_of_subsingleton`.
ASSUMED (explicit machine-law classes): `OutcomeAdmissible`
(discharge PROVEN for all five example machines); `EquivLaws`
(witness for Counter; assumed setoid behavior); `FootprintsSound`
(proven FOR Pair via `pair_commutes`; general form OPEN O-1).
CONJECTURED: G4 congruence package (STC-002).
UNPROVABLE without additional assumptions: composition-determinism
(GAP G4 — analysis in STCLaws.lean).

## 9. Unresolved Questions

- O-1: general commutation theorem needs composed-outcome equivalence
  (pair ≡) — structure to define in STC-002.
- O-2/G4: state-level ≡ + congruence of {applicable, consents,
  outcomeOf, result} — the STC-002 increment.
- O-3: causality (docs/107 §13) and temporal relations (§14) — not
  yet attempted; no blocker found (they are relational over derived
  transitions, expected expressible).
- O-4: identity obligations across transitions (docs/107 §16) —
  `SCR.Identity` compatible; no formal statement produced yet.
- docs/106 §30 items 1,2,4,7,8,9,10: PARTIALLY answered (state vs
  semantic state: §5 of STC — implementation state ⊋ projection,
  preserved; context: reuse confirmed, one-point vs multi-point
  contexts both legal; atomicity: definable as outcome-set
  condition — not formalized; observation: PRIMITIVE NO, probe-
  derived; computational-field criterion: unchanged).

## 10. Reference Executor

Position fixed per spec §20: RE = one conforming witness
(`RE ⊨ SMM` is now a well-typed statement once G4 lands), NOT the
source of semantics. The Counter machine here is the Lean mirror of
the golden-path witness; `Counter.compose_success` reproduces the
canonical pipeline step in STC terms (spec §27 exit criterion
"existing SCR witness described in STC terms" — partially met:
transformation application covered; multi-entity/provenance legs of
the witness not yet re-expressed). RE was NOT used as ontology
justification anywhere in this increment.

## 11. Representation Independence

Evidence: machines are abstract over S/C/T/K/O; two DIFFERENT
`ResultState` structures over identical kernel data (`rRes1`/`rRes2`)
are both well-formed — representation/realization choices live
OUTSIDE the semantic kernel, as required. CX-NDet/CX-EQV show the
kernel does not secretly commit to value-equality or functional
execution. Full provider-substitution theorem is downstream (EGS
layers; spec §43 trajectory).

## 12. Concurrency / Temporal / Causal Semantics

- Independence formalized ONLY via footprint structure after CX-IND
  refuted outcome-only definitions. `Pair.independent_witness` +
  `pair_commutes`: semantic independence, proven commutation — with
  zero scheduler/thread/queue/parallelism vocabulary (spec §15 clean).
- Semantic order ≠ scheduler order: preserved structurally — STC has
  no scheduling object at all (nothing to collapse into).
- Temporal/causal: deferred (§9 O-3).

## 13. Failure and Outcome Semantics

Taxonomy implemented: Rejection = ¬admissible ∧ provably no outcome
(`rejected_no_outcome`, machine-discharged `rejected_has_no_outcome`);
semantic failure = outcome with `IsFailure` (`Div`: admissible ∧
outcome `fail` ∧ failure — row 1 vs row 2 separated by PROOF, not
prose); partiality = admissible ∧ no outcomes (`Loop.run_partial`,
requires `OutcomeAdmissible` one-directionality — confirmed the
correct axiom orientation); realization/physical failure =
INEXPRESSIBLE in kernel (no O-construct, no provider parameter —
firewall holds by construction, spec §11).

## 14. Documentation Changes

- `SCRFormal/SCR/Transformation.lean`: `ValidTransition` signature
  repair (was ill-typed: applied the `Transition` TYPE alias as a
  function). No semantic change.
- `SCRFormal/lakefile.lean` (new) replacing broken `lakefile.toml`
  (non-existent targets). `SCRFormal/SCRFormal.lean`: imports + 4 STC
  modules.
- `SCRFormal/SCR/Basic.lean`: `import Mathlib` → `import Batteries`
  (FACT: zero Mathlib identifiers used in the entire inner project —
  audit `grep Mathlib\.\w` empty). Builds went from >30 min swap-thrash
  to ~1 s; semantically neutral (all modules elaborate unchanged).
- `program_increments/.../002_semantic_machine/crosswalk.md` (new).
- This `report.md` (new).
- Planned with this increment's acceptance: `docs/106_SEMANTIC_MACHINE_
  MODEL.md` §30 status annotation (per spec §36 "formal argument
  established" now satisfied).

## 15. Validation (exact, recorded post-completion)

- `lake update && lake build` (inner SCRFormal, Lean v4.19):
  **"Build completed successfully." — 185/185 jobs** (legacy 9 modules
  + STC, STCLaws, STCExamples, STCCounterexamples + root barrel),
  no-op re-run 1.2 s. Zero `error:` lines.
- `lake build SCRFormal` (root `formal/`, Lean v4.34):
  **"Build completed successfully (8882 jobs)"** — unchanged, 8 s.
- Mojo kernel (47) + Reference Executor (35) + equivalence (15) +
  multi-entity (14) + differential (2): NOT re-run — zero files touched
  under `lib/`, `runtime/`, `formal/` (FACT: `git status` shows changes
  only in `SCRFormal/`, `docs/106`, this milestone dir, and root
  README/docs from the prior documentation increment). Spec §31
  "relevant tests": the relevant suite is the formal one; both formal
  projects are green.
- Axiom audit (`#print axioms` on headline results): all depend only
  on standard `propext`/`Quot.sound` (via `simp`/`omega`), none on
  `Classical.choice`, no custom axioms, zero `sorry`/`admit` in any
  STC file (grep-verified + kernel-checked build).
- Warnings: linter `unusedVariables` infos remain in STC files
  (underscore-prefixed binders).

## 16. Architectural Consequences

1. SMM kernel tuple must be restated as
   ⟨S,C,T,K,O,≡⟩ + {ResultState, Footprint/Overlap} for any
   composition/concurrency claims — executable hypergraph design
   (EGS era) must consume transitions WITH footprints.
2. `Admissible ⇒ Applicable` needs no axiom — safe to keep as
   definitional; constraint violation vs domain refusal are already
   distinct machines facts.
3. Provider/realization/physical failure classes cannot be
   mentioned in kernel types: the firewall survives formalization.
4. STC-002 scope is now precisely defined: setoid/congruence package
   (G4) + general commutation (O-1) + causal/temporal relations.

## 17. Recommended Next Increment

**STC-002 — Lawful Equivalence:** introduce state/transition-level ≡
with the four congruence laws as explicit machine axioms; re-prove
composition-determinism; then discharge `FootprintsSound` generally.
NOT EGS, NOT provider infrastructure (spec §43 sequence unchanged).
