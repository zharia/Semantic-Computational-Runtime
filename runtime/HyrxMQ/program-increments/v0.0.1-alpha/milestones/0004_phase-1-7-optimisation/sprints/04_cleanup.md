# Sprint 04 — Cleanup (WP-D)

Status: **complete** — dead `try/except` around non-raising `close()` removed
(listener.mojo); the "fold double-parse" item withdrawn as a mis-specification
(decision D3).

## Planned slice

1. Remove only the two local non-raising `close()` try/except blocks in
   `listener.mojo`; retain the outer fail-closed connection boundary.
2. Restructure frame parsing only after the intended read-loop contract is
   specified.
3. Run the full suite; frame-codec and hostile-listener tests protect the
   parser and failure-containment behavior.

## Feedback / blocker evidence

- Completed: removed the two specified local try/except wrappers around
  non-raising `close()` calls in `src/hyrxmq/listener.mojo`. The outer
  fail-closed error boundary remains intact.
- Validation: `tests/integration/listener_hostile.mojo` compiled through the
  changed listener path, then could not execute because this environment denies
  socket creation (`NetworkError(errno 1): Operation not permitted`).
- The two `try_parse_frame()` calls are not duplicate parsing of the same
  buffer: the first consumes an already-buffered frame; only if absent does the
  listener receive bytes, and the second parses that new input. Removing either
  changes buffered-frame or newly-read-frame behavior. The requested cleanup
  needs a specified replacement control flow and proof target.
