# Dotfiles

Arch Linux + Hyprland configuration with a modern, maintainable structure.

## Quick Start

### One-Line Install

```bash
curl -sL https://raw.githubusercontent.com/Rakshitk2223/dotfiles/main/boot.sh | bash
```

### Manual Install

```bash
# Clone repository
git clone https://github.com/Rakshitk2223/dotfiles.git ~/.local/bin/dotfiles

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


## Documentation

- [Installation Guide](docs/installation.md)
- [Customization Guide](docs/customization.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Architecture](docs/architecture.md)


