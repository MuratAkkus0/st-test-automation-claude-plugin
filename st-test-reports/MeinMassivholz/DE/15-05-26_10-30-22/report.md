# Sales Tracking Test Report — MeinMassivholz (DE)

| Field | Value |
| --- | --- |
| Partner | MeinMassivholz |
| Market | DE (Germany) |
| Portal | https://www.moebel.de |
| Partner domain | meinmassivholz.com |
| Test date / time | 2026-05-15 10:30:22 |
| Tester | Murat Akkus (murat.akkus@moebel.de) |
| Integration type detected | **GTM Client-Side** (moeclid stored in `localStorage.MOEBEL_CLICKOUT_ID`; `.sale()` call resolves values from `google_tag_manager["rm"][...]` macros) |
| Overall result | 🔴 **FAIL — Conversion Part broken** |

---

## Phases summary

| Phase | Result | Notes |
| --- | --- | --- |
| 0 — Pre-test setup | ✅ PASS | Browser state cleared, moebel.de portal CMP accepted on first snapshot. |
| 1 — Navigation & moeclid | ✅ PASS | MeinMassivholz found on `/shops` listing. Click on the cheapest product opened `meinmassivholz.com` with moeclid in URL. |
| 2 — Base Part | ✅ PASS | After accepting Consentmanager.net CMP, moeclid stored in `localStorage.MOEBEL_CLICKOUT_ID` matching URL value. |
| 3 — Purchase flow | ✅ PASS | Guest checkout (Shopware-based shop), Vorkasse, primary address. Order 31708 confirmed on page. |
| 4 — Conversion Part | 🔴 **FAIL** | `.sale()` call is attempted but with `total`, `shipping`, `items`, `orderId` all undefined. Sanitizer rejects the object — no network call to the sales endpoint. |
| 5 — Console errors | 🔴 **FAIL** | `Can not convert total to number`, `Error sanitizing sale`, `Received sales object: {currency:"EUR", orderId:"undefined"}`. |

---

## Phase 1 — Navigation & moeclid capture

| Field | Value |
| --- | --- |
| Listing source | `shops` (`https://www.moebel.de/shops?ps=asc`) |
| Partner shop page | https://www.moebel.de/shops/meinmassivholz?ps=asc |
| Product clicked | Nachtkonsole EGHOLM, Kernbuche — 50x34 cm — mit Schublade (cheapest, 270,00 €) |
| Click method | Live-DOM click via snapshot (NOT `new_page(url=redirect_href)`) |
| Portal `partnerId` in redirect href | `1f237950-90fa-4447-a7f4-f0ffc2a593f8` |
| `partnerName` in redirect href | `MeinMassivholz` |
| Final partner URL | https://meinmassivholz.com/p/nachtkonsole-egholm-kernbuche-mm10050.3?moeclid=ee3f55cc-47c1-4135-8264-3a9acfc85c17 |
| moeclid present in URL | ✅ Yes |
| moeclid value | `ee3f55cc-47c1-4135-8264-3a9acfc85c17` |

---

## Phase 2 — Base Part verification

| Field | Value |
| --- | --- |
| Pre-clean reload performed | ✅ Yes (cookies + localStorage + sessionStorage cleared, page reloaded with moeclid still in URL) |
| Initial page state | Product page with Consentmanager.net CMP banner visible at the top |
| CMP platform | **consentmanager.net** (Layer 1 — snapshot detection) |
| Consent banner type | Banner (does not fully block content) |
| Consent action | ✅ Accepted via "Alle akzeptieren" |
| Newsletter / email popup after consent | None present |
| Cookies after consent | `timezone`, `__cmpconsent30733`, `__cmpcccu30733`, `_gcl_au`, `_swag_ga_ga_R41WG54ZTX`, `_swag_ga_ga`, `_swag_ga_au` |
| `moeclid` cookie present? | ❌ No |
| `localStorage.MOEBEL_CLICKOUT_ID` present? | ✅ Yes |
| Stored clickId | `ee3f55cc-47c1-4135-8264-3a9acfc85c17` |
| Matches URL moeclid? | ✅ Yes |
| Storage timestamp | `2026-05-15T08:26:57.817Z` |
| Verdict | **Base Part WORKING — Client-Side (localStorage)** |

