# Sales Tracking Test Report — Wohnschick (DE)

| | |
|---|---|
| **Partner** | Wohnschick (*Wohn Schick* / GO-DE) |
| **Market** | DE (Germany) |
| **Partner domain** | `www.wohn-schick.de` |
| **Date** | 2026-05-26 22:53:12 |
| **Jira ticket** | ACM-3091 |
| **Overall result** | ⚠️ **NOT COMPLETED** — the checkout could not be completed (partner checkout returns HTTP 500), so no order was placed and the test could not be finished |
| **Shop platform** | Shopware 6 |
| **Partner CMP** | Usercentrics |

---

## Phase status summary

| Phase | Result |
|---|---|
| Phase 0 — Pre-test setup & portal consent | ✅ PASS |
| Phase 1 — Navigation & moeclid capture | ✅ PASS |
| Phase 2 — moeclid storage check | ⚠️ INCONCLUSIVE — click ID found, but stored in a non-standard location (`MOEBEL_CLICKOUT_ID` cookie); does not match our server-side or client-side pattern |
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

## Phase 2 — moeclid storage check

- Pre-clean: partner-domain storage cleared, page reloaded with `moeclid` in URL.
- Initial page state: product page with a **Usercentrics** consent banner. No blocking newsletter modal.
- Cookie consent: **Usercentrics** — "Alles akzeptieren" accepted.
- Storage check (no reload after consent):
  - A `MOEBEL_CLICKOUT_ID` **cookie** was found, carrying the JSON `{"date":..., "clickId":"108adadc-00a2-4e76-b73b-4a69bea20f00"}` (clickId matches the URL).
  - No cookie named `moeclid`; no `MOEBEL_CLICKOUT_ID` entry in localStorage.
- **Verdict: INCONCLUSIVE — storage location does not match either supported integration pattern.** Our server-side integration stores the click ID in a cookie named **`moeclid`**; our client-side integration stores **`MOEBEL_CLICKOUT_ID`** in **localStorage**. Here the value is in a **`MOEBEL_CLICKOUT_ID` cookie**, which is neither. So even though a click ID is present, it cannot be treated as a correctly-implemented base setup — the conversion side may not read it as expected. This needs review against the integration the partner actually set up. (It could not be validated end-to-end anyway, because the checkout blocked the conversion test — see Phase 3.)

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

Two separate findings:

1. **Checkout blocked (primary blocker):** the partner's own **checkout confirmation page (`/checkout/confirm`) returns an HTTP 500 server error**, so no order can be finalised. This affects the partner's normal checkout (real customers would hit the same error), independent of moebel.de tracking. Until it is fixed, the Conversion Part cannot be tested because no order can be placed.
2. **Non-standard click-ID storage (needs review):** the click ID is stored in a `MOEBEL_CLICKOUT_ID` **cookie**, which matches neither our server-side pattern (cookie named `moeclid`) nor our client-side pattern (`MOEBEL_CLICKOUT_ID` in localStorage). So the storage cannot be treated as a correctly-implemented setup; it should be checked against the integration type the partner actually uses.

## Recommendations

- Partner must investigate the **HTTP 500 on `/checkout/confirm`** in their Shopware logs (likely a payment/shipping method or checkout plugin exception — note: Adyen appears to be in TEST mode `checkoutshopper-test.adyen.com`, and a `saleschecker.io` script fails with a certificate error on the confirm page; either could be implicated).
- Review the click-ID storage: it is currently in a `MOEBEL_CLICKOUT_ID` **cookie**, which is neither the server-side (`moeclid` cookie) nor the client-side (`MOEBEL_CLICKOUT_ID` localStorage) location. Confirm which integration the partner implemented and that the click ID is stored where the conversion side expects to read it.
- Re-run the test once the checkout completes successfully, to validate the conversion end-to-end.

## Test Data References

| Key | Value |
|---|---|
| moeclid | `108adadc-00a2-4e76-b73b-4a69bea20f00` |
| partnerId (portal redirect) | `33d93ff9-0975-44a9-8d50-469b6d1cc2f2` |
| PARTNER_KEY used in sales call | Not captured — Conversion Part not reached (checkout blocked) |
| Order number | None — no order could be placed |
| Product | LEA Sitzkissen 40x40 (7,99 €) |

_Created by Sales Tracking Test Automation_
