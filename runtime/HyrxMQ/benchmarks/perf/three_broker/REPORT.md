# Three-Broker AMQP Performance Benchmark

**HyrxMQ vs RabbitMQ vs LavinMQ — single host, all brokers in Docker.**

- Run id: `20260914T145132Z`
- Started (UTC): 2026-09-14T14:51:32.551137+00:00 · duration 1250.5s
- Mode: full · replicates per cell: 5 (median reported)

## Host & software

- CPU: AMD Ryzen 5 3600 6-Core Processor (12 logical CPUs)
- RAM: 15.54 GiB · kernel 7.2.4-3-cachyos · docker 29.8.0
- Client: pika 1.4.4 on Python 3.14.7
- HyrxMQ git: `99a464e` · CPU governor: powersave
- Images: hyrxmq:latest, rabbitmq:4-management, cloudamqp/lavinmq:latest

## Methodology (fairness notes)

- All three brokers run in their own container on **one user-defined bridge** (`hyrxmq-bench`), each published to `127.0.0.1`, so every client connection crosses the **same docker-proxy hop**.
- Each container is capped identically: `--cpus 4 --memory 2g`. (HyrxMQ is single-threaded, so it cannot use more than one core.)
- Credentials are `admin`/`password` on all three. RabbitMQ and LavinMQ users are created at container start; HyrxMQ's built-in default is `admin`/`password` (its `HYRXMQ_USERS` env var is not read by this build but the default already matches). Auth happens once per connection and is outside every timed window.
- Identical protocol config on all three: ephemeral (auto-delete, non-durable, **exclusive**) direct/fanout exchange + queue + binding, `delivery_mode=1`, `heartbeat=0`, `frame_max=131072`, `auto_ack=True` on the throughput `basic_get`.
  - `exclusive=True` is required because RabbitMQ 4.3 refuses transient *non-exclusive* queues (`transient_nonexcl_queues` deprecated). An exclusive+auto-delete queue is still fully ephemeral.
- One pika version, **one connection to one broker at a time** (the concurrency workload is the only exception: N thread pairs, each with its own connection).
- Every cell: first 10% of each rep is discarded as warm-up; `5` reps; **median** reported; count auto-tuned so a rep lasts >= 2s.
- Brokers run in a **rotated order across reps** to spread order/thermal bias. CPU% and RSS are sampled from `docker stats --no-stream` during each rep.

## Workload definitions

- **publish_get**: closed-loop publish -> basic_get(auto_ack), batch 128 so queue depth <= 128
- **publish_only**: fire-and-forget to an exchange with no bound queue (producer-bound ceiling)
- **latency**: publish -> get -> ack round trip, one in flight
- **confirms**: confirm_select; timed span is confirm-publish only, drain (64) is untimed
- **fanout**: 1 fanout exchange -> 4 queues, delivered msgs/s
- **concurrency**: N producer+consumer thread pairs, own connection+queue each, fixed duration
- **warmup**: first 10% of each rep
- **report**: median of >=5 reps

## Results

Rates are the median of the reps; `ratio` is relative to the fastest broker in that row. Every result — including where HyrxMQ loses — is shown.

### Workload 1 — publish + get (closed loop, auto_ack)

| param | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H / R / L) |
|---|---|---|---|---|---|
| 64B | 6,008.3 | 4,824.2 | 6,023.1 | 6,023.1 | 1.00 / 1.25 / 1.00 |
| 1024B | 5,809.5 | 4,754.5 | 6,020.9 | 6,020.9 | 1.04 / 1.27 / 1.00 |
| 16384B | 4,977.5 | 4,007.5 | 29.8 | 4,977.5 | 1.00 / 1.24 / 167.21 |
| 65536B | 3,425.5 | 2,922.1 | 1,664.9 | 3,425.5 | 1.00 / 1.17 / 2.06 |
| 262144B | 1,063.6 | 1,013.0 | 26.2 | 1,063.6 | 1.00 / 1.05 / 40.67 |

