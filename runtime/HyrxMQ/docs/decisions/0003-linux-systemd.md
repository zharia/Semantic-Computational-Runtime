# ADR-0003 — GNU/Linux and systemd

## Status

Accepted seed decision.

## Decision

Hyrx/HyrxMQ are designed exclusively for GNU/Linux/systemd environments.

## Rationale

The performance and operational goals justify deliberate use of Linux facilities
where evidence supports them.

Potential facilities include:

- epoll;
- io_uring;
- Unix-domain sockets;
- mmap;
- eventfd/futex;
- TCP socket options;
- NUMA controls;
- filesystem durability primitives.

These are candidates, not automatic requirements. Each must earn inclusion
through correctness and measurement.
