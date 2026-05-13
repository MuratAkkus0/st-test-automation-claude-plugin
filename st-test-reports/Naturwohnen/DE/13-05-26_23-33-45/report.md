# Sales Tracking Test Report — Naturwohnen (DE)

| Field | Value |
| --- | --- |
| Partner | Naturwohnen |
| Market | DE |
| Portal | https://www.moebel.de |
| Partner domain | https://www.naturwohnen.de |
| Test date | 2026-05-13 23:33:45 |
| Tester | Murat Akkus (murat.akkus@moebel.de) |
| Overall result | **PARTIAL PASS — Base Part WORKING; Conversion Part NOT TESTED (order placement intentionally skipped by tester)** |
| Integration type | **GTM Client-Side or Manual Client-Side or Shopify** (moeclid stored in `localStorage`, not in a cookie) |

> Phase 3 (purchase flow) and Phase 4 (conversion verification) were **intentionally skipped** at the tester's explicit request — no order was placed on Naturwohnen's shop. The Base Part of the integration was fully verified; the Conversion Part still needs to be tested on a follow-up run with a real order.

---

## Phase status summary

| Phase | Status | Notes |
| --- | --- | --- |
| Phase 0 — Pre-test setup | ✅ Completed | Browser state cleared on `moebel.de`; portal CMP banner accepted via `Akzeptieren` button on page snapshot |
| Phase 1 — Navigation & moeclid capture | ✅ Completed | Partner found on `/shops` listing; product opened by clicking the redirect link (not direct URL); moeclid present in final URL |
| Phase 2 — Base Part verification | ✅ Working | moeclid stored in `localStorage.MOEBEL_CLICKOUT_ID` immediately after consent acceptance, matches URL parameter exactly |
| Phase 3 — Purchase flow | ⏭️ Skipped | Intentionally skipped at tester's request — no order placed |
| Phase 4 — Conversion verification | ⏭️ Skipped | Cannot run without a Phase 3 order |
| Phase 5 — Console error scan | ⏭️ Skipped | Not run because Phase 4 was skipped |
| Phase 6 — Report generation | ✅ Completed | This document + Jira draft + partner email draft |

---

## Phase 0 — Pre-test setup

- Browser history cleared globally.
- Anchor tab opened (`about:blank`) before closing pre-existing tabs to keep the BrowserOS profile alive.
- Cookies + localStorage + sessionStorage cleared on `www.moebel.de`.
- Portal opened at `https://www.moebel.de` and reloaded so the CMP banner re-appeared as a true first-visit.
- Portal CMP banner detected via accessibility snapshot — accept button `[1048] button "Akzeptieren"` clicked.
- Banner confirmed gone via re-check (no visible element with `textContent === "akzeptieren"`).
- **Portal consent method:** `accepted_via_snapshot`.

---

## Phase 1 — Navigation & moeclid capture

| Field | Value |
| --- | --- |
| Shops listing URL | `https://www.moebel.de/shops?ps=asc` |
| Found in listing | `shops` (first pass — brand fallback not needed) |
| Partner listing URL | `https://www.moebel.de/shops/naturwohnen` |
| Product page URL (partner shop on portal) | `https://www.moebel.de/shops/naturwohnen?ps=asc` |
| Cheapest product | Beistelltisch aus Bio-Massivholz |
| `partnerId` in redirect href | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| Open method | Clicked the link in the live DOM (`target` switched from `_blank` to `_self` because programmatic `.click()` is popup-blocked for `_blank`). Direct URL navigation to the redirect href was **not** used — that path strips `partnerId` and 404s on the portal-internal `/api/product/redirectWithCheck` endpoint. |
| Final URL after redirect chain | `https://www.naturwohnen.de/beistelltisch-aus-bio-massivholz_560137_24790/?ReferrerID=13.00&moeclid=f2d8d7cd-6043-4f85-b11f-51f974c0ddb7` |
| `moeclid` present in final URL | ✅ Yes |
| `moeclid` value | `f2d8d7cd-6043-4f85-b11f-51f974c0ddb7` |

The redirect chain completed cleanly on the first attempt — `partnerId` survived end-to-end and the `moeclid` query parameter is present on the partner's product page.

---

## Phase 2 — Base Part verification

### Initial page state (after pre-clean reload, before any clicks)

- URL: `https://www.naturwohnen.de/beistelltisch-aus-bio-massivholz_560137_24790/?ReferrerID=13.00&moeclid=f2d8d7cd-6043-4f85-b11f-51f974c0ddb7`
- Page title: `Beistelltisch aus Bio-Massivholz | Naturwohnen.de`
- Overlays detected: **cookie consent banner** (custom CMP — `Einverstanden, zum Shop →` accept button).
- No newsletter / age-gate / welcome popup visible.

### Cookie consent

| Field | Value |
| --- | --- |
| Banner present | Yes |
| Banner type | Banner at bottom (does not fully block content) |
| Consent platform | Custom (no `Cookiebot`, `UC_UI`, `OneTrust`, `Didomi`, or `Sourcepoint` globals) |
| Accept button | `[3862] button "Einverstanden, zum Shop →"` |
| Action | **Accepted** via snapshot click — no TreeWalker fallback needed |

### Email/newsletter popup

| Field | Value |
| --- | --- |
| Present | No |
| Action | None |

### Storage check (same page load, no reload after consent)

**Cookies** (Server-Side check):

