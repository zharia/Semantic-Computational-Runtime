# SCR Library Directory Documentation Pass

## Objective

Perform a **documentation-only inventory pass** over the entire:

```text
lib/
```

directory of the Semantic Computational Runtime repository.

The objective is simple:

> **Every directory and subdirectory under `lib/` must contain a `101_definition.md` file that documents what is currently present in that directory.**

This task exists so that the complete semantic-library directory structure is explicitly represented in Git.

This is **not** a specification exercise.

This is **not** an architecture redesign.

This is **not** an implementation task.

This is **not** an attempt to determine what each domain should eventually become.

It is a structured documentation pass over the repository as it exists now.

---

# 1. Governing Principle

The most important instruction is:

> **Document the repository that exists. Do not design the repository that should exist.**

The agent must inspect the actual contents of every directory and write a concise, factual `101_definition.md` describing that directory.

The documentation must be derived from:

1. directory location;
2. directory name;
3. child directories;
4. files present;
5. source code actually present;
6. existing documentation;
7. existing tests/examples where relevant;
8. existing parent/child relationships.

Do not infer functionality merely from names.

Do not invent semantic contracts.

Do not turn an implementation inventory into a normative specification.

---

# 2. Scope

The traversal root is:

```text
lib/
```

The agent MUST recursively traverse the entire tree.

This includes:

```text
lib/
lib/<directory>/
lib/<directory>/<subdirectory>/
lib/<directory>/<subdirectory>/<subdirectory>/
...
```

Every directory encountered must be considered.

The current top-level library contains domains including, but not limited to:

```text
000_meta
101_Core
201_Data
202_Math
203_Graph
301_Field
302_Geometry
303_Topology
401_Morphology
501_Physics
502_Dynamics
503_Simulation
601_Agent
602_Neural
603_Perception
604_Control
701_Optimization
702_Learning
703_Adaptation
704_Evolution
705_Ecology
801_Spatial
802_Stream
901_Analysis
902_Interfaces
903_Lowering
904_Providers
905_Transforms
A01_Render
```

The agent must **not assume that this is the complete hierarchy**.

It must discover the hierarchy from the filesystem.

---

# 3. Required Result

For every directory:

```text
<directory>/
```

create:

```text
<directory>/101_definition.md
```

unless that file already exists.

If a `101_definition.md` already exists:

* inspect it;
* determine whether it already documents the directory adequately;
* do not overwrite good existing documentation unnecessarily;
* update it only when required to bring it into compliance with this inventory-pass standard.

The end state must be:

```text
Every directory under lib/
        │
        └── 101_definition.md
```

This is the primary success criterion.

---

# 4. Important Git Requirement

One purpose of this operation is to ensure that the directory hierarchy is represented explicitly in Git.

Git does not track empty directories.

Therefore, a directory that contains no implementation files may still require:

```text
101_definition.md
```

specifically so that the directory exists as a tracked part of the SCR library structure.

An empty or nearly empty directory is **not** evidence that the directory should be removed.

Document it.

Do not populate it with speculative implementation merely to make the directory appear meaningful.

---

# 5. What `101_definition.md` Means During This Pass

Normally, SCR uses:

```text
101_definition.md
```

as a semantic definition.

For this specific operation, however, the immediate purpose is **directory documentation and inventory**.

Therefore each newly created document should be understood as:

> **A factual description of the current contents and apparent role of this repository directory, based on available evidence.**

It must not establish new normative semantics merely by being created.

Do not use this pass to create:

* new semantic contracts;
* new invariants;
* new interfaces;
* new operations;
* new MLIR operations;
* new type systems;
* new provider contracts;
* new mathematical definitions;
* new architecture;
* new implementation requirements.

Those belong to later specification work.

---

# 6. Required Content of Each Definition

Every `101_definition.md` should contain approximately the following sections.

