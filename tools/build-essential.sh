#!/bin/bash

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Correctly resolve project root assuming script is in tools/
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utility functions if available
if [ -f "$PROJECT_ROOT/lib/utils.sh" ]; then
    source "$PROJECT_ROOT/lib/utils.sh"
else
    # Fallback if utils not found (for standalone execution outside project structure)
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_warning() { echo "[WARNING] $1"; }
    log_error() { echo "[ERROR] $1"; }
    install_apt_packages() {
        sudo apt update && sudo apt install -y "$@"
    }
fi

# Essential build tools (gcc, g++, make, libc-dev, etc.)
apt_packages=("build-essential")

pre_install() {
    log_info "Checking for existing build tools..."
}

install() {
    if [ ${#apt_packages[@]} -gt 0 ]; then
        install_apt_packages "${apt_packages[@]}"
    fi
}

post_install() {
    log_info "Verifying build-essential installation..."
    
    # Verify gcc installation as representative check
    if command -v gcc &> /dev/null; then
        log_success "build-essential installed: gcc $(gcc --version | head -n1 | grep -oP '\d+\.\d+\.\d+')"
    else
        log_error "build-essential installation failed"
        exit 1
    fi
    
    # Additional verification for make
    if command -v make &> /dev/null; then
        log_success "make available: $(make --version | head -n1)"
    fi
}

# Main execution logic
# This allows the script to be run standalone
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting standalone execution of build-essential installation..."
    
    pre_install
    install
    post_install
    
    log_success "Build-essential installation finished."
fi
