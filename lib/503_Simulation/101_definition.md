---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-SIMULATION
name: Simulation

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
---

# Simulation

## Definition

Simulation is the semantic computational domain concerned with the **computational realization, execution, observation, experimentation, and analysis of models of systems and their behaviour**.

A simulation realizes a semantic model through a computational process while preserving an explicit distinction between:

1. the system being modelled;
2. the model describing that system;
3. the computational state representing the model;
4. the simulation process executing the model;
5. observations produced by the simulation;
6. the physical, informational, or perceptual system represented by those observations.

Simulation therefore provides the semantic bridge between **models and computational experiments**.

```text
System / Phenomenon
        ↓
Semantic Model
        ↓
Simulation Model
        ↓
Simulation State
        ↓
Simulation Evolution
        ↓
Observations / Results
```

Simulation is not synonymous with:

* physics;
* dynamics;
* numerical integration;
* visualization;
* a simulation engine;
* a game engine;
* a particular numerical method;
* a particular execution environment.

A simulation MAY realize physical, biological, ecological, chemical, social, economic, agent-based, neural, morphological, computational, informational, or abstract dynamical systems.

---

# Semantic Model

A simulation can be understood conceptually as:

```text
SIM = (M, S, E, T, X, O, I, C, P)
```

where:

* `M` = model
* `S` = simulation state
* `E` = environment
* `T` = temporal semantics
* `X` = execution/evolution semantics
* `O` = observations
* `I` = interventions and inputs
* `C` = constraints
* `P` = provenance

This is a conceptual semantic model rather than a prescribed implementation structure.

A simulation MUST preserve the distinction between model semantics and the computational mechanisms used to realize them.

---

# Scope

SCR Simulation includes semantics for:

* simulation models
* simulation instances
* simulation state
* initial conditions
* environments
* model parameters
* simulation configuration
* scenarios
* experiments
* interventions
* inputs
* controls
* clocks
* timelines
* timesteps
* events
* state transitions
* trajectories
* checkpoints
* snapshots
* state deltas
* execution
* scheduling
* stepping
* continuous simulation
* discrete simulation
* hybrid simulation
* deterministic simulation
* stochastic simulation
* agent-based simulation
* field-based simulation
* particle-based simulation
* event-driven simulation
* discrete-event simulation
* multiscale simulation
* distributed simulation
* co-simulation
* coupled simulation
* surrogate simulation
* reduced-order simulation
* parameter sweeps
* ensembles
* experimental design
* observation
* measurement
* telemetry
* simulation streams
* simulation provenance
* reproducibility
* validation
* verification
* calibration
* sensitivity analysis
* uncertainty propagation
* scenario comparison
* result analysis
* model comparison
* simulation equivalence
* simulation lifecycle
* simulation resources
* simulation capabilities.

---

# System, Model, and Simulation

SCR MUST distinguish three fundamental concepts:

```text
System
  │
  │ is the phenomenon or structure of interest
  ▼
Model
  │
  │ describes selected aspects of that system
  ▼
Simulation
  │
  │ computationally realizes the model
  ▼
Results
```

A model is not the system.

A simulation is not the model.

A result is not necessarily the system.

This distinction is fundamental to semantic correctness.

---

# Model

A model is a semantic abstraction describing selected properties, relationships, laws, constraints, behaviours, or structures of a system.

A model MAY be:

* physical
* mathematical
* dynamical
* statistical
* probabilistic
* agent-based
* morphological
* geometric
* topological
* field-based
* graph-based
* neural
* computational
* hybrid.

A simulation MAY compose multiple models.

---

# Simulation Model

A simulation model is a computationally realizable representation of a semantic model.

It MAY include:

* state definitions
* evolution rules
* parameters
* constraints
* initial conditions
* boundary conditions
* observation functions
* intervention interfaces
* numerical approximations
* execution requirements.

The simulation model MUST preserve provenance linking it to the semantic model it realizes.

---

# Simulation Instance

A simulation instance represents a particular execution context of a model.

It MAY specify:

* model identity
* initial state
* parameters
* environment
* scenario
* random-state configuration
* temporal configuration
* resolution
* precision
* execution configuration
* observation configuration.

Two simulation instances of the same model MAY produce different trajectories because their initial conditions, inputs, environments, or stochastic realizations differ.

---

# Simulation State

Simulation state represents the current computational realization of the model state.

It MAY contain:

* semantic state
* derived state
* execution state
* cached state
* numerical state
* scheduler state
* provider state.

