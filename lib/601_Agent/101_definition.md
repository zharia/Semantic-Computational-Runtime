---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-AGENTS
name: Agents

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
---

# Agents

## Definition

An Agent is a **semantic entity capable of participating in an environment through state, observation, perception, selection, action, adaptation, or other forms of directed interaction**.

Agents provide the semantic domain for entities whose state participates in interactions with other entities, environments, processes, or information structures.

An agent is not defined by:

* artificial intelligence;
* neural networks;
* machine learning;
* consciousness;
* autonomy;
* biological embodiment;
* robotics;
* software;
* a programming language;
* a particular decision algorithm.

An agent may be extremely simple.

A thermostat, cellular organism, simulated animal, robot, software process, economic actor, adaptive controller, or artificial organism may all be represented as agents when their semantics satisfy the relevant agency contract.

The fundamental agent relationship is:

```text
Environment
     ↓
Observation
     ↓
Agent State
     ↓
Selection / Decision
     ↓
Action
     ↓
Environment
     ↓
State Change
     ↺
```

Agency is therefore fundamentally a **relationship between an entity and the state transitions in which it participates**.

---

# Semantic Model

An agent can be represented conceptually as:

```text
A = (I, S, O, P, D, G, C, X, E, T, R)
```

where:

* `I` = identity
* `S` = internal state
* `O` = observations
* `P` = perception/interpretation
* `D` = decision or selection mechanism
* `G` = goals or directed objectives
* `C` = capabilities and constraints
* `X` = actions
* `E` = environment
* `T` = temporal semantics
* `R` = relationships and provenance

Not every agent requires every component.

In particular:

* an agent need not have explicit goals;
* an agent need not possess memory;
* an agent need not learn;
* an agent need not perceive through a sensory subsystem;
* an agent need not make conscious decisions.

The semantic model MUST allow minimal as well as highly sophisticated agents.

---

# Scope

SCR Agents includes semantics for:

* agents
* agent identity
* agent state
* agent lifecycle
* embodiment
* environments
* observations
* perception
* action
* action spaces
* policies
* decision
* selection
* goals
* objectives
* preferences
* constraints
* capabilities
* memory
* beliefs
* internal models
* self-models
* adaptation
* learning
* communication
* interaction
* cooperation
* competition
* coordination
* navigation
* control
* agency
* autonomy
* populations
* collectives
* societies
* agent networks
* multi-agent systems
* agent hierarchies
* reproduction
* division
* fusion
* death
* lifecycle transitions
* embodiment
* morphology
* spatial agency
* temporal agency
* agent streams
* agent deltas
* agent provenance
* uncertainty
* simulation coupling.

---

# Agency

Agency describes an entity's capacity to participate in directed state transitions.

Agency does not require consciousness or free will.

Conceptually:

```text
State
  +
Available Actions
  +
Constraints
  +
Selection
  ↓
Directed State Transition
```

The degree and nature of agency may vary continuously or categorically.

An agent MAY have:

* deterministic agency;
* stochastic agency;
* reactive agency;
* goal-directed agency;
* adaptive agency;
* learned agency;
* collective agency.

---

# Agent Identity

Every persistent agent MUST have a semantic identity.

Identity MUST remain distinct from:

* memory address;
* process identifier;
* database identifier;
* network address;
* object pointer;
* rendering identifier.

An agent may change representation, location, embodiment, or implementation without necessarily changing semantic identity.

---

# Agent State

Agent state represents the semantically relevant state of an agent.

It MAY include:

* physical state;
* internal state;
* memory;
* beliefs;
* goals;
* preferences;
* capabilities;
* relationships;
* learned state;
* emotional or affective state;
* physiological state;
* resource state;
* morphological state;
* spatial state;
* temporal state.

Implementation state MUST NOT automatically become semantic agent state.

---

# Internal State

Internal state describes information maintained by the agent.

It MAY include:

* memory;
* beliefs;
* internal models;
* expectations;
* goals;
* preferences;
* plans;
* learned parameters;
* latent state;
* accumulated experience.

Internal state may be explicit or implicit.

---

# Environment

An environment defines the context in which an agent operates.

An environment MAY provide:

* state;
* resources;
* signals;
* fields;
* geometry;
* topology;
* morphology;
* other agents;
* constraints;
* events;
* opportunities for action.

