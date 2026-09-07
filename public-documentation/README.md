# Semantic Computational Runtime

> **A semantic computational substrate for expressing, transforming, executing, and materialising computation from a shared Semantic Field.**

**Semantic Computational Runtime (SCR)** is an architectural and computational research project exploring a different foundation for computing: rather than treating computation primarily as the manipulation of pre-defined data structures, services, processes, or machine instructions, SCR begins with **semantic structure** and derives computation outward from it.

The central proposition is simple:

> **Computation is transformation of semantic structure within a field.
> The runtime is the mechanism by which that semantic topology becomes physical reality.**

This documentation presents the theory, conceptual foundations, architecture, examples, applications, comparative analysis, research programme, and current implementation status of SCR.

---

## Documentation at a Glance

| Section                                       | Purpose                                                                                           |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **[010 · Orientation](./010_orientation/)**   | Understand what SCR is, why it exists, and the larger computational worldview behind it.          |
| **[020 · Concepts](./020_concepts/)**         | Explore the foundational concepts upon which SCR is built.                                        |
| **[030 · Architecture](./030_architecture/)** | Understand how the Semantic Field becomes an executable computational architecture.               |
| **[060 · Examples](./060_examples/)**         | See the principles expressed through concrete computational examples.                             |
| **[060 · Use Cases](./060_use-cases/)**       | Explore domains and market segments in which SCR may provide meaningful architectural advantages. |
| **[080 · Comparisons](./080_comparisons/)**   | Examine SCR in relation to established computational technologies and architectures.              |
| **[090 · Research](./090_research/)**         | Explore the mathematical, theoretical, and scientific questions underlying the project.           |
| **[100 · Status](./100_status/)**             | Understand what exists today, what is being validated, and what remains prospective.              |
| **[_meta](./_meta/)**                         | Documentation metadata, conventions, and supporting material.                                     |

---

# Where Should I Start?

SCR spans several levels of abstraction. The best entry point therefore depends upon what you are trying to understand.

### I want to understand the idea

Start here:

1. **[What Is SCR?](./010_orientation/001_what-is-scr.md)**
2. **[Why Semantic Computation?](./010_orientation/002_why-semantic-computation.md)**
3. **[The Computational Universe](./010_orientation/003_the-computational-universe.md)**

These documents establish the motivation and worldview before introducing implementation details.

---

### I want to understand the foundational theory

Begin with:

1. **[Semantic Computation](./020_concepts/001_semantic-computation.md)**
2. **[Semantic Primacy](./020_concepts/002_semantic-primacy.md)**
3. **[Meaning and Representation](./020_concepts/003_meaning-and-representation.md)**
4. **[Information as Computation](./020_concepts/008_information-as-computation.md)**
5. **[Patterns and Morphology](./020_concepts/009_patterns-and-morphology.md)**

This is the conceptual core of the project.

---

### I want to understand the actual architecture

Proceed to:

1. **[Architecture Overview](./030_architecture/001_architecture-overview.md)**
2. **[MLIR](./030_architecture/004_mlir.md)**
3. **[Providers](./030_architecture/007_providers.md)**
4. **[Adaptive Execution](./030_architecture/010_adaptive-execution.md)**
5. **[The Two Graphs](./030_architecture/011_the-two-graphs.md)**

The architecture documents explain how semantic structure is transformed into executable computational machinery and how SCR relates semantic representation to physical execution.

---

### I want to see something concrete

Visit **[Examples](./060_examples/)**.

Current examples include:

* [Particle System](./060_examples/002_particle-system.md)
* [Simulation to Rendering](./060_examples/007_simulation-to-rendering.md)

These examples are particularly useful after reading the orientation and conceptual material because they demonstrate how the abstract principles can manifest as actual computational systems.

---

### I want to understand what SCR could be used for

Go directly to **[Use Cases](./060_use-cases/)**.

The use-case portfolio deliberately approaches domains from the **Semantic Field outward** rather than presenting SCR as merely another replacement for an existing infrastructure product.

The portfolio currently spans areas including:

* Stream processing
* Signal processing
* Media processing
* Data processing
* SQL databases
* Graph databases
* Object storage
* Model hosting
* Workflow orchestration
* Digital twins
* Robotics
* Edge computing
* HPC and scientific computing
* Simulation and digital engineering
* IoT and cyber-physical systems
* Geospatial computing
* Financial infrastructure
* Cybersecurity
* Knowledge systems
* Data integration and federation
* Serverless computing
* Computational edge delivery
* Digital assets and content infrastructure
* Semantic operating systems
* Developer infrastructure
* Virtual machines

