Hallo @[COLLEAGUE_NAME],

Ich habe den ST-Test für MeinMassivholz auf dem DE-Markt gemacht und er war leider nicht erfolgreich.

Der Base Tag funktioniert einwandfrei — der moeclid wird nach dem Cookie-Consent korrekt im localStorage gespeichert. Der Conversion Tag wird auf der Bestätigungsseite zwar aufgerufen, aber `total`, `shipping`, `items` und `orderId` werden als `undefined` aus dem DataLayer übergeben. Dadurch verwirft die MOEBEL_SALES-SDK den Sale-Aufruf und es geht überhaupt kein Request an unseren Endpoint raus. Der Partner muss den DataLayer-Push auf `/checkout/finish` reparieren und die GTM-Variable für die Bestellnummer korrigieren (aktuell wird der String `"undefined"` gesendet).

Relevante Dokumentation:
- [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)

Bestellungsinformationen:

- Moeclid: ee3f55cc-47c1-4135-8264-3a9acfc85c17
- Bestellnr.: 31708
- Datum: 2026-05-15 10:30:22
- Zahlungsmethode: Vorkasse

---
_Created by Sales Tracking Test Automation_
