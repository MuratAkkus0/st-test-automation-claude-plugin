# Shopify Integration – Custom Sales Tracking Pixel

Für Shopify-Partner steht zusätzlich ein allgemeines Integrations-Guide für die **Custom Sales Tracking Pixel** zur Verfügung.

## Technical Note

Die vorgeschlagene Lösung basiert auf einer **Client-Side-Implementierung** und ist technisch äquivalent zu unserem **GTM Client-Side-Setup**. Der wesentliche Unterschied besteht darin, dass sie vollständig in die Shopify-Umgebung integriert ist und nicht auf externe Systeme angewiesen ist.

## Pixel erstellen

1. Öffne in eurem **Shopify-Admin-Bereich** die **Settings**.
2. Navigiere zu **Customer Events**.
3. Über den Button **„Add custom pixel"** kann der Partner anschließend einen neuen Pixel anlegen.

## Privacy Configuration (für beide Pixel)

Die folgende Konfiguration ist die Empfehlung — kann natürlich vom Partner angepasst werden:

| Einstellung    | Wert                            | Bedeutung                                                                                  |
| -------------- | ------------------------------- | ------------------------------------------------------------------------------------------ |
| **Permission** | Not required                    | Der Pixel wird immer ausgeführt.                                                           |
| **Data Sale**  | Does not qualify as a data sale | Der Pixel sammelt weiterhin Daten, auch wenn Kunden dem Verkauf ihrer Daten widersprechen. |

---

## Custom Pixel – moebel.de | Base Code Pixel

Dieser Pixel wird bei jedem Page View ausgelöst. Er prüft, ob der URL-Parameter `moeclid` vorhanden ist, und lädt in diesem Fall das Initialisierungsskript, welches die Click-ID im Local Storage speichert.

```javascript
analytics.subscribe("page_viewed", (pageViewEvent) => {
  const pageUrl = new URL(pageViewEvent.context.document.location.href);
  const clickId = pageUrl.searchParams.get("moeclid");
  if (!clickId) return;

  const initScript = document.createElement("script");
  // Replace with the related domain (e.g. meubles.fr, meubelo.nl, moebel24.at, moebel24.ch, mobi24.es)
  initScript.src = "https://www.moebel.de/partner/initialize.js";

  document.head.appendChild(initScript);
});
```

> **Hinweis:** Die URL `https://www.moebel.de/partner/initialize.js` muss durch die zum jeweiligen Portal passende Domain ersetzt werden (z. B. `meubles.fr`, `meubelo.nl`, `moebel24.at`, `moebel24.ch`, `mobi24.es`, `mobi24.it`, `living24.pl`, `living24.uk`).

---

## Custom Pixel – moebel.de | Conversion Pixel

Dieser Pixel wird beim **erfolgreichen Abschluss des Checkouts** ausgelöst. Er übermittelt die relevanten Bestelldaten an unser System — jedoch nur, wenn zuvor ein `moeclid` gesetzt wurde.

```javascript
analytics.subscribe("checkout_completed", (checkoutEvent) => {
  const checkoutData = checkoutEvent.data?.checkout;

  const lineItems = checkoutData.lineItems.map((lineItem) => ({
    item_id: lineItem.id,
    quantity: lineItem.quantity,
    price: lineItem.variant.price.amount,
    item_category: lineItem.title,
  }));

  const salePayload = {
    total: checkoutData.subtotal?.amount,
    shipping: checkoutData.shippingLine?.price?.amount,
    currency: "EUR",
    orderId: checkoutData.order?.id,
    items: lineItems,
  };

  const pushScript = document.createElement("script");
  // Replace with the related domain (e.g. meubles.fr, meubelo.nl, moebel24.at, moebel24.ch, mobi24.es)
  pushScript.src = "https://www.moebel.de/partner/push.js";
  pushScript.dataset.partnerKey = "INSERT-YOUR-PARTNER-KEY";
  pushScript.onload = () => {
    if (window.MOEBEL_SALES) {
      window.MOEBEL_SALES.sale(salePayload);
    }
  };

  document.head.appendChild(pushScript);
});
```

### Wichtige Anpassungen vor dem Live-Gang

- **Skript-Domain**: `https://www.moebel.de/partner/push.js` muss durch die zum jeweiligen Portal passende Domain ersetzt werden (`meubles.fr`, `meubelo.nl`, `moebel24.at`, `moebel24.ch`, `mobi24.es`, `mobi24.it`, `living24.pl`, `living24.uk`).
- **Partner Key**: `INSERT-YOUR-PARTNER-KEY` muss durch den vom Account Manager bereitgestellten Partner Key / Sales Tracking Key ersetzt werden.

---

## Hinweis zum Pixel-Setup

Das vorliegende Setup ist **vollständig** und kann direkt in Shopify implementiert werden. Nach der Implementierung der Custom Pixels sollten die Änderungen bitte in Shopify **veröffentlicht** werden.

---

## ⚠️ Wichtiger Hinweis zur bestehenden GTM-Integration (optional)

Da diese Lösung direkt in Ihrem Shopify-Shop implementiert wird, bitten wir Sie, **alle bestehenden GTM-Konfigurationen** im Zusammenhang mit unserem Tracking **vollständig aus Ihren Containern zu entfernen**, um Doppel-Trackings zu vermeiden.
