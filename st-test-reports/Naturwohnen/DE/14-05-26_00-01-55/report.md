# Sales Tracking Test Report — Naturwohnen (DE)

| | |
| --- | --- |
| **Partner** | Naturwohnen |
| **Market** | DE (Germany) |
| **Portal** | https://www.moebel.de |
| **Partner domain** | https://www.naturwohnen.de |
| **Tester** | Murat (murat.akkus@moebel.de) |
| **Date** | 2026-05-14 00:01:55 |
| **Overall result** | PARTIAL — Base Part PASS / Conversion Part not tested |
| **Reason for partial scope** | Tester explicitly requested no order placement for this run |

---

## Phase summary

| Phase | Result |
| --- | --- |
| Phase 0 — Pre-test setup | PASS |
| Phase 1 — Navigation & moeclid capture | PASS |
| Phase 2 — Base Part verification | PASS (Client-Side / localStorage) |
| Phase 3 — Purchase flow | SKIPPED (no order placement requested) |
| Phase 4 — Conversion Part verification | SKIPPED (no order to verify against) |
| Phase 5 — Console error check | SKIPPED (no order page reached) |

---

## Phase 0 — Pre-test setup

- Anchor tab opened to prevent BrowserOS profile teardown during cleanup
- Global browser history cleared
- Portal-domain cookies / localStorage / sessionStorage cleared on `www.moebel.de`
- Portal page reloaded as a fresh first-visit
- Portal CMP banner detected via the accessibility-tree snapshot (custom moebel.de CMP, button label `Akzeptieren`)
- Consent accepted via snapshot-based click
- Confirmed `user-consent` cookie set on the portal domain after consent acceptance

## Phase 1 — Navigation & moeclid capture

- Listing source: `shops` (`https://www.moebel.de/shops?ps=asc`)
- Note: User initially typed "Naturmobel" — this matched three candidates (Massive Naturmöbel, Naturmoebel Manufaktur, Naturwohnen). User confirmed **Naturwohnen** was the intended partner.
- Partner shop page: https://www.moebel.de/shops/naturwohnen
- First product (cheapest, after `?ps=asc` price sort): *Regalboden "Arbor" schmal Erle natur geölt* — 39,95 €
- Opened via DOM click on the marked `<a>` element (never via direct `new_page(url=redirect_href)`)
- Final URL after redirect chain: `https://www.naturwohnen.de/moebel/regale/arbor-regalboden-schmal_560050_22763/?ReferrerID=13.00&moeclid=05f8a6a4-7bd1-4f37-b860-b0afeb75414e`
- moeclid present in URL: YES
- moeclid value: **`05f8a6a4-7bd1-4f37-b860-b0afeb75414e`**
- partnerId in redirect: `7a4d28ce-ac02-4b0a-80ad-eb29699b9223`

## Phase 2 — Base Part verification

### Pre-clean
- Partner-domain cookies / localStorage / sessionStorage cleared on `www.naturwohnen.de`
- Page reloaded (moeclid preserved in URL across reload)

### Initial page state after pre-clean reload
- Cookie consent banner present (custom CMP, non-Cookiebot/non-Usercentrics — the accept button label is `Einverstanden, zum Shop →`)
- No newsletter / email popup
- Promo banner present (`-20% NATURMÖBEL-WOCHE!`) — not a blocker
- Product page rendered correctly for the selected product

### Consent action
- Accept button: `Einverstanden, zum Shop →` (snapshot element [1678])
- Action: ACCEPTED via snapshot-based click

### Newsletter / email popup
- Not present

### Cookie inspection (Server-Side integration check)
| Field | Value |
| --- | --- |
| `moeclid` cookie found | NO |
| Cookies present | `_ga`, `_fbp`, `_pin_unauth`, `_gcl_au`, `XSRF-TOKEN`, `_ga_57F7GBCD0V`, `plenty-shop-cookie` |

### localStorage inspection (Client-Side integration check)
| Field | Value |
| --- | --- |
| `MOEBEL_CLICKOUT_ID` found | YES |
| Raw value | `{"date":"2026-05-13T22:00:57.210Z","clickId":"05f8a6a4-7bd1-4f37-b860-b0afeb75414e"}` |
| Parsed `clickId` | `05f8a6a4-7bd1-4f37-b860-b0afeb75414e` |
| Matches URL moeclid | **YES** |

### Verdict
- **Base Part: WORKING**
- Integration type: **Client-Side (localStorage)** — likely GTM Client-Side or Manual Client-Side
- The Base Tag fires on `page_view` and stores the moeclid in localStorage on the same page load where the user accepts consent — no reload needed. This is the textbook correct behaviour.

## Phase 3 — Purchase flow

SKIPPED. The tester explicitly instructed `Dont place any order. skip the placing order path.` — no cart action, no checkout, no order submission.

## Phase 4 — Conversion Part verification

SKIPPED. Phase 4 requires a confirmation page produced by a real order, which was not placed.

PARTNER_KEY for Naturwohnen DE could not be captured in this run because the sale request is only fired during conversion. Suggest verifying it in a follow-up run that includes the purchase flow.

## Phase 5 — Console error check

SKIPPED. No confirmation page was reached.

---

## Test Data References

| Field | Value |
| --- | --- |
| moeclid (Phase 1, in URL) | `05f8a6a4-7bd1-4f37-b860-b0afeb75414e` |
| moeclid (Phase 2, stored) | `05f8a6a4-7bd1-4f37-b860-b0afeb75414e` |
| partnerId (in redirect URL) | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| PARTNER_KEY (from sale call) | not captured — Phase 4 skipped |
| Storage location | localStorage key `MOEBEL_CLICKOUT_ID` |
| Final partner URL | https://www.naturwohnen.de/moebel/regale/arbor-regalboden-schmal_560050_22763/?ReferrerID=13.00&moeclid=05f8a6a4-7bd1-4f37-b860-b0afeb75414e |

## Recommendations

- No action required for the Base Part — it works correctly.
- To fully validate the integration, run a follow-up test that includes placing a real test order so the Conversion Tag can be verified and the partner's PARTNER_KEY can be captured and (optionally) cross-checked against ACM.
- Relevant documentation for the partner's Client-Side integration: [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html) and [Manual Client-Side Integration](https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html)
