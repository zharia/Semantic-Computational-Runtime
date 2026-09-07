---
name: kanban
description: Filesystem-based Kanban board manager. Use when user says "kanban", "add task", "move task", "show board", "task board", "todo board", "/kanban". Manages tasks across columns: backlog, todo, in-progress, done.
---

# Kanban Board Skill

Filesystem-based Kanban board using `scripts/kanban.sh`.

## Commands

### Initialize board

```bash
bash scripts/kanban.sh init
```

Creates `kanban/` directory with columns: `1-backlog`, `2-todo`, `3-in-progress`, `4-done`.

### Add task

```bash
bash scripts/kanban.sh add "Task Title" "Description of the task"
```

Creates a `.txt` file in `kanban/1-backlog/`.

### Move task

```bash
bash scripts/kanban.sh move task-file.txt [1-4]
```

Column indices: `1` = Backlog, `2` = To Do, `3` = In Progress, `4` = Done.

### View board

```bash
bash scripts/kanban.sh view
```

Displays side-by-side terminal board view.

## Conventions

- Task filenames are lowercase, hyphen-separated (e.g., `fix-auth-bug.txt`).
- Each task file contains: Title, Created timestamp, Description.
- Tasks are `.txt` files stored in numbered column directories under `kanban/`.
