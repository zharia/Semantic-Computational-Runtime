# HyrxMQ — Complete Development Agent Implementation Instruction

## 0. Mission

You are the primary development agent responsible for implementing **Hyrx** and **HyrxMQ** according to the supplied project documentation.

You MUST treat the repository documentation as the authoritative engineering specification.

Your objective is **not** to create a RabbitMQ clone by translating RabbitMQ's architecture.

Your objective is to implement:

> **Hyrx: a self-contained, native Mojo messaging engine designed around extremely low-cost message routing and delivery, with transport-independent semantics and multiple deployment paths.**

and:

> **HyrxMQ: the independently deployable GNU/Linux/systemd broker product built on Hyrx, exposing AMQP 0-9-1 interoperability and the operational capabilities expected of a serious standalone message broker.**

The simulation is an important motivating workload, but **it is NOT part of Hyrx's architecture and MUST NOT become a dependency of Hyrx or HyrxMQ.**

---

# 1. READ THE DOCUMENTATION FIRST

Before modifying implementation code:

1. Read `README.md`.
2. Read `docs/INDEX.md`.
3. Read, in particular:

   * `docs/PROJECT.md`
   * `docs/VISION.md`
   * `docs/ARCHITECTURE.md`
   * `docs/CORE_ENGINE.md`
   * `docs/REQUIREMENTS.md`
   * `docs/TRANSPORTS.md`
   * `docs/MEMORY_MODEL.md`
   * `docs/CONCURRENCY.md`
   * `docs/ROUTING.md`
   * `docs/PROTOCOL.md`
   * `docs/RABBITMQ_COMPATIBILITY.md`
   * `docs/PERSISTENCE.md`
   * `docs/SECURITY.md`
   * `docs/OBSERVABILITY.md`
   * `docs/MANAGEMENT.md`
   * `docs/MANAGEMENT_API.md`
   * `docs/FAILURE_SEMANTICS.md`
   * `docs/SYSTEMD.md`
   * `docs/CONFIGURATION.md`
   * `docs/TESTING.md`
   * `docs/FUZZING.md`
   * `docs/BENCHMARKING.md`
   * `docs/PERFORMANCE.md`
   * `docs/IMPLEMENTATION_PLAN.md`
   * `docs/QUALITY_GATES.md`
   * `docs/SELF_ASSESSMENT.md`
   * `docs/DECISIONS.md`
   * `docs/DEVELOPMENT.md`
   * `docs/RELEASE.md`
   * `docs/MIGRATION_FROM_RABBITMQ.md`

Do not begin substantial implementation until you understand the architectural separation between:

```text
Hyrx Core
    ↓
Hyrx Embedded
    ↓
Hyrx Local
    ↓
Hyrx Network
    ↓
AMQP 0-9-1 adapter
    ↓
HyrxMQ
```

---

# 2. NON-NEGOTIABLE ARCHITECTURAL PRINCIPLES

These are hard constraints.

## 2.1 Hyrx is independent

Hyrx SHALL be:

* independently buildable
* independently testable
* independently usable
* independently versioned
* independently documented
* independently deployable

Hyrx SHALL NOT depend upon:

* the simulation
* creatures
* agents
* a game engine
* a semantic-world implementation
* any particular application
* RabbitMQ
* Erlang/OTP
* AMQP framing
* network connectivity

---

## 2.2 Simulation independence

The simulation is an **external consumer of Hyrx**.

Do not add concepts such as:

```text
Creature
Simulation
World
Agent
Perception
Cognition
Motor system
```

to Hyrx Core merely because they are useful to the simulation.

If the simulation eventually uses:

```text
creature/017/perception
creature/017/cognition
creature/017/memory
creature/017/motor
```

that is application-level topology.

Hyrx should only understand generic concepts such as:

```text
endpoint
address
message
route
queue
consumer
publisher
delivery
acknowledgement
transport
```

---

# 3. Hyrx VS HyrxMQ

Maintain this distinction throughout the implementation.

## Hyrx

The technology/substrate.

Its responsibilities include:

* messages
* envelopes
* endpoints
* routing
* queues
* consumers
* delivery
* acknowledgements
* backpressure
* scheduling
* ownership
* memory management
* transport abstraction
* direct communication
* local communication
* native network communication

