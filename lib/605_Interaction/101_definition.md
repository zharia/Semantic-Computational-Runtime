# Semantic Computational Runtime

# Interaction Domain Definition

**Path:** `lib/605_Interaction/101_definition.md`
**Version:** `0.0.1`
**Status:** Normative Definition
**Domain:** Interaction
**Semantic Authority:** Semantic Computational Runtime (SCR)

---

## 1. Purpose

The Interaction domain defines the semantic structures through which an actor, observer, agent, process, device, or computational entity participates in a computational field.

Interaction describes how observations, inputs, gestures, intentions, controls, actions, and feedback relate to one another.

The Interaction domain provides the semantic foundation for:

* human-computer interaction;
* machine-computer interaction;
* agent-computer interaction;
* multimodal interaction;
* mouse and pointer interaction;
* touch interaction;
* pen and stylus interaction;
* spatial and immersive interaction;
* gesture recognition;
* gesture sequences;
* gesture chords;
* interaction mapping;
* interaction sessions;
* control;
* feedback;
* accessibility;
* alternative interaction modalities.

Interaction is a semantic domain.

It is not a GUI framework, widget toolkit, device driver framework, rendering system, or general-purpose event-processing framework.

---

# 2. Fundamental Principle

SCR defines interaction as a semantic relationship between an actor or observer and a computational field.

The fundamental model is:

```text
Actor / Observer
       │
       ▼
    Input
       │
       ▼
  Observation
       │
       ▼
 Recognition
       │
       ▼
    Gesture
       │
       ▼
     Intent
       │
       ▼
     Action
       │
       ▼
Transformation
       │
       ▼
Semantic Field
       │
       ▼
   Feedback
       │
       └──────────────► Actor / Observer
```

Not every interaction contains every stage.

The model describes the semantic relationship, not a mandatory implementation pipeline.

---

# 3. Semantic Primacy

The Interaction domain defines what an interaction means.

It does not define how an interaction is physically captured or rendered.

For example:

```text
Mouse
Touchscreen
Stylus
VR Controller
Hand Tracker
Eye Tracker
Microphone
Keyboard
```

are implementation or input modalities.

The corresponding semantic concepts may include:

```text
Pointer
Movement
ButtonState
Gesture
Observation
Intent
Action
Control
```

The distinction is mandatory.

A concrete device or framework must not become the semantic definition merely because it provides an implementation.

---

# 4. Scope

The Interaction domain governs:

1. input abstraction;
2. observations;
3. gesture representation;
4. gesture recognition;
5. gesture composition;
6. temporal interaction;
7. spatial interaction;
8. gesture sequences;
9. gesture chords;
10. interaction expressions;
11. intent;
12. interaction context;
13. interaction mappings;
14. interaction sessions;
15. control;
16. feedback;
17. cancellation;
18. commitment;
19. accessibility;
20. multimodal interaction.

---

# 5. Non-Scope

The Interaction domain does not define:

* operating-system input APIs;
* GUI widget implementations;
* rendering APIs;
* windowing systems;
* device drivers;
* hardware protocols;
* browser event APIs;
* vendor-specific controller APIs;
* application-specific command vocabularies;
* visual presentation;
* physical device implementation;
* provider-specific recognition algorithms;
* general-purpose programming-language syntax.

These belong to applications, providers, runtimes, or other semantic domains as appropriate.

---

# 6. Relationship to the Semantic Field

Interaction exists at the boundary between an actor or observer and a Semantic Field.

An interaction may:

* observe state;
* request state transformation;
* modify state;
* establish a relationship;
* remove a relationship;
* navigate a computational space;
* manipulate an object;
* invoke an operation;
* control an execution process;
* provide feedback.

The Semantic Field remains authoritative.

An interaction does not become authoritative merely because it originates from a user or device.

---

# 7. Interaction as a Semantic Relationship

An Interaction is a semantic relationship involving:

```text
Actor
Context
Observation
Interpretation
Intent
Target
Action
State
Feedback
```

An interaction may therefore be represented conceptually as:

```text
Actor
  │
  │ participatesIn
  ▼
Interaction
  │
  ├── occursIn → Context
  ├── observes → Observation
  ├── interprets → Gesture
  ├── expresses → Intent
  ├── targets → SemanticObject
  ├── requests → Action
  └── produces → Feedback
```

The exact participating elements depend on the interaction.

---

# 8. Actor

An Actor is an entity capable of initiating or participating in an interaction.

Actors may include:

* humans;
* software agents;
* autonomous systems;
* processes;
* services;
* robots;
* machines;
* sensors;
* external computational systems.

An Actor is not restricted to a human user.

---

# 9. Observer

An Observer is an entity or process that receives or derives information from a computational field.

An Observer may be:

* a human;
* an application;
* a sensor;
* an agent;
* a rendering system;
* an analysis process;
* another computational system.

