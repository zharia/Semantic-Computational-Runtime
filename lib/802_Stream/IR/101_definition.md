---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-STREAM-IR
name: Stream MLIR Dialect

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-STREAM

authority: SCR
domain: semantic-library
classification: intermediate-representation
---

# Stream MLIR Dialect

> Directory documentation for the current SCR library tree.

**Path:** `lib/802_Stream/IR`

**Documentation role:** Repository inventory

## Purpose

This directory is MLIR dialect material for the Stream domain.

## Current Contents

The directory currently contains:

- `101_definition.md`

No substantive MLIR dialect implementation was present when this documentation pass was performed.

## Current Role

The directory establishes the MLIR dialect location for Stream.

## Relationship to Parent

`IR` is a child of `802_Stream` and represents the MLIR dialect scope for the Stream semantic domain.

## Relationship to Core MLIR Dialect

This directory defines the MLIR dialect representation for the corresponding semantic domain. SCR represents domain semantics through MLIR dialects, types, operations, attributes, and interfaces. This directory does not redefine or duplicate the Core semantic contract.

## Scope Boundary

This document records the current repository organization. It does not introduce additional domain MLIR semantics beyond those established elsewhere in SCR.

## Notes

The Stream MLIR dialect has not yet been independently specified. This directory serves as a structural placeholder for future MLIR dialect development.
