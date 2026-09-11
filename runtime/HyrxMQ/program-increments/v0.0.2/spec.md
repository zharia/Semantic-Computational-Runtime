# Hyrx Next-Phase Engineering Programme

## Mission

Continue development of Hyrx/HyrxMQ from its current alpha-stage state toward a **provably coherent, interoperable, recoverable and trustworthy systems substrate**.

This is **not** a request to add more superficial features.

The current architecture already contains a substantial vertical slice:

* Hyrx Core
* embedded execution
* routing
* queues
* consumers
* delivery
* acknowledgement
* TCP
* UDS
* event-driven serving
* AMQP 0-9-1 machinery
* persistence seams
* WSS/HTTP experimentation
* management/control-plane beginnings
* performance instrumentation and optimization work

The next phase must consolidate that work.

The central objective is:

> **Stop proving that HyrxMQ can exist. Start proving that Hyrx can be trusted.**

The implementation must therefore proceed through explicit engineering gates.

Do not treat documentation, compilation, a happy-path test, or an isolated benchmark as proof of correctness.

Every significant claim must have corresponding executable evidence.

---

# 1. Non-negotiable architectural principles

Preserve the existing architectural separation.

The following distinctions MUST remain explicit:

```text
Hyrx Core
    ≠
HyrxMQ
    ≠
AMQP
    ≠
TCP
    ≠
UDS
    ≠
WSS/HTTP
    ≠
simulation
```

Hyrx Core is the semantic messaging substrate.

HyrxMQ is one product/runtime manifestation of Hyrx.

AMQP is an adapter/protocol surface, not the canonical internal representation.

Transport is a physical execution mechanism, not the semantic messaging model.

Do not introduce dependencies from Hyrx Core into:

* AMQP
* TCP
* filesystem
* systemd
* TLS
* HTTP
* WSS
* RabbitMQ
* simulation-specific concepts

unless an existing architectural specification explicitly requires such a dependency.

If an apparent requirement conflicts with this separation, stop and document the conflict before implementing it.

---

# 2. First task: establish the actual current baseline

Before changing implementation code:

1. Inspect the complete current Hyrx/HyrxMQ tree.
2. Read the current architecture and core specifications.
3. Read the current programme increments and milestone records.
4. Inspect all current tests.
5. Inspect the current AMQP compatibility material.
6. Inspect current performance measurements.
7. Inspect persistence implementation and tests.
8. Inspect current security implementation versus security specification.
9. Inspect management/control-plane implementation.
10. Run the existing validation suite.
11. Establish the current compiler/toolchain version actually used by the repository.
12. Record the current git revision/commit being evaluated.

Do not assume that previous reports accurately describe the current implementation.

The repository itself is the source of truth for implementation state.

Create a baseline report before substantive modifications:

```text
docs/engineering/
    CURRENT_STATE.md
```

The report must distinguish:

```text
IMPLEMENTED
TESTED
PROVEN
PARTIALLY VALIDATED
SPECIFIED ONLY
NOT IMPLEMENTED
NOT PROVEN
```

Do not use ambiguous terms such as "supported" unless the evidence supporting that claim is identified.

---

# 3. Establish the Hyrx Semantic Invariant Model

This is the first major engineering gate.

Create a canonical specification for the semantic invariants governing Hyrx Core.

Suggested location:

```text
runtime/HyrxMQ/docs/SEMANTIC_INVARIANTS.md
```

Use the existing repository naming/versioning conventions where appropriate rather than blindly creating a new structure.

The invariant model must cover at minimum:

## 3.1 Message identity

Define and test:

```text
M1  A message has a canonical identity.
M2  Routing does not change message identity.
M3  Fan-out does not silently mutate message identity.
M4  Payload identity is preserved through routing.
M5  Message metadata survives routing and delivery.
```

If the actual architecture deliberately defines different semantics, document those semantics rather than imposing the above blindly.

## 3.2 Envelope and delivery identity

Define:

```text
D1  A delivery is distinguishable from the underlying message.
D2  Every delivery has a defined lifecycle.
D3  Acknowledgement refers to a specific delivery.
D4  Duplicate acknowledgement has deterministic semantics.
D5  Delivery cancellation/rejection has defined semantics.
```

## 3.3 Routing

Define:

```text
R1  Routing is deterministic for a fixed topology and input.
R2  Routing does not silently lose metadata.
R3  Routing does not introduce unintended duplication.
R4  Binding changes have defined visibility semantics.
R5  Topology mutation cannot corrupt in-flight routing.
```

## 3.4 Queue semantics

Define:

```text
Q1  Queue state transitions are deterministic.
Q2  Enqueue/dequeue semantics are explicit.
Q3  Queue limits are enforced.
Q4  Queue exhaustion has defined behaviour.
Q5  Consumer lifecycle cannot corrupt queue state.
```

## 3.5 Consumer/delivery semantics

Define:

```text
C1  Consumers have explicit lifecycle states.
C2  Delivery ownership is explicit.
C3  Disconnect semantics are defined.
C4  Unacknowledged delivery behaviour is defined.
C5  Consumer cancellation cannot lose or duplicate messages unexpectedly.
```

## 3.6 Resource boundedness

Establish invariants for:

```text
connections
channels
queues
consumers
messages
payload size
frame size
queue depth
in-flight deliveries
memory
CPU/event-loop work
```

The core principle is:

```text
bounded external input
        ↓
bounded internal work
        ↓
bounded resource consumption
```

Where boundedness is intentionally relaxed, document why.

---

# 4. Turn invariants into executable evidence

Do not stop at documentation.

Every invariant that can be tested must become an executable test.

Organize tests according to repository conventions, for example:

```text
tests/
    semantic/
    routing/
    delivery/
    ownership/
    lifecycle/
    resources/
```

Each test must establish:

```text
PRECONDITION
ACTION
OBSERVATION
EXPECTED INVARIANT
RESULT
```

Where practical, tests should be deterministic and repeatable.

Tests must cover both:

```text
happy path
```

and:

```text
failure path
```

Do not declare an invariant proven merely because one positive test passes.

Add negative tests where applicable.

Examples:

* duplicate acknowledgement
* acknowledgement after cancellation
* consumer disconnect during delivery
* queue exhaustion
* malformed delivery state
* routing to zero destinations
* fan-out to multiple destinations
* topology mutation during active delivery
* repeated publish/consume cycles
* shutdown during active work

---

# 5. Build an invariant/evidence registry

Create a machine-readable registry using the repository's preferred format.

For example:

```text
runtime/HyrxMQ/docs/
    invariants/
        registry.yaml
```

or an equivalent structure consistent with existing repository practice.

Each invariant should have:

```yaml
id:
category:
statement:
implementation:
tests:
status:
evidence:
known_limitations:
```

Statuses must be constrained to explicit states such as:

```text
specified
implemented
tested
provisionally-proven
proven
failed
blocked
not-applicable
```

Do not mark an invariant `proven` unless there is reproducible executable evidence.

This registry becomes the foundation for future Hyrx development.

---

# 6. Gate 1 — Semantic correctness

Do not proceed to declaring this phase complete until:

* semantic invariants are documented;
* core implementation has been audited against them;
* executable tests exist for applicable invariants;
* known violations are explicitly recorded;
* ambiguous semantics have been resolved or explicitly marked unresolved;
* no documentation claims exceed implementation evidence.

Produce:

```text
docs/engineering/GATE_01_SEMANTIC_CORRECTNESS.md
```

The gate must contain:

```text
PASS
FAIL
BLOCKED
NOT PROVEN
```

for each major invariant group.

A gate may legitimately fail.

Do not modify evidence to obtain a PASS.

---

# 7. Gate 2 — Ownership and memory model

This is a major technical priority.

Create a canonical ownership/memory model for Hyrx.

Suggested documentation:

```text
runtime/HyrxMQ/docs/OWNERSHIP_AND_MEMORY.md
```

