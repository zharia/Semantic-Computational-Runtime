# SCR Application — Definition

**Path:** `lib/804_Application/101_definition.md`
**Domain:** Application
**Version:** 0.0.1
**Status:** Normative Draft

---

## 1. Purpose

The SCR Application domain defines the semantic model by which a bounded computational system is structured, composed, executed, interacted with, and exposed to external actors and systems.

The Application domain defines the **meaning and architecture of an application**, not a general-purpose programming language and not a concrete user-interface framework.

An SCR Application is defined by its:

* identity;
* state;
* structure;
* modules;
* capabilities;
* services;
* operations;
* interfaces;
* interactions;
* processes;
* transformations;
* resources;
* policies;
* lifecycle;
* implementation contracts;
* relationships.

Concrete implementation technologies such as Mojo, MLIR, WASM, native executables, GPU kernels, remote services, databases, message brokers, GUI frameworks, and operating systems participate through explicit semantic and execution boundaries.

---

# 2. Fundamental Definition

> **Application** — a bounded semantic computational system that maintains and transforms state, composes capabilities, coordinates executable behaviour, exposes semantic interfaces, receives observations and commands, produces actions and transformations, and participates in one or more execution environments.

An Application is therefore a semantic computational boundary.

Conceptually:

```text
Application =
    Identity
  + State
  + Structure
  + Behaviour
  + Interaction
  + Capability
  + Interface
  + Process
  + Transformation
  + Resource
  + Lifecycle
  + Implementation
```

This is a semantic composition, not a programming-language definition.

---

# 3. Semantic Primacy

The Application domain follows the SCR principle:

> **Meaning is defined before implementation.**

The semantic Application model MUST be valid independently of:

* programming language;
* compiler;
* executable format;
* operating system;
* processor architecture;
* database;
* message broker;
* network protocol;
* GUI toolkit;
* rendering engine;
* cloud platform;
* physical device;
* deployment topology.

Concrete technologies implement or manifest semantic contracts.

They do not define those contracts.

---

# 4. Application as Semantic Hypergraph

An Application is represented within SCR as a semantic hypergraph.

The Application hypergraph may contain:

* Application;
* ApplicationInstance;
* Module;
* Component;
* Service;
* Operation;
* Controller;
* Port;
* Adapter;
* Policy;
* Capability;
* Interface;
* State;
* Property;
* Value;
* Event;
* Observation;
* Command;
* Action;
* Transformation;
* Process;
* Resource;
* Lifecycle;
* Implementation;
* ImplementationBinding;
* ExecutableArtifact;
* ExecutionContract;
* EntryPoint;
* execution requirements;
* semantic relationships.

The Application hypergraph is the canonical semantic representation.

SCR MUST NOT introduce independent:

* service graphs;
* dependency graphs;
* widget trees;
* event graphs;
* controller graphs;
* implementation graphs.

Where such structures are required, they are represented as portions of the canonical SCR semantic hypergraph.

---

# 5. Application Architectural Model

SCR combines three architectural principles.

### 5.1 Semantic architecture

The Application is defined by semantic entities, relationships, capabilities, state, behaviour, and execution meaning.

### 5.2 Modular application architecture

Applications are decomposed into bounded Modules containing coherent capabilities and behaviour.

The organizational principles of frameworks such as NestJS provide useful architectural inspiration for:

* modules;
* services;
* controllers;
* dependency resolution;
* lifecycle;
* capability composition.

NestJS itself is not an SCR dependency and does not define SCR semantics.

### 5.3 Hexagonal architecture

Application semantics are separated from external infrastructure through:

```text
Port → Adapter → Provider
```

The Application depends upon semantic contracts.

Infrastructure implements those contracts.

---

# 6. Canonical Application Architecture

The resulting architecture is:

```text
                         APPLICATION
                              │
                         ┌────┴────┐
                         │ Modules │
                         └────┬────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
          Services       Controllers        Ports
              │               │               │
          Operations          │               │
              │               │               │
              └───────────────┼───────────────┘
                              │
                       Semantic Contracts
                              │
                     Implementation Binding
                              │
                  ┌───────────┴───────────┐
                  │                       │
          Execution Contract      Executable Artifact
                                          │
                         ┌────────────────┼────────────────┐
                         │                │                │
                        WASM            Native           Remote
                         │                │                │
                       Runtime       Mojo/MLIR/etc.      API/RPC
                         │                │                │
                         └────────────────┼────────────────┘
                                          │
                                         EGS
                                          │
                              Execution Space / Process
```

