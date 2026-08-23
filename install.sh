#!/usr/bin/env bash

set -euo pipefail

# ===============================================================
# CREP Installer
# ===============================================================

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREP_VERSION="$(cat "$CREP_ROOT/VERSION")"

INSTALL_ROOT="${CREP_INSTALL_ROOT:-$HOME/.local/share/crep}"
BIN_DIR="${CREP_BIN_DIR:-$HOME/.local/bin}"
LAUNCHER="$BIN_DIR/crep"

# Set CREP_INSTALL_FAST=true for automated tests.
CREP_INSTALL_FAST="${CREP_INSTALL_FAST:-false}"


# ===============================================================
# Terminal Colors & Formatting
# ===============================================================

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'


# ===============================================================
# Output Helpers
# ===============================================================

print_error() {
    printf '%bError:%b %s\n' "$RED" "$RESET" "$1"
}

print_success() {
    printf '%bSuccess:%b %s\n' "$GREEN" "$RESET" "$1"
}

print_warning() {
    printf '%bWarning:%b %s\n' "$YELLOW" "$RESET" "$1"
}

print_info() {
    printf '%-25s : %b\n' "$1" "$2"
}


# ===============================================================
# Animation
# ===============================================================

pause() {

    if [[ "$CREP_INSTALL_FAST" == true ]]; then
        return 0
    fi

    sleep "${1:-0.35}"
}


show_progress_bar() {

    local current="$1"
    local total="$2"
    local width=40
    local percent
    local filled
    local empty

    percent=$((current * 100 / total))
    filled=$((current * width / total))
    empty=$((width - filled))

    printf '\r    '

    if [[ "$filled" -gt 0 ]]; then
        printf '%*s' "$filled" '' | tr ' ' '█'
    fi

    if [[ "$empty" -gt 0 ]]; then
        printf '%*s' "$empty" '' | tr ' ' '░'
    fi

    printf ' %3d%%' "$percent"
}


animate_progress() {

    local duration="${1:-0.8}"
    local steps=20
    local step

    if [[ "$CREP_INSTALL_FAST" == true ]]; then
        show_progress_bar "$steps" "$steps"
        printf '\n'
        return 0
    fi

    for ((step = 1; step <= steps; step++)); do

        show_progress_bar "$step" "$steps"

        sleep "$(awk "BEGIN { print $duration / $steps }")"

    done

    printf '\n'
}


show_spinner() {

    local message="$1"
    local duration="${2:-0.8}"

    if [[ "$CREP_INSTALL_FAST" == true ]]; then
        printf "    %s %b✓%b\n" \
            "$message" \
            "$GREEN$BOLD" \
            "$RESET"
        return 0
    fi

    local spinner="|/-\\"
    local start
    local elapsed
    local index=0

    start="$(date +%s)"

    while true; do

        elapsed=$(( $(date +%s) - start ))

        if [[ "$elapsed" -ge 1 ]]; then
            break
        fi

        printf '\r    %s %s' \
            "$message" \
            "${spinner:index:1}"

        index=$(( (index + 1) % 4 ))

        sleep 0.08
    done

    printf '\r    %s %b✓%b\n' \
        "$message" \
        "$GREEN$BOLD" \
        "$RESET"
}


# ===============================================================
# Installer Banner
# ===============================================================

show_installer_banner() {

    clear 2>/dev/null || true

    echo

    printf "%b\n" \
        "${RED}${BOLD}  ██████╗ ██████╗ ███████╗██████╗${RESET}"

    printf "%b\n" \
        "${RED}${BOLD} ██╔════╝ ██╔══██╗██╔════╝██╔══██╗${RESET}"

    printf "%b\n" \
        "${RED}${BOLD} ██║      ██████╔╝█████╗  ██████╔╝${RESET}"

    printf "%b\n" \
        "${RED}${BOLD} ██║      ██╔══██╗██╔══╝  ██╔═══╝${RESET}"

    printf "%b\n" \
        "${RED}${BOLD} ╚██████╗ ██║  ██║███████╗██║${RESET}"

    printf "%b\n" \
        "${RED}${BOLD}  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝${RESET}"

    echo

    printf "%b\n" \
        "${BOLD}${GREEN}  Code Repository Environment Provisioner${RESET}"

    printf "%b\n" \
        "  GitHub + Git project lifecycle automation"

    printf "%b\n" \
        "${DIM}  Installer • Version ${CREP_VERSION}${RESET}"

    echo
}


# ===============================================================
# Validation
# ===============================================================

validate_installer() {

    if [[ ! -f "$CREP_ROOT/VERSION" ]]; then
        print_error "VERSION file not found."
        return 1
    fi

    if [[ ! -x "$CREP_ROOT/bin/crep" ]]; then
        print_error "CREP executable not found or not executable."
        return 1
    fi

    if [[ ! -d "$CREP_ROOT/lib" ]]; then
        print_error "CREP library directory not found."
        return 1
    fi

    if ! command -v bash >/dev/null 2>&1; then
        print_error "Bash is required."
        return 1
    fi

    return 0
}


