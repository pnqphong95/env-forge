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
