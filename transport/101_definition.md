# Semantic Computational Runtime

# Transport — Definition

**Document:** `lib/representation/transport/101_definition.md`
**Semantic ID:** `representation.transport`
**Version:** `0.1.0`
**Status:** Normative Semantic Definition
**Parent Domain:** `representation`
**Related Domains:** `representation.interchange`, `representation.persistence`

---

# 1. Purpose

The `representation.transport` subdomain defines the semantics of moving representations, messages, references, or semantic information between computational contexts.

Transport answers:

> **How does information move from one computational context to another while preserving the guarantees declared by the transport contract?**

Transport concerns **movement across a boundary**.

It does not define:

* what the information means;
* how the information is represented;
* whether the information is persistent;
* where the information executes;
* who owns the semantic object;
* what semantic authority the sender possesses;
* which physical networking mechanism is used.

The governing principle is:

> **Transport moves information between contexts; it does not own the meaning of the information being moved.**

---

# 2. Scope

This definition establishes the semantic foundations for:

* transport;
* transport endpoints;
* transport channels;
* messages;
* envelopes;
* delivery;
* ordering;
* reliability;
* acknowledgement;
* flow control;
* backpressure;
* routing;
* addressing;
* fragmentation;
* reassembly;
* duplication;
* replay;
* retransmission;
* delivery guarantees;
* transport provenance;
* transport security;
* transport lifecycle;
* transport failure.

Concrete mechanisms such as:

* AMQP;
* Hyrx;
* HyrxMQ;
* WebSocket;
* TCP;
* QUIC;
* Unix domain sockets;
* shared memory;
* RDMA;

are providers or implementation mechanisms.

They do not define SCR transport semantics.

---

# 3. Architectural Position

Transport sits between information and computational contexts.

```text
Semantic Meaning
       │
       ▼
Representation / Message
       │
       ▼
Transport Semantics
       │
       ▼
Transport Provider
       │
       ▼
Physical / Logical Network
       │
       ▼
Transport Provider
       │
       ▼
Transport Semantics
       │
       ▼
Representation / Message
       │
       ▼
Semantic Interpretation
```

The fundamental distinction is:

```text
Semantic Meaning
    ≠
Representation
    ≠
Transport
    ≠
Network Mechanism
```

---

# 4. Transport Is Not Interchange

Interchange defines how information is represented for exchange.

Transport defines how information moves between contexts.

Therefore:

```text
Interchange ≠ Transport
```

A glTF document MAY be transported using AMQP.

An AMQP message MAY contain JSON.

A Hyrx message MAY contain an SCR hypergraph reference.

None of these relationships makes the transport mechanism the semantic definition of the payload.

---

# 5. Transport Is Not Persistence

Transport concerns movement.

Persistence concerns survival across a lifetime boundary.

Therefore:

```text
Transport ≠ Persistence
```

A transport provider MAY offer durable messaging.

That durability is a transport capability.

It MUST NOT automatically become semantic persistence.

For example:

```text
AMQP durable queue
    ≠
SCR persistent semantic state
```

unless an explicit persistence operation establishes that relationship.

---

# 6. Transport Is Not Representation

A transport system may carry many representation types.

For example:

```text
Transport
 ├── bytes
 ├── JSON
 ├── CBOR
 ├── glTF
 ├── semantic graph
 └── opaque payload
```

Therefore:

```text
Transport ≠ Representation
```

The transport layer MUST remain semantically agnostic to the payload except where the transport contract explicitly requires limited metadata interpretation.

---

# 7. Transport Is Not Execution

Moving information to an execution context does not itself constitute execution.

Therefore:

```text
Transport ≠ Execution
```

A message MAY contain:

* executable code;
* an executable hypergraph;
* an execution request;
* a state transition;
* data.

The transport operation itself merely moves the information.

Execution requires an explicit execution transition.

---

# 8. Transport Context

A transport context identifies the source and destination computational contexts involved in movement.

Conceptually:

```text
TransportContext =
    <Source,
     Destination,
     Channel,
     Policy,
     SecurityContext>
```

