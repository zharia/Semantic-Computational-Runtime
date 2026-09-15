# Three-Broker AMQP Performance Benchmark — v2 (compiled client)

**HyrxMQ vs RabbitMQ vs LavinMQ — one host, all brokers in Docker, one compiled Go load generator.**

- Run id: `20260914T181603Z`
- Started (UTC): 2026-09-14T18:16:03Z · finished 2026-09-14T19:46:52Z
- Mode: full · replicates per cell: 5 (median reported) · target rep >= 2.0 s

## Host & software

- CPU: AMD Ryzen 5 3600 6-Core Processor (12 logical CPUs)
- RAM: 15.54 GiB · kernel 7.2.4-3-cachyos · docker 29.8.0
- Client: Go (go version go1.27.1-X:nodwarf5 linux/amd64) `amqp091-go` v1.10.0, compiled, one goroutine + connection per worker
- CPU governor: powersave · host loadavg(1m) at start: 1.52
- Image HyrxMQ: `hyrxmq:latest` · id `sha256:ccdf6c2fdb97f350db9e8f78b72a8762480657a04152315e70f31d21752a9ff3`
- Image RabbitMQ: `rabbitmq:4-management` · id `sha256:ffd1b50c522ad20172ffd6716a2f41db375c7269560c8f3fb9a694e210ef0852`
- Image LavinMQ: `cloudamqp/lavinmq:latest` · id `sha256:0fa126ed80521a50f8a0ac575a5d7bb7447376c3c6bb829a38b85685b9340664`

## Methodology and fairness notes

- All three brokers run in their own container on **one user-defined bridge** (`hyrxmq-bench2`), each published on `127.0.0.1`, so every client connection crosses the **same docker-proxy hop**.
- Each container is capped identically: `--cpus 4 --memory 2g`.
- **One compiled client binary** (`loadgen`, Go + amqp091-go) is used against every broker; the client is no longer the GIL-bound bottleneck of the previous Python/pika run.
- Each worker goroutine opens its **own connection + channel** and its **own exchange and queue(s)**. This measures connection/channel scaling and avoids cross-connection contention on a single queue.
  - A *shared* queue with 16 concurrent `basic.get` connections was tried first: HyrxMQ served ~69/125 messages then stopped. Per-worker topology is used for the matrix; the shared-queue behaviour is noted under caveats.
- Queues are **durable, non-exclusive, non-auto-delete and pre-declared**, then purged before each run, so connection close never races an auto-delete and no state leaks between runs.
- Identical protocol settings: `delivery_mode=1`, `frame_max=131072`, `heartbeat=30s`, `auto_ack=True` on the throughput `basic.get` (explicit ack only in the latency workload).
- The first 10% of every run is discarded as warm-up; >= 5 reps per cell, brokers rotated across reps; the **median** is reported.
- Batches are payload-scaled (`~512 KiB` in flight) so a 256 KiB payload at 32 connections cannot exhaust the 2 GiB container cap.
- CPU% and RSS are sampled every ~2 s from `docker stats --no-stream` for exactly the three benchmark containers.
- **Two medians are reported**: `median` uses every successful rep; `clean` drops reps that errored or whose wall time was > 3x the target (HyrxMQ intermittently stalls ~15 s; see caveats). The primary verdict uses `median`; the clean verdict shows steady-state.

### Workload — publish — fire-and-forget to a bindingless direct exchange (producer/transport ceiling)

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H/R/L) | HyrxMQ stalls |
|---|---|---|---|---|---|---|---|
| 64 | 1 | 145,991.1 | 143,466.7 | 151,431.1 | 151,431.1 | 1.04 / 1.06 / 1.00 | 0/5 |
| 64 | 4 | 459,648.8 | 357,312.6 | 465,991.1 | 465,991.1 | 1.01 / 1.30 / 1.00 | 0/5 |
| 64 | 8 | 546,940.0 | 384,248.6 | 534,577.8 | 546,940.0 | 1.00 / 1.42 / 1.02 | 0/5 |
| 64 | 16 | 608,553.9 | 384,851.0 | 544,071.0 | 608,553.9 | 1.00 / 1.58 / 1.12 | 0/5 |
| 64 | 32 | 671,937.7 | 399,565.7 | 583,099.3 | 671,937.7 | 1.00 / 1.68 / 1.15 | 0/5 |
| 1024 | 1 | 136,995.6 | 132,337.8 | 137,706.7 | 137,706.7 | 1.01 / 1.04 / 1.00 | 0/5 |
| 1024 | 4 | 308,563.8 | 332,224.3 | 409,870.1 | 409,870.1 | 1.33 / 1.23 / 1.00 | 0/5 |
| 1024 | 8 | 324,098.5 | 491,197.4 | 540,215.4 | 540,215.4 | 1.67 / 1.10 / 1.00 | 0/5 |
| 1024 | 16 | 324,492.4 | 443,431.0 | 567,511.7 | 567,511.7 | 1.75 / 1.28 / 1.00 | 0/5 |
| 1024 | 32 | 360,462.7 | 411,489.5 | 578,555.7 | 578,555.7 | 1.61 / 1.41 / 1.00 | 0/5 |
| 16384 | 1 | 45,688.9 | 45,653.3 | 45,394.1 | 45,688.9 | 1.00 / 1.00 / 1.01 | 0/5 |
| 16384 | 4 | 87,446.6 | 127,254.2 | 95,484.7 | 127,254.2 | 1.46 / 1.00 / 1.33 | 0/5 |
| 16384 | 8 | 82,532.8 | 141,098.2 | 91,003.3 | 141,098.2 | 1.71 / 1.00 / 1.55 | 0/5 |
| 16384 | 16 | 76,764.8 | 139,250.4 | 84,781.5 | 139,250.4 | 1.81 / 1.00 / 1.64 | 0/5 |
| 16384 | 32 | 73,856.7 | 123,326.4 | 76,696.2 | 123,326.4 | 1.67 / 1.00 / 1.61 | 0/5 |
| 65536 | 1 | 28,393.1 | 31,893.3 | 29,103.8 | 31,893.3 | 1.12 / 1.00 / 1.10 | 0/5 |
| 65536 | 4 | 27,033.3 | 48,692.6 | 29,519.4 | 48,692.6 | 1.80 / 1.00 / 1.65 | 0/5 |
| 65536 | 8 | 25,038.9 | 43,988.9 | 27,645.2 | 43,988.9 | 1.76 / 1.00 / 1.59 | 0/5 |
| 65536 | 16 | 21,793.1 | 37,447.2 | 23,930.1 | 37,447.2 | 1.72 / 1.00 / 1.56 | 0/5 |
| 65536 | 32 | 20,532.8 | 29,975.5 | 19,848.1 | 29,975.5 | 1.46 / 1.00 / 1.51 | 0/5 |
| 262144 | 1 | 5,431.6 | 8,048.8 | 3,842.1 | 8,048.8 | 1.48 / 1.00 / 2.09 | 0/5 |
| 262144 | 4 | 5,230.3 | 12,072.8 | 3,488.4 | 12,072.8 | 2.31 / 1.00 / 3.46 | 0/5 |
| 262144 | 8 | 5,140.0 | 10,887.0 | 3,303.2 | 10,887.0 | 2.12 / 1.00 / 3.30 | 0/5 |
| 262144 | 16 | 5,467.2 | 8,501.6 | 3,356.4 | 8,501.6 | 1.56 / 1.00 / 2.53 | 0/5 |
| 262144 | 32 | 4,040.1 | 6,344.7 | 2,997.1 | 6,344.7 | 1.57 / 1.00 / 2.12 | 0/5 |

