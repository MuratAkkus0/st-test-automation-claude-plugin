---
name: st-plugin-development
description: MUST BE USED for ALL development work on the st-test-plugin — adding/modifying/removing any skill, agent, slash command, hook, script, CLAUDE.md section, README/CHANGELOG entry, settings.json, memory file, or other plugin artifact. Use PROACTIVELY whenever the user requests phrases like "add a skill/agent/hook/command", "modify the plugin", "patch this", "edit the skill", "refactor", "implement a feature", "add functionality", "fix the plugin", "yeni skill ekle", "agent ekle", "hook ekle", "komut ekle", "plugin'i güncelle", "plugin'e ekle", "düzenle". Codifies the methodology developed during this plugin's iterative build-out, captured to prevent re-learning the same lessons. Hard guarantees: no workarounds, no orphan files, no duplicate features/data, no inline bash in hooks.json, no AI attribution in commits, root-cause fixes only. Refer to `docs/dev-conventions.md` for the WHAT (conventions); this skill is the HOW (the workflow process when development is happening).
---

# st-plugin-development

This is the **canonical development workflow** for the st-test-plugin. Any change to the plugin's files goes through these phases. The methodology is the codified version of what worked across the plugin's first 7+ iterations — when followed, it prevents the categories of problems we already paid for once.

The conventions themselves (hook patterns, subagent patterns, commit standards, etc.) live in [`docs/dev-conventions.md`](../../docs/dev-conventions.md). This skill describes **the workflow that applies those conventions**.

## When to invoke this skill

Whenever ANY of the following is true:

- The user wants to add a new skill, agent, slash command, hook, or script
- The user wants to modify, refactor, or remove an existing plugin artifact
- The user wants to update CLAUDE.md, README.md, CHANGELOG.md, settings.json, or `.gitignore`
- The user wants to fix a bug in the plugin's own code (not in the test target)
- The user wants to add new MCP integration, new permissions, or new memory entries

