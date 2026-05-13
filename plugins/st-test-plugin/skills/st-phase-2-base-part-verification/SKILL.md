---
name: st-phase-2-base-part-verification
description: Phase 2 of the sales tracking test. Use this skill after Phase 1 has landed on the partner site with a valid moeclid — it snapshots the page, accepts the partner's cookie consent, dismisses newsletter popups, then verifies the moeclid is stored in cookies (server-side integration) or localStorage (client-side integration) WITHOUT reloading the page. The step order is mandatory: snapshot, accept consent, dismiss popups, check storage. When storage is empty after consent, reloads once to distinguish "base tag trigger not page_view" from "base tag missing entirely". Stops the test on Base Part failure.
compatibility: claude-code
---

# Phase 2: Partner Page Inspection & Base Part Verification

**The order of steps in this phase is mandatory and must never be skipped or reordered:**
1. Snapshot the page immediately after redirect (see what is shown)
2. Accept cookie consent
3. Handle email/newsletter popups
4. Check storage (cookies + localStorage) — **without reloading the page**

This order matters because Base Part scripts on many partners only fire after the user makes a consent decision. Checking storage before accepting consent is the single most common cause of false-negative results.

**Critical: never reload the page before checking storage.**
A correct integration fires the tracking script via the CMP's consent callback (e.g., `CookiebotOnAccept`, `UCEvent`, `OneTrustGroupsUpdated`) — meaning the moeclid is stored on the same page load, immediately after the user accepts consent, without any navigation or reload. If storage is still empty after consent is accepted on the same page, that is a broken integration, not a timing issue. A page reload would mask this bug by giving a false positive — the script fires on the reloaded page's `page_view` even though it would never fire for a real user who lands fresh and accepts consent.

---

**Step 2.0: Snapshot the partner page immediately after redirect**

This step is mandatory. Take it before clicking anything. It documents the exact initial state of the page and reveals what overlays, popups, or consent walls are present.

```python
# Take a snapshot to see all interactive elements
take_snapshot(page=newPageId)

# Also take a screenshot for visual documentation in the report
take_screenshot(page=newPageId)

# Identify everything visible on the page:
# - Cookie consent banner or wall (Usercentrics, OneTrust, Cookiebot, Consentmanager, custom)
# - Email / newsletter subscription popup
# - Age verification gate
# - Promotional welcome modal
# - Any overlay blocking or covering page content

report["phase2"]["initial_page_state"] = {
    "url": final_url,
    "partner_domain": domain_from_url(final_url),
    "overlays_detected": ["cookie_consent", "email_popup", ...],  # list what is visible
    "notes": "Describe what is showing on the page immediately after redirect"
}
```

---

**Step 2.1: Accept cookie consent (BEFORE checking storage)**

Cookie consent must always be handled before checking storage. Many partners gate their Base Part script behind consent callbacks — the script simply does not run until the user accepts consent. Skipping this step produces a guaranteed false negative.

**Always ACCEPT cookie consent** — this is required to allow all tracking scripts (including the Base Part) to run. Never decline consent during a sales tracking test, because declining may prevent the partner's Base Part script from executing.

Treat cookie consent as the expected default for virtually every partner. The absence of a consent popup is the exception, not the rule.

**What correct behaviour looks like after accepting consent:**
A correctly integrated partner has the Base Tag trigger set to **Page View — All Pages**. With this trigger, the Base Tag fires on every page load. The CMP (e.g. Cookiebot) handles consent gating automatically — it blocks the tag before consent is given and allows it to fire on subsequent page loads once consent is active. This means the moeclid is reliably captured on the first page load after consent, without any custom consent callbacks needed.

```python
# Use the snapshot to find the ACCEPT button by text content:
# Accept keywords: "akzeptieren", "alle akzeptieren", "accept", "accept all", "accepter",
#                  "tout accepter", "accettare", "accepteren", "aceptar", "zgadzam się"

# ALWAYS click the Accept / Accept All button
if accept_button_in_snapshot:
    click(page=newPageId, element=accept_button_element_id)
    consent_action = "accepted"
else:
    consent_action = "none_found"
    # Note: some partners have no consent banner — this is fine, proceed

report["phase2"]["cookie_consent"] = {
    "banner_present": True/False,
    "banner_type": "wall" or "banner" or "none",
    # "wall" = full-page overlay blocking all content
    # "banner" = notice at top/bottom that does not block content
    "consent_platform": "Usercentrics / OneTrust / Cookiebot / Consentmanager / custom / unknown",
    "action": consent_action,  # "accepted", "none_found"
    "notes": ""
}
```

For the layered detection strategy (a11y snapshot → TreeWalker → retry) — apply the same approach documented in `st-phase-0-pre-test-setup` Step 7 when a partner CMP is custom-built with generic class names. The TreeWalker fallback is the canonical method for any custom CMP.

---

**Step 2.2: Handle email/newsletter subscription popups (after consent)**

