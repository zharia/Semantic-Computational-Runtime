---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS
name: Physics

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
---

# Physics

## Definition

Physics is the semantic computational domain concerned with the meaning, relationships, laws, constraints, interactions, quantities, states, and transformations that describe physical systems and phenomena.

Physics defines **what physical behaviour means** without prescribing the numerical method, solver, implementation language, representation, storage mechanism, execution substrate, or simulation engine used to realize that behaviour.

Physics provides semantic descriptions of physical quantities, physical states, interactions, forces, fields, conservation laws, constitutive relationships, equations, constraints, symmetries, and physical processes.

Physics is therefore a **semantic law domain**, not merely a numerical computation library or physics engine.

The fundamental distinction is:

```text
Mathematics
    ↓
provides mathematical structures and operations

Physics
    ↓
assigns physical meaning and laws to those structures

Dynamics
    ↓
describes state evolution through time

Simulation
    ↓
computationally realizes physical and dynamical models
```

Physics may describe systems whose evolution is deterministic, stochastic, discrete, continuous, classical, relativistic, quantum, statistical, thermodynamic, field-based, or otherwise formally specified.

---

# Semantic Model

A physical model can be understood conceptually as:

```text
P = (Q, S, L, I, C, K, B, R, T, Π)
```

where:

* `Q` = physical quantities and observables
* `S` = physical state
* `L` = physical laws
* `I` = interactions and couplings
* `C` = constraints
* `K` = constitutive relationships
* `B` = boundary and initial conditions
* `R` = reference-frame and coordinate semantics
* `T` = temporal semantics
* `Π` = provenance and model assumptions

This is a conceptual semantic model, not a prescribed data structure.

A physical model MUST distinguish:

1. physical meaning,
2. mathematical formulation,
3. computational representation,
4. numerical approximation,
5. implementation,
6. execution,
7. physical manifestation or observation.

---

# Scope

SCR Physics includes semantics for:

* physical quantities
* units and dimensions
* observables
* physical states
* state variables
* parameters
* physical systems
* physical entities
* interactions
* forces
* energy
* momentum
* angular momentum
* mass
* charge
* temperature
* entropy
* pressure
* density
* volume
* displacement
* velocity
* acceleration
* fields
* potentials
* fluxes
* currents
* waves
* particles
* continua
* rigid bodies
* deformable bodies
* fluids
* gases
* plasmas
* thermodynamic systems
* electromagnetic systems
* gravitational systems
* mechanical systems
* statistical systems
* quantum systems
* relativistic systems
* physical constraints
* conservation laws
* constitutive relations
* equations of state
* symmetries
* invariants
* boundary conditions
* initial conditions
* interactions and coupling
* physical processes
* phase transitions
* equilibrium
* non-equilibrium behaviour
* stochastic physical processes
* measurement
* observation
* uncertainty
* physical model validity
* approximation
* parameterisation
* dimensional analysis
* scaling
* nondimensionalisation
* physical model composition
* physical model transformation
* physical state evolution
* physical events
* physical deltas
* physical streams
* provenance
* model assumptions
* model validity domains
* physical equivalence
* physical capabilities.

---

# Physical Meaning

A physical quantity is not merely a numerical value.

For example:

```text
5
```

is mathematically a number.

```text
5 m/s
```

is a physical quantity with dimensional meaning.

```text
velocity = 5 m/s
```

assigns that quantity to a physical state variable.

```text
velocity(body_A) = 5 m/s
```

further establishes the physical entity and context to which the quantity applies.

SCR Physics MUST preserve these semantic distinctions.

A numerical representation MUST NOT silently redefine the physical meaning of the quantity it represents.

---

# Quantities and Units

Physics MUST provide semantic treatment of physical quantities independently of their representation.

A quantity has, conceptually:

```text
Quantity
├── magnitude
├── dimension
├── unit
├── reference
├── uncertainty
└── provenance
```

Units MUST remain semantically distinct from raw numerical representation.

Where applicable, SCR SHOULD reuse established standards for:

* units
* dimensions
* quantities
* coordinate reference systems
* time
* physical constants.

Unit conversion is a semantic transformation, not merely arithmetic scaling.

For example:

```text
1 km
```

and

```text
1000 m
```

may represent equivalent physical quantities while having different representations.

---

# Physical State

A physical state represents the information required by a physical model to describe the relevant condition of a system.

A state MAY contain:

* positions
* velocities
* momenta
* orientations
* angular velocities
* mass distributions
* energy
* temperature
* pressure
* density
* field values
* particle states
* material properties
* phase information
* internal variables
* boundary state
* environmental conditions
* stochastic variables
* other model-specific quantities.

