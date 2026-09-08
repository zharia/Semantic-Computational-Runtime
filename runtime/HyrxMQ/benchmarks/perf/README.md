# Fair RabbitMQ-vs-HyrxMQ AMQP performance benchmark

Permanent, transport-symmetric benchmark of the HyrxMQ AMQP front end against
the reference RabbitMQ broker, driven by a real `pika` client. It is **not**
part of `scripts/test_all.sh` (correctness suite stays fast and deterministic);
run it explicitly with `pixi run bench-fair`.

Files:

| File | Role |
|------|------|
| `harness.py` | runs the matrix (4 cells × payloads + latency + floors), writes `results.json` |
| `pika_uds.py` | AF_UNIX transport for pika (subclass only, no pika source change, no new deps) |
| `docker_hyrx.py` | throwaway HyrxMQ-in-container image + lifecycle (the fairness cell) |
| `index.py` | the single Performance Rating `R` + transport matrix + floors |
| `compare.py` | baseline capture (`--update-baseline`) and the regression gate |
| `run_all.sh` | preflight → build → measure → rate → gate → cleanup |
| `baseline.json` | captured reference run (regenerate only via an explicit human step) |
| `results.json` | latest raw run |

## Quick start

```bash
/tmp/amqp-venv/bin/python -c 'import pika; print(pika.__version__)'  # 1.4.4
bash benchmarks/perf/run_all.sh                                      # full matrix (~6-8 min)
pixi run bench-fair                                                  # same thing
pixi run bench-regress                                               # gate only
```

Fast smoke variant: `BENCH_ARGS=--quick BENCH_PAYLOADS=64,1024 bash benchmarks/perf/run_all.sh`

## The four cells

| cell | endpoint | network path |
|------|----------|--------------|
| `rabbit-tcp` | `127.0.0.1:5672` | live `node-rabbitmq` container, docker port publish |
| `hyrx-tcp-docker` | `127.0.0.1:5700` | **throwaway container on the same bridge**, published the same way |
| `hyrx-tcp-native` | `127.0.0.1:5701` | host process, plain loopback |
| `hyrx-uds` | `/tmp/hyrx-bench-<pid>.sock` | `AF_UNIX`, no TCP/IP at all |

`rabbit-tcp` vs `hyrx-tcp-docker` is the **fair pair** used for the headline
rating: both brokers are reached through an identical userspace-proxy hop, so
the difference is the engine and not the wiring. `hyrx-tcp-native` and
`hyrx-uds` are reported as the transport matrix (they show the docker tax and
the UDS advantage), never as the headline.

RabbitMQ has **no** Unix-socket listener, so `hyrx-uds` is compared only
against `hyrx-tcp-native`. No RabbitMQ-over-UDS number exists here, by design.

## Fairness rules enforced by the harness

1. One process, one pika version, **one connection to one broker at a time**,
   strictly sequential, no concurrency on either side.
2. Identical AMQP configuration on both brokers (`PROTOCOL` in `harness.py`):
   ephemeral non-durable queue + direct exchange, `x-expires`, `auto_ack=True`
   on the drain get, `delivery_mode=1`, `heartbeat=0`, `frame_max=131072`,
   `channel_max=1`, no publisher confirms, same credentials, same connection
   teardown (abrupt fd close on every cell — our broker does not implement
   `channel.close-ok`/`connection.close-ok`, so graceful close would block
   there; keeping it abrupt on both sides keeps the two sides symmetric and
   outside every timed window).
3. Explicit exchange + bind, never the default exchange: default-exchange
   auto-binding is broker-specific behaviour, so it would not be a shared
   semantic.
4. Closed-loop workload: publish → `basic_get(auto_ack)` in batches of ≤256, so
   the in-flight depth stays far below HyrxMQ's 1024-entry queue capacity
   (beyond it, publishes are dropped **silently** — a rate measured past that
   point would be meaningless). Under-delivery raises instead of reporting.
   Why not open-loop: HyrxMQ has no push-to-idle-subscriber path (deliveries
   are flushed on subscribe, capped at 128), so an "active consumer" cell would
   stall on one broker and not the other. Ack correctness is proven separately
   by `scripts/interop/pika_content.py`, not here.
5. 5 % warm-up per rep, count auto-calibrated per cell so a rep lasts ≥2.5 s
   and a cell stays under `--max-cell-seconds` (default 90 s); 5 reps, median
   reported, spread reported, rep-aligned 95 % CI on the rating.
6. Measured floors, both raw and subtracted: `amqp_open_close` (handshake +
   teardown, no traffic), `bare_connect` (raw TCP/AF_UNIX connect + close, no
   AMQP at all — the docker-proxy tax and the transport floor), `empty_get`
   (get-empty method round trip on an established connection — the per-message
   latency floor).
7. The reference broker is only ever connected to: never started, stopped,
   restarted or reconfigured. Teardown of the benchmark's own container/image
   is unconditional (also on `--quick` runs and failures).

## The Performance Rating

```
G_T = exp( mean_p[ ln( T_hyrx(p) / T_rabbit(p) ) ] )     # median msgs/sec
G_L = exp( mean_p[ ln( L_rabbit(p) / L_hyrx(p) ) ] )     # p50 round-trip µs
R   = ( G_T + G_L ) / 2                                  # only for the fair pair
```

`R = 1.000` is parity, `R = 1.050` means HyrxMQ is ~5 % better on the geometric
average of throughput and latency. Higher = HyrxMQ faster. `index.py` prints
the per-payload factors, the CI from rep-aligned pairs, and the list of what the
number does **not** claim (durability, concurrency, open-loop producer rate,
TLS, cross-machine comparability).

## Regression gate

```bash
# capture (explicit human step, after reviewing a clean run)
/tmp/amqp-venv/bin/python benchmarks/perf/compare.py --update-baseline \
    --now benchmarks/perf/results.json

# gate
/tmp/amqp-venv/bin/python benchmarks/perf/compare.py \
    --baseline benchmarks/perf/baseline.json --now benchmarks/perf/results.json
```

Thresholds live in one block at the top of `compare.py`: HyrxMQ cell
throughput drop > 10 %, HyrxMQ p99 rise > 25 %, |ΔR| > 0.10 → `REGRESSION`,
exit 1. Missing/incomparable data → `INCONCLUSIVE`, exit 2 (never a silent
pass). The host signature (CPU model, `nproc`, kernel, governor, python, pika,
RabbitMQ version, HyrxMQ git HEAD) is recorded in both files: if it changed,
the comparison is loudly warned about (`--fail-on-host-mismatch` → exit 3),
because a cross-machine delta is not evidence of a code regression.

## Results

Latest numbers are generated by the run, not by this file — read
`results.json` / the printed table, or the report under
`program-increments/.../reports/perf_rabbitmq_vs_hyrxmq_fair.md`.
