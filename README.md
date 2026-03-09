<div align="center">

# Claude Code TMUX Team

**Run 10 Claude Code agents in parallel. One terminal.**

Orchestrate a fleet of AI coding agents with a Manager that plans, Workers that execute,<br>and a Watchdog that keeps everything running — all inside tmux.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-CLI-blueviolet)](https://docs.anthropic.com/en/docs/claude-code)
[![tmux](https://img.shields.io/badge/tmux-powered-green)](https://github.com/tmux/tmux)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%2F%20Zsh-orange)](#requirements)

</div>

---

```
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ 0.0      │ 0.1      │ 0.2      │ 0.3      │ 0.4      │ 0.5      │
│ MANAGER  │ Worker 1 │ Worker 2 │ Worker 3 │ Worker 4 │ Worker 5 │
├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ 0.6      │ 0.7      │ 0.8      │ 0.9      │ 0.10     │ 0.11     │
│ WATCHDOG │ Worker 6 │ Worker 7 │ Worker 8 │ Worker 9 │ Worker10 │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
          Default 6x2 grid — 10 workers, 1 manager, 1 watchdog
```

---

## The Problem

You have 30 files to refactor. One Claude Code instance. You wait for each file, one by one. It takes forever.

## The Solution

TMUX Claude Team launches **10 Claude Code instances in parallel**, coordinated by a Manager agent that breaks your task into subtasks, dispatches them to idle workers, and monitors progress — all in a single tmux session.

You talk to the Manager. The Manager runs the team. You ship 10x faster.

---

## Quick Start

**Install:**

```bash
curl -fsSL https://raw.githubusercontent.com/frikk-gyldendal/claude-code-tmux-team/main/web-install.sh | bash
```

Or clone and install locally:

```bash
git clone https://github.com/frikk-gyldendal/claude-code-tmux-team.git
cd claude-code-tmux-team && ./install.sh
```

The installer validates prerequisites automatically (Claude Code CLI, tmux, shell config) and provides clear feedback with colored output.

**Launch:**

```bash
cd ~/your-project
claude-team            # first time: shows project picker, choose "init"
claude-team            # next time: auto-launches your team
```

That's it. No config files. No shell reload. Just `claude-team`.

---

## What You'll See

When you run `claude-team`, the startup sequence gives you full visibility into what's happening:

1. **ASCII art banner** with your session configuration (grid size, worker count, working directory)
2. **Step-by-step progress** — each phase (grid creation, pane setup, agent launches) shows a checkmark as it completes
3. **Workers boot in ~15 seconds** — Claude Code instances launch in parallel across the grid
4. **Summary dashboard** — a formatted box confirms the session is ready, showing the grid layout and pane assignments

Once the summary appears, switch to the Manager pane (`0.0`) and start giving it tasks.

> Run `claude-team` to see the premium startup experience. Demo video coming soon.

---

## Commands

| Command | Description |
|---------|-------------|
| `claude-team` | Smart launch — auto-attach, launch, or show project picker |
| `claude-team init` | Register current directory as a project |
| `claude-team list` | Show all projects with running/stopped status |
| `claude-team stop` | Stop the team for the current project |
| `claude-team 4x3` | Launch with a custom grid layout |
| `claude-team --help` | Show all options |

---

## How It Works

<table>
<tr>
<td width="40" align="center"><strong>0</strong></td>
<td>You register your project: <code>claude-team init</code> (one time per project)</td>
</tr>
<tr>
<td align="center"><strong>1</strong></td>
<td>You run <code>claude-team</code> — it auto-launches or reattaches to an existing session</td>
</tr>
<tr>
<td align="center"><strong>2</strong></td>
<td>You tell the Manager what to do — <em>"Refactor all components to use the new design tokens"</em></td>
</tr>
<tr>
<td align="center"><strong>3</strong></td>
<td>The Manager analyzes the task and breaks it into independent, parallelizable subtasks</td>
</tr>
<tr>
<td align="center"><strong>4</strong></td>
<td>Each subtask is dispatched to an idle worker with a self-contained prompt</td>
</tr>
<tr>
<td align="center"><strong>5</strong></td>
<td>The Watchdog monitors workers and auto-accepts permission prompts to keep them unblocked</td>
</tr>
<tr>
<td align="center"><strong>6</strong></td>
<td>The Manager tracks progress and reports back when everything is done</td>
</tr>
</table>

---

## Features

- **Parallel execution** — 10 workers running simultaneously, not sequentially
- **Smart orchestration** — Manager plans, delegates, and monitors without writing code itself
- **Auto-unblocking** — Watchdog handles `y/n` prompts, permission dialogs, and confirmations
- **Premium startup experience** — ASCII banner, step-by-step progress indicators, and a summary dashboard
- **Session manifest** — Project context written to `/tmp/claude-team/<project>/session.env` so all tools and agents share config
- **Project-aware** — Register projects, auto-attach to running sessions, interactive picker
- **Flexible grid** — Configure `COLSxROWS` to match your screen and workload
- **Message bus** — Workers, Manager, and Watchdog communicate through a lightweight file-based system
- **Slash commands** — Built-in `/tmux-dispatch`, `/tmux-monitor`, `/tmux-team` and more
- **Zero config** — Install, init, launch. Works with any project.
- **Restartable** — Restart workers without killing the Manager with `/tmux-restart-workers`

---

## Architecture

| Role | Pane | Description |
|------|------|-------------|
| **Manager** | `0.0` | Plans tasks, delegates to workers, monitors progress. Never writes code. |
| **Watchdog** | `0.{cols}` | Monitors all worker panes. Auto-accepts prompts and confirmations. |
| **Workers** | All others | Standard Claude Code instances that do the actual implementation work. |

### Communication

| Channel | Mechanism |
|---------|-----------|
| Task dispatch | `tmux send-keys` / `tmux paste-buffer` |
| Progress monitoring | `tmux capture-pane` |
| Session manifest | `/tmp/claude-team/<project>/session.env` — shared config for all agents |
| Inter-pane messages | `/tmp/claude-team/<project>/messages/` |
| Broadcasts | `/tmp/claude-team/<project>/broadcasts/` |
| Status tracking | `/tmp/claude-team/<project>/status/` |

---

## Grid Configurations

The grid argument to `claude-team` is a `COLSxROWS` specification. Two panes are always reserved (Manager + Watchdog):

| Grid | Panes | Workers | Best for |
|------|-------|---------|----------|
| `6x2` | 12 | 10 | **Default** — large refactors, codebase sweeps |
| `4x3` | 12 | 10 | Taller panes — better for reading output |
| `4x2` | 8 | 6 | Medium tasks, smaller screens |
| `3x2` | 6 | 4 | Quick parallel tasks |
| `8x1` | 8 | 6 | Single row — maximizes pane height |

---

<details>
<summary><strong>Slash Commands Reference</strong></summary>

Once installed, these commands are available in any Claude Code instance:

| Command | Description |
|---------|-------------|
| `/tmux-dispatch` | Dispatch tasks to workers (primary send mechanism) |
| `/tmux-delegate` | Delegate a task to a specific pane |
| `/tmux-monitor` | Check status of all workers |
| `/tmux-team` | View full team overview with statuses |
| `/tmux-send` | Send a message to another pane |
| `/tmux-broadcast` | Broadcast a message to all panes |
| `/tmux-inbox` | Check incoming messages |
| `/tmux-status` | Set or view pane statuses |
| `/tmux-restart-workers` | Restart all workers (keeps Manager alive) |

</details>

<details>
<summary><strong>File Structure</strong></summary>

```
claude-code-tmux-team/
├── install.sh                   # Installer
├── web-install.sh               # Self-contained web installer (curl | bash)
├── agents/
│   ├── tmux-manager.md          # Manager agent definition → ~/.claude/agents/
│   └── tmux-watchdog.md         # Watchdog agent definition → ~/.claude/agents/
├── skills/                      # User-level slash commands → ~/.claude/skills/
│   ├── tmux-dispatch.md
│   ├── tmux-delegate.md
│   ├── tmux-monitor.md
│   ├── tmux-restart-workers.md
│   ├── tmux-manager-prompt.md
│   ├── tmux-runner-prompt.md
│   ├── tmux-team.md
│   ├── tmux-send.md
│   ├── tmux-broadcast.md
│   ├── tmux-inbox.md
│   └── tmux-status.md
├── commands/                    # Project-level commands → .claude/commands/
│   └── (same tmux-*.md files)
└── shell/
    └── claude-team.sh           # Smart launcher script → ~/.local/bin/claude-team
```

</details>

<details>
<summary><strong>Environment Variables</strong></summary>

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_TEAM_DIR` | `$PWD` | Working directory for the session |
| `CLAUDE_TEAM_NAME` | `claude-team` | tmux session name |

</details>

---

## Tips

**Aliases** — Add these to your shell config for quick access:

```bash
alias ct="claude-team"
alias ct4="claude-team 4x2"
alias cts="claude-team 3x2"   # small team
```

**Project commands** — Copy the commands into your project for project-scoped access:

```bash
cp -r /path/to/claude-code-tmux-team/commands/ .claude/commands/
```

---

## Windows Installation (WSL2)

Claude Team runs natively on Windows through WSL2 (Windows Subsystem for Linux). No dual-boot or VM needed — WSL2 gives you a real Linux kernel inside Windows with full tmux support.

### Prerequisites

- Windows 10 (version 2004+) or Windows 11
- Admin access for WSL2 installation

### Step 1: Install WSL2

```
wsl --install
```

This installs Ubuntu by default. Restart your PC when prompted.

After restart, Ubuntu will open automatically — set up your Unix username and password.

### Step 2: Install Dependencies

Once inside the WSL2 Ubuntu terminal, it's standard Linux from here:

```bash
sudo apt update && sudo apt install -y tmux git curl

# Install Node.js via fnm
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc
fnm install --lts
```

### Step 3: Install Claude Code & Team

```bash
npm install -g @anthropic-ai/claude-code
claude auth

# Install Claude Team
curl -fsSL https://raw.githubusercontent.com/frikk-gyldendal/claude-code-tmux-team/main/web-install.sh | bash
```

### Step 4: Launch

```bash
cd /path/to/your/project
claude-team init
claude-team
```

That's it — from here, the experience is identical to macOS and Linux.

### Tips for WSL2 Users

- **Access Windows files** from WSL2 at `/mnt/c/Users/YourName/...` — but working inside the Linux filesystem (`~/`) is significantly faster
- **Windows Terminal** is the best way to use WSL2 — it supports tabs, splits, and renders the tmux grid cleanly. Install it from the Microsoft Store if you don't have it.
- **VS Code integration** — run `code .` from WSL2 to open VS Code with the WSL remote extension
- **Clipboard** works between Windows and WSL2 automatically
- **RAM allocation** — WSL2 uses up to 50% of system RAM by default. For a 10-worker team, 8GB+ total system RAM is comfortable. You can limit WSL2 memory in `%UserProfile%\.wslconfig`:

```ini
[wsl2]
memory=4GB
```

---

## Linux Server Deployment

Running Claude Code TMUX Team on a Linux server is one of the best use cases — your team of agents keeps working even after you disconnect from SSH. Start a task, detach, close your laptop, and come back later to find the work done.

### Prerequisites

| Distro | Install essentials |
|--------|-------------------|
| **Ubuntu / Debian** | `sudo apt update && sudo apt install -y tmux git curl` |
| **Amazon Linux / RHEL** | `sudo yum install -y tmux git curl` |
| **Arch Linux** | `sudo pacman -S tmux git curl` |

**Node.js 18+** — install via [fnm](https://github.com/Schniz/fnm) (recommended):

```bash
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc        # or restart your shell
fnm install --lts
```

**Claude Code CLI:**

```bash
npm install -g @anthropic-ai/claude-code
```

**Authenticate:**

```bash
claude auth
```

### Quick Setup (< 5 Minutes)

Copy-paste this entire block on a fresh Ubuntu/Debian server to go from zero to a running team:

```bash
# 1. Install system dependencies
sudo apt update && sudo apt install -y tmux git curl

# 2. Install Node.js via fnm
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc
fnm install --lts

# 3. Install Claude Code CLI and authenticate
npm install -g @anthropic-ai/claude-code
claude auth

# 4. Install claude-code-tmux-team
git clone https://github.com/frikk-gyldendal/claude-code-tmux-team.git
cd claude-code-tmux-team && ./install.sh

# 5. Init your project and launch
cd ~/your-project
claude-team init
claude-team
```

### Headless / SSH Usage

The core workflow is simple — SSH in, launch (or reattach), work, detach, disconnect:

```bash
# From your local machine
ssh user@your-server

# On the server — start or reattach
cd ~/your-project
claude-team

# Give the Manager a task, then detach when ready
# Ctrl+B, D  →  detaches from tmux (team keeps running)

# Disconnect SSH — the team continues working
exit
```

Reconnect anytime — `claude-team` auto-reattaches to the running session:

```bash
ssh user@your-server
cd ~/your-project
claude-team              # picks up right where you left off
```

<details>
<summary><strong>Running as a Background Service (Advanced)</strong></summary>

You can configure a systemd user service to auto-start a claude-team session on boot.

Create `~/.config/systemd/user/claude-team.service`:

```ini
[Unit]
Description=Claude Code TMUX Team
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
Environment=HOME=%h
Environment=PATH=%h/.local/bin:%h/.fnm/aliases/default/bin:/usr/local/bin:/usr/bin:/bin
WorkingDirectory=%h/your-project
ExecStart=/usr/bin/tmux new-session -d -s claude-team "%h/.local/bin/claude-team"
ExecStop=/usr/bin/tmux kill-session -t claude-team
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

Enable and start:

```bash
# Enable lingering so user services run without an active login
sudo loginctl enable-linger $USER

systemctl --user daemon-reload
systemctl --user enable claude-team
systemctl --user start claude-team

# Check status
systemctl --user status claude-team
```

> This is optional. Most users will prefer the manual SSH + detach workflow above.

</details>

### Cloud Providers

Claude Team is network-bound (API calls to Anthropic), not CPU/RAM-intensive — even the smallest instances work. Any Linux VPS with tmux and Node.js is enough.

<details>
<summary><strong>Hetzner Cloud (~€3.29/mo)</strong></summary>

1. Create a **CX22** server with **Ubuntu 24.04** (Falkenstein, Nuremberg, Helsinki, or Ashburn)
2. SSH into the server
3. Run the Quick Setup block from above

```bash
ssh root@your-hetzner-ip

# Then run the Quick Setup script (see above), starting with:
sudo apt update && sudo apt install -y tmux git curl
# ... rest of the Quick Setup block
```

EU and US datacenters available. No egress fees.

</details>

<details>
<summary><strong>DigitalOcean ($6/mo)</strong></summary>

1. Create a **Basic Droplet** with **Ubuntu 24.04**
2. SSH into the droplet
3. Run the Quick Setup block from above

```bash
ssh root@your-droplet-ip

# Then run the Quick Setup script (see above), starting with:
sudo apt update && sudo apt install -y tmux git curl
# ... rest of the Quick Setup block
```

Simple UI, great for getting started quickly.

</details>

<details>
<summary><strong>AWS EC2 (free tier eligible)</strong></summary>

1. Launch a **t3.micro** instance with the **Ubuntu 24.04** AMI
2. Configure the security group to allow **SSH (port 22)** from your IP
3. SSH into the instance with your key pair
4. Run the Quick Setup block from above

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip

# Then run the Quick Setup script (see above), starting with:
sudo apt update && sudo apt install -y tmux git curl
# ... rest of the Quick Setup block
```

Free tier gives you 12 months of t3.micro at no cost.

</details>

**Security reminders:**

- **Never commit API keys** — use environment variables or a `.env` file (already in `.gitignore`)
- Set `ANTHROPIC_API_KEY` in your shell profile or use `claude auth` for session-based auth
- Use SSH key authentication — disable password auth in `sshd_config` for production servers

### Troubleshooting (Linux)

| Issue | Fix |
|-------|-----|
| **tmux version too old** (< 2.4) | Install from source or use a backports repo: `sudo apt install -t bullseye-backports tmux` |
| **`node` not found after fnm install** | Run `source ~/.bashrc` or open a new shell — fnm needs the PATH update |
| **Locale / UTF-8 errors** (garbled ASCII art) | `sudo apt install -y locales && sudo locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8` |
| **`claude-team` command not found** | Ensure `~/.local/bin` is on your PATH: `export PATH="$HOME/.local/bin:$PATH"` |
| **Workers fail to start** | Check that `claude` CLI works standalone first: `claude --version` |

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- [tmux](https://github.com/tmux/tmux) (any recent version)
- macOS or Linux
- A terminal with a large window (the grid needs room)

---

## Contributing

Contributions are welcome! Open an issue or submit a PR.

This project is in active development — if you find bugs, have ideas for new slash commands, or want to improve the orchestration logic, jump in.

---

## License

[MIT](LICENSE)

---

<div align="center">

**Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code)**

If you find this useful, [give it a star](https://github.com/frikk-gyldendal/claude-code-tmux-team) — it helps others find it.

</div>
