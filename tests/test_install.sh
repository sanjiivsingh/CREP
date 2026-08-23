#!/usr/bin/env bash

set -euo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/tests/assertions.sh"

TEST_ROOT=""
INSTALL_ROOT=""
BIN_DIR=""


# -------------------------------------------------
# Test setup
# -------------------------------------------------

setup_test_environment() {

    TEST_ROOT="$(mktemp -d)"

    INSTALL_ROOT="$TEST_ROOT/install"
    BIN_DIR="$TEST_ROOT/bin"

    mkdir -p "$INSTALL_ROOT"
    mkdir -p "$BIN_DIR"
}


cleanup_test_environment() {

    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi

    TEST_ROOT=""
    INSTALL_ROOT=""
    BIN_DIR=""
}


trap cleanup_test_environment EXIT


# -------------------------------------------------
# Test header
# -------------------------------------------------

echo
echo "Testing CREP installer..."
echo


# =================================================
# Fresh installation
# =================================================

setup_test_environment

output="$(
    CREP_INSTALL_ROOT="$INSTALL_ROOT/crep" \
    CREP_BIN_DIR="$BIN_DIR" \
    "$CREP_ROOT/install.sh"
)"

assert_contains \
    "Installer reports successful installation" \
    "$output" \
    "CREP installed successfully."

assert_contains \
    "Installer reports completion" \
    "$output" \
    "Installation complete."

assert_file_exists \
    "Installed CREP executable exists" \
    "$INSTALL_ROOT/crep/bin/crep"

assert_file_exists \
    "Installed VERSION exists" \
    "$INSTALL_ROOT/crep/VERSION"

assert_file_exists \
    "Installed launcher exists" \
    "$BIN_DIR/crep"

assert_executable \
    "Installed CREP executable is executable" \
    "$INSTALL_ROOT/crep/bin/crep"

assert_executable \
    "Installed launcher is executable" \
    "$BIN_DIR/crep"


# =================================================
# Version verification
# =================================================

installed_version="$(
    "$INSTALL_ROOT/crep/bin/crep" --version
)"

expected_version="$(
    cat "$CREP_ROOT/VERSION"
)"

assert_equals \
    "Installed version matches project version" \
    "CREP $expected_version" \
    "$installed_version"


# =================================================
# Launcher verification
# =================================================

launcher_version="$(
    "$BIN_DIR/crep" --version
)"

assert_equals \
    "Launcher executes installed CREP" \
    "CREP $expected_version" \
    "$launcher_version"


# =================================================
# Idempotent installation
# =================================================

first_marker="$INSTALL_ROOT/crep/test-marker"

printf '%s\n' "old installation" > "$first_marker"

output="$(
    CREP_INSTALL_ROOT="$INSTALL_ROOT/crep" \
    CREP_BIN_DIR="$BIN_DIR" \
    "$CREP_ROOT/install.sh"
)"

assert_contains \
    "Repeated installation succeeds" \
    "$output" \
    "Installation complete."

if [[ -e "$first_marker" ]]; then

    printf 'FAIL: Reinstallation replaces previous installation\n'

    exit 1

else

    printf 'PASS: Reinstallation replaces previous installation\n'

fi


# =================================================
# Final verification
# =================================================

assert_file_exists \
    "Reinstalled CREP executable exists" \
    "$INSTALL_ROOT/crep/bin/crep"

assert_equals \
    "Reinstalled launcher works" \
    "CREP $expected_version" \
    "$("$BIN_DIR/crep" --version)"


# =================================================
# Result
# =================================================

echo
echo "CREP installer tests passed."