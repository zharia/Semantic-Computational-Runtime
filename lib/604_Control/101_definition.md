---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-CONTROL
name: Control

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
---

# Control

## Definition

Control is the semantic computational domain concerned with **influencing the evolution of a system through the selection, generation, application, and adaptation of interventions relative to desired conditions, constraints, observations, and system dynamics**.

Control describes the computational relationship between:

* system state;
* desired state or objectives;
* observations;
* available interventions;
* constraints;
* system dynamics;
* resulting state evolution.

Control is therefore not synonymous with:

* PID control;
* robotics;
* automation;
* feedback;
* optimization;
* reinforcement learning;
* actuation;
* regulation;
* physical control systems.

Those are implementations, specializations, or applications of control semantics.

The fundamental control relationship is:

```text
System
   ↓
Observation
   ↓
State / Estimate
   ↓
Objective / Reference
   ↓
Controller
   ↓
Intervention
   ↓
System Dynamics
   ↓
New State
   ↺
```

Control is fundamentally concerned with **purposeful influence over state evolution**.

---

# Semantic Model

A control system can be represented conceptually as:

```text
C = (S, O, R, G, A, K, U, D, T, Q, P)
```

where:

* `S` = system state;
* `O` = observations;
* `R` = reference or desired condition;
* `G` = goals/objectives;
* `A` = available actions/interventions;
* `K` = controller or control law;
* `U` = selected control input;
* `D` = system dynamics;
* `T` = temporal semantics;
* `Q` = constraints and resource conditions;
* `P` = provenance.

Not every control system requires every component.

Control may be:

* open-loop;
* closed-loop;
* feedback;
* feed-forward;
* reactive;
* predictive;
* model-based;
* model-free;
* deterministic;
* stochastic;
* continuous;
* discrete;
* hybrid;
* centralized;
* distributed;
* hierarchical;
* adaptive;
* optimal;
* robust;
* learned.

---

# Scope

SCR Control includes semantics for:

* control systems;
* controllers;
* control laws;
* control inputs;
* interventions;
* actuators;
* references;
* setpoints;
* targets;
* objectives;
* constraints;
* feedback;
* feed-forward control;
* open-loop control;
* closed-loop control;
* regulation;
* tracking;
* stabilization;
* trajectory control;
* state control;
* output control;
* predictive control;
* model-based control;
* model-free control;
* optimal control;
* robust control;
* adaptive control;
* nonlinear control;
* linear control;
* discrete control;
* continuous control;
* hybrid control;
* distributed control;
* multi-agent control;
* hierarchical control;
* supervisory control;
* safety control;
* constraint enforcement;
* resource control;
* learned control;
* neural control;
* evolutionary control;
* control estimation;
* observability;
* controllability;
* stability;
* reachability;
* viability;
* intervention streams;
* control deltas;
* provenance;
* simulation and execution.

---

# Controlled System

A controlled system is a semantic system whose state evolution may be influenced by one or more interventions.

Conceptually:

```text
        ┌──────────────────────┐
        │       System         │
        └──────────┬───────────┘
                   │
                State
                   │
                   ▼
              Observation
                   │
                   ▼
             Controller
                   │
               Control
                Input
                   │
                   ▼
        ┌──────────────────────┐
        │       System         │
        └──────────────────────┘
```

The controlled system may be:

* physical;
* biological;
* simulated;
* economic;
* ecological;
* computational;
* social;
* informational;
* distributed.

---

# Control State

Control state represents the state relevant to determining interventions.

It MAY include:

* measured state;
* estimated state;
* controller state;
* accumulated error;
* historical observations;
* internal model;
* reference trajectory;
* constraint state.

Control state MUST remain distinguishable from the complete underlying system state.

---

# Observation

Control systems may receive observations from:

* sensors;
* Fields;
* Agents;
* simulations;
* databases;
* streams;
* internal state;
* external systems.

Observation semantics belong to Perception and Data where appropriate.

Control consumes observations but does not redefine their semantics.

---

# State Estimation

A controller may operate on an estimated state when the true system state is unavailable.

```text
Actual State
     ↓
Observation
     ↓
State Estimator
     ↓
Estimated State
     ↓
Controller
```

Estimated state MUST remain distinguishable from directly observed and actual state.

---

# Reference

A reference defines a desired or target condition against which system behaviour may be evaluated.

