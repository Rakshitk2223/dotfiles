# Customization Guide

How to customize your dotfiles without losing changes on updates.

## Overview

This dotfiles system uses a **layered configuration** approach:

1. **Core configs** - Default settings from the repository (may be updated)
2. **Local configs** - Your personal overrides (never touched by updates)

Local configs are loaded *after* core configs, so your settings win.

## Shell Customization (Zsh)

Your shell customizations live in `~/.config/dotfiles/zsh/`:

```
~/.config/dotfiles/zsh/
├── aliases.local      # Your custom aliases
├── functions.local    # Your custom functions
└── shell.local        # Your environment variables
```

### Custom Aliases

Edit `~/.config/dotfiles/zsh/aliases.local`:

```bash
# Project shortcuts
alias projects="cd ~/Projects"
alias work="cd ~/Work"

# Tool preferences
alias vim="nvim"
alias cat="bat"

# Git shortcuts
alias gs="git status"
alias gc="git commit"
alias gp="git push"
```

### Custom Functions

Edit `~/.config/dotfiles/zsh/functions.local`:

```bash
# Quick project setup
mkproject() {
    mkdir -p ~/Projects/"$1"
    cd ~/Projects/"$1"
    git init
    echo "# $1" > README.md
}

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "Unknown format: $1" ;;
        esac
    fi
}

# Fuzzy cd into directory
fcd() {
    local dir
    dir=$(find . -type d 2>/dev/null | fzf)
    [[ -n "$dir" ]] && cd "$dir"
}
```

### Custom Environment Variables

Edit `~/.config/dotfiles/zsh/shell.local`:

```bash
# Development
export EDITOR="nvim"
export BROWSER="zen-browser"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Custom paths
export PATH="$HOME/scripts:$PATH"

# Secrets (don't commit these!)
export GITHUB_TOKEN="your-token-here"
export OPENAI_API_KEY="your-key-here"
```

## Hyprland Customization

Hyprland configs use a core/local split:

```
~/.config/hypr/
├── core/                  # From repo (updated automatically)
│   ├── appearance.conf
│   ├── keybinds.conf
│   ├── programs.conf
│   └── ...
├── local/                 # Your overrides (never touched)
│   ├── programs.conf
│   ├── keybinds.conf
│   └── custom.conf
├── monitors.conf          # Your monitor setup
└── hyprland.conf          # Main config (sources core/ then local/)
```

### Change Default Programs

Create `~/.config/hypr/local/programs.conf`:

```bash
# Override default terminal
$terminal = kitty

# Override default browser
$browser = firefox

# Override default file manager
$fileManager = nautilus

# Override default menu
$menu = rofi -show drun
```

### Add Custom Keybindings

Create `~/.config/hypr/local/keybinds.conf`:

```bash
# Custom application launchers
bind = $mainMod, C, exec, code
bind = $mainMod, O, exec, obsidian
bind = $mainMod, D, exec, discord

# Custom scripts
bind = $mainMod, P, exec, ~/scripts/project-picker.sh
bind = $mainMod+Shift, W, exec, ~/scripts/wallpaper-picker.sh

# Override existing keybind
bind = $mainMod, Return, exec, kitty  # Use kitty instead of ghostty
```

### Custom Appearance

Create `~/.config/hypr/local/appearance.conf`:

```bash
# Larger gaps
general {
    gaps_in = 8
    gaps_out = 16
    border_size = 3
}

# Different colors
general {
    col.active_border = rgba(89b4faee) rgba(cba6f7ee) 45deg
    col.inactive_border = rgba(45475aaa)
}

# Faster animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 3, myBezier
    animation = fade, 1, 3, default
}
```

### Custom Window Rules

Create `~/.config/hypr/local/windowrules.conf`:

```bash
# Float specific apps
windowrulev2 = float, class:^(Calculator)$
windowrulev2 = float, class:^(file-roller)$
windowrulev2 = float, title:^(Open File)$

# Workspace assignments
windowrulev2 = workspace 2, class:^(firefox)$
windowrulev2 = workspace 3, class:^(code)$
windowrulev2 = workspace 4, class:^(discord)$

# Opacity
windowrulev2 = opacity 0.95, class:^(kitty)$
```

