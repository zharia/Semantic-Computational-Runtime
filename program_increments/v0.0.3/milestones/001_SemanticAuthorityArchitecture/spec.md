# Milestone 001: Semantic Authority & Architecture

## 1. Scope & Objective
Establish SCR's foundational semantic architecture: authority model, definitions, alignment principles, and provenance requirements. This milestone produces the architectural invariants that govern all subsequent assessment work.

## 2. Deliverables
- SCR semantic authority model (who defines what)
- Semantic concept vs representation vs adapter vs provider definitions
- Semantic alignment principles (align before invent)
- Provenance requirements for externally-informed concepts
- Repository documentation of architectural invariants

## 3. Formal Invariants
1. SCR semantic definitions are authoritative for SCR.
2. External technologies are representations/providers, not semantic authorities.
3. Representation equality does not imply semantic equality.
4. Every SCR concept derived from an external source records provenance.

## 4. Exit Criteria
- [ ] Semantic authority model documented
- [ ] Four-tier concept hierarchy (semantic → representation → adapter → provider) documented
- [ ] Alignment principles established
- [ ] Provenance template defined
- [ ] Architectural invariant preserved in repository

## 5. Dependencies
- None (foundational milestone)
