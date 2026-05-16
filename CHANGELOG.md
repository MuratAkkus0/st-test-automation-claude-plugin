# Changelog

All notable changes to this plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this plugin uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `skills/st-plugin-development/SKILL.md` — canonical development workflow skill that codifies the methodology established across the plugin's first 7+ iterations. Auto-invoked for any plugin edit/patch/feature work. Enforces nine phases (pre-check → plan → subagent decision → anti-orphan/anti-duplicate/anti-workaround → implementation → validation → docs update → commit → post-verification). Hard guarantees: no workarounds, no orphan files, no duplicate features, no inline bash in `hooks.json`, no AI attribution in commits, root-cause fixes only.
- `memory/lessons-learned/plugin-scope-no-global-edits.md` — codifies that `/st-plugin-development` may only edit files inside the plugin tree; never `~/.claude/`, `/etc/`, or sibling repos. Cross-linked from `docs/dev-conventions.md` as a new "Scope discipline" section.
- New English fix-paragraph variant in the partner-email template (`skills/st-report-generation/SKILL.md`) for the "Conversion Tag called with undefined values" failure mode — instructs the partner to check both GTM variable names and data-layer population at checkout.

### Fixed

- Skill files now link the bundled integration / identity reference docs by relative path. `skills/st-market-reference/SKILL.md` adds a "Local reference file" column to the integration documentation URL table and links the IDENTITY INFORMATIONEN note to `hepler-documantations/IDENTITY INFORMATIONEN.md`. `skills/st-phase-2-base-part-verification/SKILL.md` turns the bare `GTM_*_Integration_Documentation` doc names into clickable links pointing at the bundled local files. Root cause: when the plugin was extracted from the source project, the in-skill references kept pointing to project-relative paths that no longer exist; the docs were re-added under `hepler-documantations/` but the references were never re-wired. The public partner-facing URLs stay the source of truth for partner reports — the local links are for the agent's own reading.
- Removed dangling references to `Sales_Tracking_Report_for_Jira_Example_*` files and to "Example 3" / "Example 2 and Example 6" from `skills/st-report-generation/SKILL.md`, and the "in the style of the project's real Jira comments" phrase from `skills/sales-tracking-test-automation/SKILL.md`. Those example files were not carried over into the plugin when it was extracted from the source project, and the skills already encode the format conventions explicitly.

### Changed

- Phase 6 problem-summary variant for the Conversion-Tag failure mode (`skills/st-report-generation/SKILL.md`): replaced the narrow "Conversion payload sends null for shipping/items (server-side)" wording with the broader, hand-authored canonical version that covers wrong GTM variable names AND unpopulated checkout data, written as two paragraphs (problem description + fix instruction). The variant now lists explicit trigger criteria (`MOEBEL_SALES.sale()` call present + console errors `Can not convert undefined to number` / `Error sanitizing sale`) so the right variant is selected automatically. English email outcome-paragraph variant updated to mirror.
- `st-test-plugin/settings.json` (plugin-root forward-compat manifest) — added `Bash(until *)`, `Bash(ls *)`, `Bash(jq *)` so the declared permission set matches what ST-test runs actually exercise. The file is still ignored by Claude Code today (only `agent` and `subagentStatusLine` keys are honored at plugin root), but stays the canonical source of truth for the team-facing setup guide.
- `docs/setup-guide.md` — full team-facing permission list now mirrors plugin-root `settings.json` (MCP wildcards + bash utilities), not just the two MCP wildcards. Clarified that `Read`/`Write`/`Edit` paths inside the plugin tree don't need to be added to user-side `~/.claude/settings.json`.

## [1.7.0] — 2026-05-13

Initial structured release. Converted from a standalone `.skill` archive into a full Claude Code plugin with skills, agents, commands, hooks, memory, and conventions.

### Added — Core structure

- Plugin manifest at `.claude-plugin/plugin.json` (name, version, author)
- 8 modular skills split from the original 1802-line monolithic `SKILL.md`:
  - `sales-tracking-test-automation` (orchestrator)
  - `st-market-reference` (9 markets reference data)
  - `st-phase-0-pre-test-setup`
  - `st-phase-1-navigation-and-moeclid-capture`
  - `st-phase-2-base-part-verification`
  - `st-phase-3-purchase-flow`
  - `st-phase-4-conversion-verification`
  - `st-report-generation`

### Added — Subagents

- `st-cookie-consent-handler` — multi-layer CMP detection (a11y snapshot → TreeWalker text-scan → retry → defensive re-click)
- `st-partner-finder` — two-pass partner search (shops listing, then brands listing)
- `st-storage-inspector` — moeclid storage verification with reload-once strategy
- `st-report-writer` — generates Markdown report + ADF Jira draft + Outlook email draft
- `auto-committer` — automated Conventional Commits with recursion guard + secrets scan, no AI attribution

