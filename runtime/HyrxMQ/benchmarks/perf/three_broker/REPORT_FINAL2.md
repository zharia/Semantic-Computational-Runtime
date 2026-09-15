# Three-Broker AMQP Performance Benchmark — FINAL2 (post-optimization)

**HyrxMQ vs RabbitMQ vs LavinMQ — post-optimization run on one host, all three brokers in Docker, one compiled Go load generator.**

- Run id: `20260915T064807Z`
- Started (UTC): 2026-09-15T06:48:07Z · finished 2026-09-15T08:04:22Z
- Mode: full · replicates per cell: 7 (median reported) · target rep >= 2.0 s
- Consolidated data: `results/v2_consolidated_20260915T064807Z.json`

## Host, software and image digests

- CPU: AMD Ryzen 5 3600 6-Core Processor (12 logical CPUs)
- RAM: 15.54 GiB · kernel 7.2.4-3-cachyos · machine x86_64
- Docker server 29.8.0 · client Go go version go1.27.1-X:nodwarf5 linux/amd64 · module `github.com/rabbitmq/amqp091-go`
- CPU governor: `powersave` · host loadavg(1m) at start: 5.33

| broker | image | image id |
|---|---|---|
| HyrxMQ | `hyrxmq:latest` | `sha256:236d4e0742a227e6d3b1ed259bcf6c763452c58911cf8807c3d712815d5dcd39` |
| RabbitMQ | `rabbitmq:4-management` | `sha256:ffd1b50c522ad20172ffd6716a2f41db375c7269560c8f3fb9a694e210ef0852` |
| LavinMQ | `cloudamqp/lavinmq:latest` | `sha256:0fa126ed80521a50f8a0ac575a5d7bb7447376c3c6bb829a38b85685b9340664` |

## Methodology and fairness notes

- All three brokers run in their own container on **one user-defined bridge** (`hyrxmq-bench2`), each published on `127.0.0.1`, so every client connection crosses the **same docker-proxy hop**.
- Each container is capped identically: `--cpus 4 --memory 2g`.
- **One compiled client binary** (`/tmp/loadgen`, Go + amqp091-go, one goroutine + connection + channel per worker) drives every broker.
- Each worker opens its **own connection + channel** and its **own exchange and queue(s)**; queues are durable, non-exclusive, non-auto-delete, pre-declared and purged before each run.
- Identical protocol settings: `delivery_mode=1`, `frame_max=131072`, `heartbeat=30s`, `auto_ack=True` for `pubget` throughput, explicit ack in `latency`.
- Hit counts are **calibrated per broker/workload/payload/concurrency** to a >= 2 s measured window, then clamped; `publish` runs a fixed duration. The first 10% of every run is discarded as warm-up.
- `7` reps per cell, **brokers rotated across reps** to cancel drift; the **median** is reported.
- Batches are payload-scaled (~512 KiB in flight) so a 256 KiB payload at 32 connections cannot exhaust the 2 GiB container cap.
- CPU% and RSS are sampled every ~1 s from `docker stats --no-stream` for exactly the three benchmark containers.
- **Primary median** uses every successful rep; **clean median** drops reps that errored or whose wall time was > 3x target (stalls). The headline verdict uses the primary median; the clean median is shown as a robustness check.

## Complete results table (throughput cells)

Every throughput cell, all three brokers, primary median msg/s (all reps), the cell winner, and each broker's ratio vs the fastest (1.00 = fastest). "fastest" column is the winning rate. Ratio > 1 = slower. H = HyrxMQ, R = RabbitMQ, L = LavinMQ.

| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest (broker) | H ratio | R ratio | L ratio |
|---|---|---|---|---|---|---|---|---|---|
| publish | 64 | 1 | 146,844.4 | 151,360.0 | 151,182.2 | 151,360.0 (RabbitMQ) | 1.03 | 1.00 | 1.00 |
| publish | 64 | 4 | 474,702.2 | 378,776.2 | 482,488.9 | 482,488.9 (LavinMQ) | 1.02 | 1.27 | 1.00 |
| publish | 64 | 8 | 671,588.1 | 409,870.1 | 566,973.9 | 671,588.1 (HyrxMQ) | 1.00 | 1.64 | 1.18 |
| publish | 64 | 16 | 643,018.9 | 457,756.1 | 610,434.2 | 643,018.9 (HyrxMQ) | 1.00 | 1.40 | 1.05 |
| publish | 64 | 32 | 676,490.3 | 440,474.8 | 631,592.0 | 676,490.3 (HyrxMQ) | 1.00 | 1.54 | 1.07 |
| publish | 1024 | 1 | 140,302.2 | 140,835.6 | 140,728.9 | 140,835.6 (RabbitMQ) | 1.00 | 1.00 | 1.00 |
| publish | 1024 | 4 | 497,340.0 | 355,342.2 | 443,982.2 | 497,340.0 (HyrxMQ) | 1.00 | 1.40 | 1.12 |
| publish | 1024 | 8 | 497,289.8 | 511,580.8 | 546,947.8 | 546,947.8 (LavinMQ) | 1.10 | 1.07 | 1.00 |
| publish | 1024 | 16 | 537,237.0 | 440,577.1 | 560,124.3 | 560,124.3 (LavinMQ) | 1.04 | 1.27 | 1.00 |
| publish | 1024 | 32 | 592,325.5 | 358,896.4 | 569,011.1 | 592,325.5 (HyrxMQ) | 1.00 | 1.65 | 1.04 |
| publish | 16384 | 1 | 48,177.8 | 47,689.1 | 48,071.1 | 48,177.8 (HyrxMQ) | 1.00 | 1.01 | 1.00 |
| publish | 16384 | 4 | 137,011.1 | 133,824.6 | 108,345.9 | 137,011.1 (HyrxMQ) | 1.00 | 1.02 | 1.26 |
| publish | 16384 | 8 | 134,477.4 | 161,203.5 | 106,087.5 | 161,203.5 (RabbitMQ) | 1.20 | 1.00 | 1.52 |
| publish | 16384 | 16 | 136,986.1 | 151,173.0 | 101,304.1 | 151,173.0 (RabbitMQ) | 1.10 | 1.00 | 1.49 |
| publish | 16384 | 32 | 136,997.9 | 132,765.2 | 94,279.2 | 136,997.9 (HyrxMQ) | 1.00 | 1.03 | 1.45 |
| publish | 65536 | 1 | 33,528.9 | 33,884.4 | 34,628.2 | 34,628.2 (LavinMQ) | 1.03 | 1.02 | 1.00 |
| publish | 65536 | 4 | 39,991.2 | 51,569.4 | 31,115.0 | 51,569.4 (RabbitMQ) | 1.29 | 1.00 | 1.66 |
| publish | 65536 | 8 | 40,367.6 | 48,274.5 | 30,466.1 | 48,274.5 (RabbitMQ) | 1.20 | 1.00 | 1.58 |
| publish | 65536 | 16 | 42,929.8 | 41,203.1 | 29,436.5 | 42,929.8 (HyrxMQ) | 1.00 | 1.04 | 1.46 |
| publish | 65536 | 32 | 41,272.3 | 32,449.2 | 26,538.3 | 41,272.3 (HyrxMQ) | 1.00 | 1.27 | 1.56 |
| publish | 262144 | 1 | 10,921.6 | 10,542.0 | 4,418.7 | 10,921.6 (HyrxMQ) | 1.00 | 1.04 | 2.47 |
| publish | 262144 | 4 | 11,341.8 | 13,592.9 | 4,273.8 | 13,592.9 (RabbitMQ) | 1.20 | 1.00 | 3.18 |
| publish | 262144 | 8 | 11,077.6 | 11,110.6 | 4,169.4 | 11,110.6 (RabbitMQ) | 1.00 | 1.00 | 2.66 |
| publish | 262144 | 16 | 10,930.9 | 8,864.2 | 3,474.5 | 10,930.9 (HyrxMQ) | 1.00 | 1.23 | 3.15 |
| publish | 262144 | 32 | 10,831.8 | 6,856.0 | 3,381.4 | 10,831.8 (HyrxMQ) | 1.00 | 1.58 | 3.20 |
| pubget | 64 | 1 | 15,039.8 | 8,996.3 | 15,106.4 | 15,106.4 (LavinMQ) | 1.00 | 1.68 | 1.00 |
| pubget | 64 | 4 | 34,386.1 | 22,211.4 | 37,391.8 | 37,391.8 (LavinMQ) | 1.09 | 1.68 | 1.00 |
| pubget | 64 | 8 | 42,956.7 | 31,880.9 | 50,196.6 | 50,196.6 (LavinMQ) | 1.17 | 1.57 | 1.00 |
| pubget | 64 | 16 | 47,219.4 | 38,230.0 | 56,028.2 | 56,028.2 (LavinMQ) | 1.19 | 1.47 | 1.00 |
| pubget | 64 | 32 | 50,263.1 | 40,633.1 | 57,485.2 | 57,485.2 (LavinMQ) | 1.14 | 1.41 | 1.00 |
| pubget | 1024 | 1 | 14,626.2 | 8,638.1 | 14,317.3 | 14,626.2 (HyrxMQ) | 1.00 | 1.69 | 1.02 |
| pubget | 1024 | 4 | 32,158.8 | 21,285.9 | 34,486.4 | 34,486.4 (LavinMQ) | 1.07 | 1.62 | 1.00 |
| pubget | 1024 | 8 | 40,986.2 | 31,030.9 | 46,455.0 | 46,455.0 (LavinMQ) | 1.13 | 1.50 | 1.00 |
| pubget | 1024 | 16 | 45,093.7 | 36,804.6 | 50,041.3 | 50,041.3 (LavinMQ) | 1.11 | 1.36 | 1.00 |
| pubget | 1024 | 32 | 47,233.7 | 38,858.6 | 51,598.2 | 51,598.2 (LavinMQ) | 1.09 | 1.33 | 1.00 |
| pubget | 16384 | 1 | 9,778.5 | 6,561.2 | 2,420.4 | 9,778.5 (HyrxMQ) | 1.00 | 1.49 | 4.04 |
| pubget | 16384 | 4 | 18,907.7 | 14,777.6 | 114.0 | 18,907.7 (HyrxMQ) | 1.00 | 1.28 | 165.86 |
| pubget | 16384 | 8 | 22,419.5 | 20,043.5 | 259.9 | 22,419.5 (HyrxMQ) | 1.00 | 1.12 | 86.26 |
| pubget | 16384 | 16 | 24,710.2 | 21,410.7 | 494.9 | 24,710.2 (HyrxMQ) | 1.00 | 1.15 | 49.93 |
| pubget | 16384 | 32 | 24,710.2 | 20,748.2 | 1,010.6 | 24,710.2 (HyrxMQ) | 1.00 | 1.19 | 24.45 |
| pubget | 65536 | 1 | 6,502.6 | 4,580.1 | 233.8 | 6,502.6 (HyrxMQ) | 1.00 | 1.42 | 27.81 |
| pubget | 65536 | 4 | 11,142.0 | 9,629.2 | 137.5 | 11,142.0 (HyrxMQ) | 1.00 | 1.16 | 81.03 |
| pubget | 65536 | 8 | 12,013.0 | 10,447.6 | 211.3 | 12,013.0 (HyrxMQ) | 1.00 | 1.15 | 56.85 |
| pubget | 65536 | 16 | 12,118.0 | 9,777.8 | 408.7 | 12,118.0 (HyrxMQ) | 1.00 | 1.24 | 29.65 |
| pubget | 65536 | 32 | 11,214.5 | 9,666.7 | 796.4 | 11,214.5 (HyrxMQ) | 1.00 | 1.16 | 14.08 |
| pubget | 262144 | 1 | 2,634.3 | 2,282.2 | 29.5 | 2,634.3 (HyrxMQ) | 1.00 | 1.15 | 89.30 |
| pubget | 262144 | 4 | 4,162.2 | 3,882.4 | 112.2 | 4,162.2 (HyrxMQ) | 1.00 | 1.07 | 37.10 |
| pubget | 262144 | 8 | 4,142.9 | 3,899.2 | 216.0 | 4,142.9 (HyrxMQ) | 1.00 | 1.06 | 19.18 |
| pubget | 262144 | 16 | 3,279.2 | 3,501.9 | 420.9 | 3,501.9 (RabbitMQ) | 1.07 | 1.00 | 8.32 |
| pubget | 262144 | 32 | 2,829.3 | 2,955.4 | 726.7 | 2,955.4 (RabbitMQ) | 1.04 | 1.00 | 4.07 |
| confirm | 64 | 1 | 7,813.2 | 4,358.9 | 107.1 | 7,813.2 (HyrxMQ) | 1.00 | 1.79 | 72.95 |
| confirm | 64 | 4 | 16,684.8 | 12,269.7 | 282.6 | 16,684.8 (HyrxMQ) | 1.00 | 1.36 | 59.04 |
| confirm | 64 | 8 | 21,966.1 | 17,692.3 | 459.1 | 21,966.1 (HyrxMQ) | 1.00 | 1.24 | 47.85 |
| confirm | 64 | 16 | 24,688.9 | 21,136.0 | 1,047.8 | 24,688.9 (HyrxMQ) | 1.00 | 1.17 | 23.56 |
| confirm | 64 | 32 | 25,244.7 | 21,790.7 | 1,377.8 | 25,244.7 (HyrxMQ) | 1.00 | 1.16 | 18.32 |
| confirm | 1024 | 1 | 7,917.4 | 4,512.0 | 134.5 | 7,917.4 (HyrxMQ) | 1.00 | 1.75 | 58.87 |
| confirm | 1024 | 4 | 16,531.6 | 12,262.7 | 371.0 | 16,531.6 (HyrxMQ) | 1.00 | 1.35 | 44.56 |
| confirm | 1024 | 8 | 21,448.4 | 17,565.7 | 357.7 | 21,448.4 (HyrxMQ) | 1.00 | 1.22 | 59.96 |
| confirm | 1024 | 16 | 25,159.3 | 20,987.5 | 721.7 | 25,159.3 (HyrxMQ) | 1.00 | 1.20 | 34.86 |
| confirm | 1024 | 32 | 25,636.9 | 21,396.7 | 1,294.6 | 25,636.9 (HyrxMQ) | 1.00 | 1.20 | 19.80 |
| confirm | 16384 | 1 | 4,891.6 | 3,517.1 | 21.6 | 4,891.6 (HyrxMQ) | 1.00 | 1.39 | 226.46 |
| confirm | 16384 | 4 | 11,441.4 | 9,825.4 | 93.1 | 11,441.4 (HyrxMQ) | 1.00 | 1.16 | 122.89 |
| confirm | 16384 | 8 | 14,322.3 | 13,124.6 | 173.4 | 14,322.3 (HyrxMQ) | 1.00 | 1.09 | 82.60 |
| confirm | 16384 | 16 | 16,193.2 | 14,931.2 | 322.9 | 16,193.2 (HyrxMQ) | 1.00 | 1.08 | 50.15 |
| confirm | 16384 | 32 | 16,211.0 | 14,462.7 | 417.0 | 16,211.0 (HyrxMQ) | 1.00 | 1.12 | 38.88 |
| confirm | 65536 | 1 | 4,003.3 | 3,064.8 | 80.4 | 4,003.3 (HyrxMQ) | 1.00 | 1.31 | 49.79 |
| confirm | 65536 | 4 | 8,177.4 | 6,919.3 | 80.8 | 8,177.4 (HyrxMQ) | 1.00 | 1.18 | 101.21 |
| confirm | 65536 | 8 | 9,554.4 | 8,439.4 | 147.3 | 9,554.4 (HyrxMQ) | 1.00 | 1.13 | 64.86 |
| confirm | 65536 | 16 | 9,675.4 | 8,000.0 | 280.2 | 9,675.4 (HyrxMQ) | 1.00 | 1.21 | 34.53 |
| confirm | 65536 | 32 | 9,542.4 | 8,140.4 | 381.0 | 9,542.4 (HyrxMQ) | 1.00 | 1.17 | 25.05 |
| confirm | 262144 | 1 | 2,154.2 | 1,756.2 | 18.3 | 2,154.2 (HyrxMQ) | 1.00 | 1.23 | 117.72 |
| confirm | 262144 | 4 | 3,242.1 | 3,029.5 | 77.8 | 3,242.1 (HyrxMQ) | 1.00 | 1.07 | 41.67 |
| confirm | 262144 | 8 | 3,145.8 | 3,042.6 | 126.4 | 3,145.8 (HyrxMQ) | 1.00 | 1.03 | 24.89 |
| confirm | 262144 | 16 | 2,556.5 | 2,599.4 | 163.5 | 2,599.4 (RabbitMQ) | 1.02 | 1.00 | 15.90 |
| confirm | 262144 | 32 | 2,367.3 | 2,689.9 | 273.4 | 2,689.9 (RabbitMQ) | 1.14 | 1.00 | 9.84 |
| fanout | 1024 | 1 | 12,000.0 | 7,377.0 | 12,587.4 | 12,587.4 (LavinMQ) | 1.05 | 1.71 | 1.00 |
| fanout | 1024 | 4 | 25,531.9 | 19,047.6 | 33,333.3 | 33,333.3 (LavinMQ) | 1.31 | 1.75 | 1.00 |
| fanout | 1024 | 8 | 34,769.2 | 28,031.0 | 43,566.3 | 43,566.3 (LavinMQ) | 1.25 | 1.55 | 1.00 |
| fanout | 1024 | 16 | 40,629.2 | 32,000.0 | 49,534.2 | 49,534.2 (LavinMQ) | 1.22 | 1.55 | 1.00 |
| fanout | 1024 | 32 | 42,541.2 | 33,794.4 | 48,864.9 | 48,864.9 (LavinMQ) | 1.15 | 1.45 | 1.00 |

