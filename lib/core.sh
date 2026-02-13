#!/bin/bash

# core.sh - Core installation functions for env-forge
# This library contains bundle resolution, state management, and app execution logic

# Resolve bundle dependencies
resolve_bundle() {
    local bundle_file="$1"
    
    if [ ! -f "$bundle_file" ]; then
        log_error "Bundle file not found: $bundle_file"
        exit 1
    fi

    # Use python script to parse and resolve dependencies
    if ! "$LIB_DIR/bundle_resolver.py" "$bundle_file"; then
        log_error "Failed to resolve bundle: $bundle_file"
        exit 1
    fi
}

# State management functions
get_bundle_state_dir() {
    local bundle_name=$(basename "$1" .yaml)
    echo "$STATE_DIR/$bundle_name"
}

is_app_completed() {
    local bundle_state_dir="$1"
    local app_name="$2"
    
    if [ ! -d "$bundle_state_dir" ]; then
        return 1  # Not processed
    fi
    
    [ -f "$bundle_state_dir/$app_name" ]
}

mark_app_completed() {
    local bundle_state_dir="$1"
    local app_name="$2"
    
    if [ ! -d "$bundle_state_dir" ]; then
        mkdir -p "$bundle_state_dir"
    fi
    
    touch "$bundle_state_dir/$app_name"
}

reset_state() {
    local bundle_file="$1"
    
    if [ -z "$bundle_file" ]; then
        # Reset all
        if [ -d "$STATE_DIR" ]; then
            rm -rf "$STATE_DIR"
            log_success "All state files cleared."
        fi
    else
        local bundle_state_dir=$(get_bundle_state_dir "$bundle_file")
        if [ -d "$bundle_state_dir" ]; then
            rm -rf "$bundle_state_dir"
            log_success "State cleared for bundle: $(basename "$bundle_file")"
        else
            log_info "No state found for bundle: $(basename "$bundle_file")"
        fi
    fi
}

# Function to execute an app installation
execute_app() {
    local app_name="$1"
    local bundle_state_dir="$2"
    local app_script="$TOOLS_DIR/$app_name.sh"
    
    # Search for script containing the name
    local found_script=$(find "$TOOLS_DIR" -maxdepth 1 -name "*${app_name}.sh" -print -quit)
    
    if [ -z "$found_script" ]; then
        log_error "Tool script not found for: $app_name"
        exit 1
    fi

    log_info "=========================================="
    log_info "Processing: $app_name"
    log_info "=========================================="
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN: Would execute $found_script"
        log_info "Would run phases: pre_install -> install -> post_install"
        log_success "Would mark as completed: $app_name"
    else
        # Execute the script
        if "$found_script"; then
            log_success "Completed: $app_name"
            mark_app_completed "$bundle_state_dir" "$app_name"
        else
            log_error "Failed to install: $app_name"
            exit 1
        fi
    fi
    
    echo ""
}

# Main installation function
install_bundle() {
    local bundle_file="$1"
    local bundle_state_dir=$(get_bundle_state_dir "$bundle_file")
    
    log_info "Resolving bundle: $bundle_file"
    local app_list
    if ! app_list=$(resolve_bundle "$bundle_file"); then
        exit 1
    fi
    
    if [ -z "$app_list" ]; then
        log_warning "No apps found in bundle."
        return
    fi
    
    if [ "$SHOW_LIST" = true ]; then
        log_info "Bundle Content (Execution Order):"
        echo "$app_list" | nl -s ". "
        return
    fi
    
    log_info "Starting installation process..."
    echo ""
    
    # Read line by line
    while IFS= read -r app_name; do
        if [ -z "$app_name" ]; then continue; fi
        
        # Check state
        if [ "$FORCE_RUN" != true ] && is_app_completed "$bundle_state_dir" "$app_name"; then
            log_skip "$app_name (already completed)"
            continue
        fi
        
        execute_app "$app_name" "$bundle_state_dir"
        
    done <<< "$app_list"
    
    log_success "Bundle installation completed!"
}

