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

# No apt packages needed - GitHub CLI uses custom repository
apt_packages=()

pre_install() {
    log_info "Preparing to install GitHub CLI (gh)..."
    
    # Check if gh is already installed
    if command -v gh &> /dev/null; then
        log_warning "GitHub CLI is already installed: $(gh --version | head -n1)"
    fi
}

install() {
    log_info "Setting up GitHub CLI repository and installing..."
    
    # Ensure wget is available
    if ! type -p wget > /dev/null; then
        log_info "wget not found, installing..."
        sudo apt update && sudo apt install wget -y
    fi
    
    # Create keyrings directory
    sudo mkdir -p -m 755 /etc/apt/keyrings
    
    # Download and install the signing key
    local tmp_keyring=$(mktemp)
    if wget -nv -O"$tmp_keyring" https://cli.github.com/packages/githubcli-archive-keyring.gpg; then
        cat "$tmp_keyring" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        rm -f "$tmp_keyring"
    else
        log_error "Failed to download GitHub CLI GPG key"
        rm -f "$tmp_keyring"
        exit 1
    fi
    
    # Add the GitHub CLI repository
    sudo mkdir -p -m 755 /etc/apt/sources.list.d
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    # Update package list and install gh
    sudo apt update
    sudo apt install gh -y
}

post_install() {
    log_info "Verifying GitHub CLI installation..."
    
    # Verify gh installation
    if command -v gh &> /dev/null; then
        local version=$(gh --version | head -n1)
        log_success "GitHub CLI installed: $version"
        log_info "You can authenticate with: gh auth login"
    else
        log_error "GitHub CLI installation failed"
        exit 1
    fi
}

# Main execution logic
# This allows the script to be run standalone
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting standalone execution of GitHub CLI installation..."
    
    pre_install
    install
    post_install
    
    log_success "GitHub CLI installation finished."
fi