The environment may itself be another agent or contain nested agents.

---

# Agent–Environment Coupling

The fundamental agent interaction is bidirectional:

```text
              Environment
              ↕         ↕
        Observation     Action
              ↕         ↕
             Agent
```

An agent may:

* observe the environment;
* modify the environment;
* receive signals;
* emit signals;
* consume resources;
* produce resources;
* alter relationships;
* alter topology;
* alter morphology;
* create or destroy structures.

---

# Observation

An observation is information made available to an agent concerning some aspect of its environment or internal state.

An observation may be:

* direct;
* transformed;
* aggregated;
* delayed;
* noisy;
* partial;
* probabilistic;
* derived.

Observation semantics MUST remain distinct from the underlying environment state.

An agent does not necessarily have access to the complete state of its environment.

---

# Perception

Perception transforms observations into an agent-relevant representation.

```text
Environment
     ↓
Observation
     ↓
Perception
     ↓
Agent Representation
```

Perception may involve:

* filtering;
* feature extraction;
* classification;
* interpretation;
* aggregation;
* inference;
* attention;
* spatial transformation;
* temporal integration.

Perception belongs to the Agents domain as an agent capability and to the Perception domain as a general computational domain.

---

# Action

An action is a semantic operation through which an agent attempts to influence state.

Actions may:

* modify the environment;
* modify agent state;
* communicate;
* move;
* consume resources;
* create structures;
* destroy structures;
* alter relationships;
* invoke processes.

An action does not guarantee its intended result.

The environment and its constraints determine whether and how an action takes effect.

---

# Action Space

An action space defines the set or structure of actions available to an agent under specified conditions.

Action spaces may be:

* discrete;
* continuous;
* hybrid;
* constrained;
* parameterized;
* state-dependent;
* dynamically changing.

---

# Capability

Capabilities describe what an agent is semantically capable of doing.

Examples include:

* movement;
* observation;
* communication;
* manipulation;
* reproduction;
* learning;
* planning;
* construction;
* computation;
* sensing;
* resource acquisition.

Capability does not imply current availability.

An agent may possess a capability while being unable to exercise it because of:

* state;
* environment;
* resources;
* constraints;
* permissions;
* temporal conditions.

---

# Constraints

Agent behaviour may be constrained by:

* physical laws;
* morphology;
* resources;
* environment;
* topology;
* geometry;
* policy;
* safety;
* relationships;
* goals;
* social rules;
* computational resources.

Constraints MUST remain distinguishable from preferences and goals.

---

# Goals

A goal represents a semantically meaningful desired condition, outcome, or state.

Goals may be:

* explicit;
* implicit;
* hierarchical;
* conflicting;
* dynamic;
* externally assigned;
* emergent.

Not every agent requires goals.

---

# Preferences

Preferences describe relative valuation or ordering among alternatives.

Preferences may be:

* scalar;
* ordinal;
* partial;
* context-dependent;
* state-dependent;
* learned;
* uncertain.

Preferences MUST NOT automatically be interpreted as goals.

---

# Decision

Decision is the semantic selection of one or more actions, transitions, or internal changes from available alternatives.

Decision may be:

* deterministic;
* probabilistic;
* rule-based;
* optimization-based;
* learned;
* reactive;
* deliberative;
* hierarchical.

The decision mechanism is an implementation concern unless its structure itself is semantically relevant.

---

# Policy

A policy maps agent state and observations to actions or action distributions.

Conceptually:

```text
(State, Observation, Context)
             ↓
           Policy
             ↓
       Action / Distribution
```

Policies may be:

* symbolic;
* procedural;
* mathematical;
* neural;
* learned;
* evolutionary;
* externally supplied.

The Agents domain defines the semantics of policy application, not the implementation technology.

---

# Memory

Memory represents persistent information available to an agent across state transitions.

Memory may contain:

* observations;
* experiences;
* events;
* learned information;
* relationships;
* models;
* plans;
* historical state.

Memory may be:

* short-term;
* long-term;
* episodic;
* semantic;
* procedural;
* distributed.

These categories are semantic classifications, not mandatory storage structures.

---

# Belief

A belief represents an agent's internal representation concerning some proposition, state, entity, or possibility.

Beliefs may be:

* certain;
* probabilistic;
* incomplete;
* contradictory;
* revised over time.