```markdown
# <Directory Name>

## Purpose

Brief factual description of what this directory currently represents
within the repository.

## Current Contents

Describe the files and child directories currently present.

## Current Role

Describe the apparent role of this directory based on the
repository evidence.

## Relationship to Parent

Explain how this directory fits into its immediate parent directory.

## Child Structure

List the immediate child directories, where applicable.

## Implementation Evidence

Briefly describe the implementation currently present.

## Documentation Status

State whether the directory is:

- populated;
- partially populated;
- minimally populated;
- currently structural/documentary;
- implementation-bearing;
- or otherwise accurately describe its state.

## Scope Boundary

Describe what this directory appears to contain and, where useful,
what belongs to neighbouring directories instead.

## Notes

Record important observations, ambiguities, or limitations.
```

The exact sections may be shortened where they are not meaningful.

Do **not** mechanically fill every section with meaningless text.

---

# 7. Minimum Acceptable Standard

A good `101_definition.md` at this stage does **not** need to be large.

The minimum acceptable document should establish:

1. **what directory is being documented;**
2. **where it sits in the library hierarchy;**
3. **what is currently inside it;**
4. **what its current repository role appears to be;**
5. **whether it currently contains meaningful implementation or is primarily structural;**
6. **any important uncertainty.**

For example, a small directory may legitimately have a definition as short as:

```markdown
# 302_Geometry

## Purpose

This directory contains the current SCR geometry library area.

## Current Contents

The directory currently contains the geometry-related implementation
and subordinate geometry modules present in this repository.

## Current Role

This directory provides the repository location for geometry-related
SCR development.

## Relationship to Parent

`302_Geometry` is a child of `lib/` and belongs to the structural
geometry portion of the SCR library hierarchy.

## Current State

The directory currently contains implementation/documentation at the
level observed during this documentation pass.

## Scope Boundary

This document records the current repository structure. It does not
define the future geometry semantic contract.

## Notes

The semantic scope of this directory should not be inferred beyond
what is supported by the existing implementation and documentation.
```

However, if the directory contains substantial implementation, the definition should document that implementation more usefully.

---

# 8. Evidence-Based Documentation

The agent must distinguish between three levels of knowledge.

### Level 1 — Directly observed

Examples:

```text
This directory contains `foo.rs`.

This directory contains the subdirectory `bar`.

The Rust module defines `Position`.

The module exports `Graph`.

The directory contains tests.
```

These may be stated directly.

### Level 2 — Strongly supported interpretation

Examples:

```text
The directory appears to contain graph-related primitives.

The directory appears to provide shared core infrastructure.

The implementation appears to support geometry operations.
```

These should use language such as:

```text
appears to
currently functions as
is used for
contains implementation related to
```

when appropriate.

### Level 3 — Speculation

Examples:

```text
This will eventually become the universal graph abstraction.

This must support distributed hypergraphs.

This should lower to dialect X.

This domain will eventually replace Y.
```

These MUST NOT be included.

---

# 9. Do Not Infer Semantics From Directory Names Alone

A directory named:

```text
701_Optimization
```

does not automatically prove that the repository has a complete optimization semantic model.

A directory named:

```text
401_Morphology
```

does not automatically prove that computational morphology has already been fully specified.

A directory named:

```text
904_Providers
```

does not automatically prove that the provider architecture is implemented.

A directory named:

```text
A01_Render
```

does not automatically establish the final rendering architecture.

The documentation must describe **evidence**, not ambition.

For example:

### Good

> This directory contains the current implementation associated with rendering-related functionality.

### Bad

> This directory defines the complete SCR rendering semantic contract.

unless the repository actually contains evidence supporting that statement.

---

# 10. Do Not Turn Names Into Specifications

The following reasoning is prohibited:

```text
directory name
      ↓
assumed semantic model
      ↓
invented definition
```

Instead:

```text
directory
   ↓
files
   ↓
source
   ↓
existing documentation
   ↓
observed role
   ↓
concise definition
```

The purpose is repository archaeology and documentation.

---

# 11. Inspect Before Writing

For every directory, perform approximately this process:

```text
1. Enter directory.

2. List immediate contents.

3. Identify source files.

4. Identify tests.

5. Identify documentation.

6. Identify child directories.

7. Inspect relevant source/documentation.

8. Determine what can be stated factually.

9. Create/update 101_definition.md.

10. Continue recursively.
```

Do not write definitions from the directory listing alone when meaningful implementation is present.

---

# 12. Source Inspection Depth

Do not read every source file line-by-line merely for documentation purposes.

Use progressive inspection.

### Empty / structural directory

Inspect:

```text
directory listing
parent context
child directories
```

This may be sufficient.

### Small implementation directory

Inspect:

```text
directory listing
source files
README/documentation
```

### Substantial implementation directory

Inspect enough of the implementation to determine:

```text
what the code actually does;
what the primary components are;
what the module exports;
what its dependencies are;
what role it currently plays.
```

Do not perform a full code review.

Do not redesign the code.

Do not fix unrelated problems.

---

# 13. Parent/Child Relationship Documentation

The directory hierarchy itself is meaningful and should be recorded.

For example:

```text
lib/
└── 301_Field/
    ├── 101_definition.md
    ├── ...
    └── <child>/
        └── 101_definition.md
```

The parent definition should describe its immediate children at a high level.

A child definition should identify its parent.

However, do not manufacture semantic dependencies merely because one directory is physically nested beneath another.

Remember:

```text
Filesystem Hierarchy
        ≠
Semantic Dependency Graph
```

A statement such as:

> `302_Geometry` is physically located under `lib/`.

is factual.

A statement such as:

> `302_Geometry` semantically depends on `301_Field`.

requires evidence.

---

# 14. What SHOULD Be Included

Include information such as:

### Directory identity

```text
name
path
position in hierarchy
```

### Current purpose

```text
what is currently stored here
```

### Current implementation

```text
Rust modules
MLIR-related code
configuration
support code
tests
examples
utilities
```

### Child structure

```text
immediate subdirectories
```

### Major components

Where evident:

```text
types
modules
operations
traits
interfaces
utilities
algorithms
providers
transforms
analyses
```

### Current repository role

For example:

```text
domain implementation
shared infrastructure
cross-cutting infrastructure
provider area
transformation area
analysis area
experimental area
structural placeholder
```

### Evidence

Where useful, identify:

```text
important source files
existing README
existing tests
existing documentation
```

### Known uncertainty

For example:

```text
The directory currently contains only structural scaffolding.

The intended semantic boundary cannot yet be determined from the
current implementation.

The implementation appears incomplete.
```

---

# 15. What SHOULD NOT Be Included

Do not use this pass to add:

### New specifications

Do not invent:

```text
formal semantic contracts
normative invariants
axioms
laws
semantic equations
new interfaces
```

### New architecture

Do not decide:

```text
this should depend on X
this should be merged with Y
this should become Z
```

unless this is already explicitly established elsewhere.

### New implementation

Do not create:

```text
Rust modules
MLIR dialects
traits
interfaces
providers
tests
```

unless required solely to document the directory — which normally means **do not create them**.

### Refactoring

Do not:

```text
rename directories
move files
reorganize modules
change numbering
change architecture
```

### Cleanup

Do not opportunistically:

```text
fix unrelated bugs
format unrelated source files
rename symbols
rewrite APIs
remove apparently unused files
```

### Future roadmap

Do not fill the definitions with:

```text
future plans
roadmap items
desired functionality
architectural aspirations
```

unless clearly labelled as existing repository context and genuinely necessary.

This pass is not the place for that material.

---

# 16. Avoid False Precision

Do not invent exact semantic terminology simply because it sounds appropriate.

For example, do not write:

> `301_Field` defines a differentiable continuous spatiotemporal field algebra.

unless the implementation or existing authoritative documentation actually establishes that.

Instead:

> `301_Field` contains the current field-related implementation and supporting structures.

Precision must come from evidence.

---

# 17. Avoid Marketing Language

