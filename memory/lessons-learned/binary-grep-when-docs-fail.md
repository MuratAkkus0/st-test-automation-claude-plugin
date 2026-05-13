---
name: binary-grep-when-docs-fail
description: When Claude Code docs are ambiguous or contradict observed behavior, grep the installed binary for ground truth instead of guessing
type: lesson
---

For Claude Code framework internals (plugin schema, env vars, source types, hook events, valid CLI flags), if the official docs and observed behavior disagree, the installed binary is the authoritative source.

The binary lives at `/Users/murat.akkus/.local/share/claude/versions/<version>` and is a Mach-O executable (single Bun-compiled file on macOS). Extract embedded strings:

```bash
strings /Users/murat.akkus/.local/share/claude/versions/2.1.140 | grep -oE 'CLAUDE_[A-Z_]+' | sort -u
strings <binary> | grep -E 'error.*source type'
strings <binary> | grep -oE 'pluginSource[^"]*'
```

**Why:** Twice during this plugin's development, the official docs led to wasted hours:

1. The `marketplace.json` `source` field — docs said `"./..."` strings work for local paths. Empirically it failed with a "source type not supported" error on `"./"` AND on `"./plugins/X"`. Grepping the binary found the actual parser switch statement accepted only `"npm"`, `"github"`, `"url"`, `"git-subdir"` object discriminators plus arbitrary string paths. The real fix was the missing `author` field in the plugin entry — completely unrelated to the misleading error message the user saw.

2. The `$CLAUDE_PLUGIN_ROOT` env var — never mentioned in `create-plugins-doc.md`, but `strings` on the binary listed it among 200+ env vars Claude Code defines. Without binary inspection we'd have been stuck using `$CLAUDE_PROJECT_DIR`, which resolves to the parent directory when Claude is launched outside the plugin folder.

**How to apply:**

- After reading the official docs, if a plugin-internals question remains unanswered or behavior contradicts the docs, run `strings <binary>` with a targeted grep before guessing.
- Look for: env var names (`CLAUDE_*`), error message strings (paste an observed error and find its source), schema literals (`literal("name")` patterns from Zod schemas), and config keys.
- Don't assume training-data knowledge of Claude Code internals — the framework moves fast and binary strings are the only stable ground truth across versions.
- Always include the version in your evidence: `2.1.140` may differ from `2.2.x`.

Related: [[plugin-dev-workflow]] (the `--plugin-dir` vs marketplace lesson came from this same investigation).
