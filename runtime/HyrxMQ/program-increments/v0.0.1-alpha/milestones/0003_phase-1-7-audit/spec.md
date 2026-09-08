# HyrxMQ — Confidence Restoration, Validation & Hardening

## Mission

Before implementing substantial new functionality, perform a rigorous retrospective audit of the current Hyrx/HyrxMQ implementation and strengthen the project wherever necessary to materially increase confidence in:

* architectural correctness
* semantic correctness
* ownership and lifecycle correctness
* transport correctness
* concurrency correctness
* AMQP 0-9-1 correctness
* RabbitMQ interoperability
* failure behavior
* resource boundedness
* security posture
* persistence readiness
* operational correctness
* performance measurement quality
* documentation accuracy
* test validity

This is **not a feature-count exercise**.

The objective is to establish a defensible engineering baseline from which subsequent phases can proceed with high confidence.

Do not assume that an implementation is correct because existing tests pass.

Do not assume that a previous progress report is correct merely because it says something is complete.

Verify claims against the actual repository, source code, tests, toolchain behavior, and observable runtime behavior.

Where something cannot be demonstrated, explicitly mark it:

> **NOT PROVEN**

Do not convert assumptions into claims of completion.

---

# 1. Read the project before changing it

Start by reading the current repository documentation and implementation.

At minimum inspect:

* README
* architecture documentation
* requirements
* implementation plan
* architecture invariants
* decisions / ADRs
* current phase documentation
* testing documentation
* benchmarking documentation
* compatibility documentation
* persistence documentation
* security documentation
* management documentation
* systemd documentation
* current progress reports
* all existing source under `src/`
* all existing tests
* benchmark code
* scripts
* configuration
* CI configuration

Pay particular attention to the architecture established by the project:

```text
                    HyrxMQ
                       │
                AMQP 0-9-1 Adapter
                       │
                  Hyrx Engine
                       │
               Transport Contract
                ┌──────┼──────┐
               UDS     TCP    Direct
```

The intended dependency direction is:

```text
Hyrx Core → HyrxMQ
```

and never:

```text
Hyrx Core → HyrxMQ
Hyrx Core → AMQP
Hyrx Core → TCP
Hyrx Core → simulation
```

The simulation is an external workload and consumer of Hyrx. Hyrx must remain completely independent of simulation-specific concepts.

---

# 2. Establish an independent baseline

Before modifying implementation, run the current project from a clean state.

Record:

* exact Mojo version
* exact build/run commands
* compiler/toolchain configuration
* operating-system/kernel information
* test results
* benchmark results
* warnings
* failures
* skipped tests
* known environment dependencies

Do not silently change the environment to make tests pass.

If the current toolchain differs from documented requirements, record the discrepancy.

Produce a baseline report:

```text
BASELINE

Build:
Tests:
Integration:
Protocol:
Benchmarks:
Systemd:
Toolchain:
Known failures:
Known warnings:
Known assumptions:
```

---

# 3. Audit test validity first

This is a high-priority task.

Previous work identified a concern that some early tests may rely on Mojo `assert` behavior that is not equivalent to runtime validation.

Inspect every existing test.

Determine whether each assertion is genuinely evaluated at runtime.

Where tests can pass vacuously, retrofit them to use an explicit runtime checking mechanism.

For example, establish a consistent project-level mechanism such as:

```text
check(condition, message)
```

or an equivalent runtime assertion facility appropriate to the actual Mojo version.

Do not assume the mechanism.

Verify it experimentally.

Create a deliberate failing test and demonstrate:

```text
failure → non-zero exit
success → zero exit
```

Then migrate vulnerable tests.

### Requirement

No test may be counted as evidence if its assertion mechanism has not been demonstrated to execute at runtime.

Report:

```text
Tests reviewed:
Tests with valid runtime assertions:
Tests repaired:
Tests still uncertain:
```

---

# 4. Re-audit the Hyrx architectural boundary

Perform a source-level dependency audit.

Search the entire repository for:

