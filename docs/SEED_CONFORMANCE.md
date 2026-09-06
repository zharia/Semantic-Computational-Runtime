# Seed Conformance Matrix

| Requirement | Artifact | Gate |
|---|---|---|
| Canonical vocabulary | `seed/001_*` etc. | unique IDs |
| Distinctions | `seed/008_distinctions` | no unresolved endpoints |
| Foundational laws | `seed/007_semantic-laws` | mapped to formalization status |
| External evidence | `seed/009_external` | structured metadata |
| Formal mapping | `seed/010_formal/lean-map.yaml` | Lean declarations exist |
| Formal kernel | `SCRFormal/SCR` | `lake build SCRFormal` |
| Derived graph | `seed/103_seed.graph.json` | validation |
| Automated validation | `scripts/check-seed.sh` | exit code 0 |
| Implementation direction | docs/bootstrap | Mojo declared primary |
| Execution baseline | Reference Executor | integration gate in repository |

A passing Seed package is not equivalent to a complete SCR implementation.
