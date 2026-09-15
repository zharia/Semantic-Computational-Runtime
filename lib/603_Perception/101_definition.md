---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PERCEPTION
name: Perception
version: 0.2.0
status: normative
created: 2026-09-15
updated: 2026-09-15

authority: SCR
domain: semantic-library
------------------------

# Perception

## 1. Definition

Perception is the semantic computational domain concerned with the **transformation of available observations and information into representations that are meaningful to a declared perceiving system, process, agent, or computational context**.

Perception establishes a relationship between:

```text
Available Information
        ↓
   Perceptual Process
        ↓
Semantic Representation
```

Perception therefore concerns what a computational system can derive, distinguish, represent, or maintain from information available to it.

Perception is inherently relative to:

* an observer or perceiving system;
* available information;
* a declared context;
* a perceptual process;
* a representation;
* a set of semantic distinctions or invariants.

Perception does **not** imply consciousness, cognition, intelligence, neural computation, biological sensing, or human experience.

---

# 2. Fundamental Distinctions

SCR MUST distinguish the following concepts:

```text
Source / State
      ↓
Acquisition / Access
      ↓
Observation
      ↓
Perception
      ↓
Representation
      ↓
Interpretation / Inference
      ↓
Decision / Action
```

These stages may be implemented together, but their semantic meanings remain distinct.

## 2.1 Observation

An Observation is information available to a computational system concerning a source, state, phenomenon, entity, field, process, or environment.

Observation does not assert that the represented information is complete, accurate, or directly equivalent to the underlying state.

## 2.2 Perception

Perception transforms available information into a representation relative to a perceiving system and context.

## 2.3 Interpretation

Interpretation assigns semantic significance to a representation.

Interpretation may be a component of perception, but Perception MUST NOT be defined as authoritative interpretation of reality itself.

## 2.4 Inference

Inference derives information from available information through a declared computational, mathematical, statistical, logical, neural, or other process.

Inference may participate in perception but is not synonymous with perception.

## 2.5 Action

Action changes or attempts to change semantic state.

Action belongs to the interaction/control/execution architecture rather than being a constituent definition of Perception.

---

# 3. Perception as Observer-Relative Transformation

A perceptual process can be represented conceptually as:

```text
P = (O, C, K, T, R, U, X)
```

where:

* `O` = available observations;
* `C` = context;
* `K` = prior knowledge or available semantic state;
* `T` = perceptual transformation;
* `R` = resulting representation;
* `U` = uncertainty;
* `X` = provenance.

A perceptual process MAY additionally depend upon:

* goals;
* temporal history;
* spatial reference;
* task constraints;
* semantic contracts;
* available capabilities;
* computational resources.

The model does not require every component.

---

# 4. Scope

SCR Perception includes semantics for:

* observation processing;
* perceptual transformation;
* feature extraction;
* detection;
* recognition;
* classification;
* segmentation;
* localization;
* identification;
* correspondence;
* tracking;
* estimation;
* perceptual inference;
* interpretation;
* context;
* attention;
* salience;
* multimodal integration;
* temporal integration;
* spatial integration;
* representation;
* abstraction;
* equivalence;
* invariance;
* uncertainty;
* ambiguity;
* missing information;
* occlusion;
* resolution;
* sampling;
* active perception;
* predictive perception;
* perceptual fields;
* perceptual graphs;
* perceptual streams;
* perceptual deltas;
* provenance.

These concepts are semantic capabilities, not requirements that every implementation provide all of them.

---

# 5. What Perception Is Not

Perception MUST remain distinct from:

* raw sensing;
* device input;
* data storage;
* measurement;
* signal transport;
* signal processing;
* rendering;
* graph storage;
* neural computation;
* general inference;
* cognition;
* consciousness;
* decision making;
* action;
* control;
* user-interface semantics.

These mechanisms may participate in perceptual computation without defining its semantic boundary.

---

# 6. Observation Boundary

Observation is the principal input boundary of Perception.

An observation MAY be:

* direct;
* indirect;
* partial;
* noisy;
* delayed;
* sampled;
* aggregated;
* transformed;
* simulated;
* externally supplied;
* internally exposed;
* inferred from another observation.

The underlying state and its observation MUST remain distinguishable.

```text
Underlying State
       │
       ▼
   Observation
       │
       ▼
    Perception
```

An observation MAY contain less information, differently structured information, or information expressed in another representation than the underlying state.

---

# 7. Observation Is Not Absence

The absence of an observation MUST NOT automatically imply absence of the observed phenomenon.

For example:

```text
No Observation
      ≠
Phenomenon Absent
```

