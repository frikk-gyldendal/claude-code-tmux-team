# Skill: tmux-stop-all

Stop all running Claude Team sessions at once.

## Usage
`/tmux-stop-all`

## Prompt
You need to stop all running Claude Team tmux sessions.

### Steps

1. Read the projects registry and find running sessions:
   ```bash
   PROJECTS_FILE="$HOME/.claude/claude-team/projects"
   while IFS=: read -r name path; do
     [ -z "$name" ] && continue
     SESSION="ct-${name}"
     if tmux has-session -t "$SESSION" 2>/dev/null; then
       echo "Stopping $SESSION ($path)..."
       tmux kill-session -t "$SESSION"
       echo "  ✓ Stopped"
     else
       echo "  ○ $SESSION — not running"
     fi
   done < "$PROJECTS_FILE"
   ```

2. Report what was stopped and what was already offline.
