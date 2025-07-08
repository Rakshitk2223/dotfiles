# Modular Dotfiles Structure

This directory contains a modular Hyprland configuration that can be easily transported between systems.

## Structure

### Hyprland Configuration Files

- `hyprland.conf` - Main configuration file that sources all other configs
- `monitors.conf` - Monitor configuration
- `programs.conf` - Default programs settings
- `autostart.conf` - Applications to start automatically
- `environment.conf` - Environment variables
- `appearance.conf` - Look and feel, animations, decorations
- `input.conf` - Input devices and gestures
- `layout.conf` - Window layout settings
- `keybinds.conf` - Keyboard shortcuts and bindings
- `windowrules.conf` - Window rules and behavior
- `nvidia.conf` - NVIDIA-specific settings

### Scripts

#### System-wide Scripts (in `~/.local/bin/scripts/`)
General-purpose scripts that can be called from anywhere:

- `set-permissions.sh` - Sets executable permissions for all scripts (runs at startup)
- `setup-path.sh` - Ensures ~/.local/bin is in PATH
- `mic-toggle.sh` - Toggles microphone mute with notifications (called by keybinds)
- `screenshot.sh` - Advanced screenshot functionality with annotation support
- `waybar-toggle.sh` - Toggles Waybar visibility
- `verify-dotfiles.sh` - Verifies dotfiles installation
- `install-dotfiles-enhanced.sh` - Enhanced installation script

#### Application-specific Scripts (in component directories)
Scripts tightly coupled to specific applications:

##### Waybar Scripts (in `~/.config/waybar/scripts/`)
- `microphone.sh` - Microphone status for Waybar (called by waybar config)
- `updates.sh` - System updates status for Waybar (called by waybar config)

> **Best Practice**: Keep application-specific scripts in their respective config directories when they are tightly coupled to that application's configuration.

## Installation on a New System

### Automatic Installation (Recommended)
1. Copy the dotfiles directory to your new system
2. Run the installation script: `./install-dotfiles.sh`
3. Restart Hyprland or reload configuration: `hyprctl reload`

### Manual Installation
1. Copy the entire `.config/hypr/` directory to `~/.config/hypr/`
2. Copy the entire `.config/waybar/` directory to `~/.config/waybar/`
3. Copy the scripts from `.local/bin/scripts/` to `~/.local/bin/scripts/`
4. Make sure all scripts are executable: `chmod +x ~/.local/bin/scripts/*.sh`
5. Restart Hyprland or reload the configuration

### Verification
Run the verification script anytime to check your setup:
```bash
~/.local/bin/scripts/verify-dotfiles.sh
```

## Key Features

- **Modular Design**: Each aspect of the configuration is in a separate file
- **Portable**: Uses `$HOME` and relative paths instead of hardcoded paths
- **Organized Scripts**: All scripts are centrally located and properly managed
- **Documentation**: Each file is well-commented for easy understanding
- **Backup-Friendly**: Easy to backup and restore individual components

## Dependencies

The configuration expects the following tools to be installed:
- hyprland
- waybar
- wofi
- dunst
- pamixer
- grim
- slurp
- swappy
- wl-clipboard
- cliphist
- brightnessctl
- playerctl
- jq

## Customization

To customize the configuration:
1. Edit the relevant `.conf` file in `~/.config/hypr/`
2. Reload Hyprland configuration: `hyprctl reload`

For script modifications:
1. Edit the script in `~/.local/bin/scripts/`
2. Ensure it remains executable
3. Test the functionality

## Troubleshooting

If keybinds don't work:
1. Check that scripts are executable: `ls -la ~/.local/bin/scripts/`
2. Verify paths in `keybinds.conf` match actual script locations
3. Test scripts manually: `~/.local/bin/scripts/screenshot.sh area`

If Hyprland doesn't start:
1. Check syntax in configuration files
2. Use the backup: `cp ~/.config/hypr/hyprland.conf.backup-* ~/.config/hypr/hyprland.conf`
3. Check Hyprland logs for errors