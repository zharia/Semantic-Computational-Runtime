# Setup

## Requirements

- Linux/macOS/WSL with a supported Mojo 1.0 installation
- `uv`

The project pins the Python-distributed Mojo package to `1.0.0`.

## Setup

```bash
uv sync
```

## Verify

```bash
uv run mojo --version
```

## Run

```bash
uv run mojo run -I src examples/001_hello.mojo
```

## Test

```bash
uv run mojo run -I src tests/test_reference_executor.mojo
```

If a locally installed Mojo differs from 1.0.0, do not use it to certify the reference executor. Run through the project's `uv` environment so the toolchain is reproducible.