Belief MUST remain distinct from externally established world state.

---

# Internal Models

An agent may maintain models of:

* itself;
* its environment;
* other agents;
* future trajectories;
* resources;
* causal relationships.

Internal models may differ from the actual system they represent.

This distinction is fundamental to modelling bounded or imperfect agents.

---

# Self-Model

An agent may maintain an internal representation of:

* its state;
* capabilities;
* morphology;
* location;
* resources;
* relationships;
* limitations.

Self-models may be incomplete or inaccurate.

---

# Adaptation

Adaptation describes changes to an agent that alter how it participates in future state transitions.

Adaptation may affect:

* policy;
* goals;
* memory;
* morphology;
* capabilities;
* internal models;
* behaviour;
* resource allocation.

Adaptation does not necessarily imply learning.

---

# Learning

Learning is a process through which agent state or behaviour changes as a consequence of experience, observation, interaction, or information.

Learning may modify:

* parameters;
* policies;
* representations;
* models;
* memory;
* goals.

Neural computation is one possible implementation of learning but is not required.

---

# Communication

Agents may exchange semantic information.

Communication may occur through:

* messages;
* signals;
* fields;
* environmental modification;
* shared state;
* direct interaction;
* indirect interaction.

Communication semantics MUST remain independent of transport.

AMQP or other messaging protocols may implement communication but do not define its semantic meaning.

---

# Interaction

Agent interactions describe semantic relationships among agents.

Interactions may include:

* cooperation;
* competition;
* coordination;
* negotiation;
* conflict;
* communication;
* resource exchange;
* reproduction;
* predation;
* assistance;
* signalling.

Interactions may be pairwise or higher-order.

The Semantic Hypergraph MUST support higher-order interactions where pairwise decomposition would lose meaning.

---

# Multi-Agent Systems

Multiple agents may coexist within a shared environment.

```text
                 Environment
          ┌────────┼────────┐
          ▼        ▼        ▼
        Agent A  Agent B  Agent C
          ↕        ↕        ↕
          └────────┼────────┘
                   ▼
              Collective State
```

Collective behaviour may emerge from local interactions.

The global behaviour of an agent population MUST NOT automatically be attributed to any individual agent.

---

# Collective Agency

A collection of agents MAY itself form a semantic agent when the collective has:

* persistent identity;
* state;
* boundaries;
* capabilities;
* directed interactions;
* collective transitions.

This permits hierarchical agency.

```text
Individual Agents
       ↓
Collective
       ↓
Higher-Order Collective
```

---

# Hierarchical Agency

Agents may contain or control other agents.

Examples include:

* organisms containing subsystems;
* organisations containing individuals;
* robotic systems containing controllers;
* simulations containing autonomous subsystems.

Hierarchy MUST NOT imply semantic superiority.

---

# Population

A population is a semantic collection of agents related by a declared criterion.

Population semantics MAY include:

* membership;
* reproduction;
* mortality;
* migration;
* interaction;
* variation;
* selection;
* population-level state.

---

# Reproduction

Agents MAY create new agents.

Reproduction may involve:

* copying;
* variation;
* recombination;
* inheritance;
* mutation;
* construction.

The resulting agent MUST receive an explicit semantic identity.

---

# Division and Fusion

An agent may divide into multiple agents.

Multiple agents may fuse into a new semantic agent.

```text
        A                 A₁
        │                 │
      divide              │
      /   \               │
    A₁     A₂             │

    A₁ + A₂
       │
      fuse
       ▼
       B
```

Identity transitions MUST be explicitly defined.

---

# Lifecycle

An agent lifecycle may include:

```text
Creation
   ↓
Initialization
   ↓
Active
   ↓
Adaptation / Transformation
   ↓
Dormant / Inactive
   ↓
Termination
```

Additional states may be domain-specific.

Lifecycle transitions SHOULD preserve provenance.

---

# Embodiment

Embodiment describes how an agent's semantic agency is coupled to a body, structure, or representational substrate.

Embodiment may be:

* physical;
* biological;
* simulated;
* virtual;
* informational;
* distributed.

An agent may have multiple representations of its embodiment.

---

# Morphological Coupling

Agent morphology may constrain agency.

For example:

```text
Morphology
    ↓
Available Sensors
    ↓
Available Actions
    ↓
Agent Capabilities
    ↓
Behaviour
```