**Clean medians (stall-/error-free reps only), same cells:**

| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | H ratio | R ratio | L ratio |
|---|---|---|---|---|---|---|---|---|
| publish | 64 | 1 | 146,844.4 | 151,360.0 | 151,182.2 | 1.03 | 1.00 | 1.00 |
| publish | 64 | 4 | 474,702.2 | 378,776.2 | 482,488.9 | 1.02 | 1.27 | 1.00 |
| publish | 64 | 8 | 671,588.1 | 409,870.1 | 566,973.9 | 1.00 | 1.64 | 1.18 |
| publish | 64 | 16 | 643,018.9 | 457,756.1 | 610,434.2 | 1.00 | 1.40 | 1.05 |
| publish | 64 | 32 | 676,490.3 | 440,474.8 | 631,592.0 | 1.00 | 1.54 | 1.07 |
| publish | 1024 | 1 | 140,302.2 | 140,835.6 | 140,728.9 | 1.00 | 1.00 | 1.00 |
| publish | 1024 | 4 | 497,340.0 | 355,342.2 | 443,982.2 | 1.00 | 1.40 | 1.12 |
| publish | 1024 | 8 | 497,289.8 | 511,580.8 | 546,947.8 | 1.10 | 1.07 | 1.00 |
| publish | 1024 | 16 | 537,237.0 | 440,577.1 | 560,124.3 | 1.04 | 1.27 | 1.00 |
| publish | 1024 | 32 | 592,325.5 | 358,896.4 | 569,011.1 | 1.00 | 1.65 | 1.04 |
| publish | 16384 | 1 | 48,177.8 | 47,689.1 | 48,071.1 | 1.00 | 1.01 | 1.00 |
| publish | 16384 | 4 | 137,011.1 | 133,824.6 | 108,345.9 | 1.00 | 1.02 | 1.26 |
| publish | 16384 | 8 | 134,477.4 | 161,203.5 | 106,087.5 | 1.20 | 1.00 | 1.52 |
| publish | 16384 | 16 | 136,986.1 | 151,173.0 | 101,304.1 | 1.10 | 1.00 | 1.49 |
| publish | 16384 | 32 | 136,997.9 | 132,765.2 | 94,279.2 | 1.00 | 1.03 | 1.45 |
| publish | 65536 | 1 | 33,528.9 | 33,884.4 | 34,628.2 | 1.03 | 1.02 | 1.00 |
| publish | 65536 | 4 | 39,991.2 | 51,569.4 | 31,115.0 | 1.29 | 1.00 | 1.66 |
| publish | 65536 | 8 | 40,367.6 | 48,274.5 | 30,466.1 | 1.20 | 1.00 | 1.58 |
| publish | 65536 | 16 | 42,929.8 | 41,203.1 | 29,436.5 | 1.00 | 1.04 | 1.46 |
| publish | 65536 | 32 | 41,272.3 | 32,449.2 | 26,538.3 | 1.00 | 1.27 | 1.56 |
| publish | 262144 | 1 | 10,921.6 | 10,542.0 | 4,418.7 | 1.00 | 1.04 | 2.47 |
| publish | 262144 | 4 | 11,341.8 | 13,592.9 | 4,273.8 | 1.20 | 1.00 | 3.18 |
| publish | 262144 | 8 | 11,077.6 | 11,110.6 | 4,169.4 | 1.00 | 1.00 | 2.66 |
| publish | 262144 | 16 | 10,930.9 | 8,864.2 | 3,474.5 | 1.00 | 1.23 | 3.15 |
| publish | 262144 | 32 | 10,831.8 | 6,856.0 | 3,381.4 | 1.00 | 1.58 | 3.20 |
| pubget | 64 | 1 | 15,039.8 | 8,996.3 | 15,106.4 | 1.00 | 1.68 | 1.00 |
| pubget | 64 | 4 | 34,386.1 | 22,211.4 | 37,391.8 | 1.09 | 1.68 | 1.00 |
| pubget | 64 | 8 | 42,956.7 | 31,880.9 | 50,196.6 | 1.17 | 1.57 | 1.00 |
| pubget | 64 | 16 | 47,219.4 | 38,230.0 | 56,028.2 | 1.19 | 1.47 | 1.00 |
| pubget | 64 | 32 | 50,263.1 | 40,633.1 | 57,485.2 | 1.14 | 1.41 | 1.00 |
| pubget | 1024 | 1 | 14,626.2 | 8,638.1 | 14,317.3 | 1.00 | 1.69 | 1.02 |
| pubget | 1024 | 4 | 32,158.8 | 21,285.9 | 34,486.4 | 1.07 | 1.62 | 1.00 |
| pubget | 1024 | 8 | 40,986.2 | 31,030.9 | 46,455.0 | 1.13 | 1.50 | 1.00 |
| pubget | 1024 | 16 | 45,093.7 | 36,804.6 | 50,041.3 | 1.11 | 1.36 | 1.00 |
| pubget | 1024 | 32 | 47,233.7 | 38,858.6 | 51,598.2 | 1.09 | 1.33 | 1.00 |
| pubget | 16384 | 1 | 9,778.5 | 6,561.2 | 2,420.4 | 1.00 | 1.49 | 4.04 |
| pubget | 16384 | 4 | 18,907.7 | 14,777.6 | 114.0 | 1.00 | 1.28 | 165.86 |
| pubget | 16384 | 8 | 22,419.5 | 20,043.5 | 259.9 | 1.00 | 1.12 | 86.26 |
| pubget | 16384 | 16 | 24,710.2 | 21,410.7 | 494.9 | 1.00 | 1.15 | 49.93 |
| pubget | 16384 | 32 | 24,710.2 | 20,748.2 | 1,010.6 | 1.00 | 1.19 | 24.45 |
| pubget | 65536 | 1 | 6,502.6 | 4,580.1 | 233.8 | 1.00 | 1.42 | 27.81 |
| pubget | 65536 | 4 | 11,142.0 | 9,629.2 | 116.5 | 1.00 | 1.16 | 95.64 |
| pubget | 65536 | 8 | 12,013.0 | 10,447.6 | 211.3 | 1.00 | 1.15 | 56.85 |
| pubget | 65536 | 16 | 12,118.0 | 9,777.8 | 408.7 | 1.00 | 1.24 | 29.65 |
| pubget | 65536 | 32 | 11,214.5 | 9,666.7 | 796.4 | 1.00 | 1.16 | 14.08 |
| pubget | 262144 | 1 | 2,634.3 | 2,282.2 | 29.5 | 1.00 | 1.15 | 89.30 |
| pubget | 262144 | 4 | 4,162.2 | 3,882.4 | 112.2 | 1.00 | 1.07 | 37.10 |
| pubget | 262144 | 8 | 4,142.9 | 3,899.2 | 216.0 | 1.00 | 1.06 | 19.18 |
| pubget | 262144 | 16 | 3,279.2 | 3,501.9 | 420.9 | 1.07 | 1.00 | 8.32 |
| pubget | 262144 | 32 | 2,829.3 | 2,955.4 | 726.7 | 1.04 | 1.00 | 4.07 |
| confirm | 64 | 1 | 7,813.2 | 4,358.9 | 107.1 | 1.00 | 1.79 | 72.95 |
| confirm | 64 | 4 | 16,684.8 | 12,269.7 | 282.6 | 1.00 | 1.36 | 59.04 |
| confirm | 64 | 8 | 21,966.1 | 17,692.3 | 459.1 | 1.00 | 1.24 | 47.85 |
| confirm | 64 | 16 | 24,688.9 | 21,136.0 | 1,047.8 | 1.00 | 1.17 | 23.56 |
| confirm | 64 | 32 | 25,244.7 | 21,790.7 | 1,377.8 | 1.00 | 1.16 | 18.32 |
| confirm | 1024 | 1 | 7,917.4 | 4,512.0 | 134.5 | 1.00 | 1.75 | 58.87 |
| confirm | 1024 | 4 | 16,531.6 | 12,262.7 | 371.0 | 1.00 | 1.35 | 44.56 |
| confirm | 1024 | 8 | 21,448.4 | 17,565.7 | 357.7 | 1.00 | 1.22 | 59.96 |
| confirm | 1024 | 16 | 25,159.3 | 20,987.5 | 721.7 | 1.00 | 1.20 | 34.86 |
| confirm | 1024 | 32 | 25,636.9 | 21,396.7 | 1,294.6 | 1.00 | 1.20 | 19.80 |
| confirm | 16384 | 1 | 4,891.6 | 3,517.1 | 21.6 | 1.00 | 1.39 | 226.46 |
| confirm | 16384 | 4 | 11,441.4 | 9,825.4 | 93.1 | 1.00 | 1.16 | 122.89 |
| confirm | 16384 | 8 | 14,322.3 | 13,124.6 | 173.4 | 1.00 | 1.09 | 82.60 |
| confirm | 16384 | 16 | 16,193.2 | 14,931.2 | 322.9 | 1.00 | 1.08 | 50.15 |
| confirm | 16384 | 32 | 16,211.0 | 14,462.7 | 417.0 | 1.00 | 1.12 | 38.88 |
| confirm | 65536 | 1 | 4,003.3 | 3,064.8 | 80.4 | 1.00 | 1.31 | 49.79 |
| confirm | 65536 | 4 | 8,177.4 | 6,919.3 | 80.8 | 1.00 | 1.18 | 101.21 |
| confirm | 65536 | 8 | 9,554.4 | 8,439.4 | 147.3 | 1.00 | 1.13 | 64.86 |
| confirm | 65536 | 16 | 9,675.4 | 8,000.0 | 280.2 | 1.00 | 1.21 | 34.53 |
| confirm | 65536 | 32 | 9,542.4 | 8,140.4 | 381.0 | 1.00 | 1.17 | 25.05 |
| confirm | 262144 | 1 | 2,154.2 | 1,756.2 | 18.3 | 1.00 | 1.23 | 117.72 |
| confirm | 262144 | 4 | 3,242.1 | 3,029.5 | 77.8 | 1.00 | 1.07 | 41.67 |
| confirm | 262144 | 8 | 3,145.8 | 3,042.6 | 126.4 | 1.00 | 1.03 | 24.89 |
| confirm | 262144 | 16 | 2,556.5 | 2,599.4 | 163.5 | 1.02 | 1.00 | 15.90 |
| confirm | 262144 | 32 | 2,367.3 | 2,689.9 | 273.4 | 1.14 | 1.00 | 9.84 |
| fanout | 1024 | 1 | 12,000.0 | 7,377.0 | 12,587.4 | 1.05 | 1.71 | 1.00 |
| fanout | 1024 | 4 | 25,531.9 | 19,047.6 | 33,333.3 | 1.31 | 1.75 | 1.00 |
| fanout | 1024 | 8 | 34,769.2 | 28,031.0 | 43,566.3 | 1.25 | 1.55 | 1.00 |
| fanout | 1024 | 16 | 40,629.2 | 32,000.0 | 49,534.2 | 1.22 | 1.55 | 1.00 |
| fanout | 1024 | 32 | 42,541.2 | 33,794.4 | 48,864.9 | 1.15 | 1.45 | 1.00 |

