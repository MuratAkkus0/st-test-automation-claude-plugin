---
name: st-memory
description: MUST BE USED for ALL user preferences and ALL ST-test / plugin-domain memory requests, OVERRIDING Claude Code's built-in auto-memory system for those topics. Use PROACTIVELY whenever the user says "remember", "hatırla", "forget", "unut", "call me X", "ben şuyumu", expresses a preference (communication, format, name, workflow, language), asks "what do you know about X" / "ne biliyorsun X hakkında", or when you (Claude) detect a new ST-domain lesson, market quirk, or user preference. Built-in auto-memory at `~/.claude/projects/*` is ONLY for unrelated topics outside the ST-test domain AND not user preferences — when in doubt about a user preference, route here. Writes to the plugin's `memory/` directory: lessons-learned/, market-quirks/, or personal/.
---

## When to invoke

Trigger this skill when any of the following happen:

- User says `remember`, `hatırla`, `save this`, `not al`, `kaydet`.
- User says `forget`, `unut`, `delete memory`, `sil`.
- User asks `what do you know about X`, `ne biliyorsun X hakkında`, `hatırlıyor musun`.
- You (Claude) detect a generalizable lesson, a market-specific quirk, or a stable user preference and the anti-spam heuristics in `CLAUDE.md` are satisfied.

## Where to write

Use the plugin's own memory tree — never `~/.claude/projects/*`.

- `memory/lessons-learned/<slug>.md` — generalizable insights, debugging patterns, fix recipes.
- `memory/market-quirks/<market-code>.md` — technical idiosyncrasies for `de`, `fr`, `nl`, `at`, `ch`, `es`, `it`, `pl`, `gb`. One file per market.
- `memory/personal/user-preferences.md` (or `memory/personal/<slug>.md`) — stable user preferences. Gitignored.

## Writing procedure

1. Decide the category — lesson, quirk, or preference.
2. Check `memory/MEMORY.md` and the relevant subdirectory for an existing file that covers the same topic. If one exists, UPDATE it; if not, CREATE a new file.
3. Use a `kebab-case-slug` filename.
4. Write the file with the frontmatter and body format defined in `CLAUDE.md`:
   ```yaml
   ---
   name: <kebab-case-slug>
   description: <one-line summary>
   type: lesson | quirk | preference
   ---
   ```
   For lessons, include `**Why:**` and `**How to apply:**` lines in the body.
5. Append a one-line index entry to `memory/MEMORY.md` under the correct section header:
   `- [Title](<subdir>/<slug>.md) — one-line hook`
6. Inform the user briefly with a single line: `Saved memory: <slug>`.

## Reading procedure

When the user asks what is known about a topic:

1. Read `memory/MEMORY.md` to see candidate entries.
2. Read the relevant detail file(s) the index points to.
3. Summarize what is known in plain language. Do not paste the raw file unless asked.

## Deletion procedure

When the user says "forget X":

1. Locate the matching file under `memory/`.
2. Delete the file.
3. Remove the corresponding index line from `memory/MEMORY.md`.
4. Confirm with a single line: `Forgot: <slug>`.

## Edge cases

- If unsure whether something is personal vs public, default to `memory/personal/` (safer — gitignored).
- If a "lesson" is actually a one-off observation tied to a single test run or partner, skip the write and route the detail to `st-test-reports/` instead.
- Never write secrets, API keys, credentials, or tokens into any memory file.
- Never duplicate content that already exists in another SKILL.md — link to the skill instead.