An Actor may also be an Observer.

An Observer need not be an Actor.

---

# 10. Input

Input is a semantic representation of information entering an interaction boundary.

Input may originate from:

* physical devices;
* software;
* sensors;
* other computational processes;
* network messages;
* agents;
* human activity;
* environmental phenomena.

Input is not synonymous with a physical device.

A device is an implementation source of Input.

---

# 11. Pointer

Pointer is a semantic abstraction representing a directed or position-bearing interaction reference.

A Pointer may have:

* position;
* orientation;
* movement;
* button state;
* pressure;
* velocity;
* acceleration;
* contact state;
* identity;
* source;
* timestamp.

A Pointer may be realized by:

* mouse;
* touch contact;
* stylus;
* controller;
* tracked hand;
* gaze;
* other pointing mechanisms.

The semantic Pointer must remain independent of the physical device.

---

# 12. Observation

An Observation represents information obtained from an interaction boundary.

Examples include:

```text
PointerMoved
ButtonPressed
ButtonReleased
PointerEntered
PointerExited
TouchStarted
TouchMoved
TouchEnded
HandMoved
GazeChanged
ControllerMoved
VoiceReceived
```

An Observation is not necessarily an Event.

An Event represents an occurrence in a semantic system.

An Observation represents information acquired about a system, environment, or interaction.

The same occurrence may produce an Event and an Observation, but the concepts must not be conflated.

---

# 13. Gesture

A Gesture is a recognized semantic pattern within one or more observations.

Examples include:

```text
Click
DoubleClick
Drag
Swipe
Stroke
Circle
Pinch
Rotate
Dwell
Hold
Point
```

A Gesture may have:

* spatial characteristics;
* temporal characteristics;
* direction;
* magnitude;
* velocity;
* acceleration;
* curvature;
* duration;
* participants;
* modifiers;
* constraints;
* context;
* confidence.

A Gesture is an interpretation of observations.

A raw pointer trajectory is not necessarily a Gesture.

---

# 14. Gesture Candidate

A Gesture Candidate represents a provisional interpretation of observations that has not yet achieved final recognition.

A recognizer may maintain multiple candidates:

```text
Circle       0.62
Arc          0.24
Drag         0.14
```

Recognition may evolve as additional observations arrive.

This permits:

* predictive interaction;
* early feedback;
* continuous recognition;
* ambiguity handling;
* delayed commitment.

A Gesture Candidate must not be treated as a committed semantic Gesture unless its recognition criteria have been satisfied.

---

# 15. Gesture Recognition

Gesture Recognition is the semantic process of deriving Gestures from observations.

Conceptually:

```text
Observation*
      │
      ▼
Gesture Recognition
      │
      ▼
Gesture Candidate*
      │
      ▼
Recognized Gesture
```

The recognition mechanism is implementation-dependent.

A Provider may implement recognition using:

* deterministic rules;
* geometric algorithms;
* statistical models;
* machine learning;
* neural networks;
* temporal models;
* user-specific models.

The semantic contract defines the resulting meaning and guarantees, not the recognition algorithm.

---

# 16. Gesture Path

A Gesture Path represents the spatial or abstract trajectory associated with a Gesture.

A Gesture Path may contain:

* ordered positions;
* timestamps;
* velocity;
* acceleration;
* direction;
* curvature;
* pressure;
* orientation;
* source identity.

Gesture Path data may be retained even after a higher-level Gesture has been recognized.

This permits applications to use both:

```text
recognized semantic gesture
```

and:

```text
underlying continuous control signal
```

without conflating them.

---

# 17. Gesture Phase

A Gesture may have semantic phases.

Typical phases include:

```text
Begin
Acquire
Update
Recognize
Commit
Cancel
Complete
```

A continuous Gesture may produce state updates between Begin and Complete.

A discrete Gesture may transition directly from recognition to completion.

---

# 18. Gesture Constraint

A Gesture Constraint restricts the conditions under which a Gesture is valid.

Constraints may include:

* spatial tolerance;
* angular tolerance;
* temporal tolerance;
* minimum displacement;
* maximum displacement;
* velocity;
* acceleration;
* pressure;
* participant count;
* modifier state;
* target;
* context.

Constraints may be absolute or contextual.

---

# 19. Interaction Expression

An Interaction Expression is a composable semantic representation of one or more interaction primitives.

An Interaction Expression may contain:

* a primitive Gesture;
* a Gesture Sequence;
* a Gesture Chord;
* an Alternative;
* an Optional component;
* a Repetition;
* a Conditional component;
* constraints.

Interaction Expressions provide a compositional grammar for interaction.

---

# 20. Gesture Sequence

A Gesture Sequence represents an ordered temporal composition of interaction elements.

For example:

```text
A → B → C
```

is a sequence in which ordering is semantically significant.