---

## Phase 3 — Purchase flow

| Field | Value |
| --- | --- |
| Platform | Shopware-based shop (form fields use `billingAddress[...]` naming) |
| Checkout method | Guest checkout (no email-already-registered prompt; FriendlyCaptcha auto-solved in the background) |
| Address used | Primary (Mia Moebel.de-Test, Moebel.de Str. 3, 20095 Hamburg) |
| Payment method | Vorkasse |
| Shipping carrier | Kühne+Nagel (default) |
| Subtotal (Zwischensumme) | 270,00 € |
| Shipping cost | 0,00 € |
| Gross total (Gesamtsumme) | 270,00 € |
| Net total (Gesamtnettosumme) | 226,89 € |
| VAT 19% | 43,11 € |
| Currency | EUR |
| Order ID | **31708** (from page text — `Ihre Bestellnummer: 31708`) |
| Order ID source | `page_text` (trusted — visible on confirmation page) |
| URL parameter | `orderId=019e2ac0775e728492056ff3a2510351` (internal hash, not the customer-facing reference) |
| Confirmation URL | https://meinmassivholz.com/checkout/finish?orderId=019e2ac0775e728492056ff3a2510351 |

---

## Phase 4 — Conversion Part verification

| Field | Value |
| --- | --- |
| `window.MOEBEL_SALES` loaded? | ✅ Yes |
| `window.PARTNER_KEY` | `1f237950-90fa-4447-a7f4-f0ffc2a593f8` |
| `window.MARKET` | `de` ✅ |
| `localStorage.MOEBEL_CLICKOUT_ID.clickId` available at sale time? | ✅ Yes (`ee3f55cc-47c1-4135-8264-3a9acfc85c17`) |
| Sales endpoint call to `redirect.moebel.de/api/1.0/moebel/de/sales`? | ❌ **No** — not present in `performance.getEntriesByType('resource')` |
| Inline `.sale(...)` call present in page source? | ✅ Yes — but with broken arguments |
| Captured sale call source | `MOEBEL_SALES.sale({total:google_tag_manager["rm"]["124496192"](8),shipping:google_tag_manager["rm"]["124496192"](9),currency:"EUR",orderId:"undefined",items:google_tag_manager["rm"]["124496192"](10)});` |

### PARTNER_KEY captured

| Field | Value |
| --- | --- |
| PARTNER_KEY used by partner in the sales call | `1f237950-90fa-4447-a7f4-f0ffc2a593f8` |
| MARKET value used | `de` |
| Match against portal's `partnerId` (redirect href) | ✅ Same UUID |
| PARTNER_KEY verification | Skipped — no expected key provided by tester |

### Verdict

🔴 **Conversion Part FAILED.** The `MOEBEL_SALES.sale(...)` call is invoked on the confirmation page with **`total`, `shipping`, `items` and `orderId` all `undefined`**. The SDK's sanitizer rejects the payload (`Can not convert undefined to number (float)`) and never fires the network call to the sales endpoint. No order is reaching ACM.

---

## Phase 5 — Console errors

| Level | Source | Message |
| --- | --- | --- |
| error | console | `Can not convert total to number Can not convert undefined to number (float)` |
| error | console | `Error sanitizing sale Can not convert undefined to number (float)` |
| error | console | `Received sales object: {"currency":"EUR","orderId":"undefined"}` |
| error | exception | `SyntaxError: Unexpected end of input` (in `/theme/.../dne-custom-css-js/dne-custom-css-js.js?1777360618`) — unrelated to ST integration |
| warning | console | `FriendlyCaptcha: No div was found with .frc-captcha class` — unrelated to ST integration |

Sales-object errors found: **Yes** — duplicated twice in the same page load (the tag fires twice with the same broken payload).

