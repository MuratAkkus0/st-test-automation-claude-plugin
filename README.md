# st-test-plugin

End-to-end sales tracking (ST) test automation for the Moebel.de family of furniture e-commerce portals. Verifies moeclid tracking, Base Part, and Conversion Part across 9 markets (DE, FR, NL, AT, CH, ES, IT, PL, GB) using BrowserOS for browser automation.

## What it does

Given a partner name and market code, the plugin runs a full test:

1. **Phase 0** — clears browser state, opens the portal, accepts CMP
2. **Phase 1** — finds the partner on the portal, opens a product, captures the `moeclid` from the redirect chain
3. **Phase 2** — accepts partner-site cookie consent, verifies `moeclid` is stored in cookies/localStorage
4. **Phase 3** — adds the product to the cart, fills checkout, submits the order
5. **Phase 4** — verifies the sales API call fired with the right `PARTNER_KEY` and payload
6. **Phase 6** — generates three deliverables: a comprehensive Markdown report, a German Jira draft, and (optional) an English partner email

## Installation

```bash
claude --plugin-dir /path/to/st-test-plugin
```

For permission setup (so the plugin doesn't ask for approval on every BrowserOS / Jira call), see [`docs/setup-guide.md`](./docs/setup-guide.md).

## Usage

### Run a test

```
/st-test <partner> <market> [JIRA-TICKET] [@colleague] [partner-key UUID] [partner-email]
```

Examples:
```
/st-test IKEA de
/st-test Naturwohnen de ST-1234 @colleague
test IKEA in germany
```

### View past reports

```
/st-report [partner] [market]
```

Reads from `st-test-reports/<Partner>/<Market>/`.

### Post existing Jira draft

```
/st-jira-post <JIRA-TICKET> [path-to-_jira.md] [@colleague]
```

Use when `/st-test` was run without a ticket ID and you want to post the existing draft later.

## Features

- **10 modular skills** — orchestrator + market reference + 5 phase skills + report generation + memory management (`st-memory`) + development workflow enforcer (`st-plugin-development`)
- **5 specialist subagents** — cookie consent handler, partner finder, storage inspector, report writer, auto-committer
- **3 slash commands** — `/st-test`, `/st-report`, `/st-jira-post`
- **3 hooks** — session greet, memory injection (SessionStart) + auto-commit (Stop)
- **Plugin-scoped memory** with auto-write for lessons learned, market quirks, and user preferences
- **Auto-commit on response end** — Conventional Commits, no AI attribution, recursion-safe
- **9 supported markets** — `de fr nl at ch es it pl gb`
- **Permission defaults** for BrowserOS and Atlassian MCP servers

## Structure

```
st-test-plugin/
├── .claude-plugin/plugin.json        plugin manifest
├── settings.json                     plugin-level permission defaults (forward-compat)
├── CLAUDE.md                         plugin memory rules (Part 1)
├── docs/
│   ├── dev-conventions.md            development conventions (Part 2)
│   └── setup-guide.md                required user permission setup (Part 3)
├── agents/                           5 specialist subagents
├── commands/                         3 slash commands
├── hooks/                            3 hooks + 3 shell scripts
├── skills/                           10 skills (orchestrator + 7 phase + memory + dev-workflow)
├── memory/                           plugin-scoped memory (lessons, quirks, personal)
├── st-test-reports/                  generated test reports (auto-created per run)
├── log/                              hook logs (gitignored)
└── hepler-documantations/            local snapshot of official Claude Code plugin docs
```

## Dependencies

| Dependency | Purpose | Required? |
|---|---|---|
| Claude Code 2.1.140+ | Runtime | Yes |
| BrowserOS MCP server | Browser automation | Yes — test cannot run without it |
| Atlassian MCP server | Direct Jira posting (Phase 6 Step 6.5) | Optional — drafts are written to disk regardless |

## Development

- See [`docs/dev-conventions.md`](./docs/dev-conventions.md) for plugin development conventions (structure, hooks, subagents, testing, commits).
- See [`skills/st-plugin-development/SKILL.md`](./skills/st-plugin-development/SKILL.md) for the development workflow that enforces those conventions.
- See [CHANGELOG.md](./CHANGELOG.md) for version history.
- See `memory/lessons-learned/` for evidence-backed lessons captured during development.

## Repository

`MuratAkkus0/st-test-automation-claude-plugin`
