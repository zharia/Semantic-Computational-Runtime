# 013 — Manifestation and Representation Boundary

## Fundamental separation

The architecture must preserve:

```text
Semantic Meaning
    ≠
Formal Representation
    ≠
Implementation Representation
    ≠
Physical Manifestation
```

## Representation

Representation is an encoding that preserves a defined semantic contract.

## Manifestation

Manifestation is the physical realization of semantic structure/behaviour.

## Projection

Where implementation state contains extra information:

`pi : IState -> S`

may provide the semantic projection.

## Refinement

Define when implementation behaviour refines semantic behaviour.

## Provider correctness

A provider is conforming when its observable behaviour satisfies the semantic contract.

Provider implementation details are not semantic authority.

## Compiler correctness

Compilation/lowering is correct when the resulting representation preserves the required semantic contract.

Parsing/verification alone is not proof of semantic preservation.

## Metadata

Metadata preservation must be treated separately from executable semantic equivalence.

Do not claim arbitrary metadata survives a lowering boundary unless that boundary is explicitly tested.

## Provenance

Define provenance as either:

- semantic metadata;
- formal artifact metadata;
- execution metadata.

Do not conflate these categories.

## Manifestation independence

Different manifestations may be semantically equivalent even when:

- memory layout differs;
- scheduling differs;
- hardware differs;
- provider differs;
- representation differs;
- execution duration differs.