The distinction may arise from:

* occlusion;
* limited range;
* insufficient resolution;
* sampling;
* communication failure;
* sensor failure;
* computational filtering;
* unavailable access;
* temporal mismatch;
* semantic filtering.

A perceptual system MUST be able to represent relevant unknown or unobserved states.

---

# 8. Sensing and Acquisition

Sensing and acquisition describe mechanisms through which information becomes available.

They MAY include:

* physical sensors;
* simulated sensors;
* software APIs;
* files;
* streams;
* queries;
* computational probes;
* semantic-field access;
* remote systems;
* internal process state.

Concrete acquisition mechanisms belong to implementation/provider architecture.

Perception defines what is done semantically with the resulting information.

---

# 9. Modality

A modality is a semantic classification of available information according to characteristics relevant to perception.

Modalities MAY include:

* visual;
* auditory;
* tactile;
* thermal;
* chemical;
* electromagnetic;
* proprioceptive;
* textual;
* symbolic;
* numerical;
* spatial;
* temporal;
* semantic.

A modality is not necessarily equivalent to a physical sensor.

The same physical source MAY provide multiple modalities.

Multiple physical sources MAY provide one modality.

---

# 10. Perceptual Transformation

A perceptual transformation converts one information representation into another representation having declared semantic significance.

Examples include:

```text
Signal → Feature
Feature → Detection
Detection → Entity
Observation → Geometry
Observations → Track
Observations → Scene
Field → Region
Graph → Pattern
Pattern → Classification
Multiple Modalities → Integrated Representation
```

A perceptual transformation MUST declare its relevant semantic assumptions.

---

# 11. Feature

A Feature is a semantically relevant property extracted from or associated with an observation or representation.

Features MAY describe:

* geometry;
* topology;
* morphology;
* colour;
* texture;
* motion;
* frequency;
* temporal behaviour;
* statistical structure;
* relational structure;
* semantic properties.

A Feature is meaningful only relative to its declared semantic context or perceptual purpose.

---

# 12. Detection

Detection determines whether a declared phenomenon, pattern, condition, or entity is present or potentially present.

Detection MAY produce:

* Boolean results;
* ranked candidates;
* probabilities;
* scores;
* continuous measures;
* hypotheses.

Detection MUST NOT be assumed to establish identity.

```text
Detection
    ≠
Identification
```

---

# 13. Recognition

Recognition associates an observation or representation with a known or inferred semantic category, structure, pattern, or phenomenon.

Recognition MAY depend on:

* prior knowledge;
* learned representations;
* context;
* similarity;
* structure;
* temporal history.

Recognition does not necessarily establish persistent identity.

---

# 14. Classification

Classification maps observations or representations into declared semantic categories.

Classification MAY be:

* single-label;
* multi-label;
* hierarchical;
* probabilistic;
* fuzzy;
* open-set;
* contextual.

The classification scheme itself is semantic information and MUST therefore be represented explicitly where necessary.

---

# 15. Identification

Identification associates an observation with a semantic identity.

Identification MUST remain distinct from:

* classification;
* similarity;
* appearance;
* recognition;
* representation equality.

Two observations MAY identify the same semantic entity without being identical representations.

Identity remains governed by SCR identity and provenance semantics.

---

# 16. Segmentation

Segmentation partitions an observation, field, graph, space, temporal interval, or other domain into semantically meaningful regions.

Segmentation MAY be:

* spatial;
* temporal;
* geometric;
* topological;
* morphological;
* graph-based;
* field-based;
* semantic.

Segmentation is not restricted to images.

---

# 17. Localization

Localization determines the position of a phenomenon or entity relative to a declared reference system.

Localization MAY operate over:

* Euclidean spaces;
* geospatial spaces;
* semantic spaces;
* graphs;
* manifolds;
* fields;
* temporal domains.

Localization MUST declare its reference system.

---

# 18. Correspondence and Tracking

Correspondence establishes relationships between observations or representations that may refer to the same evolving phenomenon or entity.

Tracking maintains correspondence over time.

```text
Observationₜ
     ↓
Correspondence
     ↓
Observationₜ₊₁
     ↓
Temporal Representation
```

Tracking MUST preserve identity and provenance where the relevant semantic contract requires them.

Tracking MUST distinguish:

* actual identity;
* inferred correspondence;
* similarity;
* trajectory;
* prediction.

---

# 19. Estimation

Estimation derives an approximation of a latent, unavailable, or incompletely observed quantity.

Examples include:

* position;
* velocity;
* state;
* environmental condition;
* probability;
* future state.

