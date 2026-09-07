# Manifestation Engine — Execution Context

## 1. Purpose

Execution context describes the conditions under which semantic execution is realized.

Context constrains realization; it does not redefine semantic meaning.

## 2. Context components

A context may contain:

- semantic scope;
- identity scope;
- authority;
- capability grants;
- resource limits;
- locality;
- temporal scope;
- precision requirements;
- consistency requirements;
- determinism requirements;
- provider policy;
- observation policy;
- transaction scope;
- cancellation/deadline policy;
- lineage.

## 3. Context inheritance

Nested execution SHOULD inherit context explicitly. Values may be narrowed by child operations but MUST NOT be silently broadened.

## 4. Authority

Capability availability is not equivalent to authorization. The Engine MUST evaluate both.

## 5. Resource scope

Resource limits are part of execution context and may cause admission failure without implying semantic invalidity.

## 6. Locality

Locality may influence provider selection and data placement. Semantic identity MUST remain independent of locality.

## 7. Temporal scope

Context may specify deadlines, semantic time windows, scheduling constraints or execution epochs.

Wall-clock deadlines MUST be distinguished from semantic temporal state.

## 8. Precision

Precision requirements may constrain providers and representations. Relaxation is valid only when explicitly allowed by the semantic contract.

## 9. Observation scope

Context may specify what observations are required, retained or exposed. Security policy MUST still govern access to observations.

## 10. Context identity

A context SHOULD have an identity or lineage identifier so execution decisions can be reproduced and audited.
