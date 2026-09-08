# 10 — Fields, Streams, Messaging, Morphology, Rendering, Simulation, Graphs

---

## Fields, Streams, Messaging, Morphology and Rendering

These are computational concerns, not merely implementation plumbing.

Agents must preserve the following architectural distinctions.

### Fields

A field is a semantic computational structure.

Do not automatically equate:

```
Field = Tensor
Field = Grid
Field = Buffer
Field = Texture
```

Those may be representations or providers.

### Streams

A semantic stream describes computational flow.

Do not equate:

```
Stream = Transport
```

or:

```
Stream = Broker
```

### Messaging

SCR may use an AMQP-oriented messaging model where appropriate.

AMQP is a messaging/protocol model or provider concern, not the semantic definition of every SCR message.

### Morphology

Morphology is a first-class computational domain.

Preserve both directions:

```
Pattern
   ↕
Morphological Interpretation
   ↕
Morphological Structure
```

Do not reduce morphology to mesh generation or rendering.

### Rendering

Rendering is a computational domain and observation pathway.

Do not treat rendering as merely the final output stage.

A rendering backend is subordinate to the rendering contract.

---

## Simulation and Dynamics

Keep these concepts distinct:

```
Dynamics = meaning of system evolution
Simulation = computational realization of a model
```

Do not collapse simulation semantics into a particular numerical engine.

Likewise:

```
Physics ≠ Dynamics ≠ Simulation
```

They may interact strongly without becoming interchangeable.

---

## Semantic Graph vs Library Architecture Graph

SCR contains multiple graph concepts.

Do not conflate:

### Computational Semantic Graph

Represents computational meaning:

```
Entities
Relationships
Operations
Constraints
Types
Capabilities
State
Events
Dataflow
Control Flow
Spatial Relations
Temporal Relations
Execution Requirements
```

### Library Architecture Graph

Represents project organization:

```
Domains
Definitions
Modules
Interfaces
Implementations
Providers
Tests
Relationships
Status
```

The second is derived from project artifacts.

The first represents semantic computational structure.

They may correspond, but they are not the same graph.
