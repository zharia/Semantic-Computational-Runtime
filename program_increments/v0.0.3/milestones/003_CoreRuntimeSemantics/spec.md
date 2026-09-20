# Milestone 003: Core Runtime Semantics

## 1. Scope & Objective
Define/extend SCR core runtime semantics: entity/component lifecycle, spatial hierarchy, physics/dynamics, and asset/resource/materialization. Produce semantic library candidate definitions where gaps exist.

## 2. Deliverables
- Entity/component lifecycle semantic definitions
- Spatial hierarchy semantic definitions
- Physics/dynamics semantic definitions
- Asset/resource/materialization semantic definitions
- Semantic library directory structure recommendations

## 3. Formal Invariants
1. Entity identity uniqueness preserved across contexts.
2. Component composition is explicit, not implicit.
3. Transform composition is associative and preserves parent/child.
4. Materialization is a semantic operation, not merely file conversion.

## 4. Exit Criteria
- [ ] Core semantic definitions produced with provenance
- [ ] Gap analysis from Milestone 002 addressed
- [ ] Semantic library candidates justified (not automatic)
- [ ] Each definition classified: already-defined / needs-clarity / needs-extension / new-required

## 5. Dependencies
- Milestone 002 (AzFramework assessment)