# Resolve bundle file path from argument
resolve_bundle_path() {
    local bundle_arg="$1"
    
    # Check if it's an absolute path
    if [[ "$bundle_arg" = /* ]]; then
        echo "$bundle_arg"
    # Check if file exists in current directory
    elif [ -f "$bundle_arg" ]; then
        echo "$(cd "$(dirname "$bundle_arg")" && pwd)/$(basename "$bundle_arg")"
    # Check if it exists relative to BUNDLES_DIR
    elif [ -f "$BUNDLES_DIR/$bundle_arg" ]; then
        echo "$BUNDLES_DIR/$bundle_arg"
    else
        # Use as-is and let it fail later with proper error
        echo "$bundle_arg"
    fi
}

# Upgrade env-forge to latest version
# Upgrade env-forge to latest version or specific tag
upgrade_envforge() {
    local target_version="$1"
    
    if [[ "$target_version" == "-h" ]] || [[ "$target_version" == "--help" ]]; then
        log_info "Usage: envforge upgrade [latest|VERSION]"
        return 0
    fi

    log_info "Starting envforge upgrade process..."
    
    # Check if we're in a git repository
    if ! git -C "$ENV_FORGE_HOME" rev-parse --git-dir > /dev/null 2>&1; then
        log_error "envforge installation is not a git repository. Cannot upgrade."
        log_info "Please reinstall using: curl -fsSL https://raw.githubusercontent.com/pnqphong95/envforge/master/bootstrap-init.sh | bash"
        exit 1
    fi
    
    # Fetch latest from origin
    log_info "Fetching latest updates from remote..."
    if ! git -C "$ENV_FORGE_HOME" fetch origin master --quiet 2>/dev/null; then
        log_error "Failed to fetch updates from remote repository."
        exit 1
    fi
    
    # Read .versions file from remote URL
    log_info "Reading version information from remote..."
    local versions_content
    local versions_url="https://raw.githubusercontent.com/pnqphong95/envforge/master/.versions"

    if command -v curl &> /dev/null; then
        versions_content=$(curl -sSL "$versions_url" || true)
    elif command -v wget &> /dev/null; then
        versions_content=$(wget -qO- "$versions_url" || true)
    else
        log_error "Neither curl nor wget found. Cannot fetch latest version."
        exit 1
    fi

    if [ -z "$versions_content" ]; then
        log_error "Failed to read .versions file from remote URL."
        exit 1
    fi
    
    # Filter empty lines
    local available_versions
    available_versions=$(echo "$versions_content" | grep -v '^$')
    
    if [ -z "$available_versions" ]; then
        log_error "No versions found in remote .versions file."
        exit 1
    fi
    
    # Get latest version (last line)
    local latest_version
    latest_version=$(echo "$available_versions" | tail -n 1)
    
    # Determine target version
    if [ -z "$target_version" ]; then
        # Interactive mode
        log_info "Available versions:"
        echo "$available_versions" | sed 's/^/  /'
        echo ""
        read -p "Enter version to install (default: $latest_version): " input_version
        if [ -z "$input_version" ]; then
            target_version="$latest_version"
        else
            target_version="$input_version"
        fi
    elif [ "$target_version" = "latest" ]; then
        target_version="$latest_version"
    fi

    # Normalize version (add 'v' prefix if missing and needed)
    # Check if the target version exists in the available versions list?
    # Or just try to checkout it. The user might want to install a tag not in .versions (e.g. older ones not listed? or dev tags?)
    # But the requirement is "The version should always look from remote url". 
    # Let's verify if the chosen version is in the list, unless it's a direct checkout attempt which we verify via git.
    
    # Fetch tags to ensure we can checkout
    log_info "Fetching tags..."
    if ! git -C "$ENV_FORGE_HOME" fetch --tags --quiet 2>/dev/null; then
        log_warning "Failed to fetch tags, but continuing..."
    fi

    # Normalize version (add 'v' prefix if missing and needed)
    if [[ ! "$target_version" =~ ^v ]]; then
        if git -C "$ENV_FORGE_HOME" rev-parse "v$target_version" >/dev/null 2>&1; then
            target_version="v$target_version"
        fi
    fi

    # Verify version exists
    if ! git -C "$ENV_FORGE_HOME" rev-parse "$target_version" >/dev/null 2>&1; then
        log_error "Version '$target_version' not found in repository."
        exit 1
    fi

    log_info "Upgrading to version $target_version..."
    
    # Checkout the version
    if git -C "$ENV_FORGE_HOME" checkout "$target_version" --quiet 2>/dev/null; then
        log_success "Successfully upgraded to version $target_version!"
        log_info "Please restart your shell or run: source ~/.bashrc"
    else
        log_error "Failed to checkout version $target_version."
        log_error "You may have local changes. Please commit or stash them first."
        exit 1
    fi
}
