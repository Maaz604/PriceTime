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
