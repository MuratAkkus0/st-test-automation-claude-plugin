---
description: Show the most recent sales tracking test report (or list recent reports). Reads from the workspace folder `/sessions/.../mnt/Sales Tracking/st-test-reports/`. Use after running `/st-test` to re-display the report files without re-running the test.
argument-hint: [partner] [market]
disable-model-invocation: true
---

# /st-report — Show recent Sales Tracking reports

You are looking up sales tracking test reports already written to the workspace folder.

**Arguments passed (`$ARGUMENTS`):** `$ARGUMENTS`

## Step 1 — Locate the reports folder

Reports are written to `/sessions/.../mnt/Sales Tracking/st-test-reports/`. The exact session-prefix path varies. List recent `.md` files there sorted by modification time, newest first.

## Step 2 — Filter (optional)

If `$ARGUMENTS` contains a partner name and/or market code, filter the file list by filename pattern:
- Filename format: `{partner_name}_{market}_{YYYYMMDD_HHMMSS}.md`
- Partner is the part before the first underscore; market is the next two letters; timestamp is the rest.

If no arguments are passed, show the 5 most recent reports across all partners.

## Step 3 — Present

For each matching report set (the comprehensive `.md`, the `_jira.md` if present, and the `_email.txt` if present), print a single line per file with:
- File name
- Last modified timestamp
- A one-line summary derived from the file header (partner, market, overall PASS/FAIL)

Then offer to display the full body of any one of them when the user picks.

Do not modify or delete any report files. This command is strictly read-only.
