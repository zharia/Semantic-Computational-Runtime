# Three-Broker AMQP Performance Benchmark — FINAL

**HyrxMQ vs RabbitMQ vs LavinMQ — definitive run on one host, all three brokers in Docker, one compiled Go load generator.**

- Run id: `20260915T034749Z`
- Started (UTC): 2026-09-15T03:47:49Z · finished 2026-09-15T05:02:25Z
- Mode: full · replicates per cell: 7 (median reported) · target rep >= 2.0 s
- Consolidated data: `results/v2_consolidated_20260915T034749Z.json`

## Host, software and image digests

- CPU: AMD Ryzen 5 3600 6-Core Processor (12 logical CPUs)
- RAM: 15.54 GiB · kernel 7.2.4-3-cachyos · machine x86_64
- Docker server 29.8.0 · client Go go version go1.27.1-X:nodwarf5 linux/amd64 · module `github.com/rabbitmq/amqp091-go`
- CPU governor: `powersave` · host loadavg(1m) at start: 5.53

| broker | image | image id |
|---|---|---|
| HyrxMQ | `hyrxmq:latest` | `sha256:febf45a3ae22315b933051ee9b434adc82005955377a9e6d9372f5536de485b0` |
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
| publish | 64 | 1 | 138,097.8 | 136,320.0 | 139,448.9 | 139,448.9 (LavinMQ) | 1.01 | 1.02 | 1.00 |
| publish | 64 | 4 | 397,760.0 | 334,996.1 | 413,724.4 | 413,724.4 (LavinMQ) | 1.04 | 1.24 | 1.00 |
| publish | 64 | 8 | 608,000.0 | 406,316.5 | 551,480.3 | 608,000.0 (HyrxMQ) | 1.00 | 1.50 | 1.10 |
| publish | 64 | 16 | 582,069.9 | 414,401.8 | 553,175.8 | 582,069.9 (HyrxMQ) | 1.00 | 1.40 | 1.05 |
| publish | 64 | 32 | 612,667.8 | 421,073.2 | 582,495.8 | 612,667.8 (HyrxMQ) | 1.00 | 1.46 | 1.05 |
| publish | 1024 | 1 | 132,480.0 | 129,955.6 | 129,671.1 | 132,480.0 (HyrxMQ) | 1.00 | 1.02 | 1.02 |
| publish | 1024 | 4 | 446,802.4 | 328,528.6 | 393,914.5 | 446,802.4 (HyrxMQ) | 1.00 | 1.36 | 1.13 |
| publish | 1024 | 8 | 458,858.7 | 380,835.6 | 492,099.9 | 492,099.9 (LavinMQ) | 1.07 | 1.29 | 1.00 |
| publish | 1024 | 16 | 489,516.3 | 378,929.6 | 500,166.6 | 500,166.6 (LavinMQ) | 1.02 | 1.32 | 1.00 |
| publish | 1024 | 32 | 537,299.3 | 379,494.5 | 523,800.7 | 537,299.3 (HyrxMQ) | 1.00 | 1.42 | 1.03 |
| publish | 16384 | 1 | 43,093.3 | 45,760.0 | 43,448.9 | 45,760.0 (RabbitMQ) | 1.06 | 1.00 | 1.05 |
| publish | 16384 | 4 | 117,528.6 | 122,850.2 | 96,124.2 | 122,850.2 (RabbitMQ) | 1.05 | 1.00 | 1.28 |
| publish | 16384 | 8 | 116,274.3 | 137,543.2 | 93,445.7 | 137,543.2 (RabbitMQ) | 1.18 | 1.00 | 1.47 |
| publish | 16384 | 16 | 117,121.7 | 138,508.0 | 88,312.3 | 138,508.0 (RabbitMQ) | 1.18 | 1.00 | 1.57 |
| publish | 16384 | 32 | 128,465.9 | 137,840.8 | 95,773.8 | 137,840.8 (RabbitMQ) | 1.07 | 1.00 | 1.44 |
| publish | 65536 | 1 | 32,338.0 | 30,968.9 | 32,497.8 | 32,497.8 (LavinMQ) | 1.00 | 1.05 | 1.00 |
| publish | 65536 | 4 | 35,547.7 | 50,810.0 | 28,531.0 | 50,810.0 (RabbitMQ) | 1.43 | 1.00 | 1.78 |
| publish | 65536 | 8 | 34,091.5 | 48,017.7 | 27,085.1 | 48,017.7 (RabbitMQ) | 1.41 | 1.00 | 1.77 |
| publish | 65536 | 16 | 34,977.1 | 38,947.4 | 25,502.2 | 38,947.4 (RabbitMQ) | 1.11 | 1.00 | 1.53 |
| publish | 65536 | 32 | 35,333.7 | 31,486.6 | 21,715.5 | 35,333.7 (HyrxMQ) | 1.00 | 1.12 | 1.63 |
| publish | 262144 | 1 | 9,198.9 | 8,801.8 | 4,042.5 | 9,198.9 (HyrxMQ) | 1.00 | 1.05 | 2.28 |
| publish | 262144 | 4 | 8,986.8 | 12,934.7 | 3,789.5 | 12,934.7 (RabbitMQ) | 1.44 | 1.00 | 3.41 |
| publish | 262144 | 8 | 8,799.1 | 10,748.4 | 3,519.8 | 10,748.4 (RabbitMQ) | 1.22 | 1.00 | 3.05 |
| publish | 262144 | 16 | 8,426.3 | 8,571.7 | 3,078.8 | 8,571.7 (RabbitMQ) | 1.02 | 1.00 | 2.78 |
| publish | 262144 | 32 | 7,952.8 | 6,368.2 | 2,911.8 | 7,952.8 (HyrxMQ) | 1.00 | 1.25 | 2.73 |
| pubget | 64 | 1 | 13,437.7 | 8,037.3 | 13,426.3 | 13,437.7 (HyrxMQ) | 1.00 | 1.67 | 1.00 |
| pubget | 64 | 4 | 30,195.9 | 19,534.3 | 32,540.5 | 32,540.5 (LavinMQ) | 1.08 | 1.67 | 1.00 |
| pubget | 64 | 8 | 40,932.5 | 31,173.6 | 49,041.6 | 49,041.6 (LavinMQ) | 1.20 | 1.57 | 1.00 |
| pubget | 64 | 16 | 42,808.4 | 36,247.1 | 52,254.3 | 52,254.3 (LavinMQ) | 1.22 | 1.44 | 1.00 |
| pubget | 64 | 32 | 43,787.8 | 38,230.0 | 54,142.2 | 54,142.2 (LavinMQ) | 1.24 | 1.42 | 1.00 |
| pubget | 1024 | 1 | 13,209.7 | 7,843.2 | 13,104.1 | 13,209.7 (HyrxMQ) | 1.00 | 1.68 | 1.01 |
| pubget | 1024 | 4 | 28,459.7 | 19,243.7 | 30,495.0 | 30,495.0 (LavinMQ) | 1.07 | 1.58 | 1.00 |
| pubget | 1024 | 8 | 34,924.9 | 27,183.4 | 39,614.8 | 39,614.8 (LavinMQ) | 1.13 | 1.46 | 1.00 |
| pubget | 1024 | 16 | 38,221.3 | 32,740.0 | 43,833.3 | 43,833.3 (LavinMQ) | 1.15 | 1.34 | 1.00 |
| pubget | 1024 | 32 | 40,004.9 | 35,146.0 | 45,279.2 | 45,279.2 (LavinMQ) | 1.13 | 1.29 | 1.00 |
| pubget | 16384 | 1 | 8,639.6 | 5,813.5 | 2,070.9 | 8,639.6 (HyrxMQ) | 1.00 | 1.49 | 4.17 |
| pubget | 16384 | 4 | 15,282.9 | 12,802.1 | 118.0 | 15,282.9 (HyrxMQ) | 1.00 | 1.19 | 129.52 |
| pubget | 16384 | 8 | 17,990.2 | 16,995.4 | 246.2 | 17,990.2 (HyrxMQ) | 1.00 | 1.06 | 73.07 |
| pubget | 16384 | 16 | 19,513.2 | 18,212.3 | 475.0 | 19,513.2 (HyrxMQ) | 1.00 | 1.07 | 41.08 |
| pubget | 16384 | 32 | 20,098.1 | 17,334.9 | 959.5 | 20,098.1 (HyrxMQ) | 1.00 | 1.16 | 20.95 |
| pubget | 65536 | 1 | 6,124.6 | 4,507.3 | 225.2 | 6,124.6 (HyrxMQ) | 1.00 | 1.36 | 27.20 |
| pubget | 65536 | 4 | 10,359.6 | 9,629.2 | 263.7 | 10,359.6 (HyrxMQ) | 1.00 | 1.08 | 39.29 |
| pubget | 65536 | 8 | 10,815.2 | 10,104.1 | 207.9 | 10,815.2 (HyrxMQ) | 1.00 | 1.07 | 52.02 |
| pubget | 65536 | 16 | 10,934.9 | 10,016.3 | 406.0 | 10,934.9 (HyrxMQ) | 1.00 | 1.09 | 26.93 |
| pubget | 65536 | 32 | 10,005.4 | 9,742.8 | 798.3 | 10,005.4 (HyrxMQ) | 1.00 | 1.03 | 12.53 |
| pubget | 262144 | 1 | 2,310.8 | 2,169.4 | 32.1 | 2,310.8 (HyrxMQ) | 1.00 | 1.07 | 71.99 |
| pubget | 262144 | 4 | 3,567.6 | 3,500.0 | 120.5 | 3,567.6 (HyrxMQ) | 1.00 | 1.02 | 29.61 |
| pubget | 262144 | 8 | 3,386.9 | 3,596.9 | 228.7 | 3,596.9 (RabbitMQ) | 1.06 | 1.00 | 15.73 |
| pubget | 262144 | 16 | 2,927.4 | 3,399.3 | 464.9 | 3,399.3 (RabbitMQ) | 1.16 | 1.00 | 7.31 |
| pubget | 262144 | 32 | 2,487.9 | 2,964.9 | 716.6 | 2,964.9 (RabbitMQ) | 1.19 | 1.00 | 4.14 |
| confirm | 64 | 1 | 7,333.3 | 4,142.9 | 133.8 | 7,333.3 (HyrxMQ) | 1.00 | 1.77 | 54.81 |
| confirm | 64 | 4 | 15,527.4 | 10,868.9 | 279.8 | 15,527.4 (HyrxMQ) | 1.00 | 1.43 | 55.49 |
| confirm | 64 | 8 | 19,128.0 | 15,652.2 | 493.7 | 19,128.0 (HyrxMQ) | 1.00 | 1.22 | 38.74 |
| confirm | 64 | 16 | 24,531.5 | 21,373.0 | 1,004.5 | 24,531.5 (HyrxMQ) | 1.00 | 1.15 | 24.42 |
| confirm | 64 | 32 | 24,573.4 | 22,018.3 | 1,699.5 | 24,573.4 (HyrxMQ) | 1.00 | 1.12 | 14.46 |
| confirm | 1024 | 1 | 7,267.3 | 4,174.4 | 129.4 | 7,267.3 (HyrxMQ) | 1.00 | 1.74 | 56.16 |
| confirm | 1024 | 4 | 15,012.7 | 10,823.1 | 333.7 | 15,012.7 (HyrxMQ) | 1.00 | 1.39 | 44.99 |
| confirm | 1024 | 8 | 19,023.5 | 15,685.4 | 562.2 | 19,023.5 (HyrxMQ) | 1.00 | 1.21 | 33.84 |
| confirm | 1024 | 16 | 20,405.4 | 18,387.3 | 881.9 | 20,405.4 (HyrxMQ) | 1.00 | 1.11 | 23.14 |
| confirm | 1024 | 32 | 22,441.6 | 19,739.5 | 1,369.3 | 22,441.6 (HyrxMQ) | 1.00 | 1.14 | 16.39 |
| confirm | 16384 | 1 | 4,742.1 | 3,509.6 | 21.1 | 4,742.1 (HyrxMQ) | 1.00 | 1.35 | 224.74 |
| confirm | 16384 | 4 | 10,331.0 | 8,787.5 | 110.4 | 10,331.0 (HyrxMQ) | 1.00 | 1.18 | 93.58 |
| confirm | 16384 | 8 | 12,544.2 | 11,801.6 | 174.1 | 12,544.2 (HyrxMQ) | 1.00 | 1.06 | 72.05 |
| confirm | 16384 | 16 | 13,171.4 | 13,187.7 | 321.1 | 13,187.7 (RabbitMQ) | 1.00 | 1.00 | 41.07 |
| confirm | 16384 | 32 | 13,362.3 | 12,587.0 | 492.8 | 13,362.3 (HyrxMQ) | 1.00 | 1.06 | 27.12 |
| confirm | 65536 | 1 | 3,294.9 | 2,664.0 | 74.2 | 3,294.9 (HyrxMQ) | 1.00 | 1.24 | 44.41 |
| confirm | 65536 | 4 | 7,038.2 | 6,095.9 | 81.5 | 7,038.2 (HyrxMQ) | 1.00 | 1.15 | 86.36 |
| confirm | 65536 | 8 | 7,880.3 | 7,106.0 | 160.3 | 7,880.3 (HyrxMQ) | 1.00 | 1.11 | 49.16 |
| confirm | 65536 | 16 | 7,931.3 | 7,275.6 | 273.7 | 7,931.3 (HyrxMQ) | 1.00 | 1.09 | 28.98 |
| confirm | 65536 | 32 | 7,591.0 | 7,847.8 | 437.2 | 7,847.8 (RabbitMQ) | 1.03 | 1.00 | 17.95 |
| confirm | 262144 | 1 | 1,949.3 | 1,694.9 | 21.8 | 1,949.3 (HyrxMQ) | 1.00 | 1.15 | 89.42 |
| confirm | 262144 | 4 | 2,914.8 | 2,896.6 | 76.0 | 2,914.8 (HyrxMQ) | 1.00 | 1.01 | 38.35 |
| confirm | 262144 | 8 | 2,909.1 | 3,222.2 | 123.8 | 3,222.2 (RabbitMQ) | 1.11 | 1.00 | 26.03 |
| confirm | 262144 | 16 | 2,621.5 | 3,256.1 | 202.7 | 3,256.1 (RabbitMQ) | 1.24 | 1.00 | 16.06 |
| confirm | 262144 | 32 | 2,274.5 | 2,855.4 | 214.0 | 2,855.4 (RabbitMQ) | 1.26 | 1.00 | 13.34 |
| fanout | 1024 | 1 | 12,203.4 | 7,627.1 | 12,811.4 | 12,811.4 (LavinMQ) | 1.05 | 1.68 | 1.00 |
| fanout | 1024 | 4 | 24,827.6 | 18,750.0 | 29,752.1 | 29,752.1 (LavinMQ) | 1.20 | 1.59 | 1.00 |
| fanout | 1024 | 8 | 30,906.0 | 26,785.2 | 38,468.1 | 38,468.1 (LavinMQ) | 1.24 | 1.44 | 1.00 |
| fanout | 1024 | 16 | 33,794.4 | 32,576.6 | 42,046.5 | 42,046.5 (LavinMQ) | 1.24 | 1.29 | 1.00 |
| fanout | 1024 | 32 | 37,666.7 | 31,443.5 | 44,642.0 | 44,642.0 (LavinMQ) | 1.19 | 1.42 | 1.00 |

