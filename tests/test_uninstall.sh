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

    INSTALL_ROOT="$TEST_ROOT/install/crep"
    BIN_DIR="$TEST_ROOT/bin"

    mkdir -p "$INSTALL_ROOT/bin"
    mkdir -p "$BIN_DIR"

    printf '%s\n' "test installation" \
        > "$INSTALL_ROOT/VERSION"

    printf '%s\n' "#!/usr/bin/env bash" \
        > "$INSTALL_ROOT/bin/crep"

    chmod +x "$INSTALL_ROOT/bin/crep"

    printf '%s\n' "#!/usr/bin/env bash" \
        > "$BIN_DIR/crep"

    chmod +x "$BIN_DIR/crep"
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
echo "Testing CREP uninstaller..."
echo


# =================================================
# Installed CREP
# =================================================

setup_test_environment

output="$(
    CREP_INSTALL_ROOT="$INSTALL_ROOT" \
    CREP_BIN_DIR="$BIN_DIR" \
    "$CREP_ROOT/uninstall.sh"
)"

assert_contains \
    "Uninstaller reports installation removal" \
    "$output" \
    "CREP installation directory removed."

assert_contains \
    "Uninstaller reports launcher removal" \
    "$output" \
    "CREP launcher removed."

assert_contains \
    "Uninstaller reports successful completion" \
    "$output" \
    "CREP uninstalled successfully."


# -------------------------------------------------
# Verify files are gone
# -------------------------------------------------

if [[ ! -e "$INSTALL_ROOT" ]]; then

    printf 'PASS: Installation directory removed\n'

else

    printf 'FAIL: Installation directory still exists\n'

    exit 1
fi


if [[ ! -e "$BIN_DIR/crep" ]]; then

    printf 'PASS: Launcher removed\n'

else

    printf 'FAIL: Launcher still exists\n'

    exit 1
fi


cleanup_test_environment


# =================================================
# Already uninstalled
# =================================================

setup_test_environment

rm -rf "$INSTALL_ROOT"
rm -f "$BIN_DIR/crep"

output="$(
    CREP_INSTALL_ROOT="$INSTALL_ROOT" \
    CREP_BIN_DIR="$BIN_DIR" \
    "$CREP_ROOT/uninstall.sh"
)"

assert_contains \
    "Uninstaller safely handles missing installation" \
    "$output" \
    "CREP is not installed."

assert_contains \
    "Missing installation exits successfully" \
    "$output" \
    "CREP uninstalled successfully."


cleanup_test_environment


# =================================================
# Result
# =================================================

echo
echo "CREP uninstaller tests passed."