* AMQP references inside Hyrx Core
* RabbitMQ-specific references inside Hyrx Core
* TCP-specific assumptions inside Core
* socket APIs inside Core
* simulation-specific concepts
* broker-specific concepts that should belong to HyrxMQ
* transport implementation leakage
* protocol framing leakage
* duplicated routing logic
* duplicated message lifecycle logic

The desired conceptual dependency graph is:

```text
Hyrx Core
    ↓
transport contract

HyrxMQ
    ↓
AMQP adapter
    ↓
Hyrx Core
```

Transport providers implement the transport contract.

AMQP translates protocol semantics.

The Hyrx engine remains the authority for:

* routing
* queue state
* message ownership
* delivery semantics
* acknowledgements
* consumer state
* flow control semantics

Do not allow protocol adapters to become alternate routing engines.

### Deliverable

Produce an architecture audit table:

| Boundary          | Expected      | Actual | Status |
| ----------------- | ------------- | ------ | ------ |
| Core → AMQP       | none          |        |        |
| Core → TCP        | none          |        |        |
| Core → simulation | none          |        |        |
| AMQP → Core       | yes           |        |        |
| Transport → Core  | contract only |        |        |
| Broker → Core     | yes           |        |        |

Any violation must either be removed or explicitly justified through an ADR.

---

# 5. Re-audit ownership and message lifecycle

This is one of the most important areas.

Trace a message through the complete lifecycle:

```text
producer
  ↓
message creation
  ↓
routing
  ↓
queue
  ↓
consumer
  ↓
delivery
  ↓
ack / nack / reject
  ↓
release
```

Document ownership at every stage.

Determine:

* who owns the payload
* who owns message metadata
* when ownership moves
* when references are borrowed
* when data is copied
* when data is cloned
* when a message becomes immutable
* when it can be reclaimed
* what happens on failed delivery
* what happens on redelivery
* what happens on disconnect
* what happens when multiple consumers exist

Do not use informal terminology such as "non-owning view" if the implementation actually copies the data.

Specifically inspect the existing `BufferView` design.

If it copies bytes, either:

1. rename it to accurately represent its semantics, or
2. redesign it into a genuinely non-owning view with correctly enforced lifetime rules.

Do not make a terminology change merely for aesthetics; make the API accurately describe ownership.

---

# 6. Validate routing semantics

Review:

* direct exchange
* fanout exchange
* topic exchange
* headers exchange
* bindings
* routing keys
* multiple destinations
* no-route cases
* queue ordering
* consumer selection
* duplicate delivery behavior

Construct explicit tests for:

```text
one publisher → one queue
one publisher → many queues
many publishers → one queue
many publishers → many queues
multiple consumers → one queue
unroutable publish
multiple matching bindings
duplicate bindings
```

Determine whether routing produces:

* copies
* references
* shared immutable payloads
* ownership transfers

Document actual behavior.

Do not call a suspected optimization a measured bottleneck without profiling evidence.

Use terminology such as:

> strongly indicated by implementation inspection

until actual profiling demonstrates a bottleneck.

---

# 7. Validate queue and backpressure semantics

Audit every bounded resource.

At minimum:

* queue depth
* queue bytes
* message size
* consumer count
* unacked messages
* connections
* channels
* exchanges
* bindings
* confirms
* memory
* persistence buffers

For each determine:

```text
limit
failure condition
producer-visible behavior
consumer-visible behavior
message fate
recovery behavior
```

Explicitly test queue exhaustion.

Determine whether publish:

* blocks
* rejects
* drops
* disconnects
* returns an error
* applies flow control

Do not leave this implicit.

Resource boundedness claims must only cover resources that are actually bounded.

---

# 8. Validate concurrency architecture before adding concurrency

The current vertical slice has serialized connection handling.

Do not simply add a global mutex to make it "concurrent."

First determine the intended concurrency model.

Analyze:

* ownership domains
* queue ownership
* exchange ownership
* consumer ownership
* connection ownership
* worker/event-loop boundaries
* lock requirements
* atomic requirements
* contention points
* cache locality
* wakeup behavior

Evaluate candidate models such as:

```text
single event loop
sharded queues
connection-per-worker
queue ownership
work stealing
actor-like ownership
hybrid
```

