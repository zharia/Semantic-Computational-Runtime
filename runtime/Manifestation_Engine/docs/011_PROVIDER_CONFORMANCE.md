# Manifestation Engine — Provider Conformance

## 1. Purpose

This document defines how a provider demonstrates that it can satisfy a semantic capability contract.

## 2. Required provider declaration

A provider SHOULD declare:

- provider identity;
- capability identities;
- contract versions;
- supported representations;
- precision characteristics;
- determinism/stochasticity;
- resource requirements;
- side effects;
- failure modes;
- security/trust properties.

## 3. Conformance levels

### Level 0 — Discovery
The provider can be identified and queried.

### Level 1 — Contract
The provider exposes a machine-checkable capability contract.

### Level 2 — Behavioral
The provider passes semantic conformance tests.

### Level 3 — Differential
The provider agrees with the Reference Executor for the applicable test domain.

### Level 4 — Operational
The provider satisfies lifecycle, resource, failure, security and observability requirements.

## 4. Required tests

Providers SHOULD be tested for:

- valid inputs;
- invalid inputs;
- boundary values;
- state transitions;
- determinism;
- precision/error bounds;
- cancellation;
- resource exhaustion;
- retries;
- partial failure;
- concurrency;
- provenance.

## 5. Provider certification

Certification is contract- and version-specific. A provider MUST NOT claim universal semantic equivalence merely from implementing a common API.

## 6. Revocation

A provider whose behavior no longer satisfies its contract MUST be removable from selection without changing semantic graph definitions.