The model must explicitly describe:

```text
message
envelope
payload
metadata
queue
delivery
consumer
transport
codec
```

and ownership/lifetime relationships between them.

Determine which objects are:

```text
owned
borrowed
shared
moved
copied
reference-counted
```

according to the actual Mojo implementation and supported language semantics.

Do not invent an ownership model that the implementation does not actually enforce.

---

# 8. Create a copy/allocation ledger

Trace the complete message path:

```text
publish
    ↓
protocol decode
    ↓
canonical message
    ↓
routing
    ↓
queue
    ↓
delivery
    ↓
consumer
    ↓
protocol encode
    ↓
transport
```

For each stage record:

```text
copy?
allocation?
ownership transfer?
reference?
serialization?
reason?
avoidable?
```

Produce an auditable ledger.

Example:

| Stage     | Copy | Allocation | Ownership | Required | Evidence |
| --------- | ---- | ---------- | --------- | -------- | -------- |
| Decode    |      |            |           |          |          |
| Publish   |      |            |           |          |          |
| Route     |      |            |           |          |          |
| Queue     |      |            |           |          |          |
| Deliver   |      |            |           |          |          |
| Encode    |      |            |           |          |          |
| Transport |      |            |           |          |          |

Do not optimize blindly.

The objective is not:

> zero copies at any cost.

The objective is:

> **Every copy and allocation must have an identified semantic or physical justification.**

---

# 9. Correct fan-out semantics before optimizing it

Specifically inspect current routing/fan-out behaviour.

Verify that:

```text
one semantic message
        ↓
N destinations
```

does not accidentally become:

```text
N semantically independent messages
```

unless that is explicitly the intended model.

Preserve:

* message identity
* metadata
* payload correctness
* delivery identity
* acknowledgement semantics

across fan-out.

Create regression tests for the currently documented copy/metadata issues.

---

# 10. Measure before and after optimization

Establish repeatable measurements for:

```text
single destination
fan-out 2
fan-out 8
fan-out 32
fan-out 128
```

where practical.

Measure:

* throughput
* latency
* tail latency
* allocations
* copies
* memory footprint
* CPU
* queue contention
* event-loop behaviour

Do not publish synthetic numbers without describing the workload.

Record:

```text
hardware
OS
compiler/toolchain
build mode
message size
fan-out
consumer count
queue count
transport
duration
sample count
```

Performance claims must be reproducible.

---

# 11. Gate 2 completion criteria

Do not mark ownership/memory complete until:

* ownership semantics are documented;
* implementation matches documentation;
* known copies are identified;
* avoidable copies have been removed where justified;
* fan-out correctness is proven;
* lifetime safety is tested;
* allocation/copy measurements exist;
* performance changes are benchmarked rather than assumed.

Produce:

```text
docs/engineering/GATE_02_OWNERSHIP_MEMORY.md
```

---

# 12. Gate 3 — Real AMQP/RabbitMQ interoperability

This is the primary external validation gate.

Resolve all contradictory compatibility claims in the repository.

There MUST be one canonical current statement of interoperability status.

Use real external clients.

At minimum investigate and test with:

```text
pika
RabbitMQ
```

and other existing AMQP tooling where practical.

Do not substitute an internal Hyrx test for an external interoperability test.

---

# 13. Build an AMQP interoperability corpus

Establish tests for at least:

```text
connection
connection negotiation
channel creation
exchange declaration
queue declaration
binding
publish
consume
ack
nack
reject
close
reconnect
```

Then progressively test:

```text
QoS/prefetch
publisher confirms
mandatory publish
TTL
dead-letter exchange
priority
alternate exchange
exchange-to-exchange
authentication
virtual hosts
authorization
```

Only mark features as compatible when actual evidence exists.

---

# 14. Create RabbitMQ differential testing

Run equivalent workloads against:

```text
RabbitMQ
HyrxMQ
```

Capture observable behaviour.

Compare:

```text
routing
delivery
ordering
acknowledgement
errors
connection behaviour
channel behaviour
resource limits
recovery
```

Where behaviour differs, classify the difference:

```text
Hyrx bug
RabbitMQ-specific behaviour
AMQP requirement
undefined/implementation-specific behaviour
intentional Hyrx semantic difference
unknown
```

Do not automatically reproduce RabbitMQ behaviour if doing so would violate the Hyrx semantic architecture.

The purpose of RabbitMQ differential testing is to distinguish:

```text
protocol compatibility
```

from:

```text
semantic identity
```

---

# 15. Create an interoperability receipt

Every compatibility milestone must produce a reproducible receipt.

For example:

```text
environment
client
server
commit
configuration
test
result
logs
observed protocol sequence
pass/fail
known deviations
```

The receipt must make statements such as:

```text
"pika successfully completed AMQP connection negotiation"
```

objectively verifiable.

No more ambiguous claims such as:

```text
"AMQP handshake proven"
```

unless the exact test proving it is identified.

---

# 16. Gate 3 completion

The gate should progressively establish:

```text
Level A — TCP + AMQP handshake
Level B — publish
Level C — consume
Level D — acknowledgement/recovery
Level E — broader RabbitMQ behavioural compatibility
```

Do not claim a higher level when only a lower level is proven.

Produce:

```text
docs/engineering/GATE_03_AMQP_INTEROPERABILITY.md
```

Update the canonical compatibility document so that no contradictory status remains elsewhere in the repository.

---

# 17. Gate 4 — Persistence and crash recovery

Treat persistence as a **semantic correctness problem**, not merely a storage implementation.

First define the durability model.

At minimum distinguish:

```text
volatile
memory-backed
recoverable
durable
crash-consistent
```

Define exactly what each mode promises.

---

# 18. Persistence state-transition model

Document which state transitions are externally observable before persistence.

For example:

```text
publish
    ↓
journal
    ↓
enqueue
    ↓
deliver
    ↓
ack
```

Determine the durability point for each operation.

Define behaviour when the process terminates:

```text
before journal write
during journal write
after journal write
before enqueue
after enqueue
before delivery
after delivery
before ack
after ack
```

---

# 19. Implement crash/recovery testing

Build automated recovery tests where practical:

```text
start
publish known workload
terminate at controlled point
restart
recover
inspect state
compare expected semantic state
```

Test:

* incomplete records
* truncated records
* repeated records
* invalid records
* corruption
* clean shutdown
* abrupt process termination
* multiple queues
* outstanding deliveries
* acknowledgements
* topology state

Do not declare persistence reliable merely because data survives a normal restart.

---

# 20. Gate 4 completion

Persistence must have:

* documented durability semantics;
* journal/storage invariants;
* recovery tests;
* crash tests;
* corruption handling;
* deterministic recovery behaviour;
* evidence-backed durability claims.

Produce:

```text
docs/engineering/GATE_04_PERSISTENCE.md
```

---

# 21. Gate 5 — Security and isolation

Audit the current security specification against actual implementation.

Create a matrix:

| Capability         | Specified | Implemented | Tested | Proven |
| ------------------ | --------: | ----------: | -----: | -----: |
| TLS                |           |             |        |        |
| authentication     |           |             |        |        |
| SASL               |           |             |        |        |
| vhosts             |           |             |        |        |
| authorization      |           |             |        |        |
| resource limits    |           |             |        |        |
| frame limits       |           |             |        |        |
| message limits     |           |             |        |        |
| timeout protection |           |             |        |        |
| hostile input      |           |             |        |        |
| systemd hardening  |           |             |        |        |

Do not count architecture documents as implementation.

---

# 22. Define the security semantic boundary

Model:

```text
Principal
    ↓
Authentication
    ↓
Authorization
    ↓
Virtual host/resource boundary
    ↓
Operation
```

Verify that no authenticated principal can improperly:

* observe another principal's data;
* mutate another principal's topology;
* consume unauthorized queues;
* publish to unauthorized exchanges;
* bypass resource limits.