Physical state MUST remain distinct from:

* storage state,
* memory state,
* renderer state,
* simulation engine state,
* numerical solver state.

A computational implementation MAY maintain additional state required for execution, but such implementation state MUST NOT automatically acquire physical meaning.

---

# Physical Systems

A physical system is a semantically defined collection of physical entities, quantities, interactions, fields, constraints, and environmental relationships.

Systems MAY be:

* isolated
* closed
* open
* coupled
* hierarchical
* distributed
* continuous
* discrete
* hybrid
* deterministic
* stochastic
* equilibrium
* non-equilibrium.

System boundaries are semantic constructs.

A physical system MAY contain subsystems, and subsystems MAY themselves contain systems.

---

# Laws

Physical laws define normative relationships governing physical quantities, states, interactions, or transformations within a specified domain of validity.

Examples include:

* conservation of energy
* conservation of momentum
* conservation of charge
* Newtonian mechanics
* Maxwell's equations
* thermodynamic laws
* equations of state
* diffusion laws
* wave equations
* gravitational laws
* quantum mechanical postulates
* relativistic relationships.

SCR does not privilege a particular physical theory.

A law MUST have an explicit semantic domain and, where applicable:

* assumptions
* applicability conditions
* variables
* parameters
* constraints
* dimensional requirements
* boundary conditions
* validity domain
* approximation level
* provenance.

A numerical implementation of a law is not itself the law.

---

# Conservation

Conservation principles are first-class physical semantics.

A conservation relationship MAY apply to:

* mass
* energy
* momentum
* angular momentum
* charge
* particle number
* probability
* other conserved quantities.

Conservation MUST be represented semantically rather than inferred solely from numerical behaviour.

A solver SHOULD be able to expose whether and how a computational realization preserves, approximates, or violates a specified conservation invariant.

---

# Interactions

Interactions describe physical relationships through which systems, entities, fields, or quantities influence one another.

Interactions MAY include:

* contact
* collision
* gravitation
* electromagnetic interaction
* chemical interaction
* thermal exchange
* diffusion
* fluid coupling
* radiation
* constraint forces
* field coupling
* material interaction
* biological interaction where physical semantics apply.

Interactions MAY involve arbitrary numbers of participants.

The Semantic Hypergraph therefore provides an appropriate foundational representation for higher-order physical interactions.

---

# Forces and Potentials

Forces, potentials, impulses, stresses, strains, fluxes, currents, and related concepts are semantic physical quantities or relationships.

The representation of a force MUST NOT be confused with its implementation.

For example:

```text
Force(body_A, body_B)
```

is semantic information.

A vector stored in an array is one possible representation.

A SIMD kernel computing that vector is one possible implementation.

A GPU executing that kernel is one possible execution substrate.

These are distinct layers.

---

# Fields

Physics makes extensive use of fields.

A physical field MAY assign quantities such as:

* temperature
* pressure
* density
* velocity
* electric potential
* electric field
* magnetic field
* gravitational potential
* probability density
* stress
* strain
* concentration.

The Fields domain defines the general semantics of information distributed over a domain.

Physics assigns physical interpretation and laws to such fields.

Thus:

```text
Fields
    ↓
distributed information

Physics
    ↓
physical meaning + laws

Dynamics
    ↓
evolution

Simulation
    ↓
computational realization
```

A physical field MUST retain its domain, quantity semantics, units, coordinate/reference semantics, and applicable physical laws.

---

# Constitutive Relationships

Physics MUST support constitutive relationships that describe how physical quantities relate within a particular material, medium, or model.

Examples include relationships involving:

* stress and strain
* pressure and density
* temperature and energy
* conductivity
* viscosity
* elasticity
* permeability
* diffusion
* material response.

Constitutive relationships MUST be distinguishable from universal or conservation laws.

Their applicability MAY depend on:

* material
* phase
* temperature
* pressure
* scale
* frequency
* deformation
* history
* model assumptions.

---

# Equilibrium

Physics MUST represent equilibrium as a semantic condition rather than simply as numerical convergence.

A system MAY be in:

* mechanical equilibrium
* thermal equilibrium
* chemical equilibrium
* statistical equilibrium
* dynamic equilibrium
* other domain-specific equilibrium states.

Numerical convergence MAY be evidence for an equilibrium condition, but convergence itself does not define the physical semantics.

---

# Non-Equilibrium Systems

Physics MUST also support systems away from equilibrium.

These may include:

* transport
* diffusion
* fluid flow
* reaction systems
* dissipative systems
* driven systems
* phase transitions
* biological physical processes
* turbulent systems
* self-organising physical systems.

The semantic model MUST NOT assume equilibrium as a prerequisite for physical validity.

---

# Initial and Boundary Conditions

Initial and boundary conditions are semantic components of a physical model.

They constrain the admissible physical states and/or their evolution.

Boundary semantics MAY include:

* fixed values
* fixed fluxes
* periodic boundaries
* reflective boundaries
* absorbing boundaries
* open boundaries
* coupled boundaries
* moving boundaries
* dynamically evolving boundaries.

Boundary conditions MUST remain distinguishable from numerical boundary implementations.

---

# Reference Frames

Physical quantities MAY depend on:

* coordinate systems
* reference frames
* observers
* transformations
* measurement conventions.

SCR Physics MUST represent reference-frame semantics explicitly where they affect physical meaning.

A coordinate transformation MUST NOT be assumed to change the physical entity or phenomenon being described.

---

# Symmetry

Symmetries are first-class physical structures.

Physics MAY represent:

* spatial symmetry
* temporal symmetry
* rotational symmetry
* translational symmetry
* gauge symmetry
* permutation symmetry
* scale symmetry
* other model-specific symmetries.

Symmetries MAY induce or constrain conservation laws and physical equivalence.

---

# Physical Invariants

Physical invariants are properties preserved under specified physical transformations or evolution.

Examples include:

* conserved quantities
* topological invariants
* dimensional relationships
* symmetries
* gauge-invariant quantities
* model-specific invariants.

Invariants SHOULD be expressible as semantic contracts that implementations can test or monitor.

---

# Thermodynamics

Thermodynamic semantics MAY include:

* temperature
* heat
* work
* energy
* entropy
* enthalpy
* free energy
* pressure
* volume
* chemical potential
* phase
* equilibrium
* irreversible processes.

Thermodynamic quantities MUST retain their physical semantics independently of the numerical formulation used to calculate them.

---

# Statistical and Stochastic Physics

Physics MAY describe inherently probabilistic or statistically defined systems.

Such systems MAY contain:

* probability distributions
* ensembles
* stochastic variables
* random processes
* statistical observables
* expectation values
* fluctuations
* correlations.

Randomness MUST be semantically distinguished from implementation-specific pseudo-random number generation.

Where reproducibility is required, the relevant stochastic semantics and provenance MUST be explicit.

---

# Scale

Physical models MAY operate across different scales:

```text
quantum
   ↓
atomic
   ↓
molecular
   ↓
microscopic
   ↓
mesoscopic
   ↓
macroscopic
   ↓
continuum
   ↓
large-scale
```

Scale is a semantic property where model validity depends upon it.

Different models MAY describe the same physical phenomenon at different resolutions or abstraction levels.

SCR MUST NOT assume that a higher-resolution representation is automatically semantically superior.

---

# Approximation

Physical models frequently involve approximations.

Approximation MUST be explicit where it materially affects semantic validity.

An approximation MAY involve:

* scale reduction
* linearisation
* discretisation
* coarse graining
* parameter reduction
* model reduction
* perturbation
* asymptotic approximation
* closure assumptions.

An approximation MUST NOT silently be presented as exact physical semantics.

---

# Dimensional Analysis

Dimensional consistency is a semantic invariant of physical equations where applicable.

SCR Physics SHOULD support:

* dimensional checking
* unit consistency
* nondimensionalisation
* scaling analysis
* dimensional equivalence.

An expression that violates required dimensional relationships SHOULD be rejected or explicitly marked as semantically invalid.

---

# Physics and Mathematics

Mathematics provides the formal structures through which physical laws may be expressed.

Physics assigns physical meaning to those structures.

```text
Mathematical function
        │
        ▼
Physical law
        │
        ▼
Physical model
```

The same mathematical structure MAY have different physical interpretations.

Conversely, one physical concept MAY admit multiple mathematically equivalent formulations.

Physics therefore depends semantically upon mathematical structures without being reducible to Mathematics.

---

# Physics and Fields

Fields provide distributed information over domains.

Physics defines when such information represents physical quantities and how physical laws constrain those fields.

This relationship is bidirectional:

```text
Field → Physical Interpretation
Physics → Field Constraints / Evolution
```

---

# Physics and Geometry

Geometry provides spatial form, position, measurement, and geometric relationships.

Physics assigns physical meaning to geometric structures.

Examples include:

* position
* distance
* velocity
* spatial extent
* body geometry
* trajectories
* curvature
* spatial fields.

Geometry MUST remain independent of any particular physical theory.

---

# Physics and Topology

Topology provides structural relationships such as:

* connectivity
* continuity
* boundaries
* incidence
* neighbourhood
* invariants.

Physics MAY impose topological constraints or undergo topology-changing processes.

Topological semantics MUST NOT be reduced to geometric coordinates merely because a particular physical implementation uses them.

---

# Physics and Morphology

Morphology describes meaningful form, structure, organisation, and transformation.

Physics can:

* constrain morphology
* generate morphology
* transform morphology
* explain morphological differentiation
* couple morphology to physical fields
* drive growth or deformation.

Conversely, morphology can alter the physical state of a system by changing:

* geometry
* material distribution
* boundary conditions
* topology
* interaction surfaces
* field domains.

This creates an important feedback relationship:

```text
Physical State
     │
     ▼
Physics ───────→ Morphological Change
     ▲                  │
     │                  ▼
     └──── altered physical conditions
```

---

# Physics and Dynamics

Physics and Dynamics MUST remain distinct.

Physics defines physical laws, quantities, interactions, constraints, and valid physical relationships.

Dynamics defines the semantics of state evolution through time.

A physical model may induce a dynamical system:

```text
Physical Laws
      +
Physical State
      +
Constraints
      ↓
Dynamical System
```

Dynamics may also describe non-physical systems.

Therefore:

```text
Physics ⊄ Dynamics
Dynamics ⊄ Physics
```

They are strongly coupled semantic domains with overlapping computational structures.

---

# Physics and Simulation

Simulation is the computational realization of a model.

A simulation MAY implement physical semantics, but the simulation itself is not the physical model.

```text
Physical Model
      ↓
Mathematical Formulation
      ↓
Numerical / Symbolic Model
      ↓
Simulation
      ↓
Execution
```

Different simulations MAY implement the same physical model using different:

* algorithms
* discretisations
* solvers
* precision
* hardware
* representations
* execution strategies.

Semantic equivalence MUST be established rather than assumed.

---

# Physics and Agents

Agents MAY exist within physical environments.

Physics can constrain:

* movement
* energy
* collision
* sensing
* embodiment
* communication
* resource consumption
* actuation
* environmental interaction.

Agents MAY also alter physical state through actions.

This permits coupled computational systems:

```text
Environment
    ↕
Physics
    ↕
Agents
    ↕
Perception / Action
```

---

# Physics and Rendering

Rendering provides perceptual or representational manifestations of physical state.

Examples include:

* visible geometry
* lighting
* material appearance
* particle systems
* fluid surfaces
* temperature visualisation
* electromagnetic visualisation
* stress maps.

Rendering MUST NOT redefine physical semantics.

A visual approximation of a physical phenomenon is a representation of that phenomenon.

---

# Physical Events

Physical events represent semantically meaningful transitions or occurrences.

Examples include:

* collision
* emission
* absorption
* phase transition
* reaction
* fracture
* ignition
* impact
* measurement
* state transition.

Events MAY be represented as operations, graph transitions, stream elements, or other semantic structures.

---

# Physical State Evolution

Physical state evolution MAY be represented conceptually as:

```text
S(t₀) ──L──→ S(t₁) ──L──→ S(t₂) ...
```

where `L` represents the applicable physical laws and constraints.

A computational delta MAY describe the change:

```text
ΔS = S(t₁) − S(t₀)
```

but a physical delta is not necessarily a raw numerical difference.

It may instead contain semantic changes such as:

```text
body_created
body_collided
phase_changed
boundary_changed
field_updated
energy_transferred
topology_changed
```

---

# Physical Streams

Physical systems may produce continuously evolving information.

Examples include:

* sensor measurements
* field evolution
* particle trajectories
* fluid state
* telemetry
* experimental observations
* simulation output.

Physics therefore supports semantic streams of physical observations and state transitions.

Streaming transport is an implementation concern.

The semantic stream represents the physical information being communicated.

---

# Measurement and Observation

Physics MUST distinguish physical state from observation of physical state.

Conceptually:

```text
Physical System
      ↓
Physical State
      ↓
Measurement Process
      ↓
Observation
```

Measurement MAY introduce:

* uncertainty
* sampling
* quantisation
* delay
* noise
* observer dependence
* instrument limitations.

An observation MUST NOT automatically be treated as the complete underlying physical state.

---

# Uncertainty

Physical quantities MAY have uncertainty.

Uncertainty MUST be distinguishable from:

* numerical error
* implementation error
* measurement noise
* stochastic physical variation
* approximation error
* epistemic uncertainty
* model uncertainty.

Where possible, uncertainty SHOULD carry provenance describing its origin and interpretation.

---

# Physical Model Validity

A physical model MUST define, where applicable:

* assumptions
* applicable scales
* parameter ranges
* boundary conditions
* initial conditions
* material assumptions
* approximation level
* reference-frame assumptions
* validity domain.

A computational result outside the model's validity domain MUST NOT automatically be considered physically meaningful.

---

# Physical Transformations

Physics supports semantic transformations such as:

* change of reference frame
* unit conversion
* coordinate transformation
* model reduction
* parameter transformation
* state transformation
* physical coupling
* scale transformation
* constitutive transformation.

A transformation MUST declare the semantic conditions under which it preserves physical meaning.

---

# Physical Equivalence

Two physical representations MAY be considered semantically equivalent when they represent the same physical system, quantities, relationships, and relevant observables under the applicable model.

Equivalence MAY be:

* exact
* approximate
* observational
* scale-dependent
* model-dependent
* invariant-dependent.

Numerical similarity alone does not establish physical equivalence.

---

# Provenance

Physical models and quantities SHOULD preserve provenance describing:

* source
* model
* theory
* assumptions
* parameters
* measurements
* calibration
* transformation history
* approximation
* uncertainty
* computational derivation.

Provenance is part of semantic traceability.

---

# Semantic Hypergraph Integration

Physics MUST integrate with the SCR Semantic Hypergraph.

Physical entities, quantities, fields, laws, constraints, interactions, observations, events, transformations, and provenance MAY be represented as nodes, hyperedges, regions, patterns, operations, or streams.

Higher-order physical relationships MUST remain representable without forced reduction to binary relationships when such reduction would lose semantic information.

For example:

```text
Interaction
 ├── participant: body_A
 ├── participant: body_B
 ├── medium: environment
 ├── force: F
 ├── location: x
 ├── time: t
 └── law: L
```

is naturally represented as a higher-order semantic relationship.

---

# Representation Independence

Physics MUST remain independent of:

* arrays
* tensors
* meshes
* particle buffers
* database records
* JSON
* binary formats
* memory layouts
* GPU buffers
* CPU structures
* simulation-engine objects.

These are possible representations.

No representation is semantically authoritative.

---

# Provider Independence

Physics MUST remain independent of particular:

* physics engines
* numerical libraries
* symbolic systems
* solver libraries
* GPU frameworks
* CPU libraries
* programming languages
* hardware platforms.

External implementations are providers.

A provider realizes a physical contract; it does not redefine that contract.

---

# MLIR Representation

Physics MAY be represented in MLIR through suitable dialects, operations, types, attributes, interfaces, and transformations.

MLIR provides compiler infrastructure.

MLIR MUST NOT become the normative authority for physical semantics.

Conceptually:

```text
Physics Semantics
       ↓
Semantic Representation
       ↓
MLIR
       ↓
Lowering / Optimization
       ↓
Provider / Runtime
       ↓
Execution
```

A dialect is an implementation and compilation representation of semantic concepts.

---

# Runtime Semantics

The runtime MAY use physical semantic information to:

* select providers
* select numerical methods
* select precision
* exploit hardware
* select execution strategies
* schedule computations
* monitor invariants
* detect invalid states
* adapt resolution
* adapt timestep
* select representations
* manage resources.

Runtime decisions MUST preserve declared physical semantics.

---

# Capabilities

Physics operations MAY declare capabilities including:

* `Deterministic`
* `Stochastic`
* `Continuous`
* `Discrete`
* `Differentiable`
* `Conservative`
* `EnergyPreserving`
* `MomentumPreserving`
* `Parallelizable`
* `Vectorizable`
* `Tileable`
* `Distributed`
* `Streamable`
* `Incremental`
* `Multiscale`
* `Adaptive`
* `UncertaintyAware`
* `TopologyChanging`
* `GeometryDependent`
* `FieldBased`
* `ParticleBased`.

Capabilities describe semantic or computational properties and MUST NOT be confused with implementation guarantees unless explicitly specified.

---

# Performance Semantics

Physics MUST distinguish semantic correctness from performance.

Performance-relevant properties MAY include:

* numerical precision
* resolution
* timestep
* convergence rate
* stability
* memory requirements
* computational complexity
* parallelism
* locality
* communication requirements
* hardware acceleration.

Optimisation MUST NOT silently change physical meaning.

