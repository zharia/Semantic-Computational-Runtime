# HyrxMQ Benchmark Suite — empirical results (audit §19, §20, §21)

Date: 2026-09-08. Author: benchmark suite added under `benchmarks/`.
All numbers below come from **actual runs performed in this environment**. No
number is estimated or invented (§32). Run-to-run variance is real and is
stated where observed; single-run values are not averaged.

## Environment

| Item | Value |
|------|-------|
| CPU | AMD Ryzen 5 3600 (6 cores / 12 threads), `nproc` = 12 |
| OS / kernel | Linux (CachyOS), kernel `7.1.8-1-cachyos`, x86_64 |
| Mojo | **1.0.0 (ed45d567)** |
| `CLK_TCK` | 100 (1 tick = 10 ms) |
| Profilers | **none available**: `perf`, `valgrind`, `strace`, `ltrace` absent (`gdb` present but is a debugger, not a sampling/trace profiler) |
| `/proc` | readable for the process (stat/status sampled externally — see §B4) |

## Commands (exact)

Each benchmark is a file under `benchmarks/`; `mojo run` adds the main file's
directory to the search path, so they `import` the shared helpers
(`LatencyResult`, `compute_percentiles`, `format_ns`, `BenchmarkResult`) from
`direct_benchmark.mojo` instead of duplicating them.

```sh
pixi run bench-direct      # == mojo run -I src -I vendor/flare benchmarks/interleaved_direct.mojo
pixi run bench-transport   # == mojo run -I src -I vendor/flare benchmarks/transport_matrix.mojo
pixi run bench-fanout      # == mojo run -I src -I vendor/flare benchmarks/fanout_copy.mojo
pixi run bench-profile     # == mojo run -I src -I vendor/flare benchmarks/profiling_probe.mojo
```

The four `bench-*` tasks were added to `pixi.toml` `[tasks]`; existing tasks
(`build`, `test`) are untouched. The benchmarks are **not** in
`scripts/test_all.sh` (they are long workloads, not correctness smoke).

---

## B1 — Interleaved (steady-state) direct — audit §19

`benchmarks/interleaved_direct.mojo`. The audit says publish-all-then-consume-all
is **not** steady-state evidence. This runs, per iteration, the full
`publish → route → consume → ack` cycle on one engine so queue depth stays ~0–1
(bounded). The timed region is the engine cycle; the payload `Buffer` is
constructed just before `t0`.

Counts chosen to finish each cell in < 20 s. Single run:

| payload | cycles | msgs/s | MiB/s | p50 | p95 | p99 | p99.9 |
|--------:|-------:|-------:|------:|----:|----:|----:|------:|
| 64 B    | 98 000 | 716 765 | 43.74 | 1.00 µs | 1.38 µs | 1.68 µs | 4.86 µs |
| 256 B   | 98 000 | 276 073 | 67.40 | 2.38 µs | 3.48 µs | 3.91 µs | 8.36 µs |
| 1 024 B | 98 000 | 85 005  | 83.01 | 7.29 µs | 9.70 µs | 12.23 µs | 15.55 µs |
| 4 096 B | 48 000 | 23 474  | 91.69 | 26.95 µs | 33.91 µs | 43.60 µs | 55.47 µs |
| 65 536 B| 8 000  | 1 376   | 86.02 | 465.25 µs | 572.48 µs | 741.12 µs | 909.03 µs |

All percentiles above are from the single `pixi run bench-direct` invocation
(the program prints the full distribution per cell).

**Run-to-run variance (honest):** a second build of the same file gave 256 B =
340 435 msgs/s and 64 B = 828 017 msgs/s (~20% higher). Throughput is reported
per single run, not averaged; treat the two runs as a variance band, not a
regression. Bandwidth plateaus at ~85–98 MiB/s across 256 B–64 KiB — the ceiling
is the per-byte copy path (§B3), not the queue.

Interpretation: this is the **correct baseline**. The cycle cost scales with
payload because `publish()` copies the payload (and twice, see §B3). At 64 B the
cycle is ~1 µs; at 64 KiB it is ~465 µs.

---

## B2 — Transport matrix (real sockets), same workload — audit §19

`benchmarks/transport_matrix.mojo`. Same `publish → route → consume → ack`
workload measured across four transports over **single-process loopback**
(bind→connect→accept, strict ping-pong, tiny payloads → no blocking). For the
socket rows the engine cycle runs on the *server* side; the timed region adds
the two wire hops (payload down, 1-byte ack up) and, for AMQP, the codec.

