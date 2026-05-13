# Sales Tracking Test Report — Naturwohnen (DE)

**Partner:** Naturwohnen
**Market:** DE (Germany — moebel.de)
**Test date:** 2026-05-13 23:15 CET
**Tester:** Murat Akkus
**Test scope:** Base Part only — purchase/conversion phase intentionally **skipped** by tester request.
**Overall result:** ✅ **PASS — Base Part working (Client-Side / localStorage integration)**

---

## Summary

The Base Part of the sales tracking integration on `naturwohnen.de` is working correctly. The `moeclid` query parameter passed through the moebel.de redirect chain was captured by the partner's tracking script and persisted to `localStorage` (`MOEBEL_CLICKOUT_ID`) on the first product page load, with an accurate timestamp from the same page view. The captured `clickId` matches the URL `moeclid` value exactly.

Conversion Part (Phase 4) was **not tested in this run** because the purchase phase (Phase 3) was explicitly skipped per the tester's instruction. The Conversion Part status is therefore reported as **NOT TESTED** rather than PASS/FAIL.

---

## Phase 0 — Pre-Test Setup

| Item | Value |
| --- | --- |
| Portal URL | https://www.moebel.de |
| Browser state cleared | Yes (history + moebel.de cookies/localStorage/sessionStorage) |
| Pre-existing tabs from prior session | Closed before test start |
| Portal CMP banner present | Yes |
| Portal CMP detection layer | Accessibility-tree snapshot (`[854] button "Akzeptieren"`) |
| Portal CMP accept action | Accepted |
| Portal `user-consent` cookie after accept | Set (`Usercentrics Consent Management Platform…Optin…`) |

---

## Phase 1 — Navigation & moeclid Capture

