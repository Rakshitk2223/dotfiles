# Dotfiles

Arch Linux + Hyprland configuration with a modern, maintainable structure.

## Features

- **Hyprland** window manager with layered config system
- **Waybar** status bar with custom modules
- **Wofi** application launcher
- **Dunst** notification daemon
- **Ghostty** terminal emulator
- **Zsh** with Oh My Zsh and modular configuration
- **Tmux** with plugin manager

### System Features

- **Config Layering** - Core configs update safely, your customizations are preserved
- **Hook System** - Run custom scripts on install/update events
- **Migration System** - Automatic upgrades between versions
- **Hardware Detection** - Auto-detects NVIDIA GPU, ASUS laptop
- **State Tracking** - Tracks installed version and update history

## Quick Start

### One-Line Install

```bash
curl -sL https://raw.githubusercontent.com/mohak34/dotfiles/main/boot.sh | bash
```

### Manual Install

```bash
# Clone repository
git clone https://github.com/mohak34/dotfiles.git ~/.local/bin/dotfiles

# Run installer
cd ~/.local/bin/dotfiles
./install.sh
```

### Install Options

```bash
./install.sh              # Full interactive install
./install.sh -y           # Auto-confirm all prompts
./install.sh --minimal    # Skip optional packages and themes
./install.sh --dry-run    # Preview without making changes
./install.sh --help       # Show all options
```

## Updating

```bash
dotfiles-update           # Interactive update
dotfiles-update -y        # Auto-confirm
dotfiles-update --check   # Check if updates available
```

## Customization

Your customizations are stored separately and never touched by updates:

### Shell (Zsh)

```
~/.config/dotfiles/zsh/
├── aliases.local      # Your custom aliases
├── functions.local    # Your custom functions
└── shell.local        # Your environment variables
```

### Hyprland

```
~/.config/hypr/local/
├── programs.conf      # Override $terminal, $browser, etc.
├── keybinds.conf      # Add/override keybindings
├── appearance.conf    # Custom colors, borders, gaps
└── custom.conf        # Any other settings
```

Example - change default terminal:
```bash
# ~/.config/hypr/local/programs.conf
$terminal = kitty
```

### Hooks

Run custom scripts on events:

```
~/.config/dotfiles/hooks/
├── post-install       # After fresh install
├── pre-update         # Before update
└── post-update        # After update
```

## Commands

| Command | Description |
|---------|-------------|
| `dotfiles-update` | Update dotfiles to latest version |
| `dotfiles-version` | Show installed version and status |
| `dotfiles-refresh-config` | Refresh core configs from repo |
| `dotfiles-hook` | Run or list hooks |
| `dotfiles-screenshot` | Take screenshots (area/fullscreen/monitor) |
| `dotfiles-mic-toggle` | Toggle microphone mute |
| `dotfiles-waybar-toggle` | Toggle waybar visibility |

## Directory Structure

```
dotfiles/
├── .config/              # Application configs
│   ├── hypr/             # Hyprland (core/ + local/)
│   ├── waybar/           # Waybar bar
│   ├── wofi/             # App launcher
│   ├── dunst/            # Notifications
│   └── ghostty/          # Terminal
├── bin/                  # dotfiles-* commands
├── lib/                  # Shared libraries (state, hooks)
├── scripts/              # Installation scripts
│   ├── helpers/          # Logging, errors, presentation
│   └── install/          # Modular install components
├── default/zsh/          # Default shell configs
├── migrations/           # Version migration scripts
├── Wallpapers/           # Wallpaper collection
└── docs/                 # Documentation
```

## Documentation

- [Installation Guide](docs/installation.md)
- [Customization Guide](docs/customization.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Architecture](docs/architecture.md)

## Requirements

- Arch Linux (or Arch-based distro)
- Git, curl, rsync
- sudo access

## License

MIT
