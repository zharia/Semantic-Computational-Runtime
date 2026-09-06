# SCR v0.0.1-0A — Reference Semantic Executor

The first executable reference implementation of the Semantic Computational Runtime (SCR)
semantic execution model.

## Principles

- The Semantic Field is the execution substrate.
- Semantic identity is independent of physical representation.
- State changes occur through explicit semantic transformations.
- Constraints are part of semantic validity.
- Observation exposes semantic state.
- JSON is a bootstrap representation, not the SCR language.
- The implementation is subordinate to normative SCR semantics.
- Golden cases are calibration evidence for future implementations.

## Requirements

- Python 3.11+
- uv

## Quick start

```bash
uv sync
uv run scr examples/001_hello.json
uv run scr examples/003_transformation.json
uv run pytest
uv run pytest --cov
uv run ruff check .
uv run ruff format --check .
```

## Test strata

- `tests/unit/` — isolated semantic primitive behaviour
- `tests/integration/` — composition of primitives
- `tests/golden/` — canonical semantic behaviour
- `tests/conformance/` — provider/conformance-facing fixtures
- `tests/properties/` — property-based semantic tests

The test suite is part of the calibration mechanism, not merely a regression suite.
