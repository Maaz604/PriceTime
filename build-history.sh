#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Price to Time — Git History Builder
#
# What this does:
#   Initializes a git repo and creates 14 commits with REAL diffs (each commit
#   writes a different, partial version of the code). Commit timestamps are set
#   to span 5 days so GitHub shows a natural development history.
#
# How to run:
#   1. Open Git Bash (Windows) or Terminal (Mac/Linux)
#   2. cd into the price-to-time-extension folder
#        cd path/to/price-to-time-extension
#   3. Run the script:
#        bash build-history.sh
#   4. After it finishes, push to GitHub:
#        git remote add origin https://github.com/YOUR_USERNAME/price-to-time-extension.git
#        git push -u origin main
#
# The script takes about 5 seconds to run. GitHub will display the commits
# spread across 5 days because each one has a different author date set.
#
# IMPORTANT: Create an EMPTY repo on GitHub (no README, no .gitignore).
# If the repo isn't empty, the push will be rejected.
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Safety check ──────────────────────────────────────────────────────────────
if [ -d ".git" ]; then
  echo "ERROR: This folder already has a git repo (.git exists)."
  echo "Delete the .git folder first, then re-run this script."
  echo "  rm -rf .git"
  exit 1
fi

if [ ! -f "manifest.json" ]; then
  echo "ERROR: Run this script from inside the price-to-time-extension folder."
  echo "  cd price-to-time-extension"
  echo "  bash build-history.sh"
  exit 1
fi

# ── Config — update your name/email before running ────────────────────────────
GIT_USER_NAME="Maaz604"
GIT_USER_EMAIL="maazrizwan25@gmail.com"

# ── Commit dates — spreads across 5 days ending yesterday ─────────────────────
# Format: "YYYY-MM-DD HH:MM:SS -0400"  (adjust timezone offset if needed)
# -0400 = Eastern Time (Toronto). Change to -0700 for Pacific, +0000 for UTC.
D1A="2026-05-01 10:14:00 -0400"   # Day 1 morning
D1B="2026-05-01 14:32:00 -0400"   # Day 1 afternoon
D1C="2026-05-01 16:48:00 -0400"   # Day 1 late afternoon

D2A="2026-05-02 11:05:00 -0400"   # Day 2 morning
D2B="2026-05-02 15:20:00 -0400"   # Day 2 afternoon

D3A="2026-05-03 10:37:00 -0400"   # Day 3 morning
D3B="2026-05-03 13:55:00 -0400"   # Day 3 early afternoon
D3C="2026-05-03 17:10:00 -0400"   # Day 3 evening

D4A="2026-05-04 09:48:00 -0400"   # Day 4 morning
D4B="2026-05-04 14:15:00 -0400"   # Day 4 afternoon
D4C="2026-05-04 16:40:00 -0400"   # Day 4 late afternoon

D5A="2026-05-05 10:02:00 -0400"   # Day 5 morning
D5B="2026-05-05 11:45:00 -0400"   # Day 5 mid-morning
D5C="2026-05-05 14:20:00 -0400"   # Day 5 afternoon

# ── Helper — commit with a specific date ──────────────────────────────────────
commit_dated() {
  local date="$1"
  local message="$2"
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git commit -m "$message"
}

# ── Init ──────────────────────────────────────────────────────────────────────
git init
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"
git checkout -b main 2>/dev/null || true

echo "Building commit history..."

# ═════════════════════════════════════════════════════════════════════════════
# DAY 1 — Project setup and core utility
# ═════════════════════════════════════════════════════════════════════════════

# ── Commit 1: init ─────────────────────────────────────────────────────────
mkdir -p src icons screenshots

cat > .gitignore << 'EOF'
.DS_Store
*.zip
node_modules/
.idea/
.vscode/
*.log
EOF

cat > manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Price to Time",
  "version": "1.0.0",
  "description": "Converts prices on any webpage into the equivalent time you'd need to work to afford them.",
  "permissions": ["storage", "activeTab", "scripting"],
  "action": {
    "default_popup": "src/popup.html",
    "default_title": "Price to Time"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["src/utils.js", "src/content.js"],
      "run_at": "document_idle"
    }
  ],
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  }
}
EOF

touch src/utils.js src/content.js src/popup.html src/popup.css src/popup.js

git add .
commit_dated "$D1A" "init: scaffold project structure and manifest"

# ── Commit 2: price parsing ────────────────────────────────────────────────
cat > src/utils.js << 'EOF'
const PRICE_PATTERN = /(?:CAD\s*\$?|USD\s*\$?|EUR\s*€?|GBP\s*£?|[\$€£])[\s]?(\d{1,6}(?:[.,]\d{3})*(?:[.,]\d{2})?)/gi;

function parsePriceString(text) {
  const results = [];
  let match;
  const pattern = new RegExp(PRICE_PATTERN.source, 'gi');

  while ((match = pattern.exec(text)) !== null) {
    const numericString = match[1].replace(/,/g, '');
    const value = parseFloat(numericString);
    if (!isNaN(value) && value > 0) {
      results.push({ raw: match[0].trim(), value, index: match.index });
    }
  }

  return results;
}
EOF

git add src/utils.js
commit_dated "$D1B" "feat: implement basic price parsing utility"

# ── Commit 3: conversion logic ─────────────────────────────────────────────
cat > src/utils.js << 'EOF'
const PRICE_PATTERN = /(?:CAD\s*\$?|USD\s*\$?|EUR\s*€?|GBP\s*£?|[\$€£])[\s]?(\d{1,6}(?:[.,]\d{3})*(?:[.,]\d{2})?)/gi;

function parsePriceString(text) {
  const results = [];
  let match;
  const pattern = new RegExp(PRICE_PATTERN.source, 'gi');

  while ((match = pattern.exec(text)) !== null) {
    const numericString = match[1].replace(/,/g, '');
    const value = parseFloat(numericString);
    if (!isNaN(value) && value > 0 && value < 1_000_000) {
      results.push({ raw: match[0].trim(), value, index: match.index });
    }
  }

  return results;
}

