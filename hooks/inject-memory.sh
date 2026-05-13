#!/usr/bin/env bash
# SessionStart hook — injects plugin memory index into Claude's context.
# Primary output (stdout) feeds Claude's system prompt.
# Side-effect: one-line log entry per fire to log/memory-injection.log.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT_FALLBACK="$(dirname "$SCRIPT_DIR")"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$PLUGIN_ROOT_FALLBACK}"
LOG_DIR="$PLUGIN_ROOT/log"
LOG_FILE="$LOG_DIR/memory-injection.log"
MEMORY_FILE="$PLUGIN_ROOT/memory/MEMORY.md"

mkdir -p "$LOG_DIR" 2>/dev/null

TS=$(date '+%Y-%m-%d %H:%M:%S')

if [ -f "$MEMORY_FILE" ]; then
  SIZE=$(wc -c < "$MEMORY_FILE" | tr -d ' ')
  echo "[$TS] fired; MEMORY.md=${SIZE}B; injected" >> "$LOG_FILE"
  printf '\n=== Plugin memory index ===\n'
  cat "$MEMORY_FILE"
  printf '\n=== end memory index ===\n'
else
  echo "[$TS] skipped; MEMORY.md not found at $MEMORY_FILE" >> "$LOG_FILE"
fi

exit 0
