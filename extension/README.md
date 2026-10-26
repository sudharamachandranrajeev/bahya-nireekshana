# Nireekshana browser extension

Shows how much data each website uses in Chrome, Edge and Firefox. It is part of
[Bahya Nireekshana](../README.md).

The extension makes no network requests of its own. It has no remote code and no
analytics. Everything it records stays in the browser's extension storage on this
device.

## What it does

- **Per-site usage.** Every request is counted against the site of the tab that
  made it. A site is the registrable domain of the tab's address, so
  `www.bbc.co.uk` and `static.bbc.co.uk` are both `bbc.co.uk`. For each day it
  keeps data received, data sent, the number of requests, and the third-party
  hosts the site loaded (hosts on a different domain).
- **Popup.** Today's total for the browser, the current site (today, 7 days, third
  parties), top sites today, a 14-day trend, and a Block button for each of the
  current site's third-party domains.
- **Dashboard.** Today, 7 days, 30 days, this month or all time. Totals, a daily
  chart of download and upload, a sortable and searchable table of sites, and a
  detail panel for each site with its third-party hosts and daily trend.
- **Blocklist.** Block a domain and all its subdomains in every tab.
- **Data alerts.** Optional daily budgets in MB for the whole browser and per
  site. Each budget sends one notification on the day it is crossed.
- **Themes.** The same themes as the Nireekshana app, light and dark. You can
  import a theme exported from the app, and export the current theme.
- **Export and clear.** Export usage as JSON or CSV. Clear all usage history.

History older than 400 days is removed.

## What is measured

| | Firefox | Chrome and Edge |
|---|---|---|
| Data received | `responseSize` from Firefox: the bytes transferred, headers included, after compression | The `Content-Length` response header |
| Data sent | `requestSize` from Firefox: request headers and body | The request body size, when the browser exposes it |
| Accuracy | Measured | **Estimate** |

Chrome does not tell extensions how many bytes a request used. The extension
reads the `Content-Length` header instead, so in Chrome:

- Responses without that header (chunked or streamed) count as a request with 0 bytes.
- Headers are not counted, in either direction.
- Uploaded files only count when Chrome exposes their bytes.

In both browsers:

- Responses served from the cache are not counted. They did not use the network.
- WebSocket messages after the connection opens, and WebRTC traffic, are not visible to extensions.
- Requests blocked by the blocklist or another blocker are not counted.
- Requests made by a site's service worker count for that site. Requests from
  other extensions and the browser itself are grouped under **Browser & extensions**.
- Sites are found with a short built-in list of multi-part suffixes such as
  `co.uk`, `com.au` and `co.in`, not the full Public Suffix List. IP addresses
  and `localhost` are kept as they are.

The numbers are a guide to which sites use the most data. They will not match
your provider's meter exactly.

## Install

Download the zips from the
[latest release](https://github.com/sudharamachandranrajeev/bahya-nireekshana/releases).

**Chrome or Edge**

1. Unzip `Nireekshana-<version>-chrome.zip` into a folder you will keep.
2. Open `chrome://extensions` (or `edge://extensions`) and turn on **Developer mode**.
3. Click **Load unpacked** and pick the folder.

**Firefox**

The release zip is not signed yet, so Firefox loads it as a temporary add-on.
It is removed when Firefox restarts.

1. Open `about:debugging#/runtime/this-firefox`.
2. Click **Load Temporary Add-on** and pick `Nireekshana-<version>-firefox.zip`.
3. If the popup asks for access to all sites, click **Allow access**. Without it
   nothing can be measured.

Firefox 140 or newer is required. Chrome 116 or newer is required.

## Permissions

| Permission | Why |
|---|---|
| `webRequest` | To see each completed request and its size. Observe only. The extension never changes or delays requests with it. |
| `declarativeNetRequest` | To block the domains on your blocklist. The browser applies the rules; the extension does not see the blocked requests. |
| `storage` | To keep usage history, settings, the blocklist and imported themes on this device. |
| `unlimitedStorage` | 400 days of per-site history with third-party hosts can pass the default 10 MB storage limit in Chrome. |
| `notifications` | To show a data budget alert. |
| Host access to all sites (`<all_urls>`) | Request events are only reported for sites the extension has access to. It also lets the popup read the current tab's address without the `tabs` permission. |

No `tabs`, `activeTab`, `scripting` or content scripts are used. The extension
never reads page content.

## Privacy

- No accounts, no servers, no analytics, no remote code.
- Only domain names, byte counts and request counts are stored. Full URLs, page
  titles and request contents are never stored.
- Data stays in the browser's local extension storage until you clear it,
  remove the extension, or it is older than 400 days.
- Exports are files you save yourself.

## Build and test

Requirements: Node 22 or newer, and `zip` or Python 3.

```sh
# Run the tests (Node's built-in runner).
node --test 'extension/tests/*.test.mjs'

# Build both packages. The version defaults to the one in manifest.template.json.
extension/build.sh
extension/build.sh 0.2.0      # or v0.2.0
```

The build writes:

- `extension/dist/Nireekshana-<version>-chrome.zip`
- `extension/dist/Nireekshana-<version>-firefox.zip`
- `extension/dist/chrome/` and `extension/dist/firefox/`, unpacked, for **Load unpacked**
  and `about:debugging` during development.

The source tree is not loadable as is. Build first.

## Layout

```
extension/
  manifest.template.json   one template for both browsers
  build.sh                 builds dist/ zips
  tools/manifest.mjs       makes the Chrome and Firefox manifests
  icons/                   PNG icons rendered from branding/nireekshana.svg
  src/
    background.js          counts requests and writes them in batches
    shim.js                browser / chrome namespace
    lib/                   pure logic with no browser APIs (tested in Node)
    platform/              storage and blocklist rules
    ui/                    shared styles, theming, charts
    popup/                 toolbar popup
    dashboard/             dashboard (the options page)
  tests/                   node --test suites
```

The built-in themes come from `themes/builtin.json` at the repository root. The
build copies that file in, so the app and the extension always share it.

To redraw the icons after changing the logo:

```sh
for s in 16 32 48 128; do
  rsvg-convert -w $s -h $s branding/nireekshana.svg -o extension/icons/icon-$s.png
done
```