## HyrxMQ

The product.

Its responsibilities include:

* standalone service
* AMQP 0-9-1
* TCP
* TLS
* authentication
* authorization
* virtual hosts
* persistence
* recovery
* management API
* CLI
* UI
* metrics
* diagnostics
* systemd
* operational packaging

## Dependency direction

This is mandatory:

```text
Hyrx
  ↑
HyrxMQ
```

NOT:

```text
HyrxMQ
  ↑
Hyrx
```

and definitely not:

```text
Simulation
  ↓
Hyrx
  ↓
HyrxMQ
```

where Hyrx becomes simulation-specific.

---

# 4. CORE DESIGN PHILOSOPHY

The central performance principle is:

> **Preserve messaging semantics; minimize the physical work required to realize them.**

Do not make every message pass through:

```text
serialize
→ frame
→ socket
→ parse
→ copy
→ route
→ copy
→ serialize
```

when both endpoints are already inside the same Hyrx process.

The direct path should be capable of approaching:

```text
producer
    ↓
native message
    ↓
route
    ↓
consumer
```

with unnecessary serialization, copying, allocation, system calls, and scheduling avoided.

---

# 5. AMQP IS AN INTEROPERABILITY BOUNDARY

Do NOT make AMQP frames the canonical internal representation.

The intended architecture is:

```text
                    AMQP client
                        │
                     TCP/TLS
                        │
                 AMQP 0-9-1 codec
                        │
                        ▼
                 Hyrx semantic API
                        │
                        ▼
                  Hyrx Core
                        │
               routing / delivery
                        │
                        ▼
                 Hyrx semantic API
                        │
                 AMQP serialization
                        │
                        ▼
                    client
```

A native Hyrx application should instead be capable of:

```text
application
    ↓
Hyrx API
    ↓
native message
    ↓
routing
    ↓
consumer
```

without AMQP serialization.

This is one of the project's most important architectural decisions.

---

# 6. TRANSPORT ARCHITECTURE

Transport is an implementation strategy, not the messaging semantic model.

The architecture MUST allow:

```text
Direct in-process
       ↓
Unix domain socket
       ↓
Shared memory
       ↓
Hyrx TCP
       ↓
Hyrx QUIC
       ↓
AMQP 0-9-1/TCP
```

Not all transports need to be implemented immediately.

However, the architecture must not make future transports impossible.

## Required baseline

TCP is the baseline external interoperability transport.

## Local transports

Evaluate:

* direct/in-process
* Unix domain sockets
* shared memory

Shared memory is NOT automatically required merely because it sounds faster.

It must earn its complexity through benchmarks.

## QUIC

QUIC may become a Hyrx-native transport.

Do NOT incorrectly claim that this is standard AMQP 0-9-1 over QUIC unless an appropriate protocol specification exists.

Call it a Hyrx transport extension.

---

# 7. IMPLEMENTATION ORDER

Follow this order unless an architectural review explicitly approves a change:

```text
Phase 0  Foundation
Phase 1  Hyrx Core memory/ownership substrate
Phase 2  Core routing and delivery
Phase 3  Embedded API + direct benchmarks
Phase 4  Local transports
Phase 5  Hyrx network transport
Phase 6  AMQP 0-9-1 adapter
Phase 7  HyrxMQ vertical slice
Phase 8  RabbitMQ compatibility
Phase 9  Performance engineering
Phase 10 Persistence
Phase 11 Security
Phase 12 Management API + CLI
Phase 13 UI + observability
Phase 14 Hardening
Phase 15 Performance qualification
Phase 16 Release candidate
```

Do not skip ahead simply because a later component is easier to demonstrate.

---

# 8. PHASE 0 — FOUNDATION

Establish:

* repository structure
* Mojo toolchain
* Linux baseline
* build system
* test system
* CI
* formatting/linting
* benchmark framework
* documentation framework
* configuration conventions
* decision log
* compatibility matrix

Establish the minimum supported:

* Mojo version
* Linux kernel
* glibc/runtime assumptions
* systemd version

only after validating the actual APIs being used.

## Gate

A clean checkout MUST:

1. build;
2. run unit tests;
3. run baseline benchmarks;
4. start the development service under systemd;
5. expose health/readiness;
6. produce useful logs;
7. pass CI.