Do NOT invoke this skill for: running a sales tracking test (that's `sales-tracking-test-automation`), querying past reports (`/st-report`), or asking conceptual questions about how the plugin works.

## Phase 1: Pre-development checklist

Run through these BEFORE writing or editing any plugin file:

1. **Refresh conventions** — read [`docs/dev-conventions.md`](../../docs/dev-conventions.md) if it has been more than one session since you last loaded it.
2. **Check prior lessons** — `ls memory/lessons-learned/` and read any entry whose name matches the area you're touching. Re-learn nothing.
3. **Survey what exists** — for the area you're modifying (skills, agents, hooks, commands), list current files and skim their descriptions to detect:
   - Existing files that already cover this domain (duplicate risk)
   - Existing files that will need to know about your change (orphan risk)
4. **Identify the entry point** — every new feature must have ONE clear entry point: a skill description, a slash command, an agent trigger, or a hook event. If you can't name the entry point in one sentence, the design is wrong.

## Phase 2: Plan before implementing

For anything beyond a single-file 1-line edit:

1. **Write the plan in chat** with: list of files to add/modify, list of files to delete (if any), the compatibility risks, and the validation steps. Use TodoWrite when the plan has more than 3 steps.
2. **Get user approval** for non-trivial work. For obvious tiny changes (typo fix, single-line config update), skip approval.
3. **Decide whether to use subagents** based on Phase 3 below.

## Phase 3: Subagent decision

| Situation | Use |
|---|---|
| Multi-file feature, independent workstreams | `team-manager` spawning worker subagents |
| Need to find code / files by pattern | `Explore` agent (read-only, fast) |
| Question about Claude Code internals | `claude-code-guide` agent |
| Token / efficiency audit | `token-optimizer` agent (user-global, available everywhere) |
| Single-file edit you understand fully | No subagent — direct |

When delegating to team-manager:
- Give it the full structural context (current state, target state, constraints) in the brief
- List the worker breakdown explicitly — don't make team-manager re-derive it
- Specify which files each worker owns to prevent collisions
- Demand validation in the brief (JSON parse, YAML check, dry-run) — team-managers and workers skip validation when it's not asked for

## Phase 4: Anti-orphan / anti-duplicate / anti-workaround

These three rules are HARD and override any other consideration.

### No orphan files

A file is an orphan if nothing references it. Before adding a new file, ensure at least one of these is true:

- It is a **skill** → its name appears in CLAUDE.md or other skills via trigger context, AND it appears in the skill discovery (i.e., it's in `skills/<name>/SKILL.md`)
- It is an **agent** → its name appears in CLAUDE.md, another skill, or a hook command
- It is a **command** → it has clear user-facing trigger via slash command
- It is a **hook** → it is wired up in `hooks/hooks.json`
- It is a **script** (`hooks/<name>.sh`) → it is called by `hooks.json`
- It is a **memory entry** → it is indexed in `memory/MEMORY.md`
- It is **documentation** → it is linked from README.md or CLAUDE.md
- It is a **settings file** → it is at a path Claude Code or our hooks read

If none apply, do not create the file. If you've already created it, either wire it up or delete it.

### No duplicate features/data

Before adding a new skill, agent, command, hook, memory entry, or doc section:

- `grep -r "<the concept>" skills/ agents/ commands/ hooks/ memory/` to find existing coverage
- If the concept already exists somewhere, **extend that file** instead of creating a parallel one
- If two existing files cover overlapping ground, merge them as part of your change rather than adding a third
- Same for data: do NOT add the same fact (e.g., a market URL, a partner ID, a test credential) in two places — pick one source of truth and reference from elsewhere

### No workarounds

When something doesn't work as expected:

- Find the **root cause** (often by reading the binary at `/Users/murat.akkus/.local/share/claude/versions/<version>`, the live docs, or the actual error)
- Fix at the root, not at the symptom
- Do NOT add `try/except` to silence an error, hardcoded paths to dodge env var issues, or `--no-verify` to skip a failing hook
- If a real workaround is the only option (e.g., upstream bug), document it in `memory/lessons-learned/` with `**Workaround for upstream issue:**` clearly stated, including the upstream tracking link

## Phase 5: Implementation discipline

While writing the change:

1. **One commit = one logical change.** Resist the urge to fold unrelated cleanups into a feature commit.
2. **Stage specific files** (not `git add -A`) when committing manually — `git add` then commit. The auto-committer hook is allowed to use `-A` because it captures all pending session changes; humans should be precise.
3. **MCP tool names are lowercase** — `mcp__browseros__*`, NOT `mcp__browserOS__*`. The casing bug cost us 4 agent files in early development.
4. **`$CLAUDE_PLUGIN_ROOT` is the plugin's install path** — never use `$CLAUDE_PROJECT_DIR` for that purpose inside hooks/scripts.
5. **Hook commands are one line:** `bash "$CLAUDE_PLUGIN_ROOT/hooks/<name>.sh"` — full logic lives in the script file, never inline in JSON.
6. **Subagent `tools:` field is minimal** — list only the tools the agent actually uses, not the union of plausible tools.
7. **Non-interactive `claude -p` invocations** need both `--plugin-dir "$CLAUDE_PLUGIN_ROOT"` AND `--allowed-tools "Bash(<scope>) Read"`. Without the first, plugin subagents are invisible; without the second, the child hangs on permission prompts.
8. **Recursion guard** via env var for any hook that operates on the side effects of its own event (canonical example: the Stop hook running git operations that fire another Stop).

## Phase 6: Validation gate

After every meaningful edit, BEFORE declaring done:

- **JSON files:** `python3 -m json.tool <file>` exit 0 (`hooks.json`, `plugin.json`, `marketplace.json` if any, `settings.json`)
- **YAML frontmatter:** `head -10 <file>.md` and verify the `---` fences and required keys (`name`, `description`, optional `tools`, `model`, `type`)
- **Bash scripts:** `bash -n <script>.sh` exit 0
- **Dry-run** any new or modified hook script with the expected env vars set: `CLAUDE_PLUGIN_ROOT=/path bash hooks/<name>.sh` and inspect both stdout and the log file
- **Cross-reference check:** if you added `[[link]]` or markdown `[link](path)` references, confirm the target exists
- **Trust-but-verify subagent output:** when a subagent reports it did N things, list the actual files with `find` and spot-check

## Phase 7: Documentation update

After the change is implemented and validated, update wherever the change is user-visible or convention-altering:

| Change type | Update |
|---|---|
| New user-facing feature | `README.md` Features list |
| Any change worth tracking | `CHANGELOG.md` under the upcoming version |
| New convention or rule | `docs/dev-conventions.md` |
| Permission default change | `docs/setup-guide.md` — only if user-side action needed |
| New lesson learned during this change | `memory/lessons-learned/<slug>.md` + index entry in `memory/MEMORY.md` |
| New market-specific quirk discovered | `memory/market-quirks/<market>.md` + index entry |

**Do not bump `plugin.json` version** for every change — version bump is a separate, deliberate act tied to a logical release boundary.

## Phase 8: Commit

The auto-committer Stop hook will fire when the response ends. It uses Conventional Commits format with no AI attribution. If you want a different commit message than what auto-committer would generate, write the commit manually before the response ends:

```
git add <specific files>
git commit -m "<type>(<scope>): <subject under 70 chars>

<body explaining WHY this change was made, what motivated it, what was considered>"
```

- **`<type>`** = `feat | fix | docs | refactor | chore | test | style | perf`
- Never `--no-verify`, never `--amend` to a published commit, never force-push.
- No `Co-Authored-By: Claude`, no robot emoji. The human's git identity covers attribution.

## Phase 9: Post-development verification

Final check before saying done:

- `git status` — only the changes you intended are present, no leftover temp files, no untracked stale artifacts
- `find . -type f \( -name "*.swp" -o -name "*.bak" -o -name "*.tmp" -o -name "*~" \) -not -path "./.git/*"` — should return nothing
- The new files appear in the right place; no rogue files at the repo root or in `.claude-plugin/`
- The auto-commit's generated message accurately describes what changed (read it in the log/console after the response)

## Quick reference — common operations

### Add a new skill
1. `mkdir -p skills/<name>` → write `SKILL.md` with frontmatter (`name`, `description` with strong triggers, optional `compatibility`)
2. Decide if it should be auto-invoked (description style) or user-invoked (`disable-model-invocation: true`)
3. Test description triggers don't conflict with existing skills' triggers (grep existing descriptions)
4. Update README "Features" if user-facing

### Add a new agent
1. Write `agents/<name>.md` with frontmatter (`name`, `description`, `tools`, `model`)
2. Tools list MINIMAL
3. Description includes "MUST BE USED" / "Use PROACTIVELY" only if auto-routing is critical
4. Reference it from CLAUDE.md or a hook/skill so it's discoverable

### Add a new slash command
1. Write `commands/<name>.md` with `description`, `argument-hint`, `disable-model-invocation: true` if it should not auto-fire
2. Body describes what the command does step-by-step
3. Confirm no other command's name conflicts

### Add a new hook
1. Write `hooks/<name>.sh` — self-locating via `$0`, logs to `log/<name>.log`, follows the recursion-guard pattern if needed
2. `chmod +x` it
3. Add an entry in `hooks/hooks.json` with command `bash "$CLAUDE_PLUGIN_ROOT/hooks/<name>.sh"`
4. Validate JSON, validate bash syntax, dry-run
5. Update `.gitignore` if the hook generates artifacts that shouldn't be committed

### Modify an existing skill/agent
1. Read it fully before editing
2. If the change is significant (new section, behavior change), make sure consumers of this file (other skills, hooks, CLAUDE.md references) still align
3. Validate frontmatter after edit
4. If trigger phrases changed, re-test that auto-invocation still works as intended

## What this skill is NOT

- Not a substitute for [`docs/dev-conventions.md`](../../docs/dev-conventions.md) — that file holds the WHAT (rules). This skill is the HOW (process).
- Not for running tests — that's `sales-tracking-test-automation`.
- Not for memory writes — that's `st-memory`.
- Not for token efficiency audits — that's the global `token-optimizer` agent.

When in doubt about which file holds which information, default to: memory rules in `CLAUDE.md`, development conventions in `docs/dev-conventions.md`, user setup in `docs/setup-guide.md`, process in this skill, evidence in `memory/lessons-learned/`, history in `CHANGELOG.md`, user docs in `README.md`.
