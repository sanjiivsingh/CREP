# 🚀 CREP

### Code Repository Environment Provisioner

> **State first. Action second.**

CREP is a Bash-based CLI that automates the lifecycle of GitHub repositories and local Git projects.

Instead of manually creating a repository, creating a local directory, initializing Git, configuring `origin`, making the first commit, and pushing everything to GitHub, CREP turns the workflow into a **state-aware, idempotent, testable CLI experience**.

---

## ✨ Why CREP?

Creating a repository looks simple:

```text
Create GitHub repo
      ↓
Create local directory
      ↓
git init
      ↓
git branch -M main
      ↓
git remote add origin ...
      ↓
git add .
      ↓
git commit
      ↓
git push
```

But real projects are rarely in a clean starting state.

What if:

- 📁 the local directory already exists?
- 🐙 the GitHub repository already exists?
- 🌳 the local project is already a Git repository?
- 🔗 `origin` points somewhere else?
- 📝 there are uncommitted changes?
- 🧬 local and remote histories have diverged?
- 🔄 you run the command again?

CREP is designed around those states.

> **CREP does not blindly execute commands. It determines the repository state first, then chooses a safe execution path.**

---

## 🎯 What CREP Does

```text
                    ┌─────────────────────┐
                    │       CREP CLI      │
                    └──────────┬──────────┘
                               │
                               ▼
                    🔍 Detect repository state
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
          💻 Local only    🐙 GitHub only   🆕 Neither
                │              │              │
                ▼              ▼              ▼
           Analyze Git      Clone repo      Create repo
                │              │              │
                └──────────────┼──────────────┘
                               ▼
                       📋 Build execution plan
                               │
                               ▼
                       🛡️ Execute safely
                               │
                               ▼
                         📊 Report result
```

---

## 🧠 State-Aware by Design

CREP understands four fundamental repository states:

| Local | GitHub | CREP behavior |
|---|---|---|
| ❌ | ❌ | 🆕 Create repository and local project |
| ✅ | ❌ | 🏠 Use existing local project and create GitHub repository |
| ❌ | ✅ | 📥 Clone GitHub repository locally |
| ✅ | ✅ | 🔍 Analyze and synchronize safely |

When both repositories exist, CREP goes deeper:

```text
Local project
    │
    ├── Git repository?
    ├── Has commits?
    ├── Working tree clean?
    ├── Has origin?
    ├── Does origin point to target?
    └── What is the history relationship?
             │
             ├── 🟢 synchronized
             ├── 🔵 local ahead
             ├── 🟡 remote ahead
             ├── 🔴 diverged
             └── ⚠️ unrelated / unknown
```

> **State first. Action second.**

---

## 🛡️ Safety First

CREP is intentionally conservative.

It does not automatically overwrite an existing dirty working tree.

It does not silently replace an existing remote.

It does not blindly merge unrelated histories.

It can tell you when manual reconciliation is required.

This makes CREP useful not only for creating repositories, but also for understanding the state of repositories that already exist.

---

## 🧪 Dry Run

Want to know what CREP would do before changing anything?

```bash
crep my-project --local --dry-run
```

A dry run builds the execution plan without performing repository changes.

Example:

```text
Execution plan:

Warning: DRY RUN

Action : The following operations would be performed:

  1. Create GitHub repository.
  2. Create local project directory.
  3. Initialize Git repository.
  4. Configure GitHub repository as origin.
  5. Create initial Git commit.
  6. Push initial commit to GitHub.

Warning: DRY RUN: No changes were made.
```

---

## ⚡ Quick Start

### 1️⃣ Install

From the CREP project directory:

```bash
./install.sh
```

CREP installs for the current user:

```text
~/.local/share/crep
└── bin/
    └── crep

~/.local/bin/
└── crep
```

No `sudo` required.

### 2️⃣ Verify

```bash
crep --version
```

### 3️⃣ Get help

```bash
crep --help
```

### 4️⃣ Create a repository

```bash
crep my-project
```

### 5️⃣ Create GitHub + local project

```bash
crep my-project --local
```

### 6️⃣ Create a private repository

```bash
crep my-project --private
```

### 7️⃣ Use a custom local path

```bash
crep my-project --local ./projects/my-project
```

### 8️⃣ Preview before execution

```bash
crep my-project --local --dry-run
```

---

## 🧰 CLI Options

```text
Usage:
  crep <repository-name> [options]

Options:
  --local [path]              Create/use a local Git project
  --public                    Create a public repository
  --private                   Create a private repository
  --readme <file>             Use a file as README content
  --gitignore <template>      Use a GitHub gitignore template
  --description <text>        Set repository description
  --dry-run                   Preview operations without making changes
  -h, --help                  Show this help
  --version                   Show version
```

---

## 🔐 Requirements

CREP currently relies on:

- 🐚 Bash
- 🌳 Git
- 🐙 GitHub CLI (`gh`)
- 🔑 GitHub CLI authentication

Authenticate GitHub CLI with:

```bash
gh auth login
```

Verify authentication:

```bash
gh auth status
```

---

## 🏗️ Architecture

CREP is deliberately split into focused Bash modules:

