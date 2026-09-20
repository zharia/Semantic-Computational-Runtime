# Sprint 003 Record: Alignment & Provenance

## 1. Semantic Alignment Process

Before defining a new SCR concept:

1. Identify the concept precisely.
2. Identify established terminology in the field.
3. Identify relevant industry standards.
4. Identify relevant mathematical/domain definitions.
5. Identify existing implementations and established practice.
6. Determine whether SCR already contains an equivalent concept.
7. Determine whether competing concepts are actually different semantics or merely different representations.
8. Align with established terminology where appropriate.
9. Define an SCR-specific abstraction only where required for composition, integration, execution, interoperability, formalisation, or a genuine semantic gap.
10. Record provenance.

**Rules:**
- Do not invent terminology merely because an external framework uses different names.
- Do not mechanically copy external framework terminology into SCR.
- Do not assume that an API type represents a semantic primitive.
- Align before inventing. Use existing terms where they exist.

## 2. Provenance Template

Every semantic definition derived from an external standard must record:

```yaml
concept: <SCR concept name>
source: <external system>
source_terminology: <term used in source>
source_authority: <who defines it in source>
scr_interpretation: <how SCR interprets it>
reason_for_alignment: <why aligned>
differences: <what SCR changes>
mapping: <bidirectional mapping if applicable>
provider_implications: <which providers affected>
```

## 3. Example: SCR Entity

```yaml
concept: Entity
source: AzFramework, USD, ROS 2
source_terminology: "AZ::Entity", "USD Prim", "ROS 2 Node"
source_authority: O3DE, USD consortium, ROS 2 consortium
scr_interpretation: >
  A semantic entity is a persistent identity with associated
  components/capabilities. SCR entity identity (SCR SID) is
  authoritative. Provider entity IDs are mappings.
reason_for_alignment: >
  Entity is a universal concept across game engines, scene graphs,
  and robotics. SCR adopts the established term.
differences: >
  SCR entity identity is provider-independent. O3DE EntityId is
  a provider-local identifier mapped from SCR SID.
mapping: >
  SCR SID → O3DE identity mapping → AZ::EntityId
  SCR SID → USD projection → USD Prim path
  SCR SID → ROS 2 projection → ROS 2 entity identifier
provider_implications: >
  All providers must implement identity mapping from SCR SID.
```

## 4. Verification

- 10-step alignment process documented
- Provenance template captures all required fields
- Example demonstrates the template in use
- Rules against terminology invention stated
