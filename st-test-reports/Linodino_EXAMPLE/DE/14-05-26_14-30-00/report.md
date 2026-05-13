# Sales Tracking Integration Test Report

> **EXAMPLE / DEMO REPORT** — Generated for template demonstration. Not a real test run. All identifiers (partner name, moeclid, order ID, PARTNER_KEY, prices) are fabricated.

## Test Information

| Field | Value |
|---|---|
| Partner | Linodino |
| Market | DE |
| Tester | Murat Akkus (murat.akkus@moebel.de) |
| Date | 2026-05-14 14:30:00 |
| Overall Status | **FAIL** |
| Detected Integration Type | GTM Client-Side |

---

## Phase 1 — Redirect & moeclid Capture

| Field | Value |
|---|---|
| Listing page (found via) | shops listing — `https://www.moebel.de/shops/linodino/` |
| Outbound click target | `https://www.moebel.de/c?...&u=https%3A%2F%2Fwww.linodino.de%2F` |
| Final landing URL | `https://www.linodino.de/?moeclid=a3f7c2e1-8b9d-4f6a-9c1e-2d8b4a7f3c5e` |
| moeclid present in URL | Yes |
| moeclid value | `a3f7c2e1-8b9d-4f6a-9c1e-2d8b4a7f3c5e` |

**Verdict:** PASS — moeclid is forwarded through the redirect chain to the partner site.

---

## Phase 2 — Base Part Verification

### Initial Page State (on first load, before consent)
- Cookie consent banner present (Usercentrics CMP, blocking interaction).
- Newsletter / discount popup present in the DOM behind the consent layer.
- Cookies and localStorage empty (expected — consent not yet granted).

### Cookie Consent

| Field | Value |
|---|---|
| Platform | Usercentrics |
| Banner type | "Accept all" button visible without expanding settings |
| Action taken | Accepted |
| Detection layer that fired | Accessibility-tree snapshot match on `button[name="Accept All"]` |

### Email / Newsletter Popup

| Field | Value |
|---|---|
| Present after consent | Yes |
| Dismissed | Yes (close-X button) |

### First Storage Check (immediately after consent)

| Storage | Key | Result |
|---|---|---|
| Cookies | `moeclid` | Not found |
| localStorage | `MOEBEL_CLICKOUT_ID` | Not found |

### Reload Re-check (one reload, then re-check storage)

| Storage | Key | Result |
|---|---|---|
| Cookies | `moeclid` | Not found |
| localStorage | `MOEBEL_CLICKOUT_ID` | Found — `a3f7c2e1-8b9d-4f6a-9c1e-2d8b4a7f3c5e` |

**Failure cause:** `consent_callback_not_configured` — the Base Tag is present and works, but its trigger does not include the page load on which consent is accepted. Storage only fills on the next page load.

**Verdict:** FAIL — Base Tag trigger is not "Page View — All Pages". Real visitors who accept consent and proceed straight to checkout without reloading will not be tracked.

---

## Phase 3 — Order Placement

| Field | Value |
|---|---|
| Item added to cart | Yes (1 product) |
| Checkout flow | Guest checkout, completed |
| Payment method | Vorkasse |
| Order submitted | Yes |
| Order ID source | `page_text` (visible on confirmation page) |
| Order ID | `166094` |
| Net product total | 281.50 EUR |
| Shipping | 5.95 EUR |
| Grand total (gross) | 287.45 EUR |

---

## Phase 4 — Conversion Part Verification

### Sale Request

| Field | Value |
|---|---|
| Endpoint | `https://acm.moebel.de/api/v1/sale` |
| Method | POST |
| HTTP status | 200 OK |
| Response time | 142 ms |
| Captured via | DevTools Network panel filter `acm.moebel.de` |

### Captured Payload (relevant fields)

| Field | Value |
|---|---|
| **PARTNER_KEY used by partner in the sales call** | `LIN_DE_4729` |
| **MARKET** | `DE` |
| moeclid | `a3f7c2e1-8b9d-4f6a-9c1e-2d8b4a7f3c5e` |
| order_id | `166094` |
| total | `281.50` (net, correct) |
| shipping | `5.95` |
| currency | `EUR` |
| items | `[{ id: "art-9914", price: 281.50, qty: 1 }]` |

> **PARTNER_KEY verification skipped** — no expected key provided by tester.

**Verdict:** PASS — Sale call fired with all required fields populated correctly. Net total is net (excludes shipping), shipping is in its own field, items array is non-null.

---

## Phase 5 — Console Errors

| Check | Result |
|---|---|
| `sales_object` errors | None |
| Other moebel-tracking errors | None |
| Other unrelated console errors | 2 (third-party chat widget — not relevant) |

**Verdict:** PASS — no tracking-related console errors.

---

## Phases Status Summary

| Phase | Status |
|---|---|
| Phase 1 — Redirect & moeclid | PASS |
| Phase 2 — Base Part | **FAIL** |
| Phase 3 — Order Placement | PASS |
| Phase 4 — Conversion Part | PASS |
| Phase 5 — Console Errors | PASS |

---

## Root Cause Analysis

The Base Tag in the partner's GTM container is implemented and functions correctly — it reads the `moeclid` URL parameter and writes it to `MOEBEL_CLICKOUT_ID` in localStorage. However, its **trigger is misconfigured**. The tag does not fire on the page load where the user accepts cookie consent; it only fires on the subsequent page load. We verified this by reloading the page once with consent already granted, after which the value appeared in localStorage exactly as expected.

In production, this means any visitor who:

1. Lands on the shop with `?moeclid=...` in the URL,
2. Accepts the consent banner,
3. Proceeds straight to a product / checkout without reloading the landing page

…will NOT have their click ID persisted. Their subsequent conversion cannot be attributed to moebel.de, even though the Conversion Tag itself is working perfectly (as Phase 4 confirms).

Note that the Conversion Tag fired correctly in this test because the test flow includes navigation between pages (category → product → cart → checkout → confirmation), which gave the Base Tag a non-landing page on which to fire. A real shopper who buys directly from the landing page would silently fail to be attributed.

---

## Recommendations

1. **Partner action (required):** Open the Base Tag in the partner's GTM container and set its trigger to **"Page View — All Pages"** (or equivalent on non-GTM setups). Publish the container.
2. **Re-test:** Once published, only the Base Part needs to be re-verified — the Conversion Part is already confirmed working in this run, so a second order is not required.
3. **Relevant documentation:**
   - [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)

---

_Generated by Sales Tracking Test Automation — EXAMPLE REPORT_
