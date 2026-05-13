---
name: phase1-always-click-never-direct-navigate
description: Phase 1 must always CLICK the product link to open the partner page — never new_page(url=redirect_href). Direct navigation 404s on the portal-internal redirect endpoint.
type: lesson
---

In Phase 1 (navigation & moeclid capture), the partner page must always be opened by clicking the product link in the live DOM on the partner shop page. Never call `mcp__browseros__new_page(url=redirect_href, ...)` against the moebel.de `/redirect?...` URL.

**Why:** Verified 2026-05-13 on Naturwohnen DE. Opening the first product's redirect href via `new_page(url=redirect_href)` 404'd on the portal-internal `https://www.moebel.de/api/product/redirectWithCheck?...` endpoint — `partnerId` and `partnerName` were stripped from the URL during the redirect chain. Clicking the exact same link on the same partner shop page (after the same Phase 0 portal consent) succeeded: the redirect resolved correctly and landed on the partner domain with `moeclid` intact. The 404 looked like the Schlafenwelt-DE "consent missing" pattern from 2026-04-27, but consent WAS accepted — the real cause was the direct-URL navigation. The moebel.de `/redirect?...` endpoint depends on same-page context (Referer header, the click-handler that fires a tracking event before navigation, listing-page session state) that direct URL navigation cannot provide.

**How to apply:** Phase 1 Step 1.3 always uses snapshot → click. Mark the first product link with a temp class via `evaluate_script`, resolve it through `search_dom` (or `take_snapshot` when the page is small enough), then `click` it via the BrowserOS click tool. Find the new tab via `list_pages` (links usually have `target="_blank"`). The href is only read for logging — never passed to `new_page(url=...)`. When a 404 on `/api/product/redirectWithCheck` is observed, the first two checks are (a) was Phase 0 portal consent accepted on the same session, (b) was the partner page opened via click or direct navigation. If both pass, only then report it as a real bug.
