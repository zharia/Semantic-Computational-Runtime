# Sprint 011-003: Slice Selection

## Objective
Select one bounded operation that exercises canonical SCR semantics and can run in the available environment.

## Deliverables
- Selected vertical slice with rationale
- Scope and exclusions documented
- Execution path diagram

## Exit Criteria
- [ ] One bounded operation selected
- [ ] Rationale documented (why this operation)
- [ ] Scope explicitly bounded
- [ ] Exclusions listed
- [ ] Operation exercises real canonical SCR contracts
- [ ] Operation has clearly defined expected result
- [ ] Operation executable in available environment
- [ ] Operation has meaningful failure path
- [ ] Operation supports reproducible testing

## Implementation Plan
1. Review candidate operations from §5.2
2. Evaluate against existing repository capabilities
3. Select smallest useful operation
4. Document rationale
5. Define scope and exclusions

## Agent Delegation
- **cavecrew-investigator**: Identify existing capabilities that support candidate operations
- **cavecrew-builder**: Write slice selection document

## Evidence Required
- Candidate evaluation matrix
- Selected slice specification
- Scope/exclusion list