## Per-workload winners and margins

Geomean of per-cell `fastest/rate` (lower = faster overall for the workload). Margin is the runner-up's geomean relative to the winner's (e.g. 1.20 vs 1.00 = runner-up 20% slower on the geomean).

| workload | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | margin over runner-up |
|---|---|---|---|---|---|---|
| publish | 25 | 1.046 | 1.160 | 1.434 | **HyrxMQ** | 1.11x (RabbitMQ) |
| pubget | 25 | 1.043 | 1.301 | 7.529 | **HyrxMQ** | 1.25x (RabbitMQ) |
| confirm | 25 | 1.006 | 1.212 | 45.159 | **HyrxMQ** | 1.21x (RabbitMQ) |
| fanout | 5 | 1.192 | 1.597 | 1.000 | **LavinMQ** | 1.19x (HyrxMQ) |

## Scaling curves — throughput vs concurrency (primary medians, msg/s)

### publish

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 146,844.4 | 151,360.0 | 151,182.2 |
| 64 | 4 | 474,702.2 | 378,776.2 | 482,488.9 |
| 64 | 8 | 671,588.1 | 409,870.1 | 566,973.9 |
| 64 | 16 | 643,018.9 | 457,756.1 | 610,434.2 |
| 64 | 32 | 676,490.3 | 440,474.8 | 631,592.0 |
| 1024 | 1 | 140,302.2 | 140,835.6 | 140,728.9 |
| 1024 | 4 | 497,340.0 | 355,342.2 | 443,982.2 |
| 1024 | 8 | 497,289.8 | 511,580.8 | 546,947.8 |
| 1024 | 16 | 537,237.0 | 440,577.1 | 560,124.3 |
| 1024 | 32 | 592,325.5 | 358,896.4 | 569,011.1 |
| 16384 | 1 | 48,177.8 | 47,689.1 | 48,071.1 |
| 16384 | 4 | 137,011.1 | 133,824.6 | 108,345.9 |
| 16384 | 8 | 134,477.4 | 161,203.5 | 106,087.5 |
| 16384 | 16 | 136,986.1 | 151,173.0 | 101,304.1 |
| 16384 | 32 | 136,997.9 | 132,765.2 | 94,279.2 |
| 65536 | 1 | 33,528.9 | 33,884.4 | 34,628.2 |
| 65536 | 4 | 39,991.2 | 51,569.4 | 31,115.0 |
| 65536 | 8 | 40,367.6 | 48,274.5 | 30,466.1 |
| 65536 | 16 | 42,929.8 | 41,203.1 | 29,436.5 |
| 65536 | 32 | 41,272.3 | 32,449.2 | 26,538.3 |
| 262144 | 1 | 10,921.6 | 10,542.0 | 4,418.7 |
| 262144 | 4 | 11,341.8 | 13,592.9 | 4,273.8 |
| 262144 | 8 | 11,077.6 | 11,110.6 | 4,169.4 |
| 262144 | 16 | 10,930.9 | 8,864.2 | 3,474.5 |
| 262144 | 32 | 10,831.8 | 6,856.0 | 3,381.4 |

