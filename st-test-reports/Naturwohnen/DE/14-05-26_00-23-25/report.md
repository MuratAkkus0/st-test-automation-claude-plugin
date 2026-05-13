# Sales Tracking Test Report — Naturwohnen (DE)

| Field | Value |
| --- | --- |
| Partner | Naturwohnen |
| Market | DE (Germany) |
| Portal | https://www.moebel.de |
| Partner domain | www.naturwohnen.de |
| Test date | 2026-05-14 00:23:25 |
| Tester | Murat Akkus (murat.akkus@moebel.de) |
| Overall result | **BASE PART PASS — CONVERSION PART NOT TESTED** (Phase 3 + Phase 4 skipped per user request) |
| Integration type | **Client-Side** (GTM Client-Side or Manual Client-Side) |

---

## Test scope

This run was a **Base-Part-only test**. The user explicitly instructed the orchestrator to skip the order placement path (Phase 3) and conversion verification (Phase 4). Only Phases 0–2 were executed.

| Phase | Status | Notes |
| --- | --- | --- |
| Phase 0 — Pre-test setup & portal CMP | PASS | Portal consent accepted via accessibility-snapshot layer |
| Phase 1 — Navigation & moeclid capture | PASS | Partner found in `/shops` listing on first pass; moeclid present in final URL |
| Phase 2 — Base Part verification | **PASS** | moeclid stored in `localStorage` on the same page load after consent acceptance — Base Tag trigger correctly set to page_view |
| Phase 3 — Purchase flow | SKIPPED | User requested to skip the order placement path |
| Phase 4 — Conversion verification | SKIPPED | Requires Phase 3 order — could not be run |
| Phase 6 — Reporting | PASS | All three deliverables produced |

---

## Phase 0 — Pre-test setup

- Portal URL: `https://www.moebel.de`
- Portal CMP consent: **accepted via accessibility snapshot (Layer 1)** — element `[238] button "Akzeptieren"` was found in the initial snapshot and clicked. Post-click verification confirmed the banner is gone and tracking cookies (`_ga`, `_gcl_au`, `_fbp`) were subsequently set.
- Browser state cleared before opening the portal (history + portal-domain cookies/localStorage/sessionStorage).
- Anchor-tab rule applied throughout.

## Phase 1 — Navigation & moeclid capture

| Step | Result |
| --- | --- |
| Listing lookup (Pass 1: `/shops?ps=asc`) | Found — `https://www.moebel.de/shops/naturwohnen` |
| Listing lookup (Pass 2: `/marken`) | Not needed |
| Partner shop page | `https://www.moebel.de/shops/naturwohnen?ps=asc` |
| First product (cheapest) | "Naturwohnen Massivholz Regalboden 2x43x43cm Erle natur geölt Serie Arbor" — €39,95 |
| Redirect href | Carries `partnerId=7a4d28ce-ac02-4b0a-80ad-eb29699b9223` and `partnerName=Naturwohnen` |
| Open method | **Click on the link element via snapshot** (per skill rule — never `new_page(url=redirect_href)`) |
| Final URL | `https://www.naturwohnen.de/moebel/regale/arbor-regalboden-schmal_560050_22763/?ReferrerID=13.00&moeclid=20bb390c-fb57-462c-b856-0f5681ec4bd5` |
| moeclid present | ✅ Yes |
| moeclid value | `20bb390c-fb57-462c-b856-0f5681ec4bd5` |

## Phase 2 — Base Part verification

### Initial page state (after pre-clean reload, before consent)

The partner site uses a **wall-style cookie consent banner** (full-page overlay blocking all content) with custom branding (Plenty-based shop platform — `plenty-shop-cookie` was observed in the cookie names post-consent).

- Accept button: `[1663] button "Einverstanden, zum Shop →"`
- Settings button: `[1662] button "Einstellungen"`
- Banner title: "Datenschutz-Einstellungen"
- No newsletter popup observed after consent acceptance.

### Step order (mandatory, all followed)

