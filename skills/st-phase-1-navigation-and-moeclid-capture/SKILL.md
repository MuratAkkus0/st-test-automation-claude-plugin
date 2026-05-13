---
name: st-phase-1-navigation-and-moeclid-capture
description: Phase 1 of the sales tracking test. Use this skill after Phase 0 has accepted the portal CMP — it locates the partner on the portal (shops listing first, marken/marques brands listing as second pass), opens the cheapest product, follows the moebel.de redirect chain to the partner's site, and verifies the moeclid tracking parameter is present in the final URL. Stops the test if the partner is listed nowhere, no product redirect URL is found, or the moeclid parameter is missing from the final URL.
compatibility: claude-code
---

# Phase 1: Navigation & Product Selection

Goal: find the partner on the portal, click a product, and confirm the moeclid parameter survived the moebel.de redirect chain.

**Prerequisite:** Phase 0 (`st-phase-0-pre-test-setup`) must have completed — portal CMP consent must already be accepted in this browser session. Without portal consent, the redirect chain on some markets strips `partnerId`/`partnerName` mid-chain and lands on a 404 on the portal's own domain.

**Step 1.1: Navigate to partner shop page with price sorting**

Try the **shops/boutiques** listing first. If the partner is not present there, **also try the marken/marques** (brands) listing as a second pass before declaring the partner missing — some partners are listed only as a brand on certain markets, especially when they are mid-onboarding. Only when both listings come back empty should the skill stop and report the partner as not yet listed on this market.

Use the `LISTING_PATHS` and `PORTAL_URLS` tables from the `st-market-reference` skill.

```python
# Localised listing paths per market — each market exposes a "shops" listing and a
# "marken/marques/brands" listing. The price-sort query (?ps=asc) is supported on the
# shop pages. Both paths must be tried before declaring the partner missing.
# See st-market-reference for the full LISTING_PATHS table.

def _find_partner_on_listing(page_id, listing_url, partner_name):
    navigate_page(page=page_id, url=listing_url)
    return evaluate_script(page=page_id, expression=f"""
    (function() {{
      const target = {json.dumps(partner_name).lower()};
      const links = Array.from(document.querySelectorAll('a'));
      const hit = links.find(l =>
        ((l.textContent || '').toLowerCase().includes(target)) ||
        ((l.title || '').toLowerCase().includes(target)) ||
        ((l.href || '').toLowerCase().includes(target.replace(/\\s+/g, '-')))
      );
      return hit ? hit.href : null;
    }})()
    """)

paths = LISTING_PATHS[market_code]
shops_listing_url  = f"{PORTAL_URLS[market_code]}{paths['shops']}?ps=asc"
brands_listing_url = f"{PORTAL_URLS[market_code]}{paths['brands']}"

# Pass 1 — shops/boutiques listing (with price sort)
partner_url = _find_partner_on_listing(pageId, shops_listing_url, partner_name)
listing_source = "shops" if partner_url else None

# Pass 2 — marken/marques listing (only if Pass 1 found nothing)
if not partner_url:
    partner_url = _find_partner_on_listing(pageId, brands_listing_url, partner_name)
    if partner_url:
        listing_source = "brands"

report["phase1"]["listing_lookup"] = {
    "shops_listing_url": shops_listing_url,
    "brands_listing_url": brands_listing_url,
    "found_in": listing_source,  # "shops" | "brands" | None
    "partner_url": partner_url,
}

# 🛑 STOP if the partner is in neither listing
if not partner_url:
    report["phase1"]["status"] = "FAILED"
    report["phase1"]["failure_cause"] = "partner_not_listed_on_portal"
    report["phase1"]["notes"] = (
        f"{partner_name} was not found on {PORTAL_URLS[market_code]}{paths['shops']} "
        f"and was also not found on {PORTAL_URLS[market_code]}{paths['brands']}. "
        f"The partner is not yet live on this market's portal — nothing to redirect through. "
        f"This is an internal/listing issue, not a partner-side ST integration bug."
    )
    generate_report_and_stop()

# When the partner was found via the brands listing, document that explicitly in the
# comprehensive report — the brand page on these portals is a listing of products from
# the brand across multiple shops (not a single-shop redirect chain), so the redirect
# behaviour and the moeclid attribution may differ from the shop page. Flag this so
# the tester can sanity-check the resulting redirect URL still carries the right
# partnerId before continuing.
if listing_source == "brands":
    report["phase1"]["notes_on_source"] = (
        "Partner was found only via the marken/marques (brands) listing — not in the "
        "shops/boutiques listing. The brand page may aggregate products from multiple "
        "shops. After Step 1.2, verify the redirect URL still contains the expected "
        "`partnerId` (and not just a brand id) before opening it."
    )

# Navigate to the partner page with price sorting (works on shop pages; on brand pages
# the ?ps=asc parameter is ignored harmlessly)
navigate_page(page=pageId, url=f"{partner_url}?ps=asc")
```

**Step 1.2: Find the cheapest product redirect link**
```python
# Confirm the first product's moebel.de redirect href exists in the DOM. The href is
# read for sanity-checking and logging only — never used as a URL to navigate to
# directly. Step 1.3 always opens the partner page by CLICKING the link in the live
# DOM, not by navigating to the href.
evaluate_script(page=pageId, expression="""
(function() {
  const links = Array.from(document.querySelectorAll('a'));
  const productLink = links.find(l => l.href.includes('/redirect?') && l.href.includes('partnerId'));
  return productLink ? productLink.href : null;
})()
""")

report["phase1"]["product_selection"] = {
    "sorting_applied": True,
    "redirect_href_found": True/False,
}
```

