---
sidebar_position: 3
---

# Quick Start

Get started with EnvForge in minutes. This guide will walk you through your first bundle installation.

## Basic Usage

### Install Default Bundle

The simplest way to get started:

```bash
envforge up
```

This installs the default bundle defined in `bundles/default.yaml`.

### List Available Bundles

See what bundles are available:

```bash
envforge up --list
```

### List Available Tools

See all individual tools:

```bash
envforge up --list-tool
```

### Install Custom Bundle

Install a specific bundle:

```bash
envforge up --env bundles/webdev.yaml
```

## Common Commands

### Version Management

```bash
# Show current version
envforge version

# Interactive upgrade (shows available versions)
envforge upgrade

# Upgrade to latest version
envforge upgrade latest

# Upgrade to specific version
envforge upgrade 0.9.3
```

### Installation Options

```bash
# Preview without executing
envforge up --dry-run

# Force re-installation (ignore state)
envforge up --force

# Reset state for bundle
envforge up --reset-state

# Install specific bundle
envforge up --env my-bundle.yaml
```

## Example Workflow

Here's a typical workflow for setting up a new development environment:

### 1. Check Available Bundles

```bash
envforge up --list
```

Output:
```
Available bundles:
  - default.yaml: Default development tools
  - webdev.yaml: Web development environment
  - mobile.yaml: Mobile development tools
```

### 2. Preview Installation

```bash
envforge up --env webdev.yaml --dry-run
```

This shows what will be installed without actually installing anything.

### 3. Install Bundle

```bash
envforge up --env webdev.yaml
```

EnvForge will:
1. Resolve dependencies
2. Sort tools in correct order
3. Execute installation phases
4. Track completion state

### 4. Verify Installation

```bash
# Check installed tools
which node
which docker
which code

# Check versions
node --version
docker --version
```

## State Management

EnvForge tracks installation state to prevent redundant installations.

### View State

State is stored in `.install_state/`:

```bash
ls -la ~/.envforge/.install_state/
```

### Reset State

If you need to re-run installations:

```bash
# Reset specific bundle
envforge up --env webdev --reset-state

# Or manually delete state
rm -rf ~/.envforge/.install_state/webdev/
```

### Force Re-installation

Ignore state and re-run everything:

```bash
envforge up --force
```

## Tips & Tricks

### Combine with Other Tools

EnvForge works well with other automation tools:

```bash
# Use in scripts
#!/bin/bash
envforge up --env production.yaml

# Use with ansible
- name: Install dev tools
  shell: envforge up --env devtools.yaml
```

### Selective Installation

Install only specific tools by creating a minimal bundle:

```yaml
name: "Minimal Setup"
tools:
  - git:
  - build-essential:
```

### Resume Interrupted Installations

If installation is interrupted, simply run the same command again:

```bash
envforge up --env webdev.yaml
```

EnvForge will skip completed tools and continue from where it left off.

## Next Steps

- [**Architecture Overview**](architecture/overview.md) - Understand how EnvForge works
- [**Creating Bundles**](scripting/creating-bundles.md) - Create your own bundles
- [**Creating Tools**](scripting/creating-tools.md) - Add custom tools
- [**Customization Guide**](customization/overview.md) - Customize EnvForge for your needs
