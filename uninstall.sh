#!/usr/bin/env bash

set -euo pipefail

# ===============================================================
# CREP Uninstaller
# ===============================================================


INSTALL_ROOT="${CREP_INSTALL_ROOT:-$HOME/.local/share/crep}"
BIN_DIR="${CREP_BIN_DIR:-$HOME/.local/bin}"
LAUNCHER="$BIN_DIR/crep"


# ===============================================================
# Output
# ===============================================================

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'


print_success() {
    printf "%bSuccess:%b %s\n" "$GREEN" "$RESET" "$1"
}

print_error() {
    printf "%bError:%b %s\n" "$RED" "$RESET" "$1"
}

print_warning() {
    printf "%bWarning:%b %s\n" "$YELLOW" "$RESET" "$1"
}


# ===============================================================
# Uninstallation
# ===============================================================

uninstall_crep() {

    local removed=false


    # -----------------------------------------------------------
    # Remove installed application
    # -----------------------------------------------------------

    if [[ -d "$INSTALL_ROOT" ]]; then

        rm -rf "$INSTALL_ROOT"

        print_success "CREP installation directory removed."

        removed=true

    fi


    # -----------------------------------------------------------
    # Remove launcher
    # -----------------------------------------------------------

    if [[ -e "$LAUNCHER" ]]; then

        rm -f "$LAUNCHER"

        print_success "CREP launcher removed."

        removed=true

    fi


    # -----------------------------------------------------------
    # Nothing installed
    # -----------------------------------------------------------

    if [[ "$removed" == false ]]; then

        print_warning "CREP is not installed."

        return 0

    fi


    return 0
}


# ===============================================================
# Verification
# ===============================================================

verify_uninstallation() {

    if [[ -e "$INSTALL_ROOT" ]]; then

        print_error \
            "CREP installation directory still exists."

        return 1

    fi


    if [[ -e "$LAUNCHER" ]]; then

        print_error \
            "CREP launcher still exists."

        return 1

    fi


    return 0
}


# ===============================================================
# Main
# ===============================================================

main() {

    echo
    printf "%s\n" "CREP Uninstaller"
    printf "%s\n" "Code Repository Environment Provisioner"
    echo

    uninstall_crep || {

        print_error "CREP uninstallation failed."

        exit 1
    }


    if verify_uninstallation; then

        print_success "CREP uninstalled successfully."

    else

        print_error "CREP uninstallation verification failed."

        exit 1
    fi
}


main "$@"