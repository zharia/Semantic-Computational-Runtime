# Milestone 005 — FAIL-CLOSED CLOSURE AND VERIFICATION REPAIR

## Authority

You are operating on the existing Semantic Computational Runtime repository.

Milestone 005 is **NOT ACCEPTED** in its current state.

Do not interpret the existing `Status: COMPLETE` in `program_increments/v0.0.1/reports/005/verification_report_milestone.md` as authoritative. The repository evidence, not the report's declaration, determines milestone completion.

The purpose of this instruction is to **close the actual remaining semantic and verification gaps in Milestone 005 and nothing broader**.

Do not begin a new architectural milestone.

Do not redesign SCR.

Do not introduce speculative abstractions.

Do not weaken, reinterpret, remove, or defer an acceptance requirement in order to obtain PASS.

---

# 1. NON-NEGOTIABLE OPERATING RULE

You are not permitted to decide that Milestone 005 is complete.

Completion is determined exclusively by executable/formal acceptance evidence.

The final state MUST satisfy:

```text
implementation
    ↓
formal verification
    ↓
representation verification
    ↓
lowering
    ↓
native execution
    ↓
differential verification
    ↓
automated acceptance gate
    ↓
independent re-run
    ↓
report generated from evidence
    ↓
automated acceptance gate AGAIN
    ↓
clean repository
    ↓
COMPLETE
```

If any required gate fails:

```text
FAIL
  ↓
continue implementation
  ↓
rerun complete acceptance
```

There is no valid state called:

* COMPLETE WITH LIMITATIONS
* COMPLETE EXCEPT FOR...
* COMPLETE WITH FUTURE WORK
* COMPLETE BUT DEFERRED
* PROVISIONALLY COMPLETE
* COMPLETE AT IMPLEMENTATION LEVEL
* COMPLETE FOR THE CURRENT WITNESS

For Milestone 005, a required property is either demonstrated or it is not.

---

# 2. CURRENTLY IDENTIFIED DEFECTS

The current report contains the following contradiction:

```text
Status: COMPLETE
```

while also stating that:

```text
constraint violation semantics
```

are not formalised in Lean and are deferred to a future milestone.

That is unacceptable because the stated objective of 005 is:

> Resolve every outstanding architectural, semantic, representation, verification, and documentation issue identified in Milestone 004 and establish a fully verified semantic-to-executable representation path.

The current report also contains this verification row:

```text
Constraint Failure | Lean: - | Mojo: PASS | RE: PASS |
MLIR Rep: PASS | Lowered Exec: PASS | Differential: PASS
```

The `PASS` values must not remain unless the underlying evidence actually demonstrates the property at those boundaries.

The current differential evidence demonstrates successful values:

```text
single entity = 10
multi entity c1 = 8
multi entity c2 = 8
```

but does not execute and compare a constraint-failure case.

The current MLIR constraint representation uses conditional execution/no-store behaviour. That must not be called semantic failure unless the representation actually exposes the required semantic distinction.

These defects must be repaired.

---

# 3. FIRST PRINCIPLE: PRESERVE THE EXISTING SEMANTIC CONTRACT

Do not silently change the semantic model merely to make the implementation convenient.

The existing contract is:

```text
Entity Definition = type_id + value_schema
Entity Instance   = identity + definition_type + values
Transformation    = Context × State → State
Constraint        = State → Bool
Observation       = non-mutating read
SemanticTime      = non-decreasing semantic step
```

If the existing `Transformation = Context × State → State` model is insufficient to represent a semantically observable constraint failure, determine the **smallest mathematically correct extension** required to model failure.

Do not pretend that:

```text
failure = unchanged state
```

unless the semantic model explicitly represents failure as an observable outcome.

The required distinction is:

```text
successful no-op:
    success
    state unchanged
    semantic time advances according to the contract

constraint violation:
    failure
    state unchanged
    semantic time does NOT advance according to the existing contract
```

These outcomes MUST remain distinguishable.

---

# 4. LEAN: FORMALISE THE ACTUAL FAILURE SEMANTICS

Extend the Lean model minimally so that non-trivial constraints and their failure semantics are represented formally.

