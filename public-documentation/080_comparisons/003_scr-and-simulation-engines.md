# SCR and Simulation Engines

Simulation engines typically provide a concrete environment for executing simulations.

They may include:

- state management;
- simulation loops;
- numerical integration;
- entities;
- events;
- scheduling;
- collision handling;
- visualization.

SCR approaches the problem at a different architectural level.

## Simulation engine question

A simulation engine tends to ask:

> How do I run this simulation?

## SCR question

SCR asks:

> What does this simulation mean, and how can that meaning be realized on an available computational substrate?

## Separation

A simulation in SCR can be represented as:

```text
Semantic State
      ↓
Semantic Dynamics
      ↓
Domain IR
      ↓
MLIR
      ↓
Provider
      ↓
Execution
```

The provider could eventually use an existing simulation engine.

That engine becomes an implementation mechanism rather than the semantic definition of the simulation.

## Consequences

The same semantic simulation could potentially be:

- executed headlessly;
- accelerated on a GPU;
- distributed;
- coupled to a renderer;
- analysed;
- replayed;
- transformed;
- compared with another implementation.

## Relationship

SCR does not attempt to eliminate simulation engines.

It attempts to make simulation semantics portable across them.
