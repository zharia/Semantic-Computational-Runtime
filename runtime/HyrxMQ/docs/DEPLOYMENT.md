# Deployment

## Supported environment

GNU/Linux + systemd.

## Deployment modes

### Embedded

Application links/embeds Hyrx directly.

### Local service

HyrxMQ runs as a local service accessible through network or local IPC transports.

### Network broker

HyrxMQ runs as an independently managed broker accessed over TCP/TLS and AMQP 0-9-1.

## Containers

Containers may be supported as packaging targets, but container orchestration is not an architectural dependency.

## Hardware qualification

Performance reports must record:

- CPU model
- core/thread count
- RAM
- NUMA topology
- storage device
- filesystem
- kernel
- systemd
- Mojo version
- compiler/build flags
- governor/power profile
- network interface
- test topology