Where an optimisation introduces approximation, the approximation MUST be explicit.

---

# Numerical Stability

Numerical stability is an implementation-relevant property of physical computation.

SCR Physics SHOULD allow computational realizations to declare:

* stability requirements
* convergence criteria
* error bounds
* precision requirements
* acceptable approximation
* invariant tolerances.

These properties are important to validating whether an implementation adequately realizes a physical semantic contract.

---

# Errors and Failure Semantics

Physics errors MAY include:

* invalid dimensional expression
* invalid unit
* invalid physical state
* violated constraint
* undefined model
* invalid parameter domain
* incompatible reference frame
* invalid boundary condition
* conservation violation
* numerical instability
* non-convergence
* model validity violation
* unsupported physical regime
* inconsistent constitutive relation.

Errors SHOULD preserve semantic provenance and identify whether the failure originates from:

* model definition
* input state
* approximation
* numerical method
* provider
* execution
* observation.

---

# Resource Semantics

Physical computation MAY consume:

* memory
* compute
* accelerator resources
* communication bandwidth
* simulation time
* numerical precision
* storage
* energy.

Resource constraints MUST remain distinct from physical quantities unless explicitly modelled as physical phenomena.

---

# Determinism

A physical model MAY be deterministic or stochastic.

Determinism of an implementation MUST NOT be assumed to imply determinism of the underlying physical semantics.

Where reproducibility is required, implementations SHOULD preserve:

* model identity
* parameters
* initial state
* boundary conditions
* random-state provenance
* numerical configuration
* provider identity
* transformation history.

---

# Security and Isolation

Physical models may originate from untrusted inputs or external providers.

Implementations MUST isolate:

* external code
* numerical providers
* plugins
* dynamically loaded implementations
* external data
* execution resources.

Semantic physical descriptions MUST remain authoritative over provider-specific behaviour.

---

# Standards and Interoperability

SCR Physics SHOULD reuse established open standards wherever applicable.

Relevant standards MAY include:

* SI units and established quantity semantics
* UCUM for machine-readable units
* ISO 8601 / RFC 3339 for temporal values
* OGC standards for spatial semantics
* EPSG coordinate reference systems
* MathML and OpenMath for mathematical representations
* established scientific data formats
* established uncertainty and measurement representations.

Standards provide interoperability mechanisms.

SCR Physics remains authoritative over SCR's physical computational semantics.

---

# Expected Subdomains

The following structure is illustrative and may evolve:

```text
physics/
├── physics-core
├── quantity
├── unit
├── dimension
├── constant
├── observable
├── state
├── system
├── particle
├── continuum
├── rigid-body
├── deformable-body
├── material
├── medium
├── field
├── force
├── potential
├── energy
├── momentum
├── angular-momentum
├── mass
├── charge
├── temperature
├── pressure
├── density
├── entropy
├── interaction
├── coupling
├── conservation
├── law
├── constitutive
├── equation-of-state
├── constraint
├── symmetry
├── invariant
├── equilibrium
├── non-equilibrium
├── thermodynamics
├── statistical
├── stochastic
├── wave
├── particle
├── electromagnetic
├── gravitational
├── quantum
├── relativistic
├── boundary
├── initial-condition
├── reference-frame
├── scale
├── approximation
├── dimensional-analysis
├── measurement
├── observation
├── uncertainty
├── validity
├── transformation
├── state-transition
├── event
├── delta
├── stream
├── provenance
├── equivalence
├── capability
└── provider
```

This structure is not a requirement that every subdomain be implemented immediately.

---

# Invariants

## PHYSICS-INV-001 — Semantic Primacy

Physical meaning MUST be independent of implementation.

## PHYSICS-INV-002 — Quantity Integrity

Physical quantities MUST retain their dimensional and unit semantics.

## PHYSICS-INV-003 — Law Integrity

Physical laws MUST remain distinct from their numerical or algorithmic implementations.

## PHYSICS-INV-004 — State Integrity

Physical state MUST remain distinguishable from implementation state.

## PHYSICS-INV-005 — Constraint Integrity

Physical constraints MUST remain explicit and semantically identifiable.

## PHYSICS-INV-006 — Conservation Integrity

Declared conservation relationships MUST be representable independently of implementation.

## PHYSICS-INV-007 — Model Validity

Physical models MUST be associated with their applicable assumptions and validity domains where required.

## PHYSICS-INV-008 — Representation Independence

Physical semantics MUST NOT depend upon a particular representation.

## PHYSICS-INV-009 — Provider Independence

External physics implementations MUST NOT become semantic authorities.