Choose based on the semantics and expected workload, not fashion.

The design should minimize synchronization on the hot path.

### Required tests

Eventually test:

```text
many producers → one queue
one producer → many consumers
many producers → many queues
many consumers → many queues
connection churn
simultaneous publish/consume/ack
```

Include race/concurrency tooling where supported by the actual Mojo toolchain.

Do not claim concurrency correctness without concurrent execution tests.

---

# 9. Validate real socket behavior

The recent flare-backed implementation has established meaningful evidence for:

* TCP bind
* TCP accept
* UDS operation
* incremental framing
* AMQP-over-TCP
* broker roundtrip

Do not discard that work.

Instead, independently verify it.

Test:

```text
connect
open
declare
publish
route
deliver
ack
disconnect
reconnect
```

over real sockets.

Also test:

* partial frames
* multiple frames in one read
* one frame split over multiple reads
* malformed frames
* oversized frames
* zero-length payloads where legal
* abrupt disconnect
* half-open connection
* peer termination

The transport layer must not accidentally acquire messaging semantics.

---

# 10. AMQP 0-9-1 conformance audit

This is a major confidence gate.

Use the authoritative AMQP 0-9-1 specification and RabbitMQ's machine-readable protocol definition where appropriate.

Do not infer protocol behavior from memory.

Build a compatibility matrix.

At minimum classify every relevant feature as:

```text
SUPPORTED
PARTIALLY SUPPORTED
INTENTIONALLY UNSUPPORTED
NOT IMPLEMENTED
NOT TESTED
```

Do not mark something "compatible" merely because the codec can serialize it.

Separate:

1. protocol encoding correctness
2. protocol state-machine correctness
3. broker semantic correctness
4. RabbitMQ interoperability

These are different claims.

---

# 11. Build real-client interoperability tests

Use at least one genuine AMQP 0-9-1 client implementation.

Prefer clients from more than one ecosystem if practical.

Test:

```text
connect
authenticate
open vhost
open channel
declare exchange
declare queue
bind
publish
consume
deliver
ack
close
reconnect
```

Also test:

* prefetch/QoS
* confirms where implemented
* redelivery
* consumer cancellation
* multiple consumers
* concurrent channels
* connection failure

Record exact client versions.

No generic claim such as:

> AMQP compatible

may be made until actual client interoperability is demonstrated.

---

# 12. RabbitMQ differential testing

Run the same behavioral test suite against:

```text
RabbitMQ reference
HyrxMQ
```

Normalize environmental differences.

Compare:

* connection behavior
* channel behavior
* declarations
* routing
* delivery
* acknowledgement
* rejection
* redelivery
* ordering
* errors
* protocol exceptions
* resource exhaustion behavior

Distinguish:

```text
AMQP requirement
RabbitMQ behavior
RabbitMQ extension
Hyrx deliberate behavior
```

Do not blindly reproduce RabbitMQ behavior when the behavior is an implementation extension rather than an AMQP requirement.

Any intentional difference must be documented.

---

# 13. AMQP negative testing and fuzzing

This is mandatory before claiming protocol maturity.

Test:

* truncated frames
* invalid frame type
* invalid frame end marker
* invalid method
* invalid channel
* invalid state transition
* invalid field types
* malformed field tables
* malformed arrays
* oversized strings
* oversized frames
* invalid lengths
* duplicate/invalid declarations
* unexpected methods
* invalid credentials
* malformed connection negotiation

Fuzz:

* frame decoder
* field-table decoder
* method decoder
* state machine transitions
* configuration parser
* management API inputs

Any:

* crash
* hang
* uncontrolled allocation
* memory corruption
* assertion failure
* state corruption
* connection leak
* resource runaway

is a release blocker unless explicitly reviewed and accepted.

---

# 14. Validate disconnect and failure semantics

Create a failure matrix.

At minimum:

| Failure              | Expected behavior | Tested |
| -------------------- | ----------------- | ------ |
| publisher disconnect |                   |        |
| consumer disconnect  |                   |        |
| broker process crash |                   |        |
| half-open TCP        |                   |        |
| malformed client     |                   |        |
| queue full           |                   |        |
| memory pressure      |                   |        |
| disk full            |                   |        |
| persistence failure  |                   |        |
| forced termination   |                   |        |