References MAY specify:

* target state;
* target output;
* target trajectory;
* target region;
* desired rate;
* acceptable range;
* temporal objective.

A reference need not be a single scalar setpoint.

---

# Goal

A control goal specifies a desired property of system evolution.

Goals MAY concern:

* state;
* trajectory;
* stability;
* energy;
* resource usage;
* safety;
* performance;
* time;
* multiple objectives.

Control goals may be inherited from Agents, Optimization, Simulation, or other domains.

---

# Objective

An objective defines a criterion used to evaluate control behaviour.

Examples include:

* tracking error;
* energy expenditure;
* response time;
* stability;
* safety margin;
* resource consumption;
* trajectory deviation.

Objectives may be:

* scalar;
* vector-valued;
* lexicographic;
* constrained;
* probabilistic.

---

# Control Input

A control input is a semantic intervention supplied to a controlled system.

```text
Controller
    ↓
Control Input
    ↓
System
```

Control inputs MAY affect:

* forces;
* positions;
* velocities;
* parameters;
* resources;
* signals;
* fields;
* agents;
* topology;
* morphology;
* computational processes.

A control input represents intended intervention, not necessarily resulting state change.

---

# Intervention

An intervention is an explicit attempt to alter the evolution of a system.

Interventions MAY be:

* direct;
* indirect;
* physical;
* informational;
* structural;
* environmental;
* computational.

An intervention MUST remain distinguishable from its consequence.

---

# Actuation

Actuation is the realization of a control input against a controlled system.

Actuation may involve:

* motors;
* forces;
* valves;
* signals;
* software operations;
* environmental changes;
* resource allocation.

Control semantics describe the intended intervention.

Actuation describes its realization.

---

# Feedback

Feedback occurs when information resulting from system behaviour influences subsequent control decisions.

```text
        ┌──────────────────────┐
        │       System         │
        └──────────┬───────────┘
                   │
                   ▼
              Observation
                   │
                   ▼
              Controller
                   │
                   ▼
              Intervention
                   │
                   └──────────────→ System
```

Feedback may be:

* negative;
* positive;
* delayed;
* nonlinear;
* adaptive;
* stochastic.

---

# Feed-Forward Control

Feed-forward control selects interventions based on available information without requiring the intervention to depend directly on the resulting system response.

Feed-forward and feedback control MAY be composed.

```text
Prediction / Context
        ↓
Feed-Forward
        ↓
Control Input
        ↑
Feedback Controller
```

---

# Open-Loop Control

Open-loop control generates interventions without using subsequent system observations to modify the current control sequence.

Open-loop control remains valid where:

* system behaviour is sufficiently known;
* feedback is unavailable;
* timing constraints prevent feedback;
* the intervention itself is predetermined.

---

# Closed-Loop Control

Closed-loop control uses observations of system behaviour to modify subsequent interventions.

Closed-loop control is therefore a specialization of feedback control.

---

# Regulation

Regulation maintains a system within a desired region, range, condition, or operating regime.

Regulation may concern:

* temperature;
* pressure;
* velocity;
* population;
* resource level;
* computational load;
* ecological state.

---

# Tracking

Tracking attempts to make a system follow a desired trajectory, signal, or evolving reference.

```text
Reference Trajectory
        ↓
     Controller
        ↓
   System Trajectory
        ↓
     Comparison
        ↺
```

Tracking differs from static regulation because the desired condition may itself evolve.

---

# Stabilization

Stabilization seeks to maintain or return a system to a desired stable region or operating condition.

Stability semantics belong primarily to Dynamics and Mathematics.

Control defines how interventions are used to achieve or maintain stability.

---

# Trajectory Control

Trajectory control concerns influencing the path of a system through state space.

A trajectory may exist over:

* physical space;
* configuration space;
* parameter space;
* semantic state space;
* graph state;
* morphological space.

---

# State Control

State control directly or indirectly influences system state.

A controller may operate over:

```text
Current State
     ↓
Desired State
     ↓
Control Law
     ↓
Intervention
     ↓
State Transition
```

---

# Output Control

A controller may regulate an observable output without directly controlling the complete internal state.

Output control MUST preserve the distinction between:

* internal state;
* observable output;
* controlled variable.

---

# Control Law

A control law defines the semantic mapping from available control information to intervention.

Conceptually:

```text
(State, Observation, Reference, Context)
                  ↓
             Control Law
                  ↓
             Intervention
```

The control law may be:

* mathematical;
* symbolic;
* procedural;
* learned;
* neural;
* optimized;
* evolutionary.

---

# PID Control

PID control is one particular control-law family based on:

* proportional response;
* integral response;
* derivative response.

PID is a provider or specialization of Control.

The Control domain MUST NOT be defined in terms of PID.

---

# Model-Based Control

A model-based controller uses an explicit model of system behaviour.

```text
Current State
     ↓
System Model
     ↓
Predicted Outcomes
     ↓
Control Selection
```

The model may originate from:

* Physics;
* Dynamics;
* Simulation;
* learned models;
* empirical models.

---

# Model-Free Control

A controller may operate without an explicit semantic model of system dynamics.

It may instead use:

* observations;
* historical outcomes;
* policies;
* learned mappings;
* adaptive mechanisms.

Model-free control remains a valid semantic control strategy.

---

# Predictive Control

Predictive control selects interventions using predicted future system behaviour.

Conceptually:

```text
Current State
     ↓
Predict Future
     ↓
Evaluate Candidate Actions
     ↓
Select Intervention
     ↓
Execute
     ↓
Observe
     ↺
```

Predictive control naturally composes with Simulation and Dynamics.

---

# Optimal Control

Optimal control selects interventions according to an objective and constraints.

Optimization semantics belong to the Optimization domain.

Control defines the relationship between optimization and system intervention.

---

# Robust Control

Robust control seeks acceptable behaviour despite uncertainty, disturbances, model mismatch, or variation.

Robustness MAY concern:

* parameter uncertainty;
* environmental variation;
* observation noise;
* model error;
* actuator variation.

---

# Adaptive Control

Adaptive control changes controller behaviour in response to changes in the controlled system or environment.

```text
System
  ↓
Observation
  ↓
Controller
  ↓
Adaptation
  ↺
```

Adaptation may modify:

* parameters;
* control law;
* model;
* policy;
* constraints.

---

# Learned Control

A control policy MAY be learned from:

* data;
* simulation;
* experience;
* optimization;
* reinforcement;
* evolutionary processes.

Learning mechanisms belong to Neural or Learning domains where appropriate.

Control defines the semantic role of the resulting policy.

---

# Neural Control

Neural computation MAY implement a controller:

```text
Observation / State
        ↓
Neural Computation
        ↓
Control Policy
        ↓
Intervention
```

Neural computation is an implementation mechanism.

Control semantics remain independent of Neural.

---

# Agent Control

Agents may act as controllers or be controlled by external controllers.

```text
Agent
  ↓
Decision
  ↓
Control Action
  ↓
Environment
```

Conversely:

```text
Controller
    ↓
Agent
    ↓
Behaviour
```

Control does not require agency.

---

# Multi-Agent Control

Control may operate over multiple interacting agents.

It may address:

* formation;
* coordination;
* consensus;
* distributed optimization;
* cooperation;
* competition;
* collective stability.

Higher-order control relationships SHOULD be representable through the Semantic Hypergraph.

---

# Distributed Control

Distributed control allows multiple controllers or computational entities to coordinate interventions.

```text
        Shared Environment
        /       |       \
       ↓        ↓        ↓
 Controller A Controller B Controller C
       ↕        ↕        ↕
        Distributed State
```

Distributed control MUST preserve semantic coordination and temporal relationships independently of the communication transport.

---

# Hierarchical Control

Control systems MAY contain multiple levels:

```text
Strategic Control
       ↓
Supervisory Control
       ↓
Operational Control
       ↓
Actuation
```

Higher-level controllers may define objectives while lower-level controllers realize them.

---

# Constraint Control

Control may operate subject to constraints including:

* physical limits;
* safety limits;
* resource limits;
* actuator limits;
* topology;
* geometry;
* morphology;
* temporal constraints;
* policy restrictions.

Constraints MUST remain explicit.

---

# Safety Control

Safety control seeks to keep system evolution within declared safe regions.

Safety semantics may include:

* forbidden states;
* forbidden transitions;
* safety margins;
* emergency interventions;
* fallback policies.

Safety constraints MUST NOT be silently overridden by optimization objectives.

---

# Reachability

Reachability describes whether a desired state or region can be reached from a given state under available interventions and constraints.

