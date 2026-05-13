# Sales Tracking Test Report — Naturwohnen (DE)

## Test Information

| Field | Value |
| --- | --- |
| Partner | Naturwohnen |
| Market | DE |
| Portal | https://www.moebel.de |
| Partner domain | https://www.naturwohnen.de |
| Test date | 2026-05-14 00:36:41 CEST |
| Tester | murat.akkus@moebel.de |
| Overall status | **PASS (Base Part only)** — Conversion Part not tested |
| Scope | Phases 0 → 1 → 2 only. Phases 3, 4, 5 skipped per tester request ("Don't place any order. skip the placing order path."). |

> **Scope caveat:** This run verifies the **Base Part** of the integration (moeclid capture and storage on the partner domain). The **Conversion Part** (sales request firing on the order confirmation page, payload validation, PARTNER_KEY check, console errors) was NOT tested because the tester explicitly requested no order be placed. A full PASS verdict can only be issued after a follow-up run that exercises Phases 3 and 4.

---

## Phase Status Summary

| Phase | Status | Note |
| --- | --- | --- |
| Phase 0 — Pre-test setup + portal CMP consent | ✅ PASS | Portal CMP accepted via accessibility-tree snapshot (`Akzeptieren` button) |
| Phase 1 — Partner lookup + moeclid capture | ✅ PASS | Partner found on `/shops` listing, moeclid present in final URL |
| Phase 2 — Base Part verification | ✅ PASS | `MOEBEL_CLICKOUT_ID` localStorage stored on first page load after consent |
| Phase 3 — Purchase flow | ⏭️ SKIPPED | Tester requested no order |
| Phase 4 — Conversion Part verification | ⏭️ SKIPPED | Depends on Phase 3 |
| Phase 5 — Console error check | ⏭️ SKIPPED | Folded into Phase 4 in the standard flow |
| Phase 6 — Report generation | ✅ DONE | This document |

---

## Phase 0 — Pre-Test Setup

| Step | Outcome |
| --- | --- |
| Anchor tab opened (`about:blank`) | ✅ |
| Browser history cleared | ✅ |
| Pre-existing tabs from prior run closed (Naturwohnen leftover tabs) | ✅ |
| Cookies + localStorage + sessionStorage cleared on `www.moebel.de` | ✅ |
| Cookies + localStorage + sessionStorage cleared on `www.naturwohnen.de` | ✅ (partner domain was known up front from leftover tabs) |
| Anchor tab closed after portal tab opened | ✅ |
| Portal CMP detection | ✅ Detected via accessibility-tree snapshot (Layer 1) — no fallback needed |
| Portal CMP action | ✅ Accepted (`Akzeptieren` button) |
| Portal consent cookie set after accept | ✅ Cookie jar grew from 504 → 2828 chars after click |

---

## Phase 1 — Partner Lookup & Moeclid Capture

### Listing lookup

| Field | Value |
| --- | --- |
| Shops listing URL | https://www.moebel.de/shops?ps=asc |
| Found in | `shops` (Pass 1 — brand fallback not needed) |
| Partner listing URL | https://www.moebel.de/shops/naturwohnen?ps=asc |

### Product selection

| Field | Value |
| --- | --- |
| Product | Naturwohnen Massivholz Regalboden "Arbor" schmal Erle natur geölt |
| Price | 39,95 € (cheapest after `?ps=asc` sort) |
| Redirect href found | ✅ Yes — `/redirect?...&partnerId=7a4d28ce-ac02-4b0a-80ad-eb29699b9223&partnerName=Naturwohnen` |
| Navigation method | ✅ **Click on the live DOM link** (never `new_page(url=redirect_href)`) — per skill rule #28 |

### Redirect chain

| Field | Value |
| --- | --- |
| Final URL | `https://www.naturwohnen.de/moebel/regale/arbor-regalboden-schmal_560050_22763/?ReferrerID=13.00&moeclid=b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b` |
| moeclid present | ✅ Yes |
| moeclid value | `b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b` |
| partnerId | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| Redirect status | ✅ Success |

---

## Phase 2 — Base Part Verification

### Pre-clean (Step 2.0)

| Step | Outcome |
| --- | --- |
| Partner-domain cookies cleared | ✅ (HttpOnly cookies cannot be removed via JS — best-effort) |
| Partner-domain localStorage cleared | ✅ |
| Partner-domain sessionStorage cleared | ✅ |
| Page reloaded after clear | ✅ (moeclid query param preserved across reload) |

### Initial page state (Step 2.1, after pre-clean reload, before consent)

- URL: `https://www.naturwohnen.de/moebel/regale/arbor-regalboden-schmal_560050_22763/?ReferrerID=13.00&moeclid=b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b`
- Overlays detected: custom CMP banner with `Einstellungen` / `Einverstanden, zum Shop →` buttons; marketing promo bar at top with discount code `NATUR20` (not a consent gate)

