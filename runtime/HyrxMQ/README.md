# HyrxMQ — Phase 0 Seed

This archive is the **Phase 0 repository and toolchain groundwork** for Hyrx/HyrxMQ.

Phase 0 is deliberately non-functional as a broker. Its purpose is to establish a
clean, reproducible, evidence-driven engineering substrate before implementing
messaging semantics.

## Phase 0 objective

A fresh GNU/Linux checkout must be able to:

1. identify and validate the project/toolchain environment;
2. build/run the minimal Mojo seed;
3. execute the Phase 0 verification suite;
4. run formatting and repository checks;
5. produce deterministic seed/configuration output;
6. execute the benchmark harness skeleton;
7. expose explicit architecture invariants and decision records;
8. make no unsupported claims about AMQP, performance, or Mojo APIs.

## What Phase 0 does NOT implement

- AMQP 0-9-1
- TCP broker
- queues/exchanges
- routing
- persistence
- authentication
- management API
- clustering
- distributed consensus
- simulation-specific concepts

Those belong to later phases.

## Repository shape

```text
.
├── README.md
├── LICENSE
├── .gitignore
├── .editorconfig
├── docs/
│   ├── PHASE_0.md
│   ├── ARCHITECTURE_INVARIANTS.md
│   ├── DEVELOPMENT.md
│   ├── TOOLCHAIN.md
│   ├── TESTING.md
│   ├── BENCHMARKING.md
│   ├── COMPATIBILITY_POLICY.md
│   ├── QUALITY_GATES.md
│   └── decisions/
├── src/
│   └── hyrx/
├── tests/
│   └── phase0/
├── examples/
├── tools/
├── scripts/
├── config/
├── assets/
├── benchmarks/
├── schemas/
├── packaging/
│   └── systemd/
├── .github/workflows/
└── mojo.toml
```

## Phase 0 exit criterion

Phase 0 is complete only when the repository's actual environment has been
validated and the checks in `docs/PHASE_0.md` have been executed successfully.

The seed files are **not evidence of completion**. They are the starting point
from which the development agent must establish evidence.

## Naming

- **Hyrx** — native messaging technology/core.
- **HyrxMQ** — standalone broker product/runtime.
- `hyrxmq` — standalone service/binary naming.

Hyrx Core must remain independent of HyrxMQ and independent of any simulation.

## Evidence rule

If a toolchain feature, API, protocol behavior, optimization, or compatibility
claim has not been demonstrated in the current environment, record it as
`NOT PROVEN`.

Do not replace missing evidence with assumptions.