In general:

```text
A → B ≠ B → A
```

unless explicitly declared equivalent by the applicable semantic contract.

A sequence may specify:

* ordering;
* temporal intervals;
* maximum delays;
* minimum delays;
* overlap;
* repetition;
* cancellation;
* completion conditions.

---

# 21. Gesture Chord

A Gesture Chord represents multiple interaction elements whose concurrent occurrence has semantic significance.

For example:

```text
Shift + MouseButton + Drag
```

is a chord.

A chord is not equivalent to a sequence.

Conceptually:

```text
A & B
```

means concurrent composition.

Whereas:

```text
A → B
```

means temporal composition.

The distinction is semantic.

---

# 22. Multimodal Chord

A Gesture Chord may contain heterogeneous modalities.

For example:

```text
Gaze(Object42)
    +
Point(Object42)
    +
Voice("Delete")
```

may form a single interaction chord.

The individual components may originate from different Providers.

The semantic interaction system determines whether their combined state satisfies the applicable interaction expression.

---

# 23. Interaction Composition Operators

The Interaction domain defines the following conceptual composition operators:

```text
A ; B       temporal sequence

A & B       concurrent chord

A | B       alternative

A ?         optional

A *         repetition
```

These operators describe semantic composition.

They are not required to correspond directly to programming-language syntax.

---

# 24. Alternative Interaction

An Alternative represents multiple interaction expressions that may produce the same semantic intent or action.

For example:

```text
MouseGesture
    |
TouchGesture
    |
VoiceCommand
    |
AgentCommand
```

may all resolve to:

```text
RotateObject
```

Alternative interaction is fundamental to:

* multimodal interaction;
* accessibility;
* user preferences;
* device independence;
* adaptive interfaces.

---

# 25. Optional Interaction

An Optional component may occur without invalidating the enclosing Interaction Expression.

For example:

```text
Hold(Shift)?
    +
Drag
```

may allow both:

```text
Drag
```

and:

```text
Shift + Drag
```

to remain valid expressions with different interpretations.

---

# 26. Repetition

Repetition represents repeated occurrence of an interaction element.

Examples:

```text
Click*
Circle[3]
Swipe[2..4]
```

Repetition may be bounded or unbounded according to the applicable contract.

Timing and termination conditions must be defined where ambiguity would otherwise arise.

---

# 27. Intent

Intent represents the semantic purpose inferred from an interaction.

Examples include:

```text
Select
Move
Rotate
Scale
Navigate
Connect
Create
Delete
Inspect
Invoke
Open
Close
Transform
```

Intent is distinct from Gesture.

A Gesture describes what interaction pattern occurred.

Intent describes what the Actor is attempting to accomplish.

The same Gesture may express different Intents in different contexts.

---

# 28. Interaction Context

Interaction Context defines the semantic circumstances in which an Interaction is interpreted.

Context may include:

* Application;
* Module;
* Service;
* current operation;
* semantic target;
* current state;
* actor;
* active modality;
* spatial region;
* permissions;
* interaction mode;
* active Interaction Mapping.

Context may change during an Interaction Session.

---

# 29. Target

An Interaction Target is the semantic object, field, operation, space, relationship, or process toward which an interaction is directed.

Targets may include:

```text
Object
Relationship
Field
Application
Service
Operation
Process
Space
Provider
Semantic Machine
```

Target selection is semantic.

A rendered visual object may be a manifestation of the target but is not necessarily the target itself.

---

# 30. Interaction Mapping

An Interaction Mapping associates an Interaction Expression and Context with an Intent or Action.

Conceptually:

```text
Interaction Expression
        +
Context
        +
Target
        ↓
Interaction Mapping
        ↓
Intent / Action
```

Example:

```text
RMB + Drag
    +
3D Object Context
    ↓
Orbit / Rotate
```

The same Gesture may therefore produce different semantic results in different contexts.

---

# 31. Action

Action represents a semantic operation that an Actor or computational process requests or performs.

Interaction may produce, request, or invoke an Action.

Interaction does not own the universal definition of Action where Action is already defined by another SCR semantic domain.

The Interaction domain therefore references Action rather than redefining it.

---

# 32. Command

A Command represents a semantic request for an operation to be performed.

Interaction may generate a Command.

For example:

```text
Gesture
    ↓
Intent: Delete
    ↓
Command: Delete(Object42)
    ↓
Operation
```

Command semantics remain governed by the appropriate SCR semantic domain.

---

# 33. Transformation

A Transformation changes semantic state.

Interaction may initiate a Transformation indirectly through:

```text
Gesture
    ↓
Intent
    ↓
Action / Command
    ↓
Operation
    ↓
Transformation
```

The Interaction domain does not become the owner of state transformation semantics.

---

# 34. Interaction Session

An Interaction Session represents a bounded period during which interaction state is maintained.

