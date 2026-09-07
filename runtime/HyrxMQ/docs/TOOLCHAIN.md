# Toolchain Baseline

## Platform

Hyrx/HyrxMQ targets GNU/Linux and systemd.

## Mojo

Mojo is the primary implementation language.

The exact supported Mojo version must be pinned/recorded by the development
agent after inspecting the actual environment. This document intentionally does
not invent a version.

## Required evidence

Capture:

```text
mojo --version
uname -a
uname -m
ldd --version
systemd --version
```

Also record:

- CPU model and core count;
- RAM;
- kernel version;
- filesystem;
- compiler/toolchain installation source;
- relevant environment variables;
- repository revision.

## Toolchain principles

1. Prefer the official/current Mojo facilities available in the actual
   environment.
2. Do not assume an API exists because an older document or another language
   provides it.
3. Verify APIs by compiling minimal experiments.
4. Keep dependencies minimal.
5. Pin reproducibility where practical.
6. Record toolchain changes as decision records.

## Mojo-specific design relevance

Mojo's ownership and lifetime system is directly relevant to Hyrx because
message buffers, queue nodes, transport buffers and persistence buffers need
explicit ownership semantics.

The development agent must therefore produce small compile-tested experiments
for:

- value ownership;
- borrowing/reference access;
- transfer;
- lifecycle/destruction;
- non-owning buffer views;
- synchronization primitives actually selected.

Do not extrapolate from documentation without compiling the intended pattern.