**🛑 STOP if no product redirect URL found:**
- Generate report immediately
- Mark test as FAILED — "No product redirect URL found on partner page"

**Step 1.3: Open the partner page by CLICKING the product link (never by `new_page(url=redirect_href)`)**

**Mandatory rule: always click the link in the live DOM. Never call `new_page(url=...)` against the redirect href.** Opening the redirect href directly bypasses the same-page context (Referer header, the click-handler that fires a tracking event before the navigation, the listing-page's session-level state) that the portal's `/redirect?...` endpoint depends on to resolve `partnerId`/`partnerName`. Without that context, the portal's redirect endpoint strips the partner params mid-chain and lands on `/api/product/redirectWithCheck?...` → a portal-internal 404. Verified 2026-05-13 on Naturwohnen DE: the first product 404'd via `new_page(url=redirect_href)`; clicking the same link on the same partner page opened the partner site with `moeclid` intact. The fix is "always click the link element"; there is no fallback to direct navigation.

Phase 0 must also already have accepted the portal's own cookie consent in the same browser session before this step runs — that's a separate prerequisite, not a substitute for the click rule. Both are required.

```python
# 1) Snapshot the listing tab so the click tool can resolve element IDs.
take_snapshot(page=pageId)

# 2) Identify the first product link via the same DOM query as Step 1.2, but this
#    time keep a stable selector for it so we can click it via the snapshot/click
#    flow. The cleanest path is to assign a temporary marker class via
#    evaluate_script, then ask take_snapshot to surface the marked element. If the
#    BrowserOS snapshot is too large to scan, use search_dom with a CSS selector
#    instead — the goal is to obtain the snapshot's element ID for the link.
evaluate_script(page=pageId, expression="""
(function() {
  const links = Array.from(document.querySelectorAll('a'));
  const productLink = links.find(l => l.href.includes('/redirect?') && l.href.includes('partnerId'));
  if (!productLink) return 'no_link';
  productLink.classList.add('__st_test_first_product__');
  productLink.scrollIntoView({block: 'center'});
  return 'marked';
})()
""")

# 3) Resolve the marked element to a snapshot element ID and click it via the
#    BrowserOS click tool. Real user click → triggers the portal's click-handler
#    (which fires the redirect with the listing-page Referer and the tracking
#    event the redirect endpoint expects), so the redirect resolves correctly
#    instead of stripping partnerId/partnerName.
search_dom(page=pageId, query="a.__st_test_first_product__")  # returns the element with its snapshot ID
click(page=pageId, element=<that_snapshot_id>)

# 4) Most product links open in a new tab (target="_blank"). Wait briefly, then
#    look up the new tab via list_pages — the partner-site tab is the one whose
#    URL is NOT the moebel.de listing.
wait_for_new_tab(timeout_ms=8000)
pages_after = list_pages()
new_page_entry = next(p for p in pages_after["pages"] if "moebel.de/shops/" not in p["url"] and "meubles.fr/boutiques/" not in p["url"])
newPageId = new_page_entry["pageId"]

# 5) Some partners or markets don't use target="_blank" — the click navigates
#    the SAME tab. Detect that by re-reading the listing tab's URL: if it
#    changed away from the partner shop page, the click navigated in place,
#    so newPageId is just pageId. (Both branches converge to the same next
#    step.)
if newPageId is None:
    if listing_tab_url_changed_away_from_partner_shop:
        newPageId = pageId

# 6) Confirm final URL after the redirect chain settles.
evaluate_script(page=newPageId, expression="window.location.href")
```

**On 404 on the portal-internal `/api/product/redirectWithCheck` endpoint:** verify (a) Phase 0 accepted the portal CMP on the same session, and (b) the partner page was opened via CLICK rather than `new_page(url=redirect_href)`. The vast majority of these 404s on healthy partners are caused by direct-URL navigation. Only after both are confirmed should the 404 be reported as a partner-side / portal-side bug — and even then, retry once with a different product id in case the first product is stale.

**Step 1.4: Verify moeclid in the final URL**
```python
final_url = evaluate_script(page=newPageId, expression="window.location.href")

moeclid_present = "moeclid=" in final_url
moeclid_value = extract_moeclid_from_url(final_url) if moeclid_present else None

report["phase1"]["redirect"] = {
    "final_url": final_url,
    "moeclid_present": moeclid_present,
    "moeclid_value": moeclid_value,
    "status": "success" if moeclid_present else "FAILED"
}
```

**🛑 STOP if moeclid parameter missing:**
- Document: "moeclid parameter missing in redirect URL — partner has redirect issue"
- Generate report with FAILED status
- Skip all remaining phases

---

## Exit criteria

Phase 1 is done when:
- The partner has been located on either the shops or brands listing (or the test has stopped with `partner_not_listed_on_portal`)
- A product redirect URL has been opened and the partner site has loaded
- `final_url` and `moeclid_value` are captured into `report["phase1"]["redirect"]`
- `moeclid_present == True` (otherwise the test has stopped here)

Proceed to `st-phase-2-base-part-verification`.
