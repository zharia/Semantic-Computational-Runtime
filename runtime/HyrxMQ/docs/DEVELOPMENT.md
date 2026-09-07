# Development Guide

## Development order

Work from:

```text
core semantics
→ ownership
→ routing
→ direct delivery
→ transports
→ protocol
→ product
```

## Code review requirements

Reviewers must examine:

- ownership correctness
- lifetime correctness
- concurrency
- error paths
- resource limits
- semantic compatibility
- benchmark evidence
- documentation impact

## Generated protocol code

Where protocol metadata can be generated from authoritative machine-readable definitions, prefer generation over manually duplicated constants.

Generated artifacts must be reproducible and reviewed at the source-definition level.

## Unsafe/native interfaces

Unsafe code is permitted where required for systems-level functionality, but each use must document:

- why it is necessary
- lifetime assumptions
- aliasing assumptions
- failure behavior
- benchmark justification

## Dependencies

Prefer the smallest dependency surface compatible with the product.

A dependency must have:

- clear license
- maintenance rationale
- security rationale
- performance impact assessment
- build/release implications

## Documentation rule

A behavior change is incomplete until affected documentation and tests are updated.