Conversely, agent behaviour may alter morphology through:

* growth;
* adaptation;
* construction;
* damage;
* development.

Therefore:

```text
Agent ↔ Morphology
```

is potentially bidirectional.

---

# Spatial Agency

An agent may possess semantic spatial state including:

* position;
* orientation;
* extent;
* region;
* topology;
* movement;
* navigation;
* proximity;
* accessibility.

Spatial agency depends upon Geometry and Topology but MUST NOT be reduced to either.

---

# Temporal Agency

Agent behaviour is temporally structured.

Temporal semantics may include:

* state duration;
* action timing;
* anticipation;
* delay;
* deadlines;
* periodic behaviour;
* event ordering.

Agent temporal semantics MUST remain distinct from wall-clock execution time.

---

# Resource Semantics

Agents may consume, possess, transform, or exchange resources.

Resources may include:

* energy;
* matter;
* information;
* computational capacity;
* space;
* time;
* social relationships.

Resource constraints may affect action availability and behaviour.

---

# Uncertainty

Agents may operate under uncertainty regarding:

* environment state;
* other agents;
* future outcomes;
* their own state;
* observations;
* actions.

Uncertainty may be represented explicitly through probabilistic or qualitative semantics.

---

# Causality

Agent actions may participate in causal chains.

```text
Observation
    ↓
Internal Transition
    ↓
Decision
    ↓
Action
    ↓
Environmental Transition
    ↓
New Observation
```

Causal provenance SHOULD identify relevant transitions and interactions.

---

# Agent State Deltas

Agent state evolution MAY be represented through semantic deltas.

Deltas may describe:

* state changes;
* memory changes;
* belief updates;
* goal changes;
* policy changes;
* relationship changes;
* capability changes;
* morphological changes;
* lifecycle transitions.

Agent deltas are semantic state changes, not storage-level diffs.

---

# Agent Streams

Agent behaviour MAY be represented as a semantic stream:

```text
Observation
    ↓
Decision
    ↓
Action
    ↓
State Delta
    ↓
Observation
    ↓
...
```

Streams may support:

* monitoring;
* interaction;
* learning;
* visualization;
* distributed execution;
* control;
* replay.

Transport mechanisms remain implementation concerns.

---

# Agents and Simulation

Simulation provides the computational environment in which agents may evolve.

```text
Simulation
     │
     ├── Environment
     │
     ├── Agents
     │     ├── State
     │     ├── Policy
     │     └── Actions
     │
     └── Evolution
```

Simulation MUST NOT define agent semantics.

Agents provide semantic entities that participate in simulation.

---

# Agents and Physics

Physical agents may be constrained by Physics.

Physics may determine:

* forces;
* energy;
* momentum;
* collisions;
* material behaviour;
* environmental interaction.

An agent's policy determines intended action.

Physics determines what physical consequences occur.

```text
Agent Intention
      ↓
Action
      ↓
Physical Constraints / Laws
      ↓
Physical Outcome
```

---

# Agents and Dynamics

Dynamics defines how state evolves.

Agents provide entities whose internal and external state participates in those dynamics.

Agent actions may therefore become inputs to dynamical systems.

---

# Agents and Fields

Agents may:

* sense fields;
* modify fields;
* move through fields;
* emit fields;
* respond to field gradients;
* use fields as communication or environmental information.

The relationship may be bidirectional.

---

# Agents and Graphs

Agents naturally participate in semantic graphs.

Graphs may represent:

* relationships;
* communication;
* social structure;
* interaction networks;
* dependency;
* knowledge;
* spatial connectivity.

Higher-order interactions SHOULD be represented as hyperrelationships when required.

---

# Agents and Geometry

Geometry may represent:

* embodiment;
* position;
* extent;
* shape;
* movement;
* spatial interaction.

Geometry describes spatial semantics.

Agents describe agency.

Neither domain replaces the other.

---

# Agents and Topology

Topology may constrain:

* connectivity;
* reachability;
* neighbourhood;
* interaction;
* movement;
* network structure.

Topology-changing agent actions MUST preserve explicit topological semantics.

---

# Agents and Morphology

Morphology describes agent form and structure.

Agent semantics describe what the entity can do and how it participates in its environment.

Morphology may therefore constrain:

