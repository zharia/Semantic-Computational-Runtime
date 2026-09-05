---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-OPTIMIZATION
name: Optimization

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-MATHEMATICS

authority: SCR
domain: semantic-library
------------------------

# Optimization

## Definition

Optimization is the semantic computational domain concerned with **selecting, constructing, or adapting solutions, configurations, trajectories, policies, or transformations according to declared objectives, constraints, preferences, and available alternatives**.

Optimization answers the semantic question:

> **Given a space of possible alternatives, which alternatives best satisfy the declared objectives and constraints?**

Optimization therefore defines the semantics of:

* objectives;
* decision variables;
* feasible regions;
* constraints;
* preferences;
* costs;
* utilities;
* trade-offs;
* optimality;
* approximation;
* search;
* solution selection.

Optimization is not synonymous with:

* numerical optimization libraries;
* gradient descent;
* linear programming;
* machine learning;
* control;
* scheduling;
* compiler optimization;
* evolutionary algorithms.

Those are particular applications, methods, or implementations of optimization semantics.

---

# Semantic Model

An optimization problem can be represented conceptually as:

```text id="xj9w5r"
O = (X, F, C, J, P, R, S, Q)
```

where:

* `X` = decision space;
* `F` = feasible region;
* `C` = constraints;
* `J` = objective function or objective relation;
* `P` = preferences;
* `R` = result/solution semantics;
* `S` = solution-selection semantics;
* `Q` = provenance, uncertainty, and quality information.

A problem MAY contain multiple objectives, multiple feasible solutions, or no unique optimum.

---

# Fundamental Optimization Relationship

```text id="f7m2nz"
              Decision Space
                    │
                    ▼
             Candidate Solutions
                    │
                    ▼
                Constraints
                    │
                    ▼
              Feasible Solutions
                    │
                    ▼
                 Objectives
                    │
                    ▼
             Evaluation / Ranking
                    │
                    ▼
              Selected Solution
```

Optimization therefore separates:

```text id="4c3h7a"
WHAT IS POSSIBLE?
        ↓
WHAT IS PREFERRED?
        ↓
WHICH POSSIBILITY BEST SATISFIES THE PREFERENCE?
```

---

# Scope

SCR Optimization includes semantics for:

* decision variables;
* decision spaces;
* candidate solutions;
* feasible regions;
* constraints;
* objectives;
* objective functions;
* cost functions;
* utility functions;
* preferences;
* scalarization;
* multi-objective optimization;
* Pareto optimality;
* trade-offs;
* optimality;
* local optima;
* global optima;
* constrained optimization;
* unconstrained optimization;
* discrete optimization;
* continuous optimization;
* mixed optimization;
* combinatorial optimization;
* convex optimization;
* non-convex optimization;
* linear optimization;
* nonlinear optimization;
* stochastic optimization;
* robust optimization;
* dynamic optimization;
* optimal control;
* trajectory optimization;
* parameter optimization;
* structural optimization;
* topology optimization;
* morphological optimization;
* resource optimization;
* scheduling;
* allocation;
* search;
* sampling;
* approximation;
* surrogate optimization;
* evolutionary optimization;
* gradient-based optimization;
* gradient-free optimization;
* Bayesian optimization;
* population-based optimization;
* distributed optimization;
* online optimization;
* adaptive optimization;
* differentiable optimization;
* optimization under uncertainty;
* sensitivity;
* solution quality;
* convergence;
* termination;
* provenance;
* reproducibility.

---

# Decision Variables

A decision variable represents a semantic quantity whose value may be selected or modified by an optimization process.

Decision variables MAY include:

* scalar quantities;
* vectors;
* tensors;
* parameters;
* graph structures;
* topology;
* geometry;
* morphology;
* trajectories;
* control policies;
* resource allocations;
* schedules;
* neural parameters;
* simulation parameters.

A decision variable MUST remain distinguishable from the implementation variable used by a solver.

---

# Decision Space

The decision space defines the alternatives over which optimization operates.

It MAY be:

* finite;
* discrete;
* continuous;
* mixed;
* combinatorial;
* structured;
* graph-based;
* geometric;
* morphological;
* functional;
* infinite-dimensional.

The decision space need not be numerical.

For example:

```text id="r6p4n1"
Possible Morphologies
        ↓
      Search
        ↓
Best Morphology
```

is an optimization problem even though its alternatives are structural rather than scalar.

---

# Candidate Solution

A candidate solution is a particular assignment or configuration within the decision space.

Candidates MAY be:

* complete;
* partial;
* infeasible;
* approximate;
* provisional.

Optimization SHOULD preserve the distinction between candidate generation and candidate evaluation.

---

# Feasible Region

The feasible region consists of candidate solutions satisfying all declared hard constraints.

