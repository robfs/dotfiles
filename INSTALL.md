# Building install.sh Script Step by Step

This guide breaks down creating the dotfiles installer from a simple hello world to a full-featured cross-platform script.

## Step 1: Basic Hello World Script

Let's start with the simplest possible script:

```bash
#!/bin/bash
# install.sh - Step 1: Hello World

echo "Hello, Dotfiles!"
```

**Test it:**
```bash
chmod +x install.sh
./install.sh
```

**What we learned:**
- Basic script structure with shebang
- Simple output
- Making script executable

---

## Step 2: Add Script Location Detection

```bash
#!/bin/bash
# install.sh - Step 2: Script location detection

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Hello, Dotfiles!"
echo "Script is located at: $DOTFILES_DIR"
```

**What we added:**
- `DOTFILES_DIR` variable to know where our script lives
- This will be crucial for finding our config files

---

## Step 3: Add Platform Detection

```bash
#!/bin/bash
# install.sh - Step 3: Platform detection

set -e  # Exit on any error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect what platform we're running on
detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

PLATFORM=$(detect_platform)

echo "Hello, Dotfiles!"
echo "Script is located at: $DOTFILES_DIR"
echo "Platform detected: $PLATFORM"
```

**What we added:**
- `set -e` to fail fast on errors
- Platform detection function
- This tells us whether to use symlinks or junctions/hardlinks

---

## Step 4: Add Basic Logging with Colors

```bash
#!/bin/bash
# install.sh - Step 4: Colored logging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Script location: $DOTFILES_DIR"
log_info "Platform: $PLATFORM"
log_warn "This is a warning message"
log_error "This is an error message (but script continues)"
```

**What we added:**
- Color constants for pretty output
- Logging functions with consistent formatting
- Makes the script more professional and easier to debug

---

## Step 5: Add Single Configuration Support

```bash
#!/bin/bash
# install.sh - Step 5: Single config support (kitty only)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Install kitty configuration
install_kitty() {
    local source_path="$DOTFILES_DIR/config/kitty"
    local target_path=""
    
    # Set target path based on platform
    case $PLATFORM in
        "linux"|"macos")
            target_path="$HOME/.config/kitty"
            ;;
        "windows")
            local appdata=$(cygpath "$APPDATA" 2>/dev/null || echo "$APPDATA")
            target_path="$appdata/kitty"
            ;;
    esac
    
    log_info "Installing kitty configuration..."
    log_info "Source: $source_path"
    log_info "Target: $target_path"
    
    # Check if source exists
    if [[ ! -d "$source_path" ]]; then
        log_error "Source directory not found: $source_path"
        return 1
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$target_path")"
    
    # Create symlink (we'll add other methods later)
    ln -sf "$source_path" "$target_path"
    log_info "✓ Kitty configuration installed"
}

PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Platform: $PLATFORM"

# Install kitty config
install_kitty

log_info "Installation complete!"
```

**What we added:**
- First real configuration installation (kitty)
- Platform-specific path handling
- Source validation
- Directory creation
- Basic symlinking (Unix only for now)

**Test it:**
```bash
mkdir -p config/kitty
echo "font_size 12.0" > config/kitty/kitty.conf
./install.sh
ls -la ~/.config/kitty  # Should show symlink
```

---

## Step 6: Add Windows Support (Junctions/Hardlinks)

```bash
#!/bin/bash
# install.sh - Step 6: Windows junction/hardlink support

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# Create symlink (Unix)
create_symlink() {
    local target_path="$1"
    local source_path="$2"
    
    log_debug "Creating symlink: $target_path -> $source_path"
    ln -sf "$source_path" "$target_path"
    log_info "✓ Configuration linked (symlink)"
}

# Create junction (Windows directories)
create_junction() {
    local target_path="$1"
    local source_path="$2"
    
    log_debug "Creating junction: $target_path -> $source_path"
    
    # Convert to Windows paths
    local win_target=$(cygpath -w "$target_path" 2>/dev/null || echo "$target_path")
    local win_source=$(cygpath -w "$source_path" 2>/dev/null || echo "$source_path")
    
    if cmd //c "mklink /J \"$win_target\" \"$win_source\"" >/dev/null 2>&1; then
        log_info "✓ Configuration linked (junction)"
    else
        log_error "Failed to create junction"
        return 1
    fi
}

# Install kitty configuration
install_kitty() {
    local source_path="$DOTFILES_DIR/config/kitty"
    local target_path=""
    
    case $PLATFORM in
        "linux"|"macos")
            target_path="$HOME/.config/kitty"
            ;;
        "windows")
            local appdata=$(cygpath "$APPDATA" 2>/dev/null || echo "$APPDATA")
            target_path="$appdata/kitty"
            ;;
    esac
    
    log_info "Installing kitty configuration..."
    
    if [[ ! -d "$source_path" ]]; then
        log_error "Source directory not found: $source_path"
        return 1
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$target_path")"
    
    # Remove existing target
    if [[ -e "$target_path" ]]; then
        log_warn "Removing existing target: $target_path"
        rm -rf "$target_path"
    fi
    
    # Create appropriate link type
    case $PLATFORM in
        "linux"|"macos")
            create_symlink "$target_path" "$source_path"
            ;;
        "windows")
            create_junction "$target_path" "$source_path"
            ;;
    esac
}

PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Platform: $PLATFORM"

install_kitty

log_info "Installation complete!"
```