**Clean medians (stall-/error-free reps only), same cells:**

| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | H ratio | R ratio | L ratio |
|---|---|---|---|---|---|---|---|---|
| publish | 64 | 1 | 138,097.8 | 136,320.0 | 139,448.9 | 1.01 | 1.02 | 1.00 |
| publish | 64 | 4 | 397,760.0 | 334,996.1 | 413,724.4 | 1.04 | 1.24 | 1.00 |
| publish | 64 | 8 | 608,000.0 | 406,316.5 | 551,480.3 | 1.00 | 1.50 | 1.10 |
| publish | 64 | 16 | 582,069.9 | 414,401.8 | 553,175.8 | 1.00 | 1.40 | 1.05 |
| publish | 64 | 32 | 612,667.8 | 421,073.2 | 582,495.8 | 1.00 | 1.46 | 1.05 |
| publish | 1024 | 1 | 132,480.0 | 129,955.6 | 129,671.1 | 1.00 | 1.02 | 1.02 |
| publish | 1024 | 4 | 446,802.4 | 328,528.6 | 393,914.5 | 1.00 | 1.36 | 1.13 |
| publish | 1024 | 8 | 458,858.7 | 380,835.6 | 492,099.9 | 1.07 | 1.29 | 1.00 |
| publish | 1024 | 16 | 489,516.3 | 378,929.6 | 500,166.6 | 1.02 | 1.32 | 1.00 |
| publish | 1024 | 32 | 537,299.3 | 379,494.5 | 523,800.7 | 1.00 | 1.42 | 1.03 |
| publish | 16384 | 1 | 43,093.3 | 45,760.0 | 43,448.9 | 1.06 | 1.00 | 1.05 |
| publish | 16384 | 4 | 117,528.6 | 122,850.2 | 96,124.2 | 1.05 | 1.00 | 1.28 |
| publish | 16384 | 8 | 116,274.3 | 137,543.2 | 93,445.7 | 1.18 | 1.00 | 1.47 |
| publish | 16384 | 16 | 117,121.7 | 138,508.0 | 88,312.3 | 1.18 | 1.00 | 1.57 |
| publish | 16384 | 32 | 128,465.9 | 137,840.8 | 95,773.8 | 1.07 | 1.00 | 1.44 |
| publish | 65536 | 1 | 32,338.0 | 30,968.9 | 32,497.8 | 1.00 | 1.05 | 1.00 |
| publish | 65536 | 4 | 35,547.7 | 50,810.0 | 28,531.0 | 1.43 | 1.00 | 1.78 |
| publish | 65536 | 8 | 34,091.5 | 48,017.7 | 27,085.1 | 1.41 | 1.00 | 1.77 |
| publish | 65536 | 16 | 34,977.1 | 38,947.4 | 25,502.2 | 1.11 | 1.00 | 1.53 |
| publish | 65536 | 32 | 35,333.7 | 31,486.6 | 21,715.5 | 1.00 | 1.12 | 1.63 |
| publish | 262144 | 1 | 9,198.9 | 8,801.8 | 4,042.5 | 1.00 | 1.05 | 2.28 |
| publish | 262144 | 4 | 8,986.8 | 12,934.7 | 3,789.5 | 1.44 | 1.00 | 3.41 |
| publish | 262144 | 8 | 8,799.1 | 10,748.4 | 3,519.8 | 1.22 | 1.00 | 3.05 |
| publish | 262144 | 16 | 8,426.3 | 8,571.7 | 3,078.8 | 1.02 | 1.00 | 2.78 |
| publish | 262144 | 32 | 7,952.8 | 6,368.2 | 2,911.8 | 1.00 | 1.25 | 2.73 |
| pubget | 64 | 1 | 13,437.7 | 8,037.3 | 13,426.3 | 1.00 | 1.67 | 1.00 |
| pubget | 64 | 4 | 30,195.9 | 19,534.3 | 32,540.5 | 1.08 | 1.67 | 1.00 |
| pubget | 64 | 8 | 40,932.5 | 31,173.6 | 49,041.6 | 1.20 | 1.57 | 1.00 |
| pubget | 64 | 16 | 42,808.4 | 36,247.1 | 52,254.3 | 1.22 | 1.44 | 1.00 |
| pubget | 64 | 32 | 43,787.8 | 38,230.0 | 54,142.2 | 1.24 | 1.42 | 1.00 |
| pubget | 1024 | 1 | 13,209.7 | 7,843.2 | 13,104.1 | 1.00 | 1.68 | 1.01 |
| pubget | 1024 | 4 | 28,459.7 | 19,243.7 | 30,495.0 | 1.07 | 1.58 | 1.00 |
| pubget | 1024 | 8 | 34,924.9 | 27,183.4 | 39,614.8 | 1.13 | 1.46 | 1.00 |
| pubget | 1024 | 16 | 38,221.3 | 32,740.0 | 43,833.3 | 1.15 | 1.34 | 1.00 |
| pubget | 1024 | 32 | 40,004.9 | 35,146.0 | 45,279.2 | 1.13 | 1.29 | 1.00 |
| pubget | 16384 | 1 | 8,639.6 | 5,813.5 | 2,120.9 | 1.00 | 1.49 | 4.07 |
| pubget | 16384 | 4 | 15,282.9 | 12,802.1 | 118.0 | 1.00 | 1.19 | 129.52 |
| pubget | 16384 | 8 | 17,990.2 | 16,995.4 | 246.2 | 1.00 | 1.06 | 73.07 |
| pubget | 16384 | 16 | 19,513.2 | 18,212.3 | 475.0 | 1.00 | 1.07 | 41.08 |
| pubget | 16384 | 32 | 20,098.1 | 17,334.9 | 959.5 | 1.00 | 1.16 | 20.95 |
| pubget | 65536 | 1 | 6,124.6 | 4,507.3 | 225.2 | 1.00 | 1.36 | 27.20 |
| pubget | 65536 | 4 | 10,359.6 | 9,629.2 | 376.9 | 1.00 | 1.08 | 27.49 |
| pubget | 65536 | 8 | 10,815.2 | 10,104.1 | 207.9 | 1.00 | 1.07 | 52.02 |
| pubget | 65536 | 16 | 10,934.9 | 10,016.3 | 406.0 | 1.00 | 1.09 | 26.93 |
| pubget | 65536 | 32 | 10,005.4 | 9,742.8 | 798.3 | 1.00 | 1.03 | 12.53 |
| pubget | 262144 | 1 | 2,310.8 | 2,169.4 | 32.1 | 1.00 | 1.07 | 71.99 |
| pubget | 262144 | 4 | 3,567.6 | 3,500.0 | 120.5 | 1.00 | 1.02 | 29.61 |
| pubget | 262144 | 8 | 3,386.9 | 3,596.9 | 228.7 | 1.06 | 1.00 | 15.73 |
| pubget | 262144 | 16 | 2,927.4 | 3,399.3 | 464.9 | 1.16 | 1.00 | 7.31 |
| pubget | 262144 | 32 | 2,487.9 | 2,964.9 | 716.6 | 1.19 | 1.00 | 4.14 |
| confirm | 64 | 1 | 7,333.3 | 4,142.9 | 133.8 | 1.00 | 1.77 | 54.81 |
| confirm | 64 | 4 | 15,527.4 | 10,868.9 | 286.0 | 1.00 | 1.43 | 54.29 |
| confirm | 64 | 8 | 19,128.0 | 15,652.2 | 512.5 | 1.00 | 1.22 | 37.32 |
| confirm | 64 | 16 | 24,531.5 | 21,373.0 | 1,004.5 | 1.00 | 1.15 | 24.42 |
| confirm | 64 | 32 | 24,573.4 | 22,018.3 | 1,699.5 | 1.00 | 1.12 | 14.46 |
| confirm | 1024 | 1 | 7,267.3 | 4,174.4 | 129.4 | 1.00 | 1.74 | 56.16 |
| confirm | 1024 | 4 | 15,012.7 | 10,823.1 | 333.7 | 1.00 | 1.39 | 44.99 |
| confirm | 1024 | 8 | 19,023.5 | 15,685.4 | 575.2 | 1.00 | 1.21 | 33.07 |
| confirm | 1024 | 16 | 20,405.4 | 18,387.3 | 881.9 | 1.00 | 1.11 | 23.14 |
| confirm | 1024 | 32 | 22,441.6 | 19,739.5 | 1,369.3 | 1.00 | 1.14 | 16.39 |
| confirm | 16384 | 1 | 4,742.1 | 3,509.6 | 21.1 | 1.00 | 1.35 | 224.74 |
| confirm | 16384 | 4 | 10,331.0 | 8,787.5 | 110.4 | 1.00 | 1.18 | 93.58 |
| confirm | 16384 | 8 | 12,544.2 | 11,801.6 | 174.1 | 1.00 | 1.06 | 72.05 |
| confirm | 16384 | 16 | 13,171.4 | 13,187.7 | 321.1 | 1.00 | 1.00 | 41.07 |
| confirm | 16384 | 32 | 13,362.3 | 12,587.0 | 492.8 | 1.00 | 1.06 | 27.12 |
| confirm | 65536 | 1 | 3,294.9 | 2,664.0 | 74.2 | 1.00 | 1.24 | 44.41 |
| confirm | 65536 | 4 | 7,038.2 | 6,095.9 | 87.7 | 1.00 | 1.15 | 80.25 |
| confirm | 65536 | 8 | 7,880.3 | 7,106.0 | 160.3 | 1.00 | 1.11 | 49.16 |
| confirm | 65536 | 16 | 7,931.3 | 7,275.6 | 273.7 | 1.00 | 1.09 | 28.98 |
| confirm | 65536 | 32 | 7,591.0 | 7,847.8 | 437.2 | 1.03 | 1.00 | 17.95 |
| confirm | 262144 | 1 | 1,949.3 | 1,694.9 | 21.8 | 1.00 | 1.15 | 89.42 |
| confirm | 262144 | 4 | 2,914.8 | 2,896.6 | 76.0 | 1.00 | 1.01 | 38.35 |
| confirm | 262144 | 8 | 2,909.1 | 3,222.2 | 123.8 | 1.11 | 1.00 | 26.03 |
| confirm | 262144 | 16 | 2,621.5 | 3,256.1 | 202.7 | 1.24 | 1.00 | 16.06 |
| confirm | 262144 | 32 | 2,274.5 | 2,855.4 | 225.1 | 1.26 | 1.00 | 12.69 |
| fanout | 1024 | 1 | 12,203.4 | 7,627.1 | 12,811.4 | 1.05 | 1.68 | 1.00 |
| fanout | 1024 | 4 | 24,827.6 | 18,750.0 | 29,752.1 | 1.20 | 1.59 | 1.00 |
| fanout | 1024 | 8 | 30,906.0 | 26,785.2 | 38,468.1 | 1.24 | 1.44 | 1.00 |
| fanout | 1024 | 16 | 33,794.4 | 32,576.6 | 42,046.5 | 1.24 | 1.29 | 1.00 |
| fanout | 1024 | 32 | 37,666.7 | 31,443.5 | 44,642.0 | 1.19 | 1.42 | 1.00 |

