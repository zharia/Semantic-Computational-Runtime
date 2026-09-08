# 13 — Repository Conventions and Development Environment

---

## Repository Conventions

Follow existing repository conventions before introducing new ones.

Prefer:

```
Existing scripts
Existing build configuration
Existing test infrastructure
Existing naming conventions
Existing metadata schemas
Existing control-plane artifacts
Existing MLIR conventions
```

Do not introduce a competing convention without architectural justification.

For environment and build setup, use the repository's documented scripts.

Do not make bootstrap tooling:

- launch an interactive shell unexpectedly;
- silently modify shell startup files;
- silently install unrelated dependencies;
- implicitly modify the parent shell;
- mix incompatible LLVM/MLIR installations.

---

## Current Development Environment

The preferred development environment for SCR is:

> **Arch Linux**

Other Linux distributions may be supported, but they are compatibility environments unless explicitly designated otherwise.

The canonical environment should use a coherent LLVM/MLIR toolchain.

Do not mix incompatible LLVM/MLIR installations.

When environment configuration is required, prefer the repository's separation between:

```
Bootstrap
    ↓
Environment Activation
    ↓
Environment Check
    ↓
Build
    ↓
Test
```

A bootstrap script must not unexpectedly turn into an interactive development shell.
