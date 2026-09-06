# Transformation and Refinement

## 1. Transformation

A transformation maps one valid semantic state or structure to another:

\[
T : S_t \rightarrow S_{t+1}
\]

It may change values, relationships, topology, representation, state, or any combination thereof.

## 2. Transformation contract

Every transformation SHOULD define:

- domain;
- codomain;
- preconditions;
- postconditions;
- preserved invariants;
- introduced effects;
- determinism;
- resource requirements;
- observability;
- reversibility, if any.

## 3. Refinement

Refinement narrows or enriches a semantic description without violating the parent contract. Lower-level representations are refinements only when the mapping is explicit and valid.

## 4. Optimisation

Fusion, tiling, vectorisation, parallelisation, quantisation, provider substitution and layout conversion are valid only when they preserve the relevant semantic invariants.

## 5. Evolution

Execution is repeated semantic transformation. A running system therefore has a trajectory through the space of valid field states rather than merely a sequence of instructions.
