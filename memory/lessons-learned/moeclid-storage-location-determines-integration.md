---
name: moeclid-storage-location-determines-integration
description: The click-ID storage location/key determines whether Base Part is valid; a MOEBEL_CLICKOUT_ID cookie is non-standard and is NOT a working base setup
type: lesson
---

The Phase 2 verdict depends on **where** and **under which key** the click ID is stored — not merely that it is present somewhere.

- **Server-side** integration stores it in a cookie named **`moeclid`**.
- **Client-side** integration stores it in **localStorage** under the key **`MOEBEL_CLICKOUT_ID`** (JSON `{date, clickId}`).

A **`MOEBEL_CLICKOUT_ID` *cookie*** matches neither pattern. Finding the click ID there must NOT be reported as a working Base Part — it is a non-standard / likely-misconfigured setup, and the conversion side may not read it as expected. Report it as INCONCLUSIVE and flag the storage location for review against the integration the partner actually implemented.

**Why:** On the Wohnschick DE run (2026-05-26) the click ID was present in a `MOEBEL_CLICKOUT_ID` cookie and was initially (incorrectly) reported as "Base Part WORKING". The domain expert corrected it: that is neither the server-side (`moeclid` cookie) nor the client-side (`MOEBEL_CLICKOUT_ID` localStorage) location, so it is not a valid base setup.

**How to apply:** In Phase 2, check the exact key AND storage type. Only treat as WORKING when it matches a known pattern: `moeclid` cookie (server-side) OR `MOEBEL_CLICKOUT_ID` in localStorage (client-side). Anything else (e.g. `MOEBEL_CLICKOUT_ID` in a cookie) → INCONCLUSIVE, do not claim the base part works, flag the storage location. See [[phase2-pre-clean-partner-domain]].
