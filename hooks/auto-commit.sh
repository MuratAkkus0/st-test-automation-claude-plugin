#!/usr/bin/env bash
# Stop-hook auto-commit script for st-test-plugin.
# Triggered when Claude finishes a response turn. Stages all repo changes
# inside the plugin directory, generates a Conventional Commits message via
# the auto-committer subagent, commits, and pushes. Safe-by-default: every
# guard logs a clear skip reason.
#
# Uses $CLAUDE_PLUGIN_ROOT (plugin install location) — NOT $CLAUDE_PROJECT_DIR
# (which is the user's working dir and may be the parent of the plugin).

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT_FALLBACK="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PLUGIN_ROOT_FALLBACK/log"
LOG_FILE="$LOG_DIR/auto-committer.log"

mkdir -p "$LOG_DIR" 2>/dev/null

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# Resolve the plugin root: prefer the env var Claude Code sets, fall back to
# the script's own parent directory so manual `bash auto-commit.sh` still works.
TARGET_DIR="${CLAUDE_PLUGIN_ROOT:-$PLUGIN_ROOT_FALLBACK}"

{
  echo "[$(ts)] === Stop hook fired ==="
  echo "[$(ts)] CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT:-<unset>}'"
  echo "[$(ts)] CLAUDE_PROJECT_DIR='${CLAUDE_PROJECT_DIR:-<unset>}'"
  echo "[$(ts)] ST_AUTOCOMMIT_RUNNING='${ST_AUTOCOMMIT_RUNNING:-<unset>}'"
  echo "[$(ts)] PWD='$PWD'"
  echo "[$(ts)] TARGET_DIR='$TARGET_DIR'"

  if ! cd "$TARGET_DIR" 2>/dev/null; then
    echo "[$(ts)] SKIP: cd into '$TARGET_DIR' failed"
  elif [ ! -d .git ]; then
    echo "[$(ts)] SKIP: '$PWD' is not a git repo"
  elif [ -z "$(git status --porcelain)" ]; then
    echo "[$(ts)] SKIP: no changes to commit"
  elif [ "$ST_AUTOCOMMIT_RUNNING" = "1" ]; then
    echo "[$(ts)] SKIP: recursion guard active (ST_AUTOCOMMIT_RUNNING=1)"
  else
    CHANGED_COUNT="$(git status --porcelain | wc -l | tr -d ' ')"
    echo "[$(ts)] all guards passed; $CHANGED_COUNT changed path(s); invoking claude -p"
    ST_AUTOCOMMIT_RUNNING=1 claude \
      --plugin-dir "$TARGET_DIR" \
      --allowed-tools "Bash(git *) Read" \
      -p "Use the auto-committer subagent to commit and push all current changes." \
      --output-format text 2>&1
    echo "[$(ts)] claude -p exited with status=$?"
  fi

  echo "[$(ts)] === hook done ==="
} >> "$LOG_FILE" 2>&1

exit 0
