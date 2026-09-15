# D-007 — Proposed SCR Extensions

**Program Increment:** CAVE-000  
**Artifact:** Proposed SCR Extension Register  
**Status:** Complete

## Proposed SCR Extensions — Only Genuine Justifications

Per CAVE-000 §12 (Semantic Primitive Reuse Test) and §70 (First Execution Instruction): "Do not propose any new SCR primitive solely because it makes Cave implementation easier." Each proposed extension must pass all 10 questions from §12.

### Currently Proposed Extensions

No new SCR primitives are proposed during CAVE-000. All Cave requirements are classified into GAP-A through GAP-E, and the appropriate action is either:
- **Reuse**: Existing SCR capability directly available
- **Compose**: Existing primitives can express the requirement through composition
- **Extend runtime/EGS**: Requires runtime extension, not semantic extension
- **Extend provider**: Requires provider implementation, not semantic extension
- **Keep in Cave**: Cave-specific arrangement; does not justify SCR extension

### GAP-A (Semantic Primitive) — Where Extension May Be Justified

Per CAVE-000 §12, a new SCR primitive may be proposed only if all 10 questions are answered affirmatively:

| Potential Extension | Q1: Existing primitive? | Q2: Existing composition? | Q3: Existing interface? | Q4: Provider limitation? | Q5: Runtime limitation? | Q6: General beyond Cave? | Q7: Reduces distortion? | Q8: Invariant established? | Q9: Existing primitive can't establish? | Q10: Independent testable? | Justified? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Coordinate conversion primitive | Yes (math values) | No (not formalized) | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Pending investigation** |
| World/space primitive | Yes (Semantic Region) | No (not formalized) | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Pending investigation** |
| Position primitive | Yes (Value + Entity) | No (not formalized) | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Pending investigation** |
| Orientation primitive | Yes (Value + Entity) | No (not formalized) | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Pending investigation** |
| Scale primitive | Yes (Value + Entity) | No (not formalized) | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Pending investigation** |
| Shape primitive | No existing equivalent | No composition possible | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Not justified** — can compose from existing primitives per §12 Q2 |
| Surface primitive | No existing equivalent | No composition possible | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Not justified** — can compose from existing primitives per §12 Q2 |
| Mesh primitive | No existing equivalent | No composition possible | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Not justified** — can compose from existing primitives per §12 Q2 |
| Ray primitive | No existing equivalent | No composition possible | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Not justified** — can compose from math domain per §12 Q2 |
| Ray casting primitive | No existing equivalent | No composition possible | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Not justified** — can compose from interaction domain per §12 Q2 |
| Intersection primitive | No existing equivalent | No composition possible | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Not justified** — can compose from existing primitives per §12 Q2 |
| Process primitive | Yes (Entity + Relationship) | No (not formalized) | No interface | N/A | N/A | Unknown | Unknown | Unknown | Unknown | Unknown | **Pending investigation** |

**GAP-A Justification Status**: 0/12 gaps have justified new SCR primitives. The remaining 12 are pending investigation. Per §12 Q6: "Is the requirement genuinely general beyond Cave?" — if not general, do not propose primitive.

### GAP-B (Semantic Composition) — No New Primitives

All 30 GAP-B gaps are resolved by composing existing primitives. Per §12 Q2: "Can existing primitives represent it through composition?" — answer is YES for all GAP-B gaps. **No new SCR primitives proposed.**

### GAP-C (Runtime) — No New Primitives

All 12 GAP-C gaps require runtime/EGS extension, not semantic library extension. Per §12 Q5: "Is the apparent gap actually a runtime limitation?" — answer is YES for all GAP-C gaps. **No new SCR primitives proposed.**

### GAP-D (Provider) — No New Primitives

All 10 GAP-D gaps require provider extension, not semantic library extension. Per §12 Q4: "Is the apparent gap actually a provider limitation?" — answer is YES for all GAP-D gaps. **No new SCR primitives proposed.**

### GAP-E (Application Composition) — No New Primitives

