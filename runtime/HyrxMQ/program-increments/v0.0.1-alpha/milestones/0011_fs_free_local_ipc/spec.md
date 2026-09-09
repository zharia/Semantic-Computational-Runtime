# HyrxMQ — 0011 · Filesystem-Free Local IPC (+ bench hostnet cell)

**Status:** Complete
**Milestone:** 0011_fs_free_local_ipc
**Depends on:** 0010_response_copy_elimination (emit/compaction landed, R 1.430 baseline; 0010 evidence pointed 0011 at byte-path work sequenced after this increment so each gate stays attributable)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Problem (user-driven)

The user requirement is **filesystem-independent local IPC**. HyrxMQ's UDS
transport binds Unix domain socket pathnames: a filesystem name that someone
must create, and a lifecycle someone must manage (`unlink(2)` before bind,
stale socket files after crashes). Linux abstract-namespace sockets live in
kernel memory only — bound while a listening socket holds the name, vanished
with the process, no filesystem artifact at any point — on the same
AF_UNIX kernel machinery, with full AMQP compatibility.

Second problem, measurement-only: the `hyrx-tcp-docker` bench cell rides the
docker **userspace port-publish proxy** (docker-proxy) — an extra IPC hop
inside our own benchmark path. It is the current hypothesis for the docker
cell's ratio deficit vs native (~10–30% depending size across 0008–0010
sweeps). A host-net bench cell isolates that hop.

## 1. Change (additive; existing paths byte-identical)

| # | item | operation |
|---|---|---|
| 1 | `vendor/flare flare/uds/_libc.mojo::fill_sockaddr_un` | Gains the Linux abstract-namespace `@name` encoding: a `path` starting with ASCII `@` (0x40) encodes family bytes as usual, then `sun_path[0] = 0` (kernel "abstract, not pathname" marker) followed by the name octets — **no trailing NUL**; `addrlen = 2 + 1 + len(name)` (pathname branch unchanged: `2 + len(path) + 1`). Embedded-NUL check covers abstract names; a name that outgrows `sun_path` − 1 raises; `@name` raises on macOS/BSD (no abstract sockets there). The **pathname branch is byte-identical** to the pre-0011 encoding |
| 2 | `src/hyrx/transport/uds.mojo` | Doc note only: the `@name` convention, the no-schema-created/unlink-no-op abstract lifecycle, Linux-onlyness, and "any other path behaves exactly as before" |
| 3 | `tests/integration/uds_abstract.mojo` | NEW full E2E over `@hyrxmq_bench_abstract` live sockets, mirroring `broker_uds_e2e` verbatim: listener + client connect, complete handshake, exchange/queue declare + bind, publish (method+header+2 body frames), consume → deliver → ack, byte-compared body, EOF teardown |
| 4 | `benchmarks/perf/docker_hyrx.py` | `--network host` mode for the throwaway bench container: no port publishing, negotiated free loopback port (floor `5702`), distinct container name `hyrx-bench-listen-hostnet` so baseline A/B stays traceable; bridge path unchanged |
| 5 | `benchmarks/perf/harness.py` | NEW cell `hyrx-tcp-hostnet`: same throwaway container + same broker binary, reached over loopback **without the proxy hop**. Rabbit cells untouched |
| 6 | production semantics | **NONE otherwise.** No flag, no wire change, no removal of the pathname UDS lifecycle |

## 2. Justification of the vendored-dependency edit

The only change inside `vendor/flare` is `fill_sockaddr_un` — flare's single,
documented, package-internal seam for building a `sockaddr_un`. The edit is:

- **Single documented seam:** one private function, one docstring amendment;
  no flare public API gained or changed surface.
- **Additive-only:** a new `@`-prefix branch plus its guard rows; the
  pre-existing pathname encoding, its `SUN_PATH_MAX` budget and its error
  strings are untouched, and the pathname branch returns the **same bytes and
  the same `addrlen`** as before 0011 — a pathname socket is byte-identical,
  which is why no addressing negative-proof applies (see report §negative
  note).
