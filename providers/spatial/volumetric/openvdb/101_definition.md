# openvdb Provider

**Provider ID:** openvdb
**Domain:** spatial
**Subdomain:** volumetric
**Status:** Seeded

## Purpose

This directory defines the SCR integration of the `openvdb`
implementation as a Provider for the `spatial/volumetric`
semantic capability area.

## Provider Role

The Provider supplies a concrete implementation of one or more
SCR semantic capabilities through the applicable Normative Provider
Contracts.

The Provider is not the semantic authority.

Semantic meaning is defined by the corresponding SCR semantic library
under `lib/`.

Provider architecture is governed by:

`docs/architecture/102_provider_architecture.md`

Normative Provider Contracts are governed by:

`docs/architecture/103_provider_contracts.md`

## Required Work

Before this Provider can be considered operational:

1. Identify the semantic capabilities supplied.
2. Identify the applicable semantic contracts.
3. Define the Provider identity and provenance.
4. Define the supported versions.
5. Define implementation bindings.
6. Define adapters where required.
7. Declare resources and platform requirements.
8. Declare fidelity and numerical semantics where applicable.
9. Declare determinism and lifecycle behaviour.
10. Implement conformance tests.
11. Validate Provider Contract conformance.
12. Register the Provider with EGS.

## Provider Isolation

No provider-specific types, classes, terminology, or ontology may
be promoted into the SCR semantic library merely because they exist
in this implementation.

Provider-specific concepts remain here unless they are explicitly
promoted into the semantic layer through the Provider Promotion rules.

## Status

This directory was created by the SCR provider seeding process.

It is not evidence that the Provider is implemented or conformant.