---

## Root Cause Analysis

The partner has implemented the Sales Tracking integration via **GTM Client-Side**:
- The Base Tag is wired up correctly and fires on `Page View — All Pages`. The moeclid is captured from the URL and persisted to `localStorage.MOEBEL_CLICKOUT_ID` immediately after consent acceptance. This part works as documented.
- The Conversion Tag is also injected into the confirmation page and the `MOEBEL_SALES` SDK is loaded with the correct `PARTNER_KEY` and `MARKET`.

However, the Conversion Tag's **call arguments resolve to `undefined` for every value that should come from the partner's GTM data layer**:

```js
MOEBEL_SALES.sale({
  total:    google_tag_manager["rm"]["124496192"](8),   // → undefined
  shipping: google_tag_manager["rm"]["124496192"](9),   // → undefined
  currency: "EUR",                                       // ✓ hard-coded
  orderId:  "undefined",                                 // → literal string "undefined" (likely `String({{ Order ID }})` in GTM)
  items:    google_tag_manager["rm"]["124496192"](10),  // → undefined
});
```

The four bracketed `rm` macros (`(8)`, `(9)`, `(10)`) are GTM's compiled forms of the partner's data-layer variables for `total`, `shipping`, and `items`. All three return `undefined` on this page load, which means **the partner's confirmation page is not pushing the order's `total`, `shipping`, and `items` into the data layer**. The `orderId` macro evaluates the same way but is being stringified into a hard-coded `"undefined"` (a classic `{{ Order ID }}` -> `String(undefined)` problem in GTM's variable resolution).

Because `total` is undefined, the moebel.de SDK's input sanitizer aborts the call with `Can not convert total to number`. No network request to `https://redirect.moebel.de/api/1.0/moebel/de/sales` is fired. The conversion is lost — and this is the case for every order this shop will produce until the data layer is fixed.

The page DOM clearly has the data the GTM variables should read (the values 270.00, 226.89, 0.00, MM10050.3 are all in the order-summary block), so the fix is on the partner side — the data layer push for the `Thank You` / `checkout/finish` page needs to populate the variables that GTM is binding to.

---

## Recommendations (for partner)

1. **Fix the GTM data layer on the order confirmation page (`/checkout/finish`).** Push the order's `total` (use the **net** value `226.89`, not the gross `270.00`), `shipping` (`0.00`), and `items` array into `window.dataLayer` before the moebel.de Conversion Tag fires. Either a hard-coded `<script>dataLayer.push({...})</script>` block emitted by the Shopware theme on the success page, or a server-rendered JSON block read by a GTM Custom JavaScript variable, will both work.
2. **Fix the `orderId` variable in GTM.** The current value `"undefined"` (string) indicates the variable is being stringified before it is resolved (`String({{ Order ID }})` rather than `{{ Order ID }}`). Wire it to the page's `Ihre Bestellnummer` value (e.g. `31708`) directly — without `String(...)`. The order id is visible on the success page as a clean integer.
3. **Re-test once the data layer push is in place.** A second test order is required to verify the Conversion Part end to end. The Base Part does not need to be re-tested.

### Integration documentation

- [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)

---

## Test Data References

| Field | Value |
| --- | --- |
| moeclid (Phase 1) | `ee3f55cc-47c1-4135-8264-3a9acfc85c17` |
| PARTNER_KEY used by partner in the sales call | `1f237950-90fa-4447-a7f4-f0ffc2a593f8` |
| MARKET value used by partner | `de` |
| Order ID | 31708 (from `Ihre Bestellnummer`) |
| Order placed at | 2026-05-15 ~10:28 (Vorkasse — payment pending on partner side, please cancel) |
| Sales endpoint (expected) | https://redirect.moebel.de/api/1.0/moebel/de/sales |
| Test identity (DE) | Mia Moebel.de-Test, Moebel.de Str. 3, 20095 Hamburg, partner@moebel.de, 040210910730 |
