# Troubleshooting Guide

Solutions for common issues with the dotfiles installation and usage.

## Quick Diagnostics

Run these commands first to gather information:

```bash
# Check dotfiles version and status
dotfiles-version

# Check Hyprland logs
cat ~/.local/share/hyprland/hyprland.log | tail -50

# Check systemd user services
systemctl --user status

# Check journal for errors
journalctl --user -xe --no-pager | tail -100
```

## Installation Issues

### Preflight Checks Fail

**Error**: `Preflight failed with X error(s)`

**Solutions**:

1. **Running as root**
   ```bash
   # Don't run as root! Run as normal user
   exit  # If in root shell
   ./install.sh
   ```

2. **No sudo access**
   ```bash
   # Add yourself to wheel group (requires admin)
   su -c "usermod -aG wheel $USER"
   # Log out and back in
   ```

3. **Missing dependencies**
   ```bash
   sudo pacman -S git curl rsync
   ```

4. **No internet connection**
   ```bash
   # Check connectivity
   ping -c 3 archlinux.org
   
   # If using WiFi, try
   nmcli device wifi connect "SSID" password "PASSWORD"
   ```

5. **Not enough disk space**
   ```bash
   # Check disk usage
   df -h ~
   
   # Clean package cache
   sudo pacman -Scc
   
   # Remove old packages
   sudo pacman -Rns $(pacman -Qdtq)
   ```

### Package Installation Fails

**Error**: `Failed to install packages`

**Solutions**:

1. **Refresh mirrors**
   ```bash
   sudo pacman -Syy
   ```

2. **Keyring issues**
   ```bash
   sudo pacman -S archlinux-keyring
   sudo pacman-key --init
   sudo pacman-key --populate archlinux
   ```

3. **Corrupted package database**
   ```bash
   sudo rm -rf /var/lib/pacman/sync
   sudo pacman -Syy
   ```

4. **AUR package fails to build**
   ```bash
   # Install build dependencies
   sudo pacman -S base-devel
   
   # Try building manually
   cd /tmp
   git clone https://aur.archlinux.org/PACKAGE.git
   cd PACKAGE
   makepkg -si
   ```

5. **Specific package conflict**
   ```bash
   # Check what's conflicting
   sudo pacman -S package_name 2>&1 | grep conflict
   
   # Remove conflicting package first
   sudo pacman -R conflicting_package
   ```

### Yay Not Found

**Error**: `yay: command not found`

```bash
# Install yay manually
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

## Hyprland Issues

### Hyprland Won't Start

**Symptoms**: Black screen, crash on login, returns to TTY

1. **Check logs**
   ```bash
   cat ~/.local/share/hyprland/hyprland.log
   ```

2. **Start from TTY with verbose output**
   ```bash
   # Switch to TTY: Ctrl+Alt+F2
   Hyprland 2>&1 | tee /tmp/hyprland-debug.log
   ```

3. **Check config syntax**
   ```bash
   # Hyprland validates on reload
   hyprctl reload 2>&1
   ```

4. **Reset to default config**
   ```bash
   # Backup current config
   mv ~/.config/hypr/local ~/.config/hypr/local.bak
   
   # Try starting again
   Hyprland
   ```

### NVIDIA GPU Issues

**Symptoms**: Flickering, artifacts, crash with NVIDIA

1. **Verify drivers installed**
   ```bash
   nvidia-smi
   ```

2. **Check NVIDIA config is sourced**
   ```bash
   # In ~/.config/hypr/hyprland.conf, should have:
   source = ~/.config/hypr/nvidia.conf
   ```

3. **Force NVIDIA environment variables**
   ```bash
   # Add to ~/.config/hypr/local/environment.conf
   env = LIBVA_DRIVER_NAME,nvidia
   env = __GLX_VENDOR_LIBRARY_NAME,nvidia
   env = GBM_BACKEND,nvidia-drm
   env = __GL_VRR_ALLOWED,1
   env = WLR_NO_HARDWARE_CURSORS,1
   ```

4. **Check kernel modules**
   ```bash
   lsmod | grep nvidia
   # Should show: nvidia, nvidia_modeset, nvidia_drm, nvidia_uvm
   
   # If missing, try:
   sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm
   ```

5. **Regenerate initramfs**
   ```bash
   sudo mkinitcpio -P
   sudo reboot
   ```

### Screen Flickering

1. **Disable VRR**
   ```bash
   # Add to ~/.config/hypr/local/appearance.conf
   misc {
       vrr = 0
   }
   ```

2. **Set explicit refresh rate**
   ```bash
   # In ~/.config/hypr/monitors.conf
   monitor = DP-1, 2560x1440@144, 0x0, 1
   ```

3. **Disable hardware cursors**
   ```bash
   # Add to ~/.config/hypr/local/input.conf
   cursor {
       no_hardware_cursors = true
   }
   ```

### Keybinds Not Working

1. **Check if mod key is correct**
   ```bash
   # Test with wev
   wev
   # Press your Super key and check the output
   ```

2. **Reload config**
   ```bash
   hyprctl reload
   ```

3. **Check keybind conflicts**
   ```bash
   hyprctl binds | grep "your_key"
   ```

4. **Verify program exists**
   ```bash
   which wofi  # Should return path
   ```

## Waybar Issues

### Waybar Not Showing

1. **Check if running**
   ```bash
   pgrep waybar
   ```

2. **Start manually with debug**
   ```bash
   waybar -l debug 2>&1 | tee /tmp/waybar-debug.log
   ```

3. **Validate JSON config**
   ```bash
   jq . ~/.config/waybar/config
   ```

4. **Check CSS for errors**
   ```bash
   # Waybar will log CSS errors to stderr
   waybar 2>&1 | grep -i error
   ```

### Waybar Modules Missing

1. **Check module dependencies**
   ```bash
   # For pulseaudio module
   pacman -Q pulseaudio pavucontrol
   
   # For network module
   pacman -Q networkmanager
   ```

2. **Restart related services**
   ```bash
   systemctl --user restart wireplumber pipewire
   ```

## Audio Issues

### No Sound

1. **Check PipeWire status**
   ```bash
   systemctl --user status pipewire pipewire-pulse wireplumber
   ```

2. **Restart audio stack**
   ```bash
   systemctl --user restart pipewire pipewire-pulse wireplumber
   ```

3. **Check output device**
   ```bash
   wpctl status
   wpctl set-default <sink_id>
   ```

4. **Check mute status**
   ```bash
   wpctl get-volume @DEFAULT_AUDIO_SINK@
   wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
   ```

### Microphone Not Working

1. **Check input devices**
   ```bash
   wpctl status | grep -A 5 "Audio/Source"
   ```

2. **Set default input**
   ```bash
   wpctl set-default <source_id>
   ```

3. **Check application permissions**
   ```bash
   # Some apps need explicit permission
   # Check with pavucontrol
   pavucontrol
   ```

## Update Issues

### Update Fails

**Error**: `Git update failed`

1. **Check for local changes**
   ```bash
   cd ~/.local/bin/dotfiles
   git status
   ```

2. **Stash local changes**
   ```bash
   git stash
   dotfiles-update
   git stash pop  # Restore changes after
   ```

3. **Force update (discards local changes)**
   ```bash
   dotfiles-update --force
   ```

4. **Manual reset**
   ```bash
   cd ~/.local/bin/dotfiles
   git fetch origin
   git reset --hard origin/main
   ```

### Migration Fails

**Error**: `Migration failed: 20250526_xxx.sh`

1. **Check migration log**
   ```bash
   cat ~/.local/state/dotfiles/migrations/
   ```

2. **Run migration manually**
   ```bash
   bash ~/.local/bin/dotfiles/migrations/20250526_xxx.sh
   ```

3. **Skip migration (mark as done)**
   ```bash
   date > ~/.local/state/dotfiles/migrations/20250526_xxx.sh
   ```

### Rollback Update

```bash
cd ~/.local/bin/dotfiles