- **Behavior-bounded:** non-Linux targets raise before any buffer write; the
  abstract marker is exactly the kernel rule (`sun_path[0] == 0`,
  length from `addrlen`).

Every path-UDS caller in HyrxMQ (tests and bench `hyrx-uds` cell) executes
exactly the pre-0011 branch.

## 3. Protocol compatibility

**AMQP wire bytes are identical for both addressings.** The addressing lives
entirely below the socket layer: `sun_path`/`addrlen` encoding for
`bind(2)`/`connect(2)` has zero representation in the AMQP protocol. The
abstract E2E drives the same handshake/publish/deliver/ack frames on the same
frame layout, and the body is byte-compared across the abstract socket.

## 4. Measured, not speculative

Verification comes from this host's runs: the new E2E executed over live
abstract-namespace sockets (kernel evidence, not argument); suite 44/0
(43 prior + the new E2E); a smoke pass on the hostnet cell (64 B 7,623 msg/s,
4 KB 7,110 msg/s, spread 3.5%, status OK) then a FULL 5-cell sweep (5-rep
medians, env identical to 0008–0010), gate `R 1.430 -> 1.442 PASS`, baseline
refreshed via `compare.py --update-baseline`. The hostnet cell is recorded as
evidence and deliberately **not gated** this increment. Honest limitations
are recorded in the report (hostnet isolates the proxy hop, not a broker
improvement; abstract-UDS throughput not harness-measurable yet).

## 5. Acceptance criteria

1. `fill_sockaddr_un` abstract encoding: `@name` → `addrlen = 2+1+len(name)`,
   `sun_path[0] = 0`, no trailing NUL; pathname paths byte-identical
   (pathname branch unmodified — verified by the full path-UDS tier staying
   green); portability rows implemented (macOS/BSD reject before write)
2. `tests/integration/uds_abstract.mojo` green over live `@hyrxmq_bench_abstract`
   sockets on Linux: full handshake + consume→deliver→ack, body byte-compared
3. Suite **44/0** (43 prior + new E2E), auto-discovered by test_all; path-UDS
   tier unchanged
4. Full harness sweep incl. the new `hyrx-tcp-hostnet` cell: no existing cell
   below its baseline at any gate size; hostnet recorded as evidence
5. Gate PASS with baseline refreshed upward (R 1.430 → 1.442)
6. Rabbit bench cells untouched; hostnet failures (e.g. bind collisions)
   recorded as clean fail/BLOCKED statuses — no invented numbers

## 6. Definition of done

1. Changes landed; `spec.md` + `plan.md` receipts + this milestone's
   `reports/performance_canonical.md` complete
2. Suite 44/0 including `tests/integration/uds_abstract.mojo`
3. `benchmarks/perf/baseline.json` refreshed to the 0011-state sweep
   (5 cells; R 1.442)
4. `docs/MEMORY_MODEL.md` carries the 0011 note (after the 0010 note)
5. Gating decision recorded: `hyrx-tcp-hostnet` is deliberately absent from
   `index.py CELL_ORDER` this increment; it becomes gated only after a
   considered index/compare edit + baseline refresh
6. 0012 handoff: the 0010 follow-up (direct-into-codec ingest + persistent
   per-connection buffers, gated on the 0010 profile) remains sequenced next —
   not skipped

## 7. Verdict

**Local IPC is now filesystem-free and the docker-proxy hop is isolated.**
`@name` UDS binds in the Linux abstract namespace through the vendored
dependency's single documented seam — additive-only, pathname behavior
byte-identical, full AMQP compatibility — proven end-to-end over live
abstract sockets on the Linux kernel (handshake + consume→deliver→ack,
byte-compared; suite 44/0). The bench matrix gains `hyrx-tcp-hostnet` (same
container, no proxy hop): hostnet ≥ native at every gate size, and the
docker-vs-hostnet delta isolates the userspace proxy hop as the docker cell's
historical ~10–30% ratio deficit — a measurement-path finding, not a broker
improvement. Gate stays PASS with the baseline refreshed upward
(R 1.430 → 1.442); no wire change, no pathname-UDS behavior change.
