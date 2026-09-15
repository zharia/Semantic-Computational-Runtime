# SDP-001K — Agent Integration Instructions

## Objective

Integrate the supplied **SDP-001K — Event and History Algebra** specification into the repository as a conceptual/formalisation milestone.

**Do not implement the SDP runtime, schemas, CLI, Lean kernel, or production code as part of this task.**

The purpose of this milestone is to establish whether the Event/History model is sufficiently sound to become part of the formal SDP foundation.

---

## 1. First: Inspect Before Modifying

Before making changes:

1. Inspect the existing SDP documentation/specification hierarchy.
2. Locate the existing SDP-001 through SDP-001J material.
3. Determine the repository's established naming, numbering, metadata, and document conventions.
4. Determine whether SDP-001K already exists in any form.
5. Identify references to:

   * State
   * Context
   * Assertion
   * Transition
   * Event
   * History
   * Branch
   * Merge
   * Bootstrap
   * Adoption
   * Extraction
   * Fork
   * Transfer
   * Replay
   * Canonical state
6. Check whether existing specifications conflict with the SDP-001K formulation.

Do not blindly copy the supplied document into the repository.

---

## 2. Integrate SDP-001K

Add the supplied:

`SDP-001K_event_and_history_algebra.md`

to the appropriate specification/documentation location.

Preserve the document's conceptual status.

Do not silently rewrite its conclusions.

If repository conventions require formatting or metadata changes, make only mechanical/conventional changes.

---

## 3. Perform a Semantic Consistency Review

Compare SDP-001K against SDP-001A through SDP-001J.

Look specifically for contradictions involving:

### State

SDP-001K provisionally changes the interpretation of State from:

> canonical semantic source of truth

toward:

> semantic projection domain derived from canonical history.

Identify every earlier statement that must consequently be revised.

### Context

SDP-001K retains Context as a candidate semantic dimension but explicitly opens the question of whether Context itself can eventually be reconstructed from History.

Do not prematurely resolve this question.

### Event

Verify that Event remains distinct from:

* Assertion
* Transition
* Evidence
* Observation
* State change
* Execution
* Governance decision.

### History

Verify that History is represented as causal structure rather than:

* a simple set;
* a total sequence;
* a Git history analogue.

### Branches

Verify that branches can be represented as causal alternatives without requiring Branch to become a kernel primitive.

### Merge

Verify that merge can be represented as an event with multiple causal parents.

### Genesis

Verify that bootstrap/adoption/import/extraction/fork semantics can be represented consistently through genesis or related events.

---

## 4. Do Not Freeze K₅ Yet

The current candidate is:

`K5 = Identity + Context + Assertion + Transition + Event + History`

with State treated provisionally as a projection domain.

This is **not yet a frozen kernel**.

Do not create a normative machine-readable schema claiming that K₅ is final.

Do not create Lean definitions representing K₅ as final unless explicitly requested as an experimental countermodel.

---

## 5. Identify Required Corrections

Produce a review identifying:

1. contradictions with earlier SDP specifications;
2. terminology that is now obsolete;
3. definitions that require updating;
4. invariants that require restatement;
5. assumptions that have become questionable;
6. concepts that should be promoted from implementation concepts to semantic concepts;
7. concepts that should be demoted from kernel primitives to derived projections.

Do not resolve philosophical/formal questions merely by choosing the easiest implementation.

---

## 6. Validate the Event/History Model Adversarially

Construct countermodels for at least:

* two identical events occurring at different times;
* event retry/idempotence;
* rejected event;
* unauthorised event;
* observed but unaccepted event;
* event with no state effect;
* context-only event;
* governance-only event;
* concurrent independent events;
* non-commuting events;
* branching history;
* merging history;
* contradictory observations;
* external unrecorded state changes;
* incomplete event history;
* nondeterministic external effects;
* historical context differing from current context;
* changed invariant regime;
* project extraction;
* project fork;
* project transfer;
* repository adoption;
* repository bootstrap;
* invalid history;
* historical events later determined to be erroneous.

For each countermodel determine whether the current model represents it without introducing an ad-hoc exception.

---

## 7. Investigate Replay

Determine exactly what:

`Replay(H)`

means.

It must **not** mean blindly re-executing historical side effects.

Determine whether replay means semantic reconstruction from recorded effects.

Identify what information an event must contain for deterministic reconstruction.

Explicitly identify cases where replay is impossible.

Do not solve this by silently assuming deterministic external systems.

---

## 8. Investigate Canonicality

Analyse the distinction between:

* observed history;
* accepted history;
* canonical history;
* objective reality.

Determine whether canonicality is:

1. a property of History;
2. a projection of History under governance context;
3. an assertion about History;
4. some combination of these.

Do not collapse these concepts.

---

## 9. Investigate State Reduction

Test the proposition:

`State = Projection(History, Context)`

Determine whether State can actually be reconstructed from historical events.

Pay particular attention to:

* genesis;
* external systems;
* snapshots;
* nondeterminism;
* incomplete histories;
* semantic effects;
* irreversible operations;
* contextual interpretation.

The goal is to determine whether State can be removed from the ontological kernel while retaining State as a formal semantic domain.

---

## 10. Investigate Context Reduction

Do not assume Context is irreducible.

Test the stronger hypothesis:

`Context = Projection(History)`

Determine whether this produces:

* genuine simplification;
* circularity;
* state explosion;
* loss of historical semantics;
* loss of authority semantics;
* loss of epistemic distinction.

This investigation belongs to the next conceptual milestone, SDP-001L.

---

## 11. Maintain the Fact / Inference / Hypothesis Boundary

Clearly label conclusions as appropriate:

* established definition;
* formal result;
* derived consequence;
* counterexample;
* analogy;
* conjecture;
* unresolved question.

Do not promote a hypothesis to a normative rule merely because it appears elegant.

---

## 12. Update the Development Knowledge Base

Record the SDP-001K findings in the project's knowledge structure according to the existing SDP conventions.

At minimum capture:

### Established

* Event is not Assertion.
* Event is not Transition.
* History is not merely a set of Events.
* History is not generally a total sequence.
* Event identity is required.
* Event occurrence and event effect are distinct.
* Historical invalidity does not imply deletion.
* Branch and Merge need not be kernel primitives.
* State and History are not identical.

### Provisional

* State is a projection of canonical history.
* Event is irreducible.
* History is irreducible.
* K₅ is the current kernel candidate.

### Open

* Whether Context is itself derivable from History.
* Whether History can become the complete semantic substrate.
* Whether State requires an independent semantic primitive/domain.
* Whether canonicality can be completely represented as historical projection.
* Whether the kernel can reduce to Identity + Event + Causal Structure + Interpretation.

---

## 13. Prepare SDP-001L

Do not implement SDP-001L unless explicitly instructed.

Instead produce a proposed scope for:

**SDP-001L — History as the Semantic Substrate**

The proposal must include the questions already identified in SDP-001K, particularly:

1. Can Context be reconstructed from History?
2. Can governance be reconstructed from History?
3. Can Knowledge be reconstructed from History?
4. Can Authority be reconstructed from History?
5. Can invariant regimes be reconstructed from History?
6. Can Evidence remain distinct if represented historically?
7. Can contradictory histories coexist?
8. Can alternative histories coexist without Branch primitives?
9. Can History describe its own interpretation?
10. Does this produce circularity?
11. What is the minimal genesis axiom?
12. What prevents arbitrary histories becoming canonical?
13. Can the resulting model be represented cleanly in Lean?

---

## 14. Formalisation Rule

Do not proceed to the final Lean kernel merely because the conceptual model appears coherent.

The required sequence remains:

`Concept → Countermodel → Algebra → Lean → Specification → Implementation`

SDP-001K is currently between:

`Concept → Countermodel → Algebra`

and therefore must remain in that phase.

---

## 15. Required Deliverable

After integration and analysis, report:

### A. Repository changes

Exactly what files were added or modified.

### B. Semantic changes

What SDP-001K changes relative to SDP-001J.

### C. Contradictions found

Every contradiction with earlier SDP material.

### D. Required follow-up changes

Changes that should be made now versus deferred to SDP-001L.

### E. Countermodel results

A concise result for each adversarial case.

### F. Kernel assessment

Whether K₅ survives the current tests.

### G. Open questions

Questions that must remain unresolved.

### H. SDP-001L proposal

The exact scope for the next conceptual milestone.

### I. Implementation status

Explicitly state:

> No implementation was undertaken because the SDP conceptual kernel has not yet been frozen.

---

## 16. Critical Instruction

**Do not optimise for implementation convenience.**

The objective is to discover the smallest semantically correct SDP foundation.

If the existing model is wrong, document why and propose the correction.

If SDP-001K is wrong, do not preserve it merely because it has already been written.

If K₅ can be reduced further, demonstrate the reduction.

If a reduction introduces hidden assumptions, expose them.

The development agent's role at this stage is **semantic verification and integration**, not code generation.