A transport context MAY contain:

* process;
* node;
* namespace;
* Semantic Machine;
* partition;
* application;
* endpoint;
* network domain.

Transport context MUST NOT be confused with semantic ownership or authority.

---

# 9. Transport Endpoint

A transport endpoint identifies a participant in transport.

Conceptually:

```text
Endpoint =
    <Identity,
     Address,
     Capabilities,
     Context>
```

An endpoint MAY be identified by:

* network address;
* socket;
* URI;
* queue;
* exchange;
* topic;
* channel;
* logical endpoint identifier.

An endpoint address is not automatically a semantic identity.

Therefore:

```text
TransportAddress ≠ SemanticIdentity
```

---

# 10. Transport Address

A transport address identifies a location or routing destination within a transport system.

Examples include:

```text
IP address
port
URI
AMQP exchange
AMQP queue
topic
Unix socket
WebSocket endpoint
Hyrx endpoint
```

Transport addresses MAY change while the semantic identity of the communicating entity remains unchanged.

Therefore:

```text
TransportAddress ≠ SemanticIdentity
```

---

# 11. Transport Identity

A transport implementation MAY assign an identity to an endpoint or channel.

Such identity is transport-scoped.

It MUST NOT automatically become an SCR semantic identifier.

Where an endpoint is associated with an SCR SID, the relationship MUST be explicitly established through the identity model.

---

# 12. Message

A message is a transportable unit of information.

Conceptually:

```text
Message =
    <Payload,
     Envelope,
     MessageIdentity,
     DeliveryContext>
```

A message MAY contain:

* semantic content;
* representation content;
* references;
* commands;
* events;
* control information;
* metadata.

The message container does not determine the meaning of its payload.

---

# 13. Message Identity

A transport implementation MAY assign a message identity.

Conceptually:

```text
MID : Message → MessageIdentity
```

Message identity is distinct from:

```text
SemanticIdentity
RepresentationIdentity
ContentIdentity
PersistenceIdentity
```

A message MAY transport information about a semantic object without being the semantic object itself.

---

# 14. Message Content Identity

A message MAY identify its content using a content digest.

For example:

```text
CID = Hash(Payload)
```

Content identity MAY support:

* deduplication;
* integrity;
* caching;
* replay detection.

Content identity MUST NOT be treated as semantic identity.

---

# 15. Envelope

A transport envelope contains metadata required to move or interpret a message at the transport boundary.

Conceptually:

```text
Envelope =
    <Source,
     Destination,
     MessageIdentity,
     Correlation,
     Ordering,
     DeliveryPolicy,
     SecurityMetadata>
```

The envelope MUST remain distinguishable from the semantic payload.

---

# 16. Payload

The payload is the information transported by a message.

The payload MAY be:

```text
Bytes
Structured Data
Representation
Semantic Reference
Semantic State
Command
Event
Executable Hypergraph
```

Transport semantics MUST NOT assume a particular payload representation unless required by an explicitly declared transport profile.

---

# 17. Message and Semantic State

A message MAY carry semantic state.

However:

```text
Message ≠ SemanticState
```

The semantic state exists independently of its transport manifestation.

A message may therefore be:

```text
Created
Sent
Delivered
Consumed
Expired
Rejected
Replayed
Deleted
```

without changing the lifecycle of the semantic object it describes.

---

# 18. Send

`send` establishes a transport operation from a source endpoint into a transport system.

Conceptually:

```text
Source
  │
  ▼
send(Message)
  │
  ▼
Transport System
```

Successful send does not imply delivery.

Therefore:

```text
SendSuccess ≠ DeliverySuccess
```

---

# 19. Delivery

Delivery occurs when a message reaches the destination defined by the transport contract.

The exact meaning of delivery MUST be specified.

Possible levels include:

```text
Accepted
Enqueued
Transmitted
Received
Delivered
Consumed
Processed
```

These MUST NOT be conflated.

For example:

```text
Received ≠ Processed
```

---

