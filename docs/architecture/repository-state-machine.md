# CREP Repository State Machine

## Purpose

CREP determines the relationship between a local project and its corresponding
GitHub repository before performing any repository operation.

The purpose of the state machine is to make repository actions predictable,
safe, and explicit.

CREP must never overwrite existing work simply because a repository exists.

---

## 1. Primary Repository State

CREP first determines whether the local project and GitHub repository exist.

| Local | GitHub | State |
|---|---|---|
| Does not exist | Does not exist | `neither_exist` |
| Exists | Does not exist | `local_only` |
| Does not exist | Exists | `github_only` |
| Exists | Exists | `both_exist` |

### State Matrix

```text
                         GitHub
                    ┌──────────────┐
                    │      No      │      Yes
              ┌─────┼──────────────┼──────────────
              │ No  │ neither     │ github_only
       Local  │     │ _exist      │
              ├─────┼──────────────┼──────────────
              │ Yes │ local_only  │ both_exist
              └─────┴──────────────┴──────────────
```

---

## 2. `neither_exist`

Neither the local directory nor the GitHub repository exists.

```text
Local   = absent
GitHub  = absent
```

CREP can safely offer to create a new repository.

### Possible workflow

```text
Create GitHub repository
        ↓
Create local directory
        ↓
Create content
        ↓
Initialize Git
        ↓
Configure origin
        ↓
Create commit
        ↓
Push
```

### Safety rule

Creation requires explicit user confirmation.

---

## 3. `local_only`

The local directory exists but the GitHub repository does not.

```text
Local   = exists
GitHub  = absent
```

CREP treats the existing local project as the source of truth.

### Possible workflow

```text
Inspect local project
        ↓
Create GitHub repository
        ↓
Prepare local project
        ↓
Configure Git
        ↓
Commit changes
        ↓
Push to GitHub
```

### Safety rule

CREP must not discard or replace the existing local project.

---

## 4. `github_only`

The GitHub repository exists but the local directory does not.

```text
Local   = absent
GitHub  = exists
```

CREP can offer to clone the repository.

```text
GitHub repository
        ↓
User confirmation
        ↓
Clone locally
```

### Safety rule

CREP must not overwrite an existing local path.

---

## 5. `both_exist`

Both the local directory and GitHub repository exist.

This state requires deeper analysis before any synchronization occurs.

CREP examines:

1. Git repository initialization
2. Git history
3. Working tree
4. Git origin
5. Origin relationship
6. Local/remote history relationship

---

## 6. Git Repository State

When the local directory exists, CREP determines whether it is a Git repository.

### `not_initialized`

The local directory exists but `.git` does not.

```text
Local directory
      ↓
No .git
      ↓
not_initialized
```

CREP reports that Git initialization is required.

CREP must not automatically overwrite the directory.

### `no_history`

The local directory is a Git repository but contains no commits.

```text
.git exists
    ↓
HEAD does not exist
    ↓
no_history
```

A commit is required before normal history synchronization can occur.

### `exists`

The local repository contains Git history.

CREP can continue with repository analysis.

---

## 7. Working Tree State

CREP checks whether the working tree contains uncommitted changes.

### `clean`

No uncommitted changes exist.

CREP may safely continue repository-state analysis.

### `dirty`

Uncommitted changes exist.

```text
Working tree
     ↓
dirty
```

### Safety rule

CREP must **not automatically synchronize** a dirty repository.

User changes must remain untouched.

---

## 8. Git Origin State

CREP compares the local `origin` with the target GitHub repository.

### `missing`

No `origin` remote is configured.

CREP may offer to configure the target repository as `origin`.

### `target`

The existing `origin` points to the target GitHub repository.

CREP can continue with history comparison.

### `different`

The existing `origin` points to another repository.

```text
Local origin
     ↓
Different repository
```

### Safety rule

CREP must never silently replace an existing origin.

Changing the origin requires explicit user action.

---

## 9. History State

When the local origin points to the target repository, CREP compares local
and remote history.

### `synchronized`

```text
Local commits = Remote commits
```

No synchronization is required.

```text
Local
  │
  ├── A ── B ── C
  │
Remote
  │
  └── A ── B ── C
```

### Action

No changes.

### `local_ahead`

Local contains commits that GitHub does not contain.

