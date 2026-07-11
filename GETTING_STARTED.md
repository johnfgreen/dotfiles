# Getting Started — dotfiles

Set up a new Mac from scratch using this dotfiles repo.

## Prerequisites

These are required before anything else runs.

### 1. Xcode Command Line Tools

Provides `git`, compilers, and other macOS build tools.

```bash
xcode-select --install
```

If a dialog appears, click "Install" and wait for it to complete.

### 2. Homebrew

Package manager for macOS — used to install everything else.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, follow any "Next steps" printed by the installer (usually adding Homebrew to your PATH).

Verify it works:

```bash
brew doctor
```

## Installation

### 3. Clone this repo

```bash
mkdir -p ~/Projects
git clone https://github.com/johnfgreen/dotfiles.git ~/Projects/dotfiles
```

### 4. Install packages and apps

```bash
brew bundle --file=~/Projects/dotfiles/Brewfile
```

This installs everything listed in `Brewfile`:

| Package | Type | Purpose |
|---|---|---|
| `coreutils` | brew | GNU core utilities |
| `fd` | brew | Fast file search |
| `gh` | brew | GitHub CLI |
| `git` | brew | Version control |
| `lazydocker` | brew | Docker TUI |
| `lazygit` | brew | Git TUI |
| `neovim` | brew | Editor |
| `ripgrep` | brew | Fast text search |
| `tmux` | brew | Terminal multiplexer |
| `aerospace` | cask | Tiling window manager |
| `ghostty` | cask | Terminal emulator |
| `karabiner-elements` | cask | Keyboard remapping (fixes key bleed) |
| `font-jetbrains-mono-nerd-font` | cask | Terminal font |

### 5. Symlink config files

```bash
~/Projects/dotfiles/install.sh
```

This creates symlinks for all config files under `~/Projects/dotfiles/` to their standard locations (e.g. `~/.zshrc`, `~/.config/ghostty/config.ghostty`, etc.). Existing files are backed up with a `.bak` suffix.

### 6. Apply macOS system defaults

The `.macos` file is sourced automatically by `.zshrc` in new shells. To apply immediately:

```bash
source ~/.macos
```

This sets system preferences like window corner radius.

## Grant permissions

These are **required** for keyboard shortcuts and window management to work.

### Karabiner-Elements (key bleed prevention)

1. Open **System Settings → Privacy & Security → Input Monitoring**
2. Click **+** and add:
   - `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server`
   - `/Applications/Karabiner-Elements.app`
3. Enable the toggle for both entries
4. Go to **Accessibility** and add:
   - `/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Core-Service.app`
5. Restart Karabiner-Elements (menu bar icon → Quit, then reopen from `/Applications`)

### Aerospace (window manager)

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add `/Applications/AeroSpace.app`
3. Open **Input Monitoring** and add `/Applications/AeroSpace.app`
4. Restart Aerospace

## Verify everything works

| Check | How |
|---|---|
| **Workspace switching** | Press `Alt+2` — should switch to workspace 2 with no characters bleeding into apps |
| **Focus navigation** | Press `Alt+h/j/k/l` — should move focus between windows |
| **Terminal** | Open Ghostty — should show Catppuccin Mocha theme, JetBrains Mono font |
| **tmux** | Run `tmux` — status bar should show Catppuccin theme |
| **Karabiner** | Open Karabiner-Elements → Complex Modifications — should show both Aerospace rules as enabled |

## Architecture

The keyboard event pipeline, top to bottom:

```
User presses Alt+2
    ↓
Karabiner-Elements (IOKit driver level)
    └─ consumes the event, runs `aerospace workspace 2` via shell
    └─ event never reaches macOS event queue → no key bleed
    ↓
Ghostty (if event leaks past Karabiner)
    └─ macos-option-as-alt = true  → harmless escape sequence
    └─ macos-auto-secure-input = false
    └─ keybind = alt+2=ignore      → safety net
    ↓
Aerospace (if Karabiner is absent)
    └─ alt-2 binding removed from aerospce config
    └─ focus/move/resize bindings still handled natively
```

## File index

| Repo path | Installed to | Purpose |
|---|---|---|
| `config/aerospace/aerospace.toml` | `~/.config/aerospace/aerospace.toml` | Window manager keybindings, layout |
| `config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` | Terminal theme, fonts, key handling |
| `config/karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` | Keyboard remapping (workspace keys) |
| `config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | tmux theme, keybindings |
| `config/nvim/` | `~/.config/nvim/` | Neovim configuration |
| `config/opencode/` | `~/.config/opencode/` | OpenCode agent configs |
| `config/launchd/com.tmux.server.plist` | `~/Library/LaunchAgents/` | tmux server launch agent |
| `home/.zshrc` | `~/.zshrc` | Shell aliases, PATH, key bindings |
| `home/.zprofile` | `~/.zprofile` | Shell environment setup (Homebrew) |
| `home/.gitconfig` | `~/.gitconfig` | Git identity, pull strategy |
| `home/.macos` | `~/.macos` | macOS system defaults |
| `Brewfile` | — | Homebrew package manifest |
| `install.sh` | — | Symlink creator |
