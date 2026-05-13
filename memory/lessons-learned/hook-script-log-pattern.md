---
name: hook-script-log-pattern
description: Every plugin hook should follow the script + log + gitignore pattern rather than inline bash in hooks.json
type: lesson
---

For every new hook in a Claude Code plugin, use this three-piece pattern instead of cramming bash into `hooks.json`:

1. **`hooks/<name>.sh`** — executable bash script with the actual logic. Self-locating via `$0`/`dirname` so it works regardless of `pwd`.
2. **`log/<name>.log`** — one-line minimal log entry per fire (timestamp + fired/skipped + key state).
3. **`hooks.json` command** — just `bash "$CLAUDE_PLUGIN_ROOT/hooks/<name>.sh"`.

The `log/` directory is gitignored via `.gitignore` so auto-commit doesn't self-loop on its own log writes.

**Why:** During this plugin's development we first wrote complex one-liners directly into `hooks.json` (multiple `&&`/`||` chains, env var checks, `claude -p` invocations, escaped quotes). They were unreadable, hard to test in isolation, and silent when they failed — for example, an empty `cd ""` would succeed under POSIX rules and run git operations in the wrong directory. Extracting to `hooks/auto-commit.sh` exposed each branch as separate test points and the explicit log file revealed which guard had short-circuited.

**How to apply:**

- Never write more than a single `bash "$VAR/hooks/<name>.sh"` line as a hook command in JSON.
- The script logs *entry state* (relevant env vars, working directory) and *outcome* (fired vs which guard skipped). For verbose nested-process hooks (like one that spawns `claude -p`), also capture the child's output.
- Verify the hook end-to-end with a dry-run setting the expected env vars before relying on it in real Claude sessions: `CLAUDE_PLUGIN_ROOT=/path bash hooks/<name>.sh`, then `tail log/<name>.log`.
- For hooks that mutate the repo (commit, push, file edits), include a recursion guard env var that the script checks on entry and the hook command exports when invoking child processes — see [[subagent-non-interactive-invocation]].

Related: [[plugin-dev-workflow]] (when to set up hooks at all vs simpler approaches).
