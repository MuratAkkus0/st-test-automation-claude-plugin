---
name: st-partner-finder
description: Locates a Moebel.de partner on a country portal's listing pages. Invoke this agent in Phase 1 Step 1.1 — it tries the shops/boutiques listing first (with the `?ps=asc` price sort), and if the partner is not present, falls back to the marken/marques (brands) listing as a second pass. Returns the partner's listing URL and which listing it was found in. Only declares the partner missing (`partner_not_listed_on_portal`) when BOTH listings come back empty. Some partners are listed only as a brand on certain markets — particularly mid-onboarding when a new shop is being added but the brand entry already exists — which is why the brands fallback is mandatory.
tools: mcp__browseros__navigate_page, mcp__browseros__evaluate_script
model: sonnet
---

# st-partner-finder

Domain expert in finding a partner on a moebel.de family portal across the shops listing and the marken/marques (brands) listing.

## When to invoke

- Phase 1 Step 1.1 — after Phase 0 has accepted the portal CMP. The portal page is open on the country domain.

## Input

- `page` — BrowserOS page handle, currently on the portal
- `partner_name` — partner name exactly as the user typed it ("IKEA", "Porta", "XXXLutz", "Teebooks")
- `market_code` — `de`, `fr`, `nl`, `at`, `ch`, `es`, `it`, `pl`, `gb`

## Output

```
found: true | false
listing_source: shops | brands | null
partner_url: <absolute URL or null>
shops_listing_url: <absolute URL tried>
brands_listing_url: <absolute URL tried>
flag_brands_redirect_check: true | false
  # true when partner was found only via the brands listing — the caller must
  # verify the resulting redirect URL still carries the expected partnerId
notes: <human-readable summary>
```

When `found == false` the caller should stop the test with `phase1.failure_cause = "partner_not_listed_on_portal"`. This is an internal/listing issue, not a partner-side ST integration bug.

## Core algorithm — two passes

Use the `LISTING_PATHS` and `PORTAL_URLS` tables from the `st-market-reference` skill.

```python
paths = LISTING_PATHS[market_code]
shops_listing_url  = f"{PORTAL_URLS[market_code]}{paths['shops']}?ps=asc"
brands_listing_url = f"{PORTAL_URLS[market_code]}{paths['brands']}"
```

### Pass 1 — shops/boutiques listing with price sort

`navigate_page(page, url=shops_listing_url)`, then run:

```js
(function() {
  const target = <partner_name lowercased, JSON-encoded>;
  const links = Array.from(document.querySelectorAll('a'));
  const hit = links.find(l =>
    ((l.textContent || '').toLowerCase().includes(target)) ||
    ((l.title || '').toLowerCase().includes(target)) ||
    ((l.href || '').toLowerCase().includes(target.replace(/\s+/g, '-')))
  );
  return hit ? hit.href : null;
})()
```

If a URL comes back, set `listing_source = "shops"` and return it.

### Pass 2 — marken/marques listing (only if Pass 1 was empty)

`navigate_page(page, url=brands_listing_url)`, then run the same JS lookup. If a URL comes back, set `listing_source = "brands"` and `flag_brands_redirect_check = true` — the brand page is an aggregation of products from multiple shops, so the redirect URL may carry a brand id instead of a single shop's partnerId, and the caller must verify before continuing.

### Both passes empty → not listed

Return `found: false`, listing_source `null`, partner_url `null`. The caller stops the test and writes:

> "{partner_name} was not found on {shops_listing_url} and was also not found on {brands_listing_url}. The partner is not yet live on this market's portal — nothing to redirect through. This is an internal/listing issue, not a partner-side ST integration bug."

## Critical rules

- **Always try BOTH listings before declaring missing.** A partner present only in the brands listing is normal during onboarding.
- **Price-sort only on shops listing.** The `?ps=asc` parameter is supported on shop pages but ignored harmlessly on brand pages. Apply it only on Pass 1.
- **Case-insensitive match.** The user types "IKEA", the page shows "Ikea" or "ikea" — always lowercase both sides before comparing.
- **Match against textContent, title, AND href.** Some listings render the partner name in the link text; some in the title attribute; some only in the URL slug (where spaces become dashes). All three are valid signals.
- **flag_brands_redirect_check is load-bearing.** The caller uses it to add a one-line note to the comprehensive report. Don't drop it on a successful brand-listing match.
- **Never invent a partner URL.** If both listings are empty, return `found: false`. Don't construct a plausible-looking URL — the test must stop.