* sensing;
* movement;
* manipulation;
* energy consumption;
* interaction;
* reproduction.

Agents may also participate in morphological evolution.

---

# Agents and Neural Computation

Neural computation MAY implement:

* perception;
* policy;
* memory;
* prediction;
* learning;
* control.

Neural computation is therefore a provider or computational domain used by Agents rather than the definition of agency itself.

```text
Agent
 ├── Perception
 ├── Memory
 ├── Policy
 └── Learning
        ↓
    Neural Provider
```

An agent can exist without neural computation.

---

# Agents and Rendering

Rendering provides a perceptual or representational manifestation of agents.

Rendering MUST NOT become the source of agent state.

```text
Agent State
     ↓
Render State
     ↓
Rendering
     ↓
Perceptual Representation
```

---

# Semantic Hypergraph Integration

Agents SHOULD be represented directly within the Semantic Hypergraph.

A semantic agent region may contain:

```text
Agent
├── Identity
├── State
├── Capabilities
├── Goals
├── Preferences
├── Memory
├── Beliefs
├── Models
├── Policies
├── Actions
├── Relationships
├── Morphology
├── Observations
├── Events
└── Provenance
```

Agent interactions SHOULD be first-class semantic relationships.

Higher-order interactions MUST NOT be reduced to pairwise edges when doing so loses meaning.

---

# Representation Independence

Agent semantics MUST remain independent of:

* objects;
* structs;
* processes;
* threads;
* containers;
* database records;
* network identities;
* neural-network tensors;
* game entities;
* robotics middleware.

These are implementation representations.

---

# Provider Independence

Agents MUST remain independent of particular:

* AI frameworks;
* reinforcement-learning frameworks;
* robotics frameworks;
* game engines;
* simulation engines;
* neural-network libraries;
* programming languages;
* operating systems;
* hardware.

Providers implement declared agent semantics.

Providers MUST NOT redefine agency.

---

# MLIR Representation

Agent semantics MAY be represented in MLIR through appropriate operations, types, interfaces, and transformations.

MLIR provides compilation infrastructure.

It does not define what an agent means.

Conceptually:

```text
Agent Semantics
      ↓
Agent Representation
      ↓
MLIR
      ↓
Lowering
      ↓
Runtime
      ↓
Provider
      ↓
Execution
```

Different agent implementations MAY therefore realize equivalent semantic policies using different computational mechanisms.

---

# Runtime Semantics

The SCR runtime MAY:

* schedule agents;
* manage agent state;
* resolve references;
* deliver observations;
* invoke policies;
* execute actions;
* enforce constraints;
* route messages;
* manage agent streams;
* checkpoint state;
* branch simulations;
* monitor invariants;
* select providers;
* allocate resources.

Runtime decisions MUST preserve semantic contracts.

---

# Capabilities

Agent operations MAY declare capabilities including:

* `Observable`
* `Actionable`
* `Stateful`
* `GoalDirected`
* `PolicyDriven`
* `Adaptive`
* `Learning`
* `Communicative`
* `Embodied`
* `Spatial`
* `Temporal`
* `Reactive`
* `Deliberative`
* `Stochastic`
* `Deterministic`
* `Controllable`
* `Reproducible`
* `Branchable`
* `Streamable`
* `Distributed`
* `Collective`
* `Hierarchical`.

Capabilities describe semantic properties and MUST NOT be inferred merely from implementation technology.

---

# Performance Semantics

Agent execution may be constrained by:

* observation latency;
* decision latency;
* action latency;
* population size;
* memory requirements;
* communication bandwidth;
* simulation scale;
* inference cost.

Performance characteristics MUST remain distinct from agency semantics.

---

# Errors and Failure Semantics

Agent errors MAY include:

* invalid state;
* invalid action;
* unavailable capability;
* invalid policy;
* invalid observation;
* violated constraint;
* invalid lifecycle transition;
* resource exhaustion;
* communication failure;
* perception failure;
* model failure;
* environment incompatibility.

Failures SHOULD identify whether they originate from the:

* agent;
* environment;
* policy;
* action;
* provider;
* runtime;
* execution substrate.

---

# Security and Isolation

Agents may represent autonomous or potentially untrusted computational entities.

Agent execution SHOULD support:

* capability isolation;
* resource limits;
* action authorization;
* environment boundaries;
* communication controls;
* provenance;
* sandboxing.