---

# 9. PHASE 1 — MEMORY AND OWNERSHIP

Implement the core memory substrate.

Investigate:

* message buffers
* buffer views
* buffer chains
* pools
* slabs
* arenas
* ring buffers
* segments
* metadata storage

Use Mojo's ownership/lifetime facilities idiomatically.

## Requirements

Measure:

* allocations/message
* frees/message
* copies/message
* bytes copied/message
* pool hit rate
* memory/message

Every ownership transition must be documented.

## Gate

No known lifetime/ownership defects.

Stress tests must demonstrate safe behavior under concurrency and exhaustion.

---

# 10. PHASE 2 — ROUTING AND DELIVERY

Implement:

* publisher
* queue
* consumer
* route
* delivery
* acknowledgement
* rejection
* cancellation
* backpressure

The minimum vertical slice must work without:

* network
* AMQP
* disk
* systemd
* UI

## Gate

A native Hyrx producer can:

```text
publish
→ route
→ enqueue
→ deliver
→ acknowledge
→ release
```

correctly and repeatedly under concurrency.

---

# 11. PHASE 3 — EMBEDDED API

Create a stable Hyrx embedded API.

The API must expose semantic operations rather than internal implementation details.

Do not expose:

* slab internals
* queue implementation structures
* AMQP frames
* socket implementation details

unless specifically required by a carefully documented low-level API.

## Required benchmark

At minimum:

```text
producer → Hyrx → consumer
```

Test:

* tiny messages
* small messages
* medium messages
* large messages
* one producer/consumer
* many producers
* many consumers
* contention
* sustained throughput

Record:

* p50
* p95
* p99
* p99.9
* messages/sec
* bytes/sec
* CPU/message
* allocation/message
* copy/message
* memory/message

This establishes the baseline against which transport costs can later be measured.

---

# 12. PHASE 4 — LOCAL TRANSPORTS

Implement and benchmark Unix domain sockets.

Then investigate shared memory.

Shared memory requires explicit designs for:

* ownership
* synchronization
* process crash
* stale mappings
* versioning
* memory limits
* security
* NUMA
* recovery

Do not implement shared memory merely to tick a feature box.

## Gate

All implemented transports must pass semantic conformance tests.

Benchmark:

```text
direct
UDS
SHM
```

using equivalent workloads.

The benchmark report must show whether SHM actually provides sufficient benefit to justify its complexity.

---

# 13. PHASE 5 — HYRX NETWORK

Implement Hyrx-native TCP.

Requirements:

* connection lifecycle
* framing
* transport state
* flow control
* backpressure
* disconnect handling
* reconnect semantics where applicable
* resource limits

Evaluate:

* epoll
* io_uring

Do not assume either is superior.

Measure them.

QUIC may be prototyped after the TCP path is sound.

---

# 14. PHASE 6 — AMQP 0-9-1

Implement AMQP as an adapter over Hyrx.

Implement, according to the compatibility profile:

* protocol negotiation
* connections
* channels
* frame codec
* methods
* content headers
* content bodies
* field tables
* field arrays
* heartbeats
* errors
* limits
* state machines

The protocol engine must be deterministic and robust against malformed clients.

## Negative testing

For every implemented protocol feature, test:

* valid input
* invalid input
* invalid state
* malformed frames
* oversized input
* truncated input
* unexpected method
* connection termination
* channel termination

---

# 15. PHASE 7 — HYRXMQ VERTICAL SLICE

Produce the first real standalone broker.

It must support:

* executable
* systemd service
* TCP
* AMQP 0-9-1
* exchange
* queue
* binding
* publish
* consume
* ack
* health/status

## Acceptance test

On a clean Linux system:

```text
install
→ systemd start
→ ready
→ AMQP client connects
→ declare topology
→ publish
→ consume
→ acknowledge
```

must work.

---

# 16. PHASE 8 — RABBITMQ COMPATIBILITY

Build the compatibility matrix from actual evidence.

Test real AMQP clients.

Test against a pinned RabbitMQ reference version.

Compare:

* successful operations
* failures
* routing
* queue behavior
* delivery counts
* ordering
* acknowledgement
* redelivery
* confirms
* QoS
* cancellation
* TTL
* dead lettering
* priorities
* alternate exchanges
* exchange-to-exchange routing
* transactions where supported
* authentication
* vhosts
* authorization
* TLS
* heartbeat behavior

