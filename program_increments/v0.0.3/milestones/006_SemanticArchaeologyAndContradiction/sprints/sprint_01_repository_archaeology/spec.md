# Sprint 006-001: Repository Archaeology

## Objective
Map all SCR coordinate-system, transform, identity, lifecycle, and entity/component definitions to canonical locations. Produce the Concept→Location→Status→Dependencies→Evidence table.

## Deliverables
- Archaeology map covering all 12 scope areas from objective §2.1
- Concept provenance: documented/specified/implemented/tested/validated
- Explicit dependency graph between concepts

## Exit Criteria
- [ ] All 12 scope areas covered
- [ ] Every concept has canonical location + evidence status
- [ ] No concept left without provenance classification

## Implementation Plan
- Inspect `lib/101_definition.md`, `lib/102_status.yaml`
- Inspect `providers/101_definition.md`, `providers/102_status.yaml`
- Inspect all sprint records in milestones 001-005
- Inspect `providers/o3de/` artifacts
- Inspect `lib/` domain definitions
- Inspect implementation headers and test files
- Build concept provenance table

## Agent Delegation
- **cavecrew-investigator**: Search concepts across repo, map to canonical files
- **cavecrew-builder**: Compile archaeology table into report
