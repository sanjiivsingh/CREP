#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_plan.sh"
source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


# -----------------------------------------------------------
# Test doubles
# -----------------------------------------------------------

SELECTED_HANDLER=""

handle_both_exist() {
    SELECTED_HANDLER="both_exist"
    return 0
}

handle_local_only() {
    SELECTED_HANDLER="local_only"
    return 0
}

handle_github_only() {
    SELECTED_HANDLER="github_only"
    return 0
}

handle_neither_exist() {
    SELECTED_HANDLER="neither_exist"
    return 0
}


reset_plan_test() {

    initialize_state

    SELECTED_HANDLER=""
}


assert_handler_selected() {

    local description="$1"
    local expected="$2"

    assert_equals \
        "$description" \
        "$expected" \
        "$SELECTED_HANDLER"
}


echo
echo "Testing execute_repository_plan..."
echo


# -----------------------------------------------------------
# Both exist
# LOCAL=0 GITHUB=0
# -----------------------------------------------------------

reset_plan_test

LOCAL_STATUS=0
GITHUB_STATUS=0

execute_repository_plan >/dev/null

assert_handler_selected \
    "Both repositories exist selects both_exist" \
    "both_exist"


# -----------------------------------------------------------
# Local only
# LOCAL=0 GITHUB=1
# -----------------------------------------------------------

reset_plan_test

LOCAL_STATUS=0
GITHUB_STATUS=1

execute_repository_plan >/dev/null

assert_handler_selected \
    "Local repository only selects local_only" \
    "local_only"


# -----------------------------------------------------------
# GitHub only
# LOCAL=1 GITHUB=0
# -----------------------------------------------------------

reset_plan_test

LOCAL_STATUS=1
GITHUB_STATUS=0

execute_repository_plan >/dev/null

assert_handler_selected \
    "GitHub repository only selects github_only" \
    "github_only"


# -----------------------------------------------------------
# Neither exists
# LOCAL=1 GITHUB=1
# -----------------------------------------------------------

reset_plan_test

LOCAL_STATUS=1
GITHUB_STATUS=1

execute_repository_plan >/dev/null

assert_handler_selected \
    "Neither repository exists selects neither_exist" \
    "neither_exist"


# -----------------------------------------------------------
# GitHub state unknown
# GITHUB=2
# -----------------------------------------------------------

reset_plan_test

LOCAL_STATUS=0
GITHUB_STATUS=2

assert_failure \
    "Unknown GitHub state stops execution" \
    execute_repository_plan


assert_equals \
    "No handler selected when GitHub state is unknown" \
    "" \
    "$SELECTED_HANDLER"


# -----------------------------------------------------------
# Invalid repository state
# -----------------------------------------------------------

reset_plan_test

LOCAL_STATUS=2
GITHUB_STATUS=0

assert_failure \
    "Invalid repository state is rejected" \
    execute_repository_plan


assert_equals \
    "No handler selected for invalid state" \
    "" \
    "$SELECTED_HANDLER"


echo
echo "Repository plan tests passed."