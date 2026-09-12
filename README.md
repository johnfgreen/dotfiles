# dotfiles — macOS development environment

Personal macOS dotfiles that bootstrap a complete development machine — from zero to productive in one sitting.

## What's inside

| Layer | Tool | Purpose |
|---|---|---|
| **Window manager** | [AeroSpace](https://github.com/nikitabobko/AeroSpace) | i3-like tiling window manager |
| **Terminal** | [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| **Multiplexer** | [tmux](https://github.com/tmux/tmux) | Terminal session management |
| **Editor** | [Neovim](https://neovim.io) | Modal text editor |
| **Shell** | Zsh | macOS default shell with custom `.zshrc` |
| **AI agent** | [OpenCode](https://opencode.ai) | AI coding agent for ongoing system management |
| **Keyboard** | [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Key remapping (fixes AeroSpace key bleed) |

All managed through a **multi-agent worktree system**: OpenCode delegates config changes to specialized sub-agents, each working in its own git worktree branch. Changes stay isolated until reviewed and merged.

---

## Quick start — set up a new Mac

### Prerequisites

#### 1. Xcode Command Line Tools

Provides `git`, compilers, and other macOS build tools.

```bash
xcode-select --install
```

If a dialog appears, click "Install" and wait for it to complete.

#### 2. Homebrew

Package manager for macOS — used to install everything else.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, follow any "Next steps" printed by the installer (usually adding Homebrew to your PATH).

Verify it works:

```bash
brew doctor
```

### Installation

#### 3. Clone this repo

```bash
mkdir -p ~/Projects
git clone https://github.com/johnfgreen/dotfiles.git ~/Projects/dotfiles
```

#### 4. Install packages and apps

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

#### 5. Install OpenCode (AI coding agent)

```bash
curl -fsSL https://opencode.ai/install | bash
```

The install script downloads the latest binary to `~/.opencode/bin/` and adds it to your PATH.

Verify the installation:

```bash
opencode --version
```

> **Note:** The OpenCode config (`~/.config/opencode/opencode.jsonc`) is managed by this dotfiles repo and will be symlinked in the next step.

#### 6. Symlink config files

```bash
~/Projects/dotfiles/install.sh
```

This creates symlinks for all config files under `~/Projects/dotfiles/` to their standard locations (e.g. `~/.zshrc`, `~/.config/ghostty/config.ghostty`, etc.). It also symlinks the OpenCode memory tools (`opencode-memory` and `todo-manager`) into `~/.config/opencode/bin/`. Existing files are backed up with a `.bak` suffix.

#### 7. Apply macOS system defaults

The `.macos` file is sourced automatically by `.zshrc` in new shells. To apply immediately:

```bash
source ~/.macos
```

This sets system preferences like window corner radius.

### Grant permissions

These are **required** for keyboard shortcuts, window management, and the AI coding agent to work.

#### OpenCode (AI coding agent)

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add your terminal emulator (e.g. `/Applications/Ghostty.app`)
3. Open **Input Monitoring** and add your terminal emulator (e.g. `/Applications/Ghostty.app`)
4. Restart your terminal

> OpenCode reads keystrokes and manages the terminal UI — these permissions let it capture keyboard input and control the system.

#### Karabiner-Elements (key bleed prevention)

1. Open **System Settings → Privacy & Security → Input Monitoring**
2. Click **+** and add:
   - `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server`
   - `/Applications/Karabiner-Elements.app`
3. Enable the toggle for both entries
4. Go to **Accessibility** and add:
   - `/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Core-Service.app`
5. Restart Karabiner-Elements (menu bar icon → Quit, then reopen from `/Applications`)

#### Aerospace (window manager)

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add `/Applications/AeroSpace.app`
3. Open **Input Monitoring** and add `/Applications/AeroSpace.app`
4. Restart Aerospace

### Verify everything works

| Check | How |
|---|---|
| **Workspace switching** | Press `Alt+2` — should switch to workspace 2 with no characters bleeding into apps |
| **Focus navigation** | Press `Alt+h/j/k/l` — should move focus between windows |
| **Terminal** | Open Ghostty — should show Catppuccin Mocha theme, JetBrains Mono font |
| **tmux** | Run `tmux` — status bar should show Catppuccin theme |
| **Karabiner** | Open Karabiner-Elements → Complex Modifications — should show both Aerospace rules as enabled |
| **OpenCode** | Run `opencode` — should start the TUI with the system agent loaded |

---

## Ongoing management with OpenCode

Once everything is installed, OpenCode can maintain your system going forward. Just start a session:

```bash
opencode
```

Or use one-shot commands for quick tasks:

```bash
# System maintenance
opencode run "Check for brew updates and upgrade everything"
opencode run "Find large files over 1GB and suggest cleanup"
opencode run "Check disk usage and show me what's taking space"

# Dotfile management
opencode run "Add lazygit to the Brewfile"
opencode run "Update the tmux status bar colors to match Catppuccin"

# Diagnostics
opencode run "Check system logs for errors in the last 24 hours"
opencode run "Show me running processes sorted by memory usage"
```

OpenCode uses a **persistent memory system** (`opencode-memory`) to track tasks and context across sessions. If you quit and relaunch OpenCode, the system agent remembers what it was working on. The memory state file lives at `~/.config/opencode/agents/system-memory.json` and is machine-local (not tracked in git — recreated fresh on each machine).

OpenCode also uses the **multi-agent worktree system** defined in this dotfiles repo. When you ask to modify config, it delegates to specialized sub-agents:

| Agent | Handles |
|---|---|
| `@agent-bootstrap` | `Brewfile`, `install.sh`, helper scripts |
| `@agent-desktop` | Aerospace, Neovim, Zsh, Git, tmux & Ghostty config |
| `@agent-opencode` | `opencode.jsonc`, agent prompts, permissions |

Each sub-agent works in its own git worktree branch, so changes are isolated and reviewed before merging.

---

## Architecture

### Keyboard event pipeline

AeroSpace's Alt-based shortcuts (workspace switching, focus, move) can leak keystrokes into apps when macOS Secure Input mode is active (common in Safari, terminals). The fix uses a multi-layered approach:

```
User presses Alt+key (any Aerospce shortcut)
    ↓
Karabiner-Elements (IOKit driver level)
    └─ consumes the event, runs `aerospace <command>` via shell
    └─ covers: digits (workspace), h/j/k/l (focus), shift+h/j/k/l (move)
    └─ event never reaches macOS event queue → no key bleed
    ↓
Ghostty (if event leaks past Karabiner)
    └─ macos-option-as-alt = true  → harmless escape sequence
    └─ macos-auto-secure-input = false
    └─ keybind = alt+...=ignore    → safety net
    ↓
Aerospace (fallback — Karabiner absent)
    └─ workspace/focus/move bindings removed from aerospce config
    └─ only resize (alt+minus/equal) and layout (alt+slash/comma) remain
```

### Agent worktree system

Each sub-agent operates in its own parallel git worktree, allowing multiple agents to make changes simultaneously without conflicts:

```bash
~/Projects/
  dotfiles/                          # main branch — source of truth
  dotfiles-agent-bootstrap/          # agent/bootstrap worktree
  dotfiles-agent-desktop/            # agent/desktop worktree
  dotfiles-agent-opencode/           # agent/opencode worktree
```

---

## File index

| Repo path | Installed to | Purpose |
|---|---|---|
| `config/aerospace/aerospace.toml` | `~/.config/aerospace/aerospace.toml` | Window manager keybindings, layout |
| `config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` | Terminal theme, fonts, key handling |
| `config/karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` | Keyboard remapping (prevents AeroSpace key bleed into apps) |
| `config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | tmux theme, keybindings |
| `config/nvim/` | `~/.config/nvim/` | Neovim configuration |
| `~/.opencode/bin/opencode` | — | OpenCode binary (installed via install script) |
| `config/opencode/` | `~/.config/opencode/` | OpenCode agent configs, permissions |
| `config/launchd/com.tmux.server.plist` | `~/Library/LaunchAgents/` | tmux server launch agent |
| `home/.zshrc` | `~/.zshrc` | Shell aliases, PATH, key bindings |
| `home/.zprofile` | `~/.zprofile` | Shell environment setup (Homebrew) |
| `home/.gitconfig` | `~/.gitconfig` | Git identity, pull strategy |
| `home/.macos` | `~/.macos` | macOS system defaults |
| `Brewfile` | — | Homebrew package manifest |
| `bin/opencode-memory` | `~/.config/opencode/bin/opencode-memory` | Cross-session memory tool for OpenCode |
| `bin/todo-manager` | `~/.config/opencode/bin/todo-manager` | Task sync helper wrapping opencode-memory |
| `install.sh` | — | Symlink creator |
