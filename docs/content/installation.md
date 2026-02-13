---
sidebar_position: 2
---

# Installation

EnvForge can be installed in two ways: **Quick Install** (recommended) or **Manual Installation** (for development).

## Quick Install (Recommended)

Install EnvForge globally with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/pnqphong95/envforge/master/bootstrap-init.sh | bash
```

### Install Specific Version

For a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/pnqphong95/envforge/1.0.0/bootstrap-init.sh | bash -s 1.0.0
```

### After Installation

After installation, restart your terminal or run:

```bash
source ~/.bashrc  # or ~/.zshrc for zsh
```

Then verify the installation:

```bash
envforge version
```

## Manual Installation (Development)

For development or if you prefer cloning manually:

### 1. Clone the Repository

```bash
git clone https://github.com/pnqphong95/envforge.git ~/.envforge
cd ~/.envforge
```

### 2. Set Permissions

```bash
chmod +x envforge
chmod +x lib/*.sh lib/*.py
chmod +x tools/*.sh
```

### 3. Test Installation

```bash
./envforge --list      # Preview tools
./envforge             # Install default bundle
```

### 4. Add to PATH

```bash
echo 'export PATH="$HOME/.envforge:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Requirements

Before installing EnvForge, ensure your system meets these requirements:

- **OS**: Linux (Debian/Ubuntu/Mint/Pop!_OS)
- **Shell**: Bash 4.0+
- **Python**: 3.x (installed automatically by bootstrap script)
- **Privileges**: sudo access for package installation
- **Network**: Internet connection required

## Verify Installation

After installation, verify that EnvForge is working correctly:

```bash
# Check version
envforge version

# List available bundles
envforge up --list

# List available tools
envforge up --list-tool

# Show help
envforge --help
```

## Troubleshooting

### Command Not Found

If you get `envforge: command not found`, ensure the PATH is set correctly:

```bash
# Check if ~/.envforge exists
ls -la ~/.envforge

# Add to PATH manually
echo 'export PATH="$HOME/.env-forge:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Permission Denied

If you encounter permission errors:

```bash
chmod +x ~/.envforge/envforge
chmod +x ~/.envforge/lib/*.sh
chmod +x ~/.envforge/tools/*.sh
```

### Python Not Found

The bootstrap script should install Python automatically. If it doesn't:

```bash
sudo apt update
sudo apt install python3
```

## Next Steps

Now that EnvForge is installed, proceed to the [Quick Start](quick-start.md) guide to install your first bundle.