Never mark a feature "compatible" because its implementation looks plausible.

It must have evidence.

---

# 17. PHASE 9 — PERFORMANCE ENGINEERING

Only after correctness is established should aggressive optimization begin.

Investigate, measure, and where justified implement:

* buffer pooling
* ownership transfer
* zero/one-copy paths
* cache locality
* data-oriented structures
* queue sharding
* exchange/routing sharding
* batching
* specialized codecs
* generated codecs
* SIMD
* atomics
* CPU affinity
* NUMA locality
* epoll/io_uring variants
* socket tuning
* busy polling
* Linux-specific optimizations

## Important

Never optimize based solely on intuition.

For each optimization produce:

```text
hypothesis
→ baseline
→ implementation
→ benchmark
→ comparison
→ semantic regression test
→ decision
```

If it does not produce meaningful improvement, revert it or document why it remains necessary.

---

# 18. PERFORMANCE LABORATORY

Create reproducible benchmark suites.

At minimum:

## Core

```text
direct in-process
```

## Local

```text
Unix socket
shared memory, if implemented
```

## Network

```text
Hyrx TCP
Hyrx QUIC, if implemented
```

## Compatibility

```text
AMQP 0-9-1/TCP
AMQP 0-9-1/TLS
```

## Durable

Run each relevant transport under each persistence mode.

Do not mix persistence latency into claims about raw in-memory messaging.

---

# 19. PERFORMANCE METRICS

Measure at minimum:

* throughput messages/sec
* throughput bytes/sec
* p50 latency
* p95 latency
* p99 latency
* p99.9 latency
* CPU/message
* allocations/message
* bytes copied/message
* memory/message
* syscalls/message
* context switches
* scheduler wakeups
* routing cost
* codec cost
* persistence cost
* queue contention
* recovery time

Where practical also collect:

* cache misses
* branch misses
* CPU migrations
* NUMA effects

Use Linux performance tooling where appropriate.

---

# 20. PERFORMANCE MODEL

Maintain separate latency categories:

```text
L0 = protocol/codec
L1 = Hyrx routing
L2 = scheduling
L3 = transport
L4 = persistence
```

This allows us to answer:

> Where is Hyrx actually spending its time?

rather than merely saying:

> Hyrx is fast.

The long-term objective is to make:

```text
L1 + L2
```

as small as practically possible for native local workloads.

For network workloads, transport/kernel costs must be measured separately.

For durable workloads, persistence costs must be isolated.

---

# 21. PHASE 10 — PERSISTENCE

Implement:

* WAL
* segments
* indexes
* checkpoints
* recovery
* durability modes
* crash consistency

Potential modes:

```text
ephemeral
buffered durable
flush-bounded durable
strict durable
```

Exact semantics must be specified before release.

## Crash tests

Force termination:

* during append
* during segment rotation
* during checkpoint
* during index update
* during flush
* during recovery

Also test:

* partial records
* corruption
* missing segments
* disk full
* permission errors

No silent data corruption is acceptable.

---

# 22. PHASE 11 — SECURITY

Implement:

* TLS
* SASL
* authentication
* authorization
* vhosts
* resource permissions
* operation permissions
* connection limits
* frame limits
* message limits
* memory limits
* queue limits
* timeout controls

Security testing must include hostile input.

A malformed client MUST NOT crash HyrxMQ.

---

# 23. PHASE 12 — MANAGEMENT API AND CLI

Management is a separate control plane.

It MUST NOT become part of the hot message path.

Implement versioned API.

Initial conceptual endpoints:

```text
/api/v1/status
/api/v1/health
/api/v1/connections
/api/v1/channels
/api/v1/exchanges
/api/v1/queues
/api/v1/bindings
/api/v1/consumers
/api/v1/users
/api/v1/permissions
/api/v1/metrics
/api/v1/topology
/api/v1/diagnostics
```

Maintain an OpenAPI specification.

CLI should provide operations such as:

