#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_analysis.sh"
source "$CREP_ROOT/lib/repository_plan.sh"
source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"

TEST_DIR=""

REPO_NAME="test-repo"
GITHUB_USER="test-user"
LOCAL_PATH=""

LOCAL_STATUS=0
GITHUB_STATUS=0
DRY_RUN=true

CALL_LOG=""


# -------------------------------------------------
# Test environment
# -------------------------------------------------

setup_test_environment() {

    TEST_DIR="$(mktemp -d)"
    LOCAL_PATH="$TEST_DIR/local"

    mkdir -p "$LOCAL_PATH"
}


cleanup_test_environment() {

    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi

    TEST_DIR=""
    LOCAL_PATH=""
}


trap cleanup_test_environment EXIT


# -------------------------------------------------
# Reset test state
# -------------------------------------------------

reset_dry_run_state() {

    reset_test_state

    REPO_NAME="test-repo"
    GITHUB_USER="test-user"
    LOCAL_PATH="$TEST_DIR/local"

    LOCAL_STATUS=0
    GITHUB_STATUS=0
    DRY_RUN=true

    CALL_LOG=""
}


# -------------------------------------------------
# Mock handlers
# -------------------------------------------------

handle_both_exist() {

    CALL_LOG="${CALL_LOG} handle_both_exist"

    return 0
}


handle_local_only() {

    CALL_LOG="${CALL_LOG} handle_local_only"

    return 0
}


handle_github_only() {

    CALL_LOG="${CALL_LOG} handle_github_only"

    return 0
}


handle_neither_exist() {

    CALL_LOG="${CALL_LOG} handle_neither_exist"

    return 0
}


# -------------------------------------------------
# Mock repository analysis
# -------------------------------------------------

inspect_existing_repository() {

    CALL_LOG="${CALL_LOG} inspect_existing_repository"

    EXISTING_GIT_STATUS="exists"
    EXISTING_WORKTREE_STATUS="clean"
    EXISTING_ORIGIN_STATUS="target"
    EXISTING_HISTORY_STATUS="synchronized"

    return 0
}


# -------------------------------------------------
# Test header
# -------------------------------------------------

echo
echo "Testing CREP dry-run..."
echo


# =================================================
# Neither exists
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=1
GITHUB_STATUS=1

output="$(
    execute_repository_plan
)"

status=$?

assert_equals \
    "Dry-run succeeds when neither exists" \
    "0" \
    "$status"

assert_contains \
    "Dry-run identifies neither repository exists" \
    "$output" \
    "Neither local directory nor GitHub repository exists."

assert_contains \
    "Dry-run displays DRY RUN" \
    "$output" \
    "DRY RUN"

assert_contains \
    "Dry-run states that no changes will be performed" \
    "$output" \
    "No changes were made."

assert_equals \
    "Dry-run does not call neither-exist handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Local only
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=0
GITHUB_STATUS=1

output="$(
    execute_repository_plan
)"

status=$?

assert_equals \
    "Dry-run succeeds for local-only state" \
    "0" \
    "$status"

assert_contains \
    "Dry-run identifies local-only state" \
    "$output" \
    "Local directory exists, but GitHub repository does not."

assert_equals \
    "Dry-run does not call local-only handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# GitHub only
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=1
GITHUB_STATUS=0

output="$(
    execute_repository_plan
)"

status=$?

assert_equals \
    "Dry-run succeeds for GitHub-only state" \
    "0" \
    "$status"

assert_contains \
    "Dry-run identifies GitHub-only state" \
    "$output" \
    "GitHub repository exists, but local directory does not."

assert_equals \
    "Dry-run does not call GitHub-only handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Both exist
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=0
GITHUB_STATUS=0

output="$(
    execute_repository_plan
)"

status=$?

assert_equals \
    "Dry-run succeeds when both repositories exist" \
    "0" \
    "$status"

assert_contains \
    "Dry-run identifies both repositories exist" \
    "$output" \
    "Local directory and GitHub repository both exist."

assert_contains \
    "Dry-run reports synchronized history" \
    "$output" \
    "No action required."

assert_contains \
    "Dry-run analyzes existing repository" \
    "$output" \
    "No action required."

assert_equals \
    "Dry-run does not call both-exist handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Unknown GitHub state
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=1
GITHUB_STATUS=2

output="$(
    execute_repository_plan
)"

status=$?

assert_equals \
    "Dry-run rejects unknown GitHub state" \
    "1" \
    "$status"

assert_contains \
    "Dry-run reports unknown GitHub state" \
    "$output" \
    "Unable to determine GitHub repository state."

assert_equals \
    "Unknown GitHub state does not call a handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Invalid repository state
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=2
GITHUB_STATUS=0

output="$(
    execute_repository_plan
)"

status=$?

assert_equals \
    "Dry-run rejects invalid repository state" \
    "1" \
    "$status"

assert_contains \
    "Dry-run reports invalid repository state" \
    "$output" \
    "Invalid repository state."

assert_equals \
    "Invalid dry-run state does not call a handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Dry-run must not execute handlers
# =================================================

setup_test_environment
reset_dry_run_state

LOCAL_STATUS=1
GITHUB_STATUS=1

handle_neither_exist() {

    CALL_LOG="${CALL_LOG} FORBIDDEN_HANDLER"

    return 1
}

execute_repository_plan >/dev/null 2>&1

assert_equals \
    "Dry-run never executes repository handler" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Dry-run disabled
# =================================================

setup_test_environment
reset_dry_run_state

DRY_RUN=false
LOCAL_STATUS=0
GITHUB_STATUS=0

handle_both_exist() {

    CALL_LOG="${CALL_LOG} handle_both_exist"

    return 0
}

execute_repository_plan >/dev/null 2>&1

assert_equals \
    "Normal execution calls repository handler when dry-run is disabled" \
    " handle_both_exist" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Result
# =================================================

echo
echo "CREP dry-run tests passed."