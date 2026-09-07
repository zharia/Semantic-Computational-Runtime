# Why Mojo and AMQP 0-9-1?

## Mojo

Mojo is being used because the project requires systems-level control over:

- memory
- ownership
- lifetimes
- data layout
- concurrency
- native compilation
- SIMD
- Linux integration

The implementation must use Mojo idiomatically rather than treating it as a thin syntax layer over conventional designs.

## AMQP 0-9-1

AMQP 0-9-1 provides an established interoperability surface with a large client ecosystem and strong broker semantics.

Hyrx does not inherit RabbitMQ's internal architecture. It implements the protocol boundary over its own engine.