# See recent commits
git reflog

# Reset to previous state
git reset --hard HEAD~1

# Or reset to specific commit
git reset --hard abc1234

# Re-apply configs
./scripts/install_dotfiles.sh
```

## Application Issues

### Wofi Not Launching

1. **Check if installed**
   ```bash
   which wofi
   ```

2. **Test manually**
   ```bash
   wofi --show drun
   ```

3. **Check config**
   ```bash
   cat ~/.config/wofi/config
   ```

### Screenshots Not Working

1. **Check dependencies**
   ```bash
   pacman -Q grim slurp wl-clipboard
   ```

2. **Test manually**
   ```bash
   grim -g "$(slurp)" - | wl-copy
   ```

3. **Check screenshot command**
   ```bash
   # The dotfiles provides a screenshot command
   which dotfiles-screenshot
   
   # Test it directly
   dotfiles-screenshot
   ```

### Notifications Not Appearing

1. **Check dunst status**
   ```bash
   pgrep dunst
   ```

2. **Restart dunst**
   ```bash
   killall dunst
   dunst &
   ```

3. **Test notification**
   ```bash
   notify-send "Test" "This is a test notification"
   ```

## State and Config Issues

### Reset Dotfiles State

```bash
# Remove all state (will treat next update as fresh install)
rm -rf ~/.local/state/dotfiles

# Reinitialize
dotfiles-update
```

### Reset Config to Defaults

```bash
# Backup current configs
cp -r ~/.config/hypr ~/.config/hypr.bak

# Remove local overrides
rm -rf ~/.config/hypr/local

# Refresh from repo
dotfiles-refresh-config --force
```

### Check What's Installed

```bash
dotfiles-version
```

Shows:
- Installed version
- Repository version  
- Installation date
- Last update date

## Getting Help

### Gather Debug Info

```bash
# Create debug report
{
    echo "=== Dotfiles Version ==="
    dotfiles-version
    
    echo -e "\n=== System Info ==="
    uname -a
    cat /etc/os-release
    
    echo -e "\n=== GPU Info ==="
    lspci | grep -i vga
    
    echo -e "\n=== Hyprland Version ==="
    hyprctl version
    
    echo -e "\n=== Recent Hyprland Logs ==="
    tail -50 ~/.local/share/hyprland/hyprland.log
    
    echo -e "\n=== Journal Errors ==="
    journalctl --user -p err --no-pager -n 20
} > ~/dotfiles-debug.txt

echo "Debug info saved to ~/dotfiles-debug.txt"
```

### Where to Ask

1. **Hyprland issues**: [Hyprland GitHub](https://github.com/hyprwm/Hyprland/issues)
2. **Arch packages**: [Arch Forums](https://bbs.archlinux.org/)
3. **Dotfiles issues**: Open an issue on the dotfiles repository

### Useful Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Arch Wiki - Hyprland](https://wiki.archlinux.org/title/Hyprland)
- [Arch Wiki - NVIDIA](https://wiki.archlinux.org/title/NVIDIA)
- [Arch Wiki - PipeWire](https://wiki.archlinux.org/title/PipeWire)