```text
hyrxmq status
hyrxmq health
hyrxmq queues list
hyrxmq queues inspect
hyrxmq queues purge
hyrxmq exchanges list
hyrxmq bindings list
hyrxmq connections list
hyrxmq consumers list
hyrxmq users list
hyrxmq permissions list
hyrxmq metrics
hyrxmq topology
hyrxmq config validate
hyrxmq diagnostics
```

Provide machine-readable output such as:

```text
--json
```

---

# 24. PHASE 13 — MANAGEMENT UI

Implement a browser management interface.

At minimum:

* dashboard
* queues
* exchanges
* bindings
* consumers
* connections
* channels
* topology visualization
* privileged message inspection
* users
* permissions
* performance
* storage
* diagnostics
* configuration validation

Destructive actions must require explicit confirmation.

The UI is not a replacement for the API or CLI.

---

# 25. OBSERVABILITY

Provide metrics for:

* published messages
* routed messages
* delivered messages
* acknowledged messages
* redeliveries
* rejects
* nacks
* confirms
* queue depth
* consumer count
* connections
* channels
* bytes in/out
* latency
* persistence latency
* errors
* rejected/dropped messages
* resource pressure

Provide appropriate histogram metrics for tail latency.

Instrumentation must be designed so that production observability does not impose disproportionate hot-path overhead.

---

# 26. SYSTEMD

HyrxMQ is GNU/Linux/systemd native.

Provide:

* service unit
* startup
* readiness
* graceful shutdown
* restart policy
* optional watchdog
* dedicated user/group
* journal integration
* runtime directory
* data directory
* configuration validation
* safe reload where applicable

Evaluate:

* NoNewPrivileges
* ProtectSystem
* ProtectHome
* PrivateTmp
* RestrictAddressFamilies
* capability restrictions
* filesystem restrictions
* resource limits

Every hardening control must be tested before becoming normative.

---

# 27. FAILURE SEMANTICS

Explicitly define behavior for:

* network disconnect
* half-open connection
* client crash
* consumer crash
* publisher failure
* malformed protocol
* queue exhaustion
* memory exhaustion
* disk full
* storage failure
* process crash
* forced termination

For each failure specify:

* what the client sees
* what happens to the message
* whether it is redelivered
* whether state survives
* whether the connection/channel closes
* how recovery works

Do not leave failure behavior implicit.

---

# 28. RESOURCE GOVERNANCE

Implement explicit limits for:

* connections
* channels
* queues
* exchanges
* bindings
* consumers
* message size
* frame size
* queue depth
* memory
* disk
* unacknowledged messages
* confirms
* transactions

Resource exhaustion must be deterministic and observable.

Never allow accidental unbounded growth.

---

# 29. TESTING REQUIREMENTS

Testing is continuous.

Every implementation feature must have appropriate:

```text
unit
component
integration
compatibility
stress
fault
performance
```

coverage.

## Required test classes

### Unit

Pure logic.

### Component

Subsystem interaction.

### Integration

Real Hyrx/HyrxMQ components.

### Protocol

AMQP conformance.

### Compatibility

Real AMQP clients and RabbitMQ differential tests.

### Stress

High load.

### Soak

Long-running stability.

### Fuzzing

Malformed/random inputs.

### Fault injection

Injected operational failures.

### Persistence recovery

Crash/restart/corruption.

### Security

Authentication, authorization, hostile input.

---

# 30. TEST MATRIX

Build a persistent test matrix covering at least:

| Area                   | Required            |
| ---------------------- | ------------------- |
| Build                  | Yes                 |
| Unit tests             | Yes                 |
| Ownership              | Yes                 |
| Memory exhaustion      | Yes                 |
| Routing                | Yes                 |
| Ordering               | Yes                 |
| Delivery               | Yes                 |
| Ack/Nack               | Yes                 |
| Backpressure           | Yes                 |
| Direct transport       | Yes                 |
| UDS                    | If implemented      |
| SHM                    | If implemented      |
| TCP                    | Yes                 |
| QUIC                   | If implemented      |
| AMQP codec             | Yes                 |
| AMQP state machine     | Yes                 |
| RabbitMQ compatibility | Yes                 |
| Persistence            | If enabled          |
| Crash recovery         | Yes for persistence |
| TLS                    | Yes                 |
| Authentication         | Yes                 |
| Authorization          | Yes                 |
| Management API         | Yes                 |
| CLI                    | Yes                 |
| UI                     | Yes                 |
| Metrics                | Yes                 |
| systemd                | Yes                 |
| Fuzzing                | Yes                 |
| Stress                 | Yes                 |
| Soak                   | Yes                 |
| Performance            | Yes                 |