**Which is faster:**
- **64**: LavinMQ fastest at 6,023.1 msg/s (HyrxMQ 1.00x slower; RabbitMQ 1.25x slower)
- **1024**: LavinMQ fastest at 6,020.9 msg/s (HyrxMQ 1.04x slower; RabbitMQ 1.27x slower)
- **16384**: HyrxMQ fastest at 4,977.5 msg/s (RabbitMQ 1.24x slower; LavinMQ 167.21x slower)
- **65536**: HyrxMQ fastest at 3,425.5 msg/s (RabbitMQ 1.17x slower; LavinMQ 2.06x slower)
- **262144**: HyrxMQ fastest at 1,063.6 msg/s (RabbitMQ 1.05x slower; LavinMQ 40.67x slower)

### Workload 2 — publish-only (fire-and-forget producer ceiling)

| param | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H / R / L) |
|---|---|---|---|---|---|
| 64B | 18,100.4 | 18,982.7 | 18,460.4 | 18,982.7 | 1.05 / 1.00 / 1.03 |
| 1024B | 17,909.5 | 18,139.4 | 17,515.1 | 18,139.4 | 1.01 / 1.00 / 1.04 |
| 16384B | 15,789.9 | 16,806.8 | 15,640.5 | 16,806.8 | 1.06 / 1.00 / 1.07 |
| 65536B | 11,769.5 | 12,767.0 | 11,638.3 | 12,767.0 | 1.08 / 1.00 / 1.10 |
| 262144B | 3,151.1 | 3,265.7 | 3,278.8 | 3,278.8 | 1.04 / 1.00 / 1.00 |

**Which is faster:**
- **64**: RabbitMQ fastest at 18,982.7 msg/s (HyrxMQ 1.05x slower; LavinMQ 1.03x slower)
- **1024**: RabbitMQ fastest at 18,139.4 msg/s (HyrxMQ 1.01x slower; LavinMQ 1.04x slower)
- **16384**: RabbitMQ fastest at 16,806.8 msg/s (HyrxMQ 1.06x slower; LavinMQ 1.07x slower)
- **65536**: RabbitMQ fastest at 12,767.0 msg/s (HyrxMQ 1.08x slower; LavinMQ 1.10x slower)
- **262144**: LavinMQ fastest at 3,278.8 msg/s (HyrxMQ 1.04x slower; RabbitMQ 1.00x slower)

### Workload 3 — latency (publish -> get -> ack round trip, one in flight)

Per-op microseconds, pooled across reps:

| payload | broker | p50 | p95 | p99 | p99.9 | mean |
|---|---|---|---|---|---|---|
| 64B | HyrxMQ | 216.9 | 280.5 | 339.5 | 1,027.0 | 225.9 |
| 64B | RabbitMQ | 257.1 | 355.9 | 434.9 | 1,478.4 | 272.0 |
| 64B | LavinMQ | 207.0 | 267.0 | 326.8 | 1,460.6 | 215.9 |
| 1024B | HyrxMQ | 216.4 | 276.9 | 317.2 | 681.9 | 223.3 |
| 1024B | RabbitMQ | 271.2 | 334.6 | 390.5 | 1,121.1 | 279.5 |
| 1024B | LavinMQ | 213.9 | 269.4 | 311.8 | 1,015.4 | 220.9 |
| 16384B | HyrxMQ | 234.7 | 306.1 | 353.2 | 843.6 | 246.0 |
| 16384B | RabbitMQ | 294.3 | 372.0 | 464.7 | 850.1 | 306.2 |
| 16384B | LavinMQ | 579.1 | 41,983.5 | 42,084.7 | 42,307.9 | 20,520.0 |
| 65536B | HyrxMQ | 331.1 | 427.9 | 539.8 | 1,292.0 | 345.4 |
| 65536B | RabbitMQ | 379.8 | 473.6 | 561.0 | 1,413.5 | 394.2 |
| 65536B | LavinMQ | 420.5 | 41,537.0 | 42,144.8 | 42,831.9 | 12,989.2 |
| 262144B | HyrxMQ | 736.6 | 899.3 | 1,044.0 | 1,752.4 | 761.4 |
| 262144B | RabbitMQ | 774.8 | 962.5 | 1,095.2 | 1,792.0 | 800.7 |
| 262144B | LavinMQ | 41,943.9 | 43,020.0 | 45,033.8 | 46,256.3 | 37,629.8 |

