# CLAUDE.md

## Project Overview

claude-code-tmux-team is a CLI tool that creates a tmux-based multi-agent Claude Code team. It launches a Manager, Watchdog, and N Workers (default 10) in a single tmux session, enabling parallel task execution across multiple Claude Code instances. The CLI entry point is `ct` (alias for `claude-team`).

## Architecture

- **Manager (pane 0.0):** Orchestrator — plans and delegates, never writes code. Uses `--agent tmux-manager` (Opus).
- **Watchdog (pane 0.{cols}):** Monitors workers, auto-accepts prompts. Uses `--agent tmux-watchdog` (Haiku).
- **Workers (remaining panes):** Standard Claude Code instances (Opus) that execute tasks.

Communication is via tmux commands (`send-keys`, `capture-pane`) and runtime files under `/tmp/claude-team/<project>/`. See `docs/context-reference.md` for details.

## Key Directories

- `agents/` -- Agent definitions (tmux-manager.md, tmux-watchdog.md), installed to `~/.claude/agents/`
- `commands/` -- Slash command skills (tmux-*.md), installed to `~/.claude/commands/`
- `.claude/hooks/` -- Hook scripts (status-hook.sh) for status tracking, watchdog keep-alive, research enforcement, notifications
- `.claude/settings.local.json` -- Hook registration (maps events to status-hook.sh)
- `shell/` -- Launcher script (claude-team.sh), installed to `~/.local/bin/claude-team` with `ct` symlink
- `docs/` -- Platform guides (linux-server.md, windows-wsl2.md) and context-reference.md

## Development Conventions

- Agent definitions use YAML frontmatter: name, model, color, memory, description
- Commands follow the format: `# Skill: name` + `## Usage` + `## Prompt`
- Hook exit codes: 0 = allow, 1 = block with error, 2 = block with feedback message
- Shell scripts use `set -euo pipefail`
- The installer (`install.sh`) copies agents/ to `~/.claude/agents/` and commands/ to `~/.claude/commands/`
- Session names follow the pattern `ct-<project-name>`
- Runtime data lives under `/tmp/claude-team/<project>/`

## Testing Changes

- **Agent definitions:** restart the Manager or Watchdog to pick up changes
- **Hook changes:** restart ALL workers (hooks are loaded at startup per-instance)
- **Command/skill changes:** no restart needed (loaded on-demand)
- **Launcher changes:** need `ct stop && ct` or new `ct init`

## Important Files

- `shell/claude-team.sh` -- Main launcher: init, start, stop, restart, status, doctor, update, grid setup
- `.claude/hooks/status-hook.sh` -- Control plane: WORKING/IDLE status tracking, watchdog keep-alive (blocks Stop on watchdog pane), research report enforcement, Manager-only macOS notifications
- `install.sh` -- Copies agents, commands, shell script to user directories; registers repo path

## Context Reference

For deep documentation of all context layers (settings, hooks, memory, env vars, CLI flags, tmux integration, runtime state), see `docs/context-reference.md`.