## Per-workload winners and margins

Geomean of per-cell `fastest/rate` (lower = faster overall for the workload). Margin is the runner-up's geomean relative to the winner's (e.g. 1.20 vs 1.00 = runner-up 20% slower on the geomean).

| workload | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | margin over runner-up |
|---|---|---|---|---|---|---|
| publish | 25 | 1.085 | 1.127 | 1.440 | **HyrxMQ** | 1.04x (RabbitMQ) |
| pubget | 25 | 1.062 | 1.250 | 6.801 | **HyrxMQ** | 1.18x (RabbitMQ) |
| confirm | 25 | 1.024 | 1.172 | 38.479 | **HyrxMQ** | 1.14x (RabbitMQ) |
| fanout | 5 | 1.182 | 1.476 | 1.000 | **LavinMQ** | 1.18x (HyrxMQ) |

## Scaling curves — throughput vs concurrency (primary medians, msg/s)

### publish

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 138,097.8 | 136,320.0 | 139,448.9 |
| 64 | 4 | 397,760.0 | 334,996.1 | 413,724.4 |
| 64 | 8 | 608,000.0 | 406,316.5 | 551,480.3 |
| 64 | 16 | 582,069.9 | 414,401.8 | 553,175.8 |
| 64 | 32 | 612,667.8 | 421,073.2 | 582,495.8 |
| 1024 | 1 | 132,480.0 | 129,955.6 | 129,671.1 |
| 1024 | 4 | 446,802.4 | 328,528.6 | 393,914.5 |
| 1024 | 8 | 458,858.7 | 380,835.6 | 492,099.9 |
| 1024 | 16 | 489,516.3 | 378,929.6 | 500,166.6 |
| 1024 | 32 | 537,299.3 | 379,494.5 | 523,800.7 |
| 16384 | 1 | 43,093.3 | 45,760.0 | 43,448.9 |
| 16384 | 4 | 117,528.6 | 122,850.2 | 96,124.2 |
| 16384 | 8 | 116,274.3 | 137,543.2 | 93,445.7 |
| 16384 | 16 | 117,121.7 | 138,508.0 | 88,312.3 |
| 16384 | 32 | 128,465.9 | 137,840.8 | 95,773.8 |
| 65536 | 1 | 32,338.0 | 30,968.9 | 32,497.8 |
| 65536 | 4 | 35,547.7 | 50,810.0 | 28,531.0 |
| 65536 | 8 | 34,091.5 | 48,017.7 | 27,085.1 |
| 65536 | 16 | 34,977.1 | 38,947.4 | 25,502.2 |
| 65536 | 32 | 35,333.7 | 31,486.6 | 21,715.5 |
| 262144 | 1 | 9,198.9 | 8,801.8 | 4,042.5 |
| 262144 | 4 | 8,986.8 | 12,934.7 | 3,789.5 |
| 262144 | 8 | 8,799.1 | 10,748.4 | 3,519.8 |
| 262144 | 16 | 8,426.3 | 8,571.7 | 3,078.8 |
| 262144 | 32 | 7,952.8 | 6,368.2 | 2,911.8 |

