#!/usr/bin/env bash

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration storage
declare -A CONFIGS
declare -A CONFIG_TYPES

# Detect what platform the machine is on
detect_platform() {
    case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*) echo "linux" ;;
    msys* | cygwin* | mingw*) echo "windows" ;;
    *) echo "unknown" ;;
    esac
}

# Setup configuration mappings
setup_config_paths() {
    case $PLATFORM in
    "linux" | "macos")
        CONFIGS[kitty]="$HOME/.config/kitty:$DOTFILES_DIR/config/kitty"
        CONFIG_TYPES[kitty]="symlink"

        CONFIGS[starship]="$HOME/.config/starship.toml:$DOTFILES_DIR/config/starship/starship.toml"
        CONFIG_TYPES[starship]="symlink"

        CONFIGS[nvim]="$HOME/.config/nvim:$DOTFILES_DIR/config/nvim"
        CONFIG_TYPES[nvim]="symlink"
        ;;
    "windows")
        local appdata=$(cygpath "$APPDATA" 2>/dev/null || echo "$APPDATA")
        local localappdata=$(cygpath "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")
        local userprofile=$(cygpath "$USERPROFILE" 2>/dev/null || echo "$USERPROFILE")

        CONFIGS[kitty]="$appdata/kitty:$DOTFILES_DIR/config/kitty"
        CONFIG_TYPES[kitty]="junction"

        CONFIGS[starship]="$appdata/starship.toml:$DOTFILES_DIR/config/starship.toml"
        CONFIG_TYPES[starship]="hardlink"

        CONFIGS[nvim]="$localappdata/nvim:$DOTFILES_DIR/config/nvim"
        CONFIG_TYPES[nvim]="junction"
        ;;
    esac
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

create_symlink() {
    local target_path="$1"
    local source_path="$2"
    ln -sf "$source_path" "$target_path"
    log_info "✓ Configuration linked (symlink)"
}

create_junction() {
    local target_path="$1"
    local source_path="$2"

    local win_target=$(cygpath -w "$target_path" 2>/dev/null || echo "$target_path")
    local win_source=$(cygpath -w "$source_path" 2>/dev/null || echo "$source_path")

    if cmd //c "mklink /J \"$win_target\" \"$win_source\"" >/dev/null 2>&1; then
        log_info "✓ Configuration linked (junction)"
    else
        log_error "Failed to create junction"
        return 1
    fi
}

create_hardlink() {
    local target_path="$1"
    local source_path="$2"

    local win_target=$(cygpath -w "$target_path" 2>/dev/null || echo "$target_path")
    local win_source=$(cygpath -w "$source_path" 2>/dev/null || echo "$source_path")

    if cmd //c "mklink /H \"$win_target\" \"$win_source\"" >/dev/null 2>&1; then
        log_info "✓ Configuration linked (hardlink)"
    else
        log_error "Failed to create hardlink"
        return 1
    fi
}

install_config() {
    local app_name="$1"
    local config_mapping="${CONFIGS[$app_name]}"
    local config_type="${CONFIG_TYPES[$app_name]}"

    if [[ -z "$config_mapping" ]]; then
        log_error "No configuration found for: $app_name"
        return 1
    fi

    # Parse the mapping (target:source format)
    IFS=':' read -r target_path source_path <<<"$config_mapping"

    log_info "Installing $app_name configuration..."

    if [[ ! -e "$source_path" ]]; then
        log_error "Source not found: $source_path"
        return 1
    fi

    mkdir -p "$(dirname "$target_path")"

    if [[ -e "$target_path" ]]; then
        log_warn "Removing existing target: $target_path"
        rm -rf "$target_path"
    fi

    # Create appropriate link type
    case $config_type in
    "symlink")
        create_symlink "$target_path" "$source_path"
        ;;
    "junction")
        create_junction "$target_path" "$source_path"
        ;;
    "hardlink")
        create_hardlink "$target_path" "$source_path"
        ;;
    *)
        log_error "Unknown configuration type: $config_type"
        return 1
        ;;
    esac
}

PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Platform: $PLATFORM"

# Setup configuration paths
setup_config_paths

# Install all configurations
for app in "${!CONFIGS[@]}"; do
    install_config "$app"
    echo
done

log_info "Installation complete!"
