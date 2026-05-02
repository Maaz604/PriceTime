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