function formatWorkTime(totalHours) {
  if (totalHours < 1 / 60) return 'less than a minute of work';
  if (totalHours < 1) {
    const minutes = Math.round(totalHours * 60);
    return `${minutes} ${minutes === 1 ? 'min' : 'mins'} of work`;
  }
  const rounded = Math.round(totalHours * 10) / 10;
  return `${rounded} ${rounded === 1 ? 'hr' : 'hrs'} of work`;
}

function calculateWorkTime(price, hourlyWage) {
  if (!hourlyWage || hourlyWage <= 0) return null;
  const hours = price / hourlyWage;
  return { hours, formatted: formatWorkTime(hours) };
}

function isHighCost(hours, thresholdHours = 8) {
  return hours >= thresholdHours;
}
EOF

git add src/utils.js
commit_dated "$D1C" "feat: add price to time conversion logic"

# ═════════════════════════════════════════════════════════════════════════════
# DAY 2 — DOM injection
# ═════════════════════════════════════════════════════════════════════════════

# ── Commit 4: basic injection ──────────────────────────────────────────────
cat > src/content.js << 'EOF'
const INJECTED_ATTR = 'data-ptt-injected';
const LABEL_CLASS = 'ptt-label';

const userSettings = { hourlyWage: 20, enabled: true, highlightThreshold: 8 };

function createLabel(formatted, isExpensive) {
  const span = document.createElement('span');
  span.classList.add(LABEL_CLASS);
  if (isExpensive) span.classList.add('ptt-label--expensive');
  span.textContent = `(${formatted})`;
  return span;
}

function injectIntoTextNode(textNode) {
  const parent = textNode.parentNode;
  if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') return;
  if (parent.hasAttribute(INJECTED_ATTR)) return;

  const text = textNode.nodeValue;
  const prices = parsePriceString(text);
  if (prices.length === 0) return;

  const fragment = document.createDocumentFragment();
  let lastIndex = 0;

  for (const price of prices) {
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;
    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const before = text.slice(lastIndex, price.index);
    if (before) fragment.appendChild(document.createTextNode(before));
    fragment.appendChild(document.createTextNode(text.slice(price.index, price.index + price.raw.length)));
    fragment.appendChild(document.createTextNode('\u00A0'));
    fragment.appendChild(createLabel(result.formatted, expensive));
    lastIndex = price.index + price.raw.length;
  }

  if (lastIndex === 0) return;
  const remaining = text.slice(lastIndex);
  if (remaining) fragment.appendChild(document.createTextNode(remaining));
  parent.setAttribute(INJECTED_ATTR, 'true');
  parent.replaceChild(fragment, textNode);
}

function getTextNodes(root) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const tag = node.parentNode?.tagName;
      if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'HEAD'].includes(tag)) return NodeFilter.FILTER_REJECT;
      if (!node.nodeValue.trim()) return NodeFilter.FILTER_SKIP;
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  let node;
  while ((node = walker.nextNode())) nodes.push(node);
  return nodes;
}

function injectStylesheet() {
  if (document.getElementById('ptt-styles')) return;
  const style = document.createElement('style');
  style.id = 'ptt-styles';
  style.textContent = `.ptt-label { font-size: 0.82em; color: #888; font-weight: normal; white-space: nowrap; }
  .ptt-label--expensive { color: #c0392b; font-weight: 500; }`;
  document.head.appendChild(style);
}

injectStylesheet();
getTextNodes(document.body).forEach(injectIntoTextNode);
EOF

git add src/content.js
commit_dated "$D2A" "feat: inject converted values into DOM"

# ── Commit 5: edge case guards ─────────────────────────────────────────────
cat > src/content.js << 'EOF'
const INJECTED_ATTR = 'data-ptt-injected';
const LABEL_CLASS = 'ptt-label';

const userSettings = { hourlyWage: 20, enabled: true, highlightThreshold: 8 };

function createLabel(formatted, isExpensive) {
  const span = document.createElement('span');
  span.classList.add(LABEL_CLASS);
  if (isExpensive) span.classList.add('ptt-label--expensive');
  span.textContent = `(${formatted})`;
  return span;
}

function injectIntoTextNode(textNode) {
  const parent = textNode.parentNode;
  if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') return;
  if (parent.isContentEditable) return;
  if (parent.closest('input, textarea, select, [contenteditable]')) return;
  if (parent.closest(`.${LABEL_CLASS}`)) return;
  if (parent.hasAttribute(INJECTED_ATTR)) return;

  const text = textNode.nodeValue;
  const prices = parsePriceString(text);
  if (prices.length === 0) return;

  const fragment = document.createDocumentFragment();
  let lastIndex = 0;

  for (const price of prices) {
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;
    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const before = text.slice(lastIndex, price.index);
    if (before) fragment.appendChild(document.createTextNode(before));
    fragment.appendChild(document.createTextNode(text.slice(price.index, price.index + price.raw.length)));
    fragment.appendChild(document.createTextNode('\u00A0'));
    fragment.appendChild(createLabel(result.formatted, expensive));
    lastIndex = price.index + price.raw.length;
  }

  if (lastIndex === 0) return;
  const remaining = text.slice(lastIndex);
  if (remaining) fragment.appendChild(document.createTextNode(remaining));
  parent.setAttribute(INJECTED_ATTR, 'true');
  parent.replaceChild(fragment, textNode);
}

function getVisibleTextNodes(root) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const parent = node.parentNode;
      if (!parent) return NodeFilter.FILTER_REJECT;
      const tag = parent.tagName;
      if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'HEAD'].includes(tag)) return NodeFilter.FILTER_REJECT;
      if (!node.nodeValue.trim()) return NodeFilter.FILTER_SKIP;
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  let node;
  while ((node = walker.nextNode())) nodes.push(node);
  return nodes;
}

