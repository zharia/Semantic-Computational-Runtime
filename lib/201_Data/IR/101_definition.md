---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-DATA-IR
name: Data MLIR Dialect

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
classification: intermediate-representation
---

# Data MLIR Dialect

> Directory documentation for the current SCR library tree.

**Path:** `lib/201_Data/IR`

**Documentation role:** Repository inventory

## Purpose

This directory is MLIR dialect material for the Data domain.

## Current Contents

The directory currently contains:

- `101_definition.md`

No substantive MLIR dialect implementation was present when this documentation pass was performed.

## Current Role

The directory establishes the MLIR dialect location for Data.

## Relationship to Parent

`IR` is a child of `201_Data` and represents the MLIR dialect scope for the Data semantic domain.

## Relationship to Core MLIR Dialect

This directory defines the MLIR dialect representation for the corresponding semantic domain. SCR represents domain semantics through MLIR dialects, types, operations, attributes, and interfaces. This directory does not redefine or duplicate the Core semantic contract.

## Scope Boundary

This document records the current repository organization. It does not introduce additional domain MLIR semantics beyond those established elsewhere in SCR.

## Notes

The Data MLIR dialect has not yet been independently specified. This directory serves as a structural placeholder for future MLIR dialect development.
