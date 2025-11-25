# Dotfiles zshrc - thin wrapper that sources modular configs
# See default/zsh/ for the actual configuration

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Dotfiles path - determines where to source configs from
DOTFILES_PATH="$HOME/.local/bin/dotfiles"

# Source modular configurations
[[ -f "$DOTFILES_PATH/default/zsh/shell" ]] && source "$DOTFILES_PATH/default/zsh/shell"
[[ -f "$DOTFILES_PATH/default/zsh/aliases" ]] && source "$DOTFILES_PATH/default/zsh/aliases"
[[ -f "$DOTFILES_PATH/default/zsh/functions" ]] && source "$DOTFILES_PATH/default/zsh/functions"

# Auto-start tmux (call function from functions file)
start_tmux
