#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/arguments.sh"
source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"

assert_parse_failure() {

    local description="$1"
    shift

    reset_test_state

    if parse_arguments "$@"; then
        printf 'FAIL: %s\n' "$description"
        return 1
    fi

    printf 'PASS: %s\n' "$description"
    return 0
}


echo
echo "Testing parse_arguments..."
echo


# -----------------------------------------------------------
# Repository name
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project"

assert_equals \
    "Repository name is parsed" \
    "my-project" \
    "$REPO_NAME"


# -----------------------------------------------------------
# --private
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" --private

assert_equals \
    "Private visibility is parsed" \
    "private" \
    "$VISIBILITY"


# -----------------------------------------------------------
# --public
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" --public

assert_equals \
    "Public visibility is parsed" \
    "public" \
    "$VISIBILITY"


# -----------------------------------------------------------
# --local without path
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" --local

assert_equals \
    "Local project is enabled" \
    "true" \
    "$CREATE_LOCAL"

assert_equals \
    "Default local path is generated" \
    "./my-project" \
    "$LOCAL_PATH"


# -----------------------------------------------------------
# --local with path
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" --local ./projects/my-project

assert_equals \
    "Custom local path is parsed" \
    "./projects/my-project" \
    "$LOCAL_PATH"


# -----------------------------------------------------------
# --readme
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" --readme README-template.md

assert_equals \
    "README file is parsed" \
    "README-template.md" \
    "$README_FILE"


# -----------------------------------------------------------
# --gitignore
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" --gitignore Terraform

assert_equals \
    "Gitignore template is parsed" \
    "Terraform" \
    "$GITIGNORE_TEMPLATE"


# -----------------------------------------------------------
# --description
# -----------------------------------------------------------

reset_test_state

parse_arguments "my-project" \
    --description "Terraform Azure foundation"

assert_equals \
    "Description is parsed" \
    "Terraform Azure foundation" \
    "$DESCRIPTION"


# -----------------------------------------------------------
# --help
# -----------------------------------------------------------

reset_test_state

parse_arguments --help

assert_equals \
    "Help action is selected" \
    "help" \
    "$CLI_ACTION"


# -----------------------------------------------------------
# --version
# -----------------------------------------------------------

reset_test_state

parse_arguments --version

assert_equals \
    "Version action is selected" \
    "version" \
    "$CLI_ACTION"


echo
echo "Argument parser tests passed."

# -----------------------------------------------------------
# Invalid argument handling
# -----------------------------------------------------------

assert_parse_failure \
    "Unknown option is rejected" \
    --unknown

assert_parse_failure \
    "--readme without value is rejected" \
    my-project --readme

assert_parse_failure \
    "--readme followed by another option is rejected" \
    my-project --readme --private

assert_parse_failure \
    "--gitignore without value is rejected" \
    my-project --gitignore

assert_parse_failure \
    "--gitignore followed by another option is rejected" \
    my-project --gitignore --private

assert_parse_failure \
    "--description without value is rejected" \
    my-project --description

assert_parse_failure \
    "Unexpected second positional argument is rejected" \
    my-project another-project