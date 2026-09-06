---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-NEURAL
name: Neural

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
---

# Neural

## Definition

Neural is the semantic computational domain concerned with **networks of adaptive computational units, distributed representations, signal propagation, transformation, learning, and emergent computation inspired by or structurally analogous to neural systems**.

Neural computation provides a semantic foundation for representing and executing computational structures in which information is transformed through interconnected units, parameters, signals, states, and adaptive processes.

Neural computation is not synonymous with:

* artificial intelligence;
* machine learning;
* deep learning;
* agents;
* cognition;
* consciousness;
* biological neurons;
* neural-network libraries;
* tensor operations;
* GPU execution.

Those domains may use neural computation, but none defines it.

The fundamental abstraction is:

```text
Input
  ↓
Representation
  ↓
Neural Network
  ↓
Signal Propagation
  ↓
Transformation
  ↓
Output
  ↕
State / Parameters
  ↕
Learning / Adaptation
```

Neural computation therefore describes a class of **distributed computational transformations whose structure, parameters, signals, and adaptation have semantic meaning**.

---

# Semantic Model

A neural computational system can be represented conceptually as:

```text
N = (U, R, W, X, S, F, Y, L, T, C, P)
```

where:

* `U` = computational units;
* `R` = relationships/connections;
* `W` = connection parameters or weights;
* `X` = input signals;
* `S` = internal state;
* `F` = transformation/activation semantics;
* `Y` = output signals;
* `L` = learning/adaptation semantics;
* `T` = temporal semantics;
* `C` = constraints and capabilities;
* `P` = provenance.

Not every neural system requires every component.

Neural computation MAY be:

* feed-forward;
* recurrent;
* convolutional;
* attention-based;
* graph-structured;
* spiking;
* continuous;
* discrete;
* stochastic;
* deterministic;
* static;
* adaptive;
* learned;
* evolutionary;
* hybrid.

---

# Scope

SCR Neural includes semantics for:

* neural computational units;
* neurons;
* populations;
* networks;
* connections;
* synapses;
* weights;
* biases;
* activations;
* transfer functions;
* aggregation;
* signal propagation;
* representations;
* embeddings;
* latent spaces;
* recurrent state;
* memory;
* attention;
* gating;
* normalization;
* message passing;
* neural fields;
* convolution;
* recurrence;
* sequence processing;
* graph neural computation;
* spiking computation;
* plasticity;
* learning;
* training;
* inference;
* optimization;
* gradients;
* automatic differentiation;
* parameter updates;
* objectives;
* losses;
* regularization;
* initialization;
* architecture;
* topology;
* sparsity;
* modularity;
* compositionality;
* pruning;
* quantization;
* distillation;
* adaptation;
* transfer;
* continual learning;
* uncertainty;
* stochasticity;
* neural state;
* neural streams;
* neural deltas;
* provenance;
* model versioning;
* neural execution.

---

# Neural Computation

Neural computation is fundamentally a transformation of information through structured relationships.

Conceptually:

```text
x
│
▼
┌─────────────┐
│ Neural      │
│ Structure   │
└─────────────┘
│
▼
f(x; θ, s)
│
├── θ = parameters
├── s = state
└── f = transformation
│
▼
y
```

The function `f` is a semantic computational transformation.

Its implementation may vary.

---

# Computational Units

A neural computational unit is a semantic entity capable of receiving, transforming, maintaining, or emitting computational signals.

A unit MAY represent:

* an artificial neuron;
* a biological neuron abstraction;
* a spiking element;
* a recurrent unit;
* an activation unit;
* an attention unit;
* a logical computational element;
* a learned computational module.

A unit's implementation MUST NOT determine its semantic identity.

---

# Connections

Connections represent directed or otherwise structured relationships through which computational information propagates.

Connections MAY have:

* weights;
* delays;
* transmission functions;
* gating;
* polarity;
* metadata;
* temporal characteristics.

Connections may be:

