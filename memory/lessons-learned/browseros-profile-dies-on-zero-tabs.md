---
name: browseros-profile-dies-on-zero-tabs
description: BrowserOS tears down its profile when total tab count drops to 0 — Phase 0 cleanup must keep an anchor tab open the entire time.
type: lesson
---

When BrowserOS is left with **0 open tabs**, its profile / browser-window object is torn down. After that:

- `mcp__browseros__new_page` returns `"No browser window available"`.
- `mcp__browseros__create_window` returns `"No profile available"`.

Both are unrecoverable from the skill side — the user has to manually relaunch BrowserOS to restore a profile. There is no graceful re-init API exposed to the MCP layer.

**Why:** Hit on 2026-05-13 during a Naturwohnen DE run. Two tabs were open from a previous session (a moebel.de shops listing and a naturwohnen.de product page with a moeclid in the URL). Phase 0's clean-state policy required closing them. Both `close_page` calls succeeded individually, but the moment the second `close_page` dropped the tab count from 1 to 0, the profile was destroyed. Every subsequent attempt to open a new tab — `new_page`, `create_window`, with or without `hidden:true` — failed with the errors above. The entire test had to be aborted and the user had to relaunch BrowserOS manually before any further runs could start.

**How to apply:**

1. **Never let total tab count reach 0 during Phase 0 (or any other cleanup path).** Before running any `close_page` loop or per-domain clear-state loop that could leave 0 tabs, open an `about:blank` anchor tab first. The anchor is harmless, has no domain state, and protects the profile.

2. **Pattern for Phase 0 cleanup:**
   ```python
   anchor = new_page(url="about:blank", background=False)
   # close stale tabs — anchor is still open
   # run per-domain clear loop — anchor is still open
   portal = new_page(url=portal_url, background=False)
   close_page(page=anchor["pageId"])  # safe: portal tab is the new last tab
   ```

3. **The rule is "count ≥ 1 at every step", not "count ≥ 1 at the end".** A run that closes all tabs and then re-opens one is the bug — the brief moment at 0 is enough to lose the profile. Always open the new tab BEFORE closing the last old tab.

4. **This is a `mcp__browseros__*` characteristic, not a general Chrome / browser behaviour.** Plain Chrome lets the window persist as an empty frame; BrowserOS treats 0-tabs as "release the profile". Don't generalise from one to the other.

5. **Phase 0 SKILL.md step 6 now codifies the anchor-tab pattern.** Any future cleanup/clear-state code added to other phases must follow the same pattern. See `skills/st-phase-0-pre-test-setup/SKILL.md` step 6.
