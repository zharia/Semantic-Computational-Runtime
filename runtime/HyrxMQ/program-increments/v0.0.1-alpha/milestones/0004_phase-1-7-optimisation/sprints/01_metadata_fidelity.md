# Sprint 01 — Envelope Metadata Fidelity (WP-A)

Status: **done** — message_id/headers preserved on fan-out; `Message` accessors +
`read_message_id`/`read_headers` read-back; pinned by `test_metadata_fidelity_*`.

## Contract

A publication with a non-zero `MessageID` and headers must deliver the same
metadata to every accepted fan-out destination. Each queued envelope owns an
independent header dictionary. Payload ownership remains independent per
destination except for the separately specified single-destination move path.

## Planned slice

1. Add `Message.message_id()` and `Message.headers()` delegating to `Envelope`.
2. Add a read-only queued-envelope read-back surface through Queue and Router,
   sufficient to test metadata after a delivery claim.
3. Replace `MessageID(0)` and empty headers in `Router.publish` with metadata
   copied from the published message for every clone.
4. Extend `tests/phase2/routing_matrix_test.mojo` with a multi-queue fan-out
   test for ID and headers using `check`.

## Acceptance and negative proof

The test must fail against the current `MessageID(0)`/empty-header router,
then pass after the change. It must also prove every destination receives the
published ID and header values.

## Feedback / progress

- `Envelope` already exposes `message_id()` and `headers()`; `Message` lacks
  both accessors.
- The current public core has no queued metadata read-back API. A Queue and
  Router read-back accessor is required to make the defect testable rather
  than merely observed.
- This sprint is otherwise isolated and does not change routing authority.
