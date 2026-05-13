---
name: ch-market-quirks
description: Switzerland (CH) market technical idiosyncrasies for sales tracking tests
type: quirk
---

- **Wait 5 seconds before clickout from the portal.** When testing the CH market, pause 5 seconds on the moebel.ch product page before clicking through to the partner site — clicking immediately can break the redirect chain and produce a missing moeclid in Phase 1.
