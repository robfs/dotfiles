#!/usr/bin/env bash

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log functions
log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }
log_debug() { printf "${BLUE}[DEBUG]${NC} %s\n" "$1"; }

# Detect what platform the machine is on
detect_platform() {
    case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*) echo "linux" ;;
    msys* | cygwin* | mingw*) echo "windows" ;;
    *) echo "unknown" ;;
    esac
}

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration storage
declare -A CONFIGS
declare -A CONFIG_TYPES

# Setup configuration mappings
setup_config_paths() {
    local kitty_config="$DOTFILES_DIR/config/kitty"
    local win_terminal_config="$DOTFILES_DIR/config/windowsterminal/settings.json"
    local starship_config="$DOTFILES_DIR/config/starship/starship.toml"
    local nvim_config="$DOTFILES_DIR/config/nvim"

    case $PLATFORM in
    "linux" | "macos")
        CONFIGS[terminal]="$HOME/.config/kitty|$kitty_config"
        CONFIG_TYPES[terminal]="symlink"

        CONFIGS[starship]="$HOME/.config/starship.toml|$starship_config"
        CONFIG_TYPES[starship]="symlink"

        CONFIGS[nvim]="$HOME/.config/nvim|$nvim_config"
        CONFIG_TYPES[nvim]="symlink"
        ;;
    "windows")
        CONFIGS[terminal]="$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json|$win_terminal_config"
        CONFIG_TYPES[terminal]="hardlink"

        CONFIGS[starship]="$APPDATA/starship.toml|$starship_config"
        CONFIG_TYPES[starship]="hardlink"

        CONFIGS[nvim]="$LOCALAPPDATA/nvim|$nvim_config"
        CONFIG_TYPES[nvim]="junction"
        ;;
    esac
}

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

    if cmd //c "mklink /J $win_target $win_source" >/dev/null 2>&1; then
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

    if cmd //c "mklink /H $win_target $win_source" >/dev/null 2>&1; then
        log_info "✓ Configuration linked (hardlink)"
    else
        log_error "Failed to create hardlink"
        return 1
    fi
}

install_config() {
    local app_name="$1"
    local config_mapping="${CONFIGS[$app_name]}"

    # Parse the mapping (target|source format)
    IFS='|' read -r target_path source_path <<<"$config_mapping"

    if [[ -z "$config_mapping" ]]; then
        log_error "No configuration found for: $app_name"
        return 1
    fi


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

    # Determine the type of link to create
    if [[ "$PLATFORM" == "windows"  ]]; then
        if [[ -d "$source_path" ]]; then
            create_junction "$target_path" "$source_path"
        else
            create_hardlink "$target_path" "$source_path"
        fi
    else
        create_symlink "$target_path" "$source_path"
    fi
    
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
