# Architecture Guide

Technical overview of how the dotfiles system works.

## Directory Structure

```
~/.local/bin/dotfiles/           # Repository root
├── bin/                         # Executable commands (added to PATH)
│   ├── dotfiles-update          # Main update orchestrator
│   ├── dotfiles-update-confirm  # Check for updates, show changelog
│   ├── dotfiles-update-git      # Git operations with stash/backup
│   ├── dotfiles-update-packages # Package sync
│   ├── dotfiles-refresh-config  # Config file management
│   ├── dotfiles-version         # Show version info
│   ├── dotfiles-hook            # Run hooks manually
│   ├── dotfiles-screenshot      # Screenshot utility
│   ├── dotfiles-mic-toggle      # Microphone toggle
│   ├── dotfiles-waybar-toggle   # Waybar visibility toggle
│   └── dotfiles-set-permissions # Fix file permissions
│
├── lib/                         # Shared libraries (sourced by scripts)
│   ├── state.sh                 # State management functions
│   └── hooks.sh                 # Hook system functions
│
├── scripts/                     # Installation and setup scripts
│   ├── helpers/                 # Shared helper functions
│   │   ├── logging.sh           # log_info, log_error, etc.
│   │   ├── errors.sh            # Error handling, cleanup
│   │   └── presentation.sh      # Progress bars, banners
│   ├── install/                 # Modular installation
│   │   ├── preflight.sh         # System checks
│   │   ├── packages.sh          # Package installation
│   │   └── hardware.sh          # NVIDIA/ASUS detection
│   ├── arch_packages.txt        # Pacman packages
│   ├── yay_packages.txt         # AUR packages
│   └── *.sh                     # Individual installers
│
├── migrations/                  # Database-style migrations
│   └── YYYYMMDD_description.sh  # Dated migration scripts
│
├── .config/                     # Config files (symlinked to ~/.config/)
│   ├── hypr/                    # Hyprland configs
│   │   ├── core/                # Upstream-managed (updates replace)
│   │   └── local/               # User overrides (never touched)
│   ├── waybar/                  # Waybar config
│   ├── wofi/                    # Wofi launcher
│   ├── dunst/                   # Notifications
│   └── ...
│
├── default/                     # Default shell configs
│   └── zsh/                     # Zsh modules
│       ├── aliases              # Default aliases
│       ├── functions            # Default functions
│       └── shell                # Shell environment
│
├── docs/                        # Documentation
├── boot.sh                      # One-liner web installer
├── install.sh                   # Main installer
├── update.sh                    # Update entry point
└── version                      # Current version number
```

## State Management

State is stored in `~/.local/state/dotfiles/`:

```
~/.local/state/dotfiles/
├── version              # Currently installed version
├── installed_at         # First installation timestamp
├── updated_at           # Last update timestamp
├── migrations/          # Completed migration markers
│   ├── 20250125_migrate_to_new_structure.sh
│   └── 20250526_hyprland_config_layering.sh
└── backups/             # Config backups before updates
```

### State Functions (lib/state.sh)

```bash
# Check if installed
state_is_installed        # Returns true if dotfiles installed

# Version management
state_get_version         # Get installed version
state_get_repo_version    # Get version from repo
state_set_version         # Set installed version
state_update_available    # Check if update available

# Timestamps
state_get_installed_at    # First install date
state_get_updated_at      # Last update date

# Migration tracking
state_migration_done      # Check if migration ran
state_migration_mark      # Mark migration complete

# Combined operations
state_record_install      # Record full install state
state_record_update       # Record update state
```

## Migration System

Migrations handle breaking changes between versions. They run automatically during updates.

### Migration Naming

```
YYYYMMDD_description.sh
```

Example: `20250526_hyprland_config_layering.sh`

### Migration Structure

```bash
#!/bin/bash
# Description: What this migration does
# From version: X.X.X
# To version: Y.Y.Y

set -euo pipefail

# Migration logic here
# - Move files
# - Update configs
# - Transform data

echo "Migration complete"
```

### Migration Execution

1. `migrations_get_pending` finds unrun migrations
2. Scripts run in date order (oldest first)
3. Each successful migration is marked in state
4. Failed migrations stop the update

## Hook System

Hooks let users run custom scripts at defined points.

### Hook Locations

```
~/.config/dotfiles/hooks/
├── post-install         # Single script
├── pre-update           # Single script
├── post-update          # Single script
└── post-update.d/       # Directory of scripts
    ├── 01-notify.sh
    └── 02-restart-services.sh
```

### Available Hooks

| Hook | When | Use Case |
|------|------|----------|
| `post-install` | After fresh install | Set up personal tools |
| `pre-update` | Before pulling updates | Backup custom files |
| `post-update` | After update completes | Reload services |

### Hook Functions (lib/hooks.sh)

```bash
hook_run "post-update"      # Run single hook
hook_run_dir "post-update.d"  # Run all scripts in dir
hook_exists "post-install"  # Check if hook exists
hooks_list                  # List all hooks
```

## Config Layering (Hyprland)

The Hyprland config uses a layering system:

