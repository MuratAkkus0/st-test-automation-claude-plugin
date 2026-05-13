---
name: st-phase-4-conversion-verification
description: Phase 4 of the sales tracking test. Use this skill after the order is submitted and the confirmation page is loaded — it passively reads the Performance API to verify the sales API call was fired during page load, captures MOEBEL_SALES / PARTNER_KEY / MARKET globals and the stored clickId, validates the call payload from inline scripts, optionally verifies the captured PARTNER_KEY against a user-provided expected key (a mismatch is a blocking failure), and checks the console for errors. NEVER calls MOEBEL_SALES.sale() manually — read-only verification only.
compatibility: claude-code
---

# Phase 4: Conversion Part Verification

**CRITICAL: Never call MOEBEL_SALES.sale() or re-trigger any tracking function manually.**
Calling the sale function again creates duplicate records in the sales tracking dashboard.
The correct approach is to read what the browser already recorded during the natural page load.

**Prerequisite:** Phase 3 (`st-phase-3-purchase-flow`) has submitted the order and the confirmation page is loaded. `report["phase3"]["order_id"]` is captured.

---

**Step 4.1: Verify sales API call via Performance API (read-only, no re-triggering)**

After the confirmation page loads, use the browser's resource timing API to check if the sales API call was made during the page load. This is completely passive — it reads what already happened and never triggers any new network request.

Use the `sales_endpoints` table from the `st-market-reference` skill.

```python
# Get the expected sales API endpoint for this market — see st-market-reference for the full table.
expected_endpoint = sales_endpoints[market]

# After confirmation page loads — read Performance resource timing (passive, read-only)
result = evaluate_script(page=confirmPageId, expression=f"""
(function() {{
  const entries = window.performance.getEntriesByType('resource');
  const salesEntry = entries.find(e => e.name.includes('{expected_endpoint}'));
  
  // Also check for MOEBEL_SALES object presence (confirms script was loaded)
  const scriptPresent = typeof window.MOEBEL_SALES !== 'undefined';
  const partnerKey = typeof window.PARTNER_KEY !== 'undefined' ? window.PARTNER_KEY : null;
  const market = typeof window.MARKET !== 'undefined' ? window.MARKET : null;
  
  // Check MOEBEL_CLICKOUT_ID in localStorage (confirms moeclid was available for the call)
  const storedClickId = localStorage.getItem('MOEBEL_CLICKOUT_ID');
  let clickId = null;
  try {{ clickId = storedClickId ? JSON.parse(storedClickId).clickId : null; }} catch(e) {{}}
  
  return JSON.stringify({{
    sales_call_found: !!salesEntry,
    sales_url: salesEntry ? salesEntry.name : null,
    sales_call_duration_ms: salesEntry ? Math.round(salesEntry.duration) : null,
    MOEBEL_SALES_present: scriptPresent,
    PARTNER_KEY: partnerKey,
    MARKET: market,
    MOEBEL_CLICKOUT_ID_clickId: clickId
  }});
}})()
""")

report["phase4"] = {
    "sales_call_found": result["sales_call_found"],
    "sales_url": result["sales_url"],
    "sales_call_duration_ms": result["sales_call_duration_ms"],
    "MOEBEL_SALES_present": result["MOEBEL_SALES_present"],
    "PARTNER_KEY": result["PARTNER_KEY"],
    "MARKET": result["MARKET"],
    "clickId_in_localStorage": result["MOEBEL_CLICKOUT_ID_clickId"],
    "pass": result["sales_call_found"] and result["MOEBEL_SALES_present"]
}
```

**Step 4.2: Validate call payload (if sales script exposes data)**
```python
# Try to read the actual call arguments from inline scripts on the confirmation page
# This does NOT re-trigger — just reads the already-executed script source
call_data = evaluate_script(page=confirmPageId, expression="""
(function() {
  const scripts = Array.from(document.querySelectorAll('script:not([src])')).map(s => s.textContent);
  const callScript = scripts.find(t => t.includes('MOEBEL_SALES.sale('));
  if (!callScript) return null;
  // Extract the end of the script which contains the actual .sale() call
  const callStart = callScript.lastIndexOf('MOEBEL_SALES.sale(');
  return callScript.substring(callStart, callStart + 300);
})()
""")

report["phase4"]["call_source"] = call_data  # e.g. MOEBEL_SALES.sale({total:79, orderId:"48578", ...})
```

**Step 4.3: PARTNER_KEY verification (only runs when user provided an expected key)**