Add adversarial tests.

---

# 23. Hostile-input testing

At minimum investigate:

```text
oversized frames
oversized messages
invalid frame sequences
invalid method sequences
malformed headers
invalid UTF-8 where relevant
connection exhaustion
channel exhaustion
queue exhaustion
consumer exhaustion
rapid connect/disconnect
partial frames
truncated frames
unexpected EOF
invalid authentication
authorization failures
resource exhaustion
```

The objective is not merely "does it reject invalid input?"

Also establish:

> **Does hostile input leave the system in a valid semantic state?**

---

# 24. Gate 5 completion

Produce:

```text
docs/engineering/GATE_05_SECURITY_ISOLATION.md
```

No production-security claim is permitted without executable evidence.

---

# 25. Gate 6 — Operations and observability

Now consolidate the emerging product layer.

The control plane must remain separate from the data plane.

Data plane:

```text
publish
route
enqueue
deliver
ack
flow control
```

Control plane:

```text
configuration
topology
users
permissions
metrics
diagnostics
lifecycle
```

Do not allow management functionality to introduce unnecessary hot-path dependencies.

---

# 26. Establish authoritative observability

Expose enough information to diagnose:

```text
connections
channels
queues
exchanges
bindings
consumers
message rates
delivery rates
ack rates
queue depth
in-flight deliveries
errors
resource exhaustion
latency
memory
CPU
persistence
recovery
```

Metrics must have clearly defined semantics.

Do not expose metrics whose meaning is ambiguous.

---

# 27. Operational failure testing

Test:

```text
startup failure
configuration failure
port binding failure
permission failure
storage failure
shutdown
restart
crash
recovery
resource exhaustion
client disconnect
network failure
```

Systemd integration should be tested rather than merely documented.

---

# 28. Gate 6 completion

Produce:

```text
docs/engineering/GATE_06_OPERATIONS.md
```

The gate must distinguish:

```text
development operation
alpha operation
production operation
```

Do not call something production-ready merely because systemd can launch it.

---

# 29. Repository documentation integrity

As part of every gate, audit documentation against implementation.

Search for statements such as:

```text
supported
complete
proven
production-ready
compatible
zero-copy
durable
secure
```

For each claim determine whether it is:

```text
demonstrated
partially demonstrated
specified
aspirational
false/stale
```

Correct stale documentation.

Do not weaken technical truth to make the project appear more mature.

The repository's credibility is more important than its apparent feature count.

---

# 30. No speculative feature expansion during this programme

Do NOT add new protocol adapters or transports merely to increase feature count.

Unless required to validate an existing architectural invariant, defer:

```text
new messaging protocols
new network transports
additional UI
additional management surfaces
distributed clustering
large feature expansions
```

The current architecture has sufficient surface area.

The priority is:

```text
correctness
→
ownership
→
interoperability
→
durability
→
security
→
operations
```

---

# 31. Preserve the possibility of distributed Hyrx

Do not implement distributed Hyrx yet unless a discovered requirement makes it necessary.

However, while implementing the current gates, identify which invariants will matter when Hyrx crosses process/machine boundaries.

Explicitly record future concerns around:

```text
message identity
ownership transfer
delivery identity
topology
ordering
failure domains
network partitions
duplicate delivery
acknowledgement
persistence
locality
backpressure
```

Create a short future architecture note if appropriate:

```text
docs/engineering/FUTURE_DISTRIBUTED_HYRX.md
```

This is research/design only.

Do not allow it to destabilize the current implementation.

---

# 32. Evidence discipline

This is mandatory.

For every completed piece of work report:

```text
WHAT CHANGED

WHY IT CHANGED

WHAT WAS TESTED

HOW IT WAS TESTED

WHAT WAS OBSERVED

WHICH INVARIANT IT ESTABLISHES

WHAT REMAINS UNPROVEN

KNOWN LIMITATIONS
```

Use precise language.

### PROVEN

There is reproducible executable evidence.

### IMPLEMENTED