* dense;
* sparse;
* static;
* dynamic;
* learned;
* structural;
* inhibitory;
* excitatory;
* probabilistic.

---

# Neural Topology

Network topology defines the structural arrangement of computational units and connections.

Topology may include:

* layers;
* directed acyclic structures;
* recurrent structures;
* cycles;
* graphs;
* hypergraphs;
* hierarchical structures;
* modular structures;
* sparse structures;
* dynamic structures.

Neural topology MUST remain distinct from:

* physical hardware topology;
* memory layout;
* tensor layout;
* network transport topology.

---

# Neural State

Neural state represents information required for the current computational condition of a neural system.

State MAY include:

* activation state;
* recurrent state;
* membrane state;
* synaptic state;
* attention state;
* cached state;
* learned state.

State MUST remain distinct from persistent model parameters.

---

# Parameters

Parameters represent values governing neural transformations.

Examples include:

* weights;
* biases;
* thresholds;
* time constants;
* normalization parameters;
* attention parameters.

Parameters MAY be:

* fixed;
* learned;
* dynamically adapted;
* externally supplied.

---

# Parameters vs State

Neural parameters and neural state MUST remain semantically distinguishable.

```text
Neural Model
├── Structure
├── Parameters
└── Transformation

Neural Runtime State
└── Current computational state
```

A parameter update is not necessarily an ordinary state transition.

---

# Signals

Signals represent information propagated through neural computational structures.

Signals MAY be:

* scalar;
* vector;
* tensor;
* categorical;
* probabilistic;
* sparse;
* event-based;
* temporal;
* continuous;
* discrete.

Signal semantics MUST remain independent of physical representation.

---

# Activation

Activation semantics describe how a computational unit transforms incoming information into output or state.

Examples include:

* threshold functions;
* continuous nonlinearities;
* piecewise functions;
* probabilistic activations;
* spiking responses;
* learned transformations.

An activation function is a semantic transformation, not merely a mathematical implementation detail.

---

# Aggregation

A neural unit may combine multiple incoming signals.

Aggregation MAY involve:

* summation;
* weighted summation;
* product;
* maximum;
* attention;
* learned aggregation;
* graph message aggregation;
* custom semantic operators.

---

# Propagation

Propagation defines how information moves through neural structure.

Propagation may be:

* feed-forward;
* recurrent;
* iterative;
* event-driven;
* synchronous;
* asynchronous;
* delayed;
* continuous-time.

Execution scheduling MUST remain distinct from propagation semantics.

---

# Recurrence

Recurrent neural computation occurs when current computation depends upon prior computational state.

Conceptually:

```text
xₜ
 ↓
┌─────────────┐
│ Neural      │
│ Transition  │
└─────────────┘
 ↑           │
 └── sₜ₋₁ ───┘
      ↓
     sₜ
```

Recurrent state MUST have explicit temporal semantics.

---

# Temporal Neural Computation

Neural computation MAY operate over:

* discrete timesteps;
* continuous time;
* event time;
* simulation time;
* asynchronous events.

Temporal semantics MUST remain independent of wall-clock execution.

---

# Spiking Computation

Spiking neural systems represent computation through temporally structured events or spikes.

Relevant semantics include:

* spike events;
* membrane state;
* thresholds;
* refractory periods;
* delays;
* temporal coding;
* spike propagation;
* synaptic state.

Spiking computation is a specialization of Neural, not a separate semantic authority.

---

# Representations

Neural computation may transform information between representations.

```text
Input Representation
        ↓
Neural Transformation
        ↓
Latent Representation
        ↓
Neural Transformation
        ↓
Output Representation
```

Representations MAY be:

* explicit;
* latent;
* distributed;
* sparse;
* continuous;
* discrete;
* symbolic-neural;
* multimodal.

---

# Embeddings

An embedding is a semantic transformation that maps objects, signals, entities, or structures into another representational space.

Embeddings MAY preserve selected relationships while changing representation.

Embedding semantics MUST specify the properties intended to be preserved.