The definitions are repository documentation.

Avoid language such as:

```text
revolutionary
groundbreaking
universal
world-class
complete
ultimate
next-generation
```

unless such terminology is genuinely part of an existing authoritative description.

Prefer:

```text
contains
provides
defines
implements
supports
organizes
currently includes
appears to represent
```

---

# 18. Implementation Status

Be careful with status.

Do not equate:

```text
directory exists
```

with:

```text
domain implemented
```

Do not equate:

```text
type exists
```

with:

```text
semantic model complete
```

Do not equate:

```text
README exists
```

with:

```text
architecture established
```

Use factual descriptions such as:

```text
The directory currently contains implementation for...

The directory currently contains structural scaffolding for...

The directory currently contains documentation but no substantive
implementation.

The directory contains several source modules but its broader
semantic scope is not yet explicit in the implementation.
```

---

# 19. Existing `101_definition.md` Files

If an existing `101_definition.md` is encountered:

### First

Determine whether it is:

```text
normative specification
descriptive documentation
implementation documentation
placeholder
```

### Do not casually overwrite it.

If it contains an established semantic specification, preserve that semantic content.

If it is already appropriate, leave it substantially unchanged.

If it is clearly incomplete and can safely be supplemented with factual repository information, update it carefully.

Do not downgrade an existing normative definition into a purely descriptive inventory.

The goal is:

```text
Documentation pass
        +
Preservation of existing authority
```

not:

```text
Documentation pass
        ↓
Rewrite all definitions
```

---

# 20. Special Handling of `000_meta`

`lib/000_meta` should be treated like every other directory for the purposes of traversal.

It requires:

```text
lib/000_meta/101_definition.md
```

The document should describe what currently exists there.

Do not reinterpret or replace the repository's existing metadata/control-plane model during this task.

---

# 21. Special Handling of Cross-Cutting Directories

Directories such as:

```text
901_Analysis
902_Interfaces
903_Lowering
904_Providers
905_Transforms
```

may not behave like ordinary semantic domains.

Document their actual role as cross-cutting infrastructure.

Do not force every directory into a domain-oriented description.

For example:

```text
904_Providers
```

may appropriately be described as a provider-related infrastructure area rather than pretending that it represents a computational domain.

---

# 22. Special Handling of Empty or Nearly Empty Directories

If a directory contains almost nothing:

**Do not invent content.**

A valid definition can simply say:

```markdown
# <Name>

## Purpose

This directory currently exists as a structural location within the
SCR library hierarchy.

## Current Contents

The directory currently contains:

- `101_definition.md`

No substantive implementation was present when this documentation
pass was performed.

## Current Role

The directory establishes a documented location for this area of the
SCR library.

## Scope Boundary

No additional semantic contract is inferred from the directory's
existence alone.

## Notes

Further semantic or implementation definition is outside the scope of
this documentation pass.
```

This is completely acceptable.

---

# 23. Recommended Document Header

Each new definition should begin consistently.

Use:

```markdown
# <Directory Name>

> Directory documentation for the current SCR library tree.
```

Optionally:

```markdown
**Path:** `lib/<path>`

**Documentation role:** Repository inventory
```

Do not add artificial versioning or semantic-status machinery unless it already exists for that directory.

---

# 24. Do Not Add `102_status.yaml` or `103_library.graph.json`

This task is specifically about:

```text
101_definition.md
```

Do not use the task as an excuse to generate:

```text
102_status.yaml
103_library.graph.json
```

or any other control-plane files.

Those are separate concerns.

The current task is:

```text
Directory
    ↓
101_definition.md
```

and nothing more is required.

---

# 25. Do Not Modify the Directory Structure

The agent must not:

```text
rename directories
move directories
merge directories
split directories
renumber directories
create new semantic directories
delete directories
```

The existing hierarchy is the subject being documented.

---

# 26. Do Not Change Source Code

Unless an extremely unusual repository condition makes it impossible to create the documentation otherwise, this task must produce:

```text
documentation changes only
```

There should be no source-code modifications.

The final diff should consist primarily of:

```text
+ lib/.../101_definition.md
```

and, where necessary:

```text
~ existing lib/.../101_definition.md
```

No unrelated changes should appear.

---

# 27. Recursive Completeness Requirement

Before declaring the task complete, the agent must independently verify the filesystem.

Conceptually:

```text
find lib -type d
```

and for every returned directory:

```text
<directory>/101_definition.md
```

must exist.

The agent should perform an automated completeness check rather than relying on memory.

For example:

```bash
missing=0

while IFS= read -r dir; do
    if [ ! -f "$dir/101_definition.md" ]; then
        echo "MISSING: $dir/101_definition.md"
        missing=1
    fi
done < <(find lib -type d -print)

exit "$missing"
```

Adapt the command as appropriate for the repository environment.

The important requirement is that **every directory is checked mechanically**.

---

# 28. Verify Git Sees the Complete Structure

After creating the files:

```bash
git status --short
```

and:

```bash
git diff --stat
```

must be inspected.

The agent must verify that:

1. every expected directory has a definition;
2. no unrelated source files changed;
3. no directories were renamed;
4. no unexpected files were created;
5. all new definitions are tracked/untracked as expected;
6. the resulting tree corresponds to the actual filesystem.

---

# 29. Validate the Documentation Files

Every generated `101_definition.md` should be checked for:

* valid Markdown;
* correct filename;
* correct path;
* correct directory name;
* no accidental placeholder text;
* no references to nonexistent files;
* no invented implementation;
* no contradictory claims;
* no accidental normative requirements.

The agent should also search for suspicious language such as:

```text
will
must
should
shall
eventually
future
planned
TODO
TBD
```

and manually inspect those occurrences.

These words are not forbidden, but they should not accidentally turn an inventory document into a future specification.

---

# 30. Quality Standard

A successful document should answer:

> **"If I arrive in this directory six months from now, what can I reliably learn about why this directory exists and what is currently inside it?"**

It does not need to answer:

> "What should this domain eventually become?"

That is a different document.

The standard is therefore:

```text
Accurate
    >
Complete
    >
Concise
    >
Speculative
```

Accuracy is more important than comprehensiveness.

A short accurate definition is better than a sophisticated invented one.

---

# 31. Completion Report

At the end of the task, provide a concise report containing:

### Directories discovered

```text
<count>
```

### Definitions created

```text
<count>
```

### Existing definitions preserved

```text
<count>
```

### Definitions modified

```text
<count>
```

### Directories still missing definitions

```text
<count>
```

This must be:

```text
0
```

for completion.

### Source files modified

```text
<count>
```

This should normally be:

```text
0
```

### Unexpected changes

List any unexpected changes.

### Validation

Report the actual commands/checks used to verify recursive completeness.

---

# 32. Final Acceptance Criteria

The task is complete only when all of the following are true:

* [ ] Every directory under `lib/` has been recursively discovered.
* [ ] Every directory has `101_definition.md`.
* [ ] Existing definitions were preserved unless modification was genuinely necessary.
* [ ] Definitions describe current repository evidence.
* [ ] No semantic contracts were invented.
* [ ] No future architecture was invented.
* [ ] No source code was modified.
* [ ] No directories were renamed, moved, created, deleted, or reorganized.
* [ ] No unrelated files were changed.
* [ ] Empty/structural directories are documented rather than populated speculatively.
* [ ] Cross-cutting directories are documented according to their actual role.
* [ ] The completeness check was performed mechanically.
* [ ] Git status/diff was inspected.
* [ ] The final result is a clean documentation-only change.

---

# 33. The Rule to Remember

If there is uncertainty, use this rule:

> **Document what is there. Do not decide what it means beyond the evidence required to explain why the directory exists.**

This pass establishes the physical/documentary skeleton of the SCR library.

Later work can turn individual directories into proper semantic specifications.

That later work is explicitly **not part of this task**.