```text id="9x6f4q"
Decision Space
┌───────────────────────────────┐
│                               │
│     ┌───────────────────┐     │
│     │   Feasible Region │     │
│     │                   │     │
│     │       ● optimum   │     │
│     │                   │     │
│     └───────────────────┘     │
│                               │
└───────────────────────────────┘
```

Feasibility MUST be distinguishable from preference.

---

# Constraints

Constraints define conditions that candidate solutions MUST, SHOULD, or MAY satisfy depending on their declared semantic strength.

Constraints MAY concern:

* mathematical relationships;
* physical laws;
* safety;
* resources;
* geometry;
* topology;
* morphology;
* time;
* causality;
* computation;
* policy;
* environment.

SCR MUST distinguish at least:

* hard constraints;
* soft constraints;
* preference conditions.

---

# Objectives

An objective specifies what constitutes a desirable outcome.

Examples:

* minimize energy;
* maximize accuracy;
* minimize latency;
* maximize stability;
* minimize cost;
* maximize coverage;
* minimize structural complexity;
* maximize biological viability.

Objectives MAY conflict.

Optimization MUST NOT assume that all objectives can always be reduced to one scalar without loss of meaning.

---

# Cost

A cost expresses an undesirable quantity that an optimization process may seek to minimize.

Cost semantics MAY represent:

* energy;
* error;
* latency;
* resource consumption;
* risk;
* complexity;
* deviation;
* monetary expense.

---

# Utility

Utility expresses a desirable quantity that an optimization process may seek to maximize.

Cost and utility are related but MUST remain semantically distinguishable when their interpretation differs.

---

# Preference

A preference defines a semantic ordering or comparison between alternatives.

Preferences MAY be:

* total;
* partial;
* ordinal;
* cardinal;
* lexicographic;
* contextual;
* uncertain.

Optimization does not require preferences to be expressed as scalar values.

---

# Objective Functions

An objective function maps candidates to an evaluative quantity or structure.

The function MAY return:

* scalar values;
* vectors;
* distributions;
* intervals;
* rankings;
* structured evaluations.

---

# Multi-Objective Optimization

Optimization MAY contain multiple objectives:

```text id="6p3h8x"
              Candidate
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
      Cost      Error     Risk
        │         │         │
        └─────────┼─────────┘
                  ▼
             Trade-off
```

Objectives SHOULD remain individually identifiable.

---

# Pareto Optimality

A solution is Pareto-optimal when no other feasible solution improves one objective without worsening at least one other objective under the declared comparison semantics.

The Pareto frontier is therefore a semantic object.

```text id="a6s3de"
Objective B
   ↑
   │          ●
   │       ●
   │    ●
   │ ●
   └────────────────→ Objective A
```

---

# Scalarization

Multiple objectives MAY be transformed into a scalar objective.

Such transformations MUST preserve the declared preference semantics to the extent required by the optimization contract.

Scalarization is therefore a transformation, not the definition of multi-objective optimization itself.

---

# Optimality

Optimization MUST distinguish different notions of optimality, including:

* global optimum;
* local optimum;
* constrained optimum;
* Pareto optimum;
* approximate optimum;
* probabilistic optimum;
* robust optimum;
* contextual optimum.

A result MUST NOT be described simply as “optimal” when the relevant optimality guarantee is weaker.

---

# Approximate Optimization

Optimization MAY produce approximate solutions.

Approximation SHOULD expose:

* approximation criterion;
* error bound where available;
* tolerance;
* confidence;
* termination condition;
* quality estimate.

Approximation MUST NOT be silently presented as exact optimality.

---

# Local and Global Optimization

A local optimum is optimal relative to a declared neighbourhood.

A global optimum is optimal over the relevant feasible domain.

These guarantees MUST remain semantically distinct.

---

# Continuous Optimization

Continuous optimization operates over continuously valued decision spaces.

It MAY use:

* derivatives;
* gradients;
* Hessians;
* differential structure;
* continuous relaxations.

Mathematics defines the mathematical semantics.

Optimization defines their use for solution selection.

---

# Discrete Optimization

Discrete optimization operates over discrete decision spaces.

Examples include:

* scheduling;
* routing;
* graph selection;
* combinatorial structures;
* symbolic configurations.

Discrete optimization does not require differentiability.

---

# Mixed Optimization

Optimization MAY combine discrete and continuous variables.

```text id="x8o2kd"
Discrete Structure
        +
Continuous Parameters
        ↓
   Joint Optimization
```

This is particularly relevant to morphology, geometry, simulation, and system design.

---

# Convex Optimization

Convex optimization concerns problems whose feasible and objective structures satisfy declared convexity properties.

Convexity MAY provide stronger guarantees concerning:

* global optimality;
* convergence;
* uniqueness.

Such guarantees MUST be explicit.

---

# Nonlinear Optimization

Optimization MAY operate on nonlinear objectives, constraints, or system relationships.

