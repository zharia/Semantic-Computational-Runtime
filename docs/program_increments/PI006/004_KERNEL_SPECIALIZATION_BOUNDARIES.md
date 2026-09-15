# Kernel Specialization Boundaries

The five-type kernel is provisionally frozen. The following current implementation
choices are reference specializations, not universal laws:

- deterministic `step`;
- total transition;
- rollback-on-failure;
- failure-preserves-time;
- minimal Context;
- context-independent applicability;
- CRUD-style `HyperOp`;
- `observeNode` as the complete observation vocabulary.

General transition semantics may be modeled as a relation/set of outcomes:
`TransitionSemantics(T,S,C) -> Set(Outcome)`.
The deterministic reference `step` is the singleton specialization.

Partiality is an empty outcome set; nondeterminism has multiple outcomes. Failure need
not universally imply rollback. `logical_step : Nat` is a reference temporal coordinate,
not the whole theory of semantic time.

Do not add kernel primitives unless a concrete semantic counterexample defeats a derived
concept.