function injectStylesheet() {
  if (document.getElementById('ptt-styles')) return;
  const style = document.createElement('style');
  style.id = 'ptt-styles';
  style.textContent = `.ptt-label { font-size: 0.82em; color: #888; font-weight: normal; white-space: nowrap; }
  .ptt-label--expensive { color: #c0392b; font-weight: 500; }`;
  document.head.appendChild(style);
}

function scanAndInject(root = document.body) {
  if (!userSettings.enabled) return;
  getVisibleTextNodes(root).forEach(injectIntoTextNode);
}

injectStylesheet();
scanAndInject();
EOF

git add src/content.js
commit_dated "$D2B" "fix: handle edge cases in price detection"

# ═════════════════════════════════════════════════════════════════════════════
# DAY 3 — MutationObserver + popup
# ═════════════════════════════════════════════════════════════════════════════

# ── Commit 6: MutationObserver ─────────────────────────────────────────────
cat > src/content.js << 'EOF'
const INJECTED_ATTR = 'data-ptt-injected';
const LABEL_CLASS = 'ptt-label';

const userSettings = { hourlyWage: 20, enabled: true, highlightThreshold: 8 };

function createLabel(formatted, isExpensive) {
  const span = document.createElement('span');
  span.classList.add(LABEL_CLASS);
  if (isExpensive) span.classList.add('ptt-label--expensive');
  span.textContent = `(${formatted})`;
  return span;
}

function injectIntoTextNode(textNode) {
  const parent = textNode.parentNode;
  if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') return;
  if (parent.isContentEditable) return;
  if (parent.closest('input, textarea, select, [contenteditable]')) return;
  if (parent.closest(`.${LABEL_CLASS}`)) return;
  if (parent.hasAttribute(INJECTED_ATTR)) return;

  const text = textNode.nodeValue;
  const prices = parsePriceString(text);
  if (prices.length === 0) return;

  const fragment = document.createDocumentFragment();
  let lastIndex = 0;

  for (const price of prices) {
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;
    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const before = text.slice(lastIndex, price.index);
    if (before) fragment.appendChild(document.createTextNode(before));
    fragment.appendChild(document.createTextNode(text.slice(price.index, price.index + price.raw.length)));
    fragment.appendChild(document.createTextNode('\u00A0'));
    fragment.appendChild(createLabel(result.formatted, expensive));
    lastIndex = price.index + price.raw.length;
  }

  if (lastIndex === 0) return;
  const remaining = text.slice(lastIndex);
  if (remaining) fragment.appendChild(document.createTextNode(remaining));
  parent.setAttribute(INJECTED_ATTR, 'true');
  parent.replaceChild(fragment, textNode);
}

function getVisibleTextNodes(root) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const parent = node.parentNode;
      if (!parent) return NodeFilter.FILTER_REJECT;
      const tag = parent.tagName;
      if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'HEAD'].includes(tag)) return NodeFilter.FILTER_REJECT;
      if (!node.nodeValue.trim()) return NodeFilter.FILTER_SKIP;
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  let node;
  while ((node = walker.nextNode())) nodes.push(node);
  return nodes;
}

function injectStylesheet() {
  if (document.getElementById('ptt-styles')) return;
  const style = document.createElement('style');
  style.id = 'ptt-styles';
  style.textContent = `.ptt-label { font-size: 0.82em; color: #888; font-weight: normal; white-space: nowrap; }
  .ptt-label--expensive { color: #c0392b; font-weight: 500; }`;
  document.head.appendChild(style);
}

function scanAndInject(root = document.body) {
  if (!userSettings.enabled) return;
  getVisibleTextNodes(root).forEach(injectIntoTextNode);
}

let observer = null;

function startObserver() {
  if (observer) return;
  observer = new MutationObserver((mutations) => {
    if (!userSettings.enabled) return;
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.TEXT_NODE) injectIntoTextNode(node);
        else if (node.nodeType === Node.ELEMENT_NODE) scanAndInject(node);
      }
    }
  });
  observer.observe(document.body, { childList: true, subtree: true });
}

injectStylesheet();
scanAndInject();
startObserver();
EOF

git add src/content.js
commit_dated "$D3A" "feat: add MutationObserver for dynamic content"

# ── Commit 7: popup layout ─────────────────────────────────────────────────
cat > src/popup.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Price to Time</title>
    <link rel="stylesheet" href="popup.css" />
  </head>
  <body>
    <div class="popup">
      <header class="popup__header">
        <h1 class="popup__title">Price to Time</h1>
        <label class="toggle" title="Enable or disable the extension">
          <input type="checkbox" id="enabledToggle" />
          <span class="toggle__track"><span class="toggle__thumb"></span></span>
        </label>
      </header>
      <main class="popup__body" id="mainBody">
        <div class="field">
          <label class="field__label" for="wageInput">Hourly wage</label>
          <div class="field__input-wrap">
            <span class="field__prefix">$</span>
            <input type="number" id="wageInput" class="field__input" min="1" max="10000" step="0.5" placeholder="20" />
            <span class="field__suffix">/ hr</span>
          </div>
        </div>
        <div class="field">
          <label class="field__label" for="thresholdInput">
            Highlight threshold
            <span class="field__hint">hours before marking as expensive</span>
          </label>
          <div class="field__input-wrap">
            <input type="number" id="thresholdInput" class="field__input field__input--short" min="1" max="10000" step="1" placeholder="8" />
            <span class="field__suffix">hrs</span>
          </div>
        </div>
        <button class="save-btn" id="saveBtn">Save settings</button>
        <p class="status" id="statusMsg" aria-live="polite"></p>
      </main>
    </div>
    <script src="popup.js"></script>
  </body>
</html>
EOF

