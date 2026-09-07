# Memory and Ownership Model

## Goals

- predictable lifetimes
- low allocation rate
- minimal copying
- cache locality
- bounded memory
- safe concurrent ownership transfer

Mojo's ownership and lifetime model is particularly relevant to this design.

## Proposed primitives

The implementation should investigate:

- `Buffer`
- `BufferView`
- `BufferChain`
- `BufferPool`
- slab allocator
- arena
- ring buffer
- segment
- message envelope
- reference/view types with explicit lifetime rules

Names are provisional; semantics are normative.

## Copy policy

Every copy on a hot path must have a reason.

Instrumentation should expose:

- bytes copied/message
- copies/message
- allocations/message
- deallocations/message
- pooled reuse rate

## Ownership transitions

Document ownership transitions for:

1. producer creates/acquires payload
2. routing acquires delivery ownership
3. queue owns pending delivery
4. consumer receives ownership/view
5. acknowledgement releases/reclaims resources

## Safety rule

Do not bypass Mojo's ownership/lifetime system with unsafe aliases unless the performance benefit is demonstrated and the lifetime contract is formally documented and tested.

## Resource exhaustion

All pools and queues must have explicit capacity behavior.

Exhaustion must result in one of:

- backpressure
- rejection
- blocking where explicitly configured
- controlled failure

Never uncontrolled memory growth.
