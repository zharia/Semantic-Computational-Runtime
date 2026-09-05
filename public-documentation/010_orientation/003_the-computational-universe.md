# The Computational Universe

SCR is intentionally broader than a simulation framework.

The long-term computational universe includes interacting semantic domains such as:

```text
Information Fields
        ↕
Patterns
        ↕
Morphology
        ↕
Geometry / Topology
        ↕
Dynamics
        ↕
Simulation
        ↕
Agents
        ↕
Neural Computation
        ↕
Perception
        ↕
Control
        ↕
Rendering
        ↕
Observation
        ↕
Streams
        ↕
Messaging
```

This is an architectural direction, not a claim that every domain is implemented.

## Information is not passive data

SCR treats information structures as potentially computational objects.

Examples include:

- fields;
- graphs and hypergraphs;
- tensors;
- streams;
- semantic state;
- topology;
- patterns;
- observations.

These structures can be transformed, queried, composed, observed, and used to drive further computation.

## Rendering can be computation

Rendering is not necessarily the final step.

A renderer can produce an observation that feeds another computation:

```text
Simulation State
    ↓
Morphological / Spatial Interpretation
    ↓
Render State
    ↓
Rendering
    ↓
Observation
    ↓
Perception / Analysis
    ↓
Decision
```

The same semantic substrate can therefore support simulation, visualization, perception, and feedback.

## Streams and messaging

A semantic stream describes computationally meaningful sequences of values, state transitions, or operations.

Messaging transports those semantics.

An AMQP implementation can therefore be a provider for a semantic messaging domain without becoming the definition of that domain.

## The unifying principle

The domains are not isolated modules.

A field may influence morphology. Morphology may produce geometry. Geometry may participate in physics. Physics may update an agent. An agent may emit a message. A message may update another graph. A rendering observation may influence perception.

SCR's purpose is to provide a common semantic environment in which such relationships remain explicit.
