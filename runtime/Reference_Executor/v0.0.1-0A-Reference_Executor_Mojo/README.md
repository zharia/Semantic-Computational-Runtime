# SCR v0.0.1-0A — Reference Semantic Executor

Mojo 1.0 implementation of the SCR bootstrap/reference executor.

## Toolchain

This project targets **Mojo 1.0.0**.

Mojo reached 1.0 on 11 August 2026. The project pins the Mojo package to `1.0.0` so that the reference executor is not silently recompiled against a moving nightly compiler.

Use `uv` to create and synchronize the environment:

```bash
uv sync
```

Then verify:

```bash
uv run mojo --version
```

The expected major/minor release is Mojo 1.0.x.

## Running examples

From the project root:

```bash
uv run mojo run -I src examples/001_hello.mojo
uv run mojo run -I src examples/002_relationship.mojo
uv run mojo run -I src examples/003_transformation.mojo
uv run mojo run -I src examples/004_constraint_rollback.mojo
```

## Running tests

The project uses Mojo's native testing framework:

```bash
uv run mojo run -I src tests/test_reference_executor.mojo
```

The test suite uses `TestSuite.discover_tests[__functions_in_module()]().run()`.

## Why the source path is explicit

The executor is currently a source tree rather than a published Mojo package. `-I src` adds the source directory to Mojo's module search path.

This is intentional for 0A and keeps the bootstrap free from a second packaging/runtime abstraction.

## Architecture

```text
Semantic Field
      ↓
Semantic Model
      ↓
Semantic Transformation
      ↓
Validation
      ↓
Committed Semantic State
      ↓
Observation / Trace
```

Mojo is the primary application/implementation language:

```text
Developer Mojo
      ↓
SCR Semantic Library
      ↓
Mojo compiler
      ↓
MLIR
      ↓
SCR semantic analysis / transformation
      ↓
Provider
      ↓
Runtime / execution substrate
```

There is deliberately no second SCR-specific implementation language between the developer's Mojo implementation and MLIR.

## Scope

0A establishes:

- semantic identity
- values
- entities
- relationships
- constraints
- transformations
- observations
- execution state
- logical time
- execution trace
- deterministic execution
- transactional transformation
- rollback on failed validation
- conformance tests

0A does not yet implement:

- the production SCR runtime
- MLIR dialects
- lowering passes
- Wasm providers
- GPU execution
- distributed execution
- persistent storage
- AMQP
- rendering
- networking
- OS integration

Those belong to subsequent SCR work.

## Calibration principle

The executor is an executable reference of semantic behaviour.

It is not authoritative because its implementation is written in Mojo. The normative semantic model remains the SCR specification.

The purpose of 0A is to make semantic behaviour executable, testable, observable and comparable with future providers.