### Added — Slash commands

- `/st-test <partner> <market> [JIRA-TICKET] [@colleague] [partner-key] [partner-email]` — primary test entry point
- `/st-report [partner] [market]` — display past reports
- `/st-jira-post <ticket> [path] [@colleague]` — post existing draft to a Jira ticket

### Added — Hooks

- SessionStart `session-greet.sh` — BrowserOS dependency reminder at startup
- SessionStart `inject-memory.sh` — injects `memory/MEMORY.md` into Claude's context
- Stop `auto-commit.sh` — auto-commits + pushes plugin changes after each response (recursion-safe via `ST_AUTOCOMMIT_RUNNING` env guard)
- All hooks follow the `script + log + gitignore` pattern (no inline bash in `hooks.json`)

### Added — Memory system

- Plugin-scoped memory at `memory/` with three subdirectories:
  - `lessons-learned/` (public, tracked)
  - `market-quirks/` (public, tracked, populated on demand)
  - `personal/` (private, gitignored)
- `st-memory` skill manages read / write / delete with auto-write triggers
- `CLAUDE.md` anchors plugin governance:
  - Part 1 — memory rules with routing override (plugin memory wins over built-in for ST / preference topics)
  - Part 2 — development conventions (structure, hooks, subagents, tests, commits, doc-first)
  - Part 3 — required user permission setup
- 4 seeded lessons captured during plugin development:
  - `plugin-dev-workflow.md` — prefer `--plugin-dir` over marketplace for local dev
  - `hook-script-log-pattern.md` — every hook = script + log + gitignore
  - `subagent-non-interactive-invocation.md` — `claude -p` needs `--plugin-dir` AND `--allowed-tools`
  - `binary-grep-when-docs-fail.md` — grep the installed binary when docs and behavior disagree
- `memory/personal/user-preferences.md` for private user preferences

### Added — Permission defaults

- User-level `~/.claude/settings.json`:
  - `mcp__browseros__*` (all BrowserOS tools auto-approved)
  - `mcp__claude_ai_Atlassian__*` (all Jira tools auto-approved)
  - `Read(<plugin>/**)` (full read access to plugin files)
  - `Write(<plugin>/st-test-reports/**)` (test report writes auto-approved)
  - `Write(<plugin>/memory/**)` and `Edit(<plugin>/memory/**)` (memory operations auto-approved)
- Plugin root `settings.json` with forward-compat permission defaults — currently silently ignored by Claude Code (only `agent` and `subagentStatusLine` keys are supported), but ready for the day plugin-shipped permissions land

### Added — Documentation

- `README.md` — plugin overview, installation, usage, features, dependencies
- `CHANGELOG.md` — this file
- `hepler-documantations/create-plugins-doc.md` — local snapshot of the official Claude Code plugin docs
- `.gitignore` — covers `log/`, `memory/personal/`, macOS noise (`.DS_Store`, `*.swp`)

### Changed

- Plugin layout flattened from `plugins/st-test-plugin/` (marketplace-style) to plugin root — marketplace layer removed
- Hook commands refactored from inline bash to script files

### Removed

- Original monolithic `sales-tracking-test-v1.7.skill` ZIP archive (extracted, no longer needed)
- Stale `.claude/settings.local.json` debug cruft (76 of 85 entries were one-off Bash approvals from development)
- Stale `extraKnownMarketplaces.st-local` and empty `enabledPlugins` from user-level settings

### Fixed

- MCP tool name casing bug in 3 agent files — `mcp__browserOS__*` corrected to `mcp__browseros__*` (case-sensitive — wrong case silently hid the tools)
- Hook script's `cd "$CLAUDE_PROJECT_DIR"` silent bypass when the env var is unset (`cd ""` returns 0 under POSIX) — added explicit `[ -n "$CLAUDE_PROJECT_DIR" ]` guard
- Wrong env var in hook command — `$CLAUDE_PROJECT_DIR` (where Claude was launched) replaced with `$CLAUDE_PLUGIN_ROOT` (plugin install dir)
- `claude -p` not seeing plugin subagents — added `--plugin-dir "$CLAUDE_PLUGIN_ROOT"` flag
- `claude -p` hanging on permission prompts in non-interactive mode — added `--allowed-tools "Bash(git *) Read"` flag
- `marketplace.json` plugin entry missing required `author` field — addressed during the marketplace experiment, ultimately superseded by the marketplace removal