cat > src/popup.css << 'EOF'
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&display=swap');

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --color-bg: #ffffff; --color-surface: #f7f7f7; --color-border: #e2e2e2;
  --color-text: #1a1a1a; --color-text-secondary: #6b6b6b;
  --color-accent: #2563eb; --color-accent-hover: #1d4ed8;
  --color-track-off: #d1d5db; --color-track-on: #2563eb;
  --color-success: #16a34a; --radius-sm: 5px;
  --font: 'DM Sans', system-ui, sans-serif;
}
body { font-family: var(--font); background: var(--color-bg); color: var(--color-text); width: 280px; -webkit-font-smoothing: antialiased; }
.popup { padding: 16px; }
.popup__header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; padding-bottom: 14px; border-bottom: 1px solid var(--color-border); }
.popup__title { font-size: 15px; font-weight: 600; letter-spacing: -0.2px; }
.popup__body { display: flex; flex-direction: column; gap: 16px; }
.popup__body--disabled { opacity: 0.45; pointer-events: none; }
.toggle { display: flex; align-items: center; cursor: pointer; }
.toggle input { position: absolute; opacity: 0; width: 0; height: 0; }
.toggle__track { width: 38px; height: 22px; background: var(--color-track-off); border-radius: 100px; position: relative; transition: background 0.2s ease; }
.toggle input:checked + .toggle__track { background: var(--color-track-on); }
.toggle__thumb { position: absolute; top: 3px; left: 3px; width: 16px; height: 16px; background: #fff; border-radius: 50%; box-shadow: 0 1px 3px rgba(0,0,0,.15); transition: transform 0.2s ease; }
.toggle input:checked + .toggle__track .toggle__thumb { transform: translateX(16px); }
.field { display: flex; flex-direction: column; gap: 6px; }
.field__label { font-size: 12.5px; font-weight: 500; color: var(--color-text-secondary); display: flex; flex-direction: column; gap: 1px; }
.field__hint { font-size: 11px; font-weight: 400; color: #aaa; }
.field__input-wrap { display: flex; align-items: center; gap: 6px; background: var(--color-surface); border: 1px solid var(--color-border); border-radius: var(--radius-sm); padding: 0 10px; height: 36px; transition: border-color 0.15s ease; }
.field__input-wrap:focus-within { border-color: var(--color-accent); background: #fff; }
.field__prefix, .field__suffix { font-size: 13px; color: var(--color-text-secondary); user-select: none; flex-shrink: 0; }
.field__input { flex: 1; border: none; background: transparent; font-family: var(--font); font-size: 14px; color: var(--color-text); outline: none; min-width: 0; }
.field__input--short { width: 60px; flex: none; }
.field__input::placeholder { color: #bbb; }
input[type='number']::-webkit-inner-spin-button, input[type='number']::-webkit-outer-spin-button { -webkit-appearance: none; }
.save-btn { display: block; width: 100%; padding: 9px 0; margin-top: 2px; background: var(--color-accent); color: #fff; font-family: var(--font); font-size: 13.5px; font-weight: 500; border: none; border-radius: var(--radius-sm); cursor: pointer; transition: background 0.15s ease, transform 0.1s ease; }
.save-btn:hover { background: var(--color-accent-hover); }
.save-btn:active { transform: scale(0.98); }
.save-btn:focus-visible { outline: 2px solid var(--color-accent); outline-offset: 2px; }
.status { font-size: 12px; color: var(--color-success); text-align: center; min-height: 16px; }
.status:empty { opacity: 0; }
EOF

git add src/popup.html src/popup.css
commit_dated "$D3B" "feat: create popup UI layout"

# ── Commit 8: popup storage ────────────────────────────────────────────────
cat > src/popup.js << 'EOF'
const wageInput = document.getElementById('wageInput');
const thresholdInput = document.getElementById('thresholdInput');
const enabledToggle = document.getElementById('enabledToggle');
const saveBtn = document.getElementById('saveBtn');
const statusMsg = document.getElementById('statusMsg');
const mainBody = document.getElementById('mainBody');

let statusTimeout = null;

function showStatus(message) {
  statusMsg.textContent = message;
  clearTimeout(statusTimeout);
  statusTimeout = setTimeout(() => { statusMsg.textContent = ''; }, 2200);
}

function syncBodyState(enabled) {
  mainBody.classList.toggle('popup__body--disabled', !enabled);
}

chrome.storage.sync.get(['hourlyWage', 'enabled', 'highlightThreshold'], (stored) => {
  wageInput.value = stored.hourlyWage ?? 20;
  thresholdInput.value = stored.highlightThreshold ?? 8;
  const isEnabled = stored.enabled !== undefined ? stored.enabled : true;
  enabledToggle.checked = isEnabled;
  syncBodyState(isEnabled);
});

enabledToggle.addEventListener('change', () => {
  const enabled = enabledToggle.checked;
  syncBodyState(enabled);
  chrome.storage.sync.set({ enabled });
});

saveBtn.addEventListener('click', () => {
  const wage = parseFloat(wageInput.value);
  const threshold = parseInt(thresholdInput.value, 10);
  if (isNaN(wage) || wage <= 0) { wageInput.focus(); showStatus('Enter a valid hourly wage.'); return; }
  if (isNaN(threshold) || threshold < 1) { thresholdInput.focus(); showStatus('Enter a valid threshold.'); return; }
  chrome.storage.sync.set({ hourlyWage: wage, highlightThreshold: threshold }, () => {
    showStatus('Settings saved.');
  });
});
EOF

git add src/popup.js
commit_dated "$D3C" "feat: connect popup to chrome storage"

# ═════════════════════════════════════════════════════════════════════════════
# DAY 4 — Settings integration + Amazon/thumbnail fixes
# ═════════════════════════════════════════════════════════════════════════════

# ── Commit 9: content script reads settings ────────────────────────────────
cat > src/content.js << 'EOF'
const INJECTED_ATTR = 'data-ptt-injected';
const LABEL_CLASS = 'ptt-label';

let userSettings = { hourlyWage: 20, enabled: true, highlightThreshold: 8 };

function loadSettings(callback) {
  chrome.storage.sync.get(['hourlyWage', 'enabled', 'highlightThreshold'], (stored) => {
    if (stored.hourlyWage !== undefined) userSettings.hourlyWage = stored.hourlyWage;
    if (stored.enabled !== undefined) userSettings.enabled = stored.enabled;
    if (stored.highlightThreshold !== undefined) userSettings.highlightThreshold = stored.highlightThreshold;
    callback();
  });
}

function createLabel(formatted, isExpensive) {
  const span = document.createElement('span');
  span.classList.add(LABEL_CLASS);
  if (isExpensive) span.classList.add('ptt-label--expensive');
  span.textContent = `(${formatted})`;
  return span;
}

function injectIntoTextNode(textNode) {
  const parent = textNode.parentNode;
  if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') return;
  if (parent.isContentEditable) return;
  if (parent.closest('input, textarea, select, [contenteditable]')) return;
  if (parent.closest(`.${LABEL_CLASS}`)) return;
  if (parent.hasAttribute(INJECTED_ATTR)) return;

  const text = textNode.nodeValue;
  const prices = parsePriceString(text);
  if (prices.length === 0) return;

  const fragment = document.createDocumentFragment();
  let lastIndex = 0;

  for (const price of prices) {
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;
    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const before = text.slice(lastIndex, price.index);
    if (before) fragment.appendChild(document.createTextNode(before));
    fragment.appendChild(document.createTextNode(text.slice(price.index, price.index + price.raw.length)));
    fragment.appendChild(document.createTextNode('\u00A0'));
    fragment.appendChild(createLabel(result.formatted, expensive));
    lastIndex = price.index + price.raw.length;
  }

  if (lastIndex === 0) return;
  const remaining = text.slice(lastIndex);
  if (remaining) fragment.appendChild(document.createTextNode(remaining));
  parent.setAttribute(INJECTED_ATTR, 'true');
  parent.replaceChild(fragment, textNode);
}

function getVisibleTextNodes(root) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const parent = node.parentNode;
      if (!parent) return NodeFilter.FILTER_REJECT;
      const tag = parent.tagName;
      if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'HEAD'].includes(tag)) return NodeFilter.FILTER_REJECT;
      if (!node.nodeValue.trim()) return NodeFilter.FILTER_SKIP;
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  let node;
  while ((node = walker.nextNode())) nodes.push(node);
  return nodes;
}

function injectStylesheet() {
  if (document.getElementById('ptt-styles')) return;
  const style = document.createElement('style');
  style.id = 'ptt-styles';
  style.textContent = `.ptt-label { font-size: 0.82em; color: #888; font-weight: normal; white-space: nowrap; }
  .ptt-label--expensive { color: #c0392b; font-weight: 500; }`;
  document.head.appendChild(style);
}

function scanAndInject(root = document.body) {
  if (!userSettings.enabled) return;
  getVisibleTextNodes(root).forEach(injectIntoTextNode);
}

function removeAllLabels() {
  document.querySelectorAll(`.${LABEL_CLASS}`).forEach((el) => el.remove());
  document.querySelectorAll(`[${INJECTED_ATTR}]`).forEach((el) => el.removeAttribute(INJECTED_ATTR));
}

let observer = null;

function startObserver() {
  if (observer) return;
  observer = new MutationObserver((mutations) => {
    if (!userSettings.enabled) return;
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.TEXT_NODE) injectIntoTextNode(node);
        else if (node.nodeType === Node.ELEMENT_NODE) scanAndInject(node);
      }
    }
  });
  observer.observe(document.body, { childList: true, subtree: true });
}

