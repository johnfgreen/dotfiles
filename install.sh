#!/usr/bin/env bash
#
# dotfiles — bootstrap installer
# Creates symlinks from $HOME to the files in this repo.
#
# Usage: ./install.sh [--dry-run]
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN="${1:-}"

# Pairs of: repo_path -> target_path
# Config files
LINKS=(
  "config/aerospace/aerospace.toml:.config/aerospace/aerospace.toml"
  "config/ghostty/config:.config/ghostty/config"
  "config/ghostty/config.ghostty:.config/ghostty/config.ghostty"
  "config/tmux/tmux.conf:.config/tmux/tmux.conf"
  "config/opencode/opencode.jsonc:.config/opencode/opencode.jsonc"
  "config/opencode/agents/system.md:.config/opencode/agents/system.md"
  "home/.zshrc:.zshrc"
  "home/.zprofile:.zprofile"
)

echo "==> Installing dotfiles from $DOTFILES_DIR"

for entry in "${LINKS[@]}"; do
  repo_rel="${entry%%:*}"
  target_rel="${entry##*:}"

  source="$DOTFILES_DIR/$repo_rel"
  target="$HOME/$target_rel"

  # Ensure parent directory exists
  target_dir="$(dirname "$target")"
  if [ ! -d "$target_dir" ]; then
    if [ -n "$DRY_RUN" ]; then
      echo "  [dry-run] mkdir -p $target_dir"
    else
      mkdir -p "$target_dir"
      echo "  created $target_dir"
    fi
  fi

  # Create symlink
  if [ -f "$target" ] || [ -L "$target" ]; then
    if [ -n "$DRY_RUN" ]; then
      echo "  [dry-run] backup $target -> ${target}.bak"
      echo "  [dry-run] ln -sf $source $target"
    else
      mv "$target" "${target}.bak"
      echo "  backed up $target -> ${target}.bak"
      ln -sf "$source" "$target"
      echo "  linked $target -> $source"
    fi
  else
    if [ -n "$DRY_RUN" ]; then
      echo "  [dry-run] ln -s $source $target"
    else
      ln -s "$source" "$target"
      echo "  linked $target -> $source"
    fi
  fi
done

# Handle neovim config directory (symlink the whole dir)
NVIM_SOURCE="$DOTFILES_DIR/config/nvim"
NVIM_TARGET="$HOME/.config/nvim"
if [ -d "$NVIM_TARGET" ] && [ ! -L "$NVIM_TARGET" ]; then
  if [ -n "$DRY_RUN" ]; then
    echo "  [dry-run] mv $NVIM_TARGET ${NVIM_TARGET}.bak"
    echo "  [dry-run] ln -s $NVIM_SOURCE $NVIM_TARGET"
  else
    mv "$NVIM_TARGET" "${NVIM_TARGET}.bak"
    echo "  backed up $NVIM_TARGET -> ${NVIM_TARGET}.bak"
    ln -s "$NVIM_SOURCE" "$NVIM_TARGET"
    echo "  linked $NVIM_TARGET -> $NVIM_SOURCE"
  fi
elif [ ! -e "$NVIM_TARGET" ]; then
  if [ -n "$DRY_RUN" ]; then
    echo "  [dry-run] ln -s $NVIM_SOURCE $NVIM_TARGET"
  else
    ln -s "$NVIM_SOURCE" "$NVIM_TARGET"
    echo "  linked $NVIM_TARGET -> $NVIM_SOURCE"
  fi
else
  echo "  $NVIM_TARGET is already a symlink — skipping"
fi

echo "==> Done! Reload your shell or run: source ~/.zshrc"
