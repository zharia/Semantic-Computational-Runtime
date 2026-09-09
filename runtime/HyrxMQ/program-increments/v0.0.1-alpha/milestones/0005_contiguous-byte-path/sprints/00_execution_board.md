# 0005 — Execution Board (Contiguous Byte-Path Performance)

Status: **planned — not started**. Depends on 0004 (complete). Sole writer: scr-architect.
Full plan: [`../spec.md`](../spec.md).

## Objective
HyrxMQ throughput ≥ RabbitMQ at 4 KB & 16 KB (today ~0.59× / 0.34×), no small-payload
regression, via a contiguous byte path + O(1)-per-frame codec. Byte-exact, flag-gated
(default OFF), measured with paired same-broker A/B.

## Sprint sequence

| Sprint | Scope | Status | Exit gate |
|---|---|---|---|
| [G0](../spec.md#5-phases-each-independently-green--committed--measured) | copy/append/rebuild counters; attribute cost | not started | bytes-touched table shows superlinear elementwise ops today |
| 01 | P1 `RawBytes` contiguous buffer; block-copy in Buffer/Snapshot/encode | not started | byte-exact 0/1/4K/128K + leak/no-stale tests + fewer bytes-touched; flag OFF |
| 02 | P2 cursor/frame-slice codec (no per-frame rebuild) | not started | frame/content/bounds suites green unchanged; parse O(frame) |
| 03 | P3 eliminate redundant copies publish/deliver/get | not started | copies/get = payload+O(1); 39/0 |
| 04 | P4 paired same-broker A/B + full fair matrix | not started | 4K/16K ratio ≥ ~1.0, no small regression, noise-null-control |
| 05 | P5 closeout docs (MEMORY_MODEL/confidence/board/canonical) + default decision | not started | flip ON only if P4 met; else OFF + verdict |

## Invariants (every commit)
- byte-exact delivered bytes (multi-frame + mid-frame split property tests)
- `test_all` 39/0; negative proof per behavioural change
- `buffer_pool_enabled`/`raw_bytes_enabled` default OFF; List[UInt8] path retained
- core independence; boundedness (frame_max, capacity); no new deps; no semantic change
- performance claims only from paired same-broker measurement (0004 lesson)

## Decision to settle before P1
RawBytes vs the 0004 BufferPool: likely RawBytes supersedes the size-class pool →
decide early whether to retire/repurpose `buffer_pool_enabled` (don't keep two byte
models). Record in spec §7 / a `decisions.md` here.

## Risk register
- P1 core memory ownership change — highest risk; flag + exhaustive byte-exact tests.
- Mojo block-copy/pointer API unknown — compile-probe first (0004 discipline).
- Benchmark confounds — same-session, same-broker, alternating order, CIs, null-control.

## Progress log
- 2026-09-09 — spec + board drafted from 0004 canonical data + verified root causes
  (`buffer_snapshot:55`, `frame_codec:59/167/224/238`). Awaiting go to start G0/P1.
