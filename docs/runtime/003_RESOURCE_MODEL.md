# Runtime Resource Model

## 1. Purpose

The resource model describes physical capacity available to manifest semantic execution.

Resources include CPU cores, vector units, GPUs, accelerators, memory, storage, network links, message brokers and external services.

## 2. Resource abstraction

A resource descriptor SHOULD expose capability, capacity, locality, cost, availability, contention, energy characteristics and supported representations.

## 3. Scheduling

Semantic work is mapped to resources through constraints and policies. A resource MUST NOT become part of semantic identity merely because an implementation currently requires it.

## 4. Placement

Placement MAY be spatial, temporal, affinity-based, topology-aware or adaptive. Migration is permitted where semantic identity and required state are preserved.

## 5. Heterogeneity

Different resources MAY implement the same semantic contract. Provider selection therefore becomes a constrained optimisation problem rather than a fixed implementation binding.

## 6. Failure

Resource failure is an execution event. Recovery semantics must distinguish between reconstructable physical state and irreducible semantic state.
