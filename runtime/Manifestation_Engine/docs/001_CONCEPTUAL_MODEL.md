# Manifestation Engine — Conceptual Model

## 1. Semantic world and physical world

The semantic world contains meaning: identities, relationships, transformations, state, context, constraints and executable requirements.

The physical world contains concrete machinery: processors, memory, files, devices, transports, brokers, databases, operating-system resources and external services.

The boundary is not a serialization boundary. It is an authority boundary.

```text
SEMANTIC WORLD
  Field
  Hypergraph
  Identity
  State
  Transformation
  Constraint
  Capability
       │
       │ manifestation
       ▼
MANIFESTATION ENGINE
       │
       ├── policy
       ├── capability resolution
       ├── provider selection
       ├── resource allocation
       ├── execution
       └── observation
       │
       ▼
PHYSICAL WORLD
  Provider
  Memory
  Device
  Storage
  Network
  External system
```

## 2. Hypergraph closure

The executable hypergraph is closed over semantic identity. It may refer to a semantic capability or semantic data entity, but it does not encode how that capability or entity is physically realized.

A physical address is therefore not an alternative spelling of a semantic identity. It is a manifestation locator.

## 3. The Engine as membrane

The Engine has three simultaneous roles:

1. interpreter of semantic execution requirements;
2. authority boundary for physical access;
3. realization mechanism connecting semantic intent to physical providers.

It is therefore neither purely a compiler nor purely a runtime.

## 4. Four distinct concepts

### Manifestation
A semantic concept describing or requiring a physical realization.

### Manifestation Engine
The machinery that resolves and realizes manifestations.

### Provider
An implementation mechanism satisfying a semantic capability contract.

### Physical manifestation
The concrete realization currently used by a provider: memory, file, device state, network connection, process, kernel, database record, etc.

Confusing these four concepts is a major architectural error.

## 5. Semantic versus implementation relationships

```text
physics.simulate --REQUIRES--> physics.compute
physics.compute --SATISFIED_BY--> physics provider
physics provider --REALIZES--> physical execution
```

The first relationship is semantic. The latter relationships cross into implementation and manifestation domains.

## 6. Identity levels

SCR should distinguish:

- semantic identity;
- graph identity;
- execution identity;
- manifestation identity;
- provider identity;
- physical resource identity.

These identifiers MAY be related but MUST NOT be conflated.

## 7. What the graph can know

The graph may know:

- that a capability is required;
- what semantic inputs and outputs exist;
- which constraints apply;
- what context is required;
- what relationships exist;
- what semantic state transition is intended;
- what observations are semantically relevant.

The graph must not need to know:

- which CPU executes it;
- which file stores data;
- which broker carries a message;
- which vendor library supplies a kernel;
- which host owns a resource.

## 8. Semantic closure does not mean physical isolation

The Engine may legitimately expose physical facts to compilation and scheduling: available GPU memory, CPU topology, bandwidth, latency, precision, locality or provider availability.

These facts influence realization. They do not become semantic dependencies unless explicitly admitted into the semantic contract.

## 9. Core relationship

```text
meaning
  ↓
requirement
  ↓
capability
  ↓
realization policy
  ↓
provider
  ↓
physical manifestation
  ↓
execution
  ↓
observation
  ↓
semantic result
```
