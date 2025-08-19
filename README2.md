# Cross-Platform Dotfiles Setup Guide (Bash Only)

A step-by-step guide to set up a dotfiles repository that works across Windows (Git Bash/WSL), macOS, and Linux using a single bash installer with junctions/hardlinks on Windows and symbolic links on Unix systems.

## Repository Structure

First, create your dotfiles repository with this structure:

```
dotfiles/
├── README.md
├── install.sh              # Universal bash installer
├── config/
│   ├── kitty/
│   │   └── kitty.conf
│   ├── starship/
│   │   └── starship.toml
│   └── nvim/
│       ├── init.lua
│       ├── lua/
│       └── ...
├── scripts/
│   ├── detect-platform.sh
│   └── backup.sh
└── docs/
    └── setup.md
```

## Step 1: Initialize Repository

```bash
# Create the repository
mkdir dotfiles && cd dotfiles
git init

# Create directory structure
mkdir -p config/{kitty,starship,nvim}
mkdir -p scripts docs

# Create initial README
echo "# My Dotfiles" > README.md
```

## Step 2: Move Existing Configurations

### Find Your Current Config Locations

**Windows (Git Bash/WSL paths):**
- Kitty: `$APPDATA/kitty/kitty.conf` (or `/c/Users/$USER/AppData/Roaming/kitty/`)
- Starship: `$USERPROFILE/.config/starship.toml` (or `/c/Users/$USER/.config/`)
- Neovim: `$LOCALAPPDATA/nvim/` (or `/c/Users/$USER/AppData/Local/nvim/`)

**macOS/Linux:**
- Kitty: `~/.config/kitty/kitty.conf`
- Starship: `~/.config/starship.toml`
- Neovim: `~/.config/nvim/`

### Move Configs to Repository

```bash
# Example for moving existing configs (adjust paths as needed)

# If you have existing kitty config
cp ~/.config/kitty/kitty.conf config/kitty/ 2>/dev/null || echo "No existing kitty config found"

# If you have existing starship config
cp ~/.config/starship.toml config/starship/ 2>/dev/null || echo "No existing starship config found"

# If you have existing neovim config
cp -r ~/.config/nvim/* config/nvim/ 2>/dev/null || echo "No existing neovim config found"
```

## Step 3: Create Universal Bash Installer

Create the main installer that works on all platforms:

