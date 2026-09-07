# Release Checklist

## Source

- [ ] clean build
- [ ] CI green
- [ ] no unexplained warnings
- [ ] dependency audit complete

## Core

- [ ] core unit suite
- [ ] ownership/lifetime suite
- [ ] concurrency suite
- [ ] resource exhaustion suite

## Protocol

- [ ] AMQP conformance
- [ ] negative protocol tests
- [ ] real-client interoperability
- [ ] RabbitMQ differential tests

## Persistence

- [ ] crash tests
- [ ] recovery tests
- [ ] corruption tests
- [ ] disk-full tests

## Security

- [ ] TLS
- [ ] authentication
- [ ] authorization
- [ ] fuzzing
- [ ] hostile input

## Operations

- [ ] systemd install
- [ ] startup
- [ ] readiness
- [ ] graceful shutdown
- [ ] restart
- [ ] health
- [ ] metrics
- [ ] logs
- [ ] management API
- [ ] CLI
- [ ] UI

## Performance

- [ ] direct-core benchmarks
- [ ] local transport benchmarks
- [ ] network benchmarks
- [ ] AMQP benchmarks
- [ ] durable benchmarks
- [ ] RabbitMQ comparison
- [ ] tail latency
- [ ] resource consumption

## Documentation

- [ ] README
- [ ] architecture
- [ ] requirements
- [ ] compatibility matrix
- [ ] configuration
- [ ] deployment
- [ ] migration
- [ ] release notes