These categories MUST remain distinguishable.

Only state explicitly designated as semantically relevant becomes part of the model's semantic state.

---

# Initial Conditions

Initial conditions define the starting state of a simulation.

They MAY specify:

* entity state
* field state
* geometry
* topology
* morphology
* agent state
* environmental state
* parameters
* stochastic state.

Initial conditions MUST be semantically explicit.

---

# Environment

A simulation environment defines the contextual system in which the simulated model operates.

An environment MAY contain:

* spatial domain
* temporal domain
* fields
* boundaries
* resources
* external inputs
* agents
* physical conditions
* interaction rules
* environmental processes.

The environment MAY itself be dynamically simulated.

---

# Scenario

A scenario defines a particular set of conditions under which a simulation is executed.

A scenario MAY include:

* initial conditions
* parameters
* environment
* interventions
* external inputs
* model variants
* constraints
* observation configuration.

Scenarios SHOULD be identity-addressable and provenance-bearing.

---

# Experiments

Simulation provides semantics for computational experiments.

An experiment consists conceptually of:

```text
Model
  +
Scenario
  +
Intervention
  +
Execution
  ↓
Observation
  ↓
Analysis
```

Experiments MAY be:

* exploratory
* comparative
* predictive
* diagnostic
* calibration-oriented
* sensitivity-oriented
* optimization-oriented
* hypothesis-testing.

Simulation experiments SHOULD preserve sufficient provenance to reproduce or interpret their results.

---

# Parameters

Parameters define values controlling a model or simulation.

Parameters MAY be:

* fixed
* variable
* estimated
* sampled
* optimized
* inferred
* dynamically changing.

A parameter MUST remain distinguishable from state where the model semantics require that distinction.

---

# Configuration

Simulation configuration describes how a model is computationally realized.

It MAY include:

* timestep
* resolution
* precision
* solver configuration
* execution provider
* parallelism
* checkpoint frequency
* observation frequency
* resource limits.

Configuration MUST NOT silently redefine semantic model meaning.

---

# Time

Simulation requires explicit temporal semantics.

Simulation time MAY differ from:

* physical time
* model time
* observation time
* wall-clock time
* processing time.

Conceptually:

```text
Model Time
     │
     ▼
Simulation Clock
     │
     ▼
Execution
     │
     ▼
Wall Clock
```

These temporal domains MUST NOT be conflated.

A simulation may execute faster or slower than the time represented by the model.

---

# Stepping

Stepping advances a simulation through its temporal domain.

A step MAY represent:

* a fixed interval
* an adaptive interval
* a discrete event
* a batch of events
* a state transition
* an externally triggered advancement.

The semantic meaning of a step MUST remain distinct from the numerical mechanism used to calculate it.

---

# Continuous Simulation

Continuous simulations realize models whose semantic evolution is continuous.

Implementation MAY use:

* numerical integration
* adaptive integration
* discretised PDE methods
* symbolic methods
* hybrid numerical methods.

The simulation semantics remain independent of those methods.

---

# Discrete Simulation

Discrete simulations realize systems whose relevant evolution occurs through discrete state transitions or events.

Examples include:

* cellular automata
* discrete-event systems
* agent-based models
* network models
* rule systems.

---

# Hybrid Simulation

Hybrid simulation combines continuous evolution with discrete events.

```text
Continuous State
      ↓
Threshold / Event
      ↓
Discrete Transition
      ↓
Continuous State
```

The simulation MUST preserve the semantic distinction between continuous evolution and discrete transition.

---

# Deterministic Simulation

A deterministic simulation produces a uniquely defined semantic trajectory given equivalent:

* model
* initial state
* parameters
* inputs
* environment
* temporal conditions.

Implementation-level nondeterminism MUST be distinguished from semantic nondeterminism.

---

# Stochastic Simulation

Stochastic simulations realize models involving probabilistic evolution.

They MAY use:

* random processes
* probability distributions
* sampled events
* Monte Carlo methods
* stochastic differential equations
* stochastic agent behaviour.

The stochastic model MUST remain distinct from the implementation's random-number generator.

---

# Agent-Based Simulation

Agent-based simulation realizes systems in which semantic agents participate in state evolution.

```text
Environment
    ↕
Agents
    ↕
Interactions
    ↕
Collective Dynamics
```

Agents MAY possess:

* state
* perception
* goals
* policies
* memory
* learning
* actions.

Agent semantics belong to the Agents domain.

Simulation provides the computational environment in which those agents evolve.

