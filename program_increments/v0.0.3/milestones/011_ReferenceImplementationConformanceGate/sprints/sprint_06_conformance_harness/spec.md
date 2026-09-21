# Sprint 011-006: Conformance Harness

## Objective
Create or extend reusable harness for testing reference path and future provider adapters.

## Deliverables
- Reusable conformance test harness
- Identity tests (SID mapping, reverse mapping, preservation, invalid mapping)
- Coordinate/transform tests (frame, unit, composition, inverse, round-trip, precision)
- Lifecycle/composition tests (transitions, constraints, provider mapping)
- Execution tests (valid input, operation, result, preconditions, failure)
- Observation tests (semantic interpretation, approximation, unavailable)
- Provenance tests (contract ID, provider identity, mapping version)

## Exit Criteria
- [ ] Harness driven by semantic contracts, not provider details
- [ ] Identity test category implemented
- [ ] Coordinate/transform test category implemented
- [ ] Lifecycle/composition test category implemented
- [ ] Execution test category implemented
- [ ] Observation test category implemented
- [ ] Provenance test category implemented
- [ ] Each test identifies: Test ID, Semantic contract, Canonical spec, Preconditions, Input, Expected, Observed, Tolerance, Result, Evidence
- [ ] Negative tests challenge assumptions
- [ ] Property-based tests where appropriate

## Implementation Plan
1. Design harness structure per §12.2
2. Implement identity tests
3. Implement coordinate/transform tests
4. Implement lifecycle/composition tests
5. Implement execution tests
6. Implement observation tests
7. Implement provenance tests
8. Add negative tests per §12.4
9. Add property-based tests per §12.3

## Agent Delegation
- **cavecrew-builder**: Implement test harness
- **cavecrew-reviewer**: Verify test coverage and contract alignment

## Evidence Required
- Test source code
- Test execution results
- Test coverage matrix
