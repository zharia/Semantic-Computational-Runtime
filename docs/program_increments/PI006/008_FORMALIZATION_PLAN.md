# Formalization Plan

Lean formalization proves semantic laws, not merely implementation behavior.

Priority:
1. domain registry invariants, dependency acyclicity, kernel conformance, state invariants,
   applicability, outcome preservation, observation purity;
2. mathematical foundations, set/relation/function/algebra/graph laws;
3. cross-domain composition.

Where the reference algebra is deterministic, prove the deterministic specialization.
General nondeterminism/partiality belongs in derived transition semantics.

Never use a theorem about a specialization as evidence of universal SCR semantics.