### pubget

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 13,437.7 | 8,037.3 | 13,426.3 |
| 64 | 4 | 30,195.9 | 19,534.3 | 32,540.5 |
| 64 | 8 | 40,932.5 | 31,173.6 | 49,041.6 |
| 64 | 16 | 42,808.4 | 36,247.1 | 52,254.3 |
| 64 | 32 | 43,787.8 | 38,230.0 | 54,142.2 |
| 1024 | 1 | 13,209.7 | 7,843.2 | 13,104.1 |
| 1024 | 4 | 28,459.7 | 19,243.7 | 30,495.0 |
| 1024 | 8 | 34,924.9 | 27,183.4 | 39,614.8 |
| 1024 | 16 | 38,221.3 | 32,740.0 | 43,833.3 |
| 1024 | 32 | 40,004.9 | 35,146.0 | 45,279.2 |
| 16384 | 1 | 8,639.6 | 5,813.5 | 2,070.9 |
| 16384 | 4 | 15,282.9 | 12,802.1 | 118.0 |
| 16384 | 8 | 17,990.2 | 16,995.4 | 246.2 |
| 16384 | 16 | 19,513.2 | 18,212.3 | 475.0 |
| 16384 | 32 | 20,098.1 | 17,334.9 | 959.5 |
| 65536 | 1 | 6,124.6 | 4,507.3 | 225.2 |
| 65536 | 4 | 10,359.6 | 9,629.2 | 263.7 |
| 65536 | 8 | 10,815.2 | 10,104.1 | 207.9 |
| 65536 | 16 | 10,934.9 | 10,016.3 | 406.0 |
| 65536 | 32 | 10,005.4 | 9,742.8 | 798.3 |
| 262144 | 1 | 2,310.8 | 2,169.4 | 32.1 |
| 262144 | 4 | 3,567.6 | 3,500.0 | 120.5 |
| 262144 | 8 | 3,386.9 | 3,596.9 | 228.7 |
| 262144 | 16 | 2,927.4 | 3,399.3 | 464.9 |
| 262144 | 32 | 2,487.9 | 2,964.9 | 716.6 |

