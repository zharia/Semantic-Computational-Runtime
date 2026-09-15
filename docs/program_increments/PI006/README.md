# SCR PI006 — Semantic Domain Foundation
Status: PROPOSED IMPLEMENTATION PACKAGE
Date: 2026-09-13

## Purpose
Implement SCR semantic domains and subdomains outward from the canonical five-type kernel:

`State`, `Context`, `Transformation`, `Outcome`, `Observation`.

Domains add semantic structures, transformations, constraints, observations and laws.
They must not create competing semantic machines or redefine the kernel.

## Critical boundary
The current `SCR.Algebra` is a deterministic/reference specialization. Do not silently
promote its current restrictions to universal SCR semantics. In particular:
determinism, totality, rollback-on-failure, failure-preserves-time, minimal Context,
context-independent applicability, CRUD-style HyperOp, and node-only observation are
specializations until formally justified.

General nondeterministic, partial, stochastic, non-transactional and richer temporal
semantics must remain expressible as derived relations/extensions without forcing new
kernel primitives unless a concrete counterexample proves necessity.