### pubget

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 15,039.8 | 8,996.3 | 15,106.4 |
| 64 | 4 | 34,386.1 | 22,211.4 | 37,391.8 |
| 64 | 8 | 42,956.7 | 31,880.9 | 50,196.6 |
| 64 | 16 | 47,219.4 | 38,230.0 | 56,028.2 |
| 64 | 32 | 50,263.1 | 40,633.1 | 57,485.2 |
| 1024 | 1 | 14,626.2 | 8,638.1 | 14,317.3 |
| 1024 | 4 | 32,158.8 | 21,285.9 | 34,486.4 |
| 1024 | 8 | 40,986.2 | 31,030.9 | 46,455.0 |
| 1024 | 16 | 45,093.7 | 36,804.6 | 50,041.3 |
| 1024 | 32 | 47,233.7 | 38,858.6 | 51,598.2 |
| 16384 | 1 | 9,778.5 | 6,561.2 | 2,420.4 |
| 16384 | 4 | 18,907.7 | 14,777.6 | 114.0 |
| 16384 | 8 | 22,419.5 | 20,043.5 | 259.9 |
| 16384 | 16 | 24,710.2 | 21,410.7 | 494.9 |
| 16384 | 32 | 24,710.2 | 20,748.2 | 1,010.6 |
| 65536 | 1 | 6,502.6 | 4,580.1 | 233.8 |
| 65536 | 4 | 11,142.0 | 9,629.2 | 137.5 |
| 65536 | 8 | 12,013.0 | 10,447.6 | 211.3 |
| 65536 | 16 | 12,118.0 | 9,777.8 | 408.7 |
| 65536 | 32 | 11,214.5 | 9,666.7 | 796.4 |
| 262144 | 1 | 2,634.3 | 2,282.2 | 29.5 |
| 262144 | 4 | 4,162.2 | 3,882.4 | 112.2 |
| 262144 | 8 | 4,142.9 | 3,899.2 | 216.0 |
| 262144 | 16 | 3,279.2 | 3,501.9 | 420.9 |
| 262144 | 32 | 2,829.3 | 2,955.4 | 726.7 |