See the **[SCR Use-Case Portfolio](./060_use-cases/000_USE_CASE_PORTFOLIO.md)** for the portfolio-level view.

---

### I want to know how SCR compares with existing technologies

See **[Comparisons](./080_comparisons/)**.

Current comparative work includes:

* [SCR and MLIR](./080_comparisons/001_scr-and-mlir.md)
* [SCR and Simulation Engines](./080_comparisons/003_scr-and-simulation-engines.md)
* [SCR and .NET](./080_comparisons/004_scr_and_dotnet.md)

The purpose of these documents is not to produce superficial feature matrices. They examine differences in **computational model, abstraction boundary, semantic representation, execution model, and architectural purpose**.

---

### I want to investigate the research

See **[Research](./090_research/)**.

Current research areas include:

* [Semantic Equivalence](./090_research/001_semantic-equivalence.md)
* [Computational Morphology](./090_research/003-computational-morphology.md)
* [Semantic Hypergraphs](./090_research/005-semantic-hypergraphs.md)

This section contains material where the project moves beyond engineering specification into questions requiring mathematical, theoretical, or empirical investigation.

---

### I want to know what actually exists

Read **[Current State](./100_status/001-current-state.md)**.

This distinction is important.

SCR documentation intentionally separates:

> **conceptual possibility**
> → **architectural proposal**
> → **implemented capability**
> → **validated behaviour**

A document describing an architectural capability should not be interpreted as evidence that the corresponding implementation is already complete.

---

# The SCR Documentation Model

The documentation is organised as a progression from **meaning to manifestation**:

```text
                    SEMANTIC FIELD
                          │
                          ▼
                    ORIENTATION
                          │
                          ▼
                     CONCEPTS
                          │
                          ▼
                    ARCHITECTURE
                          │
             ┌────────────┼────────────┐
             ▼            ▼            ▼
          EXAMPLES      USE CASES   RESEARCH
             │            │            │
             └────────────┼────────────┘
                          ▼
                     COMPARISONS
                          │
                          ▼
                       STATUS
```

This is intentional.

SCR should not be understood by beginning with implementation details and attempting to reconstruct the underlying theory afterwards. The architectural proposition is that **semantic structure is prior to the particular physical mechanism used to execute it**.

Accordingly, the documentation follows the same direction.

---

# The Central Idea

Conventional computational systems commonly begin with physical or infrastructural primitives:

```text
machine
  ↓
memory
  ↓
instructions
  ↓
data structures
  ↓
programs
  ↓
applications
```

SCR investigates an alternative direction:

```text
meaning
  ↓
semantic structure
  ↓
relationships
  ↓
computational transformation
  ↓
execution
  ↓
physical manifestation
```

The distinction is not merely terminological.

If semantic structure is treated as foundational, then many things conventionally regarded as separate categories of infrastructure may instead be understood as different **manifestations of computation over semantic structure**.

A database, stream processor, workflow engine, simulation, model runtime, graph system, virtual machine, or edge computation system can therefore be examined as particular physical realisations of a more general computational substrate.

This is one of the principal questions SCR is attempting to answer.

---

# Semantic Primacy

The project is built around a foundational engineering principle:

> **Architectural decisions should be derived outward from the Semantic Field rather than continually introducing lower-level abstractions and attempting to reconcile them afterwards.**

This gives the project a characteristic architectural direction:

```text
                    Semantic Field
                           │
              ┌────────────┼────────────┐
              │            │            │
          semantics     topology     relations
              │            │            │
              └────────────┼────────────┘
                           │
                    computational
                      morphology
                           │
                           ▼
                    execution model
                           │
                           ▼
                 physical manifestation
```

The runtime is consequently not merely an execution engine sitting underneath a language.

It is the **bridge between semantic structure and physical computation**.

---

# A Useful Mental Model

One useful way to approach SCR is to distinguish three questions.

### 1. What exists?

This concerns the **semantic field**:

* entities
* values
* relationships
* structures
* states
* transformations
* context
* topology

### 2. What can happen?

This concerns **computation**:

* transformations
* composition
* propagation
* evaluation
* inference
* interaction
* adaptation
* execution

### 3. How does it become real?

This concerns **runtime manifestation**:

* memory
* processors
* accelerators
* devices
* storage
* networks
* operating-system facilities
* external systems

SCR seeks to make the relationship between these three levels explicit rather than hiding it beneath layers of unrelated abstractions.

---

# Documentation Conventions

The numeric prefixes are intentional.