This architecture deliberately separates **semantic application structure** from **executable realization**.

---

# 7. Module

> **Module** — a bounded semantic composition of related application capabilities, services, controllers, ports, policies, resources, components, and interfaces.

A Module establishes a coherent semantic boundary.

A Module MAY contain:

* Services;
* Controllers;
* Ports;
* Operations;
* Policies;
* Components;
* Interfaces;
* Resources;
* subordinate Modules.

A Module MAY expose selected capabilities while keeping internal structure private.

Example:

```text
TradingModule
├── OrderService
├── PortfolioService
├── MarketDataService
├── OrderController
├── ExchangePort
└── TradingInterface
```

Modules provide semantic and dependency organization.

A Module is not itself a programming-language namespace, source-code directory, or deployment unit, although an implementation MAY map a Module to any of these.

---

# 8. Service

> **Service** — a semantic computational component that provides one or more coherent application capabilities through defined Operations, consumes dependencies through semantic Ports, and participates in application state and execution.

A Service represents **application behaviour and capability**.

A Service MAY:

* provide Operations;
* consume or transform state;
* invoke other Services;
* require capabilities;
* consume Resources;
* emit Events;
* produce Observations;
* issue Commands;
* invoke Ports;
* participate in transactions;
* execute synchronously or asynchronously.

Example:

```text
OrderService
├── CreateOrder
├── CancelOrder
├── AmendOrder
└── RetrieveOrder
```

A Service is semantic.

It is not a Provider.

---

# 9. Service and Process

Service and Process MUST remain distinct.

> **Service** defines a capability-bearing application boundary.

> **Process** defines an executing activity.

Therefore:

```text
Service
    │
    └── executesThrough → Process
```

A Service MAY execute through:

* one Process;
* multiple Processes;
* concurrent Processes;
* distributed Processes;
* remote Processes;
* GPU Processes;
* scheduled Processes.

A Process MAY execute behaviour belonging to one or more Services.

---

# 10. Operation

> **Operation** — a semantically defined executable capability exposed by an Application component or Service.

An Operation defines the semantic contract for a unit of application behaviour.

An Operation MAY define:

* identity;
* inputs;
* outputs;
* preconditions;
* postconditions;
* required capabilities;
* required resources;
* state effects;
* transformations;
* emitted events;
* errors;
* rejection conditions;
* execution constraints;
* implementation bindings.

Conceptually:

```text
Operation
├── accepts → Input
├── requires → Capability
├── requires → Resource
├── performs → Transformation
├── changes → State
└── produces → Output/Event
```

An Operation is a semantic contract.

It is not synonymous with a programming-language function.

---

# 11. Controller

> **Controller** — an application boundary component that receives an external Observation, Event, or Command and dispatches it into application semantics through an appropriate Operation, Service, or Port.

Controllers represent inbound application boundaries.

Possible manifestations include:

* HTTP Controller;
* CLI Controller;
* GUI Controller;
* AMQP Controller;
* WebSocket Controller;
* AI Controller;
* Robotics Controller;
* Sensor Controller;
* Timer Controller.

The transport mechanism is not part of the semantic Controller definition.

The canonical relationship is:

```text
External Input
      ↓
Observation / Event / Command
      ↓
Controller
      ↓
Operation
      ↓
Service
```

Controllers MUST NOT contain domain semantics that belong in Services, Operations, or other semantic components.

---

# 12. Port

> **Port** — a semantic contract defining a capability boundary between the Application and an external, replaceable, or independently implemented computational capability.

Ports implement the hexagonal boundary.

Two primary classes exist.

## 12.1 Inbound Port

An Inbound Port defines capabilities through which an external actor or system may cause application behaviour.

Examples:

```text
CreateOrderPort
UserManagementPort
SimulationControlPort
RobotCommandPort
```

Controllers commonly adapt external interactions to Inbound Ports.

## 12.2 Outbound Port

An Outbound Port defines a capability required by the Application from an external system.

Examples:

```text
OrderRepositoryPort
MarketDataPort
IdentityPort
ClockPort
StoragePort
MessagePort
RenderingPort
```

Services depend upon the semantic contract of the Port rather than its implementation.

---

# 13. Adapter

> **Adapter** — a concrete architectural component that translates between a semantic Port and an external implementation, protocol, representation, or Provider.

Adapters belong outside the semantic Application core.

Example:

```text
OrderRepositoryPort
        │
        ▼
CouchDBAdapter
        │
        ▼
CouchDB Provider
```

or:

```text
RobotCommandPort
        │
        ▼
ROS2Adapter
        │
        ▼
ROS2 Provider
```

An Adapter MAY translate:

* data representation;
* protocol;
* ABI;
* transport;
* addressing;
* lifecycle;
* authentication;
* resource management.

The semantic meaning remains defined by the Port.

---

# 14. Provider

> **Provider** — a concrete implementation capable of satisfying a semantic capability, Port, or execution requirement.

Providers are external to the semantic Application ontology.

Examples include:

* CouchDB;
* PostgreSQL;
* RabbitMQ;
* AMQP implementations;
* Chrono;
* H3;
* OpenVDB;
* Vulkan;
* CUDA;
* ROS2;
* OGRE;
* Qt;
* GTK;
* Web runtimes;
* Mojo runtimes;
* WASM runtimes;
* Keycloak.

A Provider MAY be:

* canonical;
* preferred;
* alternative;
* experimental;
* local;
* remote;
* test-only.

Provider-specific concepts MUST NOT leak into the semantic Application ontology.

---

# 15. Service–Port–Adapter–Provider Boundary

The canonical dependency direction is:

```text
Service
   │
   ▼
Port
   │
   ▼
Adapter
   │
   ▼
Provider
```

A semantic Service MUST NOT directly depend upon a concrete infrastructure Provider.

Incorrect:

```text
OrderService → CouchDB
```

Correct:

```text
OrderService
      │
      ▼
OrderRepositoryPort
      │
      ▼
CouchDBAdapter
      │
      ▼
CouchDB
```

Provider substitution MUST therefore be possible without changing application meaning.

---

# 16. Capability

> **Capability** — a semantically identifiable ability that may be provided, required, composed, authorized, or executed.

Examples:

```text
CreateUser
PersistUser
ReadMarketData
ExecuteTrade
RenderScene
PublishMessage
ControlRobot
ComputeDynamics
```

Capabilities are used by:

* Services;
* Operations;
* Ports;
* Policies;
* dependency resolution;
* authorization;
* EGS.

Capability identity is independent of implementation identity.

---

# 17. Dependency

> **Dependency** — a semantic requirement of one application element upon another capability, resource, service, port, or execution facility.

Dependencies MUST be represented semantically.

For example:

```text
OrderService
    └── requires → MarketDataPort
```

rather than:

```text
OrderService
    └── imports → SomeConcreteLibrary
```

The latter is implementation metadata.

---

# 18. Dependency Resolution

> **Dependency Resolution** — the runtime process of identifying and binding implementations capable of satisfying declared semantic dependencies.

The Application declares requirements.

EGS resolves those requirements.

Resolution MAY consider:

* capability;
* identity;
* version;
* locality;
* execution space;
* platform;
* architecture;
* resource availability;
* performance;
* security;
* trust;
* provider;
* lifecycle;
* compatibility.

Conceptually:

```text
Requirement
    ↓
Semantic Capability
    ↓
Port
    ↓
Candidate Implementations
    ↓
Provider / Artifact Selection
    ↓
Implementation Binding
```

Dependency resolution MUST NOT require the Application semantic model to know the implementation language.

---

# 19. Implementation

> **Implementation** — an executable realization of a semantic application capability, component, Operation, Service, Controller, Transformation, or other executable semantic element.

An Implementation is distinct from the semantic entity it realizes.

For example:

```text
Semantic:
    OrderService
        └── CreateOrder

Implementation:
    order_service.wasm
        └── create_order
```

The semantic entity defines meaning.

The Implementation realizes that meaning.

---

# 20. Implementation Binding

> **Implementation Binding** — the semantic association between an Application element and an executable Implementation, identifying the executable artifact, invocation contract, entry point, required capabilities, effects, and execution constraints necessary to realize the semantic element.

Conceptually:

```text
CreateOrder
     │
     └── implementedBy
              │
       ImplementationBinding
              │
       ┌──────┴──────┐
       │             │
    Artifact      EntryPoint
```

An Implementation Binding is therefore the bridge between:

```text
semantic meaning
```

and:

```text
executable realization
```

without making executable realization part of the semantic ontology.

---

# 21. Executable Artifact

> **Executable Artifact** — an identifiable, versioned representation containing executable implementation that can be instantiated, invoked, loaded, or otherwise executed by an SCR execution environment.

Examples include:

* WASM module;
* native executable;
* native library;
* Mojo-compiled artifact;
* MLIR executable artifact;
* GPU executable;
* accelerator binary;
* containerized executable;
* remote executable service;
* other supported execution artifact.

The Application domain MUST NOT require a single artifact format.

---

# 22. Execution Contract

> **Execution Contract** — the machine-interpretable contract governing how an Implementation may be invoked and what semantic effects it may produce.

An Execution Contract MAY specify:

* inputs;
* outputs;
* types;
* representation requirements;
* entry point;
* invocation mode;
* synchronous/asynchronous behaviour;
* state effects;
* transformations;
* emitted events;
* required capabilities;
* resource requirements;
* lifecycle requirements;
* isolation requirements;
* security requirements;
* determinism requirements;
* failure semantics;
* ABI or invocation mechanism.

The Execution Contract separates semantic invocation from executable representation.

---

# 23. Entry Point

> **Entry Point** — an identifiable invocation target within an executable Implementation associated with a semantic Operation, Service, Controller, or other executable element.

An Entry Point MAY correspond to:

* a WASM export;
* a native symbol;
* a Mojo function;
* an MLIR-generated callable;
* a remote RPC operation;
* another execution mechanism.

The semantic identity of the Operation MUST remain independent of the concrete Entry Point identity.

---

# 24. Invocation

> **Invocation** — the runtime act of causing an Implementation associated with a semantic executable element to execute according to its Execution Contract.

Invocation is an execution concern.

A semantic Command or Action MAY result in an Invocation.

Conceptually:

```text
Command
   ↓
Operation
   ↓
Implementation Binding
   ↓
Invocation
   ↓
Executable Artifact
   ↓
Process
```

---

# 25. Mojo

Mojo is a primary implementation technology for SCR.

Mojo MAY be used to implement:

* Services;
* Operations;
* Controllers;
* Adapters;
* Providers;
* runtime components;
* semantic library implementation;
* executable application components.

Mojo MUST NOT define the semantics of those Application concepts.

The semantic model MUST remain valid if a particular implementation is replaced with another supported execution technology.

---

# 26. MLIR

SCR is an MLIR extension ecosystem.

MLIR provides an important implementation and compilation boundary between semantic representation and executable realization.

Conceptually:

```text
SCR Semantic Model
       ↓
SCR / MLIR representation
       ↓
Implementation
       ↓
Compilation / Lowering
       ↓
Executable Artifact
```

SCR semantic dialects MAY represent application contracts and executable relationships.

They MUST NOT accidentally become a complete general-purpose programming language merely because they are represented through MLIR.

---

# 27. WASM

WebAssembly (WASM) is a supported portable executable target for appropriate SCR implementations.

WASM provides a useful boundary for:

* portable application components;
* sandboxed execution;
* browser execution;
* edge execution;
* service execution;
* plugin execution;
* controlled execution environments.

WASM is an **implementation technology**, not an Application semantic primitive.

The correct relationship is:

```text
Service
   │
Operation
   │
ImplementationBinding
   │
ExecutableArtifact
   │
format = WASM
   │
WASM Runtime
```

The semantic Application MUST NOT become WASM-specific.

---

# 28. Mojo and WASM Relationship

Mojo and WASM occupy different architectural positions.

Mojo is primarily an **implementation language** within the SCR ecosystem.

WASM is primarily an **executable target/runtime boundary**.

Therefore:

```text
Semantic Application
        │
        ▼
Implementation
        │
      Mojo
        │
       MLIR
        │
        ▼
Executable Artifact
        │
      WASM
        │
        ▼
WASM Runtime
```

or:

```text
Semantic Application
        │
        ▼
Implementation
        │
     Mojo/MLIR
        │
        ▼
Native Executable
```

or:

```text
Semantic Application
        │
        ▼
Implementation
        │
    Other Language
        │
        ▼
Remote / Native / WASM
```

The semantic model is independent of all three choices.

---

# 29. No General-Purpose Programming Language

The Application semantic library MUST NOT become a complete programming system.

The semantic library MAY define:

* executable capabilities;
* Operations;
* Services;
* state transitions;
* transformations;
* dependencies;
* ports;
* contracts;
* execution requirements;
* implementation bindings;
* invocation semantics;
* execution effects.

The semantic library MUST NOT attempt to define a general-purpose programming language containing concepts such as:

