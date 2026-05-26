# Sales Tracking Test Report — Wohnschick (DE)

| | |
|---|---|
| **Partner** | Wohnschick (*Wohn Schick* / GO-DE) |
| **Market** | DE (Germany) |
| **Partner domain** | `www.wohn-schick.de` |
| **Date** | 2026-05-26 22:53:12 |
| **Jira ticket** | ACM-3091 |
| **Overall result** | ⚠️ **NOT COMPLETED** — Base Part works, but the checkout could not be completed (partner checkout returns HTTP 500), so no order was placed and the Conversion Part could not be verified |
| **Shop platform** | Shopware 6 |
| **Partner CMP** | Usercentrics |

---

## Phase status summary

| Phase | Result |
|---|---|
| Phase 0 — Pre-test setup & portal consent | ✅ PASS |
| Phase 1 — Navigation & moeclid capture | ✅ PASS |
| Phase 2 — Base Part verification | ✅ WORKING (moeclid stored in cookie) |
| Phase 3 — Purchase flow | 🛑 BLOCKED — `/checkout/confirm` returns HTTP 500; no order could be placed |
| Phase 4 — Conversion Part | ⏭️ Not reached (no order to verify) |

---

## Phase 0 — Pre-test setup

- Portal `https://www.moebel.de` opened, browser state cleared, portal CMP accepted (`Akzeptieren`). Consent cookie confirmed.

## Phase 1 — Navigation & moeclid capture

- Partner located in the **shops listing**: `https://www.moebel.de/shops/wohn-schick` (display name "Wohn Schick").
- Cheapest product opened by clicking the product link. Redirect carried `partnerId=33d93ff9-0975-44a9-8d50-469b6d1cc2f2&partnerName=wohn-schick`.
- Product: **LEA Sitzkissen 40x40** (7,99 €)
- Final URL: `https://www.wohn-schick.de/lea-sitzkissen-40x40/1206229-7?...&moeclid=108adadc-00a2-4e76-b73b-4a69bea20f00`
- **moeclid present:** ✅ `108adadc-00a2-4e76-b73b-4a69bea20f00`

## Phase 2 — Base Part verification

- Pre-clean: partner-domain storage cleared, page reloaded with `moeclid` in URL.
- Initial page state: product page with a **Usercentrics** consent banner. No blocking newsletter modal.
- Cookie consent: **Usercentrics** — "Alles akzeptieren" accepted.
- Storage check (no reload after consent):
  - **`MOEBEL_CLICKOUT_ID` cookie found:** ✅ clickId `108adadc-00a2-4e76-b73b-4a69bea20f00` — **matches the URL parameter exactly**
  - `moeclid` cookie: not present; `MOEBEL_CLICKOUT_ID` localStorage: not present
- **Base Part verdict: WORKING.** The moeclid is stored in a `MOEBEL_CLICKOUT_ID` cookie carrying the JSON structure `{"date":..., "clickId":...}`. The cookie is readable via `document.cookie` (JS-set) and persisted across login.

## Phase 3 — Purchase flow 🛑 BLOCKED

- Product LEA Sitzkissen 40x40 added to cart (7,99 €), 1 unit.
- Proceeded to checkout (`/checkout/confirm`). As a guest, the email `partner@moebel.de` is already a registered customer account here, and the guest confirm page errored.
- **Logged in** with the DE test credentials (`partner@moebel.de`) successfully (reached `/account`). Login cleared the cart; the product was re-added and the moeclid cookie survived login.
- On `/checkout/confirm` — **the page returns HTTP 500** and renders only the generic Shopware error *"Leider ist etwas schiefgelaufen"*. The payment/shipping selection and the place-order button never render. Reproduced:
  - as guest → confirm page error
  - logged in → `/checkout/confirm` HTTP **500**
  - after reload → HTTP **500** again
- Console confirms: `Failed to load resource: the server responded with a status of 500 () — https://www.wohn-schick.de/checkout/confirm`. (Other console entries are unrelated CSP violations for third-party scripts/fonts: Cloudflare beacon, TikTok pixel, Clarity, saleschecker.io cert error.)
- **No order could be placed.** Because no order was submitted, no test order needs cancelling.

## Phase 4 — Conversion Part

Not reached — there is no order confirmation page to read. The Conversion Part (sales call) cannot be verified until a purchase can be completed.

---

## Root cause analysis

The moebel.de tracking integration's **Base Part is working correctly** — the moeclid is captured from the landing URL and stored (in a `MOEBEL_CLICKOUT_ID` cookie) after consent, and it survives login. The blocker is **not** a tracking issue: the partner's own **checkout confirmation page (`/checkout/confirm`) returns an HTTP 500 server error**, so the order cannot be finalised. This affects the partner's normal checkout (real customers would hit the same error), independent of moebel.de tracking. Until the partner fixes the checkout, the Conversion Part cannot be tested because no order can be placed.

## Recommendations

- Partner must investigate the **HTTP 500 on `/checkout/confirm`** in their Shopware logs (likely a payment/shipping method or checkout plugin exception — note: Adyen appears to be in TEST mode `checkoutshopper-test.adyen.com`, and a `saleschecker.io` script fails with a certificate error on the confirm page; either could be implicated).
- Re-run the Conversion Part test once the checkout completes successfully.
- Base Part requires no action — it is storing the moeclid correctly.

## Test Data References

| Key | Value |
|---|---|
| moeclid | `108adadc-00a2-4e76-b73b-4a69bea20f00` |
| partnerId (portal redirect) | `33d93ff9-0975-44a9-8d50-469b6d1cc2f2` |
| PARTNER_KEY used in sales call | Not captured — Conversion Part not reached (checkout blocked) |
| Order number | None — no order could be placed |
| Product | LEA Sitzkissen 40x40 (7,99 €) |

_Created by Sales Tracking Test Automation_