Do NOT merely add a theorem about the existing trivial constraint:

```text
v = v
```

That does not establish constraint-failure semantics.

The Lean model must contain enough structure to express at least:

```text
valid constraint
invalid constraint
successful transformation
constraint failure
state preservation on failure
semantic-time preservation on failure
successful no-op distinct from failure
```

The formal model MUST support a witness where the constraint can actually fail.

Then prove the relevant properties.

At minimum, establish formal results equivalent to:

```text
constraint_failure_preserves_state
constraint_failure_preserves_time
successful_noop_is_not_failure
successful_noop_obeys_time_transition
```

Use the repository's existing semantic vocabulary and architecture. Do not create an unrelated mini-framework.

The exact Lean representation is your implementation decision, but the semantics are not.

---

# 5. MOJO / RE: ALIGN IMPLEMENTATION WITH THE FORMAL MODEL

The existing Mojo and Reference Executor tests already distinguish:

```text
constraint violation:
    raises
    state unchanged
    time unchanged

successful no-op:
    no raise
    state unchanged
    time advances
```

Retain this behaviour.

Where necessary, refactor the implementation so that its semantic result corresponds explicitly to the formal model.

Do not merely rely on an exception as an informal semantic mechanism if the formal model establishes an explicit result/outcome abstraction.

The Reference Executor remains the semantic oracle.

Mojo remains the primary implementation.

Neither is permitted to silently define semantics that Lean does not model.

---

# 6. MLIR: REPRESENT FAILURE, NOT A NO-OP

The current representation:

```text
constraint
    ↓
scf.if
    ├── valid → transform
    └── invalid → no store
```

is not automatically equivalent to:

```text
constraint violation → semantic failure
```

A no-store branch is only sufficient if the representation ALSO exposes the semantic outcome required by the contract.

The MLIR representation must therefore make the distinction machine-observable.

The representation MUST support something equivalent to:

```text
success(state', time')
failure(state, time)
```

or another formally equivalent representation.

The precise MLIR mechanism is deliberately left open.

Use standard MLIR mechanisms where they are sufficient.

Do NOT introduce a custom SCR dialect merely to make the implementation convenient.

A custom dialect is permitted only if, after analysis, standard MLIR cannot preserve the required semantic property or boundary.

If standard MLIR is sufficient, use standard MLIR.

---

# 7. EXECUTABLE FAILURE WITNESS

Create an executable MLIR witness in which the constraint actually fails.

The executable path must demonstrate:

```text
semantic source
    ↓
MLIR representation
    ↓
MLIR verification
    ↓
lowering
    ↓
LLVM IR
    ↓
native executable
    ↓
observable failure outcome
```

The failure MUST NOT be inferred from absence of a state write.

The executable must provide an observable result sufficient to distinguish:

```text
SUCCESS + unchanged state
```

from:

```text
FAILURE + unchanged state
```

and must preserve the semantic-time distinction.

The witness should be minimal.

Do not expand the workload unnecessarily.

---

# 8. DIFFERENTIAL FAILURE TEST

Extend the existing differential verification.

It MUST execute at least these cases:

### Case A — successful transformation

Expected:

```text
success
expected state
expected semantic time
```

### Case B — successful no-op

Expected:

```text
success
unchanged state
time advances according to contract
```

### Case C — constraint violation

Expected:

```text
failure
state unchanged
time unchanged
```

The Reference Executor and executable MLIR path must produce semantically equivalent outcomes.

The comparison MUST include the outcome class.

Therefore this is insufficient:

```text
RE value == MLIR value
```

The comparison must establish something equivalent to:

```text
RE outcome == MLIR outcome
RE state   == MLIR state
RE time    == MLIR time
```

where applicable.

A test that merely checks that both executions leave the value unchanged does NOT prove failure equivalence.

---

# 9. FORMAL → IMPLEMENTATION → MLIR TRACEABILITY

For the constraint-failure witness, establish a concrete trace:

```text
Lean semantic definition/theorem
        ↓
Mojo semantic implementation
        ↓
Reference Executor behaviour
        ↓
MLIR representation
        ↓
lowered representation
        ↓
native executable behaviour
        ↓
differential test
```