---

# 31. FUZZING

Fuzz at least:

* AMQP frames
* AMQP field tables
* field arrays
* method/state transitions
* configuration
* management API
* persistence records
* transport framing

Any:

* crash
* hang
* assertion failure
* memory-safety issue
* state corruption
* resource runaway

is a release blocker until resolved or explicitly accepted through architectural review.

---

# 32. DIFFERENTIAL TESTING

For equivalent behavior execute tests against:

```text
RabbitMQ reference
        vs
HyrxMQ
```

Use a pinned RabbitMQ version.

Compare semantic outcomes.

Do not compare only throughput.

Compare:

* topology
* routing
* deliveries
* acknowledgements
* redelivery
* ordering
* confirms
* errors
* lifecycle behavior

---

# 33. COMPATIBILITY CLAIMS

Never write:

> "RabbitMQ compatible"

without qualification.

Instead maintain a matrix:

```text
supported
partially supported
intentionally unsupported
not yet tested
```

Every claimed feature must point to automated evidence.

If behavior differs from RabbitMQ, document the difference.

Do not hide incompatibilities.

---

# 34. ARCHITECTURAL QUALITY GATES

No phase is complete until:

## Q0

Build integrity passes.

## Q1

Core correctness passes.

## Q2

Semantic correctness passes.

## Q3

Transport conformance passes.

## Q4

Protocol conformance passes.

## Q5

Compatibility evidence exists.

## Q6

Persistence/recovery passes.

## Q7

Security passes.

## Q8

Performance qualification passes.

## Q9

Operational integration passes.

## Q10

Release criteria pass.

Release blockers include:

* data corruption
* unintended message loss
* incorrect acknowledgement behavior
* protocol-state corruption
* crash from malformed input
* uncontrolled memory growth
* undocumented compatibility gaps
* false performance claims
* systemd startup/recovery failure

---

# 35. SELF-ASSESSMENT — MANDATORY

At the end of EVERY implementation phase, produce a self-assessment.

Answer explicitly:

### Architecture

1. Did I preserve Hyrx's independence from simulation?
2. Did I accidentally make AMQP an internal dependency?
3. Did I accidentally make TCP mandatory inside Hyrx Core?
4. Did I introduce HyrxMQ responsibilities into Hyrx Core?
5. Did I introduce premature distributed-system architecture?

### Correctness

6. What invariants are actually proven?
7. What remains assumption?
8. Which failure paths remain untested?

### Performance

9. What is the measured bottleneck?
10. What evidence supports each optimization?
11. How many allocations occur per message?
12. How many copies occur per message?
13. What is the contention profile?
14. What is the tail-latency profile?
15. Did the optimization improve the target workload?

### Compatibility

16. Which AMQP features are genuinely tested?
17. Which RabbitMQ behaviors are inferred rather than demonstrated?
18. Has the compatibility matrix been updated?

### Reliability

19. What happens under memory exhaustion?
20. What happens under connection storms?
21. What happens under process termination?
22. What happens under disk failure?

### Security

23. What hostile inputs were tested?
24. What privileges does the service require?
25. Which systemd restrictions have been validated?

### Documentation

26. Does the documentation describe actual behavior?
27. Are unsupported features explicit?
28. Are benchmark results reproducible?

---

# 36. HONESTY REQUIREMENT

The development agent MUST NOT mark something complete merely because:

* the code compiles;
* a happy-path test passes;
* the implementation looks correct;
* a benchmark number is impressive;
* the feature works once;
* another system behaves similarly;
* the agent believes the behavior is correct.

Completion requires the evidence specified by the applicable quality gate.

If evidence does not exist, report:

> **NOT PROVEN**

rather than claiming completion.

---

# 37. STOP CONDITIONS

Stop implementation and request architectural review if:

* two requirements conflict;
* a transport optimization changes semantics;
* unsafe memory behavior appears necessary;
* compatibility cannot be established;
* persistence semantics are ambiguous;
* simulation-specific concepts appear necessary in Hyrx Core;
* a new dependency materially changes architecture;
* a proposed optimization requires undocumented semantic changes;
* clustering/distributed consensus begins appearing as an implicit requirement.

