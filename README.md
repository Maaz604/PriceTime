# Price to Time

A Chrome extension that converts prices on any webpage into the equivalent amount of time you'd need to work to afford them, based on a customizable hourly wage.

---

## Overview

Every price tag on the internet is an abstraction. Seeing "$120" doesn't have much meaning on its own until you frame it in terms of real effort. At $20/hr, that's 6 hours of work. This extension makes that trade-off visible as you browse.

The goal was to build something genuinely useful, technically solid, and small in scope. It requires no sign-up, no external API, and collects no data. Everything runs locally in the browser.

---

## Features

- Detects and converts prices inline on any webpage
- Supports USD, EUR, GBP, and CAD formats
- Handles both static and dynamically loaded content (React, infinite scroll, etc.)
- Configurable hourly wage and expensive item threshold
- Highlights items that exceed a set work-hour threshold
- Enable/disable toggle without losing your settings
- Lightweight — no dependencies, no external requests

---

## How It Works

**Price detection** uses a regular expression to scan text nodes in the DOM for recognizable price patterns. The scanner walks the document tree using `TreeWalker` to avoid touching scripts, style tags, editable fields, and hidden elements. Each match is parsed into a numeric value and associated with its original raw string.

**Conversion logic** divides the detected price by the configured hourly wage to get a decimal hour value. Values under one hour are displayed in minutes; values over one hour are rounded to one decimal place. The threshold check flags items that would cost more than a set number of hours of work.

**Injection** replaces the original text node with a document fragment that preserves the original price text and appends a styled label. A custom `data-ptt-injected` attribute prevents double-injection on re-scans.

**Dynamic content** is handled by a `MutationObserver` watching the document body for new nodes. When new content appears (pagination results, modal dialogs, etc.), the scanner processes only the newly added subtree rather than re-walking the entire page.

**Settings** are stored via `chrome.storage.sync`, which means they persist across sessions and sync across devices if the user is signed into Chrome. The content script listens for storage changes and re-runs the injection with updated values whenever settings are saved.

---

## Demo

### Price conversion on a product page

[Insert screenshot of product page with converted prices here]

Store screenshots in a `/screenshots` directory and reference them like:

```
![Product page example](./screenshots/product-page.png)
```

### Extension popup UI

[Insert screenshot of extension popup UI here]

```
![Popup UI](./screenshots/popup.png)
```

### Expensive item highlight

[Insert screenshot showing highlighted expensive item here]

```
![Expensive item highlight](./screenshots/highlight.png)
```

---

## Installation

Since this extension is not published to the Chrome Web Store, it must be loaded manually.

1. Clone this repository:

   ```
   git clone https://github.com/yourusername/price-to-time-extension.git
   ```

2. Open Chrome and navigate to `chrome://extensions`.

3. Enable **Developer mode** using the toggle in the top-right corner.

4. Click **Load unpacked** and select the root directory of the cloned repository.

5. The extension icon should appear in the toolbar. Click it to configure your hourly wage.

---

## Usage

After installing, the extension runs automatically on every webpage. Prices will appear with a small gray annotation next to them showing the equivalent work time.

To configure:

- Click the extension icon to open the popup
- Enter your hourly wage (after tax, ideally)
- Adjust the highlight threshold if desired — this controls how many hours of work triggers the red emphasis
- Toggle the extension off temporarily without losing your settings

Changes take effect immediately on the current page.

---

## Design Decisions

**No framework.** The popup UI is built with plain HTML, CSS, and JavaScript. Given the scope, pulling in React or any build toolchain would have added complexity for no real benefit. The result loads faster and is easier to audit.

**TreeWalker over querySelectorAll.** When scanning for price strings, the relevant content lives in text nodes, not elements. `TreeWalker` with `NodeFilter.SHOW_TEXT` traverses only text nodes, which is more semantically appropriate and avoids unnecessarily touching every element on the page.

**Fragment-based replacement.** Rather than setting `innerHTML` or wrapping elements, prices are injected by replacing the original text node with a document fragment. This preserves surrounding DOM structure and avoids layout shifts or event listener disruption.

**Attribute-based deduplication.** A `data-ptt-injected` attribute marks parent elements that have already been processed. This is cheaper than keeping a WeakSet of injected nodes and survives re-scanning after settings changes (where labels are stripped and the attribute is cleared).

**`chrome.storage.sync` over `localStorage`.** Sync storage persists settings across devices tied to the same Google account. It has lower write limits than local storage, which is fine here since writes only happen on explicit save actions.

---

## Development Timeline

**Day 1**
- Set up project structure, wrote manifest.json with MV3 configuration
- Decided on final file layout

**Day 2**
- Implemented `parsePriceString` utility with regex supporting multiple currency formats
- Wrote `calculateWorkTime` and `formatWorkTime` with edge case handling (sub-minute, exactly 1 hour, etc.)

**Day 3**
- Built DOM scanning using `TreeWalker`
- Implemented fragment-based injection with deduplication attribute
- Added inline stylesheet injection for labels

**Day 4**
- Added `MutationObserver` for dynamic content handling
- Built popup HTML and CSS from scratch
- Connected popup inputs to `chrome.storage.sync`

**Day 5**
- Wired content script to respond to storage changes
- Refined label styling and expensive item highlight logic
- Tested across Amazon, eBay, various news sites, and SPA-style product pages
- Cleaned up code and wrote README

---

## Future Improvements

**Currency conversion.** The extension currently converts all prices to work time regardless of currency, assuming parity with the user's wage currency. Adding real exchange rates (fetched once and cached) would make it accurate for international shopping.

**Per-site toggle.** Some pages have dozens of prices and the annotation can get noisy. A per-domain blocklist stored in sync storage would let users opt certain sites out.

**After-tax wage estimate.** Most people think in gross salary terms. A simple tax estimator built into the popup (select country or province, enter gross hourly) would make the wage input more practical.

**Keyboard shortcut.** A hotkey to toggle the extension on/off without opening the popup would be a quick quality-of-life addition.

**Firefox support.** The extension uses only Web Extensions API features that are compatible with Firefox's MV3 implementation. Adjusting the manifest and testing in Firefox would make it cross-browser with minimal changes.
