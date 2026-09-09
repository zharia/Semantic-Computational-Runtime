# 0011 — filesystem-free bearer + bench-network bypass

**Status:** complete
**Mode:** coordinator; T1 delegated (general), T2 delegated (cavecrew-builder), verify = coordinator

## Why

- User requirement: filesystem-independent local IPC. UDS path sockets require
  a filesystem name + unlink lifecycle. Linux abstract namespace sockets live
  in kernel memory only (vanish with process) — full AMQP compatibility, same
  kernel machinery, zero fs.
- Docker bench cell currently rides the docker **userspace port-publish
  proxy** (extra IPC hop in our own benchmark path; hypotheses for lower
  docker ratios). host-net bench cell isolates that hop.

## Tasks

- **T1** (general) — **DONE.** Receipt: `flare/uds/_libc.mojo`
  `fill_sockaddr_un` gains the `@name` abstract encoding
  (additive; `sun_path[0]=0`, `addrlen = 2+1+len(name)`, pathname branch
  byte-identical); `src/hyrx/transport/uds.mojo` doc note; NEW
  `tests/integration/uds_abstract.mojo` (broker_uds_e2e mirror over
  `@hyrxmq_bench_abstract`) — E2E PASS on Linux; suite 44/0.
- **T2** (builder) — **DONE.** Receipt: `benchmarks/perf/docker_hyrx.py`
  `--network host` mode + `free_host_port` (floor 5702) + container
  `hyrx-bench-listen-hostnet`; `benchmarks/perf/harness.py` NEW cell
  `hyrx-tcp-hostnet`; rabbit cells untouched.
- **T3** (coordinator) — **DONE** (verification numbers): suite **44/0**
  (43 prior + new E2E); smoke hostnet OK (64 B 7,623 / 4 KB 7,110 msg/s,
  spread 3.5%); FULL 5-cell sweep recorded; gate
  `R 1.430 -> 1.442 (delta +0.012, threshold ±0.10) PASS [95% CI
  1.4314-1.4454]`; `baseline.json` refreshed via `--update-baseline`.
  Evidence: `reports/performance_canonical.md`.

## Gates

- suite 43/0 (path-UDS unchanged tier); T1 integration test green.
- Full harness sweep: no existing cell below its baseline; new cell recorded
  as evidence (+ baseline refresh).
- No wire change: AMQP protocol bytes identical for both UDS addressings.

## Explicitly NOT claimed

- No cross-container shm sharing scope (docker `--ipc` model) — separate
  analysis if pursued.
- Direct-into-codec ingest + persistent per-connection buffers = 0012, gated
  on the 0010-followup profile (feed/parse allocation churn), not skipped —
  sequenced after this increment lands so each gate stays attributable.