Do not resolve architectural conflicts by silently choosing one interpretation.

---

# 38. DEPENDENCY DISCIPLINE

Do not add dependencies merely because another broker uses them.

For every significant dependency document:

* purpose
* license
* maintenance status
* security implications
* performance impact
* build impact
* deployment impact

Prefer native Mojo/Linux facilities where they are appropriate.

---

# 39. GENERATED CODE

Where authoritative machine-readable protocol definitions exist, prefer generated protocol metadata/code over duplicated handwritten constants.

Generated output must be:

* reproducible
* deterministic
* reviewable
* traceable to its source specification

Do not manually maintain large duplicated protocol tables when generation is practical.

---

# 40. DOCUMENTATION DISCIPLINE

Whenever implementation changes behavior:

1. update tests;
2. update requirements/status;
3. update compatibility matrix if relevant;
4. update architecture documentation if relevant;
5. update operational documentation if relevant;
6. update public documentation if user-visible;
7. update benchmark methodology/results if performance claims change.

Documentation is part of the implementation.

---

# 41. GIT/REPOSITORY DISCIPLINE

Keep commits logically coherent.

Prefer commits such as:

```text
core: add message ownership model
core: implement bounded queue
routing: add direct exchange matcher
transport: add unix domain transport
amqp: implement connection negotiation
amqp: implement basic publish
hyrxmq: add systemd service
perf: add direct-path benchmark
test: add RabbitMQ differential suite
docs: document transport semantics
```

Do not mix unrelated architectural changes into one opaque commit.

---

# 42. REQUIRED DEVELOPMENT REPORT

At the end of every significant work session, report:

## Implemented

What was actually implemented.

## Tested

Exact test commands and outcomes.

## Benchmarked

Exact benchmark commands, workload, environment, and results.

## Compatibility

Exact compatibility tests and status.

## Documentation

Which documentation changed.

## Remaining

What is incomplete.

## Risks

Known technical risks.

## Decisions

Any architectural decision that changed.

## Self-assessment

Complete the mandatory self-assessment described above.

---

# 43. DO NOT GUESS

If a Mojo API, Linux API, AMQP behavior, RabbitMQ behavior, or third-party library behavior is uncertain:

1. inspect authoritative documentation;
2. inspect the actual installed/toolchain API;
3. create a minimal experiment;
4. test it;
5. record the result.

Do not invent APIs.

Do not invent protocol behavior.

Do not assume an API exists because it exists in another language.

Do not assume Mojo behaves like C++, Rust, Python, or another language.

Do not assume RabbitMQ behavior without testing or authoritative documentation.

---

# 44. PERFORMANCE EXPERIMENTALISM

The project explicitly welcomes aggressive performance engineering.

However:

> **Complexity must earn its place.**

A sophisticated optimization is desirable only when it produces meaningful measurable benefit.

Investigate aggressively:

* zero-copy
* ownership transfer
* pooling
* batching
* lock-free structures
* sharding
* SIMD
* specialized codecs
* epoll
* io_uring
* Unix sockets
* shared memory
* QUIC
* CPU affinity
* NUMA
* Linux socket features
* kernel-assisted data movement

But benchmark each one.

The desired question is not:

> "Can we implement this optimization?"

It is:

> "Does this optimization reduce the cost of a real messaging operation enough to justify its complexity?"

---

# 45. PERFORMANCE TARGETING

Do not invent arbitrary performance numbers before the baseline exists.

First establish:

```text
Hyrx direct baseline
```

Then establish:

```text
UDS
SHM
Hyrx TCP
Hyrx QUIC
AMQP TCP
AMQP TLS
durable
```

Only then establish explicit performance targets based on measured capability and realistic workloads.

Performance targets must distinguish:

* latency
* throughput
* resource efficiency
* tail behavior

Never optimize solely for messages/sec.

---

# 46. THE SIMULATION USE CASE

The simulation should eventually be able to use Hyrx in ways such as:

```text
Simulation
├── Creature 001
│   ├── perception
│   ├── cognition
│   ├── memory
│   └── motor
│
├── Creature 002
│   ├── perception
│   ├── cognition
│   ├── memory
│   └── motor
│
└── ...
```