Semantic agency MUST NOT imply unrestricted execution authority.

---

# Standards and Interoperability

SCR Agents SHOULD reuse established standards wherever applicable.

Relevant standards MAY include:

* URI/IRI for identity;
* JSON/JSON-LD for interoperable representations;
* RDF/RDF-star where appropriate;
* ISO 8601 / RFC 3339 for temporal data;
* UCUM for quantities and units;
* established provenance standards;
* established messaging protocols;
* established model-interchange standards.

Standards provide interoperability mechanisms.

SCR Agents remains authoritative over SCR agent semantics.

---

# Expected Subdomains

The following structure is illustrative:

```text
agents/
├── agent-core
├── identity
├── state
├── lifecycle
├── environment
├── observation
├── perception
├── action
├── action-space
├── capability
├── constraint
├── goal
├── objective
├── preference
├── decision
├── policy
├── memory
├── belief
├── model
├── self-model
├── adaptation
├── learning
├── communication
├── interaction
├── cooperation
├── competition
├── coordination
├── negotiation
├── navigation
├── control
├── embodiment
├── morphology
├── spatial
├── temporal
├── population
├── collective
├── hierarchy
├── reproduction
├── division
├── fusion
├── resource
├── uncertainty
├── causality
├── event
├── delta
├── stream
├── provenance
├── simulation
├── capability
└── provider
```

This structure is illustrative and does not require immediate implementation of every subdomain.

---

# Invariants

## AGENT-INV-001 — Semantic Primacy

Agent semantics MUST remain independent of implementation.

## AGENT-INV-002 — Identity Persistence

Agent identity MUST remain distinct from physical or implementation identifiers.

## AGENT-INV-003 — State Integrity

Semantic agent state MUST remain distinguishable from implementation state.

## AGENT-INV-004 — Environment Distinction

Agent state MUST remain distinguishable from environment state.

## AGENT-INV-005 — Observation Integrity

Observations MUST remain distinguishable from the state being observed.

## AGENT-INV-006 — Action Integrity

Actions MUST remain distinct from their resulting state transitions.

## AGENT-INV-007 — Capability Integrity

Capabilities MUST remain distinct from their current availability.

## AGENT-INV-008 — Constraint Integrity

Constraints MUST remain distinguishable from goals and preferences.

## AGENT-INV-009 — Policy Integrity

Policies MUST remain distinct from the execution mechanisms implementing them.

## AGENT-INV-010 — Belief Integrity

Agent beliefs MUST remain distinguishable from externally established state.

## AGENT-INV-011 — Temporal Integrity

Agent temporal semantics MUST remain distinct from wall-clock execution time.

## AGENT-INV-012 — Interaction Integrity

Higher-order interactions MUST remain representable without forced pairwise reduction.

## AGENT-INV-013 — Lifecycle Integrity

Agent creation, transformation, division, fusion, and termination MUST have explicit semantics.

## AGENT-INV-014 — Provenance Integrity

Agent state transitions SHOULD preserve causal and provenance information.

## AGENT-INV-015 — Representation Independence

Agent meaning MUST NOT depend on a particular representation.

## AGENT-INV-016 — Provider Independence

Agent providers MUST NOT become semantic authorities.

## AGENT-INV-017 — Environment Coupling

Agent–environment relationships MUST remain explicitly representable.

## AGENT-INV-018 — Agency Minimality

An agent MUST NOT require intelligence, learning, consciousness, or neural computation unless explicitly required by a specialized domain.

---

# Domain Relationships

