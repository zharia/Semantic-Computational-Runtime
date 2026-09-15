# SDP-001K — Event and History Algebra

**Status:** Conceptual Formalisation  
**Predecessor:** SDP-001J — Context Algebra and Semantic Scope  
**Purpose:** Determine whether Event and History are irreducible kernel primitives and whether State can be reduced to a projection of immutable events and their causal history.

---

## 1. Objective

The current candidate kernel is:

\[
K_4 = (ID,State,Context,Assertion,Transition,Event,History)
\]

The outstanding reduction question is:

\[
State \stackrel{?}{=} Projection(Event,History)
\]

If State can be completely derived from History, then State need not be a primitive.

If it cannot, then State remains fundamental.

The same question must be applied recursively:

\[
Event \stackrel{?}{=} Assertion
\]

\[
History \stackrel{?}{=} Set(Event)
\]

\[
History \stackrel{?}{=} State
\]

The goal is to determine the smallest kernel that preserves all previously established semantics.

## 2. Candidate Architectures

Four models are tested:

### Model A — State Primitive
State + Event + History.

State is canonical and history records change.

### Model B — Event Primitive
Event + History.

State is reconstructed.

### Model C — History Primitive
History.

State and events are projections.

### Model D — Transition Primitive
Transition + History.

Events are accepted occurrences of transitions and State is reconstructed.

These represent different ontological claims about development.

## 3. What Is an Event?

An Event is an immutable historical record of an accepted semantic occurrence.

This deliberately avoids defining an event as a state change.

An event may represent:

- a state change;
- a context change;
- an observation;
- an approval;
- a rejection;
- a discovery;
- a reconciliation;
- a governance action.

Therefore:

\[
Event \not\equiv StateChange
\]

## 4. Event Is Not an Assertion

An event can contain an assertion such as `occurred(E)`, but an assertion does not provide event identity, causal position, or temporal occurrence.

Two identical assertions may correspond to distinct historical events:

\[
E_1 \neq E_2
\]

even where:

\[
Assertion(E_1) = Assertion(E_2)
\]

Therefore:

\[
Assertion \neq Event
\]

## 5. Event Is Not a Transition

A transition describes a permissible transformation; an event describes an actual historical occurrence.

A transition may be possible without occurring.

Therefore:

\[
Transition \neq Event
\]

This preserves the distinction:

\[
Specification \neq Execution
\]

## 6. Event Identity and Idempotence

Every event has immutable identity:

\[
ID(E)
\]

Two semantically equivalent events may remain historically distinct:

\[
E_1 \approx E_2
\land
ID(E_1)\neq ID(E_2)
\]

A retried submission of the same event must retain the same identity. Legitimate separate occurrences require distinct identities.

Thus event identity is required for idempotent processing and auditability.

## 7. Event Content

Conceptually:

\[
E=(id,actor,before,after,transition,context,effect,evidence,causalParents,time,status)
\]

Not every implementation must physically store every field, but the semantic model must be capable of representing:

1. what happened;
2. to what;
3. under what context;
4. who caused it;
5. what transformation occurred;
6. what evidence supports it;
7. what caused it;
8. its historical status.

## 8. Observed and Accepted Events

An event may be observed without being accepted:

\[
Observed(E) \land \neg Accepted(E)
\]

An observed event may later become accepted or rejected.

The original observation must remain.

Therefore:

> Historical invalidity does not imply historical deletion.

Rejected, unauthorised, contradicted, superseded, or erroneous events remain representable historical facts about the protocol record.

## 9. Can History Be a Set of Events?

No.

A set:

\[
\{E_1,E_2,E_3\}
\]

does not encode causality.

Therefore:

\[
History \neq Set(Event)
\]

## 10. Can History Be a Sequence?

A sequence supplies total ordering but imposes order on independent events:

\[
E_1 \parallel E_2
\]

may have no causal relationship.

Therefore a sequence is an implementation projection, not the general semantic model:

\[
History \neq List(Event)
\]

## 11. History as Causal Structure

The minimum credible semantic model is:

\[
H=(E,\prec)
\]

where \(\prec\) is causal precedence.

Required properties:

- irreflexive;
- transitive;
- asymmetric.

This yields a causal DAG / partial-order history.

Other relations such as semantic dependency, observation, derivation, authorisation, and contradiction must not automatically be conflated with causal precedence.

## 12. Branching and Merging

If:

\[
E_0\rightarrow E_1
\]

and:

\[
E_0\rightarrow E_2
\]

history naturally represents alternative development paths.

No Branch primitive is required.

Likewise a merge can be represented by an event with multiple causal parents:

\[
Parents(E_m)=\{E_1,E_2\}
\]

Thus:

