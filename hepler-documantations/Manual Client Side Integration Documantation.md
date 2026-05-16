# Manual Client-Side Integration

## How does it work?

When a user clicks on one of your products on `moebel.de`, `meubles.fr`, `meubelo.nl`, `moebel24.at`, `moebel24.ch`, `mobi24.es`, `mobi24.it`, `living24.pl` or `living24.uk`, our server generates a unique clickID (`moeclid`) which is appended as a query parameter to your landing page URL. With the integration of our client-side script, the clickID is written into the local storage for **90 days**. Our server does not get any requests from you unless the user converts.

If the user makes a purchase on your site and has an existing `moeclid` value in the local storage of the browser, a conversion event is sent to our server including the clickID and further purchase-related data.

## Prerequisites

Before you proceed with this integration, make sure the following conditions are met:

- You have received your **Partner ID** or dedicated **Sales Tracking Key**.

## Integration

The client-side sales tracking consists of two main `<script>` tags — the **initialization script** and the **push script**.

---

## 1. Initialization Script

The initialization script needs to be inserted on any page where the user directly lands after clicking on a product on our portal. The script writes the appended `moeclid` parameter value of the landing page URL into the local storage of the browser.

### Initialization Script per Portal

| Portal      | Script Tag                                                              |
| ----------- | ----------------------------------------------------------------------- |
| moebel.de   | `<script src="https://www.moebel.de/partner/initialize.js"></script>`   |
| meubles.fr  | `<script src="https://www.meubles.fr/partner/initialize.js"></script>`  |
| meubelo.nl  | `<script src="https://www.meubelo.nl/partner/initialize.js"></script>`  |
| moebel24.at | `<script src="https://www.moebel24.at/partner/initialize.js"></script>` |
| moebel24.ch | `<script src="https://www.moebel24.ch/partner/initialize.js"></script>` |
| mobi24.es   | `<script src="https://www.mobi24.es/partner/initialize.js"></script>`   |
| mobi24.it   | `<script src="https://www.mobi24.it/partner/initialize.js"></script>`   |
| living24.pl | `<script src="https://www.living24.pl/partner/initialize.js"></script>` |
| living24.uk | `<script src="https://www.living24.uk/partner/initialize.js"></script>` |

### Example: Initialization script on the landing page

The initialization script can be placed in the `<head>` tag or at the bottom of the `<body>` tag of the page where the user lands after clicking on a product on our portal.

**Example 1 — In the `<head>`:**

```html
<html>
  <head>
    <title>initialize script in head tag</title>
    <script src="https://www.moebel.de/partner/initialize.js"></script>
  </head>
  <body>
    ...
  </body>
</html>
```

**Example 2 — At the end of `<body>`:**

```html
<html>
  <head>
    <title>initialize script at the end of body tag</title>
  </head>
  <body>
    <div>A lot of content here</div>
    ...
    <div>A lot of content here</div>
    <script src="https://www.moebel.de/partner/initialize.js"></script>
  </body>
</html>
```

> **Important:** Since local storage cannot be shared across domains/subdomains, saving the clickID (`moeclid`) to use at checkout will not work if the actual checkout page is on a different domain/subdomain than the product page the user was sent from us.

---

## 2. Push Script

This script exposes a JavaScript API that shall be used to submit sales data. It should be placed on the checkout page and the API call should be made after the checkout is completed.

> **Note:** You will need to enter your **Partner ID** or dedicated **Sales Tracking Key** (provided by your account manager) in the `data-partner-key` attribute.

### Push Script per Portal

| Portal      | Script Tag                                                                                                |
| ----------- | --------------------------------------------------------------------------------------------------------- |
| moebel.de   | `<script src="https://www.moebel.de/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>`   |
| meubles.fr  | `<script src="https://www.meubles.fr/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>`  |
| meubelo.nl  | `<script src="https://www.meubelo.nl/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>`  |
| moebel24.at | `<script src="https://www.moebel24.at/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>` |
| moebel24.ch | `<script src="https://www.moebel24.ch/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>` |
| mobi24.es   | `<script src="https://www.mobi24.es/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>`   |
| mobi24.it   | `<script src="https://www.mobi24.it/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>`   |
| living24.pl | `<script src="https://www.living24.pl/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>` |
| living24.uk | `<script src="https://www.living24.uk/partner/push.js" data-partner-key="INSERT-YOUR-KEY-HERE"></script>` |