**What we added:**
- Windows junction support using `mklink /J`
- Path conversion with `cygpath` for Windows
- Separate functions for different link types
- Debug logging level

---

## Step 7: Add Configuration Data Structure

```bash
#!/bin/bash
# install.sh - Step 7: Configuration data structure

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration storage
declare -A CONFIGS
declare -A CONFIG_TYPES

detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Set up configuration mappings
setup_config_paths() {
    case $PLATFORM in
        "linux"|"macos")
            CONFIGS[kitty]="$HOME/.config/kitty:$DOTFILES_DIR/config/kitty"
            CONFIG_TYPES[kitty]="symlink"
            ;;
        "windows")
            local appdata=$(cygpath "$APPDATA" 2>/dev/null || echo "$APPDATA")
            CONFIGS[kitty]="$appdata/kitty:$DOTFILES_DIR/config/kitty"
            CONFIG_TYPES[kitty]="junction"
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

# Generic configuration installer
install_config() {
    local app_name="$1"
    local config_mapping="${CONFIGS[$app_name]}"
    local config_type="${CONFIG_TYPES[$app_name]}"
    
    if [[ -z "$config_mapping" ]]; then
        log_error "No configuration found for: $app_name"
        return 1
    fi
    
    # Parse the mapping (target:source format)
    IFS=':' read -r target_path source_path <<< "$config_mapping"
    
    log_info "Installing $app_name configuration..."
    log_debug "Source: $source_path"
    log_debug "Target: $target_path"
    log_debug "Type: $config_type"
    
    if [[ ! -e "$source_path" ]]; then
        log_error "Source not found: $source_path"
        return 1
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$target_path")"
    
    # Remove existing target
    if [[ -e "$target_path" ]]; then
        log_warn "Removing existing target"
        rm -rf "$target_path"
    fi
    
    # Create appropriate link
    case $config_type in
        "symlink")
            create_symlink "$target_path" "$source_path"
            ;;
        "junction")
            create_junction "$target_path" "$source_path"
            ;;
        *)
            log_error "Unknown config type: $config_type"
            return 1
            ;;
    esac
}

PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Platform: $PLATFORM"

# Set up configuration paths
setup_config_paths

# Install kitty
install_config "kitty"

log_info "Installation complete!"
```

**What we added:**
- Associative arrays to store configuration mappings
- Generic `install_config()` function that works for any app
- Separation of data (config paths) from logic (installation)
- This makes it easy to add new configurations

---

## Step 8: Add Multiple Configurations