---

# Field-Based Simulation

Field-based simulation realizes models whose state includes evolving fields.

Fields MAY represent:

* physical quantities
* environmental variables
* information
* probability
* concentration
* temperature
* pressure
* neural activity
* abstract semantic quantities.

The Fields domain defines field semantics.

Simulation realizes their evolution.

---

# Particle-Based Simulation

Particle-based simulation represents systems through collections of semantically meaningful entities or particles.

Particles MAY represent:

* physical particles
* agents
* material elements
* abstract entities.

A particle representation MUST NOT be assumed to define the underlying semantic model.

---

# Event-Driven Simulation

Event-driven simulation advances state based on discrete semantic events rather than fixed temporal steps.

Events MAY include:

* collisions
* messages
* threshold crossings
* agent actions
* state changes
* external interventions.

Event ordering MUST preserve declared temporal and causal semantics.

---

# Multiscale Simulation

Simulation MAY combine models operating at different:

* spatial scales
* temporal scales
* semantic resolutions
* abstraction levels.

```text
Microscopic Model
       ↕
Mesoscopic Model
       ↕
Macroscopic Model
```

Coupling between scales MUST preserve declared semantic relationships and approximation assumptions.

---

# Co-Simulation

Co-simulation combines independently defined models or simulation components.

Components MAY have:

* different state representations
* different time resolutions
* different numerical methods
* different providers
* different execution substrates.

Co-simulation MUST define:

* coupling semantics
* synchronization
* data exchange
* temporal alignment
* error semantics
* provenance.

---

# Distributed Simulation

Simulation MAY execute across multiple computational resources.

Distribution MAY involve:

* processes
* machines
* clusters
* accelerators
* cloud resources
* heterogeneous hardware.

Distributed execution MUST NOT alter semantic meaning merely because state is physically partitioned.

---

# Parallel Simulation

Simulation MAY exploit:

* data parallelism
* task parallelism
* spatial decomposition
* temporal decomposition
* pipeline parallelism
* accelerator execution.

Parallelism is an execution property unless explicitly represented as semantic structure.

---

# Simulation Events

Events are first-class simulation concepts.

Events MAY:

* trigger transitions
* alter parameters
* modify environments
* invoke interventions
* generate observations
* initiate checkpoints
* terminate simulations.

Events SHOULD retain temporal and causal metadata.

---

# State Deltas

Simulation state MAY evolve through semantic deltas.

```text
S₀
 │
 Δ₁
 ▼
S₁
 │
 Δ₂
 ▼
S₂
```

Deltas MAY describe:

* entity creation
* entity destruction
* attribute changes
* relationship changes
* topology changes
* geometry changes
* morphology changes
* field updates
* agent actions
* parameter changes.

A delta is semantic state evolution, not a storage-layer diff.

---

# Checkpoints

A checkpoint represents a recoverable semantic state of a simulation.

Checkpoints MAY support:

* restart
* branching
* replay
* analysis
* comparison
* debugging
* provenance.

A checkpoint MAY be a materialized representation of state reconstructed from prior states and deltas.

The conceptual semantics do not prescribe how checkpoints are stored.

---

# Branching

Simulation state MAY branch into multiple future trajectories.

```text
                 S₀
                  │
                 S₁
              ┌───┴───┐
              ▼       ▼
             S₂a     S₂b
              │       │
             ...     ...
```

Branching enables:

* scenario analysis
* parameter exploration
* intervention analysis
* counterfactual experiments
* uncertainty exploration.

Branches SHOULD preserve lineage to their originating state.

---

# Replay

A simulation MAY be replayed from:

* initial conditions
* checkpoint
* state snapshot
* event sequence
* delta sequence
* deterministic execution history.

Replay semantics MUST specify what level of equivalence is required.

Bitwise replay is stronger than semantic replay.

---

# Counterfactual Simulation

Simulation MAY evaluate alternative trajectories resulting from hypothetical changes to:

* initial conditions
* parameters
* interventions
* policies
* environment
* model assumptions.

Counterfactual branches SHOULD preserve explicit provenance identifying the divergence point.

---

# Parameter Sweeps

Simulation MAY evaluate multiple parameter configurations.

```text
Model
  │
  ├── Parameter Set A → Run A
  ├── Parameter Set B → Run B
  ├── Parameter Set C → Run C
  └── Parameter Set D → Run D
```

Each run MUST remain independently identifiable.

---

# Ensembles

An ensemble is a semantically related collection of simulation runs.