Nonlinearity MUST remain a semantic property rather than an implementation classification.

---

# Combinatorial Optimization

Combinatorial optimization operates over structured discrete alternatives.

Relevant structures include:

* graphs;
* hypergraphs;
* permutations;
* partitions;
* schedules;
* configurations;
* topologies.

---

# Structural Optimization

Optimization MAY operate over structure rather than merely numerical parameters.

Examples include:

* graph structure;
* topology;
* geometry;
* morphology;
* neural architecture;
* system architecture.

This establishes an important relationship with Morphology:

```text id="4b5s9w"
Pattern / Requirements
        ↓
Candidate Structures
        ↓
Optimization
        ↓
Selected Morphology
```

---

# Topology Optimization

Topology MAY itself be a decision variable.

Optimization can therefore select:

* connectivity;
* adjacency;
* components;
* structural organization.

Topology-changing optimization MUST preserve explicit topological semantics.

---

# Morphological Optimization

Morphological optimization selects or transforms form and structure according to objectives and constraints.

Examples include:

* shape optimization;
* organism morphology;
* robot morphology;
* architecture;
* spatial layouts;
* cellular structures.

Morphology provides the semantic structure being optimized.

Optimization provides the selection process.

---

# Geometry Optimization

Optimization MAY operate over:

* positions;
* dimensions;
* curves;
* surfaces;
* volumes;
* trajectories;
* geometric configurations.

Geometry defines spatial semantics.

Optimization defines preference over alternatives.

---

# Field Optimization

Fields MAY themselves be optimized.

Examples include:

* control fields;
* potential fields;
* resource distributions;
* parameter fields;
* environmental configurations.

---

# Dynamic Optimization

Optimization MAY operate over evolving systems.

The solution may therefore be:

* a trajectory;
* a time-dependent policy;
* a sequence of interventions;
* an evolving configuration.

---

# Trajectory Optimization

Trajectory optimization selects paths through state or configuration space according to objectives and constraints.

```text id="r2s8c4"
Initial State
      ↓
Possible Trajectories
      ↓
Constraints
      ↓
Objective Evaluation
      ↓
Selected Trajectory
```

---

# Optimal Control

Optimal control is the composition of Optimization and Control.

```text id="6y5h2s"
Optimization
     ↓
Select preferred control strategy
     ↓
Control
     ↓
Intervention
     ↓
Dynamics
```

Optimization MUST NOT subsume Control.

---

# Resource Optimization

Optimization MAY allocate limited resources across competing demands.

Resources may include:

* compute;
* memory;
* energy;
* bandwidth;
* storage;
* physical materials;
* time;
* attention.

---

# Scheduling

Scheduling is an optimization specialization concerned with assigning activities to resources and time.

Scheduling MAY operate over:

* computational workloads;
* simulations;
* agents;
* streams;
* rendering;
* distributed execution.

---

# Runtime Optimization

SCR's runtime MAY use optimization to select:

* providers;
* algorithms;
* hardware;
* memory placement;
* scheduling;
* execution strategies;
* representation strategies.

Such optimization MUST preserve semantic contracts.

---

# Compiler Optimization

Compiler transformations MAY optimize execution while preserving semantic equivalence.

```text id="7y2t0k"
Semantic Program
      ↓
Optimization
      ↓
Equivalent Program
      ↓
Lowering
      ↓
Execution
```

Compiler optimization is therefore an application of optimization semantics.

---

# Adaptive Optimization

Optimization MAY operate continuously as conditions change.

Inputs may include:

* telemetry;
* workload;
* hardware state;
* environmental conditions;
* model updates;
* observed performance.

Adaptive optimization MUST preserve declared semantic objectives and constraints.

---

# Stochastic Optimization

Optimization MAY operate under:

* uncertain objectives;
* stochastic candidate evaluation;
* uncertain parameters;
* probabilistic constraints.

Uncertainty MUST remain explicit.

---

# Robust Optimization

Robust optimization seeks solutions that remain acceptable under specified variation or uncertainty.

Robustness MAY concern:

* parameter uncertainty;
* disturbances;
* model mismatch;
* environmental variation;
* implementation variation.

---

# Online Optimization

Online optimization makes decisions as information becomes available.

```text id="3k2v6f"
Information
    ↓
Decision
    ↓
Observation
    ↓
Updated Problem
    ↓
Next Decision
    ↺
```

This naturally composes with Streams, Control, Perception, and Agents.

---

# Distributed Optimization

Optimization MAY be distributed across multiple computational entities.

Distributed optimization MUST preserve:

* objective semantics;
* constraint semantics;
* synchronization semantics;
* causal relationships;
* convergence guarantees where declared.

Transport remains implementation-specific.

---

# Search

Optimization MAY use search to explore candidate spaces.

Search strategies include:

* exhaustive search;
* heuristic search;
* stochastic search;
* evolutionary search;
* sampling;
* branch-and-bound;
* learned search.

Search is a mechanism for exploring alternatives, not the definition of optimality.

---

# Gradient-Based Optimization

Gradient-based methods use derivatives to guide search.

They are applicable only where the required differentiability semantics exist.

Gradient computation is supplied by Mathematics or Differentiable computational domains.

---

# Gradient-Free Optimization

Optimization MAY operate without derivatives.

This permits optimization over:

* discrete structures;
* discontinuous objectives;
* black-box systems;
* simulations;
* external systems.

---

# Evolutionary Optimization

Evolutionary methods may generate and select candidate solutions through population-based variation and selection.

They may operate over:

* morphology;
* agents;
* neural architectures;
* graph structures;
* parameter sets.

Evolutionary mechanisms are providers or specializations of optimization.

---

# Bayesian Optimization

Bayesian optimization uses an explicit model of objective uncertainty to select informative candidate evaluations.

The uncertainty model MUST remain distinguishable from the underlying objective.

---

# Surrogate Optimization

A surrogate model MAY approximate an expensive objective or system.

```text id="k9c4e2"
Expensive System
       ↓
Observed Evaluations
       ↓
Surrogate
       ↓
Candidate Selection
       ↓
Expensive Evaluation
       ↺
```

Surrogate error and validity conditions MUST remain explicit.

---

# Optimization Under Uncertainty

Optimization MAY explicitly model uncertainty in:

* state;
* parameters;
* objectives;
* constraints;
* observations;
* system responses.

Solutions MAY therefore optimize:

* expected performance;
* worst-case performance;
* risk;
* confidence;
* probabilistic guarantees.

---

# Sensitivity

Sensitivity describes how solution quality or feasibility changes as inputs, parameters, or assumptions change.

Sensitivity information MAY be used to:

* assess robustness;
* guide adaptation;
* prioritize measurements;
* identify critical parameters.

---

# Solution Quality

Optimization results SHOULD expose quality information appropriate to the problem.

Possible measures include:

* objective value;
* constraint violation;
* optimality gap;
* approximation error;
* confidence;
* robustness;
* Pareto dominance;
* convergence status.

---

# Convergence

When an optimization method has a convergence concept, the semantic contract SHOULD identify:

* convergence target;
* tolerance;
* stopping criterion;
* guarantee;
* assumptions.

Termination MUST NOT automatically imply optimality.

---

# Termination

An optimization process MAY terminate because:

* a solution was found;
* a quality threshold was achieved;
* a resource limit was reached;
* a time limit was reached;
* convergence was detected;
* no further progress was observed;
* an error occurred.

Termination reason MUST remain observable.

---

# Optimization and Mathematics

Mathematics provides the formal structures used to describe optimization.

Optimization specializes those structures around:

* alternatives;
* objectives;
* constraints;
* preferences;
* solution selection.

Optimization MUST NOT redefine mathematical meaning.

---

# Optimization and Data

Data supplies:

* observations;
* parameters;
* historical evaluations;
* candidate populations;
* constraints;
* objective measurements.

Optimization produces new semantic information including:

* candidate solutions;
* rankings;
* selected solutions;
* sensitivity information;
* provenance.

---

# Optimization and Fields

Fields MAY be:

* decision variables;
* objectives;
* constraints;
* cost landscapes;
* solution spaces.

Optimization may therefore transform a field into another field representing preferred configurations.

---

# Optimization and Graphs

Graph and hypergraph structures may themselves be optimized.

Examples:

* network topology;
* routing;
* graph partitioning;
* connectivity;
* dependency structures;
* knowledge structures.

Higher-order relationships MUST remain representable.

---

# Optimization and Topology

Topology can define:

* feasible structural configurations;
* connectivity constraints;
* topological objectives;
* topological invariants.

Optimization may search over topological state spaces.

---

# Optimization and Geometry

Geometry provides spatial decision spaces and constraints.

Optimization may select:

* shape;
* placement;
* trajectory;
* dimensions;
* spatial arrangement.

---

# Optimization and Morphology

Morphology supplies structured form and organization as optimization variables or objectives.

This makes morphology optimization particularly important for SCR's artificial-life and generative systems.

---

# Optimization and Physics

Physics provides:

* physical constraints;
* energy relationships;
* conservation laws;
* constitutive relationships.

Optimization may select physically admissible configurations.

Optimization MUST NOT treat a physical law merely as a soft preference when the model declares it as a hard constraint.

---

# Optimization and Dynamics

Dynamics determines how candidate decisions affect system evolution.

Optimization may therefore evaluate:

```text id="y3j7v8"
Candidate Intervention
        ↓
Dynamics
        ↓
Predicted Evolution
        ↓
Objective Evaluation
```

---

# Optimization and Simulation

