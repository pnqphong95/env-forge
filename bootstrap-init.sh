#!/bin/bash

# envforge Bootstrap Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/pnqphong95/envforge/master/bootstrap-init.sh | bash
# Usage with version: curl -fsSL https://raw.githubusercontent.com/pnqphong95/envforge/1.0.0/bootstrap-init.sh | bash -s 1.0.0

set -e  # Exit on error

# Configuration
INSTALL_DIR="$HOME/.envforge"
REPO_URL="https://github.com/pnqphong95/envforge.git"
ENV_FORGE_VERSION="${ENV_FORGE_VERSION:-${1:-master}}" 

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

# Check OS compatibility
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint|pop)
                log_success "Supported OS detected: $PRETTY_NAME"
                return 0
                ;;
            *)
                log_warning "Untested OS: $PRETTY_NAME"
                log_info "This system is optimized for Debian/Ubuntu-based distributions."
                ;;
        esac
    else
        log_warning "Cannot determine OS"
    fi
}

# Check for sudo access
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_info "Checking sudo access..."
        if ! sudo -v; then
            log_error "sudo access required"
            exit 1
        fi
    fi
    log_success "sudo access confirmed"
}

# Check and install Python3
check_python3() {
    if command -v python3 &> /dev/null; then
        local py_version=$(python3 --version 2>&1 | awk '{print $2}')
        log_success "Python3 installed: $py_version"
    else
        log_warning "Python3 not found. Installing..."
        sudo apt update
        sudo apt install -y python3
        log_success "Python3 installed"
    fi
}

# Detect shell
detect_shell() {
    if [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    else
        # Fallback to checking SHELL variable
        case "$SHELL" in
            */bash)
                echo "bash"
                ;;
            */zsh)
                echo "zsh"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    fi
}

# Get shell RC file
get_shell_rc() {
    local shell_type=$(detect_shell)
    case "$shell_type" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Check if PATH is already configured
is_path_configured() {
    local rc_file="$1"
    if [ -f "$rc_file" ]; then
        grep -q "\.envforge" "$rc_file" && return 0
    fi
    return 1
}

# Add to PATH
add_to_path() {
    local rc_file=$(get_shell_rc)
    
    if is_path_configured "$rc_file"; then
        log_info "PATH already configured in $rc_file"
        return 0
    fi
    
    log_info "Adding envforge to PATH in $rc_file..."
    
    cat << 'EOF' >> "$rc_file"

# envforge - Universal Environment Scaffolding
export PATH="$HOME/.envforge:$PATH"
EOF
    
    log_success "Added to PATH in $rc_file"
}

# Main installation
main() {
    echo ""
    log_info "==========================================="
    log_info "  envforge Bootstrap Installation"
    log_info "==========================================="
    echo ""
    
    # Check OS and sudo
    check_os
    check_sudo
    echo ""
    
    # Check for git
    if ! command -v git &> /dev/null; then
        log_error "git is not installed. Please install git first:"
        log_info "  Ubuntu/Debian: sudo apt install git"
        log_info "  CentOS/RHEL: sudo yum install git"
        exit 1
    fi
    
    # Check if already installed
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "envforge is already installed at $INSTALL_DIR"
        read -p "Do you want to reinstall? This will remove the existing installation. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Removing existing installation..."
            rm -rf "$INSTALL_DIR"
        else
            log_info "Installation cancelled."
            exit 0
        fi
    fi
    
    # Clone repository
    log_info "Cloning envforge to $INSTALL_DIR..."
    
    # Always clone master first to get the repo
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        log_error "Failed to clone repository"
        exit 1
    fi
    
    # If version is master (default), try to find latest stable from remote .versions
    if [ "$ENV_FORGE_VERSION" = "master" ]; then
        log_info "Fetching latest version information from remote..."
        VERSIONS_URL="https://raw.githubusercontent.com/pnqphong95/envforge/master/.versions"
        
        if command -v curl &> /dev/null; then
            VERSIONS_CONTENT=$(curl -sSL "$VERSIONS_URL" || true)
        elif command -v wget &> /dev/null; then
            VERSIONS_CONTENT=$(wget -qO- "$VERSIONS_URL" || true)
        else
            log_warning "Neither curl nor wget found. Cannot fetch latest version."
            VERSIONS_CONTENT=""
        fi

        if [ -n "$VERSIONS_CONTENT" ]; then
            LATEST_VERSION=$(echo "$VERSIONS_CONTENT" | grep -v '^$' | tail -n 1)
            
            if [ -n "$LATEST_VERSION" ]; then
                log_info "Found latest stable version: $LATEST_VERSION"
                ENV_FORGE_VERSION="$LATEST_VERSION"
            else
                log_warning "Could not parse version from remote .versions file. Falling back to master."
            fi
        else
             log_warning "Failed to fetch .versions file. Falling back to master."
        fi
    fi

    # Checkout specific version if not master
    if [ "$ENV_FORGE_VERSION" != "master" ]; then
        log_info "Checking out version: $ENV_FORGE_VERSION..."
        if ! git -C "$INSTALL_DIR" checkout "$ENV_FORGE_VERSION"; then
            log_error "Failed to checkout version: $ENV_FORGE_VERSION"
            log_info "Available versions (tags):"
            git -C "$INSTALL_DIR" tag -l | head -n 10
            exit 1
        fi
    fi
    
    log_success "Repository cloned successfully"
    
    # Install Python3 if needed
    log_info "Checking dependencies..."
    check_python3
    echo ""
    
    # Make scripts executable
    log_info "Setting permissions..."
    chmod +x "$INSTALL_DIR/envforge"
    chmod +x "$INSTALL_DIR/lib/bundle_resolver.py"
    chmod +x "$INSTALL_DIR"/tools/*.sh 2>/dev/null || true
    
    # Add to PATH
    add_to_path
    
    # Reload source file to apply changes
    local rc_file=$(get_shell_rc)
    if [ -f "$rc_file" ]; then
        log_info "Reloading source file $rc_file..."
        # We use . instead of source for better compatibility, though in bash they are the same
        . "$rc_file"
    fi
    
    echo ""
    log_success "==========================================="
    log_success "  envforge installed successfully!"
    log_success "==========================================="
    echo ""
    log_info "Installation location: $INSTALL_DIR"
    log_info "Version: $ENV_FORGE_VERSION"
    echo ""
    log_warning "IMPORTANT: Please restart your terminal or run:"
    log_info "  source $(get_shell_rc)"
    echo ""
    log_info "Then you can use envforge from anywhere:"
    log_info "  envforge --list       # Show available tools"
    log_info "  envforge              # Install default bundle"
    log_info "  envforge --help       # Show all options"
    echo ""
}

# Run main function
main "$@"