### confirm

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 64 | 1 | 7,333.3 | 4,142.9 | 133.8 |
| 64 | 4 | 15,527.4 | 10,868.9 | 279.8 |
| 64 | 8 | 19,128.0 | 15,652.2 | 493.7 |
| 64 | 16 | 24,531.5 | 21,373.0 | 1,004.5 |
| 64 | 32 | 24,573.4 | 22,018.3 | 1,699.5 |
| 1024 | 1 | 7,267.3 | 4,174.4 | 129.4 |
| 1024 | 4 | 15,012.7 | 10,823.1 | 333.7 |
| 1024 | 8 | 19,023.5 | 15,685.4 | 562.2 |
| 1024 | 16 | 20,405.4 | 18,387.3 | 881.9 |
| 1024 | 32 | 22,441.6 | 19,739.5 | 1,369.3 |
| 16384 | 1 | 4,742.1 | 3,509.6 | 21.1 |
| 16384 | 4 | 10,331.0 | 8,787.5 | 110.4 |
| 16384 | 8 | 12,544.2 | 11,801.6 | 174.1 |
| 16384 | 16 | 13,171.4 | 13,187.7 | 321.1 |
| 16384 | 32 | 13,362.3 | 12,587.0 | 492.8 |
| 65536 | 1 | 3,294.9 | 2,664.0 | 74.2 |
| 65536 | 4 | 7,038.2 | 6,095.9 | 81.5 |
| 65536 | 8 | 7,880.3 | 7,106.0 | 160.3 |
| 65536 | 16 | 7,931.3 | 7,275.6 | 273.7 |
| 65536 | 32 | 7,591.0 | 7,847.8 | 437.2 |
| 262144 | 1 | 1,949.3 | 1,694.9 | 21.8 |
| 262144 | 4 | 2,914.8 | 2,896.6 | 76.0 |
| 262144 | 8 | 2,909.1 | 3,222.2 | 123.8 |
| 262144 | 16 | 2,621.5 | 3,256.1 | 202.7 |
| 262144 | 32 | 2,274.5 | 2,855.4 | 214.0 |