---

# Latent Spaces

A latent space represents an internal computational representation whose dimensions or structure may not directly correspond to externally observable quantities.

Latent representations MAY be:

* learned;
* fixed;
* probabilistic;
* structured;
* continuous;
* discrete.

A latent representation MUST NOT automatically be interpreted as an ontological representation of the underlying domain.

---

# Attention

Attention represents selective weighting or routing of computational information according to a declared mechanism.

Attention MAY operate over:

* sequences;
* graphs;
* fields;
* spatial regions;
* modalities;
* agents;
* memory;
* arbitrary semantic collections.

Attention is a computational mechanism and does not imply human-like attention.

---

# Neural Memory

Neural systems MAY maintain computational memory through:

* recurrent state;
* learned parameters;
* external memory;
* associative structures;
* attention;
* state-space mechanisms.

Memory semantics MUST remain distinguishable from storage implementation.

---

# Learning

Learning modifies a neural system according to an adaptation process.

Conceptually:

```text
Input
  ↓
Inference
  ↓
Output
  ↓
Objective / Observation
  ↓
Learning Process
  ↓
Parameter / State Update
  ↺
```

Learning may modify:

* parameters;
* topology;
* state;
* representations;
* policies;
* memory.

---

# Training

Training is a computational process that produces or modifies a neural model according to an objective, data, environment, or experience.

Training MAY involve:

* supervised learning;
* unsupervised learning;
* self-supervised learning;
* reinforcement learning;
* evolutionary processes;
* online learning;
* continual learning;
* meta-learning.

Training is a process, not the semantic identity of the resulting model.

---

# Inference

Inference is execution of a neural computational model to produce outputs or state transitions from inputs and current state.

Inference MUST remain distinct from training.

A system MAY support both without conflating their semantics.

---

# Objective

An objective specifies a criterion used to evaluate or guide neural computation.

Objectives MAY include:

* prediction accuracy;
* reconstruction;
* likelihood;
* control performance;
* reward;
* structural preservation;
* energy minimization;
* multi-objective criteria.

---

# Loss

A loss represents a semantic measure of deviation between an expected or desired result and an actual result.

Loss functions MUST remain distinguishable from:

* optimization algorithms;
* gradient implementations;
* numerical libraries.

---

# Gradient

A gradient represents sensitivity of an objective with respect to one or more parameters or variables.

Gradient semantics MAY support:

* optimization;
* learning;
* sensitivity analysis;
* control;
* differentiable simulation.

Automatic differentiation is one implementation mechanism for producing gradients.

---

# Plasticity

Plasticity describes changes to neural relationships or computational behaviour resulting from activity, experience, or other adaptation.

Plasticity MAY affect:

* weights;
* topology;
* thresholds;
* connectivity;
* temporal parameters.

---

# Optimization

Optimization may be used to determine neural parameters or structures.

The Optimization domain defines general optimization semantics.

Neural defines how optimization participates in neural learning.

---

# Architecture

Neural architecture describes the structural organization of a neural computational system.

Architecture MAY include:

* layers;
* modules;
* pathways;
* recurrent loops;
* attention mechanisms;
* memory;
* routing;
* hierarchical composition.

Architecture itself is semantic information.

---

# Modularity

Neural systems MAY be composed of semantically identifiable modules.

A module MAY provide:

* inputs;
* outputs;
* state;
* capabilities;
* contracts;
* internal structure.

Modules SHOULD be composable without requiring knowledge of their implementation.

---

# Compositionality

Neural systems SHOULD support composition of computational structures.

```text
Neural Module A
      ↓
Neural Module B
      ↓
Neural Module C
```

Composition MUST preserve declared signal, state, temporal, and semantic contracts.

---

# Graph Neural Computation

Neural computation MAY operate directly over Graphs and Semantic Hypergraphs.

```text
Graph
  ↓
Message Passing
  ↓
Node / Edge Representations
  ↓
Aggregation
  ↓
Transformation
  ↓
Updated Graph Representation
```

