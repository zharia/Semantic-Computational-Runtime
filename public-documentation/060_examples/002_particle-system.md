# Example: A Semantic Particle System

This example illustrates the architectural path without implying that every stage is already implemented in SCR.

## Semantic model

A particle can have semantic state:

```text
position
velocity
```

A simple deterministic transition is:

```text
step(state, dt) → state'
```

For constant velocity:

```text
position' = position + velocity × dt
```

The equation expresses semantic meaning. It does not prescribe a memory layout or hardware.

## Representation

The semantic state could be represented through a domain IR containing:

- particle identity;
- position;
- velocity;
- timestep;
- transition operation.

That representation can then be mapped into MLIR.

## Lowering

A possible path is:

```text
Semantic Definition
        ↓
Semantic Model
        ↓
Domain IR
        ↓
MLIR
        ↓
CPU Execution
        ↓
Simulation State
        ↓
Render State
        ↓
Rendering
```

A later implementation could instead target a GPU provider.

## Important distinction

The semantic particle is not:

- a Rust struct;
- an array in memory;
- an MLIR SSA value;
- a GPU buffer;
- a renderer object.

Those are representations or implementations.

## Why this is a useful example

The example is intentionally small, but it demonstrates the central thesis:

> The semantic description can remain stable while the realization path changes.