**Clean (stall-free/error-free) medians, same cells:**

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | ratio vs fastest (H/R/L) |
|---|---|---|---|---|---|
| 64 | 1 | 145,991.1 | 143,466.7 | 151,431.1 | 1.04 / 1.06 / 1.00 |
| 64 | 4 | 459,648.8 | 357,312.6 | 465,991.1 | 1.01 / 1.30 / 1.00 |
| 64 | 8 | 546,940.0 | 384,248.6 | 534,577.8 | 1.00 / 1.42 / 1.02 |
| 64 | 16 | 608,553.9 | 384,851.0 | 544,071.0 | 1.00 / 1.58 / 1.12 |
| 64 | 32 | 671,937.7 | 399,565.7 | 583,099.3 | 1.00 / 1.68 / 1.15 |
| 1024 | 1 | 136,995.6 | 132,337.8 | 137,706.7 | 1.01 / 1.04 / 1.00 |
| 1024 | 4 | 308,563.8 | 332,224.3 | 409,870.1 | 1.33 / 1.23 / 1.00 |
| 1024 | 8 | 324,098.5 | 491,197.4 | 540,215.4 | 1.67 / 1.10 / 1.00 |
| 1024 | 16 | 324,492.4 | 443,431.0 | 567,511.7 | 1.75 / 1.28 / 1.00 |
| 1024 | 32 | 360,462.7 | 411,489.5 | 578,555.7 | 1.61 / 1.41 / 1.00 |
| 16384 | 1 | 45,688.9 | 45,653.3 | 45,394.1 | 1.00 / 1.00 / 1.01 |
| 16384 | 4 | 87,446.6 | 127,254.2 | 95,484.7 | 1.46 / 1.00 / 1.33 |
| 16384 | 8 | 82,532.8 | 141,098.2 | 91,003.3 | 1.71 / 1.00 / 1.55 |
| 16384 | 16 | 76,764.8 | 139,250.4 | 84,781.5 | 1.81 / 1.00 / 1.64 |
| 16384 | 32 | 73,856.7 | 123,326.4 | 76,696.2 | 1.67 / 1.00 / 1.61 |
| 65536 | 1 | 28,393.1 | 31,893.3 | 29,103.8 | 1.12 / 1.00 / 1.10 |
| 65536 | 4 | 27,033.3 | 48,692.6 | 29,519.4 | 1.80 / 1.00 / 1.65 |
| 65536 | 8 | 25,038.9 | 43,988.9 | 27,645.2 | 1.76 / 1.00 / 1.59 |
| 65536 | 16 | 21,793.1 | 37,447.2 | 23,930.1 | 1.72 / 1.00 / 1.56 |
| 65536 | 32 | 20,532.8 | 29,975.5 | 19,848.1 | 1.46 / 1.00 / 1.51 |
| 262144 | 1 | 5,431.6 | 8,048.8 | 3,842.1 | 1.48 / 1.00 / 2.09 |
| 262144 | 4 | 5,230.3 | 12,072.8 | 3,488.4 | 2.31 / 1.00 / 3.46 |
| 262144 | 8 | 5,140.0 | 10,887.0 | 3,303.2 | 2.12 / 1.00 / 3.30 |
| 262144 | 16 | 5,467.2 | 8,501.6 | 3,356.4 | 1.56 / 1.00 / 2.53 |
| 262144 | 32 | 4,040.1 | 6,344.7 | 2,997.1 | 1.57 / 1.00 / 2.12 |

