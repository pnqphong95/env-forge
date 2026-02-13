# Tools Directory

This directory contains the modular installation scripts used by `envforge`.

## How to Add a New Tool

To add a new tool or application to the installation process, create a new `.sh` file in this directory.

### 1. Naming Convention
Files are executed in alphanumeric order. Use a numeric prefix to control the installation order.
*   `00_...` - System prep (mirrors, updates)
*   `01_...` - Base dependencies
*   `10_...` - Core applications
*   `99_...` - Cleanup or finalization

**Example:** `03_docker.sh`

### 2. Script Structure
Each script runs in the context of the main `install.sh`. You do not need to repeat common variables or logging functions.

**Template:**
```bash
#!/bin/bash

# Define system packages to execute via apt install
apt_packages=("package-name" "another-package")

pre_install() {
    # Optional: Check for prerequisites
    # e.g., check if a specific hardware exists
    :
}

install() {
    # Optional: Custom installation logic
    # Use this for things apt can't handle (curl | bash, binary downloads, etc.)
    # The 'apt_packages' defined above are installed BEFORE this function runs.
    
    echo "Running custom install steps..."
}

post_install() {
    # Optional: Verification
    # Check if the command exists or version is correct
    if command -v my-tool &> /dev/null; then
        echo "Verification passed."
    else
        echo "Verification failed."
        exit 1
    fi
}
```

### 3. Best Practices
1.  **Idempotency**: Ensure your `install` function can run multiple times without breaking anything.
2.  **Dependencies**: If your tool depends on another (e.g., requires `curl`), ensure the dependency has a lower number prefix (e.g., `01_base.sh` installs curl, so your script should be `02_` or higher).
3.  **Logs**: Use the provided logging functions from `install.sh` if needed (though standard `echo` is fine, as `install.sh` handles formatting).
