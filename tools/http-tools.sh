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

# HTTP download tools
apt_packages=("curl" "wget")

pre_install() {
    log_info "Checking for existing HTTP tools installations..."
}

install() {
    if [ ${#apt_packages[@]} -gt 0 ]; then
        install_apt_packages "${apt_packages[@]}"
    fi
}

post_install() {
    log_info "Verifying HTTP tools installations..."
    
    # Verify curl installation
    if command -v curl &> /dev/null; then
        log_success "curl installed: $(curl --version | head -n1)"
    else
        log_error "curl installation failed"
        exit 1
    fi
    
    # Verify wget installation
    if command -v wget &> /dev/null; then
        log_success "wget installed: $(wget --version | head -n1)"
    else
        log_error "wget installation failed"
        exit 1
    fi
}

# Main execution logic
# This allows the script to be run standalone
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting standalone execution of HTTP tools installation..."
    
    pre_install
    install
    post_install
    
    log_success "HTTP tools installation finished."
fi
