# SID-001: Concrete Semantic Identity Coordinate Architecture & Production Carrier

**Sprint:** 004_SID-001  
**Predecessor:** 003_SID-001 (IAM-001 Verification Closure & Readiness Gate — Verdict: `READY FOR SID-001`)  
**Repository:** `Semantic-Computational-Runtime`  
**Target Area:** `lib/101_Core/Identity/`  
**Production Carrier Crate:** `lib/101_Core/Identity/301_Implementation/rust/` (`scr-identity`)  
**Status:** In Execution  

---

## 1. Context & Motivation

Sprint `003_SID-001` closed the reference model phase of IAM-001, verifying through bounded model exploration ($N=8$), 28 adversarial scenarios, 8 recovery resilience checks, and deep temporal trace exploration that:
1. Root uniqueness, domain disjointness, domain containment, and allocation injectivity hold.
2. The remediated recovery consistency model (`IAM-R017` / `IAM-I017`) eliminates orphaned allocations across snapshot restores.
3. Transaction non-rebinding (`IAM-R018`) guarantees idempotence without allowing coordinate cross-binding.
4. Autonomous Multi-Root Identity (Model B, `IAM-R019`) scopes identity without polluting internal coordinate bits: $\text{GlobalIdentity} = (\text{RootAuthorityId}, \text{SidCoordinate})$.
5. The SCR Architectural Review issued the authoritative gate verdict: **`READY FOR SID-001`**.

This sprint implements the concrete production carrier crate `scr-identity` under `lib/101_Core/Identity/301_Implementation/rust/`.

---

## 2. Concrete Coordinate Geometry

The concrete `SID-001` coordinate geometry provides:
1. **Multi-Root Scoped Identity**:
   ```rust
   pub struct GlobalIdentity {
       pub root: RootAuthorityId,
       pub coordinate: SidCoordinate,
   }
   ```
2. **Canonical Coordinate Geometry**:
   A compact, 128-bit coordinate structure:
   - `domain_id`: 64-bit integer specifying the hierarchical allocation domain partition.
   - `index`: 32-bit integer specifying the allocated sequence or coordinate offset within the domain's declared range.
   - `generation`: 32-bit integer specifying the active authority generation at commitment time.
3. **Representational Mappings**:
   - High-throughput value representation: `u128` (packed `domain_id[64] | index[32] | generation[32]`).
   - Human-readable canonical URI: `sid://<root_id>/<domain_id>/<index>?gen=<generation>`.
   - String display and parsing conforming to standard formats.
4. **Layer Decoupling**:
   - $\text{Identity} \neq \text{Representation}$
   - $\text{Identity} \neq \text{Binding}$
   - $\text{Identity} \neq \text{Manifestation}$
   - Coordinates remain invariant while runtime handles (buffers, actor IDs, pointers) are dynamically updated.

---

## 3. Normative State Machine Engine (`IAMMachine`)

Implements the formal transition system $T: \Sigma \times \text{Event} \to \Sigma \cup \{\text{Error}\}$:
- $\Sigma = (I, D, A, H, P, B, M, Q)$
- Enforcing all 17 normative invariants (`IAM-I001` .. `IAM-I017`).
- Native support for snapshotting and crash recovery with complete carry-forward of $(P, D, B, M)$ for all $s \in H$.
- Canonical projection into the `scr-hypergraph` dialect.
