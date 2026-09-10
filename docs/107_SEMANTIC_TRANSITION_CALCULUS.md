# Semantic Transition Calculus (STC)

**Document ID:** SCR-DOC-STC-107  
**Status:** Normative architectural draft  
**Version:** 0.1.0  
**Purpose:** Formal calculus for the Semantic Machine Model.

---

## 1. Purpose

The Semantic Transition Calculus (STC) gives operationally precise rules to the Semantic Machine Model without turning the model into a runtime component architecture.

The STC is the next formal artifact to implement in Lean.

The kernel is:

\[
\boxed{
STC=\langle S,C,T,K,O,\equiv\rangle
}
\]

The calculus must express:

- applicability;
- admissibility;
- instantiation;
- transition;
- outcome;
- composition;
- failure;
- concurrency;
- causality;
- temporal ordering;
- atomicity;
- equivalence.

---

## 2. Judgements

The calculus uses the following conceptual judgements.

### Applicability

\[
S,C\vdash \tau\;applicable
\]

### Constraint admissibility

\[
S,C,K\vdash \tau\;admissible
\]

### Transition instantiation

\[
S,C,K\vdash \tau\Downarrow\delta
\]

### Outcome

\[
\delta\Downarrow o
\]

### Semantic equivalence

\[
x\equiv_C y
\]

### Independence

\[
\delta_1\perp_C\delta_2
\]

### Causal precedence

\[
\delta_1\prec_C\delta_2
\]

These are semantic relations, not implementation events.

---

## 3. Applicability

A transformation can only be instantiated where its semantic domain permits it.

\[
\frac{
S,C\vdash\tau\;applicable
}{
S,C\vdash\tau\;candidate
}
\]

Applicability is not capability availability.

An implementation may be unable to realize an applicable transformation.

---

## 4. Admissibility

Constraints determine whether an applicable transformation is lawful:

\[
\frac{
S,C\vdash\tau\;applicable
\qquad
K(S,C,\tau)
}{
S,C,K\vdash\tau\;admissible
}
\]

No implementation detail belongs in \(K\) unless the physical detail has explicitly been elevated into semantic meaning by the field.

---

## 5. Instantiation

An admissible transformation produces a semantic transition instance:

\[
\frac{
S,C\vdash\tau\;applicable
\qquad
S,C,K\vdash\tau\;admissible
}{
S,C,K\vdash\tau\Downarrow\delta
}
\]

A transition instance records enough semantic information to determine its permitted outcomes and observation obligations.

It does not prescribe a physical execution plan.

---

## 6. Outcome Relation

The transition semantics are relational:

\[
\boxed{
M(\delta)\subseteq O
}
\]

and:

\[
\delta\Downarrow o
\iff
o\in M(\delta)
\]

This deliberately supports non-function semantics.

### Determinism

\[
\forall o_1,o_2\in M(\delta):
o_1\equiv o_2
\]

### Nondeterminism

There exist distinguishable outcomes:

\[
\exists o_1,o_2\in M(\delta):
o_1\not\equiv o_2
\]

### Stochastic semantics

A transition may associate outcomes with a probability model, but probability is only semantically relevant when the field defines it as observable or constrained.

---

## 7. Failure

The calculus must distinguish at least:

```text
Reject
Failure
Indeterminate
Partial
Success
```

A realization error is not automatically a semantic failure.

Suggested outcome structure:

\[
Outcome =
Success(S')
\mid
Failure(f,S')
\mid
Partial(S',r)
\mid
Indeterminate(r)
\mid
Rejected(r)
\]

The exact Lean datatype must be derived during formalization rather than assumed from this notation.

---

## 8. State Transition

For an outcome carrying a resulting semantic state:

\[
\delta:S\rightarrow O(S')
\]

is shorthand only.

The authoritative model remains relational:

\[
M(\delta)\subseteq O
\]

A successful transition may be represented as:

\[
\delta:S\leadsto S'
\]

but only as derived notation.

---

## 9. Composition

Two transitions may compose when the output semantics of the first satisfy the applicability requirements of the second.

\[
\frac{
\delta_1:S\leadsto S'
\qquad
\delta_2:S'\leadsto S''
}{
\delta_2\circ\delta_1:S\leadsto S''
}
\]

Composition must preserve:

- context;
- constraints;
- provenance;
- identity obligations;
- temporal relations;
- observation semantics.

Composition must not imply physical adjacency.

---

## 10. Conditional Composition

A graph may express a transition whose applicability depends on an observed outcome.

Conceptually:

\[
\delta_1;
\begin{cases}
\delta_2 & \text{if }P(o_1)\\
\delta_3 & \text{otherwise}
\end{cases}
\]

This is semantic branching.

It need not become a conventional control-flow instruction.

---

## 11. Parallel / Independent Composition

If:

\[
\delta_1\perp_C\delta_2
\]

then their semantic composition may be unordered:

\[
\delta_1\parallel\delta_2
\]

Physical execution may nevertheless be:

- sequential;
- parallel;
- distributed;
- speculative;
- fused;
- cached.

Correctness is determined by semantic observation.

---

## 12. Conflict

Independence must be established semantically.

Two transitions conflict if their composition can change an observable semantic result due to an ordering dependency.

Conceptually:

\[
Conflict_C(\delta_1,\delta_2)
\]

If conflict exists, the model must expose the required ordering or coordination constraint.

The calculus must not infer independence merely because two transitions use different physical resources.

---

## 13. Causality

Causality is a semantic relation:

\[
\delta_1\prec_C\delta_2
\]

meaning that the semantic existence or outcome of \(\delta_2\) depends on \(\delta_1\).

Physical message delivery, thread execution, CPU ordering, or network topology are possible realizations of causality, not its definition.

---

## 14. Temporal Semantics

The calculus must support semantic temporal relations such as:

- before;
- after;
- simultaneous;
- during;
- duration;
- deadline;
- periodicity;
- temporal window.

Physical wall-clock time must not be conflated with semantic time.

Where time is not semantically observable, implementations may use different physical schedules.

Where time is semantically observable, it enters the observation/equivalence contract.

---

## 15. Atomicity

Atomicity is a semantic constraint:

\[
Atomic(\delta,C)
\]

meaning that the transition's required observation boundary does not expose prohibited intermediate semantic states.

Atomicity is not a physical primitive.

---

## 16. Identity Preservation

A transformation may preserve, refine, replace, split, merge, or otherwise alter semantic identities.

The calculus must record identity obligations where required.

A physically copied object does not necessarily acquire a new semantic identity.

A physically moved object does not necessarily change semantic identity.

A representation change does not by itself change semantic identity.

---

## 17. Provenance

Every transformation capable of changing semantically relevant state should admit provenance.

A derived transition may preserve:

\[
Provenance(\delta)
\]

and composition should preserve or explicitly transform provenance.

Provenance is semantic when it is part of the field's meaning; otherwise it remains metadata.

---

## 18. Observation

Let:

\[
Obs_C(x)
\]

be the observation of semantic object \(x\) under context \(C\).

Two outcomes are observationally equivalent when:

\[
Obs_C(o_1)=Obs_C(o_2)
\]

or, more generally:

\[
Obs_C(o_1)\equiv Obs_C(o_2)
\]

Implementation equivalence is therefore not byte equivalence.

---

## 19. Realization

A semantic transition is realizable only if an implementation provides the necessary capabilities.

\[
Requires(\delta,c)
\]

and:

\[
Provides(I,c)
\]

are distinct predicates.

Thus:

\[
Valid(\delta)\not\Rightarrow Realizable(I,\delta)
\]

and:

\[
Realizable(I,\delta)\not\Rightarrow PhysicalSuccess(I,\delta)
\]

This is a critical separation.

---

## 20. Conformance

An implementation \(I\) conforms when every required observable semantic behaviour is preserved.

A simplified statement is:

\[
I\models_C SMM
\]

iff for each required semantic transition:

\[
Obs_C(I(\delta))
\equiv
Obs_C(M(\delta))
\]

subject to the implementation's declared realization capabilities.

The final formal definition must be made precise in Lean.

---

## 21. Reference Executor

The Reference Executor is one implementation:

\[
RE\models SMM
\]

It is valuable because it provides an executable witness.

The calculus does not make it ontologically privileged.

---

## 22. Representation

A representation function may be introduced:

\[
\rho:S\rightarrow R
\]

where \(R\) is a representation domain.

Representation preservation requires:

\[
\rho^{-1}(r)\equiv S
\]

where meaningful, but the semantic state remains authoritative.

MLIR is therefore a representation/lowering mechanism, not a semantic domain.

---

## 23. Physical Manifestation

A realization function may be conceptualized as:

\[
\mu:(\delta,P)\rightarrow PhysicalExecution
\]

where \(P\) is a selected provider/capability realization.

Correctness requires:

\[
\mu(\delta,P)\models\delta
\]

The exact physical mechanism is unconstrained by STC.

---

## 24. Key Inference Rules

The implementation should eventually formalize rules corresponding to:

### Applicability

\[
\frac{}{S,C\vdash\tau\;applicable}
\]

when transformation preconditions hold.

### Admissibility

\[
\frac{
S,C\vdash\tau\;applicable
\quad
K(S,C,\tau)
}{
S,C,K\vdash\tau\;admissible
}
\]

### Instantiation

\[
\frac{
S,C,K\vdash\tau\;admissible
}{
S,C,K\vdash\tau\Downarrow\delta
}
\]

### Outcome

\[
\frac{
\delta\Downarrow o
}{
o\in M(\delta)
}
\]

### Composition

\[
\frac{
\delta_1:S\leadsto S'
\quad
\delta_2:S'\leadsto S''
}{
\delta_2\circ\delta_1:S\leadsto S''
}
\]

### Equivalence

\[
\frac{
Obs_C(x)\equiv Obs_C(y)
}{
x\equiv_C y
}
\]

These are intentionally skeletal. Lean formalization must expose any hidden assumptions rather than bury them in notation.

---

## 25. Formalization Requirement

The Lean implementation must not simply encode the proposed tuple as a collection of structures.

It must test whether the tuple is sufficient.

If a required semantic law cannot be expressed without adding a new primitive, record the counterexample and justify the new primitive.

This is the falsification criterion for SMM.

---

## 26. Required Lean Work

The next formal increment should include:

1. semantic state;
2. context;
3. transformation;
4. constraint;
5. outcome;
6. applicability;
7. admissibility;
8. transition instantiation;
9. observation;
10. equivalence;
11. composition;
12. independence;
13. causality;
14. temporal relation;
15. atomicity;
16. realization/conformance boundary.

No provider, scheduler, storage, processor, or EGS ontology should be introduced into the SMM kernel.

---

## 27. Exit Criteria

STC is complete enough for SMM promotion when:

- the core relations are formally defined;
- deterministic behaviour is expressible;
- nondeterministic behaviour is expressible;
- semantic rejection is distinct from realization failure;
- composition is defined;
- independence/conflict is defined;
- temporal and causal ordering are distinguishable;
- observation/equivalence are defined;
- identity obligations can be expressed;
- the Reference Executor can be characterized as a conforming realization;
- at least one existing SCR witness can be described entirely in STC terms.

---

## 28. Anti-Expansion Rule

Do not add an SMM primitive merely because an implementation has a component with the same name.

The existence of a:

- scheduler,
- processor,
- executor,
- memory,
- storage layer,
- message bus,
- namespace,
- process,
- thread,
- cache,
- device,

does not establish that the concept belongs in SMM.

A primitive requires a semantic necessity, demonstrated by a counterexample against the existing calculus.

---

## 29. STC-001 Status Against §27 Exit Criteria

Formalization (Lean, `SCRFormal/SCR/STC{,Laws,Examples,Counterexamples}.lean`, milestone `002_semantic_machine`):

| §27 criterion | Status | Evidence |
|---|---|---|
| Core relations formally defined | MET | kernel classes, `STC.lean` |
| Deterministic behaviour expressible | MET | `Counter.inc_deterministic` |
| Nondeterministic behaviour expressible | MET | `Choice.toss_nondeterministic`; functional alias refuted (`CX-NDet`) |
| Semantic rejection distinct from realization failure | MET | `Prov.realization_down_is_partial_not_rejected` (realization failure enters only as context-elevated partiality); rejection≠semantic-failure: `Div.div_zero_is_semantic_failure` + `rejected_no_outcome` |
| Composition defined | MET | `composeOutcome` over `ResultState` (G1 refinement); laws `compose_exists`, `rejected_compose_none`; witness composition `Witness.step4_compose` |
| Independence/conflict defined | MET | `Footprint`/`Overlap` (G3 refinement); `Pair` independence+commutation; conflict witness `IFO` (order-sensitive, 8 ≠ 7) |
| Temporal and causal ordering distinguishable | MET (minimal) | `causallyDependent` = footprint overlap (recorded as falsifiable hypothesis); temporal-without-causal: `Pair`; causal-and-order-sensitive: `IFO` |
| Observation/equivalence defined | MET | probe-derived state observation `probeDistinction` + `Probe` machine both directions; context-indexed `Equiv` (`EquivLaws`), `CX-EQV` refutes equality |
| Identity obligations expressible | MET | `Witness.step6_identity` via `SCR.SameIdentity` across transitions |
| Reference Executor as conforming realization | MET | `Laws.Oracle`: `Realization ρ`; tryEvolve-shape proven a realization; RE remains evidence, not authority |
| Existing SCR witness described entirely in STC terms | MET | `Examples.Witness` reproduces the multi-entity golden path over the committed `SCR.State` ontology |

Open items retained for STC-002 (§28 anti-expansion unchanged): G4
state/transition-level equivalence + congruences (composition
determinism, recorded as unprovable-from-kernel with the exact
missing structure, not laundered); general commutation law for
arbitrary `FootprintsSound` machines (O-1); richer causality beyond
the overlap hypothesis. Kernel additions remain relation-level:
`ResultState`, `Footprint`, `Overlap`, `causallyDependent` — no new
carriers, no runtime ontology (spec §41 respected: zero
scheduler/provider/storage constructs).

---

## 30. Graph-Relational Refinement Status (pre-STC-002 gate)

The graph-relational hypothesis — semantic computation as a typed
graph relation `I --τ--> O`, `R_τ ⊆ I_τ × O_τ` — was tested
counterexample-by-counterexample in
`SCRFormal/SCR/STCGraphCounterexamples.lean` and reported in
`docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`.

Outcome: the hypothesis SURVIVES as the transition carrier (typed,
labelled, relational consequences); `OutcomeOf` and `ResultState`
are DEMOTED to projections of the edge (retained in `SCR.STC` for
compatibility, not re-promoted); `causallyDependent :=
¬independent` is REJECTED in favour of an open, edge-only
order-sensitivity candidate; consents/applicability are reused
UNCHANGED (irreducible per CX-GRAPH-007).

The kernel of this document (§3–§28) is NOT silently redefined: the
demotion/rejection decisions stand provisionally until STC-002
establishes equivalence/congruence, the causal definition, the
Delta mapping, and the golden-path re-derivation over the graph
carrier.

**STC-002 gate: RELEASED.** The gate clauses were discharged in
`SCRFormal/SCR/STCGraphLaws.lean` /
`STCGraphMigration.lean` (evidence table: `docs/112`, "Gate Closure"
part): composition determinism proven (closing old G4/O-2), the
causality decision made with three machine-checked separations, the
Delta mapping resolved per `101_Core` §23, and the golden path
re-derived over the graph carrier. Two items continue INSIDE STC-002:
continuation-congruence (open — no padded class exists) and the
hyperedge endpoint bridge.

---

## 31. Kernel Adoption

Per docs/106 §32 the calculus is stated on the adopted `GMKernel`:
typed labelled edge carrier, reused admissibility, derived
continuation congruence (`STCGraphCongruence`), structural
associativity, data-flow causal dependence. The §3–§24 material
remains the historical development and its falsification record;
`OutcomeOf`/`ResultState`-style judgements continue to compile as
deprecated compatibility forms.
