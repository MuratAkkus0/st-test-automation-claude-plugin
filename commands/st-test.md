---
description: Run a sales tracking test for a Moebel.de partner. Primary entry point of the st-test-plugin. Parses `<partner> <market>` from arguments (plus optional Jira ticket, colleague tag, expected PARTNER_KEY, partner email) and dispatches to the sales-tracking-test-automation orchestrator skill.
argument-hint: <partner> <market> [JIRA-TICKET] [@colleague] [partner-key UUID] [partner-email]
disable-model-invocation: true
---

# /st-test — Run a Sales Tracking test

You are running the **st-test-plugin** sales tracking test workflow.

**Arguments passed (`$ARGUMENTS`):** `$ARGUMENTS`

## Step 1 — Parse the arguments

Extract from `$ARGUMENTS`:

- **Partner name** (required) — the first word/identifier. Preserve capitalisation exactly as typed (e.g., `IKEA`, `Porta`, `XXXLutz`).
- **Market code** (required) — one of `de`, `fr`, `nl`, `at`, `ch`, `es`, `it`, `pl`, `gb`. Also accept the common aliases the user might type (`germany`, `austria`, `uk`, etc.) and normalise to the two-letter code.
- **Jira ticket ID** (optional) — any token matching `[A-Z]+-\d+` (e.g., `DSA-1234`, `ACM-3051`).
- **Colleague tag** (optional) — any token starting with `@` (e.g., `@Steffen`, `@Jara`, `@"Michael Hans"`). Strip the leading `@` for processing; the orchestrator re-adds a single `@` when rendering.
- **Expected PARTNER_KEY** (optional) — any token matching the UUID pattern `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`, or any value the user labels as "partner key", "expected key", "correct key", "soll-key", "PARTNER_KEY".
- **Partner email** (optional) — any token matching the RFC-5322-ish pattern `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}` that is NOT one of the moebel.de internal test identities (`partner@moebel.de`, `partenaire@meubles.fr`) and NOT a `@moebel.de` / `@meubles.fr` / `@meubelo.nl` etc. internal colleague address.

If the partner name or market code is missing, ask the user to clarify before proceeding. Do not invent either value.

## Step 2 — Dispatch to the orchestrator

Invoke the **`sales-tracking-test-automation`** skill. That skill is the orchestrator — it knows how to drive the phase skills in order (`st-phase-0-pre-test-setup` → `st-phase-1-navigation-and-moeclid-capture` → `st-phase-2-base-part-verification` → `st-phase-3-purchase-flow` → `st-phase-4-conversion-verification` → `st-report-generation`).

Pass the parsed inputs through. Do not run the phase skills yourself — the orchestrator handles sequencing, stop conditions, and report generation.

## Step 3 — Confirm any side-effect actions before they happen

The orchestrator will not post to Jira or open an Outlook draft without an explicit confirmation from the user. If the user provided a Jira ticket ID or a partner email, you will see a preview prompt mid-flow — surface it as written and wait for the user's confirmation. Do not auto-confirm. Do not skip the preview.
