# Fair RabbitMQ-vs-HyrxMQ AMQP Performance Benchmark (audit §19, §20, §32, §48)

**Package:** HyrxMQ — permanent transport-symmetric performance benchmark
**Date:** 2026-09-08
**Scope of change:** `benchmarks/perf/*` (new), `pixi.toml` (two new tasks),
`.gitignore` (two derived-artifact ignores), this report. **No `src/` or `tests/`
file was created or edited. The live `node-rabbitmq` container was not
started, stopped, restarted or reconfigured** (verified after the run:
`state=running startedAt=2026-09-08T04:07:04.713083117Z` — unchanged), and it
has no benchmark queues or exchanges left on it.
**Suite unaffected:** `bash scripts/test_all.sh` → `TOTAL pass=38 fail=0`
(the benchmark is *not* part of it — `pixi run bench-fair` is separate).

---

## 0. Headline result

| | value |
|---|---|
| **Performance Rating `R`** | **1.051** (HyrxMQ ~5 % faster) |
| 95 % CI (rep-aligned, n=5) | **[1.045, 1.053]** (median over reps 1.050) |
| Basis | fair pair only: `rabbit-tcp` vs `hyrx-tcp-docker` |
| Throughput factor `G_T` | 0.813 (HyrxMQ *slower* on the 5-payload geomean) |
| Latency factor `G_L` | 1.289 (HyrxMQ 28.9 % faster round trip) |
| Formula | `R = (G_T + G_L) / 2`, see §4 |
| Fair cell RAN? | **YES** — HyrxMQ-in-container built, ran all 5 payloads × 5 reps, torn down; **no fallback was needed** |
| pika AF_UNIX patch | **WORKS** (`PIKA_UDS_OK ... reply=GetOk`, preflight + all 25 UDS runs body-verified) |

The rating is *deliberately* close to parity even though the cells disagree
strongly by size: HyrxMQ wins ≤1 KB by 1.2–1.44× and loses ≥4 KB by 0.51×/0.28×.
A single number hides that, so §3/§5 state both halves explicitly.

---

## 1. Why this design is the honest one

### 1.1 The confound being removed

`node-rabbitmq` is reached through **Docker port publishing** (`docker-proxy`
userspace hop, `127.0.0.1:5672->5672`). A natively-started HyrxMQ process is
reached through plain loopback. Comparing those two measures "engine + one
extra userspace proxy on one side" — not the engine (audit §19/§20:
implementation/representation convenience silently redefining the comparison).

Fix: run **HyrxMQ in a container too**, on the same bridge, published
`127.0.0.1:5700->5700`, mirroring the rabbit publish. `docker_hyrx.py` copies
`build/hyrxmq-listen` **plus its full `ldd` closure including the host glibc and
`ld-linux-x86-64.so.2`** into an `alpine:latest`-based throwaway image, so the
container executes the identical binary against the identical libc. The only
variable that differs between `hyrx-tcp-native` and `hyrx-tcp-docker` is the
network path. Measured docker tax: **−9.2 % (geomean)** — real but far smaller
than the engine deltas, which is why the fair pair is the headline.

Base-image note (found, not assumed): a distro base's own glibc is older than
this host's (CachyOS), so the binary will not load against it; copying the host
libs is both the working and the fairer option.

### 1.2 Unix sockets: HyrxMQ-only, and compared to itself

Verified: **RabbitMQ has no AF_UNIX listener** (TCP-based only). There is
therefore **no RabbitMQ-UDS number in this report** — fabricating one would be
the exact failure §32/§48 warns about. `hyrx-uds` is compared against
`hyrx-tcp-native`, isolating the transport delta inside our own broker:
**+15.5 % (geomean), +2.9 %…+26.3 % by payload.** The bare-connect floor shows
why: 7.8 µs (AF_UNIX) vs 35.0 µs (loopback TCP) — the TCP/IP stack is skipped
entirely, while the AMQP path above the socket is the same
`AMQPConnServing` code (measured negotiation floor 670 µs UDS vs 828 µs native
TCP, i.e. the handshake cost is essentially identical, as it should be).

### 1.3 Identical protocol configuration

Both brokers get the same pika `ConnectionParameters` and the same declare
sequence: ephemeral non-durable queue + non-durable `direct` exchange +
explicit bind, `auto_ack=True` on the drain get, `delivery_mode=1`,
`heartbeat=0`, `frame_max=131072`, `channel_max=1`, no publisher confirms,
`x-expires=60000`, same credentials, same abrupt connection teardown (our broker
does not implement `channel.close-ok`/`connection.close-ok`, so graceful close
would block there; identical teardown on both sides keeps it symmetric and
outside every timed window).