Estimated information MUST remain distinguishable from directly observed information.

---

# 20. Perceptual Inference

Perceptual inference derives information not directly available in an observation.

Inference MAY use:

* mathematical models;
* constraints;
* prior knowledge;
* contextual relationships;
* learned models;
* probabilistic models;
* neural computation;
* graph structure;
* physical models;
* temporal history.

Inference MUST preserve provenance sufficient to distinguish derived information from source information.

---

# 21. Interpretation

Interpretation assigns semantic significance to an existing representation.

Interpretation MAY depend on:

* context;
* task;
* goals;
* ontology;
* prior knowledge;
* relationships;
* temporal state;
* observer.

The same representation MAY admit different interpretations under different semantic contexts.

---

# 22. Context

Context is information relevant to determining the semantic meaning of an observation or perceptual result.

Context MAY include:

* spatial state;
* temporal state;
* environmental state;
* observer state;
* task;
* goals;
* history;
* relationships;
* domain;
* semantic knowledge.

Context dependencies MUST be representable when they affect perceptual results.

---

# 23. Attention

Attention is the selective allocation of computational or representational resources toward portions of available information.

Attention MAY operate over:

* spatial regions;
* temporal intervals;
* graph neighbourhoods;
* modalities;
* entities;
* fields;
* signals;
* representations.

Attention MUST NOT be interpreted as consciousness.

---

# 24. Salience

Salience describes the relative significance of information for a declared perceiving system, context, or task.

Salience MAY depend upon:

* novelty;
* contrast;
* relevance;
* uncertainty;
* goals;
* context;
* change.

Salience is therefore observer- and context-relative.

---

# 25. Multimodal Perception

Perception MAY combine information from multiple modalities.

```text
Modality A ──┐
Modality B ──┼──→ Perceptual Integration
Modality C ──┘
```

Integration MAY occur:

* before feature extraction;
* between representations;
* after independent inference;
* through shared latent structures;
* through explicit semantic relationships.

Multimodal integration MUST preserve source provenance where required.

---

# 26. Temporal Perception

Perception MAY integrate information across time.

Temporal perception MAY support:

* persistence;
* motion;
* event detection;
* prediction;
* temporal pattern recognition;
* state estimation;
* change detection.

SCR MUST distinguish:

* observation time;
* source/event time;
* semantic time;
* simulation time;
* processing time;
* execution time.

These times MUST NOT be conflated merely because an implementation uses one clock.

---

# 27. Spatial Perception

Perception MAY derive spatial information from observations.

Spatial perceptual results MAY include:

* position;
* distance;
* orientation;
* geometry;
* topology;
* morphology;
* spatial relationships;
* occupancy;
* boundaries;
* regions.

Spatial semantics remain governed by the Spatial, Geometry, Topology, and Morphology domains.

Perception defines how such information is derived or represented.

---

# 28. Perceptual Representation

A Perceptual Representation is a semantic representation produced by a perceptual process for use by a declared consumer.

It MAY be represented as:

* a scalar;
* vector;
* tensor;
* symbolic structure;
* graph;
* hypergraph;
* field;
* geometric structure;
* topological structure;
* morphological structure;
* embedding;
* categorical state;
* probability distribution;
* semantic entity;
* semantic relation.

The representation MUST NOT be confused with the underlying phenomenon.

---

# 29. Abstraction

Perception MAY operate at multiple abstraction levels.

```text
Available Information
        ↓
Features
        ↓
Structures
        ↓
Entities
        ↓
Relations
        ↓
Situations
        ↓
Higher-Level Representations
```

Higher-level abstraction MUST NOT imply that lower-level information no longer exists.

Multiple perceptual representations MAY coexist simultaneously.

---

# 30. Perceptual Equivalence

Two representations MAY be perceptually equivalent relative to a declared observer, task, context, and contract.

```text
Representation A
       ≈
Representation B
```

Perceptual equivalence MUST specify, where relevant:

* observer;
* context;
* task;
* resolution;
* invariants;
* tolerance;
* modality;
* intended consumer.

Perceptual equivalence does not imply numerical, structural, or implementation equality.

---

# 31. Perceptual Invariance

A perceptual transformation MAY preserve selected semantic properties while changing representation.

Potential invariances include:

* translation;
* rotation;
* scale;
* illumination;
* noise;
* temporal displacement;
* representation format;
* coordinate representation.

Invariance MUST be declared rather than assumed.

---

# 32. Uncertainty

Perception MUST be capable of representing uncertainty.

Uncertainty MAY arise from:

* noisy observations;
* ambiguity;
* occlusion;
* missing information;
* limited resolution;
* model uncertainty;
* stochastic processes;
* conflicting observations;
* incomplete context.

Uncertainty MUST NOT be silently converted into certainty.

---

# 33. Confidence

Confidence is a declared measure associated with a perceptual result.

Confidence MUST NOT automatically be interpreted as probability.

Its semantics MUST be explicitly declared.

For example:

```text
confidence = 0.8
```

does not by itself establish:

```text
P(result is correct) = 0.8
```

unless the governing contract explicitly defines that relationship.

---

# 34. Ambiguity

An observation or representation is ambiguous when multiple semantic interpretations remain consistent with available information.

SCR Perception SHOULD be capable of representing multiple hypotheses:

```text
Observation
     ↓
 ┌───┼───┐
 ▼   ▼   ▼
H₁   H₂  H₃
```

Premature selection of one hypothesis MUST NOT destroy materially relevant alternatives without a declared semantic reason.

---

# 35. Predictive Perception

Perception MAY use models to predict:

* future observations;
* latent state;
* likely entities;
* expected measurements;
* expected field state.

Predicted information MUST remain distinguishable from observed information.

```text
Observed
   │
   ├──→ Perception
   │
   └──→ Prediction
             │
             ▼
       Predicted State
```

Prediction does not become observation merely because it is highly confident.

---

# 36. Active Perception

A perceptual system MAY select observations according to current information requirements.

```text
Current Representation
        ↓
Uncertainty / Information Need
        ↓
Observation Selection
        ↓
New Observation
        ↓
Updated Representation
```

Active perception MAY involve:

* changing viewpoint;
* selecting sensors;
* requesting additional data;
* increasing resolution;
* changing sampling rate;
* querying another computational space;
* requesting another agent's observation.

Active perception MAY interact with Action and Control but does not make either domain part of Perception.

---

# 37. Perception and Interaction

Interaction and Perception are complementary but distinct.

```text
Environment
     ↓
Observation
     ↓
Perception
     ↓
Semantic Representation
     ↓
Intent / Decision
     ↓
Action
     ↓
Environment
```

Perception provides information for Interaction.

Interaction determines how an actor or computational entity participates in the semantic field.

Gesture, intent, action, commitment, cancellation, and interaction sessions belong to `605_Interaction`.

Perception may consume interaction observations, but MUST NOT redefine them.

---

# 38. Perception and Agents

Agents MAY use Perception to maintain internal or external representations.

```text
Environment
     ↓
Observation
     ↓
Perception
     ↓
Agent Representation
     ↓
Decision
```

Perception is not restricted to Agents.

Non-agent systems MAY perform perception, including:

* monitoring systems;
* simulations;
* databases;
* distributed systems;
* rendering systems;
* compilers;
* runtime systems;
* autonomous processes.

---

# 39. Perception and Neural Computation

Neural computation is one possible implementation mechanism for perception.

```text
Observation
     ↓
Neural Computation
     ↓
Perceptual Representation
```

Neural computation MUST NOT become the semantic authority for Perception.

Equivalent perceptual semantics MAY be implemented through:

* analytical algorithms;
* symbolic computation;
* geometric algorithms;
* statistical methods;
* neural models;
* learned models;
* procedural computation;
* hybrid methods.

---

# 40. Perception and Semantic Fields

Semantic Fields MAY be both sources and products of perception.

Examples include:

* physical fields;
* spatial fields;
* probability fields;
* salience fields;
* confidence fields;
* computational fields;
* semantic state fields.

Perception MAY transform one semantic field into another semantic representation.

The resulting perceptual representation remains subject to canonical SCR hypergraph semantics.

---

# 41. Perception and Hypergraphs

Perceptual results MUST be representable within the canonical SCR semantic hypergraph.

A perceptual result MAY contain:

```text
Perceptual Result
├── Source Observation
├── Context
├── Features
├── Entities
├── Relationships
├── Interpretations
├── Hypotheses
├── Confidence
├── Uncertainty
├── Temporal State
└── Provenance
```

Higher-order perceptual structures SHOULD use hyperrelationships where pairwise decomposition would lose semantic information.

Perception MUST NOT create a competing semantic graph that becomes authoritative independently of the SCR hypergraph.

---

# 42. Reference Semantics

Perceptual results may reference:

* observations;
* entities;
* fields;
* representations;
* hypotheses;
* semantic relationships;
* source provenance.

References MUST use SCR semantic identity and reference semantics.

