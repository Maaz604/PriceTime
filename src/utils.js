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