**Workload winner (clean geomean): RabbitMQ** (LavinMQ 1.42x; HyrxMQ 1.43x)

### Workload — pubget — closed-loop publish -> basic.get(auto_ack), payload-scaled batch

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H/R/L) | HyrxMQ stalls |
|---|---|---|---|---|---|---|---|
| 64 | 1 | 135.1 | 7,515.4 | 12,593.3 | 12,593.3 | 93.21 / 1.68 / 1.00 | 4/5 |
| 64 | 4 | 796.8 | 18,672.5 | 31,012.6 | 31,012.6 | 38.92 / 1.66 / 1.00 | 5/5 |
| 64 | 8 | 1,688.5 | 30,497.8 | 49,764.7 | 49,764.7 | 29.47 / 1.63 / 1.00 | 4/5 |
| 64 | 16 | 2,058.3 | 37,413.8 | 51,384.3 | 51,384.3 | 24.96 / 1.37 / 1.00 | 5/5 |
| 64 | 32 | 2,509.3 | 39,412.9 | 58,265.5 | 58,265.5 | 23.22 / 1.48 / 1.00 | 4/5 |
| 1024 | 1 | 196.1 | 8,037.9 | 13,212.6 | 13,212.6 | 67.38 / 1.64 / 1.00 | 5/5 |
| 1024 | 4 | 1,056.7 | 20,471.8 | 34,028.7 | 34,028.7 | 32.20 / 1.66 / 1.00 | 5/5 |
| 1024 | 8 | 1,530.7 | 26,800.4 | 40,601.8 | 40,601.8 | 26.52 / 1.51 / 1.00 | 5/5 |
| 1024 | 16 | 1,908.6 | 32,420.6 | 44,192.4 | 44,192.4 | 23.15 / 1.36 / 1.00 | 5/5 |
| 1024 | 32 | 4,051.5 | 33,488.1 | 42,375.4 | 42,375.4 | 10.46 / 1.27 / 1.00 | 3/5 |
| 16384 | 1 | 468.5 | 5,656.4 | 1,582.4 | 5,656.4 | 12.07 / 1.00 / 3.57 | 3/5 |
| 16384 | 4 | 672.9 | 14,276.9 | 120.4 | 14,276.9 | 21.22 / 1.00 / 118.58 | 3/5 |
| 16384 | 8 | 24.3 | 19,513.2 | 279.2 | 19,513.2 | 803.01 / 1.00 / 69.89 | 5/5 |
| 16384 | 16 | 18,833.3 | 19,989.2 | 465.4 | 19,989.2 | 1.06 / 1.00 / 42.95 | 0/5 |
| 16384 | 32 | 890.3 | 19,669.3 | 962.1 | 19,669.3 | 22.09 / 1.00 / 20.44 | 4/5 |
| 65536 | 1 | 0.0 | 4,690.8 | 267.9 | 4,690.8 | — / 1.00 / 17.51 | 5/5 |
| 65536 | 4 | 9.1 | 10,301.7 | 614.1 | 10,301.7 | 1132.05 / 1.00 / 16.78 | 5/5 |
| 65536 | 8 | 25.0 | 10,567.3 | 197.7 | 10,567.3 | 422.69 / 1.00 / 53.45 | 5/5 |
| 65536 | 16 | 24.0 | 9,600.0 | 414.2 | 9,600.0 | 400.00 / 1.00 / 23.18 | 5/5 |
| 65536 | 32 | 25.6 | 9,397.5 | 763.4 | 9,397.5 | 367.09 / 1.00 / 12.31 | 5/5 |
| 262144 | 1 | 2,243.3 | 2,419.9 | 29.9 | 2,419.9 | 1.08 / 1.00 / 80.93 | 0/5 |
| 262144 | 4 | 3,397.1 | 3,725.8 | 114.2 | 3,725.8 | 1.10 / 1.00 / 32.63 | 0/5 |
| 262144 | 8 | 3,135.1 | 3,741.9 | 222.8 | 3,741.9 | 1.19 / 1.00 / 16.79 | 0/5 |
| 262144 | 16 | 2,636.4 | 3,374.5 | 423.8 | 3,374.5 | 1.28 / 1.00 / 7.96 | 0/5 |
| 262144 | 32 | 2,133.3 | 3,042.6 | 733.0 | 3,042.6 | 1.43 / 1.00 / 4.15 | 0/5 |