Simulation may serve as an objective evaluator when direct analytical evaluation is unavailable.

This enables:

* simulation-based optimization;
* parameter fitting;
* design optimization;
* policy optimization;
* experimental design;
* surrogate construction.

---

# Optimization and Agents

Agents may:

* optimize their own behaviour;
* optimize shared objectives;
* optimize resource allocation;
* participate in multi-agent optimization.

Optimization does not require agents.

---

# Optimization and Neural

Neural computation may be optimized during training.

Optimization may determine:

* neural parameters;
* architectures;
* objectives;
* policies;
* representations.

Learning and optimization remain distinct:

> Learning changes a system through information or experience; optimization defines the preference and selection process used to choose among alternatives.

---

# Optimization and Perception

Perception may provide observations used to optimize:

* sensing;
* feature selection;
* attention;
* sensor placement;
* perception models.

Optimization may also determine which observations are worth acquiring.

---

# Semantic Hypergraph Integration

Optimization SHOULD integrate directly with the Semantic Hypergraph.

An optimization problem may be represented as:

```text id="q7s3m8"
Optimization Problem
├── Decision Space
├── Decision Variables
├── Candidate Solutions
├── Constraints
├── Objectives
├── Preferences
├── Evaluator
├── Search Strategy
├── Solution
├── Quality
├── Uncertainty
└── Provenance
```

Relationships SHOULD explicitly represent:

* candidate membership;
* constraint applicability;
* objective evaluation;
* dominance;
* preference;
* derivation;
* solution selection;
* transformation history.

---

# Optimization Operations

Optimization processes SHOULD be representable as semantic operations.

An operation may:

```text
consume:
    problem
    candidates
    observations
    constraints

produce:
    candidates
    evaluations
    rankings
    solution
    provenance
```

The optimization process itself MAY therefore become part of the semantic graph.

---

# Optimization Deltas

Optimization MAY produce semantic deltas including:

* parameter changes;
* topology changes;
* morphology changes;
* policy changes;
* candidate-set changes;
* objective changes;
* constraint changes.

Optimization deltas MUST remain semantic rather than storage-specific.

---

# Optimization Streams

Optimization MAY operate over streams of:

* candidates;
* observations;
* evaluations;
* constraints;
* objectives;
* solutions;
* telemetry.

This enables:

* online optimization;
* adaptive optimization;
* distributed optimization;
* runtime optimization.

---

# Provenance

Optimization SHOULD preserve provenance describing:

* problem definition;
* objective definitions;
* constraints;
* decision variables;
* candidate generation;
* evaluator;
* algorithm/provider;
* random seed where applicable;
* execution environment;
* termination condition;
* solution;
* quality;
* approximation;
* uncertainty.

---

# Reproducibility

Optimization results SHOULD be reproducible when the semantic contract declares deterministic behaviour.

Where stochastic methods are used, reproducibility MAY require:

* random seed;
* stochastic model version;
* candidate ordering;
* provider version;
* numerical environment.

---

# Representation Independence

Optimization semantics MUST remain independent of:

* solver APIs;
* matrix formats;
* numerical libraries;
* programming languages;
* memory layouts;
* hardware;
* accelerator APIs.

---

# Provider Independence

Optimization providers MAY include:

* linear programming solvers;
* nonlinear solvers;
* evolutionary frameworks;
* automatic differentiation systems;
* Bayesian optimization libraries;
* scheduling engines;
* external optimization services.

Providers implement optimization semantics.

They MUST NOT become semantic authorities.

---

# Semantic Equivalence

Two optimization implementations MAY be considered equivalent if they satisfy the same declared optimization contract.

Equivalence MAY concern:

* exact solution;
* optimality class;
* Pareto frontier;
* feasible region;
* approximation bound;
* objective quality;
* constraint satisfaction;
* probabilistic guarantee.

Different algorithms need not produce identical intermediate trajectories to be semantically equivalent.

---

# Runtime Semantics

The SCR runtime MAY optimize:

* provider selection;
* hardware placement;
* execution scheduling;
* memory placement;
* representation;
* kernel selection;
* compilation strategy.

Runtime optimization MUST preserve application-level semantic contracts.

This creates a recursive relationship:

```text id="r8k1p2"
Application Optimization
          ↓
    Semantic Objective
          ↓
Runtime Optimization
          ↓
Execution Strategy
```

---

# MLIR Representation

Optimization semantics MAY be represented through MLIR operations, attributes, types, interfaces, and transformations.

Potential representations include:

* optimization problems;
* objectives;
* constraints;
* decision variables;
* candidate evaluation;
* transformations;
* equivalence contracts.

MLIR transformations MAY themselves be optimization operations.

MLIR remains compilation infrastructure and MUST NOT become the semantic authority over optimization.

---

# Capabilities

Optimization operations MAY declare capabilities including:

