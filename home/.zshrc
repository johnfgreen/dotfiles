export PATH=/Users/john/.opencode/bin:$PATH

# Dotfiles & worktree management
export PATH="$HOME/Projects/dotfiles/bin:$PATH"
alias wts='worktree-session'
alias wtsl='worktree-session list'
alias wtso='worktree-session open'
alias wtsk='worktree-session kill'
alias wtm='worktree-manager'

# VNC — Mac mini via Tailscale (Screen Sharing.app)
alias vnc-mini='open vnc://100.125.111.112'
alias vnc-mini-magic='open vnc://johns-mac-mini.tail236725.ts.net'
alias vnc-mini-short='open vnc://johns-mac-mini'

# opencode memory auto-routing
# Sets OPCODE_AGENT based on --agent flag and current directory

# Wrap opencode binary to capture --agent
opencode() {
  local agent=""
  local next_is_agent=0
  for arg in "$@"; do
    if [[ $next_is_agent -eq 1 ]]; then
      agent="$arg"
      break
    fi
    case "$arg" in
      --agent) next_is_agent=1 ;;
      --agent=*) agent="${arg#--agent=}" ; break ;;
    esac
  done
  if [[ -n "$agent" ]]; then
    export OPCODE_AGENT="$agent"
  fi
  command opencode "$@"
}

# Auto-set OPCODE_AGENT when entering inclusion-specialist project
_opencode_auto_agent() {
  if [[ "$PWD" == "$HOME/Projects/inclusion-specialist"* ]]; then
    export OPCODE_AGENT="inclusion-specialist"
  else
    # Only clear if it was auto-set to inclusion-specialist (preserve manual values like 'system')
    if [[ "$OPCODE_AGENT" == "inclusion-specialist" ]]; then
      unset OPCODE_AGENT
    fi
  fi
}
autoload -U add-zsh-hook 2>/dev/null && {
  add-zsh-hook chpwd _opencode_auto_agent
  add-zsh-hook precmd _opencode_auto_agent
}
_opencode_auto_agent

# Apply macOS system defaults (idempotent)
[ -f "$HOME/.macos" ] && source "$HOME/.macos"
