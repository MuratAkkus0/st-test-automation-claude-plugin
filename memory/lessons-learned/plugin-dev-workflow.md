---
name: plugin-dev-workflow
description: For personal/local plugin development, prefer --plugin-dir over marketplace setup
type: lesson
---

For Claude Code plugin development, when the user wants "personal use only" / "just for this project" / "not global" — recommend `claude --plugin-dir <path>` first, NOT a local marketplace.

**Why:** During an early plugin build the assistant jumped straight to marketplace + `.claude-plugin/marketplace.json` + `.claude/settings.local.json` setup for a project-scoped install. Significant time was then spent debugging `marketplace.json` source-field bugs (`./` vs `"."`, plugin-must-be-in-subdirectory, missing `author` field) — all of which would have been avoided with `--plugin-dir`. The official docs state the documented path for personal dev is simply `claude --plugin-dir ./my-plugin`. Marketplace is for sharing and distribution, not local iteration.

**How to apply:**
- If the user says "just for me" / "local test" / "personal" / "not global" / "this project only" → `--plugin-dir` flag (single command, no JSON wrangling).
- If the user says "share with team" / "distribute" / "marketplace" / "git repo for others" → then a marketplace.json setup is justified.
- For development iteration: `/reload-plugins` picks up changes without restart.
- When in doubt about plugin internals (source types, schema, structure), read the official docs at `code.claude.com/docs/en/plugins` before recommending an approach — training-data recall on plugin specifics is unreliable.