```text
Initial State
     ↓
Available Interventions
     ↓
Reachable Region
     ↓
Target
```

Reachability is closely related to Dynamics and Mathematics.

---

# Controllability

Controllability describes whether a system can be driven between relevant states or regions through available interventions under declared assumptions.

Controllability is a semantic property of the system-control relationship.

---

# Observability

Observability describes whether relevant system state can be inferred from available observations.

```text
System State
     ↓
Observation Process
     ↓
Available Information
```

Observability is related to Perception and Dynamics.

It MUST remain distinguishable from sensor implementation.

---

# Viability

Viability concerns whether a system can remain within an acceptable region of state space through available interventions.

```text
Safe / Viable Region
┌────────────────────────┐
│                        │
│     System State       │
│         ↕              │
│    Control Actions     │
│                        │
└────────────────────────┘
```

---

# Stability

Control may seek to establish or preserve stability.

Stability itself belongs to Dynamics and Mathematics.

Control specifies the intervention strategy used to influence stability.

---

# Disturbances

A disturbance is an external or endogenous influence affecting system evolution that is not treated as the selected control input.

Disturbances MAY be:

* deterministic;
* stochastic;
* adversarial;
* environmental;
* structural;
* computational.

Control systems MAY compensate for disturbances.

---

# Constraints vs Objectives

Control MUST distinguish:

```text
Constraints
    ↓
What is permitted

Objectives
    ↓
What is preferred
```

A system MUST NOT treat an objective as permission to violate a declared hard constraint.

---

# Control and Dynamics

Dynamics defines how system state evolves.

Control influences that evolution.

```text
Dynamics
   ↑
   │
Intervention
   ↑
Controller
```

The distinction is fundamental:

> Dynamics describes evolution. Control describes purposeful influence over evolution.

---

# Control and Physics

Physics defines physical laws and constraints.

Control determines interventions applied to physical systems.

```text
Controller
    ↓
Intervention
    ↓
Physics
    ↓
Physical Evolution
```

Control does not override physical law.

---

# Control and Simulation

Simulation provides an environment in which control strategies may be:

* evaluated;
* compared;
* optimized;
* trained;
* validated;
* stress-tested.

Simulation MAY therefore become a computational laboratory for Control.

---

# Control and Fields

Fields may represent:

* controlled quantities;
* control inputs;
* environmental state;
* cost;
* risk;
* gradients;
* potential functions.

Control MAY therefore transform or act upon fields.

---

# Control and Geometry

Control may influence:

* position;
* orientation;
* trajectory;
* deformation;
* spatial configuration.

Geometry provides spatial semantics.

Control provides intervention semantics.

---

# Control and Topology

Control may influence systems whose state depends upon:

* connectivity;
* reachability;
* network structure;
* neighbourhood;
* topology.

Topology-changing interventions MUST preserve explicit topological semantics.

---

# Control and Morphology

Morphology may constrain control through:

* actuator placement;
* available movement;
* structural limits;
* sensor arrangement;
* mechanical configuration.

Control may also alter morphology through:

* growth;
* reconfiguration;
* construction;
* adaptation.

Thus:

```text
Morphology ↔ Control
```

may be bidirectional.

---

# Control and Perception

Perception and Control form a closed computational loop:

```text
Environment
     ↓
Observation
     ↓
Perception
     ↓
State / Interpretation
     ↓
Control
     ↓
Intervention
     ↓
Environment
     ↺
```

Perception determines available information.

Control determines purposeful intervention.

Neither domain subsumes the other.

---

# Control and Agents

Agents may use Control to influence their environment.

Control may also operate without agents.

A thermostat, for example, can implement control without requiring agency.

---

# Control and Neural

Neural systems may implement control policies.

Control remains semantically independent of the neural implementation.

---

# Semantic Hypergraph Integration

Control SHOULD integrate directly with the Semantic Hypergraph.

A control system may contain:

```text
Control System
├── Controlled System
├── State
├── Observation
├── Reference
├── Goal
├── Objective
├── Constraint
├── Controller
├── Control Law
├── Intervention
├── Actuation
├── Disturbance
├── Response
├── Provenance
└── Temporal State
```

Relationships between:

* observations;
* controllers;
* interventions;
* system transitions;
* objectives;
* constraints

SHOULD be represented explicitly.

Higher-order control relationships MUST remain representable.

---