Graph structure MUST remain semantically distinct from neural parameters.

---

# Neural Fields

Neural computation MAY operate over Fields.

Examples include:

* spatial neural fields;
* continuous neural representations;
* neural operators;
* learned field transformations.

Fields provide domain semantics.

Neural provides computational transformation semantics.

---

# Neural Geometry

Neural systems MAY encode, transform, infer, or generate Geometry.

Examples include:

* shape embeddings;
* learned geometric transformations;
* implicit representations;
* geometric prediction.

Neural computation does not redefine geometric meaning.

---

# Neural Morphology

Neural systems MAY infer or generate Morphology.

```text
Pattern / Field
       ↓
Neural Inference
       ↓
Morphological Structure
```

The reverse relationship is also possible:

```text
Morphology
    ↓
Neural Encoding
    ↓
Pattern / Representation
```

Neural computation therefore participates naturally in the bidirectional Pattern ↔ Morphology relationship.

---

# Neural Agents

Agents MAY use Neural computation for:

* perception;
* policy;
* memory;
* planning;
* prediction;
* adaptation;
* control.

However:

> Neural computation does not define agency.

An Agent may be neural, non-neural, hybrid, symbolic, procedural, or emergent.

---

# Neural Perception

Neural computation may implement perception by transforming observations into semantic representations.

```text
Environment
     ↓
Observation
     ↓
Neural Perception
     ↓
Representation
     ↓
Agent / System
```

Perception semantics remain defined by the Perception domain.

---

# Neural Control

Neural systems MAY implement controllers.

A neural controller may map:

```text
State / Observation
        ↓
Neural Controller
        ↓
Control Action
```

Control semantics remain defined by the Control domain.

---

# Neural Evolution

Neural architectures or parameters MAY evolve through:

* mutation;
* selection;
* recombination;
* structural adaptation;
* evolutionary optimization.

Evolutionary processes MUST remain distinct from ordinary parameter training.

---

# Neural Uncertainty

Neural systems MAY represent uncertainty in:

* inputs;
* parameters;
* outputs;
* latent representations;
* predictions;
* state.

Uncertainty semantics MUST be explicit where required.

---

# Neural Equivalence

Two neural implementations MAY be semantically equivalent even when they differ in:

* topology;
* parameterization;
* numerical representation;
* execution strategy;
* hardware;
* library;
* model format.

Equivalence MUST be established relative to the relevant semantic contract.

Possible equivalence levels include:

* exact;
* numerical;
* functional;
* behavioural;
* observational;
* probabilistic;
* task-level.

---

# Neural State Evolution

Neural state changes MAY be represented as semantic deltas.

Examples:

* activation changes;
* recurrent-state changes;
* parameter updates;
* topology modifications;
* learned representation changes.

These are semantic changes rather than storage-level diffs.

---

# Neural Streams

Neural computation MAY operate as a stream:

```text
Input Stream
     ↓
Neural Transformation
     ↓
State Evolution
     ↓
Output Stream
```

Streaming neural computation may support:

* online inference;
* continual learning;
* event processing;
* temporal models;
* distributed neural computation.

Transport mechanisms remain implementation concerns.

---

# Provenance

Neural computations SHOULD preserve provenance for:

* model origin;
* parameter versions;
* training data;
* training process;
* architecture;
* transformations;
* inference;
* updates;
* provider;
* execution environment.

Provenance is especially important for learned systems.

---

# Versioning

A neural model version MUST distinguish relevant changes to:

* architecture;
* parameters;
* training procedure;
* data;
* objective;
* preprocessing;
* postprocessing;
* semantic contract.

A parameter update MUST NOT necessarily constitute a new semantic model.

The appropriate versioning level depends upon the declared contract.

---

# Determinism

Neural operations MAY be:

* deterministic;
* stochastic;
* conditionally deterministic.

Sources of stochasticity SHOULD be explicitly represented where reproducibility is required.