with Hyrx potentially providing the messaging substrate.

However, this is **not a requirement that Hyrx implement creatures**.

The simulation owns:

* creature identity
* simulation time
* world state
* perception
* cognition
* agent semantics
* domain topology

Hyrx owns:

* messages
* routing
* delivery
* queues
* consumers
* transports
* messaging semantics

This boundary MUST remain intact.

---

# 47. LONG-TERM TRANSPORT VISION

The architecture should permit a future application to communicate using:

```text
same process:
    direct Hyrx

same host:
    direct / UDS / SHM

Hyrx-native remote:
    QUIC / TCP

external ecosystem:
    AMQP 0-9-1 over TCP/TLS
```

An application should ideally not have to redesign its semantic messaging model merely because the endpoints move from:

```text
same function
→ same process
→ same host
→ another host
```

Transport selection should eventually be a deployment concern.

---

# 48. PRODUCT POSITIONING

Do not describe HyrxMQ as:

> "RabbitMQ but faster"

unless an appropriately controlled benchmark actually establishes a particular comparison.

Prefer:

> **HyrxMQ is a native Mojo AMQP broker built on Hyrx, a messaging engine designed around low-cost local and transport-independent message routing.**

RabbitMQ compatibility is an interoperability feature.

It is not the definition of Hyrx's architecture.

---

# 49. FIRST PRINCIPLES

Whenever an implementation decision is unclear, reason from these principles:

### Principle 1

**Messaging semantics are primary.**

### Principle 2

**Transport is secondary.**

### Principle 3

**AMQP is an interoperability boundary.**

### Principle 4

**Hyrx Core is independent of HyrxMQ.**

### Principle 5

**Hyrx is independent of simulation.**

### Principle 6

**Local communication should not pay unnecessary network costs.**

### Principle 7

**Network communication should not contaminate the local semantic model.**

### Principle 8

**Ownership should replace copying where safely possible.**

### Principle 9

**Bounded resources are preferable to uncontrolled growth.**

### Principle 10

**Correctness precedes optimization.**

### Principle 11

**Optimization requires evidence.**

### Principle 12

**Compatibility requires evidence.**

### Principle 13

**Documentation is part of correctness.**

---

# 50. FINAL IMPLEMENTATION STANDARD

The finished system should conceptually permit all of the following without architectural contradiction:

```text
Application
    ↓
Hyrx
    ↓
direct in-process message
```

```text
Application
    ↓
Hyrx
    ↓
Unix/SHM
    ↓
another local process
```

```text
Application
    ↓
Hyrx
    ↓
Hyrx TCP/QUIC
    ↓
another Hyrx instance
```

```text
RabbitMQ-compatible application
    ↓
AMQP 0-9-1
    ↓
TCP/TLS
    ↓
HyrxMQ
    ↓
Hyrx Core
```

and:

```text
Simulation
    ↓
Hyrx
```

must work without Hyrx knowing that the simulation exists.

That is the architectural success condition.

---

# 51. FINAL COMMAND TO THE DEVELOPMENT AGENT

Proceed methodically.

Do not rush toward a visible broker UI or AMQP feature count at the expense of the core architecture.

Build the messaging engine first.

Prove its semantics.

Prove its ownership model.

Prove its direct performance.

Then add transports.

Then add AMQP.

Then assemble HyrxMQ.

Then add persistence/security/management/operations.

Then qualify the complete system.

At every stage:

```text
IMPLEMENT
    ↓
TEST
    ↓
MEASURE
    ↓
COMPARE
    ↓
DOCUMENT
    ↓
SELF-ASSESS
    ↓
QUALITY GATE
```

Do not declare a phase complete without evidence.

Do not guess.

Do not silently reinterpret requirements.

Do not allow the simulation to become a dependency.

Do not allow AMQP to become the internal architecture.

Do not optimize based on intuition alone.

The objective is not merely to produce a functioning AMQP broker.

The objective is to produce a **clean, independent, native Mojo messaging substrate whose semantics can operate at extremely low cost in-process and whose capabilities can be projected outward through progressively more expensive transports, with HyrxMQ providing a serious standalone AMQP-compatible broker product on GNU/Linux/systemd.**