```
~/.config/hypr/
├── hyprland.conf          # Main entry point
├── monitors.conf          # Monitor setup
├── nvidia.conf            # NVIDIA-specific
├── core/                  # MANAGED BY DOTFILES
│   ├── appearance.conf
│   ├── autostart.conf
│   ├── environment.conf
│   ├── input.conf
│   ├── keybinds.conf
│   ├── layout.conf
│   ├── programs.conf
│   └── windowrules.conf
└── local/                 # USER OVERRIDES (never touched)
    ├── appearance.conf    # Your appearance tweaks
    ├── keybinds.conf      # Your custom keybinds
    └── ...
```

### How Layering Works

In `hyprland.conf`:

```bash
# Source core configs (managed by dotfiles)
source = ~/.config/hypr/core/appearance.conf
source = ~/.config/hypr/core/keybinds.conf
# ... etc

# Source local overrides (your customizations)
source = ~/.config/hypr/local/appearance.conf
source = ~/.config/hypr/local/keybinds.conf
# ... etc
```

Later sources override earlier ones. Your `local/` files always win.

## Update Flow

```
dotfiles-update
    │
    ├─▶ dotfiles-update-confirm
    │      ├── git fetch
    │      ├── Compare versions
    │      ├── Show changelog
    │      └── Prompt for confirmation
    │
    ├─▶ hook_run "pre-update"
    │
    ├─▶ dotfiles-update-git
    │      ├── Stash local changes
    │      ├── git pull --rebase
    │      └── Pop stash
    │
    ├─▶ migrations_run_all
    │      └── Run each pending migration
    │
    ├─▶ dotfiles-update-packages
    │      ├── Install new packages
    │      └── Update existing
    │
    ├─▶ dotfiles-refresh-config
    │      └── Re-symlink configs
    │
    ├─▶ state_record_update
    │
    └─▶ hook_run "post-update"
```

## Installation Flow

```
install.sh
    │
    ├─▶ Parse arguments
    │
    ├─▶ scripts/install/preflight.sh
    │      ├── Check Arch Linux
    │      ├── Check Bash version
    │      ├── Check required commands
    │      ├── Check internet
    │      ├── Check disk space
    │      └── Check sudo access
    │
    ├─▶ scripts/install/hardware.sh
    │      ├── Detect NVIDIA GPU
    │      └── Detect ASUS hardware
    │
    ├─▶ scripts/install/packages.sh
    │      ├── Install yay (if needed)
    │      ├── Install arch_packages.txt
    │      └── Install yay_packages.txt
    │
    ├─▶ scripts/install_dotfiles.sh
    │      ├── Backup existing configs
    │      ├── Symlink new configs
    │      └── Set permissions
    │
    ├─▶ Optional installers
    │      ├── install_go_rust.sh
    │      ├── install_node.sh
    │      ├── install_bun.sh
    │      └── install_*_theme.sh
    │
    ├─▶ state_record_install
    │
    └─▶ hook_run "post-install"
```

## Shell Integration

The `.zshrc` sources modular configs:

```bash
# ~/.zshrc structure
source ~/.local/bin/dotfiles/default/zsh/shell      # Path, env
source ~/.local/bin/dotfiles/default/zsh/aliases    # Default aliases
source ~/.local/bin/dotfiles/default/zsh/functions  # Helper functions
```

Each default file automatically sources its corresponding user override at the end:

```bash
# In default/zsh/aliases (line 54):
[[ -f "$DOTFILES_USER_CONFIG/zsh/aliases.local" ]] && source ...

# In default/zsh/functions (line 40):
[[ -f "$DOTFILES_USER_CONFIG/zsh/functions.local" ]] && source ...

# In default/zsh/shell (line 52):
[[ -f "$DOTFILES_USER_CONFIG/zsh/shell.local" ]] && source ...
```

User override files location: `~/.config/dotfiles/zsh/*.local`

## Package Lists

### Format

```txt
# Comment line
package-name
another-package
# Disabled package
```

### Files

- `scripts/arch_packages.txt` - Official Arch repos (pacman)
- `scripts/yay_packages.txt` - AUR packages (yay)
- `scripts/protected_paths.txt` - Paths never overwritten

## Commands Reference

| Command | Purpose |
|---------|---------|
| `dotfiles-update` | Full update with all steps |
| `dotfiles-update --check` | Check for updates only |
| `dotfiles-update --dry-run` | Preview without changes |
| `dotfiles-version` | Show version and status |
| `dotfiles-refresh-config` | Re-apply config files |
| `dotfiles-hook <name>` | Run a hook manually |

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `REPO_ROOT` | `~/.local/bin/dotfiles` | Repository location |
| `STATE_DIR` | `~/.local/state/dotfiles` | State storage |
| `HOOKS_DIR` | `~/.config/dotfiles/hooks` | User hooks |
| `USER_CONFIG_DIR` | `~/.config/dotfiles` | User config overrides |

## Design Principles

1. **Non-destructive updates**: User customizations (`local/`) are never touched
2. **Atomic migrations**: Each migration is tracked, failures stop the process
3. **Graceful degradation**: Missing optional components don't break the system
4. **Transparency**: Dry-run modes show exactly what will happen
5. **Rollback support**: Git history + backups enable recovery
