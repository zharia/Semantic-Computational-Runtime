# DEVELOPMENT AGENT INSTRUCTION — SCR PI006

You are continuing development of the Semantic Computational Runtime (SCR).

## Mission
Implement semantic domains and subdomains outward from the canonical kernel:

`State`, `Context`, `Transformation`, `Outcome`, `Observation`.

## Mandatory first actions
1. Read the entire repository.
2. Inspect SCRFormal, docs, lib, program_increments, runtime, scripts and tests.
3. Build the baseline.
4. Inventory existing domains/subdomains and implementations.
5. Identify stale documentation and duplicate ontology.
6. Run current formal/conformance checks.
7. Do not trust historical COMPLETE claims without evidence.

## Authority
The five-type kernel is the semantic authority.
STC is a derived semantic calculus over the kernel.
SMM is architectural interpretation, not a competing ontology.
Reference Executor is a semantic witness/specialization.
EGS is realization infrastructure.
MLIR represents/lowers semantics.
Mojo implements semantics.
Providers realize capabilities.

## Do not universalize current Algebra restrictions
Determinism, totality, rollback-on-failure, failure-preserves-time, minimal Context,
context-independent applicability, CRUD HyperOp and node-only observation are reference
specializations unless separately proven universal.

General nondeterministic, partial, stochastic, non-transactional and richer temporal
semantics must remain expressible as derived relations/extensions. Do not add a sixth
kernel primitive unless a concrete counterexample defeats all derived alternatives.

## Implementation order
Wave 1: core; mathematics/foundations; mathematics/algebra; data; graph.
Wave 2: linear algebra; tensor; geometry; topology; analysis; dynamics.
Wave 3: field; physics; simulation; agent; neural; rendering; system.

## Domain contract
Every domain/subdomain must contain `101_spec.md`, `102_status.yaml`,
`103_library.graph.json`, and must define vocabulary, dependencies, semantic structures,
transformations, applicability/admissibility, constraints, observations, laws, equivalence
where relevant, failure/temporal/causal semantics where relevant, implementation mapping,
formalization, tests and exclusions.

## Workflow
describe -> specify -> formalize -> test -> reference implementation -> Mojo -> validate
-> integrate -> update graph/status.

## Completion
Never report COMPLETE unless semantic, formal/reference, test, metadata and integration
gates pass. Report implemented, verified, formalized and integrated separately when needed.

## Deliverable
Return changed-file inventory, domain registry, implementation/formal/test status,
cross-domain results, unresolved issues, any proposed kernel changes with counterexamples,
and exact next steps. Never hide unresolved semantic questions behind implementation progress.
