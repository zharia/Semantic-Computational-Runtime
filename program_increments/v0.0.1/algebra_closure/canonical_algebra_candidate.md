# Candidate Canonical Algebra — Working Draft

## Status

Candidate only. This document is a synthesis target for formal closure, not a pre-approved final algebra.

## 1. Semantic domain

Let:

`S` = semantic states  
`C` = semantic contexts  
`I` = identities  
`E` = entities  
`V` = semantic values  
`R` = relationships  
`K` = constraints  
`Q` = observations/queries  
`O` = outcomes  
`T` = transformations  
`τ` = semantic temporal structure

A semantic machine state is not assumed to be reducible to a single tuple until formal analysis establishes that.

## 2. Candidate outcome

A minimal candidate:

`Outcome(S) = Success(S') | Failure(F)`

The closure phase must determine whether this is sufficient once nondeterminism, inapplicability, invalidity, cancellation, and partiality are considered.

## 3. Candidate transformation

A transformation is a semantic rule:

`T : (S, C) -> Outcome`

or an equivalent relational/set-valued formulation.

The final form must be selected by counterexample and formal expressiveness, not implementation convenience.

## 4. Candidate applicability

`Applicable(T,S,C)`

is a semantic relation/predicate that must not be reconstructed merely from observed success.

## 5. Candidate observation

`Observe(S,Q,C) -> (S,O)`

with purity relative to authoritative state unless explicitly specified otherwise.

## 6. Candidate semantic projection

For an implementation state `IState`:

`π : IState -> S`

where defined.

Implementation correctness should establish a refinement/commutation relationship between implementation transitions and semantic transitions.

## 7. Candidate identity

`SameEntity(x_t,x_u)`

is a semantic relation independent of representation.

## 8. Candidate equivalence

`x ≡_C y`

denotes equivalence under context C where contextual equivalence is required.

## 9. Candidate causality

`a ->_C b`

denotes semantic causal dependency under context C.

The algebra must determine its formal properties.

## 10. Candidate composition

`T2 ∘ T1`

is defined only where the outcome of T1 supplies an admissible input to T2.

Failure propagation must be explicit.

## 11. Candidate semantic field

`F = (E,R,T,C,S,K,M)`

remains the current working representation, but the closure phase must determine whether manifestation `M` belongs inside the semantic field or is better modelled as an external realization/projection.

## 12. Closure requirement

Every symbol above is provisional until:

- formally typed;
- semantically defined;
- counterexample-tested;
- reconciled with SMM/STC;
- encoded in Lean;
- covered by the closure manifest.
