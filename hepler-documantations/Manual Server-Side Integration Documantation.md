# Manual Server-Side Integration

If you cannot decide for the Google Tag Manager integration, you can still opt for the manual server-side integration. The manual integration of server-side tracking should always be preferred over client-side integration for reliability reasons.

The manual integration requires your shop to identify traffic from us and report direct & post-sales. See explanatory sections at the bottom of this page.

## How does it work?

When a user clicks on one of your products on `moebel.de`, `meubles.fr`, `meubelo.nl`, `moebel24.at`, `moebel24.ch`, `mobi24.es`, `mobi24.it`, `living24.pl` or `living24.uk`, our server generates a unique ID (`moeclid`) which is appended as a query parameter to your landing page URL.

Your store shall remember this user by creating a first-party cookie with a lifetime of **90 days** that stores the ID submitted as the value of the request parameter (`moeclid`). The ID is required for submitting sales information to us later in the process.

> **Important:** Initialize the placement of the cookie on the server-side to ensure that in any circumstance you can recognize the visitor as a returning visitor within the set timeframe (90 days).

If the user makes a purchase on your site and has the cookie you created when they came to your shop, a conversion event shall be sent to our server including the ID of the `moeclid` query parameter and further purchase-related data.

> **Note:** We are requesting **unattributed sales data** from you. As we utilize this data to promote your products through our algorithm, attributing sales to specific customers or sources may negatively impact the scoring of your products, leading to poorer performance.

## Prerequisites

Before you proceed with this integration, make sure the following conditions are met:

- You have received your **Partner ID** or dedicated **Sales Tracking Key**.

## Submitting Sales Information

Each of our portals provides a single HTTP endpoint to which sales information should be sent. The only difference between the endpoints per portal is the endpoint URL.

### Endpoint URLs per Portal

| Portal      | Endpoint URL                                                                                  |
| ----------- | --------------------------------------------------------------------------------------------- |
| moebel.de   | `https://redirect.moebel.de/api/1.0/moebel/de/sales?key={{partner_id\|sales_tracking_key}}`   |
| meubles.fr  | `https://redirect.meubles.fr/api/1.0/moebel/fr/sales?key={{partner_id\|sales_tracking_key}}`  |
| meubelo.nl  | `https://redirect.meubelo.nl/api/1.0/moebel/nl/sales?key={{partner_id\|sales_tracking_key}}`  |
| moebel24.at | `https://redirect.moebel24.at/api/1.0/moebel/at/sales?key={{partner_id\|sales_tracking_key}}` |
| moebel24.ch | `https://redirect.moebel24.ch/api/1.0/moebel/ch/sales?key={{partner_id\|sales_tracking_key}}` |
| mobi24.es   | `https://redirect.mobi24.es/api/1.0/moebel/es/sales?key={{partner_id\|sales_tracking_key}}`   |
| mobi24.it   | `https://redirect.mobi24.it/api/1.0/moebel/it/sales?key={{partner_id\|sales_tracking_key}}`   |
| living24.pl | `https://redirect.living24.pl/api/1.0/moebel/pl/sales?key={{partner_id\|sales_tracking_key}}` |
| living24.uk | `https://redirect.living24.uk/api/1.0/moebel/gb/sales?key={{partner_id\|sales_tracking_key}}` |

## Endpoint Communication

Communicating with our tracking service using the endpoint URL requires a few parameters to be added to the endpoint call.

### HTTP Method

`POST`

### Query Parameter

| Parameter | Description                           | Mandatory | Data type | Example                                | Comment                          |
| --------- | ------------------------------------- | --------- | --------- | -------------------------------------- | -------------------------------- |
| `key`     | Your sales tracking key or partner ID | Yes       | string    | `0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75` | Provided by your account manager |

### Body Parameters

| Parameter               | Description                                                     | Mandatory | Data type | Example                                | Comment                                                    |
| ----------------------- | --------------------------------------------------------------- | --------- | --------- | -------------------------------------- | ---------------------------------------------------------- |
| `moeclid`               | Unique clickout ID from moebel.de                               | Yes       | string    | `0f81f6c0-bee9-420f-8f1f-e9f7f79f5424` | —                                                          |
| `value`                 | Gross total basket value, without shipping costs, including tax | Yes       | float     | `1499.97`                              | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `shipping`              | Shipping costs                                                  | Yes       | float     | `29.99`                                | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `type`                  | Sales tracking type (`s2s`, `c2s`)                              | Yes       | string    | `s2s`                                  | For this integration it is always `s2s` (server-to-server) |
| `items`                 | Array of unique items in order                                  | Yes       | array     | See below                              | —                                                          |
| `items[].item_id`       | Your SKU ID                                                     | Yes       | string    | `sp47886359`                           | —                                                          |
| `items[].quantity`      | Product quantity                                                | Yes       | integer   | `1`                                    | Integer, no delimiter                                      |
| `items[].price`         | Gross product price                                             | Yes       | float     | `299.99`                               | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `items[].item_category` | Your category name of the item                                  | Yes       | string    | `Couches`                              | —                                                          |
| `currency`              | Currency                                                        | Yes       | string    | `EUR`                                  | DIN Norm                                                   |
| `order_id`              | Your identifier for the order                                   | No        | string    | `1172210481407`                        | —                                                          |