```bash
#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect platform
detect_platform() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*|mingw*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

PLATFORM=$(detect_platform)

# Configuration mapping - adjust based on platform
declare -A CONFIGS
declare -A CONFIG_TYPES

setup_config_paths() {
    case $PLATFORM in
        "linux"|"macos")
            # Standard Unix paths with symlinks
            CONFIGS[kitty]="$HOME/.config/kitty:$DOTFILES_DIR/config/kitty"
            CONFIGS[starship]="$HOME/.config/starship.toml:$DOTFILES_DIR/config/starship/starship.toml"
            CONFIGS[nvim]="$HOME/.config/nvim:$DOTFILES_DIR/config/nvim"
            
            CONFIG_TYPES[kitty]="symlink"
            CONFIG_TYPES[starship]="symlink"
            CONFIG_TYPES[nvim]="symlink"
            ;;
        "windows")
            # Windows paths with junctions and hardlinks
            # Convert Windows paths for Git Bash
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

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

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

# Create symlink (Unix systems)
create_symlink() {
    local target_path="$1"
    local source_path="$2"
    local app_name="$3"
    
    log_debug "Creating symlink: $target_path -> $source_path"
    
    # Create parent directories
    mkdir -p "$(dirname "$target_path")"
    
    # Create symbolic link
    ln -sf "$source_path" "$target_path"
    log_info "✓ $app_name configuration linked (symlink)"
}

# Create junction (Windows directories)
create_junction() {
    local target_path="$1"
    local source_path="$2"
    local app_name="$3"
    
    log_debug "Creating junction: $target_path -> $source_path"
    
    # Convert paths back to Windows format for mklink
    local win_target=$(cygpath -w "$target_path" 2>/dev/null || echo "$target_path")
    local win_source=$(cygpath -w "$source_path" 2>/dev/null || echo "$source_path")
    
    # Create parent directories
    mkdir -p "$(dirname "$target_path")"
    
    # Create junction using cmd
    if cmd //c "mklink /J \"$win_target\" \"$win_source\"" >/dev/null 2>&1; then
        log_info "✓ $app_name configuration linked (junction)"
    else
        log_error "Failed to create junction for $app_name"
        return 1
    fi
}

# Create hardlink (Windows files)
create_hardlink() {
    local target_path="$1"
    local source_path="$2"
    local app_name="$3"
    
    log_debug "Creating hardlink: $target_path -> $source_path"
    
    # Convert paths back to Windows format for mklink
    local win_target=$(cygpath -w "$target_path" 2>/dev/null || echo "$target_path")
    local win_source=$(cygpath -w "$source_path" 2>/dev/null || echo "$source_path")
    
    # Create parent directories
    mkdir -p "$(dirname "$target_path")"
    
    # Create hardlink using cmd
    if cmd //c "mklink /H \"$win_target\" \"$win_source\"" >/dev/null 2>&1; then
        log_info "✓ $app_name configuration linked (hardlink)"
    else
        log_error "Failed to create hardlink for $app_name"
        return 1
    fi
}

# Install configuration for specific app
install_config() {
    local app_name="$1"
    local config_mapping="${CONFIGS[$app_name]}"
    local config_type="${CONFIG_TYPES[$app_name]}"
    
    if [[ -z "$config_mapping" ]]; then
        log_error "No configuration mapping found for: $app_name"
        return 1
    fi
    
    IFS=':' read -r target_path source_path <<< "$config_mapping"
    
    if [[ ! -e "$source_path" ]]; then
        log_warn "Source config not found for $app_name: $source_path"
        return 1
    fi
    
    log_info "Installing $app_name configuration..."
    log_debug "Source: $source_path"
    log_debug "Target: $target_path"
    log_debug "Type: $config_type"
    
    # Backup existing config
    backup_config "$target_path" "$app_name"
    
    # Create appropriate link type
    case $config_type in
        "symlink")
            create_symlink "$target_path" "$source_path" "$app_name"
            ;;
        "junction")
            create_junction "$target_path" "$source_path" "$app_name"
            ;;
        "hardlink")
            create_hardlink "$target_path" "$source_path" "$app_name"
            ;;
        *)
            log_error "Unknown config type: $config_type"
            return 1
            ;;
    esac
}

# List available configurations
list_configs() {
    echo -e "${CYAN}Available configurations for $PLATFORM:${NC}"
    for app in "${!CONFIGS[@]}"; do
        echo "  - $app (${CONFIG_TYPES[$app]})"
    done
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

# Main function
main() {
    local specific_app=""
    local verify_mode=false
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
                echo ""
                echo "Examples:"
                echo "  $0                   Install all configurations"
                echo "  $0 --app kitty       Install only Kitty configuration"
                echo "  $0 --list            Show available configurations"
                echo "  $0 --verify          Check current installation status"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo -e "${CYAN}=== Cross-Platform Dotfiles Installer ===${NC}"
    echo -e "${CYAN}Platform detected: $PLATFORM${NC}"
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
    
    # Install configurations
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
    
    echo -e "${GREEN}Installation complete! 🎉${NC}"
    echo
    echo "Next steps:"
    echo "1. Test your applications to ensure configs are loaded"
    echo "2. Run '$0 --verify' to check installation status"
    echo "3. Make changes in $DOTFILES_DIR/config/ - they'll sync automatically!"
}

# Run main function with all arguments
main "$@"
```

## Step 4: Installation Steps

### On All Systems (Windows, macOS, Linux)

1. **Open your terminal:**
   - **Windows**: Git Bash or WSL
   - **macOS/Linux**: Any terminal

2. **Navigate to your dotfiles directory**

3. **Make installer executable and run:**

```bash
# Make executable
chmod +x install.sh

# Install all configurations
./install.sh

# Or install specific app
./install.sh --app kitty

# List available configurations
./install.sh --list

# Verify installation
./install.sh --verify

# Debug mode for troubleshooting
./install.sh --debug
```

