#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_state.sh"
source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"

export PATH="$CREP_ROOT/tests/mocks:$PATH"

TEST_DIR=""


setup_test_environment() {

    TEST_DIR="$(mktemp -d)"
}


cleanup_test_environment() {

    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}


trap cleanup_test_environment EXIT


echo
echo "Testing repository state..."
echo


# -----------------------------------------------------------
# Local directory exists
# -----------------------------------------------------------

setup_test_environment

assert_success \
    "Existing local directory is detected" \
    check_local_directory "$TEST_DIR"

cleanup_test_environment
TEST_DIR=""


# -----------------------------------------------------------
# Local directory does not exist
# -----------------------------------------------------------

setup_test_environment

missing_path="$TEST_DIR/missing"

assert_failure \
    "Missing local directory is detected" \
    check_local_directory "$missing_path"

cleanup_test_environment
TEST_DIR=""


# -----------------------------------------------------------
# Path exists but is a file
# -----------------------------------------------------------

setup_test_environment

file_path="$TEST_DIR/test-file"

touch "$file_path"

assert_failure \
    "File is not detected as a local directory" \
    check_local_directory "$file_path"

cleanup_test_environment
TEST_DIR=""




# -----------------------------------------------------------
# GitHub repository exists
# -----------------------------------------------------------

reset_test_state

GITHUB_USER="test-user"

assert_success \
    "Existing GitHub repository is detected" \
    check_github_repository "existing-repo"


# -----------------------------------------------------------
# GitHub repository does not exist
# -----------------------------------------------------------

reset_test_state

GITHUB_USER="test-user"

assert_failure \
    "Missing GitHub repository is detected" \
    check_github_repository "missing-repo"


# -----------------------------------------------------------
# GitHub API failure
# -----------------------------------------------------------

reset_test_state

GITHUB_USER="test-user"

if check_github_repository "error-repo"; then

    printf 'FAIL: GitHub API failure returns status 2\n'
    exit 1

else

    github_status=$?

fi

assert_equals \
    "GitHub API failure returns status 2" \
    "2" \
    "$github_status"


# -----------------------------------------------------------
# GitHub username
# -----------------------------------------------------------

reset_test_state

github_user="$(get_github_username)"

assert_equals \
    "GitHub username is retrieved" \
    "test-user" \
    "$github_user"


# -----------------------------------------------------------
# determine_repository_state()
# -----------------------------------------------------------

echo
echo "Testing determine_repository_state..."
echo

setup_test_environment


# -----------------------------------------------------------
# Neither exists
# -----------------------------------------------------------

reset_test_state

REPO_NAME="missing-repo"
LOCAL_PATH="$TEST_DIR/missing"

determine_repository_state

assert_equals \
    "Neither exists - local status" \
    "1" \
    "$LOCAL_STATUS"

assert_equals \
    "Neither exists - GitHub status" \
    "1" \
    "$GITHUB_STATUS"


# -----------------------------------------------------------
# GitHub exists, local does not
# -----------------------------------------------------------

reset_test_state

REPO_NAME="existing-repo"
LOCAL_PATH="$TEST_DIR/missing"

determine_repository_state

assert_equals \
    "GitHub only - local status" \
    "1" \
    "$LOCAL_STATUS"

assert_equals \
    "GitHub only - GitHub status" \
    "0" \
    "$GITHUB_STATUS"


# -----------------------------------------------------------
# Local exists, GitHub does not
# -----------------------------------------------------------

reset_test_state

REPO_NAME="missing-repo"
LOCAL_PATH="$TEST_DIR/existing"

mkdir -p "$LOCAL_PATH"

determine_repository_state

assert_equals \
    "Local only - local status" \
    "0" \
    "$LOCAL_STATUS"

assert_equals \
    "Local only - GitHub status" \
    "1" \
    "$GITHUB_STATUS"


# -----------------------------------------------------------
# Both exist
# -----------------------------------------------------------

reset_test_state

REPO_NAME="existing-repo"
LOCAL_PATH="$TEST_DIR/existing"

mkdir -p "$LOCAL_PATH"

determine_repository_state

assert_equals \
    "Both exist - local status" \
    "0" \
    "$LOCAL_STATUS"

assert_equals \
    "Both exist - GitHub status" \
    "0" \
    "$GITHUB_STATUS"


# -----------------------------------------------------------
# GitHub API failure through determine_repository_state()
# -----------------------------------------------------------

reset_test_state

REPO_NAME="error-repo"
LOCAL_PATH="$TEST_DIR/missing"

determine_repository_state

assert_equals \
    "GitHub API failure is preserved" \
    "2" \
    "$GITHUB_STATUS"


echo
echo "Repository state tests passed."