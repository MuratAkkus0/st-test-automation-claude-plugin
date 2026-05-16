---
name: st-market-reference
description: Reference data tables for sales tracking tests across the moebel.de family of portals. Use this skill whenever you need portal URLs, sales API endpoints, market-specific test identities, fallback addresses, CMP accept-button keywords, listing paths, or integration documentation URLs for any of the 9 markets (de, fr, nl, at, ch, es, it, pl, gb). Other ST phase skills load these tables — open this skill first when a phase skill mentions PORTAL_URLS, sales_endpoints, LISTING_PATHS, ACCEPT_KEYWORDS, or the per-market test address.
compatibility: claude-code
---

# Sales Tracking — Market Reference Tables

This skill is the single source of truth for per-market constants used by every other ST phase skill. Do not duplicate these tables into other skills; reference this one.

## Markets Covered

The moebel.de family operates 9 country portals:

| Code | Country | Portal URL |
| --- | --- | --- |
| de | Germany | https://www.moebel.de |
| fr | France | https://www.meubles.fr |
| nl | Netherlands | https://www.meubelo.nl |
| at | Austria | https://www.moebel24.at |
| ch | Switzerland | https://www.moebel24.ch |
| es | Spain | https://www.mobi24.es |
| it | Italy | https://www.mobi24.it |
| pl | Poland | https://www.living24.pl |
| gb | UK | https://www.living24.uk |

```python
PORTAL_URLS = {
    "de": "https://www.moebel.de",
    "fr": "https://www.meubles.fr",
    "nl": "https://www.meubelo.nl",
    "at": "https://www.moebel24.at",
    "ch": "https://www.moebel24.ch",
    "es": "https://www.mobi24.es",
    "it": "https://www.mobi24.it",
    "pl": "https://www.living24.pl",
    "gb": "https://www.living24.uk"
}
```

## Sales API Endpoints (Conversion Part)

- 🇩🇪 Germany (de): `https://redirect.moebel.de/api/1.0/moebel/de/sales`
- 🇫🇷 France (fr): `https://redirect.meubles.fr/api/1.0/moebel/fr/sales`
- 🇳🇱 Netherlands (nl): `https://redirect.meubelo.nl/api/1.0/moebel/nl/sales`
- 🇦🇹 Austria (at): `https://redirect.moebel24.at/api/1.0/moebel/at/sales`
- 🇨🇭 Switzerland (ch): `https://redirect.moebel24.ch/api/1.0/moebel/ch/sales`
- 🇪🇸 Spain (es): `https://redirect.mobi24.es/api/1.0/moebel/es/sales`
- 🇮🇹 Italy (it): `https://redirect.mobi24.it/api/1.0/moebel/it/sales`
- 🇵🇱 Poland (pl): `https://redirect.living24.pl/api/1.0/moebel/pl/sales`
- 🇬🇧 UK (gb): `https://redirect.living24.uk/api/1.0/moebel/gb/sales`

```python
sales_endpoints = {
    "de": "redirect.moebel.de/api/1.0/moebel/de/sales",
    "fr": "redirect.meubles.fr/api/1.0/moebel/fr/sales",
    "nl": "redirect.meubelo.nl/api/1.0/moebel/nl/sales",
    "at": "redirect.moebel24.at/api/1.0/moebel/at/sales",
    "ch": "redirect.moebel24.ch/api/1.0/moebel/ch/sales",
    "es": "redirect.mobi24.es/api/1.0/moebel/es/sales",
    "it": "redirect.mobi24.it/api/1.0/moebel/it/sales",
    "pl": "redirect.living24.pl/api/1.0/moebel/pl/sales",
    "gb": "redirect.living24.uk/api/1.0/moebel/gb/sales"
}
```

## Listing Paths (Phase 1 partner lookup)

Each market exposes a "shops" listing and a "marken/marques/brands" listing. The price-sort query (`?ps=asc`) is supported on the shop pages. Both paths must be tried before declaring the partner missing.

```python
LISTING_PATHS = {
    "de": {"shops": "/shops",     "brands": "/marken"},
    "fr": {"shops": "/boutiques", "brands": "/marques"},
    "nl": {"shops": "/shops",     "brands": "/marken"},
    "at": {"shops": "/shops",     "brands": "/marken"},
    "ch": {"shops": "/shops",     "brands": "/marken"},
    "es": {"shops": "/shops",     "brands": "/marken"},
    "it": {"shops": "/shops",     "brands": "/marken"},
    "pl": {"shops": "/shops",     "brands": "/marken"},
    "gb": {"shops": "/shops",     "brands": "/marken"},
}
```

## CMP Accept-Button Keywords (Phase 0 portal consent)

Lowercased, exact-match against trimmed button textContent. Always include both the "all" and the short variants.

```python
ACCEPT_KEYWORDS = {
    "de": ["alle akzeptieren", "akzeptieren", "alle annehmen", "zustimmen"],
    "fr": ["tout accepter", "accepter", "tout accepter et fermer"],
    "nl": ["alles accepteren", "accepteren", "alle accepteren"],
    "at": ["alle akzeptieren", "akzeptieren", "alle annehmen", "zustimmen"],
    "ch": ["alle akzeptieren", "akzeptieren", "alle annehmen", "zustimmen"],
    "es": ["aceptar todo", "aceptar", "aceptar todas"],
    "it": ["accetta tutto", "accetta", "accetta tutti"],
    "pl": ["zaakceptuj wszystko", "akceptuję", "zaakceptuj", "akceptuj"],
    "gb": ["accept all", "accept", "accept cookies", "i accept"],
}
```