## Step 5: Test Your Setup

### Kitty Terminal
1. **Start Kitty**
2. **Check if your config is loaded** (colors, fonts, etc.)
3. **Make a test change** in `config/kitty/kitty.conf`
4. **Reload Kitty** (`Ctrl+Shift+F5`) to see changes instantly

### Starship Prompt
1. **Add starship to your shell config:**

```bash
# For bash - add to ~/.bashrc (or ~/.bash_profile on macOS)
eval "$(starship init bash)"

# For zsh - add to ~/.zshrc
eval "$(starship init zsh)"

# For fish - add to ~/.config/fish/config.fish
starship init fish | source
```

2. **Restart your terminal**
3. **You should see the starship prompt**
4. **Test by editing** `config/starship/starship.toml`

### Neovim
1. **Start neovim:** `nvim`
2. **Check if your config loads without errors**
3. **Make a test change** in `config/nvim/init.lua`
4. **Restart neovim** to see changes

## Step 6: Verify Everything Works

```bash
# Check what was created
./install.sh --verify

# On Windows, you can also check with:
# cmd //c "dir /AL %APPDATA%\kitty"
# cmd //c "dir /AL %LOCALAPPDATA%\nvim"
```

## Step 7: Adding More Configurations

To add new configurations (e.g., tmux, git):

1. **Add config files to repository:**
```bash
mkdir config/tmux
# Copy or create your .tmux.conf in config/tmux/
```

2. **Update the installer by modifying the `setup_config_paths()` function:**

```bash
# Add to both Unix and Windows sections:
# Unix:
CONFIGS[tmux]="$HOME/.tmux.conf:$DOTFILES_DIR/config/tmux/.tmux.conf"
CONFIG_TYPES[tmux]="symlink"

# Windows:
CONFIGS[tmux]="$userprofile/.tmux.conf:$DOTFILES_DIR/config/tmux/.tmux.conf"
CONFIG_TYPES[tmux]="hardlink"
```

3. **Run installer again:**
```bash
./install.sh --app tmux
```

## Troubleshooting

### Windows-Specific Issues

**Git Bash path conversion issues:**
```bash
# Debug path conversion
./install.sh --debug --app kitty
```

**Junction/hardlink creation fails:**
```bash
# Check if target already exists
ls -la "$APPDATA/kitty" 2>/dev/null || echo "Target doesn't exist"

# Manual cleanup if needed
rm -rf "$APPDATA/kitty"
./install.sh --app kitty
```

**Permission issues:**
- Junctions and hardlinks don't need admin rights
- If you get permission errors, check if files are in use

### Unix Issues

**Symlinks not working:**
```bash
# Check if symlink was created
ls -la ~/.config/kitty

# Should show something like:
# ~/.config/kitty -> /path/to/dotfiles/config/kitty
```

**Config not loading:**
- Some apps need restart after symlinking
- Check app-specific config file locations

### General Debugging

```bash
# Run with debug output
./install.sh --debug

# Check current status
./install.sh --verify

# List what should be installed
./install.sh --list
```

## Maintenance

### Daily Use
- **Edit files directly in `dotfiles/config/`** - changes reflect immediately
- **No need to re-run installer** unless adding new configs
- **Commit changes regularly:**
```bash
cd ~/dotfiles
git add .
git commit -m "Update kitty theme"
git push
```

### New Machine Setup

1. **Clone your repository:**
```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
```

2. **Run the installer:**
```bash
chmod +x install.sh
./install.sh
```

3. **Done!** Your familiar setup is ready 🎉

## Pro Tips

1. **Create minimal starter configs** if you don't have existing ones:
```bash
# Kitty
echo "font_size 12.0" > config/kitty/kitty.conf

# Starship
echo 'format = "$directory$git_branch$character"' > config/starship/starship.toml

# Neovim
echo 'vim.opt.number = true' > config/nvim/init.lua
```

2. **Test on each platform** before committing
3. **Use version control branches** for experimental configs
4. **Document platform-specific quirks** in your README

This single-script approach is much cleaner and easier to maintain while still handling all the platform differences automatically!
