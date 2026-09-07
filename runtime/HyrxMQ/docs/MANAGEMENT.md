# Management

HyrxMQ has three deliberate surfaces:

1. AMQP data plane
2. management/control plane
3. public/developer documentation

## HTTP API

The management API should be versioned and API-first.

Initial conceptual endpoints:

```text
/api/v1/status
/api/v1/health
/api/v1/connections
/api/v1/channels
/api/v1/exchanges
/api/v1/queues
/api/v1/bindings
/api/v1/consumers
/api/v1/users
/api/v1/permissions
/api/v1/metrics
/api/v1/topology
/api/v1/diagnostics
```

## CLI

The CLI should be an API consumer where practical.

Examples:

```text
hyrxmq status
hyrxmq health
hyrxmq queues list
hyrxmq queues inspect NAME
hyrxmq queues purge NAME
hyrxmq exchanges list
hyrxmq bindings list
hyrxmq connections list
hyrxmq consumers list
hyrxmq users list
hyrxmq permissions list
hyrxmq metrics
hyrxmq topology
hyrxmq config validate
hyrxmq diagnostics
```

Provide `--json` for automation.

## UI

The browser UI should support:

- dashboard
- queues
- exchanges
- bindings
- consumers
- connections/channels
- topology visualization
- privileged message inspection
- users/permissions
- performance
- persistence/storage
- diagnostics
- configuration validation

Destructive operations require explicit confirmation.

## Isolation

Management operations must not block the message hot path.
