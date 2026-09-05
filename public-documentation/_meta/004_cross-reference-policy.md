# Cross-Reference Policy

Public documentation should connect conceptual claims to repository evidence without becoming coupled to unstable implementation details.

## Preferred reference graph

```text
Public Concept
      ↕
Normative Definition
      ↕
Library Domain
      ↕
Implementation
      ↕
Test
      ↕
Example
```

## Linking principles

1. Prefer stable repository paths and semantic document identifiers.
2. Prefer links to domain definitions over source-line links.
3. Link implementation only when it exists and is relevant.
4. Do not create links to hypothetical files merely to make a document appear complete.
5. State when a referenced implementation is proposed or absent.
6. Keep public explanations understandable without following every link.

## Semantic identifiers

Where stable identifiers exist, use them.

A future documentation validator may use semantic IDs to build a traceability graph automatically.

## External links

External dependencies and technologies should link to authoritative project documentation where useful, but external systems must not become the source of SCR's semantic authority.
