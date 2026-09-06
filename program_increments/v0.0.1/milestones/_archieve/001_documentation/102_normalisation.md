# SCR `lib/` Directory Normalization and Alignment

## Mission

Bring the entire `lib/` directory of the Semantic Computational Runtime (SCR) into a **clean, consistent, canonical repository layout**.

This is a **repository normalization and information-preservation task**.

It is **not** a request to redesign SCR, invent semantic architecture, or rewrite the semantic model.

The objective is to:

1. traverse **every directory and subdirectory under `lib/`**;
2. identify the existing structure, files, metadata, definitions, implementations, documentation, and other information;
3. bring directory and file organization into alignment with the established SCR conventions;
4. ensure every directory has the appropriate `101_definition.md`;
5. normalize inconsistent naming and legacy structures;
6. move existing information into its correct canonical location and format;
7. preserve all meaningful existing information;
8. never delete information merely because it is inconvenient, obsolete-looking, duplicated, or inconsistent;
9. clearly distinguish current semantic authority from historical/implementation/documentary material;
10. mechanically verify the resulting tree.

The desired result is a **clean, predictable, navigable, Git-visible `lib/` hierarchy whose structure accurately reflects the current repository without prematurely inventing semantic specifications**.

---

# 1. Governing Principle

The governing principle for this task is:

> **Observe → classify → preserve → transform → normalize → verify.**

Do not:

> observe → redesign → invent → delete.

This is a repository-alignment task.

The agent must not use this task as an excuse to redesign the SCR semantic architecture.

---

# 2. Current Architectural Authority

The existing SCR architecture establishes important distinctions:

```text
Specification ≠ Implementation
Status ≠ Specification
Graph ≠ Source of Truth
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Representation ≠ Concept
Transformation ≠ Lowering
Domain ≠ Implementation
Filesystem Hierarchy ≠ Semantic Hierarchy
```

These distinctions MUST remain intact.

The filesystem is being normalized for clarity and discoverability.

It must not silently become a new source of semantic authority.

---

# 3. Critical Preservation Rule

## NOTHING OF VALUE MAY BE DELETED

Existing data and information must be preserved.

This includes, but is not limited to:

```text
Markdown
YAML
JSON
source code
implementation notes
documentation
metadata
status information
design notes
research notes
examples
references
tests
configuration
schemas
historical information
provider information
implementation descriptions
architecture notes
```

If a file is in the wrong location or format:

> **transform it into the correct location and format rather than deleting it.**

If information is duplicated:

> preserve the information while consolidating its canonical representation.

If two files contain overlapping information:

> merge the information into the appropriate canonical artifact, then only remove the obsolete duplicate if the complete information has demonstrably been preserved elsewhere.

Before removing any file, the agent MUST be able to answer:

```text
Where did every meaningful piece of information in this file go?
```

If the answer is unclear:

> **DO NOT DELETE THE FILE.**

---

# 4. Scope

The scope is:

```text
lib/
└── every directory
    └── every subdirectory
        └── every existing file
```

The agent MUST recursively inspect the entire tree.

Do not stop after inspecting top-level directories.

Do not assume that similarly named directories contain equivalent content.

Do not assume that a file is obsolete because its name differs from current conventions.

---

# 5. First Phase: Inventory Before Modification

Before modifying anything, construct a complete inventory.

At minimum record:

```text
directory path
directory name
files
file types
existing 101_definition.md
existing 102_status.yaml
existing 103_library.graph.json
metadata files
implementation files
documentation files
tests
nested directories
legacy naming
duplicate-looking artifacts
potential migrations
```

Use filesystem inspection rather than relying exclusively on GitHub's rendered view.

Recommended commands include:

```bash
find lib -print | sort
```

and:

```bash
find lib -type d -print | sort
```

and:

```bash
find lib -type f -print | sort
```

Also inspect Git state:

```bash
git status --short
```

and establish the baseline:

```bash
git ls-files lib | sort
```

The agent should understand the complete current state **before making structural changes**.

---

# 6. Canonical Directory Rule

Every directory under `lib/` MUST have:

```text
101_definition.md
```

unless there is an explicit, documented repository-level reason why a particular directory is an exception.

Do not create arbitrary exceptions merely because a directory appears to be metadata, implementation, documentation, or infrastructure.

If a directory is structurally meaningful, it should have a definition describing what that directory represents.

However:

> The presence of `101_definition.md` does not automatically mean that the directory has a fully developed normative semantic specification.