```text
000  Index / entry point
010  Orientation
020  Concepts
030  Architecture
040–050  Reserved for future expansion
060  Examples / use cases
070  Reserved
080  Comparisons
090  Research
100  Status
```

The numbering provides stable conceptual namespaces while leaving room for future sections without requiring the entire documentation tree to be renumbered.

Individual documents are likewise numbered within their namespace where ordering or conceptual grouping is useful.

---

# How to Read SCR

A productive first reading is:

```text
01  What Is SCR?
        ↓
02  Why Semantic Computation?
        ↓
03  Semantic Computation
        ↓
04  Semantic Primacy
        ↓
05  Meaning and Representation
        ↓
06  Architecture Overview
        ↓
07  Examples
        ↓
08  Use Cases
        ↓
09  Research
        ↓
10  Current State
```

Do not feel obliged to read the documentation linearly thereafter.

SCR is intentionally multi-disciplinary. Once the central model is understood, the documentation can be navigated according to interest.

---

# For Engineers

If you are primarily interested in implementation:

**Orientation → Concepts → Architecture → Examples → Status**

Pay particular attention to the architecture documents and the distinction between semantic structure and its physical execution mechanisms.

---

# For Researchers

If you are investigating the theoretical foundations:

**Orientation → Concepts → Research → Comparisons**

The research section is deliberately not treated as an appendix to the engineering work. The theoretical questions are part of the architectural investigation itself.

---

# For Architects

If you are evaluating SCR as a systems architecture:

**Orientation → Architecture → Comparisons → Use Cases → Status**

The key question is not simply *"what component does SCR replace?"*

It is:

> **What becomes architecturally possible when semantic structure is promoted to the primary computational substrate?**

---

# For Potential Users

If you are evaluating whether SCR is relevant to a particular domain:

**Orientation → Use Cases → Examples → Status**

The use-case portfolio describes both potential advantages and limitations. SCR is not intended to imply that every existing technology should immediately be discarded; the relevant question is whether a semantic computational substrate produces a superior architecture for a particular problem class.

---

# For Contributors

Before modifying the implementation, understand the conceptual and architectural contracts.

Recommended path:

**Concepts → Architecture → Status → Repository implementation**

The implementation should be understood as a manifestation of the architecture, not as the sole definition of the architecture.

Where implementation reality and documentation diverge, the discrepancy should be made explicit and resolved rather than silently allowing one layer to redefine another.

---

# Status and Epistemic Discipline

SCR is an active research and engineering programme.

Consequently, this documentation contains material of different epistemic statuses.

A useful distinction is:

| Status          | Meaning                                                                        |
| --------------- | ------------------------------------------------------------------------------ |
| **Established** | Supported by the current architecture, implementation, or validation evidence. |
| **Implemented** | Present in the repository implementation.                                      |
| **Validated**   | Supported by explicit tests, experiments, or other evidence.                   |
| **Proposed**    | An architectural or engineering design under consideration.                    |
| **Research**    | An open theoretical, mathematical, or empirical question.                      |
| **Exploratory** | A potentially useful direction which has not yet acquired a stable contract.   |

Readers should therefore avoid interpreting every architectural statement as a claim about current implementation completeness.

The **[Status](./100_status/)** section exists specifically to maintain that distinction.

---

# The Larger Question

SCR is ultimately investigating a question larger than the design of another runtime:

> **Can computation be organised around semantic structure itself, rather than around the historical accumulation of specialised computational abstractions?**

If the answer is yes, then a runtime built around semantic computation could provide a common substrate across domains that are presently treated as technologically distinct.

The significance of SCR therefore lies not merely in a particular implementation technique.

It lies in the possibility that:

```text
                         one semantic substrate
                                  │
          ┌───────────────────────┼────────────────────────┐
          │                       │                        │
       data                  simulation                 AI/ML
          │                       │                        │
       graphs                 robotics                 models
          │                       │                        │
       streams                finance                 knowledge
          │                       │                        │
       storage                 edge                  cyber-physical
          │                       │                        │
          └───────────────────────┼────────────────────────┘
                                  │
                                  ▼
                    Semantic Computational Runtime
```

could provide a more general computational foundation from which these specialised manifestations can be derived.

That proposition remains a subject of engineering, mathematical, and empirical investigation.

---

## Repository

The implementation, formal work, specifications, experiments, and supporting material live in the main repository:

**[Semantic Computational Runtime](https://github.com/zharia/Semantic-Computational-Runtime)**

This documentation represents the public-facing conceptual and architectural index into that work.

---

## Documentation Index

### 010 · Orientation

* [What Is SCR?](./010_orientation/001_what-is-scr.md)
* [Why Semantic Computation?](./010_orientation/002_why-semantic-computation.md)
* [The Computational Universe](./010_orientation/003_the-computational-universe.md)

### 020 · Concepts

* [Semantic Computation](./020_concepts/001_semantic-computation.md)
* [Semantic Primacy](./020_concepts/002_semantic-primacy.md)
* [Meaning and Representation](./020_concepts/003_meaning-and-representation.md)
* [Information as Computation](./020_concepts/008_information-as-computation.md)
* [Patterns and Morphology](./020_concepts/009_patterns-and-morphology.md)

### 030 · Architecture

* [Architecture Overview](./030_architecture/001_architecture-overview.md)
* [MLIR](./030_architecture/004_mlir.md)
* [Providers](./030_architecture/007_providers.md)
* [Adaptive Execution](./030_architecture/010_adaptive-execution.md)
* [The Two Graphs](./030_architecture/011_the-two-graphs.md)

### 060 · Examples

* [Particle System](./060_examples/002_particle-system.md)
* [Simulation to Rendering](./060_examples/007_simulation-to-rendering.md)

### 060 · Use Cases

* [Use-Case Portfolio](./060_use-cases/000_USE_CASE_PORTFOLIO.md)
* [Stream Processing](./060_use-cases/101_stream-processing.md)
* [Signal Processing](./060_use-cases/102_signal-processing.md)
* [Media Processing](./060_use-cases/103_media-processing.md)
* [Data Processing](./060_use-cases/105_data-processing.md)
* [SQL Database](./060_use-cases/106_sql-database.md)
* [Graph Database](./060_use-cases/107_graph-database.md)
* [Object Store](./060_use-cases/108_object-store.md)
* [Model Hosting](./060_use-cases/109_model-hosting.md)
* [Workflow Orchestration](./060_use-cases/110_workflow-orchestration.md)
* [Digital Twins](./060_use-cases/111_digital-twins.md)
* [Robotics](./060_use-cases/112_robotics.md)
* [Edge Computing](./060_use-cases/113_edge-computing.md)
* [HPC & Scientific Computing](./060_use-cases/114_hpc-scientific-computing.md)
* [Simulation & Digital Engineering](./060_use-cases/115_simulation-digital-engineering.md)
* [IoT & Cyber-Physical Systems](./060_use-cases/116_iot-cyber-physical-systems.md)
* [Geospatial Computing](./060_use-cases/117_geospatial-computing.md)
* [Financial Infrastructure](./060_use-cases/118_financial-infrastructure.md)
* [Cybersecurity](./060_use-cases/119_cybersecurity.md)
* [Knowledge Systems](./060_use-cases/120_knowledge-systems.md)
* [Data Integration & Federation](./060_use-cases/121_data-integration-federation.md)
* [Serverless Computing](./060_use-cases/122_serverless-computing.md)
* [Computational Edge Delivery](./060_use-cases/123_computational-edge-delivery.md)
* [Digital Assets & Content Infrastructure](./060_use-cases/124_digital-assets-content-infrastructure.md)
* [Semantic Operating System](./060_use-cases/125_semantic-operating-system.md)
* [Developer Infrastructure](./060_use-cases/126_developer-infrastructure.md)
* [Virtual Machines](./060_use-cases/201_virtual-machines.md)

### 080 · Comparisons

* [SCR and MLIR](./080_comparisons/001_scr-and-mlir.md)
* [SCR and Simulation Engines](./080_comparisons/003_scr-and-simulation-engines.md)
* [SCR and .NET](./080_comparisons/004_scr_and_dotnet.md)

### 090 · Research

* [Semantic Equivalence](./090_research/001_semantic-equivalence.md)
* [Computational Morphology](./090_research/003-computational-morphology.md)
* [Semantic Hypergraphs](./090_research/005-semantic-hypergraphs.md)

### 100 · Status

* [Current State](./100_status/001-current-state.md)

---

## A Final Orientation

SCR is easiest to misunderstand when viewed as merely another implementation of familiar infrastructure.

It is better understood as an attempt to change the **point of departure**.

Instead of asking:

> *How do we build a better database, workflow engine, simulation engine, model runtime, or virtual machine?*

SCR asks:

> **What computational substrate would emerge if semantic structure itself were the primary object of computation?**

The rest of the project follows from that question.

**Enter through Orientation.
Understand the Concepts.
Study the Architecture.
Observe the Examples.
Explore the Use Cases.
Challenge it through Comparison.
Investigate it through Research.
And judge it by its Status.**