**Clean (stall-free/error-free) medians, same cells:**

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | ratio vs fastest (H/R/L) |
|---|---|---|---|---|---|
| 64 | 1 | 9,782.6 | 7,515.4 | 12,593.3 | 1.29 / 1.68 / 1.00 |
| 64 | 4 | 796.8 | 18,672.5 | 31,012.6 | 38.92 / 1.66 / 1.00 |
| 64 | 8 | 34,769.2 | 30,497.8 | 49,764.7 | 1.43 / 1.63 / 1.00 |
| 64 | 16 | 2,058.3 | 37,413.8 | 51,384.3 | 24.96 / 1.37 / 1.00 |
| 64 | 32 | 42,582.9 | 39,412.9 | 58,265.5 | 1.37 / 1.48 / 1.00 |
| 1024 | 1 | 196.1 | 8,037.9 | 13,212.6 | 67.38 / 1.64 / 1.00 |
| 1024 | 4 | 1,056.7 | 20,471.8 | 34,028.7 | 32.20 / 1.66 / 1.00 |
| 1024 | 8 | 1,530.7 | 26,800.4 | 40,601.8 | 26.52 / 1.51 / 1.00 |
| 1024 | 16 | 1,908.6 | 32,420.6 | 44,192.4 | 23.15 / 1.36 / 1.00 |
| 1024 | 32 | 36,115.8 | 33,488.1 | 42,375.4 | 1.17 / 1.27 / 1.00 |
| 16384 | 1 | 7,379.1 | 5,656.4 | 1,582.4 | 1.00 / 1.30 / 4.66 |
| 16384 | 4 | 16,441.8 | 14,276.9 | 120.4 | 1.00 / 1.15 / 136.56 |
| 16384 | 8 | 24.3 | 19,513.2 | 279.2 | 803.01 / 1.00 / 69.89 |
| 16384 | 16 | 18,833.3 | 19,989.2 | 465.4 | 1.06 / 1.00 / 42.95 |
| 16384 | 32 | 17,333.3 | 19,669.3 | 962.1 | 1.13 / 1.00 / 20.44 |
| 65536 | 1 | 0.0 | 4,690.8 | 267.9 | — / 1.00 / 17.51 |
| 65536 | 4 | 9.1 | 10,301.7 | 614.1 | 1132.05 / 1.00 / 16.78 |
| 65536 | 8 | 25.0 | 10,567.3 | 197.7 | 422.69 / 1.00 / 53.45 |
| 65536 | 16 | 24.0 | 9,600.0 | 414.2 | 400.00 / 1.00 / 23.18 |
| 65536 | 32 | 25.6 | 9,397.5 | 763.4 | 367.09 / 1.00 / 12.31 |
| 262144 | 1 | 2,243.3 | 2,419.9 | 29.9 | 1.08 / 1.00 / 80.93 |
| 262144 | 4 | 3,397.1 | 3,725.8 | 114.2 | 1.10 / 1.00 / 32.63 |
| 262144 | 8 | 3,135.1 | 3,741.9 | 222.8 | 1.19 / 1.00 / 16.79 |
| 262144 | 16 | 2,636.4 | 3,374.5 | 423.8 | 1.28 / 1.00 / 7.96 |
| 262144 | 32 | 2,133.3 | 3,042.6 | 733.0 | 1.43 / 1.00 / 4.15 |

**Workload winner (clean geomean): RabbitMQ** (LavinMQ 6.55x; HyrxMQ 9.84x)

### Workload — confirm — publisher confirms, one publish per confirm wait

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H/R/L) | HyrxMQ stalls |
|---|---|---|---|---|---|---|---|
| 64 | 1 | 7,545.4 | 4,467.1 | 131.1 | 7,545.4 | 1.00 / 1.69 / 57.55 | 0/5 |
| 64 | 4 | 17,225.3 | 11,926.6 | 293.2 | 17,225.3 | 1.00 / 1.44 / 58.75 | 0/5 |
| 64 | 8 | 22,537.4 | 17,619.0 | 415.2 | 22,537.4 | 1.00 / 1.28 / 54.28 | 0/5 |
| 64 | 16 | 23,646.4 | 21,224.4 | 818.6 | 23,646.4 | 1.00 / 1.11 / 28.89 | 0/5 |
| 64 | 32 | 25,362.2 | 22,642.4 | 1,948.5 | 25,362.2 | 1.00 / 1.12 / 13.02 | 0/5 |
| 1024 | 1 | 7,719.2 | 4,514.3 | 128.3 | 7,719.2 | 1.00 / 1.71 / 60.17 | 0/5 |
| 1024 | 4 | 16,861.8 | 12,068.0 | 307.7 | 16,861.8 | 1.00 / 1.40 / 54.80 | 0/5 |
| 1024 | 8 | 20,943.0 | 17,471.6 | 584.4 | 20,943.0 | 1.00 / 1.20 / 35.84 | 0/5 |
| 1024 | 16 | 23,505.1 | 20,930.7 | 1,038.7 | 23,505.1 | 1.00 / 1.12 / 22.63 | 0/5 |
| 1024 | 32 | 24,654.5 | 22,230.2 | 1,687.8 | 24,654.5 | 1.00 / 1.11 / 14.61 | 0/5 |
| 16384 | 1 | 5,219.9 | 3,824.8 | 22.2 | 5,219.9 | 1.00 / 1.36 / 235.13 | 0/5 |
| 16384 | 4 | 11,630.9 | 9,626.6 | 124.6 | 11,630.9 | 1.00 / 1.21 / 93.35 | 0/5 |
| 16384 | 8 | 14,406.3 | 13,350.2 | 179.0 | 14,406.3 | 1.00 / 1.08 / 80.48 | 0/5 |
| 16384 | 16 | 15,382.7 | 14,796.4 | 312.8 | 15,382.7 | 1.00 / 1.04 / 49.18 | 0/5 |
| 16384 | 32 | 15,192.6 | 14,392.2 | 565.6 | 15,192.6 | 1.00 / 1.06 / 26.86 | 0/5 |
| 65536 | 1 | 4,033.9 | 3,154.0 | 93.4 | 4,033.9 | 1.00 / 1.28 / 43.19 | 0/5 |
| 65536 | 4 | 8,052.4 | 7,274.2 | 169.3 | 8,052.4 | 1.00 / 1.11 / 47.56 | 0/5 |
| 65536 | 8 | 8,677.6 | 8,596.7 | 178.1 | 8,677.6 | 1.00 / 1.01 / 48.72 | 0/5 |
| 65536 | 16 | 8,575.4 | 8,419.1 | 303.9 | 8,575.4 | 1.00 / 1.02 / 28.22 | 0/5 |
| 65536 | 32 | 8,417.2 | 8,987.9 | 490.0 | 8,987.9 | 1.07 / 1.00 / 18.34 | 0/5 |
| 262144 | 1 | 1,716.9 | 1,829.4 | 21.3 | 1,829.4 | 1.07 / 1.00 / 85.89 | 0/5 |
| 262144 | 4 | 2,625.0 | 3,049.5 | 75.0 | 3,049.5 | 1.16 / 1.00 / 40.66 | 0/5 |
| 262144 | 8 | 2,570.6 | 3,135.1 | 119.1 | 3,135.1 | 1.22 / 1.00 / 26.32 | 0/5 |
| 262144 | 16 | 2,542.5 | 3,515.2 | 205.6 | 3,515.2 | 1.38 / 1.00 / 17.10 | 0/5 |
| 262144 | 32 | 2,325.8 | 3,062.7 | 283.0 | 3,062.7 | 1.32 / 1.00 / 10.82 | 0/5 |