**Which is faster (by p50):**
- **64**: LavinMQ lowest p50 (207.0us) (HyrxMQ 1.05x; RabbitMQ 1.24x)
- **1024**: LavinMQ lowest p50 (213.9us) (HyrxMQ 1.01x; RabbitMQ 1.27x)
- **16384**: HyrxMQ lowest p50 (234.7us) (RabbitMQ 1.25x; LavinMQ 2.47x)
- **65536**: HyrxMQ lowest p50 (331.1us) (RabbitMQ 1.15x; LavinMQ 1.27x)
- **262144**: HyrxMQ lowest p50 (736.6us) (RabbitMQ 1.05x; LavinMQ 56.94x)

### Workload 4 — publisher confirms (confirm wait)

| param | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H / R / L) |
|---|---|---|---|---|---|
| 1024B | 7,595.4 | 5,230.5 | 129.6 | 7,595.4 | 1.00 / 1.45 / 58.59 |

**Which is faster:**
- **1024**: HyrxMQ fastest at 7,595.4 msg/s (RabbitMQ 1.45x slower; LavinMQ 58.59x slower)

### Workload 5 — fanout (1 exchange -> 4 queues, delivered)

| param | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest (H / R / L) |
|---|---|---|---|---|---|
| 1024B | 7,579.5 | 5,615.6 | 7,147.8 | 7,579.5 | 1.00 / 1.35 / 1.06 |

**Which is faster:**
- **1024**: HyrxMQ fastest at 7,579.5 msg/s (RabbitMQ 1.35x slower; LavinMQ 1.06x slower)

### Workload 6 — concurrency (N producer+consumer thread pairs)

| pairs | broker | aggregate msg/s | pairs connected | errors/rep (median) |
|---|---|---|---|---|
| 1 | HyrxMQ | 5,303.8 | 1 | 0 |
| 1 | RabbitMQ | 4,284.2 | 1 | 0 |
| 1 | LavinMQ | 5,176.3 | 1 | 0 |
| 4 | HyrxMQ | 5,485.3 | 1 | 3 |
| 4 | RabbitMQ | 4,543.2 | 4 | 0 |
| 4 | LavinMQ | 4,905.0 | 4 | 0 |
| 16 | HyrxMQ | 5,561.0 | 1 | 15 |
| 16 | RabbitMQ | 4,031.1 | 16 | 0 |
| 16 | LavinMQ | 4,427.8 | 16 | 0 |

**Which is faster:**
- **1**: HyrxMQ highest at 5,303.8 msg/s (RabbitMQ 1.24x; LavinMQ 1.02x)
- **4**: HyrxMQ highest at 5,485.3 msg/s (RabbitMQ 1.21x; LavinMQ 1.12x) — note: HyrxMQ connected only 1/4 pairs, so this is a single-pair rate, not an aggregate
- **16**: HyrxMQ highest at 5,561.0 msg/s (RabbitMQ 1.38x; LavinMQ 1.26x) — note: HyrxMQ connected only 1/16 pairs, so this is a single-pair rate, not an aggregate

## Resource usage (docker stats --no-stream, median during reps)

| workload | broker | CPU% (median) | CPU% (max) | RSS (median) | RSS (max) |
|---|---|---|---|---|---|
| publish_get | HyrxMQ | 26.4 | 28.5 | 65.2 MiB | 65.8 MiB |
| publish_get | RabbitMQ | 45.1 | 47.6 | 285.0 MiB | 304.8 MiB |
| publish_get | LavinMQ | 19.6 | 25.9 | 45.1 MiB | 49.9 MiB |
| publish_only | HyrxMQ | 40.1 | 42.5 | 65.7 MiB | 66.1 MiB |
| publish_only | RabbitMQ | 75.4 | 76.7 | 141.0 MiB | 198.8 MiB |
| publish_only | LavinMQ | 58.9 | 63.8 | 32.1 MiB | 32.5 MiB |
| latency | HyrxMQ | 22.2 | 29.4 | 65.8 MiB | 66.1 MiB |
| latency | RabbitMQ | 50.1 | 50.3 | 138.2 MiB | 139.6 MiB |
| latency | LavinMQ | 18.2 | 21.3 | 32.1 MiB | 32.9 MiB |
| confirms | HyrxMQ | 13.7 | 14.1 | 65.8 MiB | 66.0 MiB |
| confirms | RabbitMQ | 35.2 | 36.9 | 136.3 MiB | 137.6 MiB |
| confirms | LavinMQ | 14.5 | 16.5 | 32.3 MiB | 32.7 MiB |
| fanout | HyrxMQ | 13.5 | 14.6 | 65.3 MiB | 66.0 MiB |
| fanout | RabbitMQ | 38.9 | 40.3 | 138.2 MiB | 139.1 MiB |
| fanout | LavinMQ | 16.6 | 18.2 | 32.0 MiB | 33.6 MiB |
| concurrency | HyrxMQ | 14.3 | 16.8 | 65.3 MiB | 65.7 MiB |
| concurrency | RabbitMQ | 65.7 | 81.3 | 144.1 MiB | 145.1 MiB |
| concurrency | LavinMQ | 23.3 | 25.9 | 33.8 MiB | 35.0 MiB |