For each define:

* message fate
* acknowledgement state
* redelivery behavior
* queue state
* connection state
* persistence state
* recovery behavior

Do not implement behavior merely because it seems reasonable.

Where AMQP/RabbitMQ semantics govern behavior, verify against authoritative documentation or differential testing.

---

# 15. Persistence readiness audit

If persistence is not yet implemented, do not pretend otherwise.

Instead verify that the architecture has not accidentally made persistence impossible.

Audit:

* message identity
* ordering
* ownership
* acknowledgement state
* durable queue state
* exchange/binding topology
* recovery metadata
* replay requirements

Define the required WAL/storage semantics before implementing persistence.

Specify:

```text
ephemeral
buffered durable
flush-bounded durable
strict durable
```

with precise guarantees.

Do not claim durability until crash/recovery tests demonstrate it.

---

# 16. Systemd validation

The systemd unit already contains meaningful hardening.

Now test it on a clean GNU/Linux/systemd environment.

Validate:

* service installation
* dedicated user/group
* startup
* restart
* failure recovery
* shutdown
* signal handling
* journal output
* runtime directory
* data directory
* permissions
* network restrictions
* filesystem restrictions
* `NoNewPrivileges`
* resource controls
* configuration loading

Where supported and appropriate, test:

```text
systemctl start hyrxmq
systemctl status hyrxmq
systemctl restart hyrxmq
systemctl stop hyrxmq
```

Verify the service actually behaves correctly rather than merely parsing as a valid unit.

Document the minimum supported environment.

---

# 17. Configuration audit

The current implementation has limitations around portable Mojo file APIs.

Do not invent a workaround without validating it against the actual toolchain.

Determine the correct project strategy for:

* configuration file loading
* environment variables
* command-line overrides
* defaults
* validation
* secret handling
* reload semantics

Test invalid configuration.

Examples:

```text
unknown field
invalid type
invalid value
missing required value
duplicate field
out-of-range limit
invalid endpoint
invalid permission
```

Configuration validation must fail safely and clearly.

---

# 18. Security audit

Perform a basic threat model.

At minimum consider:

```text
untrusted network client
malformed AMQP client
credential attacker
resource exhaustion attacker
oversized message attacker
connection storm
queue exhaustion
management API attacker
local UDS attacker
filesystem compromise
service privilege escalation
```

Audit:

* TLS boundary
* authentication
* authorization
* vhosts
* management API
* local socket permissions
* resource limits
* filesystem permissions
* systemd sandboxing
* logging of security events
* secret exposure

Do not claim TLS security before TLS exists and has been tested.

---

# 19. Performance measurement must now become empirical

The network path is now real enough to benchmark.

Create a reproducible benchmark suite.

Benchmark at minimum:

```text
Direct Hyrx
UDS
Hyrx TCP
AMQP TCP
AMQP TLS once implemented
```

Use multiple payload sizes, including:

```text
64 B
256 B
1 KiB
4 KiB
64 KiB
```

Measure:

* messages/sec
* bytes/sec
* p50
* p95
* p99
* p99.9
* CPU usage
* CPU/msg
* allocations/msg
* bytes copied/msg
* syscalls/msg
* context switches
* queue depth
* connection count
* routing cost
* codec cost

Do not use a publish-all-then-consume-all benchmark as evidence of steady-state throughput.

Create an interleaved workload:

```text
publish → route → consume → ack
publish → route → consume → ack
...
```

Also create sustained tests with concurrent producers/consumers.

---

# 20. Establish an actual profiling baseline

Do not guess the bottleneck.

Profile representative workloads.

Investigate:

* routing
* queue insertion
* message cloning
* allocation
* copying
* codec
* socket I/O
* synchronization
* wakeups
* scheduler overhead

Use the best profiling tools available on the actual GNU/Linux environment.

Until profiling identifies a bottleneck, phrase conclusions as:

> implementation-level hotspot

