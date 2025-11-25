# Installation Guide

Complete guide for installing the dotfiles on a fresh Arch Linux system.

## Prerequisites

### System Requirements

- **Arch Linux** or Arch-based distro (EndeavourOS, Manjaro)
- **Bash 4.0+** (default on Arch)
- **1GB+ free disk space** in home directory
- **Internet connection**
- **sudo access**

### Required Packages

These will be installed automatically, but if you want to install manually:

```bash
sudo pacman -S git curl rsync
```

## Installation Methods

### Method 1: One-Line Install (Recommended)

```bash
curl -sL https://raw.githubusercontent.com/mohak34/dotfiles/main/boot.sh | bash
```

This will:
1. Clone the repository to `~/.local/bin/dotfiles`
2. Run the installer automatically

### Method 2: Manual Install

```bash
# 1. Clone the repository
git clone https://github.com/mohak34/dotfiles.git ~/.local/bin/dotfiles

# 2. Navigate to the directory
cd ~/.local/bin/dotfiles

# 3. Run the installer
./install.sh
```

## Installation Options

### Interactive Install (Default)

```bash
./install.sh
```

The installer will:
- Run preflight checks
- Detect your hardware (NVIDIA, ASUS)
- Ask for confirmation before major steps
- Show progress throughout

### Auto-Confirm Install

```bash
./install.sh -y
```

Automatically confirms all prompts. Useful for scripted installations.

### Minimal Install

```bash
./install.sh --minimal
```

Skips:
- Development tools (Go, Rust, Node, Bun)
- Themes (GTK, SDDM)
- Optional packages

### Dry Run (Preview)

```bash
./install.sh --dry-run
```

Shows what would be installed without making changes.

### All Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-y, --yes` | Auto-confirm all prompts |
| `--dry-run` | Preview without changes |
| `--minimal` | Skip optional packages/themes |
| `--no-preflight` | Skip preflight checks |
| `--no-packages` | Skip package installation |
| `--no-dev-tools` | Skip Go, Rust, Node, etc. |
| `--no-themes` | Skip theme installation |
| `--nvidia` | Force NVIDIA driver install |
| `--asus` | Force ASUS tools install |

## What Gets Installed

### Packages

The installer installs packages from two lists:

- `scripts/arch_packages.txt` - Official Arch packages (pacman)
- `scripts/yay_packages.txt` - AUR packages (yay)

### Configuration Files

Configs are installed to `~/.config/`:

- `hypr/` - Hyprland window manager
- `waybar/` - Status bar
- `wofi/` - Application launcher
- `dunst/` - Notifications
- `ghostty/` - Terminal
- `btop/` - System monitor

### Shell Configuration

- `~/.zshrc` - Zsh configuration (sources modular configs)
- `~/.tmux.conf` - Tmux configuration
- Oh My Zsh (if not already installed)

### Scripts

Utility scripts installed to `~/.local/bin/`:

- `dotfiles-update` - Update dotfiles
- `dotfiles-version` - Show version info
- `dotfiles-screenshot` - Screenshot tool
- `dotfiles-mic-toggle` - Microphone toggle
- `dotfiles-waybar-toggle` - Waybar toggle
- `dotfiles-refresh-config` - Refresh configs

## Hardware Detection

The installer automatically detects:

### NVIDIA GPU

If detected, offers to install:
- `nvidia-dkms` - NVIDIA kernel module
- `nvidia-utils` - NVIDIA utilities
- `nvidia-settings` - Settings app
- `libva-nvidia-driver` - VA-API driver

### ASUS Laptop

If detected, offers to install:
- `asusctl` - ASUS control daemon
- `supergfxctl` - GPU switching

### Manual Override

Force hardware packages even if not detected:

```bash
./install.sh --nvidia --asus
```

## Post-Installation

### 1. Reboot

```bash
sudo reboot
```

### 2. Start Hyprland

From TTY, run:
```bash
Hyprland
```

Or select Hyprland from your display manager (SDDM).

### 3. Install Tmux Plugins

```bash
tmux
# Then press: Ctrl+b I (capital I)
```

### 4. Verify Installation

```bash
dotfiles-version
```

Should show:
```
Dotfiles v1.0.0

Installed:    1.0.0
Install date: 2025-01-25 10:30:00
Last update:  2025-01-25 10:30:00

Status:       Up to date
```

## Troubleshooting

### Preflight Fails

If preflight checks fail:

```
[ERROR] Preflight failed with 2 error(s)
```

Check:
- Are you running as normal user (not root)?
- Do you have sudo access?
- Is internet connected?
- Is there enough disk space?

### Package Installation Fails

Some packages may fail due to:
- Mirror issues: `sudo pacman -Syy`
- Keyring issues: `sudo pacman -S archlinux-keyring`
- AUR build failures: Check the package's AUR page

### Hyprland Doesn't Start

1. Check logs: `cat ~/.local/share/hyprland/hyprland.log`
2. Verify NVIDIA drivers (if applicable): `nvidia-smi`
3. Try starting from TTY: `Hyprland`

See [Troubleshooting Guide](troubleshooting.md) for more solutions.

## Uninstallation

To remove dotfiles (keeps your customizations):

```bash
# Remove installed configs
rm -rf ~/.config/hypr ~/.config/waybar ~/.config/wofi
rm -rf ~/.config/dunst ~/.config/ghostty ~/.config/btop

# Remove dotfiles scripts
rm -f ~/.local/bin/dotfiles-*

# Remove state
rm -rf ~/.local/state/dotfiles

# Optionally remove the repository
rm -rf ~/.local/bin/dotfiles
```

## Next Steps

- [Customization Guide](customization.md) - Make it your own
- [Troubleshooting](troubleshooting.md) - Common issues
- [Architecture](architecture.md) - How it works