### fanout

| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|
| 1024 | 1 | 12,203.4 | 7,627.1 | 12,811.4 |
| 1024 | 4 | 24,827.6 | 18,750.0 | 29,752.1 |
| 1024 | 8 | 30,906.0 | 26,785.2 | 38,468.1 |
| 1024 | 16 | 33,794.4 | 32,576.6 | 42,046.5 |
| 1024 | 32 | 37,666.7 | 31,443.5 | 44,642.0 |

## Latency percentiles (publish -> get -> ack, one in flight)

Per-op microseconds; median across reps of each run percentile. Ratio is p50 vs the fastest broker in that payload row.

| payload | broker | p50 | p95 | p99 | p99.9 | p50 ratio |
|---|---|---|---|---|---|---|
| 64 | HyrxMQ | 114.0 | 154.0 | 204.0 | 1,106.0 | 1.33x |
| 64 | RabbitMQ | 163.0 | 231.0 | 321.0 | 1,921.0 | 1.90x |
| 64 | LavinMQ | 86.0 | 124.0 | 183.0 | 1,521.0 | 1.00x |
| 1024 | HyrxMQ | 100.0 | 149.0 | 207.0 | 1,240.0 | 1.19x |
| 1024 | RabbitMQ | 165.0 | 249.0 | 394.0 | 1,932.0 | 1.96x |
| 1024 | LavinMQ | 84.0 | 129.0 | 206.0 | 1,336.0 | 1.00x |
| 16384 | HyrxMQ | 147.0 | 234.0 | 363.0 | 1,738.0 | 1.00x |
| 16384 | RabbitMQ | 202.0 | 312.0 | 597.0 | 2,003.0 | 1.37x |
| 16384 | LavinMQ | 154.0 | 310.0 | 40,901.0 | 41,821.0 | 1.05x |
| 65536 | HyrxMQ | 203.0 | 378.0 | 646.0 | 1,853.0 | 1.00x |
| 65536 | RabbitMQ | 257.0 | 461.0 | 1,251.0 | 2,177.0 | 1.27x |
| 65536 | LavinMQ | 261.0 | 41,366.0 | 42,023.0 | 42,660.0 | 1.29x |
| 262144 | HyrxMQ | 369.0 | 667.0 | 1,131.0 | 2,044.0 | 1.00x |
| 262144 | RabbitMQ | 405.0 | 647.0 | 1,354.0 | 1,988.0 | 1.10x |
| 262144 | LavinMQ | 41,020.0 | 42,354.0 | 44,986.0 | 45,490.0 | 111.17x |