# 20. Consumption

Consumption occurs when a receiving participant accepts a message for processing according to the applicable transport contract.

Consumption does not imply semantic execution.

For example:

```text
Message
  ↓
Consumed
  ↓
Semantic Transition
```

The final transition remains governed by SCR execution and STC semantics.

---

# 21. Acknowledgement

An acknowledgement communicates a transport state regarding a message.

Possible acknowledgement states include:

```text
Accepted
Received
Persisted
Consumed
Rejected
Failed
```

The acknowledgement MUST identify what property it actually confirms.

An acknowledgement of receipt MUST NOT be interpreted as acknowledgement of semantic processing.

---

# 22. Delivery Guarantee

A transport profile MUST declare its delivery guarantee.

Possible classes include:

```text
BestEffort
AtMostOnce
AtLeastOnce
ExactlyOnce
EffectivelyOnce
ApplicationDefined
```

These terms MUST be given precise operational definitions within the profile.

In particular:

> **Exactly-once transport delivery does not imply exactly-once semantic effect.**

A duplicate message may be delivered without producing a duplicate semantic effect if the receiving semantic transition is idempotent or deduplicated.

---

# 23. Duplicate Delivery

A transport implementation MAY deliver the same message more than once.

Duplicate detection MAY use:

* message identity;
* content identity;
* sequence number;
* application key;
* correlation identity.

Deduplication semantics MUST be explicit.

A duplicate message MUST NOT automatically imply a duplicate semantic transition.

---

# 24. Idempotence

A transport operation MAY be idempotent.

Semantic idempotence belongs to the receiving semantic operation.

Therefore:

```text
TransportIdempotence
    ≠
SemanticIdempotence
```

A transport system MUST NOT claim semantic idempotence merely because it suppresses duplicate messages.

---

# 25. Ordering

Transport MAY provide ordering guarantees.

Ordering MAY be defined over:

```text
connection
channel
queue
partition
topic
sender
message group
causal sequence
```

An ordering guarantee MUST identify its scope.

For example:

```text
Ordered(A,B)
```

does not imply:

```text
Ordered(A,C)
```

unless the contract establishes that relationship.

---

# 26. Causal Ordering

A transport MAY preserve causal ordering.

Causal ordering MUST be explicitly established.

Transport sequence numbers alone do not automatically establish semantic causality.

SCR semantic causality remains governed by the transition and graph models.

---

# 27. Transport Ordering and STC

Transport ordering MAY provide evidence about the order in which messages were delivered.

It MUST NOT redefine semantic causal ordering.

Therefore:

```text
TransportOrder
    ≠
SemanticCausality
```

unless an explicit semantic relationship establishes the correspondence.

---

# 28. Routing

Routing determines how a message moves through a transport topology.

Conceptually:

```text
Source
  │
  ▼
Router
  │
  ├── Route A
  ├── Route B
  └── Route C
```

Routing decisions MAY depend on:

* address;
* topic;
* routing key;
* partition;
* priority;
* capability;
* policy.

Routing MUST NOT silently alter semantic meaning.

---

# 29. Transport Topology

A transport topology describes relationships between transport participants.

Examples include:

```text
PointToPoint
PublishSubscribe
FanOut
Brokered
Mesh
RequestResponse
Streaming
Pipeline
```

Transport topology is distinct from semantic topology.

Therefore:

```text
TransportTopology ≠ SemanticHypergraph
```

---

# 30. Transport Partition

A transport system MAY partition traffic.

Examples include:

```text
queue partition
topic partition
shard
channel
connection
routing domain
```

A transport partition is not automatically an SCR semantic partition.

Therefore:

```text
TransportPartition ≠ SemanticPartition
```

unless explicitly mapped.

---

# 31. Flow Control

Flow control regulates the rate at which information enters a transport path.

It MAY use:

* credits;
* windows;
* queue depth;
* rate limits;
* backpressure;
* admission control.

Flow control affects transport behavior.

It does not alter semantic meaning.

---

# 32. Backpressure