After accepting consent, some partners immediately display a newsletter or email subscription modal. Always check for this and dismiss it before reading storage. Leaving it open clutters screenshots and can occasionally interfere with DOM queries.

```python
# Take a fresh snapshot after consent was accepted
take_snapshot(page=newPageId)

# Look for email/newsletter modal indicators:
# Modal content: "newsletter", "email", "subscribe", "abonnieren", "anmelden", "registrieren"
# Dismiss buttons: "no thanks", "nein danke", "schließen", "close", "×", "fermer", "chiudi", "skip"

if email_popup_detected_in_snapshot:
    click(page=newPageId, element=dismiss_button_element_id)
    report["phase2"]["email_popup"] = {
        "present": True,
        "action": "dismissed",
        "notes": "Newsletter modal dismissed before storage check"
    }
else:
    report["phase2"]["email_popup"] = {
        "present": False,
        "action": "none",
        "notes": ""
    }
```

---

**Step 2.3: Take a post-popup screenshot**

Now that all overlays are cleared, take a screenshot of the clean product page. This shows the state in which the Base Part should have run and is useful for the report.

```python
take_screenshot(page=newPageId)
# Label: "Partner page — all popups dismissed, ready for storage check"
```

---

**Step 2.4: Check cookies (Server-Side Integration)**

```python
result = evaluate_script(page=newPageId, expression="""
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
""")

report["phase2"]["cookies"] = {
    "all_cookie_names": result["cookie_names"],
    "moeclid_cookie_found": result["moeclid_cookie"] is not None,
    "cookie_value": result["moeclid_cookie"]["value"] if result["moeclid_cookie"] else None,
    "matches_url_param": result["moeclid_cookie"]["value"] == moeclid_value if result["moeclid_cookie"] else False
}
```

---

**Step 2.5: Check localStorage (Client-Side Integration)**

```python
result = evaluate_script(page=newPageId, expression="""
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
""")

report["phase2"]["localStorage"] = {
    "moebel_clickout_id_found": result["clickId"] is not None,
    "localStorage_raw": result["localStorage_raw"],
    "clickId": result["clickId"],
    "matches_url_param": result["clickId"] == moeclid_value if result["clickId"] else False
}
```

---

**Step 2.6: Base Part Result**

```python
base_part_working = (
    (report["phase2"]["cookies"]["moeclid_cookie_found"] and
     report["phase2"]["cookies"]["matches_url_param"]) or
    (report["phase2"]["localStorage"]["moebel_clickout_id_found"] and
     report["phase2"]["localStorage"]["matches_url_param"])
)

if base_part_working:
    integration_type = (
        "Server-Side (Cookie)" if report["phase2"]["cookies"]["moeclid_cookie_found"]
        else "Client-Side (localStorage)"
    )
    report["phase2"]["result"] = {
        "status": "WORKING",
        "storage_type": integration_type,
        "notes": "Base Part working — moeclid stored successfully"
    }
    # PROCEED TO PHASE 3
else:
    # Storage is empty after consent. We need to distinguish two cases:
    # reload the page and check storage again.
    #
    # After reload, CookieConsent is already set. If the Base Tag has a page_view trigger,
    # the tag will fire on this reload and store the moeclid (which is still in the URL).
    # - moeclid found after reload → Base Tag trigger EXISTS and fires on page_view,
    #   but the tag MISSED the original page load (the one with consent just accepted).
    #   → failure_cause = "base_tag_trigger_not_set_to_page_view"
    #   → Fix: ensure the Base Tag trigger is set to page_view so it fires on every load
    # - moeclid still absent after reload → Base Tag trigger is missing entirely, or tag broken
    #   → failure_cause = "base_tag_trigger_missing_or_tag_not_implemented"
    #
    # This two-step check is only needed when consent was just accepted on this page load.
    # If there was no consent banner, skip straight to the generic failure.

    if consent_action == "accepted":
        # Step 2.6a: Reload the page to let the script fire on a fresh page_view
        # with consent already active
        navigate_page(page=newPageId, action="reload")
        take_snapshot(page=newPageId)  # always retake snapshot after reload

        # Step 2.6b: Re-check storage after reload (same script as Steps 2.4–2.5)
        post_reload_storage = evaluate_script(page=newPageId, expression="""
        (function() {
          const allCookies = document.cookie.split(';').map(c => {
            const [name, ...rest] = c.trim().split('=');
            return { name: name.trim(), value: rest.join('=') };
          });
          const moeclidCookie = allCookies.find(c => c.name === 'moeclid');
          const lsValue = localStorage.getItem('MOEBEL_CLICKOUT_ID');
          let clickId = null;
          if (lsValue) {
            try { clickId = JSON.parse(lsValue).clickId; } catch(e) { clickId = lsValue; }
          }
          return JSON.stringify({
            moeclid_cookie: moeclidCookie || null,
            localStorage_raw: lsValue,
            clickId: clickId
          });
        })()
        """)

        moeclid_found_after_reload = (
            post_reload_storage["moeclid_cookie"] is not None or
            post_reload_storage["clickId"] is not None
        )

        report["phase2"]["post_reload_storage"] = post_reload_storage

        if moeclid_found_after_reload:
            # moeclid stored after reload, but NOT on same page after consent.
            # This means the Base Tag trigger is NOT set to page_view (or not set at all).
            # A correctly configured Base Tag with a page_view trigger fires on every page load —
            # including the one where the user just accepted consent. Because the moeclid is in
            # the URL on that page load, it should be stored immediately when the tag fires.
            # The fact that a reload is required proves the tag did NOT fire on this page load,
            # meaning the trigger is absent or points to a different event.
            failure_cause = "base_tag_trigger_not_set_to_page_view"
            failure_notes = (
                "Cookie consent was accepted on this page load but moeclid was NOT stored. "
                "After reloading the same URL, moeclid WAS stored — confirming the Base Tag "
                "fires on page_view, but did not fire on the page load where consent was given. "
                "This means the Base Tag trigger is not set to the page_view event, so the tag "
                "misses the page load that contains the moeclid in the URL. "
                "New visitors who land on the site and must accept consent will never be tracked."
            )
        else:
            # Script didn't fire even after a full reload with consent active.
            # The Base Tag trigger is either not set at all, or the tag itself is broken/missing.
            failure_cause = "base_tag_trigger_missing_or_tag_not_implemented"
            failure_notes = (
                "Cookie consent was accepted and the page was reloaded (with consent active), "
                "but the moeclid was still not stored in localStorage or a cookie after the reload. "
                "The Base Tag trigger does not appear to be configured at all, or the Base Part "
                "tag itself is missing from the GTM container or tracking implementation."
            )
    else:
        # No consent banner was present, or storage is empty for another reason
        failure_cause = "base_part_not_implemented_or_misconfigured"
        failure_notes = "Base Part failed — moeclid not stored in cookie or localStorage"

    report["phase2"]["result"] = {
        "status": "FAILED",
        "failure_cause": failure_cause,
        "consent_action_taken": consent_action,
        "notes": failure_notes
    }
    # STOP and generate report
    generate_report_and_stop()
```

