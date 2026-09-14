# systemd Integration

HyrxMQ is a GNU/Linux/systemd-native product.

## Service requirements

The service should support:

- deterministic startup
- readiness signaling
- graceful shutdown
- restart policy
- optional watchdog
- dedicated user/group
- journal logging
- runtime directory
- data directory
- configuration validation before start
- safe reload where supported

## Hardening

Evaluate and document:

- NoNewPrivileges
- ProtectSystem
- ProtectHome
- PrivateTmp
- RestrictAddressFamilies
- capability restrictions
- resource controls
- filesystem access
- device access

Do not enable a hardening control until it has been tested against all supported operations.

## Service acceptance

A release candidate must:

1. install the unit
2. start successfully
3. become ready
4. pass health checks
5. survive controlled restart
6. recover expected durable state
7. stop cleanly
8. emit useful journal output

## Graceful shutdown (verified)

`build/hyrxmq-listen` installs real SIGTERM/SIGINT handlers. Mojo 1.0 has no
signal module and no module-level mutable globals, so the async-signal-safe
flag lives in a small C shim (`src/hyrxmq/shutdown_shim.c`, a
`volatile sig_atomic_t` written by a `signal(2)` handler). The serving loop
polls `hyrxmq_shutdown_requested()` on its ~100 ms poll cadence, calls
`begin_shutdown()`, then `flush_storage()` + `stop()` before exiting 0.

The shim is compiled and linked by the pixi `hyrxmq-listen` task:

```
clang -O2 -c src/hyrxmq/shutdown_shim.c -o build/shutdown_shim.o
mojo build -I src -I vendor/flare -Xlinker build/shutdown_shim.o \
    src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen
```

`mojo run` (JIT) cannot link the object, so unit tests cover only the pure-Mojo
`ShutdownState` / listener-flag seam
(`tests/phase10/graceful_shutdown_test.mojo`). The end-to-end signal path is
verified on the built executable: `kill -TERM <pid>` (and `kill -INT`) while
idle returns exit code 0 in <10 ms and prints `shut down cleanly`.

Limitation (HONEST): in the legacy serial loop, a connection being served
blocks the OS-signal poll until it finishes; the event-driven loop
(`event_driven_serving()` True) rotates doses so the poll stays responsive
during active traffic.