This step catches a common real-world mistake: when a partner is already live on one market and goes live on a second market, they sometimes reuse the first market's integration (and its PARTNER_KEY) instead of wiring up the fresh key we issued for the new market. The result is silent — the Conversion Part fires as if everything works, but every order from the new market is attributed to the wrong partner account.

The captured PARTNER_KEY from Step 4.1 (`report["phase4"]["PARTNER_KEY"]`) must ALWAYS be written to the comprehensive report — the tester needs to see which key the partner is actually using, regardless of whether verification runs.

The verification step runs **only if the user supplied an expected PARTNER_KEY in their original request**. If they didn't, skip this step entirely — do not invent a key, do not look it up anywhere, do not fail the test for a missing input.

```python
# expected_partner_key was extracted in the Input Format parsing
# (None/empty when the user did not provide one)

actual_key = report["phase4"]["PARTNER_KEY"]  # already captured in Step 4.1

if expected_partner_key:
    # Normalise both strings to lowercase and trim whitespace before comparing.
    # Never treat a `None` or empty actual_key as "matches" — that means the
    # conversion script didn't expose the key at all, which is a separate bug.
    if actual_key and actual_key.strip().lower() == expected_partner_key.strip().lower():
        report["phase4"]["partner_key_check"] = {
            "performed": True,
            "status": "MATCH",
            "expected": expected_partner_key,
            "actual": actual_key,
        }
    else:
        report["phase4"]["partner_key_check"] = {
            "performed": True,
            "status": "MISMATCH",
            "expected": expected_partner_key,
            "actual": actual_key,
            "notes": (
                "Partner is sending the wrong PARTNER_KEY. This typically happens "
                "when a partner reuses an existing integration from another market "
                "without swapping in the fresh key issued for the new market. All "
                "conversions from this market are being attributed to the wrong "
                "partner account until the key is corrected."
            ),
        }
        # A mismatch is a blocking issue on par with a Base Part failure — it
        # turns the overall test result into FAIL regardless of whether the
        # Conversion Part otherwise looks healthy. The sale call succeeded, but
        # it's landing in the wrong account, which is worse than not tracking.
else:
    report["phase4"]["partner_key_check"] = {
        "performed": False,
        "reason": "No expected PARTNER_KEY provided by user — verification skipped.",
        "actual": actual_key,
    }
```

**Rules for this step:**

1. **Always capture** `PARTNER_KEY` and `MARKET` from the confirmation page in Step 4.1 (already in the baseline flow).
2. **Always write** the captured `PARTNER_KEY` into the comprehensive report in Phase 6, regardless of whether verification ran. Use the "Test Data References" section and the Phase 4 results table as the canonical places. Label it clearly as "PARTNER_KEY used by partner in the sales call" so the tester can cross-reference with ACM themselves if they want.
3. **Only verify** when the user provided an expected key. Never invent a key or guess based on market.
4. **Never hard-code** a lookup table of expected keys in this skill. The source of truth is ACM; the user passes the value in when they know it.
5. **On mismatch, escalate the overall result** to FAIL — even if Base Part and Conversion Part both otherwise passed. Attributing conversions to the wrong account is strictly worse than not attributing them.
6. **On skip**, do not show the `partner_key_check` section as an error in the report — it's simply not applicable when no expected key was provided. The captured key is still printed.

---

**Step 4.4: Console Error Check (formerly Phase 5)**

```python
# Use mcp__browserOS__get_console_logs — page ID must be an integer
console_logs = get_console_logs(page=int(newPageId))

errors = [msg for msg in console_logs if msg.get("level") == "error"]
sales_object_error = any("Received sales object" in e["message"] for e in errors)

report["phase5"]["console"] = {
    "errors_found": len(errors) > 0,
    "sales_object_error": sales_object_error,
    "error_messages": [e["message"] for e in errors]
}
```

---

## Exit criteria

Phase 4 is done when:
- `report["phase4"]["pass"]` is set (True/False) based on `sales_call_found && MOEBEL_SALES_present`
- `report["phase4"]["PARTNER_KEY"]` and `report["phase4"]["MARKET"]` are captured (even if null) — these always appear in the final comprehensive report
- `report["phase4"]["partner_key_check"]` is set with either `performed: True` (and MATCH/MISMATCH) or `performed: False` (skipped)
- `report["phase5"]["console"]` contains errors_found / sales_object_error / error_messages

Proceed to `st-report-generation`.
