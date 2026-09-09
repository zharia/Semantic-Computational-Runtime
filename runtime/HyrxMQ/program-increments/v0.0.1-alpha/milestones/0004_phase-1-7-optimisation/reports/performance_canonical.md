# HyrxMQ ↔ RabbitMQ — Canonical Performance Comparison

**Run:** 2026-09-09, quiet, same-host. **Reference broker:** fresh RabbitMQ 4.3.5
container `hyrxmq-bench-rabbit` on `127.0.0.1:5673` (admin/password; the pre-existing
`node-rabbitmq` was left untouched — it was in a broken-auth state from an earlier
disk-full event). **Subject:** HyrxMQ (commit `fa65e28`, post-0004), via
`hyrx-tcp-docker` (throwaway container), `hyrx-tcp-native`, `hyrx-uds`.
**Host:** AMD Ryzen 5 3600 (12 logical), kernel 7.1.8-cachyos, pika 1.4.4,
governor powersave. Both brokers run on the same v3-capable machine → symmetric.

> **Method:** closed-loop `publish → basic_get(auto_ack)` (the broker has no
> push-to-idle path and drops at queue capacity, so closed-loop is the honest
> comparable), single connection per broker, sequential, same client. 5 reps,
> auto-calibrated counts. frame_max 131072, delivery_mode 1, no confirms,
> no durability. `verified=True` on every cell. See `method`/`protocol` in
> `results.json`.

## Headline — and its honest decomposition

| quantity | value |
|---|---|
| Fair-pair Rating **R** (rabbit-tcp vs hyrx-tcp-docker) | **1.063** (95% CI 1.054–1.073, median 1.060) |
| — throughput geomean **G_T** (Hyrx/Rabbit, all payloads) | **0.861**  (Hyrx slightly *behind* on aggregate throughput) |
| — latency geomean **G_L** (sampled at 256 B) | **1.265** |

**R>1 is a composition of "much faster at small payloads" and one latency sample;
it is NOT "uniformly faster than RabbitMQ."** Decomposed, HyrxMQ wins small and
loses large. Read the matrix; do not lead with R alone.

## Throughput matrix (median msgs/s; 5 reps, low spread)

| payload | RabbitMQ (tcp) | HyrxMQ docker | HyrxMQ native | HyrxMQ UDS | HyrxMQ vs Rabbit (best cell) |
|---:|---:|---:|---:|---:|:--|
| 64 B   | 4,438 | 6,541 | 7,277 | 8,922 | **2.0× faster** (UDS) |
| 256 B  | 4,502 | 6,476 | 7,145 | 8,531 | **1.9× faster** (UDS) |
| 1,024 B| 4,525 | 5,788 | 6,235 | 7,642 | **1.7× faster** (UDS) |
| 4,096 B| 4,382 | 2,348 | 2,586 | 3,255 | **0.74× — SLOWER** (even UDS) |
| 16,384B| 4,040 | 1,317 | 1,356 | 1,486 | **0.37× — ~2.7× SLOWER** |

Fair-pair (both docker-published TCP) throughput ratios: 64B 1.47×, 256B 1.44×,
1024B 1.28×, 4096B **0.54×**, 16384B **0.33×**.

## Reading the numbers

- **Transport overhead (HyrxMQ internal):** native is ~9–12% faster than the
  docker-published path (the "docker/NAT tax"); UDS is ~15–24% faster than native
  (kernel-copy saving). RabbitMQ here is measured only over TCP.
- **Small payloads:** HyrxMQ is decisively faster (1.3–1.5× vs RabbitMQ on the
  fair pair, up to 2.0× on UDS).
- **Large payloads — the standing weakness:** RabbitMQ throughput is nearly flat
  with size (~4.4k→4.0k/s from 64B→16KB; network/IO-bound); HyrxMQ **collapses**
  with size (native 7.3k→1.4k/s). From ~4 KB on, RabbitMQ wins. This is the
  0003-identified crossover (0.51× @4K, 0.28× @16K) and the 0004 copy-cut did **not
  close it** — it removed one per-byte pass per destination (helping small/moderate
  and the in-process fan-out slope) but the large-payload cost is dominated by the
  per-byte `List[UInt8]` copy model + frame chunking/memory bandwidth, not the
  removed duplicate pass. **Top open follow-up.**

## Regression gate / noise

- **Rating gate: PASS** (R 1.051 → 1.063, +0.012, threshold ±0.10). Baseline was
  captured pre-0004 (`ed20be0`) on the same machine, so the delta reflects 0004.
- `compare.py` flags **1 regression**: `hyrx-tcp-docker 256 B p99` 301→670 µs. This
  is the same high-variance 256 B p99 point: the **unchanged RabbitMQ reference
  cell's** own 256 B p99 swung 413→1105 µs (−168%) in the same run — its code did
  not change, so it is host tail-jitter, not a HyrxMQ regression. (`compare.py` also
  warns "host signature changed" because `hyrxmq_git_head` legitimately moved
  ed20be0→fa65e28 on the same hardware.)
- `results.json` captured; **`baseline.json` NOT updated** (a single-point p99 is
  flagged and the run is post-change; refresh is a human-reviewed decision).

## What this does NOT claim
- No production-readiness, durability, TLS, clustering, heartbeat, publisher-confirm,
  or open-loop producer-throughput claim (closed-loop, auto_ack, single-connection).
- Not machine-independent: R is comparable only between runs on this host signature.
- No RabbitMQ-over-UDS figure (RabbitMQ has no UDS listener).

## Verdict (honest)
HyrxMQ is a **fast small-message** broker (~1.3–1.5× RabbitMQ on the fair pair, up
to 2× over UDS) that **falls behind RabbitMQ at ≥4 KB payloads** (memory-bound
per-byte copy model). Increment 0004 (copy-cut, metadata/wire fidelity, P1b pool
evaluated-and-left-off) holds fair-pair parity-to-better at **no regression**, but
**large-payload copy efficiency remains the principal gap and the top next
optimization.** The headline R=1.063 should always be presented with this
decomposition.

## Reproduce
```bash
# fresh reference broker (does NOT touch node-rabbitmq):
docker run -d --name hyrxmq-bench-rabbit --hostname rabbit-bench \
  -p 127.0.0.1:5673:5672 -p 127.0.0.1:15673:15672 \
  -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=password \
  -v rabbitmq_bench_data:/var/lib/rabbitmq rabbitmq:4-management
docker exec hyrxmq-bench-rabbit bash -c 'echo "deprecated_features.permit.transient_nonexcl_queues = true" >> /etc/rabbitmq/rabbitmq.conf' && docker restart hyrxmq-bench-rabbit
# full fair matrix (both brokers same-host):
RABBIT_HOST=127.0.0.1 RABBIT_PORT=5673 bash benchmarks/perf/run_all.sh
```
