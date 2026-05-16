# GTM Server-Side Custom Tag Template — Source Reference

This is the **sandboxed JavaScript code** powering the `moebel.de Salestracking` Custom Tag Template used in the [Server-Side GTM Integration](./server-side-gtm-integration.md). It runs inside the GTM **server container** and handles both the **Base Code** (setting the `moeclid` cookie) and **Conversion** (POSTing sales data to the moebel.de API) event types in a single template.

## Required GTM Sandboxed APIs

The template uses Google Tag Manager's sandboxed JavaScript APIs — these must be granted permission in the template configuration:

| API                   | Purpose                                                         |
| --------------------- | --------------------------------------------------------------- |
| `sendHttpRequest`     | POST the conversion payload to the moebel.de redirect API       |
| `getEventData`        | Read the incoming event's `page_location`                       |
| `JSON`                | Stringify request/response bodies for logging                   |
| `setCookie`           | Persist the `moeclid` cookie for 90 days                        |
| `parseUrl`            | Extract the `moeclid` query parameter from the landing-page URL |
| `encodeUriComponent`  | Safely encode the `partnerKey` in the request URL               |
| `getRequestHeader`    | Read the `trace-id` header for log correlation                  |
| `makeTableMap`        | Convert the GTM `bodyData` table into a JS object               |
| `logToConsole`        | Emit structured debug logs                                      |
| `getContainerVersion` | Detect debug mode so logs only fire when intended               |

## Cookie Configuration

The `moeclid` cookie is set with these options (90-day lifetime = `7776000` seconds):

```js
const COOKIE_OPTIONS = {
  domain: "auto",
  path: "/",
  secure: true,
  "max-age": 7776000, // 90 days
  httpOnly: false,
};
```

> `httpOnly: false` is required because the cookie may need to be read by other client-side scripts on the partner's checkout page.

## Execution Flow

1. **Event type dispatch** — `processData` reads the `eventType` field. If it's `base_code`, it routes to `processBaseCode`; otherwise it treats the call as a **Conversion**.
2. **Base Code branch** — Parses the landing-page URL, extracts the `moeclid` query parameter, and writes it to a first-party cookie.
3. **Conversion branch** — Builds the POST URL (`portal + "?key=" + partnerKey`), assembles the JSON body from the `bodyData` table, force-sets `type: "s2s"`, and sends the request to the moebel.de redirect endpoint.
4. **Response handling** — Status `2xx` calls `gtmOnSuccess()`; anything else calls `gtmOnFailure()`.

---

## Full Source

```javascript
const sendHttpRequest = require("sendHttpRequest");
const getEventData = require("getEventData");
const JSON = require("JSON");
const setCookie = require("setCookie");
const parseUrl = require("parseUrl");
const encodeUriComponent = require("encodeUriComponent");
const getRequestHeader = require("getRequestHeader");
const traceId = getRequestHeader("trace-id");
const makeTableMap = require("makeTableMap");
const logToConsole = require("logToConsole");
const getContainerVersion = require("getContainerVersion");

const COOKIE_OPTIONS = {
  domain: "auto",
  path: "/",
  secure: true,
  "max-age": 7776000,
  httpOnly: false,
};

function determinateIsLoggingEnabled(data) {
  const logType = data.logType;
  if (!logType || logType === "debug") {
    return getContainerVersion().debugMode;
  }
  return logType === "always";
}

function processBaseCode(dataToProcess) {
  const urlSource = dataToProcess.urlSource;
  const parsedUrl = parseUrl(
    urlSource === "page_location_default"
      ? getEventData("page_location")
      : urlSource,
  );

  const name = "moeclid";
  const value =
    parsedUrl && parsedUrl.searchParams ? parsedUrl.searchParams[name] : "";

  if (value) {
    setCookie(name, value, COOKIE_OPTIONS, false);
  }

  dataToProcess.gtmOnSuccess();
}

function handleResponseFactory(dataToProcess, isLoggingEnabled) {
  return (statusCode, responseHeaders, responseBody) => {
    if (isLoggingEnabled) {
      logToConsole(
        JSON.stringify({
          Name: "moebel.de",
          TraceId: traceId,
          EventName: "Sale",
          Type: "Response",
          ResponseStatusCode: statusCode,
          ResponseHeaders: responseHeaders,
          ResponseBody: responseBody,
        }),
      );
    }

    return statusCode >= 200 && statusCode < 300
      ? dataToProcess.gtmOnSuccess()
      : dataToProcess.gtmOnFailure();
  };
}

function processData(dataToProcess) {
  const eventType = dataToProcess.eventType;
  const portal = dataToProcess.portal;
  const partnerKey = dataToProcess.partnerKey;
  const bodyData = dataToProcess.bodyData;
  const isLoggingEnabled = determinateIsLoggingEnabled(dataToProcess);

  if (eventType === "base_code") {
    return processBaseCode(dataToProcess);
  }

  const postUrl = portal + "?key=" + encodeUriComponent(partnerKey || "");
  const postBodyData = bodyData ? makeTableMap(bodyData, "key", "value") : {};

  postBodyData.type = "s2s";

  if (isLoggingEnabled) {
    logToConsole(
      JSON.stringify({
        Name: "moebel.de",
        TraceId: traceId,
        EventName: "Sale",
        Type: "Request",
        RequestMethod: "POST",
        RequestUrl: postUrl,
        RequestBody: postBodyData,
      }),
    );
  }

  sendHttpRequest(
    postUrl,
    handleResponseFactory(dataToProcess, isLoggingEnabled),
    {
      headers: { "Content-Type": "application/json" },
      method: "POST",
    },
    JSON.stringify(postBodyData),
  );
}

processData(data);
```

---

## Tag Configuration Fields (`data` object)

These are the fields the template reads from the GTM tag configuration form:

| Field        | Type   | Used When  | Description                                                                                                                                                |
| ------------ | ------ | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eventType`  | string | always     | `"base_code"` or any other value (treated as Conversion)                                                                                                   |
| `urlSource`  | string | Base Code  | Either the literal string `"page_location_default"` (read from the GA4 event) or a custom URL variable reference                                           |
| `portal`     | string | Conversion | Full endpoint URL of the portal (e.g. `https://redirect.moebel.de/api/1.0/moebel/de/sales`)                                                                |
| `partnerKey` | string | Conversion | Partner ID / Sales Tracking Key from the account manager                                                                                                   |
| `bodyData`   | table  | Conversion | Key/value table mapped into the JSON request body (`moeclid`, `value`, `shipping`, `items`, `currency`, `order_id`) — `type: "s2s"` is added automatically |
| `logType`    | string | always     | `"debug"` (logs only in debug mode), `"always"` (always logs), or unset (defaults to debug)                                                                |

## Notes

- The `type` field on the request body is **always overwritten to `"s2s"`** — partners cannot change this from the tag config.
- The Base Code path silently no-ops if no `moeclid` query parameter is present on the URL. It does **not** call `gtmOnFailure()` in that case — `gtmOnSuccess()` is always called.
- Logs are JSON-stringified single lines, tagged with `Name: "moebel.de"` and the inbound `trace-id` header, so they can be correlated with GA4 server logs.
