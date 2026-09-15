# Domain Specification Contract

Every domain/subdomain MUST contain:
- `101_spec.md`
- `102_status.yaml`
- `103_library.graph.json`

`101_spec.md` must define identity, purpose, dependencies, structures, values,
transformations, applicability/admissibility, constraints, observations, laws,
equivalence, failure semantics, temporal/causal semantics where relevant, implementation
mapping, formalization, tests and exclusions.

`102_status.yaml` uses explicit states such as PLANNED, SPECIFIED, FORMALIZED,
IMPLEMENTED, VERIFIED, INTEGRATED, COMPLETE. No percentage-based completion.

`103_library.graph.json` records identity, hierarchy, dependencies, semantic types,
transformations, observations, laws, formal artifacts, implementation artifacts and
providers.

Fail closed: unresolved semantic ambiguity prevents COMPLETE.