---

# Performance Semantics

Neural execution may be affected by:

* parameter count;
* activation size;
* sparsity;
* sequence length;
* batch size;
* memory bandwidth;
* parallelism;
* vectorization;
* accelerator availability;
* precision;
* communication overhead.

These characteristics MUST NOT redefine neural semantics.

---

# Numerical Semantics

Neural implementations MAY use:

* exact representations;
* floating-point representations;
* reduced precision;
* quantized representations;
* approximate computation.

Changes in numerical representation MUST be explicit where they can affect semantic guarantees.

---

# Hardware Awareness

Neural execution SHOULD exploit available hardware capabilities including:

* CPU vector units;
* GPUs;
* tensor accelerators;
* neuromorphic hardware;
* distributed systems;
* specialized accelerators.

Hardware selection is an execution concern.

Hardware MUST NOT become semantic authority.

---

# Provider Model

External neural systems MAY act as providers.

Examples include:

* neural-network runtimes;
* tensor libraries;
* inference engines;
* accelerator APIs;
* model formats;
* training frameworks.

Providers implement declared Neural semantics.

They do not define the semantic domain.

---

# MLIR Representation

Neural semantics MAY be represented using MLIR operations, types, dialects, interfaces, and transformations.

Potential representations MAY include:

* neural operations;
* parameter objects;
* signal types;
* graph structures;
* differentiable operations;
* stateful operations;
* training operations;
* inference operations.

MLIR remains the compilation infrastructure.

It does not define neural meaning.

Conceptually:

```text
Neural Semantics
       ↓
Neural IR
       ↓
MLIR
       ↓
Lowering
       ↓
Provider / Runtime
       ↓
CPU / GPU / Accelerator / Distributed System
```

---

# Semantic Hypergraph Integration

Neural systems SHOULD be representable within the Semantic Hypergraph.

A neural system may contain:

```text
Neural System
├── Architecture
├── Units
├── Connections
├── Parameters
├── State
├── Signals
├── Representations
├── Objectives
├── Learning Processes
├── Transformations
├── Versions
└── Provenance
```

Connections and higher-order structures SHOULD be represented as semantic relationships rather than reduced to implementation-specific arrays.

---

# Representation Independence

Neural semantics MUST remain independent of:

* tensors;
* arrays;
* matrices;
* memory layouts;
* model files;
* serialized graphs;
* framework-specific modules;
* GPU buffers;
* accelerator memory.

These are representations or execution mechanisms.

---

# Runtime Semantics

The SCR runtime MAY:

* execute neural transformations;
* maintain neural state;
* route signals;
* schedule computation;
* select providers;
* specialize models;
* compile kernels;
* manage model versions;
* stream inference;
* manage parameter updates;
* monitor semantic contracts;
* checkpoint neural state;
* distribute neural computation.

Runtime optimization MUST preserve declared semantics.

---

# Capabilities

Neural operations MAY declare capabilities including:

* `Differentiable`
* `Trainable`
* `Inferable`
* `Stateful`
* `Stateless`
* `Recurrent`
* `Temporal`
* `Stochastic`
* `Deterministic`
* `Parallelizable`
* `Vectorizable`
* `Sparse`
* `Streamable`
* `Distributed`
* `Quantizable`
* `Composable`
* `Adaptive`
* `Online`
* `Batch`
* `GraphStructured`
* `FieldStructured`.

Capabilities describe semantic properties rather than implementation choices.

---

# Errors and Failure Semantics

Neural errors MAY include:

* invalid architecture;
* invalid topology;
* incompatible signal;
* invalid parameter;
* invalid state;
* shape/semantic mismatch;
* unsupported operation;
* numerical instability;
* convergence failure;
* invalid gradient;
* provider failure;
* resource exhaustion;
* unavailable capability.

Errors SHOULD identify the semantic layer at which failure occurred.

---

# Security and Isolation

Neural execution MAY involve:

* untrusted models;
* untrusted parameters;
* external providers;
* resource-intensive computation;
* model-generated actions.

Systems SHOULD support:

* capability isolation;
* resource limits;
* provenance;
* model integrity;
* execution isolation;
* controlled provider access.

---

# Standards and Interoperability

SCR Neural SHOULD reuse established standards where applicable.

Potential interoperability mechanisms include:

* ONNX;
* MLIR;
* tensor/model interchange standards;
* JSON/JSON-LD;
* URI/IRI;
* established provenance standards;
* established numerical standards.

External model formats are representations.

They MUST NOT become semantic authorities over SCR Neural.

---

# Expected Subdomains

The following structure is illustrative:

```text
neural/
├── neural-core
├── unit
├── neuron
├── population
├── connection
├── synapse
├── topology
├── architecture
├── parameter
├── state
├── signal
├── activation
├── aggregation
├── propagation
├── recurrence
├── temporal
├── spiking
├── representation
├── embedding
├── latent
├── attention
├── memory
├── module
├── composition
├── graph
├── field
├── perception
├── control
├── agent
├── objective
├── loss
├── gradient
├── learning
├── training
├── inference
├── adaptation
├── plasticity
├── evolution
├── uncertainty
├── optimisation
├── approximation
├── quantization
├── sparsity
├── pruning
├── distillation
├── state
├── delta
├── stream
├── version
├── provenance
├── equivalence
├── capability
└── provider
```

This structure is illustrative and does not require immediate implementation of every subdomain.

---

# Invariants

## NEURAL-INV-001 — Semantic Primacy

Neural semantics MUST remain independent of implementation technology.

## NEURAL-INV-002 — Structural Integrity

Neural computational structure MUST remain semantically distinguishable from its physical or memory representation.

## NEURAL-INV-003 — Parameter Integrity

Parameters MUST remain distinguishable from neural runtime state.

## NEURAL-INV-004 — Signal Integrity

Signals MUST remain distinguishable from their physical or memory representation.

## NEURAL-INV-005 — Topology Integrity

Neural topology MUST remain distinguishable from hardware and storage topology.

## NEURAL-INV-006 — State Integrity

Neural state MUST have explicit semantics and temporal interpretation where applicable.

## NEURAL-INV-007 — Learning Integrity

Learning MUST remain distinguishable from inference.

## NEURAL-INV-008 — Objective Integrity

Objectives MUST remain distinguishable from optimization mechanisms.

## NEURAL-INV-009 — Representation Independence

Neural meaning MUST NOT depend on a particular tensor, array, or model representation.

## NEURAL-INV-010 — Provider Independence

External neural frameworks MUST NOT become semantic authorities.

## NEURAL-INV-011 — Temporal Integrity

Temporal neural semantics MUST remain distinct from wall-clock execution.

## NEURAL-INV-012 — Differentiation Integrity

Gradient semantics MUST remain distinguishable from automatic-differentiation implementation.

## NEURAL-INV-013 — Equivalence Integrity

Substitution between neural implementations MUST require an appropriate equivalence guarantee.

## NEURAL-INV-014 — Provenance Integrity

Training, inference, adaptation, and parameter evolution SHOULD preserve provenance.

## NEURAL-INV-015 — Numerical Integrity

Approximation and reduced precision MUST NOT silently change declared semantic guarantees.

## NEURAL-INV-016 — Composition Integrity

Composed neural systems MUST preserve compatible signal, state, and transformation contracts.

## NEURAL-INV-017 — Domain Independence

Neural computation MUST remain usable independently of Agents, AI, Simulation, or any other particular application domain.

## NEURAL-INV-018 — Hardware Independence

Neural semantics MUST remain independent of the execution hardware while permitting hardware-aware realization.

---

# Domain Relationships

