# 0012 — persistent codec buffers + direct-into-codec ingest

**Status:** complete — P2/P3 SKIPPED BY GATE: P1 measured recoverable ingest cost 8.6us/msg (1.3% of wall) < implement threshold 10us/msg; increment closes as measurement-only, P2 rejected by rule 17
**Mode:** coordinator; P1 measure (coordinator), P2 delegated (general), P3 delegated (general), verify = coordinator

## Why

Fresh profile (0010 post-mortem): remaining `List::realloc`/`extend` ~28%
user-CPU @128KB, now from per-message allocation churn in the ingest path:
every 64KB socket read allocates a fresh List (plus shrink), then
`feed_bytes` grows the codec buffer (downsize-killed capacity from
`_compact`, regrow pays alloc+copy), and `try_parse_frame` allocates a fresh
payload List per frame. Established microbench facts (0009 probe):
downsize does NOT retain capacity (regrow 3.46µs @128KB); one-shot reserve
beats cascade growth ~10x.

## Stages

- **P1 (measure first) — DONE**: `benchmarks-external probe (same codec file
  reuse as all prior probes): 2 × 65544 B frames through feed+parse+payload_copy
  = 9.9-11.1 us/msg (3 runs); memcpy floor pair 2.2 µs. Recoverable 8.6 µs.
  GATE: below the 10 µs implement threshold -> P2 REJECTED (speculative churn
  for <1.5% wall would violate rule 17/optimization-follows-measurement).
- **P2 — REJECTED BY GATE** (was: codec _used bookkeeping + admit_tail +
  recv_bytes_into; skipped).
- **P3 — DONE (docs only)**: below.
- **P2 (gated on P1)**: codec becomes cursor-bookkept (`_used` field + single
  persistent capacity, resize-UP only, no downsize); new
  `admit_tail/commit_bytes` internal API; `AMQPConn.recv_bytes_into`
  (additive trait method + both transports) reads straight into the codec
  tail; listener serving loop uses it. `feed_bytes` stays for tests/flag-False
  fallback (rollback tier intact).
- **P3**: verification docs + benches.

## Gates

- Wire-identical: suite 44/0 both flag tiers; phase8 byte-path + compaction +
  identity guards; negative proof on the new ingest path (mutate commit
  arithmetic → compaction probe CHECK FAIL).
- Native bench A/B + full pika 5-cell sweep: no cell below baseline; gate
  must pass; baseline refresh.

## Explicitly NOT claimed

- No multi-connection, no semantic changes, no protocol changes.
