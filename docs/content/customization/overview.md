---
sidebar_position: 1
---

# Customization Overview

EnvForge is designed to be highly customizable. This guide covers the various ways you can adapt it to your specific needs.

## What Can You Customize?

### 1. **Tools**
Create custom installation scripts for any software or configuration.

### 2. **Bundles**
Define collections of tools tailored to your workflow.

### 3. **Utilities**
Extend the shared library with custom helper functions.

### 4. **Installation Logic**
Modify core behavior for specialized requirements.

## Customization Levels

### Level 1: Using Existing Tools

**Difficulty**: Easy  
**Time**: Minutes

Create bundles from existing tools:

```yaml
name: "My Workflow"
tools:
  - git:
  - nodejs:
  - docker:
```

### Level 2: Creating Custom Tools

**Difficulty**: Moderate  
**Time**: 30-60 minutes

Write tool scripts for new software:

```bash
#!/bin/bash
source "$PROJECT_ROOT/lib/utils.sh"

pre_install() { ... }
install() { ... }
post_install() { ... }
```

### Level 3: Extending Utilities

**Difficulty**: Moderate  
**Time**: 1-2 hours

Add helper functions to `lib/utils.sh`:

```bash
my_custom_helper() {
    log_info "Custom functionality"
    # Your code
}
```

### Level 4: Modifying Core Logic

**Difficulty**: Advanced  
**Time**: Several hours

Customize core behavior in `lib/core.sh` or `envforge`:

- Change state management
- Modify execution flow
- Add new subcommands

## Common Customization Scenarios

### Scenario 1: Company-Specific Setup

Create a bundle for your organization:

```yaml
name: "Acme Corp Development"
description: "Standard development environment for Acme Corp"
tools:
  - git:
  - company-vpn:
  - company-certificates:
  - nodejs:
      depends_on:
        - company-certificates
  - company-cli-tools:
      depends_on:
        - nodejs
```

### Scenario 2: Multi-Environment Support

Create bundles for different environments:

**bundles/local.yaml**:
```yaml
name: "Local Development"
tools:
  - git:
  - nodejs:
  - docker:
  - vscode:
```

**bundles/ci.yaml**:
```yaml
name: "CI Environment"
tools:
  - git:
  - nodejs:
  - docker:
```

### Scenario 3: Personal Dotfiles Integration

Create a tool to install your dotfiles:

```bash
#!/bin/bash
source "$PROJECT_ROOT/lib/utils.sh"

DOTFILES_REPO="https://github.com/user/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

pre_install() {
    log_info "Installing dotfiles..."
}

install() {
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    ./install.sh
}

post_install() {
    log_success "Dotfiles installed"
}
```

### Scenario 4: Custom Package Sources

Add tools from non-standard sources:

```bash
#!/bin/bash
source "$PROJECT_ROOT/lib/utils.sh"

CUSTOM_REPO="https://custom-repo.example.com"

pre_install() {
    log_info "Adding custom repository..."
}

install() {
    curl -fsSL "$CUSTOM_REPO/key.gpg" | sudo apt-key add -
    echo "deb $CUSTOM_REPO/apt stable main" | sudo tee /etc/apt/sources.list.d/custom.list
    sudo apt update
    install_apt_packages "custom-package"
}

post_install() {
    if command -v custom-package &> /dev/null; then
        log_success "Custom package installed"
    fi
}
```

## Customization Workflow

### 1. Identify Need

What do you want to customize?
- New software to install?
- Custom configuration?
- Workflow automation?

### 2. Choose Approach

- **Existing tools**: Create a bundle
- **New software**: Create a tool script
- **Shared logic**: Add to utilities
- **Core behavior**: Modify core files

### 3. Implement

Follow the appropriate guide:
- [Creating Tools](../scripting/creating-tools.md)
- [Creating Bundles](../scripting/creating-bundles.md)
- [Custom Tools](custom-tools.md)
- [Custom Bundles](custom-bundles.md)

### 4. Test

```bash
# Test standalone
./tools/mytool.sh

# Test in bundle
envforge up --env mybundle.yaml --dry-run
envforge up --env mybundle.yaml
```

### 5. Iterate

Refine based on testing:
- Fix errors
- Improve logging
- Add validation
- Handle edge cases

## Best Practices

### 1. Keep Tools Focused

Each tool should do one thing well:

✅ **Good**: `nodejs.sh` installs Node.js  
❌ **Bad**: `devtools.sh` installs Node.js, Docker, and VS Code

### 2. Use Descriptive Names

```yaml
# Good
name: "Full-Stack Web Development"

# Bad
name: "My Bundle"
```

### 3. Document Your Customizations

Add comments to your tools and bundles:

```bash
# Install Node.js LTS version
# Includes npm and npx
install() {
    install_apt_packages "${apt_packages[@]}"
}
```

### 4. Version Control

Keep your customizations in git:

```bash
cd ~/.envforge
git add bundles/mybundle.yaml
git add tools/mytool.sh
git commit -m "Add custom bundle and tool"
```

### 5. Share with Team

If useful for others, share your customizations:

```bash
# Push to your fork
git push origin my-customizations

# Or create a PR
gh pr create
```

## Advanced Topics

### Custom State Management

Implement custom state tracking:

```bash
CUSTOM_STATE_DIR="$PROJECT_ROOT/.custom_state"

mark_complete() {
    mkdir -p "$CUSTOM_STATE_DIR"
    touch "$CUSTOM_STATE_DIR/$1"
}

is_complete() {
    [[ -f "$CUSTOM_STATE_DIR/$1" ]]
}
```

### Conditional Installation

Install based on conditions:

```bash
install() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        install_apt_packages "${apt_packages[@]}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install "${brew_packages[@]}"
    fi
}
```

### Parameterized Tools

Accept parameters in tools:

```bash
TOOL_VERSION="${1:-latest}"

install() {
    log_info "Installing version: $TOOL_VERSION"
    # Install specific version
}
```

## Getting Help

### Documentation

- [Creating Tools](../scripting/creating-tools.md)
- [Creating Bundles](../scripting/creating-bundles.md)
- [How It Works](../scripting/how-it-works.md)

### Examples

Study existing tools:

```bash
cd ~/.envforge/tools
cat git.sh
cat nodejs.sh
cat docker.sh
```

### Community

- Open an issue on GitHub
- Submit a PR with improvements
- Share your customizations

## Next Steps

- [**Custom Tools**](custom-tools.md) - Advanced tool customization
- [**Custom Bundles**](custom-bundles.md) - Advanced bundle patterns
- [**Architecture**](../architecture/overview.md) - Understand the internals