1. Pre-clean partner-domain cookies + localStorage + sessionStorage ✅
2. Reload (with `moeclid` still in the URL) ✅
3. Snapshot the page ✅
4. Accept consent ✅
5. Snapshot again — no newsletter popup ✅
6. Read storage **without reloading after consent** ✅

### Storage check results (on the same page load after consent)

| Storage type | Key | Found | Value |
| --- | --- | --- | --- |
| Cookies | `moeclid` | ❌ No | — |
| localStorage | `MOEBEL_CLICKOUT_ID` | ✅ Yes | `{"date":"2026-05-13T22:22:11.622Z","clickId":"20bb390c-fb57-462c-b856-0f5681ec4bd5"}` |

| Value compared | URL `moeclid` | localStorage `clickId` | Match |
| --- | --- | --- | --- |
| `20bb390c-fb57-462c-b856-0f5681ec4bd5` | `20bb390c-fb57-462c-b856-0f5681ec4bd5` | ✅ Exact match |

**All cookies observed after consent**: `_ga, _fbp, _pin_unauth, _gcl_au, XSRF-TOKEN, _ga_57F7GBCD0V, plenty-shop-cookie`

**All localStorage keys observed**: `_gcl_ls, MOEBEL_CLICKOUT_ID`

### Verdict

**Base Part: WORKING — Client-Side integration**.

- The moeclid was stored on the **same page load** immediately after consent acceptance, with no reload required. This means the Base Tag trigger is correctly set to **Page View — All Pages** and the CMP consent gating is properly configured.
- The presence of `_gcl_au` and `_gcl_ls` and a `plenty-shop-cookie` suggests a GTM-managed Client-Side setup on a Plenty/PlentyOne shop platform.

---

## Phase 3 — Purchase flow

**SKIPPED** by user request ("Dont place any order. skip the placing order path."). No order was added to cart, no checkout was attempted, no order number was captured.

## Phase 4 — Conversion verification

**SKIPPED** — Phase 4 requires Phase 3 to have produced an order confirmation page so it can read the sales-endpoint call from the Performance API and capture `PARTNER_KEY`, `MARKET`, and the payload. Without an order, this phase cannot run.

> ⚠️ **PARTNER_KEY was therefore NOT captured during this run.** The captured-key value is normally written here as a tester-verifiable reference; for this Base-Part-only run, that data point is unavailable. A follow-up test that includes Phase 3 + Phase 4 is required to capture and (optionally) verify the PARTNER_KEY.

### PARTNER_KEY verification

PARTNER_KEY verification was skipped — no expected key was provided by the tester, and Phase 4 did not run.

---

## Root cause analysis

No failure to analyse — Base Part is working correctly. The remaining work is to verify the Conversion Part in a follow-up test run that includes a real order.

## Recommendations

1. **Schedule a follow-up Conversion Part test** that runs Phases 3 + 4 to verify the sales endpoint call fires with a correct payload and the right PARTNER_KEY for the DE market.
2. **For the partner** (Naturwohnen): no action required from the Base Part perspective — the moeclid is being captured and stored correctly as soon as cookie consent is accepted.

### Relevant integration documentation

- [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)
- [Manual Client-Side Integration](https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html)

---

## Test Data References

| Reference | Value |
| --- | --- |
| moeclid (URL) | `20bb390c-fb57-462c-b856-0f5681ec4bd5` |
| moeclid (localStorage clickId) | `20bb390c-fb57-462c-b856-0f5681ec4bd5` |
| Partner ID (from redirect href) | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| Partner name (from redirect href) | `Naturwohnen` |
| Captured PARTNER_KEY | _not captured — Phase 4 skipped_ |
| Expected PARTNER_KEY | _not provided by tester_ |
| Test product | Regalboden "Arbor" schmal Erle natur geölt — €39,95 |
| Partner product URL | https://www.naturwohnen.de/moebel/regale/arbor-regalboden-schmal_560050_22763/ |
| Order ID | _no order placed_ |

---

_Created by Sales Tracking Test Automation_
