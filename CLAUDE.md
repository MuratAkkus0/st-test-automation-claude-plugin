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

# Part 2 & 3: Development Conventions + Setup

See `docs/dev-conventions.md` and `docs/setup-guide.md`. Load these only when modifying the plugin itself or during initial setup.