Document the exact artifact and test corresponding to each boundary.

No generic statement such as:

> "This is preserved"

is sufficient.

Each preservation claim must identify evidence.

---

# 10. PROVENANCE: STOP OVERCLAIMING

The current report claims that provenance survives LLVM lowering merely because provenance exists as an MLIR attribute.

That claim must be corrected unless it is actually demonstrated.

Distinguish these properties:

```text
A. provenance exists in canonical MLIR
B. provenance survives MLIR transformations
C. provenance exists in lowered MLIR
D. provenance survives translation to LLVM IR
E. provenance is retained in native executable metadata
```

These are different claims.

Only claim the levels that are actually demonstrated.

If the project requires provenance only as an artifact-level property, establish that explicitly and verify it at the relevant artifact boundaries.

Do not claim native executable provenance unless it is actually machine-checked.

Do not remove provenance merely to avoid the verification requirement.

Correct the documentation to match the demonstrated boundary.

---

# 11. RELATIONSHIP, IDENTITY, CONTEXT, TIME

Do not create unnecessary new architecture.

Re-check the existing 005 evidence for:

* identity independence
* entity definition
* entity instance
* relationship representation
* semantic time
* context
* observation
* multiple entities

For each property, determine whether the current evidence actually proves what the report says it proves.

In particular:

```text
metadata exists
```

is not automatically equivalent to:

```text
semantic property is preserved
```

If a relationship is intentionally declarative metadata, that is acceptable only if the semantic contract defines it as such.

Then verify preservation of that declaration.

Do not claim that a relationship participates computationally if it does not.

Likewise:

```text
function name != semantic identity
memref != semantic state
index != SemanticTime
```

must remain explicit.

---

# 12. BUILD A MACHINE-CHECKABLE ACCEPTANCE GATE

Create or update a repository-local acceptance command/script for Milestone 005.

The acceptance gate MUST fail if ANY required criterion fails.

It must execute, as appropriate:

1. Lean build.
2. Lean theorem/test suite.
3. Mojo semantic kernel tests.
4. Reference Executor tests.
5. Mojo/RE equivalence tests.
6. canonical MLIR parse/verification.
7. MLIR lowering.
8. LLVM translation.
9. native compilation.
10. successful executable witness.
11. successful no-op executable witness.
12. constraint-failure executable witness.
13. differential comparison against Reference Executor.
14. representation/provenance verification at the boundaries actually claimed.
15. repository consistency checks.
16. final documentation consistency checks.

The gate MUST return a non-zero exit status for failure.

Do not make the report itself the acceptance mechanism.

Do not manually mark checkboxes.

Do not allow the agent to override the gate.

Do not allow a failed subtest to be converted into a warning.

---

# 13. ACCEPTANCE GATE MUST TEST THE SEMANTIC FAILURE CASE

This is mandatory.

The acceptance command must fail if the constraint-failure witness is absent.

It must fail if:

```text
failure is represented only as unchanged state
```

without an observable failure outcome.

It must fail if:

```text
successful no-op
```

and:

```text
constraint failure
```

cannot be distinguished.

It must fail if state changes on failure.

It must fail if semantic time advances on failure when the contract says it must not.

It must fail if the Reference Executor and executable MLIR disagree.

---

# 14. DO NOT MODIFY THE ACCEPTANCE CRITERIA TO MAKE THEM PASS

This is a hard prohibition.

You may modify implementation, tests, formalisation, representation, tooling, and documentation.

You may NOT:

* delete a failing requirement;
* weaken a requirement;
* redefine PASS;
* mark an unverified property as implementation-only;
* move a required property to a future milestone;
* declare a property outside scope;
* remove a test because it fails;
* alter expected results to match incorrect behaviour;
* change the semantic contract merely to make the implementation pass.

If an existing requirement is genuinely inconsistent with the higher-level SCR specification, stop and resolve that inconsistency explicitly against the authoritative specification.

Do not silently choose the easier interpretation.

---

# 15. REPORTS ARE GENERATED LAST

Do not edit the final 005 verification report to say COMPLETE until the acceptance gate has passed.