Backpressure communicates inability or unwillingness of a downstream transport participant to accept additional traffic at the current rate.

Conceptually:

```text
Producer
   │
   ▼
Transport
   │
   ▼
Consumer
   │
   └── backpressure
          │
          ▼
      Producer slows
```

Backpressure MUST NOT be interpreted as semantic rejection unless explicitly mapped.

---

# 33. Priority

Transport MAY assign delivery priority.

Priority is transport-local unless explicitly mapped into semantic priority.

Therefore:

```text
TransportPriority ≠ SemanticPriority
```

unless an explicit semantic contract establishes equivalence.

---

# 34. Fragmentation

A transport implementation MAY divide a message into fragments.

Conceptually:

```text
Message
  │
  ├── Fragment 1
  ├── Fragment 2
  └── Fragment 3
```

Fragments are transport manifestations of one message.

A fragment MUST NOT automatically become a semantic object.

---

# 35. Reassembly

Reassembly reconstructs a message from transport fragments.

```text
Fragments
    │
    ▼
Reassembly
    │
    ▼
Message
```

Reassembly MUST verify:

* fragment identity;
* sequence;
* completeness;
* integrity;
* size;
* applicable limits.

Incomplete reassembly MUST NOT be treated as a complete message.

---

# 36. Retransmission

Retransmission sends a message or fragment again after failure or according to a reliability policy.

Retransmission MUST NOT automatically create a new semantic message identity.

The transport system SHOULD preserve the identity of the original message where the retransmission represents the same logical message.

---

# 37. Replay

Replay intentionally or unintentionally delivers previously transmitted information again.

Replay MAY be used for:

* recovery;
* testing;
* event reconstruction;
* replication;
* debugging.

Replay MUST preserve sufficient provenance to distinguish:

```text
OriginalDelivery
Replay
Retransmission
Duplicate
```

where that distinction matters.

---

# 38. Expiration

A transport message MAY have an expiration condition.

Expiration removes the message from eligibility for delivery according to the transport contract.

Expiration MUST NOT imply semantic deletion.

Therefore:

```text
MessageExpiration ≠ SemanticDeletion
```

---

# 39. Dead-Letter Handling

A message that cannot be delivered or consumed MAY be routed to a dead-letter destination.

Dead-letter handling MUST preserve relevant provenance.

A dead-lettered message remains transport information unless explicitly interpreted by another semantic operation.

---

# 40. Correlation

Transport messages MAY carry correlation information linking related messages.

Examples include:

```text
Request → Response
Command → Result
Event → Consequence
Parent → Child
Job → Completion
```

Correlation does not itself establish semantic causality.

Where semantic causality is intended, the mapping MUST explicitly establish it.

---

# 41. Request and Response

Request/response is a transport interaction pattern.

Conceptually:

```text
Request
   │
   ▼
Receiver
   │
   ▼
Response
```

A response MAY carry:

* data;
* result;
* acknowledgement;
* error;
* reference.

The transport pattern MUST NOT define the semantics of the requested operation.

---

# 42. Streaming

A transport stream is an ordered or partially ordered sequence of transport information.

Conceptually:

```text
M1 → M2 → M3 → M4 → ...
```

A stream MAY represent:

* telemetry;
* semantic transitions;
* sensor data;
* execution output;
* replication changes;
* media.

The semantic interpretation belongs to the consuming domain.

---

# 43. Transport Lifecycle

A transport message MAY progress through states such as:

```text
Created
  ↓
Submitted
  ↓
Accepted
  ↓
Routed
  ↓
Transmitted
  ↓
Received
  ↓
Consumed
  ↓
Acknowledged
```

Failures MAY occur at any stage.

Implementations MUST NOT report a later state when only an earlier state has been established.

---

# 44. Transport Failure

Transport failures SHOULD distinguish:

```text
AddressResolutionFailure
ConnectionFailure
RoutingFailure
CapacityFailure
FlowControlFailure
TransmissionFailure
IntegrityFailure
AuthenticationFailure
AuthorizationFailure
Timeout
Expiration
ReassemblyFailure
DeliveryFailure
ConsumerFailure
```

