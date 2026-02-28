# zsh options
setopt AUTO_CD
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Vim bindings
bindkey -e

# Zsh Autocomplete Options
bindkey -M menuselect  '^[[D' .backward-char  '^[OD' .backward-char
bindkey -M menuselect  '^[[C'  .forward-char  '^[OC'  .forward-char
bindkey -a \
    "^P"    .up-history \
    "^N"    .down-history \
    "k"     .up-line-or-history \
    "^[OA"  .up-line-or-history \
    "^[[A"  .up-line-or-history \
    "j"     .down-line-or-history \
    "^[OB"  .down-line-or-history \
    "^[[B"  .down-line-or-history \
    "/"     .vi-history-search-backward \
    "?"     .vi-history-search-forward \

# aliases
alias vim="nvim"
alias l="ls -la"
alias gco="git checkout"
alias gst="git status"
alias code="cd $HOME/code"

# exports
export VISUAL="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/.local/bin:$PATH"
export PATH=$HOME/go/bin:$PATH
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
export VAULT_ADDR="https://vault.corp.hadrian-automation.com:8200"
export VAULT_TOKEN="vault login -method=oidc -token-only role=default"
export DOCKER_HOST="$(docker context inspect -f='{{.Endpoints.docker.Host}}')"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock

# Setup nvim
alias vim="nvim"
export EDITOR='nvim'
export GIT_EDITOR=nvim

# Setup fzf
eval "$(fzf --zsh)"

# Setup starship
eval "$(starship init zsh)"

# Setup direnv
eval "$(direnv hook zsh)"

# Setup fnm (node version manager)
eval "$(fnm env --use-on-cd)"

# pnpm
export PNPM_HOME="/Users/matt/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Libpq
 
# Load Scripts
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
