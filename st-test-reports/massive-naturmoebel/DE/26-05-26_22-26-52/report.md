# Sales Tracking Test Report — massive-naturmoebel (DE)

| | |
|---|---|
| **Partner** | massive-naturmoebel (*Massive Naturmöbel*) |
| **Market** | DE (Germany) |
| **Partner domain** | `massive-naturmoebel.de` |
| **Date** | 2026-05-26 22:26:52 |
| **Jira ticket** | ACM-3099 |
| **Overall result** | ✅ **PASS** — Base Part working; Conversion confirmed present in the ACM tool (sales record exists for order 000022086) |
| **Integration type** | **GTM Server-Side** (moeclid stored in a cookie; first-party sGTM container `a.massive-naturmoebel.de` / `GTM-P8JGSG`) |
| **Shop platform** | Magento (Leonex theme) |

---

## Phase status summary

| Phase | Result |
|---|---|
| Phase 0 — Pre-test setup & portal consent | ✅ PASS |
| Phase 1 — Navigation & moeclid capture | ✅ PASS |
| Phase 2 — Base Part verification | ✅ WORKING (Server-Side / Cookie) |
| Phase 3 — Purchase flow | ✅ Order placed (000022086) |
| Phase 4 — Conversion Part | ✅ Confirmed in ACM (sales record present for order 000022086) |
| Phase 5 — Console errors | ✅ No moebel.de-related errors |

---

## Phase 0 — Pre-test setup

- Portal: `https://www.moebel.de`
- Browser state cleared on the portal domain (cookies + localStorage + sessionStorage); global history cleared (user-authorized).
- Portal CMP banner detected via accessibility snapshot and accepted (`Akzeptieren`). `user-consent=...Optin...` cookie confirmed set; `visitor_status=new_visitor` confirmed a clean first-visit state.
- Note: a small number of third-party analytics cookies (`_ga`, `_fbp`, `_gcl_au`, `_uetsid`) could not be removed via JS (not consent/first-visit relevant).

## Phase 1 — Navigation & moeclid capture

- Partner located in the **shops listing** (`https://www.moebel.de/shops/massive-naturmoebel`), confirmed via exact match "Massive Naturmöbel".
- Cheapest product opened **by clicking the product link** in the live DOM (not direct navigation). Redirect carried `partnerId=bdaa675c-74fc-467d-805e-d98a653ed7b5&partnerName=massive+naturmoebel`.
- Product: **Nachtkommode Queens in Wildeiche massiv**
- Final URL on partner domain: `https://massive-naturmoebel.de/nachtkommode-queens.html?...&moeclid=191c18b7-0159-4bef-a64e-c8cfdc70ea1d`
- **moeclid present:** ✅ `191c18b7-0159-4bef-a64e-c8cfdc70ea1d`

## Phase 2 — Base Part verification

- Pre-clean: partner-domain cookies/localStorage/sessionStorage cleared, page reloaded with `moeclid` still in the URL (true first-visit).
- Initial page state: product page with a **CookieFirst** consent banner. No blocking newsletter modal (only an embedded footer newsletter form).
- Cookie consent: **CookieFirst** — "Akzeptieren Sie alle cookies" accepted. Banner dismissed on first click; no second stage.
- Storage check (no reload after consent):
  - **`moeclid` cookie found:** ✅ value `191c18b7-0159-4bef-a64e-c8cfdc70ea1d` — **matches the URL parameter exactly**
  - `MOEBEL_CLICKOUT_ID` localStorage: not present (null)
- **Base Part verdict: WORKING.** Storage type = **Server-Side (Cookie)**. The moeclid cookie is readable via `document.cookie` (JS-set, not HttpOnly), and was stored on the same page load after consent without any reload.

## Phase 3 — Purchase flow

| Field | Value |
|---|---|
| Product | Nachtkommode Queens in Wildeiche massiv (Holzart: Wildeiche; geriffeltes Vorderstück: links) |
| Quantity | 1 |
| Cart value (base) | 265,88 € gross / 223,43 € net (incl. 42,45 € VAT) |
| Shipping | 0,00 € (free — order over 100 €, Spedition) |
| Currency | EUR |
| Checkout method | Guest (email `partner@moebel.de` recognized as registered, but guest checkout was available and not blocked → login not required) |
| Address used | Primary (Mia Moebel.de-Test, Moebel.de Str. 3, 20095 Hamburg, DE) |
| Payment method | **Vorkasse** (`banktransfer`, -3% Skonto) |
| **Order ID** | **000022086** (captured from the visible confirmation page — "Ihre Bestellnummer ist: 000022086") |
| Order ID source | `page_text` (trusted) |