A transport failure MUST NOT automatically be treated as a semantic failure.

---

# 45. Transport Availability

Transport availability is the ability to establish or maintain the declared transport service.

Availability is distinct from semantic availability.

For example:

```text
TransportAvailable
    ≠
SemanticObjectAvailable
```

A semantic object may remain available through another representation or transport path.

---

# 46. Transport Security

Transport MAY provide:

* confidentiality;
* integrity;
* authentication;
* authorization;
* replay protection;
* endpoint verification;
* channel security.

Security properties apply to the transport boundary.

They MUST NOT automatically establish semantic authority.

For example:

```text
AuthenticatedSender
    ≠
SemanticAuthority
```

unless the authority model explicitly binds the authenticated identity to the relevant authority.

---

# 47. Transport Trust Boundary

Messages crossing a transport boundary MUST be treated according to the receiving context's trust policy.

The receiver MUST NOT assume:

```text
ValidTransport
→
ValidRepresentation
→
ValidSemanticState
```

Each layer requires its own validation.

The canonical pipeline remains:

```text
Transport Validation
      ↓
Representation Validation
      ↓
Semantic Mapping
      ↓
Semantic Validation
```

---

# 48. Transport and Provenance

Transport SHOULD preserve provenance necessary to establish:

* source endpoint;
* destination;
* transport channel;
* transmission time;
* message identity;
* correlation;
* retransmission;
* replay;
* routing history;

where required by the transport profile.

Transport provenance is distinct from semantic provenance.

Therefore:

```text
TransportProvenance ≠ SemanticProvenance
```

although the two MAY be related.

---

# 49. Transport and Authority

Transport MAY enforce transport-level authorization.

For example:

```text
CanSend
CanReceive
CanSubscribe
CanPublish
CanConsume
CanRoute
```

These permissions MUST NOT automatically become semantic authority.

The distinction remains:

```text
TransportAuthority
    ≠
SemanticAuthority
```

---

# 50. Transport and Ownership

A transport provider may own:

* a connection;
* a queue;
* a broker;
* a channel;
* a routing domain.

That ownership MUST NOT imply ownership of the semantic objects transported through it.

Therefore:

```text
TransportOwnership ≠ SemanticOwnership
```

---

# 51. Transport and Spatial Semantics

Transport endpoints MAY have spatial locations.

For example:

```text
Node A
  │
  └── endpoint
          │
          ▼
      network
          │
          ▼
Node B
```

Network topology MUST NOT automatically become SCR spatial topology.

Therefore:

```text
NetworkLocation ≠ SemanticCoordinate
NetworkTopology ≠ SemanticTopology
```

---

# 52. Transport and Spatial Partitioning

A transport partition MAY correspond to an SCR computational partition.

If so, the relationship MUST be explicitly declared.

For example:

```text
SCR Partition P7
      │
      ├── Transport Queue Q7
      └── Execution Context E7
```

The queue is a transport mechanism.

The partition remains a semantic concept.

Therefore:

```text
TransportPartition ≠ SCRPartition
```

unless explicitly mapped.

---

# 53. Transport and Representation

Transport may carry any representation for which the transport profile permits transmission.

Examples:

```text
SCR Semantic Message
      │
      ▼
AMQP
      │
      ▼
JSON

SCR Geometry Representation
      │
      ▼
Hyrx
      │
      ▼
Binary Payload

glTF
      │
      ▼
WebSocket
```

The transport provider does not define the representation semantics.

---

# 54. AMQP Integration

AMQP MAY serve as a canonical transport mechanism for SCR messaging.

Where AMQP is used:

```text
Exchange
Queue
Binding
Routing Key
Consumer
Message
```

are transport mechanisms.

They MUST NOT become semantic concepts merely because SCR uses AMQP operationally.

Hyrx and HyrxMQ MAY provide high-performance implementations of the transport capability while preserving the same semantic separation.

---

# 55. Transport and Hyrx