## Overall verdict

Geometric mean of "ratio vs fastest" over the **18 fair cells** (all brokers completed; for concurrency, all brokers connected all requested pairs):

| broker | geomean ratio vs fastest | interpretation |
|---|---|---|
| HyrxMQ | 1.0207 | 1.021x slower than the per-cell fastest on average |
| RabbitMQ | 1.1583 | 1.158x slower than the per-cell fastest on average |
| LavinMQ | 4.2627 | 4.263x slower than the per-cell fastest on average |

**Winner on this hardware/workload set: HyrxMQ.** Ranking: HyrxMQ > RabbitMQ > LavinMQ.

This is a single-host, single-client, 3-way test. It does **not** establish "fastest AMQP broker in the world"; it establishes relative behaviour on this CPU, this kernel, this Docker, these images and this pika client.

## Failures and non-OK cells

- `concurrency` 4 **HyrxMQ**: 3 thread error(s) per rep (median); first: ConnectionFailed: hyrxmq: AMQPConnectorStackTimeout: Timeout during AMQP handshake'127.0.0.1'/(<AddressFamily.AF_INET: 2>, <SocketKind.SOCK_STREAM: 1>, 6, '', (
- `concurrency` 16 **HyrxMQ**: 15 thread error(s) per rep (median); first: ConnectionFailed: hyrxmq: AMQPConnectorStackTimeout: Timeout during AMQP handshake'127.0.0.1'/(<AddressFamily.AF_INET: 2>, <SocketKind.SOCK_STREAM: 1>, 6, '', (

## Caveats and limitations

- **HyrxMQ serves one connection at a time** in this build. At pairs>1 it completes exactly one handshake and the rest time out; the reported concurrency "aggregate" for HyrxMQ is therefore a single-pair rate. This is excluded from the overall verdict.
- The concurrency workload runs all thread pairs **inside one Python process with blocking pika**. The interpreter GIL limits how far any broker can scale there, so the multi-threaded brokers' aggregate does not represent their true scaling. A multi-process client would be needed to measure broker-side scaling.
- HyrxMQ's `hyrxmq:latest` default CMD is `hyrxmq-web`; in this build its embedded AMQP listener does not complete a client handshake. The identical image's dedicated binary `/app/build/hyrxmq-listen` (used here) does. HyrxMQ numbers are for that dedicated broker process.
- `publish_only` publishes to an exchange with **no bound queue**, so nothing is stored: it isolates the producer/transport ceiling. A single Python producer is itself a ceiling; these numbers are not broker receive-path limits.
- `confirms` times only the confirm-publish span; the drain that keeps the queue bounded runs outside the timed window.
- **LavinMQ large-payload behaviour**: in the batched `publish_get` shape (queue depth <= 128) LavinMQ throughput collapses at payloads >= 16 KiB (to tens of msg/s), and its per-op latency develops a heavy ~42 ms tail. The pattern was consistent across every rep and is reported as measured; it is most likely message-store segment pressure in LavinMQ, not a harness artifact.
- `publish_get` uses auto_ack=True, so it measures routing + content + transport, **not** the acknowledgement path. `latency` uses explicit ack.
- Results depend on this client, this host, container CPU/mem caps and the specific image versions. Do not generalise across hardware.