This distinction is critical.

---

# 7. `101_definition.md` at This Stage

For this normalization task, newly created or substantially normalized definitions must be **evidence-based**.

They should describe:

```text
what the directory contains
why the directory exists
its role in the current repository
its relationship to its parent
its immediately visible children
the type of material contained within it
its current implementation/documentation role where observable
```

They should NOT invent:

```text
new semantics
new operations
new interfaces
new invariants
new capabilities
new MLIR operations
new providers
new mathematical models
new runtime guarantees
new architectural commitments
future implementation plans
```

unless those things are already explicitly established elsewhere in the repository.

---

# 8. Descriptive Versus Normative Definitions

There are two situations.

## Existing authoritative definition

If an existing `101_definition.md` is clearly an established normative semantic definition:

* preserve its semantic content;
* correct formatting;
* correct references;
* remove accidental duplication;
* do not weaken or overwrite established semantics.

## Newly required directory definition

If a directory previously lacked `101_definition.md`:

create a **descriptive repository definition**.

Do not manufacture a complete semantic specification merely because the filename is `101_definition.md`.

For example:

```markdown
# Data IR

## Purpose

This directory contains the IR-related material associated with the SCR Data domain.

## Current Repository Role

The directory currently serves as the repository location for Data-domain IR material.

## Contents

Describe the actual contents observed in this directory.

## Scope

This document records the current repository organization. It does not introduce additional Data IR semantics beyond those established elsewhere in SCR.
```

This is preferable to inventing an elaborate semantic contract.

---

# 9. YAML Front Matter

All `101_definition.md` files using YAML front matter MUST use valid YAML delimiters.

Correct:

```yaml
---
document: 101_definition
...
---
```

Incorrect:

```text
---
document: 101_definition
...
------------------------
```

The agent MUST identify and correct malformed front matter throughout `lib/`.

After correction, YAML must parse successfully.

Do not merely make GitHub render correctly; make the underlying document structurally valid.

---

# 10. Canonical Control-Plane Files

SCR uses the following convention:

```text
101_definition.md
    ↓
semantic definition / directory definition

102_status.yaml
    ↓
engineering state

103_library.graph.json
    ↓
derived library graph
```

Do not confuse these roles.

### `101_definition.md`

Defines what the directory/domain represents.

### `102_status.yaml`

Records current engineering reality.

### `103_library.graph.json`

Represents derived relationships.

Neither status nor graph data should be silently promoted into semantic authority.

---

# 11. Status Information Must Be Preserved

Existing:

```text
102_status.yaml
```

files must not be deleted simply because the new layout does not require them everywhere.

If a status file exists:

* preserve it;
* validate it;
* normalize its location if necessary;
* preserve its information;
* update only when required to reflect a structural migration;
* do not convert status information into semantic claims.

If information from an old status file must move into another status artifact, preserve the complete information.

---

# 12. Graph Information Must Be Preserved

Existing:

```text
103_library.graph.json
```

or equivalent graph artifacts must not be discarded.

If the graph is stale because directories or definitions have moved:

1. preserve the existing information;
2. determine whether it is a derived artifact;
3. update/regenerate it where the repository's tooling supports this;
4. retain any information that is not regenerated automatically;
5. do not make the graph the semantic source of truth.

---

# 13. Metadata Must Be Transformed, Not Deleted

Legacy metadata files such as:

```text
000_meta.md
```

must be inspected individually.

Do not delete them merely because the preferred structure is now:

```text
000_meta/
```

or:

```text
000_meta/
├── 101_definition.md
├── README.md
└── references.md
```

If an existing:

```text
000_meta.md
```

contains meaningful information, transform it into the appropriate canonical artifact.

For example, if it contains directory-definition information:

```text
000_meta.md
        ↓
000_meta/101_definition.md
```

If it contains references:

```text
000_meta.md
        ↓
000_meta/references.md
```

If it contains general explanatory information:

```text
000_meta.md
        ↓
000_meta/README.md
```

If it contains multiple kinds of information:

```text
000_meta.md
        ↓
split into appropriate canonical files
```

The original information must remain represented after the transformation.

---

# 14. Legacy Hypergraph Structure

The Hypergraph subtree requires particular care because it contains older organizational conventions.

Inspect and normalize structures such as:

```text
203_Graph/Hypergraph/
```

including:

```text
201_lean-lang/
301_implementation/
401_documentaion/
000_meta.md
101_definition.md
102_status.yaml
101_implementation.md
```