```bash
#!/bin/bash
# install.sh - Step 8: Multiple configurations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A CONFIGS
declare -A CONFIG_TYPES

detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

setup_config_paths() {
    case $PLATFORM in
        "linux"|"macos")
            CONFIGS[kitty]="$HOME/.config/kitty:$DOTFILES_DIR/config/kitty"
            CONFIGS[starship]="$HOME/.config/starship.toml:$DOTFILES_DIR/config/starship/starship.toml"
            CONFIGS[nvim]="$HOME/.config/nvim:$DOTFILES_DIR/config/nvim"
            
            CONFIG_TYPES[kitty]="symlink"
            CONFIG_TYPES[starship]="symlink" 
            CONFIG_TYPES[nvim]="symlink"
            ;;
        "windows")
            local appdata=$(cygpath "$APPDATA" 2>/dev/null || echo "$APPDATA")
            local localappdata=$(cygpath "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")
            local userprofile=$(cygpath "$USERPROFILE" 2>/dev/null || echo "$USERPROFILE")
            
            CONFIGS[kitty]="$appdata/kitty:$DOTFILES_DIR/config/kitty"
            CONFIGS[starship]="$userprofile/.config/starship.toml:$DOTFILES_DIR/config/starship/starship.toml"
            CONFIGS[nvim]="$localappdata/nvim:$DOTFILES_DIR/config/nvim"
            
            CONFIG_TYPES[kitty]="junction"
            CONFIG_TYPES[starship]="hardlink"
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
    local win_source=$(cygpath -w "$source_path" 2>/dev/null || echo "$source_source")
    
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
    
    IFS=':' read -r target_path source_path <<< "$config_mapping"
    
    log_info "Installing $app_name configuration..."
    
    if [[ ! -e "$source_path" ]]; then
        log_warn "Source not found for $app_name: $source_path"
        return 1
    fi
    
    mkdir -p "$(dirname "$target_path")"
    
    if [[ -e "$target_path" ]]; then
        log_warn "Removing existing $app_name config"
        rm -rf "$target_path"
    fi
    
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
            log_error "Unknown config type: $config_type"
            return 1
            ;;
    esac
}

PLATFORM=$(detect_platform)

log_info "Dotfiles installer starting"
log_info "Platform: $PLATFORM"

setup_config_paths

# Install all configurations
for app in "${!CONFIGS[@]}"; do
    install_config "$app"
    echo  # Empty line for readability
done

log_info "Installation complete!"
```

**What we added:**
- Support for kitty, starship, and nvim
- Hardlink support for individual files (starship config)
- Different link types per platform (junctions for directories, hardlinks for files on Windows)
- Loop to install all configurations

**Test it:**
```bash
# Create test configs
mkdir -p config/{kitty,starship,nvim}
echo "font_size 12.0" > config/kitty/kitty.conf  
echo 'format = "$directory$character"' > config/starship/starship.toml
echo 'vim.opt.number = true' > config/nvim/init.lua

./install.sh
```

---

## Step 9: Add Command Line Arguments

```bash
#!/bin/bash
# install.sh - Step 9: Command line arguments

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A CONFIGS
declare -A CONFIG_TYPES

# ... (previous functions remain the same) ...

# List available configurations
list_configs() {
    echo -e "${CYAN}Available configurations for $PLATFORM:${NC}"
    for app in "${!CONFIGS[@]}"; do
        echo "  - $app (${CONFIG_TYPES[$app]})"
    done
}

# Install configurations (all or specific)
install_configs() {
    local specific_app="$1"
    
    if [[ -n "$specific_app" ]]; then
        if [[ -n "${CONFIGS[$specific_app]}" ]]; then
            install_config "$specific_app"
        else
            log_error "Unknown configuration: $specific_app"
            echo
            list_configs
            exit 1
        fi
    else
        for app in "${!CONFIGS[@]}"; do
            install_config "$app"
            echo
        done
    fi
}

# Main function
main() {
    local specific_app=""
    local list_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--app)
                specific_app="$2"
                shift 2
                ;;
            -l|--list)
                list_mode=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -a, --app APP        Install specific app configuration"
                echo "  -l, --list           List available configurations"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                   Install all configurations"
                echo "  $0 --app kitty       Install only Kitty configuration"
                echo "  $0 --list            Show available configurations"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo -e "${CYAN}=== Dotfiles Installer ===${NC}"
    echo -e "${CYAN}Platform: $PLATFORM${NC}"
    echo -e "${CYAN}Dotfiles directory: $DOTFILES_DIR${NC}"
    echo
    
    setup_config_paths
    
    if [[ "$list_mode" == true ]]; then
        list_configs
        exit 0
    fi
    
    install_configs "$specific_app"
    
    log_info "Installation complete! 🎉"
}

PLATFORM=$(detect_platform)

# Run main function with all arguments
main "$@"
```

**What we added:**
- Command line argument parsing
- Help system (`--help`)
- List mode (`--list`) to see available configs
- Selective installation (`--app kitty`)
- Main function structure

**Test it:**
```bash
./install.sh --help
./install.sh --list
./install.sh --app kitty
./install.sh  # Install all
```

---

## Step 10: Add Backup System