Ensembles MAY vary:

* initial conditions
* parameters
* stochastic realizations
* models
* environments
* interventions.

Ensemble semantics SHOULD preserve the relationship among constituent runs.

---

# Calibration

Simulation MAY be calibrated against observations or reference data.

Calibration MAY modify:

* parameters
* model selection
* uncertainty estimates
* initial conditions.

Calibration provenance MUST distinguish observed data from model-generated data.

---

# Validation

Validation asks whether a simulation adequately represents the intended system or phenomenon for a specified purpose.

Validation MAY compare:

* observables
* trajectories
* distributions
* invariants
* morphology
* topology
* statistical properties
* physical quantities.

Validation MUST be defined relative to an explicit model purpose and validity domain.

---

# Verification

Verification asks whether the simulation implementation correctly realizes its declared computational model.

Verification MAY include:

* analytical comparisons
* invariant checks
* conservation checks
* numerical convergence
* deterministic replay
* provider comparison
* formal contracts.

Verification and validation MUST remain distinct.

```text
Verification
    ↓
Did we implement the model correctly?

Validation
    ↓
Does the model adequately represent the intended system?
```

---

# Observations

Simulation produces observations of simulated state.

An observation MAY include:

* sampled state
* measurement
* derived quantity
* event
* rendered output
* aggregate
* statistic
* trajectory segment.

Observation MUST remain distinguishable from underlying simulation state.

---

# Simulation Outputs

Outputs MAY include:

* states
* deltas
* trajectories
* events
* fields
* graphs
* geometry
* morphology
* measurements
* statistics
* render streams
* telemetry.

Outputs SHOULD retain semantic identity and provenance.

---

# Streaming

Simulation is naturally compatible with semantic streaming.

A simulation stream MAY contain:

```text
State
  ↓
Delta
  ↓
Event
  ↓
Observation
  ↓
State
  ↓
...
```

Streams MAY support:

* live observation
* incremental analysis
* remote execution
* visualization
* control
* monitoring
* downstream computation.

Transport mechanisms such as AMQP MAY realize simulation streams but are not themselves the semantic stream.

---

# Simulation and the Semantic Hypergraph

Simulation integrates directly with the SCR Semantic Hypergraph.

A simulation MAY be represented as a semantic region containing:

```text
Simulation
├── Model
├── State
├── Environment
├── Parameters
├── Timeline
├── Events
├── Interventions
├── Observations
├── Trajectories
├── Checkpoints
├── Deltas
├── Results
└── Provenance
```

Relationships between these structures MUST remain semantically addressable.

Simulation state changes MAY be expressed as graph operations or semantic deltas.

---

# Simulation Branches and Graph State

Simulation branching naturally maps onto semantic graph state evolution.

```text
                 Graph State G₀
                      │
                     Δ₁
                      ▼
                 Graph State G₁
                  /          \
               Δ₂a            Δ₂b
                ▼              ▼
               G₂a            G₂b
```

This permits simulations to be treated as evolving semantic histories rather than merely sequences of opaque frames.

---

# Morphological Simulation

Simulation MAY evolve morphology.

Examples include:

* growth
* deformation
* branching
* fission
* fusion
* self-organisation
* developmental processes
* structural adaptation.

Morphology remains a semantic domain.

Simulation provides the process through which morphological state evolves.

---

# Geometry and Topology

Simulation MAY evolve:

* geometry
* topology
* spatial fields
* boundaries
* connectivity.

Topology-changing simulation MUST preserve explicit topological semantics.

Geometric approximation MUST NOT silently imply topological equivalence.

---

# Rendering

Simulation MAY produce rendering state or rendering streams.

```text
Simulation State
      ↓
Semantic Render State
      ↓
Render Commands
      ↓
Renderer
```

Rendering is an observer/manifestation domain.

It MUST NOT become the source of simulation truth.

---

# Simulation Control

A running simulation MAY accept semantic control operations such as:

* pause
* resume
* step
* advance
* rewind
* branch
* checkpoint
* restore
* intervene
* terminate
* change observation
* alter permitted parameters.

Control operations SHOULD be represented as semantic operations with provenance.

---

# Adaptive Simulation

A simulation MAY adapt its computational realization based on:

* error estimates
* state complexity
* available resources
* resolution requirements
* timescales
* topology
* morphology
* observed dynamics.

Adaptation MUST preserve declared semantic contracts.

For example, adaptive resolution MAY alter representation without altering the intended model.

---

# Model Reduction