**🛑 STOP if Base Part fails:**
- Generate report with FAILED status
- Include the exact failure cause and actionable fix instructions (see Recommendations section below)
- Skip remaining phases

**Recommendations to include in the report when `failure_cause == "base_tag_trigger_not_set_to_page_view"`:**

> **Root cause:** The Base Tag trigger is not set to the `page_view` event. The Base Tag fires on some page loads (confirmed: moeclid was stored after a reload) but did not fire on the page load where the user accepted consent. This means the trigger is either missing, set to a non-standard event, or configured in a way that skips certain page loads. Since the moeclid is in the URL on the first page load, the tag must fire on every `page_view` to reliably capture it.
>
> **Required fix:**
>
> - **GTM integration:** Open the Base Tag in the GTM container and check its trigger. Set the trigger to **Page View — All Pages** (the standard `page_view` trigger). This ensures the tag fires on every page load, including the one that contains the moeclid in the URL. Publish the container after making the change.
>
> - **Manual Client-Side integration:** Ensure the moeclid storage script runs on every page load — place it in a `DOMContentLoaded` or `window.onload` handler that fires unconditionally on every page view.
>
> - **Manual Server-Side or Shopify integration:** Ensure the client-side script that reads the moeclid from the URL and sends it to the server runs on every page load, triggered by `DOMContentLoaded` or equivalent.

**Recommendations to include in the report when `failure_cause == "base_tag_trigger_missing_or_tag_not_implemented"`:**

> **Root cause:** The Base Tag trigger is not configured at all, or the Base Part tag is missing from the tracking implementation entirely. The moeclid was not stored even after a full page reload with consent active, which rules out a consent-related issue — the tag simply does not run.
>
> **Required fix:**
>
> - **GTM integration:** Verify the Base Tag exists in the GTM container and is published. If the tag exists, check that it has a **Page View — All Pages** trigger attached. If the tag is missing, implement it from scratch following the GTM_Client_Side_Integration_Documentation or GTM_Server-Side_Integration_Documentation.
>
> - **Manual integration:** Verify the tracking script is included in the page source. Open browser DevTools → Sources and confirm the script loads. Check the Console for JavaScript errors. Verify the script reads `window.location.search` or `URLSearchParams` for the `moeclid` parameter.

---

## Exit criteria

Phase 2 is done when:
- `report["phase2"]["result"]["status"]` is set to `WORKING` or `FAILED`
- On FAILED: report has been generated and the test has stopped
- On WORKING: `integration_type` is recorded (Server-Side / Client-Side)

Proceed to `st-phase-3-purchase-flow` only when Base Part is `WORKING`.