# Control State Deltas

Control MAY produce semantic deltas representing:

* controller state changes;
* reference changes;
* objective changes;
* policy changes;
* intervention changes;
* constraint changes.

Control deltas are semantic state changes, not storage-level diffs.

---

# Control Streams

Control may operate continuously over streams:

```text
Observation Stream
        ↓
Control Transformation
        ↓
Intervention Stream
        ↓
System
        ↓
Observation Stream
```

Streams may support:

* real-time control;
* distributed control;
* simulation;
* monitoring;
* adaptive systems.

Transport mechanisms remain implementation concerns.

---

# Provenance

Control actions SHOULD preserve provenance including:

* observation inputs;
* controller version;
* policy;
* reference;
* objectives;
* constraints;
* model;
* selected intervention;
* execution context;
* resulting state;
* timestamps.

This enables causal reconstruction of control behaviour.

---

# Control Equivalence

Two controllers MAY be semantically equivalent under a declared control contract even when their internal implementations differ.

Equivalence may concern:

* exact control input;
* trajectory;
* bounded error;
* stability;
* safety;
* reachable set;
* observational outcome;
* behavioural result.

Equivalence MUST specify the relevant guarantees.

---

# Representation Independence

Control semantics MUST remain independent of:

* motor APIs;
* actuator drivers;
* robotics middleware;
* PID libraries;
* PLC implementations;
* hardware registers;
* network protocols;
* tensor layouts;
* memory structures.

These are implementation mechanisms.

---

# Provider Independence

Control providers MAY include:

* robotics frameworks;
* control libraries;
* optimization engines;
* neural controllers;
* simulation engines;
* industrial control systems;
* hardware controllers.

Providers implement declared control semantics.

They MUST NOT redefine them.

---

# Runtime Semantics

The SCR runtime MAY:

* schedule controllers;
* route observations;
* resolve references;
* execute control laws;
* select providers;
* enforce constraints;
* manage control state;
* coordinate distributed controllers;
* stream interventions;
* monitor safety;
* adapt execution;
* checkpoint control state;
* record provenance.

Runtime optimization MUST preserve control contracts.

---

# MLIR Representation

Control semantics MAY be represented through MLIR operations, types, interfaces, and transformations.

Potential representations include:

* controller operations;
* state/control types;
* intervention operations;
* constraint interfaces;
* feedback relationships;
* control loops;
* optimization interfaces.

Conceptually:

```text
Control Semantics
       ↓
Control Representation
       ↓
MLIR
       ↓
Lowering
       ↓
Runtime / Provider
       ↓
Physical / Simulated / Computational System
```

MLIR provides compilation infrastructure.

It does not define control semantics.

---

# Capabilities

Control operations MAY declare capabilities including:

* `Feedback`
* `FeedForward`
* `ClosedLoop`
* `OpenLoop`
* `Reactive`
* `Predictive`
* `ModelBased`
* `ModelFree`
* `Adaptive`
* `Optimal`
* `Robust`
* `Safe`
* `Constrained`
* `Continuous`
* `Discrete`
* `Hybrid`
* `Distributed`
* `Hierarchical`
* `Deterministic`
* `Stochastic`
* `Streamable`
* `Parallelizable`
* `Differentiable`
* `Learnable`
* `Observable`
* `Controllable`.

---

# Performance Semantics

Control performance may depend upon:

* observation latency;
* control latency;
* actuator latency;
* sampling rate;
* computation time;
* communication delay;
* model complexity;
* controller complexity;
* system dynamics.

Performance MUST remain distinct from control semantics.

Timing guarantees MUST be explicit where they affect stability or safety.

---

# Errors and Failure Semantics

Control errors MAY include:

* invalid control input;
* unavailable actuator;
* invalid reference;
* constraint violation;
* unstable controller;
* insufficient observability;
* insufficient controllability;
* model mismatch;
* delayed observation;
* provider failure;
* resource exhaustion;
* unsafe state;
* communication failure.

Safety-critical failures SHOULD have explicit fallback semantics.

---

# Security and Isolation

Control systems may influence physical, computational, or economic systems.

Implementations SHOULD support:

* capability restrictions;
* intervention authorization;
* safety boundaries;
* resource limits;
* controller isolation;
* provenance;
* auditability;
* fail-safe behaviour.

Semantic control authority MUST NOT imply unrestricted execution authority.