Provider handles, memory addresses, database keys, filenames, object pointers, and device identifiers MUST NOT become semantic identity merely because they are used by an implementation.

---

# 43. Nullary Relations

Perception MUST support nullary relations where they are semantically meaningful.

A nullary relation MAY represent a perceptual assertion, state, or condition without participating entity references.

Zero arguments MUST NOT be interpreted as absence of semantic content.

---

# 44. Deletion Semantics

Deletion of a perceptual result is a semantic lifecycle operation.

SCR MUST distinguish:

* deletion of a representation;
* invalidation of a representation;
* withdrawal of an observation;
* supersession;
* historical retention;
* tombstone state;
* deletion of references;
* destruction of provider resources.

Deleting a perceptual representation MUST NOT silently imply deletion of the source observation or underlying entity.

Likewise, deleting an underlying entity MUST NOT automatically erase historical perceptual provenance where retention is semantically required.

---

# 45. Provenance

Perceptual results SHOULD preserve provenance sufficient to identify:

* source observation;
* source entity or field;
* acquisition mechanism;
* transformations;
* models;
* context;
* temporal information;
* uncertainty;
* provider;
* provider version;
* execution environment;
* semantic contract.

Provenance is distinct from identity.

A perceptual result may have its own identity while referencing the identities of its sources.

---

# 46. Representation Independence

Perception semantics MUST remain independent of implementation representation such as:

* image buffers;
* audio buffers;
* tensors;
* point clouds;
* database records;
* memory layouts;
* serialization formats;
* device handles;
* neural-network weights;
* vendor APIs.

These are implementation representations.

---

# 47. Provider Boundary

Concrete perception implementations belong to the Provider architecture.

Examples MAY include:

* computer-vision libraries;
* sensor frameworks;
* signal-processing libraries;
* neural models;
* geometric algorithms;
* statistical inference systems;
* external perception services.

The relationship is:

```text
Perceptual Capability
        ↓
Semantic Contract
        ↓
Implementation Binding
        ↓
Adapter / Artifact
        ↓
Provider
        ↓
Execution Runtime
```

Providers MUST NOT become semantic authorities.

The Perception domain therefore does **not** contain a `provider` semantic subdomain.

---

# 48. Runtime Semantics

The SCR runtime MAY:

* route observations;
* schedule perceptual transformations;
* maintain perceptual state;
* select providers;
* fuse modalities;
* manage perceptual streams;
* maintain provenance;
* adapt resolution;
* exploit hardware;
* checkpoint state;
* execute active perception;
* maintain incremental representations.

Runtime optimisation MUST preserve declared perceptual contracts and invariants.

---

# 49. MLIR Representation

Perceptual operations MAY be represented through MLIR.

Possible operations include:

* observation transformation;
* feature extraction;
* detection;
* classification;
* segmentation;
* tracking;
* estimation;
* fusion;
* inference;
* representation transformation.

MLIR provides compilation and representation infrastructure.

MLIR does not define the semantic meaning of perception.

---

# 50. Capabilities

Perception operations MAY declare capabilities including:

* `Observable`;
* `Multimodal`;
* `Temporal`;
* `Spatial`;
* `Geometric`;
* `Topological`;
* `Morphological`;
* `Probabilistic`;
* `Deterministic`;
* `Stochastic`;
* `Learnable`;
* `Differentiable`;
* `Streaming`;
* `Incremental`;
* `Adaptive`;
* `Active`;
* `Predictive`;
* `Hierarchical`;
* `Composable`;
* `Distributed`;
* `Parallelizable`.

Capabilities describe semantic or execution properties and MUST NOT be confused with provider identity.

---

# 51. Performance Semantics

Perceptual performance MAY depend upon:

* observation rate;
* resolution;
* latency;
* computational complexity;
* memory;
* bandwidth;
* hardware acceleration;
* modality count;
* temporal history.

Performance MUST remain distinct from semantic meaning.

A faster implementation is not semantically superior merely because it is faster.

---

# 52. Failure Semantics

Perceptual failure MAY include:

* invalid observation;
* missing information;
* incompatible modality;
* insufficient resolution;
* ambiguous result;
* unsupported transformation;
* model failure;
* provider failure;
* numerical failure;
* resource exhaustion;
* temporal inconsistency;
* provenance failure.

A failure MUST NOT silently become a valid perceptual assertion.

In particular:

```text
Failure
  ≠
False Observation
```

unless explicitly defined by the governing contract.

---

# 53. Semantic Security

Perceptual systems MAY process trusted, untrusted, private, or sensitive observations.

Implementations SHOULD support:

* provenance;
* authority;
* access control;
* capability isolation;
* provider isolation;
* resource limits;
* model integrity;
* controlled observation access.

Perception MUST NOT automatically confer authority on the source of an observation.

---

# 54. Domain Relationships

| Domain      | Relationship          | Meaning                                                                                       |
| ----------- | --------------------- | --------------------------------------------------------------------------------------------- |
| Core        | REFINES               | Perception uses foundational semantic identity, state, relation, and transformation semantics |
| Data        | CONSUMES / PRODUCES   | Perception consumes and produces information representations                                  |
| Mathematics | USES                  | Perception may use mathematical transformations and inference                                 |
| Field       | OBSERVES / TRANSFORMS | Fields may provide perceptual information and perceptual results may form fields              |
| Graph       | PRODUCES / ANALYSES   | Perception may derive relational and graph structures                                         |
| Geometry    | INFERS                | Perception may derive geometric properties                                                    |
| Topology    | INFERS                | Perception may derive connectivity and structural properties                                  |
| Morphology  | ANALYSES              | Perception may derive or analyse form and structure                                           |
| Physics     | OBSERVES              | Physical state may become perceptual information                                              |
| Dynamics    | OBSERVES              | Perception may derive temporal state and change                                               |
| Simulation  | CONSUMES              | Simulation may provide controlled observations                                                |
| Agent       | SERVES                | Agents may consume perceptual representations                                                 |
| Neural      | MAY_IMPLEMENT         | Neural computation may implement perceptual transformations                                   |
| Interaction | INFORMS               | Perception may provide information used by interaction semantics                              |
| Control     | INFORMS               | Perception may provide information used by control                                            |
| Render      | OBSERVES              | Rendered manifestations may become observations                                               |
| Stream      | FLOWS_THROUGH         | Perceptual observations and results may be streamed                                           |
| Spatial     | USES                  | Perception may operate over semantic spaces                                                   |

These relationships describe semantic relationships and do not automatically imply implementation dependencies.

---

# 55. Testing Requirements