| Domain      | Relationship      | Meaning                                                                              |
| ----------- | ----------------- | ------------------------------------------------------------------------------------ |
| Core        | REFINES           | Agents specialize identity, state, relationships, operations, and temporal semantics |
| Data        | SPECIALIZES       | Agents organize persistent semantic state and information                            |
| Mathematics | DEPENDS_ON        | Agent models may use mathematical structures                                         |
| Graphs      | COMPOSES          | Agents participate in relational and interaction structures                          |
| Fields      | INTERACTS_WITH    | Agents may sense and modify fields                                                   |
| Geometry    | COMPOSES          | Agents may have spatial embodiment                                                   |
| Topology    | CONSTRAINS        | Connectivity and neighbourhood may constrain agency                                  |
| Morphology  | CONSTRAINS        | Form and structure may constrain capabilities                                        |
| Physics     | CONSTRAINS        | Physical agents operate under physical laws                                          |
| Dynamics    | PARTICIPATES_IN   | Agent state evolves through dynamical processes                                      |
| Simulation  | EXECUTES_IN       | Simulation realizes agent behaviour computationally                                  |
| Neural      | IMPLEMENTED_BY    | Neural computation may implement agent capabilities                                  |
| Perception  | COMPOSES          | Agents may use perception to interpret observations                                  |
| Rendering   | OBSERVED_BY       | Agent state may be rendered or visualized                                            |
| Messaging   | COMMUNICATES_WITH | Agents may exchange semantic messages                                                |
| Control     | INTERACTS_WITH    | Agents may be controlled or act as controllers                                       |

These relationships describe semantic composition and MUST NOT automatically imply implementation dependencies.

---

# Testing Requirements

Agent implementations MUST support testing at multiple levels:

```text
Specification Tests
        ↓
Unit Tests
        ↓
Domain Tests
        ↓
Composition Tests
        ↓
MLIR Tests
        ↓
Lowering Tests
        ↓
Runtime Tests
        ↓
Cross-Substrate Tests
```

Testing SHOULD include:

* identity persistence;
* state transitions;
* observation semantics;
* action semantics;
* policy behaviour;
* capability constraints;
* lifecycle transitions;
* communication;
* interaction;
* resource constraints;
* deterministic behaviour;
* stochastic behaviour;
* adaptation;
* learning;
* population behaviour;
* collective behaviour;
* environment coupling;
* causal provenance;
* checkpoint/replay;
* provider equivalence.

---

# Validation Requirements

Agent validation SHOULD evaluate whether:

1. the agent satisfies its declared semantic contract;
2. observations correctly represent available information;
3. actions respect constraints;
4. policies produce declared behaviour;
5. lifecycle transitions are valid;
6. environment coupling is correct;
7. capabilities are accurately declared;
8. learned or adaptive behaviour remains within declared contracts.

Validation MUST distinguish agent semantics from implementation performance.

---

# Function-Level Requirements

Every Agent function MUST specify, where applicable:

* semantic purpose;
* agent identity;
* state requirements;
* observations;
* inputs;
* outputs;
* actions;
* action space;
* policy semantics;
* goals;
* constraints;
* capabilities;
* temporal semantics;
* determinism;
* stochasticity;
* uncertainty;
* side effects;
* environment interaction;
* provenance;
* errors;
* resource requirements.

---

# Completeness Criteria

The Agents domain definition is complete only when:

* agents are semantically identifiable;
* agent state is defined;
* environment relationships are explicit;
* observations are first-class;
* perception is representable;
* actions are first-class;
* action spaces are representable;
* capabilities are explicit;
* constraints are explicit;
* goals and preferences are distinguishable;
* decisions and policies are representable;
* memory and beliefs are representable;
* internal models are representable;
* adaptation is representable;
* learning is representable;
* communication is representable;
* interactions are representable;
* higher-order interactions are representable;
* multi-agent systems are representable;
* collective agency is expressible;
* lifecycle transitions are explicit;
* embodiment is representable;
* morphology can constrain agency;
* spatial and temporal agency are explicit;
* uncertainty is representable;
* causal provenance is preserved;
* state deltas are representable;
* agent streams are representable;
* Semantic Hypergraph integration exists;
* provider independence is maintained;
* representation independence is maintained;
* MLIR remains an implementation/compilation mechanism rather than semantic authority.

---

# Architectural Rules

1. **An agent is defined by semantic participation in directed state transitions, not by intelligence.**
2. **Agency MUST NOT require consciousness, learning, autonomy, or neural computation.**
3. **Agent identity MUST remain independent of implementation identity.**
4. **Agent state MUST remain distinct from environment state.**
5. **Observation MUST remain distinct from underlying state.**
6. **Action MUST remain distinct from action outcome.**
7. **Capabilities MUST remain distinct from current availability.**
8. **Goals MUST remain distinct from constraints.**
9. **Preferences MUST remain distinct from goals.**
10. **Policies MUST remain distinct from their implementation mechanisms.**
11. **Beliefs MUST remain distinct from externally established state.**
12. **Agent–environment interaction MUST be explicitly representable.**
13. **Higher-order interactions MUST NOT be forced into pairwise representations when semantic information would be lost.**
14. **Agent lifecycle transitions MUST preserve identity and provenance semantics where applicable.**
15. **Morphology MAY constrain agency and agency MAY influence morphology.**
16. **Agents MUST integrate naturally with Simulation without being defined by Simulation.**
17. **Neural computation MAY implement agents but MUST NOT define agency.**
18. **Rendering MUST remain an observation or manifestation mechanism rather than agent truth.**
19. **External AI, robotics, or agent frameworks MUST be treated as providers.**
20. **Runtime optimisation MUST preserve declared agent semantics.**
21. **Hardware characteristics MAY influence execution but MUST NOT redefine agency.**

