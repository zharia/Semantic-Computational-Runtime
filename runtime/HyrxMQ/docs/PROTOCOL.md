# AMQP 0-9-1 Protocol

HyrxMQ targets AMQP 0-9-1 as its external interoperability protocol.

AMQP 0-9-1 is a binary messaging protocol and semantic framework. AMQP 1.0 is a different protocol and is not an incremental version of 0-9-1. HyrxMQ should not imply AMQP 1.0 compatibility unless it is separately implemented.

## Protocol implementation

Implement:

- protocol header negotiation
- frame parsing/serialization
- method identifiers
- channel lifecycle
- connection lifecycle
- content headers
- content bodies
- field tables
- field arrays
- heartbeats
- negotiated limits
- protocol errors
- connection closure
- channel closure
- method state machines

## Canonical boundary

```text
wire bytes
   |
frame codec
   |
AMQP operation
   |
Hyrx semantic operation
```

The reverse path performs the inverse translation.

## Method/state testing

Each implemented method must have:

- valid request tests
- invalid-state tests
- malformed-input tests
- error-response tests
- ordering tests
- concurrency/lifecycle tests where applicable

## RabbitMQ extensions

RabbitMQ extensions such as publisher confirms, `basic.nack`, blocked connection notifications, consumer cancellation notifications, priorities, and Direct Reply-To require explicit compatibility decisions and tests.

Do not silently claim compatibility for extensions that are not implemented.