* `Constrained`
* `Unconstrained`
* `Continuous`
* `Discrete`
* `Mixed`
* `Convex`
* `Nonlinear`
* `Combinatorial`
* `MultiObjective`
* `Pareto`
* `Stochastic`
* `Robust`
* `Adaptive`
* `Online`
* `Distributed`
* `Differentiable`
* `GradientBased`
* `GradientFree`
* `Evolutionary`
* `Bayesian`
* `Surrogate`
* `Deterministic`
* `Parallelizable`
* `Streamable`
* `Approximate`
* `Certified`.

---

# Performance Semantics

Optimization performance MAY concern:

* convergence rate;
* evaluation count;
* computational complexity;
* memory consumption;
* communication;
* parallel scalability;
* numerical stability;
* latency.

Performance MUST remain distinct from solution quality.

A faster algorithm is not necessarily a better optimizer if it changes the declared semantic guarantee.

---

# Errors and Failure Semantics

Optimization errors MAY include:

* infeasible problem;
* unbounded objective;
* invalid objective;
* invalid constraint;
* undefined evaluation;
* numerical instability;
* convergence failure;
* timeout;
* resource exhaustion;
* provider failure;
* invalid candidate;
* insufficient information.

The runtime SHOULD distinguish:

```text
No Feasible Solution
        ≠
No Optimal Solution Found
        ≠
Optimization Failed
```

---

# Security and Isolation

Optimization may select actions affecting:

* physical systems;
* resources;
* networks;
* financial systems;
* autonomous agents;
* infrastructure.

Optimization execution SHOULD therefore support:

* resource limits;
* constraint enforcement;
* authorization;
* sandboxing;
* provenance;
* auditability.

An optimizer MUST NOT gain authority to violate system-level safety constraints merely because such violations improve its objective.

---

# Expected Subdomains

The following structure is illustrative:

```text id="u6j4p9"
optimization/
├── optimization-core
├── decision
├── decision-space
├── variable
├── candidate
├── feasible-region
├── constraint
├── objective
├── objective-function
├── cost
├── utility
├── preference
├── ranking
├── scalarization
├── multi-objective
├── pareto
├── optimality
├── local
├── global
├── approximate
├── continuous
├── discrete
├── mixed
├── combinatorial
├── convex
├── nonlinear
├── structural
├── topology
├── geometry
├── morphology
├── field
├── trajectory
├── dynamic
├── control
├── resource
├── scheduling
├── search
├── sampling
├── gradient
├── gradient-free
├── evolutionary
├── bayesian
├── surrogate
├── stochastic
├── robust
├── adaptive
├── online
├── distributed
├── sensitivity
├── convergence
├── termination
├── quality
├── uncertainty
├── provenance
├── reproducibility
├── equivalence
├── stream
├── delta
├── capability
└── provider
```

This structure is illustrative and does not require immediate implementation of every subdomain.

---

# Invariants

## OPT-INV-001 — Semantic Primacy

Optimization semantics MUST remain independent of any particular optimization algorithm or solver.

## OPT-INV-002 — Decision Integrity

Decision variables MUST remain distinguishable from implementation variables.

## OPT-INV-003 — Constraint Integrity

Hard constraints MUST remain explicit and enforceable.

## OPT-INV-004 — Objective Integrity

Objectives MUST remain distinguishable from constraints.

## OPT-INV-005 — Preference Integrity

Preferences MUST remain explicit rather than being silently inferred from implementation behaviour.

## OPT-INV-006 — Feasibility Integrity

Feasibility MUST remain distinguishable from optimality.

## OPT-INV-007 — Optimality Integrity

Claims of optimality MUST identify the relevant optimality guarantee.

## OPT-INV-008 — Approximation Integrity

Approximate solutions MUST NOT be silently represented as exact solutions.

## OPT-INV-009 — Multi-Objective Integrity

Distinct objectives MUST remain identifiable unless an explicit semantic transformation combines them.

## OPT-INV-010 — Uncertainty Integrity

Uncertainty MUST remain distinguishable from objective value and solution quality.

## OPT-INV-011 — Termination Integrity

Termination MUST NOT imply convergence or optimality unless explicitly guaranteed.

## OPT-INV-012 — Provenance Integrity

Optimization results SHOULD preserve the derivation and evaluation history necessary to interpret them.

## OPT-INV-013 — Provider Independence

Optimization providers MUST NOT become semantic authorities.

## OPT-INV-014 — Representation Independence

Optimization semantics MUST remain independent of solver representation.

## OPT-INV-015 — Constraint Preservation

Optimization transformations MUST preserve declared constraints.

## OPT-INV-016 — Equivalence Integrity

Optimization transformations claiming semantic equivalence MUST satisfy the declared equivalence contract.

## OPT-INV-017 — Determinism Integrity