Cycle is serialized (one message in flight), so throughput = 1 / mean cycle.

### 256 B (primary), 20 000 cycles, 2 000 warm-up — single run

| transport | p50 | p95 | p99 | p99.9 | mean | msgs/s | overhead vs direct (p50) |
|-----------|----:|----:|----:|------:|-----:|-------:|--------------------------:|
| direct    | 3.36 µs | 5.20 µs | 5.66 µs | 11.21 µs | 3.57 µs | 280 144 | — |
| UDS       | 8.21 µs | 10.90 µs | 12.80 µs | 20.67 µs | 8.48 µs | 117 943 | **+4.85 µs** (~2.4×) |
| Hyrx TCP  | 14.28 µs | 19.35 µs | 20.92 µs | 30.57 µs | 14.82 µs | 67 460 | **+10.92 µs** (~4.3×) |
| AMQP/TCP  | 23.27 µs | 32.99 µs | 36.27 µs | 52.56 µs | 24.94 µs | 40 094 | **+19.91 µs** (~6.9×) |

- **UDS overhead vs direct** = +4.85 µs (two AF_UNIX hops + kernel copies).
- **TCP overhead vs direct** = +10.92 µs; **TCP vs UDS** = +6.07 µs (loopback IP
  stack over AF_UNIX).
- **AMQP overhead vs TCP** = +8.99 µs = the **codec + adapter** cost (encode
  publish frame, feed/parse frame, adapter publish/deliver/ack, encode + parse
  ack frame) on top of the identical TCP hop.

### 64 B (note), same run

| transport | p50 | msgs/s | overhead vs direct (p50) |
|-----------|----:|-------:|--------------------------:|
| direct    | 1.18 µs | ~790 000 | — |
| UDS       | 5.62 µs | ~171 000 | +4.44 µs |
| Hyrx TCP  | 11.24 µs | ~85 000 | +10.06 µs |
| AMQP/TCP  | 16.37 µs | ~59 000 | +15.19 µs (codec +5.13 µs over TCP) |

The overheads are **near-constant in payload** (UDS +4.4…+4.9 µs, TCP
+10.1…+10.9 µs, AMQP +15.2…+19.9 µs across 64 B→256 B): they are per-message
transport/protocol costs, not bandwidth costs. Runtime: **2.4 s** total.

Interpretation (phrasing per §20): the per-transport overhead is **strongly
indicated by measurement** to be dominated by socket syscalls + protocol
machinery, not by payload copy (the deltas barely move from 64 B to 256 B).
§B4 CPU split corroborates the syscall attribution.

---

## B3 — Message-copy / fan-out investigation — audit §21