Hyrx MAY provide an optimized implementation of transport semantics.

Hyrx-specific mechanisms MAY include:

* AMQP-compatible messaging;
* WebSocket;
* Unix domain sockets;
* virtual domain sockets;
* high-performance routing;
* zero-copy or low-copy transfer.

These are implementation/provider mechanisms.

They MUST NOT redefine SCR transport semantics.

---

# 56. GPU and Transport

Transport MAY move data between:

```text
CPU
GPU
GPU
GPU
Node
Node
Partition
Partition
```

GPU-resident transport MAY optimize movement by transmitting:

* references;
* descriptors;
* metadata;
* memory handles;
* compressed payloads.

A reference-based transfer MUST explicitly establish what semantic information the reference denotes.

A GPU memory address MUST NOT become semantic identity.

---

# 57. Zero-Copy Transport

Zero-copy transport MAY avoid copying payload bytes.

Zero-copy is an implementation optimization.

It MUST preserve the semantic guarantees of ordinary transport.

Therefore:

```text
ZeroCopy ≠ Different Semantics
```

unless the transport profile explicitly defines a different ownership or lifetime contract.

---

# 58. Ownership Transfer

A transport operation MAY transfer ownership of a representation or resource.

If ownership transfer is semantically meaningful, it MUST be explicit.

For example:

```text
Sender
  │
  └── transfer ownership
          │
          ▼
Receiver
```

Ownership transfer MUST NOT be inferred merely from physical movement of bytes.

---

# 59. Reference Transport

A transport system MAY transport a reference rather than the referenced data.

For example:

```text
Message
  │
  └── reference → DataObject
```

The receiver MUST have sufficient authority and capability to resolve the reference.

Transport of a reference does not constitute transport of the referenced semantic state.

---

# 60. Transported Execution Requests

Transport MAY carry a request to execute a semantic transition.

For example:

```text
Transport
   │
   ▼
Execution Request
   │
   ▼
STC
   │
   ▼
Semantic Transition
```

Transport establishes movement.

The receiving execution environment determines whether the requested transition is applicable and consented to.

Therefore:

```text
TransportedCommand
    ≠
AuthorizedExecution
```

---

# 61. STC Integration

Transport operations are compatible with the Semantic Transition Calculus.

Examples include:

```text
τsend
τroute
τreceive
τacknowledge
τreject
τreplay
τexpire
τretransmit
```

These operations MUST use the existing transition model.

Transport MUST NOT introduce a second foundational transition calculus.

Applicability and consent remain governed by:

```text
Applicable(τ,S,C)
Consents(τ,S,C,K)
```

Transport state, endpoint capability, security context, routing policy, and delivery constraints MAY participate in context and constraint environments.

---

# 62. Transport Consequences

Transport transitions MAY produce consequences such as:

```text
MessageAccepted
MessageRouted
MessageTransmitted
MessageReceived
MessageConsumed
MessageAcknowledged
MessageRejected
MessageExpired
MessageReplayed
MessageRetransmitted
```

These are consequence descriptions.

They do not replace the GMKernel edge model.

---

# 63. Formal Model

The transport domain MAY be modeled as:

```text
Transport =
    <E,M,C,A,D,O,R,F,S>
```

where:

```text
E = endpoints
M = messages
C = channels
A = addressing/routing
D = delivery relations
O = ordering relations
R = reliability guarantees
F = flow-control relations
S = security constraints
```

Transport relation:

```text
Transports(E1,M,E2,C) : Prop
```

means that message `M` is transported from endpoint `E1` to endpoint `E2` through channel `C` under the applicable contract.

Delivery:

```text
Delivered(M,E2,C) : Prop
```

Acceptance:

```text
Accepted(M,C) : Prop
```

Consumption:

```text
Consumed(M,E2) : Prop
```

These relations MUST remain distinct.

---

# 64. Delivery Preservation

A transport profile MAY claim preservation of properties such as:

```text
MessageIdentity
ContentIntegrity
Ordering
Correlation
Provenance
PayloadIntegrity
```

