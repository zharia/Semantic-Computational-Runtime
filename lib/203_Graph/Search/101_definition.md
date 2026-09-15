# Search

**Directory:** `lib/203_Graph/Search`

**Documentation role:** Semantic search definition and GQL query specification

## 1. Purpose

The Search domain defines the query language and search mechanisms for the SCR semantic library. It specifies:

- **GQL (ISO/IEC 39075:2024)** as the standard query language for graph data
- **Search operations** over the hypergraph semantic model
- **Query translation** from GQL to MLIR scr dialect operations
- **Search result semantics** and well-formedness conditions

The Search domain bridges human-readable query specifications (GQL) with machine-executable representations (MLIR operations) and formal verification (Lean).

## 2. GQL Standard (IEC 39075:2024)

GQL (Graph Query Language) is the ISO standard for querying property graphs. In the SCR context:

| GQL Feature | SCR Equivalent | MLIR Representation |
|---|---|---|
| `MATCH` pattern | `scr.match` operation | MLIR operation with pattern matching |
| `FILTER` conditions | `scr.constraint.validate` | Op verifier checks |
| `RETURN` projection | `scr.observe_node` / projection ops | MLIR result types |
| `WITH` clauses | `scr.make_context` | Context management |
| `UNWIND` | `scr.add_node` / node expansion | Hypergraph expansion |

## 2. Lean-Lang Definitions

The Lean 4 formalization of Search provides machine-checked verification of:

| Concept | Lean Definition | Invariant |
|---|---|---|
| `GQL Pattern` | `lean_hypergraph.GQLPattern` | Pattern syntax validation |
| `Query Result` | `lean_hypergraph.QueryResult` | Result well-formedness |
| `Search Invariant` | `lean_hypergraph.SearchInvariant` | Semantic preservation |
| `GQL Translation` | `lean_hypergraph.GQLTranslation` | Translation correctness |

**Key Lean definitions:**

```lean
-- GQL pattern syntax
structure GQLPattern :=
  pattern: String
  | variables: List String
  | constraints: List Constraint

-- Search query
structure Query :=
  pattern: GQLPattern
  | parameters: List Value
  | result_type: Type

-- Search result
structure QueryResult :=
  success: Bool
  | data: List Value
  | errors: List String

-- Well-formedness predicate
def is_valid_query (q : Query) : Bool :=
  -- GQL syntax validation
  -- Type correctness
  -- Constraint satisfaction
```

## 3. MLIR Definitions

The MLIR scr dialect provides search operations translated from GQL:

| GQL Construct | MLIR Op | MLIR Type |
|---|---|---|
| `MATCH pattern` | `scr.match` | `(!scr.hypergraph, !scr.pattern) -> !scr.results` |
| `FILTER condition` | `scr.validate` | `(!scr.constraint) -> !scr.bool` |
| `RETURN projections` | `scr.project` | `(!scr.results, !scr.values) -> !scr.results` |
| `START node` | `scr.make_node` | `(!scr.pattern) -> !scr.entity` |

**MLIR search operations** (`lib/203_Graph/IR/mlir/SCR.td`):

```lean
def scr.MatchOp : Op<SCR_Dialect, "match", [NotPure]> {
  let pattern = "scr.match"
  let pattern_body = "MATCH ... RETURN ... FILTER ..."
  let pattern_inputs = "MATCH (n) WHERE ... RETURN n"
  let pattern_results = "OUT ... n"
}

def scr.ValidateOp : Op<SCR_Dialect, "validate", [NotPure]> {
  let condition = "scr.validate"
  let condition_body = "WHERE ... FILTER ..."
}

def scr.ProjectOp : Op<SCR_Dialect, "project", [NotPure]> {
  let projections = "PROJECT ... RETURN ..."
}
```

## 3. Search Semantics

### 3.1 Query Execution

1. **Parse** GQL query text
2. **Translate** to MLIR scr dialect operations
3. **Verify** MLIR operations (type checks, verifiers)
4. **Execute** MLIR operations over hypergraph state
5. **Project** results into query result format
6. **Return** query result with well-formedness guarantees

### 3.2 Well-Formedness Conditions

