#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


# -----------------------------------------------------------
# Load CREP modules
# -----------------------------------------------------------

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_handlers.sh"

source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


# -----------------------------------------------------------
# Test environment
# -----------------------------------------------------------

TEST_DIR=""


setup_handler_test_environment() {

    TEST_DIR="$(mktemp -d)"
}


cleanup_handler_test_environment() {

    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}


trap cleanup_handler_test_environment EXIT


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
# Reset handler test
# -----------------------------------------------------------

reset_handler_test() {

    initialize_state

    CALLED_FUNCTIONS=""
    CONFIRM_RESULT=0
}


# ===========================================================
# Test doubles
# ===========================================================

build_gh_command() {

    record_call "build_gh_command"
}


confirm_action() {

    record_call "confirm_action"

    return "$CONFIRM_RESULT"
}


create_github_repository() {

    record_call "create_github_repository"
}


prepare_existing_local() {

    record_call "prepare_existing_local"
}


configure_existing_git() {

    record_call "configure_existing_git"
}


initialize_git() {

    record_call "initialize_git"
}


configure_git_remote() {

    record_call "configure_git_remote"
}


commit_changes() {

    record_call "commit_changes"
}


push_to_github() {

    record_call "push_to_github"
}


clone_github_repository() {

    record_call "clone_github_repository"
}


create_local_directory() {

    record_call "create_local_directory"
}


copy_readme() {

    record_call "copy_readme"
}


create_gitignore() {

    record_call "create_gitignore"
}


# ===========================================================
# Test suite
# ===========================================================

echo
echo "Testing repository handlers..."
echo


# ===========================================================
# handle_github_only
# ===========================================================

echo
echo "Testing handle_github_only..."
echo


# -----------------------------------------------------------
# User accepts clone
# -----------------------------------------------------------

reset_handler_test

CONFIRM_RESULT=0

handle_github_only >/dev/null

assert_called \
    "GitHub-only handler asks for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_called \
    "GitHub-only handler clones repository after confirmation" \
    "clone_github_repository" \
    "$CALLED_FUNCTIONS"


# -----------------------------------------------------------
# User declines clone
# -----------------------------------------------------------

reset_handler_test

CONFIRM_RESULT=1

handle_github_only >/dev/null

assert_called \
    "GitHub-only handler asks for confirmation when declined" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "GitHub-only handler does not clone after rejection" \
    "clone_github_repository" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# handle_neither_exist
# ===========================================================

echo
echo "Testing handle_neither_exist..."
echo


# -----------------------------------------------------------
# Neither exists + no local project
# -----------------------------------------------------------

reset_handler_test

CREATE_LOCAL=false
CONFIRM_RESULT=0

handle_neither_exist >/dev/null

assert_called \
    "Neither-exist handler builds GitHub command" \
    "build_gh_command" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Neither-exist handler asks for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Neither-exist handler creates GitHub repository" \
    "create_github_repository" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "No local project is created when CREATE_LOCAL is false" \
    "create_local_directory" \
    "$CALLED_FUNCTIONS"


# -----------------------------------------------------------
# Neither exists + local project
# -----------------------------------------------------------

reset_handler_test

CREATE_LOCAL=true
CONFIRM_RESULT=0

handle_neither_exist >/dev/null

assert_called \
    "Local project is created when enabled" \
    "create_local_directory" \
    "$CALLED_FUNCTIONS"

assert_called \
    "README preparation is performed" \
    "copy_readme" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Gitignore preparation is performed" \
    "create_gitignore" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Git repository is initialized" \
    "initialize_git" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Git remote is configured" \
    "configure_git_remote" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Changes are committed" \
    "commit_changes" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Changes are pushed" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# -----------------------------------------------------------
# Neither exists + user declines
# -----------------------------------------------------------

reset_handler_test

CREATE_LOCAL=true
CONFIRM_RESULT=1

handle_neither_exist >/dev/null

assert_called \
    "Neither-exist handler asks for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Repository is not created after rejection" \
    "create_github_repository" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Local project is not created after rejection" \
    "create_local_directory" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Changes are not pushed after rejection" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"


# ===========================================================
# handle_local_only
# ===========================================================

echo
echo "Testing handle_local_only..."
echo


# -----------------------------------------------------------
# Local directory is not a Git repository
# -----------------------------------------------------------

setup_handler_test_environment

reset_handler_test

LOCAL_PATH="$TEST_DIR/non-git-project"

mkdir -p "$LOCAL_PATH"

CONFIRM_RESULT=0

handle_local_only >/dev/null

assert_called \
    "Local-only handler builds GitHub command" \
    "build_gh_command" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Local-only handler asks for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Local-only handler creates GitHub repository" \
    "create_github_repository" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Local-only handler prepares existing project" \
    "prepare_existing_local" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Non-Git project is initialized" \
    "initialize_git" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Git remote is configured for new Git repository" \
    "configure_git_remote" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Existing Git configuration is not used for non-Git project" \
    "configure_existing_git" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Local-only handler commits changes" \
    "commit_changes" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Local-only handler pushes changes" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"

cleanup_handler_test_environment
TEST_DIR=""


# -----------------------------------------------------------
# Existing Git repository
# -----------------------------------------------------------

setup_handler_test_environment

reset_handler_test

LOCAL_PATH="$TEST_DIR/existing-git"

mkdir -p "$LOCAL_PATH"

git -C "$LOCAL_PATH" init -q

CONFIRM_RESULT=0

handle_local_only >/dev/null

assert_called \
    "Existing Git repository is detected" \
    "configure_existing_git" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Existing Git repository is not reinitialized" \
    "initialize_git" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Existing Git repository does not use new remote configuration" \
    "configure_git_remote" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Existing Git project is committed" \
    "commit_changes" \
    "$CALLED_FUNCTIONS"

assert_called \
    "Existing Git project is pushed" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"

cleanup_handler_test_environment
TEST_DIR=""


# -----------------------------------------------------------
# Local-only + user declines
# -----------------------------------------------------------

setup_handler_test_environment

reset_handler_test

LOCAL_PATH="$TEST_DIR/project"

mkdir -p "$LOCAL_PATH"

CONFIRM_RESULT=1

handle_local_only >/dev/null

assert_called \
    "Local-only handler asks for confirmation" \
    "confirm_action" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "GitHub repository is not created after rejection" \
    "create_github_repository" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Existing project is not prepared after rejection" \
    "prepare_existing_local" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Changes are not committed after rejection" \
    "commit_changes" \
    "$CALLED_FUNCTIONS"

assert_not_called \
    "Changes are not pushed after rejection" \
    "push_to_github" \
    "$CALLED_FUNCTIONS"

cleanup_handler_test_environment
TEST_DIR=""


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'Repository handler tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1

fi

echo "Repository handler tests passed."