or

> strongly indicated bottleneck

rather than:

> measured bottleneck

---

# 21. Investigate the message-copy architecture

The current implementation reportedly clones payloads per destination.

Do not immediately replace this.

First measure:

```text
1 destination
2 destinations
10 destinations
100 destinations
```

with increasing payload sizes.

Determine whether the cost is significant.

Then evaluate alternatives:

### Candidate A

Immutable shared payload + per-delivery metadata.

### Candidate B

Reference-counted shared storage.

### Candidate C

Ownership transfer where only one consumer exists.

### Candidate D

Copy-on-write.

### Candidate E

Current cloning model.

Benchmark them.

Choose based on evidence.

Do not sacrifice semantic simplicity merely to claim zero-copy.

---

# 22. Investigate Buffer / BufferView / ownership APIs

Audit the current buffer implementation.

Determine:

* construction cost
* move behavior
* copy behavior
* deinitialization
* slicing
* views
* pooling
* reuse
* thread safety
* lifetime guarantees

Verify every claimed zero-copy path.

If an API copies bytes, document that fact.

If a true view is introduced, prove its lifetime safety.

Use the actual Mojo ownership/lifetime model rather than approximating it from another language.

---

# 23. Evaluate shared memory only after benchmarking

Do not implement SHM merely because it sounds performant.

First establish:

```text
Direct
UDS
TCP
```

baselines.

Then determine whether SHM can materially outperform UDS for the actual Hyrx workload.

If not, document why SHM remains deferred.

If yes, define:

* ownership
* synchronization
* crash recovery
* stale mappings
* versioning
* security
* memory limits
* NUMA behavior
* process lifecycle

Only then implement.

---

# 24. Review the transport abstraction

Confirm that the transport abstraction remains deliberately small.

The transport layer must answer questions such as:

```text
connect
accept
receive
send
close
address
state
```

It must NOT answer:

```text
publish
consume
ack
route
queue
exchange
```

Those belong above transport.

Confirm that flare remains confined behind the Hyrx transport contract.

Do not let a third-party transport library become a conceptual dependency of the core architecture.

---

# 25. Review the current AMQP delivery implementation

Pay special attention to the existing:

> `basic.consume` → flush pending messages as `basic.deliver`

behavior.

Determine how this behaves with real clients.

Test:

* empty queue
* messages arriving after consume
* multiple messages
* multiple consumers
* acknowledgements
* prefetch
* consumer cancellation
* redelivery
* connection loss
* ordering

A vertical-slice implementation may be sufficient for a milestone, but do not allow it to accidentally become the final delivery architecture.

Document what is currently implemented versus what remains.

---

# 26. Management/control-plane boundary

Verify that management operations do not become part of the hot messaging path.

The intended conceptual separation is:

```text
AMQP data plane
        │
        │
   Hyrx engine
        │
        ├── management state projection
        │
        └── metrics/diagnostics
```

Management may inspect and control the engine, but should not become the engine's routing authority.

Audit future management API design for this property.

---

# 27. Documentation truth audit

After all validation, audit the documentation against the implementation.

Search for statements such as:

* "complete"
* "supported"
* "compatible"
* "production-ready"
* "zero-copy"
* "high performance"
* "concurrent"
* "durable"
* "secure"
* "RabbitMQ compatible"
* "proven"

Every such claim must have evidence.

Replace unsupported claims with precise language.

Use:

```text
IMPLEMENTED
TESTED
FUNCTIONALLY PROVEN
BENCHMARKED
INTEROPERABILITY PROVEN
NOT PROVEN
```

as distinct states.

Do not use "complete" where only implementation exists.

---

# 28. Create a formal confidence matrix

Produce a project-wide matrix:

| Area                  | Implementation | Tests | Evidence | Confidence | Remaining |
| --------------------- | -------------- | ----- | -------- | ---------- | --------- |
| Core                  |                |       |          |            |           |
| Ownership             |                |       |          |            |           |
| Routing               |                |       |          |            |           |
| Queueing              |                |       |          |            |           |
| Backpressure          |                |       |          |            |           |
| UDS                   |                |       |          |            |           |
| TCP                   |                |       |          |            |           |
| Hyrx framing          |                |       |          |            |           |
| AMQP codec            |                |       |          |            |           |
| AMQP state machine    |                |       |          |            |           |
| Real AMQP clients     |                |       |          |            |           |
| RabbitMQ differential |                |       |          |            |           |
| Concurrency           |                |       |          |            |           |
| Persistence           |                |       |          |            |           |
| Failure semantics     |                |       |          |            |           |
| Security              |                |       |          |            |           |
| Systemd               |                |       |          |            |           |
| Management            |                |       |          |            |           |
| Performance           |                |       |          |            |           |
| Fuzzing               |                |       |          |            |           |

Use confidence categories:

```text
HIGH
MEDIUM
LOW
NOT PROVEN
```

Do not assign HIGH merely because tests exist.

---

# 29. Fix findings rather than merely reporting them

For every finding, classify it:

```text
BUG
ARCHITECTURAL DEFECT
TEST DEFICIENCY
DOCUMENTATION DEFICIENCY
MISSING VALIDATION
PERFORMANCE ISSUE
SECURITY ISSUE
TECHNICAL DEBT
INTENTIONAL LIMITATION
```

Fix issues that materially reduce confidence.

Do not create large speculative refactors.

Prefer the smallest change that:

1. improves correctness,
2. improves evidence,
3. preserves architecture,
4. is covered by tests.

---

# 30. Do not introduce speculative architecture

During this audit, do NOT introduce:

* clustering
* consensus
* distributed queues
* federation
* shovel
* AMQP 1.0
* MQTT
* STOMP
* Erlang compatibility
* RabbitMQ plugin compatibility
* simulation-specific abstractions
* unnecessary service decomposition
* GPU acceleration
* speculative microservices

The purpose of this increment is confidence in the existing architecture.

---

# 31. Dependency discipline

Before introducing any dependency:

1. determine whether Mojo provides the capability;
2. inspect the actual installed API/toolchain;
3. inspect Linux facilities;
4. run a minimal experiment;
5. benchmark where performance matters;
6. document the dependency.

Never add a dependency because:

> RabbitMQ uses it.

The project is not an Erlang port.

---

# 32. No guessing rule

This rule is absolute.

If uncertain about:

* Mojo API
* Mojo ownership behavior
* Mojo compiler behavior
* AMQP semantics
* RabbitMQ behavior
* Linux socket behavior
* systemd behavior
* flare behavior
* performance characteristics

then:

```text
1. inspect authoritative documentation
2. inspect the actual installed environment
3. create a minimal experiment
4. execute it
5. record the result
```

Never invent an API.

Never infer protocol behavior from memory when authoritative documentation exists.

Never report a benchmark that was not actually run.

Never report a test as passing if its assertions were not actually evaluated.

---

# 33. Required phase gate

Do not proceed to major new feature implementation until this audit reaches a defensible gate.

The gate is:

```text
ARCHITECTURE
    PASS

CORE SEMANTICS
    PASS

OWNERSHIP
    PASS

TEST VALIDITY
    PASS

TRANSPORT
    PASS

CONCURRENCY
    VALIDATED OR EXPLICITLY DEFERRED WITH EVIDENCE

AMQP
    PROTOCOL VALIDATION PASS

REAL CLIENT INTEROP
    PASS OR EXPLICITLY BLOCKED

RABBITMQ DIFFERENTIAL
    PASS OR EXPLICITLY BLOCKED

FAILURE SEMANTICS
    VALIDATED

SECURITY
    BASELINE VALIDATED

SYSTEMD
    CLEAN-MACHINE VALIDATED

PERFORMANCE
    REPRODUCIBLE BASELINE

DOCUMENTATION
    ACCURATE

SELF-ASSESSMENT
    COMPLETE
```

If a gate is not satisfied, do not conceal it.

---

# 34. Required self-assessment

At the end of the work, answer all of these explicitly.

## Architecture

