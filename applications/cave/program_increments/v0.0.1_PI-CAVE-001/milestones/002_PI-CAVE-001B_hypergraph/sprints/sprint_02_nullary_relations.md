# Sprint 02: Nullary Relations & Context Hyperedges

**Parent Milestone:** [Milestone 002: PI-CAVE-001B Semantic Hypergraph](../spec.md)  
**Derived from:** `spec.md` (Section 7)  
**Governing Documents:** [`docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md)  
**Status:** Planned  

---

## 1. Mission

Implement **Nullary Relations** ($\text{arity} = 0$) within the SCR Semantic Hypergraph to formally model ambient environmental context, global field invariants, and desktop-wide physical properties without fabricating artificial entity nodes.

---

## 2. Theoretical Formulation & Architecture

In classical graph theory, edges require at least one or two endpoints. However, in relational mathematics and SCR's hypergraph model:
$$R_0 \subseteq \prod_{i=1}^0 E_i \cong \{()\}$$

A nullary relation is an asserted predicate or ambient state over the entire semantic field $\mathcal{F}$. It is an active hyperedge with **zero endpoints**:
$$\text{endpoints}(e_{\text{null}}) = \emptyset$$

### 2.1 Cave Nullary Relation Applications:
1. **Ambient Gravity Context:**
   $$\text{RelNullaryGravity}(g = -9.81 \, \text{m/s}^2, \text{vector} = (0, -1, 0))$$
   Asserts field-wide downward acceleration for volumetric fluid advection.
2. **Global Illumination Environment:**
   $$\text{RelNullaryAmbientLight}(\text{color} = (0.2, 0.2, 0.25), \text{intensity} = 1.0)$$
   Directs rendering providers (OGRE/OpenGL) on default scene lighting.
3. **Spatial Metric Standard:**
   $$\text{RelNullaryMetricUnit}(\text{unit} = \text{METER}, \text{scale} = 1.0)$$
   Establishes physical distance scaling across independent spatial frames.

---

## 3. Technical Implementation

```mojo
struct NullaryHyperEdge:
    var id: SemanticId
    var relation_type: String
    var parameters: Dict[String, Float64]

    fn is_nullary(self) -> Bool:
        return True

    fn evaluate_context(self) -> FieldContext:
        ...
```

### Verification & Testing Tasks:
1. **Zero-Endpoint Invariance:** Verify that nullary relations execute and mutate field state without requiring dummy target nodes.
2. **Singleton Scope:** Enforce uniqueness for singleton environmental relations (e.g. at most one active gravity relation per desktop field).
3. **Serialization:** Verify round-trip serialization of nullary hyperedges in JSON/MLIR formats.