When properly included, this script exposes a global `MOEBEL_SALES` object that allows the use of API functions.

> **Note:** If the `data-partner-key` attribute is missing or empty, the API is **not** exposed. If there is no clickID from the initialization script in the browser's local storage, calling the sales function will do nothing. The script also removes outdated clickIDs (older than 90 days) from the local cache.

---

## JavaScript API

The JavaScript API is exposed through the `push.js` script on the global scope and is accessible through the properties of the global object `MOEBEL_SALES`.

### Sale Function

The `sale` function is used to report sales for product(s). It reports sales only if the user came to your site by clicking on one of your products on our portal within the last **90 days**.

#### Type Signature

```ts
MOEBEL_SALES.sale(object: SaleObject)

SaleObject {
  total:    Number,           // required, e.g. 1, 1.0, 10.12
  shipping: Number | String,  // required, e.g. 1, 1.0, 10.12 or "100.00"
  currency: String,           // optional, missing currency assumes "EUR" (e.g. "EUR", "CHF", "USD")
  orderId:  String | Number,  // optional, e.g. "e04cc718-85bf-11ed-a1eb-0242ac120002" or 123
  items:    Array<Item>       // required, must not be empty
}

Item {
  id:       String | Number,  // required, e.g. "113b4c3c-85c0-11ed-a1eb-0242ac120002" or 123
                              // ALIAS: item_id (can be used instead of `id`)
  quantity: Number (Integer), // required, e.g. 1
  price:    Number | String,  // required, e.g. 33, 33.33 or "100.00"
  category: String            // optional, e.g. "Sofas", "Baumarkt"
                              // ALIAS: item_category (can be used instead of `category`)
}
```

### Usage Example

```html
<!-- On the checkout/confirmation page -->
<script
  src="https://www.moebel.de/partner/push.js"
  data-partner-key="0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75"
></script>

<script>
  MOEBEL_SALES.sale({
    total: 1499.97,
    shipping: 29.99,
    currency: "EUR",
    orderId: "1172210481407",
    items: [
      {
        item_id: "47886359",
        quantity: 1,
        price: 899.99,
        item_category: "Boxspringbetten",
      },
      {
        item_id: "31118801",
        quantity: 2,
        price: 299.99,
        item_category: "Heimtextilien",
      },
    ],
  });
</script>
```

### Parameter Reference

| Parameter                                    | Description                                                     | Mandatory | Data Type | Example           | Comment                                                    |
| -------------------------------------------- | --------------------------------------------------------------- | --------- | --------- | ----------------- | ---------------------------------------------------------- |
| `total`                                      | Gross total basket value, without shipping costs, including tax | Yes       | float     | `1499.97`         | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `shipping`                                   | Shipping costs                                                  | Yes       | float     | `29.99`           | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `currency`                                   | Currency                                                        | Yes       | string    | `EUR`             | DIN Norm                                                   |
| `orderId`                                    | Your identifier for the order                                   | No        | string    | `1172210481407`   | —                                                          |
| `items`                                      | Array of unique items                                           | Yes       | array     | See below         | —                                                          |
| `items[].item_id` _(alias `id`)_             | Your SKU ID                                                     | Yes       | string    | `47886359`        | —                                                          |
| `items[].quantity`                           | Product quantity                                                | Yes       | integer   | `1`               | —                                                          |
| `items[].price`                              | Gross product price                                             | Yes       | float     | `899.99`          | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `items[].item_category` _(alias `category`)_ | Your category name of the item                                  | Yes       | string    | `Boxspringbetten` | —                                                          |

#### Example `items` array

```json
[
  {
    "item_id": "47886359",
    "quantity": "1",
    "price": "899.99",
    "item_category": "Boxspringbetten"
  },
  {
    "item_id": "31118801",
    "quantity": "2",
    "price": "299.99",
    "item_category": "Heimtextilien"
  }
]
```