Where deterministic behaviour is declared, equivalent inputs MUST produce equivalent results under the declared contract.

## OPT-INV-018 — Hardware Independence

Optimization semantics MUST remain independent of hardware while permitting hardware-aware execution strategies.

---

# Domain Relationships

| Domain      | Relationship | Meaning                                                                                        |
| ----------- | ------------ | ---------------------------------------------------------------------------------------------- |
| Core        | REFINES      | Optimization uses foundational state, operations, constraints, provenance, and transformations |
| Mathematics | SPECIALIZES  | Optimization specializes mathematical structures around selection and preference               |
| Data        | CONSUMES     | Optimization consumes observations, parameters, candidates, and evaluations                    |
| Fields      | OPERATES_ON  | Fields may be decision spaces, objectives, constraints, or candidate structures                |
| Graphs      | OPTIMIZES    | Graph and hypergraph structures may be decision variables                                      |
| Geometry    | OPTIMIZES    | Spatial configurations may be optimized                                                        |
| Topology    | OPTIMIZES    | Connectivity and topological structures may be optimized                                       |
| Morphology  | OPTIMIZES    | Form and organization may be optimization variables                                            |
| Physics     | CONSTRAINS   | Physical laws may define feasibility                                                           |
| Dynamics    | EVALUATES    | System evolution may determine candidate quality                                               |
| Simulation  | EVALUATES    | Simulation may provide objective evaluations                                                   |
| Control     | COMPOSES     | Control strategies may be optimized                                                            |
| Agents      | SERVES       | Agents may optimize behaviour or shared objectives                                             |
| Neural      | TRAINS       | Neural parameters and architectures may be optimized                                           |
| Perception  | OPTIMIZES    | Sensing and interpretation strategies may be optimized                                         |
| Rendering   | OPTIMIZES    | Rendering configuration and resource allocation may be optimized                               |

These are semantic relationships and do not imply implementation dependencies.

---

# Testing Requirements

Optimization implementations MUST support the SCR testing hierarchy:

```text id="j9r4v2"
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

* objective evaluation;
* constraint enforcement;
* feasibility;
* candidate generation;
* solution selection;
* local/global optimality where applicable;
* Pareto dominance;
* approximation guarantees;
* stochastic behaviour;
* convergence;
* termination;
* reproducibility;
* sensitivity;
* robustness;
* distributed behaviour;
* provider equivalence;
* runtime optimization;
* semantic preservation.

---

# Validation Requirements

Optimization validation SHOULD determine whether:

1. the decision space is represented correctly;
2. constraints are correctly interpreted;
3. objectives are correctly interpreted;
4. candidate solutions are valid;
5. feasibility is correctly determined;
6. solution quality is correctly evaluated;
7. declared optimality guarantees hold;
8. approximation bounds hold where declared;
9. uncertainty is preserved;
10. provenance is preserved;
11. transformations preserve optimization semantics;
12. provider substitutions preserve the required contract.

Validation MUST distinguish:

* optimization problem correctness;
* solver correctness;
* numerical correctness;
* implementation correctness;
* execution correctness.

---

# Function-Level Requirements

Every Optimization function MUST specify, where applicable:

* decision variables;
* decision space;
* candidate representation;
* feasible region;
* constraints;
* objectives;
* preferences;
* evaluation semantics;
* optimization direction;
* optimality semantics;
* approximation semantics;
* uncertainty;
* termination;
* determinism;
* resource requirements;
* provenance;
* capabilities;
* errors;
* equivalence requirements.

---

# Completeness Criteria

The Optimization domain definition is complete only when:

* decision spaces are representable;
* decision variables are explicit;
* candidate solutions are explicit;
* constraints are explicit;
* objectives are explicit;
* preferences are expressible;
* feasible regions are representable;
* objective evaluation is representable;
* multi-objective optimization is representable;
* Pareto semantics are representable;
* local and global optimality are distinguishable;
* approximate solutions are representable;
* continuous optimization is representable;
* discrete optimization is representable;
* mixed optimization is representable;
* structural optimization is representable;
* topology optimization is representable;
* morphological optimization is representable;
* trajectory optimization is representable;
* stochastic optimization is representable;
* robust optimization is representable;
* adaptive optimization is representable;
* online optimization is representable;
* distributed optimization is representable;
* optimization under uncertainty is representable;
* sensitivity is representable;
* convergence is representable;
* termination is observable;
* solution quality is explicit;
* provenance is preserved;
* Semantic Hypergraph integration exists;
* provider independence is maintained;
* representation independence is maintained;
* MLIR remains compilation infrastructure;
* hardware-aware execution does not redefine optimization semantics.

---

# Architectural Rules

1. **Optimization MUST be defined by semantic selection among alternatives, not by a particular solver.**
2. **Decision spaces MUST NOT be assumed to be numerical.**
3. **Objectives MUST remain distinguishable from constraints.**
4. **Hard constraints MUST remain enforceable.**
5. **Feasibility MUST remain distinct from optimality.**
6. **Optimality guarantees MUST be explicit.**
7. **Approximation MUST be explicit.**
8. **Multi-objective semantics MUST NOT be silently collapsed into scalar optimization.**
9. **Preferences MUST remain explicit where they affect solution selection.**
10. **Termination MUST remain distinct from convergence.**
11. **Convergence MUST remain distinct from optimality.**
12. **Optimization MAY operate over numerical, structural, graph, topological, geometric, morphological, field, agent, and computational spaces.**
13. **Optimization MAY compose with Control but MUST NOT redefine Control.**
14. **Optimization MAY evaluate candidate behaviour through Dynamics or Simulation.**
15. **Physics MAY provide hard constraints.**
16. **Neural computation MAY provide optimization mechanisms or optimized models.**
17. **Providers MUST NOT become semantic authorities.**
18. **Optimization transformations MUST preserve declared semantic contracts.**
19. **Runtime optimization MUST preserve application-level semantics.**
20. **Hardware-aware optimization MUST NOT redefine the optimization problem.**

---

# Open Semantic Questions

The following remain intentionally open:

* How should arbitrary preference relations be represented?
* How should non-scalar objectives be canonically compared?
* How should conflicting objectives be composed?
* How should preference hierarchies be represented?
* How should hard, soft, and probabilistic constraints interact?
* How should optimization over arbitrary Semantic Hypergraph regions be expressed?
* How should structural optimization preserve identity across topology changes?
* How should Morphological optimization represent developmental constraints?
* How should optimization operate over continuously evolving Fields?
* How should dynamic optimization represent objectives that themselves evolve?
* How should uncertainty propagate through candidate evaluation?
* How should approximate optimality be represented independently of a particular algorithm?
* How should optimality guarantees be expressed formally?
* How should distributed optimization represent causal and consistency requirements?
* How should optimization provenance be represented when candidate spaces are generated dynamically?
* How should runtime optimization expose its decisions without becoming part of application semantics?
* How should compiler optimization formally interact with SCR semantic equivalence?
* How should resource optimization interact with safety constraints?
* How should optimization itself be recursively optimized?

These questions SHOULD remain open until sufficient semantic requirements exist to resolve them.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Established:

* decision spaces;
* decision variables;
* candidates;
* feasibility;
* constraints;
* objectives;
* preferences;
* costs and utilities;
* multi-objective optimization;
* Pareto semantics;
* optimality;
* approximation;
* structural optimization;
* topology and morphology optimization;
* trajectory optimization;
* optimal control;
* resource optimization;
* scheduling;
* runtime optimization;
* compiler optimization;
* adaptive and online optimization;
* stochastic and robust optimization;
* distributed optimization;
* search and sampling;
* provenance;
* uncertainty;
* solution quality;
* convergence and termination;
* Semantic Hypergraph integration;
* provider independence;
* representation independence;
* MLIR integration.

---

# Definition Authority

This document is the normative semantic definition of the SCR Optimization domain.

Optimization libraries, solvers, numerical frameworks, machine-learning systems, compiler passes, scheduling engines, examples, benchmarks, generated artifacts, and implementation details MUST NOT redefine this domain without an explicit semantic revision.

---

# Definition Principle

> **Optimization is the semantic process of selecting or constructing preferred alternatives within a declared decision space subject to explicit objectives, preferences, constraints, and uncertainty.**

The essential relationship is:

```text id="h4z8p1"
                 DECISION SPACE
                       │
                       ▼
                 ALTERNATIVES
                       │
                       ▼
                  CONSTRAINTS
                       │
                       ▼
                 FEASIBILITY
                       │
                       ▼
                   OBJECTIVES
                       │
                       ▼
                  PREFERENCE
                       │
                       ▼
                OPTIMIZATION
                       │
                       ▼
                  SELECTION
                       │
                       ▼
                  SOLUTION
```

And within the broader SCR computational universe:

```text id="v7n3k5"
                    MATHEMATICS
                        │
                        ▼
                   OPTIMIZATION
                  ╱      │       ╲
                 ╱       │        ╲
                ▼        ▼         ▼
           CONTROL    DESIGN    LEARNING
                │        │         │
                ▼        ▼         ▼
             DYNAMICS  MORPHOLOGY  NEURAL
                │        │         │
                └────────┼─────────┘
                         ▼
                    SYSTEM STATE
                         │
                         ▼
                     SIMULATION
                         │
                         ▼
                    OBSERVATION
                         │
                         └────────────↺
```

Optimization is consequently the semantic layer that allows SCR to move from **what can happen** to **what should be selected**, without assuming that preference must be numerical, that solutions must be physical, or that optimization must be implemented by any particular algorithm.
