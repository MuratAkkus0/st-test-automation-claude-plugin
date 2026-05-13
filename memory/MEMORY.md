# Plugin Memory Index

This file is loaded automatically at session start by the SessionStart hook.
Each entry links to a detail file. Keep entries to one line each.

## Lessons Learned
- [Plugin dev workflow](lessons-learned/plugin-dev-workflow.md) — prefer `--plugin-dir` over marketplace for local/personal plugin development
- [Hook script + log pattern](lessons-learned/hook-script-log-pattern.md) — every hook = script + log file + gitignore, never inline bash in hooks.json
- [Subagent non-interactive invocation](lessons-learned/subagent-non-interactive-invocation.md) — `claude -p` needs `--plugin-dir` AND `--allowed-tools` or it fails silently or hangs
- [Binary grep when docs fail](lessons-learned/binary-grep-when-docs-fail.md) — when Claude Code docs are ambiguous, grep the installed binary for ground truth
- [BrowserOS profile dies on zero tabs](lessons-learned/browseros-profile-dies-on-zero-tabs.md) — Phase 0 cleanup must keep an anchor `about:blank` open or BrowserOS tears its profile down unrecoverably

## Market Quirks
<!-- per-market entries appear here -->

## Personal
- [User preferences](personal/user-preferences.md) — Murat's communication, format, and explanation-style preferences
