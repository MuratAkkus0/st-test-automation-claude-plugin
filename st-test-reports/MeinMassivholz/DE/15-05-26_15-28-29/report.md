# Sales Tracking Test Report — meinmassivholz (DE)

| Field | Value |
| --- | --- |
| Partner | meinmassivholz |
| Market | DE (Germany) |
| Portal | https://www.moebel.de |
| Partner domain | meinmassivholz.com |
| Test date | 2026-05-15 15:28:33 |
| Tester | Murat Akkus |
| Run mode | **Partial — checkout reached, order intentionally NOT submitted** (per tester instruction) |
| Overall result | **Base Part WORKING — Conversion Part NOT TESTED** |

> ⚠️ **Modified run.** The tester explicitly instructed the automation to proceed only as far as the final checkout page and NOT to submit any order. The Conversion-Tag (Phase 4) part of the test was therefore skipped. The Base-Tag part of the integration has been fully verified.

---

## Phase 0 — Pre-test setup

- BrowserOS profile cleared (history + portal cookies + partner-domain cookies/localStorage/sessionStorage cleared before any tracking ran).
- Portal `moebel.de` opened in a fresh tab.
- Portal CMP banner detected via accessibility snapshot at element `[379] button "Akzeptieren"`.
- Consent accepted via Layer 1 (snapshot); `CookieConsent` marker present in `document.cookie` after click.
- Banner re-scan confirmed the banner was gone post-click.

| Step | Result |
| --- | --- |
| Browser state cleared (portal + partner) | ✅ |
| Portal CMP accepted | ✅ via snapshot click |
| Portal consent cookie set | ✅ |

---

## Phase 1 — Navigation & moeclid capture

| Step | Result |
| --- | --- |
| Partner located on `/shops/meinmassivholz?ps=asc` listing | ✅ Found in shops listing (no brands fallback needed) |
| Cheapest product identified | ✅ Nachtkonsole EGHOLM, Kernbuche — 270,00 € |
| Product redirect href contains `partnerId` | ✅ `partnerId=1f237950-90fa-4447-a7f4-f0ffc2a593f8` |
| Partner page opened via CLICK on snapshot element (not direct URL nav) | ✅ |
| Final URL contains `moeclid=` | ✅ |

**Redirect URL captured:**

```
https://meinmassivholz.com/p/nachtkonsole-egholm-kernbuche-mm10050.3?moeclid=aaac3036-08d4-42df-bef0-815ec35a04b0
```

**moeclid value:** `aaac3036-08d4-42df-bef0-815ec35a04b0`

---

## Phase 2 — Base Part verification

| Step | Result |
| --- | --- |
| Partner-domain pre-clean (cookies + localStorage + sessionStorage cleared) | ✅ |
| Page reloaded with `moeclid=...` still in URL | ✅ |
| Initial page state snapshot taken | ✅ |
| Cookie consent banner present at first paint | ❌ — no in-page banner shown |
| Datenschutz-Einstellungen reopener used to inspect CMP | ✅ Consentmanager modal opened |
| Consent state | Already granted (server-side via consentmanager fingerprint) — "Ihre Entscheidung: 2026-05-15" |
| Consent confirmed via "Speichern + Beenden" | ✅ |
| moeclid cookie (server-side) | ❌ not found |
| `MOEBEL_CLICKOUT_ID` in localStorage | ✅ `{"date":"2026-05-15T13:21:03.932Z","clickId":"aaac3036-08d4-42df-bef0-815ec35a04b0"}` |
| Captured clickId matches URL moeclid | ✅ MATCH |
| **Base Part verdict** | **✅ WORKING (Client-Side Integration via localStorage)** |

**CMP detected:** Consentmanager (cookies `__cmpconsent30733` / `__cmpcccu30733` — account id `30733`)

**Storage layout observed:**
- localStorage key `MOEBEL_CLICKOUT_ID` (Client-Side, expected)
- No `moeclid` cookie (Server-Side path not in use)
- Standard cookies set: `timezone`, `_gcl_au`, `_swag_ga_*` (Shopware analytics + Google Conversion Linker)

The Base Tag fires on page load with consent already active and stores the moeclid from the URL query into `MOEBEL_CLICKOUT_ID` in `localStorage` — this is the canonical Client-Side integration behaviour.

---

## Phase 3 — Purchase flow (MODIFIED — stopped at confirmation page)

The full guest checkout was walked through, but the order was **NOT** submitted per the tester's explicit instruction.

| Step | Result |
| --- | --- |
| Product added to cart | ✅ Cart slide-in showed 1 × Nachtkonsole EGHOLM @ 270,00 € |
| "Zur Kasse" clicked | ✅ Reached checkout step 2 (Anmelden / Als Gast bestellen) |
| Guest form filled with DE test identity | ✅ See below |
| AGB checkbox checked | ✅ |
| FriendlyCaptcha solved | ✅ Auto-solved (`frc-container frc-success`, hidden response token present) |
| "Weiter" clicked | ✅ Reached checkout step 3 (Bestellung abschließen) |
| Final URL on confirmation page | `https://meinmassivholz.com/checkout/confirm` |
| Payment method preselected | Vorkasse (✅ matches priority Vorkasse > Bank Transfer > Credit Card) |
| Shipping method preselected | Kühne+Nagel (Stückgutspedition) |
| Order total | 270,00 € (Versandkosten 0,00 €) |
| Delivery window | 22.05.26 – 26.05.26 |
| Order submission ("Zahlungspflichtig bestellen") | 🛑 **NOT clicked** — automation stopped here per tester instruction |

