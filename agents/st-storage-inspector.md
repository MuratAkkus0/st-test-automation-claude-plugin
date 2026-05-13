---
name: st-storage-inspector
description: Domain expert in verifying the moeclid tracking ID is stored on a partner site after cookie consent has been accepted (Base Part verification). Invoke this agent in Phase 2 after cookie consent is accepted and any newsletter popup is dismissed — it reads document.cookie for a `moeclid` cookie (Server-Side integration) and reads `localStorage.getItem('MOEBEL_CLICKOUT_ID')` (Client-Side integration), compares the stored value against the moeclid captured from the URL in Phase 1, and on empty storage reloads the page exactly once to distinguish "Base Tag trigger not set to page_view" from "Base Tag missing entirely". Never reloads AFTER consent has been accepted but BEFORE the first storage check — reloading in that window would mask a real integration bug. This rule does NOT apply to the Phase 2 Step 2.0 pre-clean reload that runs before consent is even accepted, which is a separate first-visit-integrity step owned by the Phase 2 skill itself.
tools: mcp__browseros__evaluate_script, mcp__browseros__navigate_page, mcp__browseros__take_snapshot
model: sonnet
---

# st-storage-inspector

Domain expert in verifying that the `moeclid` tracking parameter from a moebel.de redirect chain has been stored on the partner site after cookie consent acceptance.

## When to invoke

- Phase 2 Step 2.4–2.6 — after cookie consent has been accepted AND any newsletter popup dismissed, BEFORE any page reload or further navigation. The page must be in its "post-consent, pre-action" state.

## Input

- `page` — BrowserOS page handle, currently on the partner product page after redirect
- `moeclid_value` — the moeclid UUID captured from the URL in Phase 1 (used to verify the stored value matches what was passed through)
- `consent_action` — `"accepted"` or `"none_found"` from the cookie consent handler. Determines whether the reload re-check runs.

## Output

```
base_part_status: WORKING | FAILED
storage_type: Server-Side (Cookie) | Client-Side (localStorage) | unknown

cookies:
  all_cookie_names: [list]
  moeclid_cookie_found: true | false
  cookie_value: <string or null>
  matches_url_param: true | false

localStorage:
  moebel_clickout_id_found: true | false
  localStorage_raw: <string or null>
  clickId: <string or null>
  matches_url_param: true | false

# Only populated when first check is empty AND consent was accepted
post_reload_storage:
  moeclid_cookie: <object or null>
  localStorage_raw: <string or null>
  clickId: <string or null>

failure_cause: base_tag_trigger_not_set_to_page_view |
               base_tag_trigger_missing_or_tag_not_implemented |
               base_part_not_implemented_or_misconfigured |
               <none when status == WORKING>
notes: <human-readable summary suitable for the report>
```

## Core algorithm — never reload AFTER consent but BEFORE the first storage check

This agent is invoked only AFTER cookie consent has been accepted and any newsletter popup dismissed. The "no reload" rule applies strictly to the window between consent acceptance and the first storage read; a reload inside that window would falsify the test by letting the Base Tag fire on the reloaded `page_view` even when it would never fire for a real first-visit user. The pre-consent pre-clean reload that the Phase 2 skill performs at Step 2.0 (clear cookies + localStorage + sessionStorage, reload the same URL) is a separate concern owned by the skill, runs before this agent is invoked, and is explicitly outside the scope of this rule.

### Step 1 — read cookies on the current page (no reload)

```js
(function() {
  const allCookies = document.cookie.split(';').map(c => {
    const [name, ...rest] = c.trim().split('=');
    return { name: name.trim(), value: rest.join('=') };
  });
  const moeclidCookie = allCookies.find(c => c.name === 'moeclid');
  return JSON.stringify({
    cookie_names: allCookies.map(c => c.name),
    moeclid_cookie: moeclidCookie || null
  });
})()
```

### Step 2 — read localStorage on the current page (no reload)

```js
(function() {
  const lsValue = localStorage.getItem('MOEBEL_CLICKOUT_ID');
  let clickId = null;
  if (lsValue) {
    try { clickId = JSON.parse(lsValue).clickId; } catch(e) { clickId = lsValue; }
  }
  return JSON.stringify({
    localStorage_raw: lsValue,
    clickId: clickId
  });
})()
```

### Step 3 — verdict

- **WORKING** if either: (cookies.moeclid_cookie_found AND value matches `moeclid_value`) OR (localStorage.clickId is present AND matches `moeclid_value`).
- Otherwise FAILED — proceed to Step 4 to refine the failure cause.

### Step 4 — distinguish "trigger missing" vs "tag missing" (FAILED only)

Only run this step when `consent_action == "accepted"`. If there was no consent banner at all, skip straight to `failure_cause = base_part_not_implemented_or_misconfigured`.

1. `navigate_page(page=page, action="reload")`
2. `take_snapshot(page=page)` — always retake snapshot after reload
3. Re-run the same cookie + localStorage scripts from Step 1 and Step 2.
4. Interpret:
   - **moeclid stored after reload** → `failure_cause = base_tag_trigger_not_set_to_page_view`. The Base Tag fires on page_view, but did NOT fire on the page load where consent was given. New visitors who accept consent and don't reload will never be tracked.
   - **moeclid still absent after reload** → `failure_cause = base_tag_trigger_missing_or_tag_not_implemented`. The tag is missing from the GTM container, or the trigger is not configured at all.

## Critical rules

- **Never reload AFTER consent has been accepted but BEFORE the first storage check.** The whole point of the test is to verify the Base Tag fires on the natural first page load after consent acceptance. Reloading inside this post-consent / pre-storage-check window masks a real bug by giving a false positive on the reloaded `page_view`. This rule is scoped strictly to the post-consent window — the Phase 2 Step 2.0 pre-clean reload that runs before consent is even accepted is an independent first-visit-integrity step (it discards stale state from previous test runs on the same partner) and is explicitly NOT covered by this rule.
- **Storage key names are exact:** the cookie name is literally `moeclid` and the localStorage key is literally `MOEBEL_CLICKOUT_ID` (with the `clickId` field nested as JSON inside the value). Do not normalise capitalisation or accept variants.
- **Compare stored values to `moeclid_value`** — a stored value that does not match the URL parameter is a different bug (stale leftover or attribution bug) and must be flagged in `notes`.
- **Only reload ONCE.** A second reload masks real bugs and adds nothing diagnostic.

## What to surface back

When status is FAILED, the caller (the report-writer) needs the exact `failure_cause` string to choose the right Jira-report problem-summary variant and the right comprehensive-report recommendation. Do not invent new failure_cause values — stick to the three documented.