---

# Open Semantic Questions

The following remain intentionally open:

* How should degrees of agency be formally represented?
* How should intentionality be represented without requiring a philosophical commitment about consciousness or free will?
* How should goals and preferences be represented when they are emergent rather than explicitly declared?
* How should conflicting goals be represented?
* How should agent identity behave through division and fusion?
* How should collective agency emerge from individual agents?
* How should agent boundaries be represented when they are fuzzy or dynamic?
* How should an agent's internal model relate to the external semantic graph?
* How should belief revision be represented?
* How should action consequences be represented when outcomes are probabilistic?
* How should causal responsibility be represented?
* How should learned policies declare semantic guarantees?
* How should morphological adaptation affect capability contracts?
* How should agents operate across multiple temporal scales?
* How should agent communication interact with semantic streams and AMQP-oriented transports?
* How should distributed agents preserve causal semantics?
* How should agent autonomy interact with runtime control?
* How should resource limitations become part of agency semantics?
* How should agents themselves become composable computational entities?

These questions MUST NOT be prematurely resolved through dependence on a particular AI framework, neural architecture, robotics middleware, simulation engine, or execution substrate.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Established:

* Agent as a semantic entity participating in directed state transitions;
* agent identity and state;
* environment coupling;
* observation and perception;
* action and action spaces;
* capabilities and constraints;
* goals and preferences;
* decision and policy;
* memory and beliefs;
* internal and self-models;
* adaptation and learning;
* communication and interaction;
* multi-agent and collective agency;
* hierarchy and populations;
* reproduction, division, and fusion;
* lifecycle;
* embodiment;
* morphological, spatial, and temporal agency;
* resource semantics;
* uncertainty and causality;
* state deltas and streams;
* Semantic Hypergraph integration;
* Simulation integration;
* Neural integration;
* MLIR and provider independence.

---

# Definition Authority

This document is the normative semantic definition of the SCR Agents domain.

Implementation documents, source code, AI frameworks, robotics frameworks, simulation engines, providers, examples, benchmarks, and generated artifacts MUST NOT redefine this domain without an explicit semantic revision.

---

# Definition Principle

> **An agent is a semantic entity whose persistent state participates in directed interaction with an environment through observation, internal transformation, selection, action, and adaptation.**

The fundamental separation is:

```text
ENVIRONMENT
     ↓
OBSERVATION
     ↓
PERCEPTION
     ↓
AGENT STATE
     ↓
POLICY / DECISION
     ↓
ACTION
     ↓
ENVIRONMENT
     ↺
```

The implementation of the policy is replaceable.

The embodiment is replaceable.

The execution substrate is replaceable.

The semantic agency remains authoritative.

---

# Compact Conceptual Model

```text
                         AGENT
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          IDENTITY        STATE      CAPABILITIES
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          MEMORY         BELIEFS        GOALS
             │             │             │
             └─────────────┼─────────────┘
                           ▼
                      OBSERVATION
                           │
                           ▼
                       PERCEPTION
                           │
                           ▼
                    DECISION / POLICY
                           │
                           ▼
                         ACTION
                           │
                           ▼
                     ENVIRONMENT
                           │
                           ▼
                    NEW OBSERVATION
```

At higher scales:

```text
Agent
  ↕
Agent
  ↕
Agent
  ↓
Interaction Network
  ↓
Collective
  ↓
Emergent Behaviour
```

The result is a semantic foundation for computational entities that can **exist, perceive, decide, act, interact, adapt, and evolve within computational environments**, without requiring SCR to commit to any particular theory of intelligence or any particular implementation technology.
