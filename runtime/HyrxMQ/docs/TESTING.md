# Testing Strategy

Testing is a release requirement, not a final phase.

## Test layers

### Unit

Pure deterministic tests for:

- message representation
- ownership
- buffers
- routing
- queue operations
- protocol codecs
- state machines
- configuration
- authorization
- persistence records

### Component

Test subsystems without the entire product.

### Integration

Test:

- transport + protocol
- protocol + broker
- broker + persistence
- management + broker
- systemd + product

### Compatibility

Run real AMQP clients and differential tests against RabbitMQ.

### Stress

Test:

- high connection count
- high message rate
- deep queues
- many consumers
- many bindings
- large payloads
- small payloads
- connection churn
- publish/consume concurrency

### Soak

Run long enough to detect:

- memory leaks
- queue corruption
- descriptor leaks
- scheduler starvation
- counter overflow
- performance drift

### Fault injection

Inject:

- network resets
- client crashes
- process termination
- disk full
- storage failures
- resource exhaustion
- malformed input

### Fuzzing

Fuzz:

- AMQP frames
- field tables
- protocol state transitions
- configuration
- management API inputs
- persistence records

## Mandatory negative testing

For every protocol feature, test both:

- valid behavior
- invalid behavior

## Regression rule

Every production bug must become a regression test before being considered closed.
