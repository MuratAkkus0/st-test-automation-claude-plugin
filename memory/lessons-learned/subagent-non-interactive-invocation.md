---
name: subagent-non-interactive-invocation
description: When a hook spawns `claude -p` to invoke a plugin subagent, pass both `--plugin-dir` and `--allowed-tools` or the call will fail silently or hang
type: lesson
---

When a plugin hook spawns a non-interactive Claude session via `claude -p "..."` to invoke a plugin subagent, two flags are mandatory:

1. **`--plugin-dir "$CLAUDE_PLUGIN_ROOT"`** — the child session must load the plugin, otherwise plugin subagents are invisible. The parent's plugin context is NOT inherited.
2. **`--allowed-tools "Bash(<scope>) Read"`** — the child session is non-interactive and cannot prompt for permissions. Without this flag, the subagent's first Bash call hangs until timeout.

For an auto-commit hook spawning a git-focused subagent:

```bash
claude --plugin-dir "$CLAUDE_PLUGIN_ROOT" \
  --allowed-tools "Bash(git *) Read" \
  -p "Use the auto-committer subagent to commit and push all current changes." \
  --output-format text
```

**Why:** During this plugin's development, the Stop hook first ran a bare `claude -p "Use the auto-committer subagent..."`. The child Claude session reported "There's no `auto-committer` subagent available in this environment. Available types are: claude, claude-code-guide, Explore, general-purpose..." — only built-in agents were visible. Adding `--plugin-dir` fixed that, but the next iteration revealed the child was prompting for `git add` permission interactively and stalling; non-interactive sessions silently wait forever for a TTY that isn't there. Adding `--allowed-tools "Bash(git *) Read"` restricted what the subagent could do AND auto-approved its actual operations.

**How to apply:**

- Treat `claude -p` invocations from hooks as a sandboxed child process with no inherited context.
- Scope `--allowed-tools` to the minimum set the subagent actually needs. Prefer `Bash(git *)` over `Bash` to limit blast radius — even if the subagent goes rogue, it can only run git commands.
- If the subagent legitimately needs `Edit` or `Write`, add them explicitly: `--allowed-tools "Bash(git *) Read Edit Write"`.
- Don't use `--dangerously-skip-permissions` as a shortcut — the explicit allowlist is the same one-time effort and is much safer.
- Pair this with a recursion guard env var (see [[hook-script-log-pattern]]) so the child Claude's own Stop hook doesn't re-trigger the parent hook in a loop.
