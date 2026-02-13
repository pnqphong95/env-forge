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

# Software properties for PPA management
apt_packages=("software-properties-common")

pre_install() {
    log_info "Checking for existing software-properties installation..."
}

install() {
    if [ ${#apt_packages[@]} -gt 0 ]; then
        install_apt_packages "${apt_packages[@]}"
    fi
}

post_install() {
    log_info "Verifying software-properties installation..."
    
    # Verify add-apt-repository command is available
    if command -v add-apt-repository &> /dev/null; then
        log_success "software-properties-common installed: add-apt-repository available"
    else
        log_error "software-properties-common installation failed"
        exit 1
    fi
}

# Main execution logic
# This allows the script to be run standalone
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting standalone execution of software-properties installation..."
    
    pre_install
    install
    post_install
    
    log_success "Software-properties installation finished."
fi
