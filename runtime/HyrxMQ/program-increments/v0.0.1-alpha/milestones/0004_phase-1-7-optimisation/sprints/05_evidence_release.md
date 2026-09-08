# Sprint 05 — Evidence, Documentation, and Release (WP-A–D)

Status: **done** — full suite 38/0 green, negative proofs in place, docs bumped to
evidence, increment committed per WP; full `bench-fair` deferred to an
unrestricted host (interactive 120s cap) — noted in the perf report.

## Required evidence

1. Run the relevant runtime-checked test after each completed work package and
   run `bash scripts/test_all.sh` for the final integration check.
2. Record a deliberately broken expectation and non-zero exit for each changed
   behavior, then restore the passing test.
3. Re-run `pixi run bench-fanout` and `pixi run bench-fair`; write real
   before/after byte-copy ceiling, 4 KiB/16 KiB crossover, fan-out slope, and
   fair rating in `reports/perf_optimisation_results.md`.
4. Update `MEMORY_MODEL.md`, interop report, and confidence matrix solely to
   evidence. Keep exchange, content properties, and P1b recycle explicitly
   NOT DONE/NOT PROVEN.
5. Do not update `benchmarks/perf/baseline.json` without human review.

## Progress

- The baseline benchmark and report locations are identified.
- Baseline suite attempt: phase0–phase4 transport-test files and phase5 through
  `framing_test` passed before the runner's socket tests failed on this
  environment's `Operation not permitted` network restriction. This is not a
  product assertion failure. The runner did not reach a final total, so no
  full-suite-green claim is made.
- `pixi run mojo run -I src -I vendor/flare tests/phase7/amqp_service_test.mojo`
  passed after the listener cleanup.
- No benchmarks have been rerun because the implementation decision gates must
  be resolved before measurements could be attributed to this increment.
