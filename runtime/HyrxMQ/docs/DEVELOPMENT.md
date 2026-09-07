# Development Workflow

## Before coding

1. Read architecture invariants.
2. Read the current phase specification.
3. Inspect actual toolchain versions.
4. Inspect current repository state.
5. Identify unknowns.
6. Design the smallest experiment that can resolve each important unknown.

## During coding

- prefer small logical commits;
- keep hot-path assumptions explicit;
- avoid speculative abstractions;
- write tests with implementation;
- record measurements rather than anecdotes.

## After coding

Run:

```text
tests
format
integration checks
benchmark where relevant
documentation update
self-assessment
```

## Commit style

Examples:

```text
core: add message ownership model
routing: add direct exchange matcher
transport: add unix domain transport
amqp: implement connection negotiation
hyrxmq: add systemd service
perf: add direct-path benchmark
test: add RabbitMQ differential suite
docs: document transport semantics
```
