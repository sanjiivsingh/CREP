#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_handlers.sh"

source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


# -----------------------------------------------------------
# Test state
# -----------------------------------------------------------

CALLED_FUNCTIONS=""
CONFIRM_RESULT=0


# -----------------------------------------------------------
# Record function call
# -----------------------------------------------------------

record_call() {

    local function_name="$1"

    if [[ -z "$CALLED_FUNCTIONS" ]]; then
        CALLED_FUNCTIONS="$function_name"
    else
        CALLED_FUNCTIONS="$CALLED_FUNCTIONS $function_name"
    fi
}


# -----------------------------------------------------------
# Reset test state
# -----------------------------------------------------------

reset_both_exist_test() {

    initialize_state

    CALLED_FUNCTIONS=""
    CONFIRM_RESULT=0
}


# -----------------------------------------------------------
# Test doubles
# -----------------------------------------------------------

inspect_existing_repository() {

    record_call "inspect_existing_repository"

    return 0
}


confirm_action() {

    record_call "confirm_action"

    return "$CONFIRM_RESULT"
}


push_to_github() {

    record_call "push_to_github"

    return 0
}


# -----------------------------------------------------------
# Run repository scenario
# -----------------------------------------------------------

run_both_exist_scenario() {

    local worktree_status="$1"
    local git_status="$2"
    local origin_status="$3"
    local history_status="$4"
    local confirm_result="${5:-0}"

    reset_both_exist_test

    # These variables are consumed by handle_both_exist().
    # shellcheck disable=SC2034
    EXISTING_WORKTREE_STATUS="$worktree_status"

    # shellcheck disable=SC2034
    EXISTING_GIT_STATUS="$git_status"

    # shellcheck disable=SC2034
    EXISTING_ORIGIN_STATUS="$origin_status"

    # shellcheck disable=SC2034
    EXISTING_HISTORY_STATUS="$history_status"

    CONFIRM_RESULT="$confirm_result"

    handle_both_exist >/dev/null
}


# ===========================================================
# Test suite
# ===========================================================

echo
echo "Testing handle_both_exist..."
echo


# ===========================================================
# Dirty working tree
# ===========================================================

run_both_exist_scenario \
    "dirty" \
    "exists" \
    "target" \
    "synchronized"

assert_called \
    "Dirty repository inspects existing repository" \
    "inspect_existing_repository" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Dirty repository does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Dirty repository does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Git repository not initialized
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "not_initialized" \
    "missing" \
    "unknown"

assert_not_called \
    "Uninitialized repository does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Uninitialized repository does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Git repository has no history
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "no_history" \
    "missing" \
    "unknown"

assert_not_called \
    "Repository without history does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Repository without history does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Origin missing
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "missing" \
    "unknown"

assert_not_called \
    "Missing origin does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Missing origin does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Origin points to different repository
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "different" \
    "unknown"

assert_not_called \
    "Different origin does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Different origin does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# History synchronized
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "synchronized"

assert_not_called \
    "Synchronized repository does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Synchronized repository does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Local ahead + accept
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "local_ahead" \
    0

assert_called \
    "Local-ahead repository asks for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Local-ahead repository pushes after confirmation" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Local ahead + decline
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "local_ahead" \
    1

assert_called \
    "Local-ahead repository asks for confirmation when declined" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Local-ahead repository does not push after rejection" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Remote ahead
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "remote_ahead"

assert_not_called \
    "Remote-ahead repository does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Remote-ahead repository does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Diverged histories
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "diverged"

assert_not_called \
    "Diverged repository does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Diverged repository does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Unrelated histories
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "unrelated"

assert_not_called \
    "Unrelated histories do not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Unrelated histories do not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Unknown history
# ===========================================================

run_both_exist_scenario \
    "clean" \
    "exists" \
    "target" \
    "unknown"

assert_not_called \
    "Unknown history does not ask for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Unknown history does not push changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'Repository both-exist tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1

fi

echo "Repository both-exist tests passed."