### confirm

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 7,813.2 | 4,358.9 | 107.1 |
| 64 | 4 | 16,684.8 | 12,269.7 | 282.6 |
| 64 | 8 | 21,966.1 | 17,692.3 | 459.1 |
| 64 | 16 | 24,688.9 | 21,136.0 | 1,047.8 |
| 64 | 32 | 25,244.7 | 21,790.7 | 1,377.8 |
| 1024 | 1 | 7,917.4 | 4,512.0 | 134.5 |
| 1024 | 4 | 16,531.6 | 12,262.7 | 371.0 |
| 1024 | 8 | 21,448.4 | 17,565.7 | 357.7 |
| 1024 | 16 | 25,159.3 | 20,987.5 | 721.7 |
| 1024 | 32 | 25,636.9 | 21,396.7 | 1,294.6 |
| 16384 | 1 | 4,891.6 | 3,517.1 | 21.6 |
| 16384 | 4 | 11,441.4 | 9,825.4 | 93.1 |
| 16384 | 8 | 14,322.3 | 13,124.6 | 173.4 |
| 16384 | 16 | 16,193.2 | 14,931.2 | 322.9 |
| 16384 | 32 | 16,211.0 | 14,462.7 | 417.0 |
| 65536 | 1 | 4,003.3 | 3,064.8 | 80.4 |
| 65536 | 4 | 8,177.4 | 6,919.3 | 80.8 |
| 65536 | 8 | 9,554.4 | 8,439.4 | 147.3 |
| 65536 | 16 | 9,675.4 | 8,000.0 | 280.2 |
| 65536 | 32 | 9,542.4 | 8,140.4 | 381.0 |
| 262144 | 1 | 2,154.2 | 1,756.2 | 18.3 |
| 262144 | 4 | 3,242.1 | 3,029.5 | 77.8 |
| 262144 | 8 | 3,145.8 | 3,042.6 | 126.4 |
| 262144 | 16 | 2,556.5 | 2,599.4 | 163.5 |
| 262144 | 32 | 2,367.3 | 2,689.9 | 273.4 |