```text
crep/
│
├── bin/
│   └── crep
│
├── lib/
│   ├── arguments.sh
│   ├── content.sh
│   ├── environment.sh
│   ├── git_remote.sh
│   ├── github.sh
│   ├── local.sh
│   ├── output.sh
│   ├── repository_analysis.sh
│   ├── repository_handlers.sh
│   ├── repository_plan.sh
│   ├── repository_state.sh
│   ├── state.sh
│   └── validation.sh
│
├── tests/
│   ├── assertions.sh
│   ├── helpers.sh
│   ├── test_arguments.sh
│   ├── test_content.sh
│   ├── test_dry_run.sh
│   ├── test_environment.sh
│   ├── test_exit_codes.sh
│   ├── test_git_remote.sh
│   ├── test_github.sh
│   ├── test_handler_both_exist.sh
│   ├── test_idempotency.sh
│   ├── test_integration.sh
│   ├── test_install.sh
│   ├── test_local.sh
│   ├── test_repository_analysis.sh
│   ├── test_repository_handlers.sh
│   ├── test_repository_plan.sh
│   ├── test_repository_state.sh
│   ├── test_uninstall.sh
│   ├── test_validation.sh
│   └── test_runner.sh
│
├── CHANGELOG.md
├── VERSION
├── LICENSE
├── install.sh
└── uninstall.sh
```

### Design pipeline

```text
Arguments
    ↓
Validation
    ↓
Environment
    ↓
Dependencies
    ↓
Repository State
    ↓
Repository Analysis
    ↓
Execution Plan
    ↓
Handler
    ↓
Execution
    ↓
Summary
```

This separation keeps the CLI easier to reason about, test, and extend.

---

## 🔄 Idempotency

Running CREP again should not blindly repeat destructive operations.

For example:

```bash
crep my-project --local
```

followed by:

```bash
crep my-project --local
```

allows CREP to recognize the existing state.

If everything is synchronized:

```text
Success: Local and GitHub repositories are synchronized.
Action                    : No synchronization required.
```

> **Repeatable execution is a design goal, not an accident.**

---

## 📊 Execution Summary

CREP records what happened during execution.

A successful creation can finish with:

```text
Execution summary:

Action                    : GitHub repository: created
Action                    : Local directory: created
Action                    : Git repository: initialized
Action                    : Default branch: main
Action                    : Git remote: origin configured
Action                    : Git commit: initial commit created
Action                    : Git push: completed

Success: Result: SUCCESS
```

This makes automation observable instead of leaving users to infer what happened from raw Git output.

---

## 🧪 Testing

Run the complete test suite:

```bash
./tests/test_runner.sh
```

Expected:

```text
Tests:  18
Failed: 0

ALL TESTS PASSED
```

Run ShellCheck:

```bash
shellcheck -x tests/*.sh install.sh uninstall.sh
```

CREP includes tests covering:

- CLI argument handling
- Environment detection
- Dependency validation
- GitHub operations
- Local Git operations
- Git remotes
- Repository state
- Repository analysis
- Repository planning
- Repository handlers
- Integration
- Idempotency
- Dry-run behavior
- Exit codes
- Repository content
- Installation
- Uninstallation

---

## 🧹 Uninstall

CREP can remove its user-level installation:

```bash
./uninstall.sh
```

The uninstaller removes:

```text
~/.local/share/crep
~/.local/bin/crep
```

It does not remove your source repository.

---

## 🗺️ Roadmap

### v0.1.x

- 🧩 Repository templates
- ⚙️ Configuration support
- 🤖 Additional automation modes
- 📦 Packaging improvements

### v0.2.x

- 🔌 Additional repository providers
- 🏗️ Project bootstrapping
- 🔄 Advanced synchronization workflows
- 🔗 CI/CD integrations

### v1.0.x

- 🧱 Stable CLI contract
- 📦 Mature distribution
- 📚 Complete documentation
- 🚀 Production-ready release

The roadmap is intentionally evolutionary:

> **Stabilize the state engine first. Expand the automation surface second.**

---

## 🤝 Contributing

Contributions, ideas, bug reports, and improvements are welcome.

Before submitting changes:

```bash
./tests/test_runner.sh
```

and:

```bash
shellcheck -x tests/*.sh install.sh uninstall.sh
```

Please preserve CREP's core principles:

- 🛡️ Safe automation
- 🔍 State awareness
- 🔄 Idempotency
- 🧪 Testability
- 📊 Observable execution
- 🧩 Modular design

---

## 👨‍💻 Author

### Sanjeev Singh

**Senior Azure Cloud Architect & DevSecOps Platform Engineer**

CREP is part of my ongoing work in building deterministic infrastructure automation, developer tooling, and verifiable Git workflows.

🌐 **Portfolio:** [sanjeevsingh.oneps.in](https://sanjeevsingh.oneps.in)

🔗 **GitHub:** [github.com/sanjiivsingh](https://github.com/sanjiivsingh)

💼 **LinkedIn:** [linkedin.com/in/sanjiivsingh](https://www.linkedin.com/in/sanjiivsingh/)

---

## 📄 License

CREP is released under the **MIT License**.

See [LICENSE](LICENSE) for the complete license text.

---

<p align="center">

### 🚀 CREP

**State first. Action second.**

Built with ❤️ using Bash, Git, and GitHub.

</p>
