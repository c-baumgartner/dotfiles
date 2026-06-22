#!/usr/bin/env bash
# Claude Code statusline: starship-rendered dir/git/model + caveman mode badge.
# Wired in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.dotfiles/claude/statusline.sh" }
#
# Claude Code feeds session JSON on stdin. We extract cwd + model, render a
# compact starship line from claude.toml, then append the caveman badge (which
# reads its own flag file and ignores stdin).

input=$(cat)

# Parse cwd + model display name (two lines; handles spaces in paths).
# Avoid mapfile/readarray — macOS ships bash 3.2 which lacks them.
parsed=$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
ws = d.get("workspace") or {}
print(ws.get("current_dir") or d.get("cwd") or "")
print((d.get("model") or {}).get("display_name") or "")
' 2>/dev/null)

cwd="${parsed%%$'\n'*}"
model="${parsed#*$'\n'}"

[ -n "$cwd" ] && [ -d "$cwd" ] && cd "$cwd" || true
export CLAUDE_MODEL="$model"

# Starship segment (dir / git / model). Empty STARSHIP_SHELL emits raw ANSI
# (no zsh %{%} / bash \[\] non-printing wrappers, which the statusline can't use).
if command -v starship >/dev/null 2>&1; then
  STARSHIP_SHELL= STARSHIP_CONFIG="$HOME/.config/starship/claude.toml" starship prompt 2>/dev/null
fi

# Caveman mode badge — resolve newest plugin version dir (path contains a hash).
cav=$(ls -t "$HOME"/.claude/plugins/cache/caveman/caveman/*/hooks/caveman-statusline.sh 2>/dev/null | head -1)
if [ -n "$cav" ] && [ -f "$cav" ]; then
  badge=$(bash "$cav" 2>/dev/null)
  [ -n "$badge" ] && printf ' %s' "$badge"
fi