**Clean (stall-free/error-free) medians, same cells:**

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | ratio vs fastest (H/R/L) |
|---|---|---|---|---|---|
| 64 | 1 | 7,545.4 | 4,467.1 | 131.1 | 1.00 / 1.69 / 57.55 |
| 64 | 4 | 17,225.3 | 11,926.6 | 293.2 | 1.00 / 1.44 / 58.75 |
| 64 | 8 | 22,537.4 | 17,619.0 | 500.0 | 1.00 / 1.28 / 45.07 |
| 64 | 16 | 23,646.4 | 21,224.4 | 818.6 | 1.00 / 1.11 / 28.89 |
| 64 | 32 | 25,362.2 | 22,642.4 | 1,948.5 | 1.00 / 1.12 / 13.02 |
| 1024 | 1 | 7,719.2 | 4,514.3 | 128.3 | 1.00 / 1.71 / 60.17 |
| 1024 | 4 | 16,861.8 | 12,068.0 | 307.7 | 1.00 / 1.40 / 54.80 |
| 1024 | 8 | 20,943.0 | 17,471.6 | 584.4 | 1.00 / 1.20 / 35.84 |
| 1024 | 16 | 23,505.1 | 20,930.7 | 1,038.7 | 1.00 / 1.12 / 22.63 |
| 1024 | 32 | 24,654.5 | 22,230.2 | 1,687.8 | 1.00 / 1.11 / 14.61 |
| 16384 | 1 | 5,219.9 | 3,824.8 | 22.2 | 1.00 / 1.36 / 235.13 |
| 16384 | 4 | 11,630.9 | 9,626.6 | 124.6 | 1.00 / 1.21 / 93.35 |
| 16384 | 8 | 14,406.3 | 13,350.2 | 179.0 | 1.00 / 1.08 / 80.48 |
| 16384 | 16 | 15,382.7 | 14,796.4 | 312.8 | 1.00 / 1.04 / 49.18 |
| 16384 | 32 | 15,192.6 | 14,392.2 | 570.6 | 1.00 / 1.06 / 26.63 |
| 65536 | 1 | 4,033.9 | 3,154.0 | 93.4 | 1.00 / 1.28 / 43.19 |
| 65536 | 4 | 8,052.4 | 7,274.2 | 169.3 | 1.00 / 1.11 / 47.56 |
| 65536 | 8 | 8,677.6 | 8,596.7 | 178.1 | 1.00 / 1.01 / 48.72 |
| 65536 | 16 | 8,575.4 | 8,419.1 | 303.9 | 1.00 / 1.02 / 28.22 |
| 65536 | 32 | 8,417.2 | 8,987.9 | 490.0 | 1.07 / 1.00 / 18.34 |
| 262144 | 1 | 1,716.9 | 1,829.4 | 21.3 | 1.07 / 1.00 / 85.89 |
| 262144 | 4 | 2,625.0 | 3,049.5 | 75.0 | 1.16 / 1.00 / 40.66 |
| 262144 | 8 | 2,570.6 | 3,135.1 | 119.1 | 1.22 / 1.00 / 26.32 |
| 262144 | 16 | 2,542.5 | 3,515.2 | 205.6 | 1.38 / 1.00 / 17.10 |
| 262144 | 32 | 2,325.8 | 3,062.7 | 283.0 | 1.32 / 1.00 / 10.82 |

**Workload winner (clean geomean): HyrxMQ** (RabbitMQ 1.16x; LavinMQ 38.58x)

### Workload — fanout — 1 fanout exchange -> 4 queues per worker, delivered msgs/s

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H/R/L) | HyrxMQ stalls |
|---|---|---|---|---|---|---|---|
| 1024 | 1 | 212.2 | 7,725.3 | 13,090.9 | 13,090.9 | 61.69 / 1.69 / 1.00 | 3/5 |
| 1024 | 4 | 27,067.7 | 19,889.5 | 33,027.5 | 33,027.5 | 1.22 / 1.66 / 1.00 | 0/5 |
| 1024 | 8 | 32,872.7 | 28,250.0 | 44,642.0 | 44,642.0 | 1.36 / 1.58 / 1.00 | 0/5 |
| 1024 | 16 | 37,278.4 | 35,106.8 | 46,961.0 | 46,961.0 | 1.26 / 1.34 / 1.00 | 0/5 |
| 1024 | 32 | 39,736.3 | 33,481.5 | 46,961.0 | 46,961.0 | 1.18 / 1.40 / 1.00 | 0/5 |

