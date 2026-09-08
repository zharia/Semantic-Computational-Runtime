# 19 — Subagent Delegation, Output Discipline, Context Budget

---

## Core Rule

> **Delegate bulk mechanical work to subagents. Never pollute main context with bulk task outputs.**

---

## When to Deploy Subagents

Deploy subagents for:

```
Multi-file search-and-replace
Repository-wide grep/audit passes
Bulk file editing (3+ files)
Code review across multiple files
Repetitive mechanical fixes
Validation sweeps across many files
Any task producing output that would exceed ~200 lines in main context
```

---

## When to Work Inline

Work inline only for:

```
Single-file surgical edits (1-2 changes)
Reading a file to understand context
Quick verification of a specific line
Coordination decisions
Architecture reasoning
User-facing responses
```

---

## Subagent Selection

Use the most appropriate subagent type:

```
cavecrew-investigator    → read-only code location, grep, audit
cavecrew-builder         → 1-2 file surgical edit
cavecrew-reviewer        → diff/branch/file review
explore                  → codebase exploration, pattern search
general                  → complex multi-step tasks
```

---

## Output Discipline

When a subagent returns results:

1. Summarize findings in ≤5 lines in main context.
2. Do not paste full file contents or full grep output into main context.
3. If the subagent found violations, deploy fixers rather than fixing inline.
4. Track completion via todo list, not by displaying every edit.

---

## Parallelism

When multiple independent subtasks exist, deploy subagents in parallel within a single message. Do not serialize work that has no dependency.

---

## Context Budget Awareness

Main context is a finite resource. Every line of tool output consumed is a line unavailable for later reasoning. Treat main context as a budget:

```
Subagent output summary:  ~5 lines per subtask
Main context remaining:   preserved for verification and coordination
```

If a task would require reading 5+ files to understand, delegate exploration to a subagent and consume only its summary.

---

## Iterative Reviews

After completing a task, perform up to twenty iterative reviews of your changes. In every iteration, look for meaningful improvements that were missed, for gaps in test coverage, and for deviations from the instructions in this file.

If no meaningful improvements are found for three iterations in a row, report it and stop iterating.
