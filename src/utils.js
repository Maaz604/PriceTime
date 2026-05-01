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