**Lowest p50 across payloads:** HyrxMQ 3, LavinMQ 2.

## Resource usage (`docker stats --no-stream`, median during reps)

| workload | broker | CPU% median (max over cells) | RSS median (max over cells) |
|---|---|---|---|
| publish | HyrxMQ | 95.7 | 301.0 MiB |
| publish | RabbitMQ | 174.7 | 169.7 MiB |
| publish | LavinMQ | 55.9 | 40.5 MiB |
| pubget | HyrxMQ | 39.7 | 434.1 MiB |
| pubget | RabbitMQ | 85.4 | 194.7 MiB |
| pubget | LavinMQ | 43.1 | 47.1 MiB |
| confirm | HyrxMQ | 50.0 | 411.5 MiB |
| confirm | RabbitMQ | 112.0 | 261.3 MiB |
| confirm | LavinMQ | 41.4 | 63.1 MiB |
| fanout | HyrxMQ | 24.9 | 326.2 MiB |
| fanout | RabbitMQ | 139.0 | 128.7 MiB |
| fanout | LavinMQ | 12.9 | 51.7 MiB |
| latency | HyrxMQ | 19.9 | 336.3 MiB |
| latency | RabbitMQ | 30.0 | 185.7 MiB |
| latency | LavinMQ | 11.8 | 56.0 MiB |

## Overall verdict

Metric: geometric mean over throughput cells of `fastest/rate` per broker (lower = faster; 1.000 means fastest in every included cell). Bands group by concurrency. "fair" cells are those where all three brokers completed and every requested worker connected.

**Primary (all reps):**

| band | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | runner-up gap |
|---|---|---|---|---|---|---|
| 1 | 16 | 1.008 | 1.303 | 7.227 | **HyrxMQ** | 1.293x |
| 4-8 | 32 | 1.085 | 1.197 | 7.951 | **HyrxMQ** | 1.103x |
| 16-32 | 32 | 1.073 | 1.151 | 4.817 | **HyrxMQ** | 1.073x |
| overall | 80 | 1.064 | 1.198 | 6.384 | **HyrxMQ** | 1.126x |

**Clean (stall-/error-free):**

| band | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | runner-up gap |
|---|---|---|---|---|---|---|
| 1 | 16 | 1.008 | 1.303 | 7.217 | **HyrxMQ** | 1.293x |
| 4-8 | 32 | 1.085 | 1.197 | 7.825 | **HyrxMQ** | 1.103x |
| 16-32 | 32 | 1.073 | 1.151 | 4.810 | **HyrxMQ** | 1.073x |
| overall | 80 | 1.064 | 1.198 | 6.337 | **HyrxMQ** | 1.126x |

**Fastest overall (primary geomean, 80 fair throughput cells): HyrxMQ**, geomean ratio 1.064; RabbitMQ is 12.6% slower on the geomean; LavinMQ is 499.9% slower.

### Head-to-head HyrxMQ versus each broker

Geomean of `HyrxMQ rate / other rate` over the fair throughput cells (> 1.00 = HyrxMQ faster, < 1.00 = HyrxMQ slower). This isolates the HyrxMQ-vs-broker gap and does not depend on which broker is the per-cell fastest.

| scope | cells | HyrxMQ / RabbitMQ | HyrxMQ / LavinMQ |
|---|---|---|---|
| overall | 80 | 1.126 (+12.6%) | 5.999 (+499.9%) |
| band 1 | 16 | 1.293 (+29.3%) | 7.172 (+617.2%) |
| band 4-8 | 32 | 1.103 (+10.3%) | 7.331 (+633.1%) |
| band 16-32 | 32 | 1.073 (+7.3%) | 4.490 (+349.0%) |
| workload publish | 25 | 1.039 (+3.9%) | 1.327 (+32.7%) |
| workload pubget | 25 | 1.177 (+17.7%) | 6.403 (+540.3%) |
| workload confirm | 25 | 1.145 (+14.5%) | 37.595 (+3659.5%) |
| workload fanout | 5 | 1.249 (+24.9%) | 0.846 (-15.4%) |

## Precise claim about HyrxMQ