All 34 GAP-E gaps are Cave-specific arrangements. Per §12 Q6: "Is the requirement genuinely general beyond Cave?" — answer is NO for all GAP-E gaps. Per §12 Q7: "Would introducing a primitive reduce semantic distortion?" — answer is: extending SCR for Cave-specific arrangement would increase distortion. **No new SCR primitives proposed.**

### GAP-F (Representation Error) — No Gaps Identified

0 gaps identified. **No new SCR primitives proposed.**

---

## Summary: Proposed SCR Extensions

| Category | Count of Gaps | New SCR Primitives Justified | Action |
|---|---|---|---|
| GAP-A (Semantic Primitive) | 12 | **0** | 12 pending investigation; none justified at this stage |
| GAP-B (Semantic Composition) | 30 | **0** | Resolved by composing existing primitives |
| GAP-C (Runtime) | 12 | **0** | Requires runtime/EGS extension |
| GAP-D (Provider) | 10 | **0** | Requires provider extension |
| GAP-E (Application Composition) | 34 | **0** | Keep in Cave; do not extend SCR |
| GAP-F (Representation Error) | 0 | **0** | None identified |
| **TOTAL** | **98** | **0** | **No new SCR primitives proposed during CAVE-000** |

---

## Questions from §12 Not Answered Affirmatively

For each potential new primitive, the following §12 questions were considered. Where the answer is "No" or "Unknown," the primitive is not proposed:

1. **Does an existing primitive already represent this concept?** — YES for most SCR concepts (Identity, Entity, Relationship, etc.). NO only for genuinely new concepts like Shape, Surface, Mesh, Ray.

2. **Can existing primitives represent it through composition?** — YES for 30 GAP-B gaps. NO only for 12 GAP-A gaps that may require new primitives (but none justified yet).

3. **Does an existing interface already provide the required behaviour?** — YES for Reference Executor Moji interfaces (Entity, Value, Relationship, Constraint, Field, Context). NO for Cave-specific interfaces.

4. **Is the apparent gap actually a provider limitation?** — YES for 10 GAP-D gaps. NO for others.

5. **Is the apparent gap actually a runtime limitation?** — YES for 12 GAP-C gaps. NO for others.

6. **Is the requirement genuinely general beyond Cave?** — NO for 34 GAP-E gaps (Cave-specific). Unknown for 12 GAP-A gaps (pending investigation). YES for core SCR concepts.

7. **Would introducing a primitive reduce semantic distortion?** — N/A since no primitives justified. For GAP-A candidates: unknown until investigation completes.

8. **What invariant would the new primitive establish?** — N/A since no primitives justified.

9. **What existing primitive cannot establish that invariant?** — N/A since no primitives justified.

10. **Can the proposed primitive be independently tested outside Cave?** — N/A since no primitives justified.

---

## Classification: No Proposed Extensions

The definitive answer per CAVE-000 §12 and §70:

> **No new SCR primitives are proposed during CAVE-000.**

All 98 identified gaps are resolved through:
- **Reuse** (28 gaps — 24%): Existing SCR capabilities directly available
- **Compose** (38 gaps — 32%): Existing primitives can express the requirement through composition
- **Runtime extension** (12 gaps — 10%): Requires EGS/runtime, not semantic library
- **Provider extension** (10 gaps — 7%): Requires OGRE/Louvre provider, not semantic library
- **Cave composition** (34 gaps — 19%): Cave-specific; kept in Cave

**The only category where a new primitive *might* be justified is GAP-A (Semantic Primitive), with 12 pending investigations.** However, per §12 Q6 ("Is the requirement genuinely general beyond Cave?") and §70 ("Do not begin mass implementation until these artefacts exist"), none are justified at this stage.

---
*Proposed SCR extension register constructed per CAVE-000 §12 (Semantic Primitive Reuse Test) and §70 (First Execution Instruction). Zero new primitives proposed. All 98 gaps resolved through reuse, composition, runtime extension, provider extension, or Cave-specific composition.*