* source-language syntax;
* lexical grammar;
* variables as a general programming construct;
* loops;
* functions as a complete language construct;
* classes;
* inheritance;
* closures;
* general-purpose control flow;
* memory allocation syntax;
* compiler syntax;
* language-specific ABI rules.

Those concerns belong to implementation languages, compiler infrastructure, and execution runtimes.

---

# 30. Semantic Executability

SCR nevertheless MUST provide enough semantic information to determine:

> **What executable capability is required, what contract it must satisfy, what effects it may have, and where it may execute.**

This distinction is fundamental.

SCR defines **executable semantics**.

SCR does not define a **general-purpose programming language**.

---

# 31. State

An Application maintains semantic state.

State MAY include:

* persistent state;
* transient state;
* configuration state;
* derived state;
* execution state;
* interaction state;
* resource state;
* lifecycle state.

Services and Operations MAY read or transform state subject to their semantic contracts.

Presentation components MUST NOT become authoritative state owners merely because they display or edit state.

---

# 32. Transformation

> **Transformation** — a semantic operation that changes one valid semantic state, structure, representation, or relationship into another.

Transformations MAY:

* modify state;
* create entities;
* remove entities;
* modify relationships;
* produce Events;
* produce Observations;
* invoke external capabilities;
* generate new Processes.

Transformations MUST preserve the invariants of the affected semantic domains.

---

# 33. Event

> **Event** — a semantically identifiable occurrence within an Application or its environment.

An Event MAY be:

* internally generated;
* externally received;
* derived from an Observation;
* generated by a State Transition;
* emitted by a Service;
* produced by a Provider.

A semantic Event is not equivalent to an arbitrary programming-language callback.

Where applicable, an Event contains:

* identity;
* type;
* source;
* target;
* temporal position;
* payload;
* propagation metadata;
* authority context.

---

# 34. Observation

> **Observation** — information received by an Application or semantic actor concerning a state, event, entity, field, environment, or external condition.

Observation and Event are distinct:

```text
Event       = occurrence
Observation = received information
```

An Observation MAY result in an Event, Command, Action, or State Transition.

This is not mandatory.

---

# 35. Command

> **Command** — a semantic request that an Application capability or Operation be performed.

A Command expresses intent.

It does not itself constitute execution.

For example:

```text
Command:
    CreateOrder
```

may cause:

```text
CreateOrder
    ↓
OrderService
    ↓
Action
    ↓
Transformation
```

---

# 36. Action

> **Action** — a semantically defined executable activity undertaken by an actor, Service, Process, or system to produce an intended effect.

Command and Action MUST remain distinct.

```text
Command = requested execution

Action = execution
```

A Command MAY result in an Action.

An Action MAY result in one or more Transformations.

---

# 37. Application Interface

> **Application Interface** — the semantic boundary through which an Application exposes state, observations, events, commands, actions, capabilities, resources, and other interactions to an external actor or system.

An Application Interface is not synonymous with GUI.

It MAY be manifested as:

* GUI;
* Web;
* CLI;
* API;
* AMQP;
* AI/agent interface;
* robotics interface;
* simulation interface;
* XR interface;
* embedded control interface.

The semantic interface remains independent of its manifestation.

---

# 38. Presentation

Presentation is a manifestation of Application semantics.

The fundamental rule is:

> **Presentation is a projection of application state and capability, not the owner of application meaning.**

Examples:

```text
Button
TextInput
Display
Form
Panel
Menu
Dialog
Dashboard
```

are semantic interaction concepts where their meaning is required.

Concrete instances such as:

```text
QtButton
GTKButton
HTMLButton
ReactComponent
OGREControl
```

are provider manifestations and MUST NOT become semantic Application ontology.

---

# 39. Application Lifecycle

Application lifecycle MUST be represented semantically.

At minimum:

```text
Declared
    ↓
Registered
    ↓
Initialized
    ↓
Ready
    ↓
Running
    ↓
Stopping
    ↓
Stopped
```

Additional lifecycle states MAY include:

```text
Suspended
Recovering
Degraded
Failed
Unavailable
Terminated
```

Services, Processes, Implementations, and Providers MAY have subordinate lifecycles subject to the Application lifecycle.

---

# 40. Resource

> **Resource** — a semantically identifiable computational, informational, physical, or execution asset that may be required, consumed, allocated, or released by an Application element.

Resources MAY include:

* CPU;
* GPU;
* memory;
* storage;
* network;
* files;
* datasets;
* credentials;
* devices;
* message channels;
* execution spaces;
* external services.

