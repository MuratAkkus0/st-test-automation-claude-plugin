# Part 3: Required user setup

This plugin uses the **BrowserOS** and **Atlassian (Jira)** MCP servers heavily — every browser action and Jira call routes through them. Without pre-approval, each tool invocation triggers a permission prompt, which makes the automated sales-tracking-test workflow unusable.

## What to do

Add these entries to `~/.claude/settings.json` under `permissions.allow`:

```json
{
  "permissions": {
    "allow": [
      "mcp__browseros__*",
      "mcp__claude_ai_Atlassian__*"
    ]
  }
}
```

## Forward-compatibility note

The plugin also ships these defaults in its own `settings.json` at the plugin root:

```json
{
  "permissions": {
    "allow": [
      "mcp__browseros__*",
      "mcp__claude_ai_Atlassian__*"
    ]
  }
}
```

Today, Claude Code's plugin-settings spec only honors the `agent` and `subagentStatusLine` keys (see `hepler-documantations/create-plugins-doc.md`), so the plugin-shipped `permissions` block is ignored — the manual step above is required. Once plugin-level permissions are supported, the manual entry becomes optional and the plugin will auto-apply these defaults on install.

## Trade-off

Auto-approving `mcp__browseros__*` and `mcp__claude_ai_Atlassian__*` means those tool prefixes never prompt in any Claude session — not just plugin sessions. For this plugin's use case this is intentional: both are domain-specific servers that only fire when explicitly called.