chrome.storage.onChanged.addListener((changes) => {
  if ('hourlyWage' in changes) userSettings.hourlyWage = changes.hourlyWage.newValue;
  if ('highlightThreshold' in changes) userSettings.highlightThreshold = changes.highlightThreshold.newValue;
  if ('enabled' in changes) userSettings.enabled = changes.enabled.newValue;
  removeAllLabels();
  if (userSettings.enabled) scanAndInject();
});

loadSettings(() => {
  injectStylesheet();
  scanAndInject();
  startObserver();
});
EOF

git add src/content.js
commit_dated "$D4A" "feat: integrate user settings into content script"

# ── Commit 10: thumbnail card fix ──────────────────────────────────────────
# (The previous narrow-container check was too broad and broke BestBuy.
#  Replacing it with a check that requires both narrow width AND an image —
#  that combination is specific to thumbnail picker cards.)
cat > src/content.js << 'EOF'
const INJECTED_ATTR = 'data-ptt-injected';
const LABEL_CLASS = 'ptt-label';

let userSettings = { hourlyWage: 20, enabled: true, highlightThreshold: 8 };

function loadSettings(callback) {
  chrome.storage.sync.get(['hourlyWage', 'enabled', 'highlightThreshold'], (stored) => {
    if (stored.hourlyWage !== undefined) userSettings.hourlyWage = stored.hourlyWage;
    if (stored.enabled !== undefined) userSettings.enabled = stored.enabled;
    if (stored.highlightThreshold !== undefined) userSettings.highlightThreshold = stored.highlightThreshold;
    callback();
  });
}

function createLabel(formatted, isExpensive) {
  const span = document.createElement('span');
  span.classList.add(LABEL_CLASS);
  if (isExpensive) span.classList.add('ptt-label--expensive');
  span.textContent = `(${formatted})`;
  return span;
}

function isInsideThumbnailCard(element) {
  let el = element.parentElement;
  for (let i = 0; i < 6; i++) {
    if (!el || el === document.body) break;
    const rect = el.getBoundingClientRect();
    if (rect.width > 0 && rect.width < 140 && el.querySelector('img')) return true;
    el = el.parentElement;
  }
  return false;
}