**Form data used:**

| Field | Value |
| --- | --- |
| Anrede | Frau |
| Vorname | Mia |
| Nachname | Moebel.de-Test |
| Email | partner@moebel.de |
| Straße + Hausnr. | Moebel.de Str. 3 |
| PLZ | 20095 |
| Ort | Hamburg |
| Land | Deutschland |
| Telefon | 040210910730 |

---

## Phase 4 — Conversion Part verification

🛑 **SKIPPED — no order submitted.** The Conversion Tag fires on the order-success page after `/checkout/finish?orderId=...` is reached; that page is only created when the order is submitted. Because the tester explicitly forbade order submission, there is no order-success page to inspect and the Performance API has no `/sales` call to read.

Implications:
- `MOEBEL_SALES`, `PARTNER_KEY`, `MARKET`, payload, and the sales endpoint call **were not captured** on this run.
- The Conversion Tag integration cannot be confirmed or refuted from this run.
- A follow-up run that allows order submission is required to verify the Conversion side end-to-end.

| Field | Value |
| --- | --- |
| Sales endpoint call observed | NOT TESTED |
| PARTNER_KEY captured | NOT TESTED — no order placed |
| MARKET captured | NOT TESTED — no order placed |
| Payload validation | NOT TESTED |
| PARTNER_KEY verification | Not applicable — no expected key was provided by the tester, and no actual key was captured |

---

## Phase 5 — Console / errors check

Console log read on the `meinmassivholz.com/checkout/confirm` page (post-form-submit, pre-order-submit):

| Severity | Source | Message |
| --- | --- | --- |
| error | `theme/.../js/dne-custom-css-js/dne-custom-css-js.js:223` | `SyntaxError: Unexpected end of input` |

This is a partner-side JS error in a custom Shopware theme script (`dne-custom-css-js`). It is **unrelated to the Sales Tracking integration** — the moeclid was still stored correctly in localStorage at every step, including on the confirmation page. The error should be passed back to the partner as a quality issue in their theme, but it is not a blocker for ST.

---

## Phases status summary

| Phase | Status |
| --- | --- |
| 0 — Pre-test setup | ✅ Completed |
| 1 — Navigation & moeclid capture | ✅ Completed |
| 2 — Base Part verification | ✅ WORKING (Client-Side, localStorage) |
| 3 — Purchase flow | ⚠️ Partial — reached final confirmation page, order intentionally NOT submitted |
| 4 — Conversion Part verification | 🛑 SKIPPED — no order placed |
| 5 — Console / errors check | ⚠️ 1 partner-side theme JS error (unrelated to ST) |

---

## Integration type

**GTM Client-Side or Manual Client-Side** — the moeclid is read from the URL and persisted in `MOEBEL_CLICKOUT_ID` in `localStorage`. The presence of `_gcl_au` and the Consentmanager + Shopware setup suggests a GTM-based implementation is most likely.

---

## Root Cause Analysis

There is no failure to attribute on the Base side — the Base Tag is correctly configured, fires on page load with consent active, and writes the moeclid from the URL into `MOEBEL_CLICKOUT_ID` in localStorage. The Conversion side could not be exercised in this run because no order was submitted.

The partner-side console error (`dne-custom-css-js.js:223 SyntaxError: Unexpected end of input`) originates from a custom theme JS file and is not related to the ST tracking implementation.

---

## Recommendations

1. **Re-run the test with order submission enabled** to verify the Conversion Tag end-to-end. The same Base Part run today proves that a sale call would carry the correct clickId, but the `PARTNER_KEY`, `MARKET`, payload `total/items/shipping`, and the network call against the DE sales endpoint cannot be confirmed without a real order.
2. **Optional — flag the unrelated theme JS error to the partner.** The file `theme/.../js/dne-custom-css-js/dne-custom-css-js.js` has a syntax error at line 223. It does not affect ST tracking, but it is a quality issue worth fixing.
3. **Reference documentation** for follow-up testing or troubleshooting on the Conversion Tag side:
   - [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)
   - [Manual Client-Side Integration](https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html)

---

## Test Data References

| Field | Value |
| --- | --- |
| moeclid (URL query) | `aaac3036-08d4-42df-bef0-815ec35a04b0` |
| moeclid (localStorage `MOEBEL_CLICKOUT_ID.clickId`) | `aaac3036-08d4-42df-bef0-815ec35a04b0` |
| partnerId (from redirect URL) | `1f237950-90fa-4447-a7f4-f0ffc2a593f8` |
| partnerName (from redirect URL) | `MeinMassivholz` |
| PARTNER_KEY captured by partner in the sales call | **Not captured — no order submitted** |
| MARKET captured by partner in the sales call | **Not captured — no order submitted** |
| Sales endpoint expected for this market | `redirect.moebel.de/api/1.0/moebel/de/sales` |
| Order ID | **Keine Bestellung freigegeben** (order intentionally not submitted) |
| Test product | Nachtkonsole EGHOLM, Kernbuche (MM10050.3) — 270,00 € |
| CMP | Consentmanager (account id `30733`) |
| Test identity | DE — Mia Moebel.de-Test, Moebel.de Str. 3, 20095 Hamburg |

---
_Created by Sales Tracking Test Automation_