### fanout

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 1024 | 1 | 12,000.0 | 7,377.0 | 12,587.4 |
| 1024 | 4 | 25,531.9 | 19,047.6 | 33,333.3 |
| 1024 | 8 | 34,769.2 | 28,031.0 | 43,566.3 |
| 1024 | 16 | 40,629.2 | 32,000.0 | 49,534.2 |
| 1024 | 32 | 42,541.2 | 33,794.4 | 48,864.9 |

## Latency percentiles (publish -> get -> ack, one in flight)

Per-op microseconds; median across reps of each run percentile. Ratio is p50 vs the fastest broker in that payload row.

| payload | broker | p50 | p95 | p99 | p99.9 | p50 ratio |
|---|---|---|---|---|---|---|
| 64 | HyrxMQ | 115.0 | 154.0 | 205.0 | 1,162.0 | 1.35x |
| 64 | RabbitMQ | 159.0 | 216.0 | 341.0 | 1,792.0 | 1.87x |
| 64 | LavinMQ | 85.0 | 118.0 | 185.0 | 1,305.0 | 1.00x |
| 1024 | HyrxMQ | 107.0 | 147.0 | 208.0 | 1,233.0 | 1.29x |
| 1024 | RabbitMQ | 162.0 | 237.0 | 421.0 | 1,971.0 | 1.95x |
| 1024 | LavinMQ | 83.0 | 125.0 | 215.0 | 1,456.0 | 1.00x |
| 16384 | HyrxMQ | 145.0 | 222.0 | 367.0 | 1,634.0 | 1.00x |
| 16384 | RabbitMQ | 197.0 | 311.0 | 679.0 | 2,073.0 | 1.36x |
| 16384 | LavinMQ | 155.0 | 331.0 | 40,823.0 | 41,492.0 | 1.07x |
| 65536 | HyrxMQ | 191.0 | 343.0 | 622.0 | 1,881.0 | 1.00x |
| 65536 | RabbitMQ | 249.0 | 440.0 | 1,018.0 | 2,191.0 | 1.30x |
| 65536 | LavinMQ | 228.0 | 41,346.0 | 42,133.0 | 42,553.0 | 1.19x |
| 262144 | HyrxMQ | 379.0 | 888.0 | 1,745.0 | 2,755.0 | 1.00x |
| 262144 | RabbitMQ | 440.0 | 898.0 | 1,887.0 | 2,975.0 | 1.16x |
| 262144 | LavinMQ | 41,053.0 | 42,902.0 | 45,002.0 | 47,628.0 | 108.32x |

**Lowest p50 across payloads:** HyrxMQ 3, LavinMQ 2.

## Resource usage (`docker stats --no-stream`, median during reps)

| workload | broker | CPU% median (max over cells) | RSS median (max over cells) |
|---|---|---|---|
| publish | HyrxMQ | 96.8 | 278.0 MiB |
| publish | RabbitMQ | 140.9 | 170.6 MiB |
| publish | LavinMQ | 69.1 | 47.0 MiB |
| pubget | HyrxMQ | 39.5 | 450.7 MiB |
| pubget | RabbitMQ | 128.1 | 247.7 MiB |
| pubget | LavinMQ | 43.4 | 54.3 MiB |
| confirm | HyrxMQ | 56.5 | 417.0 MiB |
| confirm | RabbitMQ | 37.4 | 266.2 MiB |
| confirm | LavinMQ | 28.7 | 63.1 MiB |
| fanout | HyrxMQ | 26.7 | 278.0 MiB |
| fanout | RabbitMQ | 152.4 | 182.1 MiB |
| fanout | LavinMQ | 15.1 | 56.6 MiB |
| latency | HyrxMQ | 18.2 | 306.4 MiB |
| latency | RabbitMQ | 15.8 | 164.9 MiB |
| latency | LavinMQ | 2.3 | 57.0 MiB |

## Overall verdict

Metric: geometric mean over throughput cells of `fastest/rate` per broker (lower = faster; 1.000 means fastest in every included cell). Bands group by concurrency. "fair" cells are those where all three brokers completed and every requested worker connected.

**Primary (all reps):**

| band | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | runner-up gap |
|---|---|---|---|---|---|---|
| 1 | 16 | 1.007 | 1.324 | 7.675 | **HyrxMQ** | 1.314x |
| 4-8 | 32 | 1.059 | 1.223 | 8.749 | **HyrxMQ** | 1.155x |
| 16-32 | 32 | 1.039 | 1.225 | 5.194 | **HyrxMQ** | 1.179x |
| overall | 80 | 1.041 | 1.244 | 6.918 | **HyrxMQ** | 1.195x |

**Clean (stall-/error-free):**

| band | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | runner-up gap |
|---|---|---|---|---|---|---|
| 1 | 16 | 1.007 | 1.324 | 7.675 | **HyrxMQ** | 1.314x |
| 4-8 | 32 | 1.059 | 1.223 | 8.794 | **HyrxMQ** | 1.155x |
| 16-32 | 32 | 1.039 | 1.225 | 5.194 | **HyrxMQ** | 1.179x |
| overall | 80 | 1.041 | 1.244 | 6.933 | **HyrxMQ** | 1.195x |

**Fastest overall (primary geomean, 80 fair throughput cells): HyrxMQ**, geomean ratio 1.041; RabbitMQ is 19.5% slower on the geomean; LavinMQ is 564.9% slower.

### Head-to-head HyrxMQ versus each broker

Geomean of `HyrxMQ rate / other rate` over the fair throughput cells (> 1.00 = HyrxMQ faster, < 1.00 = HyrxMQ slower). This isolates the HyrxMQ-vs-broker gap and does not depend on which broker is the per-cell fastest.

| scope | cells | HyrxMQ / RabbitMQ | HyrxMQ / LavinMQ |
|---|---|---|---|
| overall | 80 | 1.195 (+19.5%) | 6.649 (+564.9%) |
| band 1 | 16 | 1.314 (+31.4%) | 7.619 (+661.9%) |
| band 4-8 | 32 | 1.155 (+15.5%) | 8.261 (+726.1%) |
| band 16-32 | 32 | 1.179 (+17.9%) | 4.999 (+399.9%) |
| workload publish | 25 | 1.110 (+11.0%) | 1.371 (+37.1%) |
| workload pubget | 25 | 1.247 (+24.7%) | 7.221 (+622.1%) |
| workload confirm | 25 | 1.205 (+20.5%) | 44.899 (+4389.9%) |
| workload fanout | 5 | 1.340 (+34.0%) | 0.839 (-16.1%) |

