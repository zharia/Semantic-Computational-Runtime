# Benchmarks

Phase 0 establishes the benchmark contract, not broker performance.

## Required reporting

Every future benchmark result must identify:

- source revision;
- Mojo/toolchain version;
- kernel and CPU;
- workload;
- message count;
- payload size;
- warmup policy;
- measurement duration/iterations;
- p50/p95/p99/p99.9 latency;
- throughput;
- allocations/message;
- copies/message;
- CPU/message where available;
- relevant scheduler/context-switch data;
- benchmark command;
- raw result location.

## Baseline sequence

Do not compare optimized transports before a direct in-process baseline exists.

The planned progression is:

```text
direct Hyrx
  → Unix domain
  → shared memory (only if justified)
  → Hyrx TCP
  → Hyrx QUIC
  → AMQP TCP
  → AMQP TLS
  → durable variants
```

All results are evidence, not promises.

## Steady-state + transport matrix + copy investigation (audit §19/§20/§21)

The original `direct_benchmark.mojo` uses a publish-all-then-consume-all loop —
per §19 that is **not** steady-state evidence. The following files add a correct
interleaved baseline, a real-socket transport matrix, a fan-out copy
investigation, and a self-instrumented profiling probe:

| file | purpose | run |
|------|---------|-----|
| `interleaved_direct.mojo` | bounded `publish→route→consume→ack` cycle (steady-state) | `pixi run bench-direct` |
| `transport_matrix.mojo` | same workload over direct / UDS / Hyrx TCP / AMQP-TCP loopback | `pixi run bench-transport` |
| `fanout_copy.mojo` | §21 fan-out copy cost at 1/2/10/100 destinations (measure only) | `pixi run bench-fanout` |
| `profiling_probe.mojo` | §20 phase timers (alloc/route/deliver/ack) + copy counter | `pixi run bench-profile` |

They `import` the shared helpers from `direct_benchmark.mojo` (`mojo run` adds the
main file's directory to the search path) rather than duplicating them.

Measured results and honest tooling limits live in
`../program-increments/v0.0.1-alpha/milestones/0003_phase-1-7-audit/reports/benchmarks.md`.
These are long-running workloads and are intentionally **not** in
`scripts/test_all.sh`.

