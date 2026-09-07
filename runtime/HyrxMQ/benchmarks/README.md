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