Do not blindly delete or flatten these structures.

Instead determine what each directory and file actually contains.

Normalize directory naming to the repository convention where justified.

For example, likely transformations include:

```text
201_lean-lang
    →
201_LeanLang

301_implementation
    →
301_Implementation

401_documentaion
    →
401_Documentation
```

However:

> Verify the intended meaning and references before renaming.

Correct spelling and naming consistency while preserving all contents.

---

# 15. Legacy Implementation Definitions

If a directory contains:

```text
101_implementation.md
```

but the current repository convention requires:

```text
101_definition.md
```

do not simply overwrite the implementation document.

First classify its contents.

If it contains:

```text
directory definition
```

merge its information into:

```text
101_definition.md
```

If it contains:

```text
implementation documentation
```

move that content into an appropriate implementation/documentation artifact.

For example:

```text
301_Implementation/
├── 101_definition.md
└── implementation.md
```

or another existing repository convention if one already exists.

The goal is:

```text
definition information
→ definition artifact

implementation information
→ implementation artifact

status information
→ status artifact

references
→ reference artifact
```

Never destroy the distinction by forcing everything into `101_definition.md`.

---

# 16. IR Directories

`IR/` directories require special attention.

The presence of:

```text
Domain/IR/
```

does NOT mean that the domain's IR semantics have already been independently designed.

Where an IR directory exists, its `101_definition.md` should accurately identify its domain.

Do not copy:

```text
SCR-LIB-CORE-IR
```

into every domain's IR definition.

For example:

```text
201_Data/IR/101_definition.md
```

must not falsely identify itself as the Core IR if it is actually the Data IR scope.

Likewise:

```text
202_Math/IR/101_definition.md
203_Graph/IR/101_definition.md
301_Field/IR/101_definition.md
```

must not inherit Core IR identity merely because their files were copied from the Core template.

---

# 17. Core IR Versus Domain IR

Maintain this distinction:

```text
101_Core/IR
```

represents the generic/core SCR IR scope.

A domain-specific:

```text
Domain/IR
```

represents the IR scope associated with that domain.

If a domain-specific IR has not actually been specified:

say so.

For example:

```markdown
# Data IR

## Current Role

This directory is reserved for IR material associated with the Data domain.

## Current State

The repository currently contains this directory as the domain-specific IR location. A distinct Data-specific semantic IR contract has not yet been independently established.

## Relationship to Core IR

This directory is associated with the Core SCR IR infrastructure but does not redefine or duplicate the Core IR semantic contract.
```

Do not fabricate a Data IR specification merely to make the directory look complete.

---

# 18. Duplicate Information

Duplicates must be handled carefully.

First classify the duplicate:

### Exact duplicate

Two files contain the same information.

### Structural duplicate

Two files describe the same thing in different formats.

### Semantic duplicate

Two files claim to define the same semantic concept.

### Historical duplicate

An older file contains information retained for historical purposes.

### Accidental duplicate

A file was copied into multiple directories without being adapted.

Only after classification should consolidation occur.

For accidental duplicates:

```text
preserve useful information
→ create correct canonical definition
→ adapt identity/path/parent metadata
→ remove redundant copy only after verification
```

---

# 19. Identity Must Match Location

Every definition must describe its actual location and scope.

A file under:

```text
201_Data/IR/
```

must not claim to be:

```text
101_Core/IR
```

Likewise, a definition under:

```text
203_Graph/Hypergraph/Implementation/
```

must identify the Hypergraph implementation scope rather than Graph Core or generic SCR implementation.

Check:

```text
id
name
parent
domain
path
references
cross-references
```

for consistency.

---

# 20. Directory Naming Convention

Use the existing SCR numbering convention where already established:

```text
000_meta
101_Core
201_Data
202_Math
203_Graph
301_Field
...
A01_Render
```

Do not renumber established top-level domains.

Within a domain, use the established numeric-prefix convention where the existing structure clearly uses it.

Names should otherwise be:

```text
PascalCase
```

for named semantic/organizational scopes, unless a repository-level convention explicitly requires another form.

Avoid:

```text
lowercase
snake_case
mixed_case
misspellings
inconsistent abbreviations
```

unless the name is intentionally canonical or externally constrained.

---

# 21. Do Not Reorganize the Top-Level Semantic Taxonomy

The following top-level structure should be preserved unless direct repository evidence demonstrates an actual defect:

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

This task is about normalization, not redesign.

---