Each claim MUST specify its scope.

Transport preservation does not automatically imply semantic preservation.

---

# 65. Transport Formalisation

Lean formalisation SHOULD be considered for:

* delivery guarantees;
* ordering;
* duplication;
* acknowledgement;
* routing;
* message identity;
* replay;
* retransmission;
* flow control;
* transport lifecycle;
* security properties.

Formalisation MUST remain subordinate to this definition and MUST NOT silently redefine transport semantics.

---

# 66. Conformance

A transport implementation conforms to this definition when:

1. transport is distinguished from representation;
2. transport is distinguished from interchange;
3. transport is distinguished from persistence;
4. transport is distinguished from execution;
5. endpoint identity is distinguished from semantic identity;
6. message identity is distinguished from semantic identity;
7. delivery states are explicitly defined;
8. delivery guarantees are explicit;
9. ordering guarantees are explicit;
10. duplicate and replay behavior is explicit;
11. routing semantics are explicit;
12. failure behavior is explicit;
13. security boundaries are explicit;
14. transport authority is distinguished from semantic authority;
15. transport ownership is distinguished from semantic ownership;
16. provider mechanisms do not redefine transport semantics.

---

# 67. Normative Invariants

## TRA-001 — Semantic Independence

Transport MUST NOT define the meaning of transported information.

## TRA-002 — Representation Separation

Transport MUST remain distinct from representation.

## TRA-003 — Interchange Separation

Transport MUST remain distinct from interchange.

## TRA-004 — Persistence Separation

Transport MUST remain distinct from persistence.

## TRA-005 — Execution Separation

Transport MUST remain distinct from execution.

## TRA-006 — Endpoint Identity Separation

Transport endpoint identity MUST remain distinct from semantic identity.

## TRA-007 — Message Identity Separation

Message identity MUST remain distinct from semantic identity.

## TRA-008 — Address Separation

Transport addresses MUST remain distinct from semantic identity.

## TRA-009 — Send/Delivery Separation

Successful send MUST NOT imply successful delivery.

## TRA-010 — Delivery/Consumption Separation

Delivery MUST NOT imply consumption.

## TRA-011 — Consumption/Execution Separation

Consumption MUST NOT imply semantic execution.

## TRA-012 — Acknowledgement Explicitness

Acknowledgements MUST identify precisely what they acknowledge.

## TRA-013 — Delivery Guarantee Honesty

Delivery guarantees MUST accurately reflect actual behavior.

## TRA-014 — Duplicate Explicitness

Duplicate delivery behavior MUST be explicit.

## TRA-015 — Replay Explicitness

Replay behavior MUST be distinguishable where semantically relevant.

## TRA-016 — Ordering Scope

Ordering guarantees MUST identify their scope.

## TRA-017 — Causality Separation

Transport ordering MUST NOT automatically define semantic causality.

## TRA-018 — Routing Independence

Routing MUST NOT silently alter semantic meaning.

## TRA-019 — Partition Separation

Transport partitions MUST remain distinct from semantic partitions unless explicitly mapped.

## TRA-020 — Flow-Control Separation

Flow-control behavior MUST NOT automatically imply semantic rejection.

## TRA-021 — Expiration Separation

Transport expiration MUST NOT imply semantic deletion.

## TRA-022 — Reference Separation

Transported references MUST remain distinct from transported semantic state.

## TRA-023 — Security Separation

Transport security MUST NOT automatically establish semantic authority.

## TRA-024 — Authority Separation

Transport authority MUST remain distinct from semantic authority.

## TRA-025 — Ownership Separation

Transport ownership MUST remain distinct from semantic ownership.

## TRA-026 — Provenance Separation

Transport provenance MUST remain distinct from semantic provenance.

## TRA-027 — Fragmentation Integrity

Fragmentation and reassembly MUST preserve the declared message semantics.

## TRA-028 — Provider Independence

Transport semantics MUST remain independent of provider implementation.

## TRA-029 — STC Compatibility

