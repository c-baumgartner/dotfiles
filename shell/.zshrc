# .zshrc - Interactive shell configuration

# Exit if not running interactively
[[ $- != *i* ]] && return

###############################################################################
# Dotfiles dir
###############################################################################

# Resolve DOTFILES_DIR (works whether symlinked or not)
DOTFILES_DIR="${DOTFILES_DIR:-}"
if [[ -z "$DOTFILES_DIR" ]]; then
  if [[ -d "$HOME/.dotfiles" ]]; then
    DOTFILES_DIR="$HOME/.dotfiles"
  elif [[ -d "$HOME/Repos/dotfiles" ]]; then
    DOTFILES_DIR="$HOME/Repos/dotfiles"
  elif [[ -d "$HOME/dotfiles" ]]; then
    DOTFILES_DIR="$HOME/dotfiles"
  else
    echo "Warning: dotfiles directory not found"
  fi
fi
export DOTFILES_DIR

###############################################################################
# Source shell modules (order matters)
###############################################################################

_source() { [[ -f "$1" ]] && source "$1"; }

_source "$DOTFILES_DIR/shell/.exports"
_source "$DOTFILES_DIR/shell/.path"
_source "$DOTFILES_DIR/shell/.functions"
_source "$DOTFILES_DIR/shell/.aliases"

###############################################################################
# Completion
###############################################################################

autoload -Uz compinit

# Regenerate completions cache only once a day
if [[ -n "$ZSH_COMPDUMP" ]] && [[ $(find "$ZSH_COMPDUMP" -mtime +1 2>/dev/null) ]]; then
  compinit -d "$ZSH_COMPDUMP"
else
  ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
  mkdir -p "$(dirname "$ZSH_COMPDUMP")"
  compinit -d "$ZSH_COMPDUMP"
fi

# Local overrides (machine-specific, not in git) — sourced after compinit so
# that compdef is available for tools like az that call it during setup
_source "$HOME/.zshrc.local"

unset -f _source

###############################################################################
# History
###############################################################################

setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicate entries first when trimming
setopt HIST_IGNORE_DUPS         # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is duplicate
setopt HIST_IGNORE_SPACE        # Don't record entries starting with a space
setopt HIST_SAVE_NO_DUPS        # Don't write duplicate entries to history file
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks before recording
setopt SHARE_HISTORY            # Share history between all sessions
setopt APPEND_HISTORY           # Append to history file, don't overwrite
setopt INC_APPEND_HISTORY       # Write to history file immediately, not on exit

# Completion options
setopt ALWAYS_TO_END        # Move cursor to end of word after completing
setopt AUTO_MENU            # Show completion menu on second tab
setopt COMPLETE_IN_WORD     # Complete from cursor, not just end of word
setopt NO_FLOW_CONTROL      # Disable ctrl-s / ctrl-q flow control

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''

# Include hidden files in completions
_comp_options+=(globdots)

###############################################################################
# Key bindings
###############################################################################

# Use emacs-style keybindings (default, works well in most terminals)
bindkey -e

# Navigation
bindkey '^[[H'    beginning-of-line   # Home
bindkey '^[[F'    end-of-line         # End
bindkey '^[[1;5C' forward-word        # Ctrl+Right
bindkey '^[[1;5D' backward-word       # Ctrl+Left
bindkey '^[[3~'   delete-char         # Delete

# ghq repo picker (defined in .functions, registered there via zle -N)
bindkey '^G' _ghq_fzf

# History search with up/down arrows (matches current input prefix)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

###############################################################################
# Miscellaneous zsh options
###############################################################################

setopt AUTO_CD              # Type a directory name to cd into it
setopt CDABLE_VARS          # cd into a variable that holds a path
setopt CORRECT              # Suggest corrections for typos
setopt EXTENDED_GLOB        # Use extended globbing syntax
setopt GLOB_DOTS            # Include dotfiles in globs
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
setopt NO_BEEP              # No beeping

###############################################################################
# Plugins (installed via Homebrew)
###############################################################################

BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# zsh-autosuggestions — fish-like suggestions
if [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
fi

# zsh-syntax-highlighting — must be sourced last among plugins
if [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

###############################################################################
# Tools
###############################################################################

# fzf — fuzzy finder key bindings and completions
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# zoxide — smarter cd (replaces z/autojump)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# starship — cross-shell prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# GitHub CLI completions
if command -v gh &>/dev/null; then
  eval "$(gh completion -s zsh)"
fi

# bun completions
[ -s "/Users/christian.baumgartner/.bun/_bun" ] && source "/Users/christian.baumgartner/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/share/../bin/env"