The correct order is:

```text
repair
↓
run acceptance gate
↓
fix failures
↓
run acceptance gate
↓
when PASS:
    generate/update report from actual results
↓
run acceptance gate AGAIN
↓
verify report itself does not contain unsupported claims
↓
run acceptance gate AGAIN
↓
final clean-tree verification
```

The report must be an output of the verification process, not an input to it.

---

# 16. REPORT REQUIREMENTS

The final report MUST contain:

### Status

Exactly one of:

```text
COMPLETE
```

or:

```text
NOT COMPLETE
```

`COMPLETE` is permitted only after the automated acceptance gate passes.

### Evidence

For every semantic property, identify:

```text
semantic definition
formal theorem/test
Mojo test
Reference Executor test
MLIR artifact
lowering evidence
native execution evidence
differential evidence
```

where that layer is required.

### Exact commands

Every acceptance command must be reproducible.

Do not report commands that were not actually executed.

Do not report stale test counts.

Do not report expected results as actual results.

### Failure semantics

The final report must explicitly demonstrate:

```text
successful transformation
successful no-op
constraint failure
```

and explain why they are semantically distinct.

### Provenance

The final report must state exactly which representation boundary has been verified.

No stronger claim.

---

# 17. FINAL INDEPENDENT RE-RUN

After implementation is complete and the report has been written:

1. Start from the repository's actual final state.
2. Run the complete Milestone 005 acceptance gate.
3. Run it a second time.
4. Confirm both runs pass.
5. Confirm all generated artifacts correspond to the current source.
6. Confirm no stale results are being reused.
7. Confirm the Git working tree state.
8. Confirm the final commit/revision.
9. Only then report completion.

If either run fails:

```text
005 = NOT COMPLETE
```

and continue working.

---

# 18. STOP CONDITION

You are finished ONLY when all of the following are simultaneously true:

```text
[ ] Lean formalises non-trivial constraint failure.
[ ] Lean proves failure state preservation.
[ ] Lean proves failure time preservation.
[ ] Lean distinguishes failure from successful no-op.
[ ] Mojo implements the formal semantics.
[ ] Reference Executor implements the formal semantics.
[ ] MLIR represents the semantic outcome explicitly.
[ ] MLIR failure is not merely a silent no-op.
[ ] MLIR lowers successfully.
[ ] Native executable exposes the failure outcome.
[ ] Native failure preserves state.
[ ] Native failure preserves semantic time.
[ ] Successful no-op remains distinguishable from failure.
[ ] Differential testing includes failure.
[ ] Differential testing compares semantic outcome.
[ ] Differential testing compares relevant state.
[ ] Differential testing compares relevant semantic time.
[ ] Identity claims are actually verified.
[ ] Entity claims are actually verified.
[ ] Relationship claims are actually verified at their declared semantic level.
[ ] Context claims are actually verified.
[ ] Observation claims are actually verified.
[ ] Provenance claims do not exceed demonstrated boundaries.
[ ] No unsupported PASS remains in the verification matrix.
[ ] No required item is deferred.
[ ] No required item is marked future work.
[ ] Automated acceptance gate passes.
[ ] Acceptance gate passes a second independent run.
[ ] Final report is generated from actual evidence.
[ ] Acceptance gate passes again after final report generation.
[ ] Repository final state is internally consistent.
```

If even ONE item is false:

**DO NOT REPORT COMPLETE.**

---

# 19. FINAL RESPONSE FORMAT

When the work is genuinely complete, report only:

```text
Milestone 005 is complete.

Acceptance gate: PASS
Independent rerun: PASS
Post-report acceptance: PASS
Lean: PASS
Mojo: PASS
Reference Executor: PASS
MLIR verification: PASS
Lowering: PASS
Native execution: PASS
Differential verification: PASS
Constraint-failure equivalence: PASS
Repository consistency: PASS

Commit: <actual commit hash>
```

If the work is not complete, do NOT manufacture completion language.

Report the failing acceptance criterion and continue implementation.

**Do not ask for permission to continue.**

**Do not stop at the first failure.**

Continue until the complete acceptance gate passes.