1. Did I preserve Hyrx independence from the simulation?
2. Did I accidentally make AMQP an internal dependency?
3. Did I accidentally make TCP mandatory inside Hyrx Core?
4. Did I introduce HyrxMQ responsibilities into Hyrx Core?
5. Did I introduce premature distributed-system architecture?
6. Is Hyrx still usable in-process without networking?
7. Is HyrxMQ still a product built around Hyrx rather than the other way around?

## Correctness

8. Which invariants are actually demonstrated?
9. Which are only inferred?
10. Which failure paths remain untested?
11. Are queue and routing semantics deterministic?
12. Are ownership transitions explicit?

## Testing

13. Are all test assertions genuinely runtime assertions?
14. Which previous tests were potentially vacuous?
15. What new negative tests exist?
16. What concurrent tests exist?
17. What fault-injection tests exist?

## Performance

18. What is the measured bottleneck?
19. What is only a strongly indicated hotspot?
20. What are allocations/message?
21. What are copies/message?
22. What are syscalls/message?
23. What is p99 latency?
24. What happens under sustained load?
25. What happens with many producers?
26. What happens with many consumers?
27. What optimization produced a measured improvement?

## Compatibility

28. Which AMQP features are genuinely tested?
29. Which are only implemented?
30. Which RabbitMQ behaviors are demonstrated?
31. Which are inferred?
32. Which features are intentionally different?
33. Has the compatibility matrix been updated?

## Reliability

34. What happens during abrupt disconnect?
35. What happens during process termination?
36. What happens under resource exhaustion?
37. What happens during queue exhaustion?
38. What happens under connection storms?
39. What happens when persistence fails?

## Security

40. Have hostile protocol inputs been tested?
41. Have resource-exhaustion attacks been considered?
42. Has the systemd sandbox been validated?
43. Are credentials and secrets handled safely?

## Documentation

44. Does documentation describe actual behavior?
45. Are unsupported features explicit?
46. Are benchmark claims reproducible?
47. Are all architectural decisions recorded?
48. Are remaining uncertainties visible?

---

# 35. Required final report

Create/update a formal progress report containing:

## Executive Summary

What was reviewed and what confidence changed.

## Baseline

What the project did before the audit.

## Findings

Every significant finding.

## Changes Made

Every implementation/test/documentation change.

## Tests

Exact commands and results.

## Protocol Validation

AMQP results.

## RabbitMQ Differential

Results and discrepancies.

## Interoperability

Real client results.

## Concurrency

Results and limitations.

## Failure Testing

Results.

## Security

Results.

## Systemd

Clean-machine results.

## Performance

Reproducible benchmark results.

## Architecture Audit

Dependency-boundary results.

## Compatibility Matrix

Updated matrix.

## Remaining NOT PROVEN Items

Explicit list.

## Risks

Remaining risks ranked by severity.

## Decisions

New or modified ADRs.

## Self-Assessment

Answer every question from Section 34.

## Recommended Next Phase

Only after completing the audit, recommend the next development increment.

---

# 36. Commit discipline

Keep changes logically separated.

Prefer commits such as:

```text
test: repair runtime assertion validation
test: harden phase 0-3 regression suite
core: clarify message ownership lifecycle
core: correct buffer view semantics
routing: validate multi-destination behavior
queue: define bounded-resource failure semantics
transport: harden socket failure handling
amqp: add negative protocol tests
amqp: add real client interoperability suite
compat: add RabbitMQ differential harness
perf: add interleaved throughput benchmark
perf: add transport benchmark matrix
systemd: validate clean-machine deployment
docs: reconcile implementation status
docs: update compatibility matrix
docs: record confidence audit
```

Do not combine unrelated changes into a single opaque commit.

---

# 37. Final principle

The purpose of this work is not to make the progress report look better.

The purpose is to make the **system itself more trustworthy**.

Therefore:

> **Evidence outranks implementation.**

And:

> **Implementation outranks intention.**

And:

> **Measured behavior outranks speculation.**

And:

> **An explicit NOT PROVEN is better than a false PASS.**

At the end of this increment, HyrxMQ should have a substantially stronger empirical and architectural foundation, with uncertainty made visible rather than hidden.

Only then should the project proceed into the next major implementation phase.
