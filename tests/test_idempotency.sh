#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_state.sh"
source "$CREP_ROOT/lib/repository_analysis.sh"
source "$CREP_ROOT/lib/repository_handlers.sh"
source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"

TEST_DIR=""

REPO_NAME="test-repo"
GITHUB_USER="test-user"
LOCAL_PATH=""

MOCK_WORKTREE_STATUS=""
MOCK_GIT_STATUS=""
MOCK_ORIGIN_STATUS=""
MOCK_HISTORY_STATUS=""

PUSH_CALLED=0
CONFIRM_CALLED=0


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

reset_idempotency_state() {

    reset_test_state

    REPO_NAME="test-repo"
    GITHUB_USER="test-user"

    LOCAL_PATH="$TEST_DIR/local"

    MOCK_WORKTREE_STATUS=""
    MOCK_GIT_STATUS=""
    MOCK_ORIGIN_STATUS=""
    MOCK_HISTORY_STATUS=""

    PUSH_CALLED=0
    CONFIRM_CALLED=0
}


# -------------------------------------------------
# Mock repository inspection
# -------------------------------------------------

inspect_existing_repository() {

    EXISTING_WORKTREE_STATUS="$MOCK_WORKTREE_STATUS"
    EXISTING_GIT_STATUS="$MOCK_GIT_STATUS"
    EXISTING_ORIGIN_STATUS="$MOCK_ORIGIN_STATUS"
    EXISTING_HISTORY_STATUS="$MOCK_HISTORY_STATUS"

    return 0
}


# -------------------------------------------------
# Mock confirmation
# -------------------------------------------------

confirm_action() {

    CONFIRM_CALLED=$((CONFIRM_CALLED + 1))

    return 0
}


confirm_action_reject() {

    CONFIRM_CALLED=$((CONFIRM_CALLED + 1))

    return 1
}


# -------------------------------------------------
# Mock push
# -------------------------------------------------

push_to_github() {

    PUSH_CALLED=$((PUSH_CALLED + 1))

    return 0
}


echo
echo "Testing CREP idempotency..."
echo


# =================================================
# Synchronized repository
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="synchronized"

handle_both_exist

assert_equals \
    "Synchronized repository performs no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Synchronized repository requires no confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Local-ahead repository
# Confirmation accepted
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="local_ahead"

confirm_action() {

    CONFIRM_CALLED=$((CONFIRM_CALLED + 1))

    return 0
}

handle_both_exist

assert_equals \
    "Local-ahead repository asks before pushing" \
    "1" \
    "$CONFIRM_CALLED"

assert_equals \
    "Local-ahead repository pushes after confirmation" \
    "1" \
    "$PUSH_CALLED"

cleanup_test_environment


# =================================================
# Local-ahead repository
# Confirmation rejected
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="local_ahead"

confirm_action() {

    CONFIRM_CALLED=$((CONFIRM_CALLED + 1))

    return 1
}

handle_both_exist

assert_equals \
    "Rejected local-ahead push asks for confirmation" \
    "1" \
    "$CONFIRM_CALLED"

assert_equals \
    "Rejected local-ahead push performs no push" \
    "0" \
    "$PUSH_CALLED"

cleanup_test_environment


# =================================================
# Remote-ahead repository
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="remote_ahead"

handle_both_exist

assert_equals \
    "Remote-ahead repository performs no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Remote-ahead repository asks no confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Diverged repository
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="diverged"

handle_both_exist

assert_equals \
    "Diverged repository performs no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Diverged repository asks no confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Unrelated histories
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="unrelated"

handle_both_exist

assert_equals \
    "Unrelated histories perform no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Unrelated histories ask no confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Dirty working tree
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="dirty"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="local_ahead"

confirm_action() {

    CONFIRM_CALLED=$((CONFIRM_CALLED + 1))

    return 0
}

handle_both_exist

assert_equals \
    "Dirty repository performs no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Dirty repository asks no synchronization confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Different origin
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="different"
MOCK_HISTORY_STATUS="local_ahead"

confirm_action() {

    CONFIRM_CALLED=$((CONFIRM_CALLED + 1))

    return 0
}

handle_both_exist

assert_equals \
    "Different origin performs no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Different origin asks no synchronization confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Unknown history
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="unknown"

handle_both_exist

assert_equals \
    "Unknown history performs no push" \
    "0" \
    "$PUSH_CALLED"

assert_equals \
    "Unknown history asks no confirmation" \
    "0" \
    "$CONFIRM_CALLED"

cleanup_test_environment


# =================================================
# Repeated synchronized execution
# =================================================

setup_test_environment
reset_idempotency_state

MOCK_WORKTREE_STATUS="clean"
MOCK_GIT_STATUS="exists"
MOCK_ORIGIN_STATUS="target"
MOCK_HISTORY_STATUS="synchronized"

handle_both_exist

first_push_count="$PUSH_CALLED"
first_confirm_count="$CONFIRM_CALLED"

PUSH_CALLED=0
CONFIRM_CALLED=0

handle_both_exist

second_push_count="$PUSH_CALLED"
second_confirm_count="$CONFIRM_CALLED"

assert_equals \
    "First synchronized execution performs no push" \
    "0" \
    "$first_push_count"

assert_equals \
    "First synchronized execution asks no confirmation" \
    "0" \
    "$first_confirm_count"

assert_equals \
    "Repeated synchronized execution performs no push" \
    "0" \
    "$second_push_count"

assert_equals \
    "Repeated synchronized execution asks no confirmation" \
    "0" \
    "$second_confirm_count"

cleanup_test_environment


echo
echo "CREP idempotency tests passed."