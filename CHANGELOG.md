# Changelog

All notable changes to CREP are documented in this file.

CREP follows the principles of Keep a Changelog and Semantic Versioning.

---

# [0.1.0] - 2026-08-23

## Added

### Core CLI

- Initial CREP command-line interface.
- Repository name and option parsing.
- `--help` and `--version` support.
- Public and private repository support.
- Repository description support.
- README file support.
- GitHub `.gitignore` template support.
- Optional local project creation.

### Repository Lifecycle

- Local and GitHub repository state detection.
- Existing repository analysis.
- Git history and remote detection.
- Local and GitHub history comparison.
- Synchronized, local-ahead, remote-ahead, diverged, and unrelated history detection.
- GitHub-only clone workflow.
- Local-only repository workflow.
- New repository workflow.
- Existing repository handling.

### Git Operations

- Local Git repository initialization.
- Default `main` branch configuration.
- GitHub `origin` remote configuration.
- Existing remote analysis.
- Git staging.
- Initial and update commit creation.
- Push to GitHub.

### Repository Content

- README copying.
- GitHub `.gitignore` template creation.
- Repository content validation.

### Safety

- Interactive confirmation before repository-changing operations.
- Dry-run execution mode.
- Idempotent repository handling.
- Protection against overwriting existing local paths.
- Dirty working-tree detection.
- Manual reconciliation guidance for unsafe repository states.

### Execution Visibility

- Input validation display.
- Configuration display.
- Environment and dependency display.
- Repository state display.
- Execution plan display.
- Execution action tracking.
- Execution summary.
- Success, failure, and no-change execution states.

### Installation

- User-level installation through `install.sh`.
- Installation to `~/.local/share/crep`.
- User-level launcher through `~/.local/bin/crep`.
- Installation verification.
- Version verification.
- Idempotent reinstallation.
- PATH guidance.
- Dependency-free installation.
- Visual installation progress and status feedback.

### Uninstallation

- User-level removal through `uninstall.sh`.
- Removal of the installed application and launcher.
- Uninstallation verification.
- Safe handling when CREP is already uninstalled.

### Testing

- Automated tests covering CLI arguments, environment, validation, local Git, GitHub operations, Git remotes, repository state, analysis, planning, handlers, integration, idempotency, dry-run, exit codes, content, installation, and uninstallation.
- Centralized test runner.
- ShellCheck validation.

---

## CLI

CREP supports:

```text
crep <repository-name> [options]
```

Available options:

```text
--local [path]
--public
--private
--readme <file>
--gitignore <template>
--description <text>
-h, --help
--version
```

Examples:

```bash
crep my-project
crep my-project --local
crep my-project --local ./projects/my-project
crep my-project --private
crep my-project --readme README-template.md
crep my-project --gitignore Terraform
crep my-project --description "Infrastructure automation project"
crep my-project --local --dry-run
```

---

## Installation

Install CREP from the project directory:

```bash
./install.sh
```

The installer places CREP under:

```text
~/.local/share/crep
```

and creates:

```text
~/.local/bin/crep
```

Verify:

```bash
crep --version
crep --help
```

If `~/.local/bin` is not in `PATH`, the installer provides the required configuration command.

---

## Uninstallation

From the CREP project directory:

```bash
./uninstall.sh
```

The uninstaller removes:

```text
~/.local/share/crep
~/.local/bin/crep
```

---

## Quality

CREP 0.1.0 has been validated through:

- Automated test suite.
- Integration testing.
- Dry-run testing.
- Idempotency testing.
- ShellCheck validation.
- Real GitHub repository creation.
- Real local Git initialization.
- Real Git push.
- Real CLI installation.
- Real CLI execution outside the source repository.
- Real CLI uninstallation.

---

## Release Notes

CREP `0.1.0` is the first project milestone.

This release establishes the core repository lifecycle engine and its foundation for future capabilities.

The initial release focuses on:

1. Safe repository lifecycle automation.
2. Explicit repository state detection.
3. Idempotent behavior.
4. Dry-run visibility.
5. GitHub and local Git integration.
6. Testability.
7. User-level installation and removal.
8. Clear execution reporting.

---

## Future Releases

Future versions may expand CREP with:

- Additional repository providers.
- More advanced synchronization workflows.
- Repository templates.
- Configuration files.
- Non-interactive automation modes.
- Enhanced project bootstrapping.
- CI/CD integration.
- Additional platform support.
- Package-manager distribution.
- Automated release publishing.

---

## Versioning

CREP uses Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

Current version:

```text
0.1.0
```

The authoritative version is stored in:

```text
VERSION
```
