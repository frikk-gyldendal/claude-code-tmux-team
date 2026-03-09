#!/usr/bin/env bash
set -euo pipefail
# ──────────────────────────────────────────────────────────────────────
# claude-team — Project-aware TMUX Claude Team launcher
#
# Usage:
#   claude-team              # Smart launch (auto-attach or project picker)
#   claude-team init         # Register current directory as a project
#   claude-team list         # Show all registered projects + status
#   claude-team stop         # Stop session for current project
#   claude-team 4x3          # Launch/reattach with specific grid
#   claude-team --help       # Show usage
#
# Alias suggestion:
#   alias ct="claude-team"
# ──────────────────────────────────────────────────────────────────────

PROJECTS_FILE="$HOME/.claude/claude-team/projects"
mkdir -p "$(dirname "$PROJECTS_FILE")"
touch "$PROJECTS_FILE"

# ── Helpers ─────────────────────────────────────────────────────────

# Derive a sanitized project name from a directory path
project_name_from_dir() {
  basename "$1" | tr '[:upper:] .' '[:lower:]--' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# Find the project name registered for a given directory (empty if none)
find_project() {
  local dir="$1"
  grep -m1 ":${dir}$" "$PROJECTS_FILE" 2>/dev/null | cut -d: -f1 || true
}

# Check if a tmux session exists
session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

# Register a directory as a project
register_project() {
  local dir="$1"
  local name
  name="$(project_name_from_dir "$dir")"

  # Already registered?
  if grep -q ":${dir}$" "$PROJECTS_FILE" 2>/dev/null; then
    echo "  Already registered as '$(find_project "$dir")'"
    return 0
  fi

  # Handle name collision
  if grep -q "^${name}:" "$PROJECTS_FILE" 2>/dev/null; then
    local i=2
    while grep -q "^${name}-${i}:" "$PROJECTS_FILE" 2>/dev/null; do ((i++)); done
    name="${name}-${i}"
  fi

  echo "${name}:${dir}" >> "$PROJECTS_FILE"
  echo "  ✓ Registered '${name}' → ${dir}"
}

# List all projects with running status
list_projects() {
  echo ""
  echo "  Claude Code TMUX Team — Projects"
  echo ""
  local has_projects=false
  while IFS=: read -r name path; do
    [[ -z "$name" ]] && continue
    has_projects=true
    local short_path="${path/#$HOME/\~}"
    if session_exists "ct-${name}"; then
      printf "  ● %-20s %s\n" "$name" "$short_path"
    else
      printf "  ○ %-20s %s\n" "$name" "$short_path"
    fi
  done < "$PROJECTS_FILE"
  if [[ "$has_projects" == false ]]; then
    echo "  (no projects registered)"
  fi
  echo ""
  echo "  ● = running, ○ = stopped"
  echo ""
}

# Stop session for current directory's project
stop_project() {
  local name
  name="$(find_project "$(pwd)")"
  if [[ -z "$name" ]]; then
    echo "  No project registered for $(pwd)"
    return 1
  fi
  if tmux kill-session -t "ct-${name}" 2>/dev/null; then
    echo "  Stopped ct-${name}"
  else
    echo "  No active session for ${name}"
  fi
}

# Show interactive project picker menu
show_menu() {
  local grid="${1:-6x2}"

  echo ""
  echo "  Claude Code TMUX Team"
  echo "  ====================="
  echo ""
  echo "  No project registered for $(pwd)"
  echo ""

  # Read projects into arrays
  local -a names=() paths=() statuses=()
  while IFS=: read -r name path; do
    [[ -z "$name" ]] && continue
    names+=("$name")
    paths+=("$path")
    if session_exists "ct-${name}"; then
      statuses+=("● running")
    else
      statuses+=("○ stopped")
    fi
  done < "$PROJECTS_FILE"

  if [[ ${#names[@]} -gt 0 ]]; then
    echo "  Known projects:"
    for i in "${!names[@]}"; do
      local short_path="${paths[$i]/#$HOME/\~}"
      printf "    %d) %-20s %s  %s\n" $((i+1)) "${names[$i]}" "${short_path}" "${statuses[$i]}"
    done
    echo ""
  fi

  echo "  Options:"
  echo "    #) Enter number to open a project"
  echo "    i) Init current directory as new project"
  echo "    q) Quit"
  echo ""

  read -rp "  > " choice

  case "$choice" in
    [0-9]*)
      local idx=$((choice - 1))
      if [[ $idx -ge 0 && $idx -lt ${#names[@]} ]]; then
        local selected_name="${names[$idx]}"
        local selected_path="${paths[$idx]}"
        local selected_session="ct-${selected_name}"
        if session_exists "$selected_session"; then
          tmux attach -t "$selected_session"
        else
          launch_session "$selected_name" "$selected_path" "$grid"
        fi
      else
        echo "  Invalid selection"
        return 1
      fi
      ;;
    i|I|init)
      register_project "$(pwd)"
      echo "  Run 'claude-team' again to launch."
      ;;
    q|Q) return 0 ;;
    *)
      echo "  Invalid option"
      return 1
      ;;
  esac
}

# ── Launch Session ──────────────────────────────────────────────────
# The main tmux setup: grid splits, theming, pane naming,
# manager/watchdog/worker launches, auto-briefing.

launch_session() {
  local name="$1"
  local dir="$2"
  local grid="${3:-6x2}"
  local cols="${grid%x*}"
  local rows="${grid#*x}"
  local total=$(( cols * rows ))
  local watchdog_pane=$cols
  local session="ct-${name}"
  local runtime_dir="/tmp/claude-team/${name}"

  cd "$dir"

  # ── Clean up ─────────────────────────────────────────────────
  tmux kill-session -t "$session" 2>/dev/null || true
  rm -rf "$runtime_dir"
  mkdir -p "${runtime_dir}"/{messages,broadcasts,status}

  tmux new-session -d -s "$session" -c "$dir"

  # ── Theme: pane borders with titles ──────────────────────────
  tmux set-option -t "$session" pane-border-status top
  tmux set-option -t "$session" pane-border-format \
    ' #{?pane_active,#[fg=green#,bold],#[fg=colour245]}#{pane_index} #{pane_title} #[default]'
  tmux set-option -t "$session" pane-border-style 'fg=colour238'
  tmux set-option -t "$session" pane-active-border-style 'fg=green'
  tmux set-option -t "$session" pane-border-lines heavy

  # ── Status bar ───────────────────────────────────────────────
  tmux set-option -t "$session" status-position top
  tmux set-option -t "$session" status-style 'bg=colour235,fg=colour248'
  tmux set-option -t "$session" status-left-length 50
  tmux set-option -t "$session" status-right-length 60
  tmux set-option -t "$session" status-left \
    "#[fg=colour235,bg=green,bold]  CLAUDE TEAM: ${name} #[fg=green,bg=colour235] "
  tmux set-option -t "$session" status-right \
    "#[fg=colour245] #{pane_title} #[fg=colour235,bg=colour245] %H:%M #[fg=colour248,bg=colour240] #(echo \$((  \$(ls ${runtime_dir}/messages/*.msg 2>/dev/null | wc -l)  )) msgs) "
  tmux set-option -t "$session" status-interval 5

  # ── Split into grid ──────────────────────────────────────────
  for (( r=1; r<rows; r++ )); do
    tmux split-window -v -t "$session:0.0" -c "$dir"
  done
  tmux select-layout -t "$session" even-vertical

  for (( r=0; r<rows; r++ )); do
    for (( c=1; c<cols; c++ )); do
      tmux split-window -h -t "$session:0.$((r * cols))" -c "$dir"
    done
  done

  sleep 2

  # ── Name all panes ──────────────────────────────────────────
  tmux select-pane -t "$session:0.0" -T "MGR  Manager"
  tmux select-pane -t "$session:0.$watchdog_pane" -T "RUN  Watchdog"
  local wnum=0
  for (( i=1; i<total; i++ )); do
    [[ $i -eq $watchdog_pane ]] && continue
    (( wnum++ ))
    tmux select-pane -t "$session:0.$i" -T "W${wnum}  Worker ${wnum}"
  done

  # ── Launch Manager (pane 0.0) ────────────────────────────────
  tmux send-keys -t "$session:0.0" \
    "claude --dangerously-skip-permissions --agent tmux-manager" Enter
  sleep 0.5

  # Auto-send initial briefing once Manager is ready
  (
    sleep 10
    # Build worker pane list (all panes except 0.0 and watchdog)
    worker_panes=""
    for (( i=1; i<total; i++ )); do
      [[ $i -eq $watchdog_pane ]] && continue
      [[ -n "$worker_panes" ]] && worker_panes+=", "
      worker_panes+="0.$i"
    done
    tmux send-keys -t "$session:0.0" \
      "Team is online (project: ${name}). You have $((total - 2)) workers in panes ${worker_panes}. Pane 0.$watchdog_pane is the Watchdog (auto-accepts prompts). All workers are idle and awaiting tasks. What should we work on?" Enter
  ) &

  # ── Launch Watchdog (pane 0.$watchdog_pane) ──────────────────
  tmux send-keys -t "$session:0.$watchdog_pane" \
    "claude --dangerously-skip-permissions --agent tmux-watchdog" Enter
  sleep 0.5

  # Auto-start the watchdog loop
  (
    sleep 12
    # Build worker pane list for watchdog
    watch_panes=""
    for (( i=1; i<total; i++ )); do
      [[ $i -eq $watchdog_pane ]] && continue
      [[ -n "$watch_panes" ]] && watch_panes+=", "
      watch_panes+="0.$i"
    done
    tmux send-keys -t "$session:0.$watchdog_pane" \
      "Start monitoring. Total panes: $total. Skip pane 0.0 (Manager) and 0.$watchdog_pane (yourself). Monitor panes ${watch_panes}." Enter
  ) &

  # ── Launch Workers (all panes except Manager and Watchdog) ──
  for (( i=1; i<total; i++ )); do
    [[ $i -eq $watchdog_pane ]] && continue
    tmux send-keys -t "$session:0.$i" \
      "claude --dangerously-skip-permissions" Enter
    sleep 0.3
  done

  # ── Focus on Manager pane, attach ────────────────────────────
  tmux select-pane -t "$session:0.0"
  tmux attach -t "$session"
}

# ── Main Dispatch ───────────────────────────────────────────────────

grid=""

case "${1:-}" in
  --help|-h)
    cat << 'HELP'
Usage: claude-team [command] [grid]

Commands:
  (none)     Smart launch — auto-attach or show project picker
  init       Register current directory as a project
  list       Show all registered projects and their status
  stop       Stop the session for the current project
  --help     Show this help

Grid:
  NxM        Grid layout (e.g., 6x2, 4x3, 3x2)
             Only used when launching a new session

Examples:
  claude-team              # smart launch
  claude-team init         # register current dir
  claude-team 4x3          # launch with 4x3 grid
  claude-team list         # show all projects
  claude-team stop         # stop current project session
HELP
    exit 0
    ;;
  init)
    register_project "$(pwd)"
    exit 0
    ;;
  list)
    list_projects
    exit 0
    ;;
  stop)
    stop_project
    exit $?
    ;;
  [0-9]*x[0-9]*)
    grid="$1"
    ;;
  "")
    # No args — fall through to smart launch
    ;;
  *)
    echo "  Unknown command: $1"
    echo "  Run 'claude-team --help' for usage"
    exit 1
    ;;
esac

# ── Smart Launch ────────────────────────────────────────────────────

dir="$(pwd)"
name="$(find_project "$dir")"

if [[ -n "$name" ]]; then
  # Known project
  session="ct-${name}"
  if session_exists "$session"; then
    # Already running — just attach
    tmux attach -t "$session"
  else
    # Known but not running — launch
    launch_session "$name" "$dir" "${grid:-6x2}"
  fi
else
  # Unknown directory — show interactive menu
  show_menu "${grid:-6x2}"
fi