### Monitor Configuration

Edit `~/.config/hypr/monitors.conf` (not in local/ - it's hardware-specific):

```bash
# Single monitor
monitor = , preferred, auto, 1

# Dual monitor setup
monitor = DP-1, 2560x1440@144, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1

# Laptop with external
monitor = eDP-1, 1920x1080@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@60, 1920x0, 1
```

## Hook System

Hooks let you run custom scripts on events.

### Available Hooks

| Hook | When it runs |
|------|--------------|
| `post-install` | After fresh installation |
| `pre-update` | Before updating dotfiles |
| `post-update` | After updating dotfiles |

### Creating Hooks

Hooks live in `~/.config/dotfiles/hooks/`:

```bash
# Create post-update hook
cat > ~/.config/dotfiles/hooks/post-update << 'EOF'
#!/bin/bash
# Runs after dotfiles update

# Reload Hyprland
hyprctl reload

# Notify
notify-send "Dotfiles" "Update complete!"

# Restart waybar
pkill waybar && waybar &
EOF

# Make executable
chmod +x ~/.config/dotfiles/hooks/post-update
```

### Example Hooks

**Post-install hook** - Set up additional tools:

```bash
#!/bin/bash
# ~/.config/dotfiles/hooks/post-install

# Install additional packages I use
yay -S --noconfirm spotify discord slack-desktop

# Clone my projects
git clone git@github.com:me/project1.git ~/Projects/project1

# Set up SSH keys
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi
```

**Pre-update hook** - Backup before update:

```bash
#!/bin/bash
# ~/.config/dotfiles/hooks/pre-update

# Backup current configs
backup_dir="$HOME/.config/dotfiles/backups/$(date +%Y%m%d)"
mkdir -p "$backup_dir"
cp -r ~/.config/hypr/local "$backup_dir/"
```

**Post-update hook** - Reload services:

```bash
#!/bin/bash
# ~/.config/dotfiles/hooks/post-update

# Reload Hyprland config
hyprctl reload

# Restart waybar
pkill waybar; sleep 1; waybar &

# Show notification
notify-send "Dotfiles Updated" "Version: $(dotfiles-version --short)"
```

## Config Refresh

If you want to reset a core config to defaults:

```bash
# Preview changes
dotfiles-refresh-config -d hypr

# Refresh with confirmation
dotfiles-refresh-config hypr

# Force refresh (no prompts)
dotfiles-refresh-config -f hypr
```

This only updates `core/` files. Your `local/` files are untouched.

## Best Practices

### 1. Never Edit Core Files

Don't edit files in `~/.config/hypr/core/`. Create overrides in `local/` instead.

### 2. Use Local Configs

Always put customizations in the designated local directories:
- Shell: `~/.config/dotfiles/zsh/`
- Hyprland: `~/.config/hypr/local/`

### 3. Version Control Your Customizations

Consider creating a separate repo for your local configs:

```bash
cd ~/.config/dotfiles
git init
git add zsh/ hooks/
git commit -m "My customizations"
```

### 4. Document Your Changes

Add comments explaining why you made changes:

```bash
# ~/.config/hypr/local/keybinds.conf

# Use kitty instead of ghostty (ghostty crashes on my GPU)
bind = $mainMod, Return, exec, kitty
```

### 5. Test Before Committing

Test your changes work before relying on them:

```bash
# Reload Hyprland config
hyprctl reload

# Check for errors
hyprctl clients
```

## Examples

See the `examples/` directory for sample configurations:

- `examples/hooks/post-install` - Example post-install hook
- `examples/hooks/post-update` - Example post-update hook
- `examples/hypr-local/keybinds.conf` - Example custom keybinds
- `examples/hypr-local/appearance.conf` - Example appearance overrides

Copy and modify these as starting points for your customizations:

```bash
# Copy hook example
mkdir -p ~/.config/dotfiles/hooks
cp ~/.local/bin/dotfiles/examples/hooks/post-update ~/.config/dotfiles/hooks/
chmod +x ~/.config/dotfiles/hooks/post-update

# Copy Hyprland local config example
mkdir -p ~/.config/hypr/local
cp ~/.local/bin/dotfiles/examples/hypr-local/keybinds.conf ~/.config/hypr/local/
```
