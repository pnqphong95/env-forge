#!/bin/bash

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Correctly resolve project root assuming script is in tools/
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utility functions if available
if [ -f "$PROJECT_ROOT/lib/utils.sh" ]; then
    source "$PROJECT_ROOT/lib/utils.sh"
else
    # Fallback
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_warning() { echo "[WARNING] $1"; }
    log_error() { echo "[ERROR] $1"; }
    install_apt_packages() {
        sudo apt update && sudo apt install -y "$@"
    }
fi

# Set mirrors script - standalone
apt_packages=("bc")

pre_install() {
    log_info "Checking internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connection. Cannot fetch mirrors."
        exit 1
    fi
}

install() {
     # Install dependencies first
    if [ ${#apt_packages[@]} -gt 0 ]; then
        install_apt_packages "${apt_packages[@]}"
    fi

    # Force decimal point to be a dot regardless of system locale
    export LC_NUMERIC=C
    
    log_info "=========================================="
    log_info "    Global Linux Mint Mirror Speed Test   "
    log_info "=========================================="
    
    # 1. Scrape the full live mirror list (Worldwide)
    log_info "Fetching all official Mint mirrors..."
    MINT_LIST=$(curl -s https://linuxmint.com/mirrors.php | grep -oP 'http[s]?://[^"]+/packages/' | sort -u)
    
    if [ -z "$MINT_LIST" ]; then
        log_error "Could not fetch mirror list. Check your internet connection."
        return 1
    fi
    
    # 2. Test speeds and store results
    log_info "Testing mirrors. This may take a minute..."
    declare -a MIRROR_RESULTS
    
    # Loop through the first 50 mirrors found
    for mirror in $(echo "$MINT_LIST" | head -n 50); do
        # Measure Time to Total (in seconds)
        # Using 1.2s timeout to keep the script snappy
        speed=$(curl -o /dev/null -s -w "%{time_total}\n" --connect-timeout 1.2 --max-time 2 "$mirror" || echo "999")
        
        # Clean up the output
        speed=$(echo "$speed" | tr -d '[:space:]')
        
        # Check if the mirror responded
        if [[ "$speed" != "999" ]]; then
            MIRROR_RESULTS+=("$speed|$mirror")
            printf "." 
        fi
    done
    
    echo -e "\nDone testing."
    
    # 3. Sort and Select
    IFS=$'\n' SORTED_RESULTS=($(sort -n <<<"${MIRROR_RESULTS[*]}"))
    unset IFS
    
    if [ ${#SORTED_RESULTS[@]} -eq 0 ]; then
        log_warning "No responsive mirrors found."
        return 1
    fi
    
    echo ""
    log_info "Fastest mirrors found (Top 15):"
    
    # Set the prompt for the select menu
    PS3="Select a mirror (1-15) or 'q' to quit: "
    
    # Create labels for the select menu
    declare -a LABELS
    for entry in "${SORTED_RESULTS[@]:0:15}"; do
        time=$(echo "$entry" | cut -d'|' -f1)
        url=$(echo "$entry" | cut -d'|' -f2)
        LABELS+=("[$time s] $url")
    done
    
    # The select loop
    select choice in "${LABELS[@]}"; do
        if [[ "$REPLY" == "q" ]]; then 
            log_info "Exiting."
            return 0
        fi
        if [ -z "$choice" ]; then
            log_warning "Invalid selection. Please pick a number from the list."
        else
            # Match the index correctly
            INDEX=$((REPLY - 1))
            FINAL_MIRROR=$(echo "${SORTED_RESULTS[$INDEX]}" | cut -d'|' -f2)
            log_success "Selected: $FINAL_MIRROR"
            break
        fi
    done

    if [ -z "$FINAL_MIRROR" ]; then
        log_warning "No mirror selected. Exiting."
        return 1
    fi
    
    # 4. Apply to system
    REPO_FILE="/etc/apt/sources.list.d/official-package-repositories.list"
    
    if [ -f "$REPO_FILE" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_warning "DRY RUN: Would update $REPO_FILE with $FINAL_MIRROR"
        else
            log_info "Backing up original list to ${REPO_FILE}.bak..."
            sudo cp "$REPO_FILE" "${REPO_FILE}.bak"
            
            log_info "Applying new mirror..."
            # Targets the Mint package line specifically (handles default and custom mirrors)
            # Matches: deb [PROTOCOL://URL] [CODENAME] main upstream import ...
            sudo sed -i "s|deb \+http[s]\?://[^ ]\+ \([a-z]\+\) main upstream|deb $FINAL_MIRROR \1 main upstream|g" "$REPO_FILE"
            
            log_success "Mirror updated! Running 'sudo apt update'..."
            sudo apt update
        fi
    else
        log_error "$REPO_FILE not found. Are you running Linux Mint?"
    fi
}

post_install() {
    : # No post-installation checks needed
}

# Main execution logic
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting standalone execution of set-mirrors..."
    pre_install
    install
    post_install
    log_success "Mirror setup finished."
fi