A Session may contain:

```text
Begin
Acquire
Update*
Commit | Cancel
Release
```

For example:

```text
PointerDown
    ↓
Begin Session
    ↓
Capture
    ↓
PointerMove*
    ↓
Gesture Recognition
    ↓
Commit
    ↓
Release
```

Sessions permit interaction to remain coherent across multiple observations.

---

# 35. Capture

Capture establishes that an interaction source remains associated with an Interaction Session despite changes to its immediate presentation target.

For example, a pointer may begin dragging an object and subsequently leave the object's rendered region while the interaction remains active.

Capture belongs to semantic Interaction Session behaviour.

Concrete pointer capture mechanisms belong to Providers.

---

# 36. Commitment

Commit represents the point at which an Interaction produces an accepted semantic result.

Before commitment, an interaction may remain provisional.

Commit may:

* finalize an Action;
* finalize a Transformation;
* establish a relationship;
* invoke an Operation;
* produce a Command.

---

# 37. Cancellation

Cancellation terminates an Interaction without accepting its provisional semantic result.

Cancellation must define the required state behaviour.

Where an Interaction has already produced provisional state changes, cancellation may require restoration or compensating transformation.

Cancellation is therefore distinct from ordinary completion.

---

# 38. Feedback

Feedback represents information returned to an Actor or Observer as a consequence of an Interaction.

Feedback may include:

* visual feedback;
* auditory feedback;
* haptic feedback;
* textual feedback;
* spatial feedback;
* semantic state feedback.

Feedback is not restricted to presentation.

Its purpose is to communicate the state or consequence of an Interaction.

---

# 39. Interaction Feedback Loop

A complete interaction may form a feedback loop:

```text
Actor
  │
  ▼
Input
  │
  ▼
Observation
  │
  ▼
Gesture
  │
  ▼
Intent
  │
  ▼
Action
  │
  ▼
Transformation
  │
  ▼
Semantic Field
  │
  ▼
Observation / Feedback
  │
  └──────────────► Actor
```

This loop is fundamental to interactive computation.

---

# 40. Continuous Interaction

An Interaction may represent a continuously varying control relationship.

Examples:

```text
mouse movement → camera rotation
pointer position → parameter value
controller position → object position
pressure → intensity
gesture velocity → transformation magnitude
```

A continuous interaction must not be forced into a sequence of unrelated discrete Commands merely because an implementation processes updates discretely.

The semantic model may preserve continuous state.

---

# 41. Discrete Interaction

A discrete Interaction produces a distinct semantic occurrence.

Examples:

```text
Click
Delete
Confirm
Select
Open
Close
```

Discrete interaction may still originate from continuous observations.

For example:

```text
Pointer movement
    ↓
threshold
    ↓
Click
```

---

# 42. Ergonomic Semantics

SCR treats interaction ergonomics as a semantic consideration rather than merely an interface styling concern.

An Interaction may have associated properties such as:

```text
physical effort
movement distance
precision requirement
temporal precision
repetition
cognitive complexity
ambiguity
reversibility
attention demand
```

These properties may be used by an Interaction Mapping system to select or recommend alternative interaction mechanisms.

---

# 43. Interaction Cost

Interaction Cost represents the cost associated with performing an Interaction.

Interaction Cost may include:

```text
PhysicalCost
PrecisionCost
TemporalCost
CognitiveCost
RepetitionCost
AttentionCost
AmbiguityCost
```

The exact cost model is implementation- and context-dependent.

SCR does not prescribe a universal ergonomic scoring algorithm.

---

# 44. Accessibility

Accessibility is a semantic property of Interaction design.

A semantic Action should, where practical, support multiple Interaction Expressions.

For example:

```text
RotateObject
    ├── mouse gesture
    ├── touch gesture
    ├── keyboard control
    ├── voice command
    ├── spatial controller
    └── agent command
```

A Provider or Application must not assume that a single physical modality is universally available.

---

# 45. Device Independence

The semantic Interaction model must remain independent of specific input hardware.

The following may all produce semantically equivalent interactions:

```text
Mouse
Touch
Stylus
Hand
Controller
Voice
Eye Gaze
Agent
```

Device-specific semantics must remain below the semantic abstraction boundary unless explicitly promoted.

---

# 46. Provider Boundary

Concrete interaction mechanisms are implemented by Providers.

Examples include:

```text
Mouse Provider
Touch Provider
Pen Provider
Keyboard Provider
VR Controller Provider
Hand Tracking Provider
Eye Tracking Provider
Voice Provider
Gesture Recognition Provider
```

Providers may supply:

* observations;
* recognition;
* device access;
* tracking;
* gesture recognition;
* multimodal fusion;
* feedback.

Providers must satisfy applicable Normative Provider Contracts.

---

# 47. Provider Independence

The Interaction semantic layer must not depend upon:

* Qt;
* GTK;
* SDL;
* GLFW;
* browser DOM events;
* Win32;
* Wayland;
* X11;
* OGRE;
* Vulkan;
* OpenXR;
* vendor-specific controller APIs;
* any other concrete framework.

Such systems may provide Providers or Adapters.

---

# 48. Rendering Independence

Interaction must remain independent of visual presentation.

A Gesture may interact with:

* a 2D interface;
* a 3D scene;
* a semantic graph;
* a simulation;
* a text interface;
* a spatial computational environment;
* an agent-accessible application.

The visual representation is a manifestation.

The semantic Interaction remains authoritative.

---

# 49. Relationship to Application

Application consumes Interaction capabilities.

Conceptually:

```text
Application
    │
    ├── Interface
    │
    ├── Controller
    │
    ├── Service
    │
    └── Operation
             ▲
             │
        Interaction
             │
      Gesture / Intent
```

Application-specific interaction mappings may be declared by the Application.

The semantic Interaction model remains defined by this domain.

---

# 50. Relationship to Interface

Interface represents a boundary through which a computational system participates with an external observer or actor.

Interaction provides semantic mechanisms operating through that boundary.

Therefore:

```text
Interface ≠ Interaction
```

and:

```text
Interface
    └── may use Interaction
```

A visual interface is only one possible manifestation of an Interface.

---

# 51. Relationship to Spatial Semantics

Gestures frequently have spatial characteristics.

The Interaction domain may therefore depend upon:

* position;
* direction;
* distance;
* trajectory;
* geometry;
* topology;
* spatial relationships.

However, spatial concepts remain owned by their respective semantic domains.

Interaction composes them for interaction purposes.

---

# 52. Relationship to Temporal and Dynamic Semantics

Gestures are inherently temporal.

The Interaction domain may therefore use:

* time;
* duration;
* ordering;
* velocity;
* acceleration;
* temporal intervals;
* concurrency.

Temporal and dynamic semantics remain governed by the applicable SCR domains.

Interaction defines how those properties participate in interaction meaning.

---

# 53. Semantic Graph Representation

Interactions are represented within the canonical SCR semantic hypergraph.

A conceptual interaction may therefore contain relationships such as:

```text
Actor
  ──participatesIn──> Interaction

Interaction
  ──occursIn──> Context

Interaction
  ──observes──> Observation

Interaction
  ──recognizes──> Gesture

Interaction
  ──expresses──> Intent

Intent
  ──targets──> Object

Intent
  ──requests──> Action

Action
  ──transforms──> SemanticField
```

Gesture composition may itself be represented as semantic relationships.

For example:

```text
GestureSequence
    ├──precedes──> GestureA
    ├──precedes──> GestureB
    └──precedes──> GestureC
```

and:

```text
GestureChord
    ├──contains──> GestureA
    ├──contains──> GestureB
    └──contains──> GestureC
```

The canonical SCR hypergraph remains authoritative.

No separate interaction graph may supersede it.

---

# 54. Gesture Composition and Hypergraph Semantics

Gesture Sequence and Gesture Chord are semantic compositions.

They must preserve:

* identity;
* ordering;
* concurrency;
* cardinality;
* references;
* lifecycle;
* deletion semantics;
* nullary relation semantics where applicable.

A Gesture Sequence must not be represented merely as an implementation-specific array when semantic ordering and identity are significant.

A Gesture Chord must preserve the distinction between:

```text
concurrent composition
```

and:

```text
temporal sequence
```

---

# 55. Nullary Relations

Where the Interaction domain uses relations, nullary relations follow the canonical SCR relation policy.

A relation with zero participants is not implicitly equivalent to:

* absent relation;
* deleted relation;
* false relation;
* empty collection.

Nullary relation semantics must be determined explicitly by the governing semantic contract.

---

# 56. Reference Semantics

References between interaction entities must distinguish:

```text
reference exists
```

from:

```text
referenced object exists
```

Deletion of a target must not silently redefine the meaning of a historical interaction.

Historical interaction records may retain references to objects that no longer exist, subject to the lifecycle and retention policy of the applicable system.

---

# 57. Deletion Semantics

Deletion of a Gesture, Interaction, or Interaction Session must not implicitly delete semantic state unless an explicit relationship or lifecycle contract requires it.

In particular:

```text
Interaction deletion
    ≠
Action deletion
    ≠
Transformation reversal
```

If an Interaction has already committed a Transformation, deleting the Interaction record does not automatically reverse the Transformation.

Reversal requires an explicit compensating operation or transformation.

---

# 58. Identity

Interaction entities require stable semantic identity where they persist beyond a single observation.

Identity may apply to:

* Interaction;
* Interaction Session;
* Gesture;
* Gesture Expression;
* Gesture Mapping;
* Intent;
* Actor;
* Target.

