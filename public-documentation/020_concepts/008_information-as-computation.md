# Information as Computation

Traditional programming often separates program from data:

```text
Program + Data → Result
```

SCR explores a broader model:

```text
Information
    ↕
Structure
    ↕
Transformation
    ↕
State
    ↕
Dynamics
    ↕
Observation
```

Information structures can themselves carry computational semantics.

## Examples

### Fields

A field can represent spatially distributed information such as temperature, pressure, probability, light, influence, or semantic intensity.

### Graphs

Graphs represent entities, relationships, connectivity, dependencies, flows, and topology.

### Streams

Streams represent ordered sequences of values, events, operations, or state transitions.

### Patterns

Patterns describe recurring or structurally meaningful configurations.

### Morphology

Morphology describes the form and organization resulting from patterns, fields, constraints, topology, geometry, or dynamics.

## Cross-domain computation

A computation can therefore move through different representations:

```text
Field
  ↓
Pattern
  ↓
Morphology
  ↓
Geometry
  ↓
Rendering
```

or:

```text
Geometry
  ↓
Field
  ↓
Inference
  ↓
Agent Decision
  ↓
Dynamics
```

The value of the semantic layer is precisely that these transitions can remain explicit.

## Consequence

SCR does not require every domain to share the same physical data structure.

Instead, domains share semantic contracts and relationships while remaining free to use appropriate representations and providers.
