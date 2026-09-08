# Fair-matrix re-measurement (coordinator, quiet host)

**By:** scr-architect · **Date:** 2026-09-08 · **Method:** full 4-cell fair matrix
with the coordinator listener paused (quiet host), `run_all.sh` default payloads/reps.
**Baseline:** `baseline.json` @ git `ed20be0` (pre-0004), same machine.

This record is authoritative for the 0004 fair benchmark and **supersedes** the
provisional numbers in `perf_optimisation_results.md` (R=1.019) and the load-noise
number from an earlier contended run (R=1.134). It also corrects a factual error in
that file's explanation of the gate result (see §4).

## 1. Headline

| quantity | value |
|---|---|
| Fair-pair Rating R (rabbit-tcp vs hyrx-tcp-docker) | **1.041** (95% CI **1.033–1.049**) |
| Baseline R (pre-0004) | 1.051 |
| Delta vs baseline | **−0.010** — parity, well inside the ±0.10 rating gate |

The 0004 copy-cut is **net-neutral on the headline fair-pair rating** (HyrxMQ was
already ~1.05× RabbitMQ) and **did not regress it**.

## 2. Where the copy-cut actually helps — throughput at large payloads

msgs/s, current vs pre-0004 baseline:

| payload | hyrx-uds | hyrx-tcp-native | hyrx-tcp-docker |
|---|---|---|---|
| 4096 B | +8.24% | +8.46% | −0.99% |
| 16384 B | **+17.19%** | **+15.30%** | **+9.02%** |

Small payloads (64–1024 B) are dominated by network/docker round-trip, so the saved
copies don't move R there; the gain shows up where per-message copy cost scales with
size. This is the honest framing of the win.

## 3. R spread across runs = host load, not code

| run | conditions | R |
|---|---|---|
| k3 (quick reps) | loaded | 1.019 |
| coordinator (loaded) | my daemon + k3 + bench contending | 1.134 (inflated) |
| **coordinator (quiet)** | listener paused, full reps | **1.041** |

A single citable R requires a quiet host; 1.041 (tight CI) is that number here.

## 4. The "3 regressions" are noise — proven by a null control

The gate flagged three per-cell regressions, all at **256 B p99 latency**
(hyrx-uds −27%, hyrx-tcp-native −31%, hyrx-tcp-docker −27%).

**Null control:** the **unchanged** `rabbit-tcp` reference cell's own 256 B p99
moved 412 → 1137 µs (**−175%**) in the *same* run. RabbitMQ's code did not change,
so that swing is purely environmental tail-latency jitter — which invalidates the
256 B p99 metric for this run. The three Hyrx flags are the same artifact; a
copy-cut cannot uniformly slow latency across three transports at one payload. An
earlier targeted repeat had already shown 256 B p99 unstable (196→337→220 µs).

**Correction to `perf_optimisation_results.md`:** it attributes the gate exit to
"compare.py comparing a 2-cell R against the 4-cell baseline — invalid cell-set
comparison." That is wrong: R is always the 2-cell fair pair (`index.py`), and
`baseline.json` contains all four cells. The exit=1 came from the noisy 256 B p99
cells above, not a cell-set mismatch.

## 5. Baseline decision

`baseline.json` **not updated.** R moved within tolerance and the run's 256 B p99
is noise-corrupted (rabbit proves it). A baseline refresh is warranted only after a
quiet run whose per-cell latency is stable (rabbit p99 within ~10% of its baseline)
and `compare.py` passes cleanly — deferred to human review per spec §48/§36.

## 6. Verdict

WP-A/B/C/D copy-cut + metadata/wire fidelity: correct, tested (38/0), committed.
Performance: **parity on the headline fair R (1.041), real throughput gain at ≥4 KB
payloads, no regression.** Not faster-than-RabbitMQ beyond the existing ~1.04× —
stated without overclaim.
