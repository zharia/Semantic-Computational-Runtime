# Semantic Domain Architecture

## Canonical kernel
`K = (State, Context, Transformation, Outcome, Observation)`

State is the semantic configuration; Context is the semantic interpretation environment;
Transformation describes semantic change; Outcome describes consequences including result
state/context; Observation defines meaningful semantic distinctions.

## Domain role
A domain may define semantic structures, values, transformations, constraints,
observations, equivalence relations, composition laws, invariants, formal theorems and
reference implementations.

A domain MUST NOT introduce a fundamental semantic type without first demonstrating a
counterexample that cannot be resolved by a derived relation/type/operator.

## Initial domain roots
core, mathematics, data, field, graph, geometry, topology, physics, dynamics, simulation,
agent, neural, rendering, system.

## Dependency direction
core -> mathematics -> data/graph/geometry -> field/topology -> physics/dynamics ->
simulation/agent/neural -> rendering/system.

Circular dependencies require explicit semantic justification.

## Domain completion
A domain is complete only when vocabulary, structures, transformations, constraints,
observations, laws, composition, equivalence where relevant, formal/reference evidence,
tests, and integration agree.
