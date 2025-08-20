# dotfiles
Personal configuration files

## Installation

```bash
git clone https://github.com/robfs/dotfiles.git
cd dotfiles
./install.sh
```

> [!NOTE]
> You cannot use Windows Terminal to run this script, even in a Bash shell.
> Use the Git Bash terminal directly and Windows Terminal **must be closed**.

## Configurations

* Kitty - terminal config (unix only)
* Windows Terminal - terminal config (windows only)
* Starship - shell prompt config
* Neovim - text editor config

### New Configuration

To add a new configuration:

1. Add a new directory within the `config` directory.
1. Copy the relevant configuration files into that directory.
1. Add a new config path to the `Config Paths` section in the [`install.sh`](install.sh) script.
1. Link the configuration to its destination in the `Config Mappings` section.

> [!NOTE]
> Add both the Unix and Windows destination paths if needed.
> Both files and directories are supported.

## Structure

```sh
dotfiles
├── config
│   ├── kitty
│   │   ├── current-theme.conf
│   │   └── kitty.conf
│   ├── nvim
│   │   ├── after
│   │   │   └── ftplugin
│   │   │       ├── a.lua
│   │   │       └── b.lua
│   │   ├── init.lua
│   │   └── lua
│   │       ├── config
│   │       │   ├── keymaps.lua
│   │       │   ├── lazy.lua
│   │       │   └── options.lua
│   │       └── custom
│   │           └── plugins
│   │               ├── c.lua
│   │               └── d.lua
│   ├── starship
│   │   └── starship.toml
│   └── windowsterminal
│       └── settings.json
├── install.sh
└── README.md
```

