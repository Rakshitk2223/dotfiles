# Agents Guide

## Project Overview
Arch Linux + Hyprland dotfiles repository. Bash scripts for installation, updates, and utilities.

## Critical Rules
- **DO NOT** execute any scripts that modify the system (no running install.sh, update.sh, etc.)
- **DO NOT** make changes outside this repository path - never touch `~/.config/`, `~/.local/`, or any system files
- **DO NOT** create markdown files or documentation unless explicitly requested and approved
- **ALWAYS** review changes with the user and ask questions if requirements are unclear
- **ONLY** syntax-check scripts (`bash -n`), never execute them with actual system effects

## Commands
- **Lint scripts:** `shellcheck scripts/*.sh .local/bin/scripts/*.sh`
- **Test install (dry-run):** `bash -n install.sh && bash -n update.sh`
- **Validate Hyprland config:** `hyprctl reload` (requires running Hyprland)
- **Validate Waybar JSON:** `jq . .config/waybar/config`

## Code Style
- **Shebang:** Always `#!/bin/bash` for scripts
- **Strict mode:** Use `set -euo pipefail` at script start
- **Logging:** Use `log_info()`, `log_warn()`, `log_error()` helper functions
- **Naming:** Scripts use `snake_case.sh`, functions use `snake_case()`
- **Variables:** UPPER_CASE for exports/constants, lower_case for locals
- **Quoting:** Always quote variables `"$var"`, especially paths with spaces
- **Error handling:** Check command existence with `command -v`, use `|| true` for optional failures
- **Comments:** Add usage comment at top of utility scripts, inline comments for complex logic
- **Package lists:** One package per line in `.txt` files, comments start with `#`
- **Config files:** Follow upstream format (Hyprland uses `key = value`, Waybar uses JSON)