# 22. Cross-Cutting Directories

Treat these as cross-cutting infrastructure:

```text
901_Analysis
902_Interfaces
903_Lowering
904_Providers
905_Transforms
```

Do not force them into ordinary domain semantics.

Their definitions should describe their cross-cutting repository role.

For example:

```text
902_Interfaces
```

should describe the interface/capability scope.

It should not pretend to be another computational domain like Physics or Geometry.

---

# 23. `000_meta`

Treat:

```text
000_meta
```

as repository/library metadata and governance infrastructure.

It should not be represented as a semantic computational domain.

However, because every directory must be represented explicitly, give it:

```text
000_meta/101_definition.md
```

with a descriptive definition.

---

# 24. Rendering

`A01_Render` is a valid top-level SCR domain.

Do not move it merely because it uses a different numbering prefix.

Do not rename it to fit the `101–905` pattern.

Its current position is part of the established repository structure.

Normalize its children according to the same rules applied elsewhere.

---

# 25. Source Code Preservation

Do not modify source code unless a structural migration absolutely requires updating a path/reference.

This task is not an implementation task.

Normally:

```text
source modifications = 0
```

If a rename requires source/reference updates:

1. identify every affected reference;
2. update references consistently;
3. preserve semantics;
4. test the affected code;
5. report the change explicitly.

Never rewrite implementation simply to make the repository look cleaner.

---

# 26. References Must Be Updated

Whenever files or directories are moved or renamed, search for references.

Use tools such as:

```bash
rg "old/path" .
```

and:

```bash
rg "OldName" .
```

Check:

```text
Markdown links
YAML references
JSON references
source imports
documentation references
graph references
scripts
tests
configuration
agent instructions
README files
```

A clean filesystem with broken references is not an acceptable result.

---

# 27. Transformation Ledger

Maintain a migration ledger during the operation.

It should record:

```text
OLD PATH
NEW PATH
ACTION
REASON
INFORMATION PRESERVED
REFERENCES UPDATED
```

Example:

```text
203_Graph/Hypergraph/301_implementation
→
203_Graph/Hypergraph/301_Implementation

Reason:
Normalize directory naming.

Information:
All existing implementation files preserved.

References:
Updated N references.
```

This ledger may be temporary working material, but the final report must summarize its contents.

---

# 28. No Silent Information Loss

The agent must be especially careful with:

```text
metadata
YAML
JSON
status
research notes
implementation notes
references
design history
```

Do not assume that a small file is unimportant.

Do not assume that an old file is obsolete.

Do not assume that a malformed file contains no useful information.

First recover its information.

Then normalize it.

---

# 29. File Format Conversion

When information is stored in an inappropriate format, convert it rather than discard it.

Examples:

```text
000_meta.md
→
101_definition.md / README.md / references.md

implementation description embedded in definition
→
implementation-specific documentation

status information embedded in Markdown
→
102_status.yaml

graph relationship information
→
103_library.graph.json
```

However:

> Only perform a semantic format conversion when the destination format is actually established by SCR conventions.

Do not invent new metadata schemas merely because conversion seems convenient.

---

# 30. Definition Content Standard

Each `101_definition.md` should contain enough information to make the directory understandable.

At minimum:

```markdown
# <Name>

## Purpose

What this directory represents.

## Scope

What belongs here.

## Current Repository Role

What the directory currently contains.

## Contents

Important files/subdirectories.

## Parent Relationship

How this directory relates to its parent directory.

## Child Structure

Important immediate children.

## Authority

Whether this document is descriptive repository documentation or an established normative semantic definition.

## Notes

Only evidence-supported observations.
```

For established normative definitions, preserve the richer existing structure rather than reducing it to this template.

---

# 31. Do Not Invent Semantic Completeness

A directory is allowed to be incomplete.

A directory definition may explicitly say:

```text
The directory currently exists as the repository location for X.

A complete semantic specification has not yet been established.
```

This is a valid and useful state.

Do not manufacture:

```text
operations
types
interfaces
invariants
equations
providers
MLIR dialects
runtime guarantees
```

just to make the definition appear sophisticated.

---

# 32. Do Not Delete Empty Directories

Git does not track empty directories.

If an empty directory exists and is intentionally part of the repository structure:

```text
retain the directory
add 101_definition.md
```

The definition itself then makes the directory Git-visible.

Do not remove a directory simply because it contains no implementation.

---

# 33. Do Not Create Arbitrary New Directories

