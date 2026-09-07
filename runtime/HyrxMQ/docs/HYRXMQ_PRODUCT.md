# HyrxMQ Product

## Definition

HyrxMQ is the standalone operational packaging of Hyrx.

## Product responsibilities

- listen for network clients
- expose AMQP 0-9-1
- enforce authentication/authorization
- provide persistence
- recover after restart
- expose management interfaces
- expose metrics
- integrate with systemd
- provide operational diagnostics

## Product does not redefine Hyrx

HyrxMQ must remain an assembly/product layer.

The embedded Hyrx API should remain useful without HyrxMQ.

## Product surfaces

1. AMQP data plane
2. management HTTP API
3. CLI
4. browser UI
5. metrics endpoint
6. logs/journal
7. systemd service

## Single-node

HyrxMQ is initially single-node.

Do not introduce clustering abstractions into core APIs merely for hypothetical future distribution.

A future distributed product can be designed deliberately if required.