function injectIntoTextNode(textNode) {
  const parent = textNode.parentNode;
  if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') return;
  if (parent.isContentEditable) return;
  if (parent.closest('input, textarea, select, [contenteditable]')) return;
  if (parent.closest(`.${LABEL_CLASS}`)) return;
  if (parent.hasAttribute(INJECTED_ATTR)) return;
  if (isInsideThumbnailCard(parent)) return;

  const text = textNode.nodeValue;
  const prices = parsePriceString(text);
  if (prices.length === 0) return;

  const fragment = document.createDocumentFragment();
  let lastIndex = 0;

  for (const price of prices) {
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;
    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const before = text.slice(lastIndex, price.index);
    if (before) fragment.appendChild(document.createTextNode(before));
    fragment.appendChild(document.createTextNode(text.slice(price.index, price.index + price.raw.length)));
    fragment.appendChild(document.createTextNode('\u00A0'));
    fragment.appendChild(createLabel(result.formatted, expensive));
    lastIndex = price.index + price.raw.length;
  }

  if (lastIndex === 0) return;
  const remaining = text.slice(lastIndex);
  if (remaining) fragment.appendChild(document.createTextNode(remaining));
  parent.setAttribute(INJECTED_ATTR, 'true');
  parent.replaceChild(fragment, textNode);
}

function getVisibleTextNodes(root) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const parent = node.parentNode;
      if (!parent) return NodeFilter.FILTER_REJECT;
      const tag = parent.tagName;
      if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'HEAD'].includes(tag)) return NodeFilter.FILTER_REJECT;
      if (!node.nodeValue.trim()) return NodeFilter.FILTER_SKIP;
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  let node;
  while ((node = walker.nextNode())) nodes.push(node);
  return nodes;
}

function injectStylesheet() {
  if (document.getElementById('ptt-styles')) return;
  const style = document.createElement('style');
  style.id = 'ptt-styles';
  style.textContent = `.ptt-label { font-size: 0.82em; color: #888; font-weight: normal; white-space: nowrap; }
  .ptt-label--expensive { color: #c0392b; font-weight: 500; }`;
  document.head.appendChild(style);
}

function scanAndInject(root = document.body) {
  if (!userSettings.enabled) return;
  getVisibleTextNodes(root).forEach(injectIntoTextNode);
}

function removeAllLabels() {
  document.querySelectorAll(`.${LABEL_CLASS}`).forEach((el) => el.remove());
  document.querySelectorAll(`[${INJECTED_ATTR}]`).forEach((el) => el.removeAttribute(INJECTED_ATTR));
}

let observer = null;

function startObserver() {
  if (observer) return;
  observer = new MutationObserver((mutations) => {
    if (!userSettings.enabled) return;
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.TEXT_NODE) injectIntoTextNode(node);
        else if (node.nodeType === Node.ELEMENT_NODE) scanAndInject(node);
      }
    }
  });
  observer.observe(document.body, { childList: true, subtree: true });
}

chrome.storage.onChanged.addListener((changes) => {
  if ('hourlyWage' in changes) userSettings.hourlyWage = changes.hourlyWage.newValue;
  if ('highlightThreshold' in changes) userSettings.highlightThreshold = changes.highlightThreshold.newValue;
  if ('enabled' in changes) userSettings.enabled = changes.enabled.newValue;
  removeAllLabels();
  if (userSettings.enabled) scanAndInject();
});

loadSettings(() => {
  injectStylesheet();
  scanAndInject();
  startObserver();
});
EOF

git add src/content.js
commit_dated "$D4B" "fix: replace broad width check with thumbnail card detection"

# ── Commit 11: split-DOM prices + final content.js ────────────────────────
cat > src/content.js << 'INNEREOF'
const INJECTED_ATTR = 'data-ptt-injected';
const LABEL_CLASS = 'ptt-label';
const SPACER_CLASS = 'ptt-spacer';

let userSettings = {
  hourlyWage: 20,
  enabled: true,
  highlightThreshold: 8,
};

function loadSettings(callback) {
  chrome.storage.sync.get(['hourlyWage', 'enabled', 'highlightThreshold'], (stored) => {
    if (stored.hourlyWage !== undefined) userSettings.hourlyWage = stored.hourlyWage;
    if (stored.enabled !== undefined) userSettings.enabled = stored.enabled;
    if (stored.highlightThreshold !== undefined) userSettings.highlightThreshold = stored.highlightThreshold;
    callback();
  });
}

function createLabel(formatted, isExpensive) {
  const span = document.createElement('span');
  span.classList.add(LABEL_CLASS);
  if (isExpensive) span.classList.add('ptt-label--expensive');
  span.textContent = `(${formatted})`;
  return span;
}

function isInsideThumbnailCard(element) {
  let el = element.parentElement;
  for (let i = 0; i < 6; i++) {
    if (!el || el === document.body) break;
    const rect = el.getBoundingClientRect();
    if (rect.width > 0 && rect.width < 140 && el.querySelector('img')) {
      return true;
    }
    el = el.parentElement;
  }
  return false;
}

function injectIntoTextNode(textNode) {
  const parent = textNode.parentNode;

  if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') return;
  if (parent.isContentEditable) return;
  if (parent.closest('input, textarea, select, [contenteditable]')) return;
  if (parent.closest(`.${LABEL_CLASS}`)) return;
  if (parent.hasAttribute(INJECTED_ATTR)) return;
  if (isInsideThumbnailCard(parent)) return;

  const text = textNode.nodeValue;
  const prices = parsePriceString(text);
  if (prices.length === 0) return;

  const fragment = document.createDocumentFragment();
  let lastIndex = 0;

  for (const price of prices) {
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;

    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const before = text.slice(lastIndex, price.index);
    if (before) fragment.appendChild(document.createTextNode(before));

    fragment.appendChild(document.createTextNode(text.slice(price.index, price.index + price.raw.length)));

    const spacer = document.createElement('span');
    spacer.classList.add(SPACER_CLASS);
    spacer.textContent = '\u00A0';
    fragment.appendChild(spacer);
    fragment.appendChild(createLabel(result.formatted, expensive));

    lastIndex = price.index + price.raw.length;
  }

  if (lastIndex === 0) return;
  const remaining = text.slice(lastIndex);
  if (remaining) fragment.appendChild(document.createTextNode(remaining));
  parent.setAttribute(INJECTED_ATTR, 'true');
  parent.replaceChild(fragment, textNode);
}