| Item | Value |
| --- | --- |
| Partner found in listing | `shops` listing (`/shops?ps=asc`) — first pass |
| Partner shop URL | https://www.moebel.de/shops/naturwohnen?ps=asc |
| Cheapest product | Naturwohnen Beistelltisch Stapeltisch Massivholz Erle Groß — **144,95 €** |
| Redirect URL (partner link in DOM) | `…/redirect?…partnerId=7a4d28ce-ac02-4b0a-80ad-eb29699b9223&partnerName=Naturwohnen` |
| Navigation method | **Click on the DOM link element** (per the mandatory click-don't-navigate rule) |
| Final landing URL | https://www.naturwohnen.de/beistelltisch-aus-bio-massivholz_560137_24790/?ReferrerID=13.00&moeclid=a53f9d3e-b41a-4a0f-b093-9bb8606e11ea |
| Partner domain | www.naturwohnen.de |
| moeclid in final URL | ✅ `a53f9d3e-b41a-4a0f-b093-9bb8606e11ea` |

The redirect chain bounced cleanly from `moebel.de/redirect?…` to the partner product page with the `moeclid` query parameter intact. No 404, no `partnerId` strip, no portal-internal redirect-with-check failure.

---

## Phase 2 — Base Part Verification

### Initial state on partner page

- A promotional `-20% NATURMÖBEL-WOCHE!` ribbon and a `NATUR20` discount-code header were present.
- No cookie consent banner was visible. Three independent detection layers (a11y snapshot, TreeWalker DOM scan, CMP container scan for Usercentrics / OneTrust / Cookiebot / Consentmanager) found no banner. The page was fully interactive and unobstructed.
- No newsletter / email subscription popup.

> **Note on consent state:** Phase 0 cleared cookies on the portal domain only — the partner domain (`naturwohnen.de`) is not known until after the Phase 1 redirect, so its state was not cleared upfront. The absence of a banner on this visit most likely reflects pre-existing consent stored from a prior test run on this profile. This does **not** affect the validity of the result, because the moeclid stored in `localStorage` carries a timestamp from this exact page load (see below) — proving the tracking script fired on this visit and is not just showing leftover data from an earlier session. For full first-visit-after-consent integrity on a future run, clear the partner domain state explicitly once the partner domain is known.

### Storage check (no reload)

| Storage location | Key | Result |
| --- | --- | --- |
| Cookie | `moeclid` | ❌ Not set |
| localStorage | `MOEBEL_CLICKOUT_ID` | ✅ Set |

`MOEBEL_CLICKOUT_ID` raw value:

```json
{
  "date": "2026-05-13T21:13:50.112Z",
  "clickId": "a53f9d3e-b41a-4a0f-b093-9bb8606e11ea"
}
```

| Verification | Result |
| --- | --- |
| `clickId` matches URL `moeclid` exactly | ✅ |
| `date` matches current page load (today, just before the snapshot/screenshot) | ✅ |
| Cookie `moeclid` present | ❌ (not used — expected for client-side integration) |
| Cookie present and matching | ❌ (n/a — not applicable to client-side integration) |

All other partner-side cookies on the domain at the time of the check:
`_ga`, `_fbp`, `_pin_unauth`, `_gcl_au`, `XSRF-TOKEN`, `plenty-shop-cookie`, `_ga_57F7GBCD0V`. None of these are the moebel.de tracking cookie — confirming the integration is purely client-side.

### Result

**Integration type:** **Client-Side (localStorage)**
**Base Part status:** ✅ **WORKING**

The Base Tag fires on `page_view` and writes the `moeclid` to `localStorage` under `MOEBEL_CLICKOUT_ID` on the first product page load, with a JSON envelope containing both the `clickId` and a `date` timestamp from that same page load.

---

## Phase 3 — Purchase Flow

**Status:** ⏭️ **SKIPPED** (intentionally — tester instruction: "Siparis verme phase ni skip et. SAKIN siparis verme" / do not place an order).

No order was placed, no checkout fields were filled, no payment method was selected, and no test order needs to be cancelled by the partner.

---

## Phase 4 — Conversion Part Verification

**Status:** ⏭️ **NOT TESTED** (depends on Phase 3 — without an order there is no `MOEBEL_SALES.sale()` call to verify).

Because Phase 3 was intentionally skipped, the following Conversion-Part observations were **not** made on this run:
- Whether the `/api/1.0/moebel/de/sales` endpoint is called on the order-confirmation page
- The actual `PARTNER_KEY`, `MARKET`, and clickId values sent
- Payload contents (`order_id`, `value`, `currency`, etc.)
- Console errors on the confirmation page

**Expected PARTNER_KEY:** Not provided by the tester on this run. PARTNER_KEY verification was not run and is not part of the result.

A future end-to-end run (Phase 3 + 4 included) is required to confirm the Conversion Part is correctly wired up on Naturwohnen DE. The Base Part working as observed here is a necessary but not sufficient condition.

---

## Phase 5 — Console Errors

| Source | Severity | Count |
| --- | --- | --- |
| Partner page (`naturwohnen.de`) — warnings + errors | warning/error | 0 |

No JavaScript errors or warnings were emitted on the partner product page during this run.

---

## Test Data References

| Reference | Value |
| --- | --- |
| Partner ID (from moebel.de redirect link) | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| Partner name token in redirect | `Naturwohnen` |
| moeclid captured this run | `a53f9d3e-b41a-4a0f-b093-9bb8606e11ea` |
| `MOEBEL_CLICKOUT_ID` envelope date | `2026-05-13T21:13:50.112Z` |
| PARTNER_KEY (captured from MOEBEL_SALES globals) | Not captured — Phase 4 skipped |
| Expected PARTNER_KEY (provided by tester) | Not provided |
| Integration documentation | [GTM Client-Side](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html) · [Manual Client-Side](https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html) |

---

## Recommendations / Follow-ups

1. **Base Part:** No action required — working correctly on first product page load. Tag fires on page_view, writes to `localStorage` with timestamp.
2. **Conversion Part:** Run a full end-to-end test (with checkout) at a later point to confirm the sales call fires on the order-confirmation page with the correct `PARTNER_KEY`, `MARKET`, and clickId. This was deliberately out of scope today.
3. **Test integrity (future runs):** Once Phase 1 resolves the partner domain, repeat the Phase 0 clear-state loop against the partner domain too — this avoids the "consent already accepted from prior session" ambiguity observed in Phase 2 here. The current run's result is still valid because the storage timestamp confirms a fresh write, but explicit clearing makes the next first-visit test cleaner.