Identity must conform to the SCR identity model.

Semantic identity and implementation/device identity remain distinct.

---

# 59. Provenance

Persistent interaction information should retain provenance sufficient to establish:

* source;
* actor;
* modality;
* provider;
* recognition mechanism;
* time;
* context;
* applicable mapping;
* resulting semantic action.

Provider identity does not replace semantic identity.

---

# 60. Confidence

Where recognition is probabilistic or ambiguous, a Gesture or Intent may carry a confidence or certainty measure.

Confidence is metadata about recognition.

It is not itself semantic truth.

A low-confidence Gesture may require:

* additional observations;
* confirmation;
* alternative interpretation;
* cancellation;
* human feedback.

---

# 61. Determinism

Interaction recognition may be:

* deterministic;
* probabilistic;
* adaptive;
* learned;
* user-specific.

The applicable Provider Contract must declare the relevant behaviour.

A deterministic semantic interaction must not become nondeterministic solely because an implementation chooses an opaque recognition mechanism.

---

# 62. User Adaptation

Interaction mappings may adapt to:

* user preferences;
* device availability;
* accessibility requirements;
* learned behaviour;
* ergonomic constraints;
* environment;
* interaction history.

Adaptation must not silently alter semantic meaning.

Adaptation changes the mapping or realization of an interaction, not the definition of the target semantic operation.

---

# 63. Multimodal Interaction

Multiple modalities may contribute to one Interaction.

For example:

```text
Gaze
   +
Hand Gesture
   +
Voice
```

may resolve to a single Intent.

Multimodal composition must distinguish:

```text
concurrent evidence
```

from:

```text
independent interactions
```

The applicable Interaction Expression determines the interpretation.

---

# 64. Interaction Modes

An Application or computational environment may expose explicit Interaction Modes.

Examples:

```text
Navigation
Selection
Transformation
Creation
Inspection
Annotation
Connection
SimulationControl
```

A mode changes interpretation context.

It must not redefine the underlying semantic Gesture.

---

# 65. Interaction Mapping Resolution

When multiple Interaction Mappings apply, resolution may consider:

1. semantic context;
2. target;
3. active mode;
4. actor;
5. modality;
6. specificity;
7. permissions;
8. interaction confidence;
9. ergonomic constraints;
10. accessibility requirements;
11. provider capabilities.

Ambiguous mappings must not silently produce unsafe or destructive Actions where explicit confirmation is required.

---

# 66. Reversibility

Interactions should declare whether their resulting Actions are:

```text
reversible
irreversible
conditionally reversible
transactional
non-transactional
```

This is particularly important for:

```text
Delete
Destroy
Terminate
Commit
Deploy
Execute
```

Interaction ergonomics must consider the consequences of accidental activation.

---

# 67. Safety

An Interaction system must distinguish between:

```text
recognition
```

and:

```text
authorization
```

Recognizing that an Actor intended an Action does not establish that the Actor is authorized to perform it.

Authorization remains governed by the appropriate security and authority semantics.

---

# 68. Interaction and Security

An Interaction may carry authority context including:

* Actor identity;
* authorization context;
* capability;
* session;
* provenance;
* trust;
* authentication state.

Interaction does not itself grant authority.

---

# 69. Feedback Semantics

Feedback may occur during any phase of an Interaction.

For example:

```text
Gesture Candidate
    ↓
preview feedback

Gesture Recognized
    ↓
recognition feedback

Action Proposed
    ↓
confirmation feedback

Action Committed
    ↓
result feedback

Action Cancelled
    ↓
cancellation feedback
```

Feedback should communicate semantic state rather than merely reflect implementation events.

---

# 70. Ergonomic Adaptation

The Interaction system may select between equivalent Interaction Expressions according to interaction cost.

For example:

```text
RotateObject
    ├── mouse circular gesture
    ├── mouse drag
    ├── keyboard
    ├── touch rotation
    └── spatial hand rotation
```

The semantic Action remains:

```text
RotateObject
```

Only the interaction realization changes.

---

# 71. Immersive Interaction

Immersive interaction is not a separate semantic model.

It is Interaction operating over spatial, multimodal, continuous, and contextual inputs.

Examples include:

```text
hand tracking
gaze
body movement
spatial controllers
voice
environmental sensing
3D spatial manipulation
```

An immersive interface therefore remains subject to the same Interaction semantics as a conventional interface.

---

# 72. Interaction as Control

Interaction may provide control over:

* Applications;
* Services;
* Operations;
* Semantic Fields;
* Computational Spaces;
* Semantic Machines;
* Simulations;
* Agents;
* Providers;
* Physical systems.

Control remains distinct from presentation.

A system may be controlled without being visually represented.

---

# 73. Agent Interaction

An agent may participate in Interaction without physical Input.

For example:

```text
Agent
   ↓
Semantic Command
   ↓
Intent
   ↓
Action
```

An agent may also generate an Interaction Expression equivalent to a human gesture.

The semantic result must not depend on whether the source was human, machine, or agent unless the applicable policy explicitly requires that distinction.

---

# 74. Human-Machine Equivalence

Where two interaction modalities produce the same semantic Intent or Action, their semantic results should be equivalent unless their contracts explicitly declare otherwise.

For example:

```text
Mouse Gesture
Voice Command
VR Gesture
Agent Command
```

may all resolve to:

```text
Rotate(Object42, 30°)
```

The source modality remains part of provenance.

---

# 75. Provider Substitution

A Provider implementing interaction capability may be replaced by another Provider provided that:

* the applicable Provider Contract remains satisfied;
* semantic observations remain valid;
* required fidelity is preserved;
* required latency is preserved where normative;
* required confidence semantics are preserved;
* required provenance is preserved;
* required interaction behaviour remains conformant.

Implementation equivalence is not required.

Semantic contract conformance is required.

---

# 76. Interaction Invariants

The Interaction domain establishes the following invariants.

### INT-001 — Semantic Primacy

Semantic Interaction definitions are authoritative over concrete input frameworks.

### INT-002 — Device Independence

Semantic Interaction must not depend on a specific physical input device.

### INT-003 — Gesture Distinction

A Gesture is distinct from the raw observations from which it is derived.

### INT-004 — Recognition Distinction

Gesture recognition is distinct from gesture interpretation.

### INT-005 — Intent Distinction

Intent is distinct from Gesture.

### INT-006 — Action Distinction

Action is distinct from Intent.

### INT-007 — Context Dependence

A Gesture may have different semantic interpretations in different contexts.

### INT-008 — Sequence Semantics

Gesture Sequence preserves semantic temporal ordering.

### INT-009 — Chord Semantics

Gesture Chord preserves semantic concurrency.

### INT-010 — Sequence/Chord Non-Equivalence

Temporal composition and concurrent composition are not interchangeable.

### INT-011 — Composition

Interaction Expressions must support compositional semantics.

### INT-012 — Continuous Interaction

The semantic model must support continuous interaction.

### INT-013 — Discrete Interaction

The semantic model must support discrete interaction.

### INT-014 — Session Integrity

Interaction Sessions preserve coherent interaction state across observations.

### INT-015 — Cancellation

Cancelled interaction must not be treated as committed interaction.

### INT-016 — Commitment

Commit establishes acceptance of the semantic interaction result.

### INT-017 — Feedback

Interaction may produce feedback during and after execution.

### INT-018 — Accessibility

Equivalent semantic Actions should support multiple feasible interaction modalities where practical.

### INT-019 — Provider Independence

Concrete input and recognition implementations remain Providers.

### INT-020 — Semantic Graph Authority

The canonical SCR hypergraph remains authoritative for Interaction relationships.

### INT-021 — No Duplicate Interaction Graph

The Interaction domain must not establish a competing semantic graph outside the canonical SCR hypergraph.

### INT-022 — Reference Integrity

References between interaction entities must preserve explicit reference semantics.

### INT-023 — Deletion Integrity

Deletion of interaction records must not implicitly reverse committed semantic transformations.

### INT-024 — Nullary Relation Integrity

Nullary relations follow the canonical SCR relation policy.

### INT-025 — Authorization Separation

Recognition of an intended Action does not establish authorization to perform it.

### INT-026 — Provenance

Persistent interaction state must preserve applicable provenance.

### INT-027 — Confidence

Recognition confidence must not be conflated with semantic truth.

### INT-028 — Ergonomic Independence

Interaction ergonomics may alter realization or mapping without altering semantic meaning.

### INT-029 — Multimodal Composition

Multiple modalities may contribute to one semantic Interaction.

### INT-030 — Human-Machine Equivalence

Equivalent semantic interactions may originate from human, machine, or agent modalities.

---

# 77. Canonical Interaction Model

The canonical abstract model is:

```text
Actor
  │
  ▼
Input
  │
  ▼
Observation*
  │
  ▼
Gesture Recognition
  │
  ▼
Gesture / GestureExpression
  │
  ├── Sequence
  ├── Chord
  ├── Alternative
  ├── Optional
  └── Repetition
  │
  ▼
Interaction Context
  │
  ▼
Interaction Mapping
  │
  ▼
Intent
  │
  ▼
Action / Command
  │
  ▼
Operation
  │
  ▼
Transformation
  │
  ▼
Semantic Field
  │
  ▼
Feedback
  │
  ▼
Actor / Observer
```

This model is conceptual and does not mandate a particular execution pipeline.

---

# 78. Canonical Repository Relationship

The Interaction domain is part of the SCR semantic library.

Its concrete relationship to implementations is:

```text
lib/805_Interaction/
        │
        ▼
Semantic Interaction Contract
        │
        ▼
Implementation Binding
        │
        ▼
Adapter
        │
        ▼
Provider
        │
        ▼
Execution Runtime
```

Concrete interaction technologies belong under `providers/`.

For example:

```text
providers/
└── interaction/
    ├── pointer/
    │   ├── mouse/
    │   ├── touch/
    │   └── pen/
    ├── spatial/
    │   ├── hand_tracking/
    │   ├── gaze/
    │   └── controller/
    └── multimodal/
```

The exact provider taxonomy is governed by the Provider Architecture.

---

# 79. Relationship to Application

The Application domain may consume Interaction capabilities through:

```text
Application
    │
    ├── Interface
    ├── Controller
    ├── Service
    └── Operation
```

Interaction provides the semantic mechanism by which an Actor reaches those application capabilities.

For example:

```text
Mouse Gesture
      ↓
Interaction
      ↓
Intent
      ↓
Application Operation
      ↓
Semantic Transformation
```

The Application does not own the fundamental meaning of the Gesture.

---

# 80. Relationship to EGS

The Executable Graph Server may resolve and manifest Interaction capabilities in the same manner as other semantic capabilities.

EGS may resolve:

```text
Gesture Recognition
Pointer Input
Touch Input
Spatial Tracking
Voice Input
Haptic Feedback
```

to appropriate Providers.

EGS does not redefine the semantic meaning of those capabilities.

---

# 81. Relationship to Semantic Machine Model

Interaction may control or observe Semantic Machines.

Examples include:

```text
Human
  ↓
Gesture
  ↓
Control
  ↓
Semantic Machine
```

or:

```text
Semantic Machine
  ↓
Observation
  ↓
Interaction Feedback
  ↓
Human
```

Interaction therefore provides one mechanism through which Semantic Machine Spaces become accessible to Actors.

---

# 82. Relationship to Rendering

Rendering is a manifestation mechanism.

An OGRE, Vulkan, Web, desktop, or other rendering Provider may manifest:

* interaction targets;
* gesture feedback;
* selection;
* spatial state;
* interaction previews;
* committed transformations.

Rendering must not become the semantic authority for Interaction.

---

# 83. Implementation Freedom

Implementations may use:

* event loops;
* state machines;
* finite automata;
* parser-like gesture grammars;
* geometric recognition;
* neural networks;
* probabilistic models;
* temporal models;
* spatial models;
* GPU computation;
* distributed recognition.

The semantic model remains independent of implementation technique.

---

# 84. Semantic Library Boundary

The Interaction domain must not become a general-purpose programming language.

It defines:

* semantic interaction entities;
* relationships;
* contracts;
* constraints;
* composition;
* state semantics;
* recognition results;
* mapping semantics.

It does not define general-purpose programming syntax, arbitrary application logic, or implementation-specific gesture algorithms.

---

# 85. Initial Implementation Priority

The initial implementation should establish the smallest stable semantic core:

```text
Interaction
Observation
Pointer
Gesture
GestureExpression
GestureSequence
GestureChord
InteractionContext
Intent
InteractionMapping
InteractionSession
Feedback
```

Implementation should proceed through:

```text
describe
    ↓
specify
    ↓
test
    ↓
validate
    ↓
implement
```

Recognition algorithms and concrete device Providers should follow the stabilization of the semantic model.

---

# 86. Future Extensions

Potential future Interaction capabilities include:

* learned personal interaction models;
* adaptive gesture recognition;
* multimodal fusion;
* gaze interaction;
* hand tracking;
* body tracking;
* haptic interaction;
* spatial audio interaction;
* neural interfaces;
* brain-computer interaction;
* affective interaction;
* collaborative interaction;
* multi-actor interaction;
* remote interaction;
* interaction replay;
* interaction provenance;
* interaction simulation;
* interaction optimization.

These must be introduced only when their concepts can be expressed without violating the core Interaction invariants.

---

# 87. Final Principle

The Interaction domain exists to make participation in computation a first-class semantic capability.

A mouse movement is not merely an event.

A gesture is not merely a callback.

A gesture sequence is not merely a list of events.

A chord is not merely a collection of buttons.

An interface is not merely a collection of widgets.

Instead:

```text
Observation
    ↓
Gesture
    ↓
Composition
    ↓
Intent
    ↓
Action
    ↓
Transformation
    ↓
Semantic Field
    ↓
Feedback
```

is a semantic relationship between an Actor and a computational world.

SCR therefore treats **interaction as a compositional, contextual, multimodal, spatial, temporal, and semantic mechanism for controlling and observing computation**.

The implementation may be a mouse, keyboard, touchscreen, stylus, VR controller, hand, gaze, voice, robot, agent, or any future modality.

The modality is replaceable.

The semantic interaction is not.