Resource availability MUST remain distinct from authorization.

```text
Resource available
    ≠
Capability authorized
```

---

# 41. Policy

> **Policy** — a semantic constraint governing the permitted behaviour, execution, access, resource use, or transformation of an Application element.

Policies MAY constrain:

* Services;
* Operations;
* Controllers;
* Ports;
* Resources;
* Implementations;
* Providers;
* execution spaces.

Security and authorization MUST reuse the canonical SCR authority model.

The Application domain MUST NOT define a separate security ontology where existing SCR security semantics are sufficient.

---

# 42. Application Instance

> **Application Instance** — a runtime manifestation of an Application semantic definition within a particular execution context.

An Application definition may have multiple Instances.

For example:

```text
Application:
    TradingPlatform

Instances:
    trading-prod-eu
    trading-prod-africa
    trading-test
```

An Instance MAY have distinct:

* state;
* resources;
* execution spaces;
* provider bindings;
* lifecycle;
* configuration;
* identities.

The semantic Application definition remains distinct from its runtime Instances.

---

# 43. Execution Context

> **Execution Context** — the semantic and runtime environment in which an Application Instance or Process executes.

An Execution Context MAY include:

* execution Space;
* resources;
* identity;
* capabilities;
* providers;
* implementation bindings;
* lifecycle;
* isolation;
* network;
* storage;
* processor;
* accelerator.

This integrates the Application domain with the SCR Semantic Machine Model.

---

# 44. EGS

The Executable Graph Server (EGS) is responsible for resolving and manifesting the executable Application hypergraph.

EGS MAY:

* resolve Modules;
* resolve Services;
* resolve Dependencies;
* bind Ports;
* select Providers;
* resolve Implementations;
* resolve Executable Artifacts;
* establish Execution Contracts;
* bind Entry Points;
* instantiate Processes;
* allocate execution Spaces;
* establish messaging;
* manage lifecycle;
* enforce execution constraints;
* connect semantic fields.

EGS MUST NOT redefine Application semantics.

The Application defines meaning.

EGS resolves and manifests that meaning.

Providers implement specialized capabilities.

---

# 45. Application Execution Model

The canonical semantic execution path is:

```text
External Actor / Environment
             │
             ▼
        Observation
             │
             ▼
        Event / Command
             │
             ▼
         Controller
             │
             ▼
          Operation
             │
             ▼
          Service
             │
             ├───────────────┐
             │               │
             ▼               ▼
          State           Outbound Port
             │               │
             │               ▼
             │            Adapter
             │               │
             │               ▼
             │            Provider
             │
             ▼
      Transformation
             │
             ▼
      State Transition
             │
             ▼
      Event / Observation / Output
```

The implementation path is:

```text
Semantic Operation
        │
        ▼
Implementation Binding
        │
        ▼
Execution Contract
        │
        ▼
Executable Artifact
        │
        ▼
Entry Point
        │
        ▼
Invocation
        │
        ▼
Process
        │
        ▼
Execution Space
```

These are related but distinct semantic layers.

---

# 46. Relationship Between Semantic and Implementation Graphs

There is only one canonical SCR semantic graph.

However, the graph MAY contain relationships describing implementation.

For example:

```text
CreateOrder
    │
    └── implementedBy
            │
      ImplementationBinding
            │
            ├── artifact → order.wasm
            ├── entryPoint → create_order
            └── contract → CreateOrderContract
```

The executable artifact itself does not become part of the semantic ontology merely because the graph references it.

The graph describes the relationship.

The artifact contains the implementation.

---

# 47. Implementation Subdomain

The Application domain therefore includes an `implementation` subdomain.

The implementation subdomain is responsible for:

* Implementation;
* ImplementationBinding;
* ExecutableArtifact;
* ExecutionContract;
* EntryPoint;
* ExecutionRequirement;
* ExecutionEffect;
* Invocation.

It does NOT define:

* Mojo syntax;
* WASM instruction semantics;
* compiler grammar;
* LLVM internals;
* general-purpose programming constructs.

Those belong to their respective implementation and toolchain domains.

---

# 48. Provider Independence

An Application MUST remain semantically valid when its implementation providers are substituted.

For example:

```text
CreateOrder
│
├── Mojo/native implementation
├── WASM implementation
├── remote implementation
└── test implementation
```

The semantic Operation remains the same.

The implementation may differ in:

* performance;
* execution environment;
* numerical precision;
* resource usage;
* concurrency;
* deployment;
* ABI;
* artifact format.