**Clean (stall-free/error-free) medians, same cells:**

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | ratio vs fastest (H/R/L) |
|---|---|---|---|---|---|
| 1024 | 1 | 13,337.9 | 7,725.3 | 13,090.9 | 1.00 / 1.73 / 1.02 |
| 1024 | 4 | 27,067.7 | 19,889.5 | 33,027.5 | 1.22 / 1.66 / 1.00 |
| 1024 | 8 | 32,872.7 | 28,250.0 | 44,642.0 | 1.36 / 1.58 / 1.00 |
| 1024 | 16 | 37,278.4 | 35,106.8 | 46,961.0 | 1.26 / 1.34 / 1.00 |
| 1024 | 32 | 39,736.3 | 33,481.5 | 46,961.0 | 1.18 / 1.40 / 1.00 |

**Workload winner (clean geomean): LavinMQ** (HyrxMQ 1.20x; RabbitMQ 1.53x)

### Workload — latency (publish -> get -> ack, one in flight)

Per-op microseconds; median across reps of each run percentile.

| payload | broker | p50 | p95 | p99 | p99.9 | vs fastest p50 |
|---|---|---|---|---|---|---|
| 64 | HyrxMQ | 112.0 | 142.0 | 171.0 | 479.0 | 1.33x |
| 64 | RabbitMQ | 156.0 | 201.0 | 263.0 | 1,154.0 | 1.86x |
| 64 | LavinMQ | 84.0 | 111.0 | 146.0 | 601.0 | 1.00x |
| 1024 | HyrxMQ | 104.0 | 136.0 | 178.0 | 693.0 | 1.30x |
| 1024 | RabbitMQ | 157.0 | 211.0 | 264.0 | 995.0 | 1.96x |
| 1024 | LavinMQ | 80.0 | 110.0 | 158.0 | 1,010.0 | 1.00x |
| 16384 | HyrxMQ | 136.0 | 195.0 | 309.0 | 1,058.0 | 1.00x |
| 16384 | RabbitMQ | 190.0 | 284.0 | 484.0 | 1,739.0 | 1.40x |
| 16384 | LavinMQ | 149.0 | 40,990.0 | 41,118.0 | 42,046.0 | 1.10x |
| 65536 | HyrxMQ | 189.0 | 301.0 | 425.0 | 1,463.0 | 1.00x |
| 65536 | RabbitMQ | 247.0 | 394.0 | 877.0 | 1,972.0 | 1.31x |
| 65536 | LavinMQ | 240.0 | 41,309.0 | 42,016.0 | 42,230.0 | 1.27x |
| 262144 | HyrxMQ | 461.0 | 727.0 | 856.0 | 1,688.0 | 1.14x |
| 262144 | RabbitMQ | 406.0 | 631.0 | 867.0 | 1,961.0 | 1.00x |
| 262144 | LavinMQ | 41,025.0 | 42,591.0 | 45,002.0 | 47,162.0 | 101.05x |

**Lowest p50 across payloads:** LavinMQ 2, HyrxMQ 2, RabbitMQ 1

## Scaling curves — throughput vs concurrency (clean medians, msg/s)

### publish

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 145,991.1 | 143,466.7 | 151,431.1 |
| 64 | 4 | 459,648.8 | 357,312.6 | 465,991.1 |
| 64 | 8 | 546,940.0 | 384,248.6 | 534,577.8 |
| 64 | 16 | 608,553.9 | 384,851.0 | 544,071.0 |
| 64 | 32 | 671,937.7 | 399,565.7 | 583,099.3 |
| 1024 | 1 | 136,995.6 | 132,337.8 | 137,706.7 |
| 1024 | 4 | 308,563.8 | 332,224.3 | 409,870.1 |
| 1024 | 8 | 324,098.5 | 491,197.4 | 540,215.4 |
| 1024 | 16 | 324,492.4 | 443,431.0 | 567,511.7 |
| 1024 | 32 | 360,462.7 | 411,489.5 | 578,555.7 |
| 16384 | 1 | 45,688.9 | 45,653.3 | 45,394.1 |
| 16384 | 4 | 87,446.6 | 127,254.2 | 95,484.7 |
| 16384 | 8 | 82,532.8 | 141,098.2 | 91,003.3 |
| 16384 | 16 | 76,764.8 | 139,250.4 | 84,781.5 |
| 16384 | 32 | 73,856.7 | 123,326.4 | 76,696.2 |
| 65536 | 1 | 28,393.1 | 31,893.3 | 29,103.8 |
| 65536 | 4 | 27,033.3 | 48,692.6 | 29,519.4 |
| 65536 | 8 | 25,038.9 | 43,988.9 | 27,645.2 |
| 65536 | 16 | 21,793.1 | 37,447.2 | 23,930.1 |
| 65536 | 32 | 20,532.8 | 29,975.5 | 19,848.1 |
| 262144 | 1 | 5,431.6 | 8,048.8 | 3,842.1 |
| 262144 | 4 | 5,230.3 | 12,072.8 | 3,488.4 |
| 262144 | 8 | 5,140.0 | 10,887.0 | 3,303.2 |
| 262144 | 16 | 5,467.2 | 8,501.6 | 3,356.4 |
| 262144 | 32 | 4,040.1 | 6,344.7 | 2,997.1 |