Transport operations MUST remain compatible with the Semantic Transition Calculus.

## TRA-030 — Validation Boundary

Transport validity MUST NOT be treated as representation validity or semantic validity.

---

# 68. Library Integration

The transport subdomain belongs beneath:

```text
lib/representation/
```

with the canonical structure:

```text
lib/representation/transport/
├── README.md
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

Concrete transport technologies MAY become provider mappings or dedicated subdomains depending on semantic scope.

Possible future subdomains include:

```text
transport.amqp
transport.hyrx
transport.websocket
transport.quic
transport.rdma
transport.shared_memory
```

A technology-specific subdomain MUST NOT redefine the parent transport semantics.

---

# 69. Relationship to Interchange

The relationship is:

```text
Semantic State
      │
      ▼
Representation
      │
      ├──────────────┐
      ▼              ▼
 Interchange      Transport
      │              │
      │              └── moves representation/message
      ▼
External Format
```

A common pipeline is:

```text
Semantic State
      ↓
Representation
      ↓
Interchange Encoding
      ↓
Transport Message
      ↓
Transport
      ↓
Transport Message
      ↓
Interchange Decoding
      ↓
Representation
      ↓
Semantic State
```

Each layer retains its own semantic responsibility.

---

# 70. Relationship to Persistence

Persistence and transport may compose:

```text
Producer
   │
   ▼
Transport
   │
   ▼
Persistent Message
   │
   ▼
Consumer
```

The transport system moves the message.

The persistence system preserves the message.

These operations MUST remain distinguishable.

A persistent queue is therefore:

```text
Transport Capability
+
Persistence Capability
```

not a new foundational semantic category.

---

# 71. Relationship to Distributed Execution

Transport provides communication between computational contexts.

Distributed execution MAY depend upon transport.

However:

```text
Transport
    ≠
Distributed Execution
```

Transport provides movement.

The execution model determines:

* transition;
* state;
* authority;
* scheduling;
* execution;
* synchronization;
* consistency.

---

# 72. Minimum Viable Transport

The minimum SCR transport implementation SHOULD demonstrate:

```text
Endpoint A
    │
    ▼
Create Message
    │
    ▼
Send
    │
    ▼
Route
    │
    ▼
Receive
    │
    ▼
Validate
    │
    ▼
Consume
```

The implementation MUST demonstrate:

* endpoint identity;
* message identity;
* payload integrity;
* explicit delivery state;
* explicit failure;
* duplicate handling;
* ordering behavior;
* acknowledgement semantics.

---

# 73. Development Sequence

A concrete transport implementation SHOULD follow:

```text
1. Define transport boundary
2. Define endpoints
3. Define addresses
4. Define message model
5. Define envelope
6. Define identity semantics
7. Define delivery states
8. Define reliability guarantees
9. Define ordering
10. Define routing
11. Define acknowledgement
12. Define duplication
13. Define replay
14. Define expiration
15. Define flow control
16. Define security
17. Define provenance
18. Define failure semantics
19. Define STC integration
20. Define conformance tests
21. Formalise critical properties where justified
22. Implement provider adapter
23. Validate
24. Verify
25. Update status
26. Update library graph
```

---

# 74. Final Definition

Transport is the semantic capability by which information is moved between computational contexts under an explicitly defined delivery, ordering, reliability, security, and lifecycle contract.

The essential relationship is:

```text
Source Context
      │
      ▼
    Message
      │
      ▼
Transport Contract
      │
      ▼
 Transport System
      │
      ▼
Destination Context
      │
      ▼
Message
      │
      ▼
Semantic Interpretation
```

The governing distinction is:

```text
Meaning
   ≠
Representation
   ≠
Interchange
   ≠
Persistence
   ≠
Transport
   ≠
Execution
   ≠
Provider
```

And the governing principle is:

> **Transport moves information. Representation encodes information. Interchange enables representation exchange. Persistence preserves information across lifetime boundaries. Execution realizes meaning. Semantic domains define meaning. Providers supply the mechanisms.**
