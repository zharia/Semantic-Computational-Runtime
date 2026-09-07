# Management API

## Requirements

- versioned
- documented
- authenticated
- authorization-aware
- machine-readable schema
- stable error model
- idempotency where practical
- safe destructive-operation semantics

## API contract

Generate/maintain an OpenAPI specification.

Every endpoint needs:

- request schema
- response schema
- status codes
- error codes
- authentication requirements
- authorization requirements
- examples
- concurrency behavior

## Health

Separate:

- liveness
- readiness
- dependency health
- degraded state

Do not report healthy merely because the process is alive.

## Administrative actions

Actions such as purge, delete, disconnect, or permission modification must be auditable through logs/events.