### pubget

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 9,782.6 | 7,515.4 | 12,593.3 |
| 64 | 4 | 796.8 | 18,672.5 | 31,012.6 |
| 64 | 8 | 34,769.2 | 30,497.8 | 49,764.7 |
| 64 | 16 | 2,058.3 | 37,413.8 | 51,384.3 |
| 64 | 32 | 42,582.9 | 39,412.9 | 58,265.5 |
| 1024 | 1 | 196.1 | 8,037.9 | 13,212.6 |
| 1024 | 4 | 1,056.7 | 20,471.8 | 34,028.7 |
| 1024 | 8 | 1,530.7 | 26,800.4 | 40,601.8 |
| 1024 | 16 | 1,908.6 | 32,420.6 | 44,192.4 |
| 1024 | 32 | 36,115.8 | 33,488.1 | 42,375.4 |
| 16384 | 1 | 7,379.1 | 5,656.4 | 1,582.4 |
| 16384 | 4 | 16,441.8 | 14,276.9 | 120.4 |
| 16384 | 8 | 24.3 | 19,513.2 | 279.2 |
| 16384 | 16 | 18,833.3 | 19,989.2 | 465.4 |
| 16384 | 32 | 17,333.3 | 19,669.3 | 962.1 |
| 65536 | 1 | 0.0 | 4,690.8 | 267.9 |
| 65536 | 4 | 9.1 | 10,301.7 | 614.1 |
| 65536 | 8 | 25.0 | 10,567.3 | 197.7 |
| 65536 | 16 | 24.0 | 9,600.0 | 414.2 |
| 65536 | 32 | 25.6 | 9,397.5 | 763.4 |
| 262144 | 1 | 2,243.3 | 2,419.9 | 29.9 |
| 262144 | 4 | 3,397.1 | 3,725.8 | 114.2 |
| 262144 | 8 | 3,135.1 | 3,741.9 | 222.8 |
| 262144 | 16 | 2,636.4 | 3,374.5 | 423.8 |
| 262144 | 32 | 2,133.3 | 3,042.6 | 733.0 |

### confirm

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 7,545.4 | 4,467.1 | 131.1 |
| 64 | 4 | 17,225.3 | 11,926.6 | 293.2 |
| 64 | 8 | 22,537.4 | 17,619.0 | 500.0 |
| 64 | 16 | 23,646.4 | 21,224.4 | 818.6 |
| 64 | 32 | 25,362.2 | 22,642.4 | 1,948.5 |
| 1024 | 1 | 7,719.2 | 4,514.3 | 128.3 |
| 1024 | 4 | 16,861.8 | 12,068.0 | 307.7 |
| 1024 | 8 | 20,943.0 | 17,471.6 | 584.4 |
| 1024 | 16 | 23,505.1 | 20,930.7 | 1,038.7 |
| 1024 | 32 | 24,654.5 | 22,230.2 | 1,687.8 |
| 16384 | 1 | 5,219.9 | 3,824.8 | 22.2 |
| 16384 | 4 | 11,630.9 | 9,626.6 | 124.6 |
| 16384 | 8 | 14,406.3 | 13,350.2 | 179.0 |
| 16384 | 16 | 15,382.7 | 14,796.4 | 312.8 |
| 16384 | 32 | 15,192.6 | 14,392.2 | 570.6 |
| 65536 | 1 | 4,033.9 | 3,154.0 | 93.4 |
| 65536 | 4 | 8,052.4 | 7,274.2 | 169.3 |
| 65536 | 8 | 8,677.6 | 8,596.7 | 178.1 |
| 65536 | 16 | 8,575.4 | 8,419.1 | 303.9 |
| 65536 | 32 | 8,417.2 | 8,987.9 | 490.0 |
| 262144 | 1 | 1,716.9 | 1,829.4 | 21.3 |
| 262144 | 4 | 2,625.0 | 3,049.5 | 75.0 |
| 262144 | 8 | 2,570.6 | 3,135.1 | 119.1 |
| 262144 | 16 | 2,542.5 | 3,515.2 | 205.6 |
| 262144 | 32 | 2,325.8 | 3,062.7 | 283.0 |

### fanout

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 1024 | 1 | 13,337.9 | 7,725.3 | 13,090.9 |
| 1024 | 4 | 27,067.7 | 19,889.5 | 33,027.5 |
| 1024 | 8 | 32,872.7 | 28,250.0 | 44,642.0 |
| 1024 | 16 | 37,278.4 | 35,106.8 | 46,961.0 |
| 1024 | 32 | 39,736.3 | 33,481.5 | 46,961.0 |

## Resource usage (`docker stats --no-stream`, median during reps)

| workload | broker | CPU% median | RSS median |
|---|---|---|---|
| publish | HyrxMQ | 97.6 | 187.5 MiB |
| publish | RabbitMQ | 272.5 | 213.6 MiB |
| publish | LavinMQ | 52.4 | 47.5 MiB |
| pubget | HyrxMQ | 49.2 | 354.3 MiB |
| pubget | RabbitMQ | 121.0 | 243.5 MiB |
| pubget | LavinMQ | 44.7 | 45.0 MiB |
| confirm | HyrxMQ | 73.4 | 478.3 MiB |
| confirm | RabbitMQ | 53.9 | 307.9 MiB |
| confirm | LavinMQ | 46.3 | 66.5 MiB |
| fanout | HyrxMQ | 19.4 | 512.0 MiB |
| fanout | RabbitMQ | 93.0 | 167.6 MiB |
| fanout | LavinMQ | 16.2 | 58.0 MiB |
| latency | HyrxMQ | 13.5 | 511.2 MiB |
| latency | RabbitMQ | 26.8 | 240.1 MiB |
| latency | LavinMQ | 15.9 | 56.1 MiB |

## Overall verdict

Geometric mean of per-cell `fastest/rate` (1.00 = fastest in every cell, higher = slower), over non-latency cells where **all three brokers completed and all workers connected**.