| Field | Value |
| --- | --- |
| Cookie names found | `_ga`, `_fbp`, `_pin_unauth`, `_gcl_au`, `XSRF-TOKEN`, `_ga_57F7GBCD0V`, `plenty-shop-cookie` |
| `moeclid` cookie | ❌ Not present |

**localStorage** (Client-Side check):

| Field | Value |
| --- | --- |
| `MOEBEL_CLICKOUT_ID` raw value | `{"date":"2026-05-13T21:32:33.464Z","clickId":"f2d8d7cd-6043-4f85-b11f-51f974c0ddb7"}` |
| Parsed `clickId` | `f2d8d7cd-6043-4f85-b11f-51f974c0ddb7` |
| Matches URL `moeclid` parameter | ✅ Yes — bitwise identical |

### Base Part verdict

✅ **WORKING — Client-Side integration**

The Base Tag fires correctly on the page load where the user accepts cookie consent. The `moeclid` from the URL is captured and stored in `localStorage.MOEBEL_CLICKOUT_ID` on the same page load, with no reload required. This is the textbook-correct first-visit behaviour for a client-side integration: the CMP gates the tag, the tag fires on `page_view` once consent is granted, and the click id is captured before the user navigates away.

**Integration type:** GTM Client-Side, Manual Client-Side, or Shopify Custom Pixel. The exact platform cannot be determined from the storage layer alone — would need to inspect Phase 4's `MOEBEL_SALES` global, sales-call payload, and the partner's tag manager configuration to confirm. Naturwohnen uses **Plenty** as the shop platform (visible via the `plenty-shop-cookie` set on the partner domain), which typically pairs with GTM Client-Side.

---

## Phase 3 — Purchase flow (SKIPPED)

Skipped intentionally — the tester explicitly requested "SAKIN siparis verme" (do not place an order under any circumstances) when invoking the test. No add-to-cart, no checkout, no order submission was performed on Naturwohnen's shop.

---

## Phase 4 — Conversion verification (SKIPPED)

Skipped because Phase 3 was skipped — without a real order placed, the Conversion Tag (`MOEBEL_SALES.sale(...)`) cannot fire, the sales call cannot reach `https://redirect.moebel.de/api/1.0/moebel/de/sales`, and there is no payload to verify. The PARTNER_KEY used by Naturwohnen in the Conversion Tag is therefore also **not captured** from this run — it would have been read from the `MOEBEL_SALES` global on the order-confirmation page.

> PARTNER_KEY verification skipped — no Conversion Tag fired, and no expected key was provided by the tester anyway.

---

## Phase 5 — Console error scan (SKIPPED)

Skipped because Phase 4 was skipped. A targeted console scan on the product page (Phase 2) showed no `MOEBEL_SALES` or `moebel.de`-related errors during normal page load and CMP-accept flow, but this is not a substitute for the full Phase 5 check on the order-confirmation page.

---

## Root Cause Analysis

No failure to analyse — the Base Part is healthy and the Conversion Part was not exercised in this run.

The only open question is whether the Conversion Tag is correctly implemented end-to-end. The Base Tag's clean first-visit behaviour is a strong positive signal (it means the partner's GTM container, consent gating, and `page_view` trigger are all configured correctly for the moeclid capture), but it doesn't prove the Conversion Tag is wired up with the right PARTNER_KEY, the right `MARKET` value, or the right `items` / `total` / `shipping` payload shape.

---

## Recommendations

1. **Re-run the test with Phase 3 enabled** when ready — place a small Vorkasse / Bank Transfer order using the German test identity (Mia Moebel.de-Test, `partner@moebel.de`) and verify the Conversion Part fires on the confirmation page. This is the only way to validate the second half of the integration and capture the PARTNER_KEY for ACM cross-check.
2. **No partner-side action required for the Base Part** — the moeclid is being captured correctly on first visit. Communicate this clearly so the partner is not asked to "fix" something that already works.
3. **If a partner-side issue surfaces in a future Phase 4 run** (wrong PARTNER_KEY, total includes shipping, items missing), refer the partner to the GTM Client-Side or Manual Client-Side integration documentation — see the URLs below.

### Relevant integration documentation

- **Client-Side Tracking with Google Tag Manager** — https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html
- **Manual Client-Side Integration** — https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html

(Server-side variants omitted — the storage layer is client-side; no cookie was set.)

---

## Test Data References

| Field | Value |
| --- | --- |
| moeclid | `f2d8d7cd-6043-4f85-b11f-51f974c0ddb7` |
| partnerId from redirect href | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| PARTNER_KEY used by partner in the sales call | **Not captured** (Phase 4 skipped — would have been read from `MOEBEL_SALES` on the order-confirmation page) |
| Sales endpoint (DE) | `https://redirect.moebel.de/api/1.0/moebel/de/sales` |
| Storage location | `localStorage.MOEBEL_CLICKOUT_ID` |
| Raw localStorage value | `{"date":"2026-05-13T21:32:33.464Z","clickId":"f2d8d7cd-6043-4f85-b11f-51f974c0ddb7"}` |
| Product tested | Beistelltisch aus Bio-Massivholz (id `560137_24790`) |
| Final URL | `https://www.naturwohnen.de/beistelltisch-aus-bio-massivholz_560137_24790/?ReferrerID=13.00&moeclid=f2d8d7cd-6043-4f85-b11f-51f974c0ddb7` |
| Shop platform | Plenty (inferred from `plenty-shop-cookie` on partner domain) |

> PARTNER_KEY verification skipped — Phase 4 was not run.

---

*Generated by Sales Tracking Test Automation on 2026-05-13 23:33:45.*