A query is well-formed if:

- GQL syntax is valid per IEC 39075:2024
- All pattern variables are bound
- All constraint checks pass
- Result types are consistent
- No dangling references in results

### 3.3 Search Invariants

- **Semantic Preservation**: Query results preserve semantic meaning from the hypergraph
- **Type Safety**: Result types match declared query return types
- **Completeness**: All matching entities/nodes are included in results
- **Soundness**: No spurious results included

## 4. Search Operations

### 4.1 Core Search Operations

| Operation | GQL Equivalent | MLIR Op | Moji Function | Well-Formedness |
|---|---|---|---|---|
| `match` | `MATCH pattern` | `scr.match` | `search.match` | Pattern variables bound |
| `filter` | `FILTER condition` | `scr.validate` | `search.filter` | Constraints satisfied |
| `return` | `RETURN projections` | `scr.project` | `search.project` | Types consistent |
| `start` | implicit node expansion | `scr.make_node` | `search.start` | Node exists |

### 4.2 Search Result Format

```lean
structure SearchResult :=
  success: Bool
  results: List Entity
  errors: List String
  metadata: SearchMetadata

structure SearchMetadata :=
  query_id: String
  execution_time: Nat
  expanded_nodes: Nat
  constraints_checked: Nat
```

## 5. Search Invariants

The following invariants are normative:

- **SRCH-INV-001**: Query results preserve semantic meaning from the hypergraph
- **SRCH-INV-002**: Type safety - result types match declared return types
- **SRCH-INV-002**: Completeness - all matching entities/nodes are included
- **SRCH-INV-003**: Soundness - no spurious results included
- **SRCH-INV-004**: Type safety - result types match declared query return types
- **SRCH-INV-005**: Constraint satisfaction - all GQL FILTER constraints pass
- **SRCH-INV-006**: No dangling references - all entity references in results exist in the hypergraph

## 5. Search Providers

Search queries may be executed against:

- **MLIR-based execution**: `scr-opt --search-query` 
- **Moji kernel**: `search.execute` in the semantic kernel
- **External GQL engine**: Translated and executed via external GQL parser
- **Hybrid execution**: Combination of MLIR and Moji execution

## 6. Search Testing

Search queries are tested via:

- **GQL syntax validation**: Invalid GQL rejected with appropriate errors
- **Well-formedness checks**: Query structure validated against hypergraph schema
- **Execution tests**: Queries executed against known hypergraph states
- **Result verification**: Results verified against expected semantic outcomes
- **Property-based testing**: Random query generation and semantic verification

---

## 6. Relationship to Other Domains

- **Search ⇄ Hypergraph**: Search operates over the hypergraph semantic model
- **Search ⇄ MLIR**: GQL queries translated to MLIR scr dialect operations
- **Search ⇄ Moji**: Search queries executed via Moji kernel
- **Search ⇄ 101_Core**: Search functions conform to 101_Core conceptual requirements
- **Search ⇄ GQL**: GQL is the human-readable query language; SCR provides machine-executable translation

---

## 7. Search Versioning

| Component | Version | Updated |
|---|---|---|
| GQL Standard | ISO/IEC 39075:2024 | Fixed |
| MLIR scr dialect | v0.2.0 | v0.2.0 |
| Moji scr_kernel | v0.0.1 | v0.0.1 |
| Search domain | v0.1.0 | 2026-09-16 |

---

## 8. Search Implementation Notes

- GQL queries are first parsed for syntax validity
- Valid queries are translated to MLIR scr dialect operations
- MLIR operations are verified via per-op verifiers and cross-op invariants
- Verified MLIR operations are executed via the Moji semantic kernel
- Results are projected into the SearchResult format
- All search execution preserves semantic well-formedness

---

## 8. Search Future Extensions

- **Pattern matching extensions**: Extended GQL pattern syntax
- **Optimization**: Query optimization and reordering
- **Parallel execution**: Parallel query execution across hypergraph regions
- **Incremental search**: Incremental results for incremental graph updates
- **External GQL engine integration**: Integration with third-party GQL parsers/executors
- **Search result caching**: Caching of frequently executed queries

---
