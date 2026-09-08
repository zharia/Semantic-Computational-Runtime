# 11 — Control-Plane Files and Derived Artifacts

---

## Control-Plane Files

Where a semantic library directory uses the SCR control-plane model:

```
101_definition.md
102_status.yaml
103_library.graph.json
```

agents must preserve their roles.

A future executable or golden-path specification may additionally exist, for example:

```
104_golden-path.md
```

where applicable.

Do not put mutable implementation status into normative definitions.

Do not put normative semantics into status records.

Do not manually edit generated graph artifacts unless the repository explicitly requires it.

---

## Generated and Derived Artifacts

Before modifying a generated artifact, determine:

```
What generates it?
What is its source?
Is it committed?
Is it reproducible?
What validation checks it?
```

Prefer changing the authoritative source and regenerating the derived artifact.

Do not manually repair a generated artifact while leaving its source inconsistent.