Consequences stated plainly: this measures **routing + content framing +
transport**, *not* ack persistence, *not* durability, *not* flow control.
Ack/redelivery correctness is proven elsewhere (`scripts/interop/pika_content.py`,
9/9 on both brokers) — not by a rate benchmark.

### 1.4 The workload is a closed loop, and why

The requested shape ("producer-only push with an active auto-ack consumer") is
not measurable on both brokers as asked: HyrxMQ has no push-to-idle-subscriber
path — deliveries are flushed on subscribe, capped at `_CONSUME_FLUSH_MAX=128`
(`src/hyrxmq/amqp_service.mojo:107`, §32 intentional difference). A
`basic_consume` cell would therefore run on RabbitMQ and **stall after 128
messages on ours** — an artifact, not a result.

So the throughput cell is a symmetric closed loop: publish a batch of ≤256,
drain it with `basic_get(auto_ack)`, repeat. In-flight depth stays ≤256, far
below our 1024-entry queue capacity, beyond which **publishes are dropped
silently** — any rate measured past that point would be a fabrication. The
harness verifies every body and **raises** on under-delivery instead of
reporting a number. All 100 throughput reps and all 8000 latency samples were
body-verified (`all_verified=True` for every cell).

### 1.5 Other symmetry rules

One process, one pika (1.4.4), one connection to one broker at a time, strictly
sequential, no concurrency either side; 5 % untimed warm-up per rep; count
auto-calibrated per cell/payload (target ≥2.5 s per rep, cell cap 90 s); 5 reps;
median reported with spread; rep-aligned 95 % CI.

---

## 2. Environment / host signature (from this run)

| Field | Value |
|-------|-------|
| CPU | AMD Ryzen 5 3600 6-Core Processor (`nproc` = 12) |
| Kernel / arch | 7.1.8-1-cachyos / x86_64 |
| cpufreq governor | **powersave** (not pinned; affects all cells equally, but caps absolute numbers) |
| Load 1-min at start | 2.36 |
| Client | pika **1.4.4**, Python 3.14.7 (`/tmp/amqp-venv`) |
| Reference broker | `rabbitmq:4-management`, **RabbitMQ 4.3.5**, live container `node-rabbitmq`, `127.0.0.1:5672`, mgmt `15672` |
| Under test | HyrxMQ git **ed20be0**, `build/hyrxmq-listen`, `HYRXMQ_FRAME_MAX=131072` |
| Fair cell container | `hyrx-bench:ed20be0` on bridge, `127.0.0.1:5700->5700`, removed after the run |
| Run | 2026-09-08T14:16:47Z → 14:21:40Z (**293 s** wall, whole 4-cell matrix) |

This block is stored in `baseline.json` / `results.json` and re-checked by
`compare.py`; a changed signature makes the gate shout instead of silently
trusting the delta (§6).

---

## 3. Transport matrix (median msgs/sec, overhead vs HyrxMQ-native)

| payload | rabbit-tcp | hyrx-tcp-docker | hyrx-tcp-native | hyrx-uds |
|---------|-----------:|----------------:|----------------:|---------:|
| 64 B | 4 719 (+55.7 %) | 6 600 (+11.3 %) | **7 349** (ref) | **9 279 (−20.8 %)** |
| 256 B | 4 615 (+57.2 %) | 6 663 (+8.9 %) | **7 255** (ref) | **8 801 (−17.6 %)** |
| 1 024 B | 4 497 (+46.2 %) | 5 477 (+20.1 %) | 6 576 (ref) | 6 768 (−2.8 %) |
| 4 096 B | **4 401 (−45.5 %)** | 2 258 (+6.3 %) | 2 400 (ref) | 2 972 (−19.3 %) |
| 16 384 B | **4 077 (−70.4 %)** | 1 151 (+4.9 %) | 1 208 (ref) | 1 271 (−5.0 %) |

Parentheses = how much **slower** (+) or **faster** (−) than HyrxMQ-TCP-native,
i.e. the docker tax and the UDS gain in one view. Count per rep: rabbit
12 634→9 716, hyrx-docker 16 105→2 824, hyrx-native 18 810→2 947, UDS
23 202→3 136 (auto-calibrated from 64 B down to 16 kB). Rep-to-rep spread:
≤10.7 % worst case (rabbit 16 kB; docker cell 1 kB 9.8 %), ≤5.5 % for the
native and UDS cells.