The code exists and has passed relevant basic validation, but the complete property may not yet be proven.

### TESTED

A test exists and passes, but broader proof may still be required.

### PARTIALLY VALIDATED

Some paths are demonstrated; others remain untested.

### SPECIFIED ONLY

The architecture/documentation describes it, but implementation evidence is insufficient.

### NOT PROVEN

The feature may exist, but the required evidence does not yet establish the claim.

### CONJECTURAL

A proposed future property or architecture, not an implementation fact.

Never use a stronger category than the evidence warrants.

---

# 33. Regression requirements

Before every gate is declared complete:

Run:

```text
full existing test suite
```

plus all new tests.

Also perform:

```text
build
unit tests
integration tests
compatibility tests
failure tests
benchmark/regression tests where applicable
documentation consistency checks
```

No gate completion may knowingly introduce a regression into a previously proven invariant.

---

# 34. Git discipline

Keep changes logically grouped.

Prefer commits structured around:

```text
semantic invariants
ownership model
copy elimination
AMQP interoperability
persistence
security
operations
```

Do not create one enormous opaque commit.

Each commit should leave the repository buildable and testable where practical.

---

# 35. Final programme report

At completion of this programme, produce:

```text
docs/engineering/
    CURRENT_STATE.md
    SEMANTIC_INVARIANTS.md
    OWNERSHIP_AND_MEMORY.md
    GATE_01_SEMANTIC_CORRECTNESS.md
    GATE_02_OWNERSHIP_MEMORY.md
    GATE_03_AMQP_INTEROPERABILITY.md
    GATE_04_PERSISTENCE.md
    GATE_05_SECURITY_ISOLATION.md
    GATE_06_OPERATIONS.md
    FINAL_ENGINEERING_ASSESSMENT.md
```

Use the repository's existing naming/versioning conventions if equivalent documents already exist. Do not duplicate documents unnecessarily; update existing canonical documents when appropriate.

The final assessment must include:

```text
architecture maturity
semantic maturity
implementation maturity
test maturity
memory/ownership maturity
AMQP maturity
RabbitMQ interoperability
persistence
security
operations
performance
known defects
known limitations
unproven claims
next recommended work
```

---

# 36. Absolute completion criterion

This programme is NOT complete because:

```text
the code compiles
```

It is NOT complete because:

```text
the happy path works
```

It is NOT complete because:

```text
benchmarks look good
```

It is NOT complete because:

```text
the documentation says it works
```

It is complete only when the repository contains sufficient executable evidence to support the claims being made about Hyrx.

The final question is:

> **Can an independent engineer reproduce the evidence and determine exactly what Hyrx guarantees, what it does not guarantee, and where the remaining risks are?**

If the answer is yes, the programme has succeeded.

---

# Strategic endpoint

The purpose of this work is not merely to make HyrxMQ a better RabbitMQ-compatible broker.

The architectural objective is to mature:

```text
                    Hyrx
                      │
              semantic substrate
                      │
        ┌─────────────┼─────────────┐
        │             │             │
     embedded       local        network
        │             │             │
        └─────────────┼─────────────┘
                      │
                HyrxMQ / AMQP
```

into a trustworthy **semantic messaging and event-execution substrate**.

HyrxMQ is one manifestation of that substrate.

Protect that distinction.

Do not allow AMQP compatibility requirements, transport details, persistence implementation or product management concerns to contaminate Hyrx Core's semantic model.

The immediate objective is therefore:

```text
SEMANTICALLY COHERENT
        ↓
MEMORY-SOUND
        ↓
EXTERNALLY INTEROPERABLE
        ↓
RECOVERABLE
        ↓
SECURE
        ↓
OPERABLE
        ↓
TRUSTWORTHY HYRX
```

Only after these foundations are established should the project seriously investigate the next architectural frontier:

```text
distributed Hyrx
        ↓
Hyrx semantic fabric
        ↓
cross-process / cross-machine execution
```

That future work must be derived from the proven invariants established here, not invented independently of them.