## PHYSICS-INV-010 — Reference Integrity

Reference-frame and coordinate semantics MUST remain explicit where physically relevant.

## PHYSICS-INV-011 — Temporal Integrity

Physical state evolution MUST preserve explicit temporal semantics.

## PHYSICS-INV-012 — Uncertainty Integrity

Physical uncertainty MUST remain distinguishable from numerical and implementation error.

## PHYSICS-INV-013 — Approximation Integrity

Approximations MUST NOT silently acquire exact physical meaning.

## PHYSICS-INV-014 — Dimensional Integrity

Physically meaningful equations MUST preserve required dimensional consistency.

## PHYSICS-INV-015 — Interaction Integrity

Higher-order physical interactions MUST remain representable without mandatory binary reduction.

## PHYSICS-INV-016 — Provenance Integrity

Physical models and derived results MUST preserve relevant provenance.

## PHYSICS-INV-017 — Equivalence Integrity

Semantic equivalence MUST be established under explicit applicable conditions.

## PHYSICS-INV-018 — Runtime Independence

Physical semantics MUST remain independent of runtime and execution substrate.

---

# Domain Relationships

| Domain      | Relationship   | Meaning                                                            |
| ----------- | -------------- | ------------------------------------------------------------------ |
| Core        | REFINES        | Physics specializes foundational semantic abstractions             |
| Mathematics | DEPENDS_ON     | Physical laws use mathematical structures                          |
| Data        | SPECIALIZES    | Physical information is structured semantic data                   |
| Graphs      | COMPOSES       | Physical systems and interactions form relational structures       |
| Fields      | SPECIALIZES    | Physical fields assign physical meaning to distributed information |
| Geometry    | CONSTRAINS     | Physical systems operate over spatial structures                   |
| Topology    | INTERACTS_WITH | Physical behaviour may depend on connectivity and topology         |
| Morphology  | INTERACTS_WITH | Physical processes generate and respond to form and structure      |
| Dynamics    | CONSTRAINS     | Physical laws constrain state evolution                            |
| Agents      | INTERACTS_WITH | Agents may exist within and modify physical environments           |
| Perception  | PRODUCES       | Physical systems generate observable phenomena                     |
| Simulation  | IMPLEMENTED_BY | Simulations computationally realize physical models                |
| Rendering   | REPRESENTS     | Rendering produces perceptual representations of physical state    |

These relationships are semantic relationships and MUST NOT automatically be interpreted as software-package dependencies.

---

# Composition

Physics MUST support composition of physical models.

Models MAY be composed through:

* system composition
* field coupling
* interaction composition
* constraint composition
* material composition
* subsystem composition
* multiscale composition
* model coupling
* hierarchical composition.

Composition MUST preserve the semantic identity and assumptions of participating models.

---

# Transformation

Physical transformations MAY include:

```text
Model
  ↓
Physical formulation
  ↓
Mathematical formulation
  ↓
Approximation
  ↓
Numerical representation
  ↓
Implementation
  ↓
Execution
```

Each transformation SHOULD preserve provenance.

Semantic transformations MUST declare whether they preserve:

* exact meaning
* observational equivalence
* physical invariants
* dimensional consistency
* conservation
* topology
* geometry
* uncertainty
* temporal semantics.

---

# Testing Requirements

Physics implementations MUST support testing at multiple levels:

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

* dimensional consistency
* conservation
* invariant preservation
* known analytical solutions
* limiting cases
* symmetry
* boundary conditions
* convergence
* numerical stability
* physical plausibility
* uncertainty propagation
* model validity
* provider equivalence.

---

# Validation Requirements

A physical implementation is valid only to the extent that it satisfies its declared semantic contract.

Validation SHOULD distinguish:

1. mathematical correctness,
2. physical correctness,
3. numerical correctness,
4. implementation correctness,
5. execution correctness.

A numerically converged result is not automatically physically valid.

---

# Function-Level Requirements

Every Physics function MUST specify, where applicable:

* semantic purpose
* physical domain
* input quantities
* output quantities
* units and dimensions
* state requirements
* applicable laws
* constraints
* assumptions
* validity domain
* invariants
* determinism
* uncertainty semantics
* approximation
* error semantics
* temporal semantics
* provenance
* capabilities
* equivalence conditions
* performance characteristics.

---

# Completeness Criteria

The Physics domain definition is complete only when:

* physical concepts have explicit semantic definitions;
* quantities and units are unambiguous;
* physical state is distinguishable from implementation state;
* laws are distinguishable from algorithms;
* interactions are representable;
* constraints are explicit;
* conservation semantics are expressible;
* constitutive relationships are expressible;
* boundary and initial conditions are representable;
* uncertainty is explicit;
* approximation is explicit;
* model validity can be described;
* temporal evolution is expressible;
* provenance is preserved;
* higher-order relationships are representable;
* provider independence is maintained;
* representation independence is maintained;
* composition is defined;
* equivalence conditions are defined;
* validation requirements exist;
* implementation technology does not become semantic authority.

---

# Architectural Rules

1. **Physics defines physical meaning, not numerical implementation.**
2. **A physics engine is a provider, not the definition of Physics.**
3. **A solver is an implementation of a computational contract, not a physical law.**
4. **Numerical values without quantity semantics are not sufficient physical descriptions.**
5. **Units and dimensions are semantic information.**
6. **Physical laws MUST remain distinguishable from their discretisations.**
7. **Approximations MUST be explicit.**
8. **Model validity MUST be explicit where applicable.**
9. **Conservation and invariants MUST be representable as semantic contracts.**
10. **Physical state MUST remain distinct from implementation state.**
11. **Physics MUST compose with Fields, Geometry, Topology, Morphology, Dynamics, Agents, and Simulation.**
12. **Physics MUST integrate with the Semantic Hypergraph.**
13. **MLIR MUST remain an implementation/compiler representation rather than physical authority.**
14. **External libraries MUST be treated as providers.**
15. **Runtime optimisation MUST preserve declared physical semantics.**
16. **Hardware characteristics MAY influence execution but MUST NOT redefine physical meaning.**

---

# Open Semantic Questions

The following questions remain intentionally open for future refinement:

* How should competing physical theories describing the same phenomenon be represented?
* How should model validity domains be formally encoded?
* How should dimensional analysis integrate with the Mathematics domain?
* How should uncertainty semantics interact with stochastic Physics?
* How should physical theories with fundamentally different ontologies coexist?
* How should quantum measurement semantics be represented?
* How should observer-dependent physical semantics be represented?
* How should multiscale model coupling be formalised?
* How should conservation contracts interact with approximate numerical implementations?
* How should physical laws be represented in MLIR without making the dialect normative?
* How should physical model discovery and automatic composition operate?
* How should experimental observations be reconciled with theoretical models?
* How should learned physical models be distinguished from theoretically specified laws?
* How should model uncertainty be propagated through composed semantic systems?

These questions MUST NOT be resolved by prematurely coupling Physics to a particular implementation technology.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Established:

* Physics as a semantic law domain;
* physical quantities and units;
* physical state;
* laws and constraints;
* interactions;
* conservation;
* constitutive relationships;
* fields;
* equilibrium and non-equilibrium systems;
* measurement and uncertainty;
* scale and approximation;
* physical model validity;
* relationships with Mathematics, Fields, Geometry, Topology, Morphology, Dynamics, Agents, and Simulation;
* representation and provider independence;
* Semantic Hypergraph integration;
* MLIR integration;
* physical invariants and validation requirements.

---

# Definition Authority

This document is the normative semantic definition of the SCR Physics domain.

Implementation documents, source code, provider interfaces, examples, benchmarks, and generated artifacts MUST NOT redefine this domain without an explicit semantic revision.

---

# Definition Principle

> **Physics defines what physical systems, quantities, laws, interactions, constraints, and processes mean. It does not prescribe how those semantics are represented, solved, simulated, rendered, stored, or executed.**

The fundamental SCR separation is:

```text
PHYSICAL MEANING
      ↓
MATHEMATICAL FORM
      ↓
COMPUTATIONAL MODEL
      ↓
NUMERICAL / SYMBOLIC METHOD
      ↓
IMPLEMENTATION
      ↓
EXECUTION
      ↓
OBSERVATION / MANIFESTATION
```

The implementation is replaceable.

The physical semantics are not.

---

# Compact Conceptual Model

```text
                 PHYSICS
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
     QUANTITY      LAW       INTERACTION
        │           │           │
        └───────────┼───────────┘
                    ▼
              PHYSICAL STATE
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
       FIELDS    GEOMETRY   TOPOLOGY
          │         │         │
          └─────────┼─────────┘
                    ▼
                DYNAMICS
                    │
                    ▼
                SIMULATION
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
       AGENTS   PERCEPTION  RENDERING
```

Physics therefore occupies a critical position in SCR:

> **It is the domain that turns mathematical and structural abstractions into descriptions of lawful physical behaviour, while remaining independent of the computational machinery used to realize those descriptions.**