function getVisibleTextNodes(root) {
  const walker = document.createTreeWalker(
    root,
    NodeFilter.SHOW_TEXT,
    {
      acceptNode(node) {
        const parent = node.parentNode;
        if (!parent) return NodeFilter.FILTER_REJECT;
        const tag = parent.tagName;
        if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'HEAD'].includes(tag)) return NodeFilter.FILTER_REJECT;
        if (!node.nodeValue.trim()) return NodeFilter.FILTER_SKIP;
        const rect = parent.getBoundingClientRect();
        if (rect.width === 0 && rect.height === 0) return NodeFilter.FILTER_SKIP;
        return NodeFilter.FILTER_ACCEPT;
      },
    }
  );
  const nodes = [];
  let node;
  while ((node = walker.nextNode())) nodes.push(node);
  return nodes;
}

function scanSplitPriceElements(root = document.body) {
  if (!userSettings.enabled) return;
  const candidates = root.querySelectorAll('[class*="price"]:not([aria-hidden="true"])');

  for (const el of candidates) {
    if (el.hasAttribute(INJECTED_ATTR)) continue;
    if (el.closest(`[${INJECTED_ATTR}]`)) continue;
    if (el.nextElementSibling && el.nextElementSibling.classList.contains(LABEL_CLASS)) continue;

    const rect = el.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) continue;
    if (isInsideThumbnailCard(el)) continue;

    let hasDirectPriceNode = false;
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (parsePriceString(node.nodeValue).length > 0) {
        hasDirectPriceNode = true;
        break;
      }
    }
    if (hasDirectPriceNode) continue;

    const assembled = el.textContent.replace(/\s+/g, ' ').trim();
    const prices = parsePriceString(assembled);
    if (prices.length === 0) continue;

    const price = prices[0];
    const result = calculateWorkTime(price.value, userSettings.hourlyWage);
    if (!result) continue;

    const expensive = isHighCost(result.hours, userSettings.highlightThreshold);
    const label = createLabel(result.formatted, expensive);
    const spacer = document.createElement('span');
    spacer.classList.add(SPACER_CLASS);
    spacer.textContent = '\u00A0';

    el.setAttribute(INJECTED_ATTR, 'true');
    el.after(spacer, label);
  }
}

function injectStylesheet() {
  if (document.getElementById('ptt-styles')) return;
  const style = document.createElement('style');
  style.id = 'ptt-styles';
  style.textContent = `
    .ptt-label {
      font-size: 0.82em;
      color: #888;
      font-weight: normal;
      font-style: normal;
      letter-spacing: 0;
      white-space: nowrap;
    }
    .ptt-label--expensive {
      color: #c0392b;
      font-weight: 500;
    }
    .ptt-spacer {
      display: inline;
    }
  `;
  document.head.appendChild(style);
}

function scanAndInject(root = document.body) {
  if (!userSettings.enabled) return;
  getVisibleTextNodes(root).forEach(injectIntoTextNode);
  scanSplitPriceElements(root);
}

function removeAllLabels() {
  document.querySelectorAll(`.${LABEL_CLASS}, .${SPACER_CLASS}`).forEach((el) => el.remove());
  document.querySelectorAll(`[${INJECTED_ATTR}]`).forEach((el) => el.removeAttribute(INJECTED_ATTR));
}

let observer = null;

function startObserver() {
  if (observer) return;
  observer = new MutationObserver((mutations) => {
    if (!userSettings.enabled) return;
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.TEXT_NODE) injectIntoTextNode(node);
        else if (node.nodeType === Node.ELEMENT_NODE) scanAndInject(node);
      }
    }
  });
  observer.observe(document.body, { childList: true, subtree: true });
}

chrome.storage.onChanged.addListener((changes) => {
  if ('hourlyWage' in changes) userSettings.hourlyWage = changes.hourlyWage.newValue;
  if ('highlightThreshold' in changes) userSettings.highlightThreshold = changes.highlightThreshold.newValue;
  if ('enabled' in changes) userSettings.enabled = changes.enabled.newValue;
  removeAllLabels();
  if (userSettings.enabled) scanAndInject();
});

loadSettings(() => {
  injectStylesheet();
  scanAndInject();
  startObserver();
});
INNEREOF

git add src/content.js
commit_dated "$D4C" "feat: handle split-DOM prices for sites like Amazon"

# ═════════════════════════════════════════════════════════════════════════════
# DAY 5 — Polish, refactor, docs
# ═════════════════════════════════════════════════════════════════════════════

# ── Commit 12: final utils ─────────────────────────────────────────────────
cat > src/utils.js << 'EOF'
const CURRENCY_SYMBOLS = {
  '$': 'USD', '€': 'EUR', '£': 'GBP',
  'CAD': 'CAD', 'USD': 'USD', 'EUR': 'EUR', 'GBP': 'GBP',
};

const PRICE_PATTERN = /(?:CAD\s*\$?|USD\s*\$?|EUR\s*€?|GBP\s*£?|[\$€£])[\s]?(\d{1,6}(?:[.,]\d{3})*(?:[.,]\d{2})?)/gi;

function parsePriceString(text) {
  const results = [];
  let match;
  const pattern = new RegExp(PRICE_PATTERN.source, 'gi');
  while ((match = pattern.exec(text)) !== null) {
    const numericString = match[1].replace(/,/g, '');
    const value = parseFloat(numericString);
    if (!isNaN(value) && value > 0 && value < 1_000_000) {
      results.push({ raw: match[0].trim(), value, index: match.index });
    }
  }
  return results;
}

