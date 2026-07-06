# Multi-Agent Workflow

This document explains the three tools that power the opencode multi-agent workflow with git worktrees and tmux persistence.

---

## 1. `opencode-memory` — Cross-Session Agent Memory

**Location:** `~/Projects/dotfiles/bin/opencode-memory`  
**Manages:** `~/.config/opencode/agents/system-memory.json`

OpenCode agents use `opencode-memory` to persist tasks and context across sessions. If you quit opencode and relaunch, the agent remembers where it left off.

### Commands

```bash
# Session lifecycle
opencode-memory init                # Create a fresh memory file
opencode-memory heartbeat           # Save a checkpoint (run after milestones)
opencode-memory close               # End session and prune old tasks

# Tasks
opencode-memory add-task "description" [--priority high|medium|low]
opencode-memory update-task <id> --status pending|in_progress|completed [--notes "..."]
opencode-memory complete-task <id> --result "summary"
opencode-memory status              # List current tasks

# Notes & context
opencode-memory add-note "observation"
opencode-memory get-context         # Restore context on session start

# Housekeeping
opencode-memory archive             # Move active tasks to history (safe)
opencode-memory forget              # Discard all tasks (irreversible)
opencode-memory prune               # Manually trim old completed tasks
```

### Auto-pruning

- Completed tasks: keeps last 100 (oldest pruned on `close`/`heartbeat`)
- Context notes: keeps last 20 (oldest pruned on `close`/`heartbeat`)
- Configure via `OPCODE_MEMORY_MAX_COMPLETED` and `OPCODE_MEMORY_MAX_NOTES` env vars

### Dual-Management Protocol

The `system` agent follows a strict dual-management protocol: every `todowrite` call (in-session task list) is immediately paired with an `opencode-memory` call (persistent storage). A helper script `todo-manager` wraps `opencode-memory` for shorter commands:

```bash
todo-manager add "description" --priority high
todo-manager complete <id> --result "summary"
todo-manager status
todo-manager heartbeat
```

---

## 2. `worktree-session` — Tmux Sessions for Worktrees

**Location:** `~/Projects/dotfiles/bin/worktree-session`  
**Aliases:** `wts`, `wtsl`, `wtso`, `wtsk`

Bridges git worktrees and tmux. Each worktree gets its own persistent tmux session named after the directory.

### Commands

```bash
# List all worktrees and their tmux session status
wtsl
# or
worktree-session list

# Open a worktree in a tmux session (creates if doesn't exist)
wtso dotfiles-agent-terminal
# or
worktree-session open dotfiles-agent-terminal

# Kill a worktree's tmux session
wtsk dotfiles-agent-tmux
# or
worktree-session kill dotfiles-agent-tmux
```

### Tmux session layout

When you run `wtso dotfiles-agent-<name>`, it creates:

```
tmux session: dotfiles-agent-<name>
├── window 1: main    (work directory, shows branch banner)
└── window 2: git     (shows git status)
```

The session persists even if you close your terminal — reattach later with the same command.

### Key tmux bindings (from `~/.config/tmux/tmux.conf`)

| Action | Key |
|---|---|
| Prefix | `Ctrl+B` |
| Vertical split | `prefix` + `\|` |
| Horizontal split | `prefix` + `-` |
| Navigate panes | `prefix` + `h`/`j`/`k`/`l` |
| Resize panes | `prefix` + `H`/`J`/`K`/`L` |
| Zoom pane | `prefix` + `z` |
| Session picker | `prefix` + `s` |
| Last session | `prefix` + `=` |
| Detach | `prefix` + `d` |

---

## 3. `worktree-manager` — Worktree Lifecycle

**Location:** `~/Projects/dotfiles/bin/worktree-manager`  
**Alias:** `wtm`

Creates and removes git worktrees with a single command. Handles branch creation, remote pushing, tracking setup, tmux cleanup, and remote branch deletion.

### Commands

```bash
# Create a new worktree
wtm add <name> [branch]

# Examples:
wtm add terminal              # creates branch "agent/terminal" from main
wtm add bootstrap agent/setup # creates branch "agent/setup" from main
```

This does everything at once:
1. Creates branch `agent/<name>` from `main` (if it doesn't exist)
2. Creates worktree at `~/Projects/dotfiles-<name>`
3. Pushes branch to GitHub
4. Sets up upstream tracking

```bash
# Remove a worktree (after PR is merged)
wtm remove <name>

# Example:
wtm remove terminal
```

This does everything at once:
1. Kills any active tmux session for the worktree
2. Removes the worktree directory
3. Deletes the local branch
4. Deletes the remote branch on GitHub
5. Prunes stale worktree metadata

```bash
# List all worktrees
wtm list
```

---

## Putting It All Together

### Start a new task

```bash
# 1. Create worktree
wtm add terminal

# 2. Open tmux session
wtso dotfiles-agent-terminal

# 3. Work in the session, commit changes
#    (or delegate to the sub-agent in opencode: @agent-terminal)
```

### Complete a task (PR merged)

```bash
# Clean up worktree, branch, and tmux session
wtm remove terminal
```

### Full agent workflow in opencode

```
You (chat): @agent-terminal: Merge Ghostty configs into a single file

System agent delegates to agent-terminal via task() →
  agent-terminal works in ~/Projects/dotfiles-agent-terminal/
  agent-terminal commits to agent/terminal branch
  agent-terminal pushes to GitHub
  agent-terminal creates PR

You (chat): Approve and merge the PR

System agent merges via gh CLI →
  You confirm → PR merged

You (chat): Clean up

System agent: wtm remove terminal
```

### Available agents

| `@name` | Worktree | Configs |
|---|---|---|
| `@agent-tmux` | `dotfiles-agent-tmux` | tmux.conf |
| `@agent-opencode` | `dotfiles-agent-opencode` | opencode.jsonc, agent prompts |
| `@agent-bootstrap` | `dotfiles-agent-bootstrap` | install.sh, Brewfile, bin/ |
| `@agent-terminal` | `dotfiles-agent-terminal` | Ghostty config |
| `@agent-desktop` | `dotfiles-agent-desktop` | Aerospace, Neovim, .zshrc, .gitconfig |