Semantic equivalence MUST be evaluated against the Operation's contract and invariants, not against implementation identity.

---

# 49. Multiple Implementations

A semantic Application element MAY have multiple valid Implementations.

For example:

```text
RenderScene
│
├── Vulkan Implementation
├── WebGPU Implementation
├── CPU Implementation
└── Remote Rendering Implementation
```

or:

```text
SimulationStep
│
├── Chrono Implementation
├── GPU Implementation
└── Test Implementation
```

EGS MAY select among implementations according to semantic requirements and runtime constraints.

---

# 50. Implementation Selection

Implementation selection MAY consider:

* required capability;
* semantic version;
* implementation version;
* platform;
* architecture;
* execution Space;
* locality;
* resource requirements;
* performance;
* security;
* isolation;
* provider;
* artifact format;
* trust;
* lifecycle;
* compatibility;
* determinism;
* fidelity.

Selection MUST preserve the semantic contract.

---

# 51. Framework Independence

The Application domain MUST NOT depend upon:

* NestJS;
* MojoFlow;
* Qt;
* GTK;
* React;
* Angular;
* Vue;
* Flutter;
* Electron;
* ImGui;
* OGRE;
* ROS;
* HTTP;
* AMQP;
* PostgreSQL;
* CouchDB;
* Kubernetes;
* WASM.

These may participate as implementation technologies, providers, or adapters.

NestJS provides architectural inspiration for modularity, controllers, services, dependency resolution, and lifecycle.

Hexagonal architecture provides the application/infrastructure boundary.

Mojo provides a primary implementation language.

MLIR provides the principal compiler/IR ecosystem.

WASM provides an important portable executable target.

None of these defines SCR Application semantics.

---

# 52. MojoFlow

MojoFlow MAY be evaluated as an Application framework/provider.

If adopted as a canonical Application provider, it MUST remain subordinate to the SCR Application semantic model.

MojoFlow MUST NOT define:

* Service semantics;
* Module semantics;
* Controller semantics;
* Application state semantics;
* Application Interface semantics;
* implementation binding semantics.

It may provide implementations of them.

The semantic Application MUST remain executable without MojoFlow.

---

# 53. Cross-Domain Composition

Application Services MAY consume and expose capabilities from any SCR semantic domain.

Examples:

```text
TradingService
    → MarketData
    → Stream
    → FinancialData
    → ExchangeProvider
```

```text
RobotControlService
    → Agent
    → Embodiment
    → Observation
    → Action
    → Physics
    → ROS2Provider
```

```text
SimulationService
    → Simulation
    → Space
    → Dynamics
    → PhysicsProvider
```

```text
AIService
    → Neural
    → Observation
    → Action
    → WorldModel
    → ModelProvider
```

The Application domain is therefore a composition domain, not a replacement for the domains it consumes.

---

# 54. Application and Other SCR Domains

The Application domain MUST integrate with:

* Core;
* Data;
* Graph;
* Field;
* Spatial;
* System;
* Stream;
* Agent;
* Neural;
* Physics;
* Dynamics;
* Simulation;
* Render;
* Resource;
* Identity;
* Security;
* execution/runtime domains.

The Application domain MUST reuse existing semantic concepts wherever possible.

New concepts MUST pass the SCR semantic promotion test:

1. Is the concept genuinely new?
2. Does an existing SCR concept already express it?
3. Does the concept have independent semantic invariants?
4. Does it occur across multiple implementations?
5. Is it required for composition?
6. Would removing it make the semantic model materially less expressive?

---

# 55. Semantic Boundary Rules

The following separation is normative:

```text
Semantic Library
    ↓
defines meaning

Application Architecture
    ↓
defines composition and contracts

Implementation Binding
    ↓
connects meaning to executable realization

EGS
    ↓
resolves and manifests execution

Adapter
    ↓
translates infrastructure boundaries

Provider
    ↓
implements capability

Execution Runtime
    ↓
executes artifact
```

No layer should silently assume responsibility belonging to another layer.

---

# 56. Architectural Invariants

The following invariants are normative.

### A1 — Semantic Primacy

Application semantics MUST be defined independently of implementation technology.

### A2 — Hypergraph Primacy

The SCR semantic hypergraph is the canonical representation of Application structure and relationships.

### A3 — Modular Composition

Applications SHOULD be composed from semantically bounded Modules.

### A4 — Service Independence

