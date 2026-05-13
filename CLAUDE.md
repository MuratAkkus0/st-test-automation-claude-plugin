This file is auto-loaded when the plugin is active. It contains two sets of rules: (1) the plugin's memory system, and (2) development conventions for working on the plugin itself. Follow both.

---

# Part 1: Memory System

This plugin has its own memory system at `memory/`. Two memory systems coexist when this plugin is active: Claude Code's built-in auto-memory (writes to `~/.claude/projects/*`) and this plugin's memory (writes to `memory/`). They have different scopes — route correctly.

## Routing rule (overrides built-in auto-memory defaults)

When the user says "remember", "hatırla", expresses a preference, or you detect something memory-worthy, decide where it belongs BEFORE writing:

- **Use plugin memory (`memory/` here)** for any of the following — these override Claude Code's built-in auto-memory:
  - ST-test process insights, partner/market debugging patterns, integration quirks
  - Plugin development conventions, hook patterns, subagent design lessons
  - **Any user preference**, regardless of topic — communication style, output format, naming ("call me X"), workflow, language. ALL user preferences go to plugin memory when this plugin is active.
- **Use built-in auto-memory (`~/.claude/projects/*`)** for unrelated topics that surface in this session — generic coding tips, other projects, anything outside the ST-test domain AND not a user preference.

When in doubt about user preferences, default to plugin memory. The built-in system is for everything else.

## Memory location

The plugin keeps memory in three subdirectories under `memory/`:

- `memory/lessons-learned/` — generalizable debugging patterns, fix recipes, and insights that apply across test runs. Public, tracked in git.
- `memory/market-quirks/` — per-market technical idiosyncrasies (de, fr, nl, at, ch, es, it, pl, gb). One file per market, named `<market-code>.md`. Public, tracked in git.
- `memory/personal/` — Murat's stable preferences (communication style, output format, workflow). Private, gitignored.

`memory/MEMORY.md` is the index. It is loaded automatically at session start by the SessionStart hook and points to every detail file with a one-line hook.

## When to write

Auto-write is enabled. Write memory without asking for confirmation when one of these triggers fires:

- **Lesson learned:** When you detect a debugging pattern, fix recipe, or generalizable insight that applies beyond a single test run — write `memory/lessons-learned/<slug>.md`.
- **Market quirk:** When you detect a technical idiosyncrasy specific to one of the 9 markets (de, fr, nl, at, ch, es, it, pl, gb) — write or update `memory/market-quirks/<market-code>.md`.
- **User preference:** When Murat expresses a stable preference about communication style, output format, or workflow — write or update `memory/personal/user-preferences.md`.

## When NOT to write

These anti-spam heuristics are critical. Skip the write if any apply:

- Don't write one-off details specific to a single partner or single test run — those go in `st-test-reports/`.
- Don't write the result of a single observation — wait until you see the pattern twice.
- Don't write what's already documented in the SKILL.md files (they ARE the documentation).
- Don't write personal pronouns ("Murat", "the user") in `lessons-learned/` or `market-quirks/` (those are public). Personal phrasing goes in `personal/`.
- Don't write secrets, API keys, credentials, or tokens anywhere.

## File format

Every memory file uses YAML frontmatter:

```yaml
---
name: <kebab-case-slug>
description: <one-line summary used for retrieval>
type: lesson | quirk | preference
---

<body — short, factual>
```

For lessons, the body should include two labelled lines:

- `**Why:**` — the evidence or incident that justifies the lesson.
- `**How to apply:**` — the rule of thumb for future runs.

## Index discipline

After writing or updating any memory file, also update `memory/MEMORY.md` with a one-line entry under the matching section header. Format:

`- [Title](<subdir>/<slug>.md) — one-line hook`

If you update an existing file, leave the index entry as-is unless the hook needs revising.

## Reference docs

The canonical Claude Code plugin docs live at https://code.claude.com/docs/en/plugins (plugin creation), plus the sibling pages for plugins-reference, plugin-marketplaces, skills, hooks, and sub-agents. Murat keeps a local snapshot at `hepler-documantations/create-plugins-doc.md` — read that first, then fetch the live URL if the snapshot is stale. These docs are authoritative; prefer them over training-data recall when answering plugin-internals questions.

---

# Part 2: Development Conventions

These conventions apply when modifying the plugin itself (adding skills, agents, hooks, scripts, or refactoring structure). They were learned through real incidents during this plugin's development — see `memory/lessons-learned/` for the evidence behind each rule.

## Plugin structure

