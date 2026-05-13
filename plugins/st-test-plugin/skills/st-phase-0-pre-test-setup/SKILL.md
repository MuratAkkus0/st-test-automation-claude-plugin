---
name: st-phase-0-pre-test-setup
description: Phase 0 of the sales tracking test. Use this skill when starting a new ST test run for a Moebel.de partner — it loads BrowserOS tools, picks the portal URL for the market, loads the market's test identity, clears stale browser state (cookies, localStorage, history) on both the portal and partner domains, opens the portal, and accepts the portal's own custom CMP banner using a layered detection strategy (a11y snapshot → TreeWalker text-scan → retry after hydration). Skipping this phase silently masks first-visit behaviour in Phase 2 and can cause partner-redirect 404s. Run before Phase 1.
compatibility: claude-code
---

# Phase 0: Pre-Test Setup

This phase prepares the browser session so Phase 1's first navigation behaves like a true first-visit. It is non-optional — skipping it produces false-positive Base Part results and can cause partner-redirect 404s on the portal's own domain.

**1. Load BrowserOS MCP tools**
```
Use ToolSearch to load BrowserOS tools:
query="mcp__browserOS__new_page,mcp__browserOS__navigate_page,mcp__browserOS__take_snapshot,mcp__browserOS__take_screenshot,mcp__browserOS__evaluate_script,mcp__browserOS__click,mcp__browserOS__search_dom"
```

**2. Determine portal URL from market code**

Use the `PORTAL_URLS` table from the `st-market-reference` skill.

**3. Load market-specific test data**

Use the per-market test identities from the `st-market-reference` skill. The same email rules apply: ALWAYS use the market's designated email — never invent, generate, or modify it.

**4. Initialize report structure**
Create a dictionary/object to store all test results as you progress through phases.

**5. Browser setup:**
- Use `mcp__browserOS__new_page` to open a fresh tab for each test
- Note: Tests should be run from Office WiFi/VPN for proper "internal traffic" invalidation

**6. Clear browser state for both the portal and the partner domain (mandatory)**

Stale `CookieConsent` cookies and `MOEBEL_CLICKOUT_ID` localStorage entries from a previous test run will silently mask real first-visit behaviour in Phase 2 — the moeclid will appear to be stored "on first page load" when in fact it's a leftover from yesterday. Always clear browser state before starting.

```python
# 1) Clear global browser history (covers all domains, recent and historical)
delete_history_range(startTime=0, endTime=99999999999999)

# 2) For each domain we'll touch (portal + partner's main domain when known),
#    open it once, clear cookies and storage, then close the tab.
for domain in [PORTAL_URLS[market_code], partner_domain_if_known]:
    page = new_page(url=domain, background=False)
    evaluate_script(page=page, expression="""
    (function() {
      // Clear cookies on this domain (best-effort — HttpOnly cookies cannot be removed via JS,
      // but session/CMP cookies that drive consent state always can)
      document.cookie.split(';').forEach(c => {
        const eq = c.indexOf('=');
        const name = eq > -1 ? c.substr(0, eq).trim() : c.trim();
        const host = window.location.hostname;
        ['/', '/' + host, host, '.' + host].forEach(d => {
          document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/;domain=' + d;
        });
        document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/';
      });
      localStorage.clear();
      sessionStorage.clear();
    })()
    """)
    close_page(page=page)
```

The partner's main domain is usually not known yet at Phase 0 (it's only revealed after the moebel.de redirect chain in Phase 1), so for now clear at least the portal domain. Once Phase 1 has resolved the partner domain, repeat the clear on that domain too if any state was set during the redirect (CookieConsent, etc.) — this is the second clear, before the consent acceptance and storage check in Phase 2.

**7. Accept the portal's own cookie consent BEFORE clicking any partner redirect (mandatory)**

The moebel.de family of portals (and their localised variants meubles.fr, meubelo.nl, etc.) gate parts of their redirect endpoints behind their own cookie consent. If you click a partner redirect link before the portal's CMP consent has been accepted, the redirect chain may strip `partnerId`/`partnerName` parameters during processing and land on a 404 page on the portal's own domain instead of bouncing to the partner. This was the root cause of the "Schlafenwelt 404" we hit on 2026-04-27 — there was no fallback, just an internal portal bug visible only to consent-not-accepted visitors (i.e., new visitors arriving fresh).

**⚠️ Critical detection note (verified 2026-05-11 with Kadima DE):**
The moebel.de family of portals uses a **custom in-house CMP**, not Cookiebot / Usercentrics / OneTrust / Sourcepoint / Didomi / etc. It exposes **no CMP global** on `window` (no `Cookiebot`, no `UC_UI`, no `OneTrust`), the banner has **no `id`**, and its CSS classes are **generic** (e.g. `button.button-primary` for the accept button). It is also rendered late via React/Next.js hydration, so it is usually NOT in the accessibility tree on the very first snapshot after `new_page` — meaning `take_snapshot` alone will silently miss it on the first try. Skipping the banner is silently catastrophic: the next click on a partner redirect can 404 (Schlafenwelt) or load alternative-shop products from other partners (Kadima), and the test will look like it's running on a clean page when it isn't.

