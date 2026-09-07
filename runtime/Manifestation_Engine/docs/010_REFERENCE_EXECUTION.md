# Manifestation Engine — Reference Execution

## 1. Purpose

The SCR Reference Executor is the semantic oracle used to establish and test the intended behavior of semantic computation.

It is not the production Manifestation Engine.

## 2. Relationship

```text
Semantic Contract
      ├──────────────► Reference Executor
      │                    │
      │                    └── expected semantic result
      │
      └──────────────► Manifestation Engine
                           │
                           └── physical realization
```

## 3. Oracle rule

If a provider-backed or optimized execution disagrees with the Reference Executor, neither implementation is automatically authoritative. The semantic specification is authoritative.

The discrepancy must be classified and corrected at the incorrect layer.

## 4. Reference provider

The Reference Executor may be exposed as a provider for controlled execution, but its special status as a semantic oracle MUST remain explicit.

## 5. Differential testing

A Manifestation Engine implementation SHOULD support differential tests comparing:

- semantic inputs;
- context;
- resulting semantic state;
- observations;
- errors;
- relevant side effects.

## 6. Limitations

The Reference Executor does not prove that a physical provider is correct merely because it passes a finite test suite. Formal semantic authority and conformance remain separate from implementation coverage.