Services MUST depend upon semantic contracts rather than concrete infrastructure.

### A5 — Port Boundary

External dependencies MUST cross semantic Port boundaries.

### A6 — Adapter Isolation

Adapters MUST isolate infrastructure-specific protocols and representations.

### A7 — Provider Substitution

Providers MAY be replaced without changing Application meaning.

### A8 — Implementation Separation

Executable implementations MUST remain distinct from the semantic entities they realize.

### A9 — Binding Explicitness

The relationship between semantic executable elements and executable artifacts MUST be explicitly represented by an Implementation Binding.

### A10 — Contract Explicitness

Executable implementations MUST have a defined Execution Contract where invocation semantics require one.

### A11 — Language Independence

The Application ontology MUST NOT depend upon Mojo, WASM, or any other programming or executable technology.

### A12 — No General-Purpose Language

The semantic Application library MUST NOT evolve into a general-purpose programming language.

### A13 — Controller Boundary

Controllers MUST translate inbound interactions into semantic application operations.

### A14 — State Authority

Presentation MUST NOT become the authoritative owner of application state merely because it represents that state.

### A15 — Authorization Separation

Visibility, availability, capability, and authorization MUST remain distinct.

### A16 — Process Distinction

Service and Process MUST remain distinct semantic concepts.

### A17 — Command/Action Distinction

Command represents requested execution; Action represents execution.

### A18 — Event/Observation Distinction

Event represents occurrence; Observation represents received information.

### A19 — Core Reuse

Application MUST reuse canonical SCR primitives rather than creating duplicate semantic systems.

### A20 — Provider Non-Leakage

Provider-specific ontology MUST NOT leak into the semantic Application domain.

### A21 — Manifestation Independence

A semantic Application MUST support multiple concrete manifestations where implementations exist.

### A22 — Executable Substitution

A semantic Operation MUST be capable of having multiple valid executable Implementations.

### A23 — Contract Preservation

Implementation substitution MUST preserve the semantic contract and declared invariants of the capability being implemented.

---

# 57. Canonical Application Model

The canonical semantic architecture is:

```text
Application
│
├── Module
│   ├── Service
│   │   └── Operation
│   │       └── ImplementationBinding
│   │           ├── ExecutionContract
│   │           ├── ExecutableArtifact
│   │           └── EntryPoint
│   │
│   ├── Controller
│   │   └── Port
│   │
│   ├── Policy
│   └── Interface
│
├── State
├── Component
├── Event
├── Observation
├── Command
├── Action
├── Transformation
├── Process
├── Resource
└── Lifecycle
```

The external implementation boundary is:

```text
Semantic Application
        │
        ▼
Port / Implementation Binding
        │
        ▼
Adapter / Execution Resolver
        │
        ▼
Provider / Executable Artifact
        │
        ▼
Execution Runtime
```

---

# 58. Fundamental Execution Principle

SCR defines:

> **What the application means.**

The Application architecture defines:

> **How semantic capabilities are composed.**

Implementation bindings define:

> **Which executable realization provides those capabilities.**

EGS defines:

> **Where and under what runtime conditions those implementations execute.**

Providers define:

> **How specialized capabilities are concretely implemented.**

Mojo, MLIR, WASM, native execution, GPU execution, and remote execution provide:

> **Concrete implementation and execution mechanisms.**

---

# 59. Fundamental Definition

The SCR Application domain therefore defines:

> **An Application is a bounded semantic hypergraph whose Modules compose capabilities, whose Services provide executable application behaviour, whose Operations define semantic execution contracts, whose Controllers receive and translate external interaction, whose Ports define dependency boundaries, whose Adapters connect those boundaries to external implementations, whose State, Events, Observations, Commands, Actions, Transformations, Processes, Resources, Policies, Interfaces, and Lifecycles define application meaning, and whose Implementation Bindings connect semantic executable elements to concrete executable artifacts without making any programming language or execution format part of the semantic ontology.**

The architectural rule is:

> **Modules organize meaning. Services provide behaviour. Operations define executable capability. Controllers receive interaction. Ports define boundaries. Adapters translate boundaries. Implementation Bindings connect semantics to executable artifacts. EGS resolves and manifests execution. Providers implement capabilities. Mojo, MLIR, WASM, native, GPU, and remote technologies remain implementation mechanisms rather than semantic definitions.**

The fundamental SCR principle remains:

> **SCR owns the semantics; EGS owns executable manifestation and orchestration; implementations and providers own concrete execution.**