```text
Local
  A ── B ── C ── D

Remote
  A ── B ── C
```

### Action

CREP may offer to push local commits.

### Safety rule

Push requires explicit user confirmation.

### `remote_ahead`

GitHub contains commits that the local repository does not contain.

```text
Local
  A ── B ── C

Remote
  A ── B ── C ── D
```

### Action

CREP does not automatically push.

Local reconciliation is required first.

### `diverged`

Local and remote repositories contain different commits after their common
ancestor.

```text
              ┌── C ── D    Local
A ── B ───────┤
              └── E ── F    Remote
```

### Action

Manual reconciliation is required.

### Safety rule

CREP must not automatically merge or force-push.

### `unrelated`

The local and remote repositories have no common history.

```text
Local:
A ── B ── C

Remote:
X ── Y ── Z
```

There is no common merge base.

### Action

Manual reconciliation is required.

### Safety rule

CREP must not automatically combine or overwrite the histories.

### `unknown`

CREP cannot safely determine the relationship.

Examples include:

- detached HEAD
- failed remote fetch
- missing remote branch
- inability to determine commit counts
- other Git inspection failures

### Action

Stop automatic synchronization.

### Safety rule

Unknown state is treated as unsafe for automatic changes.

---

## 10. Complete Decision Flow

```text
                    START
                      │
                      ▼
             Determine repository
                   existence
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
       Neither      Local       GitHub
        exists      only         only
          │           │           │
          ▼           ▼           ▼
       Create       Prepare      Clone
          │         local         │
          └───────────┬───────────┘
                      │
                      ▼
                Both exist
                      │
                      ▼
              Analyze local Git
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
    Not initialized No history   Exists
          │           │           │
          │           │           ▼
          │           │      Check working tree
          │           │           │
          │           │      ┌────┴────┐
          │           │      ▼         ▼
          │           │    Dirty     Clean
          │           │      │         │
          │           │      │         ▼
          │           │      │    Check origin
          │           │      │         │
          │           │      │    ┌────┼────┐
          │           │      │    ▼    ▼    ▼
          │           │      │ Missing Diff Target
          │           │      │             │
          │           │      │             ▼
          │           │      │       Compare history
          │           │      │             │
          │           │      │    ┌────────┼────────┐
          │           │      │    ▼        ▼        ▼
          │           │      │   Sync     Ahead    Behind
          │           │      │
          │           │      │
          │           │      └── No automatic
          │           │          synchronization
          │           │
          │           └── Commit required
          │
          └── Git initialization required
```

---

## 11. Safety Principles

CREP follows these principles when making repository decisions.

| Condition | Automatic action |
|---|---|
| Neither exists | Create after confirmation |
| Local only | Create GitHub after confirmation |
| GitHub only | Clone after confirmation |
| Dirty working tree | No synchronization |
| Missing origin | Offer origin configuration |
| Different origin | Never silently replace |
| Synchronized | No action |
| Local ahead | Ask before push |
| Remote ahead | No automatic push |
| Diverged | Manual reconciliation |
| Unrelated | Manual reconciliation |
| Unknown | Stop safely |

---

## 12. Analysis vs Execution

CREP separates repository **analysis** from repository **execution**.

```text
                    Repository
                        │
                        ▼
                  State Detection
                        │
                        ▼
                 Repository Analysis
                        │
                        ▼
                 Execution Plan
                        │
                        ▼
                     Handler
                        │
                        ▼
                     Action
```

The analysis layer determines what is true.

The planning layer determines what should happen.

The handler performs the approved action.

This separation prevents repository operations from being performed before
the repository state is understood.

---

## 13. Safety Boundary

The repository analysis layer acts as a safety boundary between observation
and modification.

```text
┌─────────────────────────────┐
│       Repository State      │
│          Detection          │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│     Repository Analysis     │
│                             │
│  What exists?               │
│  What changed?              │
│  Are histories related?     │
│  Can this be determined?    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      Execution Planning     │
│                             │
│  What action is permitted?  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│          Handler            │
│                             │
│  Perform approved action    │
└─────────────────────────────┘
```

---

## 14. Core Design Principle

> **When CREP cannot determine a repository state safely, it must prefer
> doing nothing over risking existing user data.**

The state machine is therefore not only a routing mechanism.

It is a **safety boundary** between CREP's analysis layer and its execution
layer.
