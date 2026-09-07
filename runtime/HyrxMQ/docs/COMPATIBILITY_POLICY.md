# Compatibility Policy

HyrxMQ distinguishes:

1. **AMQP compatibility** — can a client communicate?
2. **AMQP semantics** — does behavior conform?
3. **RabbitMQ interoperability** — has behavior been demonstrated against a
   pinned RabbitMQ reference?

A feature is never labelled "compatible" merely because it appears implemented.

## Status vocabulary

- `SUPPORTED` — implemented and tested.
- `PARTIAL` — implemented with documented semantic differences.
- `INTENTIONALLY_UNSUPPORTED` — deliberately outside the product scope.
- `NOT_IMPLEMENTED` — planned but absent.
- `NOT_TESTED` — implementation may exist but evidence is absent.
- `NOT_PROVEN` — assumption has not been experimentally established.

## Differential testing

Where RabbitMQ behavior is used as an interoperability reference:

- pin the RabbitMQ version;
- record the test fixture;
- execute the same scenario;
- compare observable behavior;
- preserve differences;
- update the compatibility matrix.

Do not infer undocumented behavior.
