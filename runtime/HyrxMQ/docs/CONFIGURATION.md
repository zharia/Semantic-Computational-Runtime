# Configuration

## Principles

- explicit
- typed
- validated before startup
- safe defaults
- versioned
- deterministic

## Configuration domains

- listeners
- transports
- AMQP
- TLS
- authentication
- authorization
- vhosts
- resource limits
- persistence
- performance
- observability
- management
- systemd integration where applicable

## Validation

Provide:

```text
hyrxmq config validate
```

Invalid configuration must fail before the service enters ready state.

## Hot reload

Only support hot reload for settings whose semantics can be changed safely.

Document restart-required settings explicitly.
