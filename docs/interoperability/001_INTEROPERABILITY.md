# Interoperability

## 1. Purpose

Interoperability maps external semantic systems and representations into SCR without allowing external implementation models to redefine SCR's semantic authority.

## 2. Adapter model

```text
External system
      ↓
semantic mapping
      ↓
SCR semantic structure
      ↓
provider/runtime
```

## 3. Mapping classes

Mappings may be lossless, lossy-with-bounds, observational, transactional, streaming or bidirectional.

## 4. ABI versus semantics

ABIs define physical calling and data-transfer conventions. They MUST NOT be treated as semantic definitions unless explicitly wrapped by a semantic contract.

## 5. Standards

SCR SHOULD prefer established standards for transport, encoding, messaging, numeric formats and metadata when they satisfy the semantic contract. Standards are incorporated through explicit mappings.

## 6. Foreign types

Foreign types SHOULD retain provenance and conversion metadata where conversion could affect precision, identity, ordering, lifetime or interpretation.