### Example `items` array

```json
"items": [
  { "item_id": "sp47886359", "quantity": 1, "price": 899.99, "item_category": "Möbel" },
  { "item_id": "sp31118801", "quantity": 2, "price": 299.99, "item_category": "Couches" }
]
```

## cURL Examples

The request body is identical across all portals — only the endpoint URL changes.

### Generic Request Body

```json
{
  "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
  "value": "1499.97",
  "shipping": "29.99",
  "type": "s2s",
  "items": [
    {
      "item_id": "sp47886359",
      "quantity": 1,
      "price": 1499.97,
      "item_category": "Couches"
    }
  ],
  "currency": "EUR",
  "order_id": "1172210481407"
}
```

### moebel.de Partners

```bash
curl -X 'POST' \
  'https://redirect.moebel.de/api/1.0/moebel/de/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### meubles.fr Partners

```bash
curl -X 'POST' \
  'https://redirect.meubles.fr/api/1.0/moebel/fr/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### meubelo.nl Partners

```bash
curl -X 'POST' \
  'https://redirect.meubelo.nl/api/1.0/moebel/nl/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### moebel24.at Partners

```bash
curl -X 'POST' \
  'https://redirect.moebel24.at/api/1.0/moebel/at/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### moebel24.ch Partners

```bash
curl -X 'POST' \
  'https://redirect.moebel24.ch/api/1.0/moebel/ch/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### mobi24.es Partners

```bash
curl -X 'POST' \
  'https://redirect.mobi24.es/api/1.0/moebel/es/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### mobi24.it Partners

```bash
curl -X 'POST' \
  'https://redirect.mobi24.it/api/1.0/moebel/it/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### living24.pl Partners

```bash
curl -X 'POST' \
  'https://redirect.living24.pl/api/1.0/moebel/pl/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

### living24.uk Partners

```bash
curl -X 'POST' \
  'https://redirect.living24.uk/api/1.0/moebel/gb/sales?key=0a7b3e5a-3748-4f2c-9874-9cb05e9a2c75' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
    "value": "1499.97",
    "shipping": "29.99",
    "type": "s2s",
    "items": [
      { "item_id": "sp47886359", "quantity": 1, "price": 1499.97, "item_category": "Couches" }
    ],
    "currency": "EUR",
    "order_id": "1172210481407"
  }'
```

## Identify Traffic From Us

Communicate only sales and turnover based on traffic from one of our portals (`moebel.de`, `meubles.fr`, `meubelo.nl`, `moebel24.at`, `moebel24.ch`, `mobi24.es`, `mobi24.it`, `living24.pl`, `living24.uk`).

### Through an Existing Query Parameter

Each user who comes to your shop from one of our portals will have an additional query parameter called `moeclid` attached to the URL. You can check for the existence of this query parameter to identify that this user was sent to you by us.

### Through Your Own Query Parameter

When submitting your product catalog to us, you have the option to add parameters to the product deep links leading to each product's detail page. This will enable you to determine if the user accessed the page through one of our portals.

Example:

```
https://www.your-shop.de/sofa-nespolo-3-sitzer-echtleder-dunkelbraun-1?referrer=moebel
```

**Option 1:** When submitting your product catalog, add a query parameter to each product URL / deep link.

**Option 2:** You can configure a query parameter in the Partner Portal, which will be automatically added to each link to your products.

## Report Direct and Post-Sales

We require that any purchase made within **90 days** by a visitor who was referred to your store through one of our portals be reported to us using sales tracking.

By identifying traffic originating from one of our portals, you can create a cookie for those visitors that is valid for 90 days. During the checkout process of your store, you can check for the presence of the cookie and report the sales data accordingly. This allows you to track sales generated by visitors we referred to your store within the past 90 days.

> **Mobile note:** If you have a mobile version of your store that is optimized for smartphones, it is important to ensure that it behaves in the same way as the desktop version.
