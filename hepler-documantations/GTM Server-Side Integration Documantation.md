# Server-Side Tracking with Google Tag Manager

> **Important:** This integration requires a **server container** in Google Tag Manager (server-side tagging) and **cannot** be used with a classic web container. If you do not use a server container, please follow the guideline for client-side integration with Google Tag Manager instead.

## How does it work?

When a user clicks on one of your products on `moebel.de`, `meubles.fr`, `meubelo.nl`, `moebel24.at`, `moebel24.ch`, `mobi24.es`, `mobi24.it`, `living24.pl` or `living24.uk`, our server generates a unique clickID (`moeclid`) which is appended as a query parameter to your landing page URL.

With the integration of our Custom Tag Template in your server container, the clickID is written into a corresponding first-party cookie called `moeclid`. The cookie is set by your tracking server as an HTTP cookie with an expiration of **90 days**. Our server does not get any requests from you unless the user converts.

If the user makes a purchase on your site and has an existing `moeclid` cookie in their browser, a conversion event is sent to our server including the `moeclid` value and further purchase-related data.

> **Note:** We are requesting **unattributed sales data** from you. As we utilize this data to promote your products through our algorithm, attributing sales to specific customers or sources may negatively impact the scoring of your products, leading to poorer performance.

## Prerequisites

Before you proceed with this integration, make sure the following conditions are met:

- You have received your **Partner ID** or dedicated **Sales Tracking Key**.
- You have set up **server-side tagging** with Google Tag Manager and have a configured **web AND server container**.
- You have configured the following **GA4 events** in your web container, which are delivered to your server:
  - `page_view`
  - `purchase`
- Your server container is mapped to a **custom subdomain**.

## Integration

1. First, download the tag template: **`moebel_salestracking.tpl`**
2. In your GTM server container, go to **Templates**.
3. In the **Tag Templates** section, click **New**.
4. Click the three dots in the upper right corner and select **Import**.
5. Choose the downloaded template file.
6. After importing the template, you can start creating the tags.

> **Note:** The tag template is currently under review and not yet available in the template gallery.

---

## Base Code

The base code tag enables setting the `moeclid` cookie which stores the moebel.de-specific clickID. Its trigger is configured so the tag only fires if the user reached your site through moebel.de — it does not affect your traffic from other marketing channels.

### Setup Steps

1. Add a new tag and select **"moebel.de Salestracking"** as the tag type.
2. Choose **"Base Code"** as the event type.
3. As **URL Source**, select the variable which stores the location of the page.
4. Create a new **Page View** trigger where the URL of the page contains `moeclid=`. This way, the base code tag is only fired if a user reached your site through a moebel.de product click.
5. Add the trigger to the tag and save the tag.

---

## Conversion

The conversion tag sends a purchase event to us at the time the user converts. Its trigger is configured so that only purchases with a `moeclid` cookie are transmitted. Besides the `moeclid` and your partner key, the request is supposed to contain further event data (see step 4 / parameter table below).

### Setup Steps

1. Add a new tag and select **"moebel.de Salestracking"** as the tag type.
2. Choose **"Conversion"** as the event type.
3. Choose the portal where you want to send the request to (e.g. `moebel.de`, `meubles.fr`, `meubelo.nl`, `mobi24.es`, etc.).
4. Enter your **partner key** (provided by your account manager).
5. Add all required properties with the corresponding values to the **JSON Request Body** (see parameter table below).
6. To grab the required value for the `moeclid` property, create a new **"Cookie Value"** variable with the cookie name `moeclid`. All other variables can be created based on the incoming GA4 `purchase` event by using the variable type **"Event Data"**.
7. Create a new **"Custom Event"** trigger with the event name `purchase`, where the `moeclid` cookie variable does **not** equal `undefined`. This way, you only send requests for moebel.de-related conversions.
8. Add the trigger to the tag and save the tag.
9. **Publish** your container version.

### JSON Request Body — Parameter Reference

| Parameter               | Description                                                        | Mandatory | Data Type | Example                                | Comment                                                    |
| ----------------------- | ------------------------------------------------------------------ | --------- | --------- | -------------------------------------- | ---------------------------------------------------------- |
| `moeclid`               | Unique clickout ID from moebel.de (stored in the `moeclid` cookie) | Yes       | string    | `0f81f6c0-bee9-420f-8f1f-e9f7f79f5424` | —                                                          |
| `value`                 | Gross total basket value, without shipping costs, including tax    | Yes       | float     | `1499.97`                              | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `shipping`              | Shipping costs                                                     | Yes       | float     | `29.99`                                | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `items`                 | Array of unique items in the order                                 | Yes       | array     | See below                              | —                                                          |
| `items[].item_id`       | Your SKU ID                                                        | Yes       | string    | `47886359`                             | —                                                          |
| `items[].quantity`      | Product quantity                                                   | Yes       | integer   | `1`                                    | —                                                          |
| `items[].price`         | Gross product price                                                | Yes       | float     | `899.99`                               | 2 digits, `.` as decimal delimiter, no thousand delimiters |
| `items[].item_category` | Your category name of the item                                     | Yes       | string    | `boxspringbetten`                      | —                                                          |
| `currency`              | Currency                                                           | Yes       | string    | `EUR`                                  | DIN Norm                                                   |
| `order_id`              | Your identifier for the order                                      | No        | string    | `1172210481407`                        | —                                                          |

### Example `items` Array

```json
[
  {
    "item_id": "47886359",
    "quantity": "1",
    "price": "899.99",
    "item_category": "boxspringbetten"
  },
  {
    "item_id": "31118801",
    "quantity": "2",
    "price": "299.99",
    "item_category": "heimtextilien"
  }
]
```

### Example Full JSON Request Body

```json
{
  "moeclid": "0f81f6c0-bee9-420f-8f1f-e9f7f79f5424",
  "value": 1499.97,
  "shipping": 29.99,
  "items": [
    {
      "item_id": "47886359",
      "quantity": 1,
      "price": 899.99,
      "item_category": "boxspringbetten"
    },
    {
      "item_id": "31118801",
      "quantity": 2,
      "price": 299.99,
      "item_category": "heimtextilien"
    }
  ],
  "currency": "EUR",
  "order_id": "1172210481407"
}
```
