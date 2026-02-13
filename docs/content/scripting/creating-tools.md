---
sidebar_position: 2
---

# Creating Tools

Learn how to create custom tool scripts for EnvForge.

## Tool Script Template

Start with this template:

```bash
#!/bin/bash

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"

# Define packages or resources
apt_packages=("package1" "package2")

# Pre-installation phase
pre_install() {
    log_info "Preparing to install <tool-name>..."
    
    # Check if already installed
    if command -v <command> &> /dev/null; then
        log_info "<tool-name> already installed: $(<command> --version)"
    fi
}

# Installation phase
install() {
    log_info "Installing <tool-name>..."
    install_apt_packages "${apt_packages[@]}"
}

# Post-installation phase
post_install() {
    if command -v <command> &> /dev/null; then
        log_success "<tool-name> installed: $(<command> --version)"
    else
        log_error "<tool-name> installation failed"
        exit 1
    fi
}

# Enable standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

## Step-by-Step Guide

### 1. Create the Script File

```bash
cd ~/.envforge/tools
touch mytool.sh
chmod +x mytool.sh
```

### 2. Add Shebang and Imports

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"
```

### 3. Define What to Install

```bash
# For APT packages
apt_packages=("curl" "wget")

# For downloads
DOWNLOAD_URL="https://example.com/tool.tar.gz"
INSTALL_DIR="$HOME/.local/bin"
```

### 4. Implement pre_install

```bash
pre_install() {
    log_info "Checking for MyTool..."
    
    # Check existing installation
    if command -v mytool &> /dev/null; then
        log_info "MyTool already installed: $(mytool --version)"
        return 0
    fi
    
    # Validate prerequisites
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
}
```

### 5. Implement install

```bash
install() {
    log_info "Installing MyTool..."
    
    # Option 1: APT packages
    install_apt_packages "${apt_packages[@]}"
    
    # Option 2: Download and install
    # curl -fsSL "$DOWNLOAD_URL" -o /tmp/mytool.tar.gz
    # tar -xzf /tmp/mytool.tar.gz -C "$INSTALL_DIR"
    
    # Option 3: Custom installation
    # ./configure && make && sudo make install
}
```

### 6. Implement post_install

```bash
post_install() {
    # Verify installation
    if command -v mytool &> /dev/null; then
        log_success "MyTool installed successfully"
        log_info "Version: $(mytool --version)"
    else
        log_error "MyTool installation failed"
        exit 1
    fi
    
    # Optional: Additional configuration
    # echo "export MYTOOL_HOME=$HOME/.mytool" >> ~/.bashrc
}
```

### 7. Add Standalone Support

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

## Real-World Examples

### Example 1: Simple APT Package

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"

apt_packages=("git")

pre_install() {
    log_info "Installing Git..."
}

install() {
    install_apt_packages "${apt_packages[@]}"
}

post_install() {
    if command -v git &> /dev/null; then
        log_success "Git installed: $(git --version)"
    else
        log_error "Git installation failed"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

### Example 2: Download and Install

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"

TOOL_VERSION="1.2.3"
DOWNLOAD_URL="https://github.com/user/tool/releases/download/v${TOOL_VERSION}/tool-linux-amd64.tar.gz"
INSTALL_DIR="$HOME/.local/bin"

pre_install() {
    log_info "Preparing to install Tool v${TOOL_VERSION}..."
    
    if command -v tool &> /dev/null; then
        log_info "Tool already installed: $(tool --version)"
    fi
    
    mkdir -p "$INSTALL_DIR"
}

install() {
    log_info "Downloading Tool..."
    curl -fsSL "$DOWNLOAD_URL" -o /tmp/tool.tar.gz
    
    log_info "Extracting Tool..."
    tar -xzf /tmp/tool.tar.gz -C "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/tool"
    
    # Add to PATH
    add_to_path "$INSTALL_DIR"
}

post_install() {
    # Cleanup
    rm -f /tmp/tool.tar.gz
    
    # Verify
    if command -v tool &> /dev/null; then
        log_success "Tool installed: $(tool --version)"
    else
        log_error "Tool installation failed"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

### Example 3: PPA Installation

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"

PPA="ppa:git-core/ppa"
apt_packages=("git")

pre_install() {
    log_info "Installing Git from PPA..."
}

install() {
    log_info "Adding PPA: $PPA"
    add_ppa "$PPA"
    
    log_info "Installing Git..."
    install_apt_packages "${apt_packages[@]}"
}

post_install() {
    if command -v git &> /dev/null; then
        log_success "Git installed: $(git --version)"
    else
        log_error "Git installation failed"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

## Best Practices

### 1. Always Verify Installation

```bash
post_install() {
    if ! command -v mytool &> /dev/null; then
        log_error "Installation failed"
        exit 1
    fi
}
```

### 2. Use Logging Functions

```bash
log_info "Starting installation..."
log_success "Installation complete"
log_error "Installation failed"
```

### 3. Handle Errors Gracefully

```bash
install() {
    if ! install_apt_packages "${apt_packages[@]}"; then
        log_error "Failed to install packages"
        exit 1
    fi
}
```

### 4. Make Scripts Idempotent

```bash
pre_install() {
    if command -v mytool &> /dev/null; then
        log_info "Already installed, skipping..."
        exit 0
    fi
}
```

### 5. Clean Up Temporary Files

```bash
post_install() {
    rm -f /tmp/mytool.tar.gz
    rm -rf /tmp/mytool-build
}
```

## Testing Your Tool

### Test Standalone

```bash
./tools/mytool.sh
```

### Test in Bundle

Create a test bundle:

```yaml
name: "Test Bundle"
tools:
  - mytool:
```

Run it:

```bash
envforge up --env test.yaml --dry-run
envforge up --env test.yaml
```

### Test with Dependencies

```yaml
name: "Test with Dependencies"
tools:
  - build-essential:
  - mytool:
      depends_on:
        - build-essential
```

## Next Steps

- [**Creating Bundles**](creating-bundles.md) - Use your tool in bundles
- [**How It Works**](how-it-works.md) - Understand the execution flow
- [**Customization**](../customization/custom-tools.md) - Advanced tool customization
