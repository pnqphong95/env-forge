---
sidebar_position: 2
---

# Directory Structure

Understanding EnvForge's directory structure helps you navigate the codebase and know where to add customizations.

## Root Directory

```
envforge/
├── envforge              # Main CLI executable
├── bootstrap-init.sh     # Remote installation script
├── .versions             # Current version file
├── bundles/              # Bundle definitions
├── tools/                # Tool installation scripts
├── lib/                  # Shared libraries
└── .install_state/       # Runtime state (created during use)
```

## Core Files

### `envforge`

The main entry point for all commands. This is a Bash script that:

- Parses command-line arguments
- Implements subcommands (`up`, `version`, `upgrade`)
- Sources core libraries
- Handles global flags

**Location**: `/home/user/.envforge/envforge`

### `bootstrap-init.sh`

Remote installation script for quick setup:

- Clones the repository
- Sets up PATH
- Configures shell integration
- Handles version-specific installations

**Usage**: `curl -fsSL https://raw.githubusercontent.com/.../bootstrap-init.sh | bash`

### `.versions`

Simple text file containing the current version:

```
0.9.4
```

## Bundles Directory

Contains YAML bundle definitions.

```
bundles/
├── default.yaml          # Default bundle
├── webdev.yaml          # Web development bundle
└── mobile.yaml          # Mobile development bundle
```

### Bundle File Format

```yaml
name: "Bundle Name"
description: "Bundle description"
tools:
  - tool-name:
      depends_on:
        - dependency1
        - dependency2
```

## Tools Directory

Contains individual tool installation scripts.

```
tools/
├── git.sh
├── build-essential.sh
├── nodejs.sh
├── docker.sh
├── github-cli.sh
├── http-tools.sh
├── set-mirrors.sh
└── software-properties.sh
```

### Tool Script Structure

Each tool script follows this pattern:

```bash
#!/bin/bash

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/utils.sh"

# Define packages
apt_packages=("package1" "package2")

# Three-phase lifecycle
pre_install() {
    # Preparation
}

install() {
    # Installation
}

post_install() {
    # Verification
}

# Standalone execution support
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_install
    install
    post_install
fi
```

## Library Directory

Shared code used by tools and core system.

```
lib/
├── utils.sh              # Bash utilities
├── core.sh               # Core orchestration
└── bundle_resolver.py    # Python dependency resolver
```

### `lib/utils.sh`

Provides common functions:

- `log_info()` - Information messages
- `log_success()` - Success messages
- `log_error()` - Error messages
- `install_apt_packages()` - APT package installation
- `add_to_path()` - PATH management
- And more...

### `lib/core.sh`

Core orchestration logic:

- Bundle loading
- Tool execution
- State management
- Error handling

### `lib/bundle_resolver.py`

Python script for dependency resolution:

- Parses YAML bundles
- Builds dependency graph
- Topological sorting
- Circular dependency detection

## State Directory

Created at runtime to track installation state.

```
.install_state/
├── default/              # State for default bundle
│   ├── git
│   ├── build-essential
│   └── nodejs
└── webdev/              # State for webdev bundle
    ├── git
    ├── nodejs
    └── docker
```

### State Files

Each file is a marker indicating tool completion:

- **Presence** = Tool installed successfully
- **Absence** = Tool not yet installed or failed

### State Management Commands

```bash
# View state
ls -la .install_state/default/

# Reset specific bundle
rm -rf .install_state/default/

# Reset all state
rm -rf .install_state/

# Reset via command
envforge up --reset-state
```

## Installation Locations

### Global Installation

When installed via bootstrap script:

```
~/.envforge/             # Installation directory
~/.bashrc                 # PATH added here (or ~/.zshrc)
```

### Manual Installation

When cloned manually:

```
<any-directory>/envforge/
```

You must manually add to PATH:

```bash
export PATH="$HOME/.envforge:$PATH"
```

## Adding Custom Content

### Add a New Tool

1. Create script in `tools/`:
   ```bash
   touch tools/mytool.sh
   chmod +x tools/mytool.sh
   ```

2. Implement three-phase lifecycle

3. Reference in bundle:
   ```yaml
   tools:
     - mytool:
   ```

### Add a New Bundle

1. Create YAML in `bundles/`:
   ```bash
   touch bundles/mybundle.yaml
   ```

2. Define tools and dependencies

3. Use it:
   ```bash
   envforge up --env mybundle.yaml
   ```

### Extend Utilities

Add functions to `lib/utils.sh`:

```bash
my_custom_function() {
    log_info "Custom functionality"
    # Your code here
}
```

## Next Steps

- [**How Scripting Works**](../scripting/how-it-works.md) - Understand the execution flow
- [**Creating Tools**](../scripting/creating-tools.md) - Build custom tools
- [**Creating Bundles**](../scripting/creating-bundles.md) - Define custom bundles