Byte-rate view (the crossover explained): peak delivered
**MB/s = 66.8 (rabbit) vs 19.8 / 19.9 / 20.8 (HyrxMQ native / docker / UDS)**.
HyrxMQ hits a ~20 MB/s payload ceiling that **does not move with transport**
(docker −9 %, UDS +5 %): the ≥4 KB collapse is *inside the broker* (the
per-publish payload copy and ≥3 allocations per publish measured in the audit,
§18/§20/§21), not in the socket, not in the container. Message-rate-wise we are
1.2–1.44× ahead up to 1 KB; byte-rate-wise RabbitMQ is ~3.4× ahead at 16 KB.

### 3.1 Floors (measured µs, p50 / p99) and the floor-subtracted view

| cell | bare connect (no AMQP) | AMQP open+close (no traffic) | negotiation delta | empty-get RTT (per-msg floor) |
|------|-----------------------:|-----------------------------:|------------------:|------------------------------:|
| rabbit-tcp | 53.2 / 156.6 (TCP) | 1 538.1 / 2 877.4 | 1 484.9 | 121.7 / 203.7 |
| hyrx-tcp-docker | 44.5 / 107.3 (TCP) | 1 018.6 / 2 110.9 | 974.1 | 84.8 / 131.4 |
| hyrx-tcp-native | 35.0 / 88.0 (TCP) | 862.9 / 1 939.0 | 827.9 | 65.9 / 92.1 |
| hyrx-uds | 7.8 / 25.2 (AF_UNIX) | 678.2 / 4 700.8 | 670.4 | 68.5 / 116.9 |

* `negotiation delta` = open+close minus bare connect: the AMQP handshake+teardown
  cost. RabbitMQ's is 1.52× ours on the *same* published path (1 484.9 vs 974.1 µs)
  — a genuine engine-level result of the fair pair, and independent of payload size.
* `empty-get RTT` is the per-message floor used for subtraction below.
* The UDS `open+close` **p99 is 4.7 ms** (vs 678 µs p50): our single-at-a-time
  accept loop, reaping the previous force-closed connection before the next
  `accept`. Not a throughput-path effect (throughput cells reuse one
  connection), but it is a real tail and it is recorded, not smoothed away.

Floor-subtracted 256 B round trip (content+routing work only):

| cell | p50 raw | p50 − empty-get floor | ratio to its own floor |
|------|--------:|----------------------:|-----------------------:|
| rabbit-tcp | 248.0 | 126.3 | 1.04× |
| hyrx-tcp-docker | 192.4 | 107.6 | 1.27× |
| hyrx-tcp-native | 165.8 | 99.9 | 1.52× |
| hyrx-uds | 138.7 | 70.2 | 1.03× |

Read: our per-message *work above the floor* is smaller in absolute µs on every
transport, but a larger share of our 256 B round trip is method/queue overhead
rather than the floor — i.e. we are faster mostly because our path is shorter,
and the remaining per-op method cost at 1 KB+ is what the byte-rate ceiling
above also exposes.

---

## 4. The Performance Rating

```
G_T = exp( mean_p[ ln( T_hyrx(p) / T_rabbit(p) ) ] )     # median msgs/sec
G_L = exp( mean_p[ ln( L_rabbit(p) / L_hyrx(p) ) ] )     # p50 round-trip µs
R   = ( G_T + G_L ) / 2                                  # fair pair only
```

* `p` = payloads with data in **both** fair-pair cells; geometric mean so a 2×
  win and a 2× loss cancel exactly.
* `G_T` uses all five throughput payloads; `G_L` uses the payload the latency
  cell ran (256 B). They are *not* intersected — restricting throughput to the
  single latency payload would turn the headline into a one-point measurement.
* `R = 1.000` parity, `R = 1.050` ≈ HyrxMQ 5 % better, higher = HyrxMQ faster.

This run: `G_T = 0.813`, `G_L = 1.289`, **`R = 1.051`**, rep-aligned 95 % CI
**[1.045, 1.053]** (rep-aligned R values 1.0436 / 1.0492 / 1.0502 / 1.0507 /
1.0521, median 1.0502; the CI reflects only *within machine* rep variance — it
is not a claim about other hosts).

Per-payload detail printed by `index.py`:

| payload | T rabbit → hyrx-docker | ratio | L rabbit → hyrx (p50 µs) | ratio |
|---------|-----------------------:|------:|-------------------------:|------:|
| 64 B | 4 719 → 6 600 | 1.399× | not sampled | — |
| 256 B | 4 615 → 6 663 | 1.444× | 248.0 → 192.4 | 1.289× |
| 1 024 B | 4 497 → 5 477 | 1.218× | not sampled | — |
| 4 096 B | 4 401 → 2 258 | 0.513× | not sampled | — |
| 16 384 B | 4 077 → 1 151 | 0.282× | not sampled | — |

### 4.1 What `R` does **NOT** claim (§48)

1. **Not "HyrxMQ is faster."** It is ~5 % faster on the geometric average of
   one message-rate factor and one small-payload latency factor, and 2–3.5×
   *slower* in message rate at ≥4 KB. Any statement built from `R` alone hides
   the crossover in §3.
2. Not open-loop producer rate (closed loop, §1.4) — RabbitMQ's real
   producer-only rate would be *higher* than shown here, so `R` is if anything
   generous to us on that axis.
3. No durability, persistence, TLS, heartbeat, flow-control/prefetch,
   clustering, security or production-readiness claim (all excluded by the
   configuration in §1.3; prefetch is not even enforced by us).
4. No concurrency or scaling claim: one connection at a time, single-threaded
   serialized server (§24/§25/§26 of the audit still stand).
5. No RabbitMQ-over-UDS comparison (§1.2).
6. Not machine-independent: `R` is only comparable between runs sharing the host
   signature; governor is `powersave` and unpinned here.
7. Not a bitwise/numerical-equivalence statement about delivered content —
   bodies are byte-checked (they were, everywhere), envelope/property fidelity
   is **not** (our deliver frames carry empty exchange/routing key and no
   properties, audit §32/D1). The benchmark measures bytes moved, not
   metadata correctness.
8. `R` is computed from *this client*: a different client (different framing/
   pipelining) will produce different absolute rates.

---

## 5. Round-trip latency (publish → get → ack, 2 000 samples, 256 B)

| cell | p50 | p95 | p99 | p99.9 |
|------|----:|----:|----:|------:|
| rabbit-tcp | 248.0 | 323.9 | 412.8 | 1 356.9 |
| hyrx-tcp-docker | 192.4 | 247.2 | 301.4 | 393.3 |
| hyrx-tcp-native | 165.8 | 196.6 | 248.3 | 402.5 |
| hyrx-uds | **138.7** | **157.3** | **196.4** | **323.3** |

Fair-pair latency: **1.29× better p50, 1.37× better p99** for HyrxMQ. UDS
relative to native TCP: −16.3 % p50, −20.9 % p99. This cell uses an explicit
`basic_ack` (the rate cell does not), so it also exercises the ack path —
2 000/2 000 acks per cell without a single broker error or restart.

---

## 6. Regression gate (verified, both directions)

```bash
pixi run bench-fair                                        # run + rate + gate
pixi run bench-regress                                     # gate vs baseline.json
/tmp/amqp-venv/bin/python benchmarks/perf/compare.py \
    --baseline benchmarks/perf/baseline.json --now benchmarks/perf/results.json
/tmp/amqp-venv/bin/python benchmarks/perf/compare.py \
    --update-baseline --now benchmarks/perf/results.json   # explicit human step
```

* Self-comparison (baseline = the run above): **all 24 rows PASS, ΔR = +0.000,
  `GATE PASS`, exit 0.**