# ===============================================================
# Verification
# ===============================================================

verify_installation() {

    if [[ ! -x "$LAUNCHER" ]]; then
        print_error "CREP launcher was not installed."
        return 1
    fi

    if [[ ! -x "$INSTALL_ROOT/bin/crep" ]]; then
        print_error "CREP executable was not installed."
        return 1
    fi

    local installed_version

    installed_version="$(
        "$INSTALL_ROOT/bin/crep" --version 2>/dev/null
    )"

    if [[ "$installed_version" != "CREP $CREP_VERSION" ]]; then

        print_error "Installed CREP version verification failed."

        print_info "Expected" "CREP $CREP_VERSION"
        print_info "Actual" "$installed_version"

        return 1
    fi

    return 0
}


# ===============================================================
# Installation
# ===============================================================

install_crep() {

    echo
    printf "%b\n" \
        "${BLUE}${BOLD}==> Installing CREP ${CREP_VERSION}${RESET}"

    echo


    # -----------------------------------------------------------
    # Validate
    # -----------------------------------------------------------

    printf "%b\n" \
        "${BLUE}==> Validating installation${RESET}"

    validate_installer

    pause 0.4

    printf "    %b✓%b Environment validated\n" \
        "$GREEN$BOLD" "$RESET"


    # -----------------------------------------------------------
    # Prepare
    # -----------------------------------------------------------

    printf "%b\n" \
        "${BLUE}==> Preparing installation directories${RESET}"

    mkdir -p "$BIN_DIR"

    rm -rf "$INSTALL_ROOT"

    mkdir -p "$INSTALL_ROOT"

    pause 0.5

    printf "    %b✓%b Installation directory ready\n" \
        "$GREEN$BOLD" "$RESET"


    # -----------------------------------------------------------
    # Install application
    # -----------------------------------------------------------

    printf "%b\n" \
        "${BLUE}==> Installing CREP application${RESET}"

    show_spinner "Copying application files"

    cp -R "$CREP_ROOT/bin" "$INSTALL_ROOT/"
    cp -R "$CREP_ROOT/lib" "$INSTALL_ROOT/"
    cp "$CREP_ROOT/VERSION" "$INSTALL_ROOT/"

    chmod +x "$INSTALL_ROOT/bin/crep"

    printf "    %b✓%b Application installed\n" \
        "$GREEN$BOLD" "$RESET"


    # -----------------------------------------------------------
    # Install launcher
    # -----------------------------------------------------------

    printf "%b\n" \
        "${BLUE}==> Installing command launcher${RESET}"

    show_spinner "Creating global launcher"

    cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash

exec "$INSTALL_ROOT/bin/crep" "\$@"
EOF

    chmod +x "$LAUNCHER"

    printf "    %b✓%b Launcher installed\n" \
        "$GREEN$BOLD" "$RESET"


    # -----------------------------------------------------------
    # Verification
    # -----------------------------------------------------------

    printf "%b\n" \
        "${BLUE}==> Verifying installation${RESET}"

    show_spinner "Checking installed files"

    verify_installation

    printf "    %b✓%b Installation verified\n" \
        "$GREEN$BOLD" "$RESET"


    # -----------------------------------------------------------
    # Progress
    # -----------------------------------------------------------

    echo
    printf "%b\n" \
        "${BLUE}${BOLD}==> Finalizing${RESET}"

    animate_progress 0.9

    echo
}


# ===============================================================
# PATH Guidance
# ===============================================================

show_path_guidance() {

    # -----------------------------------------------------------
    # Custom installation directory
    # -----------------------------------------------------------

    if [[ -n "${CREP_BIN_DIR:-}" ]]; then

        print_info "Binary directory" "$BIN_DIR"
        print_info "Installation mode" "isolated/test"

        return 0
    fi


    # -----------------------------------------------------------
    # Standard installation directory
    # -----------------------------------------------------------

    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then

        print_success "CREP is installed and available in PATH."

        echo

        print_info "Command" "crep --version"

        return 0
    fi


    # -----------------------------------------------------------
    # PATH configuration required
    # -----------------------------------------------------------

    print_warning "$BIN_DIR is not currently in PATH."

    echo

    echo "Add the following line to your shell configuration:"
    echo

    printf '%s\n' \
        "export PATH=\"\$HOME/.local/bin:\$PATH\""

    echo

    echo "Then start a new shell or reload your configuration."
}


# ===============================================================
# Main
# ===============================================================

main() {

    show_installer_banner

    print_info "CREP version" "$CREP_VERSION"
    print_info "Install directory" "$INSTALL_ROOT"
    print_info "Binary directory" "$BIN_DIR"

    install_crep

    echo

    printf "%b\n" \
        "${GREEN}${BOLD}  🍺 CREP ${CREP_VERSION} installed successfully.${RESET}"

    echo

    show_path_guidance

    echo

    print_success "Installation complete."

    echo
}


main "$@"