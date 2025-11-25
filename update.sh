#!/bin/bash
# Legacy update script - redirects to new modular update system
# For direct usage, run: dotfiles-update

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if new update system is available
if [[ -x "$BASE_DIR/bin/dotfiles-update" ]]; then
    echo "[INFO] Using new modular update system..."
    echo "[INFO] You can also run 'dotfiles-update' directly"
    echo ""
    exec "$BASE_DIR/bin/dotfiles-update" "$@"
fi

# Fallback to legacy update if new system not available
SCRIPTS_DIR="$BASE_DIR/scripts"
PROTECTED_LIST="$SCRIPTS_DIR/protected_paths.txt"

# Source state library
source "$BASE_DIR/lib/state.sh"

# Source hooks library
source "$BASE_DIR/lib/hooks.sh"

LOG() { echo "[INFO] $*"; }
WARN() { echo "[WARN] $*"; }
ERR() { echo "[ERROR] $*" 1>&2; }

DRY_RUN=false
FORCE=false
BACKUP_CHANGED=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    --backup-changed) BACKUP_CHANGED=true; shift ;;
    *) WARN "Unknown flag $1"; shift ;;
  esac
done

update_repo() {
  LOG "Updating repository and submodules..."
  if $DRY_RUN; then return; fi
  git -C "$BASE_DIR" fetch --all --tags
  git -C "$BASE_DIR" pull --rebase --autostash || true
  git -C "$BASE_DIR" submodule update --init --recursive --remote
}

update_packages() {
  LOG "Synchronizing system packages (pacman)..."
  if $DRY_RUN; then return; fi
  sudo pacman -Syu --noconfirm || true
  if command -v yay >/dev/null 2>&1; then
    LOG "Synchronizing AUR packages (yay)..."
    yay -Syu --noconfirm || true
  else
    WARN "yay not found; skipping AUR sync"
  fi
}

sync_arch_list() {
  LOG "Installing missing Arch packages from list..."
  mapfile -t pkgs < <(grep -vE '^(#|\s*$)' "$SCRIPTS_DIR/arch_packages.txt")
  to_install=()
  for p in "${pkgs[@]}"; do
    pacman -Q "$p" &>/dev/null || to_install+=("$p")
  done
  if [[ ${#to_install[@]} -gt 0 ]]; then
    LOG "Installing: ${to_install[*]}"
    $DRY_RUN || sudo pacman -S --noconfirm --needed "${to_install[@]}" || true
  else
    LOG "All Arch packages already present"
  fi
}

update_aur_list() {
  if ! command -v yay >/dev/null 2>&1; then return; fi
  LOG "Installing missing AUR packages from list..."
  mapfile -t pkgs < <(grep -vE '^(#|\s*$)' "$SCRIPTS_DIR/yay_packages.txt")
  to_install=()
  for p in "${pkgs[@]}"; do
    yay -Q "$p" &>/dev/null || to_install+=("$p")
  done
  if [[ ${#to_install[@]} -gt 0 ]]; then
    LOG "Installing: ${to_install[*]}"
    $DRY_RUN || yay -S --noconfirm --needed "${to_install[@]}"
  else
    LOG "All AUR packages already present"
  fi
}

backup_path() {
  local target="$1"
  [[ -e "$target" ]] || return 0
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local backup="${target}.bak-${ts}"
  cp -a "$target" "$backup"
  LOG "Backed up $target -> $backup"
}

reapply_dotfiles() {
  LOG "Reapplying tracked dotfiles with protection..."
  local root="$BASE_DIR/.config"
  if [[ ! -d "$root" ]]; then LOG "No .config in repo; skipping"; return; fi

  local rsync_opts=(-a --checksum --ignore-existing)
  $DRY_RUN && rsync_opts+=(-n -v)

  local exclude_args=()
  if [[ -f "$PROTECTED_LIST" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      exclude_args+=(--exclude="$line")
    done < "$PROTECTED_LIST"
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  trap '[[ -n "${tmpdir:-}" ]] && rm -rf "$tmpdir"' EXIT
  git -C "$BASE_DIR" --work-tree="$tmpdir" checkout -f HEAD -- .config .tmux.conf .zshrc || true

  if ! $FORCE; then
    while IFS= read -r tracked; do
      [[ -z "$tracked" ]] && continue
      local src="$tmpdir/$tracked"
      local dst="$HOME/$tracked"
      if [[ -e "$dst" ]] && ! cmp -s "$src" "$dst" 2>/dev/null; then
        if $BACKUP_CHANGED && ! $DRY_RUN; then backup_path "$dst"; fi
        exclude_args+=(--exclude="$tracked")
        WARN "Local changes detected at ~/$tracked; skipping"
      fi
    done < <(cd "$tmpdir" && find .config -type f -printf '%P\n')
  fi

  rsync "${rsync_opts[@]}" "${exclude_args[@]}" "$tmpdir/.config/" "$HOME/.config/"
}

reapply_themes() {
  LOG "Reapplying themes..."
  $DRY_RUN || bash "$SCRIPTS_DIR/apply-theme.sh"
}

main() {
  LOG "Starting update"
  
  # Run pre-update hook (only if not dry run)
  if ! $DRY_RUN; then
    LOG "Running pre-update hooks..."
    hook_run pre-update || true
  fi
  
  update_repo
  
  # Run migrations after pulling new code but before applying dotfiles
  if ! $DRY_RUN; then
    LOG "Checking for pending migrations..."
    migrations_run_all || {
      ERR "Migration failed, aborting update"
      exit 1
    }
  fi
  
  update_packages
  sync_arch_list
  update_aur_list
  reapply_dotfiles
  $DRY_RUN || bash "$SCRIPTS_DIR/sync-wallpapers.sh"
  $DRY_RUN || bash "$SCRIPTS_DIR/set-wallpaper.sh"
  reapply_themes
  
  # Record update state (only if not dry run)
  if ! $DRY_RUN; then
    LOG "Recording update state..."
    state_record_update
    
    # Run post-update hook
    LOG "Running post-update hooks..."
    hook_run post-update || true
  fi
  
  LOG "Update complete"
}

main "$@"