A cell counts as **fastest** if HyrxMQ has the top median rate, **tied** if within 2% of the top rate, **behind** otherwise. Ratios are fastest/HyrxMQ (1.00 = fastest; larger = HyrxMQ slower).

- **HyrxMQ is fastest in 43 throughput cells:** publish|64|8 (1.00x), publish|64|16 (1.00x), publish|64|32 (1.00x), publish|1024|1 (1.00x), publish|1024|4 (1.00x), publish|1024|32 (1.00x), publish|65536|32 (1.00x), publish|262144|1 (1.00x), publish|262144|32 (1.00x), pubget|64|1 (1.00x), pubget|1024|1 (1.00x), pubget|16384|1 (1.00x), pubget|16384|4 (1.00x), pubget|16384|8 (1.00x), pubget|16384|16 (1.00x), pubget|16384|32 (1.00x), pubget|65536|1 (1.00x), pubget|65536|4 (1.00x), pubget|65536|8 (1.00x), pubget|65536|16 (1.00x), pubget|65536|32 (1.00x), pubget|262144|1 (1.00x), pubget|262144|4 (1.00x), confirm|64|1 (1.00x), confirm|64|4 (1.00x), confirm|64|8 (1.00x), confirm|64|16 (1.00x), confirm|64|32 (1.00x), confirm|1024|1 (1.00x), confirm|1024|4 (1.00x), confirm|1024|8 (1.00x), confirm|1024|16 (1.00x), confirm|1024|32 (1.00x), confirm|16384|1 (1.00x), confirm|16384|4 (1.00x), confirm|16384|8 (1.00x), confirm|16384|32 (1.00x), confirm|65536|1 (1.00x), confirm|65536|4 (1.00x), confirm|65536|8 (1.00x), confirm|65536|16 (1.00x), confirm|262144|1 (1.00x), confirm|262144|4 (1.00x).
- **Tied (within 2%) in 4 cells:** confirm|16384|16 (1.00x), publish|65536|1 (1.00x), publish|64|1 (1.01x), publish|262144|16 (1.02x).
- **Behind in 33 cells.** Worst cases: publish|1024|16 (1.02x), confirm|65536|32 (1.03x), publish|64|4 (1.04x), publish|16384|4 (1.05x), fanout|1024|1 (1.05x), publish|16384|1 (1.06x), pubget|262144|8 (1.06x), pubget|1024|4 (1.07x), publish|1024|8 (1.07x), publish|16384|32 (1.07x), pubget|64|4 (1.08x), confirm|262144|8 (1.11x).
- The narrowest loss is 1.02x; the widest is 1.44x.
  - Losses by workload: publish 13, pubget 11, fanout 5, confirm 4.

## Failures, errors and stalls

- `pubget|16384|1` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 2,120.9 vs median 2,070.9 msg/s.
- `pubget|65536|4` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 376.9 vs median 263.7 msg/s.
- `pubget|262144|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 32.1 vs median 32.1 msg/s.
- `confirm|64|4` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 286.0 vs median 279.8 msg/s.
- `confirm|64|8` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 512.5 vs median 493.7 msg/s.
- `confirm|1024|8` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 575.2 vs median 562.2 msg/s.
- `confirm|16384|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 21.1 vs median 21.1 msg/s.
- `confirm|65536|4` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 87.7 vs median 81.5 msg/s.
- `confirm|262144|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 21.8 vs median 21.8 msg/s.
- `confirm|262144|32` **LavinMQ**: 1/7 reps stalled (wall > 3x target); clean median 225.1 vs median 214.0 msg/s.
- `latency|262144|1` **LavinMQ**: 7/7 reps stalled (wall > 3x target); clean median 26.5 vs median 26.5 msg/s.

## Caveats and limitations

- **Single host, single client.** All results are one physical machine (12 logical CPUs, CPU governor `powersave`), one client process, one Docker bridge. They establish relative behaviour here, not a universal ranking. This is **not** a claim that any broker is "fastest in the world".
- **These exact images.** Numbers are for the image digests above; a different RabbitMQ/LavinMQ/HyrxMQ build may differ.
- **CPU governor is `powersave`** on this host, so absolute rates are lower and noisier than a `performance` governor would give; relative ordering is the robust output.
- HyrxMQ is a fundamentally different design (Mojo, per-connection serving); RabbitMQ (Erlang/OTP) and LavinMQ (Crystal) are mature multi-threaded brokers. The comparison is behavioural, not architectural equivalence.
- `publish` targets a **bindingless** exchange: it measures the producer/transport ceiling and stores nothing.
- `pubget` uses `auto_ack=True` (routing + content + transport, not the ack path); `latency` uses explicit ack.
- `confirm` waits one confirm per publish; its untimed drain is outside the measured span.
- **LavinMQ large-payload collapse (important).** In `pubget` and `confirm` at payloads >= 16 KiB, and in `latency` at 256 KiB, LavinMQ delivered only ~20-960 msg/s (e.g. `pubget|16384|8` 246 msg/s, `confirm|16384|1` 21 msg/s, `latency|262144|1` p50 41 ms), with stall/error flags in 11 cells. LavinMQ's overall geomean (6.38) is dominated by these collapsed cells; treat that single number as an observed pathology of this image/workload, not a general LavinMQ capability. The **HyrxMQ-vs-RabbitMQ** verdict is unaffected, because both are scored against the same per-cell fastest rate.
- **LavinMQ is genuinely fastest in `fanout`** (all 5 cells, ~1.19-1.24x over HyrxMQ): that is not a collapse artifact.
- **HyrxMQ had zero stalls and zero worker errors in all 85 cells / 1,785 runs**; every stall/error above is LavinMQ.
- Container caps (`--cpus 4 --memory 2g`) can bind the multi-threaded brokers differently than HyrxMQ; not all brokers were re-tuned.
- Medians across 7 rotated reps suppress drift but not all noise; cells where brokers are within ~5% should be treated as ties.
