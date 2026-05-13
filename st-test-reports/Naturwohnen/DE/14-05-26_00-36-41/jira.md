Hallo @[COLLEAGUE_NAME],

Ich habe den ST-Test für Naturwohnen auf dem DE-Markt gemacht und er war erfolgreich integriert, aber der Conversion-Tag muss noch getestet werden.

Der Base Part ist korrekt integriert: Nach Akzeptieren des Cookie-Consents wird der moeclid sofort im `MOEBEL_CLICKOUT_ID` localStorage gespeichert (Client-Side-Integration, kein Reload nötig). Der Conversion-Tag wurde in diesem Testlauf nicht geprüft, da auf Wunsch keine Bestellung aufgegeben wurde — ein Folgetest mit echter Bestellung ist erforderlich, um den Conversion-Teil zu validieren.

Relevante Dokumentation:
- [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)
- [Manual Client-Side Integration](https://partner-integration.moebel.de/sales-tracking/1/manual-client-side-integration.html)

Bestellungsinformationen:

- Moeclid: b8ae4a1c-27dc-4fb7-aa9f-8d7bd69e762b
- Bestellnr.: Keine Bestellung freigegeben
- Datum: 2026-05-14 00:36:41

---
_Created by Sales Tracking Test Automation_