* Injected regression test (synthetic copy of the run with HyrxMQ rates scaled
  ×0.7, one p99 set to 900 µs, native ×1.6, git HEAD changed): **12 rows
  `REGRESSION`, ΔR −0.122 → `REGRESSION`, `GATE FAIL`, exit 1**, and the host
  signature change was reported first
  (`hyrxmq_git_head: 'ed20be0' -> 'deadbee'` → "comparison is NOT
  trustworthy"). Directions were checked: a HyrxMQ *gain* (native ×1.6) passes,
  a loss fails; the reference broker is reported but never gates us (a RabbitMQ
  drift >25 % shows as `WARN drift`, since it invalidates the pair rather than
  our code).
* Missing or incomparable data → `INCONCLUSIVE` + exit 2, never a silent pass.
  `index.py` refuses to compute `R` when either fair-pair cell is absent
  (verified: `R = NOT COMPUTED: hyrx-tcp-docker unavailable` on a rabbit-only
  run) and exits 3.
* Thresholds, one block at the top of `compare.py`:
  `THROUGHPUT_DROP_PCT=10.0`, `P99_RISE_PCT=25.0`, `RATING_DELTA=0.10`,
  `RABBIT_DRIFT_WARN_PCT=25.0`.

`baseline.json` is the pinned reference run; `results.json` and
`regression_report.json` are derived (`.gitignore`), so a new measurement can
never overwrite the reference implicitly.

---

## 7. Reproduction (exact)

```bash
cd runtime/HyrxMQ
pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen
bash benchmarks/perf/run_all.sh
# cheaper smoke:
BENCH_ARGS=--quick BENCH_PAYLOADS=64,1024 bash benchmarks/perf/run_all.sh
# subsets:
BENCH_CELLS=rabbit-tcp,hyrx-tcp-docker BENCH_MAX_CELL_SECONDS=60 bash benchmarks/perf/run_all.sh
# pieces:
/tmp/amqp-venv/bin/python benchmarks/perf/pika_uds.py /tmp/x.sock        # UDS patch probe
/tmp/amqp-venv/bin/python benchmarks/perf/docker_hyrx.py up|down|status  # fair container
/tmp/amqp-venv/bin/python benchmarks/perf/harness.py --out /tmp/r.json   # matrix
/tmp/amqp-venv/bin/python benchmarks/perf/index.py /tmp/r.json           # R + tables
```

`run_all.sh` preflights (rabbit live + `pika_uds.py` probe), builds, measures,
rates, gates, and on **exit** (trap) removes every `hyrx-bench*`
container/image, unlinks its `/tmp/hyrx-bench-*.sock`, kills its own broker
children, and prints a leftover report. Verified after this run:
`LEFTOVERS {'containers': [], 'images': []}`, `rabbit queues left by bench:
none`, `rabbit exchanges left by bench: none`, `node-rabbitmq state: running`.
No `hyrxmq-listen` process from the benchmark survives it (0 restarts were
needed in this run).

---

## 8. Not comparable / blocked / NOT PROVEN

| Item | Status | Why |
|------|--------|-----|
| RabbitMQ over AF_UNIX | **NOT MEASURABLE, by design** | RabbitMQ has no Unix-socket listener; no number invented (§1.2) |
| Open-loop producer-only rate | **NOT MEASURED** | our broker has no push-to-idle-subscriber path (`_CONSUME_FLUSH_MAX=128`, §32); an "active consumer" cell would stall on one broker only |
| Ack persistence / durability cost | **EXCLUDED from rates** | `auto_ack` on the drain get + `delivery_mode=1` + non-durable topology, deliberately (§1.3); ack path measured only in the latency cell |
| Prefetch / flow control | **NOT COMPARABLE** | HyrxMQ does not enforce QoS; RabbitMQ defaults unlimited here |
| Heartbeats, TLS, `basic.nack` requeue, `basic.cancel`, connection.close | **NOT COMPARABLE** | not implemented/verified on our broker (audit §29); also not exercised by these cells |
| Envelope/property fidelity of deliveries | **NOT PROVEN here** | bodies byte-checked; exchange/rk/properties in our deliver frames are empty (audit §32, D1) |
| Multi-connection, many producers/consumers, sustained soak | **NOT PROVEN** | single connection at a time is the benchmark's fairness constraint; server is serialized |
| Consumer-side push throughput (both brokers, `basic_consume`) | **NOT MEASURED** | would be a RabbitMQ-only number; kept out rather than reported as a comparison |
| Machine-independence of `R` | **NOT ESTABLISHED** | one host, governor unpinned; `compare.py` flags any signature change instead of trusting the delta |
| Container CPU/memory limits as a confound | **NOT ISOLATED further** | the fairness container is started with no `--cpus`/`--memory` limits (same as the rabbit container), so both brokers share the same docker resource policy |

Two claims from the run that go beyond `R`, and are stated as measured facts
rather than as a rating: (a) our AMQP connection negotiation is 1.52×
cheaper than RabbitMQ's on the same published path (§3.1), (b) our delivered
byte rate saturates near 20 MB/s independent of transport, which localizes the
large-payload loss to the in-broker payload copy path the audit already
identified as the hotspot (§18/§21) — a *recommendation* for the next
optimization step, not an implemented fix (rule 17: correctness and measurement
first).
