---
name: st-phase-3-purchase-flow
description: Phase 3 of the sales tracking test. Use this skill after Phase 2 confirms the Base Part is working — it adds the product to the cart, handles the guest-checkout vs. already-registered-email branch (mandatory login procedure with the market's designated credentials), fills the shipping form with locale-aware data, retries with the fallback address on carrier rejection, selects payment method (Vorkasse > Bank Transfer > Credit Card), submits the order, and captures the order number from the visible confirmation page (URL id_order is only a flagged fallback).
compatibility: claude-code
---

# Phase 3: Purchase Flow

Goal: complete a real test purchase on the partner site so Phase 4 can verify the Conversion Part.

**Prerequisite:** Phase 2 (`st-phase-2-base-part-verification`) has reported `status == "WORKING"`.

**Step 3.1: Add product to cart**
```python
# Use take_snapshot() to find the add-to-cart button, then click() by element ID
# Language-specific button text:
# de: "in den warenkorb" | fr: "ajouter au panier"
# nl: "toevoegen aan winkelwagen" | it: "aggiungi al carrello" | es: "añadir al carrito"

snapshot = take_snapshot(page=newPageId)
click(page=newPageId, element=cart_button_element_id)

report["phase3"]["add_to_cart"] = {
    "status": "success",
    "product_name": product_details["name"],
    "product_price": product_details["price"],
}
```

**Step 3.2: Proceed to checkout — guest checkout vs. login**

After reaching the cart, proceed to checkout. You will encounter one of two scenarios:

**Scenario A — Guest checkout available:**
The platform offers a "guest checkout" or "order without account" option (look for labels like "Gast bestellen", "als Gast", "ZAMÓW JAKO GOŚĆ", "Commander en tant qu'invité", etc.). Click it and proceed to the shipping form.

**Scenario B — Email already registered (MOST COMMON for returning test accounts):**
After entering the market's designated email in the guest form, the platform returns a validation error such as "Diese E-Mail-Adresse ist bereits registriert", "Mamy już zarejestrowane konto dla podanego adresu e-mail", or similar.

**In Scenario B, the mandatory procedure is:**
1. Navigate directly to the login page URL on the partner's site (e.g., `/signin.php`, `/login`, `/logowanie`, `/compte/login`). Do not rely on in-page links that might carry stale state — use `navigate_page` to load the login page fresh.
2. Before filling any field, click the field first to focus it, then immediately use `fill`. This ensures the platform's JavaScript event listeners register the value correctly. Many login forms (especially IdoSell and Shopify-based) use JS-driven state management that ignores values set without prior focus — `fill` alone on an unfocused field will silently fail.
3. Fill the email field (click → fill), then fill the password field (click → fill) using the market's designated credentials from Phase 0.
4. Click the login/submit button and take a snapshot to verify the header shows the user as logged in (e.g., no longer showing "Zaloguj się", "Anmelden", "Sign in").
5. If login fails despite correct credentials, navigate to the login page again fresh (`navigate_page`) and retry — do not just re-fill the existing page. A fresh page load resets any stale JS form state.
6. After successful login, navigate back to the cart (the session should persist) and proceed to checkout as a logged-in user.

**Do NOT:**
- Try a different email address
- Append suffixes or modify the address in any way
- Create a new account
- Give up and abort Phase 3

```python
report["phase3"]["checkout"] = {
    "method": "guest" or "logged_in",  # which path was taken
    "email_already_registered": True/False,
    "login_required": True/False,
    "notes": ""
}
```

**Step 3.3: Fill shipping information**
```python
# Locate and fill form fields using take_snapshot + fill by element ID
# Use the exact test data for the market from Phase 0 — do not improvise field values
# Pay attention to locale-specific field formats:
#   - Postal codes: German 5-digit (20095), French 5-digit (75001), Polish XX-XXX (20-001)
#   - Street and house number may be separate fields (fill them independently)
#   - Phone number format varies; use the market's designated phone as-is

report["phase3"]["checkout"]["shipping_form"] = "completed"
report["phase3"]["checkout"]["address_used"] = "primary"  # or "fallback"
```

**Step 3.3a: Shipping error — fallback address**

If the order submission returns a shipping error (URL contains `shipping_error`, `delivery_error`, or the page shows a message like "nie można dostarczyć", "Lieferung nicht możliwy", "livraison impossible"), the primary address was rejected by the carrier. In this case:

1. Navigate back to the checkout form (or click the back/edit button)
2. Replace only the **street**, **postal code**, and **city** fields with the market's fallback address from Phase 0
3. Keep all other fields (name, phone, email) unchanged
4. Re-submit the order
5. If the fallback address also fails, document both attempts and mark Phase 3 as `address_validation_failed`

```python
# Fallback address retry:
if "shipping_error" in current_url or shipping_error_detected:
    fill street field with fallback_street
    fill postal code field with fallback_postal_code
    fill city field with fallback_city
    re-submit order
    report["phase3"]["checkout"]["address_used"] = "fallback"
    report["phase3"]["checkout"]["primary_address_rejected"] = True
```

**Step 3.4: Payment method selection**
```python
# Priority order: Vorkasse > Bank Transfer > Credit Card
# Use take_snapshot to find and select first available method
report["phase3"]["payment"] = {
    "method": selected_payment,
    "cart_value_net": cart_value,
    "shipping_cost": shipping_cost,
    "currency": currency
}
```

**Step 3.5: Submit order (no interceptor injection needed)**
```python
# Accept terms checkboxes if present
evaluate_script(page=newPageId, expression="""
(function() {
  const termsCb = document.querySelector('input[name*="terms"], input[name*="conditions"], input[name*="cancel"]');
  const allRequired = document.querySelectorAll('input[type="checkbox"][required]');
  allRequired.forEach(cb => { cb.checked = true; cb.dispatchEvent(new Event('change', {bubbles: true})); });
})()
""")

# Submit order form directly (find the form whose action contains the order confirmation step)
evaluate_script(page=newPageId, expression="""
(function() {
  const forms = Array.from(document.querySelectorAll('form'));
  const orderForm = forms.find(f => f.action.includes('order3') || f.action.includes('confirm') || f.action.includes('checkout'));
  if (orderForm) { orderForm.submit(); return 'submitted'; }
  // Fallback: click the submit button
  const btn = document.querySelector('input[type="submit"][value*="płac"], input[type="submit"][value*="order"], button[type="submit"]');
  if (btn) { btn.click(); return 'clicked: ' + btn.value; }
  return 'not found';
})()
""")
# Wait for confirmation page to load
```

> Note: this is "Step 4.1" in the source skill. It lives here in Phase 3 because submitting the order is the last action of the purchase flow — Phase 4 is read-only verification on the confirmation page.

**Step 3.6: Capture the order number from the confirmation ("thanks") page**

The order number that ends up in the Jira report and the comprehensive report MUST come from what the partner's confirmation page actually shows the customer. The URL's `id_order` query parameter is **not** the source of truth — many shop systems (PrestaShop being a common offender) display a human-facing order reference on the page that does not match the internal `id_order` from the URL. Using the URL value silently in those cases produces an order number that the partner cannot find in their system when they try to look it up.

Capture in this priority order:

1. **From the visible page text first.** Read the rendered confirmation page and look for the order reference next to common labels: `Bestellnummer`, `Bestellnr.`, `Auftragsnummer`, `Order number`, `Order #`, `Numéro de commande`, `Commande n°`, `N° de commande`, `Numero ordine`, `Número de pedido`, `Numer zamówienia`, `Bestelnummer`, and any matching pattern of the form `#ABC123` / `ORD-12345` near the heading `Vielen Dank` / `Merci` / `Thank you` / `Grazie` / `Gracias` / `Dziękujemy`. This is the order number the partner actually shows the customer and the one that will exist in their backoffice.

2. **Fall back to the URL only if no on-page value is found.** When the page has no visible order reference at all, fall back to the `id_order` (or equivalent) URL query parameter. When this fallback fires, **the report and the Jira draft must explicitly say so** — write `Bestellnr.: 166094 (aus URL-Parameter id_order, nicht auf der Bestätigungsseite sichtbar)` in German, or `Order no.: 166094 (from URL parameter id_order — not shown on the confirmation page)` in English. Never silently present a URL-derived value as if it had come from the page.

3. **If neither is available**, write `Keine Bestellung freigegeben` / `No order submitted` and follow the existing rules for that case.

```python
order_capture = evaluate_script(page=confirmPageId, expression="""
(function() {
  const text = document.body.innerText;

  // Common label patterns across markets
  const labelPatterns = [
    /Bestell(?:nummer|nr\\.?)\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Auftragsnummer\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Order\\s*(?:number|#|no\\.?)\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Numéro\\s+de\\s+commande\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Commande\\s+n[°o]\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Numero\\s+ordine\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /N[úu]mero\\s+de\\s+pedido\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Numer\\s+zam[óo]wienia\\s*:?\\s*([A-Za-z0-9#-]+)/i,
    /Bestelnummer\\s*:?\\s*([A-Za-z0-9#-]+)/i,
  ];
  for (const re of labelPatterns) {
    const m = text.match(re);
    if (m && m[1]) return { source: 'page_text', label: m[0].split(/\\s*:?\\s*/)[0], value: m[1] };
  }

  // Fallback: free-form #-prefixed reference near a thanks heading
  const thanksRegion = text.match(/(Vielen Dank|Merci|Thank you|Grazie|Gracias|Dziękujemy)[\\s\\S]{0,400}/i);
  if (thanksRegion) {
    const ref = thanksRegion[0].match(/#([A-Za-z0-9-]{3,})/);
    if (ref) return { source: 'page_text', label: 'thanks-region #ref', value: ref[1] };
  }

  return null;
})()
""")

if order_capture and order_capture.get("value"):
    report["phase3"]["order_id"] = order_capture["value"]
    report["phase3"]["order_id_source"] = "page_text"
    report["phase3"]["order_id_source_note"] = (
        f"Captured from the confirmation page text near label '{order_capture.get('label')}'."
    )
else:
    # Fall back to URL id_order — must be flagged in the report
    from urllib.parse import urlparse, parse_qs
    qs = parse_qs(urlparse(current_confirmation_url).query)
    url_order_id = (qs.get("id_order") or qs.get("order_id") or qs.get("orderId") or [None])[0]

    if url_order_id:
        report["phase3"]["order_id"] = url_order_id
        report["phase3"]["order_id_source"] = "url_id_order_fallback"
        report["phase3"]["order_id_source_note"] = (
            "No order number was visible on the confirmation page — falling back to the "
            "URL query parameter `id_order`. This must be flagged explicitly in the report "
            "and the Jira comment so the partner is not handed an internal id that is not "
            "visible to their customer-facing system."
        )
    else:
        report["phase3"]["order_id"] = None
        report["phase3"]["order_id_source"] = "none"
        report["phase3"]["order_id_source_note"] = "No order number found on the page or in the URL."
```

**Reporting rule (mandatory):** every comprehensive report and every Jira draft must include `order_id_source` next to the captured order number whenever the source is `url_id_order_fallback`. Use these exact phrasings:

- Comprehensive report — Phase 3 row: `Order ID | 166094 (from URL parameter id_order — not visible on confirmation page)`
- Jira draft (German): `Bestellnr.: 166094 (aus URL-Parameter id_order, nicht auf der Bestätigungsseite sichtbar)`
- Jira draft (English): `Order no.: 166094 (from URL parameter id_order — not shown on the confirmation page)`

When `order_id_source == "page_text"`, present the value plainly with no extra annotation — that is the normal, trusted case.

---

## Exit criteria

Phase 3 is done when:
- The order was submitted and the confirmation/thanks page is loaded
- `report["phase3"]["order_id"]` and `report["phase3"]["order_id_source"]` are set
- `report["phase3"]["payment"]` records the method, cart value, shipping cost, currency
- `report["phase3"]["checkout"]["address_used"]` is recorded ("primary" or "fallback")

Proceed to `st-phase-4-conversion-verification`.