### Cookie consent (Step 2.2)

| Field | Value |
| --- | --- |
| Banner present | ✅ Yes |
| Banner type | banner (not full-page wall) |
| Consent platform | Custom (no recognised CMP global like Cookiebot / UC_UI / OneTrust) |
| Action taken | ACCEPTED via accessibility-tree snapshot — clicked `Einverstanden, zum Shop →` |

### Email / newsletter popup (Step 2.3)

| Field | Value |
| --- | --- |
| Present | No newsletter popup blocked the storage check (marketing promo bar persists at the top but is not an overlay) |
| Action | None needed |

### Cookies after consent (Step 2.5 — Server-Side check)

| Field | Value |
| --- | --- |
| All cookie names | `_ga`, `_fbp`, `_pin_unauth`, `_gcl_au`, `XSRF-TOKEN`, `_ga_57F7GBCD0V`, `plenty-shop-cookie` |
| `moeclid` cookie found | ❌ No |
| Server-Side integration | Not in use on this partner |

### localStorage after consent (Step 2.6 — Client-Side check)

| Field | Value |
| --- | --- |
| `MOEBEL_CLICKOUT_ID` found | ✅ Yes |
| Raw value | `{"date":"2026-05-13T22:34:57.954Z","clickId":"b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b"}` |
| Parsed `clickId` | `b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b` |
| Matches URL `moeclid` parameter | ✅ Yes — exact match |

### Base Part verdict

| Field | Value |
| --- | --- |
| Status | ✅ **WORKING** |
| Storage type | **Client-Side (localStorage)** |
| Notes | The Base Tag fired on the same page load on which consent was accepted — no post-consent reload was required. This is the expected behaviour for a correctly integrated Client-Side tag with a Page View — All Pages trigger. |

---

## Phase 3 — Purchase Flow

**Skipped per tester request.** No order placed. No login attempted. No checkout traversed.

---

## Phase 4 — Conversion Part Verification

**Skipped — depends on Phase 3.** The Conversion Tag could not be observed because no order confirmation page was reached.

### Implications

| Aspect | Status |
| --- | --- |
| Sales API call observed | Not observed |
| PARTNER_KEY captured | Not captured |
| PARTNER_KEY verification | Skipped — no expected key provided by tester AND no actual key captured |
| Payload validation (items, shipping, total, partnerKey) | Not performed |
| Console error check | Not performed |

> The Conversion Tag is a separate piece of the integration from the Base Tag. A working Base Part does NOT imply a working Conversion Part — the Conversion Tag has its own trigger, its own payload mapping, and its own PARTNER_KEY. A follow-up run that places a test order is required to validate this.

---

## Integration Type

Based on the storage type observed in Phase 2, the partner is on one of:

- **GTM Client-Side**
- **Manual Client-Side**
- **Shopify Custom Pixel**

The three variants store the moeclid the same way (in `MOEBEL_CLICKOUT_ID` localStorage). Distinguishing between them requires inspecting the partner's tag-manager container or page source, which was not done in this run.

---

## Recommendations

### For the partner

- **No action required for the Base Part.** The Base Tag fires correctly on every page load after consent acceptance and stores the moeclid in `MOEBEL_CLICKOUT_ID` localStorage exactly as expected.
- **Conversion Tag remains unverified.** Before declaring the integration production-ready, the Conversion Tag should be tested by placing a real (test) order. We will schedule a follow-up run for this.

### For internal follow-up

- **Re-test with order placement.** Run Phases 3 and 4 against this same partner to validate the Conversion Tag payload, capture the PARTNER_KEY in use, and confirm the sales request is firing with the correct values.
- **Recipient note for this report's email step:** The tester provided their own `@moebel.de` address (`murat.akkus@moebel.de`) as the "partner email" recipient — this is unusual (the partner email rules normally exclude internal `@moebel.de` addresses) but the tester explicitly labeled it as the partner email, so the skill honoured the override. The email below was not sent to the actual Naturwohnen partner contact.

### Relevant integration documentation

- [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)
- [Manual Client-Side Integration](https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html)

---

## Test Data References

| Field | Value |
| --- | --- |
| moeclid (URL) | `b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b` |
| moeclid (storage match) | `b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b` (exact match in `MOEBEL_CLICKOUT_ID`) |
| partnerId (from portal redirect) | `7a4d28ce-ac02-4b0a-80ad-eb29699b9223` |
| PARTNER_KEY captured by sales call | Not captured — Phase 4 skipped |
| Expected PARTNER_KEY | Not provided by tester |
| PARTNER_KEY verification | Skipped — no expected key provided AND Phase 4 not executed |
| Order ID | Not applicable — no order placed |

---

_Generated by Sales Tracking Test Automation on 2026-05-14 00:36:41 CEST._
