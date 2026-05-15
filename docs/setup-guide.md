# Part 3: Required user setup

This plugin uses the **BrowserOS** and **Atlassian (Jira)** MCP servers heavily — every browser action and Jira call routes through them. Without pre-approval, each tool invocation triggers a permission prompt, which makes the automated sales-tracking-test workflow unusable.

## What to do

Add these entries to `~/.claude/settings.json` under `permissions.allow`. The first two (MCP wildcards) are the absolute minimum — without them, every browser action and every Jira call prompts. The rest cover the bash utilities and file-write paths the test phases use; without them you'll get spot prompts during a run but the test still completes.

```json
{
  "permissions": {
    "allow": [
      "mcp__browseros__*",
      "mcp__claude_ai_Atlassian__*",

      "Bash(mkdir -p st-test-reports/**)",
      "Bash(date *)",
      "Bash(python3 *)",
      "Bash(until *)",
      "Bash(ls *)",
      "Bash(jq *)"
    ]
  }
}
```

`Read`, `Write`, and `Edit` rules for the plugin's own subdirectories (`st-test-reports/`, `memory/`, etc.) are not needed in `~/.claude/settings.json` — Claude Code allows file operations inside the plugin tree by default once the plugin is installed via `--plugin-dir`.

## Forward-compatibility note

The plugin also ships the full permission set in its own `settings.json` at the plugin root (`st-test-plugin/settings.json`), including the `Read`/`Write`/`Edit` rules for the plugin's subdirectories. The contents there are the canonical source of truth for "what permissions does an ST-test run actually use".

Today, Claude Code's plugin-settings spec only honors the `agent` and `subagentStatusLine` keys at plugin root (see `hepler-documantations/create-plugins-doc.md`), so the plugin-shipped `permissions` block is ignored — the manual step above is required. Once plugin-level permissions are supported by Claude Code, the manual entry becomes optional and the plugin will auto-apply these defaults on install.

## Trade-off

Auto-approving `mcp__browseros__*` and `mcp__claude_ai_Atlassian__*` means those tool prefixes never prompt in any Claude session — not just plugin sessions. For this plugin's use case this is intentional: both are domain-specific servers that only fire when explicitly called.