Do not introduce directories merely to satisfy aesthetic symmetry.

For example, do not create:

```text
IR/
Implementation/
Documentation/
Tests/
Providers/
```

inside every domain simply because one domain has them.

Only normalize structures that are actually justified by existing repository organization.

The goal is:

> **consistent structure without artificial uniformity.**

---

# 34. Parent/Child Consistency

Every nested definition should agree with its parent.

For example:

```text
203_Graph
    ↓
Hypergraph
    ↓
Implementation
    ↓
Rust
```

should form a coherent repository relationship.

Check that:

```text
parent references child
child references parent
names agree
paths agree
identities agree
```

But remember:

```text
filesystem parent
≠
semantic dependency
```

Do not infer semantic dependency merely from nesting.

---

# 35. Semantic Identity Checks

For every definition, check:

```text
Does the name match the directory?
Does the identity match the directory?
Does the parent match the filesystem parent?
Does the domain match the directory?
Does the content describe the actual directory?
Does it accidentally claim Core identity?
Does it accidentally claim implementation that does not exist?
Does it accidentally claim semantics that are not established?
```

This is particularly important for copied files.

---

# 36. Existing Definitions Must Be Preserved

When a directory already has:

```text
101_definition.md
```

do not replace it wholesale.

Instead:

1. inspect it;
2. classify it;
3. validate its structure;
4. preserve established semantic content;
5. correct obvious structural errors;
6. reconcile its identity with its directory;
7. add only evidence-supported repository information where necessary.

If an existing definition contains genuine normative semantics, those semantics have priority over a generic template.

---

# 37. Existing Information Has Priority Over Template Purity

Do not force existing content into an overly rigid template.

The purpose of the template is consistency.

The purpose of preservation is information integrity.

When they conflict:

> **Preserve meaningful information.**

A definition may contain more sections than the standard template.

That is acceptable.

---

# 38. Validation Requirements

After the migration, mechanically verify that every directory has a definition.

Use:

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

The result MUST be:

```text
exit code 0
```

with no missing directories.

---

# 39. Validate YAML

Find YAML files:

```bash
find lib -type f \( -name '*.yaml' -o -name '*.yml' \) -print
```

Validate them using the repository's available YAML tooling.

At minimum, verify:

```text
valid YAML
no malformed front matter
no accidental truncation
no duplicate keys where prohibited
```

---

# 40. Validate Markdown Structure

Search for malformed front matter:

```bash
rg -n "^[-]{10,}$" lib
```

Inspect every match manually.

Check for:

```text
broken headings
broken links
incorrect paths
duplicated definitions
incorrect identities
stale references
```

---

# 41. Validate Path References

Search for renamed paths and legacy names.

For example:

```bash
rg "201_lean-lang|301_implementation|401_documentaion" .
```

The expected result after migration should be either:

```text
zero stale references
```

or explicit references that are intentionally historical.

---

# 42. Validate Duplicate Core IR Identity

Search:

```bash
rg "SCR-LIB-CORE-IR" lib
```

Inspect every occurrence.

Only the actual Core IR definition should identify itself as the Core IR.

Domain-specific IR definitions must not falsely inherit that identity.

---

# 43. Validate Git Changes

Before completion:

```bash
git status --short
```

and:

```bash
git diff --stat
```

and:

```bash
git diff --name-status
```

and, where useful:

```bash
git diff -- lib
```

Review the complete diff.

Do not trust automated migration merely because validation scripts pass.

---

# 44. Information-Preservation Audit

Before finalizing, perform a preservation audit.

For every deleted or renamed file:

```text
What information did it contain?
Where does that information exist now?
Was anything lost?
Were references updated?
```

A file may only be removed after this audit confirms:

```text
information preserved
references preserved
history preserved where necessary
canonical replacement exists
```

If any answer is uncertain:

> restore the file and investigate further.

---

# 45. Git Rename Detection Is Not Information Preservation

Do not assume:

```text
git mv
```

automatically means the migration is correct.

Git's rename detection is based on content similarity.

The agent must reason about the information represented by the file, not merely whether Git recognizes it as a rename.

---

# 46. No History Destruction

Do not use destructive commands such as:

```bash
rm -rf
git clean -fd
git reset --hard
```

unless explicitly authorized for a specific recovery operation.

Do not discard uncommitted user work.

If unexpected changes are encountered:

> stop and report them.

---

# 47. Working Tree Safety

Before modifying:

```bash
git status --short
```

If there are pre-existing changes:

* record them;
* do not overwrite them;
* do not revert them;
* do not incorporate them into unrelated cleanup without understanding them.

The migration must remain attributable to this task.

---

# 48. Recommended Execution Order

Execute the work in this order:

```text
1. Inspect repository state
        ↓
2. Inventory entire lib tree
        ↓
3. Classify files and directories
        ↓
4. Identify legacy structures
        ↓
5. Identify malformed metadata/front matter
        ↓
6. Identify duplicated definitions
        ↓
7. Plan transformations
        ↓
8. Normalize directory names
        ↓
9. Move/transform information
        ↓
10. Create missing 101_definition.md files
        ↓
11. Correct existing definitions
        ↓
12. Update references
        ↓
13. Validate YAML/Markdown
        ↓
14. Validate directory completeness
        ↓
15. Audit information preservation
        ↓
16. Review Git diff
        ↓
17. Report results
```

Do not mix discovery and destructive modification recklessly.

---

# 49. Preferred Migration Strategy

For significant structural changes:

```text
COPY / TRANSFORM
        ↓
VERIFY
        ↓
UPDATE REFERENCES
        ↓
VERIFY AGAIN
        ↓
REMOVE OBSOLETE SOURCE
```

Do not:

```text
DELETE
        ↓
HOPE
        ↓
RECREATE
```

The former is reversible and auditable.

The latter risks information loss.

---

# 50. Acceptance Criteria

The task is complete only when all of the following are true.

## Directory completeness

Every directory under:

```text
lib/
```

has:

```text
101_definition.md
```

unless an explicitly documented repository-level exception exists.

## Naming

Directory names are consistent with SCR conventions.

Known spelling errors and accidental naming inconsistencies are corrected.

## Definitions

Definitions correspond to their actual directories.

No copied definition falsely identifies itself as another domain.

## YAML

All YAML and front matter are syntactically valid.

## Information preservation

All meaningful information from migrated files has been preserved.

## Legacy migration

Legacy metadata, implementation, documentation, and status artifacts have been transformed into appropriate canonical locations rather than simply deleted.

## References

Internal references have been updated.

## Architecture

No semantic architecture has been invented or changed as part of the normalization.

## Implementation

No implementation changes have been made unless required solely to accommodate a structural rename/reference update.

## Git

The complete diff has been reviewed.

## Verification

The directory completeness check passes.

---

# 51. Final Report

At completion, report:

```text
SCR lib/ Directory Normalization Report

Directories discovered:
<COUNT>

Directories with 101_definition.md:
<COUNT>

Definitions created:
<COUNT>

Definitions modified:
<COUNT>

Definitions preserved unchanged:
<COUNT>

Directories renamed:
<COUNT>

Files moved:
<COUNT>

Files transformed:
<COUNT>

Files deleted:
<COUNT>

Information-preservation audit:
<PASS/FAIL>

YAML validation:
<PASS/FAIL>

Markdown validation:
<PASS/FAIL>

Reference validation:
<PASS/FAIL>

Directory completeness:
<PASS/FAIL>

Source files modified:
<COUNT>

Unexpected changes:
<NONE / DETAILS>
```

For every deleted file, provide:

```text
OLD FILE
WHY REMOVED
WHERE INFORMATION WAS PRESERVED
```

If any file was deleted without a demonstrable information-preserving destination:

> **the task has failed.**

---

# 52. Final Principle

The agent must keep this rule in mind throughout the entire operation:

> **The purpose of this task is to make the repository structurally coherent without destroying or inventing its contents.**

Or, more operationally:

```text
KEEP THE INFORMATION.
KEEP THE SEMANTICS.
KEEP THE IMPLEMENTATION.
KEEP THE HISTORY WHERE RELEVANT.
FIX THE LOCATION.
FIX THE FORMAT.
FIX THE IDENTITY.
FIX THE REFERENCES.
FIX THE CONSISTENCY.
DO NOT INVENT ARCHITECTURE.
```

The desired final state is:

```text
                 SCR lib/
                    │
          ┌─────────┴─────────┐
          │                   │
     Clean hierarchy      Preserved information
          │                   │
          └─────────┬─────────┘
                    │
              Canonical files
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
       Definition  Status    Graph
          │
          ▼
     Semantic Authority
```

The filesystem should become **predictable**.

The information should remain **complete**.

The semantic architecture should remain **authoritative**.

And anything that cannot yet be established semantically should remain explicitly **unestablished rather than invented**.
