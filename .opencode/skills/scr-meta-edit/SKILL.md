---
name: scr-meta-edit
description: >
  Edit SCR meta files: lib/000_meta/references.md (reference catalogue),
  lib/000_meta/glossary.md (glossary of terms), lib/000_meta/README.md
  (metadata governance). Follows controlled vocabulary and cross-reference
  conventions. Trigger: "edit references", "update glossary", "edit meta",
  "add reference".
---

## Workflow

### 1. Identify target file

| File | Purpose |
|------|---------|
| `lib/000_meta/references.md` | Catalogue of all normative references (standards, specs, papers) |
| `lib/000_meta/glossary.md` | Canonical term definitions for the project |
| `lib/000_meta/README.md` | Meta-directory governance rules |

### 2. Read before editing

Always `Read` the target file before editing. Check:
- Existing structure and formatting conventions.
- No duplicate entries.
- Cross-reference links are valid.

### 3. Edit rules

#### references.md
- Entries must have: title, source, URL (if available), relevance to SCR.
- Group by category: standards, specifications, academic papers, tools.
- New references must note which SCR domains they relate to.
- Do not add references without verifying they exist.

#### glossary.md
- Terms must be defined in plain English.
- Include SCR-specific usage notes where terms have domain-specific meaning.
- Cross-reference related terms.
- Avoid circular definitions.

#### README.md
- Describe the governance model for meta files.
- Document conventions for additions.
- Do not change governance rules without justification.

### 4. Verify

- No duplicate entries.
- Links are valid (where applicable).
- Formatting matches existing conventions.

## Anti-patterns

- Do not add references you cannot verify exist.
- Do not create circular glossary definitions.
- Do not change governance rules without documenting the rationale.