---

# Standards and Interoperability

SCR Control SHOULD reuse established standards wherever applicable.

Relevant standards MAY include:

* URI/IRI;
* JSON/JSON-LD;
* RDF/RDF-star;
* established control-system representations;
* established robotics interfaces;
* established industrial control standards;
* ISO 8601 / RFC 3339;
* UCUM;
* established provenance standards;
* established model-interchange standards.

External standards provide interoperability.

SCR Control remains authoritative over control semantics.

---

# Expected Subdomains

The following structure is illustrative:

```text
control/
├── control-core
├── system
├── controller
├── control-law
├── state
├── observation
├── estimation
├── reference
├── target
├── goal
├── objective
├── constraint
├── intervention
├── control-input
├── actuation
├── feedback
├── feed-forward
├── open-loop
├── closed-loop
├── regulation
├── tracking
├── stabilization
├── trajectory
├── state-control
├── output-control
├── predictive
├── model-based
├── model-free
├── optimal
├── robust
├── adaptive
├── nonlinear
├── linear
├── continuous
├── discrete
├── hybrid
├── distributed
├── multi-agent
├── hierarchical
├── supervisory
├── safety
├── reachability
├── controllability
├── observability
├── viability
├── disturbance
├── neural
├── learned
├── simulation
├── field
├── geometry
├── topology
├── morphology
├── stream
├── delta
├── provenance
├── equivalence
├── capability
└── provider
```

This structure is illustrative and does not require immediate implementation of every subdomain.

---

# Invariants

## CONTROL-INV-001 — Semantic Primacy

Control semantics MUST remain independent of implementation technology.

## CONTROL-INV-002 — Intervention Integrity

An intervention MUST remain distinguishable from its resulting system state.

## CONTROL-INV-003 — State Integrity

Controlled system state MUST remain distinguishable from controller state.

## CONTROL-INV-004 — Observation Integrity

Observed or estimated state MUST remain distinguishable from actual system state.

## CONTROL-INV-005 — Objective Integrity

Objectives MUST remain distinguishable from hard constraints.

## CONTROL-INV-006 — Constraint Integrity

Declared hard constraints MUST NOT be silently violated by optimization or policy selection.

## CONTROL-INV-007 — Reference Integrity

References and targets MUST remain semantically explicit.

## CONTROL-INV-008 — Feedback Integrity

Feedback relationships MUST preserve their temporal and causal semantics.

## CONTROL-INV-009 — Temporal Integrity

Control timing MUST remain distinct from wall-clock execution unless explicitly coupled.

## CONTROL-INV-010 — Causal Integrity

Control actions SHOULD preserve causal provenance linking observations, decisions, interventions, and outcomes.

## CONTROL-INV-011 — Model Independence

Control MUST remain meaningful with or without an explicit system model.

## CONTROL-INV-012 — Provider Independence

Control providers MUST NOT become semantic authorities.

## CONTROL-INV-013 — Representation Independence

Control meaning MUST remain independent of actuator, driver, protocol, or memory representation.

## CONTROL-INV-014 — Domain Independence

Control MUST remain usable outside physical robotics or automation.

## CONTROL-INV-015 — Stability Integrity

Where stability guarantees are declared, implementation transformations MUST preserve the relevant stability contract.

## CONTROL-INV-016 — Safety Integrity

Safety constraints MUST remain explicit and enforceable.

## CONTROL-INV-017 — Equivalence Integrity

Controller substitution MUST require an appropriate semantic equivalence guarantee.

## CONTROL-INV-018 — Hardware Independence

Control semantics MUST remain independent of physical execution hardware while allowing hardware-aware realization.

---

# Domain Relationships

