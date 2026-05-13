#!/usr/bin/env bash
# SessionStart hook — prints the BrowserOS MCP reminder.
# Primary output (stdout) is shown to the user at session start.
# Side-effect: one-line log entry per fire to log/session-greet.log.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT_FALLBACK="$(dirname "$SCRIPT_DIR")"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$PLUGIN_ROOT_FALLBACK}"
LOG_DIR="$PLUGIN_ROOT/log"
LOG_FILE="$LOG_DIR/session-greet.log"

mkdir -p "$LOG_DIR" 2>/dev/null

TS=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TS] fired" >> "$LOG_FILE"

printf '[st-test-plugin] Loaded. Sales tracking tests require the BrowserOS MCP server to be connected for browser automation. Use the /st-test slash command to start a test run (e.g. /st-test IKEA de).\n'

exit 0