Simulation MAY employ reduced-order models.

Reduction MAY involve:

* dimensional reduction
* coarse-graining
* surrogate models
* learned approximations
* reduced state spaces
* temporal abstraction.

A reduced model MUST explicitly declare:

* source model
* approximation
* preserved properties
* validity domain
* error characteristics.

---

# Surrogate Models

A surrogate model approximates another model for a specified purpose.

Surrogates MAY be:

* analytical
* statistical
* machine learned
* reduced-order
* interpolated.

A surrogate MUST NOT automatically inherit full semantic equivalence to its source model.

Equivalence MUST be established relative to explicit observables and validity criteria.

---

# Simulation Equivalence

Two simulation executions MAY be equivalent under different criteria.

Possible equivalence levels include:

```text
Bitwise Equivalence
       ↓
Numerical Equivalence
       ↓
Trajectory Equivalence
       ↓
Observational Equivalence
       ↓
Behavioural Equivalence
```

A weaker equivalence MUST NOT be represented as a stronger one.

---

# Uncertainty

Simulation MAY propagate uncertainty arising from:

* initial conditions
* parameters
* observations
* model assumptions
* stochastic processes
* numerical approximation
* environmental uncertainty.

Uncertainty provenance MUST be preserved.

---

# Sensitivity Analysis

Simulation MAY evaluate sensitivity to:

* initial state
* parameters
* inputs
* environment
* model assumptions
* numerical configuration.

Sensitivity results SHOULD identify the semantic variables being varied.

---

# Provenance

Simulation provenance SHOULD capture:

* model identity
* model version
* scenario
* initial state
* parameters
* environment
* interventions
* provider
* execution configuration
* transformations
* approximations
* random-state provenance
* observations
* derived results.

Provenance is necessary for reproducibility and interpretation.

---

# Reproducibility

Simulation SHOULD support reproducibility at explicitly declared levels.

Possible levels include:

* semantic reproducibility
* observational reproducibility
* numerical reproducibility
* deterministic replay
* bitwise reproducibility.

Reproducibility requirements MUST be explicit.

---

# Representation Independence

Simulation MUST remain independent of:

* arrays
* tensors
* particle buffers
* meshes
* graph databases
* files
* containers
* network protocols
* memory layouts
* specific simulation engines.

These are implementation mechanisms.

---

# Provider Independence

Simulation MUST remain independent of particular:

* simulation engines
* physics engines
* numerical solvers
* agent frameworks
* workflow systems
* distributed runtimes
* GPU frameworks
* programming languages
* hardware.

Providers implement simulation contracts.

Providers MUST NOT become semantic authorities.

---

# MLIR Representation

Simulation MAY be represented in MLIR through appropriate dialects, operations, interfaces, and transformations.

MLIR provides compilation infrastructure.

MLIR MUST NOT become the normative authority over simulation semantics.

Conceptually:

```text
Simulation Semantics
        ↓
Simulation Representation
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

A simulation MAY lower into different execution strategies while preserving its semantic model.

---

# Runtime Semantics

The SCR runtime MAY use simulation semantics to:

* schedule execution
* select providers
* select numerical methods
* manage state
* manage checkpoints
* stream deltas
* branch trajectories
* allocate resources
* adapt resolution
* monitor invariants
* execute distributed simulations
* coordinate coupled simulations.

Runtime decisions MUST preserve declared semantic contracts.

---

# Capabilities

Simulation operations MAY declare capabilities including:

* `Deterministic`
* `Stochastic`
* `Continuous`
* `Discrete`
* `Hybrid`
* `EventDriven`
* `Stateful`
* `Branchable`
* `Checkpointable`
* `Replayable`
* `Streamable`
* `Distributed`
* `Parallelizable`
* `Adaptive`
* `Multiscale`
* `CoSimulatable`
* `Observable`
* `Controllable`
* `Incremental`
* `Differentiable`
* `UncertaintyAware`
* `SurrogateCapable`.

Capabilities MUST describe declared properties rather than assumed implementation behaviour.

---

# Performance Semantics

Simulation performance MAY involve:

* simulation-time / wall-time ratio
* throughput
* latency
* timestep cost
* memory consumption
* communication cost
* checkpoint cost
* stream bandwidth
* parallel scaling
* accelerator utilisation.

Performance MUST remain distinct from semantic validity.

A faster simulation is not necessarily a more accurate simulation.

---

# Errors and Failure Semantics

Simulation errors MAY include:

* invalid model
* invalid initial state
* invalid parameter
* invalid scenario
* invalid intervention
* violated constraint
* numerical instability
* non-convergence
* invalid temporal configuration
* provider failure
* resource exhaustion
* synchronization failure
* provenance failure
* reproducibility failure
* model validity violation.

Errors SHOULD identify whether the failure originated from:

* model
* state
* scenario
* numerical method
* provider
* runtime
* execution substrate.

---

# Resource Semantics

Simulation MAY consume:

* CPU
* GPU
* accelerator resources
* memory
* storage
* communication
* energy
* wall-clock time.

Resource requirements SHOULD be declarable independently of semantic model meaning.

---

# Security and Isolation

Simulation may execute:

* external models
* user-defined providers
* plugins
* learned models
* generated code
* distributed workloads.

Execution environments MUST provide appropriate isolation.

Untrusted simulation implementations MUST NOT automatically gain authority over the semantic model or runtime.

---

# Standards and Interoperability

SCR Simulation SHOULD reuse established open standards wherever applicable.

Relevant standards MAY include:

* ISO 8601 / RFC 3339 for time
* UCUM for quantities and units
* MathML / OpenMath for mathematical representations
* established scientific data formats
* established graph representations
* established model-exchange standards
* established workflow and provenance standards.

Standards provide interoperability mechanisms.

SCR Simulation remains authoritative over SCR simulation semantics.

---

# Expected Subdomains

The following structure is illustrative and may evolve:

```text
simulation/
├── simulation-core
├── model
├── model-version
├── instance
├── state
├── environment
├── scenario
├── parameter
├── configuration
├── initial-condition
├── boundary-condition
├── clock
├── timeline
├── step
├── transition
├── event
├── intervention
├── control
├── continuous
├── discrete
├── hybrid
├── deterministic
├── stochastic
├── agent-based
├── field-based
├── particle-based
├── event-driven
├── multiscale
├── distributed
├── parallel
├── co-simulation
├── checkpoint
├── snapshot
├── branch
├── replay
├── counterfactual
├── ensemble
├── parameter-sweep
├── calibration
├── verification
├── validation
├── observation
├── measurement
├── output
├── stream
├── delta
├── provenance
├── reproducibility
├── uncertainty
├── sensitivity
├── surrogate
├── model-reduction
├── equivalence
├── adaptation
├── capability
└── provider
```

This structure is illustrative and does not require immediate implementation of every subdomain.

---

# Invariants

## SIMULATION-INV-001 — Semantic Primacy

Simulation semantics MUST remain independent of implementation.

## SIMULATION-INV-002 — Model Integrity

A simulation MUST remain traceable to the semantic model it realizes.

## SIMULATION-INV-003 — State Integrity

Semantic simulation state MUST remain distinguishable from implementation state.

## SIMULATION-INV-004 — Temporal Integrity

Simulation time MUST remain distinct from wall-clock and processing time.

## SIMULATION-INV-005 — Initial Condition Integrity

Initial conditions MUST be explicit and provenance-bearing.

## SIMULATION-INV-006 — Transition Integrity

Simulation transitions MUST preserve declared model semantics.

## SIMULATION-INV-007 — Event Integrity

Semantically meaningful events MUST remain explicitly representable.

## SIMULATION-INV-008 — Delta Integrity

State deltas MUST represent semantic changes rather than storage-level differences.

## SIMULATION-INV-009 — Branch Integrity

Simulation branches MUST preserve lineage to their source state.

## SIMULATION-INV-010 — Checkpoint Integrity

Checkpoints MUST represent semantically recoverable simulation state.

## SIMULATION-INV-011 — Provenance Integrity

Simulation results MUST preserve relevant model, scenario, execution, and transformation provenance.

## SIMULATION-INV-012 — Reproducibility Integrity

Declared reproducibility requirements MUST remain explicit.

## SIMULATION-INV-013 — Validation Integrity

Simulation validation MUST remain distinct from implementation verification.

## SIMULATION-INV-014 — Approximation Integrity

Model reductions and numerical approximations MUST remain explicit.

## SIMULATION-INV-015 — Equivalence Integrity

Simulation equivalence MUST be defined relative to explicit criteria.

## SIMULATION-INV-016 — Representation Independence

Simulation semantics MUST NOT depend on a particular physical representation.

## SIMULATION-INV-017 — Provider Independence

Simulation providers MUST NOT become semantic authorities.

## SIMULATION-INV-018 — Runtime Independence

Simulation semantics MUST remain independent of runtime and hardware substrate.

---

# Domain Relationships

| Domain      | Relationship   | Meaning                                                                         |
| ----------- | -------------- | ------------------------------------------------------------------------------- |
| Core        | REFINES        | Simulation specializes state, operation, temporal, and transformation semantics |
| Data        | SPECIALIZES    | Simulation manages structured semantic state and results                        |
| Mathematics | DEPENDS_ON     | Simulation models may use mathematical structures                               |
| Graphs      | COMPOSES       | Simulation state and interactions may be graph-structured                       |
| Fields      | COMPOSES       | Fields may constitute simulation state                                          |
| Geometry    | COMPOSES       | Geometry may evolve during simulation                                           |
| Topology    | COMPOSES       | Topological state may evolve during simulation                                  |
| Morphology  | COMPOSES       | Morphological state may evolve during simulation                                |
| Physics     | REALIZES       | Simulation may computationally realize physical models                          |
| Dynamics    | REALIZES       | Simulation computationally realizes dynamical models                            |
| Agents      | REALIZES       | Simulation provides execution contexts for agents                               |
| Perception  | PRODUCES       | Simulation may produce observations for perception                              |
| Rendering   | PRODUCES       | Simulation may produce renderable state                                         |
| Streams     | PRODUCES       | Simulation may produce continuous semantic streams                              |
| Control     | INTERACTS_WITH | Simulations may accept interventions and control                                |
| Learning    | INTERACTS_WITH | Simulation may provide environments for learning                                |

These are semantic relationships and MUST NOT automatically imply software-package dependencies.

---

# Testing Requirements

Simulation implementations MUST support testing at multiple levels:

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

Testing SHOULD include, where applicable:

* model validity
* initial state validity
* parameter validity
* state transitions
* event ordering
* temporal correctness
* conservation
* invariant preservation
* numerical convergence
* numerical stability
* deterministic replay
* stochastic properties
* checkpoint recovery
* branching
* trajectory equivalence
* provider equivalence
* distributed consistency
* stream correctness
* provenance completeness.

---

# Validation Requirements

A simulation is valid only relative to:

1. a declared model;
2. a declared purpose;
3. a declared validity domain;
4. declared initial and boundary conditions;
5. declared parameters;
6. declared approximation and execution assumptions.

Validation SHOULD distinguish:

```text
Verification
    ↓