Detection must therefore be **layered**: (1) wait briefly for hydration, (2) try `take_snapshot`, (3) on miss, fall back to a TreeWalker text-scan that looks for a visible button whose text exactly matches one of the market's accept keywords. The TreeWalker fallback is mandatory for moebel.de-family portals and is also the most robust general fallback for any partner page later in the test.

Use the `ACCEPT_KEYWORDS` table from the `st-market-reference` skill.

```python
import time

# Open the portal landing page (already opened during the clear-state step above)
portal_page = new_page(url=PORTAL_URLS[market_code], background=False)

# Give React/Next.js ~1.5s to hydrate so the custom CMP has time to mount.
# The moebel.de family CMP is not in the DOM at first paint; without this wait
# the snapshot AND the TreeWalker fallback will both miss it on the first try.
time.sleep(1.5)

# Accept-button keywords per market — see st-market-reference for the full ACCEPT_KEYWORDS table.
keywords = ACCEPT_KEYWORDS[market_code]

# Layer 1 — accessibility-tree snapshot (cheap, works for most CMPs)
consent_action = None
snapshot = take_snapshot(page=portal_page)
accept_id = find_accept_button_in_snapshot(snapshot, keywords)  # match by text
if accept_id is not None:
    click(page=portal_page, element=accept_id)
    consent_action = "accepted_via_snapshot"

# Layer 2 — TreeWalker text-scan in the live DOM. Run this whenever the
# snapshot did not surface a match. This is the canonical method for custom
# CMPs with generic classes and no consent-named markers (e.g. moebel.de family).
if consent_action is None:
    click_result = evaluate_script(page=portal_page, expression=f"""
    (function() {{
      const KEYWORDS = {json.dumps(keywords)};
      // TreeWalker scans every element including late-mounted React modals
      const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT, null);
      let node;
      while ((node = walker.nextNode())) {{
        // Only clickable element types — button, a, role=button
        const tag = node.tagName;
        if (tag !== 'BUTTON' && tag !== 'A' && node.getAttribute('role') !== 'button') continue;
        // Must be visible to the user (rules out hidden CMP placeholders)
        if (node.offsetParent === null) continue;
        const txt = (node.textContent || '').trim().toLowerCase();
        if (!txt || txt.length > 60) continue;
        if (KEYWORDS.includes(txt)) {{
          node.click();
          return 'clicked: ' + txt;
        }}
      }}
      return 'no_match';
    }})()
    """)
    if click_result and click_result.startswith("clicked:"):
        consent_action = "accepted_via_treewalker"

# Layer 3 — if both layers found nothing, retry once after another 1.5s wait
# (covers slow CMPs that hydrate later than expected).
if consent_action is None:
    time.sleep(1.5)
    # Re-run layer 2; if still no match, declare no banner present.
    click_result = evaluate_script(page=portal_page, expression="""... (same script) ...""")
    if click_result and click_result.startswith("clicked:"):
        consent_action = "accepted_via_treewalker_retry"
    else:
        consent_action = "no_banner_found"

# After accepting, verify the banner is actually gone (defensive check —
# some CMPs require a second confirm click). If the same keyword button is
# still visible, click it once more.
still_visible = evaluate_script(page=portal_page, expression=f"""
(function() {{
  const KEYWORDS = {json.dumps(keywords)};
  return Array.from(document.querySelectorAll('button, a, [role="button"]'))
    .some(n => n.offsetParent !== null && KEYWORDS.includes((n.textContent||'').trim().toLowerCase()));
}})()
""")
if still_visible:
    evaluate_script(page=portal_page, expression="""... (same TreeWalker click script) ...""")

# Final state — log to the report so we can see which layer fired
report["phase0"]["portal_consent_accepted"] = consent_action != "no_banner_found"
report["phase0"]["portal_consent_method"] = consent_action

# Confirm that the portal CMP consent cookie is now set before proceeding
evaluate_script(page=portal_page, expression="document.cookie")
# Look for the portal's own consent cookie (e.g. CookieConsent, OptanonAlertBoxClosed, OneTrustGroupsUpdated, etc.)
```

**When `consent_action == "no_banner_found"`:** First sanity-check by taking a screenshot — if the screenshot clearly shows a banner with one of the market's accept keywords, that is a bug in this detection step (file a skill issue with the screenshot). Otherwise the portal really has no banner on this session (consent stored server-side from a prior session is the most common cause). Proceed with the test, but include a one-line note in the comprehensive report (`Portal CMP banner: not found — proceeding without explicit consent`) so the tester can sanity-check Phase 1 against any 404 / wrong-partner-redirect symptoms.

The portal page can stay open — we'll navigate to the partner shop page on the same tab in Phase 1.

---

## Exit criteria

Phase 0 is done when:
- BrowserOS tools are loaded
- `PORTAL_URLS[market_code]` is selected
- Market test identity is loaded into the run context
- Browser history + portal-domain cookies/storage are cleared
- A portal page is open and the portal CMP banner has been accepted (or confirmed absent and logged)
- `report["phase0"]` contains the portal consent method used

Proceed to `st-phase-1-navigation-and-moeclid-capture`.
