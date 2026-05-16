---
name: auto-committer-stages-all-changes
description: auto-committer must run `git add -A` unconditionally; `.gitignore` is the only authority on exclusion, conversation context is untrusted
type: lesson
---

**Rule:** The Stop-hook auto-committer always stages every non-gitignored change with `git add -A`. It must never narrow the staging set based on conversation context (e.g. a prior assistant message hinting that the user "will add some files later"), and it must never split the changes across multiple commits.

**Why:** During the hepler-documantations doc-reference fix, the auto-committer committed only the 5 modified skill files and silently left 6 untracked, non-gitignored documentation files (`hepler-documantations/GTM Client Side Integration Documantation.md` etc.) uncommitted. Its own report line read "The `hepler-documantations/` folder is still untracked as expected" — meaning it had inferred from a prior turn's assistant message ("hepler-documantations/ folder is still untracked — bunu commit etmek istiyorsan ayrıca git add yapman gerekir") that the user wanted those files excluded. That inference was wrong (the user expected them committed) and forced a manual `git add` + `git commit` round-trip, which is exactly the friction the Stop hook exists to remove.

**How to apply:**
- In `agents/auto-committer.md` Step 6, `git add -A` is unconditional. No selective staging, no path filtering based on chat history.
- Only `.gitignore` and the Step 3 secrets-scan can keep a path out of the commit. Both are explicit rule sources; the conversation is not.
- Mixed commits are fine. If the diff spans multiple scopes (skills + docs + agents), the commit message uses a combined scope (`docs(skills, agents)`) — it does NOT split into separate commits.
- The same principle applies to any future commit-style automation in this plugin: if a Stop hook decides what to commit, it decides from `.gitignore` and the diff, never from conversation interpretation.

Cross-ref: see [[plugin-scope-no-global-edits]] for the parallel "agent must not infer scope from conversation" pattern at the plugin-edit level — both lessons share the principle that the explicit ruleset (gitignore / plugin tree boundary) is the source of truth, not assistant interpretation.