| Domain       | Relationship    | Meaning                                                                                |
| ------------ | --------------- | -------------------------------------------------------------------------------------- |
| Core         | REFINES         | Neural specializes computational structures, transformations, state, and relationships |
| Data         | COMPOSES        | Neural computation transforms and maintains semantic information                       |
| Mathematics  | DEPENDS_ON      | Neural transformations and learning use mathematical semantics                         |
| Graphs       | COMPOSES        | Neural systems may operate directly over graph structures                              |
| Fields       | COMPOSES        | Neural computation may operate over distributed fields                                 |
| Geometry     | INTERACTS_WITH  | Neural systems may encode and transform geometric structures                           |
| Topology     | CONSTRAINS      | Neural architecture may possess meaningful structural topology                         |
| Morphology   | TRANSFORMS      | Neural systems may infer or generate morphology                                        |
| Physics      | INTERACTS_WITH  | Neural systems may model or control physical systems                                   |
| Dynamics     | PARTICIPATES_IN | Neural state and parameters may evolve dynamically                                     |
| Simulation   | EXECUTES_IN     | Neural systems may participate in simulations                                          |
| Agents       | IMPLEMENTS      | Neural computation may implement perception, policy, memory, and adaptation            |
| Perception   | IMPLEMENTS      | Neural computation may realize perceptual transformations                              |
| Optimization | DEPENDS_ON      | Optimization may train neural parameters                                               |
| Control      | IMPLEMENTS      | Neural computation may realize control policies                                        |
| Rendering    | INTERACTS_WITH  | Neural systems may generate or interpret render representations                        |

These relationships are semantic relationships and do not automatically imply implementation dependencies.

---

# Testing Requirements

Neural implementations MUST support testing across the SCR testing hierarchy:

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

* structural correctness;
* signal propagation;
* parameter semantics;
* state transitions;
* recurrence;
* temporal behaviour;
* deterministic behaviour;
* stochastic behaviour;
* gradient correctness;
* learning behaviour;
* inference behaviour;
* topology transformations;
* representation equivalence;
* numerical approximation;
* provider equivalence;
* serialization/interoperability;
* distributed execution.

---

# Validation Requirements

Neural validation SHOULD determine whether:

1. the neural structure satisfies its declared contract;
2. signals have compatible semantics;
3. transformations produce valid results;
4. state transitions are valid;
5. learning updates satisfy declared semantics;
6. gradients are semantically correct where required;
7. stochasticity is correctly declared;
8. numerical approximations remain within declared guarantees;
9. provider substitutions preserve required equivalence;
10. model provenance is preserved.

---

# Function-Level Requirements

Every Neural function MUST specify, where applicable:

* semantic purpose;
* input signals;
* output signals;
* unit structure;
* topology;
* parameters;
* state;
* transformation;
* temporal semantics;
* stochasticity;
* differentiability;
* learning behaviour;
* side effects;
* resource requirements;
* provenance;
* errors;
* capabilities;
* equivalence requirements.

---

# Completeness Criteria

The Neural domain definition is complete only when:

* neural computational units are representable;
* connections are first-class;
* topology is explicit;
* parameters are explicit;
* state is explicit;
* signals are explicit;
* transformations are explicit;
* recurrence is representable;
* temporal computation is representable;
* spiking computation is representable;
* representations and embeddings are representable;
* attention is representable;
* neural memory is representable;
* learning is representable;
* training is distinguishable from inference;
* objectives and losses are explicit;
* gradients are representable;
* adaptation and plasticity are representable;
* uncertainty is representable;
* neural computation can operate over graphs;
* neural computation can operate over fields;
* neural computation can interact with morphology and geometry;
* neural computation can implement agent capabilities;
* state deltas are representable;
* neural streams are representable;
* provenance is preserved;
* model versioning is supported;
* equivalence is explicit;
* provider independence is maintained;
* hardware independence is maintained;
* MLIR remains compilation infrastructure rather than semantic authority.

---

# Architectural Rules