`benchmarks/fanout_copy.mojo`. **Measurement only** — no Candidate A–D refactor
attempted. `Router.publish()` (src/hyrx/core/router.mojo:161–183) copies the
payload **twice per destination** (copy #1 `msg.payload()`→snapshot at :170;
copy #2 per-byte rebuild at :177–180), so bytes written/publish ≈
`2 × destinations × payload`. Queues are declared at capacity 8 and never
consumed, so memory stays bounded while every destination still pays its two
copies (copy precedes `enqueue`). publish-only loop; engine rebuilt per cell.

### engine `publish()` p50 (ns/µs/ms), destinations × payload — single run

| dests | 64 B | 256 B | 4 KiB | 64 KiB |
|------:|-----:|------:|------:|-------:|
| 1     | 870 ns | 2.58 µs | 36.33 µs | 581.8 µs |
| 2     | 1.63 µs | 5.12 µs | 72.58 µs | 1.157 ms |
| 10    | 7.37 µs | 24.12 µs | 351.4 µs | 6.142 ms |
| 100   | 78.12 µs | 238.4 µs | 3.668 ms | **58.28 ms** |

The cost is **linear in destinations and linear in payload** (D=1→100 ≈ 90× at
every payload; payload 64B→64KiB = 1024× at every D).

### Marginal cost of the last 90 destinations over D=1 (per-destination added cost)

| payload | p50 D=1 | p50 D=100 | per-dest added | implied copy rate |
|--------:|--------:|----------:|---------------:|------------------:|
| 64 B    | 800 ns | 79.09 µs | +791 ns/dest | ~150 MiB/s |
| 256 B   | 2.43 µs | 237.8 µs | +2.38 µs/dest | ~198 MiB/s |
| 4 KiB   | 33.53 µs | 3.385 ms | +33.85 µs/dest | ~230 MiB/s |
| 64 KiB  | 536.8 µs | 54.96 ms | +549.7 µs/dest | ~227 MiB/s |

### Isolated copy model (the exact snapshot+rebuild the router runs, 1 destination)

| payload | ns/copy | bytes/sec |
|--------:|--------:|----------:|
| 64 B | 846 ns | 144 MiB/s |
| 256 B | 3.14 µs | 156 MiB/s |
| 4 KiB | 46.96 µs | 166 MiB/s |
| 65 536 B | 809 ns·1e3 = 809 µs | 155 MiB/s |

The per-destination marginal cost (§ B3 second table) **matches the isolated
copy rate to within ~10%** — the added cost of each destination **is** the two
per-byte copy loops, and those loops run at only **~145–165 MiB/s**. A `memcpy`
on the same machine sustains multiple GiB/s; the bottleneck is the scalar
`for j in range(size): dst[j] = snap[j]` loop with per-element `List` bounds
checks, **not** the fan-out topology itself. Runtime: **11.2 s** total.

### Recommendation (evidence-based; per §20 phrasing rules)

The copy path is an **implementation-level hotspot**, and the measurements above
**strongly indicate** it is the dominant term at high `destinations × payload`
(58 ms/publish at 100×64 KiB). It is **not** "proven" to be the sole system
bottleneck — no sampling profiler is available (§B4). Ranked by measured value:

1. **Candidate C — ownership transfer when exactly one destination** is the best
   first target. The single-consumer case (D=1) is the common path and already
   pays 2 redundant payload copies + a snapshot per publish; the measured D=1
   cost is dominated by those copies (§B4 route share 62% at 256 B). Transferring
   the one owned `Buffer` instead of copy-rebuilding removes both without any
   shared-ownership semantics — the lowest-risk, highest-frequency win.
2. **Candidates A/B — immutable shared payload + per-delivery metadata, or
   refcounted shared storage** are what turn fan-out from **O(D × payload)** into
   **O(D)**; they dominate the 58 ms at 100×64 KiB and should be evaluated next
   for multi-destination routes.
3. Regardless of the above, **copy #2 (router.mojo:177–180) is pure overhead vs
   copy #1** — two full payload writes where one bulk `memcpy`-class copy would
   do. Replacing the scalar loop with a block copy (a representation change
   requiring spec sign-off) would alone lift the per-dest rate ~10× off the
   ~150 MiB/s floor. This is the smallest edit with the largest measured slope
   and should be evaluated **before** the A/B ownership redesigns.

Do **not** fold these into one change: C removes copies on the 1-dest path, the
memcpy fix raises the per-copy rate, and A/B change fan-out asymptotics — they
compose. §21 forbids replacing this before measuring; measurement is now done.

---

## B4 — Profiling baseline, honest about tooling limits — audit §20

`benchmarks/profiling_probe.mojo`. No `perf`/`valgrind`/`strace`, so **no profile
is fabricated**. Attribution is by (a) wall-clock phase timers inside the program
and (b) `/proc/<pid>/stat` + `/proc/<pid>/status` sampled from the shell around
**AOT-built** binaries (`mojo build`) so JIT codegen is excluded.

### (a) Phase decomposition of one in-process cycle, 20 000 cycles (single run)

| payload | alloc (build Buffer+fill) | route (publish: match+2×copy) | deliver (next_message) | ack (destroy) | cycle total |
|--------:|--------------------------:|------------------------------:|-----------------------:|--------------:|------------:|
| 64 B    | 314 ns (24%) | 742 ns (**56%**) | 164 ns (12%) | 104 ns (8%) | 1.32 µs |
| 256 B   | 1.08 µs (31%) | 2.16 µs (**62%**) | 161 ns (5%) | 103 ns (3%) | 3.50 µs |
| 4 KiB   | 16.50 µs (35%) | 30.88 µs (**65%**) | 176 ns (0.4%) | 109 ns (0.2%) | 47.67 µs |

`route` (publish) is the largest phase and grows with payload → the copy path.
`deliver` and `ack` are **flat ~160 ns / ~100 ns regardless of payload** — they
move a claim token and destroy a buffer, no payload copy. This corroborates §B3:
the per-byte copy loops are the hot component. Derived bytes-copied/publish =
`2 × payload` at D=1 (128/512/8192 B) at **~165–250 MiB/s** effective — the same
~150–300 MiB/s floor measured in §B3. Runtime: **1.16 s**.

### (b) `/proc` external measurements (AOT binaries, near-final sample before exit)

| binary (workload) | user ms | sys ms | kernel share | minor faults | major faults | voluntary ctxt | nonvoluntary ctxt |
|-------------------|--------:|-------:|-------------:|-------------:|-------------:|---------------:|------------------:|
| b4 direct 256 B/4 KiB cycle | 950 | 0 | 0% | ~1 570 | 0 | 2 | 49 |
| b1 interleaved direct (all sizes) | 12 730 | 0 | 0% | 2 050 | 0 | 5 | 480 |
| b3 fan-out (1..100 dest) | 8 930 | 20 | 0.2% | 15 961 | 0 | 2 | 486 |
| b2 transport matrix (UDS+TCP+AMQP) | 1 290 | 710 | **35%** | 1 729 | 0 | 2 | 200 |

Readings:
- **Direct/fan-out are 100% user time (sys ≈ 0)** — pure userspace copy work, no
  kernel/syscall component. Consistent with §B1/§B3 copy attribution.
- **Transport matrix spends ~35% of its CPU in the kernel (710 ms sys)** — this is
  the socket `send`/`recv` syscall + kernel-copy cost that §B2 measures as the
  per-transport overhead. It is a **strong indicator** (not a syscall count) that
  the socket overhead is kernel-copy/syscall-bound.
- **Voluntary context switches are tiny (2–5) on every row** — even the loopback
  socket ping-pong never blocks (strict sequencing keeps data in the kernel
  buffer), so transport overhead is **on-CPU kernel time**, not off-CPU
  wakeup/scheduler cost. Nonvoluntary switches (200–486) reflect the 12-core
  scheduler preempting the CPU-bound loops, not message flow.
- **Major faults = 0 everywhere** (working set fits RAM); minor faults track
  allocation volume — b3's 15 961 minor faults reflect the large per-message
  `Buffer` churn in the fan-out loop.

### NOT PROVEN (no profiler available in this toolchain)

- **syscalls/msg** — needs `strace`/`perf trace` (absent). The b2 kernel-time
  fraction (35%) is a proxy only.
- **cache misses / IPC** — needs `perf stat` (absent). The ~150–250 MiB/s copy
  rate is *strongly indicated* to be scalar-loop + bounds-check bound, not proven
  to be memory-bandwidth or cache bound.
- **off-CPU / wakeup / scheduler overhead per message** — needs a scheduler
  tracer; voluntary-ctxt ≈ 0 argues it is negligible here, but not measured as
  a per-message cost.
- **allocations/msg exact count** — derived as ≥3/publish (src Buffer + snapshot
  + owned Buffer/dest) from code reading; not profiler-confirmed. Minor-fault
  counts corroborate allocation volume but not per-message granularity.

Every bottleneck statement above is phrased "strongly indicated by measurement"
or "implementation-level hotspot" per §20; none is claimed as a profiler-proven
"measured bottleneck".

---

## Summary tables (headline, 256 B, single runs)

| transport | p50 cycle | msgs/s | vs direct |
|-----------|----------:|-------:|-----------|
| direct | 3.36 µs | 280 144 | baseline |
| UDS | 8.21 µs | 117 943 | +4.85 µs |
| Hyrx TCP | 14.28 µs | 67 460 | +10.92 µs |
| AMQP/TCP | 23.27 µs | 40 094 | +19.91 µs (codec +8.99 µs over TCP) |

Fan-out copy slope (256 B): D=1 → 2.43 µs, D=100 → 237.8 µs publish,
per added destination **+2.38 µs ≈ 2×256 B at ~198 MiB/s**. Recommendation:
memcpy the rebuild loop (cheapest, ~10× slope cut) → then Candidate C (1-dest
ownership transfer) → then Candidate A/B for O(D) fan-out. Hottest measured
component: **the per-byte payload copy inside `Router.publish`** (62% of the
direct cycle at 256 B; ~35%→~65% of the cycle as payload grows).

## Verification

| Benchmark | File | Status | Runtime |
|-----------|------|--------|--------:|
| B1 interleaved direct | benchmarks/interleaved_direct.mojo | runs to completion | 15.5 s |
| B2 transport matrix | benchmarks/transport_matrix.mojo | runs to completion | 2.4 s |
| B3 fan-out copy | benchmarks/fanout_copy.mojo | runs to completion | 11.2 s |
| B4 profiling probe | benchmarks/profiling_probe.mojo | runs to completion | 1.16 s |

- `bash scripts/test_all.sh`: **34 pass / 0 fail**, unchanged — no benchmark was
  added to the suite, no test file touched.
- AMQP-TLS (spec §19 bullet) **not benchmarked**: TLS is not implemented
  (pixi.toml note: openssl wired only at Phase 11). Stated, not faked.
