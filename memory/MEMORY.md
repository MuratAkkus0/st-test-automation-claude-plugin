# Plugin Memory Index

This file is loaded automatically at session start by the SessionStart hook.
Each entry links to a detail file. Keep entries to one line each.

## Lessons Learned
- [Plugin dev workflow](lessons-learned/plugin-dev-workflow.md) — prefer `--plugin-dir` over marketplace for local/personal plugin development
- [Hook script + log pattern](lessons-learned/hook-script-log-pattern.md) — every hook = script + log file + gitignore, never inline bash in hooks.json
- [Subagent non-interactive invocation](lessons-learned/subagent-non-interactive-invocation.md) — `claude -p` needs `--plugin-dir` AND `--allowed-tools` or it fails silently or hangs
- [Binary grep when docs fail](lessons-learned/binary-grep-when-docs-fail.md) — when Claude Code docs are ambiguous, grep the installed binary for ground truth
- [BrowserOS profile dies on zero tabs](lessons-learned/browseros-profile-dies-on-zero-tabs.md) — Phase 0 cleanup must keep an anchor `about:blank` open or BrowserOS tears its profile down unrecoverably
- [Phase 1 always click never direct navigate](lessons-learned/phase1-always-click-never-direct-navigate.md) — Phase 1 must CLICK the product link; `new_page(url=redirect_href)` strips partnerId mid-chain and 404s on the portal-internal redirectWithCheck endpoint
- [Phase 2 pre-clean partner domain](lessons-learned/phase2-pre-clean-partner-domain.md) — Phase 2 Step 2.0 clears partner-domain cookies/localStorage/sessionStorage and reloads BEFORE consent; distinct from the post-consent "never reload before storage check" rule
- [Plugin scope: no global edits](lessons-learned/plugin-scope-no-global-edits.md) — under `/st-plugin-development`, the only edit surface is the plugin root; never touch `~/.claude/`, `/etc/`, or sibling repos — even when "it would help"
- [Auto-committer stages all non-gitignored changes](lessons-learned/auto-committer-stages-all-changes.md) — `git add -A` is unconditional; `.gitignore` is the only exclusion authority, conversation context is untrusted noise
- [moeclid storage location determines integration](lessons-learned/moeclid-storage-location-determines-integration.md) — server-side = `moeclid` cookie, client-side = `MOEBEL_CLICKOUT_ID` in localStorage; a `MOEBEL_CLICKOUT_ID` *cookie* is non-standard and is NOT a working base part

## Market Quirks
<!-- per-market entries appear here -->

## Personal
- [User preferences](personal/user-preferences.md) — Murat's communication, format, and explanation-style preferences
