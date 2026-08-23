# ADR-001: CI and Main Branch Governance

-   **Status:** Accepted
-   **Date:** 2026-08-24
-   **Decision Owners:** CREP Maintainer
-   **Scope:** Continuous Integration and `main` branch governance

## Context

CREP is a Bash-based CLI that manages Git and GitHub repository
lifecycle operations.

Version `0.1.0` established the core repository lifecycle functionality.
Before continuing feature development, the project needed automated
verification outside the author's local macOS environment and a
controlled process for changes entering `main`.

The project therefore established:

-   GitHub Actions CI
-   Cross-platform functional testing
-   ShellCheck validation
-   Pull-request-based changes to `main`
-   Required review approval
-   Required CI status checks
-   Protected `main`
-   Squash-based integration of feature branches

## Decision

CREP will use GitHub Actions as its primary CI system and `main` will be
treated as a protected integration branch.

### Continuous Integration

Every relevant change must be validated through GitHub Actions.

The CI workflow validates CREP on:

-   Ubuntu
-   macOS
-   Windows using the Bash environment provided by Git for Windows

The workflow also runs ShellCheck against the project's shell scripts.

CLI smoke tests verify:

-   `crep --version`
-   `crep --help`

### Pull Requests

Changes to `main` must be submitted through a pull request. Direct
pushes to `main` are prohibited.

A pull request targeting `main` requires:

-   At least one approving review
-   Approval of the most recent reviewable push
-   Stale approvals dismissed when new commits are pushed
-   All required CI checks to pass
-   The branch to be up to date with `main`
-   All review conversations to be resolved

### Required CI Checks

The following checks are required before a pull request can be merged:

-   `Test CREP (ubuntu-latest)`
-   `Test CREP (macos-latest)`
-   `Test CREP (windows-latest)`
-   `ShellCheck`

### Branch Protection

The `main` branch is protected with:

-   Pull request required before merging
-   One approving review required
-   Required status checks
-   Branch must be up to date before merging
-   Conversation resolution required
-   Force pushes blocked
-   Branch deletion restricted

The ruleset does not currently require:

-   Signed commits
-   Linear history
-   Deployment environments
-   Code scanning results
-   Code quality results
-   Code coverage thresholds
-   Copilot-specific review requirements

These controls may be introduced later as separate engineering and
security improvements.

### Merge Strategy

Feature pull requests are integrated using **Squash and merge**.

This keeps `main` focused on logical changes while allowing feature
branches to contain multiple development commits.

## Rationale

### Why cross-platform CI?

CREP is intended to work across development environments. Local testing
on macOS alone cannot establish that Bash scripts behave correctly on
Linux or Windows.

Cross-platform CI provides an automated compatibility signal for every
pull request.

### Why protect `main`?

`main` represents the stable integration branch. Requiring pull requests
and successful CI prevents unreviewed or unvalidated changes from being
pushed directly into the branch.

### Why require review?

CI validates automated behavior, but it does not replace human review.
At least one collaborator must approve a change before it can be merged.

A secondary collaborator account was used during this project's
governance exercise to validate the review mechanism. In a real team
environment, approval should come from an independent maintainer or
teammate.

### Why squash merge?

Feature branches may contain implementation, testing, and corrective
commits. Squashing produces a cleaner `main` history where each merged
pull request represents one logical change.

## Verification

The governance model was deliberately tested rather than only
configured.

The CI foundation pull request successfully passed:

-   Ubuntu tests
-   macOS tests
-   Windows/Git Bash tests
-   ShellCheck
-   CLI smoke tests

The pull request received the required approval.

A direct push attempt to `main` was also performed and rejected by the
repository ruleset, confirming that the protection was actively
enforced.

## Consequences

### Positive

-   Cross-platform regressions are detected automatically.
-   `main` cannot be changed through an unreviewed direct push.
-   CI results become part of the merge gate.
-   The project has a repeatable contribution workflow.
-   The repository demonstrates practical engineering governance rather
    than only application code.
-   Feature branches can remain flexible while `main` stays controlled.

### Negative

-   Every change to `main` requires a pull request.
-   CI execution adds time to the development cycle.
-   Cross-platform runners increase CI usage.
-   A required reviewer can temporarily block a change when no reviewer
    is available.
-   Squashed history removes individual feature-branch commits from
    `main`.

These costs are accepted because repository reliability and
maintainability are more important than minimizing merge steps.

## Future Evolution

This ADR establishes the initial governance baseline. Future ADRs may
introduce:

-   CodeQL or equivalent code scanning
-   Dependency and supply-chain security checks
-   Secret scanning
-   Commit signing and verified commits
-   Code coverage requirements
-   Automated release validation
-   Release environments and deployment protection
-   Contributor and CODEOWNERS policies
-   Additional installer and upgrade testing

Those changes should be evaluated independently rather than enabling
every available GitHub control without a demonstrated project need.

## References

-   CREP repository: https://github.com/sanjiivsingh/crep
-   GitHub Actions CI workflow: `.github/workflows/ci.yml`
-   Main branch ruleset: `Protect main`
