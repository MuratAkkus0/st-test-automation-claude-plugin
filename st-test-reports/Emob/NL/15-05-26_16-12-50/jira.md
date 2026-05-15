Hallo @[COLLEAGUE_NAME],

Ich habe den ST-Test für Emob auf dem NL-Markt gemacht und er war leider nicht erfolgreich.

Der Base-Tag funktioniert einwandfrei – der moeclid wird nach dem Cookie-Consent korrekt im localStorage gespeichert. Der Conversion-Tag wird auf der Bestätigungsseite zwar aufgerufen und schickt die Daten an unser Sales-API, lädt aber das deutsche Push-Script (`https://www.moebel.de/partner/push.js`) statt das niederländische (`https://www.meubelo.nl/partner/push.js`). Dadurch werden alle NL-Conversions an das deutsche Sales-Endpoint (`redirect.moebel.de/.../de/sales`) gesendet und auf der DE-Integration verbucht — sie kommen in unserem NL-Markt nie an.

Der Partner verwendet aktuell den PARTNER_KEY `609d0e02-16de-4f17-abcb-190dad1d8701`. Falls für den NL-Markt ein eigener Key vergeben wurde, muss dieser zusammen mit der korrekten Push-Script-URL eingesetzt werden.

Relevante Dokumentation:
- [Client-Side Tracking with Google Tag Manager](https://partner-integration.moebel.de/sales-tracking/1/google-tag-manager-client-side.html)

Bestellungsinformationen:

- Moeclid: 6fc24c52-5232-41d4-8a59-756e41c64896
- Bestellnr.: 5000084845
- Datum: 2026-05-15 16:12:50
- Zahlungsmethode: Banküberweisung (Overschrijving)

---
_Created by Sales Tracking Test Automation_