Note: a Brevo chat widget popped open over the checkout mid-flow and had to be dismissed; it was a partner-side overlay, unrelated to tracking.

## Phase 4 — Conversion Part verification (read-only)

This is a **server-side** integration, so the moebel.de sales API call (`redirect.moebel.de/api/1.0/moebel/de/sales`) fires server-to-server from the sGTM container and is **not observable from the browser**. The browser-side checks below therefore confirm the *prerequisites* for the server-side conversion, not the conversion call itself.

| Check | Result |
|---|---|
| Sales call in Performance API (`.../moebel/de/sales`) | Not found — **expected** for server-side (call leaves from sGTM server, not browser) |
| `window.MOEBEL_SALES` present | No — **expected** for server-side (that is a client-side object) |
| **PARTNER_KEY used by partner in the sales call** | **Not exposed client-side** — configured server-side in the sGTM tag; cannot be captured from the browser. Confirm in ACM/dashboard. |
| MARKET global | Not exposed client-side |
| moeclid cookie present on confirmation page | ✅ `191c18b7-0159-4bef-a64e-c8cfdc70ea1d` (so sGTM can read it) |
| `purchase` dataLayer event | ✅ present and correct (see below) |
| sGTM container | ✅ active — `a.massive-naturmoebel.de` (first-party), container `GTM-P8JGSG` |

**`purchase` dataLayer event (feeds the server-side conversion tag):**
```json
{
  "ecommerce": {
    "currencyCode": "EUR",
    "purchase": {
      "actionField": { "id": "000022086", "revenue": 257.9036, "tax": 41.18,
                       "shipping": 0, "affiliation": "Massive Naturmoebel",
                       "shipping_country": "DE" },
      "products": [ { "id": "20500502-1", "name": "Nachtkommode Queens in Wildeiche massiv",
                      "price": 223.43, "quantity": 1 } ]
    }
  }
}
```
- The order id in the dataLayer (`000022086`) matches the confirmation-page order number ✅.
- `revenue` 257.90 € gross reflects the **3% Vorkasse Skonto** applied (216.72 € net × 1.19). The base order net was 223.43 €; with the -3% prepayment discount it is 216.72 € net. Worth a sanity-check that the value moebel.de ultimately receives is the intended (net) figure.

**PARTNER_KEY verification:** skipped — no expected key provided by the tester. (PARTNER_KEY also could not be captured from the browser because the integration is server-side.)

## Phase 5 — Console errors

- No moebel.de sales-tracking errors. **No "Received sales object" error.**
- Partner-side errors present but **unrelated to moebel.de tracking**:
  - 404 on `magepack/bundle-common.min.js` (Magento asset)
  - `ReferenceError: Adcell is not defined` (Adcell affiliate tracking)
  - `ReferenceError: fbq is not defined` (Facebook Pixel not loaded in their sGTM)
  - Magento `imageTemplate` / `shoppingCartUrl` jQuery exceptions
  - Generic sGTM `Uncaught [object Object]`

---

## Result

No issues detected. The integration works end-to-end:

1. **Base Part (confirmed working):** the `moeclid` is read from the landing URL and stored in a first-party cookie immediately after consent. Verified — cookie value matches the URL parameter.
2. **Conversion Part (confirmed in ACM):** the order confirmation page pushes a correct `purchase` event into the dataLayer, the server-side container forwards the conversion, and the **sales record was confirmed present in the ACM tool** for order 000022086 (verified by the tester). Conversion tracking is working.

## Recommendations

- Sanity-check the value sent: the dataLayer reports the post-Skonto figure (216.72 € net) rather than the base net (223.43 €). Confirm this is the value moebel.de should attribute.
- Cancel the test order 000022086 in the partner backoffice.

---

## Test Data References

| Key | Value |
|---|---|
| moeclid | `191c18b7-0159-4bef-a64e-c8cfdc70ea1d` |
| partnerId (portal redirect) | `bdaa675c-74fc-467d-805e-d98a653ed7b5` |
| PARTNER_KEY used in sales call | Not capturable from browser (server-side integration) — confirm in ACM |
| Order number | 000022086 (confirmation page) |
| sGTM container | `GTM-P8JGSG` on `a.massive-naturmoebel.de` |
| Sales endpoint (DE) | `redirect.moebel.de/api/1.0/moebel/de/sales` |

_Created by Sales Tracking Test Automation_