1. **Neural computation MUST NOT be equated with artificial intelligence.**
2. **Neural computation MUST NOT be equated with Agents.**
3. **Neural computation MUST NOT require learning.**
4. **Neural computation MUST NOT require biological neurons.**
5. **Neural topology MUST remain semantically distinct from hardware topology.**
6. **Parameters MUST remain distinct from runtime state.**
7. **Training MUST remain distinct from inference.**
8. **Learning MUST remain distinct from optimization algorithms.**
9. **Gradient semantics MUST remain distinct from automatic differentiation implementations.**
10. **Representations MUST remain distinct from semantic meaning.**
11. **External neural frameworks MUST be treated as providers.**
12. **Neural computation MUST be usable independently by multiple higher-level domains.**
13. **Neural computation MAY operate over graphs, fields, geometry, morphology, and other semantic structures.**
14. **Neural computation MAY implement agent capabilities without defining agency.**
15. **Neural computation MAY implement perception without defining perception itself.**
16. **Neural computation MAY implement control without defining control itself.**
17. **Approximation and quantization MUST be explicit when they affect semantic guarantees.**
18. **Temporal semantics MUST remain distinct from execution time.**
19. **Hardware-aware optimization MUST preserve neural semantic contracts.**
20. **MLIR MUST remain a representation and compilation substrate rather than the authority over neural meaning.**

---

# Open Semantic Questions

The following remain intentionally open:

* How should a general neural computational unit be formally typed?
* How should neural topology be represented natively in the Semantic Hypergraph?
* How should dynamic topology changes be represented?
* How should continuous-time neural computation be unified with discrete-time computation?
* How should spiking and non-spiking systems share a common semantic model?
* How should learned parameters acquire semantic identity and provenance?
* How should latent representations declare which properties they preserve?
* How should neural equivalence be formally established?
* How should approximation guarantees be represented?
* How should neural uncertainty interact with Field uncertainty?
* How should neural operators interact with arbitrary Fields?
* How should neural computation interact with Morphological emergence?
* How should differentiable simulations expose gradients to Neural?
* How should neural models become executable semantic transformations within MLIR?
* How should online adaptation interact with reproducibility?
* How should distributed neural state preserve causal semantics?
* How should model architecture and learned parameters be versioned independently?
* How should neural computation participate in evolutionary systems?
* How should neural computation expose interpretable semantic structure without imposing a particular interpretability theory?

These questions SHOULD remain open until sufficient semantic requirements exist to resolve them.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Established:

* neural computation as a general semantic computational domain;
* computational units;
* connections;
* topology;
* parameters;
* state;
* signals;
* propagation;
* recurrence;
* temporal computation;
* spiking computation;
* representations;
* embeddings;
* latent spaces;
* attention;
* memory;
* learning;
* training;
* inference;
* objectives;
* losses;
* gradients;
* plasticity;
* architecture;
* modularity;
* compositionality;
* graph neural computation;
* neural fields;
* neural morphology;
* neural agents;
* neural perception;
* neural control;
* neural evolution;
* uncertainty;
* equivalence;
* streams and deltas;
* provenance;
* versioning;
* provider independence;
* MLIR integration;
* hardware-aware execution.

---

# Definition Authority

This document is the normative semantic definition of the SCR Neural domain.

Implementation documents, source code, neural-network frameworks, model formats, inference engines, training systems, examples, benchmarks, and generated artifacts MUST NOT redefine this domain without an explicit semantic revision.

---

# Definition Principle

> **Neural computation is the semantic transformation of information through structured, interconnected computational units whose signals, state, parameters, and adaptation may participate in computation across time.**

The fundamental separation is:

```text
SEMANTIC INFORMATION
        ↓
NEURAL STRUCTURE
        ↓
SIGNAL TRANSFORMATION
        ↓
STATE / REPRESENTATION
        ↓
OUTPUT
        ↕
LEARNING / ADAPTATION
```

Neural computation can therefore serve as a **general computational substrate** for perception, prediction, control, learning, morphology generation, field transformation, graph processing, and agent behaviour without becoming semantically identical to any of them.