Was the simulation implemented correctly?

Validation
    ↓
Does the model/simulation adequately represent the intended system?

Reproducibility
    ↓
Can the computational result be independently reproduced?

Equivalence
    ↓
Are two realizations semantically equivalent under stated criteria?
```

---

# Function-Level Requirements

Every Simulation function MUST specify, where applicable:

* semantic purpose
* model identity
* state requirements
* inputs
* outputs
* temporal semantics
* transition semantics
* event semantics
* parameter semantics
* constraints
* determinism
* stochasticity
* approximation
* uncertainty
* provenance
* reproducibility
* equivalence
* error semantics
* capabilities
* resource requirements.

---

# Completeness Criteria

The Simulation domain definition is complete only when:

* models are explicitly representable;
* simulation instances are identifiable;
* simulation state is defined;
* initial conditions are explicit;
* environments are representable;
* scenarios are representable;
* parameters are explicit;
* time semantics are explicit;
* continuous and discrete simulation are supported;
* hybrid simulation is expressible;
* deterministic and stochastic simulation are expressible;
* events are first-class;
* interventions are first-class;
* deltas are representable;
* checkpoints are representable;
* branching is expressible;
* replay semantics exist;
* ensembles and parameter sweeps are expressible;
* distributed and coupled simulation are expressible;
* observations are distinct from state;
* validation and verification are distinct;
* provenance is preserved;
* reproducibility is explicit;
* uncertainty is representable;
* approximation is explicit;
* equivalence is defined;
* provider independence is maintained;
* representation independence is maintained;
* Semantic Hypergraph integration exists;
* runtime and hardware do not become semantic authorities.

---

# Architectural Rules

1. **Simulation realizes models; it does not define the systems being modelled.**
2. **Simulation MUST remain distinct from Dynamics.**
3. **Simulation MUST remain distinct from Physics.**
4. **Simulation state MUST remain distinct from runtime state.**
5. **Model identity and provenance MUST be preserved.**
6. **Initial conditions MUST be explicit.**
7. **Simulation time MUST remain distinct from wall-clock time.**
8. **Events and interventions MUST be first-class semantic concepts.**
9. **State deltas MUST be semantic rather than storage-level diffs.**
10. **Checkpoints MUST represent semantic state rather than opaque runtime memory.**
11. **Simulation branches MUST preserve lineage.**
12. **Approximation and model reduction MUST be explicit.**
13. **Verification MUST remain distinct from validation.**
14. **Simulation MUST integrate with the Semantic Hypergraph.**
15. **Simulation streams MUST be semantic streams independent of transport.**
16. **Rendering MUST remain an observation/manifestation mechanism rather than simulation truth.**
17. **External simulation engines MUST be treated as providers.**
18. **MLIR MUST remain a compilation representation rather than simulation authority.**
19. **Runtime optimisation MUST preserve declared simulation semantics.**
20. **Hardware characteristics MAY influence execution but MUST NOT redefine simulation meaning.**

---

# Open Semantic Questions

The following questions remain intentionally open:

* How should simulation models be formally distinguished from executable models?
* How should simulation state be partitioned into semantic and execution state?
* How should model validity be formally encoded?
* How should verification and validation contracts be machine-readable?
* How should semantic reproducibility be defined across different providers?
* How should checkpoint semantics interact with Semantic Hypergraph state and delta streams?
* How should simulation branches share immutable semantic state?
* How should distributed simulations represent causal ordering?
* How should co-simulation synchronize systems with incompatible temporal semantics?
* How should adaptive timestep selection expose semantic guarantees?
* How should model reduction declare preserved invariants?
* How should learned surrogate models declare equivalence to source models?
* How should counterfactual simulations represent causal provenance?
* How should simulation streams interact with runtime messaging infrastructure?
* How should simulations themselves become composable semantic components?
* How should simulation resources be represented when resource constraints become part of the model?
* How should long-running simulations expose incremental state without requiring complete materialization?

These questions MUST NOT be resolved by prematurely coupling Simulation to a particular engine, solver, persistence mechanism, transport protocol, or hardware platform.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Established:

* Simulation as the computational realization domain for semantic models;
* distinction between system, model, simulation, and observation;
* simulation state;
* simulation instances;
* environments and scenarios;
* parameters and configuration;
* temporal semantics;
* continuous, discrete, hybrid, deterministic, and stochastic simulation;
* agent, field, particle, and event-driven simulation;
* multiscale, distributed, parallel, and co-simulation;
* events, interventions, checkpoints, branches, replay, and counterfactuals;
* ensembles and parameter sweeps;
* calibration, verification, and validation;
* observations and outputs;
* streaming and semantic deltas;
* uncertainty and sensitivity;
* provenance and reproducibility;
* model reduction and surrogate models;
* simulation equivalence;
* Semantic Hypergraph integration;
* MLIR integration;
* provider and representation independence.

---

# Definition Authority

This document is the normative semantic definition of the SCR Simulation domain.

Implementation documents, source code, simulation engines, provider interfaces, examples, benchmarks, and generated artifacts MUST NOT redefine this domain without an explicit semantic revision.

---

# Definition Principle

> **Simulation defines the computational realization of semantic models as executable experiments, trajectories, observations, and evolving states. It does not prescribe the particular engine, algorithm, representation, storage mechanism, transport mechanism, or hardware used to perform that realization.**

The fundamental SCR separation is:

```text
SYSTEM / PHENOMENON
        ↓
SEMANTIC MODEL
        ↓
SIMULATION MODEL
        ↓
SIMULATION STATE
        ↓
SIMULATION EVOLUTION
        ↓
EXECUTION
        ↓
OBSERVATION
        ↓
ANALYSIS
```

The simulation is an executable realization of meaning.

The execution substrate is replaceable.

The semantic model remains authoritative.

---

# Compact Conceptual Model

```text
                       SIMULATION
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
        MODEL          SCENARIO          STATE
          │                │                │
          └────────────────┼────────────────┘
                           ▼
                      ENVIRONMENT
                           │
                           ▼
                    EVOLUTION / EVENTS
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
           TRAJECTORY     DELTA       OBSERVATION
              │            │            │
              └────────────┼────────────┘
                           ▼
                    CHECKPOINT / BRANCH
                           │
                           ▼
                       ANALYSIS
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
      VALIDATION      COMPARISON       STREAMING
```

Simulation is therefore the layer at which the semantic universe becomes capable of **running experiments on itself**: models can be instantiated, states can evolve, trajectories can branch, interventions can be applied, observations can be streamed, and alternative computational realizations can be compared without making any particular simulation engine the source of truth.