## Market-Specific Test Identities (Phase 3 checkout)

**German Market (de):**
- Name: Mia Moebel.de-Test
- Street: Moebel.de Str.
- House number: 3
- Postal code: 20095
- City: Hamburg
- Email: partner@moebel.de
- Phone: 040210910730
- Password: Moebel.de-test1
- Fallback street: Reeperbahn
- Fallback postal code: 20359
- Fallback city: Hamburg

> ⚠️ Note: **"Moebel.de Str."** is the literal street name used by the QA test identity (per the project's [IDENTITY INFORMATIONEN](../../hepler-documantations/IDENTITY%20INFORMATIONEN.md) document). Do not substitute "Mönckebergstraße" or any other real Hamburg street name — keep it exactly as "Moebel.de Str." with a period after "Str". If a partner's address validation rejects a dotted abbreviation, first try "Moebel.de Straße" (fully spelled) before falling back to the Reeperbahn fallback.

**French Market (fr):**
- Name: TEST MEUBLESFR
- Street: Rue de Rivoli
- House number: 3
- Postal code: 75001
- City: Paris
- Email: partenaire@meubles.fr
- Phone: 0612345678
- Password: Meubles123!
- Fallback street: Avenue des Champs-Élysées
- Fallback postal code: 75008
- Fallback city: Paris

**Polish Market (pl):**
- Name: Mia Moebel.de-Test
- Street: Marszałkowska
- House number: 3
- Postal code: 20-001  ← Polish format is XX-XXX (with dash) — required by IdoSell validation
- City: Warszawa
- Email: partner@moebel.de
- Phone: 040210910730
- Password: Moebel.de-test1
- Fallback street: Nowy Świat
- Fallback postal code: 00-497
- Fallback city: Warszawa

**Other Markets:** Use German test data as fallback, but adapt postal code and street to the local format. Fallback addresses follow the same pattern — use a known real street name in the capital city.

**⚠️ Address priority rule:** Always try the primary address first. Only switch to the fallback address if the checkout returns a shipping error, carrier validation error, or explicitly rejects the address. Document which address was used in the report.

**⚠️ CRITICAL — Email address rules:**
- ALWAYS use the market's designated email listed above. NEVER invent, generate, or modify the email address (e.g., no `partner2@`, no `partner.pl.test@`, no random suffixes).
- These are the official test accounts for their markets. Any other address breaks traceability and violates test protocol.
- The same email will often already be registered on a partner's platform from a previous test. This is expected and normal. See Phase 3 Step 3.2 for the mandatory handling procedure.

## Integration Documentation References

Reference these when writing troubleshooting recommendations. Each integration has a local reference doc bundled with the plugin under `hepler-documantations/` (read locally when you need the implementation details) AND a public URL (used in partner-facing reports and Jira drafts).

1. **GTM Client-Side Integration** — For GTM client-side issues. Local: [`GTM Client Side Integration Documantation.md`](../../hepler-documantations/GTM%20Client%20Side%20Integration%20Documantation.md)
2. **GTM Server-Side Integration** — For GTM server-side issues. Local: [`GTM Server-Side Integration Documantation.md`](../../hepler-documantations/GTM%20Server-Side%20Integration%20Documantation.md)
3. **Shopify Custom Pixel Integration** — For Shopify custom pixels. Local: [`Shopify Integration Documantation.md`](../../hepler-documantations/Shopify%20Integration%20Documantation.md)
4. **Manual Client-Side Integration** — For manual client-side implementation. Local: [`Manual Client Side Integration Documantation.md`](../../hepler-documantations/Manual%20Client%20Side%20Integration%20Documantation.md)
5. **Manual Server-Side Integration** — For manual server-side implementation. Local: [`Manual Server-Side Integration Documantation.md`](../../hepler-documantations/Manual%20Server-Side%20Integration%20Documantation.md)

**URL reference table** (canonical source of truth — never edit URLs without updating this table):

| Integration type | Public documentation URL | Local reference file |
| --- | --- | --- |
| GTM Client-Side | https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html | [GTM Client Side Integration Documantation.md](../../hepler-documantations/GTM%20Client%20Side%20Integration%20Documantation.md) |
| GTM Server-Side | https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-server-side.html | [GTM Server-Side Integration Documantation.md](../../hepler-documantations/GTM%20Server-Side%20Integration%20Documantation.md) |
| Manual Client-Side | https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html | [Manual Client Side Integration Documantation.md](../../hepler-documantations/Manual%20Client%20Side%20Integration%20Documantation.md) |
| Manual Server-Side | https://partner-integration.moebel.de/sales-tracking/1/manual-server-side-integration.html | [Manual Server-Side Integration Documantation.md](../../hepler-documantations/Manual%20Server-Side%20Integration%20Documantation.md) |
| Shopify Custom Pixel | *(not publicly available yet — to be linked once published)* | [Shopify Integration Documantation.md](../../hepler-documantations/Shopify%20Integration%20Documantation.md) |

**Rule:** When generating partner-facing reports / Jira drafts / emails, always use the **Public documentation URL** — never link the local helper file. The local file is for the agent's own reading when it needs to look up implementation details (e.g., expected payload structure, tag setup steps).

## Market Code → Uppercase Mapping (Jira/email reports)

- `de` → `DE`
- `fr` → `FR`
- `nl` → `NL`
- `at` → `AT`
- `ch` → `CH`
- `es` → `ES`
- `it` → `IT`
- `pl` → `PL`
- `gb` → `GB`