Perception implementations MUST support the SCR testing hierarchy:

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
Cross-Provider Tests
```

Testing SHOULD include:

* observation distinction;
* detection;
* recognition;
* classification;
* segmentation;
* localization;
* identification;
* correspondence;
* tracking;
* estimation;
* inference;
* uncertainty;
* ambiguity;
* multimodal integration;
* temporal consistency;
* spatial consistency;
* perceptual equivalence;
* invariance;
* provenance;
* streaming;
* incremental updates;
* provider substitution.

---

# 56. Validation Requirements

Validation MUST determine, where applicable, whether:

1. observations are correctly represented;
2. inferred information remains distinguishable from observed information;
3. transformations preserve declared invariants;
4. uncertainty is preserved;
5. ambiguity is represented;
6. context dependencies are explicit;
7. spatial and temporal references are correct;
8. multimodal integration preserves required provenance;
9. perceptual classifications satisfy their contracts;
10. identity is distinguished from similarity;
11. provenance is preserved;
12. deletion and reference semantics remain valid;
13. provider substitution preserves semantic requirements.

---

# 57. Function-Level Requirements

Every Perception function MUST specify, where applicable:

* semantic purpose;
* observation inputs;
* perceptual context;
* transformation;
* output representation;
* spatial semantics;
* temporal semantics;
* uncertainty;
* confidence;
* inference semantics;
* provenance;
* identity semantics;
* determinism;
* stochasticity;
* side effects;
* capabilities;
* resource requirements;
* failure semantics;
* equivalence requirements.

A function MUST NOT rely on undocumented provider behaviour to establish semantic meaning.

---

# 58. Invariants

## PERCEPTION-INV-001 — Semantic Primacy

Perceptual semantics MUST remain independent of implementation technology.

## PERCEPTION-INV-002 — Observation Distinction

Observation MUST remain distinguishable from underlying state.

## PERCEPTION-INV-003 — Perception Distinction

Perception MUST remain distinguishable from observation.

## PERCEPTION-INV-004 — Inference Distinction

Inferred information MUST remain distinguishable from directly observed information.

## PERCEPTION-INV-005 — Representation Independence

Perceptual meaning MUST remain independent of representation format.

## PERCEPTION-INV-006 — Context Integrity

Context affecting perceptual results MUST be representable.

## PERCEPTION-INV-007 — Uncertainty Integrity

Uncertainty MUST NOT be silently converted into certainty.

## PERCEPTION-INV-008 — Ambiguity Integrity

Material alternative hypotheses MUST remain representable.

## PERCEPTION-INV-009 — Provenance Integrity

Derived perceptual results MUST retain sufficient provenance.

## PERCEPTION-INV-010 — Identity Integrity

Identification MUST remain distinct from similarity and classification.

## PERCEPTION-INV-011 — Temporal Integrity

Observation, event, simulation, processing, and execution times MUST remain distinguishable where semantically relevant.

## PERCEPTION-INV-012 — Spatial Integrity

Spatial interpretation MUST preserve declared reference semantics.

## PERCEPTION-INV-013 — Modality Integrity

Multimodal integration MUST preserve modality provenance where required.

## PERCEPTION-INV-014 — Equivalence Integrity

Perceptual equivalence MUST be relative to a declared observer, task, context, and contract.

## PERCEPTION-INV-015 — Provider Independence

Providers MUST NOT become semantic authorities.

## PERCEPTION-INV-016 — Neural Independence

Perception MUST remain meaningful without neural computation.

## PERCEPTION-INV-017 — Agent Independence

Perception MUST remain meaningful without an Agent.

## PERCEPTION-INV-018 — Observation Non-Exclusivity

Absence of observation MUST NOT automatically imply absence of the underlying phenomenon.

## PERCEPTION-INV-019 — Hypergraph Authority

Perceptual relationships MUST remain representable within the canonical SCR semantic hypergraph.

## PERCEPTION-INV-020 — No Competing Graph Authority

Perception MUST NOT establish a separate graph that becomes semantically authoritative.

## PERCEPTION-INV-021 — Reference Integrity

Perceptual references MUST conform to SCR identity and reference semantics.

## PERCEPTION-INV-022 — Deletion Integrity

Deletion of a perceptual representation MUST NOT silently delete its source or historical provenance.

## PERCEPTION-INV-023 — Nullary Relation Integrity

Meaningful nullary perceptual relations MUST remain representable.

## PERCEPTION-INV-024 — Prediction Distinction

Predicted information MUST remain distinguishable from observed information.

## PERCEPTION-INV-025 — Failure Integrity

Perceptual failure MUST NOT silently become a valid semantic assertion.

## PERCEPTION-INV-026 — Interaction Boundary

Perception MUST remain distinct from Intent, Action, Gesture, and Control semantics.

## PERCEPTION-INV-027 — Semantic Contract Integrity

Perceptual functions MUST expose their relevant semantic assumptions through declared contracts.

## PERCEPTION-INV-028 — Provider Substitution

Provider substitution MUST preserve declared perceptual semantics where substitution is permitted.

---

# 59. Architectural Rules

1. Perception MUST remain distinct from Observation.
2. Perception MUST remain distinct from Sensing and Acquisition.
3. Perception MUST remain distinct from general Inference.
4. Perception MUST remain distinct from Action and Control.
5. Perception MUST remain distinct from Interaction.
6. Perception MUST NOT require neural computation.
7. Perception MUST NOT require an Agent.
8. Neural computation MAY implement Perception.
9. Perception MAY operate over Fields, Graphs, Geometry, Topology, Morphology, and Spatial structures.
10. Context MUST be representable where it changes perceptual meaning.
11. Uncertainty MUST NOT be silently discarded.
12. Alternative hypotheses MUST remain representable where materially relevant.
13. Perceptual identity MUST remain distinct from similarity.
14. Perceptual equivalence MUST be contract-relative.
15. Spatial and temporal reference systems MUST remain explicit.
16. Multimodal integration MUST preserve required provenance.
17. Active perception MAY interact with Action without making Action part of Perception.
18. Predictions MUST remain distinguishable from observations.
19. Rendering MAY generate observations but MUST NOT become semantic ground truth.
20. External perception systems MUST participate through Provider contracts.
21. Providers MUST remain outside the semantic authority of `lib/`.
22. Perceptual semantics MUST be represented in the canonical SCR hypergraph.
23. Domain-specific perceptual graphs MUST NOT become competing semantic authorities.
24. Reference, deletion, identity, provenance, and nullary relation semantics MUST conform to SCR foundational semantics.
25. MLIR MUST remain compilation infrastructure rather than semantic authority.

---

# 60. Expected Semantic Structure

The Perception domain may eventually contain semantic subdomains corresponding to concepts such as:

```text
603_Perception/
├── Observation
├── Sensing
├── Modality
├── Signal
├── Feature
├── Detection
├── Recognition
├── Classification
├── Segmentation
├── Localization
├── Identification
├── Correspondence
├── Tracking
├── Estimation
├── Inference
├── Interpretation
├── Context
├── Attention
├── Salience
├── Fusion
├── Temporal
├── Spatial
├── Representation
├── Abstraction
├── Equivalence
├── Invariance
├── Uncertainty
├── Confidence
├── Ambiguity
├── Occlusion
├── Resolution
├── Sampling
├── Active
├── Predictive
├── Field
├── Graph
├── Provenance
└── Capability
```

This structure is organizational and does not itself define semantic relationships.

Concrete providers MUST NOT be placed in this tree.

---

# 61. Relationship to Interaction

Perception and Interaction form complementary semantic domains.

Perception answers:

> **What information can this computational system derive or represent from what is available to it?**

Interaction answers:

> **How does an actor or computational entity participate in and influence the semantic field?**

A typical closed loop is therefore:

```text
                    ┌─────────────────┐
                    │ Semantic Field  │
                    └───────┬─────────┘
                            │
                         State
                            │
                            ▼
                       Observation
                            │
                            ▼
                       Perception
                            │
                     Representation
                            │
                            ▼
                    Intent / Decision
                            │
                            ▼
                         Action
                            │
                            ▼
                       Transformation
                            │
                            └──────────→ Semantic Field