## Precise claim about HyrxMQ

A cell counts as **fastest** if HyrxMQ has the top median rate, **tied** if within 2% of the top rate, **behind** otherwise. Ratios are fastest/HyrxMQ (1.00 = fastest; larger = HyrxMQ slower).

- **HyrxMQ is fastest in 50 throughput cells:** publish|64|8 (1.00x), publish|64|16 (1.00x), publish|64|32 (1.00x), publish|1024|4 (1.00x), publish|1024|32 (1.00x), publish|16384|1 (1.00x), publish|16384|4 (1.00x), publish|16384|32 (1.00x), publish|65536|16 (1.00x), publish|65536|32 (1.00x), publish|262144|1 (1.00x), publish|262144|16 (1.00x), publish|262144|32 (1.00x), pubget|1024|1 (1.00x), pubget|16384|1 (1.00x), pubget|16384|4 (1.00x), pubget|16384|8 (1.00x), pubget|16384|16 (1.00x), pubget|16384|32 (1.00x), pubget|65536|1 (1.00x), pubget|65536|4 (1.00x), pubget|65536|8 (1.00x), pubget|65536|16 (1.00x), pubget|65536|32 (1.00x), pubget|262144|1 (1.00x), pubget|262144|4 (1.00x), pubget|262144|8 (1.00x), confirm|64|1 (1.00x), confirm|64|4 (1.00x), confirm|64|8 (1.00x), confirm|64|16 (1.00x), confirm|64|32 (1.00x), confirm|1024|1 (1.00x), confirm|1024|4 (1.00x), confirm|1024|8 (1.00x), confirm|1024|16 (1.00x), confirm|1024|32 (1.00x), confirm|16384|1 (1.00x), confirm|16384|4 (1.00x), confirm|16384|8 (1.00x), confirm|16384|16 (1.00x), confirm|16384|32 (1.00x), confirm|65536|1 (1.00x), confirm|65536|4 (1.00x), confirm|65536|8 (1.00x), confirm|65536|16 (1.00x), confirm|65536|32 (1.00x), confirm|262144|1 (1.00x), confirm|262144|4 (1.00x), confirm|262144|8 (1.00x).
- **Tied (within 2%) in 5 cells:** publish|262144|8 (1.00x), publish|1024|1 (1.00x), pubget|64|1 (1.00x), publish|64|4 (1.02x), confirm|262144|16 (1.02x).
- **Behind in 25 cells.** Worst cases: publish|64|1 (1.03x), publish|65536|1 (1.03x), publish|1024|16 (1.04x), pubget|262144|32 (1.04x), fanout|1024|1 (1.05x), pubget|262144|16 (1.07x), pubget|1024|4 (1.07x), pubget|64|4 (1.09x), pubget|1024|32 (1.09x), publish|1024|8 (1.10x), publish|16384|16 (1.10x), pubget|1024|16 (1.11x).
- The narrowest loss is 1.03x; the widest is 1.31x.
  - Losses by workload: pubget 10, publish 9, fanout 5, confirm 1.

## Failures, errors and stalls

- `pubget|65536|4` **LavinMQ**: 3/7 reps stalled (wall > 3x target); clean median 116.5 vs median 137.5 msg/s.
- `pubget|262144|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 29.5 vs median 29.5 msg/s.
- `confirm|16384|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 21.6 vs median 21.6 msg/s.
- `confirm|262144|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 18.3 vs median 18.3 msg/s.
- `latency|16384|1` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 210.8 vs median 204.1 msg/s.
- `latency|262144|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 27.0 vs median 27.0 msg/s.

## Caveats and limitations

- **Single host, single client.** All results are one physical machine (12 logical CPUs, CPU governor `powersave`), one client process, one Docker bridge. They establish relative behaviour here, not a universal ranking. This is **not** a claim that any broker is "fastest in the world".
- **These exact images.** Numbers are for the image digests above; a different RabbitMQ/LavinMQ/HyrxMQ build may differ.
- **CPU governor is `powersave`** on this host, so absolute rates are lower and noisier than a `performance` governor would give; relative ordering is the robust output.
- HyrxMQ is a fundamentally different design (Mojo, per-connection serving); RabbitMQ (Erlang/OTP) and LavinMQ (Crystal) are mature multi-threaded brokers. The comparison is behavioural, not architectural equivalence.
- `publish` targets a **bindingless** exchange: it measures the producer/transport ceiling and stores nothing.
- `pubget` uses `auto_ack=True` (routing + content + transport, not the ack path); `latency` uses explicit ack.
- `confirm` waits one confirm per publish; its untimed drain is outside the measured span.
- **LavinMQ large-payload collapse (important).** In `pubget` and `confirm` at payloads >= 16 KiB, and in `latency` at 256 KiB, LavinMQ delivered only ~20-960 msg/s (e.g. `pubget|16384|8` 246 msg/s, `confirm|16384|1` 21 msg/s, `latency|262144|1` p50 41 ms). LavinMQ's overall geomean (6.918) is dominated by these collapsed cells; treat that single number as an observed pathology of this image/workload, not a general LavinMQ capability. The **HyrxMQ-vs-RabbitMQ** verdict is unaffected, because both are scored against the same per-cell fastest rate.
- **LavinMQ is genuinely fastest in `fanout`** (all 5 cells, 1.05-1.31x over HyrxMQ): that is not a collapse artifact.
- **HyrxMQ had 0 stall/error cells in all 85 cells / 1785 runs** (595 successful HyrxMQ runs); every stall/error above is LavinMQ (6 affected cells).
- Container caps (`--cpus 4 --memory 2g`) can bind the multi-threaded brokers differently than HyrxMQ; not all brokers were re-tuned.
- Medians across 7 rotated reps suppress drift but not all noise; cells where brokers are within ~5% should be treated as ties.