\[
Branch \subseteq History
\]

and:

\[
Merge \subseteq Event
\]

as derived concepts.

## 13. Can History Be State?

No.

Current state answers:

> What is the system now?

History answers:

> How did the system arrive here?

They differ in identity, mutation, and projection semantics.

Therefore:

\[
CurrentState \neq History
\]

## 14. State as a Projection of History

A stronger formulation is:

\[
CanonicalState = \Pi_S(CanonicalHistory,Context)
\]

Given a genesis state/event and sufficient event effects, state can be reconstructed.

This does not require historical side effects to be repeated.

Replay means deterministic semantic reconstruction, not re-execution of external effects.

## 15. Genesis

Complete reconstruction requires an initial semantic baseline.

The preferred model is a genesis event:

\[
E_0
\]

such that:

\[
Replay(\{E_0\})=S_0
\]

Genesis provenance may derive from:

- human declaration;
- imported repository;
- observed external system;
- previous protocol;
- extraction;
- fork;
- migration;
- formal construction.

Genesis is therefore not epistemically privileged; it establishes SDP's recognised baseline.

## 16. External and Unrecorded State

External changes may cause:

\[
Replay(H)\neq ObservedState
\]

This is not a contradiction. It represents semantic drift.

Define conceptually:

\[
CanonicalState(H)=Replay(H)
\]

and:

\[
ObservedState(O)
\]

Reconciliation asks whether:

\[
CanonicalState(H)\approx ObservedState(O)
\]

If not, the discrepancy must remain visible until reconciled.

## 17. Semantic Drift

Semantic drift may result from:

- external change;
- incomplete history;
- failed event recording;
- nondeterministic execution;
- corrupted state;
- stale projections;
- observation error.

Drift is therefore a first-class reconciliation condition, not an error to be silently hidden.

## 18. Event Effect

Every event has two conceptually distinct aspects:

\[
Occurrence(E)
\]

and:

\[
Effect(E)
\]

An event may occur while its accepted semantic effect is identity:

\[
Effect(E)=Identity
\]

Examples include rejected deployments, failed gates, observations, and unauthorised attempts.

Therefore event occurrence must not be equated with state mutation.

## 19. Can Transition Be Eliminated?

No.

A transition describes permissible transformations independently of their occurrence.

Many events may instantiate the same transition.

Therefore:

\[
Transition \neq Event
\]

Transition remains conceptually necessary.

## 20. Can Event Be Eliminated?

No.

If we replace an event with:

\[
(T,s,s',C)
\]

plus actor, time, evidence, identity, causality, and acceptance, we have merely reconstructed the Event abstraction.

Therefore:

> Event is irreducible.

## 21. Can History Be Eliminated?

No.

Current state cannot reconstruct causality, rejected events, alternative paths, or historical context.

A set of events cannot reconstruct causality without adding a causal relation.

Therefore:

> History is irreducible as a semantic concept.

## 22. State as a Semantic Projection Domain

State need not be a canonical source of truth.

The stronger result is:

> State is a semantic projection domain.

Conceptually:

\[
State_t=\Pi_S(H_{\leq t},C)
\]

This means State remains an important mathematical domain while becoming a derived canonical projection.

## 23. Canonical History

Not every recorded event is necessarily accepted.

Distinguish:

### Observed History
Everything recorded as possibly having occurred.

### Accepted History
Events recognised by governance.

### Canonical History
The causally coherent, authoritative history from which canonical semantic state is projected.

Canonicality is itself contextual and governed; it must not be confused with objective reality.

## 24. History Does Not Equal Reality

History records what SDP recognises as semantic occurrence.

It does not establish objective reality.

Therefore:

\[
HistoricalRecord \neq Reality
\]

The epistemic chain remains:

\[
Reality
\rightarrow Observation
\rightarrow Evidence
\rightarrow Assertion
\rightarrow GovernedHistory
\]

This preserves the distinction between occurrence, evidence, and truth.

## 25. Contextual Replay

Events must be interpreted under their historical context:

\[
E_i \text{ occurred under } C_i
\]

not automatically under current context \(C_{now}\).

Conceptually:

\[
s_0
\xrightarrow{E_1,C_1}
s_1
\xrightarrow{E_2,C_2}
s_2
\]

Historical validity must therefore not be retroactively rewritten merely because present context has changed.

## 26. Event Commutation

Independent events may commute:

\[
E_1E_2 \approx E_2E_1
\]

but only where semantic independence is established.

In general:

\[
E_1E_2 \neq E_2E_1
\]

Thus event history must preserve causal constraints without imposing artificial total order.

Temporal order and causal order are distinct:

\[
time(E_1)<time(E_2)
\not\Rightarrow
E_1\prec E_2
\]

## 27. History Validity

A history is valid only when required historical invariants hold, including:

1. event identities are unique;
2. causal relations are acyclic;
3. referenced events exist;
4. required contexts resolve;
5. event transition relations hold;
6. applicable authority constraints hold;
7. effects are semantically coherent;
8. required evidence references resolve;
9. replay does not encounter an impossible semantic state;
10. applicable governance constraints hold.

Invalid histories remain representable:

\[
ValidHistory(H)=False
\]

must not imply deletion.

## 28. History, Extraction, Fork, and Transfer

These operations can be derived from the same event/history machinery.

### Extraction
Preserves project identity and relevant historical lineage while changing persistence topology.

### Fork
Creates a new semantic identity with ancestry:

\[
Lineage(H_2,H_1)
\]

### Transfer
Preserves identity/history while changing governance context.

### Bootstrap/Adoption
Establish the initial semantic baseline through genesis/adoption events.

Thus these operations need not become kernel primitives.

## 29. Event-Centric Development

The emerging model is:

\[
ObservedEvents
\rightarrow
GovernedHistory
\rightarrow
CanonicalHistory
\rightarrow
StateProjection
\]

with Context controlling interpretation.

This is broader than ordinary event sourcing because SDP governs semantic development history rather than merely reconstructing application state.

## 30. Kernel Reduction

Candidate results:

| Question | Result |
|---|---|
| Event = Assertion? | Rejected |
| Event = Transition? | Rejected |
| History = Set(Event)? | Rejected |
| History = Sequence(Event)? | Rejected as general model |
| History = Causal event structure? | Accepted provisionally |
| State = History? | Rejected |
| State = Projection(History)? | Accepted provisionally |
| Event irreducible? | Yes, provisionally |
| History irreducible? | Yes, provisionally |
| State kernel primitive? | No, provisionally |
| Genesis event required for complete histories? | Yes |
| Bootstrap special primitive? | No |
| Adoption special primitive? | No |
| Extraction special primitive? | No |
| Fork special primitive? | No |
| Transfer special primitive? | No |

## 31. Candidate K₅

The strongest current kernel candidate is:

\[
\boxed{
K_5=(Identity,Context,Assertion,Transition,Event,History)
}
\]

with State treated as a semantic projection domain:

\[
State=\Pi_S(History,Context)
\]

and higher-level constructs derived above the kernel:

- Invariant;
- Authority;
- Gate;
- Evidence;
- Knowledge;
- Work;
- Agent;
- Project;
- Repository;
- Requirement;
- Specification;
- Milestone;
- Sprint;
- Kanban;
- Report;
- Release;
- Branch;
- Fork;
- Extraction.

## 32. The Stronger Hypothesis

There is now a deeper unresolved possibility:

\[
Context_t=\Pi_C(H_{\leq t})
\]

If Context can also be reconstructed from history, then State and Context may both be projections of one semantic historical substrate:

\[
Situation_t=
(\Pi_S(H_{\leq t}),\Pi_C(H_{\leq t}))
\]

More generally:

\[
SemanticWorld_t=\Pi(H_{\leq t})
\]

where different projections yield State, Context, Knowledge, Governance, Evidence, Work, Project, and other derived structures.

This must **not** yet be accepted.

## 33. Adversarial Next Stage — SDP-001L

The next stage must determine:

1. Can Context itself be reconstructed from history?
2. Can governance state be reconstructed from history?
3. Can knowledge state be reconstructed from history?
4. Can project identity be reconstructed from history?
5. Can authority be reconstructed from history?
6. Can invariant regimes be reconstructed from history?
7. Can evidence be represented as historical events without losing its distinction from events?
8. Can observational reality be incorporated without confusing observation with occurrence?
9. Can canonicality itself be a history projection?
10. Can contradictory histories coexist?
11. Can alternative histories be represented without a Branch primitive?
12. Can history be self-describing?
13. Can history reconstruct its own interpretation without circularity?
14. Can the resulting structure be represented in Lean without an enormous inductive universe?
15. What is the minimal genesis axiom?
16. What prevents arbitrary histories from becoming canonical?
17. Is there a fixed point between history and semantic interpretation?
18. Is SDP fundamentally a state machine, event system, graph, or higher-order semantic calculus?
19. Can the kernel be reduced further to:

\[
Identity + Event + CausalStructure + Interpretation
\]

Only after these questions are answered should the Lean kernel be frozen.

## 34. Provisional Fundamental Definition

> **SDP is a formal protocol for the governed production, interpretation, and preservation of semantic history. Canonical development state is a contextual projection of that history.**

This formulation supersedes the weaker interpretation of SDP as merely a controlled state-transition process, pending adversarial validation in SDP-001L.
