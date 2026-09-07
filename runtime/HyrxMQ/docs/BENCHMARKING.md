# Benchmarking Contract

Benchmarking begins with a correct baseline.

## Measurement layers

```text
L0 protocol/codec
L1 broker/routing
L2 scheduling
L3 transport
L4 persistence
```

## Core measurements

- messages/second;
- bytes/second;
- p50;
- p95;
- p99;
- p99.9;
- CPU/message;
- allocations/message;
- bytes copied/message;
- memory/message;
- syscalls/message;
- context switches;
- scheduler wakeups;
- routing cost;
- codec cost;
- persistence cost;
- contention;
- cache misses;
- branch misses;
- CPU migration;
- NUMA effects;
- recovery time.

## Required benchmark discipline

- fixed workload definitions;
- deterministic seeds where applicable;
- warmup;
- multiple repetitions;
- raw results retained;
- outliers explained rather than silently discarded;
- benchmark environment recorded;
- source revision recorded;
- no comparison across materially different environments without qualification.

## Optimization rule

An optimization is accepted only when:

1. its target bottleneck is measured;
2. its mechanism is understood;
3. correctness is unchanged;
4. benchmark results improve the intended workload;
5. complexity is justified by the improvement.
