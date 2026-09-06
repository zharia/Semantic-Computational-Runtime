# v0.0.1-0A — Reference Semantic Executor Specification

**Status:** Normative Draft  
**Version:** 0.0.1

## Purpose

The Reference Semantic Executor is the first executable implementation of the SCR semantic
execution model. It provides a minimal, transparent, deterministic, inspectable environment
for constructing a Semantic Field, defining entities and relationships, applying transformations,
enforcing constraints, observing state, and producing execution traces.

It prioritises semantic correctness over performance.

## Architectural Position

```text
Normative SCR Semantics
        |
        v
Reference Semantic Executor
        |
        +--> Unit Tests
        +--> Integration Tests
        +--> Golden Cases
        +--> Conformance Fixtures
        |
        v
Calibration Suite
        |
        +--> Wasm Provider
        +--> Native Runtime
        +--> Other Providers
```

The executor is an executable reference implementation, not the source of semantic authority.

## Governing Principle

> Make semantic execution executable before making it fast.

## Semantic Field

The conceptual field is `F = (E, R, T, C, S, K, M)`, where E is entities, R relationships,
T transformations, C context, S state, K constraints, and M manifestations.

The minimum 0A field is `F0 = (E, R, T, S, K)` with observation as the initial external
manifestation mechanism.

## Required Semantics

Version 0.0.1 supports:

- Semantic Field
- semantic identity
- Entity
- Value
- Property
- State
- Relationship
- Transformation
- Constraint
- Observation
- deterministic execution
- semantic errors
- execution trace
- program loading

## Transformation

A transformation is conceptually `S' = T(S)` subject to applicable constraints.

Execution performs:

1. resolve transformation;
2. validate preconditions;
3. apply transformation;
4. validate resulting state;
5. commit atomically;
6. record observation/trace.

A failed transformation MUST NOT leave partial semantic state.

## Bootstrap Operations

- `set`
- `increment`
- `add`
- `multiply`
- `append`
- `emit`

These are reference operations, not a final SCR instruction set.

## Constraints

Supported operators are `==`, `!=`, `<`, `<=`, `>`, `>=`, and `in`.

Constraints operate on semantic state. Undefined coercions MUST be rejected.

## Determinism

Equivalent semantic input and initial state MUST produce equivalent semantic results.
Hidden randomness, host time, external state, and implementation ordering MUST NOT affect
0A semantics.

## Representation Independence

JSON is a bootstrap representation only. Python objects are implementation representations only.
Neither defines SCR semantics.

Semantic identity MUST NOT depend upon memory address, Python object identity, allocation
location, or dictionary ordering.

## Security Boundary

Semantic programs MUST NOT execute arbitrary host-language code. Only explicitly registered
semantic operations may execute.

## Testing and Calibration

Testing has five strata:

1. **Unit** — isolated semantic primitives, including valid, invalid, boundary, and error paths.
2. **Integration** — composition of independently tested primitives.
3. **Golden** — canonical semantic programs and expected outcomes.
4. **Conformance** — fixtures for future execution providers.
5. **Property** — algebraic and invariant properties where appropriate.

The project SHOULD target 100% branch coverage for the semantic core. The release coverage gate
is at least 95% overall, with uncovered code explicitly reviewed. Mutation testing SHOULD be
introduced for critical semantic components.

## Calibration Suite

The calibration suite is long-term semantic evidence:

`C_SCR = {program, initial state, transitions, observations, outcomes, invariants, errors}`

Future runtimes MUST be evaluated against this suite. Changes to golden expectations require
a semantic rationale.

## Python and uv

Python 3.11+ is the reference implementation language. `uv` is the canonical project and
environment manager. `pyproject.toml` and `uv.lock` define the reproducible environment.
Developers SHOULD use `uv sync` and `uv run`.

## Scope Exclusions

0A does not require native compilation, MLIR, WebAssembly, GPU execution, distribution,
networking, persistence, databases, concurrency, parallel scheduling, physical memory
management, rendering, or external messaging.

## Success Criteria

A developer can obtain the project, run it with Python and uv, load a semantic program,
construct a field, define entities and relationships, apply transformations, enforce
constraints,
observe state, inspect traces, and run the automated test suite.

## Final Principle

`Define Meaning -> Represent Meaning -> Transform Meaning -> Observe Meaning -> Validate Meaning
-> Optimise Execution`

The Reference Executor embodies:

> Engineer outward from the Semantic Field.
