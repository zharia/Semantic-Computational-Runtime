---
name: scr-new-domain
description: >
  Create a new SCR semantic domain directory with all required files.
  Follows project conventions: PascalCase naming, YAML front matter,
  required sections in 101_definition.md, valid status in 102_status.yaml.
  Trigger: "create new domain", "add domain", "new semantic domain".
---

## Workflow

### 1. Determine placement

Ask user (or infer from context):
- Which category? (`lib/101_Core/`, `lib/201_Data/`, `lib/202_Math/`, etc.)
- Domain name (PascalCase, no spaces)?
- Short description (1 sentence)?

### 2. Create directory

```bash
mkdir -p lib/<category>/<NNN>_<DomainName>
```

Use next available sequence number in the category.

### 3. Create `101_definition.md`

```markdown
---
title: <DomainName>
domain: scr.<category_lowercase>.<domain_name_lowercase>
version: 0.1.0
status: specified
---

# <DomainName>

## Purpose

<1-2 sentences: what this domain represents in SCR>

## Scope

<what is inside this domain's boundaries>

## Core Concepts

- **ConceptA**: <brief definition>
- **ConceptB**: <brief definition>

## Relationships

- <relationship type> → <target domain>
```

Rules:
- `domain` field must follow `scr.<category>.<name>` convention.
- No implementation details (no `.rs`, `.cpp`, provider names).
- Do not duplicate parent domain content.

### 4. Create `102_status.yaml`

```yaml
---
domain: scr.<category>.<domain_name>
status: specified
last_updated: <today ISO>
milestones: []
---
```

### 5. Update parent graph

If parent `103_library.graph.json` exists, add a node for the new domain.
If not, create one.

```json
{
  "nodes": [
    {
      "id": "<NNN>_<DomainName>",
      "type": "domain",
      "path": "<NNN>_<DomainName>"
    }
  ],
  "edges": [
    {
      "source": "<parent_id>",
      "target": "<NNN>_<DomainName>",
      "type": "CONTAINS"
    }
  ]
}
```

### 6. Verify

- Directory exists.
- Files created.
- YAML front matter parses.
- No empty files.
- Directory name is PascalCase.

## Anti-patterns

- Do not create `interfaces/`, `implementations/`, `providers/`, `IR/`, `tests/` unless requested.
- Do not fill in implementation details that don't exist yet.
- Do not create sibling domains without explicit request.