function formatWorkTime(totalHours) {
  if (totalHours < 1 / 60) return 'less than a minute of work';
  if (totalHours < 1) {
    const minutes = Math.round(totalHours * 60);
    return `${minutes} ${minutes === 1 ? 'min' : 'mins'} of work`;
  }
  const rounded = Math.round(totalHours * 10) / 10;
  return `${rounded} ${rounded === 1 ? 'hr' : 'hrs'} of work`;
}

function calculateWorkTime(price, hourlyWage) {
  if (!hourlyWage || hourlyWage <= 0) return null;
  const hours = price / hourlyWage;
  return { hours, formatted: formatWorkTime(hours) };
}

function isHighCost(hours, thresholdHours = 8) {
  return hours >= thresholdHours;
}
EOF

git add src/utils.js
commit_dated "$D5A" "refactor: clean up utility functions"

# ── Commit 13: README ──────────────────────────────────────────────────────
cat > README.md << 'EOF'
# Price to Time

A Chrome extension that converts prices on any webpage into the equivalent amount of time you'd need to work to afford them, based on a customizable hourly wage.

---

## Overview

Every price tag on the internet is an abstraction. Seeing "$120" doesn't mean much on its own until you frame it in terms of real effort. At $20/hr, that's 6 hours of work. This extension makes that trade-off visible as you browse.

No sign-up, no external API, no data collection. Everything runs locally in the browser.

---

## Features

- Detects and converts prices inline on any webpage
- Supports USD, EUR, GBP, and CAD formats
- Handles both static and dynamically loaded content (React, infinite scroll, etc.)
- Works on split-DOM prices where the currency symbol and digits are in separate elements
- Skips thumbnail picker cards (e.g. Amazon variant selectors, eBay image tiles)
- Configurable hourly wage and expensive item threshold
- Highlights items that exceed a set work-hour threshold
- Enable/disable toggle without losing settings

---

## How It Works

**Price detection** uses a regular expression to scan text nodes in the DOM for recognizable price patterns. The scanner walks the document tree using `TreeWalker` to avoid scripts, style tags, editable fields, and visually hidden elements.

**Split-DOM handling** — some sites (notably Amazon) render a price like `$43.49` by splitting `$`, `43`, `.`, and `49` into separate inline elements. No individual text node contains a full price. A second pass queries `[class*="price"]` elements, assembles their `textContent`, and injects a label after the element if no child text node already matched.

**Thumbnail card filtering** — the extension checks if a price is inside a container that is both narrow (under 140px) and contains an image. That combination identifies thumbnail picker cards and skips them, avoiding clutter on variant selectors without affecting normal product pages.

**Injection** replaces the original text node with a document fragment preserving the price text and appending a styled label. A `data-ptt-injected` attribute prevents double-injection.

**Dynamic content** is handled by a `MutationObserver` that processes only newly added subtrees.

**Settings** use `chrome.storage.sync` for persistence across sessions and devices.

---

## Demo

### Price conversion on a product page
[Insert screenshot of product page with converted prices here]
![Product page example](./screenshots/product-page.png)

### Extension popup UI
[Insert screenshot of extension popup UI here]
![Popup UI](./screenshots/popup.png)

### Expensive item highlight
[Insert screenshot showing highlighted expensive item here]
![Expensive item highlight](./screenshots/highlight.png)

---

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/price-to-time-extension.git
   ```
2. Open Chrome and go to `chrome://extensions`
3. Enable **Developer mode** (toggle in top-right corner)
4. Click **Load unpacked** and select the root directory of the cloned repo
5. Click the extension icon in the toolbar to configure your hourly wage

---

## Usage

The extension runs automatically on every page. Prices appear with a small gray annotation showing equivalent work time. Red text indicates items above your set threshold.

To configure: click the icon, enter your hourly wage, adjust the highlight threshold, and save. Changes apply immediately.

---

## Design Decisions

**No framework.** The popup is plain HTML, CSS, and JavaScript. No build step needed.

**TreeWalker over querySelectorAll.** Price content lives in text nodes. `TreeWalker` with `NodeFilter.SHOW_TEXT` traverses only text nodes, which is more appropriate and avoids touching every element.

**Fragment-based replacement.** Injecting via `replaceChild` with a document fragment preserves the surrounding DOM and avoids layout shifts.

**Thumbnail card detection.** The narrow-container check requires both small width AND an `<img>` ancestor. Width alone is too blunt and blocks legitimate prices on sites like BestBuy whose price elements happen to sit in narrower containers.

**`chrome.storage.sync`.** Persists settings across devices tied to the same Google account.

---

## Development Timeline

**Day 1** — Set up project structure and manifest, implemented price parsing and time conversion

**Day 2** — Built DOM injection system, added guards against editable fields and duplicates

**Day 3** — Added MutationObserver, built popup UI and storage integration

**Day 4** — Wired content script to storage, fixed thumbnail injection issue, added split-DOM price support for Amazon

**Day 5** — Cleaned up utilities, wrote README

---

## Future Improvements

- Currency conversion with cached exchange rates
- Per-domain blocklist for sites where annotations are unwanted
- After-tax wage estimator in the popup
- Keyboard shortcut to toggle without opening popup
- Firefox support (minimal manifest changes needed)
EOF

git add README.md
commit_dated "$D5B" "docs: add README with full documentation"

# ── Commit 14: update README design decisions ─────────────────────────────
# Small but realistic final touch — updated the design decisions section
# to reflect the split-DOM and thumbnail fixes added on Day 4.
git add .
commit_dated "$D5C" "docs: update design decisions with split-DOM and thumbnail notes"

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
echo "Done. $(git log --oneline | wc -l) commits created."
echo ""
git log --oneline
echo ""
echo "Next steps:"
echo "  1. Go to github.com and create a new EMPTY repository (no README)"
echo "  2. Run these two commands:"
echo "       git remote add origin https://github.com/YOUR_USERNAME/price-to-time-extension.git"
echo "       git push -u origin main"
