#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_skip() {
    echo -e "${YELLOW}[SKIPPED]${NC} $1"
}

# Function to install packages via apt
install_apt_packages() {
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi
    
    log_info "Installing apt packages: ${packages[*]}"
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN: Would execute: sudo apt install -y ${packages[*]}"
        return 0
    fi
    
    sudo apt update
    sudo apt install -y "${packages[@]}"
}