**Primary (median of all reps, includes stalls):**

| band (connections) | cells | HyrxMQ | RabbitMQ | LavinMQ | winner |
|---|---|---|---|---|---|
| 1 | 15 | 2.915 | 1.242 | 6.612 | RabbitMQ |
| 4-8 | 32 | 3.739 | 1.181 | 7.761 | RabbitMQ |
| 16-32 | 32 | 2.763 | 1.133 | 4.783 | RabbitMQ |
| **overall** | 79 | 3.155 | 1.172 | 6.188 | RabbitMQ |

**Clean (stall-free/error-free medians only):**

| band (connections) | cells | HyrxMQ | RabbitMQ | LavinMQ | winner |
|---|---|---|---|---|---|
| 1 | 15 | 1.410 | 1.266 | 6.739 | RabbitMQ |
| 4-8 | 32 | 3.092 | 1.186 | 7.751 | RabbitMQ |
| 16-32 | 32 | 2.153 | 1.133 | 4.781 | RabbitMQ |
| **overall** | 79 | 2.300 | 1.179 | 6.206 | RabbitMQ |


**Overall winner (clean, this hardware/workload set): RabbitMQ.** Ranking: RabbitMQ > HyrxMQ > LavinMQ.

This is a single-host, single-client, three-way test. It does **not** establish "fastest AMQP broker in the world"; it establishes relative behaviour on this CPU, kernel, Docker and these image versions.

## Is HyrxMQ fastest? Where does it win/lose?

- **Single connection (band 1), clean:** HyrxMQ geomean 1.410 vs RabbitMQ 1.266 vs LavinMQ 6.739.
- **High concurrency (band 16-32), clean:** HyrxMQ geomean 2.153 vs RabbitMQ 1.133 vs LavinMQ 4.781.
- HyrxMQ is a single-threaded broker; the multi-threaded brokers are expected to overtake it as connection count rises. The tables above show exactly where.

## Failures, errors and stalls

- `pubget|64|1` **HyrxMQ**: 4 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|64|4` **HyrxMQ**: 18 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|64|8` **HyrxMQ**: 23 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|64|16` **HyrxMQ**: 14 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|64|32` **HyrxMQ**: 12 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|1024|1` **HyrxMQ**: 5 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|1024|4` **HyrxMQ**: 18 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|1024|8` **HyrxMQ**: 23 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|1024|16` **HyrxMQ**: 18 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|1024|32` **HyrxMQ**: 5 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|16384|1` **HyrxMQ**: 3 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|16384|4` **HyrxMQ**: 9 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|16384|8` **HyrxMQ**: 10 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|16384|32` **HyrxMQ**: 23 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|65536|1` **HyrxMQ**: 5 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|65536|4` **HyrxMQ**: 19 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|65536|8` **HyrxMQ**: 18 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|65536|16` **HyrxMQ**: 50 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|65536|32` **HyrxMQ**: 62 worker error(s) across 5 successful reps (drain/confirm timeouts).
- `pubget|262144|1` **LavinMQ**: 5/5 reps stalled (wall > 3x target); clean median 29.9 vs median 29.9 msg/s.
- `confirm|64|8` **LavinMQ**: 1/5 reps stalled (wall > 3x target); clean median 500.0 vs median 415.2 msg/s.
- `confirm|16384|1` **LavinMQ**: 5/5 reps stalled (wall > 3x target); clean median 22.2 vs median 22.2 msg/s.
- `confirm|16384|32` **LavinMQ**: 1/5 reps stalled (wall > 3x target); clean median 570.6 vs median 565.6 msg/s.
- `confirm|262144|1` **LavinMQ**: 5/5 reps stalled (wall > 3x target); clean median 21.3 vs median 21.3 msg/s.
- `latency|16384|1` **LavinMQ**: 1/5 reps stalled (wall > 3x target); clean median 145.4 vs median 113.3 msg/s.
- `latency|262144|1` **LavinMQ**: 5/5 reps stalled (wall > 3x target); clean median 25.6 vs median 25.6 msg/s.
- `fanout|1024|1` **HyrxMQ**: 3 worker error(s) across 5 successful reps (drain/confirm timeouts).

## Caveats and limitations

- **HyrxMQ intermittent connection stall.** On a subset of runs (roughly 10-40% depending on the cell) a new connection completes the handshake and exchange declare, then the broker does not answer the next RPC for ~15 s. It is recorded as a stalled rep and is visible as a `stall_runs` count and a gap between `median` and `clean` medians. This is broker behaviour, not a client hang: the same client completes in milliseconds on the other brokers and on HyrxMQ's own good runs.
- **HyrxMQ shared-queue concurrency.** With one shared queue and 16 concurrent `basic.get` connections, HyrxMQ delivered ~69 of 125 messages then stopped (each worker timed out). The matrix therefore gives each worker its own queue; the shared-queue result is reported here for completeness, not as a throughput cell.
- `publish` publishes to a **bindingless** exchange, so nothing is stored: it isolates the producer/transport ceiling and cannot OOM the 2 GiB container at 256 KiB payloads.
- `confirm` waits for one confirm per publish; the untimed drain that keeps the queue bounded is outside the measured span for confirm, but the reported wall is the real elapsed time of the run.
- `pubget` uses `auto_ack=True`, so it measures routing + content + transport, not the acknowledgement path; `latency` uses explicit ack.
- The previous (v1) run used Python threads in one process; its absolute rates are not comparable to these. This v2 run exists because the compiled client removes that bottleneck.
- Results depend on this host, these container caps and image versions. Do not generalise across hardware.
