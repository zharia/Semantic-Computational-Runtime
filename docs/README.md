# SCR Technical Documentation

Technical specifications for the Semantic Computational Runtime (SCR).

## Structure

- `semantics/` — normative definitions of what SCR values and operations mean.
- `runtime/` — computational mechanisms by which those semantics are manifested.

The semantic layer is authoritative over runtime representation. Runtime policy may optimise representation and execution, but must preserve semantic invariants.