```bash
#!/bin/bash
# install.sh - Step 10: Backup system

# ... (previous code remains the same) ...

# Backup existing configuration
backup_config() {
    local target_path="$1"
    local app_name="$2"
    
    if [[ -e "$target_path" ]]; then
        local backup_path="${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backing up existing $app_name config to: $backup_path"
        mv "$target_path" "$backup_path"
    fi
}

# Modified install_config function
install_config() {
    local app_name="$1"
    local config_mapping="${CONFIGS[$app_name]}"
    local config_type="${CONFIG_TYPES[$app_name]}"
    
    if [[ -z "$config_mapping" ]]; then
        log_error "No configuration found for: $app_name"
        return 1
    fi
    
    IFS=':' read -r target_path source_path <<< "$config_mapping"
    
    log_info "Installing $app_name configuration..."
    
    if [[ ! -e "$source_path" ]]; then
        log_warn "Source not found for $app_name: $source_path"
        return 1
    fi
    
    mkdir -p "$(dirname "$target_path")"
    
    # Backup instead of just removing
    backup_config "$target_path" "$app_name"
    
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
            log_error "Unknown config type: $config_type"
            return 1
            ;;
    esac
}

# ... (rest remains the same) ...
```

**What we added:**
- Automatic backup with timestamps
- Safe installation that preserves existing configs
- Never lose your existing settings

---

## Step 11: Add Verification and Debug Mode

```bash
#!/bin/bash
# install.sh - Step 11: Final version with verification

# ... (previous code) ...

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Verify installation
verify_installation() {
    local app_name="$1"
    local config_mapping="${CONFIGS[$app_name]}"
    
    if [[ -z "$config_mapping" ]]; then
        return 1
    fi
    
    IFS=':' read -r target_path source_path <<< "$config_mapping"
    
    if [[ -e "$target_path" ]]; then
        echo -e "${GREEN}✓${NC} $app_name: $target_path"
        return 0
    else
        echo -e "${RED}✗${NC} $app_name: $target_path (not found)"
        return 1
    fi
}

# Updated main function with new options
main() {
    local specific_app=""
    local list_mode=false
    local verify_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--app)
                specific_app="$2"
                shift 2
                ;;
            -l|--list)
                list_mode=true
                shift
                ;;
            -v|--verify)
                verify_mode=true
                shift
                ;;
            -d|--debug)
                DEBUG=1
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -a, --app APP        Install specific app configuration"
                echo "  -l, --list           List available configurations"
                echo "  -v, --verify         Verify existing installations"
                echo "  -d, --debug          Enable debug output"
                echo "  -h, --help           Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo -e "${CYAN}=== Dotfiles Installer ===${NC}"
    echo -e "${CYAN}Platform: $PLATFORM${NC}"
    echo -e "${CYAN}Dotfiles directory: $DOTFILES_DIR${NC}"
    echo
    
    setup_config_paths
    
    if [[ "$list_mode" == true ]]; then
        list_configs
        exit 0
    fi
    
    if [[ "$verify_mode" == true ]]; then
        echo -e "${CYAN}Verifying installations:${NC}"
        for app in "${!CONFIGS[@]}"; do
            verify_installation "$app"
        done
        exit 0
    fi
    
    install_configs "$specific_app"
    
    log_info "Installation complete! 🎉"
}

PLATFORM=$(detect_platform)
main "$@"
```

**What we added:**
- Verification mode (`--verify`) to check what's installed
- Debug mode (`--debug`) for troubleshooting
- More robust error handling

**Test the final script:**
```bash
./install.sh --debug --app kitty    # Debug single install
./install.sh --verify               # Check status
./install.sh --list                 # See what's available
./install.sh                        # Install everything
```

## Summary

We built the installer in 11 progressive steps:

1. **Hello World** - Basic script structure
2. **Script Location** - Find dotfiles directory  
3. **Platform Detection** - Know what OS we're on
4. **Colored Logging** - Professional output
5. **Single Config** - Install one app (kitty)
6. **Windows Support** - Junctions and hardlinks
7. **Data Structure** - Organized configuration mapping
8. **Multiple Configs** - Support kitty, starship, nvim
9. **Command Line Args** - User-friendly interface
10. **Backup System** - Never lose existing configs
11. **Verification & Debug** - Tools for troubleshooting

Each step builds on the previous ones, making it easy to understand how each piece works. You can stop at any step and have a working script, then add more features as needed!

## Building Your Own

To build this yourself:

1. **Start with Step 1** and get it working
2. **Ad