- **Flat layout for personal/local development.** The plugin lives at the repo root, not nested inside a `plugins/<name>/` subdirectory. Marketplace structure (`.claude-plugin/marketplace.json`) is only added when distributing to a team.
- **`--plugin-dir` is the install path for local dev.** Never assume marketplace install for personal use — see [plugin-dev-workflow](memory/lessons-learned/plugin-dev-workflow.md).
- **`$CLAUDE_PLUGIN_ROOT`, not `$CLAUDE_PROJECT_DIR`,** is the env var that points to the plugin's install directory inside hooks and scripts. `$CLAUDE_PROJECT_DIR` is where Claude was launched, which may be the parent of the plugin.

## Hook pattern

Every new hook follows the same three-piece pattern:

1. **Script:** `hooks/<name>.sh` — the actual logic in a self-contained, executable bash script. Self-locates via `$0` so it works regardless of where it's invoked from.
2. **Log:** `log/<name>.log` — one-line minimal log entry per fire (timestamp + fired/skipped + key state). Verbose logs only when the hook spawns nested processes that would otherwise be invisible.
3. **`hooks.json` entry:** just `bash "$CLAUDE_PLUGIN_ROOT/hooks/<name>.sh"` — never cram complex shell into the JSON command field.

The `log/` directory is gitignored. See [hook-script-log-pattern](memory/lessons-learned/hook-script-log-pattern.md).

## Subagent pattern

- **Minimal `tools:` list.** Each subagent's frontmatter should grant only the tools it needs. The auto-committer needs `Bash, Read` — not `Edit, Write`. Tight scoping limits blast radius if a subagent is fooled.
- **MCP tool names are lowercase.** `mcp__browseros__*`, not `mcp__browserOS__*`. Case-sensitive — wrong case means the agent silently has no tool access.
- **Recursion guard via env var** for any agent invoked from a hook that fires on its own side effects (e.g., a Stop hook that runs git operations, which then trigger another Stop). Set the var before spawning the child, check it on entry.
- **Non-interactive `claude -p` invocations need two flags:** `--plugin-dir "$CLAUDE_PLUGIN_ROOT"` (so the child sees plugin subagents/skills) and `--allowed-tools "Bash(<scope>) Read"` (so the child doesn't hang on permission prompts). See [subagent-non-interactive-invocation](memory/lessons-learned/subagent-non-interactive-invocation.md).
- **Strong description triggers.** "MUST BE USED automatically when X" and "Use PROACTIVELY" phrasing in the description are what makes Claude auto-route to the subagent.

## Test discipline

- **Dry-run any new hook script before activating it.** Set `$CLAUDE_PLUGIN_ROOT` (and any other env vars Claude would set), run `bash hooks/<name>.sh`, inspect the log file and stdout. Only then commit.
- **JSON validation after any JSON edit:** `python3 -m json.tool <file>` exit code 0.
- **Bash syntax check after any script edit:** `bash -n hooks/<name>.sh` exit code 0.
- **Trust-but-verify subagent output.** When a subagent reports it created N files, list them with `find` and spot-check each. Agents describe what they intended, not always what happened.
- **Empirical > theoretical.** When Claude Code docs and observed behavior disagree, observed behavior is truth. See [binary-grep-when-docs-fail](memory/lessons-learned/binary-grep-when-docs-fail.md).

## Commit standards

- **Conventional Commits format:** `<type>(<scope>): <subject>` with type from `feat|fix|docs|refactor|chore|test|style`. Subject is imperative mood, under 70 chars.
- **No AI attribution lines.** No `Co-Authored-By: Claude`, no `🤖 Generated with Claude Code` — the human author's identity already covers attribution and the noise clutters history.
- **Never bypass safety.** No `--no-verify`, no `--no-gpg-sign`, no `git push --force`, no `git commit --amend` to a published commit. If a hook fails, fix the underlying cause and commit again.
- **The auto-committer subagent handles routine commits** triggered by the Stop hook. Manual commits should follow the same rules.

## Doc-first verification for Claude Code internals

When questions arise about plugin structure, source types, env vars, hook event names, or any Claude Code framework detail:

1. **Read** `hepler-documantations/create-plugins-doc.md` first — the local snapshot of the official docs.
2. **Fetch** the live URL at https://code.claude.com/docs/en/plugins if the snapshot is stale or doesn't cover the topic.
3. **Grep the installed binary** at `/Users/murat.akkus/.local/share/claude/versions/<version>` (it's a Mach-O executable — use `strings <path> | grep -oE 'CLAUDE_[A-Z_]+'` or similar) when docs are ambiguous or contradicted by observed behavior.
4. **Never rely on training-data recall** for plugin internals — too many false positives.

The 5-hour marketplace-setup detour during this plugin's development was the cost of skipping step 1. Read the doc first.
