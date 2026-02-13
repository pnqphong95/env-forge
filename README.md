# EnvForge

**Universal Environment Scaffolding Scripts**

EnvForge is a modular, dependency-aware installation framework designed to scaffold and bootstrap development environments. Built for Linux distributions (Debian/Ubuntu/Mint), its flexible architecture allows easy customization for various setup needs.

## Vision

This project provides a flexible scaffolding framework for multiple purposes:
- **Generic Linux Setup**: Essential tools for fresh OS installations.
- **Developer Workstations**: Robust environments for backend, web, and systems programming.
- **Mobile Development**: Provisioning toolchains for Android, iOS, and cross-platform frameworks.
- **Custom Environments**: Easily extensible to support any specific tooling requirements.

## Features

- **Bundle System**: Define tool collections with dependency management in YAML
- **Dependency Resolution**: Automatic topological sorting ensures correct installation order
- **Standalone Tools**: Each tool script can run independently or as part of a bundle
- **State Management**: Per-bundle state tracking prevents redundant installations
- **Flexible Execution**: Install complete bundles or individual tools
- **3-Phase Hooks**: `pre_install`, `install`, and `post_install` for granular control
- **Skip Parameter**: Conditionally enable/disable tools in bundles
- **Global Command**: Install once, use `envforge` from anywhere

## Quick Install (Recommended)

Install env-forge globally with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/pnqphong95/env-forge/master/bootstrap-init.sh | bash
```

For a specific version:
```bash
curl -fsSL https://raw.githubusercontent.com/pnqphong95/env-forge/1.0.0/bootstrap-init.sh | bash -s 1.0.0
```

After installation, restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc for zsh
```

Then use env-forge from anywhere:
```bash
envforge --list       # Show available tools
envforge              # Install default bundle
envforge --help       # Show all options
```

## Manual Installation (Development)

For development or if you prefer cloning manually:

```bash
git clone https://github.com/pnqphong95/env-forge.git ~/.env-forge
cd ~/.env-forge
chmod +x envforge
chmod +x lib/*.sh lib/*.py
chmod +x tools/*.sh
./envforge --list      # Preview tools
./envforge             # Install default bundle
```

Add to PATH manually:
```bash
echo 'export PATH="$HOME/.env-forge:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Global Command (After Bootstrap Installation)

```bash
envforge                      # Install default bundle
envforge --list               # List tools in default bundle
envforge my-bundle.yaml       # Use custom bundle from current directory
envforge /path/to/bundle.yaml # Use bundle from anywhere
envforge --dry-run            # Preview without executing
envforge --force              # Force re-installation
```

### Direct Execution (Development)

```bash
cd ~/.env-forge
./envforge --list
./envforge
```

## Directory Structure

```
env-forge/
├── envforge                # Main executable - the entrypoint
├── bootstrap-init.sh       # Remote installation script
├── bundles/                # Bundle definitions (YAML)
│   └── default.yaml        # Default bundle
├── tools/                  # Standalone tool scripts
│   ├── git.sh
│   ├── http-tools.sh
│   ├── build-essential.sh
│   ├── software-properties.sh
│   ├── set-mirrors.sh
│   └── github-cli.sh
└── lib/                    # Shared utilities
    ├── utils.sh            # Logging and common functions
    ├── core.sh             # Bundle resolution and installation logic
    └── bundle_resolver.py  # Dependency resolution engine
```

## Creating a Bundle

Create a YAML file in `bundles/` directory:

**Example: `bundles/webdev.yaml`**
```yaml
name: "Web Development Bundle"
description: "Full-stack web development environment"
tools:
  - base:
      # No dependencies
  - nodejs:
      depends_on: 
        - base
  - docker:
      depends_on:
        - base
  - vscode:
      depends_on:
        - base
        - nodejs
```

## Creating a Tool

See [tools/README.md](tools/README.md) for detailed instructions.

**Quick Example: `tools/nodejs.sh`**
```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"

apt_packages=("nodejs" "npm")

pre_install() {
    log_info "Checking for Node.js..."
}

install() {
    install_apt_packages "${apt_packages[@]}"
}

post_install() {
    if command -v node &> /dev/null; then
        log_success "Node.js installed: $(node --version)"
    else
        log_error "Node.js installation failed"
        exit 1
    fi
}

# Allow standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

## Command Reference

### install.sh Options
```bash
./install.sh [OPTIONS] [BUNDLE_FILE]

OPTIONS:
  --list, -l        List tools in bundle (with execution order)
  --dry-run         Preview without executing
  --force           Ignore state, re-run all tools
  --reset-state     Clear completion state for bundle
  --help, -h        Show help message

EXAMPLES:
  ./install.sh                      # Install default bundle
  ./install.sh bundles/webdev.yaml  # Install custom bundle
  ./install.sh --list               # Show default bundle contents
  ./install.sh --force              # Force re-installation
```

### Standalone Tool Execution
```bash
./tools/01_base.sh     # Run specific tool directly
```

## Requirements

- **OS**: Linux (Debian/Ubuntu/Mint/Pop!_OS)
- **Shell**: Bash 4.0+
- **Python**: 3.x (installed automatically by init.sh)
- **Privileges**: sudo access for package installation
- **Network**: Internet connection required

## State Management

State is tracked per-bundle in `.install_state/<bundle_name>/`:
```
.install_state/
├── default/
│   ├── base
│   └── set-mirrors
└── webdev/
    ├── base
    ├── nodejs
    └── docker
```

To reset state:
```bash
./install.sh --reset-state                 # Reset current bundle
rm -rf .install_state/                     # Reset all bundles
```

## License

This project is open source and available for personal and commercial use.