```

Neither domain subsumes the other.

---

# 62. Completeness Criteria

The Perception domain is considered semantically mature when:

* Observation is first-class;
* Perception is explicitly distinguished from Observation;
* acquisition and sensing are distinguishable from perception;
* modality is representable;
* perceptual transformations are representable;
* detection is representable;
* recognition is representable;
* classification is representable;
* segmentation is representable;
* localization is representable;
* identification is representable;
* correspondence is representable;
* tracking is representable;
* estimation is representable;
* inference is distinguishable from observation;
* interpretation is representable;
* context is explicit;
* attention and salience are representable;
* multimodal integration is representable;
* temporal integration is representable;
* spatial integration is representable;
* perceptual representations are explicit;
* abstraction levels are representable;
* equivalence is explicit;
* invariance is explicit;
* uncertainty is preserved;
* ambiguity is representable;
* missing information is distinguishable;
* resolution is explicit;
* active perception is representable;
* predictive perception is distinguishable from observation;
* hypergraph relationships are expressible;
* identity and provenance are preserved;
* deletion and reference semantics are defined;
* nullary relations are representable;
* interaction boundaries are explicit;
* provider independence is maintained;
* representation independence is maintained;
* MLIR remains compilation infrastructure rather than semantic authority.

---

# 63. Open Semantic Questions

The following questions remain intentionally open and should be resolved through further semantic analysis rather than premature implementation:

1. What is the minimal formal distinction between Perception and general Inference?
2. What constitutes a perceptual transformation rather than an arbitrary information transformation?
3. How should observer-relative semantics be formally represented?
4. How should perceptual context be typed?
5. How should competing perceptual hypotheses be represented in the canonical hypergraph?
6. How should uncertainty propagate through arbitrary semantic transformations?
7. How should confidence and probability be formally distinguished?
8. How should perceptual equivalence be formally specified?
9. How should perceptual resolution interact with multiscale representations?
10. How should attention be represented without importing neural assumptions?
11. How should information loss through perceptual transformation be represented?
12. How should transformations declare information preserved, discarded, or inferred?
13. How should multimodal correspondence be represented in a hypergraph?
14. How should simulated observations declare their relationship to simulation truth?
15. How should perceptual state be versioned and replayed?
16. How should learned perceptual providers expose semantic guarantees?
17. How should active perception formally interact with Interaction and Control?
18. How should perception operate over arbitrary regions of the Semantic Hypergraph?
19. How should collective or distributed perception represent conflicting observations?
20. What constitutes semantic convergence between independent perceptual processes?

These questions MUST NOT be resolved merely by adopting terminology or implementation patterns from existing AI frameworks.

---

# 64. Final Principle

Perception is not the act of seeing.

Perception is the **semantic transformation by which available information becomes a representation meaningful to a computational observer**.

That observer may be:

* a human;
* an animal;
* an Agent;
* a simulation;
* a program;
* a runtime;
* a machine;
* a distributed system;
* another semantic process;
* or SCR itself.

The sensory modality, algorithm, neural architecture, provider, representation format, execution substrate, and physical mechanism are replaceable.

The semantic relationship is not.

```text
Information Available
        ↓
      Observe
        ↓
      Perceive
        ↓
   Represent Meaning
        ↓
  Participate in Computation
```

Perception therefore forms one of the principal bridges between the **state of a semantic field** and the **knowledge available to a computational participant**, while remaining strictly distinct from interaction, action, control, and execution.