| Domain       | Relationship   | Meaning                                                                                |
| ------------ | -------------- | -------------------------------------------------------------------------------------- |
| Core         | REFINES        | Control specializes state transitions, operations, constraints, and temporal semantics |
| Data         | COMPOSES       | Control consumes and produces semantic information                                     |
| Mathematics  | DEPENDS_ON     | Control uses mathematical models, optimization, stability, and estimation              |
| Fields       | INTERACTS_WITH | Fields may represent controlled quantities, environments, and interventions            |
| Graphs       | COMPOSES       | Control may operate over networks and relational structures                            |
| Geometry     | CONTROLS       | Control may influence spatial state and trajectories                                   |
| Topology     | CONSTRAINS     | Connectivity and reachability may constrain interventions                              |
| Morphology   | CONSTRAINS     | Form and structure may constrain actuation and control                                 |
| Physics      | CONSTRAINS     | Physical laws constrain achievable interventions and outcomes                          |
| Dynamics     | INTERACTS_WITH | Dynamics defines the response to control interventions                                 |
| Simulation   | EXECUTES_IN    | Simulation provides computational environments for control                             |
| Agents       | SERVES         | Agents may use or provide control                                                      |
| Neural       | IMPLEMENTS     | Neural computation may implement control policies                                      |
| Perception   | CONSUMES       | Control uses observations and perceptual representations                               |
| Optimization | COMPOSES       | Optimization may select or tune control strategies                                     |
| Rendering    | OBSERVES       | Rendered system state may support observation and feedback                             |

These relationships describe semantic relationships and do not automatically imply implementation dependencies.

---

# Testing Requirements

Control implementations MUST support the SCR testing hierarchy:

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

* control-law correctness;
* state estimation;
* reference tracking;
* regulation;
* stability;
* feedback;
* feed-forward behaviour;
* disturbances;
* constraint enforcement;
* safety;
* reachability;
* controllability;
* observability;
* deterministic behaviour;
* stochastic behaviour;
* adaptive behaviour;
* predictive behaviour;
* distributed coordination;
* controller equivalence;
* latency;
* provider substitution.

---

# Validation Requirements

Control validation SHOULD determine whether:

1. interventions satisfy their declared semantics;
2. constraints are respected;
3. references are interpreted correctly;
4. feedback relationships are correct;
5. controller state is valid;
6. observations and estimates are correctly interpreted;
7. declared stability properties hold;
8. safety properties hold;
9. controller substitutions preserve required equivalence;
10. provenance is preserved.

Validation SHOULD distinguish:

* controller correctness;
* system-model correctness;
* actuator correctness;
* runtime correctness;
* physical execution correctness.

---

# Function-Level Requirements

Every Control function MUST specify, where applicable:

* controlled system;
* state;
* observations;
* reference;
* objective;
* constraints;
* available interventions;
* control law;
* output;
* temporal semantics;
* feedback dependencies;
* determinism;
* stochasticity;
* stability guarantees;
* safety guarantees;
* side effects;
* resource requirements;
* provenance;
* errors;
* capabilities;
* equivalence requirements.

---

# Completeness Criteria

The Control domain definition is complete only when:

* controlled systems are representable;
* control state is explicit;
* observations are explicit;
* references are explicit;
* goals and objectives are representable;
* constraints are explicit;
* control inputs are first-class;
* interventions are first-class;
* actuation is distinguishable from intervention;
* feedback is representable;
* feed-forward control is representable;
* open-loop control is representable;
* closed-loop control is representable;
* regulation is representable;
* tracking is representable;
* stabilization is representable;
* trajectory control is representable;
* state and output control are representable;
* predictive control is representable;
* model-based and model-free control are representable;
* optimal control is representable;
* robust control is representable;
* adaptive control is representable;
* learned and neural control are representable;
* distributed control is representable;
* hierarchical control is representable;
* safety control is explicit;
* reachability is representable;
* controllability is representable;
* observability is representable;
* viability is representable;
* disturbances are representable;
* control streams are representable;
* control deltas are representable;
* provenance is preserved;
* semantic equivalence is expressible;
* Semantic Hypergraph integration exists;
* provider independence is maintained;
* representation independence is maintained;
* MLIR remains compilation infrastructure rather than semantic authority.

---

# Architectural Rules

1. **Control MUST be defined by purposeful influence over system evolution, not by a particular controller algorithm.**
2. **Intervention MUST remain distinct from outcome.**
3. **Controller state MUST remain distinct from controlled-system state.**
4. **Observation and estimation MUST remain distinguishable from actual state.**
5. **Objectives MUST remain distinguishable from hard constraints.**
6. **Hard constraints MUST NOT be silently sacrificed to improve an objective.**
7. **Control MUST remain meaningful without requiring physical embodiment.**
8. **Control MUST remain meaningful without requiring Agents.**
9. **Control MUST remain meaningful without requiring Neural computation.**
10. **Feedback MUST preserve temporal and causal semantics.**
11. **Control timing MUST be explicit where it affects correctness, stability, or safety.**
12. **Control MAY operate over Fields, Graphs, Geometry, Topology, Morphology, Agents, and Simulation state.**
13. **Control MUST integrate with Dynamics rather than redefining Dynamics.**
14. **Physics constrains physical control but does not define control semantics.**
15. **Simulation may evaluate control strategies but does not define control semantics.**
16. **External control libraries and hardware systems MUST be treated as providers.**
17. **Controller substitution MUST require appropriate equivalence guarantees.**
18. **Safety constraints MUST be explicit and enforceable.**
19. **Hardware-aware optimization MUST preserve control contracts.**
20. **MLIR MUST remain a representation and compilation substrate rather than semantic authority over control.**

