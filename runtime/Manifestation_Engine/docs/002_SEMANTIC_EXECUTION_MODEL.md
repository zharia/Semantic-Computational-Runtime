# Manifestation Engine — Semantic Execution Model

## 1. Execution is semantic transformation

Execution is not defined as invocation of a function pointer, process, thread or binary. Those are implementation mechanisms.

The semantic model is:

`execute(n, C, S) → (S', O, E)`

where `n` is an executable semantic node or operation, `C` is execution context, `S` is relevant semantic state, `S'` is resulting semantic state, `O` is observation and `E` is execution outcome.

## 2. Inputs

An execution request may include:

- target semantic identity;
- operation or transformation;
- input semantic values/entities;
- execution context;
- constraints;
- capability requirements;
- consistency requirements;
- temporal requirements;
- observation requirements.

## 3. Resolution phases

The Engine SHOULD conceptually perform:

1. identity resolution;
2. semantic validation;
3. context establishment;
4. capability discovery;
5. authorization;
6. provider candidate discovery;
7. provider selection;
8. representation/materialization planning;
9. resource admission;
10. execution;
11. observation;
12. state commitment;
13. cleanup/release.

These phases MAY be fused or reordered internally only when semantic behavior is preserved.

## 4. Node execution

A node is executable when its semantic definition identifies a valid transformation and its requirements can be satisfied in the current context.

A node does not become executable merely because a provider exists. The provider must satisfy the complete applicable contract.

## 5. Context propagation

Context MUST propagate according to explicit semantics. Hidden process-global state is not a substitute for semantic context.

Context may include authority, temporal scope, transaction scope, lineage, resource policy, precision and consistency requirements.

## 6. Side effects

Side effects MUST be classified. At minimum:

- pure semantic transformation;
- semantic state mutation;
- durable external effect;
- ephemeral physical effect;
- observational effect.

The Engine MUST know which effects require commitment, compensation, acknowledgement or idempotency.

## 7. Ordering

Ordering is semantic when the contract requires it. Otherwise, the Engine may reorder independent work.

An optimization that changes observable ordering where ordering is semantically significant is invalid even if outputs appear otherwise equivalent.

## 8. Concurrency

Concurrency is an execution choice unless explicitly represented semantically. Race freedom and independence MUST be established before parallelization.

## 9. Temporal semantics

The Engine MUST distinguish semantic time from wall-clock execution time.

A provider MAY execute faster or slower without changing semantic time unless wall-clock timing is itself part of the contract.

## 10. Determinism and stochasticity

Deterministic execution requires stable inputs, ordering, relevant provider behavior and random seeds.

Stochastic semantics MUST declare the allowed stochastic contract. Provider substitution is valid only when the substituted stochastic behavior satisfies that contract.

## 11. Cancellation

Cancellation is not equivalent to failure. The semantic contract MUST determine whether cancellation produces:

- no committed state change;
- partial state;
- compensation;
- a cancellation observation;
- an externally visible cancellation event.

## 12. Nested execution

A semantic transformation may invoke other semantic transformations. Nested execution MUST preserve context and capability boundaries and MUST remain traceable.

## 13. Distributed execution

Distribution may be introduced by realization. If distribution changes ordering, consistency, durability or failure semantics, those properties MUST be checked against the contract.
