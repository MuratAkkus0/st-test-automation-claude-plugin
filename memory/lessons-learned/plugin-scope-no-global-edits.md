---
name: plugin-scope-no-global-edits
description: When invoked under /st-plugin-development, never edit files outside the plugin root — no ~/.claude/, no /etc/, no other repos. All changes stay within /Users/murat.akkus/Desktop/claude-plugins/.
type: lesson
---

When `/st-plugin-development` is invoked, "plugin scope" means the only writable surface is **inside `/Users/murat.akkus/Desktop/claude-plugins/`**. Editing `~/.claude/settings.json`, `~/.config/`, `/etc/`, a sibling repo, or any other path outside the plugin root is a scope violation — even when the change would technically help future plugin work (e.g. adding permissions that the plugin's bash commands need).

The user wanted permissions that would make future ST-test runs prompt-free. The instinct was to add them to `~/.claude/settings.json` because that's where the existing BrowserOS wildcards lived. That instinct was wrong: the request came in *under* a plugin-development command, which scopes the work to the plugin, not the user's global config.

**Why:** During the 2026-05-15 MeinMassivholz DE run, the user invoked `/st-plugin-development` and asked for permissions to stop being prompted. The agent edited `~/.claude/settings.json` twice (adding 19 Bash patterns). The user pushed back: "Your task was only doing some developments and edits IN plugin scope. But you did it in global scope." Two `Edit` calls landed on a path that the plugin-development skill has no authority over. Even though the user benefitted from the new permissions, the trust break was structural — a "plugin development" command modified files the user expected to remain untouched.

**How to apply:**

1. When invoked under `/st-plugin-development` (or any phase skill that scopes to the plugin), the only edit surface is `/Users/murat.akkus/Desktop/claude-plugins/`. Treat `~/.claude/`, `~/.config/`, `/etc/`, `/usr/local/`, and any sibling repo as read-only.

2. If the user's request *seems* to require a global edit (e.g. "add permissions so you don't prompt"), the correct response is one of:
   - **Put the change inside plugin scope** if possible (e.g. add a `.claude/settings.local.json` at the plugin or project root — the project root `/Users/murat.akkus/Desktop/claude-plugins/.claude/settings.local.json` is acceptable because it's still inside the workspace the plugin lives in).
   - **Or surface the scope conflict and ask** — "Permissions live in `~/.claude/settings.json`, which is outside plugin scope. Do you want me to edit your global config (one-off, outside the plugin), or should we add a project-level `.claude/settings.local.json` instead?" — and wait for direction.

3. `Read` on outside-scope files is fine when needed for context (e.g. checking what permissions are already granted). `Edit` and `Write` are not.

4. This rule generalises: any scoped skill invocation creates a fence. `/sales-tracking-test-automation` writes only into `st-test-reports/{Partner}/{MARKET}/<timestamp>/`. `/st-memory` writes only into `memory/`. `/st-plugin-development` writes only into the plugin tree. The fence is part of the contract — crossing it is what makes the user feel the agent went off-task.