---

# Open Semantic Questions

The following remain intentionally open:

* How should a general control contract formally specify acceptable outcomes?
* How should control authority be represented?
* How should soft objectives and hard constraints interact formally?
* How should multiple conflicting objectives be represented?
* How should controller state be represented in the Semantic Hypergraph?
* How should interventions be represented when they modify graph topology?
* How should control operate over continuously evolving Fields?
* How should control interact with Morphological adaptation?
* How should controllability be represented for nonlinear systems?
* How should reachability be represented over arbitrary semantic state spaces?
* How should safety regions be expressed independently of a particular mathematical representation?
* How should uncertain observations propagate into control decisions?
* How should uncertain actions and outcomes be represented?
* How should distributed controllers preserve causal consistency?
* How should control policies learned by Neural systems expose semantic guarantees?
* How should adaptive controllers preserve reproducibility?
* How should simulation-derived controllers declare their transfer guarantees to physical systems?
* How should control contracts express acceptable latency and timing bounds?
* How should controller equivalence be formally established?
* How should competing controllers be composed?
* How should the runtime mediate autonomous controllers without becoming the semantic authority over their goals?

These questions SHOULD remain open until sufficient semantic requirements exist to resolve them.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Established:

* controlled systems;
* control state;
* observations and state estimation;
* references;
* goals and objectives;
* control inputs;
* interventions;
* actuation;
* feedback;
* feed-forward;
* open-loop and closed-loop control;
* regulation;
* tracking;
* stabilization;
* trajectory control;
* control laws;
* model-based and model-free control;
* predictive control;
* optimal control;
* robust control;
* adaptive control;
* learned and neural control;
* multi-agent and distributed control;
* hierarchical control;
* constraint and safety control;
* reachability;
* controllability;
* observability;
* viability;
* disturbances;
* relationships to Dynamics, Physics, Simulation, Agents, Neural, Perception, Fields, Geometry, Topology, and Morphology;
* control streams and deltas;
* provenance;
* semantic equivalence;
* Semantic Hypergraph integration;
* provider independence;
* MLIR integration.

---

# Definition Authority

This document is the normative semantic definition of the SCR Control domain.

Implementation documents, source code, robotics frameworks, industrial controllers, PID libraries, neural controllers, simulation engines, hardware interfaces, examples, benchmarks, and generated artifacts MUST NOT redefine this domain without an explicit semantic revision.

---

# Definition Principle

> **Control is the semantic process of intentionally influencing system evolution through interventions selected according to observations, objectives, constraints, and models or policies.**

The fundamental loop is:

```text
                 ┌───────────────────────┐
                 │        SYSTEM         │
                 └───────────┬───────────┘
                             │
                             ▼
                        OBSERVATION
                             │
                             ▼
                     STATE / ESTIMATE
                             │
                  ┌──────────┴──────────┐
                  │                     │
               REFERENCE             CONTEXT
                  │                     │
                  └──────────┬──────────┘
                             ▼
                         CONTROLLER
                             │
                             ▼
                       INTERVENTION
                             │
                             ▼
                          DYNAMICS
                             │
                             ▼
                       SYSTEM STATE
                             │
                             └──────────────↺
```

The deeper SCR relationship is:

```text
         OBSERVE
            │
            ▼
        PERCEPTION
            │
            ▼
      REPRESENTATION
            │
            ▼
         CONTROL
            │
            ▼
       INTERVENTION
            │
            ▼
         DYNAMICS
            │
            ▼
      SYSTEM EVOLUTION
            │
            └──────────→ OBSERVE
```

Control therefore provides the semantic bridge between **knowing what is happening and intentionally influencing what happens next**.
