---
name: scr-edit-domain
description: >
  Edit an existing SCR semantic domain's definition or status files.
  Follows project conventions: preserves YAML structure, validates
  relationship types against controlled vocabulary, maintains
  normative/derived distinction. Trigger: "edit domain", "update domain",
  "modify definition", "change status".
---

## Workflow

### 1. Locate target

Use `scr-explorer` agent or `find`/`Glob` to locate the domain directory.
Confirm the domain exists before editing.

### 2. Identify file to edit

| File | What changes |
|------|-------------|
| `101_definition.md` | Semantic meaning, scope, concepts, relationships |
| `102_status.yaml` | Implementation status, milestones, blockers |
| `103_library.graph.json` | Derived relationships (edit source of truth, not this) |

### 3. Read before editing

Always `Read` the target file before editing.
Check:
- YAML front matter parses correctly.
- Current content does not already cover the intended change.
- Relationship types use the controlled vocabulary.

### 4. Edit rules

#### 101_definition.md
- Preserve YAML front matter structure.
- Add to existing sections; do not remove without justification.
- New relationships must use controlled vocabulary.
- New concepts must have brief definitions.
- Do not introduce implementation details.

#### 102_status.yaml
- Preserve YAML front matter delimiters (standard `---`).
- Valid status values: planned | specified | designed | partially-implemented | implemented | tested | validated | blocked | deprecated.
- Update `last_updated` on any status change.
- `status: implemented` requires implementation references.
- `status: tested` requires test references.

#### 103_library.graph.json
- Do not edit directly. Edit the source files and regenerate.
- If editing is forced, validate JSON structure.

### 5. Verify

- File still parses (YAML/JSON/markdown).
- No broken cross-references.
- No duplicate sections.
- Controlled vocabulary maintained.

## Anti-patterns

- Do not merge status into definition files.
- Do not put mutable status into normative definitions.
- Do not invent implementation references.
- Do not silently change relationship semantics.
