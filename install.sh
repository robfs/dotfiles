#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

detect_platform() {
    case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*) echo "linux" ;;
    msys* | cygwin* | mingw*) echo "windows" ;;
    *) echo "unknown" ;;
    esac
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Platform: $PLATFORM"

KITTY_CONFIG="$DOTFILES_DIR/config/kitty"
STARSHIP_CONFIG="$DOTFILES_DIR/config/starship/starship.toml"
NVIM_CONFIG="$DOTFILES_DIR/config/nvim"
WIN_TERMINAL_CONFIG="$DOTFILES_DIR/config/windowsterminal/settings.json"

# Define configs as: "target|source"
if [[ "$PLATFORM" == "windows" ]]; then
    CONFIGS=(
        "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json|$WIN_TERMINAL_CONFIG"
        "$APPDATA/starship.toml|$STARSHIP_CONFIG"
        "$LOCALAPPDATA/nvim|$NVIM_CONFIG"
    )
else
    CONFIGS=(
        "$HOME/.config/kitty|$KITTY_CONFIG"
        "$HOME/.config/starship.toml|$STARSHIP_CONFIG"
        "$HOME/.config/nvim|$NVIM_CONFIG"
    )
fi

link_windows_config() {
    local target="$1"
    local source="$2"

    local win_target=$(cygpath -w "$target" 2>/dev/null || echo "$target")
    local win_source=$(cygpath -w "$source" 2>/dev/null || echo "$source")

    if [[ -d "$source" ]]; then
        cmd //c "mklink /J $win_target $win_source" >/dev/null 2>&1 &&
            log_info "✓ Linked (junction): $target" ||
            log_error "Failed to create junction"
    else
        cmd //c "mklink /H $win_target $win_source" >/dev/null 2>&1 &&
            log_info "✓ Linked (hardlink): $target" ||
            log_error "Failed to create hardlink"
    fi
}
link_config() {
    local target="$1"
    local source="$2"

    mkdir -p "$(dirname "$target")"
    if [[ -e "$target" ]]; then
        log_warn "Removing existing target: $target"
        rm -rf "$target"
    fi

    if [[ "$PLATFORM" == "windows" ]]; then
        link_windows_config "$target" "$source"
    else
        ln -sf "$source" "$target" &&
            log_info "✓ Linked (symlink): $target" ||
            log_error "Failed to create symlink"
    fi
}

for mapping in "${CONFIGS[@]}"; do
    IFS='|' read -r target source <<<"$mapping"
    log_info "Installing config: $target"
    if [[ ! -e "$source" ]]; then
        log_error "Source not found: $source"
        continue
    fi
    link_config "$target" "$source"
    echo
done

log_info "Installation complete!"
